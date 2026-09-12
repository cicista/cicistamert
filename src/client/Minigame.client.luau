--[[
	Minigame  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Minigame

	Stardew Valley balik minioyununun kazi hali.

	Dusey bir cubukta:
	  - Yesil bar oyuncunun kontrolunde: tusa/ekrana BASILI TUTUNCA yukari cikar,
	    birakinca yercekimiyle duser
	  - Brainrot ikonu kacar; rarity yukseldikce daha sik ve daha sert sicrar
	  - Ikon barin icindeyken sagdaki ilerleme dolar, disindayken geriler
	  - Ilerleme dolarsa brainrot yakalanir, sifirlanirsa kacar

	Kurek leveli barin boyunu ve tepkiselligini artirir, gerilemeyi yavaslatir;
	yani yuksek level kurek yuksek rarity brainrotlari tutulabilir kilar.
	Butun bu dengeler Shared > Shovels, Shared > Rods ve Shared > Rarity icinde ayarlanir.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DigMinigame = require(Shared:WaitForChild("DigMinigame"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local KaziMinigame = require(Shared:WaitForChild("KaziMinigame"))
local Net = require(Shared:WaitForChild("Net"))

local UI = require(script.Parent:WaitForChild("UI"))

local MinigameBasla = Net.event("MinigameBasla")
local MinigameSonuc = Net.event("MinigameSonuc")
local KaziBitti = Net.event("KaziBitti")

local ACTION_NAME = "KaziMinigameTut"

------------------------------------------------------------------
-- ARAYUZ
------------------------------------------------------------------
local screen = Instance.new("ScreenGui")
screen.Name = "KaziMinigame"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Enabled = false
screen.Parent = playerGui

--[[
	PENCERE SAGDA DURUR

	Ortada durdugunda karakteri ve savurma animasyonunu kapatiyordu.
	Sagda: sol yari serbest kalir, oyuncu hem kendini hem girdabi gorur.

	AnchorPoint sag kenara sabitlendigi icin panel her ekran genisliginde
	kenardan ayni uzaklikta durur.
]]
local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(1, 0.5)
root.Position = UDim2.new(1, -48, 0.5, 0)
root.Size = UDim2.fromOffset(300, 580)
root.BackgroundColor3 = UI.Colors.panel
root.BackgroundTransparency = 0.08
root.BorderSizePixel = 0
root.Parent = screen
UI.corner(root, 16)

local rootStroke = UI.stroke(root, UI.Colors.accent, 2)

local header = UI.text({
	text = "",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -24, 0, 32),
	position = UDim2.fromOffset(12, 14),
	parent = root,
	name = "Baslik",
})

local subHeader = UI.text({
	text = "Hold the key and keep the brainrot inside the bar",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -24, 0, 20),
	position = UDim2.fromOffset(12, 48),
	parent = root,
	name = "AltBaslik",
})

-- Dusey kacis cubugu
local track = Instance.new("Frame")
track.Name = "Track"
track.AnchorPoint = Vector2.new(0.5, 0)
track.Position = UDim2.new(0.42, 0, 0, 84)
track.Size = UDim2.fromOffset(84, 460)
track.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
track.BorderSizePixel = 0
track.ClipsDescendants = true
track.Parent = root
UI.corner(track, 12)

-- Oyuncunun kontrol ettigi yesil bar
local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.AnchorPoint = Vector2.new(0.5, 0.5)
bar.Size = UDim2.new(1, -12, 0, 60)
bar.Position = UDim2.fromScale(0.5, 0.5)
bar.BackgroundColor3 = Color3.fromRGB(86, 206, 122)
bar.BackgroundTransparency = 0.25
bar.BorderSizePixel = 0
bar.Parent = track
UI.corner(bar, 8)

-- Kacan brainrot ikonu: yazisiz, sabit kirmizi-turuncu blok
local TARGET_COLOR = Color3.fromRGB(255, 108, 40)

local target = Instance.new("Frame")
target.Name = "Target"
target.AnchorPoint = Vector2.new(0.5, 0.5)
target.Size = UDim2.fromOffset(44, 44)
target.Position = UDim2.fromScale(0.5, 0.5)
target.BackgroundColor3 = TARGET_COLOR
target.BorderSizePixel = 0
target.Parent = track
UI.corner(target, 10)

UI.stroke(target, Color3.fromRGB(255, 168, 90), 2)

-- Ilerleme cubugu (sagda)
local progressTrack = Instance.new("Frame")
progressTrack.Name = "ProgressTrack"
progressTrack.AnchorPoint = Vector2.new(0.5, 0)
progressTrack.Position = UDim2.new(0.82, 0, 0, 84)
progressTrack.Size = UDim2.fromOffset(26, 460)
progressTrack.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
progressTrack.BorderSizePixel = 0
progressTrack.ClipsDescendants = true
progressTrack.Parent = root
UI.corner(progressTrack, 10)

local progressFill = Instance.new("Frame")
progressFill.Name = "Fill"
progressFill.AnchorPoint = Vector2.new(0.5, 1)
progressFill.Position = UDim2.fromScale(0.5, 1)
progressFill.Size = UDim2.new(1, 0, 0.35, 0)
progressFill.BackgroundColor3 = UI.Colors.good
progressFill.BorderSizePixel = 0
progressFill.Parent = progressTrack
UI.corner(progressFill, 10)

------------------------------------------------------------------
-- KUM MODU: DIKEY BAR
--
-- Kum kazisinda PANEL YOK. Bar ekranin SAGINDA dikey durur; uzerinde
-- kurek ikonu ilerleme cizgisinde gezer. Deniz penceresi (root) o sirada
-- tamamen gizlenir.
------------------------------------------------------------------
local KUREK_IKONU = "rbxassetid://82895822894928"

-- Ikonun dinlenme boyu; vurusta bunun uzerine cikar
local IKON_BOY = 96

--[[
	IKONUN DURUS ACISI

	Resim kendi icinde DIKEY cizilmis; oldugu gibi birakilinca kurek bara
	dik duruyor ve ilerleme cizgisini kesiyordu. 90 derece cevrilince
	cizgiyle ayni yone, YATAY yatiyor.

	Yon ters gelirse -90 yap.
]]
local IKON_ACI = 90

-- Barin sag kenardan uzakligi: sag alttaki ayarlar dugmesiyle cakismasin
local SAG_BOSLUK = 150

-- Alttaki kaybetme bolgesi: imlec buraya inerse brainrot kacmak uzeredir
local TEHLIKE_ORANI = 0.16

local kaziEkran = Instance.new("ScreenGui")
kaziEkran.Name = "KaziBar"
kaziEkran.ResetOnSpawn = false
kaziEkran.IgnoreGuiInset = true
kaziEkran.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
kaziEkran.Enabled = false
kaziEkran.Parent = playerGui

local kaziCerceve = Instance.new("Frame")
kaziCerceve.Name = "Cerceve"
kaziCerceve.AnchorPoint = Vector2.new(1, 0.5)
kaziCerceve.Position = UDim2.new(1, -SAG_BOSLUK, 0.5, 0)
kaziCerceve.Size = UDim2.fromOffset(74, 430)
kaziCerceve.BackgroundColor3 = Color3.fromRGB(74, 55, 36)
kaziCerceve.BorderSizePixel = 0
kaziCerceve.ClipsDescendants = true
kaziCerceve.Parent = kaziEkran
UI.corner(kaziCerceve, 6)
UI.stroke(kaziCerceve, Color3.fromRGB(0, 0, 0), 4)

--[[
	KUMSU ZEMIN

	Bos kisim duz kahve durmasin diye uzerine iki egik gecis biniyor:
	biri koyu cizgiler, digeri acik parlamalar. Tek renk yerine tanecikli
	bir kum hissi veriyor.
]]
local function dokuKat(parent: Instance, renk: Color3, saydam: number, aci: number, sikilik: number)
	local kat = Instance.new("Frame")
	kat.Name = "Doku"
	kat.Size = UDim2.fromScale(1, 1)
	kat.BackgroundColor3 = renk
	kat.BackgroundTransparency = saydam
	kat.BorderSizePixel = 0
	kat.ZIndex = 2
	kat.Parent = parent

	--[[
		Tanecik: gecise bol sayida ANI saydamlik duragi konuyor. Yumusak
		bir gecis yerine kesik kesik seritler olusuyor, goz bunu doku
		olarak okuyor.
	]]
	local stops = {}
	for i = 0, sikilik do
		local t = i / sikilik
		local acikMi = i % 2 == 0
		table.insert(stops, NumberSequenceKeypoint.new(t, if acikMi then 0 else 1))
	end

	local gecis = Instance.new("UIGradient")
	gecis.Rotation = aci
	gecis.Transparency = NumberSequence.new(stops)
	gecis.Parent = kat

	return kat
end

dokuKat(kaziCerceve, Color3.fromRGB(38, 27, 16), 0.55, 28, 17)
dokuKat(kaziCerceve, Color3.fromRGB(214, 184, 132), 0.82, -14, 11)

--[[
	Dolan kisim: ASAGIDAN yukari buyur ve rengi kazilan brainrotun kademe
	rengidir, yani oyuncu ne pesinde oldugunu bara bakarak anlar.
]]
local kaziDolgu = Instance.new("Frame")
kaziDolgu.Name = "Dolgu"
kaziDolgu.AnchorPoint = Vector2.new(0.5, 1)
kaziDolgu.Position = UDim2.fromScale(0.5, 1)
kaziDolgu.Size = UDim2.fromScale(1, 0)
kaziDolgu.BackgroundColor3 = UI.Colors.good
kaziDolgu.BorderSizePixel = 0
kaziDolgu.ZIndex = 3
kaziDolgu.Parent = kaziCerceve

-- Dolgu da duz kalmasin: ayni tanecik iki kat halinde uzerine biner
dokuKat(kaziDolgu, Color3.fromRGB(0, 0, 0), 0.7, 28, 17).ZIndex = 4
dokuKat(kaziDolgu, Color3.fromRGB(255, 255, 255), 0.86, -14, 11).ZIndex = 4

--[[
	KAYBETME BOLGESI

	Barin ALT ucundaki siyah alan. Imlec buraya inerse brainrot kacmak
	uzeredir; oyuncunun "ne kadar yakinim" sorusunu bakar bakmaz
	cevaplamasi icin var.
]]
local kaziTehlike = Instance.new("Frame")
kaziTehlike.Name = "Tehlike"
kaziTehlike.AnchorPoint = Vector2.new(0.5, 1)
kaziTehlike.Position = UDim2.fromScale(0.5, 1)
kaziTehlike.Size = UDim2.fromScale(1, TEHLIKE_ORANI)
kaziTehlike.BackgroundColor3 = Color3.fromRGB(10, 8, 6)
kaziTehlike.BackgroundTransparency = 0.15
kaziTehlike.BorderSizePixel = 0
kaziTehlike.ZIndex = 6
kaziTehlike.Parent = kaziCerceve

--[[
	KUREK IKONU

	Dolgunun ucundaki cizgide gezer, yatayda barin TAM ORTASINDA.

	NEDEN AYRI BIR KATMAN
	Cerceve ClipsDescendants: ikon icinde olsaydi bar dolarken kenarlarda
	kirpilirdi. Ama cercevenin DISINA koyup konumu AbsolutePosition ile
	hesaplamak da tutmadi -- ikon cizginin bir tutam USTUNDE kaliyordu.

	Cozum: cerceveyle tipatip ayni yerde duran, arka plani olmayan ve
	KIRPMAYAN bir katman. Ikon onun icinde ORANLA konumlaniyor, yani
	hicbir piksel hesabi yok: 1 - progress dogrudan dolgunun ucu demek.
]]
local kaziKatman = Instance.new("Frame")
kaziKatman.Name = "IkonKatmani"
kaziKatman.AnchorPoint = kaziCerceve.AnchorPoint
kaziKatman.Position = kaziCerceve.Position
kaziKatman.Size = kaziCerceve.Size
kaziKatman.BackgroundTransparency = 1
kaziKatman.ZIndex = 8
kaziKatman.Parent = kaziEkran

local kaziIkon = Instance.new("ImageLabel")
kaziIkon.Name = "Kurek"
kaziIkon.AnchorPoint = Vector2.new(0.5, 0.5)
kaziIkon.Size = UDim2.fromOffset(IKON_BOY, IKON_BOY)
kaziIkon.BackgroundTransparency = 1
kaziIkon.Image = KUREK_IKONU
kaziIkon.Rotation = IKON_ACI
kaziIkon.ZIndex = 8
kaziIkon.Parent = kaziKatman

local hint = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -24, 0, 20),
	position = UDim2.new(0, 12, 1, -30),
	parent = root,
	name = "Ipucu",
})


