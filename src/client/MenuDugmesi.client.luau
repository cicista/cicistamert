--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UI = require(script.Parent:WaitForChild("UI"))
local Girdi = UI.Girdi

local OTOMATIK_GIZLEME = 10
local MENU_BOYU = 52
local LIP = 5

local KAPALI_RENK = Color3.fromRGB(255, 176, 40)
local ACIK_RENK = Color3.fromRGB(226, 70, 70)
local SIYAH = Color3.fromRGB(0, 0, 0)
local BEYAZ = Color3.fromRGB(255, 255, 255)

local menuler = playerGui:WaitForChild("OyunMenuleri")
local sol = menuler:WaitForChild("SolMenu") :: GuiObject
local sag = menuler:WaitForChild("SagMenu") :: GuiObject

if sol:FindFirstChild("MenuDugmesi") then
	return
end

local acik = true
local sonEtkilesim = os.clock()
local izlenenler: { [GuiButton]: boolean } = {}

local dugme = Instance.new("ImageButton")
dugme.Name = "MenuDugmesi"
dugme.LayoutOrder = -1000
dugme.Size = UDim2.fromOffset(MENU_BOYU, MENU_BOYU + LIP)
dugme.BackgroundColor3 = UI.shade(KAPALI_RENK, -0.32)
dugme.BorderSizePixel = 0
dugme.AutoButtonColor = false
dugme.Image = ""
dugme.Visible = false
dugme.Parent = sol
UI.corner(dugme, 14)
local kontur = UI.stroke(dugme, SIYAH, 2)

local yuz = Instance.new("Frame")
yuz.Name = "Yuz"
yuz.AnchorPoint = Vector2.new(0.5, 0.5)
yuz.Position = UDim2.new(0.5, 0, 0.5, -LIP / 2)
yuz.Size = UDim2.new(1, -8, 1, -8 - LIP)
yuz.BackgroundColor3 = KAPALI_RENK
yuz.BorderSizePixel = 0
yuz.ClipsDescendants = true
yuz.Parent = dugme
UI.corner(yuz, 10)
UI.gloss(yuz, 0.7)

local cubuklar = Instance.new("Frame")
cubuklar.Name = "Cubuklar"
cubuklar.AnchorPoint = Vector2.new(0.5, 0)
cubuklar.Position = UDim2.fromScale(0.5, 0.14)
cubuklar.Size = UDim2.fromScale(0.62, 0.42)
cubuklar.BackgroundTransparency = 1
cubuklar.ZIndex = 3
cubuklar.Parent = yuz

for i = 0, 2 do
	local cubuk = Instance.new("Frame")
	cubuk.AnchorPoint = Vector2.new(0.5, 0.5)
	cubuk.Position = UDim2.fromScale(0.5, 0.15 + i * 0.35)
	cubuk.Size = UDim2.new(1, 0, 0, 5)
	cubuk.BackgroundColor3 = BEYAZ
	cubuk.BorderSizePixel = 0
	cubuk.ZIndex = 3
	cubuk.Parent = cubuklar
	UI.corner(cubuk, 3)
	UI.stroke(cubuk, SIYAH, 1.5)
end

local carpi = UI.text({
	text = "X",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 0.62),
	position = UDim2.fromScale(0, 0.02),
	parent = yuz,
	zIndex = 3,
})
carpi.Visible = false

local etiket = UI.text({
	text = "MENU",
	size = UI.Sizes.tiny,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0.36, 0),
	position = UDim2.fromScale(0, 0.62),
	parent = yuz,
	zIndex = 3,
})

local isilti = TweenService:Create(
	kontur,
	TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Thickness = 4.5, Color = Color3.fromRGB(255, 240, 150) }
)

local function gorunumuCiz()
	local renk = if acik then ACIK_RENK else KAPALI_RENK
	yuz.BackgroundColor3 = renk
	dugme.BackgroundColor3 = UI.shade(renk, -0.32)
	cubuklar.Visible = not acik
	carpi.Visible = acik
	etiket.Text = if acik then "HIDE" else "MENU"

	if acik then
		isilti:Cancel()
		kontur.Thickness = 2
		kontur.Color = SIYAH
	elseif dugme.Visible then
		isilti:Play()
	end
end

local ACILIS_SURESI = 0.24
local KAPANIS_SURESI = 0.14
local SIRA_ARASI = 0.025

type Durum = { hedef: boolean, surum: number }
local durumlar: { [GuiObject]: Durum } = {}
local ilkCizim = true
local panelAcik = false

local function gosterOlcegi(oge: GuiObject): UIScale?
	local dogrudan = oge:FindFirstChild("GosterOlcek")
	if dogrudan and dogrudan:IsA("UIScale") then
		return dogrudan
	end
	local govde = oge:FindFirstChild("Govde")
	local icte = govde and govde:FindFirstChild("GosterOlcek")
	if icte and icte:IsA("UIScale") then
		return icte
	end
	if oge:FindFirstChildOfClass("UIScale") then
		return nil
	end
	local yeni = Instance.new("UIScale")
	yeni.Name = "GosterOlcek"
	yeni.Parent = oge
	return yeni
