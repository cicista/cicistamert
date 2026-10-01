--!strict

local ContentProvider = game:GetService("ContentProvider")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local ARKA_PLAN_KLASORU = { "Assets", "Backgrounds" }
local ARKA_PLAN_ADI = "LoadingScreen"

local OYUN_ADI = "CICISTAMERT"

local EN_COK_BEKLEME = 45
local ATLA_GECIKMESI = 1.5
local IPUCU_SURESI = 5
local OBEK = 20

local AFK_DONUS_ANAHTARI = "AfkDonus"

local BASLA_EYLEMI = "YuklemeBasla"
local ATLA_EYLEMI = "YuklemeAtla"

local TASARIM = Vector2.new(1280, 760)
local EN_KUCUK_OLCEK = 0.5
local EN_BUYUK_OLCEK = 1.15

local KART_EN = 760
local KART_BOY = 276
local KENAR = 28

local YAKLASMA = 1.07
local PARALAKS = 14

local NEON = Color3.fromRGB(70, 190, 255)
local NEON_ACIK = Color3.fromRGB(150, 225, 255)
local MOR = Color3.fromRGB(150, 95, 255)
local ALTIN = Color3.fromRGB(255, 205, 70)
local BEYAZ = Color3.fromRGB(255, 255, 255)
local SIYAH = Color3.fromRGB(0, 0, 0)
local SOLGUN = Color3.fromRGB(176, 190, 210)
local SONUK = Color3.fromRGB(92, 104, 128)
local KOYU = Color3.fromRGB(8, 11, 20)
local LACIVERT = Color3.fromRGB(12, 22, 40)

local AKTIF_RENK = ColorSequence.new(Color3.fromRGB(120, 235, 255), Color3.fromRGB(30, 140, 255))
local PASIF_RENK = ColorSequence.new(Color3.fromRGB(64, 74, 98), Color3.fromRGB(40, 48, 66))

local ISIN_RENKLERI = {
	Color3.fromRGB(80, 160, 255),
	Color3.fromRGB(180, 100, 255),
	Color3.fromRGB(255, 240, 150),
	Color3.fromRGB(255, 70, 90),
	Color3.fromRGB(255, 190, 60),
	Color3.fromRGB(150, 70, 240),
}

local KIVILCIM_RENKLERI = { NEON, NEON_ACIK, ALTIN, MOR, BEYAZ }

local ADIMLAR = {
	{ ad = "CONNECT", esik = 0.12 },
	{ ad = "ASSETS", esik = 0.8 },
	{ ad = "WORLD", esik = 0.88 },
	{ ad = "PROFILE", esik = 0.995 },
}

local IPUCLARI = {
	"Upgrade your shovel to dig up rarer pets.",
	"The Detective reveals the pets you dig up.",
	"Place pets on your base to earn Rot every second.",
	"Gold, Diamond, Galaxy and Hacker mutations multiply a pet's income.",
	"New islands boost your luck: Candy x2, Snow x4, Volcano x8.",
	"A Lucky Block rain starts every hour. Don't miss it!",
	"Weekends bring 2x luck. Plan your digging!",
	"Fuse pets in the Fuse Machine to reach a higher rarity.",
	"Reach level 15 to trade pets with other players.",
	"Your base earns a little Rot even while you are offline.",
	"Stand in Clover Fields to collect Luck Points while AFK.",
	"Fill your Index by discovering every pet and mutation.",
}

local BASLIK_FONTU = Font.fromEnum(Enum.Font.FredokaOne)
local GOVDE_FONTU = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
local KALIN_FONT = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)

local kapandi = false
local hazirlandi = false
local hazirGorundu = false
local atlaIstendi = false
local oynaAktif = false

local afkDonusu = false
do
	local ok, veri = pcall(function()
		return TeleportService:GetLocalPlayerTeleportData()
	end)
	afkDonusu = ok and type(veri) == "table" and veri[AFK_DONUS_ANAHTARI] ~= nil
end

local enAzGorunme = if afkDonusu then 0.5 else 5

local KAPATILAN_COREGUI = {
	Enum.CoreGuiType.Chat,
	Enum.CoreGuiType.PlayerList,
	Enum.CoreGuiType.Backpack,
	Enum.CoreGuiType.EmotesMenu,
}

local function coreGuiAyarla(acik: boolean)
	for _, tur in KAPATILAN_COREGUI do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(tur, acik)
		end)
	end
end

local coreGuiSuruyor = true

task.spawn(function()
	while coreGuiSuruyor do
		coreGuiAyarla(false)
		pcall(function()
			StarterGui:SetCore("TopbarEnabled", false)
		end)
		task.wait(0.25)
	end
end)

local function coreGuiGeriAc()
	coreGuiSuruyor = false

	for _, tur in KAPATILAN_COREGUI do
		if tur ~= Enum.CoreGuiType.Backpack then
			pcall(function()
				StarterGui:SetCoreGuiEnabled(tur, true)
			end)
		end
	end

	pcall(function()
		StarterGui:SetCore("TopbarEnabled", true)
	end)
end

local function kose(nesne: Instance, yaricap: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, yaricap)
	c.Parent = nesne
end

local function yuvarlak(nesne: Instance)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = nesne
end

