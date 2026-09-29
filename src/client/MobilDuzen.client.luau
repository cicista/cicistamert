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
local SOL_SATIR = 4

local PARA_DOKUNMATIK_OLCEGI = 0.62
local DUGME_EN_AZ = 0.72
local DUGME_EN_COK = 1.15

local ZIPLAMA_BOYU_KUCUK = 88
local ZIPLAMA_BOYU_BUYUK = 120
local ZIPLAMA_KENAR = 16

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

local istenenSolKonum: UDim2? = nil
local solIzleniyor = false

local function dugmeOlcegi(menuler: ScreenGui, para: GuiObject?): (number, number)
	local paraBoyu = if para then para.Size.Y.Offset * UI.nesneCarpani(para) else 0
	local ust = UST + paraBoyu + KENAR
	local yer = menuler.AbsoluteSize.Y - ust - KENAR
	local gereken = SOL_SATIR * MENU_YUKSEKLIK + (SOL_SATIR - 1) * DOKUNMATIK_ARA
	local olcek = if yer > 0 then math.clamp(yer / gereken, DUGME_EN_AZ, DUGME_EN_COK) else 1
	return olcek, ust
end

local function paraDuzenle(para: GuiObject, dokunmatik: boolean)
	kaydet(para)
	UI.dokunmatikOlcekVer(para, PARA_DOKUNMATIK_OLCEGI)
	if not dokunmatik then
		geriAl(para)
		return
	end
	para.AnchorPoint = Vector2.new(0, 0)
	para.Position = UDim2.fromOffset(KENAR, UST)
end

local function solDuzenle(sol: GuiObject, dokunmatik: boolean, carpan: number, ust: number)
	kaydet(sol)
	local izgara = sol:FindFirstChildOfClass("UIGridLayout")

	if not dokunmatik then
		istenenSolKonum = nil
		UI.dokunmatikOlcekVer(sol, 1)
		local kayit = kayitlar[sol]
		sol.Size = kayit.boyut
		sol.AnchorPoint = kayit.anchor
		if izgara then
			izgara.CellPadding = UDim2.fromOffset(MASA_ARA, MASA_ARA)
			izgara.VerticalAlignment = Enum.VerticalAlignment.Bottom
		end
		return
	end

	UI.dokunmatikOlcekVer(sol, carpan)
	sol.Size = UDim2.fromOffset(MENU_BOYU * 2 + DOKUNMATIK_ARA, 0)
	if izgara then
		izgara.CellPadding = UDim2.fromOffset(DOKUNMATIK_ARA, DOKUNMATIK_ARA)
		izgara.VerticalAlignment = Enum.VerticalAlignment.Top
	end
	sol.AnchorPoint = Vector2.new(0, 0)
	istenenSolKonum = UDim2.fromOffset(KENAR, ust)
	sol.Position = istenenSolKonum :: UDim2

	if not solIzleniyor then
		solIzleniyor = true
		sol:GetPropertyChangedSignal("Position"):Connect(function()
			local hedef = istenenSolKonum
			if hedef and Girdi.dokunmatik() and sol.Position ~= hedef then
				sol.AnchorPoint = Vector2.new(0, 0)
				sol.Position = hedef
			end
		end)
	end
end

local function sagDuzenle(sag: GuiObject, dokunmatik: boolean, carpan: number)
	kaydet(sag)
	local dizilim = sag:FindFirstChildOfClass("UIListLayout")

	if not dokunmatik then
		UI.dokunmatikOlcekVer(sag, 1)
		geriAl(sag)
		if dizilim then
			dizilim.Padding = UDim.new(0, MASA_ARA)
			dizilim.FillDirection = Enum.FillDirection.Vertical
			dizilim.HorizontalAlignment = Enum.HorizontalAlignment.Left
			dizilim.VerticalAlignment = Enum.VerticalAlignment.Bottom
		end
		return
	end

	UI.dokunmatikOlcekVer(sag, carpan)
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

local function ziplamaDuzenle()
	if not Girdi.dokunmatik() then
		return
	end
	local dugme = bul({ "TouchGui", "TouchControlFrame", "JumpButton" })
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
	local menuler = playerGui:FindFirstChild("OyunMenuleri")
	if not menuler or not menuler:IsA("ScreenGui") then
		return
	end

	local para = bul({ "OyunMenuleri", "RotGostergesi" })
	if para then
		paraDuzenle(para, dokunmatik)
	end

	local olcek, ust = dugmeOlcegi(menuler, if dokunmatik then para else nil)
	local carpan = olcek / math.max(UI.carpan(), 0.01)

	local sol = bul({ "OyunMenuleri", "SolMenu" })
	if sol then
		solDuzenle(sol, dokunmatik, carpan, ust)
	end

	local sag = bul({ "OyunMenuleri", "SagMenu" })
	if sag then
		sagDuzenle(sag, dokunmatik, carpan)
	end

	local store = bul({ "RobuxMagazasi", "StoreButonu" })
	if store then
		UI.dokunmatikOlcekVer(store, carpan)
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
	local robux = playerGui:WaitForChild("RobuxMagazasi", 10)
	if robux then
		robux:WaitForChild("StoreButonu", 10)
	end
	local madenEkrani = playerGui:WaitForChild("MadenSayaci", 10)
	if madenEkrani then
		madenEkrani:WaitForChild("Kutu", 10)
	end

	uygula()
	Girdi.degisince(uygula)
	UI.onScaleChanged(uygula)
	if menuler and menuler:IsA("ScreenGui") then
		menuler:GetPropertyChangedSignal("AbsoluteSize"):Connect(uygula)
	end
end)

task.spawn(function()
	local touchGui = playerGui:WaitForChild("TouchGui", 60)
	if not touchGui then
		return
	end
	local cerceve = touchGui:WaitForChild("TouchControlFrame", 30)
	if not cerceve then
		return
	end
	cerceve.ChildAdded:Connect(function(cocuk)
		if cocuk.Name == "JumpButton" then
			task.defer(ziplamaDuzenle)
		end
	end)
	ziplamaDuzenle()
end)
