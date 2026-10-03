local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Icons = require(Shared:WaitForChild("Icons"))
local Assets = require(Shared:WaitForChild("Assets"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Passler = require(Shared:WaitForChild("Passler"))
local RobuxMagaza = require(Shared:WaitForChild("RobuxMagaza"))

local UI = require(script.Parent:WaitForChild("UI"))

local ArayuzSesi = { tikla = function() end }
do
	local modul = script.Parent:WaitForChild("ArayuzSesi", 5)
	if modul then
		local ok, sonuc = pcall(require, modul)
		if ok then
			ArayuzSesi = sonuc
		end
	end
end

local RobuxUrunAl = Net.event("RobuxUrunAl")
local PassSatinAl = Net.event("PassSatinAl")

local SIYAH = Color3.fromRGB(0, 0, 0)
local BEYAZ = Color3.fromRGB(255, 255, 255)
local ALTIN = Color3.fromRGB(255, 200, 40)
local YESIL = Color3.fromRGB(70, 205, 85)
local KIRMIZI = Color3.fromRGB(255, 70, 70)

local LIP = 5

local IKON_X = 12
local IKON_NORMAL = 88
local LUCKY_X = 26
local LUCKY_BOYU = 190
local LUCKY_KART_BOYU = 240

local HUZME_AYARI: { [string]: UI.HuzmeAyari } = {
	Hacker = {
		sayi = 18,
		uzunluk = 240,
		kalinlik = 26,
		tur = 5,
		parlaklik = 0.06,
		zIndex = 4,
		renk = Color3.fromRGB(70, 255, 120),
	},
	Diamond = { sayi = 12, uzunluk = 240, kalinlik = 34, tur = 16, parlaklik = 0.12, zIndex = 4 },
	Golden = {
		sayi = 8,
		uzunluk = 180,
		kalinlik = 26,
		tur = 20,
		parlaklik = 0.3,
		zIndex = 4,
		renk = Color3.fromRGB(255, 250, 230),
	},
}

local KENAR_RENKLERI: { [string]: { Color3 } } = {
	Hacker = {
		Color3.fromRGB(90, 255, 140),
		Color3.fromRGB(10, 40, 20),
		Color3.fromRGB(200, 255, 210),
		Color3.fromRGB(10, 40, 20),
	},
	Diamond = {
		Color3.fromRGB(120, 235, 255),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(190, 120, 255),
		Color3.fromRGB(255, 140, 230),
	},
	Golden = {
		Color3.fromRGB(255, 215, 60),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 140, 30),
		Color3.fromRGB(255, 245, 180),
	},
	Baslangic = {
		Color3.fromRGB(255, 230, 90),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 120, 40),
		Color3.fromRGB(255, 255, 255),
	},
}

local EN_IYI_RENK = Color3.fromRGB(255, 165, 20)
local ROZET_RENK = Color3.fromRGB(255, 70, 160)

local ARKA_PLAN: { [string]: string } = {
	Diamond = "diamondbackground",
	Hacker = "hackerbackground",
	Golden = "goldenbackground",
}

local PARILTI_SAYISI: { [string]: number } = {
	Hacker = 34,
}
local PARILTI_VARSAYILAN = 16

local ARKA_PLAN_SAYDAM = 0.42
local ARKA_PLAN_YAYILMA = 3

local BASLIK_GORUNUM: { [string]: { renk: Color3, boyutEk: number } } = {
	Diamond = { renk = Color3.fromRGB(120, 235, 255), boyutEk = 8 },
	Hacker = { renk = Color3.fromRGB(80, 255, 130), boyutEk = 8 },
}

local GECIS_GORUNUM = {
	AutoClicker = { ikon = "autoClicker", renkA = Color3.fromRGB(255, 120, 60), renkB = Color3.fromRGB(230, 60, 110) },
	Teleporter = { ikon = "teleporter", renkA = Color3.fromRGB(150, 120, 255), renkB = Color3.fromRGB(80, 90, 230) },
	DetectivePass = { ikon = "detective", renkA = Color3.fromRGB(90, 200, 255), renkB = Color3.fromRGB(40, 110, 220) },
	SansX2 = { ikon = "luck2", renkA = Color3.fromRGB(60, 210, 90), renkB = Color3.fromRGB(150, 235, 40) },
	RotX15 = { ikon = "rot", renkA = Color3.fromRGB(40, 190, 120), renkB = Color3.fromRGB(20, 120, 90) },
}

local screen = Instance.new("ScreenGui")
screen.Name = "RobuxMagazasi"
screen.DisplayOrder = 5
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local function renkliZemin(frame: GuiObject, renkA: Color3, renkB: Color3, yaricap: number, desensiz: boolean?)
	frame.BackgroundColor3 = BEYAZ

	local gecis = Instance.new("UIGradient")
	gecis.Color = ColorSequence.new(renkA, renkB)
	gecis.Rotation = 0
	gecis.Parent = frame

	if not desensiz then
		UI.caprazDesen(frame)
	end
	UI.gloss(frame, 0.8)

	for _, cocuk in frame:GetChildren() do
		if cocuk:IsA("GuiObject") and (cocuk.Name == "Desen" or cocuk.Name == "Parlaklik") then
			UI.corner(cocuk, yaricap)
		end
	end
end

