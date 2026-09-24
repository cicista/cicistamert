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
local SoundService = game:GetService("SoundService")
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
local Seviye = require(script.Parent:WaitForChild("Seviye"))
local Tools = require(script.Parent:WaitForChild("Tools"))
local Sand = require(script.Parent:WaitForChild("Sand"))
local Patlama = require(script.Parent:WaitForChild("Patlama"))

local Bildirim = Net.event("Bildirim")
local EtkinlikSayaci = Net.event("EtkinlikSayaci")
local LuckyBlockAc = Net.event("LuckyBlockAc")
local LuckyBlockSonuc = Net.event("LuckyBlockSonuc")
local LuckyBlockBasladi = Net.event("LuckyBlockBasladi")

--[[
	ACILIS SESI BEKLEMESI

	Istemci once "LuckyBlock" sesini calar, bitince LuckyBlockBasladi yollar
	ve cark o an donmeye baslar. Odul ve patlama o andan itibaren sayilir.
	Istemci hic yollamazsa (ses yok, baglanti koptu) en fazla bu kadar
	beklenir.
]]
local GIRIS_EN_FAZLA = 8
local carkBasladi: { [Player]: boolean } = {}

LuckyBlockBasladi.OnServerEvent:Connect(function(player)
	carkBasladi[player] = true
end)

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
	LUCKY BLOCK SESI  --  herkes duyar

	Studio'ya elle konan ses ADIYLA bulunur: adinda (bosluk, _ ve - yok
	sayilarak) "luckyblock" gecen ilk Sound. Workspace, SoundService ya da
	ReplicatedStorage icinde olabilir. Bir kez bulunup sablon olarak saklanir.

	Sesin kopyasi sunucuda DOGRUDAN Workspace'e konup calinir: bir parcaya
	bagli olmadigi icin konumsuzdur, haritadaki HERKES ayni sekilde duyar.

	Calar:
	    - Lucky Block yagmurunda bir blok belirince
	    - kazidan Lucky Block cikinca
	    - biri yerdeki blogu alinca
	Ayni anda bircok blok duserse ses ust uste binmesin: en fazla
	SES_ARALIGI saniyede bir.
]]
local SES_ARALIGI = 0.3
local SES_KOPYA_NITELIGI = "LuckyBlockSesKopyasi"

local sesSablonu: Sound? = nil
local sesUyarildi = false
local sonSes = 0

local function luckySesAdi(ad: string): boolean
	local sade = string.lower((string.gsub(ad, "[%s_%-]", "")))
	return string.find(sade, "luckyblock", 1, true) ~= nil
end

local function luckySesi(): Sound?
	if sesSablonu then
		return sesSablonu
	end

	for _, kok in { Workspace :: Instance, SoundService, ReplicatedStorage } do
		for _, d in kok:GetDescendants() do
			if d:IsA("Sound") and luckySesAdi(d.Name) and not d:GetAttribute(SES_KOPYA_NITELIGI) then
				local sablon = d:Clone()
				sablon.Looped = false
				sablon:SetAttribute(SES_KOPYA_NITELIGI, true)
				sesSablonu = sablon
				return sablon
			end
		end
	end

	if not sesUyarildi then
		sesUyarildi = true
		warn('[LuckyBlock] Adinda "Lucky Block" gecen bir Sound bulunamadi (Workspace / SoundService / ReplicatedStorage). Ses olmadan devam ediliyor.')
	end
	return nil
end

function LuckyBlockOdul.sesCal()
	local simdi = os.clock()
	if simdi - sonSes < SES_ARALIGI then
		return
	end

	local sablon = luckySesi()
	if not sablon then
		return
	end
	sonSes = simdi

	local ses = sablon:Clone()
	ses.Parent = Workspace
	ses:Play()
	ses.Ended:Once(function()
		ses:Destroy()
	end)
	Debris:AddItem(ses, 15)
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

	-- Blok ortaya cikti: herkes duyar
	LuckyBlockOdul.sesCal()

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
--[[
	Kademenin gorunum ayari (bkz. Shared > LuckyBlock > Event.gorunum).
	Taninmayan kademe normalin ayarini kullanir.
]]
local function gorunumOf(tierId: string): any
	local g = LuckyBlock.Event.gorunum
	return g[tierId] or g.Normal or { olcek = 1, sutun = 140, kalinlik = 4, isik = 26 }
end

