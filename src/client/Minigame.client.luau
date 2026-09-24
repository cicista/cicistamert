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
local OtoTiklayici = require(Shared:WaitForChild("OtoTiklayici"))
local Assets = require(Shared:WaitForChild("Assets"))

-- Kazi animasyonlari onceden yuklenir: ilk kazida animasyon gecikip alet bir an duz tutulmasin
task.spawn(function()
	local liste = {}
	for _, ham in { Assets.Animations.shovelDig, Assets.Animations.pickaxeDig } do
		local gercek = Assets.id(ham)
		if gercek then
			local animasyon = Instance.new("Animation")
			animasyon.AnimationId = gercek
			table.insert(liste, animasyon)
		end
	end
	if #liste > 0 then
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync(liste)
		end)
	end
end)
local Ores = require(Shared:WaitForChild("Ores"))
-- Maden kazisindaki kazma resmi Assets > Icons klasorunden okunuyor
local Icons = require(Shared:WaitForChild("Icons"))
local Net = require(Shared:WaitForChild("Net"))

local UI = require(script.Parent:WaitForChild("UI"))

local MinigameBasla = Net.event("MinigameBasla")
local MinigameSonuc = Net.event("MinigameSonuc")
local KaziBitti = Net.event("KaziBitti")
-- Gecis sahipligi oyuncu niteliginden, satin alma sunucudan (bkz. Shared > Passler)
local Passler = require(Shared:WaitForChild("Passler"))
local PassSatinAl = Net.event("PassSatinAl")

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

--[[
	MADEN KAZISINDA KAZMA

	Minioyun madende de aynisi; yalnizca bardaki ikon kurek yerine KAZMA.
	Resim koda yazilmiyor: ReplicatedStorage > Assets > Icons icinde bu adla
	duran ikondan okunuyor (Decal / ImageLabel; ad eslesmesi esnek, bkz.
	Icons > OYUNUN KENDI IKONLARI). Bulunamazsa kurek resmi kalir ve
	Output'a bir kez uyari duser.

	KAZMA_ACI: kazma resmi kendi icinde zaten YATAY cizilmis (basi solda,
	sapi sagda) -- kurek gibi 90 derece cevrilmesine gerek yok. Ters
	gelirse 180 yap.
]]
local KAZMA_IKON_ADI = "pickaxe_icon"
local KAZMA_ACI = 0

-- Su anki kazinin ikon taban acisi: kurekte IKON_ACI, madende KAZMA_ACI
local ikonAci = IKON_ACI
local kazmaUyarisiVerildi = false

--[[
	BAR NEREDE DURUR  --  OTO TIKLAYICI DUGMESININ TAM USTUNDE

	Bar eskiden ekranin sag ortasindaydi ve oradaki Lucky Block yagmuru
	bildirimiyle ust uste biniyordu. Artik konumu kendi basina degil,
	oto tiklayici dugmesine GORE hesaplaniyor: ikisi tek bir yigin, dugme
	nereye tasinirsa bar da onunla gidiyor ve bir daha ayrilmiyorlar.

	Olcu ORAN (0-1), ofset degil: arayuz olcegi nesnelerin boyutunu
	carpiyor ama ofsetini carpmiyor; ofsetle yerlestirilseydi olcek
	degisince bar dugmeden kayardi.
]]
local OTO_X = 0.72
local OTO_Y = 0.8

-- Oto tiklayici kutusunun boyu; bar bunun ustune oturuyor
local OTO_BOY = 92

-- Barla dugme arasinda birakilan bosluk (piksel)
local KAZI_ARA = 14

-- Barin boyu. Dugmeyle ekranin ustu arasina sigacak kadar
local KAZI_BOY = 360

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
-- Alt kenari dugmenin hemen ustunde; yukari dogru uzuyor
kaziCerceve.AnchorPoint = Vector2.new(0.5, 1)
kaziCerceve.Position = UDim2.new(OTO_X, 0, OTO_Y, -(OTO_BOY / 2 + KAZI_ARA))
kaziCerceve.Size = UDim2.fromOffset(74, KAZI_BOY)
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

