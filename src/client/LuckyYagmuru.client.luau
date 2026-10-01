--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))
local LuckyOnizleme = require(script.Parent:WaitForChild("LuckyOnizleme"))

local E = LuckyBlock.Event

local BEYAZ = Color3.new(1, 1, 1)
local SIYAH = Color3.new(0, 0, 0)
local ALTIN = Rarity.LuckyBlock.colorA
local TURUNCU = Color3.fromRGB(255, 140, 30)
local KIRMIZI = Color3.fromRGB(255, 70, 70)
local SON_DAKIKA = 60

if not E.enabled then
	return
end

local screen = Instance.new("ScreenGui")
screen.Name = "LuckyYagmuru"
screen.DisplayOrder = 1
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local KENAR = 12

local kap = Instance.new("Frame")
kap.Name = "Kap"
kap.AnchorPoint = Vector2.new(1, 0)
kap.Position = UDim2.new(1, -KENAR, 0, KENAR)
kap.Size = UDim2.fromOffset(250, 100)
kap.BackgroundTransparency = 1
kap.Parent = screen

local kart = Instance.new("Frame")
kart.Name = "Kart"
kart.AnchorPoint = Vector2.new(0.5, 0.5)
kart.Position = UDim2.fromScale(0.5, 0.5)
kart.Size = UDim2.fromScale(1, 1)
kart.BackgroundColor3 = BEYAZ
kart.BorderSizePixel = 0
kart.Parent = kap
UI.corner(kart, 16)
local kontur = UI.stroke(kart, SIYAH, 3)
kontur.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local zemin = Instance.new("UIGradient")
zemin.Rotation = 90
zemin.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 40, 120)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 18, 60)),
})
zemin.Parent = kart

local olcek = Instance.new("UIScale")
olcek.Parent = kart

local icAlan = Instance.new("Frame")
icAlan.Name = "Ic"
icAlan.Size = UDim2.fromScale(1, 1)
icAlan.BackgroundTransparency = 1
icAlan.ClipsDescendants = true
icAlan.Parent = kart
UI.corner(icAlan, 16)
UI.caprazDesen(icAlan, BEYAZ, 8)
UI.pariltilar(icAlan, ALTIN, 10, 2)

local isik = Instance.new("Frame")
isik.Name = "Isik"
isik.AnchorPoint = Vector2.new(0.5, 0.5)
isik.Position = UDim2.fromScale(-0.3, 0.5)
isik.Size = UDim2.new(0, 60, 2, 0)
isik.Rotation = 20
isik.BackgroundColor3 = BEYAZ
isik.BorderSizePixel = 0
isik.ZIndex = 6
isik.Parent = icAlan
do
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = isik
end
TweenService:Create(
	isik,
	TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false, 2.5),
	{ Position = UDim2.fromScale(1.3, 0.5) }
):Play()

local blokAlani = Instance.new("Frame")
blokAlani.Name = "Blok"
blokAlani.AnchorPoint = Vector2.new(0.5, 0.5)
blokAlani.Position = UDim2.fromOffset(52, 50)
blokAlani.Size = UDim2.fromOffset(86, 86)
blokAlani.BackgroundTransparency = 1
blokAlani.ZIndex = 4
blokAlani.Parent = kart

local huzmeler = UI.isikHuzmeleri(blokAlani, ALTIN, {
	sayi = 10,
	uzunluk = 80,
	kalinlik = 16,
	tur = 10,
	parlaklik = 0.3,
	zIndex = 3,
})
huzmeler.Position = UDim2.fromScale(0.5, 0.5)
local hale = UI.parlama(blokAlani, ALTIN, 96, 3)

local kaydirici = Instance.new("Frame")
kaydirici.Name = "Kaydirici"
kaydirici.AnchorPoint = Vector2.new(0.5, 0.5)
kaydirici.Position = UDim2.fromScale(0.5, 0.5)
kaydirici.Size = UDim2.fromScale(1, 1)
kaydirici.BackgroundTransparency = 1
kaydirici.ClipsDescendants = true
kaydirici.ZIndex = 5
kaydirici.Parent = blokAlani

