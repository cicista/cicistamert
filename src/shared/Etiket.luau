--!strict

local Bases = require(script.Parent.Bases)
local Brainrots = require(script.Parent.Brainrots)
local Condition = require(script.Parent.Condition)
local Divine = require(script.Parent.Divine)
local Fonts = require(script.Parent.Fonts)
local Format = require(script.Parent.Format)
local Mutations = require(script.Parent.Mutations)
local Rarity = require(script.Parent.Rarity)

local Etiket = {}

Etiket.Name = "Etiket"

Etiket.Layout = {
	width = 190,
	height = 82,

	raritySize = 15,
	nameSize = 18,
	statSize = 14,
	incomeSize = 16,

	rarityY = 2,
	nameY = 20,
	statY = 42,
	incomeY = 60,

	maxDistance = 120,
}

local function line(
	billboard: BillboardGui,
	name: string,
	text: string,
	color: Color3,
	size: number,
	y: number
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, size + 2)
	label.Position = UDim2.fromOffset(0, y)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextSize = size
	label.TextScaled = false
	Fonts.apply(label)
	label.Parent = billboard
	return label
end

function Etiket.build(item: any, adornee: Instance, lift: number?): BillboardGui
	local buyutme = Rarity.labelScale(item.rarity)

	local L = {
		width = Etiket.Layout.width * buyutme,
		height = Etiket.Layout.height * buyutme,

		raritySize = math.round(Etiket.Layout.raritySize * buyutme),
		nameSize = math.round(Etiket.Layout.nameSize * buyutme),
		statSize = math.round(Etiket.Layout.statSize * buyutme),
		incomeSize = math.round(Etiket.Layout.incomeSize * buyutme),

		rarityY = Etiket.Layout.rarityY * buyutme,
		nameY = Etiket.Layout.nameY * buyutme,
		statY = Etiket.Layout.statY * buyutme,
		incomeY = Etiket.Layout.incomeY * buyutme,

		maxDistance = Etiket.Layout.maxDistance,
	}

	local rarityInfo = Rarity.get(item.rarity)
	local conditionInfo = Condition.get(item.condition)
	local mutationInfo = Mutations.get(item.mutation)
	local special = Mutations.isSpecial(item.mutation)

	local old = adornee:FindFirstChild(Etiket.Name)
	if old then
		old:Destroy()
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = Etiket.Name
	billboard.Size = UDim2.fromOffset(L.width, L.height)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = L.maxDistance
	billboard.StudsOffsetWorldSpace = Vector3.new(0, lift or 0, 0)
	billboard.LightInfluence = 0
	billboard.Parent = adornee

	local rarityLabel = line(
		billboard,
		"Kademe",
		Rarity.labelText(item.rarity),
		Rarity.textColor(item.rarity),
		L.raritySize,
		L.rarityY
	)

	if Rarity.isDivine(item.rarity) then
		Fonts.applyGlow(rarityLabel, Rarity.textColor(item.rarity))
		Divine.tagIf(rarityLabel, item.rarity)
	elseif Rarity.isGlowing(item.rarity) then
		Fonts.applyGlow(rarityLabel, Rarity.textColor(item.rarity))
	end

	local nameLabel = line(billboard, "Isim", item.name or "???", Rarity.textColor(item.rarity), L.nameSize, L.nameY)

	local statRow = Instance.new("Frame")
	statRow.Name = "Stat"
	statRow.BackgroundTransparency = 1
	statRow.Size = UDim2.new(1, 0, 0, L.statSize + 2)
	statRow.Position = UDim2.fromOffset(0, L.statY)
	statRow.Parent = billboard

	local statLayout = Instance.new("UIListLayout")
	statLayout.FillDirection = Enum.FillDirection.Horizontal
	statLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	statLayout.Padding = UDim.new(0, 8)
	statLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statLayout.Parent = statRow

	local function statParca(name: string, text: string, color: Color3, order: number): TextLabel
		local label = Instance.new("TextLabel")
		label.Name = name
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.new(0, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = color
		label.TextSize = L.statSize
		label.TextScaled = false
		label.LayoutOrder = order
		Fonts.apply(label)
		label.Parent = statRow
		return label
	end

	statParca(
		"Boyut",
		`{conditionInfo.shortName} ({conditionInfo.multiplier}x)`,
		conditionInfo.color,
		1
	)

	if special then
		local mutasyon = statParca(
			"Mutasyon",
			`{mutationInfo.displayName} ({mutationInfo.multiplier}x)`,
			mutationInfo.color,
			2
		)
		Mutations.tagIf(mutasyon, item.mutation)
	end

	local income = if item.name then Brainrots.income(item.name, item.condition, item.mutation) else 0
	line(billboard, "Gelir", Format.perSecond(income), Bases.RotColor, L.incomeSize, L.incomeY)

	return billboard
end

return Etiket
