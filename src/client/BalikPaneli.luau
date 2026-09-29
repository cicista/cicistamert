--!strict
--[[
	BALIK PANELI  (ModuleScript, istemci)
	Yeri: StarterPlayer > StarterPlayerScripts > BalikPaneli

	Denizdeki olta minioyununun ("sea" modu, Shared > DigMinigame) penceresi.
	Oyunun kurallari DigMinigame'de; burasi yalnizca GORUNUM. Minigame
	istemcisi oyunu yurutur, her karede durumu buraya verir.

	    BalikPaneli.basla(gear, rarityId)  -- pencereyi acar, giris gosterisi
	    BalikPaneli.ciz(state, holding)    -- her karede oyun durumunu cizer
	    BalikPaneli.bitir(won)             -- sonuc gosterisi (CAUGHT / GOT AWAY)
	    BalikPaneli.gizle()                -- pencereyi kapatir

	NE VAR
	  - Panel derin deniz renginde; arkasinda kabarciklar yukselir, isik
	    bantlari suzulur, cerceve kademe renginde nefes alir
	  - Su sutununda yakalama bolgesi: balik icerideyken yesil parlar,
	    disaridayken kirmiziya doner
	  - Hedef bir BALIK: kuyrugunu sallar, hizina gore burnunu kaldirir,
	    arkasinda kademe renginde hale var; tepeden inen misinaya takili
	  - Ilerleme cubugunun ucunda donen bir MAKARA: ilerledikce sarar
	  - Ilerleme dusuk ve balik disaridaysa panel kizarir ve titrer
	  - Giriste "FISH ON!", sonucta isik huzmeli "CAUGHT!" + konfeti ya da
	    misina kopar, balik dibe kacar ve panel sarsilir

	Sarsinti Settings > Screen Shake kapaliysa oynamaz (SarsintiKapali).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DigMinigame = require(Shared:WaitForChild("DigMinigame"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))

local BalikPaneli = {}

------------------------------------------------------------------
-- AYARLAR
------------------------------------------------------------------
local PANEL_EN = 250
local PANEL_BOY = 560

-- Su sutunu ve ilerleme cubugunun ust kenari ve boyu
local SUTUN_UST = 84
local SUTUN_BOY = 410

-- Yakalama bolgesinin iki rengi: balik iceride / disarida
local ICERI_RENK = Color3.fromRGB(86, 232, 140)
local DISARI_RENK = Color3.fromRGB(255, 96, 80)

-- Balik govdesi her kademede ayni turuncu: suyun mavisinde hep secilsin
local BALIK_RENK = Color3.fromRGB(255, 118, 44)
local BALIK_KOYU = Color3.fromRGB(222, 72, 26)

local ALTIN = Color3.fromRGB(255, 214, 60)

-- Ilerleme bu oranin altinda ve balik disaridaysa panel tehlike moduna girer
local TEHLIKE_ORANI = 0.3

-- Tam ilerleme (0 -> 1) makarayi kac derece dondurur
local MAKARA_DONUS = 1800

------------------------------------------------------------------
-- YARDIMCILAR
------------------------------------------------------------------
local function tween(nesne: Instance, sure: number, ozellik: { [string]: any }, stil: Enum.EasingStyle?, yon: Enum.EasingDirection?)
	local t = TweenService:Create(
		nesne,
		TweenInfo.new(sure, stil or Enum.EasingStyle.Quad, yon or Enum.EasingDirection.Out),
		ozellik
	)
	t:Play()
	return t
end

local function kutu(ad: string, parent: Instance, z: number): Frame
	local f = Instance.new("Frame")
	f.Name = ad
	f.BorderSizePixel = 0
	f.ZIndex = z
	f.Parent = parent
	return f
end

local function daire(parent: Instance)
	UI.corner(parent, 1000)
end

--[[
	ISIK BANDI KATMANI

	Sutunun iki kati boyunda, yatay yumusak bantlar. Katman yukari kaydikca
	bantlar suyun icinde yukselen isik gibi gorunur. Desen 1/8'lik
	periyotla tekrarlaniyor; katman TAM BIR sutun boyu (katmanin yarisi =
	4 periyot) kayinca basa sariliyor, sicrama gorunmuyor.
]]
local function isikKati(parent: Instance, alfa: number, z: number): Frame
	local kat = kutu("IsikBandi", parent, z)
	kat.Size = UDim2.fromScale(1, 2)
	kat.BackgroundColor3 = Color3.new(1, 1, 1)

	local duraklar = {}
	for i = 0, 16 do
		table.insert(duraklar, NumberSequenceKeypoint.new(i / 16, if i % 2 == 0 then alfa else 1))
	end

	local gecis = Instance.new("UIGradient")
	gecis.Rotation = 90
	gecis.Transparency = NumberSequence.new(duraklar)
	gecis.Parent = kat

	return kat
end

type Kabarcik = {
	nesne: Frame,
	x: number,
	y: number,
	hiz: number,
	faz: number,
}

-- Kabin icinde rastgele yerlerde yukselen kabarciklar
local rng = Random.new()

local function kabarciklar(parent: Instance, sayi: number, enAz: number, enCok: number, saydam: number, z: number): { Kabarcik }
	local liste: { Kabarcik } = {}
	for _ = 1, sayi do
		local boy = rng:NextInteger(enAz, enCok)
		local k = kutu("Kabarcik", parent, z)
		k.AnchorPoint = Vector2.new(0.5, 0.5)
		k.Size = UDim2.fromOffset(boy, boy)
		k.BackgroundColor3 = Color3.fromRGB(200, 240, 255)
		k.BackgroundTransparency = saydam
		daire(k)
		local kontur = UI.stroke(k, Color3.new(1, 1, 1), 1)
		kontur.Transparency = 0.35

		table.insert(liste, {
			nesne = k,
			x = rng:NextNumber(0.08, 0.92),
			y = rng:NextNumber(0, 1.1),
			hiz = rng:NextNumber(0.08, 0.22),
			faz = rng:NextNumber(0, math.pi * 2),
		})
	end
	return liste
end

local function kabarciklariOynat(liste: { Kabarcik }, dt: number, t: number)
	for _, k in liste do
		k.y -= k.hiz * dt
		if k.y < -0.06 then
			k.y = 1.06
			k.x = rng:NextNumber(0.08, 0.92)
		end
		local salinim = math.sin(t * 2.2 + k.faz) * 0.03
		k.nesne.Position = UDim2.fromScale(k.x + salinim, k.y)
	end
end

-- Yazinin ve konturunun saydamligini birlikte ayarlar
local function yaziSaydam(yazi: TextLabel, deger: number, sure: number?)
	local kontur = yazi:FindFirstChildOfClass("UIStroke")
	if sure then
		tween(yazi, sure, { TextTransparency = deger })
		if kontur then
			tween(kontur, sure, { Transparency = deger })
		end
	else
		yazi.TextTransparency = deger
		if kontur then
			kontur.Transparency = deger
		end
	end
end

------------------------------------------------------------------
-- PENCERE
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

	root yalnizca yer tutucu (arayuz olceginin UIScale'i ona takiliyor);
	gorunen her sey govde'de. Sarsinti ve acilis ziplamasi govde'yi
	oynatir, boylece olcekle cakismaz.
]]
local root = kutu("Root", screen, 1)
root.AnchorPoint = Vector2.new(1, 0.5)
root.Position = UDim2.new(1, -48, 0.5, 0)
root.Size = UDim2.fromOffset(PANEL_EN, PANEL_BOY)
root.BackgroundTransparency = 1

local govde = kutu("Govde", root, 1)
govde.Size = UDim2.fromScale(1, 1)
govde.BackgroundColor3 = Color3.new(1, 1, 1)
govde.BackgroundTransparency = 0.04
govde.ClipsDescendants = true
UI.corner(govde, 14)

do
	local gecis = Instance.new("UIGradient")
	gecis.Rotation = 90
	gecis.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 74, 128)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(12, 40, 82)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 14, 34)),
	})
	gecis.Parent = govde