local SLAYT_SURESI = 2.4
local KAYMA_SURESI = 0.45

local slaytlar: { { kutu: Frame, renk: Color3 } } = {}
for sira, tier in LuckyBlock.Tiers do
	local kutu = Instance.new("Frame")
	kutu.Name = tier.id
	kutu.AnchorPoint = Vector2.new(0.5, 0.5)
	kutu.Position = UDim2.fromScale(if sira == 1 then 0.5 else 1.5, 0.5)
	kutu.Size = UDim2.fromScale(1, 1)
	kutu.BackgroundTransparency = 1
	kutu.ZIndex = 5
	kutu.Parent = kaydirici
	LuckyOnizleme.ekle(kutu, tier, 6)
	table.insert(slaytlar, { kutu = kutu, renk = tier.color })
end

local function efektRengi(renk: Color3)
	for _, kap2 in { huzmeler, hale } do
		for _, parca in kap2:GetDescendants() do
			if parca:IsA("Frame") then
				TweenService:Create(parca, TweenInfo.new(KAYMA_SURESI), { BackgroundColor3 = renk }):Play()
			end
		end
	end
end

task.spawn(function()
	local simdiki = 1
	while #slaytlar > 1 do
		task.wait(SLAYT_SURESI)
		local eski = slaytlar[simdiki]
		simdiki = simdiki % #slaytlar + 1
		local yeni = slaytlar[simdiki]
		yeni.kutu.Position = UDim2.fromScale(1.5, 0.5)
		local bilgi = TweenInfo.new(KAYMA_SURESI, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(eski.kutu, bilgi, { Position = UDim2.fromScale(-0.5, 0.5) }):Play()
		TweenService:Create(yeni.kutu, bilgi, { Position = UDim2.fromScale(0.5, 0.5) }):Play()
		efektRengi(yeni.renk)
	end
end)

local baslik = UI.text({
	text = "LUCKY BLOCK RAIN",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = BEYAZ,
	glow = ALTIN,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromOffset(150, 20),
	position = UDim2.fromOffset(96, 8),
	parent = kart,
	zIndex = 7,
})

local sayac = UI.text({
	text = "--:--",
	size = 36,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromOffset(150, 40),
	position = UDim2.fromOffset(96, 28),
	parent = kart,
	zIndex = 7,
})
local sayacOlcek = Instance.new("UIScale")
sayacOlcek.Parent = sayac

local alt = UI.text({
	text = "",
	size = UI.Sizes.tiny,
	font = UI.Fonts.bold,
	color = ALTIN,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromOffset(150, 20),
	position = UDim2.fromOffset(96, 70),
	parent = kart,
	zIndex = 7,
})

local function sure(saniye: number): string
	local s = math.max(0, math.floor(saniye))
	if s >= 3600 then
		return string.format("%d:%02d:%02d", s // 3600, (s % 3600) // 60, s % 60)
	end
	return string.format("%02d:%02d", s // 60, s % 60)
end

local function nitelik(ad: string): number
	local deger = Workspace:GetAttribute(ad)
	return if type(deger) == "number" then deger else 0
end

local sonSaniye = -1

local function ekranAcik(ad: string): boolean
	local gui = playerGui:FindFirstChild(ad)
	return gui ~= nil and gui:IsA("ScreenGui") and gui.Enabled
end

local function yerlestir()
	if not UI.Girdi.dokunmatik() then
		kap.AnchorPoint = Vector2.new(1, 0)
		kap.Position = UDim2.new(1, -KENAR, 0, KENAR)
		return
	end

	local menuler = playerGui:FindFirstChild("OyunMenuleri")
	local sag = menuler and menuler:FindFirstChild("SagMenu")
	local magaza = playerGui:FindFirstChild("RobuxMagazasi")
	local store = magaza and magaza:FindFirstChild("StoreButonu")
	if not (sag and sag:IsA("GuiObject")) then
		kap.AnchorPoint = Vector2.new(1, 0)
		kap.Position = UDim2.new(1, -KENAR, 0, KENAR)
		return
	end

	local alt = sag.AbsolutePosition.Y + sag.AbsoluteSize.Y
	if store and store:IsA("GuiObject") and store.Visible then
		alt = math.max(alt, store.AbsolutePosition.Y + store.AbsoluteSize.Y)
	end
	kap.AnchorPoint = Vector2.new(1, 0)
	kap.Position = UDim2.fromOffset(sag.AbsolutePosition.X + sag.AbsoluteSize.X, alt + 8 * UI.carpan())
end

local function vurus(guc: number)
	sayacOlcek.Scale = guc
	TweenService:Create(sayacOlcek, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

RunService.Heartbeat:Connect(function()
	kap.Visible = not (ekranAcik("KaziBar") or ekranAcik("KaziMinigame"))
	if not kap.Visible then
		return
	end

	local simdi = Workspace:GetServerTimeNow()
	local t = os.clock()

	local sonraki = nitelik(E.nitelikSonraki)
	local bitis = nitelik(E.nitelikBitis)
	local kalan = nitelik(E.nitelikKalan)

	local aktif = kalan > 0 and bitis > simdi
	local bekleme = math.max(0, sonraki - simdi)
	local yakin = not aktif and sonraki > 0 and bekleme <= SON_DAKIKA

	huzmeler.Rotation = (t * (if aktif or yakin then 90 else 25)) % 360

	if aktif then
		local renk = Color3.fromHSV((t * 0.3) % 1, 0.6, 1)
		baslik.Text = "RAIN IS ACTIVE!"
		sayac.Text = `{math.floor(kalan)} LEFT`
		sayac.Position = UDim2.fromOffset(96, 28)
		sayac.TextColor3 = renk
		alt.Text = `GRAB THEM! {sure(bitis - simdi)}`
		alt.TextColor3 = BEYAZ
		kontur.Color = renk
		kontur.Thickness = 4
		olcek.Scale = 1 + math.sin(t * 6) * 0.03
		sayac.Rotation = 0
	elseif yakin then
		local yanip = math.sin(t * 10) > 0
		baslik.Text = "LUCKY BLOCK RAIN"
		sayac.Text = sure(bekleme)
		sayac.Position = UDim2.fromOffset(96, 28)
		sayac.TextColor3 = if yanip then KIRMIZI else ALTIN
		sayac.Rotation = math.sin(t * 30) * 3
		alt.Text = "DROPPING SOON!"
		alt.TextColor3 = if yanip then ALTIN else TURUNCU
		kontur.Color = if yanip then KIRMIZI else ALTIN
		kontur.Thickness = 4
		olcek.Scale = 1 + math.sin(t * 8) * 0.04

		local saniye = math.ceil(bekleme)
		if saniye ~= sonSaniye then
			sonSaniye = saniye
			vurus(if saniye <= 10 then 1.5 else 1.25)
		end
	else
		baslik.Text = "LUCKY BLOCK RAIN"
		sayac.Text = if sonraki > 0 then sure(bekleme) else "--:--"
		sayac.Position = UDim2.fromOffset(96, 40)
		sayac.TextColor3 = BEYAZ
		sayac.Rotation = 0
		alt.Text = ""
		alt.TextColor3 = ALTIN
		kontur.Color = SIYAH
		kontur.Thickness = 3
		olcek.Scale = 1
	end
end)

yerlestir()
UI.Girdi.degisince(yerlestir)
UI.onScaleChanged(yerlestir)
task.spawn(function()
	local menuler = playerGui:WaitForChild("OyunMenuleri", 30)
	local sag = menuler and menuler:WaitForChild("SagMenu", 10)
	local magaza = playerGui:WaitForChild("RobuxMagazasi", 30)
	local store = magaza and magaza:WaitForChild("StoreButonu", 10)
	for _, nesne in { sag, store } do
		if nesne and nesne:IsA("GuiObject") then
			nesne:GetPropertyChangedSignal("AbsolutePosition"):Connect(yerlestir)
			nesne:GetPropertyChangedSignal("AbsoluteSize"):Connect(yerlestir)
		end
	end
	yerlestir()
end)
