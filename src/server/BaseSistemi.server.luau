--[[
	BaseSistemi  (Script)
	Yeri: ServerScriptService > BaseSistemi

	Sunucu 6 kisiliktir; her oyuncuya katildiginda bos bir base atanir.

	YERLESTIRME (Brainrot Tsunami tarzi):
	  Acilmis bir brainrotu ELINE AL, base'indeki bir slota yaklas, E'ye bas.
	  Elindeki brainrot cantadan cikar, slotta belirir ve saniyelik gelir
	  uretmeye baslar. Dolu bir slota eli bosken E basarsan brainrotu geri alirsin.

	Gelir:
	    lerp(rarity.min, rarity.max, brainrot.incomeFactor)
	        * boyut carpani * mutasyon carpani
	Yani ayni rarity'deki iki brainrot bile farkli kazandirir; boyut
	Tiny(1x) -> Huge(3x) arasinda, mutasyon ise 1x -> 12x arasinda carpar.

	TOPLAMA:
	  Gelir dogrudan Rot'a YAZILMAZ. Base'de birikir; oyuncu base'inin
	  onundeki TOPLA butonunun uzerine basinca birikmis rot hesabina gecer.
	  Yani brainrotu koyar koymaz para gelmez, gidip toplaman gerekir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Bases = require(Shared:WaitForChild("Bases"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Condition = require(Shared:WaitForChild("Condition"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Assets = require(Shared:WaitForChild("Assets"))
local Fonts = require(Shared:WaitForChild("Fonts"))
local Divine = require(Shared:WaitForChild("Divine"))
local Etiket = require(Shared:WaitForChild("Etiket"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Tools = require(Modules:WaitForChild("Tools"))
local Envanter = require(Modules:WaitForChild("Envanter"))
local GorevTakip = require(Modules:WaitForChild("GorevTakip"))

local Bildirim = Net.event("Bildirim")
local BaseGuncelle = Net.event("BaseGuncelle")
local SlotaKoy = Net.event("SlotaKoy")
local SlottanAl = Net.event("SlottanAl")
-- Toplama aninda para destelerinin sacilma efekti (bkz. ParaSacma.client)
local ParaSac = Net.event("ParaSac")

-- [baseIndex] = Player | nil
local owners: { [number]: Player? } = {}
-- [baseIndex][slotIndex] = Model
local slotModels: { [number]: { [number]: Model } } = {}
-- [baseIndex] = henuz toplanmamis rot
local pending: { [number]: number } = {}
-- [baseIndex] = TOPLA butonu parcasi
local collectPads: { [number]: BasePart } = {}
-- [baseIndex] = gelisim tabelasi
local upgradeSigns: { [number]: BasePart } = {}
-- [baseIndex] = toplama beklemesinin bitecegi an (os.clock)
local collectUntil: { [number]: number } = {}

-- [player] = son toplama zamani (kol ve bacak ayni anda saymasin diye)
local lastTouch: { [Player]: number } = {}


-- Slot promptlari ve buton asagida tanimlanan fonksiyonlari cagirir; ileri bildirim
local placeInSlot: (player: Player, uid: string, slotIndex: number) -> ()
local removeFromSlot: (player: Player, uid: string) -> ()
local collectRot: (player: Player, baseIndex: number) -> ()
local updateSign: (baseIndex: number) -> ()
local buyUpgrade: (player: Player, baseIndex: number) -> ()
local pushBase: (player: Player) -> ()
local finishCollectButton: (pad: Part, model: Model, baseIndex: number, cfg: any) -> BasePart

------------------------------------------------------------------
-- WORKSPACE KURULUMU
------------------------------------------------------------------
--[[
	Base'leri tutan klasor.

	Arama Workspace'in TAMAMINDA yapilir (bkz. Bases.findFolder): klasor
	cogu zaman adanin modelinin icinde duruyor. Onceden yalnizca
	Workspace'in dogrudan altina bakiliyordu; bulamayinca da kendisi BOS
	bir klasor olusturuyordu ve oyun "hic base yok" sanip hicbirini
	kurmuyordu -- ada tasininca yasanan tam olarak buydu.

	Gercekten hicbir yerde yoksa yine olusturulur, ama bu sefer Output'a
	uyari duser: sessizce bos kalmasin.
]]
local function basesFolder(): Instance
	local found = Bases.findFolder()
	if found then
		return found
	end

	warn(
		`[Base] Workspace'te "{Bases.FolderName}" klasoru bulunamadi. `
			.. `Bos bir tane olusturuluyor -- base'lerini oraya koy ya da `
			.. `mevcut klasoru bu adla adlandir.`
	)

	local created = Instance.new("Folder")
	created.Name = Bases.FolderName
	created.Parent = Workspace
	return created
end

--[[
	Base'in tamaminin sinir kutusunu verir.

	Zemin parcasini isimle aramak guvenilir degil: slotlarin icinde de
	"Platform" adli parcalar var ve base'ler elle kuruldugu icin isim
	garantisi yok. Butun modelin sinir kutusu her duzende dogru sonuc verir.
]]
local function baseBounds(base: Model): (CFrame?, Vector3?)
	local ok, cf, size = pcall(function()
		return base:GetBoundingBox()
	end)

	if not ok or not cf then
		return nil, nil
	end
	return cf, size
end

--[[
	Sahiplik hologrami.

	Base'in ONUNDE havada duran, zeminsiz buyuk yazi. Tabela/pano yok --
	sadece parlayan metin, uzaktan okunacak kadar buyuk.
	  sahipli -> sahibinin nicki, yesil
	  bos     -> "EMPTY", beyaz
]]
local function buildHologram(model: Model, bounds: CFrame, size: Vector3)
	local existing = model:FindFirstChild("Hologram")
	if existing then
		existing:Destroy()
	end

	local anchor = Instance.new("Part")
	anchor.Name = "Hologram"
	anchor.Size = Vector3.new(1, 1, 1)
	-- Base'in on kenarinin onunde ve tepesinin uzerinde
	anchor.CFrame = bounds * CFrame.new(0, size.Y / 2 + Bases.HologramHeight, -size.Z / 2 - 4)
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Parent = model

	local glow = Instance.new("PointLight")
	glow.Name = "Parilti"
	glow.Color = Color3.fromRGB(255, 255, 255)
	glow.Range = 16
	glow.Brightness = 1.2
	glow.Parent = anchor

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Yazi"
	billboard.Size = UDim2.fromOffset(345, 113)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 1200
	-- Isiktan etkilenmesin: hologram her isikta ayni parlaklikta gorunsun
	billboard.LightInfluence = 0
	billboard.Parent = anchor

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Sahip"
	nameLabel.Size = UDim2.new(1, 0, 0, 72)
	nameLabel.Position = UDim2.fromOffset(0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.FontFace = Fonts.bold
	nameLabel.Text = "EMPTY"
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 51
	nameLabel.TextScaled = false
	nameLabel.TextStrokeTransparency = 1
	-- Hafif saydamlik hologram hissini verir
	nameLabel.TextTransparency = 0.1
	nameLabel.Parent = billboard

	-- Asagi dogru soluklasan hologram gecisi
	local gradient = Instance.new("UIGradient")
	gradient.Name = "Hologram"
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.65, 0.1),
		NumberSequenceKeypoint.new(1, 0.55),
	})
	gradient.Parent = nameLabel

	--[[
		SANIYELIK GETIRI  --  nickin hemen altinda.

		Hologramla ayni BillboardGui'nin icinde oldugu icin tutamak
		yukseldiginde bu da onunla birlikte yukselir. Yazi boyutu nickten
		kucuk ama uzaktan okunacak kadar buyuk; rengi para rengiyle (sari)
		ayni ki oyuncu bunun bir kazanc oldugunu ilk bakista anlasin.
	]]
	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "Gelir"
	incomeLabel.Size = UDim2.new(1, 0, 0, 38)
	incomeLabel.Position = UDim2.fromOffset(0, 74)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = ""
	incomeLabel.TextColor3 = Bases.RotColor
	incomeLabel.TextSize = 32
	incomeLabel.TextScaled = false
	incomeLabel.TextTransparency = 0
	Fonts.apply(incomeLabel)
	incomeLabel.Parent = billboard
end

--[[
	TOPLA butonu.

	Base'in onunde, hologramin altinda duran yassi bir pad. Uzerine basan
	SAHIP, base'de birikmis rotu alir. Baskasi bastiginda hicbir sey olmaz.

	Zemini isinla buluyoruz: base'ler haritada elle kuruldugu icin yukseklikleri
	farkli. Pad, base'in on kenarinin ilerisindeki zemine oturur; altta bir sey
	yoksa base'in alt hizasina konur.
]]
local function buildCollectButton(model: Model, bounds: CFrame, size: Vector3, baseIndex: number): BasePart
	local cfg = Bases.CollectPad

	local existing = model:FindFirstChild("ToplaButonu")
	if existing then
		existing:Destroy()
	end

	--[[
		BUTONUN YERI

		Once haritada elle konulmus bir isaretci aranir:
		    Base1 > ToplaNoktasi  (BasePart)

		Varsa buton TAM ORAYA, o parcanin boyutunda kurulur. Boylece butonu
		Studio'da istedigin yere surukleyip boyutlandirabilirsin; kod hicbir
		sey hesaplamaya calismaz.

		Isaretci yoksa base'in on kenarinin ilerisine kurulur (eski davranis).
	]]
	local marker = model:FindFirstChild(Bases.CollectMarkerName)
	if marker and marker:IsA("BasePart") then
		local pad = Instance.new("Part")
		pad.Name = "ToplaButonu"
		pad.Size = marker.Size
		pad.CFrame = marker.CFrame
		return finishCollectButton(pad, model, baseIndex, cfg)
	end

	local front = bounds * CFrame.new(0, size.Y / 2, -size.Z / 2 - cfg.forward)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model }
	local hit = Workspace:Raycast(front.Position, Vector3.new(0, -(size.Y + 250), 0), params)
	local groundY = if hit then hit.Position.Y else bounds.Position.Y - size.Y / 2

	local pad = Instance.new("Part")
	pad.Name = "ToplaButonu"
	pad.Size = cfg.size
	pad.CFrame = CFrame.new(front.Position.X, groundY + cfg.size.Y / 2 + 0.05, front.Position.Z) * bounds.Rotation
	return finishCollectButton(pad, model, baseIndex, cfg)
end

-- Butonun gorunumu ve dokunma baglantisi (yeri nasil belirlenmis olursa olsun)
function finishCollectButton(pad: Part, model: Model, baseIndex: number, cfg: any): BasePart
	pad.Anchored = true
	-- Uzerine basilabilsin ama takilmasin: carpisma yok, dokunma var
	pad.CanCollide = false
	--[[
		DUZ, DOLGUN RENK

		Once Neon'du. Neon rengi parlatip SOLDURUYOR: kirmizi soluk pembe-beyaz,
		yesil acik yesil gorunuyor, bekleme rengi "gri" sanilacak kadar
		solgundu. SmoothPlastic kirmiziyi kirmizi, yesili yesil gosteriyor --
		diger brainrot oyunlarindaki toplama basamagi gibi.

		Saydamlik ve yansima sifirlaniyor: Studio'da konan isaret parcasi
		(ToplaNoktasi) yari saydamsa alttaki zemin rengi butona karisiyordu.
	]]
	pad.Material = Enum.Material.SmoothPlastic
	pad.Transparency = 0
	pad.Reflectance = 0
	pad.Color = cfg.idleColor
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.BottomSurface = Enum.SurfaceType.Smooth
	pad.Parent = model

	local glow = Instance.new("PointLight")
	glow.Name = "Parilti"
	glow.Color = cfg.color
	glow.Range = 14
	glow.Brightness = 1.4
	glow.Enabled = false
	glow.Parent = pad

	-- Padin ust yuzundeki yazi
	local surface = Instance.new("SurfaceGui")
	surface.Name = "Yuzey"
	surface.Face = Enum.NormalId.Top
	surface.PixelsPerStud = 50
	surface.LightInfluence = 0
	surface.Parent = pad


	-- Uzaktan okunan miktar yazisi
	local sign = Instance.new("BillboardGui")
	sign.Name = "Yazi"
	sign.Size = UDim2.fromOffset(240, 64)
	sign.StudsOffset = Vector3.new(0, 4, 0)
	sign.AlwaysOnTop = false
	sign.MaxDistance = 400
	sign.LightInfluence = 0
	sign.Parent = pad

	local amount = Instance.new("TextLabel")
	amount.Name = "Miktar"
	amount.Size = UDim2.fromScale(1, 1)
	amount.BackgroundTransparency = 1
	amount.FontFace = Fonts.bold
	amount.Text = "EMPTY"
	amount.TextColor3 = cfg.idleColor
	amount.TextSize = 34
	amount.TextScaled = false
	amount.TextStrokeTransparency = 1
	amount.Parent = sign

	pad.Touched:Connect(function(toucher: BasePart)
		local character = toucher.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local now = os.clock()
		if lastTouch[player] and now - lastTouch[player] < cfg.cooldown then
			return
		end
		lastTouch[player] = now

		collectRot(player, baseIndex)
	end)

	return pad
end

------------------------------------------------------------------
-- BASE GELISIMI
------------------------------------------------------------------

-- Oyuncunun acik slot sayisi (veri bozuksa guvenli araliga cekilir)
local function unlockedSlots(data: any): number
	local floors = math.clamp(data.baseFloors or 1, 1, Bases.Upgrade.maxFloors)
	return math.clamp(data.baseSlots or Bases.Upgrade.startingSlots, 0, floors * Bases.Upgrade.slotsPerFloor)
end

--[[
	Siradaki gelistirme.

	Bulunulan kat dolduysa SONRAKI KAT (Rot Coin), dolmadiysa siradaki SLOT
	(Rot) satilir. Tek bir sirada ilerledigi icin tabelada tek buton yetiyor.
	Her sey acilmissa nil doner.
]]
local function nextUpgrade(data: any): { kind: string, cost: number, label: string }?
	local U = Bases.Upgrade
	local floors = math.clamp(data.baseFloors or 1, 1, U.maxFloors)
	local slots = unlockedSlots(data)

	if slots >= floors * U.slotsPerFloor then
		if floors >= U.maxFloors then
			return nil
		end
		return {
			kind = "floor",
			cost = U.floorCost[floors + 1] or 0,
			label = `FLOOR {floors + 1}`,
		}
	end

	return {
		kind = "slot",
		cost = Bases.slotCost(slots),
		label = `SLOT {slots + 1}`,
	}
end

--[[
	SLOT NUMARASI: slot zemininin UST YUZUNDE buyuk numara (1..10).
	Envanterde "Slot 3" yazan brainrotun base'in neresinde durdugu boylece
	bir bakista gorulur.
]]
local function buildSlotNumber(pad: BasePart, slotIndex: number)
	local yuzey = Instance.new("SurfaceGui")
	yuzey.Name = "SlotNumarasi"
	yuzey.Face = Enum.NormalId.Top
	yuzey.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	yuzey.PixelsPerStud = 40
	yuzey.LightInfluence = 0
	yuzey.Parent = pad

	local yazi = Instance.new("TextLabel")
	yazi.Size = UDim2.fromScale(1, 1)
	yazi.BackgroundTransparency = 1
	yazi.Text = tostring(slotIndex)
	yazi.TextScaled = true
	yazi.TextColor3 = Color3.fromRGB(255, 255, 255)
	yazi.TextTransparency = 0.35
	Fonts.apply(yazi)
	yazi.Parent = yuzey

	local sinir = Instance.new("UITextSizeConstraint")
	sinir.MaxTextSize = 120
	sinir.Parent = yazi

	local kontur = Instance.new("UIStroke")
	kontur.Color = Color3.fromRGB(0, 0, 0)
	kontur.Thickness = 3
	kontur.Transparency = 0.4
	kontur.Parent = yazi
end

local function buildSlotPrompt(pad: BasePart, baseIndex: number, slotIndex: number)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SlotPrompt"
	prompt.ActionText = "Slot"
	prompt.ObjectText = `Slot {slotIndex}`
	-- Diger NPC'lerdeki gibi basili tutulur; yanlislikla basmayi onler
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = pad

	prompt.Triggered:Connect(function(player)
		if Bases.OwnerOnlyPlacement and owners[baseIndex] ~= player then
			Bildirim:FireClient(player, "This is not your base!", Color3.fromRGB(255, 120, 120))
			return
		end

		local data = PlayerData.get(player)
		if not data then
			return
		end

		-- Kilitli slota yerlestirilemez; once tabeladan acilmali
		if slotIndex > unlockedSlots(data) then
			Bildirim:FireClient(
				player,
				`Slot {slotIndex} is locked`,
				Color3.fromRGB(255, 200, 90)
			)
			return
		end

		-- Elde brainrot varsa yerlestir
		local _, heldUid = Tools.equippedBrainrot(player)
		if heldUid then
			placeInSlot(player, heldUid, slotIndex)
			return
		end

		-- Eli bossa ve slot doluysa geri al
		for _, item in data.inventory do
			if item.slot == slotIndex then
				removeFromSlot(player, item.uid)
				return
			end
		end

		Bildirim:FireClient(player, "Hold a brainrot to place it.", Color3.fromRGB(255, 200, 90))
	end)
end

--[[
	Slotun uzerine brainrot konulacak zemin parcasini bulur.

	Slotlar haritada elle kurulmustur; script hicbir pad uretmez.
	Desteklenen yerlesimler:
	    Base1 > Slot1                     (Slot dogrudan BasePart)
	    Base1 > Slot1 (Model) > Platform  (Slot bir Model, zemini Platform)
	    Base1 > Slots > Slot1             (klasor icinde, ikisi de olur)
]]
local function resolveSlotSurface(node: Instance?): BasePart?
	if not node then
		return nil
	end

	if node:IsA("BasePart") then
		return node
	end

	if node:IsA("Model") then
		-- Slot bir Model ise uzerine konulacak zemin parcasi aranir
		local platform = node:FindFirstChild("Platform")
		if platform and platform:IsA("BasePart") then
			return platform
		end
		if node.PrimaryPart then
			return node.PrimaryPart
		end
		return node:FindFirstChildWhichIsA("BasePart", true)
	end

	return nil
end

local function findSlotPart(base: Model, slotIndex: number): BasePart?
	local name = Bases.slotName(slotIndex)

	local direct = resolveSlotSurface(base:FindFirstChild(name))
	if direct then
		return direct
	end

	local folder = base:FindFirstChild("Slots")
	if folder then
		local inFolder = resolveSlotSurface(folder:FindFirstChild(name))
		if inFolder then
			return inFolder
		end
	end

	-- Ic ice modellerde de ara (son care)
	return resolveSlotSurface(base:FindFirstChild(name, true))
end

--[[
	Base indekslerini gercek modellere baglar.

	Once "Base1".."Base6" adli modeller aranir. Isimlendirmemis olanlar icin
	klasordeki diger modeller ada gore siralanip sirayla atanir -- boylece
	modelleri Bases klasorune atmak yeterli olur, isim sart degildir.
]]
local baseModels: { [number]: Model } = {}

local function mapBases()
	local folder = basesFolder()
	table.clear(baseModels)

	for index = 1, Bases.Count do
		local named = folder:FindFirstChild(Bases.baseName(index))
		if named and named:IsA("Model") then
			baseModels[index] = named
		end
	end

	local leftovers: { Model } = {}
	for _, child in folder:GetChildren() do
		if child:IsA("Model") then
			local claimed = false
			for _, taken in baseModels do
				if taken == child then
					claimed = true
					break
				end
			end
			if not claimed then
				table.insert(leftovers, child)
			end
		end
	end

	table.sort(leftovers, function(a, b)
		return a.Name < b.Name
	end)

	local cursor = 1
	for index = 1, Bases.Count do
		if not baseModels[index] and leftovers[cursor] then
			baseModels[index] = leftovers[cursor]
			cursor += 1
		end
	end
end

local function getBase(index: number): Model?
	return baseModels[index]
end

local function getSlotPart(baseIndex: number, slotIndex: number): BasePart?
	local base = getBase(baseIndex)
	return if base then findSlotPart(base, slotIndex) else nil
end

--[[
	Kilitli katlari gizler, acilanlari gosterir.

	Parcalarin ozgun saydamligi ilk gizlemede nitelige yazilir; acilinca oradan
	geri yuklenir. Boylece haritada bilerek yariseffaf yapilmis parcalar
	acildiginda opak hale gelmez.
]]
--[[
	GORUNURLUK -- TEK KAYNAK

	Hem kat hem slot gizleme ayni parcalara dokunuyor. Ikisi ayri ayri
	"ozgun saydamlik" kaydetseydi sunlar olurdu: kat gizlenince saydamlik 1
	olur, sonra slot sistemi 1'i "ozgun" diye kaydeder, slot satin alininca
	1'e geri doner ve pad hic gorunmez. (Slot 11'in kayip olmasinin sebebi
	tam olarak buydu.)

	Bu yuzden ozgun deger TEK bir nitelige, ilk dokunusta yaziliyor; iki
	sistem de oradan okuyor.
]]
local function setVisible(node: Instance, visible: boolean)
	if node:IsA("BasePart") then
		if node:GetAttribute("OzgunSaydamlik") == nil then
			node:SetAttribute("OzgunSaydamlik", node.Transparency)
			node:SetAttribute("OzgunCarpisma", node.CanCollide)
		end

		if visible then
			local saved = node:GetAttribute("OzgunSaydamlik")
			node.Transparency = if typeof(saved) == "number" then saved else 0
			node.CanCollide = node:GetAttribute("OzgunCarpisma") ~= false
		else
			node.Transparency = 1
			node.CanCollide = false
		end
	elseif node:IsA("ProximityPrompt") then
		node.Enabled = visible
	end
end

local function applyFloors(baseIndex: number, floors: number)
	local base = getBase(baseIndex)
	if not base then
		return
	end

	for floorIndex = 2, Bases.Upgrade.maxFloors do
		local model = base:FindFirstChild(Bases.floorModelName(floorIndex))
		if not model then
			continue
		end

		local visible = floorIndex <= floors

		for _, node in model:GetDescendants() do
			setVisible(node, visible)
		end
	end
end

--[[
	Base'leri oyuna hazirlar.

	Haritadaki yapiya dokunulmaz: hicbir platform, slot padi ya da parca
	uretilmez. Yalnizca mevcut Slot parcalarina prompt ve base'in onune
	hologram yazi eklenir.
]]
--[[
	SLOT GORUNURLUGU  --  SAKLAYARAK

	1. kattaki 10 slot her zaman aciktir. Ustundeki katlarda YALNIZCA satin
	alinmis slotlar durur.

	Once saydamlik 1 yapiliyordu ama bu yetmiyor: parcanin uzerindeki kaplama,
	yazi, isik ve partikuller gorunmeye devam ediyor, slot "yarim" gorunuyordu.
	Artik kilitli slot Workspace'ten TAMAMEN cikarilip ServerStorage'da
	bekletiliyor; satin alininca ayni ebeveynine geri konuyor. Konumu
	degismiyor, cunku Parent degistirmek CFrame'i etkilemez.
]]
local slotStore: Folder? = nil

local function stashFolder(): Folder
	if slotStore and slotStore.Parent then
		return slotStore
	end

	local existing = ServerStorage:FindFirstChild("KilitliSlotlar")
	if existing and existing:IsA("Folder") then
		slotStore = existing
		return existing
	end

	local created = Instance.new("Folder")
	created.Name = "KilitliSlotlar"
	created.Parent = ServerStorage
	slotStore = created
	return created
end

-- [baseIndex][slotIndex] = { node = saklanan slot, parent = eski ebeveyni }
local stashed: { [number]: { [number]: { node: Instance, parent: Instance } } } = {}

--[[
	Slotun KENDISI (Model ya da Part) -- uzerine model konulan yuzey parcasi
	degil. Saklarken slotun tamamini almamiz gerekiyor.
]]
local function slotNode(baseIndex: number, slotIndex: number): Instance?
	local base = getBase(baseIndex)
	if not base then
		return nil
	end

	local name = Bases.slotName(slotIndex)

	local direct = base:FindFirstChild(name)
	if direct then
		return direct
	end

	local folder = base:FindFirstChild("Slots")
	if folder then
		local inFolder = folder:FindFirstChild(name)
		if inFolder then
			return inFolder
		end
	end

	return base:FindFirstChild(name, true)
end

local function setSlotVisible(baseIndex: number, slotIndex: number, visible: boolean)
	stashed[baseIndex] = stashed[baseIndex] or {}
	local store = stashed[baseIndex]

	if visible then
		local saved = store[slotIndex]
		if saved then
			if saved.node.Parent ~= saved.parent and saved.parent.Parent then
				saved.node.Parent = saved.parent
			end

			--[[
				Slot yerine kondu ama gorunumu de geri verilmeli.

				Kurulumda once applyFloors katin BUTUN parcalarini saydam
				yapiyor, hemen ardindan applySlots slotlari saklamaya
				kaldiriyor -- yani slot saydam halde ayriliyor. Kat sonradan
				acildiginda applyFloors o slota ulasamiyor (artik katin icinde
				degil), dolayisiyla slot yerine dondugunde saydam kaliyordu ve
				hicbir sey gorunmuyordu.
			]]
			local nodes: { Instance } = saved.node:GetDescendants()
			table.insert(nodes, saved.node)
			for _, child in nodes do
				setVisible(child, true)
			end

			store[slotIndex] = nil
		end
		return
	end

	-- Zaten saklanmissa tekrar arama
	if store[slotIndex] then
		return
	end

	local node = slotNode(baseIndex, slotIndex)
	local parent = node and node.Parent
	if not node or not parent then
		return
	end

	store[slotIndex] = { node = node, parent = parent }
	node.Parent = stashFolder()
end

local function applySlots(baseIndex: number, unlocked: number)
	for slotIndex = Bases.Upgrade.startingSlots + 1, Bases.SlotCount do
		setSlotVisible(baseIndex, slotIndex, slotIndex <= unlocked)
	end
end

--[[
	KAT YUKSELME ANIMASYONU

	Satin alinan kat riseHeight kadar asagida belirip yerine oturur.

	Model:PivotTo MODELIN TAMAMINI birlikte tasir; slot padleri, promptlar ve
	yeni acilan slot da beraber gelir. (Kaldirilan slot animasyonu boyle
	degildi: slotun yalnizca yuzey parcasini tasiyor, Model olan slotlarin
	gerisini yerinde birakiyordu. Sorun ondan cikmisti, bu fonksiyondan degil.)

	Animasyon SIRASI onemli: once kat gorunur yapilir, sonra hediye slot
	yerine konur, EN SON yukselir. Slot once yerine konmazsa kat yukselirken
	geride kalir.
]]
local rising: { [Model]: boolean } = {}

local function riseFloor(baseIndex: number, floorIndex: number)
	local base = getBase(baseIndex)
	local model = base and base:FindFirstChild(Bases.floorModelName(floorIndex))
	if not model or not model:IsA("Model") or rising[model] then
		return
	end

	local U = Bases.Upgrade
	local home = model:GetPivot()
	local start = home.Position - Vector3.new(0, U.riseHeight, 0)

	rising[model] = true
	model:PivotTo(CFrame.new(start) * home.Rotation)

	task.spawn(function()
		local elapsed = 0
		while elapsed < U.riseTime and model.Parent do
			elapsed += task.wait()
			local alpha = math.clamp(elapsed / U.riseTime, 0, 1)
			-- Kubik yavaslama: hizli baslar, yerine yumusak oturur
			local eased = 1 - (1 - alpha) ^ 3
			model:PivotTo(CFrame.new(start:Lerp(home.Position, eased)) * home.Rotation)
		end

		-- Yarida kesilse bile tam yerine otursun
		if model.Parent then
			model:PivotTo(home)
		end
		rising[model] = nil
	end)
end

--[[
	GELISIM TABELASI

	Base'in icine TabelaNoktasi adinda bir Part koyduysan yazi DOGRUDAN O
	PARCANIN uzerine cizilir: konumu, boyutu ve acisi tamamen senin elinde,
	kod parcayi ne tasir ne de boyutunu degistirir.

	Yazi parcanin HER IKI yuzune de konur; boylece parcayi hangi yone
	cevirirsen cevir okunur, ters kalma diye bir sey olmaz.

	TabelaNoktasi yoksa base'in onune kod kendi panosunu kurar.
]]
local function buildSignFace(board: BasePart, face: Enum.NormalId)
	local sign = Instance.new("SurfaceGui")
	sign.Name = "Yazi"
	sign.Face = face
	sign.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sign.PixelsPerStud = 50
	sign.LightInfluence = 0
	sign.Parent = board

	--[[
		Panel: ustten alta gecisli mavi zemin, altin cerceve, yuvarlak kose.
		Duz siyah zemin sonik gorunuyordu; renkler Bases.Upgrade icinde.
	]]
	local U = Bases.Upgrade

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Zemin"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = U.panelBottom
	backdrop.BackgroundTransparency = 0
	backdrop.BorderSizePixel = 0
	backdrop.Parent = sign

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(U.panelTop, U.panelBottom)
	gradient.Parent = backdrop

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.06, 0)
	corner.Parent = backdrop

	local border = Instance.new("UIStroke")
	border.Color = U.panelBorder
	border.Thickness = 5
	border.Parent = backdrop

	local function line(name: string, height: number, y: number, color: Color3): TextLabel
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = UDim2.new(0.92, 0, height, 0)
		label.Position = UDim2.new(0.04, 0, y, 0)
		label.BackgroundTransparency = 1
		label.Text = ""
		label.TextColor3 = color
		label.TextScaled = true
		label.Parent = sign
		Fonts.apply(label)
		return label
	end

	line("Baslik", 0.18, 0.03, Color3.fromRGB(255, 255, 255)).Text = "BASE UPGRADES"
	line("Durum", 0.16, 0.25, Color3.fromRGB(186, 218, 255))
	line("Sonraki", 0.17, 0.45, Color3.fromRGB(255, 214, 41))
	line("Fiyat", 0.30, 0.66, Color3.fromRGB(140, 230, 160))
end

local function buildUpgradeSign(base: Model, bounds: CFrame, size: Vector3, baseIndex: number): BasePart
	local U = Bases.Upgrade

	--[[
		Isaretci once dogrudan base'in altinda, bulunamazsa ic ice modellerde,
		son care olarak harf duyarsiz aranir.
	]]
	local marker: Instance? = base:FindFirstChild(U.markerName)
		or base:FindFirstChild(U.markerName, true)

	if not marker then
		local wanted = string.lower(U.markerName)
		for _, node in base:GetDescendants() do
			if node:IsA("BasePart") and string.lower(node.Name) == wanted then
				marker = node
				break
			end
		end
	end

	local board: BasePart

	if marker and marker:IsA("BasePart") then
		-- SENIN parcan tabela olur: konumuna, boyutuna, acisina dokunulmaz
		board = marker

		-- Onceki oturumdan kalan yazi ve prompt temizlenir (parca korunur)
		for _, child in board:GetChildren() do
			if child:IsA("SurfaceGui") or child:IsA("ProximityPrompt") then
				child:Destroy()
			end
		end

		print(`[Base] {base.Name}: tabela '{board.Name}' parcasinin uzerine yazildi`)
	else
		local old = base:FindFirstChild("GelisimTabelasi")
		if old then
			old:Destroy()
		end

		local created = Instance.new("Part")
		created.Name = "GelisimTabelasi"
		created.Anchored = true
		created.CanCollide = false
		created.Material = Enum.Material.SmoothPlastic
		created.Color = U.color
		created.TopSurface = Enum.SurfaceType.Smooth
		created.BottomSurface = Enum.SurfaceType.Smooth
		created.Size = U.size

		local front = bounds * CFrame.new(0, 0, size.Z / 2 + U.forward)
		created.CFrame = CFrame.new(
			front.Position.X,
			bounds.Position.Y - size.Y / 2 + U.size.Y / 2 + 1,
			front.Position.Z
		) * bounds.Rotation

		created.Parent = base
		board = created

		warn(`[Base] {base.Name}: '{U.markerName}' adinda Part yok, tabela base'in onune kuruldu`)
	end

	--[[
		Yazi TEK bir yuze konur: parcanin en genis yuzlerinden, base'e SIRTINI
		donen yani oyuncunun geldigi tarafa bakan yuz.

		Iki yuze birden yazildiginda arka taraftan yazi ayna gibi ters
		gorunuyordu. Hangi yuzun genis oldugu parcanin bicimine gore degisir:
		yere yatik plakada Ust, ayakta duran panoda On ya da Arka.
	]]
	local boardSize = board.Size
	local away = board.Position - bounds.Position
	local face: Enum.NormalId

	-- flipFace true ise secilen yuzun tam karsisi kullanilir
	local flip = U.flipFace == true

	if boardSize.Y <= boardSize.X and boardSize.Y <= boardSize.Z then
		face = if flip then Enum.NormalId.Bottom else Enum.NormalId.Top
	elseif boardSize.Z <= boardSize.X then
		-- LookVector parcanin On yuzunun baktigi yon
		local frontSide = board.CFrame.LookVector:Dot(away) >= 0
		if flip then
			frontSide = not frontSide
		end
		face = if frontSide then Enum.NormalId.Front else Enum.NormalId.Back
	else
		local rightSide = board.CFrame.RightVector:Dot(away) >= 0
		if flip then
			rightSide = not rightSide
		end
		face = if rightSide then Enum.NormalId.Right else Enum.NormalId.Left
	end

	buildSignFace(board, face)

	--[[
		Parcanin kendisi tabela rengine boyanir ve icinden gecilebilir yapilir:
		yazinin olmadigi yuzler beyaz kaliyordu ve oyuncu panoya carpiyordu.
	]]
	board.Color = U.color
	board.Material = Enum.Material.SmoothPlastic
	board.CanCollide = false

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GelistirPrompt"
	prompt.ActionText = "Upgrade"
	prompt.ObjectText = "Base"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = board

	prompt.Triggered:Connect(function(player)
		buyUpgrade(player, baseIndex)
	end)

	return board
end

--[[
	Tabeladaki yazilari tazeler.
	Parcanin iki yuzunde de yazi oldugu icin ikisi birden guncellenir.
]]
function updateSign(baseIndex: number)
	local board = upgradeSigns[baseIndex]
	if not board then
		return
	end

	local owner = owners[baseIndex]
	local data = if owner then PlayerData.get(owner) else nil

	local durumText, sonrakiText, fiyatText

	if not data then
		durumText, sonrakiText, fiyatText = "Unclaimed base", "", ""
	else
		local floors = math.clamp(data.baseFloors or 1, 1, Bases.Upgrade.maxFloors)
		local slots = unlockedSlots(data)
		durumText = `Floor {floors}/{Bases.Upgrade.maxFloors}   Slot {slots}/{Bases.SlotCount}`

		local up = nextUpgrade(data)
		if up then
			sonrakiText = up.label
			fiyatText = `{Format.short(up.cost)} ROT`
		else
			sonrakiText = ""
			fiyatText = "FULLY UPGRADED"
		end
	end

	for _, sign in board:GetChildren() do
		if not sign:IsA("SurfaceGui") then
			continue
		end

		local durum = sign:FindFirstChild("Durum")
		local sonraki = sign:FindFirstChild("Sonraki")
		local fiyat = sign:FindFirstChild("Fiyat")

		if durum and durum:IsA("TextLabel") then
			durum.Text = durumText
		end
		if sonraki and sonraki:IsA("TextLabel") then
			sonraki.Text = sonrakiText
		end
		if fiyat and fiyat:IsA("TextLabel") then
			fiyat.Text = fiyatText
		end
	end
end

--[[
	Siradaki gelistirmeyi satin alir.
	Kat acmak Rot Coin, slot acmak Rot ister.
]]
function buyUpgrade(player: Player, baseIndex: number)
	if owners[baseIndex] ~= player then
		Bildirim:FireClient(player, "This is not your base!", Color3.fromRGB(255, 120, 120))
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local up = nextUpgrade(data)
	if not up then
		Bildirim:FireClient(player, "Base is already fully upgraded (3 floors / 30 slots).", Color3.fromRGB(180, 200, 220))
		return
	end

	-- Kat da slot da Rot ile alinir
	if data.rot < up.cost then
		Bildirim:FireClient(
			player,
			`Not enough Rot! {up.label} costs {Format.short(up.cost)} Rot.`,
			Color3.fromRGB(255, 120, 120)
		)
		return
	end

	PlayerData.addRot(player, -up.cost)

	if up.kind == "floor" then
		data.baseFloors = math.clamp((data.baseFloors or 1) + 1, 1, Bases.Upgrade.maxFloors)
		data.baseSlots = math.clamp(
			unlockedSlots(data) + Bases.Upgrade.slotsWithFloor,
			0,
			Bases.SlotCount
		)

		--[[
			HARITA GEOMETRISI TASINMIYOR.

			Once kat ve yeni slot asagidan yukari kayarak geliyordu. Slotun
			yalnizca YUZEY parcasi tasindigi icin, slot birden fazla parcadan
			olusan bir Model ise gerisi yerinde kaliyor ve plakalar dagilmis
			gorunuyordu. Artik sadece gorunurluk aciliyor: parcalar haritada
			nasil kuruldularsa oyle kaliyorlar.
		]]
		applyFloors(baseIndex, data.baseFloors)

		-- Katla birlikte yalnizca hediye slot gorunur, digerleri kilitli kalir
		applySlots(baseIndex, unlockedSlots(data))

		-- Slot yerine kondu, artik kat tumuyle yukselebilir
		riseFloor(baseIndex, data.baseFloors)

		Bildirim:FireClient(player, `{up.label} unlocked! New slot added.`, Color3.fromRGB(140, 230, 160))
	else
		data.baseSlots = math.clamp(unlockedSlots(data) + 1, 0, Bases.SlotCount)

		applySlots(baseIndex, unlockedSlots(data))

		Bildirim:FireClient(player, `{up.label} unlocked!`, Color3.fromRGB(140, 230, 160))
	end

	updateSign(baseIndex)
	Envanter.push(player)
	pushBase(player)
end

local function setupBases()
	mapBases()

	for index = 1, Bases.Count do
		slotModels[index] = slotModels[index] or {}

		local base = getBase(index)
		if not base then
			warn(`[Base] {Bases.baseName(index)} bulunamadi -- Workspace > Bases altinda olmali`)
			continue
		end

		-- Onceki surumun biraktigi tabela nesnesi varsa temizle.
		-- Sadece bizim urettigimiz olani sil: icinde "Tabela" BillboardGui olan.
		local oldSign = base:FindFirstChild("Sign")
		if oldSign and oldSign:FindFirstChild("Tabela") then
			oldSign:Destroy()
		end

		-- Eski hologram ve buton sinir kutusuna dahil olup konumu kaydirmasin
		local oldHologram = base:FindFirstChild("Hologram")
		if oldHologram then
			oldHologram:Destroy()
		end

		local oldButton = base:FindFirstChild("ToplaButonu")
		if oldButton then
			oldButton:Destroy()
		end
		collectPads[index] = nil

		--[[
			STREAMING: base HER OYUNCUYA HER ZAMAN gonderilir. Uzak bir base'in
			para toplama butonu (renk: kirmizi bekleme / yesil hazir) bazi
			oyuncularda hic gelmiyor ya da gec geliyordu.
		]]
		if base:IsA("Model") then
			base.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		end

		local oldSign = base:FindFirstChild("GelisimTabelasi")
		if oldSign then
			oldSign:Destroy()
		end
		upgradeSigns[index] = nil

		local bounds, size = baseBounds(base)
		if bounds and size then
			buildHologram(base, bounds, size)
			collectPads[index] = buildCollectButton(base, bounds, size, index)
			upgradeSigns[index] = buildUpgradeSign(base, bounds, size, index)
		else
			warn(`[Base] {base.Name}: sinir kutusu hesaplanamadi, hologram konulamadi`)
		end

		local found = 0
		for slotIndex = 1, Bases.SlotCount do
			local pad = getSlotPart(index, slotIndex)
			if not pad then
				continue
			end
			found += 1
			if not pad:FindFirstChild("SlotPrompt") then
				buildSlotPrompt(pad, index, slotIndex)
			end
			if not pad:FindFirstChild("SlotNumarasi") then
				buildSlotNumber(pad, slotIndex)
			end
		end

		if found < Bases.SlotCount then
			local eksik: { string } = {}
			for slotIndex = 1, Bases.SlotCount do
				if not getSlotPart(index, slotIndex) then
					table.insert(eksik, Bases.slotName(slotIndex))
				end
			end
			warn(
				`[Base] {base.Name}: {found}/{Bases.SlotCount} slot bulundu. `
					.. `BULUNAMAYANLAR: {table.concat(eksik, ", ")}`
			)
		else
			print(`[Base] {index} -> {base.Name} hazir ({found} slot)`)
		end

		-- Sahipsiz base tek katli gorunur; ustu sahibi acinca belirir
		applyFloors(index, 1)
		applySlots(index, Bases.Upgrade.startingSlots)
		updateSign(index)

	end
end

setupBases()

------------------------------------------------------------------
-- SLOTTAKI GORSEL BRAINROT
------------------------------------------------------------------
local function buildDisplay(item: any): Model
	-- Yalnizca yedek kutunun rengi ve efekt temizligi icin; yazilar
	-- Shared > Etiket'ten geliyor
	local rarityInfo = Rarity.get(item.rarity)
	local mutationInfo = Mutations.get(item.mutation)
	local special = Mutations.isSpecial(item.mutation)

	-- Model arama tek yerden: ReplicatedStorage > Assets > Brainrots
	-- Mutasyonluysa once "Gold ..." surumu aranir
	local source = Assets.brainrotModel(item.name, item.mutation)

	local model: Model
	if source then
		model = source
		if not model.PrimaryPart then
			model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
		end
	else
		model = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name = "Govde"
		body.Size = Vector3.new(3, 3, 3)
		body.Color = if special then mutationInfo.color else rarityInfo.color
		body.Material = Enum.Material.Neon
		body.TopSurface = Enum.SurfaceType.Smooth
		body.BottomSurface = Enum.SurfaceType.Smooth
		body.Parent = model
		model.PrimaryPart = body
	end

	model.Name = item.name

	--[[
		BOYUT

		Model once ORTAK TABANA indirilir (Assets.BrainrotSize.slotSize),
		boyut sinifi (Tiny 0.25 .. Huge 2) ondan sonra uygulanir. Boylece
		pakette 3 studluk da 120 studluk da export edilmis olsa iki Huge
		brainrot ayni buyuklukte durur.

		Onceden dogrudan ScaleTo(scale) cagriliyordu ve buyuk export edilmis
		modeller (Bananita Dolphinita, Orcalero Orcala) haritayi kapatacak
		kadar devlesiyordu.

		KADEME OLCEGI
		Divine sonrasi kademeler boardda IKI KAT buyuk duruyor
		(Rarity.modelScale); Cosmic sonrasinda boyut sinifi tabani da
		yukseliyor -- Tiny artik Regular kadar (Condition.scaleFor).
	]]
	local boyutOlcegi = Condition.scaleFor(item.condition, rarityInfo.order)
		* Rarity.modelScale(item.rarity)

	Assets.fitModel(model, Assets.BrainrotSize.slotSize, boyutOlcegi)

	--[[
		Mutasyonsuz brainrotta gorsel efekt yok.
		Paket modellerinin bazilarinda gomulu parcacik/isik efektleri var;
		bunlar mutasyonu belli etmek icin anlamli, duz brainrotta gurultu.
	]]
	if not special then
		-- Tek kaynak: Tools icindeki ortak temizlik (parcacik, iz, isik ve
		-- adiyla belli olan susleme parcalari)
		Tools.stripEffects(model)
	end

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	local primary = model.PrimaryPart
	if not primary then
		return model
	end

	--[[
		ETIKET
		Yazi modelin TEPESININ uzerinde durur. Sabit offset kullanilirsa
		Huge brainrotlarda yazi modelin icinde kaliyordu; bu yuzden
		yukseklik modelin gercek boyundan hesaplanir.
	]]
	--[[
		ETIKET TUTAMAGI

		Etiket onceden PrimaryPart'a baglaniyordu ve yuksekligi ona gore
		hesaplaniyordu. PrimaryPart modelin neresinde olursa olsun (bazi
		paket modellerinde govdenin ortasinda, bazilarinda ayaginda) yazi
		modelin icinde kalabiliyordu.

		Artik etiketin kendi gorunmez tutamagi var; showInSlot onu modelin
		GERCEK tepe noktasinin uzerine koyuyor. Boylece yazi modelin
		bicimine ve boyutuna bakmaksizin hep ustte duruyor.
	]]
	local labelAnchor = Instance.new("Part")
	labelAnchor.Name = "EtiketTutamagi"
	labelAnchor.Size = Vector3.one
	labelAnchor.Transparency = 1
	labelAnchor.Anchored = true
	labelAnchor.CanCollide = false
	labelAnchor.CanQuery = false
	labelAnchor.CanTouch = false
	labelAnchor.Massless = true
	labelAnchor.CFrame = primary.CFrame
	-- Gorunmez tutamak modelin olcusune ve merkezine karismasin
	labelAnchor:SetAttribute(Assets.MeasureSkipAttribute, true)
	labelAnchor.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = primary
	weld.Part1 = labelAnchor
	weld.Parent = labelAnchor

	--[[
		Etiket Shared > Etiket'ten geliyor: ELDE TASINAN brainrot da ayni
		modulu kullaniyor, boylece iki yerde gorunen sey birebir ayni.
	]]
	Etiket.build(item, labelAnchor)

	return model
end

local function clearSlotModel(baseIndex: number, slotIndex: number)
	local models = slotModels[baseIndex]
	if not models then
		return
	end
	local model = models[slotIndex]
	if model and model.Parent then
		model:Destroy()
	end
	models[slotIndex] = nil
end

--[[
	Slotun GERCEK ust yuzeyi.

	pad.Position.Y + Size.Y / 2 her zaman dogru sonuc vermiyor:
	  - parca donmusse Size.Y dikey kalinlik degildir
	  - plaka zemine GOMULUYSE gorunen yuzey zeminin kendisidir

	Ikisi de hesaplanip YUKSEK olani kullanilir. Isina oyuncular ve daha once
	yerlestirilmis brainrotlar dahil edilmez; yoksa slotun uzerinde duran
	birinin kafasina model konurdu.
]]
local function slotSurfaceY(pad: BasePart): number
	local cf = pad.CFrame
	local size = pad.Size

	-- Donmus bir kutunun gercek dikey yarim yuksekligi
	local halfHeight = math.abs(cf.RightVector.Y) * size.X / 2
		+ math.abs(cf.UpVector.Y) * size.Y / 2
		+ math.abs(cf.LookVector.Y) * size.Z / 2

	local top = pad.Position.Y + halfHeight

	local ignore: { Instance } = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	for _, models in slotModels do
		for _, placed in models do
			table.insert(ignore, placed)
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore

	local hit = Workspace:Raycast(
		Vector3.new(pad.Position.X, top + 4, pad.Position.Z),
		Vector3.new(0, -8, 0),
		params
	)

	--[[
		Yuzey yalnizca AZ bir miktar yukselebilir (en fazla 2 stud).
		Genis bir isin base'in ustundeki bir catiyi ya da koprulu bir yapiyi
		yakalayip modeli oraya koyabilirdi; bu sinir onu engelliyor.
	]]
	if hit and hit.Position.Y > top and hit.Position.Y - top <= 2 then
		return hit.Position.Y
	end

	return top
end

--[[
	SLOT SESI

	Koyma, alma ve takasta calar. Kaynak slotun kendi parcasi; o yoksa
	toplama padi kullanilir, boylece ses yine base'in yaninda duyulur.
]]
local function playSlotSound(baseIndex: number, slotIndex: number?)
	local part = (if slotIndex then getSlotPart(baseIndex, slotIndex) else nil) or collectPads[baseIndex]
	if part then
		Assets.playSoundAt(Bases.SlotSound, part)
	end
end

local function showInSlot(baseIndex: number, slotIndex: number, item: any)
	clearSlotModel(baseIndex, slotIndex)

	local pad = getSlotPart(baseIndex, slotIndex)
	if not pad then
		return
	end

	local model = buildDisplay(item)
	local D = Bases.Display

	--[[
		YERLESIM

		1) Modelin kendi durusu korunur, uzerine Bases.Display.rotation
		   duzeltmesi uygulanir. Paketteki modellerin hepsi kimlik donusuyle
		   kayitli; mesh'in kendi ekseni tersse duzeltme oradan yapilir.

		2) Model, SINIR KUTUSUNUN ALTI padin ust yuzeyine gelecek sekilde
		   oturur. Onceki kod modelin PIVOTUNU hedefe koyuyordu; pivot kutu
		   merkezinde degilse model zemine gomuluyor ya da havada kaliyordu.

		3) Donme, modelin MERKEZINDEN gecen dikey eksende olur. Onceki kod
		   pivot etrafinda donduruyordu: uzun modeller (10 studluk
		   kopekbaligi) donerken padin disina savruluyordu.
	]]
	local correction = CFrame.Angles(math.rad(D.rotation.X), math.rad(D.rotation.Y), math.rad(D.rotation.Z))

	-- Once donus: konum simdilik onemsiz, asagida hesaplanacak
	local pivot = model:GetPivot()
	model:PivotTo(CFrame.new(pivot.Position) * correction * pivot.Rotation)

	--[[
		Sonra konum: model GORSEL MERKEZINDEN padin ustune oturur.

		Onceki kod modelin PIVOTUNU padin merkezine koyuyordu. Paket
		modellerinin cogunda pivot govdenin ortasinda degil -- dort ayakli
		bir brainrotta on ayagin dibinde, uzun bir modelde burnunda olabilir.
		O yuzden model padin ortasinda durmuyor ve donerken kendi ekseni
		yerine ayaginin etrafinda donuyordu; Huge boyutta bu apacik
		gorunuyordu.

		Artik butun parcalarin dunya uzayindaki sinir kutusu hesaplaniyor ve
		o kutunun YATAY MERKEZI pada, ALTI da yuzeye hizalaniyor. Donme
		ekseni de ayni merkezden geciyor (asagidaki SpinPivot), yani model
		her boyutta simetrik donuyor.
	]]
	local min, max = Assets.worldBounds(model)

	if not min or not max then
		-- Hic parca yoksa yerlestirilecek bir sey de yok
		model:Destroy()
		return
	end

	local lowest = min.Y
	local highest = max.Y
	local centerX = (min.X + max.X) / 2
	local centerZ = (min.Z + max.Z) / 2

	local surfaceY = slotSurfaceY(pad)

	-- Merkez pada, alt yuzeye gelsin diye modelin tamamini oteleyecek fark
	local shift = Vector3.new(
		pad.Position.X - centerX,
		(surfaceY + D.gap) - lowest,
		pad.Position.Z - centerZ
	)

	model:PivotTo(model:GetPivot() + shift)

	--[[
		Etiket tutamagi modelin GERCEK tepesinin uzerine oturur.
		highest tasimadan ONCE olculdugu icin ayni oteleme ona da uygulanir;
		boylece model ne kadar buyurse buyusun yazi hep tepenin 2.5 stud
		uzerinde kalir.
	]]
	local anchor = model:FindFirstChild("EtiketTutamagi")
	if anchor and anchor:IsA("BasePart") then
		anchor.CFrame = CFrame.new(pad.Position.X, highest + shift.Y + 2.5, pad.Position.Z)
	end

	model.Parent = pad

	slotModels[baseIndex] = slotModels[baseIndex] or {}
	slotModels[baseIndex][slotIndex] = model

	-- Yerlesmis hali: donme ve suzulme bunun uzerine uygulanir
	local home = model:GetPivot()

	--[[
		DONME / SUZULME  --  ISTEMCI TARAFINDA

		Onceden donme burada, sunucuda yapiliyordu. Sunucu tarafindaki
		hareket istemciye saniyede ~20 kez replike edilir; kac kez
		PivotTo cagrilirsa cagrilsin oyuncu 20 fps'lik takilma gorur.
		Sorunun sebebi dongunun hizi degil, replikasyonun kendisiydi.

		Cozum: sunucu modeli yerlestirip birakir, donmeyi her oyuncunun
		kendi makinesi cizer (StarterPlayerScripts > BaseGorsel).
		Asagidaki ozellikler o script'in ihtiyaci olan her seyi tasir.
	]]
	model:SetAttribute("SpinDisplay", true)
	-- Istemci mutasyon efektini (ornegin Rainbow renk dongusu) buna gore cizer
	model:SetAttribute("Mutation", item.mutation or "Normal")
	model:SetAttribute("SpinHome", home)
	--[[
		Donme ekseni modelin GORSEL merkezinden gecer -- yukarida sinir
		kutusunun yatay merkezini pada hizaladigimiz icin bu, padin
		merkezidir. Pivotun nerede oldugunun onemi yok; model artik her
		zaman kendi ortasindan doner.
	]]
	model:SetAttribute("SpinPivot", CFrame.new(pad.Position.X, surfaceY, pad.Position.Z))
	model:SetAttribute("SpinEnabled", D.spin)
	model:SetAttribute("SpinSpeed", D.spinSpeed)
	model:SetAttribute("BobHeight", D.bobHeight)
	model:SetAttribute("BobSpeed", D.bobSpeed)
