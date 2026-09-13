--!strict
--[[
	LUCKY BLOCK -- kazidan cikan blok ve carki.

	Kazi sirasinda Lucky Block suzmesi cikinca oyuncunun hesabina bir blok
	eklenir (PlayerData.luckyBlocks). Envanterden acilinca:

	  1. SUNUCU odulu belirler -- carkin nerede duracagini client secmez
	  2. Brainrot envantere ACILMIS olarak girer (Detective gerekmez)
	  3. Client'a IKI ASAMALIK cark verisi gonderilir

	CARK IKI ASAMALIDIR
	  1. asama  Bolmelerde yalnizca "?" ve kademe rengi vardir; durunca
	            hangi KADEMENIN ciktigi belli olur (orn. kirmizi = Mythic).
	  2. asama  Serit yeniden kurulur, bu kez sadece o kademedeki
	            brainrotlar doner ve odul aciga cikar.

	Yani cark sadece gosterim; sonuc daha o donmeye baslamadan bellidir.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Condition = require(Shared:WaitForChild("Condition"))
local Fonts = require(Shared:WaitForChild("Fonts"))
local Format = require(Shared:WaitForChild("Format"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))
local GorevTakip = require(script.Parent:WaitForChild("GorevTakip"))
local Tools = require(script.Parent:WaitForChild("Tools"))
local Sand = require(script.Parent:WaitForChild("Sand"))

local Bildirim = Net.event("Bildirim")
local EtkinlikSayaci = Net.event("EtkinlikSayaci")
local LuckyBlockAc = Net.event("LuckyBlockAc")
local LuckyBlockSonuc = Net.event("LuckyBlockSonuc")

local LuckyBlockOdul = {}

local rng = Random.new()

-- Ayni anda iki cark donmesin
local opening: { [Player]: boolean } = {}

------------------------------------------------------------------
-- KAZIDAN CIKAN BLOK (dunyadaki gorsel)
------------------------------------------------------------------

--[[
	Blok modeli yoksa yerine sari bir kup uretilir; boylece klasor bos olsa
	da oyun calisir.
]]
local function buildBlock(tierId: string): Model
	local tier = LuckyBlock.get(tierId)

	local ready = Assets.luckyBlockModel(tier.modelName, tier.order)
	if ready then
		return ready
	end

	local model = Instance.new("Model")

	local body = Instance.new("Part")
	body.Name = "Govde"
	body.Size = Vector3.new(3, 3, 3)
	body.Color = tier.color
	body.Material = Enum.Material.Neon
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model
	model.PrimaryPart = body

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(120, 60)
	sign.StudsOffset = Vector3.new(0, 1, 0)
	sign.AlwaysOnTop = true
	sign.Parent = body

	local mark = Instance.new("TextLabel")
	mark.Size = UDim2.fromScale(1, 1)
	mark.BackgroundTransparency = 1
	mark.Text = "?"
	mark.TextColor3 = Color3.fromRGB(40, 30, 0)
	mark.TextSize = 48
	mark.Parent = sign

	return model
end

--[[
	Kazilan yerde blogu kisa sure gosterir: havalanir, doner ve kaybolur.
	Sadece gorsel -- odul zaten envantere eklenmis olur.
]]
function LuckyBlockOdul.showDrop(position: Vector3, tierId: string)
	local model = buildBlock(tierId)
	local primary = model.PrimaryPart
	if not primary then
		model:Destroy()
		return
	end

	--[[
		Parcalar sabitlenir (yoksa dusup giderler) ama BASKA hicbir seyine
		dokunulmaz: rengi, malzemesi, partikulu paketten geldigi gibi kalir.
		Kemik animasyonu sabit parcada da calisir.
	]]
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	local origin = position + Vector3.new(0, 3, 0)
	model:PivotTo(CFrame.new(origin))
	model.Parent = Workspace

	-- Paketin kendi animasyonunu baslat
	Assets.playAnimations(model)

	local glow = Instance.new("PointLight")
	glow.Color = LuckyBlock.get(tierId).color
	glow.Range = 16
	glow.Brightness = 3
	glow.Parent = primary

	Debris:AddItem(model, 2.5)

	task.spawn(function()
		local t = 0
		while model.Parent and t < 2.4 do
			t += task.wait(0.03)
			model:PivotTo(
				CFrame.new(origin + Vector3.new(0, t * 1.6, 0)) * CFrame.Angles(0, t * 6, 0)
			)
		end
	end)
end

------------------------------------------------------------------
-- ETKINLIK: KUMLARA DUSEN BLOKLAR
--
-- Belirli araliklarla haritadaki kumlarin uzerinde bloklar belirir.
-- Sahipsizdir: ilk giden alir.
------------------------------------------------------------------

local eventFolder: Folder? = nil

local function blocksFolder(): Folder
	if eventFolder and eventFolder.Parent then
		return eventFolder
	end

	local existing = Workspace:FindFirstChild("LuckyBlocklar")
	if existing and existing:IsA("Folder") then
		eventFolder = existing
		return existing
	end

	local created = Instance.new("Folder")
	created.Name = "LuckyBlocklar"
	created.Parent = Workspace
	eventFolder = created
	return created
end

--[[
	Uzaktan gorunsun diye blogun uzerine isik sutunu diker.
	Blok kumda kucuk kaliyor; sutun olmadan bulmak sansa kaliyordu.
]]
--[[
	ISIK KONISI

	Uzun sari sutunun yerini BEYAZ bir koni aldi: ince ucu yerden cikar,
	yukari dogru acilir ve en genis yeri blogun durdugu yerdir.

	Koni bir Beam ile ciziliyor. Roblox'ta koni SEKLINDE hazir bir parca
	yok; Beam ise iki ucuna ayri genislik (Width0 / Width1) kabul ediyor ve
	FaceCamera ile her acidan duz gorunuyor -- yani ucgen/koni gorunumu
	kameradan bagimsiz bozulmuyor.

	groundY: koninin ince ucunun oturacagi zemin yuksekligi.
]]
local function buildBeacon(parent: BasePart, groundY: number)
	local E = LuckyBlock.Event

	local uc = Instance.new("Attachment")
	uc.Name = "KoniUc"
	-- Attachment konumu parcaya GORE; blok zeminden E.beaconHeight yukarida
	uc.Position = Vector3.new(0, groundY - parent.Position.Y, 0)
	uc.Parent = parent

	local agiz = Instance.new("Attachment")
	agiz.Name = "KoniAgiz"
	agiz.Position = Vector3.new(0, 0, 0)
	agiz.Parent = parent

	local koni = Instance.new("Beam")
	koni.Name = "Isik"
	koni.Attachment0 = uc
	koni.Attachment1 = agiz
	-- Ince uc yerde, genis agiz blogun oldugu yukseklikte
	koni.Width0 = 0.4
	koni.Width1 = E.beaconWidth
	koni.FaceCamera = true
	koni.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	koni.LightEmission = 1
	koni.LightInfluence = 0
	-- Yerde daha yogun, yukari dogru hafifce seyrelir
	koni.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 0.55),
	})
	koni.Segments = 1
	koni.Parent = parent

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 255, 255)
	light.Range = 26
	light.Brightness = 3
	light.Parent = parent
