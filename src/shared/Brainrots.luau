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
	--[[
		HANGI ADADAN CIKAR

		Sand parcasinin ADI: kum, sekerkum, snowkum, gizlikum, deniz.
		Bir brainrot YALNIZCA kendi adasindan cikar; ayni rarity farkli
		adalarda farkli brainrotlar verir.

		NOT: 4. ada oyunda "Alev Kum" diye geciyor ama Studio'daki kum
		parcasinin adi "gizlikum" -- eslesme o ad uzerinden oldugu icin
		kimlik oyle birakildi. Studio'da yeniden adlandirirsan burayi ve
		OyunConfig / LuckyBlock icindeki listeleri birlikte guncelle.
	]]
	island: string,
	-- ReplicatedStorage > Brainrots klasorunde bu isimde bir Model varsa kullanilir
	modelName: string?,
}

local Brainrots = {}

Brainrots.List = {

	------------------------------------------------------------------
	-- COMMON
	------------------------------------------------------------------
	-- 1. ada -- Kum
	{ name = "Tim Cheese", rarity = "Common", incomeFactor = 0.16, island = "kum" },
	{ name = "Pipi Kiwi", rarity = "Common", incomeFactor = 0.2, island = "kum" },
	{ name = "Pipi Potato", rarity = "Common", incomeFactor = 0.25, island = "kum" },
	{ name = "Swag Soda", rarity = "Common", incomeFactor = 0.29, island = "kum" },
	{ name = "W Or L", rarity = "Common", incomeFactor = 0.33, island = "kum" },
	{ name = "Matteo", rarity = "Common", incomeFactor = 0.37, island = "kum" },
	{ name = "Meowl", rarity = "Common", incomeFactor = 0.41, island = "kum" },
	{ name = "Chillin Chili", rarity = "Common", incomeFactor = 0.45, island = "kum" },
	-- 2. ada -- Seker Kum
	{ name = "Bambini Crostini", rarity = "Common", incomeFactor = 0.49, island = "sekerkum" },
	{ name = "Banana Dancana", rarity = "Common", incomeFactor = 0.54, island = "sekerkum" },
	{ name = "Bananini Kittini", rarity = "Common", incomeFactor = 0.58, island = "sekerkum" },
	{ name = "Cachorrito Melonito", rarity = "Common", incomeFactor = 0.66, island = "sekerkum" },
	-- 3. ada -- Snow Kum
	{ name = "Avocadini Guffo", rarity = "Common", incomeFactor = 0.7, island = "snowkum" },
	{ name = "Lerulerulerule", rarity = "Common", incomeFactor = 0.74, island = "snowkum" },
	{ name = "Talpa Di Fero", rarity = "Common", incomeFactor = 0.78, island = "snowkum" },
	{ name = "Fluri Flura", rarity = "Common", incomeFactor = 0.83, island = "snowkum" },
	-- 4. ada -- Alev Kum
	{ name = "Svinina Bombardino", rarity = "Common", incomeFactor = 0.87, island = "gizlikum" },
	{ name = "Frigo Camelo", rarity = "Common", incomeFactor = 0.91, island = "gizlikum" },
	{ name = "Trippi Troppi", rarity = "Common", incomeFactor = 0.95, island = "gizlikum" },
	-- 5. ada -- Deniz (balikcilik)
	{ name = "Bananita Dolphinita", rarity = "Common", incomeFactor = 0.62, island = "deniz" },

	------------------------------------------------------------------
	-- RARE
	------------------------------------------------------------------
	-- 1. ada -- Kum
	{ name = "Noo My Examen", rarity = "Rare", incomeFactor = 0.08, island = "kum" },
	{ name = "Yess My Examen", rarity = "Rare", incomeFactor = 0.14, island = "kum" },
	{ name = "Karkerkar Kurkur", rarity = "Rare", incomeFactor = 0.2, island = "kum" },
	{ name = "Ta Ta Ta Ta Sahur", rarity = "Rare", incomeFactor = 0.25, island = "kum" },
	{ name = "Brri Brri Bicus Dicus", rarity = "Rare", incomeFactor = 0.31, island = "kum" },
	{ name = "Nyannini Cattalini", rarity = "Rare", incomeFactor = 0.37, island = "kum" },
	{ name = "Cacto Hipopotamo", rarity = "Rare", incomeFactor = 0.43, island = "kum" },
	{ name = "Chef Crabracadabra", rarity = "Rare", incomeFactor = 0.49, island = "kum" },
	-- 2. ada -- Seker Kum
	{ name = "Ganganzelli Trulala", rarity = "Rare", incomeFactor = 0.54, island = "sekerkum" },
	{ name = "Agarrini La Pallini", rarity = "Rare", incomeFactor = 0.6, island = "sekerkum" },
	{ name = "Lionel Cactuseli", rarity = "Rare", incomeFactor = 0.72, island = "sekerkum" },
	-- 3. ada -- Snow Kum
	{ name = "Gangster Footera", rarity = "Rare", incomeFactor = 0.78, island = "snowkum" },
	{ name = "Tric Trac Barabum", rarity = "Rare", incomeFactor = 0.83, island = "snowkum" },
	-- 4. ada -- Alev Kum
	{ name = "Boneca Ambalabu", rarity = "Rare", incomeFactor = 0.89, island = "gizlikum" },
	{ name = "Tung Sahur", rarity = "Rare", incomeFactor = 0.95, island = "gizlikum" },
	-- 5. ada -- Deniz (balikcilik)
	{ name = "Blueberrinni Octopusini", rarity = "Rare", incomeFactor = 0.66, island = "deniz" },

	------------------------------------------------------------------
	-- EPIC
	------------------------------------------------------------------
	-- 1. ada -- Kum
	{ name = "Pot Hotspot", rarity = "Epic", incomeFactor = 0.08, island = "kum" },
	{ name = "Smurfo Gatto", rarity = "Epic", incomeFactor = 0.15, island = "kum" },
	{ name = "Rhino Toasterino", rarity = "Epic", incomeFactor = 0.22, island = "kum" },
	{ name = "Quesadilla Crocodila", rarity = "Epic", incomeFactor = 0.3, island = "kum" },
	{ name = "Tirilikalika Tirilikalako", rarity = "Epic", incomeFactor = 0.37, island = "kum" },
	-- 2. ada -- Seker Kum
	{ name = "Torrtuginni Dragonfrutini", rarity = "Epic", incomeFactor = 0.44, island = "sekerkum" },
	{ name = "Strawberrelli Flamingelli", rarity = "Epic", incomeFactor = 0.52, island = "sekerkum" },
	{ name = "Pandaccini Bananini", rarity = "Epic", incomeFactor = 0.59, island = "sekerkum" },
	-- 3. ada -- Snow Kum
	{ name = "Ballerino Lololo", rarity = "Epic", incomeFactor = 0.66, island = "snowkum" },
	{ name = "Brr Brr Patapim", rarity = "Epic", incomeFactor = 0.73, island = "snowkum" },
	-- 4. ada -- Alev Kum
	{ name = "Chimpanzini Bananini", rarity = "Epic", incomeFactor = 0.8, island = "gizlikum" },
	{ name = "Cappuccino Assassino", rarity = "Epic", incomeFactor = 0.88, island = "gizlikum" },

	------------------------------------------------------------------
	-- LEGENDARY
	------------------------------------------------------------------
	-- 1. ada -- Kum
	{ name = "Zibra Zubra Zibralini", rarity = "Legendary", incomeFactor = 0.08, island = "kum" },
	{ name = "Pakrahmatmamat", rarity = "Legendary", incomeFactor = 0.15, island = "kum" },
	{ name = "Pakrahmatmatina", rarity = "Legendary", incomeFactor = 0.21, island = "kum" },
	{ name = "Madudung", rarity = "Legendary", incomeFactor = 0.28, island = "kum" },
	{ name = "Garamararam", rarity = "Legendary", incomeFactor = 0.35, island = "kum" },
	-- 2. ada -- Seker Kum
	{ name = "Gorillo Watermelondrillo", rarity = "Legendary", incomeFactor = 0.48, island = "sekerkum" },
	{ name = "Tigroligre Frutonni", rarity = "Legendary", incomeFactor = 0.55, island = "sekerkum" },
	{ name = "Illuminato Triangolo", rarity = "Legendary", incomeFactor = 0.68, island = "sekerkum" },
	-- 3. ada -- Snow Kum
	{ name = "Trulimero Trulicina", rarity = "Legendary", incomeFactor = 0.75, island = "snowkum" },
	{ name = "Burbaloni Luliloli", rarity = "Legendary", incomeFactor = 0.82, island = "snowkum" },
	-- 4. ada -- Alev Kum
	{ name = "Bombombini Gusini", rarity = "Legendary", incomeFactor = 0.88, island = "gizlikum" },
	{ name = "Lirili Larila", rarity = "Legendary", incomeFactor = 0.95, island = "gizlikum" },
	-- 5. ada -- Deniz (balikcilik)
	{ name = "Orcalero Orcala", rarity = "Legendary", incomeFactor = 0.62, island = "deniz" },

	------------------------------------------------------------------
	-- MYTHIC
	------------------------------------------------------------------
	-- 1. ada -- Kum
	{ name = "Cavallo Virtuoso", rarity = "Mythic", incomeFactor = 0.08, island = "kum" },
	{ name = "Espresso Signora", rarity = "Mythic", incomeFactor = 0.15, island = "kum" },
	{ name = "Orangutini Ananassini", rarity = "Mythic", incomeFactor = 0.22, island = "kum" },
	{ name = "Glorbo Fruttodrillo", rarity = "Mythic", incomeFactor = 0.3, island = "kum" },
	{ name = "Cocofanto Elefanto", rarity = "Mythic", incomeFactor = 0.37, island = "kum" },
	-- 2. ada -- Seker Kum
	{ name = "Girafa Celeste", rarity = "Mythic", incomeFactor = 0.44, island = "sekerkum" },
	{ name = "Bobrito Bandito", rarity = "Mythic", incomeFactor = 0.52, island = "sekerkum" },
	-- 3. ada -- Snow Kum
	{ name = "Odin Din Din Dun", rarity = "Mythic", incomeFactor = 0.59, island = "snowkum" },
	{ name = "Trippi Troppi Troppa Trippa", rarity = "Mythic", incomeFactor = 0.66, island = "snowkum" },
	-- 4. ada -- Alev Kum
	{ name = "La Vacca Saturno Saturnita", rarity = "Mythic", incomeFactor = 0.8, island = "gizlikum" },
	{ name = "Bombardiro Crocodilo", rarity = "Mythic", incomeFactor = 0.88, island = "gizlikum" },
	-- 5. ada -- Deniz (balikcilik)
	{ name = "Tralalita Tralala", rarity = "Mythic", incomeFactor = 0.73, island = "deniz" },
	{ name = "Tralalero Tralala", rarity = "Mythic", incomeFactor = 0.95, island = "deniz" },

	------------------------------------------------------------------
	-- SECRET (EKRANDA DIVINE)
	------------------------------------------------------------------
	-- 1. ada -- Kum
	{ name = "Six Seven", rarity = "Secret", incomeFactor = 0.69, island = "kum" },
	{ name = "1x1x1x1", rarity = "Secret", incomeFactor = 0.78, island = "kum" },
	-- 2. ada -- Seker Kum
	{ name = "Chicleteirina Bicicleteirina", rarity = "Secret", incomeFactor = 0.08, island = "sekerkum" },
	{ name = "Chicleteira Bicicleteira", rarity = "Secret", incomeFactor = 0.17, island = "sekerkum" },
	-- 3. ada -- Snow Kum
	{ name = "Job Job Job Sahur", rarity = "Secret", incomeFactor = 0.25, island = "snowkum" },
	{ name = "Esok Sekolah", rarity = "Secret", incomeFactor = 0.34, island = "snowkum" },
	-- 4. ada -- Alev Kum
	{ name = "La Grande Combinasion", rarity = "Secret", incomeFactor = 0.95, island = "gizlikum" },
	-- 5. ada -- Deniz (balikcilik)
	{ name = "Triplito Tralaleritos", rarity = "Secret", incomeFactor = 0.43, island = "deniz" },
	{ name = "Los Tralaleritos", rarity = "Secret", incomeFactor = 0.86, island = "deniz" },

	------------------------------------------------------------------
	-- COSMIC
	------------------------------------------------------------------
	-- 2. ada -- Seker Kum
	{ name = "Ballerina Cappuccina", rarity = "Cosmic", incomeFactor = 0.95, island = "sekerkum" },

	------------------------------------------------------------------
	-- GIZLI (EKRANDA SECRET)
	------------------------------------------------------------------
	-- 3. ada -- Snow Kum
	{ name = "Strawberry Elephant", rarity = "Gizli", incomeFactor = 0.41, island = "snowkum" },

	------------------------------------------------------------------
	-- INFERNAL
	------------------------------------------------------------------
	-- 4. ada -- Alev Kum
	{ name = "Dragon Cannelloni", rarity = "Infernal", incomeFactor = 0.52, island = "gizlikum" },

	------------------------------------------------------------------
	-- ABYSSAL
	------------------------------------------------------------------
	-- 5. ada -- Deniz (balikcilik)
	{ name = "Tralaledon", rarity = "Abyssal", incomeFactor = 0.6, island = "deniz" },
} :: { BrainrotInfo }
-- rarity -> o rarity'deki brainrotlar
local byRarity: { [string]: { BrainrotInfo } } = {}
local byName: { [string]: BrainrotInfo } = {}

