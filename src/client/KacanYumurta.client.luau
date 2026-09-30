--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("KacanYumurta"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))
local BrainrotOnizleme = require(script.Parent:WaitForChild("BrainrotOnizleme"))

local Teklif = Net.event("KacanYumurtaTeklif")
local RobuxUrunAl = Net.event("RobuxUrunAl")

local KIRMIZI = Color3.fromRGB(255, 70, 70)
local SARI = Color3.fromRGB(255, 205, 60)
local YESIL = Color3.fromRGB(70, 210, 90)
local SIYAH = Color3.new(0, 0, 0)

local ACILIS_GECIKMESI = 0.4
local SON_SANIYELER = 5

local screen = Instance.new("ScreenGui")
screen.Name = "KacanYumurta"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.DisplayOrder = 30
screen.Parent = playerGui

local panel = UI.panel(screen, UDim2.fromOffset(400, 410), "KacanYumurta")

local baslik = UI.text({
	text = "TIME'S TICKING!",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = KIRMIZI,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -40, 0, 36),
	position = UDim2.fromOffset(20, 14),
	parent = panel,
})
local baslikOlcek = Instance.new("UIScale")
baslikOlcek.Parent = baslik
TweenService:Create(
	baslikOlcek,
	TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Scale = 1.1 }
):Play()

local altBaslik = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -40, 0, 24),
	position = UDim2.fromOffset(20, 52),
	parent = panel,
})

UI.closeButton(panel).MouseButton1Click:Connect(function()
	panel.Visible = false
end)

local yuva = Instance.new("Frame")
yuva.Name = "Yumurta"
yuva.AnchorPoint = Vector2.new(0.5, 0)
yuva.Position = UDim2.new(0.5, 0, 0, 82)
yuva.Size = UDim2.fromOffset(130, 130)
yuva.BackgroundTransparency = 1
yuva.ZIndex = 3
yuva.Parent = panel
local parlama = UI.parlama(yuva, KIRMIZI, 150, 2)
local onizleme = BrainrotOnizleme.seritPencere(panel)

TweenService:Create(
	yuva,
	TweenInfo.new(0.07, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Rotation = 4 }
):Play()

local sayac = UI.text({
	text = "",
	size = UI.Sizes.huge,
	font = UI.Fonts.bold,
	color = SARI,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -40, 0, 44),
	position = UDim2.fromOffset(20, 218),
	parent = panel,
})

local cubukZemin = Instance.new("Frame")
cubukZemin.Name = "Sure"
cubukZemin.Position = UDim2.fromOffset(30, 266)
cubukZemin.Size = UDim2.new(1, -60, 0, 16)
cubukZemin.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
cubukZemin.BorderSizePixel = 0
cubukZemin.Parent = panel
UI.corner(cubukZemin, 8)
UI.stroke(cubukZemin, SIYAH, 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local cubuk = Instance.new("Frame")
cubuk.Name = "Dolgu"
cubuk.Size = UDim2.fromScale(1, 1)
cubuk.BackgroundColor3 = YESIL
cubuk.BorderSizePixel = 0
cubuk.Parent = cubukZemin
UI.corner(cubuk, 8)

local uyari = UI.text({
	text = "Don't miss it! This offer won't come back.",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -40, 0, 20),
	position = UDim2.fromOffset(20, 290),
	parent = panel,
})

local alDugme, alYuz = UI.dugme3B(panel, nil, UDim2.fromOffset(250, 64), YESIL, false)
alDugme.Name = "Al"
alDugme.AnchorPoint = Vector2.new(0.5, 1)
alDugme.Position = UDim2.new(0.5, 0, 1, -18)

local icerik = Instance.new("Frame")
icerik.Name = "Icerik"
icerik.AnchorPoint = Vector2.new(0.5, 0.5)
icerik.Position = UDim2.fromScale(0.5, 0.5)
icerik.Size = UDim2.fromScale(1, 1)
icerik.BackgroundTransparency = 1
icerik.ZIndex = (alYuz.ZIndex or 1) + 1
icerik.Parent = alYuz