--[[
	GOKYUZU SUTUNU  --  blok haritanin her yerinden gorunsun

	Isik konisi yalnizca yakindan belli oluyordu. Bunun uzerine bir de
	yerden gokyuzune uzanan renkli bir sutun cikiyor: Beam oldugu icin
	her acidan duz gorunuyor, yukari dogru inceliyor ve soluyor.

	Ozel bloklarda (Elmas / Altin) sutun daha uzun ve kalin -- adanin obur
	ucundan bile hangisinin nerede oldugu anlasiliyor.
]]
local function buildSkyColumn(parent: BasePart, groundY: number, tier: any, gorunum: any)
	local yukseklik = gorunum.sutun or 140
	if yukseklik <= 0 then
		return
	end

	local alt = Instance.new("Attachment")
	alt.Name = "SutunAlt"
	alt.Position = Vector3.new(0, groundY - parent.Position.Y, 0)
	alt.Parent = parent

	local ust = Instance.new("Attachment")
	ust.Name = "SutunUst"
	ust.Position = Vector3.new(0, groundY - parent.Position.Y + yukseklik, 0)
	ust.Parent = parent

	local sutun = Instance.new("Beam")
	sutun.Name = "GokSutunu"
	sutun.Attachment0 = alt
	sutun.Attachment1 = ust
	sutun.Width0 = gorunum.kalinlik or 4
	-- Yukari dogru incelir: gokyuzunde eriyip gider
	sutun.Width1 = (gorunum.kalinlik or 4) * 0.35
	sutun.FaceCamera = true
	sutun.LightEmission = 1
	sutun.LightInfluence = 0
	sutun.Color = ColorSequence.new(Color3.new(1, 1, 1), tier.color)
	sutun.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.6, 0.72),
		NumberSequenceKeypoint.new(1, 1),
	})
	sutun.Segments = 4
	sutun.Parent = parent
end

--[[
	OZEL BLOGUN SUSU  --  kivilcimlar ve donen halka

	Elmas ve Altin bloklar normal bloklarin arasinda kaybolmasin diye:
	etraflarinda kademe renginde parcaciklar ucusuyor, altlarinda da
	yavasca donen bir isik halkasi duruyor.
]]
local function buildOzelSus(parent: BasePart, tier: any, gorunum: any)
	if gorunum.kivilcim then
		local ek = Instance.new("Attachment")
		ek.Name = "KivilcimNoktasi"
		ek.Parent = parent

		local kivilcim = Instance.new("ParticleEmitter")
		kivilcim.Name = "Kivilcim"
		kivilcim.Color = ColorSequence.new(Color3.new(1, 1, 1), tier.color)
		kivilcim.LightEmission = 1
		kivilcim.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(1, 0),
		})
		kivilcim.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		kivilcim.Lifetime = NumberRange.new(0.8, 1.6)
		kivilcim.Rate = 26
		kivilcim.Speed = NumberRange.new(2, 5)
		kivilcim.SpreadAngle = Vector2.new(180, 180)
		kivilcim.Rotation = NumberRange.new(0, 360)
		kivilcim.Parent = ek
	end

	if gorunum.halka then
		local halka = Instance.new("Part")
		halka.Name = "Halka"
		halka.Shape = Enum.PartType.Cylinder
		halka.Size = Vector3.new(0.4, 14, 14)
		-- Silindir X ekseninde uzanir: yere yatirmak icin 90 derece cevriliyor
		halka.CFrame = parent.CFrame * CFrame.new(0, -3, 0) * CFrame.Angles(0, 0, math.rad(90))
		halka.Anchored = true
		halka.CanCollide = false
		halka.CastShadow = false
		halka.Material = Enum.Material.Neon
		halka.Color = tier.color
		halka.Transparency = 0.45
		halka.Parent = parent.Parent

		-- Halka blokla birlikte agir agir doner
		task.spawn(function()
			local t = 0
			while halka.Parent and parent.Parent do
				t += task.wait(0.05)
				halka.CFrame = parent.CFrame
					* CFrame.new(0, -3, 0)
					* CFrame.Angles(0, 0, math.rad(90))
					* CFrame.Angles(t * 0.8, 0, 0)
			end
		end)
	end
end

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
--[[
	BU YAGMURDA KIM BLOK ALDI

	Her yagmurun basinda temizleniyor (bkz. runEvent). Oyuncu basina sinir
	Event.oyuncuBasiLimit'te; sinir olmasa bes blogun besini de en hizli
	kosan toplardi.
]]
local etkinlikteAlan: { [Player]: number } = {}

