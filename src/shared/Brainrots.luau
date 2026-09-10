--!strict
--[[
	Brainrot katalogu.

	Her brainrot bir rarity havuzuna aittir. GPS'te bir isik suzmesi kazildiginda
	o suzmenin rarity'sindeki havuzdan RASTGELE bir brainrot cikar.

	incomeFactor (0..1): brainrot'un kendi rarity araligindaki yeri.
	  0   -> Rarity.incomeMin
	  1   -> Rarity.incomeMax
	Ayni rarity icindeki brainrotlar boylece birbirinden ayrisir.

	Nihai saniyelik gelir:
	  lerp(rarity.incomeMin, rarity.incomeMax, incomeFactor)
	      * condition.multiplier * mutation.multiplier
]]

local Rarity = require(script.Parent.Rarity)
local Condition = require(script.Parent.Condition)
local Mutations = require(script.Parent.Mutations)

export type BrainrotInfo = {
	name: string,
	rarity: Rarity.RarityId,
	incomeFactor: number,
	-- ReplicatedStorage > Brainrots klasorunde bu isimde bir Model varsa kullanilir
	modelName: string?,
}

local Brainrots = {}

Brainrots.List = {
	-- Common
	{ name = "Tim Cheese", rarity = "Common", incomeFactor = 0.16 },
	{ name = "Pipi Kiwi", rarity = "Common", incomeFactor = 0.20 },
	{ name = "Pipi Potato", rarity = "Common", incomeFactor = 0.25 },
	{ name = "Swag Soda", rarity = "Common", incomeFactor = 0.29 },
	{ name = "W Or L", rarity = "Common", incomeFactor = 0.33 },
	{ name = "Matteo", rarity = "Common", incomeFactor = 0.37 },
	{ name = "Meowl", rarity = "Common", incomeFactor = 0.41 },
	{ name = "Chillin Chili", rarity = "Common", incomeFactor = 0.45 },
	{ name = "Bambini Crostini", rarity = "Common", incomeFactor = 0.49 },
	{ name = "Banana Dancana", rarity = "Common", incomeFactor = 0.54 },
	{ name = "Bananini Kittini", rarity = "Common", incomeFactor = 0.58 },
	{ name = "Bananita Dolphinita", rarity = "Common", incomeFactor = 0.62 },
	{ name = "Cachorrito Melonito", rarity = "Common", incomeFactor = 0.66 },
	{ name = "Avocadini Guffo", rarity = "Common", incomeFactor = 0.70 },
	{ name = "Lerulerulerule", rarity = "Common", incomeFactor = 0.74 },
	{ name = "Talpa Di Fero", rarity = "Common", incomeFactor = 0.78 },
	{ name = "Fluri Flura", rarity = "Common", incomeFactor = 0.83 },
	{ name = "Svinina Bombardino", rarity = "Common", incomeFactor = 0.87 },
	{ name = "Frigo Camelo", rarity = "Common", incomeFactor = 0.91 },
	{ name = "Trippi Troppi", rarity = "Common", incomeFactor = 0.95 },

	-- Rare
	{ name = "Noo My Examen", rarity = "Rare", incomeFactor = 0.08 },
	{ name = "Yess My Examen", rarity = "Rare", incomeFactor = 0.14 },
	{ name = "Karkerkar Kurkur", rarity = "Rare", incomeFactor = 0.20 },
	{ name = "Ta Ta Ta Ta Sahur", rarity = "Rare", incomeFactor = 0.25 },
	{ name = "Brri Brri Bicus Dicus", rarity = "Rare", incomeFactor = 0.31 },
	{ name = "Nyannini Cattalini", rarity = "Rare", incomeFactor = 0.37 },
	{ name = "Cacto Hipopotamo", rarity = "Rare", incomeFactor = 0.43 },
	{ name = "Chef Crabracadabra", rarity = "Rare", incomeFactor = 0.49 },
	{ name = "Ganganzelli Trulala", rarity = "Rare", incomeFactor = 0.54 },
	{ name = "Agarrini La Pallini", rarity = "Rare", incomeFactor = 0.60 },
	{ name = "Blueberrinni Octopusini", rarity = "Rare", incomeFactor = 0.66 },
	{ name = "Lionel Cactuseli", rarity = "Rare", incomeFactor = 0.72 },
	{ name = "Gangster Footera", rarity = "Rare", incomeFactor = 0.78 },
	{ name = "Tric Trac Barabum", rarity = "Rare", incomeFactor = 0.83 },
	{ name = "Boneca Ambalabu", rarity = "Rare", incomeFactor = 0.89 },
	{ name = "Tung Sahur", rarity = "Rare", incomeFactor = 0.95 },

	-- Epic
	{ name = "Pot Hotspot", rarity = "Epic", incomeFactor = 0.08 },
	{ name = "Smurfo Gatto", rarity = "Epic", incomeFactor = 0.15 },
	{ name = "Rhino Toasterino", rarity = "Epic", incomeFactor = 0.22 },
	{ name = "Quesadilla Crocodila", rarity = "Epic", incomeFactor = 0.30 },
	{ name = "Tirilikalika Tirilikalako", rarity = "Epic", incomeFactor = 0.37 },
	{ name = "Torrtuginni Dragonfrutini", rarity = "Epic", incomeFactor = 0.44 },
	{ name = "Strawberrelli Flamingelli", rarity = "Epic", incomeFactor = 0.52 },
	{ name = "Pandaccini Bananini", rarity = "Epic", incomeFactor = 0.59 },
	{ name = "Ballerino Lololo", rarity = "Epic", incomeFactor = 0.66 },
	{ name = "Brr Brr Patapim", rarity = "Epic", incomeFactor = 0.73 },
	{ name = "Chimpanzini Bananini", rarity = "Epic", incomeFactor = 0.80 },
	{ name = "Cappuccino Assassino", rarity = "Epic", incomeFactor = 0.88 },
	{ name = "Ballerina Cappuccina", rarity = "Epic", incomeFactor = 0.95 },

	-- Legendary
	{ name = "Zibra Zubra Zibralini", rarity = "Legendary", incomeFactor = 0.08 },
	{ name = "Pakrahmatmamat", rarity = "Legendary", incomeFactor = 0.15 },
	{ name = "Pakrahmatmatina", rarity = "Legendary", incomeFactor = 0.21 },
	{ name = "Madudung", rarity = "Legendary", incomeFactor = 0.28 },
	{ name = "Garamararam", rarity = "Legendary", incomeFactor = 0.35 },
	{ name = "Strawberry Elephant", rarity = "Legendary", incomeFactor = 0.41 },
	{ name = "Gorillo Watermelondrillo", rarity = "Legendary", incomeFactor = 0.48 },
	{ name = "Tigroligre Frutonni", rarity = "Legendary", incomeFactor = 0.55 },
	{ name = "Orcalero Orcala", rarity = "Legendary", incomeFactor = 0.62 },
	{ name = "Illuminato Triangolo", rarity = "Legendary", incomeFactor = 0.68 },
	{ name = "Trulimero Trulicina", rarity = "Legendary", incomeFactor = 0.75 },
	{ name = "Burbaloni Luliloli", rarity = "Legendary", incomeFactor = 0.82 },
	{ name = "Bombombini Gusini", rarity = "Legendary", incomeFactor = 0.88 },
	{ name = "Lirili Larila", rarity = "Legendary", incomeFactor = 0.95 },

	-- Mythic
	{ name = "Cavallo Virtuoso", rarity = "Mythic", incomeFactor = 0.08 },
	{ name = "Espresso Signora", rarity = "Mythic", incomeFactor = 0.15 },
	{ name = "Orangutini Ananassini", rarity = "Mythic", incomeFactor = 0.22 },
	{ name = "Glorbo Fruttodrillo", rarity = "Mythic", incomeFactor = 0.30 },
	{ name = "Cocofanto Elefanto", rarity = "Mythic", incomeFactor = 0.37 },
	{ name = "Girafa Celeste", rarity = "Mythic", incomeFactor = 0.44 },
	{ name = "Bobrito Bandito", rarity = "Mythic", incomeFactor = 0.52 },
	{ name = "Odin Din Din Dun", rarity = "Mythic", incomeFactor = 0.59 },
	{ name = "Trippi Troppi Troppa Trippa", rarity = "Mythic", incomeFactor = 0.66 },
	{ name = "Tralalita Tralala", rarity = "Mythic", incomeFactor = 0.73 },
	{ name = "La Vacca Saturno Saturnita", rarity = "Mythic", incomeFactor = 0.80 },
	{ name = "Bombardiro Crocodilo", rarity = "Mythic", incomeFactor = 0.88 },
	{ name = "Tralalero Tralala", rarity = "Mythic", incomeFactor = 0.95 },

	-- Secret
	{ name = "Chicleteirina Bicicleteirina", rarity = "Secret", incomeFactor = 0.08 },
	{ name = "Chicleteira Bicicleteira", rarity = "Secret", incomeFactor = 0.17 },
	{ name = "Job Job Job Sahur", rarity = "Secret", incomeFactor = 0.25 },
	{ name = "Esok Sekolah", rarity = "Secret", incomeFactor = 0.34 },
	{ name = "Triplito Tralaleritos", rarity = "Secret", incomeFactor = 0.43 },
	{ name = "Dragon Cannelloni", rarity = "Secret", incomeFactor = 0.52 },
	{ name = "Tralaledon", rarity = "Secret", incomeFactor = 0.60 },
	{ name = "Six Seven", rarity = "Secret", incomeFactor = 0.69 },
	{ name = "1x1x1x1", rarity = "Secret", incomeFactor = 0.78 },
	{ name = "Los Tralaleritos", rarity = "Secret", incomeFactor = 0.86 },
	{ name = "La Grande Combinasion", rarity = "Secret", incomeFactor = 0.95 },
} :: { BrainrotInfo }