end

------------------------------------------------------------------
-- BASE ATAMA
------------------------------------------------------------------
local function totalIncome(player: Player): number
	local total = 0
	for _, item in PlayerData.placedItems(player) do
		if item.revealed and item.name then
			total += Brainrots.income(item.name, item.condition :: any, item.mutation :: any)
		end
	end
	return total
end

local OWNED_COLOR = Color3.fromRGB(90, 235, 130)
local EMPTY_COLOR = Color3.fromRGB(255, 255, 255)

--[[
	Base'in onundeki hologram yazisini gunceller.
	  sahipli -> sahibinin nicki, yesil
	  bos     -> "EMPTY", beyaz
]]
local function setSignText(baseIndex: number, ownerName: string?, income: number)
	local base = getBase(baseIndex)
	local anchor = base and base:FindFirstChild("Hologram")
	local billboard = anchor and anchor:FindFirstChild("Yazi")
	if not billboard then
		return
	end

	local color = if ownerName then OWNED_COLOR else EMPTY_COLOR

	local nameLabel = billboard:FindFirstChild("Sahip")
	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.Text = if ownerName then string.upper(ownerName) else "EMPTY"
		nameLabel.TextColor3 = color
	end

	local incomeLabel = billboard:FindFirstChild("Gelir")
	if incomeLabel and incomeLabel:IsA("TextLabel") then
		incomeLabel.Text = if ownerName and income > 0 then Format.perSecond(income) else ""
	end

	local glow = anchor and anchor:FindFirstChild("Parilti")
	if glow and glow:IsA("PointLight") then
		glow.Color = color
	end
