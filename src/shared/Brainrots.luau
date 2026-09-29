--!strict

local Rarity = require(script.Parent.Rarity)
local Condition = require(script.Parent.Condition)
local Mutations = require(script.Parent.Mutations)

export type BrainrotInfo = {
	name: string,
	rarity: Rarity.RarityId,
	incomeFactor: number,
	island: string,
	modelName: string?,
}

local Brainrots = {}

Brainrots.List = {

	{ name = "Tim Cheese", rarity = "Common", incomeFactor = 0.16, island = "kum" },
	{ name = "Pipi Kiwi", rarity = "Common", incomeFactor = 0.2, island = "kum" },
	{ name = "Pipi Potato", rarity = "Common", incomeFactor = 0.25, island = "kum" },
	{ name = "Swag Soda", rarity = "Common", incomeFactor = 0.29, island = "kum" },
	{ name = "W Or L", rarity = "Common", incomeFactor = 0.33, island = "kum" },
	{ name = "Matteo", rarity = "Common", incomeFactor = 0.37, island = "kum" },
	{ name = "Meowl", rarity = "Common", incomeFactor = 0.41, island = "kum" },
	{ name = "Chillin Chili", rarity = "Common", incomeFactor = 0.45, island = "kum" },
	{ name = "Bambini Crostini", rarity = "Common", incomeFactor = 0.49, island = "sekerkum" },
	{ name = "Banana Dancana", rarity = "Common", incomeFactor = 0.54, island = "sekerkum" },
	{ name = "Bananini Kittini", rarity = "Common", incomeFactor = 0.58, island = "sekerkum" },
	{ name = "Cachorrito Melonito", rarity = "Common", incomeFactor = 0.66, island = "snowkum" },
	{ name = "Avocadini Guffo", rarity = "Common", incomeFactor = 0.7, island = "snowkum" },
	{ name = "Lerulerulerule", rarity = "Common", incomeFactor = 0.74, island = "snowkum" },
	{ name = "Talpa Di Fero", rarity = "Common", incomeFactor = 0.78, island = "alevkum" },
	{ name = "Fluri Flura", rarity = "Common", incomeFactor = 0.83, island = "alevkum" },
	{ name = "Bananita Dolphinita", rarity = "Common", incomeFactor = 0.62, island = "deniz" },

	{ name = "Noo My Examen", rarity = "Rare", incomeFactor = 0.08, island = "kum" },
	{ name = "Yess My Examen", rarity = "Rare", incomeFactor = 0.14, island = "kum" },
	{ name = "Karkerkar Kurkur", rarity = "Rare", incomeFactor = 0.2, island = "kum" },
	{ name = "Ta Ta Ta Ta Sahur", rarity = "Rare", incomeFactor = 0.25, island = "kum" },
	{ name = "Brri Brri Bicus Dicus", rarity = "Rare", incomeFactor = 0.31, island = "kum" },
	{ name = "Nyannini Cattalini", rarity = "Rare", incomeFactor = 0.37, island = "kum" },
	{ name = "Cacto Hipopotamo", rarity = "Rare", incomeFactor = 0.43, island = "kum" },
	{ name = "Chef Crabracadabra", rarity = "Rare", incomeFactor = 0.49, island = "kum" },
	{ name = "Ganganzelli Trulala", rarity = "Rare", incomeFactor = 0.54, island = "sekerkum" },
	{ name = "Agarrini La Pallini", rarity = "Rare", incomeFactor = 0.6, island = "sekerkum" },
	{ name = "Lionel Cactuseli", rarity = "Rare", incomeFactor = 0.72, island = "snowkum" },
	{ name = "Gangster Footera", rarity = "Rare", incomeFactor = 0.78, island = "snowkum" },
	{ name = "Tric Trac Barabum", rarity = "Rare", incomeFactor = 0.83, island = "alevkum" },
	{ name = "Blueberrinni Octopusini", rarity = "Rare", incomeFactor = 0.66, island = "deniz" },

	{ name = "Pot Hotspot", rarity = "Secret", incomeFactor = 0.08, island = "alevkum" },
	{ name = "Smurfo Gatto", rarity = "Mythic", incomeFactor = 0.15, island = "kum" },
	{ name = "Rhino Toasterino", rarity = "Epic", incomeFactor = 0.22, island = "kum" },
	{ name = "Quesadilla Crocodila", rarity = "Epic", incomeFactor = 0.3, island = "kum" },
	{ name = "Tirilikalika Tirilikalako", rarity = "Epic", incomeFactor = 0.37, island = "kum" },
	{ name = "Torrtuginni Dragonfrutini", rarity = "Epic", incomeFactor = 0.44, island = "sekerkum" },
	{ name = "Strawberrelli Flamingelli", rarity = "Epic", incomeFactor = 0.52, island = "sekerkum" },
	{ name = "Pandaccini Bananini", rarity = "Epic", incomeFactor = 0.59, island = "snowkum" },
	{ name = "Ballerino Lololo", rarity = "Epic", incomeFactor = 0.66, island = "snowkum" },
	{ name = "Brr Brr Patapim", rarity = "Epic", incomeFactor = 0.73, island = "alevkum" },
	{ name = "Chimpanzini Bananini", rarity = "Epic", incomeFactor = 0.8, island = "alevkum" },

	{ name = "Zibra Zubra Zibralini", rarity = "Legendary", incomeFactor = 0.08, island = "kum" },
	{ name = "Pakrahmatmamat", rarity = "Legendary", incomeFactor = 0.15, island = "kum" },
	{ name = "Pakrahmatmatina", rarity = "Legendary", incomeFactor = 0.21, island = "kum" },
	{ name = "Madudung", rarity = "Legendary", incomeFactor = 0.28, island = "kum" },
	{ name = "Garamararam", rarity = "Secret", incomeFactor = 0.35, island = "snowkum" },
	{ name = "Gorillo Watermelondrillo", rarity = "Legendary", incomeFactor = 0.48, island = "sekerkum" },
	{ name = "Tigroligre Frutonni", rarity = "Legendary", incomeFactor = 0.55, island = "sekerkum" },
	{ name = "Illuminato Triangolo", rarity = "Legendary", incomeFactor = 0.68, island = "sekerkum" },
	{ name = "Trulimero Trulicina", rarity = "Legendary", incomeFactor = 0.75, island = "snowkum" },
	{ name = "Burbaloni Luliloli", rarity = "Legendary", incomeFactor = 0.82, island = "snowkum" },
	{ name = "Bombombini Gusini", rarity = "Legendary", incomeFactor = 0.88, island = "alevkum" },
	{ name = "Lirili Larila", rarity = "Legendary", incomeFactor = 0.95, island = "alevkum" },
	{ name = "Orcalero Orcala", rarity = "Cosmic", incomeFactor = 0.62, island = "deniz" },

	{ name = "Cavallo Virtuoso", rarity = "Mythic", incomeFactor = 0.08, island = "kum" },
	{ name = "Espresso Signora", rarity = "Cosmic", incomeFactor = 0.15, island = "snowkum" },
	{ name = "Orangutini Ananassini", rarity = "Mythic", incomeFactor = 0.22, island = "kum" },
	{ name = "Glorbo Fruttodrillo", rarity = "Mythic", incomeFactor = 0.3, island = "kum" },
	{ name = "Cocofanto Elefanto", rarity = "Mythic", incomeFactor = 0.37, island = "kum" },
	{ name = "Girafa Celeste", rarity = "Mythic", incomeFactor = 0.44, island = "sekerkum" },
	{ name = "Bobrito Bandito", rarity = "Mythic", incomeFactor = 0.52, island = "sekerkum" },
	{ name = "Odin Din Din Dun", rarity = "Mythic", incomeFactor = 0.59, island = "snowkum" },
	{ name = "Trippi Troppi Troppa Trippa", rarity = "Mythic", incomeFactor = 0.66, island = "snowkum" },
	{ name = "La Vacca Saturno Saturnita", rarity = "Mythic", incomeFactor = 0.8, island = "alevkum" },
	{ name = "Bombardiro Crocodilo", rarity = "Mythic", incomeFactor = 0.88, island = "alevkum" },
	{ name = "Tralalita Tralala", rarity = "Mythic", incomeFactor = 0.73, island = "deniz" },
	{ name = "Tralalero Tralala", rarity = "Mythic", incomeFactor = 0.95, island = "deniz" },

	{ name = "Six Seven", rarity = "Secret", incomeFactor = 0.69, island = "kum" },
	{ name = "1x1x1x1", rarity = "Secret", incomeFactor = 0.78, island = "kum" },
	{ name = "Chicleteirina Bicicleteirina", rarity = "Secret", incomeFactor = 0.08, island = "sekerkum" },
	{ name = "Chicleteira Bicicleteira", rarity = "Secret", incomeFactor = 0.17, island = "sekerkum" },
	{ name = "Job Job Job Sahur", rarity = "Gizli", incomeFactor = 0.25, island = "alevkum" },
	{ name = "Esok Sekolah", rarity = "Secret", incomeFactor = 0.34, island = "snowkum" },
	{ name = "La Grande Combinasion", rarity = "Infernal", incomeFactor = 0.95, island = "deniz" },
	{ name = "Triplito Tralaleritos", rarity = "Secret", incomeFactor = 0.43, island = "deniz" },
	{ name = "Los Tralaleritos", rarity = "Secret", incomeFactor = 0.86, island = "deniz" },

	{ name = "Ballerina Cappuccina", rarity = "Cosmic", incomeFactor = 0.95, island = "sekerkum" },
	{ name = "Trippi Troppi", rarity = "Epic", incomeFactor = 0.95, island = "kum" },
	{ name = "Tung Sahur", rarity = "Cosmic", incomeFactor = 0.95, island = "alevkum" },
	{ name = "Frigo Camelo", rarity = "Legendary", incomeFactor = 0.91, island = "deniz" },

	{ name = "Strawberry Elephant", rarity = "Gizli", incomeFactor = 0.41, island = "snowkum" },
	{ name = "Boneca Ambalabu", rarity = "Legendary", incomeFactor = 0.89, island = "kum" },
	{ name = "Cappuccino Assassino", rarity = "Gizli", incomeFactor = 0.88, island = "deniz" },

	{ name = "Dragon Cannelloni", rarity = "Infernal", incomeFactor = 0.52, island = "alevkum" },
	{ name = "Svinina Bombardino", rarity = "Epic", incomeFactor = 0.87, island = "kum" },

	{ name = "Tralaledon", rarity = "Abyssal", incomeFactor = 0.6, island = "deniz" },
} :: { BrainrotInfo }local byRarity: { [string]: { BrainrotInfo } } = {}
local byName: { [string]: BrainrotInfo } = {}

local byIsland: { [string]: { BrainrotInfo } } = {}

for _, info in Brainrots.List do
	local pool = byRarity[info.rarity]
	if not pool then
		pool = {}
		byRarity[info.rarity] = pool
	end
	table.insert(pool, info)
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
	snowkum = "snowkum",
	alevkum = "alevkum",
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
	assert(#pool > 0, `{rarityId} icin brainrot havuzu bos`)
	return pool[rng:NextInteger(1, #pool)]
end

function Brainrots.rollIsland(rarityId: Rarity.RarityId, island: string?, rng: Random): BrainrotInfo
	local pool = Brainrots.islandPool(rarityId, island)
	if #pool == 0 then
		pool = Brainrots.islandPool(rarityId, Brainrots.firstIslandOf(rarityId))
	end
	assert(#pool > 0, `{rarityId} icin brainrot havuzu bos`)
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
