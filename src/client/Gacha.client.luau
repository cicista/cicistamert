--!strict
--[[
	Gacha  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Gacha

	Yumurta gachasinin penceresi (bkz. Shared > Gacha, Modules > Gacha).
	Gacha NPC'sinin promptu acar; diger NPC pencereleriyle ayni kurallar:
	tek panel, acilis/kapanis animasyonu, sag ustte X, NPC menu sesi.

	    +------------------------------------------------------+
	    |  EGG GACHA                                        X  |
	    |        THE MOST POWERFUL GACHA IN THE GAME           |
	    |  [Divine] [Cosmic] [Secret] [Infernal] [Abyssal]     |
	    |    40%      27%      18%       10%        5%         |
	    |  <<<  (egg) (egg) (egg) | (egg) (egg) (egg)  >>>     |
	    |                  ABYSSAL EGG!                        |
	    |               [  OPEN   R$ 500  ]     [ADMIN TEST]   |
	    +------------------------------------------------------+

	TEMA: mor ve hasmetli
	  - panelin arkasinda karartma + donen mor/altin isik huzmeleri
	  - ekranda ve panelin icinde rastgele cakan YILDIRIMLAR (+ panel flasi)
	  - panelin konturunda donen mor/pembe/altin isik
	  - panelde yagan mor elmaslar ve sonup yanan pariltilar
	  - satin alma dugmesinde nabiz, hale ve uzerinden gecen parilti bandi
	  - sans kartlarinda kademe cerceveleri (KademeEfekti)

	CEVIRME (Lucky Block carkiyla ayni, tek asamali)
	Sonucu SUNUCU secer (GachaSonuc); burada serit doldurulur ve kazanan
	KazananSira'da durur. Kazananin hemen yanina bir Abyssal konur (heyecan
	icin "az kalsin" bolmesi) -- sonucu degistirmez, yalnizca gosteri.

	KAZANINCA: ekran flasi, yildirim yagmuru, konfeti, sarsinti, kocaman
	yumurta adi. Ust kademelerde (Infernal, Abyssal) hepsi daha buyuk ve
	"JACKPOT!" yazisi cikar. FuseExplosion + FuseVFX'i sunucu oynatir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("Gacha"))
local Assets = require(Shared:WaitForChild("Assets"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))
local Rulet = require(script.Parent:WaitForChild("Rulet"))
local KademeEfekti = require(script.Parent:WaitForChild("KademeEfekti"))
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

local GachaAc = Net.event("GachaAc")
local GachaSonuc = Net.event("GachaSonuc")
local GachaDene = Net.event("GachaDene")
local RobuxUrunAl = Net.event("RobuxUrunAl")

------------------------------------------------------------------
-- RENKLER
------------------------------------------------------------------
local MOR = Color3.fromRGB(150, 60, 255)
local MOR_ACIK = Color3.fromRGB(205, 130, 255)
local MOR_KOYU = Color3.fromRGB(34, 10, 58)
local PEMBE = Color3.fromRGB(255, 90, 220)
local ALTIN = Color3.fromRGB(255, 214, 70)
local BEYAZ = Color3.new(1, 1, 1)
local SIYAH = Color3.new(0, 0, 0)

-- Bu kademelerde kutlama "JACKPOT" olur
local JACKPOT: { [string]: boolean } = { Infernal = true, Abyssal = true }

------------------------------------------------------------------
-- EKRANLAR
------------------------------------------------------------------
local screen = Instance.new("ScreenGui")
screen.Name = "GachaArayuzu"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

--[[
	Kutlama katmani (flas, konfeti, kocaman yazi) panelin de USTUNDE:
	panel katmani 20'de, bu 25'te.
]]
local efektEkrani = Instance.new("ScreenGui")
efektEkrani.Name = "GachaEfektleri"
efektEkrani.ResetOnSpawn = false
efektEkrani.IgnoreGuiInset = true
efektEkrani.DisplayOrder = UI.PanelKatmani + 5
efektEkrani.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
efektEkrani.Parent = playerGui

------------------------------------------------------------------
-- PANEL
------------------------------------------------------------------
-- Adi NpcMenuSesi'nde de yazili: acilinca ve dugmelerde tiklama sesi
local panel = UI.panel(screen, UDim2.fromOffset(660, 560), "GachaPenceresi")
UI.closeButton(panel).MouseButton1Click:Connect(function()
	panel.Visible = false
end)
UI.baslikCubugu(panel, "EGG GACHA", MOR_ACIK, MOR, nil, MOR_KOYU)

-- Konturda donen mor / pembe / altin isik
local kontur = panel:FindFirstChildOfClass("UIStroke")
if kontur then
	kontur.Thickness = 4
	kontur.Color = BEYAZ
	local isik = Instance.new("UIGradient")
	isik.Name = "DonenIsik"
	isik.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, MOR),
		ColorSequenceKeypoint.new(0.25, PEMBE),
		ColorSequenceKeypoint.new(0.5, ALTIN),
		ColorSequenceKeypoint.new(0.75, PEMBE),
		ColorSequenceKeypoint.new(1, MOR),
	})
	isik.Parent = kontur
	TweenService:Create(isik, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 }):Play()