------------------------------------------------------------------
-- OTOMATIK TIKLAYICI DUGMESI  (yalnizca kum modu)
--
-- Barin SOLUNDA, kurek ikonuyla ayni yukseklikte durur. Uc hali var:
--
--   pass yok         ->  Robux ikonu + fiyat (tiklayinca satin alma penceresi)
--   pass var, kapali ->  "OFF"
--   pass var, acik   ->  "ON"          (kurek kendi kendine vurur)
--
-- Dugme herkeste gorunur (bkz. Shared > Passler).
------------------------------------------------------------------

--[[
	Dugmenin yeri yukarida, barla BIRLIKTE tanimli (OTO_X / OTO_Y): bar
	dugmenin tam ustunde duruyor, ikisi tek yigin.
]]
local otoKutu = Instance.new("Frame")
otoKutu.Name = "OtoTiklayici"
otoKutu.AnchorPoint = Vector2.new(0.5, 0.5)
otoKutu.Position = UDim2.fromScale(OTO_X, OTO_Y)
otoKutu.Size = UDim2.fromOffset(176, OTO_BOY)
otoKutu.BackgroundTransparency = 1
otoKutu.Visible = true
otoKutu.ZIndex = 8
otoKutu.Parent = kaziEkran

UI.text({
	text = "AUTO CLICKER",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 22),
	position = UDim2.fromOffset(0, 0),
	parent = otoKutu,
	name = "Baslik",
})

--[[
	DUGME ELLE KURULUYOR, UI.button KULLANILMIYOR

	UI.hover temel rengi ILK fare temasinda onbellege aliyor ve fare
	cikinca o renge donuyor. Bu dugmenin rengi ise duruma gore
	degisiyor (kirmizi/yesil/altin): oyuncu kirmizi haldeyken uzerine
	gelip tiklasa, dugme yesile donse ve fareyi cekse, hover eski
	KIRMIZIYA geri tweenlerdi.

	O yuzden hover'i burada, her temasta GUNCEL rengi okuyacak sekilde
	kuruyoruz.
]]
local otoDugme = Instance.new("TextButton")
otoDugme.Name = "Dugme"
otoDugme.Position = UDim2.fromOffset(0, 30)
otoDugme.Size = UDim2.new(1, 0, 0, 58)
otoDugme.BackgroundColor3 = UI.Colors.bad
otoDugme.BorderSizePixel = 0
otoDugme.AutoButtonColor = false
otoDugme.Text = ""
otoDugme.ZIndex = 8
otoDugme.Parent = otoKutu
UI.corner(otoDugme, 10)
UI.stroke(otoDugme, Color3.fromRGB(0, 0, 0), 3)

local otoYazi = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = otoDugme,
	name = "Label",
	zIndex = 9,
})

-- Durum rengi burada tutuluyor; hover her seferinde bunu okur
local otoRenk = UI.Colors.bad

otoDugme.MouseEnter:Connect(function()
	otoDugme.BackgroundColor3 = UI.shade(otoRenk, UI.HoverLift)
end)

otoDugme.MouseLeave:Connect(function()
	otoDugme.BackgroundColor3 = otoRenk
end)

--[[
	Pass sahipligi sunucudan gelir; bilinene kadar false sayilir, yani
	dugme "satin al" halinde baslar. Yanlis tarafta hata yapmak bu yon:
	sahip olmayana acik dugme gostermekten iyidir.
]]
local otoSahip = Passler.sahip(player, "AutoClicker")

--[[
	Acik/kapali tercihi.

	Pass alindiktan sonra ACIK baslar -- oyuncu tiklamamak icin para
	verdi, ilk kazisinda bir de dugme aramasin. Kapatabilir ve tercih
	oturum boyunca korunur.
]]
local otoAcik = true

local function otoCalisiyorMu(): boolean
	--[[
		Kurege gore ayrica bir kontrol YOK: tiklayici her kazida calisir.
		Kuregin yetmedigi kademede geri tepme tavanin 2.5 kati oldugu icin
		imlec yine dibe iner ve brainrot kacar -- denge minioyunun kendi
		kuralindan geliyor, tiklayicidan degil.
	]]
	return otoSahip and otoAcik
end

