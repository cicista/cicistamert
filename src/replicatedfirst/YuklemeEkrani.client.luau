--!strict

local ContentProvider = game:GetService("ContentProvider")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
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
local LOGO_ORANI = 1842 / 1026

local ADA_ADI = "MainIsland"
local YORUNGE_SURESI = 70
local YORUNGE_YARICAPI = 120
local YORUNGE_YUKSEKLIGI = 0.35
local BULANIKLIK = 9
local KAMERA_EYLEMI = "YuklemeKamerasi"

local EN_COK_BEKLEME = 45
local ATLA_GECIKMESI = 0.6
local IPUCU_SURESI = 5
local OBEK = 20

local AFK_DONUS_ANAHTARI = "AfkDonus"

local BASLA_EYLEMI = "YuklemeBasla"
local ATLA_EYLEMI = "YuklemeAtla"

local TASARIM = Vector2.new(1280, 760)
local EN_KUCUK_OLCEK = 0.5
local EN_BUYUK_OLCEK = 1

local ALT_EN = 460
local ALT_BOY = 140
local KENAR = 24
local PARALAKS = 10

local ALTIN = Color3.fromRGB(255, 205, 70)
local BEYAZ = Color3.fromRGB(255, 255, 255)
local SIYAH = Color3.fromRGB(0, 0, 0)
local KOYU = Color3.fromRGB(8, 11, 20)
local LACIVERT = Color3.fromRGB(12, 22, 40)

local AKTIF_RENK = ColorSequence.new(Color3.fromRGB(120, 235, 255), Color3.fromRGB(30, 140, 255))
local ATLA_RENK = ColorSequence.new(Color3.fromRGB(70, 80, 110), Color3.fromRGB(36, 42, 62))

local IPUCLARI = {
	"Upgrade your shovel to dig up rarer pets.",
	"The Detective reveals the pets you dig up.",
	"Place pets on your base to earn Rot every second.",
	"Gold, Diamond, Galaxy and Hacker mutations boost income.",
	"New islands add luck: Candy +2, Snow +4, Volcano +8, Sea +16.",
	"A Lucky Block rain starts every hour. Don't miss it!",
	"When the Lucky Block rain ends, a Mystery Beam drops on a random island!",
	"Weekends bring 2x luck. Plan your digging!",
	"Fuse pets in the Fuse Machine to reach a higher rarity.",
	"Reach level 15 to trade pets with other players.",
	"Your base earns a little Rot even while you are offline.",
	"Stand in Clover Fields to collect Luck Points while AFK.",
	"Fill your Index by discovering every pet and mutation.",
}

local BASLIK_FONTU = Font.fromEnum(Enum.Font.FredokaOne)
local GOVDE_FONTU = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)

local kapandi = false
local hazirlandi = false
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

local bulaniklik = Instance.new("BlurEffect")
bulaniklik.Name = "YuklemeBulanikligi"
bulaniklik.Size = BULANIKLIK
bulaniklik.Parent = Lighting

local adaMerkezi: Vector3? = nil
local gorunenMerkez: Vector3? = nil

task.spawn(function()
	while not kapandi do
		local ada = Workspace:FindFirstChild(ADA_ADI)
		local dogus = ada and ada:FindFirstChildWhichIsA("SpawnLocation", true)
		if dogus and dogus:IsA("BasePart") then
			adaMerkezi = dogus.Position
		elseif ada and ada:IsA("Model") then
			local ok, cf, boyut = pcall(function()
				return ada:GetBoundingBox()
			end)
			if ok and cf and boyut and boyut.Magnitude > 1 then
				adaMerkezi = (cf :: CFrame).Position
			end
		end
		task.wait(1.5)
	end
end)

RunService:BindToRenderStep(KAMERA_EYLEMI, Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	local kamera = Workspace.CurrentCamera
	local merkez = adaMerkezi
	if not kamera or not merkez then
		return
	end

	local onceki = gorunenMerkez
	gorunenMerkez = if onceki then onceki:Lerp(merkez, math.min(1, dt * 1.5)) else merkez

	local odak = gorunenMerkez :: Vector3
	local aci = (Workspace:GetServerTimeNow() / YORUNGE_SURESI) % 1 * math.pi * 2
	local konum = odak + Vector3.new(math.cos(aci) * YORUNGE_YARICAPI, YORUNGE_YARICAPI * YORUNGE_YUKSEKLIGI, math.sin(aci) * YORUNGE_YARICAPI)

	kamera.CameraType = Enum.CameraType.Scriptable
	kamera.CFrame = CFrame.lookAt(konum, odak)
end)

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

local gizlenenler: { ScreenGui } = {}

local function arayuzGizle(gui: Instance)
	task.defer(function()
		if kapandi or gui == ekran or not gui:IsA("ScreenGui") or not gui.Enabled or gui.Parent ~= playerGui then
			return
		end
		gui.Enabled = false
		table.insert(gizlenenler, gui)
	end)
end

for _, gui in playerGui:GetChildren() do
	arayuzGizle(gui)
end
local eklenenBagi = playerGui.ChildAdded:Connect(arayuzGizle)