-- rarity -> o rarity'deki brainrotlar
local byRarity: { [string]: { BrainrotInfo } } = {}
local byName: { [string]: BrainrotInfo } = {}

for _, info in Brainrots.List do
	local pool = byRarity[info.rarity]
	if not pool then
		pool = {}
		byRarity[info.rarity] = pool
	end
	table.insert(pool, info)
	byName[info.name] = info
end

Brainrots.ByRarity = byRarity

function Brainrots.get(name: string): BrainrotInfo?
	return byName[name]
end

function Brainrots.pool(rarityId: Rarity.RarityId): { BrainrotInfo }
	return byRarity[rarityId] or {}
end

-- Bir rarity havuzundan rastgele brainrot secer.
function Brainrots.roll(rarityId: Rarity.RarityId, rng: Random): BrainrotInfo
	local pool = Brainrots.pool(rarityId)
	assert(#pool > 0, `{rarityId} icin brainrot havuzu bos`)
	return pool[rng:NextInteger(1, #pool)]
end

--[[
	Bir brainrot + kondisyon icin saniyelik pasif geliri hesaplar.
	Base'e yerlestirildiginde bu deger saniyede Rot olarak eklenir.
]]
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

--[[
	Bir rarity havuzundaki EN DUSUK saniyelik gelir.
	Kimligi belirlenmemis (siyah) brainrotlarin satis degeri buna gore
	hesaplanir: icinden ne cikacagi bilinmedigi icin en kotu ihtimal esas alinir.
	Mutasyon da bilinmedigi icin hesaba katilmaz (en kotu ihtimal: Normal).
]]
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
