--!strict

export type RarityId =
	"Common"
	| "Rare"
	| "Epic"
	| "Legendary"
	| "Mythic"
	| "Secret"
	| "Cosmic"
	| "Gizli"
	| "Infernal"
	| "Abyssal"

export type RarityInfo = {
	id: RarityId,
	displayName: string,
	order: number,
	color: Color3,
	beamChance: number,
	luckExp: number?,
	incomeMin: number,
	incomeMax: number,
	revealTime: number,
}
local Divine = require(script.Parent.Divine)
local Ores = require(script.Parent.Ores)

local Rarity = {}

Rarity.Order = {
	"Common",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Secret",
	"Cosmic",
	"Gizli",
	"Infernal",
	"Abyssal",
} :: { RarityId }

Rarity.Info = {
	Common = {
		id = "Common",
		displayName = "Common",
		order = 1,
		color = Color3.fromRGB(200, 200, 200),
		beamChance = 62,
		luckExp = -0.6,
		incomeMin = 5,
		incomeMax = 25,
		revealTime = 1.5,
	},

	Rare = {
		id = "Rare",
		displayName = "Rare",
		order = 2,
		color = Color3.fromRGB(80, 160, 255),
		beamChance = 25,
		luckExp = -0.3,
		incomeMin = 50,
		incomeMax = 250,
		revealTime = 2.5,
	},

	Epic = {
		id = "Epic",
		displayName = "Epic",
		order = 3,
		color = Color3.fromRGB(180, 100, 255),
		beamChance = 9,
		luckExp = 0.4,
		incomeMin = 500,
		incomeMax = 2_500,
		revealTime = 4,
	},

	Legendary = {
		id = "Legendary",
		displayName = "Legendary",
		order = 4,
		color = Color3.fromRGB(255, 240, 150),
		beamChance = 3,
		luckExp = 0.7,
		incomeMin = 5_000,
		incomeMax = 25_000,
		revealTime = 6,
	},

	Mythic = {
		id = "Mythic",
		displayName = "Mythic",
		order = 5,
		color = Color3.fromRGB(255, 70, 90),
		beamChance = 0.75,
		luckExp = 1.0,
		incomeMin = 50_000,
		incomeMax = 250_000,
		revealTime = 9,
	},

	Secret = {
		id = "Secret",
		displayName = "Divine",
		order = 6,
		color = Color3.fromRGB(255, 190, 60),
		beamChance = 0.3,
		luckExp = 1.2,
		incomeMin = 500_000,
		incomeMax = 2_500_000,
		revealTime = 120,
	},

	Cosmic = {
		id = "Cosmic",
		displayName = "Cosmic",
		order = 7,
		color = Color3.fromRGB(138, 43, 226),
		beamChance = 0.0504,
		luckExp = 1.4,
		incomeMin = 5_000_000,
		incomeMax = 25_000_000,
		revealTime = 480,
	},

	Gizli = {
		id = "Gizli",
		displayName = "Secret",
		order = 8,
		color = Color3.fromRGB(24, 24, 28),
		beamChance = 0.0132,
		luckExp = 1.6,
		incomeMin = 50_000_000,
		incomeMax = 250_000_000,
		revealTime = 900,
	},

	Infernal = {
		id = "Infernal",
		displayName = "Infernal",
		order = 9,
		color = Color3.fromRGB(255, 102, 20),
		beamChance = 0.00309,
		luckExp = 1.8,
		incomeMin = 500_000_000,
		incomeMax = 2_500_000_000,
		revealTime = 1800,
	},

	Abyssal = {
		id = "Abyssal",
		displayName = "Abyssal",
		order = 10,
		color = Color3.fromRGB(12, 62, 140),
		beamChance = 0.0001482,
		luckExp = 2.0,
		incomeMin = 5_000_000_000,
		incomeMax = 25_000_000_000,
		revealTime = 3600,
	},
} :: { [RarityId]: RarityInfo }

Rarity.LuckyBlock = {
	id = "LuckyBlock",
	displayName = "Lucky Block",
	colorA = Color3.fromRGB(255, 236, 90),
	colorB = Color3.fromRGB(120, 220, 255),
	beamChance = 0,
}

function Rarity.get(id: RarityId): RarityInfo
	local info = Rarity.Info[id]
	assert(info, `unknown rarity: {tostring(id)}`)
	return info
end

Rarity.LabelScaleMax = 1.5

function Rarity.modelScale(id: string?): number
	local info = if id then Rarity.Info[id :: RarityId] else nil
	return if info and info.order >= 7 then 2 else 1
end

function Rarity.textColor(id: string?): Color3
	local color = Rarity.color(id or "")
	local _, _, parlaklik = color:ToHSV()

	if parlaklik < 0.25 then
		return Color3.fromRGB(245, 245, 250)
	end

	return color
end

function Rarity.labelScale(id: string?): number
	local info = if id then Rarity.Info[id :: RarityId] else nil
	if not info or info.order <= 6 then
		return 1
	end

	local sonSira = #Rarity.Order
	local adim = (Rarity.LabelScaleMax - 1) / math.max(sonSira - 6, 1)

	return 1 + adim * (info.order - 6)
end

function Rarity.color(id: string): Color3
	local info = Rarity.Info[id :: RarityId]
	return if info then info.color else Color3.new(1, 1, 1)
end

function Rarity.displayName(id: string): string
	local info = Rarity.Info[id :: RarityId]
	return if info then info.displayName else id
end

function Rarity.labelText(id: string): string
	local info = Rarity.Info[id :: RarityId]
	if not info then
		return id
	end

	if info.order >= 6 then
		return string.upper(info.displayName)
	end

	return info.displayName
end

function Rarity.isGlowing(id: string): boolean
	local info = Rarity.Info[id :: RarityId]
	return info ~= nil and info.order >= 3
end
function Rarity.isDivine(id: string): boolean
	return Divine.Flashes[id] ~= nil
end

function Rarity.isBeamKind(kind: string): boolean
	return Rarity.Info[kind :: RarityId] ~= nil or kind == "LuckyBlock"
end

function Rarity.beamName(kind: string): string
	if kind == "LuckyBlock" then
		return Rarity.LuckyBlock.displayName
	end
	local maden = Ores.get(kind)
	if maden then
		return maden.displayName
	end
	return Rarity.displayName(kind)
end

function Rarity.beamColor(kind: string): Color3
	if kind == "LuckyBlock" then
		return Rarity.LuckyBlock.colorA
	end
	local maden = Ores.get(kind)
	if maden then
		return maden.color
	end
	return Rarity.color(kind)
end

function Rarity.rollBeam(rng: Random, luckMultiplier: number?, izin: ((string) -> boolean)?): string
	local luck = luckMultiplier or 1

	local weights: { { id: string, w: number } } = {}
	local total = 0

	for _, id in Rarity.Order do
		if izin and not izin(id) then
			continue
		end

		local info = Rarity.Info[id]
		local w = info.beamChance

		w *= luck ^ (info.luckExp or 0)

		total += w
		table.insert(weights, { id = id, w = w })
	end

	local luckyWeight = Rarity.LuckyBlock.beamChance * luck
	total += luckyWeight
	table.insert(weights, { id = "LuckyBlock", w = luckyWeight })

	local roll = rng:NextNumber() * total
	local cursor = 0
	for _, entry in weights do
		cursor += entry.w
		if roll <= cursor then
			return entry.id
		end
	end

	return "Common"
end

return Rarity