end

--[[
	Butonun uzerindeki miktari ve rengini tazeler.
	  bekleme suresinde  -> kirmizi, kalan sure yazili
	  toplanacak rot var -> yesil, miktar yazili
	  bos / sahipsiz     -> duz (gri)
]]
local function updateCollectButton(baseIndex: number)
	local pad = collectPads[baseIndex]
	if not pad then
		return
	end

	local cfg = Bases.CollectPad
	local waiting = pending[baseIndex] or 0

	-- Toplama sonrasi bekleme: buton bu sure boyunca KIRMIZI ve kapali
	local bekleme = math.max(0, (collectUntil[baseIndex] or 0) - os.clock())
	local ready = owners[baseIndex] ~= nil and waiting >= 1 and bekleme <= 0

	local renk = if bekleme > 0
		then cfg.cooldownColor
		elseif ready then cfg.color
		else cfg.idleColor

	pad.Color = renk

	local glow = pad:FindFirstChild("Parilti")
	if glow and glow:IsA("PointLight") then
		glow.Color = renk
		glow.Enabled = ready or bekleme > 0
	end

	local sign = pad:FindFirstChild("Yazi")
	local amount = sign and sign:FindFirstChild("Miktar")
	if amount and amount:IsA("TextLabel") then
		amount.Text = if bekleme > 0
			then `WAIT {math.ceil(bekleme)}s`
			elseif owners[baseIndex] then `{Format.short(math.floor(waiting))} Rot`
			else "EMPTY"
		amount.TextColor3 = if bekleme > 0
			then cfg.cooldownColor
			elseif ready then Bases.RotColor
			else cfg.idleColor
	end