end

local govdeOlcek = Instance.new("UIScale")
govdeOlcek.Name = "Ziplama"
govdeOlcek.Parent = govde

-- Cerceve kademe renginde, ince bir nefes alir
local cerceve = UI.stroke(govde, UI.Colors.accent, 2)

-- Arka plan: isik bantlari ve buyuk soluk kabarciklar
local arkaIsik = isikKati(govde, 0.94, 1)
local arkaKabarcik = kabarciklar(govde, 12, 6, 16, 0.82, 1)

local header = UI.text({
	text = "",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -24, 0, 32),
	position = UDim2.fromOffset(12, 14),
	parent = govde,
	name = "Baslik",
	zIndex = 6,
})

local subHeader = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -24, 0, 20),
	position = UDim2.fromOffset(12, 48),
	parent = govde,
	name = "AltBaslik",
	zIndex = 6,
})

------------------------------------------------------------------
-- SU SUTUNU
------------------------------------------------------------------
local track = kutu("Track", govde, 2)
track.AnchorPoint = Vector2.new(0.5, 0)
track.Position = UDim2.new(0.4, 0, 0, SUTUN_UST)
track.Size = UDim2.fromOffset(58, SUTUN_BOY)
track.BackgroundColor3 = Color3.new(1, 1, 1)
track.ClipsDescendants = true
UI.corner(track, 10)