end

-- Panelin icindeki arka katman: yagan elmaslar, pariltilar, ic yildirimlar
local icKatman = Instance.new("Frame")
icKatman.Name = "IcKatman"
icKatman.Size = UDim2.fromScale(1, 1)
icKatman.BackgroundTransparency = 1
icKatman.ClipsDescendants = true
-- 0: panelin dokusunun ustunde, baslik cubugunun ve icerigin altinda
icKatman.ZIndex = 0
icKatman.Parent = panel
UI.corner(icKatman, 14)

do
	local yagmur = UI.parcaYagmuru(icKatman, {
		renk = MOR_ACIK,
		sayi = 22,
		boyut = 9,
		sure = 5,
		sekil = "elmas",
		saydam = 0.45,
		zIndex = 1,
	})
	UI.corner(yagmur, 14)

	local parilti = UI.pariltilar(icKatman, ALTIN, 14, 2)
	parilti.Position = UDim2.fromScale(0.5, 0.5)
	parilti.Size = UDim2.fromScale(1, 1)
end

-- Panel flasi (yildirim cakinca bir an beyazlasir)
local panelFlasi = Instance.new("Frame")
panelFlasi.Name = "Flas"
panelFlasi.Size = UDim2.fromScale(1, 1)
panelFlasi.BackgroundColor3 = MOR_ACIK
panelFlasi.BackgroundTransparency = 1
panelFlasi.BorderSizePixel = 0
panelFlasi.ZIndex = 30
panelFlasi.Parent = panel
UI.corner(panelFlasi, 14)

------------------------------------------------------------------
-- BASLIK YAZISI
------------------------------------------------------------------
-- Ilk bakista en nadir yumurtanin sansi: "5% CHANCE FOR ABYSSAL!"
local altBaslik = UI.text({
	text = `{Ayar.sans("Abyssal")}% CHANCE FOR {string.upper(Rarity.displayName("Abyssal"))}!`,
	size = UI.Sizes.heading + 2,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -40, 0, 30),
	position = UDim2.fromOffset(20, 68),
	parent = panel,
	zIndex = 5,
})
do
	local gecis = Instance.new("UIGradient")
	gecis.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, ALTIN),
		ColorSequenceKeypoint.new(0.45, BEYAZ),
		ColorSequenceKeypoint.new(0.55, PEMBE),
		ColorSequenceKeypoint.new(1, ALTIN),
	})
	gecis.Offset = Vector2.new(-1, 0)
	gecis.Parent = altBaslik
	TweenService:Create(gecis, TweenInfo.new(2.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Offset = Vector2.new(1, 0) }):Play()
end

------------------------------------------------------------------
-- SANS KARTLARI
------------------------------------------------------------------
local KART_EN = 116
local KART_BOY = 128
local KART_ARA = 8