local function taramaIsigi(hedef: GuiObject, kose: number, zIndex: number, sure: number, bekleme: number, tepe: number): Frame
	local isik = Instance.new("Frame")
	isik.Name = "Tarama"
	isik.Size = UDim2.fromScale(1, 1)
	isik.BackgroundColor3 = BEYAZ
	isik.BorderSizePixel = 0
	isik.ZIndex = zIndex
	isik.Parent = hedef
	UI.corner(isik, kose)

	local kenar = tepe + (1 - tepe) * 0.55
	local bant = Instance.new("UIGradient")
	bant.Rotation = 24
	bant.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 1),
		NumberSequenceKeypoint.new(0.46, kenar),
		NumberSequenceKeypoint.new(0.5, tepe),
		NumberSequenceKeypoint.new(0.54, kenar),
		NumberSequenceKeypoint.new(0.57, 1),
		NumberSequenceKeypoint.new(0.6, kenar),
		NumberSequenceKeypoint.new(0.63, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	bant.Offset = Vector2.new(-1.2, 0)
	bant.Parent = isik

	task.delay(math.random() * bekleme, function()
		if not isik.Parent then
			return
		end
		TweenService:Create(
			bant,
			TweenInfo.new(sure, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false, bekleme),
			{ Offset = Vector2.new(1.2, 0) }
		):Play()
	end)

	return isik
end

local function kenarAkisi(kontur: UIStroke, renkler: { Color3 }, sure: number)
	kontur.Color = BEYAZ

	local noktalar = {}
	for i, renk in renkler do
		table.insert(noktalar, ColorSequenceKeypoint.new((i - 1) / #renkler, renk))
	end
	table.insert(noktalar, ColorSequenceKeypoint.new(1, renkler[1]))

	local gecis = Instance.new("UIGradient")
	gecis.Name = "KenarAkisi"
	gecis.Color = ColorSequence.new(noktalar)
	gecis.Parent = kontur

	TweenService:Create(
		gecis,
		TweenInfo.new(sure, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{ Rotation = 360 }
	):Play()
end

local function varsayilanKenar(renkA: Color3, renkB: Color3): { Color3 }
	return { BEYAZ, renkA:Lerp(BEYAZ, 0.3), BEYAZ, renkB:Lerp(BEYAZ, 0.3) }
end

local function dalga(yuz: GuiObject)
	local halka = Instance.new("Frame")
	halka.Name = "Dalga"
	halka.AnchorPoint = Vector2.new(0.5, 0.5)
	halka.Position = UDim2.fromScale(0.5, 0.5)
	halka.Size = UDim2.fromScale(0.1, 0.1)
	halka.SizeConstraint = Enum.SizeConstraint.RelativeXX
	halka.BackgroundColor3 = BEYAZ
	halka.BackgroundTransparency = 0.3
	halka.BorderSizePixel = 0
	halka.ZIndex = 4
	halka.Parent = yuz
	UI.corner(halka, 1000)

	local sonme = TweenService:Create(
		halka,
		TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.fromScale(1.3, 1.3), BackgroundTransparency = 1 }
	)
	sonme.Completed:Connect(function()
		halka:Destroy()
	end)
	sonme:Play()
end

local function yaziIsiltisi(etiket: TextLabel, renk: Color3)
	etiket.TextColor3 = BEYAZ

	local gecis = Instance.new("UIGradient")
	gecis.Name = "Isilti"
	gecis.Rotation = 15
	gecis.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, renk),
		ColorSequenceKeypoint.new(0.4, renk),
		ColorSequenceKeypoint.new(0.5, BEYAZ),
		ColorSequenceKeypoint.new(0.6, renk),
		ColorSequenceKeypoint.new(1, renk),
	})
	gecis.Offset = Vector2.new(-1, 0)
	gecis.Parent = etiket

	TweenService:Create(
		gecis,
		TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 1.2),
		{ Offset = Vector2.new(1, 0) }
	):Play()
end

local YAGMUR_AYARI: { [string]: UI.YagmurAyari } = {
	MegaLuck = { renk = Color3.fromRGB(170, 255, 140), sayi = 14, boyut = 10, sure = 5, sekil = "elmas", saydam = 0.35, zIndex = 1 },
	RotCoins = { renk = Color3.fromRGB(255, 225, 90), sayi = 16, boyut = 13, sure = 4.5, sekil = "daire", saydam = 0.2, zIndex = 1 },
}

local function dokuKatmani(kart: GuiObject, merkez: UDim2, boyu: number, yagmur: UI.YagmurAyari?)
	local kap = Instance.new("Frame")
	kap.Name = "Doku"
	kap.Size = UDim2.fromScale(1, 1)
	kap.BackgroundTransparency = 1
	kap.BorderSizePixel = 0
	kap.ClipsDescendants = true
	kap.ZIndex = 1
	kap.Parent = kart

	UI.isikHuzmeleri(kap, BEYAZ, {
		sayi = 10,
		uzunluk = math.floor(boyu * 2.6),
		kalinlik = math.floor(boyu * 0.32),
		tur = 22,
		parlaklik = 0.62,
		zIndex = 1,
	}).Position = merkez

	local akis = Instance.new("Frame")
	akis.Name = "AkanSeritler"
	akis.Size = UDim2.fromScale(2, 1)
	akis.BackgroundTransparency = 1
	akis.ZIndex = 1
	akis.Parent = kap
	UI.stripeLayer(akis, BEYAZ, 32, 10, 0.9)
	TweenService:Create(
		akis,
		TweenInfo.new(7, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{ Position = UDim2.fromScale(-1, 0) }
	):Play()

	if yagmur then
		UI.corner(UI.parcaYagmuru(kart, yagmur), 12)
	else
		UI.pariltilar(kap, BEYAZ, 8, 1)
	end

	local golge = Instance.new("Frame")
	golge.Name = "Golge"
	golge.Size = UDim2.fromScale(1, 1)
	golge.BackgroundColor3 = SIYAH
	golge.BorderSizePixel = 0
	golge.ZIndex = 1
	golge.Parent = kart
	UI.corner(golge, 12)
	local karartma = Instance.new("UIGradient")
	karartma.Rotation = 90
	karartma.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.55, 1),
		NumberSequenceKeypoint.new(1, 0.72),
	})
	karartma.Parent = golge
end

local kartlar: { GuiObject } = {}

local function kartCanlandir(kart: GuiObject)
	local olcek = Instance.new("UIScale")
	olcek.Name = "KartOlcek"
	olcek.Parent = kart

	local bilgi = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	kart.MouseEnter:Connect(function()
		TweenService:Create(olcek, bilgi, { Scale = 1.02 }):Play()
	end)
	kart.MouseLeave:Connect(function()
		TweenService:Create(olcek, bilgi, { Scale = 1 }):Play()
	end)

	taramaIsigi(kart, 12, 3, 1.1, 4.5, 0.72)
	table.insert(kartlar, kart)
end

local function satinAlmaDugmesi(parent: Instance, renk: Color3, buyusun: boolean?): (TextButton, Frame)
	local buton = Instance.new("TextButton")
	buton.Name = "SatinAl"
	buton.Text = ""
	buton.AutoButtonColor = false
	buton.BackgroundColor3 = UI.shade(renk, -0.3)
	buton.BorderSizePixel = 0
	buton.Parent = parent
	UI.corner(buton, 10)
	local cerceve = UI.stroke(buton, BEYAZ, 3)
	cerceve.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local yuz = Instance.new("Frame")
	yuz.Name = "Yuz"
	yuz.AnchorPoint = Vector2.new(0.5, 0)
	yuz.Position = UDim2.new(0.5, 0, 0, 3)
	yuz.Size = UDim2.new(1, -6, 1, -6 - LIP)
	yuz.BorderSizePixel = 0
	yuz.ClipsDescendants = true
	yuz.Parent = buton
	UI.corner(yuz, 8)
	UI.polish(yuz, renk, 8)

	local function bas(asagi: boolean)
		yuz.Position = UDim2.new(0.5, 0, 0, if asagi then 3 + LIP / 2 else 3)
	end
	buton.MouseButton1Down:Connect(function()
		bas(true)
	end)
	buton.MouseButton1Up:Connect(function()
		bas(false)
	end)
	buton.MouseLeave:Connect(function()
		bas(false)
	end)

	UI.hover(buton, yuz, if buyusun then buton else nil)

	taramaIsigi(yuz, 8, 4, 0.75, 2.6, 0.45)
	buton.Activated:Connect(function()
		dalga(yuz)
	end)

	return buton, yuz
end

local function yuzYazisi(yuz: Frame, yazi: string, boyut: number, y: number, yukseklik: number): TextLabel
	return UI.text({
		text = yazi,
		size = boyut,
		font = UI.Fonts.bold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -4, 0, yukseklik),
		position = UDim2.new(0, 2, 0, y),
		parent = yuz,
		zIndex = 5,
	})
end