------------------------------------------------------------------
-- SARSINTI VE IKON VURUSU  (kum modu)
--
-- Ikisi de tek bir "guc" sayisiyla calisir: olay olunca guc yukselir,
-- her karede sonumlenir. Tween yigmak yerine boyle yapiliyor cunku
-- tiklamalar ust uste gelebiliyor -- yigilan tweenler birbirini ezip
-- efekti takilmis gosteriyordu.
------------------------------------------------------------------
local SARSINTI_ADI = "KaziSarsinti"

-- Sarsintinin sonumleme hizi (saniyede kaybedilen guc)
local SONUM = 7

--[[
	Tiklama basina eklenen guc ve tavani.

	Ilk deger 0.35 idi ve sarsinti neredeyse fark edilmiyordu; kazma hissi
	asil buradan geliyor. Fazla gelirse ONCE bunu kucult.
]]
local TIK_GUCU = 1.1
local TIK_TAVAN = 2.6

-- Brainrot cikinca eklenen guc: tiklamadan cok daha sert
local ZAFER_GUCU = 9

local sarsintiGucu = 0
local vurusGucu = 0

-- Vurusun yonu: her tiklamada isaret degisir, kurek bir saga bir sola sallanir
local vurusYon = 1
local sarsintiBagli = false
local rng = Random.new()