local kartSirasi = Instance.new("Frame")
kartSirasi.Name = "Sanslar"
kartSirasi.AnchorPoint = Vector2.new(0.5, 0)
kartSirasi.Position = UDim2.new(0.5, 0, 0, 102)
kartSirasi.Size = UDim2.fromOffset(#Ayar.Yumurtalar * (KART_EN + KART_ARA) - KART_ARA, KART_BOY)
kartSirasi.BackgroundTransparency = 1
kartSirasi.ZIndex = 5
kartSirasi.Parent = panel

local kartlar: { Frame } = {}

for i, y in Ayar.Yumurtalar do
	local renk = Rarity.color(y.rarity)

	local kart = Instance.new("Frame")
	kart.Name = y.rarity
	kart.Position = UDim2.fromOffset((i - 1) * (KART_EN + KART_ARA), 0)
	kart.Size = UDim2.fromOffset(KART_EN, KART_BOY)
	kart.BackgroundColor3 = renk:Lerp(SIYAH, 0.55)
	kart.BorderSizePixel = 0
	kart.ZIndex = 5
	kart.Parent = kartSirasi
	UI.corner(kart, 12)
	local cizgi = UI.stroke(kart, renk, 2)

	local gecis = Instance.new("UIGradient")
	gecis.Rotation = 90
	gecis.Color = ColorSequence.new(BEYAZ, Color3.fromRGB(110, 110, 110))
	gecis.Parent = kart

	-- Yumurtanin arkasinda nefes alan hale
	local hale = UI.parlama(kart, renk, 70, 5)
	hale.Position = UDim2.new(0.5, 0, 0, 44)

	local ad = UI.text({
		text = Ayar.yumurtaAdi(Rarity.displayName(y.rarity)),
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -6, 0, 18),
		position = UDim2.new(0, 3, 1, -44),
		parent = kart,
		zIndex = 7,
	})
	UI.rarityStyle(ad, y.rarity)

	UI.text({
		text = `{y.sans}%`,
		size = UI.Sizes.label,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -6, 0, 22),
		position = UDim2.new(0, 3, 1, -25),
		parent = kart,
		zIndex = 7,
	})

	-- Degerli kart kendini belli eder (Index ve carkla ayni cerceve)
	KademeEfekti.tak(kart, cizgi, renk, y.rarity, {
		aura = "ic",
		etkin = function()
			return panel.Visible
		end,
	})

	-- Hafifce yukari asagi suzulur, her kart kendi temposunda
	local ev = kart.Position
	TweenService:Create(
		kart,
		TweenInfo.new(1.4 + i * 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Position = ev - UDim2.fromOffset(0, 5) }
	):Play()

	table.insert(kartlar, kart)
end

--[[
	Kartlardaki yumurta modelleri ILK ACILISTA kurulur: script basladiginda
	Assets > Eggs daha istemciye inmemis olabiliyor (o zaman Gold Ore'a
	dusulurdu). Model bulunamazsa sonraki acilista yeniden denenir.
]]
local function yumurtalariKur()
	for _, kart in kartlar do
		if kart:FindFirstChild("Yumurta") then
			continue
		end
		local model = Assets.hiddenBrainrotModel(kart.Name)
		local kare = model and UI.modelKaresi(kart, model, 74, 6)
		if kare then
			kare.Name = "Yumurta"
			kare.AnchorPoint = Vector2.new(0.5, 0)
			kare.Position = UDim2.new(0.5, 0, 0, 6)
		end
	end
end

------------------------------------------------------------------
-- CARK
------------------------------------------------------------------
local reel = Rulet.new(panel, {
	position = UDim2.new(0.5, 0, 0, 246),
	width = 616,
	height = 132,
	color = MOR_ACIK,
	name = "Cark",
})
reel.frame.ZIndex = 5

local sonucYazi = UI.text({
	text = "",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 36),
	position = UDim2.fromOffset(10, 386),
	parent = panel,
	zIndex = 8,
})