--[[
	FIYAT KUTUSU  --  ikon + sayi

	Pass alinmamisken dugmede "BUY 500 R$" yazisi yerine Robux ikonu ve
	sayi duruyor (bkz. UI.robuxFiyati). Kutu bir kez kuruluyor ve pass
	alininca gizleniyor: her cizimde yeniden kurmak gereksiz.
]]
local otoFiyat: Frame? = nil

local function otoDugmeyiCiz()
	otoKutu.Visible = true

	if not otoSahip then
		local pass = Passler.get("AutoClicker")

		if not otoFiyat then
			otoFiyat = UI.robuxFiyati(otoDugme, if pass then pass.fiyat else 0, UI.Sizes.label, 10)
		end
		local kutu = otoFiyat
		if kutu then
			kutu.Visible = true
		end

		otoYazi.Text = ""
		otoRenk = UI.Colors.gold
		otoDugme.BackgroundColor3 = otoRenk
		return
	end

	local kutu = otoFiyat
	if kutu then
		kutu.Visible = false
	end

	otoYazi.Text = if otoAcik then "ON" else "OFF"
	otoRenk = if otoAcik then UI.Colors.good else UI.Colors.bad
	otoDugme.BackgroundColor3 = otoRenk
end

otoDugmeyiCiz()

otoDugme.Activated:Connect(function()
	--[[
		Pass yoksa dugme satin alma penceresini acar (sunucu uzerinden).
		Satin alininca sunucu niteligi yazar, dugme kendiliginden doner.
	]]
	if not otoSahip then
		PassSatinAl:FireServer("AutoClicker")
		return
	end

	otoAcik = not otoAcik
	otoDugmeyiCiz()
end)

do
	local pass = Passler.get("AutoClicker")
	if pass then
		player:GetAttributeChangedSignal(pass.nitelik):Connect(function()
			otoSahip = Passler.sahip(player, "AutoClicker")
			otoDugmeyiCiz()
		end)
	end