-- "rarity|ada" -> o adadaki o kademenin brainrotlari
local byIsland: { [string]: { BrainrotInfo } } = {}

for _, info in Brainrots.List do
	local pool = byRarity[info.rarity]
	if not pool then
		pool = {}
		byRarity[info.rarity] = pool
	end
	table.insert(pool, info)
	byName[info.name] = info

	-- Adaya ozel havuz: kazi brainrotu buradan seciyor
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

--[[
	RARITY HAVUZU  (butun adalar)

	Ada ayrimi gerekmeyen yerler icin: Fuse ciktisi, Lucky Block odulu,
	Detective'in tahmin listesi, admin paneli. Oralarda "hangi adadasin"
	sorusunun karsiligi yok.
]]
function Brainrots.pool(rarityId: Rarity.RarityId): { BrainrotInfo }
	return byRarity[rarityId] or {}
end

--[[
	ADAYA OZEL HAVUZ

	Kazidan cikan brainrot BURADAN seciliyor: ayni rarity her adada farkli
	brainrotlar veriyor, yani oyuncu ilerledikce yeni isimler goruyor.

	Ada bilinmiyorsa ya da o adada o kademeden brainrot yoksa butun havuza
	dusulur -- kazi hicbir kosulda bos donmemeli.
]]
function Brainrots.islandPool(rarityId: Rarity.RarityId, island: string?): { BrainrotInfo }
	if not island then
		return Brainrots.pool(rarityId)
	end

	local pool = byIsland[`{rarityId}|{string.lower(island)}`]
	if pool and #pool > 0 then
		return pool
	end

	return Brainrots.pool(rarityId)
end

-- Bir rarity havuzundan rastgele brainrot secer (ada ayrimi yok).
function Brainrots.roll(rarityId: Rarity.RarityId, rng: Random): BrainrotInfo
	local pool = Brainrots.pool(rarityId)
	assert(#pool > 0, `{rarityId} icin brainrot havuzu bos`)
	return pool[rng:NextInteger(1, #pool)]
end

--[[
	ADADAN rastgele brainrot secer. Kazi bunu kullanir.
]]
function Brainrots.rollIsland(rarityId: Rarity.RarityId, island: string?, rng: Random): BrainrotInfo
	local pool = Brainrots.islandPool(rarityId, island)
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
