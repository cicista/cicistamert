--!strict

local Workspace = game:GetService("Workspace")

local Bases = {}

Bases.MaxPlayers = 6
Bases.Count = 6

Bases.SlotCount = 20

Bases.Upgrade = {
	slotsPerFloor = 10,
	maxFloors = 2,
	startingSlots = 10,
	floorCost = { [2] = 30_000_000_000, [3] = 5_000_000_000_000 },
	slotsWithFloor = 1,
	slotBaseCost = 30_000_000_000,
	slotGrowth = (3_000_000_000_000 / 30_000_000_000) ^ (1 / 9),
	floorPrefix = "Kat",
	markerName = "TabelaNoktasi",
	forward = 26,
	size = Vector3.new(18, 11, 0.8),
	color = Color3.fromRGB(24, 62, 116),

	panelTop = Color3.fromRGB(52, 126, 210),
	panelBottom = Color3.fromRGB(16, 48, 96),
	panelBorder = Color3.fromRGB(255, 202, 64),

	flipFace = true,

	riseHeight = 30,
	riseTime = 0.75,
}

function Bases.floorOf(slotIndex: number): number
	return math.ceil(slotIndex / Bases.Upgrade.slotsPerFloor)
end

function Bases.floorModelName(floorIndex: number): string
	return `{Bases.Upgrade.floorPrefix}{floorIndex}`
end

function Bases.slotCost(unlocked: number): number
	local U = Bases.Upgrade
	local step = math.max(0, unlocked - U.startingSlots)
	local ham = U.slotBaseCost * U.slotGrowth ^ step
	local basamak = 10 ^ math.max(0, math.floor(math.log10(ham)) - 2)
	return math.floor(ham / basamak + 0.5) * basamak
end

Bases.PayoutInterval = 1

Bases.CollectMarkerName = "ToplaNoktasi"

Bases.HologramHeight = 15

Bases.RotColor = Color3.fromRGB(255, 214, 41)

Bases.SlotSound = { "PutBrainrot" }

Bases.CollectPad = {
	size = Vector3.new(9, 0.6, 9),
	forward = 2,
	cooldown = 0.5,
	collectCooldown = 7,
	cooldownColor = Color3.fromRGB(220, 40, 40),
	collectSound = { "GoldCollect" },
	color = Color3.fromRGB(55, 205, 85),
	idleColor = Color3.fromRGB(90, 100, 115),
}

Bases.Display = {
	rotation = Vector3.new(0, 0, 0),
	gap = 0.15,
	spin = true,
	spinSpeed = 0.8,
	bobHeight = 0.35,
	bobSpeed = 1.6,
}

Bases.OwnerOnlyPlacement = true

Bases.SlotNumberFacing = "aisle"

Bases.FolderName = "Bases"

function Bases.findFolder(): Instance?
	local empty: Instance? = nil

	for _, node in Workspace:GetDescendants() do
		if node.Name ~= Bases.FolderName then
			continue
		end

		if not node:IsA("Folder") and not node:IsA("Model") then
			continue
		end

		if #node:GetChildren() > 0 then
			return node
		end

		empty = empty or node
	end

	return empty
end

function Bases.baseName(index: number): string
	return `Base{index}`
end

function Bases.slotName(index: number): string
	return `Slot{index}`
end

return Bases