end

--[[
	Birikmis rotu sahibine oder.

	Butona basan kisi base'in sahibi degilse hicbir sey olmaz; herkes gecerken
	birbirinin padine basacagi icin uyari da vermiyoruz.
]]
function collectRot(player: Player, baseIndex: number)
	if owners[baseIndex] ~= player then
		return
	end

	-- Bekleme surerken toplanmaz (buton kirmizi yanarken)
	if os.clock() < (collectUntil[baseIndex] or 0) then
		return
	end

	local waiting = pending[baseIndex] or 0
	local payout = math.floor(waiting)
	if payout < 1 then
		return
	end

	-- Kusurat birikmeye devam etsin
	pending[baseIndex] = waiting - payout
	PlayerData.addRot(player, payout)

	--[[
		BEKLEME BASLAR

		Buton collectCooldown saniye boyunca kirmizi yanar ve toplama kabul
		etmez. Sure dolunca buton kendiliginden yesile doner; bekleme bitisi
		ayrica tazelenir, yoksa gelir dongusunun bir sonraki adimina kadar
		kirmizi kalirdi.
	]]
	local cfg = Bases.CollectPad
	collectUntil[baseIndex] = os.clock() + cfg.collectCooldown

	local pad = collectPads[baseIndex]
	if pad then
		Assets.playSoundAt(cfg.collectSound, pad)

		--[[
			PARA SACMA EFEKTI

			Desteler sunucuda KURULMUYOR; burasi yalnizca haber veriyor,
			her istemci kendi desteleri kurup ucuruyor (bkz. StarterPlayer
			Scripts > ParaSacma). Sunucuda ucan onlarca parca hem takilarak
			gorunur hem agi doldururdu.

			Herkese gidiyor: yakindaki oyuncular da baskasinin toplamasini
			gorsun. Uzaktakileri istemci kendisi eliyor (GORUNME_MESAFESI).
			Nokta padin UST yuzu; desteler oradan firliyor.
		]]
		ParaSac:FireAllClients(player, pad.Position + Vector3.new(0, pad.Size.Y * 0.5, 0), payout)
	end

	updateCollectButton(baseIndex)

	task.delay(cfg.collectCooldown, function()
		updateCollectButton(baseIndex)
	end)

	-- Ekrandaki Rot gostergesi bayat kalmasin
	Envanter.push(player)

	Bildirim:FireClient(player, `+{Format.short(payout)} Rot collected!`, Bases.RotColor)
