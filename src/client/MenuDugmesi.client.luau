--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UI = require(script.Parent:WaitForChild("UI"))
local Girdi = UI.Girdi

local OTOMATIK_GIZLEME = 10
local MENU_BOYU = 52
local HUCRE_ARA = 8
local DUGME_EN = MENU_BOYU * 2 + HUCRE_ARA
local DUGME_BOY = 44
local LIP = 4
local DUGME_BOSLUK = 8
local ALT_PAY_NITELIGI = "MobilAltPay"
local BASE_DUGMESI = "Base"

local KAPALI_RENK = Color3.fromRGB(255, 176, 40)
local ACIK_RENK = Color3.fromRGB(226, 70, 70)
local SIYAH = Color3.fromRGB(0, 0, 0)
local BEYAZ = Color3.fromRGB(255, 255, 255)

local ACILIS_SURESI = 0.24
local KAPANIS_SURESI = 0.14
local SIRA_ARASI = 0.025

local menuler = playerGui:WaitForChild("OyunMenuleri") :: ScreenGui
local sol = menuler:WaitForChild("SolMenu") :: GuiObject
local sag = menuler:WaitForChild("SagMenu") :: GuiObject

if menuler:FindFirstChild("MenuDugmesi") or sol:FindFirstChild("MenuDugmesi") then
	return
end

local acik = true
local panelAcik = false
local sonEtkilesim = os.clock()
local izlenenler: { [GuiButton]: boolean } = {}

local dugme = Instance.new("TextButton")
dugme.Name = "MenuDugmesi"
dugme.Text = ""
dugme.AutoButtonColor = false
dugme.BackgroundTransparency = 1
dugme.AnchorPoint = Vector2.zero
dugme.Size = UDim2.fromOffset(DUGME_EN, DUGME_BOY + LIP)
dugme.Visible = false
dugme.Parent = menuler

local govde = Instance.new("Frame")
govde.Name = "Govde"
govde.AnchorPoint = Vector2.new(0.5, 0.5)
govde.Position = UDim2.fromScale(0.5, 0.5)
govde.Size = UDim2.fromScale(1, 1)
govde.BackgroundColor3 = UI.shade(KAPALI_RENK, -0.32)
govde.BorderSizePixel = 0
govde.Parent = dugme
UI.corner(govde, 12)
UI.stroke(govde, SIYAH, 2)

do
	local olcek = Instance.new("UIScale")
	olcek.Name = "GosterOlcek"
	olcek.Parent = govde
end

local yuz = Instance.new("Frame")
yuz.Name = "Yuz"
yuz.AnchorPoint = Vector2.new(0.5, 0)
yuz.Position = UDim2.new(0.5, 0, 0, 3)
yuz.Size = UDim2.new(1, -6, 1, -6 - LIP)
yuz.BackgroundColor3 = KAPALI_RENK
yuz.BorderSizePixel = 0
yuz.ClipsDescendants = true
yuz.Parent = govde
UI.corner(yuz, 9)
UI.corner(UI.gloss(yuz, 0.7), 9)

local ikonKap = Instance.new("Frame")
ikonKap.Name = "Ikon"
ikonKap.AnchorPoint = Vector2.new(0, 0.5)
ikonKap.Position = UDim2.new(0, 10, 0.5, 0)
ikonKap.Size = UDim2.fromOffset(22, 18)
ikonKap.BackgroundTransparency = 1
ikonKap.ZIndex = 3
ikonKap.Parent = yuz

local cubuklar = Instance.new("Frame")
cubuklar.Name = "Cubuklar"
cubuklar.Size = UDim2.fromScale(1, 1)
cubuklar.BackgroundTransparency = 1
cubuklar.ZIndex = 3
cubuklar.Parent = ikonKap

for i = 0, 2 do
	local cubuk = Instance.new("Frame")
	cubuk.AnchorPoint = Vector2.new(0, 0.5)
	cubuk.Position = UDim2.fromScale(0, 0.12 + i * 0.38)
	cubuk.Size = UDim2.new(1, 0, 0, 4)
	cubuk.BackgroundColor3 = BEYAZ
	cubuk.BorderSizePixel = 0
	cubuk.ZIndex = 3
	cubuk.Parent = cubuklar
	UI.corner(cubuk, 2)
	UI.stroke(cubuk, SIYAH, 1.5)
end

local carpi = UI.text({
	text = "X",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1.4),
	anchor = Vector2.new(0, 0.5),
	position = UDim2.fromScale(0, 0.5),
	parent = ikonKap,
	zIndex = 3,
})
carpi.Visible = false

local etiket = UI.text({
	text = "MENU",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -38, 1, 0),
	position = UDim2.fromOffset(34, 0),
	parent = yuz,
	zIndex = 3,
})