do
	local gecis = Instance.new("UIGradient")
	gecis.Rotation = 90
	gecis.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 190, 235)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(24, 108, 170)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 26, 62)),
	})
	gecis.Parent = track
end

local trackKontur = UI.stroke(track, Color3.fromRGB(0, 0, 0), 2)

local suIsik = isikKati(track, 0.86, 1)
local suKabarcik = kabarciklar(track, 10, 3, 8, 0.55, 2)

-- Yuzey: sutunun tepesinde parlak ince serit
do
	local yuzey = kutu("Yuzey", track, 2)
	yuzey.Size = UDim2.new(1, 0, 0, 6)
	yuzey.BackgroundColor3 = Color3.fromRGB(200, 245, 255)
	yuzey.BackgroundTransparency = 0.35
end

-- Yakalama bolgesinin arkasindaki hale
local barHale = kutu("BarHale", track, 3)
barHale.AnchorPoint = Vector2.new(0.5, 0.5)
barHale.BackgroundColor3 = ICERI_RENK
barHale.BackgroundTransparency = 0.75
UI.corner(barHale, 8)

-- Oyuncunun kontrol ettigi yakalama bolgesi
local bar = kutu("Bar", track, 4)
bar.AnchorPoint = Vector2.new(0.5, 0.5)
bar.Position = UDim2.fromScale(0.5, 0.5)
bar.Size = UDim2.new(1, -10, 0, 60)
bar.BackgroundColor3 = ICERI_RENK
bar.BackgroundTransparency = 0.25
UI.corner(bar, 6)

do
	-- Kenarlar dolu, ortasi cam gibi
	local gecis = Instance.new("UIGradient")
	gecis.Rotation = 90
	gecis.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.18, 0.45),
		NumberSequenceKeypoint.new(0.82, 0.45),
		NumberSequenceKeypoint.new(1, 0),
	})
	gecis.Parent = bar
end

local barKontur = UI.stroke(bar, Color3.new(1, 1, 1), 1)
barKontur.Transparency = 0.2

-- Misina: sutunun tepesinden baliga iner
local misina = kutu("Misina", track, 5)
misina.AnchorPoint = Vector2.new(0.5, 0)
misina.Position = UDim2.fromScale(0.5, 0)
misina.Size = UDim2.new(0, 1, 0.5, 0)
misina.BackgroundColor3 = Color3.fromRGB(235, 245, 255)
misina.BackgroundTransparency = 0.15

------------------------------------------------------------------
-- BALIK
------------------------------------------------------------------
local balik = kutu("Balik", track, 6)
balik.AnchorPoint = Vector2.new(0.5, 0.5)
balik.Position = UDim2.fromScale(0.5, 0.5)
balik.Size = UDim2.fromOffset(44, 30)
balik.BackgroundTransparency = 1

-- Kademe renginde hale; rengi basla'da ayarlaniyor
local hale = UI.parlama(balik, Color3.new(1, 1, 1), 66, 1)

local kuyruk = kutu("Kuyruk", balik, 2)
kuyruk.AnchorPoint = Vector2.new(0.5, 0.5)
kuyruk.Position = UDim2.new(0, 8, 0.5, 0)
kuyruk.Size = UDim2.fromOffset(15, 15)
kuyruk.Rotation = 45
kuyruk.BackgroundColor3 = BALIK_KOYU
UI.corner(kuyruk, 3)
UI.stroke(kuyruk, Color3.fromRGB(70, 22, 6), 1)

local yuzgec = kutu("Yuzgec", balik, 2)
yuzgec.AnchorPoint = Vector2.new(0.5, 0.5)
yuzgec.Position = UDim2.new(0.5, 2, 0.5, -10)
yuzgec.Size = UDim2.fromOffset(10, 10)
yuzgec.Rotation = 45
yuzgec.BackgroundColor3 = BALIK_KOYU
UI.corner(yuzgec, 2)
UI.stroke(yuzgec, Color3.fromRGB(70, 22, 6), 1)

