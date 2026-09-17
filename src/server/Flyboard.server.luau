--!strict
--[[
	FLYBOARD  (Script)
	Yeri: ServerScriptService > Flyboard

	Uc is yapar:

	1. SATICI
	   FlyboardSeller NPC'sine basinca 5 kademelik panel acilir. Kurek ve
	   dedektorle ayni kural: tek tahta tasinir, sirayla yukseltilir.

	2. BINME / INME
	   Oyuncu denize girdiginde tahtasi varsa kendiliginden biner. Denizden
	   cikinca Flyboard.Physics.dismountDelay saniye icinde iner -- aninda
	   degil, cunku dalga tepesinde bir kare deniz disinda sayilmak inip
	   binmeye yol aciyordu.

	3. SURUS FIZIGI
	   Tahta karakterin ayaginin altina kaynaklanir. Yukseklik BodyPosition
	   ile YALNIZCA Y ekseninde tutulur: yatay hareket Humanoid'in kendi
	   yurumesiyle olur, boylece kontrol normal hissettirir ve hiz bonusu
	   WalkSpeed uzerinden verilebilir.

	   Yatma (tilt) BodyGyro ile: gidilen yone dogru tiltAngle derece.
	   Space / Shift yuksekligi degistirir (istemci FlyboardYukseklik ile
	   bildirir); taban yuksekligin altina inilemez.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Flyboard = require(Shared:WaitForChild("Flyboard"))
local Fonts = require(Shared:WaitForChild("Fonts"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Assets = require(Shared:WaitForChild("Assets"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))

local Bildirim = Net.event("Bildirim")
local FlyboardAc = Net.event("FlyboardAc")
local FlyboardAl = Net.event("FlyboardAl")
local FlyboardYukseklik = Net.event("FlyboardYukseklik")

local P = Flyboard.Physics

------------------------------------------------------------------
-- DENIZ ALGISI
------------------------------------------------------------------

--[[
	Oyuncu denizde mi?

	Uc olcut, sirasiyla:
	  1. Humanoid yuzuyor  (Terrain su icin en guvenilir isaret)
	  2. Zemin malzemesi Water
	  3. Altindaki parcanin adi deniz sayiliyor (harita denizi normal
	     parcalarla yapildiysa)

	Ucuncusu icin asagi isin gonderilir; isin tahtanin kendisine takilmasin
	diye karakter ve tahta disarida birakilir.
]]
local function seaSurface(character: Model, ignore: { Instance }): number?
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end

	--[[
		ONCE ISIN: gercek su YUZEYININ yuksekligini yalnizca bu verir.
		Humanoid durumu yalnizca yedek olcut -- tahtaya binildikten sonra
		oyuncu artik yuzmedigi icin tek basina yeterli olmaz.
	]]
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore

	local hit = Workspace:Raycast(root.Position + Vector3.new(0, 8, 0), Vector3.new(0, -50, 0), params)
	if not hit then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Swimming then
			return root.Position.Y
		end
		return nil
	end

	if hit.Material == Enum.Material.Water then
		return hit.Position.Y
	end

	if Flyboard.isSeaInstance(hit.Instance) then
		return hit.Position.Y
	end

	-- Yedek: isin tutmadi ama oyuncu yuzuyorsa yine denizdedir
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Swimming then
		return root.Position.Y
	end

	return nil
end

------------------------------------------------------------------
-- TAHTA
------------------------------------------------------------------

--[[
	HARITADAKI TAHTAYI BULUR

	Sira: ReplicatedStorage > Assets (belgelenmis yer), sonra Workspace.
	Ikisinde de derin arama yapilir, bulunan KOPYALANIR -- asil nesneye
	dokunulmaz, her binis kendi kopyasiyla olur.

	Onceki surum yalnizca Assets > VFX altina bakiyordu; tahta Assets
	kokunde durdugunda bulunamiyor ve basit kutuya dusuluyordu.
]]
local function flyboardTemplate(): Instance?
	local assetRoot = ReplicatedStorage:FindFirstChild(Assets.FolderName)
	local found = if assetRoot then assetRoot:FindFirstChild(Flyboard.ModelName, true) else nil

	if not found then
		found = Workspace:FindFirstChild(Flyboard.ModelName, true)
	end

	if not found then
		warn(
			`[Flyboard] "{Flyboard.ModelName}" bulunamadi. `
				.. "ReplicatedStorage > Assets ya da Workspace icine koy."
		)
		return nil
	end

	return found:Clone()
end

--[[
	TAHTAYI KURAR

	Haritadaki tahta kopyalanir (Model de olabilir tek bir MeshPart da),
	kademenin rengine boyanir ve VFX'i kademeye gore guclendirilir.

	Donen deger iki parca: tahtanin kendisi ve kaynaklamada kullanilacak
	ANA PARCA.
]]
local function buildBoard(info: Flyboard.FlyboardInfo): (Instance?, BasePart?)
	local template = flyboardTemplate()

	local board: Instance
	local primary: BasePart?

	if template and template:IsA("BasePart") then
		board = template
		primary = template
	elseif template and template:IsA("Model") then
		board = template
		primary = template.PrimaryPart or template:FindFirstChildWhichIsA("BasePart", true)
	else
		if template then
			template:Destroy()
		end
		-- Harita tahtasi yoksa sistem yine calissin diye basit bir tahta
		local fallback = Instance.new("Part")
		fallback.Size = Vector3.new(4, 0.4, 1.6)
		fallback.Material = Enum.Material.SmoothPlastic
		board = fallback
		primary = fallback
	end

	if not primary then
		board:Destroy()
		return nil, nil
	end

	local anchor = primary :: BasePart

	board.Name = "Flyboard"

	--[[
		OLCEK

		Haritadaki tahta oyuncuya gore buyuk kaliyordu. Model ise ScaleTo
		butun parcalari ve icindeki noktalari birlikte kucultur; tek parca
		ise boyu dogrudan carpilir (icindeki Attachment konumlari parcaya
		gore oldugu icin onlar da yerinde kalir).
	]]
	--[[
		Gorunum adimlari PCALL icinde.

		Olcekleme ve efekt ayari haritadaki modelin icerigine bagli; oradaki
		bir aksilik (tuhaf bir deger, kilitli bir ozellik) TAHTAYA BINMEYI
		engellememeli. Hata durumunda Output'a duser, tahta yine kurulur.
	]]
	if P.boardScale ~= 1 then
		local ok, err = pcall(function()
			if board:IsA("Model") then
				board:ScaleTo(P.boardScale)
			elseif board:IsA("BasePart") then
				board.Size = board.Size * P.boardScale
			end
		end)

		if not ok then
			warn(`[Flyboard] Olcekleme yapilamadi: {tostring(err)}`)
		end
	end

	for _, node in board:GetDescendants() do
		if node:IsA("BasePart") then
			node.Anchored = false
			node.CanCollide = false
			node.CanQuery = false
			node.CanTouch = false
			node.Massless = true
		end
	end

	if board:IsA("BasePart") then
		board.Anchored = false
		board.CanCollide = false
		board.CanQuery = false
		board.CanTouch = false
		board.Massless = true
		board.Color = info.color
	end

	--[[
		KADEMEYE GORE VFX

		Tahtanin kendi Bottom noktalarindaki Lightning ve ParticleEmitter'lar
		kademeyle birlikte guclenir: boyut ve hiz burada, renk ve yogunluk
		asagidaki dongude.
	]]
	Assets.scaleEffects(board, info.vfxScale)

	--[[
		RENK VE PARLAKLIK

		Studio'daki efekt bembeyaz ve cok parlak cizilmis. Iki sey yapiliyor:

		1. RENK KADEMEDEN GELIR
		   Beyaz hic kullanilmiyor: parcacik kademenin ACIK tonunda dogar,
		   kademe renginden gecer, KOYU tonunda soner (Flyboard.colorRamp).
		   Onceki surum beyazi koruyordu ve efektin rengi hic gorunmuyordu.

		2. EKLEMELI PARLAMA KISILIYOR
		   Yuksek LightEmission parcacigi rengi ne olursa olsun ekranda
		   beyaza patlatiyor ve gozu aliyor. Tavan Flyboard.VFX icinde.
	]]
	local V = Flyboard.VFX
	-- Acik ton -> kademe rengi -> koyu ton (beyaz kullanilmiyor)
	local gecis = Flyboard.colorRamp(info)

	local vfxOk, vfxErr = pcall(function()
		for _, node in board:GetDescendants() do
			if node:IsA("ParticleEmitter") then
				node.Color = gecis
				node.LightEmission = math.min(node.LightEmission, V.lightEmission)

				-- Yogunluk kademeyle artar ama karekokle: dogrusal artis ekrani dolduruyordu
				node.Rate = node.Rate * math.sqrt(info.vfxScale)

				node.Lifetime = NumberRange.new(
					node.Lifetime.Min * math.sqrt(info.vfxScale),
					node.Lifetime.Max * math.sqrt(info.vfxScale)
				)

				--[[
					Saydamlik bir tik artar.

					ZARF DA KISILMALI: Roblox bir keypoint'te zarfin deger ile
					sinirlar arasindaki mesafeden buyuk olmasina izin vermiyor.
					Degeri 1'e yaklastirip zarfi oldugu gibi birakmak hata firlatiyor
					ve tahtanin kurulumu komple dusuyordu.
				]]
				local keys = {}
				for _, key in node.Transparency.Keypoints do
					local deger = math.clamp(key.Value + V.extraTransparency, 0, 1)
					local zarf = math.min(key.Envelope, deger, 1 - deger)
					table.insert(keys, NumberSequenceKeypoint.new(key.Time, deger, zarf))
				end
				node.Transparency = NumberSequence.new(keys)

				node.Enabled = true
			elseif node:IsA("Beam") then
				node.Color = gecis
				node.LightEmission = math.min(node.LightEmission, V.lightEmission)
				node.Width0 *= info.vfxScale
				node.Width1 *= info.vfxScale
				node.Enabled = true
			elseif node:IsA("Light") then
				node.Color = info.color
				node.Brightness = math.min(node.Brightness * info.vfxScale, V.lightBrightness)
				node.Enabled = true
			end
		end
	end)

	if not vfxOk then
		warn(`[Flyboard] Efekt ayarlanamadi: {tostring(vfxErr)}`)
	end

	return board, anchor
end

------------------------------------------------------------------
-- BINIS DURUMU
------------------------------------------------------------------
type Ride = {
	-- Model de olabilir tek parca da (haritadaki tahtaya gore)
	board: Instance,
	weld: WeldConstraint,
	hold: BodyPosition,
	gyro: BodyGyro,
	info: Flyboard.FlyboardInfo,
	-- Taban yukseklige EK olarak Space ile cikilan yukseklik
	rise: number,
	-- Denizden cikildiginda ilk anin zamani (geri sayim icin)
	leftSeaAt: number?,
	-- Binmeden onceki yurume hizi ve ziplama gucu
	walkSpeed: number,
	jumpPower: number,
	useJumpPower: boolean,
}

local rides: { [Player]: Ride } = {}

--[[
	SALINIM: tahta havada suzuluyormus gibi yavasca yukari asagi gider.
	Genlik stud cinsinden; her oyuncunun dalgasi farkli yerden baslar ki
	yan yana gezenler ayni anda inip kalkmasin.
]]
-- 0.1 stud gozle secilmiyordu (kamera da karakterle birlikte gidiyor)
local SALINIM_GENLIK = 0.3
local SALINIM_HIZI = 2

--[[
	TAHTA NE KADAR ASAGIDA

	Sabit 3 stud degil: karakterin ayak mesafesi (HipHeight + kok parcanin
	yarisi; R6'da 3) + tahtanin yari kalinligi. Sabit deger bazi
	avatarlarda tahtayi ayagin USTUNE koyuyordu, ayaklar tahtanin icinde /
	altinda kaliyordu.
]]
local function tahtaMesafesi(root: BasePart, humanoid: Humanoid, anchor: BasePart): number
	local ayak = if humanoid.RigType == Enum.HumanoidRigType.R6
		then root.Size.Y / 2 + 2
		else humanoid.HipHeight + root.Size.Y / 2
	-- Tahtanin en ince ekseni kalinligidir (model nasil donmus olursa olsun)
	local kalinlik = math.min(anchor.Size.X, anchor.Size.Y, anchor.Size.Z)
	return ayak + kalinlik / 2 + 0.05
end

--[[
	HIZ

	TABAN HIZ HUMANOID'IN UZERINDE SAKLANIR.

	Onceden binerken o anki WalkSpeed kaydediliyordu. Ayni karakterde ikinci
	kez binilirse (tahta degistirme, kisa sureli inis) kaydedilen deger ZATEN
	BONUSLU olan hiz oluyor ve inince oraya donuluyordu: hiz takili kaliyordu.

	Oznitelige bir kez yazilir, her iniste oradan geri alinir ve silinir.
]]
local TABAN_HIZ = "FlyboardTabanHiz"

-- Hiz bonusu kademeye ozel: Basic %10, Inferno %30
local function bonusHiz(taban: number, info: Flyboard.FlyboardInfo?): number
	local oran = if info then info.speedBonus else P.speedBonus
	return taban * (1 + oran)
end

-- Bonussuz hiz: ilk biniste yazilir, sonraki binislerde aynisi okunur
local function tabanHiz(humanoid: Humanoid): number
	local kayitli = humanoid:GetAttribute(TABAN_HIZ)
	if type(kayitli) == "number" then
		return kayitli
	end

	humanoid:SetAttribute(TABAN_HIZ, humanoid.WalkSpeed)
	return humanoid.WalkSpeed
end

local function dismount(player: Player, sessiz: boolean?)
	local ride = rides[player]
	if not ride then
		return
	end
	rides[player] = nil

	if ride.board.Parent then
		ride.board:Destroy()
	end
	if ride.hold.Parent then
		ride.hold:Destroy()
	end
	if ride.gyro.Parent then
		ride.gyro:Destroy()
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Taban hiz oznitelikten geri alinir, sonra oznitelik silinir
		humanoid.WalkSpeed = tabanHiz(humanoid)
		humanoid:SetAttribute(TABAN_HIZ, nil)

		humanoid.UseJumpPower = ride.useJumpPower
		humanoid.JumpPower = ride.jumpPower
	end

	-- Tahtadan inince olta da gider
	player:SetAttribute("Flyboarding", false)
	Envanter.removeRod(player)

	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(root.Orientation.Y), 0)
	end

	if not sessiz then
		Bildirim:FireClient(player, "Flyboard stowed", Color3.fromRGB(180, 200, 220))
	end
end

local function mount(player: Player, info: Flyboard.FlyboardInfo)
	if rides[player] then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not character or not root or not root:IsA("BasePart") or not humanoid then
		return
	end

	local board, anchor = buildBoard(info)
	if not board or not anchor then
		return
	end

	--[[
		YERLESTIRME VE KAYNAK

		Tahta ayagin altina konur, sonra BUTUN parcalari koke kaynaklanir.
		Model oldugunda tek parcayi kaynaklamak yetmiyor: kalanlar havada
		asili kalir ve ilk fizik adiminda dagilirdi.
	]]
	local mesafe = tahtaMesafesi(root, humanoid, anchor)
	local hedef = root.CFrame * CFrame.new(0, -mesafe, 0)

	if board:IsA("BasePart") then
		board.CFrame = hedef
	elseif board:IsA("Model") then
		board:PivotTo(hedef)
	end

	board.Parent = Workspace

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = anchor
	weld.Parent = anchor

	if board:IsA("Model") then
		for _, part in board:GetDescendants() do
			if part:IsA("BasePart") and part ~= anchor then
				local ic = Instance.new("WeldConstraint")
				ic.Part0 = anchor
				ic.Part1 = part
				ic.Parent = part
			end
		end
	end

	--[[
		YUKSEKLIK YALNIZCA Y EKSENINDE TUTULUR.

		MaxForce'un X ve Z'si sifir: yatay hareket Humanoid'e birakilir.
		Ikisi de tutulsaydi oyuncu yurumeye calisirken tahta onu yerinde
		sabitler, kontrol kaskati olurdu.
	]]
	local hold = Instance.new("BodyPosition")
	hold.Name = "FlyboardYukseklik"
	hold.MaxForce = Vector3.new(0, math.huge, 0)
	hold.P = 12000
	hold.D = 900
	hold.Position = root.Position
	hold.Parent = root

	local gyro = Instance.new("BodyGyro")
	gyro.Name = "FlyboardYatis"
	gyro.MaxTorque = Vector3.new(math.huge, 0, math.huge)
	gyro.P = 9000
	gyro.D = 600
	gyro.CFrame = root.CFrame
	gyro.Parent = root

	rides[player] = {
		board = board,
		weld = weld,
		hold = hold,
		gyro = gyro,
		info = info,
		mesafe = mesafe,
		rise = 0,
		leftSeaAt = nil,
		walkSpeed = tabanHiz(humanoid),
		jumpPower = humanoid.JumpPower,
		useJumpPower = humanoid.UseJumpPower,
	}

	--[[
		OLTA ELE GELIR

		Denizde tahtadayken olta GPS'in yerini alir: girdaplar onunla dogar
		(bkz. KaziSistemi). Oltasi olmayan oyuncuda hicbir sey olmaz.
	]]
	--[[
		DENIZDE OLDUGU ISARETLENIR

		Girdaplarin dogmasi buna bakiyor: oltanin fiziksel modeli bir sebeple
		ele takilamasa bile (el parcasi bulunamadi vb.) balikcilik calisir.
	]]
	player:SetAttribute("Flyboarding", true)

	Envanter.equipRod(player)

	-- Hiz bonusu ve ziplama kapatma
	humanoid.WalkSpeed = bonusHiz(tabanHiz(humanoid), info)
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0

	Bildirim:FireClient(
		player,
		`{info.displayName} ready (+{math.floor(info.speedBonus * 100)}% speed)`,
		info.color
	)
end

------------------------------------------------------------------
-- TAHTASIZ YUZME  --  yuzeyde kal, can kaybet
--
-- Flyboardi olmayan oyuncu denize girerse:
--   1. DERINE DALAMAZ. Kok parca, yuzeyin noBoardDepth kadar altinda
--      Y ekseninde tutulur; yatay hareket serbest kalir.
--   2. HER TIKTA CAN KAYBEDER. Giden can karakterin ustunde kirmizi
--      "-10" olarak yarim saniye gorunur.
--
-- Tahtaya binildiginde ya da sudan cikildiginda tutucu kaldirilir.
------------------------------------------------------------------
local floats: { [Player]: BodyPosition } = {}
local lastTick: { [Player]: number } = {}

local function suyuBirak(player: Player)
	local hold = floats[player]
	if hold then
		if hold.Parent then
			hold:Destroy()
		end
		floats[player] = nil
	end
	lastTick[player] = nil
end

--[[
	Giden cani karakterin ustunde gosterir.

	Sunucuda uretilir, yani hasari yiyen de yanindan gecen de gorur.
	damageTextTime saniye sonra kendiliginden silinir.
]]
local function hasarYazisi(character: Model, amount: number)
	local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if not head or not head:IsA("BasePart") then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SuHasari"
	billboard.Size = UDim2.fromOffset(120, 40)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 150
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = `-{amount}`
	label.TextColor3 = Color3.fromRGB(255, 60, 60)
	label.TextSize = 30
	label.TextScaled = false
	label.Parent = billboard
	Fonts.apply(label)

	Debris:AddItem(billboard, P.damageTextTime)
end

--[[
	TAHTASIZ DENIZE GIRIS YOK

	Hiz yukseltmesinden sonra oyuncular kaldirma kuvvetini asip denize
	dalabiliyordu. Artik flyboardi olmayan oyuncu suya degdigi anda KARADA
	son durdugu yere geri konur. Karadaki konum kisa araliklarla kaydedilir;
	suya girmeden biraz onceki kayit kullanilir (hizli oyuncu kiyida
	takilip kalmasin).
]]
local KARA_ARALIK = 0.1
local KARA_GECMIS = 12
-- Geri konulacak kayit en az bu kadar eski olmali
local KARA_GERI = 0.15
local UYARI_ARALIK = 2

type KaraKaydi = { cf: CFrame, t: number }
local karaGecmisi: { [Player]: { KaraKaydi } } = {}
local sonUyari: { [Player]: number } = {}

local function karayiKaydet(player: Player, root: BasePart, humanoid: Humanoid)
	local zemin = humanoid.FloorMaterial
	if zemin == Enum.Material.Air or zemin == Enum.Material.Water then
		return
	end

	local gecmis = karaGecmisi[player]
	if not gecmis then
		gecmis = {}
		karaGecmisi[player] = gecmis
	end

	local simdi = os.clock()
	local son = gecmis[#gecmis]
	if son and simdi - son.t < KARA_ARALIK then
		return
	end

	table.insert(gecmis, { cf = root.CFrame, t = simdi })
	if #gecmis > KARA_GECMIS then
		table.remove(gecmis, 1)
	end
end

-- Karaya geri koyar; kayit yoksa false
local function karayaGeriKoy(player: Player, character: Model, root: BasePart): boolean
	local gecmis = karaGecmisi[player]
	if not gecmis or #gecmis == 0 then
		return false
	end

	local simdi = os.clock()
	local secilen = gecmis[1]
	for i = #gecmis, 1, -1 do
		if simdi - gecmis[i].t >= KARA_GERI then
			secilen = gecmis[i]
			break
		end
	end

	character:PivotTo(secilen.cf + Vector3.new(0, 0.5, 0))
	root.AssemblyLinearVelocity = Vector3.zero

	if simdi - (sonUyari[player] or 0) >= UYARI_ARALIK then
		sonUyari[player] = simdi
		Bildirim:FireClient(player, "You need a Flyboard to enter the sea!", Color3.fromRGB(255, 120, 120))
	end
	return true
end

Players.PlayerRemoving:Connect(function(player)
	karaGecmisi[player] = nil
	sonUyari[player] = nil
end)

local function bogul(player: Player, root: BasePart, humanoid: Humanoid, surface: number)
	--[[
		KALDIRMA KUVVETI  (tutuklama DEGIL)

		Kuvvet yalnizca oyuncu SU HIZASININ ALTINDAYKEN calisir. Ustundeyse
		kuvvet kapatilir; yoksa Space ile yukari cikmaya calisan oyuncuyu
		geri asagi cekiyor, suya giren bir daha cikamiyor ve orada oluyordu.

		Sonuc: dalmak diye bir sey yok, oyuncu suyun ustunde yuzer; ama
		ziplayip kiyiya cikmasi serbest.
	]]
	local hold = floats[player]
	if not hold or not hold.Parent then
		local yeni = Instance.new("BodyPosition")
		yeni.Name = "SuyunKaldirmaKuvveti"
		yeni.P = 12000
		yeni.D = 1200
		yeni.Parent = root
		hold = yeni
		floats[player] = yeni
	end

	local aktif = hold :: BodyPosition
	local hizaY = surface - P.noBoardDepth

	if root.Position.Y < hizaY then
		-- Batiyor: yalnizca Y ekseninde yukari itilir
		aktif.MaxForce = Vector3.new(0, math.huge, 0)
		aktif.Position = Vector3.new(root.Position.X, hizaY, root.Position.Z)
	else
		-- Hizanin ustunde: hicbir kuvvet uygulanmaz, oyuncu serbest
		aktif.MaxForce = Vector3.zero
	end

	------------------------------------------------------------------
	-- CAN KAYBI
	------------------------------------------------------------------
	local now = os.clock()
	local son = lastTick[player]

	if son and now - son < P.noBoardTick then
		return
	end

	-- Ilk karede hasar verilmez: suya degen oyuncu bir tik nefes alsin
	lastTick[player] = now
	if not son then
		return
	end

	local hasar = math.max(1, math.floor(humanoid.MaxHealth * P.noBoardDamage + 0.5))
	humanoid:TakeDamage(hasar)

	local character = humanoid.Parent
	if character and character:IsA("Model") then
		hasarYazisi(character, hasar)
	end
end

------------------------------------------------------------------
-- SURUS DONGUSU
------------------------------------------------------------------
RunService.Heartbeat:Connect(function(dt)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
			if rides[player] then
				dismount(player, true)
			end
			-- Olen ya da yeniden dogan oyuncunun yuzey tutucusu da kalkar
			suyuBirak(player)
			continue
		end

		local ride = rides[player]
		local ignore: { Instance } = if ride then { character, ride.board } else { character }
		local surface = seaSurface(character, ignore)

		------------------------------------------------------------------
		-- BINME
		------------------------------------------------------------------
		if not ride then
			if not surface then
				suyuBirak(player)
				karayiKaydet(player, root, humanoid)
				continue
			end

			local data = PlayerData.get(player)
			local info = data and Flyboard.get(data.flyboard)

			if info then
				suyuBirak(player)
				mount(player, info)
			elseif not karayaGeriKoy(player, character, root) then
				-- Tahtasi yok ve karada kaydi da yok: yuzeyde tutulur, can kaybeder
				bogul(player, root, humanoid, surface)
			end

			continue
		end

		-- Tahtaya binen oyuncu artik bogulmuyor
		suyuBirak(player)

		------------------------------------------------------------------
		-- DENIZDEN CIKIS: gecikmeli inis
		------------------------------------------------------------------
		if surface then
			ride.leftSeaAt = nil
		else
			local since = ride.leftSeaAt
			if not since then
				ride.leftSeaAt = os.clock()
			elseif os.clock() - since >= P.dismountDelay then
				dismount(player)
			end
			continue
		end

		------------------------------------------------------------------
		-- YUKSEKLIK
		------------------------------------------------------------------
		local salinim = math.sin(os.clock() * SALINIM_HIZI + (player.UserId % 7)) * SALINIM_GENLIK
		local hedefY = surface + P.hoverHeight + ride.rise + (ride.mesafe or P.boardOffset) + salinim
		ride.hold.Position = Vector3.new(root.Position.X, hedefY, root.Position.Z)

		------------------------------------------------------------------
		-- YATIS
		--
		-- Gidilen yon varsa o yone dogru tiltAngle derece yatilir; dururken
		-- duz durur. Yatis BodyGyro'nun hedef CFrame'ine yazilir, gecis
		-- yumusakligi gyro'nun kendi D katsayisindan gelir.
		------------------------------------------------------------------
		local move = humanoid.MoveDirection
		local look = if move.Magnitude > 0.1 then move.Unit else Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit

		local hedef = CFrame.lookAt(root.Position, root.Position + look)
		if move.Magnitude > 0.1 then
			hedef = hedef * CFrame.Angles(math.rad(-P.tiltAngle), 0, 0)
		end

		ride.gyro.CFrame = hedef

		-- Hiz bonusu her karede dogrulanir (baska sistemler WalkSpeed'i degistirebilir)
		local beklenen = bonusHiz(ride.walkSpeed, ride.info)
		if math.abs(humanoid.WalkSpeed - beklenen) > 0.01 then
			humanoid.WalkSpeed = beklenen
		end

		--[[
			YURUYOR SAYILIR

			Tahta havada suzuldugu icin Humanoid ayagini basacak zemin
			bulamiyor ve FREEFALL durumuna dusuyor. O durumda yatay hareket
			"hava kontrolu" ile olur: WalkSpeed yazsa da ivme gevsek kalir,
			hiz bonusu hic hissedilmezdi.

			Her karede Running durumuna alinca Humanoid yurume hesabini
			kullanir ve WalkSpeed oldugu gibi uygulanir.
		]]
		if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end
end)

------------------------------------------------------------------
-- YUKSEKLIK KOMUTU  (Space / Shift)
------------------------------------------------------------------
FlyboardYukseklik.OnServerEvent:Connect(function(player, yon)
	local ride = rides[player]
	if not ride or type(yon) ~= "number" then
		return
	end

	--[[
		yon: +1 yukari (Space), -1 asagi (Shift), 0 dur.
		Taban yukseklik altina inilemez, riseLimit ustune cikilamaz.
	]]
	local adim = math.sign(yon) * P.riseSpeed * (1 / 30)
	ride.rise = math.clamp(ride.rise + adim, 0, P.riseLimit)
end)

------------------------------------------------------------------
-- SATICI
------------------------------------------------------------------
local function payload(player: Player)
	local data = PlayerData.get(player)
	local kusanilan = data and data.flyboard or nil
	local enYuksek = Flyboard.level(data and data.flyboardMax or nil)

	local liste = {}
	for _, id in Flyboard.Order do
		local info = Flyboard.Info[id]
		table.insert(liste, {
			id = info.id,
			displayName = info.displayName,
			rarity = info.rarity,
			price = info.price,
			color = info.color,
			-- Alinmis kademeler kalici: tiklayinca ucretsiz kusanilir
			owned = enYuksek >= info.level,
			equipped = kusanilan == info.id,
			-- Sirayla alinir: yalnizca bir sonraki kademe satin alinabilir
			next = enYuksek + 1 == info.level,
		})
	end

	return {
		rot = if data then data.rot else 0,
		owned = kusanilan,
		boards = liste,
	}
end

FlyboardAl.OnServerEvent:Connect(function(player, id)
	if type(id) ~= "string" then
		return
	end

	local info = Flyboard.get(id)
	local data = PlayerData.get(player)
	if not info or not data then
		return
	end

	local enYuksek = Flyboard.level(data.flyboardMax)

	--[[
		SAHIP OLUNAN KADEME: SATIN ALMA DEGIL, KUSANMA

		Alinmis tahtalar kalici. Tiklayinca ucretsiz kusanilir; denizdeyken
		degistirilirse binis yenilenir ki yeni tahta hemen gorunsun.
	]]
	if info.level <= enYuksek then
		if data.flyboard == info.id then
			Bildirim:FireClient(player, `{info.displayName} is already equipped.`, Color3.fromRGB(180, 200, 220))
			return
		end

		data.flyboard = info.id
		FlyboardAc:FireClient(player, payload(player))
		Bildirim:FireClient(player, `{info.displayName} equipped.`, Rarity.color(info.rarity))

		if rides[player] then
			dismount(player, true)
		end
		return
	end

	if info.level ~= enYuksek + 1 then
		Bildirim:FireClient(player, "Buy the previous flyboard first.", Color3.fromRGB(255, 200, 90))
		return
	end

	if data.rot < info.price then
		Bildirim:FireClient(
			player,
			`Not enough Rot! You need {Format.short(info.price - data.rot)} more Rot for {info.displayName}.`,
			Color3.fromRGB(255, 90, 90)
		)
		return
	end

	PlayerData.addRot(player, -info.price)
	data.flyboard = info.id
	data.flyboardMax = info.id

	Envanter.push(player)
	FlyboardAc:FireClient(player, payload(player))

	Bildirim:FireClient(player, `{info.displayName} purchased!`, Rarity.color(info.rarity))

	-- Denizdeyken satin aldiysa tahtasi hemen yenisiyle degissin
	if rides[player] then
		dismount(player, true)
	end
end)

------------------------------------------------------------------
-- NPC
------------------------------------------------------------------
local SATICI_ADLARI = { "FlyboardSeller", "FlyboardSatici", "Flyboard Seller" }

local function adEsit(a: string, b: string): boolean
	return string.lower(string.gsub(a, "%s", "")) == string.lower(string.gsub(b, "%s", ""))
end

local function anchorFrom(node: Instance): BasePart?
	if node:IsA("BasePart") then
		return node
	end

	if node:IsA("Model") then
		local primary = node.PrimaryPart
		if primary then
			return primary
		end
		local root = node:FindFirstChild("HumanoidRootPart", true)
		if root and root:IsA("BasePart") then
			return root
		end
	end

	return node:FindFirstChildWhichIsA("BasePart", true)
end

local function attachPrompt()
	local anchor: BasePart? = nil

	for _, name in SATICI_ADLARI do
		for _, node in Workspace:GetDescendants() do
			if adEsit(node.Name, name) then
				anchor = anchorFrom(node)
				if anchor then
					break
				end
			end
		end
		if anchor then
			break
		end
	end

	if not anchor then
		warn(`[Flyboard] Satici bulunamadi: {table.concat(SATICI_ADLARI, ", ")}`)
		return
	end

	local existing = anchor:FindFirstChild("FlyboardPrompt")
	if existing then
		existing:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "FlyboardPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = "Flyboard Seller"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = anchor

	prompt.Triggered:Connect(function(player)
		FlyboardAc:FireClient(player, payload(player))
	end)

	print(`[Flyboard] Satici promptu kuruldu: {anchor:GetFullName()}`)
end

task.spawn(attachPrompt)

Players.PlayerRemoving:Connect(function(player)
	rides[player] = nil
	suyuBirak(player)
end)