end

local function ogeyiAyarla(oge: GuiObject, goster: boolean, gecikme: number)
	local durum = durumlar[oge]
	if not durum then
		durum = { hedef = oge.Visible, surum = 0 }
		durumlar[oge] = durum
	end
	if durum.hedef == goster and oge.Visible == goster then
		return
	end
	durum.hedef = goster
	durum.surum += 1
	local surum = durum.surum
	local olcek = gosterOlcegi(oge)

	if ilkCizim or not olcek then
		oge.Visible = goster
		if olcek then
			olcek.Scale = 1
		end
		return
	end

	if goster then
		if not oge.Visible then
			olcek.Scale = 0
			oge.Visible = true
		end
		task.delay(gecikme, function()
			if durum.surum ~= surum then
				return
			end
			TweenService:Create(
				olcek,
				TweenInfo.new(ACILIS_SURESI, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			):Play()
		end)
		return
	end

	task.delay(gecikme, function()
		if durum.surum ~= surum then
			return
		end
		local kapanis = TweenService:Create(
			olcek,
			TweenInfo.new(KAPANIS_SURESI, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{ Scale = 0 }
		)
		kapanis.Completed:Connect(function(sonuc)
			if durum.surum == surum and sonuc == Enum.PlaybackState.Completed then
				oge.Visible = false
				olcek.Scale = 1
			end
		end)
		kapanis:Play()
	end)
end

local function menuOgeleri(): { GuiObject }
	local liste: { GuiObject } = {}
	local solOgeler: { GuiObject } = {}
	for _, cocuk in sol:GetChildren() do
		if cocuk:IsA("GuiObject") and cocuk ~= dugme then
			table.insert(solOgeler, cocuk)
		end
	end
	table.sort(solOgeler, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for _, oge in solOgeler do
		table.insert(liste, oge)
	end
	for _, cocuk in sag:GetChildren() do
		if cocuk:IsA("GuiObject") then
			table.insert(liste, cocuk)
		end
	end
	local robux = playerGui:FindFirstChild("RobuxMagazasi")
	local store = robux and robux:FindFirstChild("StoreButonu")
	if store and store:IsA("GuiObject") then
		table.insert(liste, store)
	end
	return liste
end

local function etkilesimiIzle(oge: GuiObject)
	local butonlar: { Instance } = oge:GetDescendants()
	table.insert(butonlar, oge)
	for _, nesne in butonlar do
		if nesne:IsA("GuiButton") and not izlenenler[nesne] then
			izlenenler[nesne] = true
			nesne.Activated:Connect(function()
				sonEtkilesim = os.clock()
			end)
		end
	end
end

local function uygula()
	local dokunmatik = Girdi.dokunmatik()
	local goster = not panelAcik and (not dokunmatik or acik)

	ogeyiAyarla(dugme, dokunmatik and not panelAcik, 0)

	local ogeler = menuOgeleri()
	local adet = #ogeler
	for i, oge in ogeler do
		local sira = if goster then i - 1 else adet - i
		ogeyiAyarla(oge, goster, sira * SIRA_ARASI)
		etkilesimiIzle(oge)
	end

	gorunumuCiz()
	ilkCizim = false
end

local function menuyuAc(yeni: boolean)
	acik = yeni
	sonEtkilesim = os.clock()
	uygula()
end

dugme.Activated:Connect(function()
	menuyuAc(not acik)
end)

dugme.MouseButton1Down:Connect(function()
	yuz.Position = UDim2.new(0.5, 0, 0.5, LIP / 2)
end)
dugme.MouseButton1Up:Connect(function()
	yuz.Position = UDim2.new(0.5, 0, 0.5, -LIP / 2)
end)
dugme.MouseLeave:Connect(function()
	yuz.Position = UDim2.new(0.5, 0, 0.5, -LIP / 2)
end)

sol.ChildAdded:Connect(function()
	task.defer(uygula)
end)
sag.ChildAdded:Connect(function()
	task.defer(uygula)
end)
Girdi.degisince(function()
	uygula()
end)

task.spawn(function()
	local robux = playerGui:WaitForChild("RobuxMagazasi", 30)
	if robux and robux:WaitForChild("StoreButonu", 30) then
		uygula()
	end
end)

uygula()

task.spawn(function()
	while true do
		task.wait(0.1)

		local simdiPanel = UI.acikPanelVarMi()
		if simdiPanel ~= panelAcik then
			panelAcik = simdiPanel
			uygula()
		end

		if Girdi.dokunmatik() and acik then
			if panelAcik then
				sonEtkilesim = os.clock()
			elseif os.clock() - sonEtkilesim >= OTOMATIK_GIZLEME then
				menuyuAc(false)
			end
		end
	end
end)
