--[[
	MadenSayaci  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > MadenSayaci

	MADENLI BIR ADANIN KUMUNUN USTUNDEYKEN o adanin uc madeninden kac tane
	oldugunu sagdaki isinlayici (Teleporter) ikonunun hemen ustunde
	gosterir.

	    Candy Island    Amethyst / Opal / Morganite
	    Snow Island     Sapphire / Lapis / Quartz
	    Volcano Island  Ruby / Obsidian / Basalt

	Main Island'da ve denizde hicbir sey gorunmez.

	HANGI ADA
	Ayagin altindaki ZEMININ ADINA bakilir: sekerkum -> Candy, snowkum ->
	Snow, alevkum -> Volcano. Once ada modelinin kutusuna bakiliyordu;
	kutular birbirine tastigi icin sayac yanlis adada cikiyordu (bug).
	Ziplarken kaybolmasin diye kumdan ayrildiktan sonra kisa bir sure
	daha gorunur kalir.

	Sayilar sunucunun gonderdigi envanterden gelir (EnvanterGuncelle.ores).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Ores = require(Shared:WaitForChild("Ores"))
local Icons = require(Shared:WaitForChild("Icons"))

local UI = require(script.Parent:WaitForChild("UI"))

local EnvanterGuncelle = Net.event("EnvanterGuncelle")

-- Zemin kontrolu sikligi (saniye)
local KONTROL_ARASI = 0.25
-- Kumdan ayrildiktan (ziplama, kazi) sonra sayac bu kadar saniye daha kalir
local KUMSUZ_BEKLEME = 1.5
-- Ayagin altina kac stud isin atilir (Config.Sand.rayDepth ile ayni)
local ISIN_BOYU = 12

-- Kutunun ayarlar ikonuna olan dikey boslugu
local IKON_BOSLUK = 8

-- Ikon + sayi satiri; ikon buyudugu icin 24'ten 34'e cikti
local SATIR_BOY = 34

------------------------------------------------------------------
-- ARAYUZ
------------------------------------------------------------------
local screen = Instance.new("ScreenGui")
screen.Name = "MadenSayaci"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local kutu = Instance.new("Frame")
kutu.Name = "Kutu"
-- Sag alt kose ikonun sag ust kosesine oturur
kutu.AnchorPoint = Vector2.new(1, 1)
-- Yalnizca ikon + "x12": eski 176'lik panel genisligine gerek yok
kutu.Size = UDim2.fromOffset(96, SATIR_BOY * 3 + 16)
kutu.Position = UDim2.new(1, -20, 1, -120)
--[[
	POP-UP GORUNUMU YOK

	Once koyu zeminli, ada renginde cerceveli bir paneldi. Artik zemin ve
	cerceve yok: ekranda yalnizca madenin ikonu ve yaninda sayisi durur.
]]
kutu.BackgroundTransparency = 1
kutu.BorderSizePixel = 0
kutu.Visible = false
kutu.Parent = screen

local ic = Instance.new("Frame")
ic.Name = "Ic"
ic.Size = UDim2.fromScale(1, 1)
ic.BackgroundTransparency = 1
ic.Parent = kutu
UI.padding(ic, 8)

local duzen = Instance.new("UIListLayout")
duzen.Padding = UDim.new(0, 0)
duzen.SortOrder = Enum.SortOrder.LayoutOrder
duzen.Parent = ic

type Satir = { nokta: Frame, ikon: ImageLabel, yazi: TextLabel }
local satirlar: { Satir } = {}

for i = 1, 3 do
	local satir = Instance.new("Frame")
	satir.Name = `Satir{i}`
	satir.Size = UDim2.new(1, 0, 0, SATIR_BOY)
	satir.BackgroundTransparency = 1
	satir.LayoutOrder = i
	satir.Parent = ic

	-- Gemin renginde kucuk bir baklava: maden bir bakista taninsin
	local nokta = Instance.new("Frame")
	nokta.Name = "Gem"
	nokta.AnchorPoint = Vector2.new(0.5, 0.5)
	nokta.Position = UDim2.new(0, 14, 0.5, 0)
	nokta.Size = UDim2.fromOffset(14, 14)
	nokta.Rotation = 45
	nokta.BorderSizePixel = 0
	nokta.Parent = satir
	UI.stroke(nokta, Color3.fromRGB(0, 0, 0), 1.5)

	--[[
		MADEN IKONU  (Assets > Icons)

		Baklavanin yerini aliyor. Ikon gelene kadar ya da bulunamazsa
		baklava gorunur kalir -- satir hicbir durumda isaretsiz kalmaz.
	]]
	local ikon = Instance.new("ImageLabel")
	ikon.Name = "Ikon"
	ikon.AnchorPoint = Vector2.new(0.5, 0.5)
	ikon.Position = UDim2.new(0, 14, 0.5, 0)
	ikon.Size = UDim2.fromOffset(28, 28)
	ikon.BackgroundTransparency = 1
	ikon.ScaleType = Enum.ScaleType.Fit
	ikon.Image = ""
	ikon.Parent = satir
	ikon:GetPropertyChangedSignal("Image"):Connect(function()
		nokta.Visible = ikon.Image == ""
	end)

	-- Zemin kalktigi icin sayi kendi konturuyla (UI.text varsayilani) okunuyor
	local yazi = UI.text({
		text = "",
		size = UI.Sizes.label,
		font = UI.Fonts.bold,
		frameSize = UDim2.new(1, -34, 1, 0),
		position = UDim2.fromOffset(34, 0),
		parent = satir,
		name = "Yazi",
	})

	table.insert(satirlar, { nokta = nokta, ikon = ikon, yazi = yazi })
end

------------------------------------------------------------------
-- VERI
------------------------------------------------------------------
local sayilar: { [string]: number } = {}
local mevcutAda: string? = nil

local function yaz()
	local cfg = if mevcutAda then Ores.Islands[mevcutAda] else nil
	if not cfg then
		kutu.Visible = false
		return
	end

	for i, id in cfg.ores do
		local satir = satirlar[i]
		local info = Ores.Info[id]
		if satir and info then
			satir.nokta.BackgroundColor3 = info.color
			-- Ada degisince ayni satira baska madenin ikonu baglanir
			Icons.bind(satir.ikon, `ore_{id}`)
			-- Ad yazmiyor: maden ikonundan taniniyor, yaninda yalnizca adet
			satir.yazi.Text = `x{sayilar[id] or 0}`
		end
	end

	kutu.Visible = true
end

EnvanterGuncelle.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and type(payload.ores) == "table" then
		sayilar = payload.ores
		yaz()
	end
end)

------------------------------------------------------------------
-- ADA TESPITI  --  yalnizca adanin KUMU
------------------------------------------------------------------
-- Zemin parcasi adi (kucuk harf) -> madenli ada kimligi
local KUM_ADI: { [string]: string } = {
	sekerkum = "sekerkum",
	sakizkum = "sekerkum",
	snowkum = "snowkum",
	buzkum = "snowkum",
	alevkum = "alevkum",
	volkankum = "alevkum",
}

local isinAyari = RaycastParams.new()
isinAyari.FilterType = Enum.RaycastFilterType.Exclude

-- Ayagin altindaki kum hangi madenli adanin; kum degilse nil
local function kumdanAda(konum: Vector3): string?
	isinAyari.FilterDescendantsInstances = { player.Character :: Instance }

	local hit = Workspace:Raycast(konum, Vector3.new(0, -ISIN_BOYU, 0), isinAyari)
	if not hit then
		return nil
	end

	-- Kum bir model/klasor icinde parcalardan olusuyor olabilir: iki ust kademeye de bakilir
	local node: Instance? = hit.Instance
	for _ = 1, 3 do
		if not node or node == Workspace then
			break
		end
		local ada = KUM_ADI[string.lower(node.Name)]
		if ada then
			return ada
		end
		node = node.Parent
	end

	return nil
end

local sonKum = -math.huge
local sonAda: string? = nil

task.spawn(function()
	while true do
		task.wait(KONTROL_ARASI)

		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local kum = if root and root:IsA("BasePart") then kumdanAda(root.Position) else nil

		local simdi = os.clock()
		if kum then
			sonKum = simdi
			sonAda = kum
		end
		local ada = if kum then kum elseif simdi - sonKum < KUMSUZ_BEKLEME then sonAda else nil

		if ada ~= mevcutAda then
			mevcutAda = ada
			yaz()
		end
	end
end)

------------------------------------------------------------------
-- ISINLAYICI IKONUNUN USTUNE YERLESTIRME
--
-- Ikon Menuler'in kurdugu "SagMenu" sutununda "Teleporter" adiyla duruyor
-- (yoksa eskisi gibi "Settings").
-- Konumu arayuz olcegiyle degisebildigi icin her karede okunuyor; kutu
-- gorunmuyorken hic hesap yapilmaz.
------------------------------------------------------------------
local ayarButonu: GuiObject? = nil

local function butonuBul(): GuiObject?
	if ayarButonu and ayarButonu.Parent then
		return ayarButonu
	end

	local menu = playerGui:FindFirstChild("OyunMenuleri")
	local sutun = menu and menu:FindFirstChild("SagMenu", true)
	local buton = sutun and (sutun:FindFirstChild("Teleporter", true) or sutun:FindFirstChild("Settings", true))

	if menu and menu:IsA("ScreenGui") then
		-- Ayni ust bosluk kurali: yoksa kutu ikona gore kayar
		screen.IgnoreGuiInset = menu.IgnoreGuiInset
	end

	ayarButonu = if buton and buton:IsA("GuiObject") then buton else nil
	return ayarButonu
end

RunService.RenderStepped:Connect(function()
	if not kutu.Visible then
		return
	end

	local buton = butonuBul()
	if not buton then
		return
	end

	local konum = buton.AbsolutePosition
	local boyut = buton.AbsoluteSize
	kutu.Position = UDim2.fromOffset(konum.X + boyut.X, konum.Y - IKON_BOSLUK)
end)

--[[
	Assets > Icons eslesmesini Output'a bir kez yaz: adi tutmayan ikon varsa
	hangisi oldugu hemen gorulsun. Klasor replike olsun diye biraz bekleniyor.
]]
task.delay(8, Icons.assetRaporu)