end

function pushBase(player: Player)
	local data = PlayerData.get(player)
	if not data or not data.base then
		return
	end

	local slots = {}
	for _, item in data.inventory do
		if item.slot then
			slots[item.slot] = {
				uid = item.uid,
				name = item.name,
				rarity = item.rarity,
				condition = item.condition,
				mutation = item.mutation,
				income = if item.name
					then Brainrots.income(item.name, item.condition :: any, item.mutation :: any)
					else 0,
			}
		end
	end

	local income = totalIncome(player)
	setSignText(data.base, player.DisplayName, income)

	BaseGuncelle:FireClient(player, {
		baseIndex = data.base,
		slotCount = Bases.SlotCount,
		-- Base gelisimi: acik kat ve slot sayisi
		floors = math.clamp(data.baseFloors or 1, 1, Bases.Upgrade.maxFloors),
		unlockedSlots = unlockedSlots(data),
		slots = slots,
		totalIncome = income,
		-- Butonda bekleyen, henuz toplanmamis rot
		pending = pending[data.base] or 0,
	})
end

local function assignBase(player: Player): number?
	local data = PlayerData.get(player)
	if not data then
		return nil
	end

	-- Zaten bir base'in sahibiyse ayni base: iki kez atanmasin
	for index, owner in owners do
		if owner == player then
			data.base = index
			return index
		end
	end

	for index = 1, Bases.Count do
		if owners[index] == nil then
			owners[index] = player
			data.base = index
			-- Base yeni sahibine bos ve beklemesiz devredilir
			pending[index] = 0
			collectUntil[index] = 0
			setSignText(index, player.DisplayName, 0)
			updateCollectButton(index)

			-- Sahibin acmis oldugu katlar ve slotlar geri gelsin
			applyFloors(index, data.baseFloors or 1)
			applySlots(index, unlockedSlots(data))
			updateSign(index)

			-- Onceki oturumdan kalan yerlesimleri geri koy
			for _, item in data.inventory do
				if item.slot and item.revealed and item.name then
					showInSlot(index, item.slot, item)
				end
			end

			return index
		end
	end

	Bildirim:FireClient(player, "No free bases left!", Color3.fromRGB(255, 120, 120))
	return nil
