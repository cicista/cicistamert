--!strict

local Condition = require(script.Parent.Condition)
local Mutations = require(script.Parent.Mutations)
local Rarity = require(script.Parent.Rarity)

local Fuse = {}

Fuse.Required = 3

Fuse.Chances = {
	same3 = 40,
	same2 = 25,
	mixed = 25,
}

Fuse.SuccessChance = Fuse.Chances.same3

Fuse.Timeout = 60

Fuse.Merge = {
	gatherTime = 1.4,
	flashTime = 0.35,
	burstTime = 1.1,
	holdTime = 1.1,

	shakeTime = 0.65,
	shakeStrength = 2.6,
}

function Fuse.mergeTime(): number
	local M = Fuse.Merge
	return M.gatherTime + M.flashTime + M.burstTime + M.holdTime
end

function Fuse.burstDelay(): number
	return Fuse.Merge.gatherTime + Fuse.Merge.flashTime
end

Fuse.VFX = {
	name = "FuseVFX",
	height = 3,
	lifetime = 3,
	burst = 60,
	stopAfter = 0.6,
	scaleByRarity = {
		Secret = 1.6,
	},

	charge = { "FuseCharge", "FuseCarge" },
	explosion = { "FuseExplosion" },
	fail = { "FuseFail" },
	preserveShading = true,
}

Fuse.Excluded = {
	Abyssal = true,
} :: { [string]: boolean }

function Fuse.sees(rarityId: string?): boolean
	return type(rarityId) == "string" and Rarity.Info[rarityId :: Rarity.RarityId] ~= nil and not Fuse.Excluded[rarityId]
end

function Fuse.nextRarity(rarityId: string): string?
	local info = Rarity.Info[rarityId :: Rarity.RarityId]
	if not info then
		return nil
	end

	for _, id in Rarity.Order do
		if Rarity.Info[id].order == info.order + 1 then
			if Fuse.Excluded[id] then
				return nil
			end
			return id
		end
	end

	return nil
end

export type SizeChance = {
	id: string,
	count: number,
	chance: number,
}

function Fuse.sizeChances(entries: { any }): { SizeChance }
	local total = #entries
	if total == 0 then
		return {}
	end

	local counts: { [string]: number } = {}
	for _, entry in entries do
		local id = Condition.get(entry.condition).id
		counts[id] = (counts[id] or 0) + 1
	end

	local out: { SizeChance } = {}
	for _, id in Condition.Order do
		local count = counts[id]
		if count then
			table.insert(out, { id = id, count = count, chance = count / total * 100 })
		end
	end

	return out
end

Fuse.Mutation = {
	chancePerItem = 10,
}

export type MutationChance = {
	id: string,
	count: number,
	chance: number,
}

function Fuse.mutationChances(entries: { any }): { MutationChance }
	local counts: { [string]: number } = {}

	for _, entry in entries do
		local info = Mutations.get(entry.mutation)
		if info.id ~= Mutations.Default then
			counts[info.id] = (counts[info.id] or 0) + 1
		end
	end

	local out: { MutationChance } = {}
	for _, id in Mutations.Order do
		local count = counts[id]
		if count then
			table.insert(out, { id = id, count = count, chance = count * Fuse.Mutation.chancePerItem })
		end
	end

	return out
end

function Fuse.rollMutation(entries: { any }, rng: Random): string
	local roll = rng:NextNumber() * 100
	local cursor = 0

	for _, entry in Fuse.mutationChances(entries) do
		cursor += entry.chance
		if roll <= cursor then
			return entry.id
		end
	end

	return Mutations.Default
end

function Fuse.rollSize(entries: { any }, rng: Random): string
	if #entries == 0 then
		return Condition.Default
	end

	local picked = entries[rng:NextInteger(1, #entries)]
	return Condition.get(picked.condition).id
end

function Fuse.chanceFor(entries: { any }): number
	local sayac: { [string]: number } = {}
	local enCok = 0
	for _, entry in entries do
		local ad = entry.name or (entry.item and entry.item.name)
		if type(ad) == "string" then
			sayac[ad] = (sayac[ad] or 0) + 1
			enCok = math.max(enCok, sayac[ad])
		end
	end

	if enCok >= 3 then
		return Fuse.Chances.same3
	elseif enCok == 2 then
		return Fuse.Chances.same2
	end
	return Fuse.Chances.mixed
end

function Fuse.rollSuccess(rng: Random, chance: number?): boolean
	return rng:NextNumber() * 100 < (chance or Fuse.SuccessChance)
end

return Fuse