local balikGovde = kutu("Govde", balik, 3)
balikGovde.AnchorPoint = Vector2.new(0.5, 0.5)
balikGovde.Position = UDim2.new(0.5, 4, 0.5, 0)
balikGovde.Size = UDim2.fromOffset(32, 20)
balikGovde.BackgroundColor3 = BALIK_RENK
UI.corner(balikGovde, 10)
UI.stroke(balikGovde, Color3.fromRGB(70, 22, 6), 1)

do
	-- Ustten aydinlik, alttan koyu: govde yuvarlak dursun
	local gecis = Instance.new("UIGradient")
	gecis.Rotation = 90
	gecis.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 170)),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 130)),
	})
	gecis.Parent = balikGovde

	local goz = kutu("Goz", balikGovde, 4)
	goz.AnchorPoint = Vector2.new(0.5, 0.5)
	goz.Position = UDim2.new(1, -8, 0.42, 0)
	goz.Size = UDim2.fromOffset(7, 7)
	goz.BackgroundColor3 = Color3.new(1, 1, 1)
	daire(goz)

	local bebek = kutu("Bebek", goz, 5)
	bebek.AnchorPoint = Vector2.new(0.5, 0.5)
	bebek.Position = UDim2.fromScale(0.62, 0.5)
	bebek.Size = UDim2.fromOffset(4, 4)
	bebek.BackgroundColor3 = Color3.new(0, 0, 0)
	daire(bebek)
end

------------------------------------------------------------------
-- ILERLEME CUBUGU VE MAKARA
------------------------------------------------------------------
local progressTrack = kutu("ProgressTrack", govde, 2)
progressTrack.AnchorPoint = Vector2.new(0.5, 0)
progressTrack.Position = UDim2.new(0.83, 0, 0, SUTUN_UST)
progressTrack.Size = UDim2.fromOffset(16, SUTUN_BOY)
progressTrack.BackgroundColor3 = Color3.fromRGB(8, 14, 26)
progressTrack.ClipsDescendants = true
UI.corner(progressTrack, 8)
local progressKontur = UI.stroke(progressTrack, Color3.fromRGB(0, 0, 0), 2)

local progressFill = kutu("Fill", progressTrack, 2)
progressFill.AnchorPoint = Vector2.new(0.5, 1)
progressFill.Position = UDim2.fromScale(0.5, 1)
progressFill.Size = UDim2.fromScale(1, 0.35)
progressFill.BackgroundColor3 = UI.Colors.good
progressFill.ClipsDescendants = true
UI.corner(progressFill, 8)
UI.cubukCilasi(progressFill)

-- Dolgunun icinde yukari kayan parlak serit
local parilti = kutu("Parilti", progressFill, 3)
parilti.AnchorPoint = Vector2.new(0.5, 0.5)
parilti.Size = UDim2.new(1, 0, 0, 60)
parilti.BackgroundColor3 = Color3.new(1, 1, 1)
do
	local gecis = Instance.new("UIGradient")
	gecis.Rotation = 90
	gecis.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	gecis.Parent = parilti
end

--[[
	Makara cubugun disina tasiyor (cubuktan genis); cubuk kirptigi icin
	ayni yerde duran, KIRPMAYAN bir katmanin icinde. Konumu oranla:
	1 - progress dogrudan dolgunun ucu.
]]
local makaraKatman = kutu("MakaraKatmani", govde, 3)
makaraKatman.AnchorPoint = progressTrack.AnchorPoint
makaraKatman.Position = progressTrack.Position
makaraKatman.Size = progressTrack.Size
makaraKatman.BackgroundTransparency = 1

local makara = kutu("Makara", makaraKatman, 1)
makara.AnchorPoint = Vector2.new(0.5, 0.5)
makara.Size = UDim2.fromOffset(26, 26)
makara.BackgroundColor3 = Color3.fromRGB(30, 36, 50)
daire(makara)
UI.stroke(makara, ALTIN, 2)

for i = 0, 2 do
	local tel = kutu("Tel", makara, 2)
	tel.AnchorPoint = Vector2.new(0.5, 0.5)
	tel.Position = UDim2.fromScale(0.5, 0.5)
	tel.Size = UDim2.fromOffset(2, 20)
	tel.Rotation = i * 60
	tel.BackgroundColor3 = ALTIN
	UI.corner(tel, 1)
end

do
	local gobek = kutu("Gobek", makara, 3)
	gobek.AnchorPoint = Vector2.new(0.5, 0.5)
	gobek.Position = UDim2.fromScale(0.5, 0.5)
	gobek.Size = UDim2.fromOffset(8, 8)
	gobek.BackgroundColor3 = Color3.fromRGB(255, 250, 220)
	daire(gobek)
	UI.stroke(gobek, Color3.fromRGB(0, 0, 0), 1)
