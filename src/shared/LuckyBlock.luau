--!strict

local Rarity = require(script.Parent.Rarity)
local Mutations = require(script.Parent.Mutations)

local LuckyBlock = {}

export type Tier = {
	id: string,
	displayName: string,
	modelName: string?,
	order: number,
	color: Color3,
	dropWeight: number,
	rarityWeights: { [string]: number },
	zorunluMutasyon: string?,
	mutationRolls: number,
}

LuckyBlock.Tiers = {
	{
		id = "Normal",
		displayName = "Lucky Block",
		modelName = "New Lucky Block",
		order = 1,
		color = Color3.fromRGB(255, 236, 90),
		dropWeight = 70,
		rarityWeights = {
			Rare = 30,
			Epic = 38,
			Legendary = 22,
			Mythic = 8,
			Secret = 2,
		},
		mutationRolls = 1,
	},
	{
		id = "Golden",
		displayName = "Golden Lucky Block",
		modelName = "New Gold Lucky Block",
		order = 2,
		color = Color3.fromRGB(255, 190, 40),
		dropWeight = 24,
		rarityWeights = {
			Epic = 28,
			Legendary = 36,
			Mythic = 24,
			Secret = 10,
			Cosmic = 2,
		},
		mutationRolls = 2,
	},
	{
		id = "Diamond",
		displayName = "Diamond Lucky Block",
		modelName = "New Diamond Lucky Block",
		order = 3,
		color = Color3.fromRGB(110, 230, 255),
		dropWeight = 6,
		rarityWeights = {
			Legendary = 30,
			Mythic = 36,
			Secret = 22,
			Cosmic = 9,
			Gizli = 3,
		},
		mutationRolls = 3,
	},
	{
		id = "Hacker",
		displayName = "Hacker Lucky Block",
		modelName = "Hacker Lucky Block",
		order = 4,
		color = Color3.fromRGB(60, 255, 110),
		dropWeight = 0,
		rarityWeights = {
			Mythic = 30,
			Secret = 33,
			Cosmic = 22,
			Gizli = 12,
			Infernal = 3,
		},
		mutationRolls = 4,
		zorunluMutasyon = "Hacker",
	},
} :: { Tier }

LuckyBlock.Default = "Normal"

LuckyBlock.Event = {
	enabled = true,

	interval = 3600,
	uyariSaniyeleri = { 300, 60 },
	zeminAdi = "luckyzemin",

	blokSayisi = 5,

	tierSanslari = {
		{ tier = "Hacker", sans = 0.5 },
		{ tier = "Diamond", sans = 10 },
		{ tier = "Golden", sans = 30 },
	},

	anaAdalar = {
		{ kum = "kum", ad = "Main Island", tierSanslari = {} },
		{ kum = "sekerkum", ad = "Candy Island", tierSanslari = {} },
		{
			kum = "snowkum",
			ad = "Snow Island",
			tierSanslari = {
				{ tier = "Diamond", sans = 5 },
				{ tier = "Golden", sans = 25 },
			},
		},
		{
			kum = "alevkum",
			ad = "Volcano Island",
			tierSanslari = {
				{ tier = "Diamond", sans = 10 },
				{ tier = "Golden", sans = 35 },
			},
		},
	},

	nitelikSonraki = "LuckyYagmurSonraki",
	nitelikBitis = "LuckyYagmurBitis",
	nitelikKalan = "LuckyYagmurKalan",

	oyuncuBasiLimit = 1,

	gorunum = {
		Normal = { olcek = 1, isik = 26 },
		Golden = { olcek = 1.45, isik = 45, kivilcim = true },
		Diamond = { olcek = 1.7, isik = 60, kivilcim = true, halka = true },
		Hacker = { olcek = 1.7, isik = 60, kivilcim = true, halka = true },
	},

	despawn = 300,
	beaconHeight = 7,
	beaconWidth = 7,
	pickupDistance = 12,
}

LuckyBlock.Wheel = {
	cellCount = 58,
	winnerIndex = 48,
	spinTime = 4,

	pause = 0.7,

	revealCellCount = 40,
	revealWinnerIndex = 33,
	revealSpinTime = 4,

	spinSounds = { "WheelSpin", "SpinWheel", "SpinSound", "Wheel Spin", "Spin" },

	settle = 0.4,
}

function LuckyBlock.totalSpinTime(): number
	local W = LuckyBlock.Wheel
	return W.spinTime + W.pause + W.revealSpinTime + W.settle
end

local byId: { [string]: Tier } = {}
for _, tier in LuckyBlock.Tiers do
	byId[tier.id] = tier
end

function LuckyBlock.toplamBlok(): number
	return LuckyBlock.Event.blokSayisi + #LuckyBlock.Event.anaAdalar
end

function LuckyBlock.sonrakiYagmur(simdi: number): number
	local aralik = LuckyBlock.Event.interval
	return (math.floor(simdi / aralik) + 1) * aralik
end

function LuckyBlock.etkinlikKademesi(rng: Random, sanslar: { { tier: string, sans: number } }?): string
	for _, satir in sanslar or LuckyBlock.Event.tierSanslari do
		if rng:NextNumber() * 100 < satir.sans then
			return satir.tier
		end
	end
	return LuckyBlock.Default
end

function LuckyBlock.get(id: string?): Tier
	return byId[id or LuckyBlock.Default] or LuckyBlock.Tiers[1]
end

function LuckyBlock.exists(id: string?): boolean
	return id ~= nil and byId[id] ~= nil
end

function LuckyBlock.rollTier(rng: Random): string
	local total = 0
	for _, tier in LuckyBlock.Tiers do
		total += tier.dropWeight
	end

	local roll = rng:NextNumber() * total
	local cursor = 0
	for _, tier in LuckyBlock.Tiers do
		cursor += tier.dropWeight
		if roll <= cursor then
			return tier.id
		end
	end

	return LuckyBlock.Default
end

function LuckyBlock.rollRarity(tierId: string, rng: Random): string
	local tier = LuckyBlock.get(tierId)

	local pool: { string } = {}
	local total = 0
	for _, id in Rarity.Order do
		local weight = tier.rarityWeights[id]
		if weight and weight > 0 then
			table.insert(pool, id)
			total += weight
		end
	end

	if #pool == 0 then
		return "Epic"
	end

	local roll = rng:NextNumber() * total
	local cursor = 0
	for _, id in pool do
		cursor += tier.rarityWeights[id]
		if roll <= cursor then
			return id
		end
	end

	return pool[#pool]
end

function LuckyBlock.rollMutation(tierId: string, rng: Random): string
	local tier = LuckyBlock.get(tierId)
	if tier and tier.zorunluMutasyon then
		return tier.zorunluMutasyon
	end
	return Mutations.roll(rng)
end

return LuckyBlock