end

--[[
	Base'i serbest birakir.

	Indeks PlayerData'dan DEGIL owners tablosundan okunur. Sebep: PlayerData
	da PlayerRemoving'e bagli ve once o calisirsa oyuncunun verisi cache'ten
	silinmis oluyor; o zaman burasi nil alip erken donuyor, base sonsuza dek
	dolu kaliyor ve birkac giris-cikistan sonra "Bos base kalmadi" cikiyordu.
	owners tablosu bu scriptin kendi kaydi oldugu icin her zaman dogru.
]]
local function releaseBase(player: Player)
	lastTouch[player] = nil

	local index: number? = nil
	for baseIndex, owner in owners do
		if owner == player then
			index = baseIndex
			break
		end
	end

	if not index then
		return
	end

	for slotIndex = 1, Bases.SlotCount do
		clearSlotModel(index, slotIndex)
	end

	owners[index] = nil
	-- Toplanmamis rot sahibiyle birlikte gider
	pending[index] = nil
	setSignText(index, nil, 0)
	updateCollectButton(index)

	-- Base bosaldi: ust katlar ve satin alinmis slotlar tekrar kilitlenir
	applyFloors(index, 1)
	applySlots(index, Bases.Upgrade.startingSlots)
	updateSign(index)
end

------------------------------------------------------------------
-- YERLESTIRME / GERI ALMA
------------------------------------------------------------------
--[[
	BASE GUVENCESI

	Oyuncuya base, veri yuklenince atanir. Canli sunucuda veri gec
	yuklenirse atama kaciyor, data.base bos kaliyor ve slota koyma HICBIR
	mesaj vermeden vazgeciyordu ("cik gir yapinca duzeldi" hatasi).

	Artik: veride base yoksa ya da o base bu oyuncuya ait degilse atama
	burada yeniden denenir. Yine olmazsa oyuncuya yazilir.
]]
-- Sahipsiz base var mi (yoksa atama denenmez: "No free bases" tekrar tekrar yazilmasin)
function bosBaseVar(): boolean
	for index = 1, Bases.Count do
		if owners[index] == nil then
			return true
		end
	end
	return false