end

local yuzdeYazi = UI.text({
	text = "0%",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	anchor = Vector2.new(0.5, 0),
	frameSize = UDim2.fromOffset(60, 22),
	position = UDim2.new(0.83, 0, 0, SUTUN_UST + SUTUN_BOY + 6),
	parent = govde,
	name = "Yuzde",
	zIndex = 6,
})

-- Sutunun altinda balikla ilgili durum yazisi: HOOKED! / SLIPPING!
local durumYazi = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	anchor = Vector2.new(0.5, 0),
	frameSize = UDim2.fromOffset(140, 24),
	position = UDim2.new(0.4, 0, 0, SUTUN_UST + SUTUN_BOY + 5),
	parent = govde,
	name = "Durum",
	zIndex = 6,
})

local hint = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -24, 0, 20),
	position = UDim2.new(0, 12, 1, -30),
	parent = govde,
	name = "Ipucu",
	zIndex = 6,
})

------------------------------------------------------------------
-- USTTEKI KATMANLAR: tehlike, flas, buyuk yazi, konfeti
------------------------------------------------------------------
local tehlike = kutu("Tehlike", govde, 10)
tehlike.Size = UDim2.fromScale(1, 1)
tehlike.BackgroundColor3 = Color3.fromRGB(200, 20, 20)
tehlike.BackgroundTransparency = 1

local flas = kutu("Flas", govde, 11)
flas.Size = UDim2.fromScale(1, 1)
flas.BackgroundColor3 = Color3.new(1, 1, 1)
flas.BackgroundTransparency = 1

-- Buyuk yazi (FISH ON! / CAUGHT! / IT GOT AWAY!) ve arkasindaki huzmeler
local sahne = kutu("Sahne", govde, 12)
sahne.AnchorPoint = Vector2.new(0.5, 0.5)
sahne.Position = UDim2.fromScale(0.5, 0.42)
sahne.Size = UDim2.fromOffset(PANEL_EN, 80)
sahne.BackgroundTransparency = 1
sahne.Visible = false

local sahneOlcek = Instance.new("UIScale")
sahneOlcek.Parent = sahne

local huzmeler = UI.isikHuzmeleri(sahne, ALTIN, {
	sayi = 12,
	uzunluk = 320,
	kalinlik = 16,
	tur = 6,
	parlaklik = 0.35,
	zIndex = 1,
})

local sahneYazi = UI.text({
	text = "",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	anchor = Vector2.new(0.5, 0.5),
	position = UDim2.fromScale(0.5, 0.5),
	frameSize = UDim2.fromScale(1, 1),
	parent = sahne,
	name = "Yazi",
	zIndex = 2,
})

-- Konfeti sutunun uzerinde, balikla ayni koordinatta; kirpmaz
local konfetiKatman = kutu("Konfeti", govde, 13)
konfetiKatman.AnchorPoint = track.AnchorPoint
konfetiKatman.Position = track.Position
konfetiKatman.Size = track.Size
konfetiKatman.BackgroundTransparency = 1

--[[
	PERFECT rozeti.
	Balik bastan sona hic yakalama bolgesinin disina cikmadiysa gosterilir.
	root'un icinde ama govdenin DISINDA: sarsintiyla titremez, kirpilmaz;
	CAUGHT! yazisinin hemen altinda durur.
]]
local perfectLabel = UI.text({
	text = "PERFECT!",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = Color3.fromRGB(255, 226, 90),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromOffset(PANEL_EN, 48),
	anchor = Vector2.new(0.5, 0.5),
	position = UDim2.new(0.5, 0, 0.42, 56),
	parent = root,
	name = "Perfect",
	zIndex = 20,
})
perfectLabel.Visible = false

------------------------------------------------------------------
-- DURUM
------------------------------------------------------------------
local baglanti: RBXScriptConnection? = nil
local zaman = 0
local sonDurum: DigMinigame.State? = nil
local tutuyor = false
local iceride = true
local iceriOran = 1
local sonIlerleme: number? = nil
local sarsinti = 0
local bitti = false
local everLeft = false
local egim = 0
-- Eski gecikmeli islerin yeni bir oyunda calismamasi icin
local tur = 0

local function sarsintiKapali(): boolean
	return player:GetAttribute("SarsintiKapali") == true
end