--[[
	Kamerayi sarsar.

	Kamera her karede yeniden hesaplandigi icin sarsinti KAMERA
	ADIMINDAN SONRA uygulanmali; yoksa oyunun kendi kamera kodu uzerine
	yazip etkiyi siler. BindToRenderStep'in oncelik sayisi bunun icin.
]]
local function sarsintiyiBagla()
	if sarsintiBagli then
		return
	end
	sarsintiBagli = true

	RunService:BindToRenderStep(SARSINTI_ADI, Enum.RenderPriority.Camera.Value + 1, function(dt)
		sarsintiGucu = math.max(0, sarsintiGucu - dt * SONUM)
		vurusGucu = math.max(0, vurusGucu - dt * SONUM)

		--[[
			IKONUN VURUSU

			Her tiklamada buyur ve egilir. Egilme YONU her tiklamada ters
			cevriliyor (vurusYon): tek yone sallanmak tekduze duruyordu,
			bir saga bir sola sallanmak kazma hareketine benziyor.
		]]
		local v = math.min(vurusGucu, 1)
		kaziIkon.Size = UDim2.fromOffset(IKON_BOY + v * 62, IKON_BOY + v * 62)
		-- Vurus, durus acisinin UZERINE ekleniyor; taban aci hep korunur
		kaziIkon.Rotation = IKON_ACI + vurusYon * v * 38

		if sarsintiGucu <= 0 then
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		local g = sarsintiGucu
		camera.CFrame = camera.CFrame
			* CFrame.new(rng:NextNumber(-g, g) * 0.5, rng:NextNumber(-g, g) * 0.5, 0)
			* CFrame.Angles(0, 0, math.rad(rng:NextNumber(-g, g) * 2.2))
	end)