end

local function baseGuvence(player: Player, data: any): number?
	if data.base and owners[data.base] == player then
		return data.base
	end

	data.base = nil
	if not bosBaseVar() then
		Bildirim:FireClient(player, "No free bases left!", Color3.fromRGB(255, 120, 120))
		return nil
	end

	local index = assignBase(player)
	if index then
		pushBase(player)
		return index
	end

	Bildirim:FireClient(player, "Your base is still loading, try again in a moment.", Color3.fromRGB(255, 200, 90))
	return nil
end

function placeInSlot(player: Player, uid: string, slotIndex: number)
	if slotIndex < 1 or slotIndex > Bases.SlotCount then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		Bildirim:FireClient(player, "Your data is still loading, try again in a moment.", Color3.fromRGB(255, 200, 90))
		return
	end
	if not baseGuvence(player, data) then
		return
	end

	local item = PlayerData.findItem(player, uid)
	if not item then
		return
	end

	if not item.revealed or not item.name then
		Bildirim:FireClient(player, "Take it to the Brainrot Detective first!", Color3.fromRGB(255, 200, 90))
		return
	end

	-- Prompt disindan (remote) gelen istekte de kilit gecerli
	if slotIndex > unlockedSlots(data) then
		Bildirim:FireClient(player, `Slot {slotIndex} is locked.`, Color3.fromRGB(255, 200, 90))
		return
	end

	if item.slot then
		return -- zaten yerlestirilmis
	end

	--[[
		SLOT DOLUYSA TAKAS.
		Onceden "Bu slot dolu" deyip vazgeciyordu; artik slottaki brainrot
		cantaya doner, elindeki onun yerine oturur. Boylece bosaltip
		yeniden koymak icin iki islem yapmak gerekmez.
	]]
	local swapped: any = nil
	for _, other in data.inventory do
		if other.slot == slotIndex then
			swapped = other
			break
		end
	end

	if swapped then
		clearSlotModel(data.base, slotIndex)
		swapped.slot = nil
	end

	item.slot = slotIndex
	showInSlot(data.base, slotIndex, item)

	-- Koyma ve takas ayni sesi calar
	playSlotSound(data.base, slotIndex)

	-- Elden cikar, takas edilen cantaya doner: iki degisiklik tek esitlemede
	Envanter.syncBrainrots(player)
	Envanter.push(player)
	pushBase(player)

	-- Gorev panosu: base'e yerlestirme sayilir (takas da bir yerlestirmedir)
	GorevTakip.ilerlet(player, "place", 1)

	local income = Brainrots.income(item.name, item.condition :: any, item.mutation :: any)
	--[[
		BILDIRIM RENGI KADEMEDEN GELIR.

		Onceden mutasyonlu brainrotta mutasyonun rengi kullaniliyordu:
		Legendary bir brainrot Galaxy olunca bildirim sari yerine mor
		cikiyordu. Kademe oyuncunun ilk bakista aradigi bilgi, o yuzden
		renk her zaman kademenin.
	]]
	local color = Rarity.color(item.rarity)

	if swapped then
		Bildirim:FireClient(
			player,
			`{item.name} placed ({swapped.name or "Brainrot"} returned)`,
			color
		)
	else
		Bildirim:FireClient(
			player,
			`{item.name} placed ({Format.perSecond(income)})`,
			color
		)
	end