local function spawnEventBlock(tierId: string, spot: Vector3?): boolean
	local nokta = spot or Sand.randomSpot(rng)
	if not nokta then
		return false
	end

	local tier = LuckyBlock.get(tierId)
	local gorunum = gorunumOf(tier.id)
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

	--[[
		OZEL BLOKLAR DAHA IRI

		Elmas ve Altin normal bloklarin bir bucuk katindan buyuk duruyor
		(bkz. Event.gorunum): uzaktan bakan oyuncu hangisinin degerli
		oldugunu boyutundan anliyor.
	]]
	if (gorunum.olcek or 1) ~= 1 then
		pcall(function()
			model:ScaleTo(gorunum.olcek)
		end)
	end

	-- Blok koninin genis agzinin uzerinde durur
	local origin = nokta + Vector3.new(0, LuckyBlock.Event.beaconHeight, 0)
	model.Name = `Etkinlik_{tier.id}`
	model:PivotTo(CFrame.new(origin))
	model.Parent = blocksFolder()

	Assets.playAnimations(model)
	buildBeacon(primary, nokta.Y)
	buildSkyColumn(primary, nokta.Y, tier, gorunum)
	buildOzelSus(primary, tier, gorunum)

	-- Kademe renginde isik: ozel bloklarin menzili daha genis
	local renkliIsik = Instance.new("PointLight")
	renkliIsik.Name = "KademeIsigi"
	renkliIsik.Color = tier.color
	renkliIsik.Range = gorunum.isik or 26
	renkliIsik.Brightness = 4
	renkliIsik.Parent = primary

	-- Blok ortaya cikti: herkes duyar
	LuckyBlockOdul.sesCal()

	--[[
		ETIKET HARITANIN HER YERINDEN GORUNUR

		MaxDistance 500'du: obur adadan bakinca blogun nerede oldugu hic
		belli olmuyordu. Artik sinir yok (AlwaysOnTop zaten acikti, yani
		duvarin arkasindan da gorunuyor) ve ozel bloklarin yazisi daha
		buyuk.
	]]
	local ozel = (gorunum.olcek or 1) > 1

	local sign = Instance.new("BillboardGui")
	sign.Name = "Etiket"
	sign.Size = UDim2.fromOffset(if ozel then 300 else 230, if ozel then 52 else 40)
	sign.StudsOffset = Vector3.new(0, if ozel then 7 else 4, 0)
	sign.AlwaysOnTop = true
	sign.MaxDistance = math.huge
	sign.LightInfluence = 0
	sign.Parent = primary

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Fonts.bold
	label.Text = string.upper(tier.displayName)
	label.TextColor3 = tier.color
	label.TextSize = if ozel then 34 else 24
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

		--[[
			OYUNCU BASINA SINIR. Blok ALINMAMIS sayiliyor: oyuncu hakkini
			doldurmussa blok yerinde kaliyor ve baskasi alabiliyor.
		]]
		local sinir = LuckyBlock.Event.oyuncuBasiLimit
		if sinir > 0 and (etkinlikteAlan[player] or 0) >= sinir then
			Bildirim:FireClient(
				player,
				`You can only take {sinir} Lucky Block per rain -- leave the rest to others!`,
				Color3.fromRGB(255, 200, 90)
			)
			return
		end
		etkinlikteAlan[player] = (etkinlikteAlan[player] or 0) + 1

		taken = true
		prompt.Enabled = false

		PlayerData.addLuckyBlocks(player, tier.id, 1)
		Envanter.syncLuckyBlocks(player)
		Envanter.push(player)

		-- Yerden alindi: ses tekrar calar
		LuckyBlockOdul.sesCal()

		model:Destroy()

		-- Haritada hala alinabilir kac blok kaldi (alinan az once silindi)
		local kalan = 0
		for _, blok in blocksFolder():GetChildren() do
			local alPrompt = blok:FindFirstChild("AlPrompt", true)
			if alPrompt and alPrompt:IsA("ProximityPrompt") and alPrompt.Enabled then
				kalan += 1
			end
		end
		local kalanYazi = if kalan == 0 then "none left" else `{kalan} left`

		Bildirim:FireClient(
			player,
			`You got a {tier.displayName}! Take it from your backpack and click. ({kalanYazi})`,
			tier.color
		)

		-- Herkese: kim aldi, kac tane kaldi
		for _, diger in Players:GetPlayers() do
			if diger ~= player then
				Bildirim:FireClient(diger, `{player.DisplayName} took a {tier.displayName}! {kalanYazi}`, tier.color)
			end
		end
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
	BLOK ZEMINLERI  --  adinda "luckyzemin" gecen parcalar

	Haritadaki ada parcalarinin (Island modelleri) icine konmus isaret
	parcalari. Ad kuralsiz aranir: buyuk/kucuk harf, bosluk, alt cizgi ve
	tire onemsiz -- "LuckyZemin 3", "lucky_zemin", "luckyzemin" hepsi olur.

	Liste her yagmurda yeniden cikariliyor: harita sonradan degisse (yeni
	ada eklense) de dogru calisir, saatte bir yapilan bir tarama.
]]
local function normalAd(ad: string): string
	return string.lower((string.gsub(ad, "[%s_%-]", "")))