end

local function sarsintiyiCoz()
	if not sarsintiBagli then
		return
	end
	sarsintiBagli = false
	RunService:UnbindFromRenderStep(SARSINTI_ADI)

	sarsintiGucu = 0
	vurusGucu = 0
	kaziIkon.Size = UDim2.fromOffset(IKON_BOY, IKON_BOY)
	kaziIkon.Rotation = IKON_ACI
end
------------------------------------------------------------------
-- OYUN DONGUSU
------------------------------------------------------------------
--[[
	IKI MOD, TEK PENCERE

	  "sea"   Stardew tarzi bar/hedef oyunu (DigMinigame) -- OLTA
	  "sand"  tiklama oyunu (KaziMinigame)                -- KUREK

	Hangisinin acik oldugunu sunucu soyluyor (MinigameBasla'nin son
	parametresi). Ayni anda yalnizca biri dolu olur.
]]
-- Kum barinin rengi: kazilan brainrotun kademe rengi (modKur ayarlar)
local kaziRenk = UI.Colors.good

local mod: string = "sea"
local active: DigMinigame.Minigame? = nil
local kazi: KaziMinigame.Game? = nil
local holding = false
local connection: RBXScriptConnection? = nil

-- Tiklama sinirina takilinca kisa bir uyari gosterilir
local throttleUntil = 0

