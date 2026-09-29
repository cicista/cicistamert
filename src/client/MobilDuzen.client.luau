--!strict

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UI = require(script.Parent:WaitForChild("UI"))
local Girdi = UI.Girdi

local MENU_BOYU = 52
local PARA_DOKUNMATIK_OLCEGI = 0.62

type Kayit = {
	nesne: GuiObject,
	anchor: Vector2,
	konum: UDim2,
	boyut: UDim2,
	otoBoyut: Enum.AutomaticSize,
}

local kayitlar: { [GuiObject]: Kayit } = {}

local function kaydet(nesne: GuiObject): Kayit
	local var = kayitlar[nesne]
	if var then
		return var
	end
	local yeni: Kayit = {
		nesne = nesne,
		anchor = nesne.AnchorPoint,
		konum = nesne.Position,
		boyut = nesne.Size,
		otoBoyut = nesne.AutomaticSize,
	}
	kayitlar[nesne] = yeni
	return yeni
end

local function geriAl(nesne: GuiObject)
	local kayit = kayitlar[nesne]
	if not kayit then
		return
	end
	nesne.AnchorPoint = kayit.anchor
	nesne.Position = kayit.konum
	nesne.Size = kayit.boyut
	nesne.AutomaticSize = kayit.otoBoyut
end

local function kucukEkran(): boolean
	local kamera = workspace.CurrentCamera
	if not kamera then
		return true
	end
	local boyut = kamera.ViewportSize
	return math.min(boyut.X, boyut.Y) <= 500
end

local function sagMenuyuDuzenle(sag: GuiObject, dokunmatik: boolean)
	kaydet(sag)
	local dizilim = sag:FindFirstChildOfClass("UIListLayout")

	if not dokunmatik then
		geriAl(sag)
		if dizilim then
			dizilim.FillDirection = Enum.FillDirection.Vertical
			dizilim.HorizontalAlignment = Enum.HorizontalAlignment.Left
			dizilim.VerticalAlignment = Enum.VerticalAlignment.Bottom
		end
		return
	end

	sag.AnchorPoint = Vector2.new(1, 0)
	sag.Position = UDim2.new(1, -12, 0, 8)
	sag.Size = UDim2.fromOffset(0, MENU_BOYU + 5)
	sag.AutomaticSize = Enum.AutomaticSize.X
	if dizilim then
		dizilim.FillDirection = Enum.FillDirection.Horizontal
		dizilim.HorizontalAlignment = Enum.HorizontalAlignment.Right
		dizilim.VerticalAlignment = Enum.VerticalAlignment.Top
	end
end

local function madenSayaciniDuzenle(kutu: GuiObject, dokunmatik: boolean)
	kaydet(kutu)
	if not dokunmatik then
		geriAl(kutu)
		return
	end
	local ziplamaUstu = if kucukEkran() then 100 else 220
	kutu.Position = UDim2.new(1, -20, 1, -ziplamaUstu)
end

local function bul(yol: { string }): GuiObject?
	local node: Instance? = playerGui
	for _, ad in yol do
		node = node and node:FindFirstChild(ad)
	end
	return if node and node:IsA("GuiObject") then node else nil
end

local function uygula()
	local dokunmatik = Girdi.dokunmatik()

	local sag = bul({ "OyunMenuleri", "SagMenu" })
	if sag then
		sagMenuyuDuzenle(sag, dokunmatik)
	end

	local para = bul({ "OyunMenuleri", "RotGostergesi" })
	if para then
		UI.dokunmatikOlcekVer(para, PARA_DOKUNMATIK_OLCEGI)
	end

	local maden = bul({ "MadenSayaci", "Kutu" })
	if maden then
		madenSayaciniDuzenle(maden, dokunmatik)
	end
end

task.spawn(function()
	local menuler = playerGui:WaitForChild("OyunMenuleri", 30)
	if menuler then
		menuler:WaitForChild("SagMenu", 10)
		menuler:WaitForChild("RotGostergesi", 10)
	end
	local madenEkrani = playerGui:WaitForChild("MadenSayaci", 10)
	if madenEkrani then
		madenEkrani:WaitForChild("Kutu", 10)
	end

	uygula()
	Girdi.degisince(uygula)
	UI.onScaleChanged(uygula)
end)