local IKON_ORANI = 1.5
local function robuxNesnesi(): Instance?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local ikonlar = assets and assets:FindFirstChild("Icons")
	local node = ikonlar and ikonlar:FindFirstChild("Robux", true)
	return if node and (node:IsA("BasePart") or node:IsA("Model")) then node:Clone() else nil
end

local function robuxYazisi(yuz: Frame, miktar: number, boyut: number, y: number, yukseklik: number): Frame
	local resim = Icons.asset("Robux")
	local nesne = if resim then nil else robuxNesnesi()
	local ikonBoy = math.floor(boyut * IKON_ORANI)

	local kutu = Instance.new("Frame")
	kutu.Name = "Fiyat"
	kutu.AnchorPoint = Vector2.new(0.5, 0)
	kutu.Position = UDim2.new(0.5, 0, 0, y)
	kutu.Size = UDim2.fromOffset(0, yukseklik)
	kutu.AutomaticSize = Enum.AutomaticSize.X
	kutu.BackgroundTransparency = 1
	kutu.ZIndex = 5
	kutu.Parent = yuz

	local dizilim = Instance.new("UIListLayout")
	dizilim.FillDirection = Enum.FillDirection.Horizontal
	dizilim.VerticalAlignment = Enum.VerticalAlignment.Center
	dizilim.Padding = UDim.new(0, 5)
	dizilim.SortOrder = Enum.SortOrder.LayoutOrder
	dizilim.Parent = kutu

	if resim then
		local ikon = Instance.new("ImageLabel")
		ikon.Name = "Ikon"
		ikon.BackgroundTransparency = 1
		ikon.Image = resim
		ikon.ScaleType = Enum.ScaleType.Fit
		ikon.Size = UDim2.fromOffset(ikonBoy, ikonBoy)
		ikon.LayoutOrder = 1
		ikon.ZIndex = 5
		ikon.Parent = kutu
	elseif nesne then
		local kare = UI.modelKaresi(kutu, nesne, ikonBoy + 4, 5)
		if kare then
			kare.Name = "Ikon"
			kare.LayoutOrder = 1
		end
	end

	local sayi = UI.text({
		text = if resim or nesne then tostring(miktar) else `R$ {miktar}`,
		size = boyut,
		font = UI.Fonts.bold,
		frameSize = UDim2.fromOffset(0, yukseklik),
		parent = kutu,
		zIndex = 5,
	})
	sayi.AutomaticSize = Enum.AutomaticSize.X
	sayi.LayoutOrder = 2

	return kutu
end

local SERIT_ZINDEX = 20

local SERIT_HUZME: UI.HuzmeAyari = {
	sayi = 7,
	uzunluk = 96,
	kalinlik = 13,
	tur = 6,
	parlaklik = 0.25,
	zIndex = SERIT_ZINDEX - 1,
}

local SERIT_KIRMIZI = Color3.fromRGB(255, 45, 45)

local function serit(kart: Frame, yazi: string)
	local kap = Instance.new("Frame")
	kap.Name = "Serit"
	kap.AnchorPoint = Vector2.new(0, 0)
	kap.Position = UDim2.fromOffset(6, 4)
	kap.Size = UDim2.fromOffset(78, 26)
	kap.BackgroundTransparency = 1
	kap.ZIndex = SERIT_ZINDEX
	kap.Parent = kart

	UI.isikHuzmeleri(kap, SERIT_KIRMIZI, SERIT_HUZME)

	local etiket = UI.text({
		text = yazi,
		size = UI.Sizes.heading,
		font = UI.Fonts.bold,
		color = SERIT_KIRMIZI,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = kap,
		zIndex = SERIT_ZINDEX,
	})
	etiket.Name = "Yazi"
	etiket.TextTruncate = Enum.TextTruncate.None
	etiket.Rotation = -14
	UI.stroke(etiket, Color3.fromRGB(0, 0, 0), 3)

	local olcek = Instance.new("UIScale")
	olcek.Parent = kap
	TweenService:Create(
		olcek,
		TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Scale = 1.12 }
	):Play()
end

local function indirimRozeti(buton: GuiObject, eski: number, yeni: number)
	local oran = math.floor((1 - yeni / eski) * 100 + 0.5)
	if oran <= 0 then
		return
	end

	local kap = Instance.new("Frame")
	kap.Name = "Indirim"
	kap.AnchorPoint = Vector2.new(0.5, 0.5)
	kap.Position = UDim2.fromOffset(2, 2)
	kap.Size = UDim2.fromOffset(46, 46)
	kap.BackgroundTransparency = 1
	kap.ZIndex = 9
	kap.Parent = buton

	local yildiz = Instance.new("Frame")
	yildiz.Name = "Yildiz"
	yildiz.AnchorPoint = Vector2.new(0.5, 0.5)
	yildiz.Position = UDim2.fromScale(0.5, 0.5)
	yildiz.Size = UDim2.fromScale(1, 1)
	yildiz.BackgroundTransparency = 1
	yildiz.ZIndex = 9
	yildiz.Parent = kap

	for _, katman in { { olcu = 0.8, renk = SIYAH }, { olcu = 0.7, renk = SERIT_KIRMIZI } } do
		for _, aci in { 0, 30, 60 } do
			local kare = Instance.new("Frame")
			kare.Name = "Uc"
			kare.AnchorPoint = Vector2.new(0.5, 0.5)
			kare.Position = UDim2.fromScale(0.5, 0.5)
			kare.Size = UDim2.fromScale(katman.olcu, katman.olcu)
			kare.Rotation = aci
			kare.BackgroundColor3 = katman.renk
			kare.BorderSizePixel = 0
			kare.ZIndex = 9
			kare.Parent = yildiz
		end
	end

	local yazi = UI.text({
		text = `-{oran}%`,
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = kap,
		zIndex = 10,
	})
	yazi.Name = "Oran"
	yazi.Rotation = -12

	TweenService:Create(
		yildiz,
		TweenInfo.new(7, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{ Rotation = 360 }
	):Play()

	local olcek = Instance.new("UIScale")
	olcek.Parent = kap
	TweenService:Create(
		olcek,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Scale = 1.12 }
	):Play()
end

local function etiketHapi(buton: GuiObject, yazi: string, renk: Color3)
	local hap = Instance.new("Frame")
	hap.Name = "EtiketHapi"
	hap.AnchorPoint = Vector2.new(0.5, 0)
	hap.Position = UDim2.new(0.5, 0, 1, 3)
	hap.Size = UDim2.fromOffset(0, 20)
	hap.AutomaticSize = Enum.AutomaticSize.X
	hap.BackgroundColor3 = BEYAZ
	hap.BorderSizePixel = 0
	hap.ZIndex = 9
	hap.Parent = buton
	UI.corner(hap, 10)
	UI.stroke(hap, SIYAH, 2)

	local gecis = Instance.new("UIGradient")
	gecis.Rotation = 90
	gecis.Color = ColorSequence.new(UI.shade(renk, 0.25), UI.shade(renk, -0.15))
	gecis.Parent = hap

	local pay = Instance.new("UIPadding")
	pay.PaddingLeft = UDim.new(0, 10)
	pay.PaddingRight = UDim.new(0, 10)
	pay.Parent = hap

	local etiket = UI.text({
		text = yazi,
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		color = BEYAZ,
		frameSize = UDim2.fromOffset(0, 20),
		parent = hap,
		zIndex = 11,
	})
	etiket.AutomaticSize = Enum.AutomaticSize.X
	etiket.TextTruncate = Enum.TextTruncate.None

	taramaIsigi(hap, 10, 10, 0.6, 1.8, 0.25)