local function sars(guc: number)
	sarsinti = math.max(sarsinti, guc)
end

local function flasla(renk: Color3, baslangic: number)
	flas.BackgroundColor3 = renk
	flas.BackgroundTransparency = baslangic
	tween(flas, 0.45, { BackgroundTransparency = 1 })
end

local function ilerlemeRengi(p: number): Color3
	if p < 0.5 then
		return UI.Colors.bad:Lerp(UI.Colors.warn, p / 0.5)
	end
	return UI.Colors.warn:Lerp(ICERI_RENK, (p - 0.5) / 0.5)
end

--[[
	Buyuk yaziyi ortada patlatir: kucukten buyur, sure dolunca soner.
	huzmeli = true iken arkasinda altin isik huzmeleri doner.
]]
local function sahneGoster(yazi: string, renk: Color3, sure: number, huzmeli: boolean)
	tur += 1
	local benimTur = tur

	sahneYazi.Text = yazi
	UI.plainStyle(sahneYazi, renk)
	yaziSaydam(sahneYazi, 0)
	huzmeler.Visible = huzmeli
	sahne.Visible = true

	sahneOlcek.Scale = 0.3
	tween(sahneOlcek, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)

	task.delay(sure, function()
		if tur ~= benimTur then
			return
		end
		yaziSaydam(sahneYazi, 1, 0.25)
		tween(sahneOlcek, 0.25, { Scale = 1.25 })
		task.delay(0.26, function()
			if tur == benimTur then
				sahne.Visible = false
			end
		end)
	end)
end

