--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Unvanlar = require(Shared:WaitForChild("Unvanlar"))

local UI = require(script.Parent:WaitForChild("UI"))
local KademeEfekti = require(script.Parent:WaitForChild("KademeEfekti"))

local UnvanDurum = Net.event("UnvanDurum")
local UnvanAc = Net.event("UnvanAc")
local UnvanKusan = Net.event("UnvanKusan")

local BEYAZ = Color3.new(1, 1, 1)
local SIYAH = Color3.new(0, 0, 0)
local YESIL = Color3.fromRGB(70, 205, 85)
local ALTIN = Color3.fromRGB(255, 200, 40)
local GRI = Color3.fromRGB(110, 115, 130)
local MOR = Color3.fromRGB(150, 80, 255)

local SEVIYE_KADEMESI = { "Common", "Rare", "Epic", "Secret", "Cosmic", "Abyssal" }

local gokkusagilar: { [TextLabel]: boolean } = {}
local nabizlar: { [TextLabel]: UIScale } = {}

local function gokkusagiEkle(nesne: Instance)
	if nesne:IsA("TextLabel") then
		gokkusagilar[nesne] = true
	end
end

local function nabizEkle(nesne: Instance)
	if not nesne:IsA("TextLabel") then
		return
	end
	local olcek = nesne:FindFirstChild("Nabiz")
	if not olcek then
		local yeni = Instance.new("UIScale")
		yeni.Name = "Nabiz"
		yeni.Parent = nesne
		olcek = yeni
	end
	nabizlar[nesne] = olcek :: UIScale
end

for _, nesne in CollectionService:GetTagged(Unvanlar.GokkusagiEtiketi) do
	gokkusagiEkle(nesne)
end
CollectionService:GetInstanceAddedSignal(Unvanlar.GokkusagiEtiketi):Connect(gokkusagiEkle)
CollectionService:GetInstanceRemovedSignal(Unvanlar.GokkusagiEtiketi):Connect(function(nesne)
	gokkusagilar[nesne :: TextLabel] = nil
end)

for _, nesne in CollectionService:GetTagged(Unvanlar.NabizEtiketi) do
	nabizEkle(nesne)
end
CollectionService:GetInstanceAddedSignal(Unvanlar.NabizEtiketi):Connect(nabizEkle)
CollectionService:GetInstanceRemovedSignal(Unvanlar.NabizEtiketi):Connect(function(nesne)
	local olcek = nabizlar[nesne :: TextLabel]
	if olcek then
		olcek.Scale = 1
	end
	nabizlar[nesne :: TextLabel] = nil
end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()

	if next(gokkusagilar) then
		local noktalar = {}
		for i = 0, 6 do
			table.insert(noktalar, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i / 6 - t * 0.35) % 1, 0.75, 1)))
		end
		local renkler = ColorSequence.new(noktalar)
		for label in gokkusagilar do
			if not label.Parent then
				gokkusagilar[label] = nil
				continue
			end
			local g = label:FindFirstChild("Gokkusagi")
			if g and g:IsA("UIGradient") then
				g.Color = renkler
			end
		end
	end

	local olcek = 1 + math.sin(t * 4) * 0.07
	for label, uiOlcek in nabizlar do
		if not label.Parent then
			nabizlar[label] = nil
			continue
		end
		uiOlcek.Scale = olcek
	end
end)

local screen = Instance.new("ScreenGui")
screen.Name = "Rozetler"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local panel = UI.panel(screen, UDim2.fromOffset(720, 540), "Rozetler")

UI.closeButton(panel).MouseButton1Click:Connect(function()
	panel.Visible = false
end)

UI.baslikCubugu(panel, "Badges & Titles", ALTIN, MOR, "trophies")

local ust = Instance.new("Frame")
ust.Name = "Kusanilan"
ust.Position = UDim2.fromOffset(16, 72)
ust.Size = UDim2.new(1, -32, 0, 50)
ust.BackgroundColor3 = Color3.fromRGB(24, 22, 36)
ust.BorderSizePixel = 0
ust.Parent = panel
UI.corner(ust, 10)
UI.stroke(ust, SIYAH, 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Border

UI.text({
	text = "YOUR TITLE:",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = UI.Colors.textDim,
	frameSize = UDim2.fromOffset(110, 50),
	position = UDim2.fromOffset(14, 0),
	parent = ust,
})

local kusanilanYazi = UI.text({
	text = "None",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	frameSize = UDim2.new(1, -330, 1, 0),
	position = UDim2.fromOffset(120, 0),
	parent = ust,
	zIndex = 3,
})

local sayacYazi = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = ALTIN,
	align = Enum.TextXAlignment.Right,
	frameSize = UDim2.fromOffset(90, 50),
	position = UDim2.new(1, -214, 0, 0),
	parent = ust,
})