end

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
local ZAFER_GUCU = 7

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
-- Settings > Screen Shake kapaliysa sarsinti yok (nitelik Ayarlar'dan gelir)
local function sarsintiKapali(): boolean
	return game:GetService("Players").LocalPlayer:GetAttribute("SarsintiKapali") == true
end

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
		kaziIkon.Size = UDim2.fromOffset(IKON_BOY + v * 45, IKON_BOY + v * 45)
		-- Vurus, durus acisinin UZERINE ekleniyor; taban aci hep korunur
		kaziIkon.Rotation = ikonAci + vurusYon * v * 27

		if sarsintiGucu <= 0 or sarsintiKapali() then
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
	kaziIkon.Rotation = ikonAci
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

------------------------------------------------------------------
-- OGRETICININ ILK KAZISI
--
-- Yeni oyuncu ilk kazisini KAYBETMEZ: imlec dibe inerse oyun bitmez,
-- imlec en altta bir tutam yukarida tutulur. Geri gitmeyi gorur ve ne
-- yapmasi gerektigini ogrenir, ama brainrotu kacirmaz.
--
-- Bunun yaninda ekranda buyuk "CLICK!" yazilari yanip soner: yeni
-- oyuncunun "tiklamam gerekiyormus" demesi icin.
--
-- Hangi adimda oldugumuz oyuncu niteliginden okunuyor (sunucu yaziyor,
-- bkz. ServerScriptService > Modules > Ogretici).
------------------------------------------------------------------
local OGRETICI_NITELIK = "OgreticiAdim"
local OGRETICI_ADIM = "ilkKazi"
-- Kaybetme yerine imlecin tutulacagi taban
local OGRETICI_TABAN = 0.06

local function ogreticiKazisi(): boolean
	return player:GetAttribute(OGRETICI_NITELIK) == OGRETICI_ADIM
end

-- Barin iki yaninda yanip sonen "CLICK!" yazilari
local tiklaYazilari: { TextLabel } = {}

for i, x in { 0.5 - 0.26, 0.5 + 0.26 } do
	local yazi = UI.text({
		text = "CLICK!",
		size = UI.Sizes.huge,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(255, 240, 120),
		align = Enum.TextXAlignment.Center,
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(x, 0.5),
		frameSize = UDim2.fromOffset(220, 60),
		parent = kaziEkran,
		name = `Tikla{i}`,
	})
	yazi.Visible = false
	yazi.ZIndex = 20
	table.insert(tiklaYazilari, yazi)
end

--[[
	Yazilar sirayla zipladigi icin tek dongu yetiyor: gorunurken her
	karede olcek ve saydamlik hesaplaniyor.
]]
local tiklaZaman = 0

local function tiklaYazisiCiz(dt: number, acik: boolean)
	if not acik then
		for _, yazi in tiklaYazilari do
			yazi.Visible = false
		end
		return
	end

	tiklaZaman += dt
	for i, yazi in tiklaYazilari do
		yazi.Visible = true
		-- Iki yazi sirayla: biri buyurken digeri kuculur
		local nabiz = (math.sin(tiklaZaman * 7 + (i - 1) * math.pi) + 1) * 0.5
		yazi.TextSize = math.floor(UI.Sizes.huge * (0.85 + nabiz * 0.4))
		yazi.TextTransparency = 0.15 - nabiz * 0.15
		yazi.Rotation = (if i == 1 then -8 else 8) * (0.5 + nabiz)
	end
end

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

-- Kazi basinda kapatilan otomatik donme; kazi bitince eski haline doner
local donusHumanoid: Humanoid? = nil
local donusEski: boolean? = nil

local function stopDigAnimation()
	if digTrack then
		digTrack:Stop(0.15)
		digTrack:Destroy()
		digTrack = nil
	end

	if donusHumanoid and donusEski ~= nil and donusHumanoid.Parent then
		donusHumanoid.AutoRotate = donusEski
	end
	donusHumanoid = nil
	donusEski = nil
end

local function startDigAnimation()
	stopDigAnimation()

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not character or not animator then
		return
	end

	--[[
		Elde KAZMA varsa madenin animasyonu (pickaxeDig), KUREK varsa kazinin
		(shovelDig). Ikisi de Shared > Assets > Animations'ta.
	]]
	local id: string? = nil
	-- Alet sunucudan bir kare gec gelebilir: 0.5 saniyeye kadar beklenir
	for deneme = 1, 10 do
		for _, item in character:GetChildren() do
			if item:IsA("Tool") then
				if item:GetAttribute("PickaxeId") then
					id = Assets.id(Assets.Animations.pickaxeDig)
					break
				elseif item:GetAttribute("ShovelId") then
					id = Assets.id(Assets.Animations.shovelDig)
					break
				end
			end
		end
		if id or deneme == 10 then
			break
		end
		task.wait(0.05)
		if not calisiyor() then
			return
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

	--[[
		KAZILAN NOKTAYA DON
		Sunucu kazi basinda karaktere KaziHedef niteligini yaziyor. Karakter o
		noktaya doner ve kazi boyunca kendiliginden donmez; kazi bitince
		(stopDigAnimation) donme eski haline gelir.
	]]
	local humanoidDon = character:FindFirstChildOfClass("Humanoid")
	local kok = character:FindFirstChild("HumanoidRootPart")
	local hedef = character:GetAttribute("KaziHedef")
	if humanoidDon and kok and kok:IsA("BasePart") and typeof(hedef) == "Vector3" then
		donusHumanoid = humanoidDon
		donusEski = humanoidDon.AutoRotate
		humanoidDon.AutoRotate = false
		local bakis = Vector3.new(hedef.X, kok.Position.Y, hedef.Z)
		if (bakis - kok.Position).Magnitude > 0.5 then
			kok.CFrame = CFrame.lookAt(kok.Position, bakis)
		end
	end
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
	if sarsintiKapali() then
		return
	end
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
		-- Madende imlec ADANIN renginde (gemin rengi kristallerde)
		local maden = Ores.get(rarityId)
		kaziRenk = if maden then maden.islandColor else Rarity.beamColor(rarityId)

		-- Madende bardaki ikon KAZMA, digerlerinde KUREK (bkz. KAZMA_IKON_ADI)
		local kazmaResmi = if maden then Icons.asset(KAZMA_IKON_ADI) else nil
		if maden and not kazmaResmi and not kazmaUyarisiVerildi then
			kazmaUyarisiVerildi = true
			warn(
				`[Minigame] Kazma ikonu bulunamadi: ReplicatedStorage > Assets > Icons `
					.. `icine "{KAZMA_IKON_ADI}" adli bir Decal ya da ImageLabel koy. Simdilik kurek gorunuyor.`
			)
		end
		kaziIkon.Image = kazmaResmi or KUREK_IKONU
		ikonAci = if kazmaResmi then KAZMA_ACI else IKON_ACI
		kaziIkon.Rotation = ikonAci
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

	--[[
		Maden kazisinda gelen kimlik bir kademe DEGIL (Amethyst, Ruby...);
		Rarity.get onda hata atardi. Kum modunda imlec rengi zaten
		Rarity.beamColor'dan geliyor ve madenin ada rengini veriyor.
	]]
	local rarityInfo = Rarity.Info[rarityId]
	-- Kumda kurek, denizde olta: hangisi geldiyse ayni yuzden okunur
	local gearInfo = DigMinigame.gear(gearId)

	--[[
		Eski sunucular mod gondermiyordu; gelmezse denize dusuluyor ki
		davranis en azindan taniddik kalsin.
	]]
	modKur(if gelenMod == "sand" then "sand" else "sea", rarityId)

	if rarityInfo then
		header.Text = `{rarityInfo.displayName} BRAINROT`
		-- Epic+ parlak, Divine parildar; cerceve kademe renginde kalir
		UI.rarityStyle(header, rarityId)
		rootStroke.Color = rarityInfo.color
	else
		header.Text = string.upper(Rarity.beamName(rarityId))
		UI.plainStyle(header, Rarity.beamColor(rarityId))
		rootStroke.Color = Rarity.beamColor(rarityId)
	end

	subHeader.Text = `{gearInfo.displayName}  |  Lv.{gearInfo.level}`
	everLeft = false
	perfectLabel.Visible = false
	throttleUntil = 0
	task.spawn(startDigAnimation)

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

		--[[
			Otomatik tiklamanin zaman birikimi. Her minioyunda sifirdan
			baslar -- kapanista kalan artik sure bir sonrakine tasinmasin.
		]]
		local otoBirikim = 0

		connection = RunService.RenderStepped:Connect(function(dt)
			local g = kazi
			if not g then
				return
			end

			-- Cok buyuk dt sicramalarini kirp (kare dususu oyunu bozmasin)
			local step = math.min(dt, 1 / 20)
			local state = g:step(step)

			--[[
				OGRETICI: KAYBETME YOK

				g:step imleci sifira indirip oyunu "kaybedildi" diye
				bitirmis olabilir. Ogreticinin ilk kazisinda bu geri
				alinir: imlec tabanda tutulur, oyun surer. state ile
				g.state ayni tablo oldugu icin duzeltme ayni karede
				gecerli oluyor.
			]]
			local ogreticide = ogreticiKazisi()
			if ogreticide and state.finished and not state.won then
				state.finished = false
				state.won = false
				state.progress = OGRETICI_TABAN
			end

			tiklaYazisiCiz(step, ogreticide and not state.finished)

			--[[
				OTOMATIK TIKLAMA  (pass sahipleri)

				SABIT ARALIKLA tiklanir: saniyede OtoTiklayici.CPS kadar,
				daha hizli DEGIL. Sebebi Shared > OtoTiklayici'da uzun
				uzun yazili; kisaca fazla tiklamanin faydasi yok (jeton
				kovasi yok sayar) ve zarari var (kova bir kerede
				bosalirsa minioyun sunucunun bekledigi alt sinirdan once
				biter).

				state ile g.state AYNI tablo (step kendi state'ini
				donduruyor), bu yuzden tikla() sonrasi yeniden okumaya
				gerek yok -- asagidaki renderKazi ve finished kontrolu
				guncel degeri gorur.
			]]
			if otoCalisiyorMu() then
				otoBirikim += step
				while otoBirikim >= OtoTiklayici.ARALIK do
					otoBirikim -= OtoTiklayici.ARALIK
					tikla()
				end
			end

			renderKazi(state)

			if state.finished then
				tiklaYazisiCiz(step, false)
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