local function calisiyor(): boolean
	return active ~= nil or kazi ~= nil
end

--[[
	KAZMA ANIMASYONU

	Kurek Tool'unun uzerine sunucuda yazilan "DigAnimation" niteligini okur
	ve minigame SURESINCE dongu halinde oynatir; minigame biter bitmez durur.

	Id tek bir yerden geliyor: Shared > Assets > Animations > shovelDig.
	Orasi bos birakildigi surece nitelik hic yazilmaz ve burasi sessizce
	atlanir -- yani animasyon hazir olmadan da oyun calisir.

	Oncelik tutma animasyonundan (Action) bir kademe YUKSEK: kazarken kazma
	pozu tutma pozunu ezmeli.
]]
local digTrack: AnimationTrack? = nil

local function stopDigAnimation()
	if digTrack then
		digTrack:Stop(0.15)
		digTrack:Destroy()
		digTrack = nil
	end
end

local function startDigAnimation()
	stopDigAnimation()

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not character or not animator then
		return
	end

	-- Elde kurek var mi, uzerinde kazma animasyonu tanimli mi
	local id: string? = nil
	for _, item in character:GetChildren() do
		if item:IsA("Tool") and item:GetAttribute("ShovelId") then
			id = item:GetAttribute("DigAnimation") :: string?
			break
		end
	end

	if not id or id == "" then
		return
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = id

	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	animation:Destroy()

	if not ok or not track then
		return
	end

	track.Priority = Enum.AnimationPriority.Action2
	track.Looped = true
	track:Play(0.1)
	digTrack = track
end

local function setHolding(value: boolean)
	holding = value
	bar.BackgroundTransparency = if value then 0.1 else 0.3
end