local function kontur(nesne: Instance, renk: Color3, kalinlik: number, saydamlik: number?, kutu: boolean?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = renk
	s.Thickness = kalinlik
	s.Transparency = saydamlik or 0
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.ApplyStrokeMode = if kutu then Enum.ApplyStrokeMode.Border else Enum.ApplyStrokeMode.Contextual
	s.Parent = nesne
	return s
end

local function seri(noktalar: { { number } }): NumberSequence
	local liste = {}
	for _, n in noktalar do
		table.insert(liste, NumberSequenceKeypoint.new(n[1], n[2]))
	end
	return NumberSequence.new(liste)
end

local function gecis(ebeveyn: Instance, renkler: ColorSequence?, saydamliklar: NumberSequence?, aci: number?): UIGradient
	local g = Instance.new("UIGradient")
	if renkler then
		g.Color = renkler
	end
	if saydamliklar then
		g.Transparency = saydamliklar
	end
	g.Rotation = aci or 0
	g.Parent = ebeveyn
	return g
end

type CerceveAyari = {
	ad: string,
	ebeveyn: Instance,
	boyut: UDim2?,
	konum: UDim2?,
	capa: Vector2?,
	renk: Color3?,
	saydamlik: number?,
	z: number?,
}

local function cerceve(a: CerceveAyari): Frame
	local f = Instance.new("Frame")
	f.Name = a.ad
	f.Size = a.boyut or UDim2.fromScale(1, 1)
	f.Position = a.konum or UDim2.new()
	f.AnchorPoint = a.capa or Vector2.zero
	f.BackgroundColor3 = a.renk or BEYAZ
	f.BackgroundTransparency = a.saydamlik or 1
	f.BorderSizePixel = 0
	f.ZIndex = a.z or 1
	f.Parent = a.ebeveyn
	return f
end

type YaziAyari = {
	ad: string,
	ebeveyn: Instance,
	metin: string?,
	boyut: number?,
	font: Font?,
	renk: Color3?,
	hiza: Enum.TextXAlignment?,
	cerceve: UDim2?,
	konum: UDim2?,
	capa: Vector2?,
	z: number?,
	kontur: number?,
}

local function yazi(a: YaziAyari): TextLabel
	local etiket = Instance.new("TextLabel")
	etiket.Name = a.ad
	etiket.BackgroundTransparency = 1
	etiket.Size = a.cerceve or UDim2.fromScale(1, 1)
	etiket.Position = a.konum or UDim2.new()
	etiket.AnchorPoint = a.capa or Vector2.zero
	etiket.FontFace = a.font or GOVDE_FONTU
	etiket.Text = a.metin or ""
	etiket.TextColor3 = a.renk or BEYAZ
	etiket.TextSize = a.boyut or 18
	etiket.TextXAlignment = a.hiza or Enum.TextXAlignment.Center
	etiket.ZIndex = a.z or 5
	if a.kontur then
		kontur(etiket, SIYAH, a.kontur)
	end
	etiket.Parent = a.ebeveyn
	return etiket
end

local OZELLIKLER = {
	{ "GuiObject", "BackgroundTransparency" },
	{ "TextLabel", "TextTransparency" },
	{ "TextButton", "TextTransparency" },
	{ "ImageLabel", "ImageTransparency" },
	{ "UIStroke", "Transparency" },
}

local tabanlar: { [Instance]: { [string]: number } } = setmetatable({}, { __mode = "k" }) :: any

local function taban(nesne: Instance, ozellik: string): number
	local kayit = tabanlar[nesne]
	if not kayit then
		kayit = {}
		tabanlar[nesne] = kayit
	end
	local deger = kayit[ozellik]
	if deger == nil then
		deger = (nesne :: any)[ozellik]
		kayit[ozellik] = deger
	end
	return deger :: number
end

local function solukluk(kok: Instance, oran: number, sure: number): Tween?
	local bilgi = TweenInfo.new(sure, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local son: Tween? = nil

	local liste = kok:GetDescendants()
	table.insert(liste, kok)

	for _, nesne in liste do
		local hedef: { [string]: number } = {}
		local var = false
		for _, o in OZELLIKLER do
			if nesne:IsA(o[1]) then
				local b = taban(nesne, o[2])
				hedef[o[2]] = b + (1 - b) * oran
				var = true
			end
		end
		if var then
			local tween = TweenService:Create(nesne, bilgi, hedef)
			tween:Play()
			son = tween
		end
	end

	return son
end

local ekran = Instance.new("ScreenGui")
ekran.Name = "YuklemeEkrani"
ekran.DisplayOrder = 1000
ekran.IgnoreGuiInset = true
pcall(function()
	(ekran :: any).ScreenInsets = Enum.ScreenInsets.None
end)
ekran.ResetOnSpawn = false
ekran.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ekran:SetAttribute("OlcekDisi", true)
ekran.Parent = playerGui

local perde = Instance.new("Frame")
perde.Name = "Perde"
perde.ChildAdded:Connect(function(cocuk)
	if cocuk:IsA("UIScale") then
		task.defer(function()
			cocuk:Destroy()
		end)
	end
end)
perde.Size = UDim2.fromScale(1, 1)
perde.BackgroundColor3 = KOYU
perde.BorderSizePixel = 0
perde.ZIndex = 1
perde.Parent = ekran

local gokyuzu = cerceve({ ad = "Gokyuzu", ebeveyn = perde, saydamlik = 0, z = 1 })
gecis(
	gokyuzu,
	ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(96, 74, 120)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(48, 44, 78)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 14, 26)),
	}),
	nil,
	90
)

local resimKabi = cerceve({
	ad = "ResimKabi",
	ebeveyn = perde,
	boyut = UDim2.new(1, PARALAKS * 3, 1, PARALAKS * 3),
	konum = UDim2.fromScale(0.5, 0.5),
	capa = Vector2.new(0.5, 0.5),
	z = 2,
})

local resimYaklasma = cerceve({
	ad = "Yaklasma",
	ebeveyn = resimKabi,
	konum = UDim2.fromScale(0.5, 0.5),
	capa = Vector2.new(0.5, 0.5),
	z = 1,
})

local resim = Instance.new("ImageLabel")
resim.Name = "Resim"
resim.Size = UDim2.fromScale(1, 1)
resim.BackgroundTransparency = 1
resim.ScaleType = Enum.ScaleType.Crop
resim.ImageTransparency = 1
resim.ZIndex = 1
resim.Parent = resimYaklasma

task.spawn(function()
	local node: Instance? = ReplicatedStorage
	for _, ad in ARKA_PLAN_KLASORU do
		node = if node then node:WaitForChild(ad, 10) else nil
	end

	local hedef = if node then node:WaitForChild(ARKA_PLAN_ADI, 10) else nil
	if not hedef then
		return
	end

	local kimlik: string? = nil
	if hedef:IsA("Decal") or hedef:IsA("Texture") then
		kimlik = hedef.Texture
	elseif hedef:IsA("ImageLabel") or hedef:IsA("ImageButton") then
		kimlik = hedef.Image
	elseif hedef:IsA("StringValue") then
		kimlik = hedef.Value
	end

	if not kimlik or kimlik == "" then
		return
	end

	resim.Image = kimlik
	pcall(function()
		ContentProvider:PreloadAsync({ resim })
	end)

	if kapandi then
		return
	end

	TweenService:Create(resim, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 0 })
		:Play()
	TweenService
		:Create(
			resimYaklasma,
			TweenInfo.new(20, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Size = UDim2.fromScale(YAKLASMA, YAKLASMA) }
		)
		:Play()
end)

cerceve({ ad = "Ton", ebeveyn = perde, renk = KOYU, saydamlik = 0.8, z = 3 })