-- Baligin oldugu yerden her yone sacilan renkli parcalar
local function konfeti(renk: Color3)
	local y = balik.Position.Y.Scale
	local renkler = { renk, ALTIN, Color3.new(1, 1, 1), Color3.fromRGB(110, 230, 255), ICERI_RENK }

	for _ = 1, 30 do
		local boy = rng:NextInteger(6, 12)
		local p = kutu("Parca", konfetiKatman, 1)
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Position = UDim2.fromScale(0.5, y)
		p.Size = UDim2.fromOffset(boy, if rng:NextNumber() < 0.5 then boy else math.floor(boy * 0.5))
		p.Rotation = rng:NextInteger(0, 360)
		p.BackgroundColor3 = renkler[rng:NextInteger(1, #renkler)]
		UI.stroke(p, Color3.new(0, 0, 0), 1)

		local aci = rng:NextNumber(0, math.pi * 2)
		local mesafe = rng:NextNumber(60, 170)
		local sure = rng:NextNumber(0.6, 0.95)
		tween(p, sure, {
			Position = UDim2.new(0.5, math.cos(aci) * mesafe, y, math.sin(aci) * mesafe - 40),
			Rotation = p.Rotation + rng:NextInteger(-360, 360),
		}, Enum.EasingStyle.Quart)
		task.delay(sure * 0.55, function()
			if p.Parent then
				tween(p, sure * 0.45, { BackgroundTransparency = 1 })
			end
		end)
		task.delay(sure + 0.05, function()
			p:Destroy()
		end)
	end
end

------------------------------------------------------------------
-- KARE DONGUSU  (pencere acikken)
------------------------------------------------------------------
local function kare(dt: number)
	zaman += dt
	local t = zaman

	-- Isik bantlari yukselir, kabarciklar suzulur
	arkaIsik.Position = UDim2.fromScale(0, -((t * 0.04) % 1))
	suIsik.Position = UDim2.fromScale(0, -((t * 0.09) % 1))
	kabarciklariOynat(arkaKabarcik, dt, t)
	kabarciklariOynat(suKabarcik, dt * 1.6, t)

	-- Cerceve nefes alir
	cerceve.Thickness = 2 + math.sin(t * 3) * 0.5

	local durum = sonDurum
	local hiz = if durum then durum.targetVelocity else 0

	-- Balik: kuyruk sallanir, burun hiza gore kalkar/iner
	local cirpma = 8 + math.min(math.abs(hiz) * 14, 16)
	kuyruk.Rotation = 45 + math.sin(t * cirpma) * 20
	kuyruk.Position = UDim2.new(0, 8 + math.sin(t * cirpma) * 1.5, 0.5, 0)
	local hedefEgim = if bitti then egim else math.clamp(-hiz * 45, -35, 35)
	egim += (hedefEgim - egim) * math.min(dt * 10, 1)
	balik.Rotation = egim

	-- Misina baliga kadar iner (balik tweende de olsa pesinden gider)
	misina.Size = UDim2.new(0, 1, math.max(balik.Position.Y.Scale, 0), 0)

	-- Yakalama bolgesinin rengi yumusakca gecer
	iceriOran += ((if iceride then 1 else 0) - iceriOran) * math.min(dt * 10, 1)
	local bolgeRenk = DISARI_RENK:Lerp(ICERI_RENK, iceriOran)
	bar.BackgroundColor3 = bolgeRenk
	bar.BackgroundTransparency = if tutuyor then 0.08 else 0.28
	barHale.BackgroundColor3 = bolgeRenk
	barHale.BackgroundTransparency = 0.72 + math.sin(t * 6) * 0.08
	barKontur.Transparency = if tutuyor then 0 else 0.35

	-- Ilerleme dolgusunun icinde parilti yukari kayar
	parilti.Position = UDim2.fromScale(0.5, 1.2 - ((t * 0.7) % 1.4))

	if bitti or not durum then
		tehlike.BackgroundTransparency = 1
	else
		local p = durum.progress

		-- Makara ilerledikce sarar, gerilerken ters doner
		if sonIlerleme then
			makara.Rotation += (p - sonIlerleme) * MAKARA_DONUS
		end
		sonIlerleme = p

		local tehlikede = not iceride and p < TEHLIKE_ORANI
		local nabiz = (math.sin(t * 12) + 1) * 0.5

		if tehlikede then
			tehlike.BackgroundTransparency = 0.86 - nabiz * 0.1
			trackKontur.Color = DISARI_RENK
			misina.BackgroundColor3 = DISARI_RENK
			sars(1.3)
		else
			tehlike.BackgroundTransparency = 1
			trackKontur.Color = Color3.fromRGB(0, 0, 0)
			misina.BackgroundColor3 = Color3.fromRGB(235, 245, 255)
		end

		-- Neredeyse doldu: cubuk altin cerceveyle parlar
		progressKontur.Color = if p > 0.85 then ALTIN else Color3.fromRGB(0, 0, 0)

		if iceride and p > 0.85 then
			durumYazi.Text = "ALMOST THERE!"
			durumYazi.TextColor3 = ALTIN
		elseif iceride then
			durumYazi.Text = "HOOKED!"
			durumYazi.TextColor3 = ICERI_RENK
		else
			durumYazi.Text = "SLIPPING!"
			durumYazi.TextColor3 = DISARI_RENK
		end
		durumYazi.TextSize = math.floor(UI.Sizes.body * (1 + nabiz * (if iceride then 0.08 else 0.18)))
		durumYazi.Rotation = if iceride then 0 else math.sin(t * 20) * 3
	end

	-- Sarsinti: govde titrer, guc zamanla soner
	if sarsinti > 0 and not sarsintiKapali() then
		local s = sarsinti
		govde.Position = UDim2.fromOffset(rng:NextNumber(-s, s), rng:NextNumber(-s, s))
		sarsinti = math.max(0, sarsinti - dt * 14)
	else
		sarsinti = 0
		govde.Position = UDim2.new()
	end
end

------------------------------------------------------------------
-- ACIK UCLAR
------------------------------------------------------------------
function BalikPaneli.basla(gear: DigMinigame.GearInfo, rarityId: string)
	tur += 1
	bitti = false
	everLeft = false
	iceride = true
	iceriOran = 1
	sonIlerleme = nil
	sonDurum = nil
	sarsinti = 0
	egim = 0
	zaman = 0

	for _, p in konfetiKatman:GetChildren() do
		p:Destroy()
	end

	-- Onceki kacistan kalan balik ve misina geri gelir
	balik.Visible = true
	balik.Position = UDim2.fromScale(0.5, 0.5)
	misina.Visible = true
	flas.BackgroundTransparency = 1
	sahne.Visible = false
	perfectLabel.Visible = false
	makara.Rotation = 0
	durumYazi.Text = ""
	yuzdeYazi.Text = "0%"

	local info = Rarity.Info[rarityId :: Rarity.RarityId]
	local renk: Color3
	if info then
		header.Text = `{info.displayName} BRAINROT`
		-- Epic+ parlak, Divine parildar; cerceve kademe renginde kalir
		UI.rarityStyle(header, rarityId)
		renk = info.color
	else
		header.Text = string.upper(Rarity.beamName(rarityId))
		renk = Rarity.beamColor(rarityId)
		UI.plainStyle(header, renk)
	end
	cerceve.Color = renk

	-- Hale cok koyu kademede (Secret) de gorunsun diye yazi rengi
	local haleRenk = if info then Rarity.textColor(rarityId) else renk
	for _, halka in hale:GetChildren() do
		if halka:IsA("Frame") then
			halka.BackgroundColor3 = haleRenk
		end
	end

	subHeader.Text = `{gear.displayName}  |  Lv.{gear.level}`
	hint.Text = if UserInputService.TouchEnabled then "Touch and hold the screen" else "Hold SPACE or left click"

	screen.Enabled = true

	-- Acilis: panel ziplayarak buyur, ortada FISH ON! patlar
	govdeOlcek.Scale = 0.6
	tween(govdeOlcek, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	flasla(Color3.new(1, 1, 1), 0.5)
	sahneGoster("FISH ON!", ALTIN, 0.7, false)

	if not baglanti then
		baglanti = RunService.RenderStepped:Connect(kare)
	end
end

function BalikPaneli.ciz(state: DigMinigame.State, holding: boolean)
	if bitti then
		return
	end

	sonDurum = state
	tutuyor = holding

	-- Cubuk 0..1 -> ekranda ust 0, alt 1 olacak sekilde ters cevrilir
	bar.Size = UDim2.new(1, -10, state.barSize, 0)
	bar.Position = UDim2.fromScale(0.5, 1 - state.barPosition)
	barHale.Size = UDim2.new(1, -4, state.barSize, 6)
	barHale.Position = bar.Position

	balik.Position = UDim2.fromScale(0.5, 1 - state.targetPosition)

	progressFill.Size = UDim2.fromScale(1, state.progress)
	progressFill.BackgroundColor3 = ilerlemeRengi(state.progress)
	makara.Position = UDim2.fromScale(0.5, 1 - state.progress)
	yuzdeYazi.Text = `{math.floor(state.progress * 100 + 0.5)}%`

	iceride = math.abs(state.targetPosition - state.barPosition) <= state.barSize * 0.5
	if not iceride then
		everLeft = true
	end
end

function BalikPaneli.bitir(won: boolean)
	if bitti then
		return
	end
	bitti = true
	durumYazi.Rotation = 0
	durumYazi.TextSize = UI.Sizes.body

	cerceve.Color = if won then ICERI_RENK else DISARI_RENK
	header.Text = if won then "CAUGHT IT!" else "IT GOT AWAY!"
	-- Kademe gorunumu (parilti / parildama) kalkmali, yoksa rengi ezer
	UI.plainStyle(header, if won then ICERI_RENK else DISARI_RENK)

	if won then
		durumYazi.Text = "REELED IN!"
		durumYazi.TextColor3 = ALTIN
		progressFill.Size = UDim2.fromScale(1, 1)
		progressFill.BackgroundColor3 = ICERI_RENK
		yuzdeYazi.Text = "100%"

		-- Balik sudan firlar, konfeti sacilir, panel zipar
		konfeti(cerceve.Color)
		tween(balik, 0.45, { Position = UDim2.fromScale(0.5, -0.15) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		egim = -60
		flasla(Color3.fromRGB(255, 250, 210), 0.35)
		sars(5)
		govdeOlcek.Scale = 1.08
		tween(govdeOlcek, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		sahneGoster("CAUGHT!", ALTIN, 0.8, true)

		-- Hic kacirmadiysa PERFECT
		if not everLeft then
			perfectLabel.Visible = true
			sars(8)
			local benimTur = tur
			task.delay(0.9, function()
				if tur == benimTur then
					perfectLabel.Visible = false
				end
			end)
		end
	else
		-- Misina kopar, balik dibe kacar
		durumYazi.Text = "LINE SNAPPED!"
		durumYazi.TextColor3 = DISARI_RENK
		misina.Visible = false
		egim = 70
		tween(balik, 0.5, { Position = UDim2.fromScale(0.5, 1.2) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		flasla(DISARI_RENK, 0.3)
		sars(7)
		sahneGoster("IT GOT AWAY!", DISARI_RENK, 0.8, false)
	end
end

function BalikPaneli.gizle()
	tur += 1
	screen.Enabled = false
	perfectLabel.Visible = false
	sahne.Visible = false
	sonDurum = nil

	local b = baglanti
	if b then
		b:Disconnect()
		baglanti = nil
	end

	sarsinti = 0
	govde.Position = UDim2.new()

	for _, p in konfetiKatman:GetChildren() do
		p:Destroy()
	end
end

-- Pencere acik mi (sonuc gosterisi dahil)
function BalikPaneli.acik(): boolean
	return screen.Enabled
end

return BalikPaneli