local cikarDugme = UI.dugme3B(ust, "UNEQUIP", UDim2.fromOffset(104, 38), Color3.fromRGB(220, 80, 80), false)
cikarDugme.AnchorPoint = Vector2.new(1, 0.5)
cikarDugme.Position = UDim2.new(1, -8, 0.5, 0)
cikarDugme.MouseButton1Click:Connect(function()
	UnvanKusan:FireServer("")
end)

local liste = Instance.new("ScrollingFrame")
liste.Name = "Liste"
liste.Position = UDim2.fromOffset(12, 132)
liste.Size = UDim2.new(1, -24, 1, -144)
liste.BackgroundTransparency = 1
liste.BorderSizePixel = 0
liste.ScrollBarThickness = 6
liste.CanvasSize = UDim2.new()
liste.AutomaticCanvasSize = Enum.AutomaticSize.Y
liste.Parent = panel
UI.listePayi(liste)

local izgara = Instance.new("UIGridLayout")
izgara.CellSize = UDim2.new(0.5, -8, 0, 150)
izgara.CellPadding = UDim2.fromOffset(12, 12)
izgara.SortOrder = Enum.SortOrder.LayoutOrder
izgara.Parent = liste

type Kart = {
	kart: Frame,
	cubuk: Frame,
	ilerlemeYazi: TextLabel,
	unvanYazi: TextLabel,
	dugme: TextButton,
	dugmeYazi: TextLabel?,
	kilit: TextLabel,
}

local kartlar: { [string]: Kart } = {}

for sira, rozet in Unvanlar.Liste do
	local renk = Unvanlar.SeviyeRenkleri[rozet.seviye] or BEYAZ

	local kart = Instance.new("Frame")
	kart.Name = rozet.id
	kart.LayoutOrder = sira
	kart.BackgroundColor3 = Color3.fromRGB(30, 28, 44)
	kart.BorderSizePixel = 0
	kart.Parent = liste
	UI.corner(kart, 12)
	local cizgi = UI.stroke(kart, renk, 3)
	cizgi.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	KademeEfekti.tak(kart, cizgi, renk, SEVIYE_KADEMESI[rozet.seviye], {
		aura = if rozet.seviye >= 4 then "ic" else nil,
		etkin = function()
			return panel.Visible
		end,
	})

	local seviyeYazi = UI.text({
		text = Unvanlar.SeviyeAdlari[rozet.seviye] or "",
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		color = renk,
		frameSize = UDim2.new(1, -24, 0, 16),
		position = UDim2.fromOffset(12, 8),
		parent = kart,
		zIndex = 4,
	})
	seviyeYazi.TextTransparency = 0.1

	UI.text({
		text = rozet.ad,
		size = UI.Sizes.label,
		font = UI.Fonts.bold,
		frameSize = UDim2.new(1, -24, 0, 24),
		position = UDim2.fromOffset(12, 24),
		parent = kart,
		zIndex = 4,
	})

	UI.text({
		text = Unvanlar.gereksinim(rozet),
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -24, 0, 18),
		position = UDim2.fromOffset(12, 48),
		parent = kart,
		zIndex = 4,
	})

	local cubukZemin = Instance.new("Frame")
	cubukZemin.Name = "Ilerleme"
	cubukZemin.Position = UDim2.fromOffset(12, 70)
	cubukZemin.Size = UDim2.new(1, -24, 0, 16)
	cubukZemin.BackgroundColor3 = Color3.fromRGB(16, 15, 24)
	cubukZemin.BorderSizePixel = 0
	cubukZemin.ClipsDescendants = true
	cubukZemin.ZIndex = 4
	cubukZemin.Parent = kart
	UI.corner(cubukZemin, 8)

	local cubuk = Instance.new("Frame")
	cubuk.Name = "Dolgu"
	cubuk.Size = UDim2.fromScale(0, 1)
	cubuk.BackgroundColor3 = renk
	cubuk.BorderSizePixel = 0
	cubuk.ZIndex = 5
	cubuk.Parent = cubukZemin
	UI.corner(cubuk, 8)
	UI.cubukCilasi(cubuk)

	local ilerlemeYazi = UI.text({
		text = "",
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = cubukZemin,
		zIndex = 6,
	})

	UI.text({
		text = "TITLE",
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		frameSize = UDim2.fromOffset(44, 34),
		position = UDim2.new(0, 12, 1, -44),
		parent = kart,
		zIndex = 4,
	})

	local unvanYazi = UI.text({
		text = rozet.unvan,
		size = UI.Sizes.label,
		font = UI.Fonts.bold,
		frameSize = UDim2.new(1, -184, 0, 34),
		position = UDim2.new(0, 56, 1, -44),
		parent = kart,
		zIndex = 4,
	})
	Unvanlar.stilUygula(unvanYazi, rozet.id)

	local dugme, _, dugmeYazi = UI.dugme3B(kart, "EQUIP", UDim2.fromOffset(112, 40), YESIL, false)
	dugme.AnchorPoint = Vector2.new(1, 1)
	dugme.Position = UDim2.new(1, -10, 1, -8)
	dugme.ZIndex = 5
	local rozetId = rozet.id
	dugme.MouseButton1Click:Connect(function()
		if dugme:GetAttribute("Durum") == "kusan" then
			UnvanKusan:FireServer(rozetId)
		end
	end)

	local kilit = UI.text({
		text = "LOCKED",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = GRI,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(112, 40),
		position = UDim2.new(1, -122, 1, -48),
		parent = kart,
		zIndex = 6,
	})

	kartlar[rozet.id] = {
		kart = kart,
		cubuk = cubuk,
		ilerlemeYazi = ilerlemeYazi,
		unvanYazi = unvanYazi,
		dugme = dugme,
		dugmeYazi = dugmeYazi,
		kilit = kilit,
	}