local isinKabi = cerceve({ ad = "Isinlar", ebeveyn = perde, z = 4 })

local altPerde = cerceve({
	ad = "AltPerde",
	ebeveyn = perde,
	boyut = UDim2.fromScale(1, 0.66),
	konum = UDim2.fromScale(0, 1),
	capa = Vector2.new(0, 1),
	renk = KOYU,
	saydamlik = 0,
	z = 5,
})
gecis(altPerde, nil, seri({ { 0, 1 }, { 0.45, 0.5 }, { 1, 0.04 } }), 90)

local ustPerde = cerceve({
	ad = "UstPerde",
	ebeveyn = perde,
	boyut = UDim2.fromScale(1, 0.22),
	renk = KOYU,
	saydamlik = 0,
	z = 5,
})
gecis(ustPerde, nil, seri({ { 0, 0.4 }, { 1, 1 } }), 90)

local solPerde = cerceve({ ad = "SolPerde", ebeveyn = perde, boyut = UDim2.fromScale(0.2, 1), renk = KOYU, saydamlik = 0, z = 5 })
gecis(solPerde, nil, seri({ { 0, 0.35 }, { 1, 1 } }), 0)

local sagPerde = cerceve({
	ad = "SagPerde",
	ebeveyn = perde,
	boyut = UDim2.fromScale(0.2, 1),
	konum = UDim2.fromScale(1, 0),
	capa = Vector2.new(1, 0),
	renk = KOYU,
	saydamlik = 0,
	z = 5,
})
gecis(sagPerde, nil, seri({ { 0, 1 }, { 1, 0.35 } }), 0)

local kivilcimKabi = cerceve({ ad = "Kivilcimlar", ebeveyn = perde, z = 6 })

local icerik = cerceve({
	ad = "Icerik",
	ebeveyn = perde,
	boyut = UDim2.fromOffset(KART_EN, KART_BOY),
	konum = UDim2.new(0.5, 0, 1, -KENAR),
	capa = Vector2.new(0.5, 1),
	z = 10,
})
local icerikOlcek = Instance.new("UIScale")
icerikOlcek.Parent = icerik

local kayan = cerceve({ ad = "Kayan", ebeveyn = icerik, z = 1 })

local kart = cerceve({ ad = "Kart", ebeveyn = kayan, saydamlik = 0.28, z = 1 })
kose(kart, 22)
gecis(kart, ColorSequence.new(Color3.fromRGB(28, 36, 60), Color3.fromRGB(8, 11, 20)), nil, 90)

local kartKontur = kontur(kart, BEYAZ, 1.6, 0.1, true)
local konturGecis = gecis(
	kartKontur,
	ColorSequence.new({
		ColorSequenceKeypoint.new(0, NEON),
		ColorSequenceKeypoint.new(0.5, MOR),
		ColorSequenceKeypoint.new(1, NEON),
	}),
	seri({ { 0, 0.05 }, { 0.5, 0.75 }, { 1, 0.05 } }),
	0
)

local ustCizgi = cerceve({
	ad = "UstCizgi",
	ebeveyn = kart,
	boyut = UDim2.new(1, -80, 0, 1),
	konum = UDim2.new(0.5, 0, 0, 1),
	capa = Vector2.new(0.5, 0),
	saydamlik = 0.35,
	z = 2,
})
gecis(ustCizgi, nil, seri({ { 0, 1 }, { 0.5, 0.2 }, { 1, 1 } }), 0)

local ic = cerceve({
	ad = "Ic",
	ebeveyn = kayan,
	boyut = UDim2.new(1, -56, 0, KART_BOY - 38),
	konum = UDim2.fromOffset(28, 22),
	z = 2,
})

local baslik = yazi({
	ad = "Baslik",
	ebeveyn = ic,
	metin = "LOADING",
	font = BASLIK_FONTU,
	boyut = 32,
	hiza = Enum.TextXAlignment.Left,
	cerceve = UDim2.new(0.6, 0, 0, 38),
	kontur = 2.5,
	z = 2,
})

local yuzdeYazi = yazi({
	ad = "Yuzde",
	ebeveyn = ic,
	metin = "0%",
	font = BASLIK_FONTU,
	boyut = 34,
	renk = NEON_ACIK,
	hiza = Enum.TextXAlignment.Right,
	cerceve = UDim2.new(0.4, 0, 0, 38),
	konum = UDim2.fromScale(1, 0),
	capa = Vector2.new(1, 0),
	kontur = 2.5,
	z = 2,
})

local durumYazi = yazi({
	ad = "Durum",
	ebeveyn = ic,
	metin = "Reaching the server",
	font = GOVDE_FONTU,
	boyut = 18,
	renk = SOLGUN,
	hiza = Enum.TextXAlignment.Left,
	cerceve = UDim2.new(1, 0, 0, 22),
	konum = UDim2.fromOffset(0, 44),
	z = 2,
})

local cubuk = cerceve({
	ad = "Cubuk",
	ebeveyn = ic,
	boyut = UDim2.new(1, 0, 0, 16),
	konum = UDim2.fromOffset(0, 78),
	renk = Color3.fromRGB(22, 28, 44),
	saydamlik = 0.1,
	z = 2,
})
yuvarlak(cubuk)
kontur(cubuk, Color3.fromRGB(70, 88, 120), 1, 0.35, true)

local dolgu = cerceve({ ad = "Dolgu", ebeveyn = cubuk, boyut = UDim2.fromScale(0, 1), saydamlik = 0, z = 1 })
yuvarlak(dolgu)
gecis(
	dolgu,
	ColorSequence.new({
		ColorSequenceKeypoint.new(0, NEON),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(110, 140, 255)),
		ColorSequenceKeypoint.new(1, MOR),
	}),
	nil,
	0
)

local dolguParlak = cerceve({ ad = "Parlak", ebeveyn = dolgu, boyut = UDim2.fromScale(1, 0.5), saydamlik = 0.72, z = 2 })
yuvarlak(dolguParlak)

local parilti = cerceve({ ad = "Parilti", ebeveyn = dolgu, saydamlik = 0, z = 3 })
yuvarlak(parilti)
local parlamaGecis = gecis(parilti, nil, seri({ { 0, 1 }, { 0.4, 1 }, { 0.5, 0.5 }, { 0.6, 1 }, { 1, 1 } }), 0)

