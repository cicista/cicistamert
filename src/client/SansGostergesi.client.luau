--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Icons = require(Shared:WaitForChild("Icons"))

local UI = require(script.Parent:WaitForChild("UI"))

local NITELIK = "SansCarpani"
local AYRINTI = "SansAyrinti"
local GECICI = "SansGeciciBitis"

local YESIL_ACIK = Color3.fromRGB(190, 255, 150)
local YESIL = Color3.fromRGB(80, 230, 110)
local YESIL_KOYU = Color3.fromRGB(25, 150, 70)
local KONTUR = Color3.fromRGB(8, 45, 20)
local SARI = Color3.fromRGB(255, 220, 90)

local menuler = playerGui:WaitForChild("OyunMenuleri")
local kutu = menuler:WaitForChild("RotGostergesi") :: Frame

local yukseklik = tonumber(kutu:GetAttribute("SansSatiri")) or 54
local ikonBoyu = yukseklik - 8

local ikon = Instance.new("ImageLabel")
ikon.Name = "SansIkon"
ikon.BackgroundTransparency = 1
ikon.AnchorPoint = Vector2.new(0.5, 0.5)
ikon.Position = UDim2.fromOffset(34, yukseklik / 2)
ikon.Size = UDim2.fromOffset(ikonBoyu, ikonBoyu)
ikon.ScaleType = Enum.ScaleType.Fit
ikon.Parent = kutu

local yedek = UI.text({
	text = "\u{1F340}",
	size = math.floor(ikonBoyu * 0.7),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = ikon,
	outline = false,
})
Icons.bind(ikon, "luck1", function(ok)
	if ok then
		yedek.Visible = false
	end
end)

local ikonOlcek = Instance.new("UIScale")
ikonOlcek.Parent = ikon

local yazi = UI.text({
	text = "x1",
	size = 40,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	align = Enum.TextXAlignment.Left,
	outline = false,
	frameSize = UDim2.new(0, 0, 0, yukseklik),
	position = UDim2.fromOffset(76, 0),
	parent = kutu,
	name = "SansYazi",
})
yazi.AutomaticSize = Enum.AutomaticSize.X

local gecis = Instance.new("UIGradient")
gecis.Rotation = 90
gecis.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, YESIL_ACIK),
	ColorSequenceKeypoint.new(0.5, YESIL),
	ColorSequenceKeypoint.new(1, YESIL_KOYU),
})
gecis.Parent = yazi

local kontur = UI.stroke(yazi, KONTUR, 4)
kontur.LineJoinMode = Enum.LineJoinMode.Round

local yaziOlcek = Instance.new("UIScale")
yaziOlcek.Parent = yazi

local sure = UI.text({
	text = "",
	size = 20,
	font = UI.Fonts.bold,
	color = SARI,
	align = Enum.TextXAlignment.Left,
	frameSize = UDim2.fromOffset(120, yukseklik),
	position = UDim2.fromOffset(84, 0),
	parent = kutu,
	name = "SansSuresi",
})
sure.Visible = false

local dugme = Instance.new("TextButton")
dugme.Name = "SansDugmesi"
dugme.BackgroundTransparency = 1
dugme.Text = ""
dugme.Size = UDim2.fromOffset(300, yukseklik)
dugme.ZIndex = 5
dugme.Parent = kutu

local balon = Instance.new("Frame")
balon.Name = "SansBalonu"
balon.AnchorPoint = Vector2.new(0, 1)
balon.Position = UDim2.fromOffset(12, -6)
balon.Size = UDim2.fromOffset(250, 0)
balon.AutomaticSize = Enum.AutomaticSize.Y
balon.BackgroundColor3 = Color3.fromRGB(18, 30, 22)
balon.BackgroundTransparency = 0.08
balon.BorderSizePixel = 0
balon.Visible = false
balon.ZIndex = 20
balon.Parent = kutu
UI.corner(balon, 12)
UI.stroke(balon, YESIL, 2)