end

local function ciz(veri: any)
	local kusanilan = if type(veri.kusanilan) == "string" then veri.kusanilan else nil
	local kazanilanSayi = 0

	for _, satir in veri.rozetler or {} do
		local rozet = Unvanlar.get(satir.id)
		local k = kartlar[satir.id]
		if not rozet or not k then
			continue
		end

		local kazanildi = satir.kazanildi == true
		if kazanildi then
			kazanilanSayi += 1
		end

		local ilerleme = math.clamp(tonumber(satir.ilerleme) or 0, 0, rozet.hedef)
		local oran = if kazanildi then 1 else ilerleme / math.max(1, rozet.hedef)
		k.cubuk.Size = UDim2.fromScale(oran, 1)
		k.ilerlemeYazi.Text = if kazanildi
			then "COMPLETED!"
			elseif rozet.tur == "kademe" then "Not found yet"
			else `{Format.short(ilerleme)} / {Format.short(rozet.hedef)}`

		k.unvanYazi.TextTransparency = if kazanildi then 0 else 0.45
		k.kart.BackgroundColor3 = if kazanildi then Color3.fromRGB(38, 34, 58) else Color3.fromRGB(24, 23, 32)

		local durum = if not kazanildi then "kilitli" elseif kusanilan == satir.id then "kusanili" else "kusan"
		k.dugme:SetAttribute("Durum", durum)
		k.dugme.Visible = durum ~= "kilitli"
		k.kilit.Visible = durum == "kilitli"
		if k.dugmeYazi then
			k.dugmeYazi.Text = if durum == "kusanili" then "EQUIPPED" else "EQUIP"
		end
		UI.dugme3BRenk(k.dugme, if durum == "kusanili" then ALTIN else YESIL)
	end

	local rozet = Unvanlar.get(kusanilan)
	kusanilanYazi.Text = if rozet then rozet.unvan else "None"
	Unvanlar.stilUygula(kusanilanYazi, kusanilan)
	if not rozet then
		kusanilanYazi.TextColor3 = UI.Colors.textDim
	end
	cikarDugme.Visible = rozet ~= nil
	sayacYazi.Text = `{kazanilanSayi} / {#Unvanlar.Liste}`
end

UnvanDurum.OnClientEvent:Connect(function(veri)
	if type(veri) == "table" then
		ciz(veri)
	end
end)

panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then
		liste.CanvasPosition = Vector2.zero
		UnvanAc:FireServer()
	end
end)

task.spawn(function()
	UI.sagMenuyeEkle("trophies", "Badges", Color3.fromRGB(255, 200, 40), function()
		panel.Visible = not panel.Visible
	end)
end)

UnvanAc:FireServer()