end

local function luckyZeminleri(): { BasePart }
	local aranan = normalAd(LuckyBlock.Event.zeminAdi or "luckyzemin")
	local liste: { BasePart } = {}

	for _, node in Workspace:GetDescendants() do
		if node:IsA("BasePart") and string.find(normalAd(node.Name), aranan, 1, true) then
			table.insert(liste, node)
		end
	end

	return liste
end

-- Zeminin UST yuzunun ortasi: blok parcanin icine gomulmesin
local function zeminNoktasi(zemin: BasePart): Vector3
	return (zemin.CFrame * CFrame.new(0, zemin.Size.Y / 2, 0)).Position
end

--[[
	YAGMUR

	Bloklar "luckyzemin" parcalarinin uzerine duser. Liste karistirilip
	bastan kullanildigi icin HER ZEMINE EN COK BIR BLOK gelir: ayni yerde
	iki blok olmaz, zeminlerin de hepsi dolmaz (fazlasi bos kalir).

	Kac blok dusecegi Event.blokSayisi'nda; her blogun kademesi AYRI
	cekiliyor (bkz. LuckyBlock.etkinlikKademesi): hepsi Normal olarak
	baslar, her biri kendi sansiyla Golden / Diamond / Hacker'a donebilir.

	Hic "luckyzemin" yoksa eski davranisa donulur: her adanin kumuna bir
	blok (Event.islandSands) -- ve Output'a neden oldugunu yazan bir uyari.
]]
local function runEvent()
	local E = LuckyBlock.Event

	--[[
		YENI YAGMUR, YENI HAK: gecen yagmurda blok almis oyuncular yeniden
		alabilir (bkz. etkinlikteAlan).
	]]
	table.clear(etkinlikteAlan)

	-- Her blogun kademesi kendi cekilisinden
	local sira: { string } = {}
	for _ = 1, E.blokSayisi do
		table.insert(sira, LuckyBlock.etkinlikKademesi(rng))
	end

	local zeminler = luckyZeminleri()

	-- YEDEK: zemin yoksa eski ada-kumu dagilimi
	if #zeminler == 0 then
		warn(
			`[LuckyBlock] Etkinlik: adinda "{E.zeminAdi}" gecen parca bulunamadi -- `
				.. "bloklar eski duzenle adalarin kumuna dusuyor. Ada parcalarinin icine "
				.. "luckyzemin adinda parcalar koy."
		)

		local dusen = 0
		for index, sandName in E.islandSands do
			local spot = Sand.randomSpotNamed({ sandName }, rng)
			if spot and spawnEventBlock(tierForIsland(index, #E.islandSands), spot) then
				dusen += 1
			end
		end

		if dusen > 0 then
			Bildirim:FireAllClients(
				`LUCKY BLOCK RAIN! {dusen} blocks dropped on the sand`,
				Rarity.LuckyBlock.colorA
			)
		end
		return
	end

	-- Zeminleri karistir (Fisher-Yates): her yagmurda baska yerler dolsun
	for i = #zeminler, 2, -1 do
		local j = rng:NextInteger(1, i)
		zeminler[i], zeminler[j] = zeminler[j], zeminler[i]
	end

	local spawned = 0
	local ozel = 0
	for index, tierId in sira do
		local zemin = zeminler[index]
		if not zemin then
			-- Zemin kalmadi: geri kalan bloklar bu etkinlikte dusmez
			break
		end

		if spawnEventBlock(tierId, zeminNoktasi(zemin)) then
			spawned += 1
			if tierId ~= LuckyBlock.Default then
				ozel += 1
			end
		end
	end

	if spawned == 0 then
		warn("[LuckyBlock] Etkinlik: zeminler bulundu ama hicbir blok dusurulemedi")
		return
	end

	--[[
		BASLANGIC BILDIRIMI

		Ne yapmasi gerektigini soyluyor: bloklar adalara dagiliyor, en hizli
		yol flyboard. Kac tanesinin ozel oldugu da yaziyor -- ozel yoksa o
		kisim hic gorunmuyor, "0 special" umut kirici duruyordu.
	]]
	local ozelYazi = if ozel > 0 then ` ({ozel} special!)` else ""
	Bildirim:FireAllClients(
		`LUCKY BLOCK RAIN STARTED! {spawned} blocks on the islands{ozelYazi} -- `
			.. "hop on your flyboard and hunt them down!",
		Rarity.LuckyBlock.colorA
	)

	print(`[LuckyBlock] Etkinlik: {spawned} blok / {#zeminler} zemin ({ozel} ozel)`)
end

--[[
	NE ZAMAN YAGAR  --  oyuncu sayisi + bekleme

	Iki sart birden:
	  1. Sunucuda Event.gerekenOyuncu kadar kisi olacak (6/6)
	  2. Son yagmurun uzerinden Event.interval gecmis olacak (1 saat)

	Ikisi de tamamlaninca Event.geriSayim saniyelik bir sayim basliyor --
	ekrandaki bilgi kutusu "DROPPING SOON" yazip herkesi hazirliyor -- ve
	bloklar duruyor. Sayim baslamissa biri cikip sayi 5'e duse bile yagmur
	iptal edilmiyor: oyuncular son saniyede birbirini oyundan atmasin.

	SAYAC EKRANI
	Durum iki saniyede bir herkese yollaniyor: kac kisi var, kac gerekiyor,
	bekleme ne kadar kaldi, sayim basladi mi. Istemci arasini kendi sayiyor
	(bkz. StarterPlayerScripts > Menuler > blok yagmuru bilgisi).
]]
local sonEtkinlik = 0
--[[
	SAYIM MUTLAK BITIS ANIYLA TUTULUYOR

	Once her saniye bir sayac azaltiliyordu ve istemci de kendi kopyasini
	ayrica azaltiyordu: iki ayri saat. task.wait(1) her turda birazcik
	geciktigi icin sunucunun sayisi geride kaliyor, istemcininki ileri
	gidiyor ve her yayinda sayi ileri geri ziplayarak duzeliyordu
	(10 -> 11 -> 9 ...).

	Artik tek gercek var: sayimin BITECEGI an. Kalan sure her sorulusta
	ondan hesaplaniyor, yani kimse kimseyi kovalamiyor.

	0 = sayim yok.
]]
local sayimBitis = 0

-- Kalan saniye (kusuratli); sayim yoksa -1
local function sayimKalani(): number
	if sayimBitis <= 0 then
		return -1
	end
	return math.max(0, sayimBitis - os.clock())
end

--[[
	SAHTE OYUNCU SAYISI  --  yalnizca sinama icin

	Admin panelinden "sunucuda 4/5/6 kisi varmis gibi davran" denince
	buraya yaziliyor (0 = kapali, gercek sayi kullanilir). Tek basina
	test ederken bildirimin 4'te cikip 3'te kaybolmasini ve 6'da sayimin
	baslamasini gormenin baska yolu yok.
]]
local sahteOyuncu = 0

local function oyuncuSayisi(): number
	return if sahteOyuncu > 0 then sahteOyuncu else #Players:GetPlayers()
end

local function etkinlikDurumu(): { [string]: any }
	local E = LuckyBlock.Event
	return {
		oyuncu = oyuncuSayisi(),
		gereken = E.gerekenOyuncu,
		-- Kutu bu sayidan itibaren gorunur
		esik = E.bildirimOyuncu,
		-- Bir sonraki yagmurun serbest kalmasina kalan sure
		bekleme = math.max(0, (sonEtkinlik + E.interval) - os.clock()),
		-- Sayim basladiysa kalan saniye, yoksa -1
		sayim = sayimKalani(),
	}
end

local function broadcastTimer(target: Player?)
	local durum = etkinlikDurumu()
	if target then
		EtkinlikSayaci:FireClient(target, durum)
	else
		EtkinlikSayaci:FireAllClients(durum)
	end
end

if LuckyBlock.Event.enabled then
	task.spawn(function()
		local E = LuckyBlock.Event

		-- Sunucu yeni acildi: ilk yagmur icin kisa bir nefes payi
		sonEtkinlik = os.clock() - E.interval + E.firstDelay

		while true do
			task.wait(2)

			local durum = etkinlikDurumu()
			if durum.oyuncu < durum.gereken or durum.bekleme > 0 then
				continue
			end

			--[[
				Sunucu doldu: bes dakikalik sayim basliyor. Sayi dakika
				olarak yaziliyor, "300s" kimseye bir sey anlatmiyor.
			]]
			sayimBitis = os.clock() + E.geriSayim
			local dakika = math.floor(E.geriSayim / 60)
			Bildirim:FireAllClients(
				`LUCKY BLOCK RAIN in {if dakika > 0 then `{dakika} min` else `{E.geriSayim}s`}! `
					.. `Server is full ({durum.gereken}/{durum.gereken})`,
				Rarity.LuckyBlock.colorA
			)

			--[[
				Yayin yarim saniyede bir: istemci arayi kendi icinde
				dolduruyor ama iki yayin arasi cok acilirsa sayi
				kayabilirdi. Sayimin ne zaman bitecegi mutlak oldugu icin
				bu dongunun kendi hizinin bir onemi yok.
			]]
			while sayimKalani() > 0 do
				broadcastTimer(nil)
				task.wait(0.5)
			end

			sayimBitis = 0
			sonEtkinlik = os.clock()
			runEvent()
			broadcastTimer(nil)
		end
	end)

	task.spawn(function()
		while true do
			broadcastTimer(nil)
			task.wait(2)
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

--[[
	SAHTE OYUNCU SAYISINI AYARLA (admin paneli).
	0 verilince gercek sayiya donulur.
]]
function LuckyBlockOdul.sahteOyuncuAyarla(sayi: number): number
	sahteOyuncu = math.max(0, math.floor(sayi))
	-- Degisiklik ekranlara hemen yansisin
	broadcastTimer(nil)
	return sahteOyuncu
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
	Seviye.xpVer(player, Seviye.XP.luckyBlock)

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

	carkBasladi[player] = nil
	LuckyBlockSonuc:FireClient(player, {
		-- 1. asama: kademe carki ("?" bolmeler, sadece renk)
		rarityCells = buildRarityCells(tierId, W.winnerIndex, rarityId, ada),
		rarityWinnerIndex = W.winnerIndex,
		raritySpinTime = W.spinTime,
		pause = W.pause,

		-- 2. asama: o kademedeki brainrotlarin carki
		cells = buildBrainrotCells(rarityId, W.revealWinnerIndex, info.name, ada),
		winnerIndex = W.revealWinnerIndex,
		spinTime = W.revealSpinTime,

		winner = winner,
		-- Kimlik de gidiyor: istemci carkta blogun modelini gosteriyor
		tier = tierId,
		tierName = tier.displayName,
		-- Hacker gibi turlerde carkin TUM bolmeleri bu mutasyonla cizilir
		tierMutation = tier.zorunluMutasyon,
		tierColor = tier.color,
		remaining = PlayerData.luckyBlockCount(player, tierId),
	})

	--[[
		Iki cark da durunca: odul cantaya girer, envanter tazelenir,
		bildirim cikar. Sure LuckyBlock.totalSpinTime()'dan geliyor --
		istemci de ayni degerlerle ciziyor, boylece bildirim cark durmadan
		once cikip sonucu ele veremez.
	]]
	task.spawn(function()
		-- Istemcinin acilis sesi bitene kadar bekle
		local basla = os.clock()
		while not carkBasladi[player] and player.Parent and os.clock() - basla < GIRIS_EN_FAZLA do
			task.wait(0.05)
		end
		carkBasladi[player] = nil

		-- Ikinci cark durdugu an: FuseExplosion + kademe renginde FuseVFX
		task.delay(W.spinTime + W.pause + W.revealSpinTime, function()
			if player.Parent then
				Patlama.oynat(player, rarityId)
			end
		end)

		task.wait(LuckyBlock.totalSpinTime())
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