local function arayuzGeriAc()
	eklenenBagi:Disconnect()
	for _, gui in gizlenenler do
		if gui.Parent then
			gui.Enabled = true
		end
	end
	table.clear(gizlenenler)
end

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
perde.BackgroundTransparency = 0.72
perde.BorderSizePixel = 0
perde.ZIndex = 1
perde.Parent = ekran

local kenarlar = cerceve({ ad = "Kenarlar", ebeveyn = perde, renk = KOYU, saydamlik = 0, z = 2 })
gecis(kenarlar, nil, seri({ { 0, 0.35 }, { 0.2, 1 }, { 0.8, 1 }, { 1, 0.35 } }), 0)
local altKenar = cerceve({ ad = "AltKenar", ebeveyn = perde, renk = KOYU, saydamlik = 0, z = 2 })
gecis(altKenar, nil, seri({ { 0, 0.5 }, { 0.18, 1 }, { 0.66, 1 }, { 1, 0.3 } }), 90)

local bokehKabi = cerceve({ ad = "Bokeh", ebeveyn = perde, z = 3 })
local kivilcimKabi = cerceve({ ad = "Kivilcimlar", ebeveyn = perde, z = 4 })

local efektKabi = cerceve({
	ad = "Efektler",
	ebeveyn = perde,
	konum = UDim2.fromScale(0.5, 0.42),
	capa = Vector2.new(0.5, 0.5),
	boyut = UDim2.fromOffset(900, 900),
	z = 5,
})

type Renkli = { nesne: GuiObject, kayma: number }
local renkliler: { Renkli } = {}

local function huzmeSeti(ad: string, sayi: number, kalinlik: number, saydamlik: number, z: number): Frame
	local kap = cerceve({
		ad = ad,
		ebeveyn = efektKabi,
		konum = UDim2.fromScale(0.5, 0.5),
		capa = Vector2.new(0.5, 0.5),
		z = z,
	})
	for i = 1, sayi do
		local en = kalinlik * (if i % 2 == 0 then 1.7 else 1)
		local huzme = cerceve({
			ad = "Huzme",
			ebeveyn = kap,
			boyut = UDim2.new(0, en, 1, 0),
			konum = UDim2.fromScale(0.5, 0.5),
			capa = Vector2.new(0.5, 0.5),
			saydamlik = saydamlik,
			z = 1,
		})
		huzme.Rotation = (i - 1) * 180 / sayi
		gecis(huzme, nil, seri({ { 0, 1 }, { 0.28, 0.75 }, { 0.5, 0 }, { 0.72, 0.75 }, { 1, 1 } }), 90)
		table.insert(renkliler, { nesne = huzme, kayma = (i - 1) / sayi })
	end
	return kap
end

local huzmelerBuyuk = huzmeSeti("HuzmelerBuyuk", 12, 34, 0.45, 1)
local huzmelerKucuk = huzmeSeti("HuzmelerKucuk", 9, 16, 0.3, 2)

local haleler: { Frame } = {}
local HALE_ORANLARI = { 0.5, 0.42, 0.34, 0.26 }
for sira, oran in HALE_ORANLARI do
	local hale = cerceve({
		ad = `Hale{sira}`,
		ebeveyn = efektKabi,
		boyut = UDim2.fromScale(oran, oran * 0.62),
		konum = UDim2.fromScale(0.5, 0.5),
		capa = Vector2.new(0.5, 0.5),
		saydamlik = 0.9,
		z = 3,
	})
	yuvarlak(hale)
	table.insert(haleler, hale)
	table.insert(renkliler, { nesne = hale, kayma = sira * 0.04 })
end

local halkaKabi = cerceve({ ad = "Halkalar", ebeveyn = efektKabi, z = 4 })

local logo = Instance.new("ImageLabel")
logo.Name = "Logo"
logo.AnchorPoint = Vector2.new(0.5, 0.5)
logo.Position = UDim2.fromScale(0.5, 0.42)
logo.Size = UDim2.fromOffset(700, 390)
logo.BackgroundTransparency = 1
logo.ScaleType = Enum.ScaleType.Fit
logo.ImageTransparency = 1
logo.ZIndex = 10
logo.Parent = perde
local logoOlcek = Instance.new("UIScale")
logoOlcek.Parent = logo

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

	logo.Image = kimlik
	pcall(function()
		ContentProvider:PreloadAsync({ logo })
	end)

	if kapandi then
		return
	end

	logoOlcek.Scale = 0.85
	TweenService:Create(logo, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 0 })
		:Play()
	TweenService:Create(logoOlcek, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end)

local icerik = cerceve({
	ad = "Icerik",
	ebeveyn = perde,
	boyut = UDim2.fromOffset(ALT_EN, ALT_BOY),
	konum = UDim2.fromScale(0.5, 0.8),
	capa = Vector2.new(0.5, 0),
	z = 20,
})
local icerikOlcek = Instance.new("UIScale")
icerikOlcek.Parent = icerik

local kayan = cerceve({ ad = "Kayan", ebeveyn = icerik, z = 1 })