--[[
	BIR TIKLAMA  (yalnizca kum modu)

	Sayilmayan tiklama makro sinirina takilmis demektir: oyun akisini
	degistirmez, yalnizca kisa bir uyari yazisi cikar. Ceza yok -- insan
	eliyle atilan hizli seriler haksiz yere cezalandirilmasin (bkz.
	Shared > KaziMinigame).
]]
local function tikla()
	local oyun = kazi
	if not oyun then
		return
	end

	if not oyun:click() then
		throttleUntil = os.clock() + 0.4
		return
	end

	-- Sayilan her tiklama ekrani sarsar ve kuregi vurdurur
	sarsintiGucu = math.min(TIK_TAVAN, sarsintiGucu + TIK_GUCU)
	vurusGucu = math.min(TIK_TAVAN, vurusGucu + TIK_GUCU)

	-- Sonraki vurus ters yone: kurek bir saga bir sola sallanir
	vurusYon = -vurusYon
end

local function bindInput()
	if mod == "sand" then
		-- Kumda TIKLAMA: yalnizca Begin sayilir, birakma onemsiz
		ContextActionService:BindAction(ACTION_NAME, function(_, state)
			if state == Enum.UserInputState.Begin then
				tikla()
			end
			return Enum.ContextActionResult.Sink
		end, true, Enum.KeyCode.Space, Enum.KeyCode.ButtonA, Enum.UserInputType.MouseButton1)

		ContextActionService:SetTitle(ACTION_NAME, "KAZ")
		return
	end

	-- Denizde BASILI TUTMA
	ContextActionService:BindAction(ACTION_NAME, function(_, state)
		if state == Enum.UserInputState.Begin then
			setHolding(true)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			setHolding(false)
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.Space, Enum.KeyCode.ButtonA, Enum.UserInputType.MouseButton1)

	ContextActionService:SetTitle(ACTION_NAME, "TUT")
end

local function unbindInput()
	ContextActionService:UnbindAction(ACTION_NAME)
	setHolding(false)
end

local function stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	active = nil
	kazi = nil
	unbindInput()
	stopDigAnimation()
	screen.Enabled = false
	kaziEkran.Enabled = false
	sarsintiyiCoz()
end

--[[
	PERFECT rozeti.
	Hedef bastan sona hic yesil barin disina cikmadiysa gosterilir:
	0.5 saniye ekranda kalir ve panel hafifce titrer.
]]
local perfectLabel = UI.text({
	text = "PERFECT!",
	size = UI.Sizes.huge,
	font = UI.Fonts.bold,
	color = Color3.fromRGB(255, 226, 90),
	align = Enum.TextXAlignment.Center,
	-- Panel sagda oldugu icin rozet de onun uzerinde durur, ekran ortasinda degil
	frameSize = UDim2.fromOffset(300, 48),
	anchor = Vector2.new(1, 0.5),
	position = UDim2.new(1, -48, 0.5, 0),
	parent = screen,
	name = "Perfect",
	outline = true,
	zIndex = 20,
})
perfectLabel.Visible = false

-- Hedef bu turda barin disina hic cikti mi
local everLeft = false

local function shakeScreen()
	local origin = root.Position

	task.spawn(function()
		local rng = Random.new()
		for _ = 1, 10 do
			root.Position = origin + UDim2.fromOffset(rng:NextInteger(-5, 5), rng:NextInteger(-5, 5))
			task.wait(0.03)
		end
		root.Position = origin
	end)
end

local function showPerfect()
	perfectLabel.Visible = true
	shakeScreen()

	task.delay(0.5, function()
		perfectLabel.Visible = false
	end)
end

