--!strict
--[[
	Brainrot GPS (dedektor) seviyeleri.

	Kurek minigame'i kolaylastirir; dedektor ise NE CIKACAGINI etkiler:
	  luck        -> yuksek rarity suzme cikma sansini carpar (Rarity.rollBeam)
	  scanRadius  -> etrafta suzme aranan yaricap
	  spawnChance -> her taramada suzme cikma yuzdesi
	  maxBeams    -> ayni anda kac suzme durabilir

	Kurekte oldugu gibi tek dedektor tasinir: yenisi alininca eskisi silinir.
]]

local Detectors = {}

export type DetectorId = "Basic" | "Pro" | "Quantum" | "Cosmic" | "Divine"

export type DetectorInfo = {
	id: DetectorId,
	displayName: string,
	level: number,
	rarity: string,
	price: number,
	-- Yuksek rarity suzmelerin agirlik carpani (1 = etkisiz)
	luck: number,
	scanRadius: number,
	spawnChance: number,
	maxBeams: number,
	color: Color3,
}

Detectors.Order = { "Basic", "Pro", "Quantum", "Cosmic", "Divine" } :: { DetectorId }

Detectors.Info = {
	Basic = {
		id = "Basic",
		displayName = "Basic GPS",
		level = 1,
		rarity = "Common",
		price = 0,
		luck = 1,
		scanRadius = 75,
		spawnChance = 35,
		maxBeams = 4,
		color = Color3.fromRGB(120, 132, 148),
	},

	Pro = {
		id = "Pro",
		displayName = "Pro GPS",
		level = 2,
		rarity = "Rare",
		price = 750_000,
		luck = 1.5,
		scanRadius = 75,
		spawnChance = 42,
		maxBeams = 5,
		color = Color3.fromRGB(74, 160, 246),
	},

	Quantum = {
		id = "Quantum",
		displayName = "Quantum GPS",
		level = 3,
		rarity = "Epic",
		price = 5_000_000,
		luck = 2,
		scanRadius = 75,
		spawnChance = 50,
		maxBeams = 6,
		color = Color3.fromRGB(168, 85, 232),
	},

	Cosmic = {
		id = "Cosmic",
		displayName = "Cosmic GPS",
		level = 4,
		rarity = "Legendary",
		price = 35_000_000,
		luck = 2.5,
		scanRadius = 75,
		spawnChance = 58,
		maxBeams = 7,
		color = Color3.fromRGB(255, 180, 50),
	},

	Divine = {
		id = "Divine",
		displayName = "Divine GPS",
		level = 5,
		rarity = "Mythic",
		price = 300_000_000,
		luck = 3,
		scanRadius = 75,
		spawnChance = 68,
		maxBeams = 8,
		color = Color3.fromRGB(255, 90, 110),
	},
} :: { [DetectorId]: DetectorInfo }

Detectors.Default = "Basic" :: DetectorId

function Detectors.get(id: DetectorId): DetectorInfo
	local info = Detectors.Info[id]
	assert(info, `bilinmeyen dedektor: {tostring(id)}`)
	return info
end

function Detectors.next(id: DetectorId): DetectorInfo?
	local current = Detectors.get(id)
	for _, candidate in Detectors.Order do
		local info = Detectors.Info[candidate]
		if info.level == current.level + 1 then
			return info
		end
	end
	return nil
end

return Detectors