local uc = cerceve({
	ad = "Uc",
	ebeveyn = cubuk,
	boyut = UDim2.fromOffset(30, 30),
	konum = UDim2.fromScale(0, 0.5),
	capa = Vector2.new(0.5, 0.5),
	renk = NEON_ACIK,
	saydamlik = 0.65,
	z = 4,
})
yuvarlak(uc)
uc.Visible = false
local ucOlcek = Instance.new("UIScale")
ucOlcek.Parent = uc

local ucCekirdek = cerceve({
	ad = "Cekirdek",
	ebeveyn = uc,
	boyut = UDim2.fromOffset(12, 12),
	konum = UDim2.fromScale(0.5, 0.5),
	capa = Vector2.new(0.5, 0.5),
	saydamlik = 0,
	z = 2,
})
yuvarlak(ucCekirdek)

type Adim = {
	esik: number,
	daire: Frame,
	nokta: Frame,
	cizgi: UIStroke,
	yazi: TextLabel,
	durum: string,
}

local adimlar: { Adim } = {}

local adimSirasi = cerceve({ ad = "Adimlar", ebeveyn = ic, boyut = UDim2.new(1, 0, 0, 22), konum = UDim2.fromOffset(0, 104), z = 2 })
local adimDuzen = Instance.new("UIListLayout")
adimDuzen.FillDirection = Enum.FillDirection.Horizontal
adimDuzen.SortOrder = Enum.SortOrder.LayoutOrder
adimDuzen.Parent = adimSirasi