local detayYazi = UI.text({
	text = "Every egg hatches into a top-tier Brainrot!",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 22),
	position = UDim2.fromOffset(10, 422),
	parent = panel,
	zIndex = 8,
})

local function bekleSeridi()
	local sira: { string } = {}
	for _ = 1, 3 do
		for _, y in Ayar.Yumurtalar do
			table.insert(sira, y.rarity)
		end
	end
	Rulet.reset(reel, sira)
end
bekleSeridi()

------------------------------------------------------------------
-- SATIN ALMA DUGMESI
------------------------------------------------------------------
local dugmeKap = Instance.new("Frame")
dugmeKap.Name = "SatinAlma"
dugmeKap.AnchorPoint = Vector2.new(0.5, 0)
dugmeKap.Position = UDim2.new(0.5, 0, 0, 456)
dugmeKap.Size = UDim2.fromOffset(280, 72)
dugmeKap.BackgroundTransparency = 1
dugmeKap.ZIndex = 8
dugmeKap.Parent = panel

-- Dugmenin arkasinda nefes alan altin hale
local dugmeHale = UI.parlama(dugmeKap, ALTIN, 190, 7)
dugmeHale.Position = UDim2.fromScale(0.5, 0.5)

local satinDugme, satinYuz, satinYazi = UI.dugme3B(dugmeKap, "", UDim2.fromScale(1, 1), MOR, true)
satinDugme.ZIndex = 9
satinYuz.ZIndex = 9
if satinYazi then
	satinYazi.Text = ""
end

local dugmeIcerik = Instance.new("Frame")
dugmeIcerik.Name = "Icerik"
dugmeIcerik.Size = UDim2.fromScale(1, 1)
dugmeIcerik.BackgroundTransparency = 1
dugmeIcerik.ZIndex = 10
dugmeIcerik.Parent = satinYuz
do
	local dizi = Instance.new("UIListLayout")
	dizi.FillDirection = Enum.FillDirection.Horizontal
	dizi.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dizi.VerticalAlignment = Enum.VerticalAlignment.Center
	dizi.Padding = UDim.new(0, 12)
	dizi.SortOrder = Enum.SortOrder.LayoutOrder
	dizi.Parent = dugmeIcerik
end

local acYazi = UI.text({
	text = "OPEN",
	size = UI.Sizes.heading + 4,
	font = UI.Fonts.bold,
	color = BEYAZ,
	frameSize = UDim2.fromOffset(0, 34),
	parent = dugmeIcerik,
	zIndex = 10,
})
acYazi.AutomaticSize = Enum.AutomaticSize.X
acYazi.LayoutOrder = 1

local fiyatKutusu = UI.robuxFiyati(dugmeIcerik, Ayar.Fiyat, UI.Sizes.heading, 10)
fiyatKutusu.LayoutOrder = 2

-- Uzerinden gecen parilti bandi
do
	local bant = Instance.new("Frame")
	bant.Name = "Parilti"
	bant.AnchorPoint = Vector2.new(0.5, 0.5)
	bant.Position = UDim2.fromScale(-0.3, 0.5)
	bant.Size = UDim2.new(0, 46, 1.6, 0)
	bant.Rotation = 20
	bant.BackgroundColor3 = BEYAZ
	bant.BorderSizePixel = 0
	bant.ZIndex = 11
	bant.Parent = satinYuz
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = bant
	satinYuz.ClipsDescendants = true

	task.spawn(function()
		while bant.Parent do
			bant.Position = UDim2.fromScale(-0.3, 0.5)
			local t = TweenService:Create(bant, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Position = UDim2.fromScale(1.3, 0.5) })
			t:Play()
			t.Completed:Wait()
			task.wait(1.4)
		end
	end)
end

-- Nabiz: dugme hafifce buyuyup kuculur
do
	local olcek = Instance.new("UIScale")
	olcek.Parent = dugmeKap
	TweenService:Create(olcek, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.06 }):Play()
end