local balonPay = Instance.new("UIPadding")
balonPay.PaddingTop = UDim.new(0, 8)
balonPay.PaddingBottom = UDim.new(0, 8)
balonPay.PaddingLeft = UDim.new(0, 12)
balonPay.PaddingRight = UDim.new(0, 12)
balonPay.Parent = balon

local balonDuzen = Instance.new("UIListLayout")
balonDuzen.SortOrder = Enum.SortOrder.LayoutOrder
balonDuzen.Padding = UDim.new(0, 2)
balonDuzen.Parent = balon

local function carpanYazisi(deger: number): string
	if deger >= 1000 then
		return `x{Format.short(deger)}`
	end
	local metin = if deger >= 10 then string.format("%.1f", deger) else string.format("%.2f", deger)
	metin = string.gsub(metin, "0+$", "")
	metin = string.gsub(metin, "%.$", "")
	return `x{metin}`
end

local function satir(metin: string, renk: Color3, sira: number)
	local etiket = UI.text({
		text = metin,
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = renk,
		align = Enum.TextXAlignment.Left,
		frameSize = UDim2.new(1, 0, 0, 20),
		parent = balon,
	})
	etiket.LayoutOrder = sira
	etiket.ZIndex = 21
end

local function balonuDoldur()
	for _, cocuk in balon:GetChildren() do
		if cocuk:IsA("TextLabel") then
			cocuk:Destroy()
		end
	end

	local toplam = tonumber(player:GetAttribute(NITELIK)) or 1
	satir(`TOTAL LUCK  {carpanYazisi(toplam)}`, SARI, 0)

	local ayrinti = player:GetAttribute(AYRINTI)
	local sira = 1
	if type(ayrinti) == "string" and ayrinti ~= "" then
		for _, parca in string.split(ayrinti, "|") do
			satir(parca, Color3.fromRGB(220, 240, 225), sira)
			sira += 1
		end
	else
		satir("No luck boosts yet", Color3.fromRGB(180, 190, 185), sira)
	end
end

local function balonAc(acik: boolean)
	if acik then
		balonuDoldur()
	end
	balon.Visible = acik
end

dugme.MouseEnter:Connect(function()
	balonAc(true)
end)
dugme.MouseLeave:Connect(function()
	balonAc(false)
end)
dugme.Activated:Connect(function()
	if UI.Girdi.dokunmatik() then
		balonAc(not balon.Visible)
	end
end)

local sonDeger = 0

local function zipla(guc: number)
	yaziOlcek.Scale = guc
	ikonOlcek.Scale = guc
	local bilgi = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(yaziOlcek, bilgi, { Scale = 1 }):Play()
	TweenService:Create(ikonOlcek, bilgi, { Scale = 1 }):Play()
end

local function guncelle()
	local deger = tonumber(player:GetAttribute(NITELIK)) or 1
	yazi.Text = carpanYazisi(deger)
	if sonDeger > 0 and deger > sonDeger + 1e-6 then
		zipla(1.18)
	end
	sonDeger = deger
	if balon.Visible then
		balonuDoldur()
	end
end

local function sureyiYerlestir()
	sure.Position = UDim2.fromOffset(76 + yazi.AbsoluteSize.X / math.max(UI.nesneCarpani(kutu), 0.01) + 10, 0)
end

player:GetAttributeChangedSignal(NITELIK):Connect(guncelle)
player:GetAttributeChangedSignal(AYRINTI):Connect(function()
	if balon.Visible then
		balonuDoldur()
	end
end)
yazi:GetPropertyChangedSignal("AbsoluteSize"):Connect(sureyiYerlestir)
guncelle()
sureyiYerlestir()

task.spawn(function()
	while true do
		local bitis = tonumber(player:GetAttribute(GECICI)) or 0
		local kalan = bitis - Workspace:GetServerTimeNow()
		if kalan > 0 then
			local s = math.floor(kalan)
			sure.Text = string.format("%d:%02d", s // 60, s % 60)
			sure.Visible = true
		else
			sure.Visible = false
		end
		task.wait(0.5)
	end
end)