local function gorunumuCiz()
	local renk = if acik then ACIK_RENK else KAPALI_RENK
	yuz.BackgroundColor3 = renk
	govde.BackgroundColor3 = UI.shade(renk, -0.32)
	cubuklar.Visible = not acik
	carpi.Visible = acik
	etiket.Text = if acik then "HIDE" else "MENU"
end

local function dugmeyiYerlestir()
	if not Girdi.dokunmatik() then
		return
	end
	local carpan = UI.carpan()
	dugme.Position = UDim2.fromOffset(
		sol.AbsolutePosition.X,
		sol.AbsolutePosition.Y + sol.AbsoluteSize.Y + DUGME_BOSLUK * carpan
	)
	local pay = math.floor((DUGME_BOY + LIP + DUGME_BOSLUK * 2) * carpan + 0.5)
	if sol:GetAttribute(ALT_PAY_NITELIGI) ~= pay then
		sol:SetAttribute(ALT_PAY_NITELIGI, pay)
	end
end

type Durum = { hedef: boolean, surum: number }
local durumlar: { [GuiObject]: Durum } = {}
local ilkCizim = true

local function gosterOlcegi(oge: GuiObject): UIScale?
	local dogrudan = oge:FindFirstChild("GosterOlcek")
	if dogrudan and dogrudan:IsA("UIScale") then
		return dogrudan
	end
	local ic = oge:FindFirstChild("Govde")
	local icte = ic and ic:FindFirstChild("GosterOlcek")
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

local function ogeyiAyarla(oge: GuiObject, goster: boolean, gecikme: number, zorla: boolean?)
	local durum = durumlar[oge]
	if not durum then
		durum = { hedef = oge.Visible, surum = 0 }
		durumlar[oge] = durum
	end
	if not zorla and durum.hedef == goster and oge.Visible == goster then
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
		if zorla or not oge.Visible then
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

local function baseDugmesi(): GuiObject?
	for _, kap in { sag, sol } do
		local bulunan = kap:FindFirstChild(BASE_DUGMESI)
		if bulunan and bulunan:IsA("GuiObject") then
			return bulunan
		end
	end
	return nil
end

local function menuOgeleri(haric: GuiObject?): { GuiObject }
	local liste: { GuiObject } = {}
	local solOgeler: { GuiObject } = {}
	for _, cocuk in sol:GetChildren() do
		if cocuk:IsA("GuiObject") and cocuk ~= haric then
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
		if cocuk:IsA("GuiObject") and cocuk ~= haric then
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
		if nesne:IsA("GuiButton") and nesne ~= dugme and not izlenenler[nesne] then
			izlenenler[nesne] = true
			nesne.Activated:Connect(function()
				sonEtkilesim = os.clock()
			end)
		end
	end
end

local function baseyiAyarla(base: GuiObject, dokunmatik: boolean)
	local solda = dokunmatik and not acik
	local hedefKap = if solda then sol else sag
	local goster = not panelAcik

	if base.Parent ~= hedefKap then
		base.Parent = hedefKap
		ogeyiAyarla(base, goster, 0, true)
		return
	end
	ogeyiAyarla(base, goster, 0)
end

local function uygula()
	local dokunmatik = Girdi.dokunmatik()
	local goster = not panelAcik and (not dokunmatik or acik)

	ogeyiAyarla(dugme, dokunmatik and not panelAcik, 0)

	local base = baseDugmesi()
	if base then
		baseyiAyarla(base, dokunmatik)
		etkilesimiIzle(base)
	end

	local ogeler = menuOgeleri(base)
	local adet = #ogeler
	for i, oge in ogeler do
		local sira = if goster then i - 1 else adet - i
		ogeyiAyarla(oge, goster, sira * SIRA_ARASI)
		etkilesimiIzle(oge)
	end

	if not dokunmatik and sol:GetAttribute(ALT_PAY_NITELIGI) ~= nil then
		sol:SetAttribute(ALT_PAY_NITELIGI, nil)
	elseif dokunmatik then
		dugmeyiYerlestir()
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
	yuz.Position = UDim2.new(0.5, 0, 0, 3 + LIP / 2)
end)
dugme.MouseButton1Up:Connect(function()
	yuz.Position = UDim2.new(0.5, 0, 0, 3)
end)
dugme.MouseLeave:Connect(function()
	yuz.Position = UDim2.new(0.5, 0, 0, 3)
end)

sol:GetPropertyChangedSignal("AbsolutePosition"):Connect(dugmeyiYerlestir)
sol:GetPropertyChangedSignal("AbsoluteSize"):Connect(dugmeyiYerlestir)
UI.onScaleChanged(dugmeyiYerlestir)

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