local yuzdeSirasi = cerceve({ ad = "Yuzde", ebeveyn = kayan, boyut = UDim2.new(1, 0, 0, 30), z = 2 })

local cubuk = cerceve({
	ad = "Cubuk",
	ebeveyn = yuzdeSirasi,
	boyut = UDim2.new(1, -156, 0, 14),
	konum = UDim2.fromScale(0.5, 0.5),
	capa = Vector2.new(0.5, 0.5),
	renk = Color3.fromRGB(16, 20, 34),
	saydamlik = 0.25,
	z = 1,
})
yuvarlak(cubuk)
kontur(cubuk, BEYAZ, 1.5, 0.55, true)

local dolgu = cerceve({ ad = "Dolgu", ebeveyn = cubuk, boyut = UDim2.fromScale(0, 1), saydamlik = 0, z = 1 })
yuvarlak(dolgu)
local dolguGecis = gecis(dolgu, nil, nil, 0)

local parilti = cerceve({ ad = "Parilti", ebeveyn = dolgu, saydamlik = 0, z = 3 })
yuvarlak(parilti)
local parlamaGecis = gecis(parilti, nil, seri({ { 0, 1 }, { 0.4, 1 }, { 0.5, 0.45 }, { 0.6, 1 }, { 1, 1 } }), 0)

local yuzdeYazi = yazi({
	ad = "Metin",
	ebeveyn = yuzdeSirasi,
	metin = "0%",
	font = BASLIK_FONTU,
	boyut = 28,
	renk = BEYAZ,
	hiza = Enum.TextXAlignment.Right,
	cerceve = UDim2.new(0, 70, 1, 0),
	konum = UDim2.fromScale(1, 0),
	capa = Vector2.new(1, 0),
	kontur = 2.5,
	z = 2,
})

local dugmeKap = cerceve({
	ad = "Dugme",
	ebeveyn = kayan,
	boyut = UDim2.fromOffset(240, 54),
	konum = UDim2.fromOffset(ALT_EN / 2, 46),
	capa = Vector2.new(0.5, 0),
	z = 3,
})

local function tusCipi(ebeveyn: Instance): (Frame, TextLabel)
	local cip = cerceve({
		ad = "Tus",
		ebeveyn = ebeveyn,
		boyut = UDim2.fromOffset(48, 22),
		konum = UDim2.new(1, -10, 0.5, 0),
		capa = Vector2.new(1, 0.5),
		renk = SIYAH,
		saydamlik = 0.55,
		z = 6,
	})
	kose(cip, 7)
	kontur(cip, BEYAZ, 1, 0.6, true)
	local cipYazi = yazi({ ad = "Yazi", ebeveyn = cip, metin = "ENTER", font = BASLIK_FONTU, boyut = 11, z = 2 })
	cip.Visible = false
	return cip, cipYazi
end

type Dugme = {
	kap: Frame,
	olcek: UIScale,
	dugme: TextButton,
	gecis: UIGradient,
	isik: Frame,
	yazi: TextLabel,
	tus: Frame,
	tusYazi: TextLabel,
}

local function dugmeKur(ad: string, metin: string, renk: ColorSequence): Dugme
	local kap = cerceve({ ad = ad, ebeveyn = dugmeKap, z = 1 })
	kap.Visible = false
	local olcek = Instance.new("UIScale")
	olcek.Parent = kap

	local dugme = Instance.new("TextButton")
	dugme.Name = "Dugme"
	dugme.Size = UDim2.fromScale(1, 1)
	dugme.BackgroundColor3 = BEYAZ
	dugme.BorderSizePixel = 0
	dugme.AutoButtonColor = false
	dugme.Text = ""
	dugme.ClipsDescendants = true
	dugme.Selectable = false
	dugme.ZIndex = 2
	dugme.Parent = kap
	kose(dugme, 16)
	kontur(dugme, SIYAH, 2.5, 0, true)
	local dugmeGecis = gecis(dugme, renk, nil, 90)

	local parlak = cerceve({
		ad = "Parlak",
		ebeveyn = dugme,
		boyut = UDim2.new(1, -8, 0.5, -2),
		konum = UDim2.fromOffset(4, 3),
		saydamlik = 0.8,
		z = 2,
	})
	kose(parlak, 12)
	gecis(parlak, nil, seri({ { 0, 0.2 }, { 1, 1 } }), 90)

	local isik = cerceve({
		ad = "Isik",
		ebeveyn = dugme,
		boyut = UDim2.new(0, 38, 1.8, 0),
		konum = UDim2.new(-0.3, 0, 0.5, 0),
		capa = Vector2.new(0.5, 0.5),
		saydamlik = 0,
		z = 3,
	})
	isik.Rotation = 18
	gecis(isik, nil, seri({ { 0, 1 }, { 0.5, 0.35 }, { 1, 1 } }), 0)

	local etiket = yazi({ ad = "Yazi", ebeveyn = dugme, metin = metin, font = BASLIK_FONTU, boyut = 28, kontur = 2.5, z = 4 })
	local tus, tusYazi = tusCipi(dugme)

	return {
		kap = kap,
		olcek = olcek,
		dugme = dugme,
		gecis = dugmeGecis,
		isik = isik,
		yazi = etiket,
		tus = tus,
		tusYazi = tusYazi,
	}