end

local function kartIkonu(kart: Frame, ikonAdi: string, boyut: number, renk: Color3?): ImageLabel
	local ikon = Instance.new("ImageLabel")
	ikon.Name = "Ikon"
	ikon.BackgroundTransparency = 1
	ikon.AnchorPoint = Vector2.new(0, 0.5)
	ikon.Position = UDim2.new(0, IKON_X, 0.5, 0)
	ikon.Size = UDim2.fromOffset(boyut, boyut)
	ikon.ScaleType = Enum.ScaleType.Fit
	ikon.ZIndex = 5
	ikon.Parent = kart
	if renk then
		ikon.ImageColor3 = BEYAZ:Lerp(renk, 0.35)
	end

	local yedek = UI.text({
		text = "?",
		size = UI.Sizes.huge,
		font = UI.Fonts.bold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = ikon,
		zIndex = 5,
	})

	Icons.bind(ikon, ikonAdi, function(ok)
		if ok then
			yedek.Visible = false
		end
	end)

	return ikon
end

local panel = UI.panel(screen, UDim2.fromOffset(720, 540), "RobuxMagaza")
do
	local kontur = panel:FindFirstChildOfClass("UIStroke")
	if kontur then
		kontur.Color = SIYAH
		kontur.Thickness = 3
	end
end

local baslik = Instance.new("Frame")
baslik.Name = "Baslik"
baslik.Position = UDim2.fromOffset(8, 8)
baslik.Size = UDim2.new(1, -16, 0, 54)
baslik.BorderSizePixel = 0
baslik.ClipsDescendants = true
baslik.Parent = panel
UI.corner(baslik, 10)
UI.polish(baslik, ALTIN, 10)
UI.stroke(baslik, SIYAH, 2)
taramaIsigi(baslik, 10, 4, 0.9, 3.5, 0.5)
UI.pariltilar(baslik, BEYAZ, 10, 3)

do
	local ikon = Instance.new("ImageLabel")
	ikon.Name = "Ikon"
	ikon.BackgroundTransparency = 1
	ikon.Position = UDim2.fromOffset(8, 3)
	ikon.Size = UDim2.fromOffset(48, 48)
	ikon.ScaleType = Enum.ScaleType.Fit
	ikon.ZIndex = 5
	ikon.Parent = baslik
	Icons.bind(ikon, "shop")

	UI.text({
		text = "Store",
		size = UI.Sizes.title,
		font = UI.Fonts.bold,
		frameSize = UDim2.new(1, -140, 1, 0),
		position = UDim2.fromOffset(62, 0),
		parent = baslik,
		zIndex = 5,
	})
end

local kapat = UI.closeButton(panel)
kapat.Position = UDim2.new(1, -18, 0, 18)
kapat.ZIndex = 6
UI.stroke(kapat, SIYAH, 2)
kapat.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

local listeKabi = Instance.new("CanvasGroup")
listeKabi.Name = "ListeKabi"
listeKabi.Position = UDim2.fromOffset(12, 72)
listeKabi.Size = UDim2.new(1, -24, 1, -84)
listeKabi.BackgroundTransparency = 1
listeKabi.BorderSizePixel = 0
listeKabi.Parent = panel

local liste = Instance.new("ScrollingFrame")
liste.Name = "Liste"
liste.Size = UDim2.fromScale(1, 1)
liste.BackgroundTransparency = 1
liste.BorderSizePixel = 0
liste.ScrollBarThickness = 6
liste.ScrollBarImageColor3 = UI.Colors.panelLight
liste.CanvasSize = UDim2.new()
liste.AutomaticCanvasSize = Enum.AutomaticSize.Y
liste.Parent = listeKabi
UI.listePayi(liste)

do
	local dizilim = Instance.new("UIListLayout")
	dizilim.Padding = UDim.new(0, 16)
	dizilim.SortOrder = Enum.SortOrder.LayoutOrder
	dizilim.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dizilim.Parent = liste

	local pay = Instance.new("UIPadding")
	pay.PaddingTop = UDim.new(0, 16)
	pay.PaddingBottom = UDim.new(0, 12)
	pay.PaddingLeft = UDim.new(0, 14)
	pay.PaddingRight = UDim.new(0, 14)
	pay.Parent = liste
end

local sira = 0
local function sonraki(): number
	sira += 1
	return sira
end

local function bolumBasligi(yazi: string)
	local etiket = UI.text({
		text = yazi,
		size = UI.Sizes.heading,
		font = UI.Fonts.bold,
		color = ALTIN,
		frameSize = UDim2.new(1, 0, 0, 28),
		parent = liste,
	})
	etiket.LayoutOrder = sonraki()
	yaziIsiltisi(etiket, ALTIN)
end

local BAKIS_YONU = Vector3.new(0, 0, -1)
local ONIZLEME_ISIGI = Color3.fromRGB(255, 255, 255)
local ONIZLEME_ISIK_YONU = Vector3.new(-0.4, -0.7, -0.6)
local ONIZLEME_CERCEVE = 0.78

local DURUS = CFrame.Angles(0, math.rad(28), 0) * CFrame.Angles(math.rad(-16), 0, 0)

local onizlemeler: { { model: Model, merkez: Vector3, taban: CFrame } } = {}

local function gorunenKutu(model: Model): (Vector3?, Vector3?)
	local enAz: Vector3? = nil
	local enCok: Vector3? = nil

	for _, parca in model:GetDescendants() do
		if not parca:IsA("BasePart") or parca.Transparency >= 0.99 then
			continue
		end

		local cf, olcu = parca.CFrame, parca.Size
		for _, sx in { -0.5, 0.5 } do
			for _, sy in { -0.5, 0.5 } do
				for _, sz in { -0.5, 0.5 } do
					local kose = (cf * CFrame.new(olcu.X * sx, olcu.Y * sy, olcu.Z * sz)).Position
					enAz = if enAz then enAz:Min(kose) else kose
					enCok = if enCok then enCok:Max(kose) else kose
				end
			end
		end
	end

	if not enAz or not enCok then
		return nil, nil
	end
	return (enAz + enCok) / 2, enCok - enAz
end

