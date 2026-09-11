--[[
	Flyboard  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Flyboard

	Iki isi var:

	1. SATICI PANELI
	   FlyboardSeller NPC'sine basinca acilir: 5 kademe, fiyatlariyla.
	   Kurek ve dedektorde oldugu gibi sirayla alinir -- yalnizca bir
	   sonraki kademenin dugmesi calisir.

	2. YUKSEKLIK TUSLARI
	   Tahtadayken Space yukseltir, Shift alcaltir. Tus BASILI oldUGU surece
	   sunucuya yon gonderilir; sinirlari (taban yukseklik ve en fazla
	   yukselme) sunucu uygular, istemci yalnizca niyeti bildirir.

	   Ziplama sunucuda kapatildigi icin Space burada serbest kalir.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Flyboard = require(Shared:WaitForChild("Flyboard"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))

local FlyboardAc = Net.event("FlyboardAc")
local FlyboardAl = Net.event("FlyboardAl")
local FlyboardYukseklik = Net.event("FlyboardYukseklik")

local screen = Instance.new("ScreenGui")
screen.Name = "FlyboardEkrani"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

------------------------------------------------------------------
-- PANEL
------------------------------------------------------------------
local panel = UI.panel(screen, UDim2.fromOffset(520, 470), "FlyboardSatici")

UI.text({
	text = "Flyboard Seller",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	frameSize = UDim2.new(1, -80, 0, 36),
	position = UDim2.fromOffset(18, 14),
	parent = panel,
})

local ozet = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 50),
	parent = panel,
})

UI.closeButton(panel).MouseButton1Click:Connect(function()
	panel.Visible = false
end)

local liste = Instance.new("ScrollingFrame")
liste.Name = "Liste"
liste.Position = UDim2.fromOffset(14, 82)
liste.Size = UDim2.new(1, -28, 1, -96)
liste.BackgroundTransparency = 1
liste.BorderSizePixel = 0
liste.ScrollBarThickness = 5
liste.ScrollBarImageColor3 = UI.Colors.panelLight
liste.CanvasSize = UDim2.new()
liste.AutomaticCanvasSize = Enum.AutomaticSize.Y
liste.Parent = panel

local listeDizilim = Instance.new("UIListLayout")
listeDizilim.Padding = UDim.new(0, 8)
listeDizilim.SortOrder = Enum.SortOrder.LayoutOrder
listeDizilim.Parent = liste

local function satirCiz(entry: any, order: number)
	local renk = entry.color or UI.Colors.accent

	local row = Instance.new("Frame")
	row.Name = entry.id
	row.Size = UDim2.new(1, -6, 0, 70)
	row.BackgroundColor3 = UI.Colors.panelLight
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.Parent = liste
	UI.corner(row, 10)
	UI.stroke(row, renk, if entry.equipped then 2 else 1)

	UI.text({
		text = entry.displayName,
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = renk,
		frameSize = UDim2.new(1, -150, 0, 24),
		position = UDim2.fromOffset(14, 8),
		parent = row,
	})

	UI.text({
		text = `{Rarity.displayName(entry.rarity)}  {Format.short(entry.price)} Rot`,
		size = UI.Sizes.small,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -150, 0, 20),
		position = UDim2.fromOffset(14, 36),
		parent = row,
	})

	--[[
		Sahip olunan kademeler kalici: kusanili olan "EQUIPPED" der,
		digerine basinca ucretsiz kusanilir.
	]]
	if entry.equipped then
		UI.text({
			text = "EQUIPPED",
			size = UI.Sizes.small,
			font = UI.Fonts.bold,
			color = UI.Colors.good,
			align = Enum.TextXAlignment.Right,
			frameSize = UDim2.new(0, 120, 0, 70),
			position = UDim2.new(1, -134, 0, 0),
			parent = row,
		})
		return
	end

	if entry.owned then
		local kusan = UI.button(row, "Use", UDim2.fromOffset(110, 34), UI.Colors.accent)
		kusan.AnchorPoint = Vector2.new(1, 0.5)
		kusan.Position = UDim2.new(1, -14, 0.5, 0)
		UI.stroke(kusan, Color3.fromRGB(0, 0, 0), 2)

		kusan.MouseButton1Click:Connect(function()
			FlyboardAl:FireServer(entry.id)
		end)

		UI.hover(kusan)
		return
	end

	if not entry.next then
		UI.text({
			text = "LOCKED",
			size = UI.Sizes.small,
			font = UI.Fonts.bold,
			color = UI.Colors.textDim,
			align = Enum.TextXAlignment.Right,
			frameSize = UDim2.new(0, 120, 0, 70),
			position = UDim2.new(1, -134, 0, 0),
			parent = row,
		})
		return
	end

	local buton = UI.button(row, "Buy", UDim2.fromOffset(110, 34), UI.Colors.gold)
	buton.AnchorPoint = Vector2.new(1, 0.5)
	buton.Position = UDim2.new(1, -14, 0.5, 0)
	UI.stroke(buton, Color3.fromRGB(0, 0, 0), 2)

	buton.MouseButton1Click:Connect(function()
		FlyboardAl:FireServer(entry.id)
	end)

	UI.hover(buton)
end

FlyboardAc.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end

	for _, child in liste:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local sahip = Flyboard.get(data.owned)
	ozet.Text = if sahip
		then `You own the {sahip.displayName}  ({Format.short(data.rot or 0)} Rot)`
		else `You have no flyboard yet  ({Format.short(data.rot or 0)} Rot)`

	for index, entry in data.boards or {} do
		satirCiz(entry, index)
	end

	panel.Visible = true
end)

------------------------------------------------------------------
-- YUKSEKLIK TUSLARI
------------------------------------------------------------------
local YUKSEL = "FlyboardYukari"
local ALCAL = "FlyboardAsagi"

-- Basili tutuldugu surece sunucuya yon gonderilir
local yon = 0

ContextActionService:BindAction(YUKSEL, function(_, state)
	yon = if state == Enum.UserInputState.Begin then 1 elseif yon == 1 then 0 else yon
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.Space)

ContextActionService:BindAction(ALCAL, function(_, state)
	yon = if state == Enum.UserInputState.Begin then -1 elseif yon == -1 then 0 else yon
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift)

--[[
	Tus basiliyken saniyede ~15 paket: her karede gondermek gereksiz,
	sunucu zaten adimi kendi hesapliyor. Tahtada degilken sunucu paketi
	sessizce yok sayar.
]]
task.spawn(function()
	while true do
		task.wait(1 / 15)
		if yon ~= 0 then
			FlyboardYukseklik:FireServer(yon)
		end
	end
end)
