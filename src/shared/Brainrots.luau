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

		Ada kimligi: kum, sekerkum, snowkum, alevkum, deniz.
		Brainrot kendi adasindan VE ondan sonraki adalardan cikar; onceki
		adalardan asla (bkz. Brainrots.islandPool).

		Zeminden ada kimligine donusum Brainrots.islandOf icinde:
		MainIsland > kum, CandyIsland > sekerkum, SnowIsland > snowkum,
		VolcanoIsland > alevkum, denizdeki "water" parcalari -> deniz.
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
	-- 3. ada -- Snow Kum
	{ name = "Cachorrito Melonito", rarity = "Common", incomeFactor = 0.66, island = "snowkum" },
	{ name = "Avocadini Guffo", rarity = "Common", incomeFactor = 0.7, island = "snowkum" },
	{ name = "Lerulerulerule", rarity = "Common", incomeFactor = 0.74, island = "snowkum" },
	-- 4. ada -- Alev Kum
	{ name = "Talpa Di Fero", rarity = "Common", incomeFactor = 0.78, island = "alevkum" },
	{ name = "Fluri Flura", rarity = "Common", incomeFactor = 0.83, island = "alevkum" },
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
	-- 3. ada -- Snow Kum
	{ name = "Lionel Cactuseli", rarity = "Rare", incomeFactor = 0.72, island = "snowkum" },
	{ name = "Gangster Footera", rarity = "Rare", incomeFactor = 0.78, island = "snowkum" },
	-- 4. ada -- Alev Kum
	{ name = "Tric Trac Barabum", rarity = "Rare", incomeFactor = 0.83, island = "alevkum" },
	-- 5. ada -- Deniz (balikcilik)
	{ name = "Blueberrinni Octopusini", rarity = "Rare", incomeFactor = 0.66, island = "deniz" },

	------------------------------------------------------------------
	-- EPIC
	------------------------------------------------------------------
	-- 1. ada -- Kum
	{ name = "Pot Hotspot", rarity = "Secret", incomeFactor = 0.08, island = "alevkum" },
	{ name = "Smurfo Gatto", rarity = "Mythic", incomeFactor = 0.15, island = "kum" },
	{ name = "Rhino Toasterino", rarity = "Epic", incomeFactor = 0.22, island = "kum" },
	{ name = "Quesadilla Crocodila", rarity = "Epic", incomeFactor = 0.3, island = "kum" },
	{ name = "Tirilikalika Tirilikalako", rarity = "Epic", incomeFactor = 0.37, island = "kum" },
	-- 2. ada -- Seker Kum
	{ name = "Torrtuginni Dragonfrutini", rarity = "Epic", incomeFactor = 0.44, island = "sekerkum" },
	{ name = "Strawberrelli Flamingelli", rarity = "Epic", incomeFactor = 0.52, island = "sekerkum" },
	-- 3. ada -- Snow Kum
	{ name = "Pandaccini Bananini", rarity = "Epic", incomeFactor = 0.59, island = "snowkum" },
	{ name = "Ballerino Lololo", rarity = "Epic", incomeFactor = 0.66, island = "snowkum" },
	-- 4. ada -- Alev Kum
	{ name = "Brr Brr Patapim", rarity = "Epic", incomeFactor = 0.73, island = "alevkum" },
	{ name = "Chimpanzini Bananini", rarity = "Epic", incomeFactor = 0.8, island = "alevkum" },

	------------------------------------------------------------------
	-- LEGENDARY
	------------------------------------------------------------------
	-- 1. ada -- Kum
	{ name = "Zibra Zubra Zibralini", rarity = "Legendary", incomeFactor = 0.08, island = "kum" },
	{ name = "Pakrahmatmamat", rarity = "Legendary", incomeFactor = 0.15, island = "kum" },
	{ name = "Pakrahmatmatina", rarity = "Legendary", incomeFactor = 0.21, island = "kum" },
	{ name = "Madudung", rarity = "Legendary", incomeFactor = 0.28, island = "kum" },
	{ name = "Garamararam", rarity = "Secret", incomeFactor = 0.35, island = "snowkum" },
	-- 2. ada -- Seker Kum
	{ name = "Gorillo Watermelondrillo", rarity = "Legendary", incomeFactor = 0.48, island = "sekerkum" },
	{ name = "Tigroligre Frutonni", rarity = "Legendary", incomeFactor = 0.55, island = "sekerkum" },
	{ name = "Illuminato Triangolo", rarity = "Legendary", incomeFactor = 0.68, island = "sekerkum" },
	-- 3. ada -- Snow Kum
	{ name = "Trulimero Trulicina", rarity = "Legendary", incomeFactor = 0.75, island = "snowkum" },
	{ name = "Burbaloni Luliloli", rarity = "Legendary", incomeFactor = 0.82, island = "snowkum" },
	-- 4. ada -- Alev Kum
	{ name = "Bombombini Gusini", rarity = "Legendary", incomeFactor = 0.88, island = "alevkum" },
	{ name = "Lirili Larila", rarity = "Legendary", incomeFactor = 0.95, island = "alevkum" },
	-- 5. ada -- Deniz (balikcilik)
	{ name = "Orcalero Orcala", rarity = "Cosmic", incomeFactor = 0.62, island = "deniz" },

	------------------------------------------------------------------
	-- MYTHIC
	------------------------------------------------------------------
	-- 1. ada -- Kum
	{ name = "Cavallo Virtuoso", rarity = "Mythic", incomeFactor = 0.08, island = "kum" },
	{ name = "Espresso Signora", rarity = "Cosmic", incomeFactor = 0.15, island = "snowkum" },
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
	{ name = "La Vacca Saturno Saturnita", rarity = "Mythic", incomeFactor = 0.8, island = "alevkum" },
	{ name = "Bombardiro Crocodilo", rarity = "Mythic", incomeFactor = 0.88, island = "alevkum" },
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
	{ name = "Job Job Job Sahur", rarity = "Gizli", incomeFactor = 0.25, island = "alevkum" },
	{ name = "Esok Sekolah", rarity = "Secret", incomeFactor = 0.34, island = "snowkum" },
	-- 4. ada -- Alev Kum
	{ name = "La Grande Combinasion", rarity = "Infernal", incomeFactor = 0.95, island = "deniz" },
	-- 5. ada -- Deniz (balikcilik)
	{ name = "Triplito Tralaleritos", rarity = "Secret", incomeFactor = 0.43, island = "deniz" },
	{ name = "Los Tralaleritos", rarity = "Secret", incomeFactor = 0.86, island = "deniz" },

	------------------------------------------------------------------
	-- COSMIC
	------------------------------------------------------------------
	-- 2. ada -- Seker Kum
	{ name = "Ballerina Cappuccina", rarity = "Cosmic", incomeFactor = 0.95, island = "sekerkum" },
	-- 3. ada -- Snow Kum
	{ name = "Trippi Troppi", rarity = "Epic", incomeFactor = 0.95, island = "kum" },
	-- 4. ada -- Alev Kum
	{ name = "Tung Sahur", rarity = "Cosmic", incomeFactor = 0.95, island = "alevkum" },
	-- 5. ada -- Deniz (balikcilik)
	{ name = "Frigo Camelo", rarity = "Legendary", incomeFactor = 0.91, island = "deniz" },

	------------------------------------------------------------------
	-- GIZLI (EKRANDA SECRET)
	------------------------------------------------------------------
	-- 3. ada -- Snow Kum
	{ name = "Strawberry Elephant", rarity = "Gizli", incomeFactor = 0.41, island = "snowkum" },
	-- 4. ada -- Alev Kum
	{ name = "Boneca Ambalabu", rarity = "Legendary", incomeFactor = 0.89, island = "kum" },
	-- 5. ada -- Deniz (balikcilik)
	{ name = "Cappuccino Assassino", rarity = "Gizli", incomeFactor = 0.88, island = "deniz" },

	------------------------------------------------------------------
	-- INFERNAL
	------------------------------------------------------------------
	-- 4. ada -- Alev Kum
	{ name = "Dragon Cannelloni", rarity = "Infernal", incomeFactor = 0.52, island = "alevkum" },
	-- 5. ada -- Deniz (balikcilik)
	{ name = "Svinina Bombardino", rarity = "Epic", incomeFactor = 0.87, island = "kum" },

	------------------------------------------------------------------
	-- ABYSSAL
	------------------------------------------------------------------
	-- 5. ada -- Deniz (balikcilik)
	{ name = "Tralaledon", rarity = "Abyssal", incomeFactor = 0.6, island = "deniz" },
} :: { BrainrotInfo }local byRarity: { [string]: { BrainrotInfo } } = {}
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
	ADA SIRASI  --  tek dogru kaynak

	    kum > sekerkum > snowkum > alevkum > deniz

	Sonraki adalarda onceki adalarin brainrotlari da cikar; sonraki
	adalarin brainrotlari onceki adalardan HICBIR KOSULDA cikmaz.
]]
Brainrots.IslandOrder = { "kum", "sekerkum", "snowkum", "alevkum", "deniz" }