end

local oyna = dugmeKur("Basla", "PLAY", AKTIF_RENK)
local atlaD = dugmeKur("Atla", "SKIP  \u{BB}", ATLA_RENK)

local ipucuSirasi = cerceve({
	ad = "Ipucu",
	ebeveyn = kayan,
	boyut = UDim2.new(1, 0, 0, 24),
	konum = UDim2.fromOffset(0, 114),
	z = 2,
})
local ipucuDuzen = Instance.new("UIListLayout")
ipucuDuzen.FillDirection = Enum.FillDirection.Horizontal
ipucuDuzen.HorizontalAlignment = Enum.HorizontalAlignment.Center
ipucuDuzen.VerticalAlignment = Enum.VerticalAlignment.Center
ipucuDuzen.SortOrder = Enum.SortOrder.LayoutOrder
ipucuDuzen.Padding = UDim.new(0, 8)
ipucuDuzen.Parent = ipucuSirasi

local ipucuEtiket = cerceve({ ad = "Etiket", ebeveyn = ipucuSirasi, boyut = UDim2.fromOffset(38, 20), renk = ALTIN, saydamlik = 0, z = 1 })
ipucuEtiket.LayoutOrder = 1
kose(ipucuEtiket, 10)
yazi({ ad = "Yazi", ebeveyn = ipucuEtiket, metin = "TIP", font = BASLIK_FONTU, boyut = 13, renk = LACIVERT, z = 2 })

local ipucuYazi = yazi({
	ad = "Metin",
	ebeveyn = ipucuSirasi,
	metin = "",
	font = GOVDE_FONTU,
	boyut = 16,
	renk = Color3.fromRGB(235, 240, 250),
	cerceve = UDim2.fromOffset(0, 20),
	kontur = 1.5,
	z = 1,
})
ipucuYazi.AutomaticSize = Enum.AutomaticSize.X
ipucuYazi.LayoutOrder = 2

local logoMerkezi = Vector2.new(640, 320)
local logoEni = 700

local function olcekle()
	local kamera = Workspace.CurrentCamera
	local v = if ekran.AbsoluteSize.X > 0 and ekran.AbsoluteSize.Y > 0
		then ekran.AbsoluteSize
		elseif kamera then kamera.ViewportSize
		else TASARIM
	if v.X <= 0 or v.Y <= 0 then
		v = TASARIM
	end

	local olcek = math.clamp(math.min(v.X / TASARIM.X, v.Y / TASARIM.Y), EN_KUCUK_OLCEK, EN_BUYUK_OLCEK)
	icerikOlcek.Scale = olcek

	local bosluk = KENAR * olcek
	local altBoy = ALT_BOY * olcek
	local enFazlaLogoBoy = v.Y - altBoy - bosluk * 4
	local en = math.min(v.X * 0.56, enFazlaLogoBoy * LOGO_ORANI, 1050)
	local boy = en / LOGO_ORANI

	local ust = math.max(bosluk, (v.Y - (boy + bosluk + altBoy)) / 2)
	logoEni = en
	logoMerkezi = Vector2.new(v.X / 2, ust + boy / 2)

	logo.Size = UDim2.fromOffset(en, boy)
	logo.Position = UDim2.new(0.5, 0, 0, logoMerkezi.Y)
	efektKabi.Size = UDim2.fromOffset(en * 1.9, en * 1.9)
	efektKabi.Position = UDim2.new(0.5, 0, 0, logoMerkezi.Y)
	icerik.Position = UDim2.new(0.5, 0, 0, ust + boy + bosluk)
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
ekran:GetPropertyChangedSignal("AbsoluteSize"):Connect(olcekle)
kameraIzle()

local rastgele = Random.new()

local function rastgeleRenk(): Color3
	return Color3.fromHSV(rastgele:NextNumber(), rastgele:NextNumber(0.55, 0.85), 1)
end

local function pastelRenk(): Color3
	return Color3.fromHSV(rastgele:NextNumber(), rastgele:NextNumber(0.35, 0.6), 1)
end

