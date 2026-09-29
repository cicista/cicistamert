--!strict

local Shovels = {}

export type ShovelId = string

export type ShovelInfo = {
	id: ShovelId,
	displayName: string,
	level: number,
	rarity: string,
	price: number,
	digSpeed: number,
	barSize: number,
	barAcceleration: number,
	progressRate: number,
	drainRate: number,
	color: Color3,
	island: string?,
	oreCost: number?,
}

Shovels.OreCosts = { 0, 3, 5, 7, 9 }

Shovels.Order = { "Wooden", "Iron", "Golden", "Diamond", "Celestial" } :: { ShovelId }

Shovels.Info = {
	Wooden = {
		id = "Wooden",
		displayName = "Basic Shovel",
		level = 1,
		rarity = "Common",
		price = 0,
		digSpeed = 1,
		barSize = 0.22,
		barAcceleration = 1.15,
		progressRate = 0.42,
		drainRate = 0.16,
		color = Color3.fromRGB(150, 111, 68),
	},

	Iron = {
		id = "Iron",
		displayName = "Emerald Shovel",
		level = 2,
		rarity = "Rare",
		price = 750_000,
		digSpeed = 0.85,
		barSize = 0.26,
		barAcceleration = 1.25,
		progressRate = 0.48,
		drainRate = 0.14,
		color = Color3.fromRGB(176, 182, 192),
	},

	Golden = {
		id = "Golden",
		displayName = "Diamond Shovel",
		level = 3,
		rarity = "Epic",
		price = 2_000_000,
		digSpeed = 0.7,
		barSize = 0.30,
		barAcceleration = 1.40,
		progressRate = 0.55,
		drainRate = 0.12,
		color = Color3.fromRGB(240, 190, 62),
	},

	Diamond = {
		id = "Diamond",
		displayName = "Amethyst Shovel",
		level = 4,
		rarity = "Legendary",
		price = 15_000_000,
		digSpeed = 0.55,
		barSize = 0.34,
		barAcceleration = 1.55,
		progressRate = 0.62,
		drainRate = 0.10,
		color = Color3.fromRGB(120, 226, 240),
	},

	Celestial = {
		id = "Celestial",
		displayName = "Celestial Shovel",
		level = 5,
		rarity = "Mythic",
		price = 110_000_000,
		digSpeed = 0.4,
		barSize = 0.40,
		barAcceleration = 1.75,
		progressRate = 0.72,
		drainRate = 0.08,
		color = Color3.fromRGB(196, 150, 255),
	},
} :: { [ShovelId]: ShovelInfo }

local function adaKuregi(id: string, displayName: string, level: number, island: string, rarity: string, price: number, color: Color3)
	local ilerleme = level - 5
	local sira = ((level - 6) % 5) + 1

	Shovels.Info[id] = {
		id = id,
		displayName = displayName,
		level = level,
		rarity = rarity,
		price = price,
		digSpeed = math.max(0.2, 0.4 - ilerleme * 0.012),
		barSize = 0.40,
		barAcceleration = 1.75,
		progressRate = 0.72,
		drainRate = 0.08,
		color = color,
		island = island,
		oreCost = Shovels.OreCosts[sira],
	}
	table.insert(Shovels.Order, id)
end

adaKuregi("LollipopShovel", "Lollipop Shovel", 6, "sekerkum", "Cosmic", 3_500_000_000, Color3.fromRGB(255, 150, 210))
adaKuregi("GummyShovel", "Gummy Shovel", 7, "sekerkum", "Cosmic", 4_500_000_000, Color3.fromRGB(255, 130, 200))
adaKuregi("CandyCaneShovel", "Candy Cane Shovel", 8, "sekerkum", "Cosmic", 5_500_000_000, Color3.fromRGB(255, 110, 170))
adaKuregi("CaramelShovel", "Caramel Shovel", 9, "sekerkum", "Cosmic", 7_000_000_000, Color3.fromRGB(240, 120, 190))
adaKuregi("SugarCrystalShovel", "Sugar Crystal Shovel", 10, "sekerkum", "Cosmic", 8_000_000_000, Color3.fromRGB(255, 90, 200))

adaKuregi("FrostShovel", "Frost Shovel", 11, "snowkum", "Gizli", 50_000_000_000, Color3.fromRGB(170, 230, 255))
adaKuregi("GlacierShovel", "Glacier Shovel", 12, "snowkum", "Gizli", 62_000_000_000, Color3.fromRGB(140, 215, 255))
adaKuregi("BlizzardShovel", "Blizzard Shovel", 13, "snowkum", "Gizli", 75_000_000_000, Color3.fromRGB(120, 200, 250))
adaKuregi("PermafrostShovel", "Permafrost Shovel", 14, "snowkum", "Gizli", 87_000_000_000, Color3.fromRGB(100, 185, 245))
adaKuregi("AuroraShovel", "Aurora Shovel", 15, "snowkum", "Gizli", 100_000_000_000, Color3.fromRGB(110, 240, 230))

adaKuregi("EmberShovel", "Ember Shovel", 16, "alevkum", "Infernal", 500_000_000_000, Color3.fromRGB(255, 170, 70))
adaKuregi("MagmaShovel", "Magma Shovel", 17, "alevkum", "Infernal", 620_000_000_000, Color3.fromRGB(255, 145, 50))
adaKuregi("BlazeShovel", "Blaze Shovel", 18, "alevkum", "Infernal", 750_000_000_000, Color3.fromRGB(255, 120, 40))
adaKuregi("InfernoShovel", "Inferno Shovel", 19, "alevkum", "Infernal", 870_000_000_000, Color3.fromRGB(255, 95, 30))
adaKuregi("EruptionShovel", "Eruption Shovel", 20, "alevkum", "Infernal", 1_000_000_000_000, Color3.fromRGB(255, 70, 20))

Shovels.Default = "Wooden" :: ShovelId

function Shovels.get(id: ShovelId): ShovelInfo
	local info = Shovels.Info[id]
	assert(info, `bilinmeyen kurek: {tostring(id)}`)
	return info
end

function Shovels.next(id: ShovelId): ShovelInfo?
	local current = Shovels.get(id)
	for _, candidate in Shovels.Order do
		local info = Shovels.Info[candidate]
		if info.level == current.level + 1 then
			return info
		end
	end
	return nil
end

function Shovels.power(level: number): number
	if level <= 5 then
		return level
	end
	return 5 + (level - 5) / 5
end

function Shovels.forIsland(island: string?): { ShovelInfo }
	local out = {}
	for _, id in Shovels.Order do
		local info = Shovels.Info[id]
		if info.island == island then
			table.insert(out, info)
		end
	end
	table.sort(out, function(a, b)
		return a.level < b.level
	end)
	return out
end

return Shovels