local function luckyOnizleme(kart: Frame, tier: any, x: number, boyut: number): ViewportFrame?
	local model = Assets.luckyBlockModel(tier.modelName or tier.displayName, tier.order)
	if not model then
		return nil
	end

	for _, nesne in model:GetDescendants() do
		if nesne:IsA("BaseScript") or nesne:IsA("Sound") then
			nesne:Destroy()
		end
	end

	local merkez, kutuBoyut = gorunenKutu(model)
	if not merkez or not kutuBoyut then
		model:Destroy()
		return nil
	end

	local vp = Instance.new("ViewportFrame")
	vp.Name = "Onizleme"
	vp.AnchorPoint = Vector2.new(0, 0.5)
	vp.Position = UDim2.new(0, x, 0.5, 0)
	vp.Size = UDim2.fromOffset(boyut, boyut)
	vp.BackgroundTransparency = 1
	vp.Ambient = ONIZLEME_ISIGI
	vp.LightColor = ONIZLEME_ISIGI
	vp.LightDirection = ONIZLEME_ISIK_YONU
	vp.ZIndex = 5
	vp.Parent = kart

	model.Parent = vp

	local kamera = Instance.new("Camera")
	kamera.Parent = vp
	vp.CurrentCamera = kamera

	kamera.CFrame = CFrame.lookAt(merkez + BAKIS_YONU * kutuBoyut.Magnitude * ONIZLEME_CERCEVE, merkez)

	table.insert(onizlemeler, { model = model, merkez = merkez, taban = model:GetPivot() })

	return vp
end

RunService.RenderStepped:Connect(function()
	if not panel.Visible then
		return
	end

	local aci = math.rad(UI.SallanmaAci) * math.sin(os.clock() * math.pi / UI.SallanmaSuresi)

	for _, kayit in onizlemeler do
		if not kayit.model.Parent then
			continue
		end
		local donus = CFrame.new(kayit.merkez)
			* CFrame.Angles(0, aci, 0)
			* DURUS
			* CFrame.new(-kayit.merkez)
		kayit.model:PivotTo(donus * kayit.taban)
	end
end)

local function tierBul(id: string): any
	for _, tier in LuckyBlock.Tiers do
		if tier.id == id then
			return tier
		end
	end
	return nil
end

local function yuzdeYazisi(oran: number): string
	local yuzde = oran * 100
	if yuzde >= 10 then
		return `{math.floor(yuzde + 0.5)}%`
	end
	return `{string.format("%g", math.floor(yuzde * 10 + 0.5) / 10)}%`
end

local function oranSatiri(parent: Instance, tierId: string, x: number, y: number)
	local tier = tierBul(tierId)
	if not tier then
		return
	end

	local toplam = 0
	for _, agirlik in tier.rarityWeights do
		toplam += agirlik
	end
	if toplam <= 0 then
		return
	end

	local satir = Instance.new("Frame")
	satir.Name = "Oranlar"
	satir.BackgroundColor3 = BEYAZ
	satir.BackgroundTransparency = 0.25
	satir.BorderSizePixel = 0
	satir.AutomaticSize = Enum.AutomaticSize.X
	satir.Position = UDim2.fromOffset(x, y)
	satir.Size = UDim2.fromOffset(0, 26)
	satir.ZIndex = 4
	satir.Parent = parent
	UI.corner(satir, 8)

	local kenarPay = Instance.new("UIPadding")
	kenarPay.PaddingLeft = UDim.new(0, 8)
	kenarPay.PaddingRight = UDim.new(0, 8)
	kenarPay.Parent = satir

	local dizilim = Instance.new("UIListLayout")
	dizilim.FillDirection = Enum.FillDirection.Horizontal
	dizilim.Padding = UDim.new(0, 6)
	dizilim.SortOrder = Enum.SortOrder.LayoutOrder
	dizilim.Parent = satir

	for siraNo, rarityId in Rarity.Order do
		local agirlik = tier.rarityWeights[rarityId]
		if not agirlik or agirlik <= 0 then
			continue
		end

		local cip = Instance.new("Frame")
		cip.Name = rarityId
		cip.BackgroundTransparency = 1
		cip.BorderSizePixel = 0
		cip.Size = UDim2.fromOffset(0, 26)
		cip.AutomaticSize = Enum.AutomaticSize.X
		cip.LayoutOrder = siraNo
		cip.ZIndex = 5
		cip.Parent = satir
		local ic = Instance.new("UIPadding")
		ic.PaddingLeft = UDim.new(0, 8)
		ic.PaddingRight = UDim.new(0, 8)
		ic.Parent = cip

		local yazi = UI.text({
			text = `{Rarity.displayName(rarityId)} {yuzdeYazisi(agirlik / toplam)}`,
			size = UI.Sizes.tiny,
			font = UI.Fonts.bold,
			color = Rarity.textColor(rarityId),
			frameSize = UDim2.fromOffset(0, 26),
			parent = cip,
			zIndex = 6,
		})
		yazi.AutomaticSize = Enum.AutomaticSize.X
	end
end

local function urunDugmesi(parent: Instance, urun: RobuxMagaza.Urun, enIyi: boolean?)
	local buton, yuz = satinAlmaDugmesi(parent, YESIL)

	if urun.eskiFiyat then
		indirimRozeti(buton, urun.eskiFiyat, urun.fiyat)
	end

	local rozet = urun.rozet or (if enIyi then "BEST VALUE" else nil)
	if rozet then
		etiketHapi(buton, rozet, if enIyi then EN_IYI_RENK else ROZET_RENK)
	end

	if enIyi then
		local nabiz = Instance.new("UIScale")
		nabiz.Parent = buton
		TweenService:Create(
			nabiz,
			TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Scale = 1.04 }
		):Play()
	end

	robuxYazisi(yuz, urun.fiyat, UI.Sizes.label, 4, 26)
	yuzYazisi(yuz, urun.etiket, UI.Sizes.small, 30, 16)

	if urun.eskiFiyat then
		local eski = UI.text({
			text = `<s>R$ {urun.eskiFiyat}</s>`,
			size = UI.Sizes.small,
			font = UI.Fonts.bold,
			color = KIRMIZI,
			align = Enum.TextXAlignment.Right,
			frameSize = UDim2.fromOffset(90, 20),
			position = UDim2.new(1, 4, 0, -14),
			anchor = Vector2.new(1, 0),
			parent = buton,
			zIndex = 8,
		})
		eski.RichText = true
		eski.Rotation = -8
	end

	buton.MouseButton1Click:Connect(function()
		ArayuzSesi.tikla()
		RobuxUrunAl:FireServer(urun.anahtar)
	end)

	return buton
end