local adaSirasi: { [string]: number } = {}
for i, ada in Brainrots.IslandOrder do
	adaSirasi[ada] = i
end

--[[
	ZEMIN -> ADA KIMLIGI

	Kum parcalari ada modellerinin ICINDE:
	    MainIsland > kum         CandyIsland > sekerkum
	    SnowIsland > snowkum     VolcanoIsland > alevkum
	Denizin parcalari "water".

	Once parcanin kendi adina, bulunamazsa ust modellerin adina bakilir.

	TANINMAYAN ZEMIN (ornegin Terrain kumu) ILK ADA sayilir: en kisitli
	secenek, yanlis tahmin hicbir zaman sonraki adanin brainrotunu vermez.
]]
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

-- Ada adi (parca adi da olabilir) -> kimlik; bilinmeyen ilk ada
function Brainrots.normalizeIsland(island: string?): string
	local ad = string.lower(island or "")
	return PARCA_ADI[ad] or MODEL_ADI[ad] or Brainrots.IslandOrder[1]
end

--[[
	ADAYA GORE HAVUZ  --  BIRIKIMLI, SIZMAZ

	Kazidan cikan brainrot BURADAN seciliyor. Bir adanin havuzu = o adanin
	VE ondan ONCEKI butun adalarin o kademedeki brainrotlari. Sonraki
	adalardan hicbiri girmez. Butun kademeler icin ayni kural.

	Eskiden ada bilinmezse ya da havuz bossa BUTUN havuza dusuluyordu; main
	island'da diger adalarin brainrotlari bu yuzden cikiyordu. Artik bos
	havuz BOS doner: o adada o kademe yok demektir. Isinin rarity'si de
	buna gore seciliyor (bkz. Beams: yalnizca havuzu dolu kademeler dogar).
]]
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