end

--[[
	Bir blok dusurur. Nokta verilmezse haritadaki herhangi bir kum secilir
	(admin panelinden elle tetiklemede boyle olur).
]]
local function spawnEventBlock(tierId: string, spot: Vector3?): boolean
	local nokta = spot or Sand.randomSpot(rng)
	if not nokta then
		return false
	end

	local tier = LuckyBlock.get(tierId)
	local model = buildBlock(tierId)
	local primary = model.PrimaryPart
	if not primary then
		model:Destroy()
		return false
	end

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	-- Blok koninin genis agzinin uzerinde durur
	local origin = nokta + Vector3.new(0, LuckyBlock.Event.beaconHeight, 0)
	model.Name = `Etkinlik_{tier.id}`
	model:PivotTo(CFrame.new(origin))
	model.Parent = blocksFolder()

	Assets.playAnimations(model)
	buildBeacon(primary, nokta.Y)

	local sign = Instance.new("BillboardGui")
	sign.Name = "Etiket"
	sign.Size = UDim2.fromOffset(230, 40)
	sign.StudsOffset = Vector3.new(0, 4, 0)
	sign.AlwaysOnTop = true
	sign.MaxDistance = 500
	sign.LightInfluence = 0
	sign.Parent = primary

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Fonts.bold
	label.Text = string.upper(tier.displayName)
	label.TextColor3 = tier.color
	label.TextSize = 24
	label.TextScaled = false
	label.Parent = sign
	Fonts.applyOutline(label)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "AlPrompt"
	prompt.ActionText = "Take"
	prompt.ObjectText = tier.displayName
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = LuckyBlock.Event.pickupDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = primary

	-- Iki oyuncu ayni anda basarsa blok iki kez verilmesin
	local taken = false

	prompt.Triggered:Connect(function(player)
		if taken then
			return
		end
		taken = true
		prompt.Enabled = false

		PlayerData.addLuckyBlocks(player, tier.id, 1)
		Envanter.syncLuckyBlocks(player)
		Envanter.push(player)

		Bildirim:FireClient(
			player,
			`You got a {tier.displayName}! Take it from your backpack and click.`,
			tier.color
		)

		model:Destroy()
	end)

	-- Havada suzul
	task.spawn(function()
		local t = 0
		while model.Parent do
			t += task.wait(0.05)
			model:PivotTo(
				CFrame.new(origin + Vector3.new(0, math.sin(t * 1.5) * 0.4, 0)) * CFrame.Angles(0, t * 1.2, 0)
			)
		end
	end)

	if LuckyBlock.Event.despawn > 0 then
		Debris:AddItem(model, LuckyBlock.Event.despawn)
	end

	return true
