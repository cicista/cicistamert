--!strict

export type ConditionId = "Tiny" | "Small" | "Normal" | "Large" | "Huge"

export type ConditionInfo = {
	id: ConditionId,
	shortName: string,
	displayName: string,
	order: number,
	scale: number,
	multiplier: number,
	chance: number,
	color: Color3,
}

local Condition = {}

Condition.Order = { "Tiny", "Small", "Normal", "Large", "Huge" } :: { ConditionId }

Condition.Info = {
	Tiny = {
		id = "Tiny",
		shortName = "Tiny",
		displayName = "Tiny",
		order = 1,
		scale = 0.25,
		multiplier = 1,
		chance = 32,
		color = Color3.fromRGB(150, 92, 76),
	},

	Small = {
		id = "Small",
		shortName = "Small",
		displayName = "Small",
		order = 2,
		scale = 0.6,
		multiplier = 1.5,
		chance = 24,
		color = Color3.fromRGB(184, 148, 84),
	},

	Normal = {
		id = "Normal",
		shortName = "Regular",
		displayName = "Regular",
		order = 3,
		scale = 1,
		multiplier = 2,
		chance = 30,
		color = Color3.fromRGB(196, 196, 108),
	},

	Large = {
		id = "Large",
		shortName = "Large",
		displayName = "Large",
		order = 4,
		scale = 1.4,
		multiplier = 2.5,
		chance = 11,
		color = Color3.fromRGB(120, 200, 140),
	},

	Huge = {
		id = "Huge",
		shortName = "Huge",
		displayName = "Huge",
		order = 5,
		scale = 2,
		multiplier = 3,
		chance = 3,
		color = Color3.fromRGB(96, 208, 232),
	},
} :: { [ConditionId]: ConditionInfo }

Condition.Default = "Normal" :: ConditionId

function Condition.get(id: string?): ConditionInfo
	if id then
		local direct = Condition.Info[id :: ConditionId]
		if direct then
			return direct
		end
	end

	return Condition.Info[Condition.Default]
end

function Condition.scale(id: string?): number
	return Condition.get(id).scale
end

local USTUN_OLCEK: { [string]: number } = {
	Tiny = 1.0,
	Small = 1.2,
	Normal = 1.5,
	Large = 1.8,
	Huge = 2.2,
}

function Condition.scaleFor(id: string?, rarityOrder: number?): number
	if rarityOrder and rarityOrder >= 8 then
		return USTUN_OLCEK[Condition.get(id).id] or Condition.scale(id)
	end

	return Condition.scale(id)
end

function Condition.multiplier(id: string?): number
	return Condition.get(id).multiplier
end

function Condition.roll(rng: Random): ConditionId
	local roll = rng:NextNumber() * 100
	local cursor = 0

	for _, id in Condition.Order do
		cursor += Condition.Info[id].chance
		if roll <= cursor then
			return id
		end
	end

	return Condition.Default
end

return Condition