local function urunKarti(kart: RobuxMagaza.Kart)
	local coklu = #kart.urunler > 1
	local oranli = kart.tier ~= nil

	local tier = if kart.tier then tierBul(kart.tier) else nil

	local huzme = if tier then HUZME_AYARI[tier.id] else nil
	local gorselX = if huzme then LUCKY_X else IKON_X
	local gorselBoyu = if huzme then LUCKY_BOYU else IKON_NORMAL
	local yaziX = gorselX + gorselBoyu + 12

	local baslikY = if huzme then 44 elseif coklu then 8 else 22
	local altBaslikY = if coklu then 40 else 56
	local oranY = if huzme then 106 else 72
	local dugmeAlt = if huzme or coklu then 28 else 10

	local yukseklik = if huzme
		then LUCKY_KART_BOYU
		elseif coklu then 72 + (if oranli then 32 else 0) + 82
		else 116

	local arkaPlanAdi = if tier then ARKA_PLAN[tier.id] else nil
	local arkaPlan = if arkaPlanAdi
		then Icons.assetKlasorden(Assets.Categories.backgrounds, arkaPlanAdi)
		else nil

	local cerceve = Instance.new("Frame")
	cerceve.Name = kart.id
	cerceve.Size = UDim2.new(1, 0, 0, yukseklik)
	cerceve.BorderSizePixel = 0
	cerceve.LayoutOrder = sonraki()
	cerceve.Parent = liste
	UI.corner(cerceve, 12)
	kenarAkisi(
		UI.stroke(cerceve, BEYAZ, 4),
		(if tier then KENAR_RENKLERI[tier.id] else nil) or varsayilanKenar(kart.renkA, kart.renkB),
		3.5
	)
	renkliZemin(cerceve, kart.renkA, kart.renkB, 12, arkaPlan == nil)

	local gorselMerkez = UDim2.fromOffset(gorselX + gorselBoyu / 2, yukseklik / 2)

	if arkaPlan then
		local kap = UI.yumusakResim(cerceve, arkaPlan, ARKA_PLAN_SAYDAM, ARKA_PLAN_YAYILMA, 1)
		UI.corner(kap, 12)
	else
		dokuKatmani(cerceve, gorselMerkez, yukseklik, YAGMUR_AYARI[kart.id])
	end

	if tier and tier.id == "Hacker" then
		UI.corner(UI.sayiYagmuru(cerceve, UI.HackerYesil, 18, 1, 1.8, 0.32), 12)
	end

	kartCanlandir(cerceve)
	local efektRengi = if tier then (if huzme then huzme.renk else nil) or tier.color else nil

	if huzme and tier and efektRengi then
		UI.isikHuzmeleri(cerceve, efektRengi, huzme).Position = gorselMerkez
		UI.parlama(cerceve, efektRengi, gorselBoyu, 4).Position = gorselMerkez
	end

	local onizleme = if tier then luckyOnizleme(cerceve, tier, gorselX, gorselBoyu) else nil
	if not onizleme then
		local ikon = kartIkonu(cerceve, kart.ikon, gorselBoyu, if tier then tier.color else nil)
		ikon.Position = UDim2.new(0, gorselX, 0.5, 0)
		UI.sallan(ikon)
	end

	if onizleme and tier then
		local pariltiAlani = Instance.new("Frame")
		pariltiAlani.Name = "PariltiAlani"
		pariltiAlani.Size = UDim2.fromScale(1, 1)
		pariltiAlani.BackgroundTransparency = 1
		pariltiAlani.ClipsDescendants = true
		pariltiAlani.ZIndex = 1
		pariltiAlani.Parent = cerceve
		UI.corner(pariltiAlani, 12)

		UI.pariltilar(
			pariltiAlani,
			efektRengi or tier.color,
			PARILTI_SAYISI[tier.id] or PARILTI_VARSAYILAN,
			1,
			tier.id == "Hacker"
		)
	end

	local yaziEni = if coklu
		then UDim2.new(1, -(yaziX + 12), 0, 32)
		else UDim2.new(1, -(yaziX + 198), 0, 32)

	local baslikGorunum = if tier then BASLIK_GORUNUM[tier.id] else nil
	local baslikBoyu = UI.Sizes.heading + 2 + (if baslikGorunum then baslikGorunum.boyutEk else 0)

	UI.text({
		text = string.upper(kart.baslik),
		size = baslikBoyu,
		font = UI.Fonts.bold,
		glow = if baslikGorunum then baslikGorunum.renk else ALTIN,
		frameSize = UDim2.new(yaziEni.X.Scale, yaziEni.X.Offset, 0, baslikBoyu + 12),
		position = UDim2.fromOffset(yaziX, baslikY),
		parent = cerceve,
		zIndex = 5,
	})

	if not huzme then
		UI.text({
			text = kart.altBaslik,
			size = UI.Sizes.small,
			font = UI.Fonts.bold,
			frameSize = UDim2.new(yaziEni.X.Scale, yaziEni.X.Offset, 0, 22),
			position = UDim2.fromOffset(yaziX, altBaslikY),
			parent = cerceve,
			zIndex = 5,
		})
	end

	if kart.serit then
		serit(cerceve, kart.serit)
	end

	local enIyi: RobuxMagaza.Urun? = nil
	if coklu then
		local enAz = math.huge
		for _, urun in kart.urunler do
			local miktar = urun.adet or urun.rotCoin
			if miktar and miktar > 0 and urun.fiyat / miktar < enAz then
				enAz = urun.fiyat / miktar
				enIyi = urun
			end
		end
	end

	if not coklu then
		local buton = urunDugmesi(cerceve, kart.urunler[1])
		buton.AnchorPoint = Vector2.new(1, 0.5)
		buton.Position = UDim2.new(1, -14, 0.5, 0)
		buton.Size = UDim2.fromOffset(170, 58)
		return
	end

	if oranli and kart.tier then
		oranSatiri(cerceve, kart.tier, yaziX, oranY)
	end

	local dugmeler = Instance.new("Frame")
	dugmeler.Name = "Dugmeler"
	dugmeler.BackgroundTransparency = 1
	dugmeler.AnchorPoint = Vector2.new(0, 1)
	dugmeler.Position = UDim2.new(0, yaziX, 1, -dugmeAlt)
	dugmeler.Size = UDim2.new(1, -(yaziX + 12), 0, 56)
	dugmeler.Parent = cerceve

	local dizilim = Instance.new("UIListLayout")
	dizilim.FillDirection = Enum.FillDirection.Horizontal
	dizilim.Padding = UDim.new(0, 10)
	dizilim.SortOrder = Enum.SortOrder.LayoutOrder
	dizilim.Parent = dugmeler

	local adet = #kart.urunler
	for siraNo, urun in kart.urunler do
		local buton = urunDugmesi(dugmeler, urun, urun == enIyi)
		buton.LayoutOrder = siraNo
		buton.Size = UDim2.new(1 / adet, -10 * (adet - 1) / adet, 1, 0)
	end
end

local gecisCizimleri: { () -> () } = {}