end

--[[
	KADEME -> ADA

	En degerli kademe her zaman SONUNCU adaya duser (ulasmasi en zor olan),
	en dusuk kademe ilk adaya. Ada sayisi kademe sayisindan fazla oldugu icin
	aradaki adalar kademeleri paylasir; ornek 5 ada / 3 kademe:

	  1. kum        -> Normal
	  2. candykum   -> Normal
	  3. snowkum    -> Golden
	  4. alevkum    -> Golden
	  5. deniz      -> Diamond
]]
local function tierForIsland(index: number, islandCount: number): string
	local tiers = LuckyBlock.Tiers

	-- Son ada daima en degerli kademe
	if index >= islandCount then
		return tiers[#tiers].id
	end

	local oran = (index - 1) / math.max(1, islandCount)
	local yer = math.clamp(math.floor(oran * #tiers) + 1, 1, #tiers)
	return tiers[yer].id
end

--[[
	YAGMUR

	Her adaya EN COK BIR blok. Adanin kumu Event.islandSands icindeki adla
	bulunur; o adda parca yoksa (harita henuz o adayi tasimiyorsa) ada
	sessizce atlanir.
]]
local function runEvent()
	local E = LuckyBlock.Event
	local adalar = E.islandSands

	local spawned = 0
	for index, sandName in adalar do
		local spot = Sand.randomSpotNamed({ sandName }, rng)
		if not spot then
			continue
		end

		if spawnEventBlock(tierForIsland(index, #adalar), spot) then
			spawned += 1
		end
	end

	if spawned == 0 then
		warn("[LuckyBlock] Etkinlik: hicbir adada kum bulunamadi, blok dusurulemedi")
		return
	end

	Bildirim:FireAllClients(
		`LUCKY BLOCK RAIN! {spawned} blocks dropped on the sand`,
		Rarity.LuckyBlock.colorA
	)

	print(`[LuckyBlock] Etkinlik: {spawned} blok dusuruldu`)
end

--[[
	SAYAC

	Sonraki yagmira kalan sure client'a saniye olarak gonderilir. Client
	kendi icinde geri sayar, sunucu 5 saniyede bir tazeler -- boylece yazi
	akici ilerler ama saat kaymasi birikmez.
]]
local nextEventAt = 0

local function broadcastTimer(target: Player?)
	local remaining = math.max(0, nextEventAt - os.clock())
	if target then
		EtkinlikSayaci:FireClient(target, remaining)
	else
		EtkinlikSayaci:FireAllClients(remaining)
	end
end

if LuckyBlock.Event.enabled then
	task.spawn(function()
		nextEventAt = os.clock() + LuckyBlock.Event.firstDelay
		task.wait(LuckyBlock.Event.firstDelay)

		while true do
			runEvent()
			nextEventAt = os.clock() + LuckyBlock.Event.interval
			task.wait(LuckyBlock.Event.interval)
		end
	end)

	task.spawn(function()
		while true do
			broadcastTimer(nil)
			task.wait(5)
		end
	end)

	-- Yeni giren oyuncu bir sonraki yayini beklemesin
	Players.PlayerAdded:Connect(function(player)
		task.wait(2)
		if player.Parent then
			broadcastTimer(player)
		end
	end)
end

-- Admin panelinden elle tetiklemek icin
function LuckyBlockOdul.runEvent()
	runEvent()
end

------------------------------------------------------------------
-- CARK
------------------------------------------------------------------

--[[
	1. ASAMA bolmeleri: yalnizca KADEME kimlikleri.

	Istemci bunlari "?" olarak cizer, sadece rengi gorunur. Kazanan bolmeye
	gercek kademe, digerlerine blogun kendi tablosundan cekilmis rastgele
	kademeler konur -- boylece serit o blogun dagilimina benzer gorunur.
]]
local function buildRarityCells(tierId: string, winnerIndex: number, winnerRarity: string, ada: string): { string }
	local cells = {}

	for index = 1, LuckyBlock.Wheel.cellCount do
		if index == winnerIndex then
			table.insert(cells, winnerRarity)
		else
			table.insert(cells, Brainrots.clampRarity(LuckyBlock.rollRarity(tierId, rng), ada))
		end
	end

	return cells
end

--[[
	2. ASAMA bolmeleri: SADECE kazanan kademedeki brainrotlar.

	Kademe artik belli oldugu icin bu serit tek renktir; oyuncu "kirmizidan
	hangisi cikacak" diye bekler. Kazanan bolmede gercek odul, digerlerinde
	ayni havuzdan baska brainrotlar durur.
]]
local function buildBrainrotCells(
	rarityId: string,
	winnerIndex: number,
	winnerName: string,
	ada: string
): { { name: string, rarity: string } }
	local cells = {}

	for index = 1, LuckyBlock.Wheel.revealCellCount do
		if index == winnerIndex then
			table.insert(cells, { name = winnerName, rarity = rarityId })
		else
			local info = Brainrots.rollIsland(rarityId :: any, ada, rng)
			table.insert(cells, { name = info.name, rarity = rarityId })
		end
	end

	return cells
end

local function openBlock(player: Player, tierId: string)
	if opening[player] then
		return
	end

	if not LuckyBlock.exists(tierId) then
		return
	end

	local data = PlayerData.get(player)
	if not data or PlayerData.luckyBlockCount(player, tierId) < 1 then
		Bildirim:FireClient(player, "You do not have that kind of Lucky Block.", Color3.fromRGB(255, 200, 90))
		return
	end

	local tier = LuckyBlock.get(tierId)

	opening[player] = true
	PlayerData.addLuckyBlocks(player, tierId, -1)
	-- Cantadaki Tool'un uzerindeki adet hemen guncellensin
	Envanter.syncLuckyBlocks(player)

	-- Odul: kademe, brainrot, kondisyon ve mutasyon burada belirlenir
	--[[
		Oyuncunun ulastigi adaya KADAR olan havuz. Cekilen kademenin o adaya
		kadar brainrotu yoksa en yakin alt kademeye inilir.
	]]
	local ada = PlayerData.reachedIsland(player)
	local rarityId = Brainrots.clampRarity(LuckyBlock.rollRarity(tierId, rng), ada)
	local info = Brainrots.rollIsland(rarityId :: any, ada, rng)
	local condition = Condition.roll(rng)
	local mutation = LuckyBlock.rollMutation(tierId, rng)

	local item = PlayerData.addBrainrot(player, rarityId, condition, mutation)
	if not item then
		opening[player] = false
		return
	end

	-- Lucky Block'tan cikan brainrot ACIK gelir: Detective'e gitmeye gerek yok
	item.name = info.name
	item.revealed = true

	-- Gorev panosu: blok acildi, icinden de bir brainrot cikti
	GorevTakip.ilerlet(player, "lucky", 1)
	GorevTakip.ilerlet(player, "collect", 1, rarityId)

	--[[
		Odul VERIYE hemen yaziliyor (cark donerken oyuncu cikarsa kaybolmasin)
		ama cantaya ve envanter ekranina cark DURUNCA yansitiliyor. Yoksa
		brainrot daha cark donmeye baslar baslamaz envanterde beliriyor ve
		surpriz kaliyor.
	]]

	local income = Brainrots.income(info.name, condition, mutation :: any)
	local winner = {
		name = info.name,
		rarity = rarityId,
		condition = condition,
		mutation = mutation,
		income = income,
	}

	local W = LuckyBlock.Wheel

	LuckyBlockSonuc:FireClient(player, {
		-- 1. asama: kademe carki ("?" bolmeler, sadece renk)
		rarityCells = buildRarityCells(tierId, W.winnerIndex, rarityId),
		rarityWinnerIndex = W.winnerIndex,
		raritySpinTime = W.spinTime,
		pause = W.pause,

		-- 2. asama: o kademedeki brainrotlarin carki
		cells = buildBrainrotCells(rarityId, W.revealWinnerIndex, info.name),
		winnerIndex = W.revealWinnerIndex,
		spinTime = W.revealSpinTime,

		winner = winner,
		tierName = tier.displayName,
		tierColor = tier.color,
		remaining = PlayerData.luckyBlockCount(player, tierId),
	})

	--[[
		Iki cark da durunca: odul cantaya girer, envanter tazelenir,
		bildirim cikar. Sure LuckyBlock.totalSpinTime()'dan geliyor --
		istemci de ayni degerlerle ciziyor, boylece bildirim cark durmadan
		once cikip sonucu ele veremez.
	]]
	task.delay(LuckyBlock.totalSpinTime(), function()
		opening[player] = false
		if not player.Parent then
			return
		end

		Envanter.syncBrainrots(player)
		Envanter.push(player)

		local special = Mutations.isSpecial(mutation)
		Bildirim:FireClient(
			player,
			`You got {info.name} {Condition.get(condition).shortName} ({Format.perSecond(income)})`,
			if special then Mutations.color(mutation) else Rarity.color(rarityId)
		)
	end)
end

-- Cantadaki Tool tiklaninca
Tools.onLuckyBlockUsed = openBlock

-- Arayuzden acma (ileride bir buton eklenirse diye duruyor)
LuckyBlockAc.OnServerEvent:Connect(function(player, tierId)
	openBlock(player, if type(tierId) == "string" then tierId else LuckyBlock.Default)
end)

Players.PlayerRemoving:Connect(function(player)
	opening[player] = nil
end)

return LuckyBlockOdul