for sira, tanim in ADIMLAR do
	local hucre = cerceve({ ad = tanim.ad, ebeveyn = adimSirasi, boyut = UDim2.new(1 / #ADIMLAR, 0, 1, 0), z = 1 })
	hucre.LayoutOrder = sira

	local hucreDuzen = Instance.new("UIListLayout")
	hucreDuzen.FillDirection = Enum.FillDirection.Horizontal
	hucreDuzen.HorizontalAlignment = Enum.HorizontalAlignment.Center
	hucreDuzen.VerticalAlignment = Enum.VerticalAlignment.Center
	hucreDuzen.SortOrder = Enum.SortOrder.LayoutOrder
	hucreDuzen.Padding = UDim.new(0, 8)
	hucreDuzen.Parent = hucre

	local daire = cerceve({ ad = "Daire", ebeveyn = hucre, boyut = UDim2.fromOffset(14, 14), renk = NEON, z = 1 })
	daire.LayoutOrder = 1
	yuvarlak(daire)
	local cizgi = kontur(daire, SONUK, 2, 0, true)

	local nokta = cerceve({
		ad = "Nokta",
		ebeveyn = daire,
		boyut = UDim2.fromOffset(6, 6),
		konum = UDim2.fromScale(0.5, 0.5),
		capa = Vector2.new(0.5, 0.5),
		saydamlik = 0,
		z = 2,
	})
	yuvarlak(nokta)
	nokta.Visible = false

	local etiket = yazi({
		ad = "Yazi",
		ebeveyn = hucre,
		metin = tanim.ad,
		font = KALIN_FONT,
		boyut = 14,
		renk = SONUK,
		cerceve = UDim2.fromOffset(0, 20),
		z = 1,
	})
	etiket.AutomaticSize = Enum.AutomaticSize.X
	etiket.LayoutOrder = 2

	table.insert(adimlar, {
		esik = tanim.esik,
		daire = daire,
		nokta = nokta,
		cizgi = cizgi,
		yazi = etiket,
		durum = "bekliyor",
	})
end

local butonSirasi = cerceve({ ad = "Butonlar", ebeveyn = ic, boyut = UDim2.new(1, 0, 0, 62), konum = UDim2.fromOffset(0, 138), z = 3 })
local butonDuzen = Instance.new("UIListLayout")
butonDuzen.FillDirection = Enum.FillDirection.Horizontal
butonDuzen.HorizontalAlignment = Enum.HorizontalAlignment.Center
butonDuzen.VerticalAlignment = Enum.VerticalAlignment.Center
butonDuzen.SortOrder = Enum.SortOrder.LayoutOrder
butonDuzen.Padding = UDim.new(0, 14)
butonDuzen.Parent = butonSirasi

local function tusCipi(ebeveyn: Instance): (Frame, TextLabel)
	local cip = cerceve({
		ad = "Tus",
		ebeveyn = ebeveyn,
		boyut = UDim2.fromOffset(58, 26),
		konum = UDim2.new(1, -12, 0.5, 0),
		capa = Vector2.new(1, 0.5),
		renk = SIYAH,
		saydamlik = 0.55,
		z = 6,
	})
	kose(cip, 8)
	kontur(cip, BEYAZ, 1, 0.6, true)
	local cipYazi = yazi({ ad = "Yazi", ebeveyn = cip, metin = "ENTER", font = BASLIK_FONTU, boyut = 13, z = 2 })
	cip.Visible = false
	return cip, cipYazi
end

local oynaKap = cerceve({ ad = "BaslaKap", ebeveyn = butonSirasi, boyut = UDim2.fromOffset(300, 62), z = 1 })
oynaKap.LayoutOrder = 1
local oynaOlcek = Instance.new("UIScale")
oynaOlcek.Parent = oynaKap

local isilti = cerceve({
	ad = "Isilti",
	ebeveyn = oynaKap,
	boyut = UDim2.new(1, 18, 1, 18),
	konum = UDim2.fromScale(0.5, 0.5),
	capa = Vector2.new(0.5, 0.5),
	renk = NEON,
	saydamlik = 1,
	z = 1,
})
kose(isilti, 24)

local oyna = Instance.new("TextButton")
oyna.Name = "Basla"
oyna.Size = UDim2.fromScale(1, 1)
oyna.BackgroundColor3 = BEYAZ
oyna.BorderSizePixel = 0
oyna.AutoButtonColor = false
oyna.Text = ""
oyna.ClipsDescendants = true
oyna.Selectable = false
oyna.ZIndex = 2
oyna.Parent = oynaKap
kose(oyna, 16)
kontur(oyna, SIYAH, 2.5, 0, true)
local oynaGecis = gecis(oyna, PASIF_RENK, nil, 90)

local oynaParlak = cerceve({ ad = "Parlak", ebeveyn = oyna, boyut = UDim2.new(1, -8, 0.5, -2), konum = UDim2.fromOffset(4, 3), saydamlik = 0.8, z = 2 })
kose(oynaParlak, 12)
gecis(oynaParlak, nil, seri({ { 0, 0.2 }, { 1, 1 } }), 90)

local oynaIsik = cerceve({
	ad = "Isik",
	ebeveyn = oyna,
	boyut = UDim2.new(0, 46, 1.8, 0),
	konum = UDim2.new(-0.3, 0, 0.5, 0),
	capa = Vector2.new(0.5, 0.5),
	saydamlik = 1,
	z = 3,
})
oynaIsik.Rotation = 18
gecis(oynaIsik, nil, seri({ { 0, 1 }, { 0.5, 0.35 }, { 1, 1 } }), 0)

local oynaYazi = yazi({ ad = "Yazi", ebeveyn = oyna, metin = "PLAY", font = BASLIK_FONTU, boyut = 32, renk = SOLGUN, kontur = 3, z = 4 })
local oynaTus, oynaTusYazi = tusCipi(oyna)

local atlaKap = cerceve({ ad = "AtlaKap", ebeveyn = butonSirasi, boyut = UDim2.fromOffset(176, 62), z = 1 })
atlaKap.LayoutOrder = 2
atlaKap.ClipsDescendants = true
atlaKap.Visible = false
local atlaOlcek = Instance.new("UIScale")
atlaOlcek.Parent = atlaKap

local atlaDugme = Instance.new("TextButton")
atlaDugme.Name = "Atla"
atlaDugme.AnchorPoint = Vector2.new(0.5, 0.5)
atlaDugme.Position = UDim2.fromScale(0.5, 0.5)
atlaDugme.Size = UDim2.fromOffset(172, 58)
atlaDugme.BackgroundColor3 = BEYAZ
atlaDugme.BackgroundTransparency = 0.88
atlaDugme.BorderSizePixel = 0
atlaDugme.AutoButtonColor = false
atlaDugme.Text = ""
atlaDugme.Selectable = false
atlaDugme.ZIndex = 1
atlaDugme.Parent = atlaKap
kose(atlaDugme, 16)
kontur(atlaDugme, BEYAZ, 2, 0.4, true)

local atlaYazi = yazi({ ad = "Yazi", ebeveyn = atlaDugme, metin = "SKIP  \u{BB}", font = BASLIK_FONTU, boyut = 26, kontur = 2.5, z = 2 })
local atlaTus, atlaTusYazi = tusCipi(atlaDugme)

local ipucuSirasi = cerceve({ ad = "Ipucu", ebeveyn = ic, boyut = UDim2.new(1, 0, 0, 26), konum = UDim2.fromOffset(0, 212), z = 2 })
local ipucuDuzen = Instance.new("UIListLayout")
ipucuDuzen.FillDirection = Enum.FillDirection.Horizontal
ipucuDuzen.HorizontalAlignment = Enum.HorizontalAlignment.Center
ipucuDuzen.VerticalAlignment = Enum.VerticalAlignment.Center
ipucuDuzen.SortOrder = Enum.SortOrder.LayoutOrder
ipucuDuzen.Padding = UDim.new(0, 10)
ipucuDuzen.Parent = ipucuSirasi

local ipucuEtiket = cerceve({ ad = "Etiket", ebeveyn = ipucuSirasi, boyut = UDim2.fromOffset(46, 24), renk = ALTIN, saydamlik = 0, z = 1 })
ipucuEtiket.LayoutOrder = 1
kose(ipucuEtiket, 12)
yazi({ ad = "Yazi", ebeveyn = ipucuEtiket, metin = "TIP", font = BASLIK_FONTU, boyut = 15, renk = LACIVERT, z = 2 })

local ipucuYazi = yazi({
	ad = "Metin",
	ebeveyn = ipucuSirasi,
	metin = "",
	font = GOVDE_FONTU,
	boyut = 18,
	renk = Color3.fromRGB(222, 230, 242),
	cerceve = UDim2.fromOffset(0, 24),
	z = 1,
})
ipucuYazi.AutomaticSize = Enum.AutomaticSize.X
ipucuYazi.LayoutOrder = 2

local solAlt = cerceve({
	ad = "SolAlt",
	ebeveyn = perde,
	boyut = UDim2.fromOffset(260, 40),
	konum = UDim2.new(0, KENAR, 1, -KENAR),
	capa = Vector2.new(0, 1),
	z = 10,
})
local solAltOlcek = Instance.new("UIScale")
solAltOlcek.Parent = solAlt

local halka = cerceve({
	ad = "Halka",
	ebeveyn = solAlt,
	boyut = UDim2.fromOffset(32, 32),
	konum = UDim2.fromScale(0, 0.5),
	capa = Vector2.new(0, 0.5),
	z = 1,
})
yuvarlak(halka)
kontur(halka, BEYAZ, 4, 0.85, true)

local donen = cerceve({ ad = "Donen", ebeveyn = halka, z = 2 })
yuvarlak(donen)
local donenKontur = kontur(donen, NEON, 4, 0, true)
local donenGecis = gecis(donenKontur, nil, seri({ { 0, 0 }, { 0.55, 0 }, { 0.75, 1 }, { 1, 1 } }), 0)

local halkaYazi = yazi({
	ad = "Yazi",
	ebeveyn = solAlt,
	metin = "SETTING UP",
	font = BASLIK_FONTU,
	boyut = 16,
	renk = SOLGUN,
	hiza = Enum.TextXAlignment.Left,
	cerceve = UDim2.new(1, -44, 1, 0),
	konum = UDim2.fromOffset(44, 0),
	kontur = 1.5,
	z = 1,
})

local sagAlt = cerceve({
	ad = "SagAlt",
	ebeveyn = perde,
	boyut = UDim2.fromOffset(320, 40),
	konum = UDim2.new(1, -KENAR, 1, -KENAR),
	capa = Vector2.new(1, 1),
	z = 10,
})
local sagAltOlcek = Instance.new("UIScale")
sagAltOlcek.Parent = sagAlt

yazi({
	ad = "OyunAdi",
	ebeveyn = sagAlt,
	metin = OYUN_ADI,
	font = BASLIK_FONTU,
	boyut = 17,
	renk = SOLGUN,
	hiza = Enum.TextXAlignment.Right,
	kontur = 1.5,
	z = 1,
})

local function olcekle()
	local kamera = Workspace.CurrentCamera
	local boyut = if kamera then kamera.ViewportSize else TASARIM
	if boyut.X <= 0 or boyut.Y <= 0 then
		boyut = TASARIM
	end

	local olcek = math.clamp(math.min(boyut.X / TASARIM.X, boyut.Y / TASARIM.Y), EN_KUCUK_OLCEK, EN_BUYUK_OLCEK)
	icerikOlcek.Scale = olcek
	solAltOlcek.Scale = olcek
	sagAltOlcek.Scale = olcek

	local kenar = math.floor(KENAR * olcek + 0.5)
	icerik.Position = UDim2.new(0.5, 0, 1, -kenar)
	solAlt.Position = UDim2.new(0, kenar, 1, -kenar)
	sagAlt.Position = UDim2.new(1, -kenar, 1, -kenar)
end

local kameraBagi: RBXScriptConnection? = nil

local function kameraIzle()
	if kameraBagi then
		kameraBagi:Disconnect()
		kameraBagi = nil
	end
	local kamera = Workspace.CurrentCamera
	if kamera then
		kameraBagi = kamera:GetPropertyChangedSignal("ViewportSize"):Connect(olcekle)
	end
	olcekle()
end

local kameraDegisti = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(kameraIzle)
kameraIzle()

local rastgele = Random.new()

local function isinCikar()
	local renk = ISIN_RENKLERI[rastgele:NextInteger(1, #ISIN_RENKLERI)]
	local en = rastgele:NextInteger(3, 6)
	local boy = rastgele:NextNumber(0.42, 0.8)
	local sure = rastgele:NextNumber(2.4, 3.6)

	local tutucu = cerceve({
		ad = "Isin",
		ebeveyn = isinKabi,
		boyut = UDim2.new(0, en * 7, 0, 0),
		konum = UDim2.fromScale(rastgele:NextNumber(0.04, 0.96), 1),
		capa = Vector2.new(0.5, 1),
		z = 1,
	})

	local hale = cerceve({ ad = "Hale", ebeveyn = tutucu, renk = renk, saydamlik = 1, z = 1 })
	yuvarlak(hale)
	gecis(hale, nil, seri({ { 0, 1 }, { 0.6, 0.55 }, { 1, 0.2 } }), 90)

	local cekirdek = cerceve({
		ad = "Cekirdek",
		ebeveyn = tutucu,
		boyut = UDim2.new(0, en, 1, 0),
		konum = UDim2.fromScale(0.5, 0),
		capa = Vector2.new(0.5, 0),
		renk = renk:Lerp(BEYAZ, 0.6),
		saydamlik = 1,
		z = 2,
	})
	yuvarlak(cekirdek)
	gecis(cekirdek, nil, seri({ { 0, 1 }, { 0.5, 0.35 }, { 1, 0 } }), 90)

	local cikis = TweenInfo.new(sure * 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(tutucu, cikis, { Size = UDim2.new(0, en * 7, boy, 0) }):Play()
	TweenService:Create(hale, cikis, { BackgroundTransparency = 0.82 }):Play()
	TweenService:Create(cekirdek, cikis, { BackgroundTransparency = 0.3 }):Play()

	task.delay(sure * 0.35, function()
		if not tutucu.Parent or kapandi then
			return
		end
		local sonus = TweenInfo.new(sure * 0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		TweenService:Create(hale, sonus, { BackgroundTransparency = 1 }):Play()
		local bitis = TweenService:Create(cekirdek, sonus, { BackgroundTransparency = 1 })
		bitis.Completed:Connect(function()
			tutucu:Destroy()
		end)
		bitis:Play()
	end)
end

local function kivilcimCikar()
	local boy = rastgele:NextInteger(3, 6)
	local x = rastgele:NextNumber(0.02, 0.98)
	local y = rastgele:NextNumber(0.6, 1.02)
	local sure = rastgele:NextNumber(2.2, 4.2)

	local tane = cerceve({
		ad = "Kivilcim",
		ebeveyn = kivilcimKabi,
		boyut = UDim2.fromOffset(boy, boy),
		konum = UDim2.fromScale(x, y),
		capa = Vector2.new(0.5, 0.5),
		renk = KIVILCIM_RENKLERI[rastgele:NextInteger(1, #KIVILCIM_RENKLERI)],
		saydamlik = 1,
		z = 1,
	})
	tane.Rotation = 45

	TweenService:Create(tane, TweenInfo.new(sure, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(x + rastgele:NextNumber(-0.03, 0.03), y - rastgele:NextNumber(0.12, 0.3)),
		Rotation = 45 + rastgele:NextNumber(-180, 180),
	}):Play()

	local giris = TweenService:Create(tane, TweenInfo.new(sure * 0.25), { BackgroundTransparency = rastgele:NextNumber(0.05, 0.4) })
	giris.Completed:Connect(function()
		if not tane.Parent or kapandi then
			return
		end
		local cikis = TweenService:Create(
			tane,
			TweenInfo.new(sure * 0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		)
		cikis.Completed:Connect(function()
			tane:Destroy()
		end)
		cikis:Play()
	end)
	giris:Play()
end

task.spawn(function()
	while not kapandi do
		if #isinKabi:GetChildren() < 6 then
			isinCikar()
		end
		task.wait(rastgele:NextNumber(0.6, 1.3))
	end
end)

task.spawn(function()
	while not kapandi do
		if #kivilcimKabi:GetChildren() < 28 then
			kivilcimCikar()
		end
		task.wait(0.16)
	end
end)

task.spawn(function()
	local sira = rastgele:NextInteger(1, #IPUCLARI)
	ipucuYazi.Text = IPUCLARI[sira]
	while not kapandi do
		task.wait(IPUCU_SURESI)
		if kapandi then
			break
		end
		local cik = TweenService:Create(ipucuYazi, TweenInfo.new(0.25), { TextTransparency = 1 })
		cik:Play()
		cik.Completed:Wait()
		if kapandi then
			break
		end
		sira = sira % #IPUCLARI + 1
		ipucuYazi.Text = IPUCLARI[sira]
		TweenService:Create(ipucuYazi, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	end
end)

local hedefYuzde = 0
local gorunenYuzde = 0
local baslikMetni = "LOADING"
local noktali = true
local zaman = 0
local paralaks = Vector2.zero

local basladi = os.clock()

local function gecenSure(): number
	return os.clock() - basladi
end

local function ilerle(deger: number, metin: string?)
	hedefYuzde = math.clamp(math.max(deger, hedefYuzde), 0, 1)
	if metin and not hazirGorundu then
		durumYazi.Text = metin
	end
end

local function adimBoya(adim: Adim, durum: string)
	adim.durum = durum
	if durum == "bitti" then
		adim.daire.BackgroundColor3 = NEON
		adim.daire.BackgroundTransparency = 0
		adim.cizgi.Color = NEON
		adim.cizgi.Transparency = 0
		adim.nokta.BackgroundColor3 = BEYAZ
		adim.nokta.Visible = true
		adim.yazi.TextColor3 = NEON_ACIK
	elseif durum == "aktif" then
		adim.daire.BackgroundTransparency = 1
		adim.cizgi.Color = NEON
		adim.nokta.BackgroundColor3 = NEON
		adim.nokta.Visible = true
		adim.yazi.TextColor3 = BEYAZ
	else
		adim.daire.BackgroundTransparency = 1
		adim.cizgi.Color = SONUK
		adim.cizgi.Transparency = 0
		adim.nokta.Visible = false
		adim.yazi.TextColor3 = SONUK
	end
end

local function adimlariGuncelle()
	for sira, adim in adimlar do
		local durum = "bekliyor"
		if gorunenYuzde >= adim.esik then
			durum = "bitti"
		elseif sira == 1 or gorunenYuzde >= adimlar[sira - 1].esik then
			durum = "aktif"
		end

		if durum ~= adim.durum then
			adimBoya(adim, durum)
		end

		if durum == "aktif" then
			adim.cizgi.Transparency = 0.2 + 0.5 * (math.sin(zaman * 5) + 1) / 2
		end
	end
end

local cizimBagi: RBXScriptConnection? = RunService.RenderStepped:Connect(function(dt: number)
	zaman += dt

	local zamanSiniri = if enAzGorunme > 0 then math.clamp(gecenSure() / enAzGorunme, 0, 1) else 1
	local hedef = math.min(hedefYuzde, zamanSiniri)
	gorunenYuzde += (hedef - gorunenYuzde) * math.min(1, dt * 5)
	if hedef >= 1 and gorunenYuzde > 0.995 then
		gorunenYuzde = 1
	end

	dolgu.Size = UDim2.fromScale(gorunenYuzde, 1)
	uc.Position = UDim2.fromScale(gorunenYuzde, 0.5)
	uc.Visible = gorunenYuzde > 0.01 and gorunenYuzde < 0.999
	ucOlcek.Scale = 1 + math.sin(zaman * 6) * 0.12
	yuzdeYazi.Text = `{math.floor(gorunenYuzde * 100)}%`
	parlamaGecis.Offset = Vector2.new((zaman * 0.7) % 2 - 1, 0)

	baslik.Text = if noktali then baslikMetni .. string.rep(".", math.floor(zaman * 2.5) % 4) else baslikMetni

	konturGecis.Rotation = (zaman * 35) % 360
	if not hazirGorundu then
		donenGecis.Rotation = (zaman * 330) % 360
	end

	if not kapandi then
		adimlariGuncelle()
	end

	if oynaAktif then
		local t = math.min((zaman % 2.6) / 0.9, 1)
		oynaIsik.Position = UDim2.new(-0.3 + t * 1.6, 0, 0.5, 0)
	end

	if UserInputService.MouseEnabled and not UserInputService.TouchEnabled then
		local kamera = Workspace.CurrentCamera
		local v = if kamera then kamera.ViewportSize else Vector2.zero
		if v.X > 0 and v.Y > 0 then
			local fare = UserInputService:GetMouseLocation()
			local hedefKayma = Vector2.new((fare.X / v.X - 0.5) * -2 * PARALAKS, (fare.Y / v.Y - 0.5) * -2 * PARALAKS)
			paralaks = paralaks:Lerp(hedefKayma, math.min(1, dt * 3))
			resimKabi.Position = UDim2.new(0.5, paralaks.X, 0.5, paralaks.Y)
		end
	end
end)

local function girisTuru(): string
	local son = UserInputService:GetLastInputType()
	if string.sub(son.Name, 1, 7) == "Gamepad" or GuiService:IsTenFootInterface() then
		return "gamepad"
	end
	if son == Enum.UserInputType.Touch or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) then
		return "dokunmatik"
	end
	return "klavye"
end

local function tusIpuclari()
	local tur = girisTuru()

	oynaTus.Visible = oynaAktif and tur ~= "dokunmatik"
	oynaTusYazi.Text = if tur == "gamepad" then "A" else "ENTER"
	oynaTus.Size = UDim2.fromOffset(if tur == "gamepad" then 28 else 58, 26)

	atlaTus.Visible = tur == "gamepad"
	atlaTusYazi.Text = "X"
	atlaTus.Size = UDim2.fromOffset(28, 26)

	if hazirGorundu and not kapandi then
		durumYazi.Text = if tur == "gamepad"
			then "Press A to start"
			elseif tur == "dokunmatik" then "Tap PLAY to start"
			else "Click PLAY or press Enter to start"
	end
end

local girisBagi = UserInputService.LastInputTypeChanged:Connect(tusIpuclari)

local function odakEfekti()
	pcall(function()
		local kamera = Workspace.CurrentCamera
		if not kamera then
			return
		end
		local bulanik = Instance.new("BlurEffect")
		bulanik.Name = "YuklemeOdak"
		bulanik.Size = 18
		bulanik.Parent = kamera
		local netles = TweenService:Create(
			bulanik,
			TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = 0 }
		)
		netles.Completed:Connect(function()
			bulanik:Destroy()
		end)
		netles:Play()
	end)
end

local function kapat()
	if kapandi then
		return
	end
	kapandi = true

	ContextActionService:UnbindAction(BASLA_EYLEMI)
	ContextActionService:UnbindAction(ATLA_EYLEMI)
	girisBagi:Disconnect()
	kameraDegisti:Disconnect()
	if kameraBagi then
		kameraBagi:Disconnect()
		kameraBagi = nil
	end

	coreGuiGeriAc()
	odakEfekti()

	TweenService
		:Create(kayan, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.fromOffset(0, 70) })
		:Play()
	TweenService
		:Create(
			resimYaklasma,
			TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.fromScale(YAKLASMA + 0.1, YAKLASMA + 0.1) }
		)
		:Play()

	local son = solukluk(perde, 1, 0.65)
	if son then
		son.Completed:Wait()
	end

	local bag = cizimBagi
	if bag then
		bag:Disconnect()
		cizimBagi = nil
	end

	ekran:Destroy()
end

local function atlaGizle()
	if not atlaKap.Visible then
		return
	end
	ContextActionService:UnbindAction(ATLA_EYLEMI)

	solukluk(atlaKap, 1, 0.25)
	TweenService:Create(butonDuzen, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Padding = UDim.new(0, 0) })
		:Play()

	local daral = TweenService:Create(
		atlaKap,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(0, 62) }
	)
	daral.Completed:Connect(function()
		if not kapandi then
			atlaKap.Visible = false
		end
	end)
	daral:Play()
end

local function atla()
	if atlaIstendi or kapandi then
		return
	end
	atlaIstendi = true
	enAzGorunme = 0

	ContextActionService:UnbindAction(ATLA_EYLEMI)

	baslikMetni = "JOINING"
	noktali = true
	atlaYazi.Text = "SKIPPED"
	atlaTus.Visible = false
	solukluk(atlaKap, 0.55, 0.2)
	durumYazi.Text = "Skipping the rest of the preload"

	if hazirlandi then
		task.spawn(kapat)
	end
end

local function atlaGoster()
	if afkDonusu or hazirlandi or kapandi or atlaIstendi then
		return
	end

	atlaKap.Visible = true
	solukluk(atlaKap, 1, 0)
	solukluk(atlaKap, 0, 0.35)

	atlaOlcek.Scale = 0.85
	TweenService:Create(atlaOlcek, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	tusIpuclari()

	ContextActionService:BindAction(ATLA_EYLEMI, function(_, durum)
		if durum == Enum.UserInputState.Begin then
			atla()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonX)
end

local function hazirGorunumu()
	hazirGorundu = true
	oynaAktif = true

	baslikMetni = "READY!"
	noktali = false
	baslik.TextColor3 = ALTIN

	halkaYazi.Text = "READY"
	halkaYazi.TextColor3 = NEON_ACIK
	donenGecis.Transparency = seri({ { 0, 0 }, { 1, 0 } })

	atlaGizle()

	oynaGecis.Color = AKTIF_RENK
	oynaYazi.TextColor3 = BEYAZ
	oynaIsik.BackgroundTransparency = 0

	oynaOlcek.Scale = 0.88
	TweenService:Create(oynaOlcek, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	isilti.BackgroundTransparency = 0.85
	TweenService
		:Create(
			isilti,
			TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ BackgroundTransparency = 0.55 }
		)
		:Play()

	tusIpuclari()

	ContextActionService:BindAction(BASLA_EYLEMI, function(_, durum)
		if durum == Enum.UserInputState.Begin then
			task.spawn(kapat)
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonStart, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter)
end

local function hazirOl()
	if hazirlandi or kapandi then
		return
	end
	hazirlandi = true

	ilerle(1, "Everything is ready")

	while not kapandi and not atlaIstendi and gecenSure() < enAzGorunme do
		task.wait(0.05)
	end

	if kapandi then
		return
	end

	if not atlaIstendi then
		task.wait(0.35)
		if kapandi then
			return
		end
	end

	if afkDonusu or atlaIstendi then
		kapat()
		return
	end

	hazirGorunumu()
end

local function dugmeTepkisi(dugme: TextButton, olcek: UIScale, kosul: () -> boolean)
	dugme.MouseEnter:Connect(function()
		if kosul() then
			TweenService:Create(olcek, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.05 }):Play()
		end
	end)
	dugme.MouseLeave:Connect(function()
		TweenService:Create(olcek, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)
	dugme.MouseButton1Down:Connect(function()
		if kosul() then
			TweenService:Create(olcek, TweenInfo.new(0.08), { Scale = 0.96 }):Play()
		end
	end)
	dugme.MouseButton1Up:Connect(function()
		if kosul() then
			TweenService:Create(olcek, TweenInfo.new(0.12), { Scale = 1.05 }):Play()
		end
	end)
end

dugmeTepkisi(oyna, oynaOlcek, function()
	return oynaAktif and not kapandi
end)

dugmeTepkisi(atlaDugme, atlaOlcek, function()
	return not atlaIstendi and not kapandi
end)

oyna.Activated:Connect(function()
	if oynaAktif then
		task.spawn(kapat)
	end
end)

atlaDugme.Activated:Connect(atla)

local function oncelik(node: Instance): number?
	if node:IsA("Decal") or node:IsA("Texture") or node:IsA("ImageLabel") or node:IsA("ImageButton") then
		return 1
	end
	if node:IsA("Sound") then
		return 2
	end
	if node:IsA("MeshPart") or node:IsA("SpecialMesh") then
		return 3
	end
	return nil
end

local function varliklariYukle()
	ilerle(0.05, "Reaching the server")

	local kok = ReplicatedStorage:WaitForChild("Assets", 15)
	if not kok then
		ilerle(0.6, "Loading the world")
		return
	end

	ilerle(0.12, "Loading world assets")

	local gruplar: { { Instance } } = { {}, {}, {} }
	for _, node in kok:GetDescendants() do
		local sira = oncelik(node)
		if sira then
			table.insert(gruplar[sira], node)
		end
	end

	local liste: { Instance } = {}
	for _, grup in gruplar do
		for _, node in grup do
			table.insert(liste, node)
		end
	end

	if #liste == 0 then
		ilerle(0.6, "Loading the world")
		return
	end

	local islenen = 0

	for bas = 1, #liste, OBEK do
		if atlaIstendi or kapandi then
			return
		end

		local obek: { Instance } = {}
		for i = bas, math.min(bas + OBEK - 1, #liste) do
			table.insert(obek, liste[i])
		end

		pcall(function()
			ContentProvider:PreloadAsync(obek)
		end)

		islenen += #obek
		if not atlaIstendi then
			ilerle(0.12 + (islenen / #liste) * 0.63, `Loading world assets  {islenen} / {#liste}`)
		end
	end
end

solukluk(kayan, 1, 0)
solukluk(solAlt, 1, 0)
solukluk(sagAlt, 1, 0)
kayan.Position = UDim2.fromOffset(0, 40)

task.defer(function()
	TweenService
		:Create(kayan, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0) })
		:Play()
	solukluk(kayan, 0, 0.5)
	solukluk(solAlt, 0, 0.5)
	solukluk(sagAlt, 0, 0.5)
end)

task.delay(ATLA_GECIKMESI, atlaGoster)
task.delay(EN_COK_BEKLEME, hazirOl)

task.spawn(function()
	local ok, hata = pcall(varliklariYukle)
	if not ok then
		warn(`[YuklemeEkrani] Assets failed to preload: {tostring(hata)}`)
	end

	ilerle(0.8, "Waiting for the world")

	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	ilerle(0.88, "Loading your progress")
	player:WaitForChild("leaderstats", 15)

	ilerle(0.94, "Spawning your character")

	if not player.Character then
		player.CharacterAdded:Wait()
	end

	hazirOl()
end)