-- Yalnizca adminlere: ucretsiz deneme (yetki sunucuda da denetleniyor)
local adminDugme = UI.dugme3B(panel, "ADMIN TEST", UDim2.fromOffset(130, 44), UI.Colors.warn)
adminDugme.AnchorPoint = Vector2.new(1, 0)
adminDugme.Position = UDim2.new(1, -16, 0, 470)
adminDugme.ZIndex = 9
adminDugme.Visible = false

------------------------------------------------------------------
-- YILDIRIM
------------------------------------------------------------------
--[[
	Iki nokta arasinda zikzak bir simsek. Kirik cizgi kisa, dondurulmus
	cercevelerden kuruluyor; beyaz cekirdek + mor kontur. Bir iki kez
	titreyip soner. Yolun ortasindan kucuk bir dal ayrilabilir.
]]
local function simsek(kap: GuiObject, a: Vector2, b: Vector2, renk: Color3, kalinlik: number, z: number, dal: boolean?)
	local PARCA = 8
	local fark = b - a
	local uzunluk = fark.Magnitude
	if uzunluk < 1 then
		return
	end
	local dik = Vector2.new(-fark.Y, fark.X) / uzunluk
	local sapma = math.clamp(uzunluk * 0.09, 8, 46)

	local noktalar = { a }
	for i = 1, PARCA - 1 do
		local t = i / PARCA
		table.insert(noktalar, a + fark * t + dik * (math.random() * 2 - 1) * sapma)
	end
	table.insert(noktalar, b)

	local grup = Instance.new("Frame")
	grup.Name = "Simsek"
	grup.Size = UDim2.fromScale(1, 1)
	grup.BackgroundTransparency = 1
	grup.ZIndex = z
	grup.Parent = kap

	local parcalar: { Frame } = {}
	for i = 1, #noktalar - 1 do
		local p, q = noktalar[i], noktalar[i + 1]
		local d = q - p
		local seg = Instance.new("Frame")
		seg.AnchorPoint = Vector2.new(0.5, 0.5)
		seg.Position = UDim2.fromOffset((p.X + q.X) / 2, (p.Y + q.Y) / 2)
		seg.Size = UDim2.fromOffset(d.Magnitude + kalinlik, kalinlik)
		seg.Rotation = math.deg(math.atan2(d.Y, d.X))
		seg.BackgroundColor3 = BEYAZ
		seg.BorderSizePixel = 0
		seg.ZIndex = z
		seg.Parent = grup
		UI.corner(seg, 999)
		local cizgi = Instance.new("UIStroke")
		cizgi.Color = renk
		cizgi.Thickness = kalinlik * 0.9
		cizgi.Transparency = 0.1
		cizgi.Parent = seg
		table.insert(parcalar, seg)
	end

	-- Ortadan kucuk bir dal
	if dal ~= false and #noktalar > 4 then
		local kok = noktalar[math.random(3, #noktalar - 2)]
		local yon = (fark.Unit + dik * (math.random() * 2 - 1) * 1.4).Unit
		simsek(grup, kok, kok + yon * uzunluk * 0.3, renk, kalinlik * 0.6, z, false)
	end

	task.spawn(function()
		-- Titreme: bir sonup bir yanar
		for _ = 1, 2 do
			task.wait(0.05)
			grup.Visible = false
			task.wait(0.04)
			grup.Visible = true
		end
		local sonme = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		for _, seg in parcalar do
			TweenService:Create(seg, sonme, { BackgroundTransparency = 1 }):Play()
			local c = seg:FindFirstChildOfClass("UIStroke")
			if c then
				TweenService:Create(c, sonme, { Transparency = 1 }):Play()
			end
		end
		task.wait(0.35)
		grup:Destroy()
	end)
end

-- Bir yerin bir an parlamasi (panel ya da ekran)
local function flas(nesne: Frame, renk: Color3, guc: number, sure: number)
	nesne.BackgroundColor3 = renk
	nesne.BackgroundTransparency = 1 - guc
	TweenService:Create(nesne, TweenInfo.new(sure, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
end

--[[
	EKRAN KATMANI (panelin arkasi): karartma + donen huzmeler + yildirimlar.
	Lucky Block panelindekiyle ayni yontem; fon ekraninda, panel acikken.
]]
local fon = Instance.new("Frame")
fon.Name = "GachaFon"
fon.Size = UDim2.fromScale(1, 1)
fon.BackgroundColor3 = Color3.fromRGB(12, 0, 24)
fon.BackgroundTransparency = 0.35
fon.BorderSizePixel = 0
fon.Visible = false
fon.Parent = UI.fonEkrani() or screen

local huzmeler = Instance.new("Frame")
huzmeler.Name = "Huzmeler"
huzmeler.AnchorPoint = Vector2.new(0.5, 0.5)
huzmeler.Position = UDim2.fromScale(0.5, 0.5)
huzmeler.Size = UDim2.fromOffset(10, 10)
huzmeler.BackgroundTransparency = 1
huzmeler.Parent = fon

for i = 1, 12 do
	local huzme = Instance.new("Frame")
	huzme.AnchorPoint = Vector2.new(0.5, 0.5)
	huzme.Position = UDim2.fromScale(0.5, 0.5)
	huzme.Size = UDim2.fromOffset(110, 1800)
	huzme.Rotation = (i - 1) * 15
	huzme.BackgroundColor3 = if i % 2 == 0 then ALTIN else MOR
	huzme.BorderSizePixel = 0
	huzme.Parent = huzmeler
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.35, 0.7),
		NumberSequenceKeypoint.new(0.5, 0.45),
		NumberSequenceKeypoint.new(0.65, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = huzme
end

local huzmeDonus = TweenService:Create(
	huzmeler,
	TweenInfo.new(18, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
	{ Rotation = 360 }
)

local fonFlasi = Instance.new("Frame")
fonFlasi.Name = "Flas"
fonFlasi.Size = UDim2.fromScale(1, 1)
fonFlasi.BackgroundTransparency = 1
fonFlasi.BorderSizePixel = 0
fonFlasi.ZIndex = 5
fonFlasi.Parent = fon

-- Ekranin tepesinden asagi, panelin iki yanina dusen bir simsek
local function ekranSimsegi(renk: Color3?)
	local boy = fon.AbsoluteSize
	if boy.X < 10 then
		return
	end
	local solda = math.random() < 0.5
	local x = if solda then math.random() * boy.X * 0.3 else boy.X * (0.7 + math.random() * 0.3)
	local a = Vector2.new(x, -10)
	local b = Vector2.new(x + math.random(-160, 160), boy.Y * (0.55 + math.random() * 0.4))
	simsek(fon, a, b, renk or MOR_ACIK, math.random(4, 7), 6)
	flas(fonFlasi, MOR_ACIK, 0.25, 0.35)
end

-- Panelin icinde, arka katmanda kucuk bir simsek
local function panelSimsegi(renk: Color3?)
	local boy = icKatman.AbsoluteSize
	if boy.X < 10 then
		return
	end
	local a = Vector2.new(math.random() * boy.X, 0)
	local b = Vector2.new(math.random() * boy.X, boy.Y * (0.4 + math.random() * 0.6))
	simsek(icKatman, a, b, renk or PEMBE, 3, 3)
	flas(panelFlasi, MOR_ACIK, 0.12, 0.3)
end

panel:GetPropertyChangedSignal("Visible"):Connect(function()
	fon.Visible = panel.Visible
	if panel.Visible then
		huzmeler.Rotation = 0
		huzmeDonus:Play()
	else
		huzmeDonus:Cancel()
	end
end)

-- Panel acikken ara ara yildirim cakar
task.spawn(function()
	while true do
		task.wait(1.2 + math.random() * 2.2)
		if panel.Visible then
			if math.random() < 0.55 then
				ekranSimsegi()
			else
				panelSimsegi()
			end
		end
	end
end)

------------------------------------------------------------------
-- KUTLAMA
------------------------------------------------------------------
local ekranFlasi = Instance.new("Frame")
ekranFlasi.Name = "EkranFlasi"
ekranFlasi.Size = UDim2.fromScale(1, 1)
ekranFlasi.BackgroundColor3 = BEYAZ
ekranFlasi.BackgroundTransparency = 1
ekranFlasi.BorderSizePixel = 0
ekranFlasi.ZIndex = 1
ekranFlasi.Parent = efektEkrani

-- Ekranin ustunden yagan renkli konfeti
local function konfeti(renk: Color3, adet: number)
	local boy = efektEkrani.AbsoluteSize
	local renkler = { renk, renk:Lerp(BEYAZ, 0.4), ALTIN, PEMBE, MOR_ACIK }
	for _ = 1, adet do
		local parca = Instance.new("Frame")
		parca.AnchorPoint = Vector2.new(0.5, 0.5)
		local x = math.random() * boy.X
		parca.Position = UDim2.fromOffset(x, -20 - math.random() * 120)
		parca.Size = UDim2.fromOffset(math.random(8, 14), math.random(14, 22))
		parca.Rotation = math.random(0, 360)
		parca.BackgroundColor3 = renkler[math.random(1, #renkler)]
		parca.BorderSizePixel = 0
		parca.ZIndex = 3
		parca.Parent = efektEkrani
		UI.corner(parca, 3)

		local sure = 1.8 + math.random() * 1.6
		TweenService:Create(parca, TweenInfo.new(sure, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromOffset(x + math.random(-180, 180), boy.Y + 40),
			Rotation = parca.Rotation + math.random(-720, 720),
		}):Play()
		task.delay(sure, function()
			parca:Destroy()
		end)
	end
end

-- Ekranin ortasinda kocaman yazi: buyuyerek gelir, bekler, solar
local function kocamanYazi(metin: string, rarityId: string?, y: number, boyut: number)
	local yazi = UI.text({
		text = metin,
		size = boyut,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, boyut + 12),
		position = UDim2.new(0, 0, y, 0),
		parent = efektEkrani,
		zIndex = 4,
	})
	if rarityId then
		UI.rarityStyle(yazi, rarityId)
	end

	local olcek = Instance.new("UIScale")
	olcek.Scale = 0.2
	olcek.Parent = yazi
	TweenService:Create(olcek, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	task.delay(2.2, function()
		TweenService:Create(olcek, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 1.4 }):Play()
		TweenService:Create(yazi, TweenInfo.new(0.35), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.wait(0.4)
		yazi:Destroy()
	end)
end

local function kutla(rarityId: string, ad: string)
	local renk = Rarity.color(rarityId)
	local buyuk = JACKPOT[rarityId] == true

	-- Ekran bir an beyaza, sonra kademe rengine doner ve solar
	flas(ekranFlasi, BEYAZ, 0.85, 0.25)
	task.delay(0.12, function()
		flas(ekranFlasi, renk, 0.55, 0.8)
	end)

	Rulet.kutla(reel, renk)
	Rulet.shake(panel)

	-- Yildirim yagmuru
	task.spawn(function()
		for _ = 1, if buyuk then 10 else 5 do
			ekranSimsegi(renk:Lerp(BEYAZ, 0.3))
			panelSimsegi(renk)
			task.wait(0.09)
		end
	end)

	konfeti(renk, if buyuk then 110 else 60)

	if buyuk then
		kocamanYazi("JACKPOT!", nil, 0.16, 72)
		-- Ikinci dalga
		task.delay(0.5, function()
			Rulet.kutla(reel, renk)
			Rulet.shake(panel)
			konfeti(renk, 60)
		end)
	end
	kocamanYazi(string.upper(ad) .. "!", rarityId, if buyuk then 0.28 else 0.2, 54)

	-- Kazanan kademenin sans karti zipler
	for _, kart in kartlar do
		if kart.Name == rarityId then
			local olcek = kart:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
			olcek.Parent = kart
			olcek.Scale = 1.25
			TweenService:Create(olcek, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
	end

	sonucYazi.Text = string.upper(ad)
	UI.rarityStyle(sonucYazi, rarityId)
	detayYazi.Text = "Take it to the Detective to reveal your Brainrot!"
	detayYazi.TextColor3 = renk:Lerp(BEYAZ, 0.35)
end

------------------------------------------------------------------
-- CEVIRME
------------------------------------------------------------------
local donuyor = false

local function dugmeleriCiz()
	UI.dugme3BRenk(satinDugme, if donuyor then Color3.fromRGB(90, 70, 110) else MOR)
	acYazi.Text = if donuyor then "SPINNING..." else "OPEN"
	fiyatKutusu.Visible = not donuyor
end

-- Seritteki bir kademe, sanslara gore (dolgu icin)
local dolguZari = Random.new()
local function rastgeleKademe(): string
	return Ayar.sec(dolguZari)
end

local function cevir(rarityId: string, ad: string)
	if donuyor then
		return
	end
	donuyor = true
	dugmeleriCiz()
	yumurtalariKur()

	if not panel.Visible then
		panel.Visible = true
	end

	sonucYazi.Text = ""
	detayYazi.Text = "Spinning..."
	detayYazi.TextColor3 = UI.Colors.textDim

	local kazanan = Ayar.KazananSira
	local cells: { Rulet.Cell } = {}
	for i = 1, Ayar.BolmeSayisi do
		local kademe = if i == kazanan then rarityId else rastgeleKademe()
		-- Kazananin hemen yaninda bir Abyssal: "az kalsin" heyecani
		if i == kazanan + 1 and rarityId ~= "Abyssal" then
			kademe = "Abyssal"
		end
		table.insert(cells, {
			text = Ayar.yumurtaAdi(Rarity.displayName(kademe)),
			color = Rarity.color(kademe),
			rarity = kademe,
			yumurta = kademe,
		})
	end

	task.wait(Ayar.GirisSuresi)

	-- Donerken gerilim: arada bir yildirim
	local acilisSesi = YerelSes.cal("LuckyBlockOpening")

	local basladi = Rulet.run(reel, {
		cells = cells,
		winner = kazanan,
		time = Ayar.CevirmeSuresi,
		onFinish = function()
			YerelSes.durdur(acilisSesi)
			kutla(rarityId, ad)
			task.delay(1.2, function()
				donuyor = false
				dugmeleriCiz()
			end)
		end,
	})

	if not basladi then
		YerelSes.durdur(acilisSesi)
		donuyor = false
		dugmeleriCiz()
		return
	end

	task.spawn(function()
		local bitis = os.clock() + Ayar.CevirmeSuresi - 0.6
		while os.clock() < bitis and donuyor do
			task.wait(0.5 + math.random() * 0.7)
			panelSimsegi()
		end
	end)
end

------------------------------------------------------------------
-- DUGMELER VE SUNUCU
------------------------------------------------------------------
satinDugme.MouseButton1Click:Connect(function()
	if donuyor then
		return
	end
	RobuxUrunAl:FireServer(Ayar.UrunAnahtari)
end)

adminDugme.MouseButton1Click:Connect(function()
	if donuyor then
		return
	end
	GachaDene:FireServer()
end)

GachaAc.OnClientEvent:Connect(function(veri)
	adminDugme.Visible = type(veri) == "table" and veri.admin == true
	yumurtalariKur()
	if not donuyor then
		bekleSeridi()
		sonucYazi.Text = ""
		detayYazi.Text = "Every egg hatches into a top-tier Brainrot!"
		detayYazi.TextColor3 = UI.Colors.textDim
	end
	panel.Visible = true
	-- Acilista bir simsek: pencere "gurleyerek" gelsin
	task.delay(0.15, ekranSimsegi)
end)

GachaSonuc.OnClientEvent:Connect(function(veri)
	if type(veri) ~= "table" or type(veri.rarity) ~= "string" then
		return
	end
	local ad = if type(veri.ad) == "string" then veri.ad else Ayar.yumurtaAdi(Rarity.displayName(veri.rarity))
	cevir(veri.rarity, ad)
end)

dugmeleriCiz()