local function gecisKarti(parent: Instance, ad: string, siraNo: number)
	local info = Passler.get(ad)
	if not info then
		return
	end
	local gorunum = GECIS_GORUNUM[ad] or GECIS_GORUNUM.Teleporter

	local kart = Instance.new("Frame")
	kart.Name = ad
	kart.BorderSizePixel = 0
	kart.LayoutOrder = siraNo
	kart.Parent = parent
	UI.corner(kart, 12)
	kenarAkisi(UI.stroke(kart, BEYAZ, 4), varsayilanKenar(gorunum.renkA, gorunum.renkB), 3.5)
	renkliZemin(kart, gorunum.renkA, gorunum.renkB, 12, true)
	dokuKatmani(kart, UDim2.fromOffset(38, 38), 150)
	kartCanlandir(kart)

	local ikon = kartIkonu(kart, gorunum.ikon, 56)
	ikon.AnchorPoint = Vector2.zero
	ikon.Position = UDim2.fromOffset(10, 10)

	UI.text({
		text = string.upper(info.ad),
		size = UI.Sizes.label,
		font = UI.Fonts.bold,
		glow = ALTIN,
		frameSize = UDim2.new(1, -80, 0, 26),
		position = UDim2.fromOffset(72, 10),
		parent = kart,
		zIndex = 5,
	})

	UI.text({
		text = info.aciklama,
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		frameSize = UDim2.new(1, -80, 0, 40),
		position = UDim2.fromOffset(72, 36),
		alignY = Enum.TextYAlignment.Top,
		wrapped = true,
		parent = kart,
		zIndex = 5,
	})

	local buton, yuz = satinAlmaDugmesi(kart, YESIL)
	buton.AnchorPoint = Vector2.new(0.5, 1)
	buton.Position = UDim2.new(0.5, 0, 1, -10)
	buton.Size = UDim2.new(1, -20, 0, 50)

	local fiyatKutusu = robuxYazisi(yuz, info.fiyat, UI.Sizes.label, 0, 36)
	fiyatKutusu.AnchorPoint = Vector2.new(0.5, 0.5)
	fiyatKutusu.Position = UDim2.fromScale(0.5, 0.5)

	local yazi = yuzYazisi(yuz, "OWNED", UI.Sizes.label, 0, 36)
	yazi.Size = UDim2.new(1, -4, 1, 0)
	yazi.Visible = false

	local function ciz()
		local sahip = Passler.sahip(player, ad)
		yazi.Visible = sahip
		fiyatKutusu.Visible = not sahip
		buton.Active = not sahip
		buton.AutoButtonColor = false
		buton.BackgroundColor3 = if sahip then Color3.fromRGB(80, 82, 88) else UI.shade(YESIL, -0.3)
		yuz.BackgroundColor3 = if sahip then Color3.fromRGB(140, 145, 155) else YESIL
		local gecis = yuz:FindFirstChildOfClass("UIGradient")
		if gecis then
			gecis.Enabled = not sahip
		end
		local tarama = yuz:FindFirstChild("Tarama")
		if tarama and tarama:IsA("GuiObject") then
			tarama.Visible = not sahip
		end
	end
	ciz()
	table.insert(gecisCizimleri, ciz)

	player:GetAttributeChangedSignal(info.nitelik):Connect(ciz)

	buton.MouseButton1Click:Connect(function()
		if Passler.sahip(player, ad) then
			return
		end
		ArayuzSesi.tikla()
		PassSatinAl:FireServer(ad)
	end)
end

local function baslangicKarti()
	local urun = RobuxMagaza.BaslangicPaketi
	local normal = tierBul(LuckyBlock.Default)
	local altin = tierBul("Golden")
	local yukseklik = 260

	local cerceve = Instance.new("Frame")
	cerceve.Name = "BaslangicPaketi"
	cerceve.Size = UDim2.new(1, 0, 0, yukseklik)
	cerceve.BorderSizePixel = 0
	cerceve.LayoutOrder = sonraki()
	cerceve.Parent = liste
	UI.corner(cerceve, 12)
	kenarAkisi(UI.stroke(cerceve, BEYAZ, 4), KENAR_RENKLERI.Baslangic, 3)
	renkliZemin(cerceve, Color3.fromRGB(255, 196, 40), Color3.fromRGB(255, 96, 40), 12)
	kartCanlandir(cerceve)

	local arkaPlan = Icons.assetKlasorden(Assets.Categories.backgrounds, "starterbackground")
	if arkaPlan then
		local resimKabi = UI.yumusakResim(cerceve, arkaPlan, ARKA_PLAN_SAYDAM, ARKA_PLAN_YAYILMA, 1)
		UI.corner(resimKabi, 12)
	else
		dokuKatmani(cerceve, UDim2.fromOffset(165, yukseklik / 2), yukseklik)
	end

	local pariltiAlani = Instance.new("Frame")
	pariltiAlani.Name = "PariltiAlani"
	pariltiAlani.Size = UDim2.fromScale(1, 1)
	pariltiAlani.BackgroundTransparency = 1
	pariltiAlani.ClipsDescendants = true
	pariltiAlani.Parent = cerceve
	UI.corner(pariltiAlani, 12)
	UI.pariltilar(pariltiAlani, Color3.fromRGB(255, 245, 200), 22, 1)

	local merkez = UDim2.fromOffset(165, yukseklik / 2)
	UI.isikHuzmeleri(cerceve, Color3.fromRGB(255, 240, 170), {
		sayi = 12,
		uzunluk = 230,
		kalinlik = 30,
		tur = 14,
		parlaklik = 0.2,
		zIndex = 2,
	}).Position = merkez
	UI.parlama(cerceve, Color3.fromRGB(255, 220, 90), 240, 3).Position = merkez

	local function blok(tier: any, x: number, y: number, boyut: number, z: number, gecikme: number): ViewportFrame?
		local vp = luckyOnizleme(cerceve, tier, x, boyut)
		if not vp then
			return nil
		end
		vp.Position = UDim2.new(0, x, 0.5, y)
		vp.ZIndex = z
		task.delay(gecikme, function()
			if vp.Parent then
				TweenService:Create(
					vp,
					TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{ Position = UDim2.new(0, x, 0.5, y - 8) }
				):Play()
			end
		end)
		return vp
	end

	if normal then
		blok(normal, 18, -50, 110, 5, 0)
		blok(normal, 112, -66, 110, 5, 0.3)
		blok(normal, 206, -50, 110, 5, 0.6)
	end
	if altin then
		blok(altin, 92, 34, 150, 7, 0.15)
	end

	local function rozet(yazi: string, x: number, y: number, renk: Color3)
		local etiket = UI.text({
			text = yazi,
			size = 34,
			font = UI.Fonts.bold,
			color = renk,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.fromOffset(70, 40),
			position = UDim2.new(0, x, 0.5, y),
			parent = cerceve,
			zIndex = 9,
		})
		etiket.Rotation = -10
		UI.stroke(etiket, SIYAH, 3)
		local olcek = Instance.new("UIScale")
		olcek.Parent = etiket
		TweenService:Create(
			olcek,
			TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Scale = 1.15 }
		):Play()
	end

	rozet(`x{(urun.luckyBlocks or {}).Normal or 0}`, 262, -112, BEYAZ)
	rozet(`x{(urun.luckyBlocks or {}).Golden or 0}`, 220, 40, Color3.fromRGB(255, 215, 60))

	local yaziX = 340
	UI.text({
		text = "STARTER PACK",
		size = UI.Sizes.title + 4,
		font = UI.Fonts.bold,
		glow = ALTIN,
		frameSize = UDim2.new(1, -(yaziX + 12), 0, 42),
		position = UDim2.fromOffset(yaziX, 16),
		parent = cerceve,
		zIndex = 6,
	})

	for siraNo, satir in RobuxMagaza.paketIcerigi(urun) do
		local tier = if satir.tier then tierBul(satir.tier) else nil
		UI.text({
			text = `+ {satir.yazi}`,
			size = UI.Sizes.label,
			font = UI.Fonts.bold,
			color = if tier and tier.id ~= LuckyBlock.Default then tier.color else BEYAZ,
			frameSize = UDim2.new(1, -(yaziX + 12), 0, 26),
			position = UDim2.fromOffset(yaziX, 62 + (siraNo - 1) * 28),
			parent = cerceve,
			zIndex = 6,
		})
	end

	serit(cerceve, "WOW!")

	local buton = urunDugmesi(cerceve, urun)
	buton.AnchorPoint = Vector2.new(1, 1)
	buton.Position = UDim2.new(1, -16, 1, -16)
	buton.Size = UDim2.fromOffset(200, 64)
	local butonOlcek = Instance.new("UIScale")
	butonOlcek.Parent = buton
	TweenService:Create(
		butonOlcek,
		TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Scale = 1.06 }
	):Play()

	local function ciz()
		cerceve.Visible = player:GetAttribute(RobuxMagaza.BaslangicNiteligi) ~= true
	end
	ciz()
	player:GetAttributeChangedSignal(RobuxMagaza.BaslangicNiteligi):Connect(ciz)