local function finish(won: boolean)
	if not calisiyor() then
		return
	end

	local kumdu = mod == "sand"
	active = nil
	kazi = nil

	if connection then
		connection:Disconnect()
		connection = nil
	end
	unbindInput()
	stopDigAnimation()

	--[[
		KUMDA SONUC

		Panel yok, o yuzden yazi/cerceve gosterisi de yok: geri bildirim
		SARSINTIDAN geliyor. Brainrot cikinca ekran tiklamadakinden cok
		daha sert sarsilir; patlama efektini sunucu oynatiyor (gorev
		odulundekinin aynisi, bkz. KaziSistemi > finishDig).
	]]
	if kumdu then
		if won then
			sarsintiGucu = ZAFER_GUCU
			vurusGucu = TIK_TAVAN
		end

		-- Bar hemen kaybolur, sarsinti sonumlenene kadar surer
		kaziEkran.Enabled = false
		task.delay(0.8, sarsintiyiCoz)

		MinigameSonuc:FireServer(won)
		return
	end

	-- Sonuc gorseli kisa sure ekranda kalir
	rootStroke.Color = if won then UI.Colors.good else UI.Colors.bad
	header.Text = if won then "CAUGHT IT!" else "IT GOT AWAY!"
	-- Kademe gorunumu (parilti / parildama) kalkmali, yoksa rengi ezer
	UI.plainStyle(header, if won then UI.Colors.good else UI.Colors.bad)

	-- PERFECT yalnizca deniz oyununda anlamli: kumda "disari cikma" yok
	if won and not everLeft then
		showPerfect()
	end

	MinigameSonuc:FireServer(won)

	task.delay(0.7, function()
		-- Bu arada yeni bir kazi baslamadiysa kapat
		if not calisiyor() then
			screen.Enabled = false
		end
	end)
end

-- DENIZ: bar/hedef oyununun cizimi
local function render(state: DigMinigame.State)
	-- Cubuk 0..1 -> ekranda ust 0, alt 1 olacak sekilde ters cevrilir
	local barHeight = state.barSize
	bar.Size = UDim2.new(1, -12, barHeight, 0)
	bar.Position = UDim2.fromScale(0.5, 1 - state.barPosition)

	target.Position = UDim2.fromScale(0.5, 1 - state.targetPosition)

	progressFill.Size = UDim2.new(1, 0, state.progress, 0)

	local inside = math.abs(state.targetPosition - state.barPosition) <= state.barSize * 0.5
	if not inside then
		everLeft = true
	end

	progressFill.BackgroundColor3 = if inside then UI.Colors.good else UI.Colors.warn
end

--[[
	KUM: tiklama oyununun cizimi

	Dolan sutun Track'in icinde, yani bar deniz oyunuyla AYNI YERDE.
	Sure gostergesi YOK: oyunun suresi diye bir sey yok, imlec sifirlanana
	kadar surer.
]]
local function renderKazi(state: KaziMinigame.State)
	-- Dolgu asagidan yukari buyur
	kaziDolgu.Size = UDim2.fromScale(1, state.progress)

	--[[
		Kurek ikonu dolgunun UCUNDAKI cizgide, yatayda barin tam ortasinda.

		Katman cerceveyle tipatip ayni yerde oldugu icin oran YETER: dolgu
		asagidan yukari buyuduguna gore cizginin yeri 1 - progress.
	]]
	kaziIkon.Position = UDim2.fromScale(0.5, 1 - state.progress)

	--[[
		Makro sinirina takilan tiklamada dolgu kisa sure sariya doner:
		oyuncu "tikliyorum ama ilerlemiyor" demesin, sebebini gorsun.
	]]
	local kisildi = os.clock() < throttleUntil
	kaziDolgu.BackgroundColor3 = if kisildi then UI.Colors.warn else kaziRenk

	--[[
		Imlec kaybetme bolgesine indiyse orasi belirginlesir: oyuncu
		"kacmak uzere" uyarisini bara bakmadan da kenar goruyle alir.
	]]
	local tehlikede = state.progress <= TEHLIKE_ORANI
	kaziTehlike.BackgroundTransparency = if tehlikede then 0 else 0.15
	kaziTehlike.BackgroundColor3 = if tehlikede
		then Color3.fromRGB(90, 12, 12)
		else Color3.fromRGB(10, 8, 6)
end

