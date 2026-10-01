--!strict

local Rarity = require(script.Parent.Rarity)

local Gorevler = {}

Gorevler.CYCLE_SECONDS = 1800
Gorevler.COUNT = 5

Gorevler.Plan = { easy = 2, normal = 1, hard = 1, extreme = 1 }

export type QuestKind = "dig" | "collect" | "sell" | "place" | "lucky" | "fuse"
export type Difficulty = "easy" | "normal" | "hard" | "extreme"

export type QuestDef = {
	id: string,
	kind: QuestKind,
	rarity: string?,
	target: number,
	difficulty: Difficulty,
	short: string,
	text: string,
}

export type Reward = { rarity: string, count: number }

Gorevler.XP = {
	easy = 500,
	normal = 1500,
	hard = 3000,
	extreme = 5000,
} :: { [Difficulty]: number }

local Rewards: { [Difficulty]: Reward } = {
	easy = { rarity = "Common", count = 1 },
	normal = { rarity = "Rare", count = 1 },
	hard = { rarity = "Epic", count = 1 },
	extreme = { rarity = "Legendary", count = 1 },
}

local Pool: { QuestDef } = {
	{
		id = "dig15",
		kind = "dig",
		target = 15,
		difficulty = "easy",
		short = "Beams Dug",
		text = "Dig Up 15 Light Beams",
	},
	{
		id = "common10",
		kind = "collect",
		rarity = "Common",
		target = 10,
		difficulty = "easy",
		short = "Common Pets",
		text = "Collect 10 Common Pets",
	},
	{
		id = "sell8",
		kind = "sell",
		target = 8,
		difficulty = "easy",
		short = "Pets Sold",
		text = "Sell 8 Pets",
	},
	{
		id = "place3",
		kind = "place",
		target = 3,
		difficulty = "easy",
		short = "Pets Placed",
		text = "Place 3 Pets On Your Base",
	},

	{
		id = "dig35",
		kind = "dig",
		target = 35,
		difficulty = "normal",
		short = "Beams Dug",
		text = "Dig Up 35 Light Beams",
	},
	{
		id = "rare8",
		kind = "collect",
		rarity = "Rare",
		target = 8,
		difficulty = "normal",
		short = "Rare Pets",
		text = "Collect 8 Rare Pets",
	},
	{
		id = "sell20",
		kind = "sell",
		target = 20,
		difficulty = "normal",
		short = "Pets Sold",
		text = "Sell 20 Pets",
	},
	{
		id = "place8",
		kind = "place",
		target = 8,
		difficulty = "normal",
		short = "Pets Placed",
		text = "Place 8 Pets On Your Base",
	},

	{
		id = "epic3",
		kind = "collect",
		rarity = "Epic",
		target = 3,
		difficulty = "hard",
		short = "Epic Pets",
		text = "Collect 3 Epic Pets",
	},
	{
		id = "dig60",
		kind = "dig",
		target = 60,
		difficulty = "hard",
		short = "Beams Dug",
		text = "Dig Up 60 Light Beams",
	},
	{
		id = "lucky1",
		kind = "lucky",
		target = 1,
		difficulty = "hard",
		short = "Lucky Blocks Opened",
		text = "Open A Lucky Block",
	},
	{
		id = "fuse1",
		kind = "fuse",
		target = 1,
		difficulty = "hard",
		short = "Fuses Done",
		text = "Use The Fuse Machine Once",
	},

	{
		id = "legendary1",
		kind = "collect",
		rarity = "Legendary",
		target = 1,
		difficulty = "extreme",
		short = "Legendary Pets",
		text = "Collect A Legendary Pet",
	},
	{
		id = "epic6",
		kind = "collect",
		rarity = "Epic",
		target = 6,
		difficulty = "extreme",
		short = "Epic Pets",
		text = "Collect 6 Epic Pets",
	},
	{
		id = "rare20",
		kind = "collect",
		rarity = "Rare",
		target = 20,
		difficulty = "extreme",
		short = "Rare Pets",
		text = "Collect 20 Rare Pets",
	},
}

Gorevler.Rewards = Rewards
Gorevler.Pool = Pool

local byId: { [string]: QuestDef } = {}
local byDifficulty: { [string]: { QuestDef } } = { easy = {}, normal = {}, hard = {}, extreme = {} }

for _, def in Pool do
	byId[def.id] = def
	table.insert(byDifficulty[def.difficulty], def)
end

function Gorevler.get(id: string): QuestDef?
	return byId[id]
end

function Gorevler.reward(def: QuestDef): Reward
	if def.kind == "collect" and def.rarity then
		return { rarity = def.rarity, count = 1 }
	end
	return Rewards[def.difficulty]
end

function Gorevler.xp(def: QuestDef): number
	return Gorevler.XP[def.difficulty] or 0
end

function Gorevler.rewardText(def: QuestDef): string
	local reward = Gorevler.reward(def)
	local ad = `{Rarity.displayName(reward.rarity)} Pet`
	return if reward.count > 1 then `{reward.count}x {ad}` else ad
end

function Gorevler.cycle(now: number?): number
	return math.floor((now or os.time()) / Gorevler.CYCLE_SECONDS)
end

function Gorevler.remaining(now: number?): number
	local zaman = now or os.time()
	return Gorevler.CYCLE_SECONDS - (zaman % Gorevler.CYCLE_SECONDS)
end

local function karistir(list: { QuestDef }, rng: Random): { QuestDef }
	local copy = table.clone(list)
	for i = #copy, 2, -1 do
		local j = rng:NextInteger(1, i)
		copy[i], copy[j] = copy[j], copy[i]
	end
	return copy
end

local cache: { [number]: { QuestDef } } = {}

function Gorevler.forCycle(cycle: number): { QuestDef }
	local hazir = cache[cycle]
	if hazir then
		return hazir
	end

	local rng = Random.new(cycle)
	local secilen: { QuestDef } = {}
	local kullanilanTur: { [string]: boolean } = {}

	for _, zorluk in { "easy", "normal", "hard", "extreme" } do
		local havuz = karistir(byDifficulty[zorluk], rng)
		local kalan = Gorevler.Plan[zorluk :: Difficulty]

		for _, def in havuz do
			if kalan <= 0 then
				break
			end
			if not kullanilanTur[def.kind] then
				table.insert(secilen, def)
				kullanilanTur[def.kind] = true
				kalan -= 1
			end
		end

		for _, def in havuz do
			if kalan <= 0 then
				break
			end
			if not table.find(secilen, def) then
				table.insert(secilen, def)
				kalan -= 1
			end
		end
	end

	cache[cycle] = secilen
	return secilen
end

return Gorevler