end

do
	local ok, hata = pcall(baslangicKarti)
	if not ok then
		warn(`[RobuxMagaza] starter pack card could not be drawn: {hata}`)
	end
end

bolumBasligi("Items")
for _, kart in RobuxMagaza.Kartlar do
	local ok, hata = pcall(urunKarti, kart)
	if not ok then
		warn(`[RobuxMagaza] card "{kart.id}" could not be drawn: {hata}`)
	end
end

bolumBasligi("Game Passes")
do
	local izgaraKutu = Instance.new("Frame")
	izgaraKutu.Name = "Gecisler"
	izgaraKutu.BackgroundTransparency = 1
	izgaraKutu.Size = UDim2.new(1, 0, 0, 0)
	izgaraKutu.AutomaticSize = Enum.AutomaticSize.Y
	izgaraKutu.LayoutOrder = sonraki()
	izgaraKutu.Parent = liste

	local izgara = Instance.new("UIGridLayout")
	izgara.CellSize = UDim2.new(0.5, -8, 0, 150)
	izgara.CellPadding = UDim2.fromOffset(16, 16)
	izgara.SortOrder = Enum.SortOrder.LayoutOrder
	izgara.Parent = izgaraKutu

	for siraNo, ad in RobuxMagaza.Gecisler do
		gecisKarti(izgaraKutu, ad, siraNo)
	end
end

local MENU_IKON = 52
local MENU_BOSLUK = 14

local tutucu = Instance.new("Frame")
tutucu.Name = "StoreButonu"
tutucu.AnchorPoint = Vector2.new(0, 1)
tutucu.Position = UDim2.new(0, 16, 0.5, 0)
tutucu.Size = UDim2.fromOffset(MENU_IKON * 2 + MENU_BOSLUK, MENU_IKON + LIP)
tutucu.BackgroundTransparency = 1
tutucu.Parent = screen

local storeGovde = Instance.new("Frame")
storeGovde.Name = "Govde"
storeGovde.AnchorPoint = Vector2.new(0.5, 0.5)
storeGovde.Position = UDim2.fromScale(0.5, 0.5)
storeGovde.Size = UDim2.fromScale(1, 1)
storeGovde.BackgroundTransparency = 1
storeGovde.Parent = tutucu
do
	local gosterOlcek = Instance.new("UIScale")
	gosterOlcek.Name = "GosterOlcek"
	gosterOlcek.Parent = storeGovde
end

local storeButon, storeYuz = satinAlmaDugmesi(storeGovde, ALTIN, true)
storeButon.Name = "Store"
storeButon.AnchorPoint = Vector2.new(0.5, 0.5)
storeButon.Position = UDim2.fromScale(0.5, 0.5)
storeButon.Size = UDim2.fromScale(1, 1)

UI.isikHuzmeleri(tutucu, ALTIN, {
	sayi = 8,
	uzunluk = 120,
	kalinlik = 20,
	tur = 9,
	parlaklik = 0.45,
	zIndex = 0,
})

do
	local nokta = UI.bildirimNoktasi(storeButon, 8)
	local function guncelle()
		nokta(player:GetAttribute(RobuxMagaza.BaslangicNiteligi) ~= true)
	end
	guncelle()
	player:GetAttributeChangedSignal(RobuxMagaza.BaslangicNiteligi):Connect(guncelle)
end

local storeIkon = Instance.new("ImageLabel")
storeIkon.Name = "Ikon"
storeIkon.BackgroundTransparency = 1
storeIkon.AnchorPoint = Vector2.new(0, 0.5)
storeIkon.Position = UDim2.new(0, 2, 0.5, 0)
storeIkon.Size = UDim2.fromOffset(40, 40)
storeIkon.ScaleType = Enum.ScaleType.Fit
storeIkon.ZIndex = 5
storeIkon.Parent = storeYuz
local storeYazi = UI.text({
	text = "STORE",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = storeYuz,
	zIndex = 5,
})

storeIkon.Visible = false
Icons.bind(storeIkon, "store", function(ok)
	if ok then
		storeIkon.Visible = true
		storeYazi.Size = UDim2.new(1, -42, 1, 0)
		storeYazi.Position = UDim2.fromOffset(40, 0)
	end
end)

task.spawn(function()
	local menuler = playerGui:WaitForChild("OyunMenuleri")
	local sol = menuler:WaitForChild("SolMenu") :: GuiObject
	local sag = menuler:WaitForChild("SagMenu") :: GuiObject

	local function yerlestir()
		if UI.Girdi.dokunmatik() then
			tutucu.AnchorPoint = Vector2.new(1, 0)
			tutucu.Position = UDim2.fromOffset(
				sag.AbsolutePosition.X + sag.AbsoluteSize.X,
				sag.AbsolutePosition.Y + sag.AbsoluteSize.Y + 8 * UI.carpan()
			)
			return
		end
		tutucu.AnchorPoint = Vector2.new(0, 1)
		tutucu.Position = UDim2.fromOffset(
			sol.AbsolutePosition.X,
			sol.AbsolutePosition.Y - MENU_BOSLUK * UI.carpan()
		)
	end

	yerlestir()
	sol:GetPropertyChangedSignal("AbsolutePosition"):Connect(yerlestir)
	sol:GetPropertyChangedSignal("AbsoluteSize"):Connect(yerlestir)
	sag:GetPropertyChangedSignal("AbsolutePosition"):Connect(yerlestir)
	sag:GetPropertyChangedSignal("AbsoluteSize"):Connect(yerlestir)
	UI.onScaleChanged(yerlestir)
	UI.Girdi.degisince(yerlestir)
end)

storeButon.MouseButton1Click:Connect(function()
	ArayuzSesi.tikla()
	panel.Visible = not panel.Visible
end)

task.spawn(function()
	local bilgi = TweenInfo.new(0.09, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	while storeIkon.Parent do
		task.wait(4)
		for _, aci in { -14, 12, -8, 5, 0 } do
			local t = TweenService:Create(storeIkon, bilgi, { Rotation = aci })
			t:Play()
			t.Completed:Wait()
		end
	end
end)

panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then
		for _, ciz in gecisCizimleri do
			ciz()
		end

		local adim = 0
		for _, kart in kartlar do
			local olcek = kart:FindFirstChild("KartOlcek")
			if kart.Visible and olcek and olcek:IsA("UIScale") then
				olcek.Scale = 0.85
				TweenService:Create(
					olcek,
					TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, adim * 0.05),
					{ Scale = 1 }
				):Play()
				adim += 1
			end
		end
	end
end)
