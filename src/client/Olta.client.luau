--[[
	Olta  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Olta

	RodSeller NPC'sine basinca acilan satici paneli: 5 kademe, fiyatlari,
	sans carpanlari.

	Kurek ve dedektorde oldugu gibi sirayla alinir; ALINAN kademeler kalici
	kalir ve tiklayinca ucretsiz geri kusanilir (EQUIPPED / USE).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Rods = require(Shared:WaitForChild("Rods"))

local UI = require(script.Parent:WaitForChild("UI"))

local RodAc = Net.event("RodAc")
local RodAl = Net.event("RodAl")

local screen = Instance.new("ScreenGui")
screen.Name = "OltaEkrani"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local panel = UI.panel(screen, UDim2.fromOffset(520, 470), "OltaSatici")

UI.text({
	text = "Rod Seller",
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

	-- Sahip olunan ama kusanili olmayan kademe soluk durur
	if entry.owned and not entry.equipped then
		row.BackgroundTransparency = 0.4
	end

	UI.text({
		text = `Lv.{entry.level}  {entry.displayName}`,
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = renk,
		frameSize = UDim2.new(1, -150, 0, 24),
		position = UDim2.fromOffset(14, 8),
		parent = row,
	})

	UI.text({
		text = `Luck x{entry.luck}  Range {entry.scanRadius} studs`,
		size = UI.Sizes.small,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -150, 0, 20),
		position = UDim2.fromOffset(14, 36),
		parent = row,
	})

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

	if not entry.owned and not entry.next then
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

	-- Sahip olunan kademe ucretsiz kusanilir, siradaki satin alinir
	local etiket = if entry.owned then "Use" else `{Format.short(entry.price)} Rot`
	local buton = UI.button(
		row,
		etiket,
		UDim2.fromOffset(130, 34),
		if entry.owned then UI.Colors.accent else UI.Colors.gold
	)
	buton.AnchorPoint = Vector2.new(1, 0.5)
	buton.Position = UDim2.new(1, -14, 0.5, 0)
	UI.stroke(buton, Color3.fromRGB(0, 0, 0), 2)

	buton.MouseButton1Click:Connect(function()
		RodAl:FireServer(entry.id)
	end)

	UI.hover(buton)
end

RodAc.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end

	for _, child in liste:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local sahip = Rods.get(data.owned)
	ozet.Text = if sahip
		then `{sahip.displayName} equipped  ({Format.short(data.rot or 0)} Rot)`
		else `You have no rod yet  ({Format.short(data.rot or 0)} Rot)`

	for index, entry in data.rods or {} do
		satirCiz(entry, index)
	end

	panel.Visible = true
end)