end

function removeFromSlot(player: Player, uid: string)
	local data = PlayerData.get(player)
	if not data or not data.base then
		return
	end

	local item = PlayerData.findItem(player, uid)
	if not item or not item.slot then
		return
	end

	local eskiSlot = item.slot
	clearSlotModel(data.base, item.slot)
	item.slot = nil

	playSlotSound(data.base, eskiSlot)

	-- Brainrot Tool olarak cantaya doner
	Envanter.syncBrainrots(player)
	Envanter.push(player)
	pushBase(player)

	Bildirim:FireClient(player, `{item.name or "Brainrot"} went back to your backpack.`, Color3.fromRGB(200, 210, 225))
end

--[[
	Base'i envanter verisiyle yeniden esitler.

	Slot modelleri sunucuda ayri tutuldugu icin envanter disaridan
	degistirildiginde (ornegin admin panelinden temizlendiginde) modeller
	oldugu yerde kaliyordu. Bu fonksiyon fazlalari siler, eksikleri koyar.
]]
local function refreshSlots(player: Player)
	local data = PlayerData.get(player)
	if not data or not data.base then
		return
	end

	local baseIndex = data.base

	-- Hangi slotta hangi esya olmali
	local expected: { [number]: any } = {}
	for _, item in data.inventory do
		if item.slot and item.revealed and item.name then
			expected[item.slot] = item
		end
	end

	local models = slotModels[baseIndex] or {}

	for slotIndex = 1, Bases.SlotCount do
		local item = expected[slotIndex]
		local shown = models[slotIndex]

		if not item and shown then
			-- Envanterde yok ama sahnede duruyor: kaldir
			clearSlotModel(baseIndex, slotIndex)
		elseif item and not shown then
			-- Envanterde var ama sahnede yok: koy
			showInSlot(baseIndex, slotIndex, item)
		end
	end

	pushBase(player)
end

-- Diger scriptler (admin paneli gibi) envanteri degistirdiginde tetikler
local refreshEvent = Instance.new("BindableEvent")
refreshEvent.Name = "BaseYenile"
refreshEvent.Parent = script
refreshEvent.Event:Connect(refreshSlots)

SlotaKoy.OnServerEvent:Connect(function(player, uid, slotIndex)
	if type(uid) ~= "string" or type(slotIndex) ~= "number" then
		return
	end
	placeInSlot(player, uid, math.floor(slotIndex))
end)

SlottanAl.OnServerEvent:Connect(function(player, uid)
	if type(uid) ~= "string" then
		return
	end
	removeFromSlot(player, uid)
end)

------------------------------------------------------------------
-- PASIF GELIR DONGUSU
--
-- Gelir Rot'a yazilmaz, base'de birikir. Oyuncu TOPLA butonuna basana
-- kadar orada bekler.
------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(Bases.PayoutInterval)

		for _, player in Players:GetPlayers() do
			local data = PlayerData.get(player)
			local index = data and data.base
			if index then
				local income = totalIncome(player)
				if income > 0 then
					pending[index] = (pending[index] or 0) + income * Bases.PayoutInterval
				end
			end
		end

		for index = 1, Bases.Count do
			updateCollectButton(index)
		end
	end
end)

-- Tabela ve client sayaci daha seyrek guncellenir
task.spawn(function()
	while true do
		task.wait(3)
		for _, player in Players:GetPlayers() do
			local data = PlayerData.get(player)
			if data and data.base and owners[data.base] == player then
				pushBase(player)
			elseif data then
				-- Emniyet: atamasi kacmis oyuncu burada base alir
				data.base = nil
				if bosBaseVar() and assignBase(player) then
					pushBase(player)
				end
			end
		end
	end
end)

------------------------------------------------------------------
-- OYUNCU BAGLANTILARI
------------------------------------------------------------------
local function setupPlayer(player: Player)
	--[[
		Veri yuklenene kadar beklenir. Eskiden 10 saniyede vazgeciliyordu:
		canli sunucuda veri gec gelirse base hic atanmiyordu.
	]]
	while player.Parent and not PlayerData.get(player) do
		task.wait(0.25)
	end
	if not player.Parent then
		return
	end

	local index = assignBase(player)
	if index then
		pushBase(player)
		Bildirim:FireClient(
			player,
			`Base {index} is yours`,
			Color3.fromRGB(140, 230, 160)
		)
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(setupPlayer, player)
end)

Players.PlayerRemoving:Connect(releaseBase)

for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end