local dizilim = Instance.new("UIListLayout")
dizilim.FillDirection = Enum.FillDirection.Horizontal
dizilim.HorizontalAlignment = Enum.HorizontalAlignment.Center
dizilim.VerticalAlignment = Enum.VerticalAlignment.Center
dizilim.Padding = UDim.new(0, 10)
dizilim.SortOrder = Enum.SortOrder.LayoutOrder
dizilim.Parent = icerik

local alYazi = UI.text({
	text = "CATCH IT!",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromOffset(0, 40),
	parent = icerik,
	zIndex = icerik.ZIndex + 1,
})
alYazi.AutomaticSize = Enum.AutomaticSize.X
alYazi.TextTruncate = Enum.TextTruncate.None
alYazi.LayoutOrder = 1

local fiyatKutusu = UI.robuxFiyati(icerik, Ayar.Fiyat, UI.Sizes.heading, icerik.ZIndex + 1)
fiyatKutusu.LayoutOrder = 2

local dugmeOlcek = Instance.new("UIScale")
dugmeOlcek.Parent = alDugme
TweenService:Create(
	dugmeOlcek,
	TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Scale = 1.06 }
):Play()

alDugme.MouseButton1Click:Connect(function()
	RobuxUrunAl:FireServer(Ayar.UrunAnahtari)
end)

local bitis = 0
local toplamSure = Ayar.Sure
local surum = 0
local baglanti: RBXScriptConnection? = nil

local function durdur()
	if baglanti then
		baglanti:Disconnect()
		baglanti = nil
	end
end

local function tik()
	local kalan = math.max(0, bitis - os.clock())
	local oran = if toplamSure > 0 then kalan / toplamSure else 0

	cubuk.Size = UDim2.fromScale(oran, 1)
	cubuk.BackgroundColor3 = if oran > 0.5
		then YESIL:Lerp(SARI, (1 - oran) * 2)
		else SARI:Lerp(KIRMIZI, (0.5 - oran) * 2)

	local sonAn = kalan <= SON_SANIYELER
	sayac.Text = `{math.ceil(kalan)}s`
	sayac.TextColor3 = if sonAn then KIRMIZI else SARI
	sayac.Rotation = if sonAn then math.sin(os.clock() * 40) * 4 else 0
	uyari.Text = if sonAn then "LAST CHANCE! It's almost gone!" else "Don't miss it! This offer won't come back."
	uyari.TextColor3 = if sonAn then KIRMIZI else UI.Colors.textDim

	if kalan <= 0 then
		panel.Visible = false
	end
end

panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if not panel.Visible then
		durdur()
		onizleme.temizle()
	end
end)

Teklif.OnClientEvent:Connect(function(veri)
	surum += 1
	local benim = surum

	if type(veri) ~= "table" or type(veri.rarity) ~= "string" then
		panel.Visible = false
		return
	end

	local rarityId: string = veri.rarity
	toplamSure = tonumber(veri.sure) or Ayar.Sure
	bitis = os.clock() + toplamSure

	task.wait(ACILIS_GECIKMESI)
	if benim ~= surum then
		return
	end

	local renk = Rarity.color(rarityId)
	altBaslik.Text = `Your {Rarity.displayName(rarityId)} Egg got away!`
	altBaslik.TextColor3 = renk
	UI.rarityStyle(altBaslik, rarityId)
	for _, halka in parlama:GetChildren() do
		if halka:IsA("Frame") then
			halka.BackgroundColor3 = renk
		end
	end

	onizleme.temizle()
	onizleme.ekle(yuva, { revealed = false, rarity = rarityId })

	durdur()
	tik()
	panel.Visible = true
	baglanti = RunService.Heartbeat:Connect(tik)
end)