local function bokehCikar()
	local cap = rastgele:NextInteger(40, 150)
	local x = rastgele:NextNumber(0, 1)
	local y = rastgele:NextNumber(0.1, 1.05)
	local sure = rastgele:NextNumber(7, 12)
	local renk = pastelRenk()
	local yogunluk = rastgele:NextNumber(0.55, 1)

	local top = cerceve({
		ad = "Top",
		ebeveyn = bokehKabi,
		boyut = UDim2.fromOffset(cap, cap),
		konum = UDim2.fromScale(x, y),
		capa = Vector2.new(0.5, 0.5),
		z = 1,
	})

	local katmanlar: { { nesne: Frame, saydam: number } } = {}
	for sira, oran in { 1, 0.78, 0.55 } do
		local katman = cerceve({
			ad = `Katman{sira}`,
			ebeveyn = top,
			boyut = UDim2.fromScale(oran, oran),
			konum = UDim2.fromScale(0.5, 0.5),
			capa = Vector2.new(0.5, 0.5),
			renk = renk:Lerp(BEYAZ, (sira - 1) * 0.2),
			saydamlik = 1,
			z = sira,
		})
		yuvarlak(katman)
		table.insert(katmanlar, { nesne = katman, saydam = 1 - (0.06 + sira * 0.035) * yogunluk })
	end

	TweenService:Create(top, TweenInfo.new(sure, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		Position = UDim2.fromScale(x + rastgele:NextNumber(-0.06, 0.06), y - rastgele:NextNumber(0.08, 0.22)),
		Size = UDim2.fromOffset(cap * 1.15, cap * 1.15),
	}):Play()

	local giris = TweenInfo.new(sure * 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	for _, k in katmanlar do
		TweenService:Create(k.nesne, giris, { BackgroundTransparency = k.saydam }):Play()
	end

	task.delay(sure * 0.55, function()
		if not top.Parent or kapandi then
			return
		end
		local cikis = TweenInfo.new(sure * 0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		local son: Tween? = nil
		for _, k in katmanlar do
			local tween = TweenService:Create(k.nesne, cikis, { BackgroundTransparency = 1 })
			tween:Play()
			son = tween
		end
		if son then
			son.Completed:Connect(function()
				top:Destroy()
			end)
		end
	end)
end

local parlamaKabi = cerceve({ ad = "Parlamalar", ebeveyn = logo, z = 12 })

local function parlamaCikar()
	local boy = rastgele:NextInteger(26, 54)
	local renk = if rastgele:NextNumber() < 0.6 then BEYAZ else pastelRenk():Lerp(BEYAZ, 0.4)
	local sure = rastgele:NextNumber(0.7, 1.1)

	local yildiz = cerceve({
		ad = "Parlama",
		ebeveyn = parlamaKabi,
		boyut = UDim2.fromOffset(boy, boy),
		konum = UDim2.fromScale(rastgele:NextNumber(0.12, 0.88), rastgele:NextNumber(0.15, 0.85)),
		capa = Vector2.new(0.5, 0.5),
		z = 1,
	})
	local olcek = Instance.new("UIScale")
	olcek.Scale = 0
	olcek.Parent = yildiz

	for sira, aci in { 0, 90 } do
		local kol = cerceve({
			ad = `Kol{sira}`,
			ebeveyn = yildiz,
			boyut = UDim2.new(0.14, 0, 1, 0),
			konum = UDim2.fromScale(0.5, 0.5),
			capa = Vector2.new(0.5, 0.5),
			renk = renk,
			saydamlik = 0,
			z = 1,
		})
		kol.Rotation = aci
		yuvarlak(kol)
		gecis(kol, nil, seri({ { 0, 1 }, { 0.35, 0.6 }, { 0.5, 0 }, { 0.65, 0.6 }, { 1, 1 } }), 90)
	end

	local cekirdek = cerceve({
		ad = "Cekirdek",
		ebeveyn = yildiz,
		boyut = UDim2.fromScale(0.3, 0.3),
		konum = UDim2.fromScale(0.5, 0.5),
		capa = Vector2.new(0.5, 0.5),
		renk = BEYAZ,
		saydamlik = 0.1,
		z = 2,
	})
	yuvarlak(cekirdek)

	local yari = TweenInfo.new(sure / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
	TweenService:Create(olcek, yari, { Scale = 1 }):Play()
	local donus = TweenService:Create(yildiz, TweenInfo.new(sure, Enum.EasingStyle.Linear), { Rotation = 90 })
	donus.Completed:Connect(function()
		yildiz:Destroy()
	end)
	donus:Play()
end

local function kivilcimCikar()
	local x = rastgele:NextNumber(0.02, 0.98)
	local y = rastgele:NextNumber(0.35, 1.02)
	local sure = rastgele:NextNumber(2.2, 4.2)
	local renk = rastgeleRenk()

	local tane: GuiObject
	local soru = rastgele:NextNumber() < 0.22
	if soru then
		local etiket = yazi({
			ad = "Soru",
			ebeveyn = kivilcimKabi,
			metin = "?",
			font = BASLIK_FONTU,
			boyut = rastgele:NextInteger(18, 36),
			renk = renk,
			cerceve = UDim2.fromOffset(40, 40),
			konum = UDim2.fromScale(x, y),
			capa = Vector2.new(0.5, 0.5),
			kontur = 2,
			z = 1,
		})
		etiket.TextTransparency = 1
		tane = etiket
	else
		local boy = rastgele:NextInteger(3, 8)
		local kare = cerceve({
			ad = "Kivilcim",
			ebeveyn = kivilcimKabi,
			boyut = UDim2.fromOffset(boy, boy),
			konum = UDim2.fromScale(x, y),
			capa = Vector2.new(0.5, 0.5),
			renk = renk,
			saydamlik = 1,
			z = 1,
		})
		kare.Rotation = 45
		tane = kare
	end

	TweenService:Create(tane, TweenInfo.new(sure, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(x + rastgele:NextNumber(-0.03, 0.03), y - rastgele:NextNumber(0.12, 0.32)),
		Rotation = (if soru then 0 else 45) + rastgele:NextNumber(-180, 180),
	}):Play()

	local ozellik = if soru then "TextTransparency" else "BackgroundTransparency"
	local konturu = tane:FindFirstChildOfClass("UIStroke")
	if konturu then
		konturu.Transparency = 1
		TweenService:Create(konturu, TweenInfo.new(sure * 0.25), { Transparency = 0.2 }):Play()
	end

	local giris = TweenService:Create(tane, TweenInfo.new(sure * 0.25), { [ozellik] = rastgele:NextNumber(0, 0.3) })
	giris.Completed:Connect(function()
		if not tane.Parent or kapandi then
			return
		end
		local bilgi = TweenInfo.new(sure * 0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		if konturu then
			TweenService:Create(konturu, bilgi, { Transparency = 1 }):Play()
		end
		local cikis = TweenService:Create(tane, bilgi, { [ozellik] = 1 })
		cikis.Completed:Connect(function()
			tane:Destroy()
		end)
		cikis:Play()
	end)
	giris:Play()
end

local function halkaCikar()
	local halka = cerceve({
		ad = "Halka",
		ebeveyn = halkaKabi,
		boyut = UDim2.fromScale(0.28, 0.28 * 0.62),
		konum = UDim2.fromScale(0.5, 0.5),
		capa = Vector2.new(0.5, 0.5),
		z = 1,
	})
	yuvarlak(halka)
	local cizgi = kontur(halka, rastgeleRenk(), 6, 0.1, true)

	local bilgi = TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(halka, bilgi, { Size = UDim2.fromScale(1, 0.62) }):Play()
	local son = TweenService:Create(cizgi, bilgi, { Transparency = 1, Thickness = 1 })
	son.Completed:Connect(function()
		halka:Destroy()
	end)
	son:Play()
end

task.spawn(function()
	while not kapandi do
		if #bokehKabi:GetChildren() < 16 then
			bokehCikar()
		end
		task.wait(rastgele:NextNumber(0.3, 0.6))
	end
end)

task.spawn(function()
	while not kapandi do
		if #parlamaKabi:GetChildren() < 4 then
			parlamaCikar()
		end
		task.wait(rastgele:NextNumber(0.2, 0.5))
	end
end)

task.spawn(function()
	while not kapandi do
		if #kivilcimKabi:GetChildren() < 45 then
			kivilcimCikar()
		end
		task.wait(0.1)
	end
end)

task.spawn(function()
	while not kapandi do
		halkaCikar()
		task.wait(1.1)
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
		TweenService:Create(ipucuYazi, TweenInfo.new(0.2), { TextTransparency = 0.7 }):Play()
		task.wait(0.2)
		if kapandi then
			break
		end
		sira = sira % #IPUCLARI + 1
		ipucuYazi.Text = IPUCLARI[sira]
		ipucuYazi.TextTransparency = 0.7
		TweenService:Create(ipucuYazi, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
	end
end)

local hedefYuzde = 0
local gorunenYuzde = 0
local zaman = 0
local paralaks = Vector2.zero

local basladi = os.clock()

local function gecenSure(): number
	return os.clock() - basladi
end

local function ilerle(deger: number)
	hedefYuzde = math.clamp(math.max(deger, hedefYuzde), 0, 1)
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
	yuzdeYazi.Text = `{math.floor(gorunenYuzde * 100)}%`
	parlamaGecis.Offset = Vector2.new((zaman * 0.7) % 2 - 1, 0)

	local ton = (zaman * 0.08) % 1
	dolguGecis.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHSV(ton, 0.7, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromHSV((ton + 0.15) % 1, 0.7, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV((ton + 0.3) % 1, 0.7, 1)),
	})

	for _, r in renkliler do
		r.nesne.BackgroundColor3 = Color3.fromHSV((ton + r.kayma) % 1, 0.7, 1)
	end
	huzmelerBuyuk.Rotation = (zaman * 9) % 360
	huzmelerKucuk.Rotation = (-zaman * 14) % 360
	for sira, hale in haleler do
		local oran = HALE_ORANLARI[sira] * (1 + math.sin(zaman * 2 + sira) * 0.04)
		hale.Size = UDim2.fromScale(oran, oran * 0.62)
	end

	local salinim = math.sin(zaman * 1.6)
	logo.Rotation = salinim * 1.2
	local kayma = Vector2.new(0, math.sin(zaman * 1.3) * 6)

	if UserInputService.MouseEnabled and not UserInputService.TouchEnabled then
		local kamera = Workspace.CurrentCamera
		local v = if kamera then kamera.ViewportSize else Vector2.zero
		if v.X > 0 and v.Y > 0 then
			local fare = UserInputService:GetMouseLocation()
			local hedefKayma = Vector2.new((fare.X / v.X - 0.5) * -2 * PARALAKS, (fare.Y / v.Y - 0.5) * -2 * PARALAKS)
			paralaks = paralaks:Lerp(hedefKayma, math.min(1, dt * 3))
		end
	end
	logo.Position = UDim2.new(0.5, paralaks.X + kayma.X, 0, logoMerkezi.Y + paralaks.Y + kayma.Y)

	local isikT = math.min((zaman % 2.6) / 0.9, 1)
	local isikKonumu = UDim2.new(-0.3 + isikT * 1.6, 0, 0.5, 0)
	oyna.isik.Position = isikKonumu
	atlaD.isik.Position = isikKonumu
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

	oyna.tus.Visible = oynaAktif and tur == "gamepad"
	oyna.tusYazi.Text = if tur == "gamepad" then "A" else "ENTER"
	oyna.tus.Size = UDim2.fromOffset(if tur == "gamepad" then 24 else 48, 22)

	atlaD.tus.Visible = tur == "gamepad" and not atlaIstendi
	atlaD.tusYazi.Text = "X"
	atlaD.tus.Size = UDim2.fromOffset(24, 22)
end

local girisBagi = UserInputService.LastInputTypeChanged:Connect(tusIpuclari)

local function kamerayiBirak()
	pcall(function()
		RunService:UnbindFromRenderStep(KAMERA_EYLEMI)
	end)

	local kamera = Workspace.CurrentCamera
	if not kamera then
		return
	end
	kamera.CameraType = Enum.CameraType.Custom
	local karakter = player.Character
	local insan = karakter and karakter:FindFirstChildOfClass("Humanoid")
	if insan then
		kamera.CameraSubject = insan
	end
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
	arayuzGeriAc()
	kamerayiBirak()

	local netles = TweenService:Create(
		bulaniklik,
		TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = 0 }
	)
	netles.Completed:Connect(function()
		bulaniklik:Destroy()
	end)
	netles:Play()

	TweenService
		:Create(kayan, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.fromOffset(0, 70) })
		:Play()
	TweenService:Create(logoOlcek, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 1.15 }):Play()

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

local function dugmeGoster(d: Dugme)
	d.kap.Visible = true
	solukluk(d.kap, 1, 0)
	solukluk(d.kap, 0, 0.3)
	d.olcek.Scale = 0.85
	TweenService:Create(d.olcek, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

local function atlaGizle()
	if not atlaD.kap.Visible then
		return
	end
	ContextActionService:UnbindAction(ATLA_EYLEMI)
	atlaD.kap.Visible = false
end

local function atla()
	if atlaIstendi or kapandi then
		return
	end
	atlaIstendi = true
	enAzGorunme = 0

	ContextActionService:UnbindAction(ATLA_EYLEMI)

	atlaD.yazi.Text = "JOINING..."
	atlaD.tus.Visible = false
	solukluk(atlaD.kap, 0.4, 0.2)

	if hazirlandi then
		task.spawn(kapat)
	end
end

local function atlaGoster()
	if afkDonusu or hazirlandi or kapandi or atlaIstendi then
		return
	end

	dugmeGoster(atlaD)
	tusIpuclari()

	ContextActionService:BindAction(ATLA_EYLEMI, function(_, durum)
		if durum == Enum.UserInputState.Begin then
			atla()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonX)
end

local function hazirGorunumu()
	oynaAktif = true

	atlaGizle()
	dugmeGoster(oyna)
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

	ilerle(1)

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

local function dugmeTepkisi(d: Dugme, kosul: () -> boolean)
	d.dugme.MouseEnter:Connect(function()
		if kosul() then
			TweenService:Create(d.olcek, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.06 }):Play()
		end
	end)
	d.dugme.MouseLeave:Connect(function()
		TweenService:Create(d.olcek, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)
	d.dugme.MouseButton1Down:Connect(function()
		if kosul() then
			TweenService:Create(d.olcek, TweenInfo.new(0.08), { Scale = 0.96 }):Play()
		end
	end)
	d.dugme.MouseButton1Up:Connect(function()
		if kosul() then
			TweenService:Create(d.olcek, TweenInfo.new(0.12), { Scale = 1.06 }):Play()
		end
	end)
end

dugmeTepkisi(oyna, function()
	return oynaAktif and not kapandi
end)

dugmeTepkisi(atlaD, function()
	return not atlaIstendi and not kapandi
end)

oyna.dugme.Activated:Connect(function()
	if oynaAktif then
		task.spawn(kapat)
	end
end)

atlaD.dugme.Activated:Connect(atla)

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
	ilerle(0.05)

	local kok = ReplicatedStorage:WaitForChild("Assets", 15)
	if not kok then
		ilerle(0.6)
		return
	end

	ilerle(0.12)

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
		ilerle(0.6)
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
			ilerle(0.12 + (islenen / #liste) * 0.63)
		end
	end
end

local function tabanAyarla(nesne: Instance, ozellik: string, deger: number)
	local kayit = tabanlar[nesne]
	if kayit then
		kayit[ozellik] = deger
	end
	(nesne :: any)[ozellik] = deger
end

local function dilimResim(ad: string, ebeveyn: Instance, kimlik: string, kesit: Rect, olcek: number, z: number): ImageLabel
	local resim = Instance.new("ImageLabel")
	resim.Name = ad
	resim.BackgroundTransparency = 1
	resim.Size = UDim2.fromScale(1, 1)
	resim.Image = kimlik
	resim.ScaleType = Enum.ScaleType.Slice
	resim.SliceCenter = kesit
	resim.SliceScale = olcek
	resim.ZIndex = z
	resim.Parent = ebeveyn
	return resim
end

local function gorselleriUygula(G: any)
	local D = G.Dugme
	local C = G.Cubuk

	local function dugmeGorseli(d: Dugme, kimlik: string, ton: Color3)
		if kimlik == "" then
			return
		end
		tabanAyarla(d.dugme, "BackgroundTransparency", 1)
		d.gecis.Enabled = false
		local cizgi = d.dugme:FindFirstChildOfClass("UIStroke")
		if cizgi then
			cizgi.Enabled = false
		end
		local parlak = d.dugme:FindFirstChild("Parlak")
		if parlak and parlak:IsA("GuiObject") then
			parlak.Visible = false
		end
		local resim = dilimResim("Gorsel", d.dugme, kimlik, D.kareKesit, dugmeKap.Size.Y.Offset / D.boy, 1)
		resim.ImageColor3 = ton
		d.yazi.Size = UDim2.fromScale(1, 1 - D.dudakOrani)

		local maske = Instance.new("CanvasGroup")
		maske.Name = "IsikMaskesi"
		maske.BackgroundTransparency = 1
		maske.BorderSizePixel = 0
		maske.Position = UDim2.new(0, 4, D.yuzUst, 0)
		maske.Size = UDim2.new(1, -8, D.yuzBoy, 0)
		maske.ZIndex = d.isik.ZIndex
		maske.Parent = d.dugme
		local maskeKosesi = Instance.new("UICorner")
		maskeKosesi.CornerRadius = UDim.new(0.5, 0)
		maskeKosesi.Parent = maske
		d.isik.Parent = maske
	end

	dugmeGorseli(oyna, D.renkler.mavi, BEYAZ)
	dugmeGorseli(atlaD, D.renkler.gri, Color3.fromRGB(150, 160, 190))

	if C.cerceve ~= "" then
		tabanAyarla(cubuk, "BackgroundTransparency", 1)
		local cizgi = cubuk:FindFirstChildOfClass("UIStroke")
		if cizgi then
			cizgi.Enabled = false
		end
		local k = cubuk.Size.Y.Offset / C.cerceveIcBoy
		local kesit = Rect.new(C.cerceveKapak, C.cerceveIcUst, C.cerceveEn - C.cerceveKapak, C.cerceveIcUst + C.cerceveIcBoy)
		local resim = dilimResim("Cerceve", cubuk, C.cerceve, kesit, k, 0)
		resim.Position = UDim2.fromOffset(-C.cerceveIcSol * k, -C.cerceveIcUst * k)
		resim.Size = UDim2.new(1, C.cerceveIcSol * k * 2, 0, C.cerceveBoy * k)
	end

	if C.dolgu ~= "" then
		tabanAyarla(dolgu, "BackgroundTransparency", 1)
		local kesit = Rect.new(C.dolguKapak, 40, C.dolguEn - C.dolguKapak, 77)
		local resim = dilimResim("Gorsel", dolgu, C.dolgu, kesit, cubuk.Size.Y.Offset / C.dolguBoy, 1)
		dolguGecis.Parent = resim
	end

	if D.renkler.altin ~= "" then
		tabanAyarla(ipucuEtiket, "BackgroundTransparency", 1)
		dilimResim("Gorsel", ipucuEtiket, D.renkler.altin, D.kareKesit, ipucuEtiket.Size.Y.Offset / D.boy, 1)
	end
end

task.spawn(function()
	local paylasilan = ReplicatedStorage:WaitForChild("Shared", 30)
	local modul = paylasilan and paylasilan:WaitForChild("ArayuzGorselleri", 30)
	if not modul or not modul:IsA("ModuleScript") or kapandi then
		return
	end
	local ok, G = pcall(require, modul)
	if ok and type(G) == "table" then
		gorselleriUygula(G)
	end
end)

solukluk(kayan, 1, 0)
kayan.Position = UDim2.fromOffset(0, 40)

task.defer(function()
	TweenService
		:Create(kayan, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0) })
		:Play()
	solukluk(yuzdeSirasi, 0, 0.5)
	solukluk(ipucuSirasi, 0, 0.5)
end)

task.delay(ATLA_GECIKMESI, atlaGoster)
task.delay(EN_COK_BEKLEME, hazirOl)

task.spawn(function()
	local ok, hata = pcall(varliklariYukle)
	if not ok then
		warn(`[YuklemeEkrani] Assets failed to preload: {tostring(hata)}`)
	end

	ilerle(0.8)

	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	ilerle(0.88)
	player:WaitForChild("leaderstats", 15)

	ilerle(0.94)

	if not player.Character then
		player.CharacterAdded:Wait()
	end

	hazirOl()
end)
