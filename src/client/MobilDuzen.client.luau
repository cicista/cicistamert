--!strict

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UI = require(script.Parent:WaitForChild("UI"))
local Girdi = UI.Girdi

local MENU_BOYU = 52
local MENU_YUKSEKLIK = MENU_BOYU + 5
local MASA_ARA = 14
local DOKUNMATIK_ARA = 8
local KENAR = 8
local UST = 6
local SOL_SUTUN_DOKUNMATIK = 2

local PARA_DOKUNMATIK_OLCEGI = 0.62

local ZIPLAMA_BOYU_KUCUK = 76
local ZIPLAMA_BOYU_BUYUK = 110
local ZIPLAMA_KENAR = 14

type Kayit = {
	anchor: Vector2,
	konum: UDim2,
	boyut: UDim2,
	otoBoyut: Enum.AutomaticSize,
}

local kayitlar: { [GuiObject]: Kayit } = {}

local function kaydet(nesne: GuiObject)
	if kayitlar[nesne] then
		return
	end
	kayitlar[nesne] = {
		anchor = nesne.AnchorPoint,
		konum = nesne.Position,
		boyut = nesne.Size,
		otoBoyut = nesne.AutomaticSize,
	}
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

local function bul(yol: { string }): GuiObject?
	local node: Instance? = playerGui
	for _, ad in yol do
		node = node and node:FindFirstChild(ad)
	end
	return if node and node:IsA("GuiObject") then node else nil
end

local function solDuzenle(sol: GuiObject, dokunmatik: boolean)
	kaydet(sol)
	local izgara = sol:FindFirstChildOfClass("UIGridLayout")
	local ara = if dokunmatik then DOKUNMATIK_ARA else MASA_ARA
	local sutun = if dokunmatik then SOL_SUTUN_DOKUNMATIK else 2
	sol.Size = UDim2.fromOffset(MENU_BOYU * sutun + ara * (sutun - 1), 0)
	if izgara then
		izgara.CellPadding = UDim2.fromOffset(ara, ara)
		izgara.StartCorner = if dokunmatik then Enum.StartCorner.BottomLeft else Enum.StartCorner.TopLeft
	end
end

local function sagDuzenle(sag: GuiObject, dokunmatik: boolean)
	kaydet(sag)
	local dizilim = sag:FindFirstChildOfClass("UIListLayout")

	if not dokunmatik then
		geriAl(sag)
		if dizilim then
			dizilim.Padding = UDim.new(0, MASA_ARA)
			dizilim.FillDirection = Enum.FillDirection.Vertical
			dizilim.HorizontalAlignment = Enum.HorizontalAlignment.Left
			dizilim.VerticalAlignment = Enum.VerticalAlignment.Bottom
		end
		return
	end

	sag.AnchorPoint = Vector2.new(1, 0)
	sag.Position = UDim2.new(1, -KENAR, 0, UST)
	sag.Size = UDim2.fromOffset(0, MENU_YUKSEKLIK)
	sag.AutomaticSize = Enum.AutomaticSize.X
	if dizilim then
		dizilim.Padding = UDim.new(0, DOKUNMATIK_ARA)
		dizilim.FillDirection = Enum.FillDirection.Horizontal
		dizilim.HorizontalAlignment = Enum.HorizontalAlignment.Right
		dizilim.VerticalAlignment = Enum.VerticalAlignment.Top
	end
end

local function ziplamaBoyu(): number
	return if kucukEkran() then ZIPLAMA_BOYU_KUCUK else ZIPLAMA_BOYU_BUYUK
end

local function madenDuzenle(kutu: GuiObject, dokunmatik: boolean)
	kaydet(kutu)
	if not dokunmatik then
		geriAl(kutu)
		return
	end
	kutu.Position = UDim2.new(1, -ZIPLAMA_KENAR, 1, -(ziplamaBoyu() + ZIPLAMA_KENAR * 2))
end

local ziplamaIzlenen: Instance? = nil
local ziplamaAyarlaniyor = false
local ziplamaBildirildi = false

local function ziplamaDugmesi(): GuiObject?
	local dugme = bul({ "TouchGui", "TouchControlFrame", "JumpButton" })
	if dugme then
		return dugme
	end
	local touchGui = playerGui:FindFirstChild("TouchGui")
	local bulunan = touchGui and touchGui:FindFirstChild("JumpButton", true)
	return if bulunan and bulunan:IsA("GuiObject") then bulunan else nil
end

local function ziplamaDuzenle()
	local dugme = ziplamaDugmesi()
	if not dugme then
		return
	end

	local boy = ziplamaBoyu()
	local hedefBoyut = UDim2.fromOffset(boy, boy)
	local hedefKonum = UDim2.new(1, -(boy + ZIPLAMA_KENAR), 1, -(boy + ZIPLAMA_KENAR))
	if dugme.Size ~= hedefBoyut or dugme.Position ~= hedefKonum or dugme.AnchorPoint ~= Vector2.zero then
		ziplamaAyarlaniyor = true
		dugme.AnchorPoint = Vector2.zero
		dugme.Size = hedefBoyut
		dugme.Position = hedefKonum
		ziplamaAyarlaniyor = false
		if not ziplamaBildirildi then
			ziplamaBildirildi = true
			print(`[MobilDuzen] Jump button moved to the bottom-right corner ({boy}px)`)
		end
	end

	if ziplamaIzlenen ~= dugme then
		ziplamaIzlenen = dugme
		for _, ozellik in { "Position", "Size" } do
			dugme:GetPropertyChangedSignal(ozellik):Connect(function()
				if not ziplamaAyarlaniyor then
					task.defer(ziplamaDuzenle)
				end
			end)
		end
	end
end

local function uygula()
	local dokunmatik = Girdi.dokunmatik()

	local para = bul({ "OyunMenuleri", "RotGostergesi" })
	if para then
		UI.dokunmatikOlcekVer(para, PARA_DOKUNMATIK_OLCEGI)
	end

	local sol = bul({ "OyunMenuleri", "SolMenu" })
	if sol then
		solDuzenle(sol, dokunmatik)
	end

	local sag = bul({ "OyunMenuleri", "SagMenu" })
	if sag then
		sagDuzenle(sag, dokunmatik)
	end

	local maden = bul({ "MadenSayaci", "Kutu" })
	if maden then
		madenDuzenle(maden, dokunmatik)
	end

	ziplamaDuzenle()
end

task.spawn(function()
	local menuler = playerGui:WaitForChild("OyunMenuleri", 30)
	if menuler then
		menuler:WaitForChild("SagMenu", 10)
		menuler:WaitForChild("SolMenu", 10)
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

playerGui.DescendantAdded:Connect(function(nesne)
	if nesne.Name == "JumpButton" or nesne.Name == "TouchControlFrame" then
		task.defer(ziplamaDuzenle)
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		ziplamaDuzenle()
	end
end)