-- Bu adada (onceki adalar dahil) bu kademeden en az bir brainrot var mi
function Brainrots.availableOn(rarityId: string, island: string?): boolean
	return #Brainrots.islandPool(rarityId :: any, island) > 0
end

-- Bir rarity havuzundan rastgele brainrot secer (ada ayrimi yok).
function Brainrots.roll(rarityId: Rarity.RarityId, rng: Random): BrainrotInfo
	local pool = Brainrots.pool(rarityId)
	assert(#pool > 0, `{rarityId} icin brainrot havuzu bos`)
	return pool[rng:NextInteger(1, #pool)]
end

--[[
	ADADAN rastgele brainrot secer. Kazi bunu kullanir.

	Havuz yalnizca ESKI kayitlarda bos gelebilir (ada bilgisi olmayan ya da
	kazildigi adada o kademe olmayan esya). Esya kaybolmasin diye YALNIZCA
	o durumda butun havuzdan secilir; yeni kazilarda isinin rarity'si adaya
	gore secildigi icin buraya dusulmez.
]]
function Brainrots.rollIsland(rarityId: Rarity.RarityId, island: string?, rng: Random): BrainrotInfo
	local pool = Brainrots.islandPool(rarityId, island)
	if #pool == 0 then
		pool = Brainrots.pool(rarityId)
	end
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