--[[
	MODA GORE ARAYUZU HAZIRLA

	Kumda PANEL YOK: deniz penceresi tamamen gizlenir, ekranin altindaki
	yatay bar acilir. Denizde tam tersi.
]]
local function modKur(yeniMod: string, rarityId: string)
	mod = yeniMod
	local kumdu = yeniMod == "sand"

	root.Visible = not kumdu
	kaziEkran.Enabled = kumdu

	if kumdu then
		-- Imlecin rengi kazilan brainrotun kademe rengi
		kaziRenk = Rarity.beamColor(rarityId)
		kaziDolgu.BackgroundColor3 = kaziRenk
		kaziDolgu.Size = UDim2.fromScale(1, KaziMinigame.START)
		sarsintiyiBagla()
	else
		sarsintiyiCoz()
	end
end

MinigameBasla.OnClientEvent:Connect(function(gearId, rarityId, seed, gelenMod)
	if calisiyor() then
		return
	end

	local rarityInfo = Rarity.get(rarityId)
	-- Kumda kurek, denizde olta: hangisi geldiyse ayni yuzden okunur
	local gearInfo = DigMinigame.gear(gearId)

	--[[
		Eski sunucular mod gondermiyordu; gelmezse denize dusuluyor ki
		davranis en azindan taniddik kalsin.
	]]
	modKur(if gelenMod == "sand" then "sand" else "sea", rarityId)

	header.Text = `{rarityInfo.displayName} BRAINROT`
	-- Epic+ parlak, Divine parildar; cerceve kademe renginde kalir
	UI.rarityStyle(header, rarityId)
	rootStroke.Color = rarityInfo.color

	subHeader.Text = `{gearInfo.displayName}  |  Lv.{gearInfo.level}`
	everLeft = false
	perfectLabel.Visible = false
	throttleUntil = 0
	startDigAnimation()

	if mod == "sand" then
		------------------------------------------------------------------
		-- KUM: TIKLAMA OYUNU
		--
		-- Panel acilmaz (screen kapali kalir); yalnizca alttaki yatay bar
		-- gorunur. Baslik/altbaslik yazilari denize ait.
		------------------------------------------------------------------
		local oyun = KaziMinigame.new(gearId, rarityId)
		kazi = oyun
		bindInput()
		renderKazi(oyun.state)

		connection = RunService.RenderStepped:Connect(function(dt)
			local g = kazi
			if not g then
				return
			end

			-- Cok buyuk dt sicramalarini kirp (kare dususu oyunu bozmasin)
			local state = g:step(math.min(dt, 1 / 20))
			renderKazi(state)

			if state.finished then
				finish(state.won)
			end
		end)
		return
	end

	------------------------------------------------------------------
	-- DENIZ: BAR / HEDEF OYUNU
	------------------------------------------------------------------
	screen.Enabled = true
	hint.Text = if UserInputService.TouchEnabled
		then "Touch and hold the screen"
		else "Hold SPACE or left click"

	-- Hedef her rarityde ayni kirmizi-turuncu; rarity rengi baslikta ve cercevede
	target.BackgroundColor3 = TARGET_COLOR

	local oyun = DigMinigame.new(gearId, rarityId, seed)
	active = oyun
	bindInput()
	render(oyun.state)

	connection = RunService.RenderStepped:Connect(function(dt)
		local g = active
		if not g then
			return
		end

		-- Cok buyuk dt sicramalarini kirp (kare dususu oyunu bozmasin)
		local step = math.min(dt, 1 / 20)
		local state = g:step(step, holding)
		render(state)

		if state.finished then
			finish(state.won)
		end
	end)
end)

-- Server kaziyi iptal ederse (uzaklasma, olum vs.)
KaziBitti.OnClientEvent:Connect(function()
	if calisiyor() then
		stop()
	end
end)

-- Karakter olurse minigame kapansin
player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		if calisiyor() then
			MinigameSonuc:FireServer(false)
			stop()
		end
	end)
end)
