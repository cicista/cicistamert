--!strict

local Rods = {}

export type RodId = "Bamboo" | "Steel" | "Carbon" | "Abyssal" | "Leviathan"

export type RodInfo = {
	id: RodId,
	displayName: string,
	level: number,
	rarity: string,
	price: number,
	luck: number,
	scanRadius: number,
	spawnChance: number,
	maxWhirls: number,
	digSpeed: number,
	barSize: number,
	barAcceleration: number,
	progressRate: number,
	drainRate: number,
	color: Color3,
}

Rods.RequiredShovelLevel = 20

Rods.Order = { "Bamboo", "Steel", "Carbon", "Abyssal", "Leviathan" } :: { RodId }

Rods.Info = {
	Bamboo = {
		id = "Bamboo",
		displayName = "Bamboo Rod",
		level = 1,
		rarity = "Common",
		price = 1_500_000_000_000,
		luck = 1,
		scanRadius = 165,
		spawnChance = 35,
		maxWhirls = 4,
		digSpeed = 1,
		barSize = 0.17,
		barAcceleration = 1,
		progressRate = 0.12,
		drainRate = 0.18,
		color = Color3.fromRGB(190, 160, 95),
	},

	Steel = {
		id = "Steel",
		displayName = "Steel Rod",
		level = 2,
		rarity = "Rare",
		price = 1_850_000_000_000,
		luck = 1.6,
		scanRadius = 190,
		spawnChance = 42,
		maxWhirls = 5,
		digSpeed = 0.85,
		barSize = 0.2,
		barAcceleration = 1,
		progressRate = 0.125,
		drainRate = 0.17,
		color = Color3.fromRGB(150, 170, 195),
	},

	Carbon = {
		id = "Carbon",
		displayName = "Carbon Rod",
		level = 3,
		rarity = "Epic",
		price = 2_200_000_000_000,
		luck = 2.4,
		scanRadius = 215,
		spawnChance = 50,
		maxWhirls = 6,
		digSpeed = 0.7,
		barSize = 0.23,
		barAcceleration = 1.05,
		progressRate = 0.13,
		drainRate = 0.16,
		color = Color3.fromRGB(120, 90, 220),
	},

	Abyssal = {
		id = "Abyssal",
		displayName = "Abyssal Rod",
		level = 4,
		rarity = "Legendary",
		price = 2_600_000_000_000,
		luck = 3.6,
		scanRadius = 240,
		spawnChance = 58,
		maxWhirls = 7,
		digSpeed = 0.55,
		barSize = 0.27,
		barAcceleration = 1.05,
		progressRate = 0.135,
		drainRate = 0.15,
		color = Color3.fromRGB(255, 225, 130),
	},

	Leviathan = {
		id = "Leviathan",
		displayName = "Leviathan Rod",
		level = 5,
		rarity = "Mythic",
		price = 3_000_000_000_000,
		luck = 5.5,
		scanRadius = 270,
		spawnChance = 66,
		maxWhirls = 8,
		digSpeed = 0.4,
		barSize = 0.31,
		barAcceleration = 1.1,
		progressRate = 0.14,
		drainRate = 0.14,
		color = Color3.fromRGB(255, 70, 90),
	},
} :: { [RodId]: RodInfo }

Rods.ToolName = "OltaModeli"

Rods.TipName = "OltaUcu"

Rods.LineName = "OltaMisinasi"

Rods.CastRelease = 0.75

Rods.CastFlight = 0.5

Rods.LineColor = Color3.fromRGB(60, 255, 230)

Rods.CastTime = Rods.CastRelease + Rods.CastFlight

function Rods.get(id: string?): RodInfo?
	if not id then
		return nil
	end
	return Rods.Info[id :: RodId]
end

function Rods.exists(id: string?): boolean
	return Rods.get(id) ~= nil
end

function Rods.level(id: string?): number
	local info = Rods.get(id)
	return if info then info.level else 0
end

return Rods
