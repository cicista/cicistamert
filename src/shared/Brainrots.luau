--!strict

local Rarity = require(script.Parent.Rarity)
local Condition = require(script.Parent.Condition)
local Mutations = require(script.Parent.Mutations)
local Petler = require(script.Parent.Petler)

export type BrainrotInfo = {
	name: string,
	rarity: Rarity.RarityId,
	incomeFactor: number,
	island: string,
	modelName: string?,
	pet: boolean?,
}

local Brainrots = {}

Brainrots.List = {} :: { BrainrotInfo }

for _, pet in Petler.liste() do
	if not Rarity.Info[pet.rarity :: Rarity.RarityId] then
		warn(`[Brainrots] pet "{pet.name}" has unknown rarity: {pet.rarity}`)
		continue
	end
	table.insert(Brainrots.List, {
		name = pet.name,
		rarity = pet.rarity :: Rarity.RarityId,
		incomeFactor = pet.incomeFactor,
		island = pet.island,
		modelName = pet.modelName,
		pet = true,
	})
end

local byRarity: { [string]: { BrainrotInfo } } = {}
local byName: { [string]: BrainrotInfo } = {}

local byIsland: { [string]: { BrainrotInfo } } = {}

for _, info in Brainrots.List do
	local pool = byRarity[info.rarity]
	if not pool then
		pool = {}
		byRarity[info.rarity] = pool
	end
	table.insert(pool, info)
	if byName[info.name] then
		warn(`[Brainrots] duplicate name in catalog: {info.name}`)
	end
	byName[info.name] = info

	local anahtar = `{info.rarity}|{string.lower(info.island)}`
	local adaHavuzu = byIsland[anahtar]
	if not adaHavuzu then
		adaHavuzu = {}
		byIsland[anahtar] = adaHavuzu
	end
	table.insert(adaHavuzu, info)
end

Brainrots.ByRarity = byRarity

function Brainrots.get(name: string): BrainrotInfo?
	return byName[name]
end

function Brainrots.pool(rarityId: Rarity.RarityId): { BrainrotInfo }
	return byRarity[rarityId] or {}
end

Brainrots.IslandOrder = { "kum", "sekerkum", "snowkum", "alevkum", "deniz" }

local adaSirasi: { [string]: number } = {}
for i, ada in Brainrots.IslandOrder do
	adaSirasi[ada] = i
end

local PARCA_ADI: { [string]: string } = {
	kum = "kum",
	sekerkum = "sekerkum",
	sakizkum = "sekerkum",
	snowkum = "snowkum",
	buzkum = "snowkum",
	alevkum = "alevkum",
	volkankum = "alevkum",
	water = "deniz",
	deniz = "deniz",
}

local MODEL_ADI: { [string]: string } = {
	mainisland = "kum",
	candyisland = "sekerkum",
	snowisland = "snowkum",
	volcanoisland = "alevkum",
}

function Brainrots.islandOf(node: Instance?): string
	local cursor = node
	local derinlik = 0

	while cursor and derinlik < 8 do
		local ad = string.lower(cursor.Name)
		local id = PARCA_ADI[ad] or MODEL_ADI[ad]
		if id then
			return id
		end
		cursor = cursor.Parent
		derinlik += 1
	end

	return Brainrots.IslandOrder[1]
end

function Brainrots.normalizeIsland(island: string?): string
	local ad = string.lower(island or "")
	return PARCA_ADI[ad] or MODEL_ADI[ad] or Brainrots.IslandOrder[1]
end

function Brainrots.islandPool(rarityId: Rarity.RarityId, island: string?): { BrainrotInfo }
	local sinir = adaSirasi[Brainrots.normalizeIsland(island)]

	local birikim = {}
	for _, brainrot in Brainrots.pool(rarityId) do
		local nerede = adaSirasi[string.lower(brainrot.island)]
		if nerede and nerede <= sinir then
			table.insert(birikim, brainrot)
		end
	end

	return birikim
end

function Brainrots.availableOn(rarityId: string, island: string?): boolean
	return #Brainrots.islandPool(rarityId :: any, island) > 0
end

Brainrots.IslandNames = {
	kum = "Main Island",
	sekerkum = "Candy Island",
	snowkum = "Snow Island",
	alevkum = "Lava Island",
	deniz = "The Sea",
}

function Brainrots.laterIsland(a: string?, b: string?): string
	local na, nb = Brainrots.normalizeIsland(a), Brainrots.normalizeIsland(b)
	return if adaSirasi[nb] > adaSirasi[na] then nb else na
end

function Brainrots.firstIslandOf(rarityId: string): string?
	local enErken: number? = nil
	for _, brainrot in Brainrots.pool(rarityId :: any) do
		local sira = adaSirasi[string.lower(brainrot.island)]
		if sira and (enErken == nil or sira < enErken) then
			enErken = sira
		end
	end
	return if enErken then Brainrots.IslandOrder[enErken] else nil
end

function Brainrots.clampRarity(rarityId: string, island: string?): string
	if Brainrots.availableOn(rarityId, island) then
		return rarityId
	end

	local info = Rarity.Info[rarityId :: any]
	if not info then
		return rarityId
	end

	local enIyi, enIyiSira = nil, -math.huge
	for _, id in Rarity.Order do
		local diger = Rarity.Info[id]
		if diger.order < info.order and diger.order > enIyiSira and Brainrots.availableOn(id, island) then
			enIyi, enIyiSira = id, diger.order
		end
	end

	return enIyi or rarityId
end

function Brainrots.roll(rarityId: Rarity.RarityId, rng: Random): BrainrotInfo
	local pool = Brainrots.pool(rarityId)
	assert(#pool > 0, `brainrot pool for {rarityId} is empty`)
	return pool[rng:NextInteger(1, #pool)]
end

function Brainrots.rollIsland(rarityId: Rarity.RarityId, island: string?, rng: Random): BrainrotInfo
	local pool = Brainrots.islandPool(rarityId, island)
	if #pool == 0 then
		pool = Brainrots.islandPool(rarityId, Brainrots.firstIslandOf(rarityId))
	end
	assert(#pool > 0, `brainrot pool for {rarityId} is empty`)
	return pool[rng:NextInteger(1, #pool)]
end

function Brainrots.income(
	name: string,
	conditionId: Condition.ConditionId,
	mutationId: Mutations.MutationId?
): number
	local info = byName[name]
	if not info then
		return 0
	end

	local rarity = Rarity.get(info.rarity)
	local base = rarity.incomeMin + (rarity.incomeMax - rarity.incomeMin) * info.incomeFactor
	return math.floor(base * Condition.get(conditionId).multiplier * Mutations.multiplier(mutationId))
end

function Brainrots.minIncome(rarityId: Rarity.RarityId, conditionId: Condition.ConditionId): number
	local pool = Brainrots.pool(rarityId)
	if #pool == 0 then
		return 0
	end

	local lowest = math.huge
	for _, info in pool do
		local income = Brainrots.income(info.name, conditionId)
		if income < lowest then
			lowest = income
		end
	end

	return if lowest < math.huge then lowest else 0
end

return Brainrots
