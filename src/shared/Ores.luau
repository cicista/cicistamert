--!strict

local Ores = {}

export type OreInfo = {
	id: string,
	displayName: string,
	island: string,
	color: Color3,
	islandColor: Color3,
	shape: string?,
	cps: number,
}

export type PickaxeInfo = {
	id: string,
	displayName: string,
	island: string,
	price: number,
	color: Color3,
}

export type IslandOres = {
	island: string,
	name: string,
	color: Color3,
	ores: { string },
	pickaxe: string,
	pickaxeSeller: string,
	shovelSeller: string,
	spawnPart: string,
	modelName: string,
}

Ores.SpawnChance = 25

Ores.MineCps = 4

Ores.MineAmount = 1

Ores.TradeCost = 1

Ores.LuckTrade = {
	cost = 10,
	potion = "LuckPotion5",
}

Ores.IslandOrder = { "sekerkum", "snowkum", "alevkum" }

Ores.Islands = {
	sekerkum = {
		island = "sekerkum",
		name = "Candy Island",
		color = Color3.fromRGB(255, 120, 200),
		ores = { "Amethyst", "Opal", "Morganite" },
		pickaxe = "CandyPickaxe",
		pickaxeSeller = "CandySeller",
		shovelSeller = "CandyShovelSeller",
		spawnPart = "Spawn_Sakiz",
		modelName = "CandyIsland",
	},
	snowkum = {
		island = "snowkum",
		name = "Snow Island",
		color = Color3.fromRGB(130, 215, 255),
		ores = { "Sapphire", "Lapis", "Quartz" },
		pickaxe = "FrostyPickaxe",
		pickaxeSeller = "FrostySeller",
		shovelSeller = "FrostyShovelSeller",
		spawnPart = "Spawn_Buz",
		modelName = "SnowIsland",
	},
	alevkum = {
		island = "alevkum",
		name = "Volcano Island",
		color = Color3.fromRGB(255, 140, 40),
		ores = { "Ruby", "Obsidian", "Basalt" },
		pickaxe = "PhoenixPickaxe",
		pickaxeSeller = "PhoenixSeller",
		shovelSeller = "PhoenixShovelSeller",
		spawnPart = "Spawn_Volkan",
		modelName = "VolcanoIsland",
	},
} :: { [string]: IslandOres }

Ores.Pickaxes = {
	CandyPickaxe = {
		id = "CandyPickaxe",
		displayName = "Candy Pickaxe",
		island = "sekerkum",
		price = 0,
		color = Ores.Islands.sekerkum.color,
	},
	FrostyPickaxe = {
		id = "FrostyPickaxe",
		displayName = "Frosty Pickaxe",
		island = "snowkum",
		price = 0,
		color = Ores.Islands.snowkum.color,
	},
	PhoenixPickaxe = {
		id = "PhoenixPickaxe",
		displayName = "Phoenix Pickaxe",
		island = "alevkum",
		price = 0,
		color = Ores.Islands.alevkum.color,
	},
} :: { [string]: PickaxeInfo }

do
	local Config = require(script.Parent:WaitForChild("OyunConfig")) :: any
	for _, kazma in Ores.Pickaxes do
		local adaAdi = Ores.Islands[kazma.island].name
		for _, ada in Config.Islands do
			if ada.name == adaAdi then
				kazma.price = ada.price
			end
		end
	end
end

Ores.GemColors = {
	Amethyst = Color3.fromRGB(176, 80, 255),
	Opal = Color3.fromRGB(255, 222, 50),
	Morganite = Color3.fromRGB(255, 130, 195),
	Sapphire = Color3.fromRGB(25, 100, 255),
	Lapis = Color3.fromRGB(40, 55, 175),
	Quartz = Color3.fromRGB(242, 246, 255),
	Ruby = Color3.fromRGB(240, 25, 50),
	Obsidian = Color3.fromRGB(28, 22, 38),
	Basalt = Color3.fromRGB(150, 152, 162),
} :: { [string]: Color3 }

Ores.GemShapes = {
	Basalt = "ball",
} :: { [string]: string }

Ores.Info = {} :: { [string]: OreInfo }

for _, ada in Ores.IslandOrder do
	local cfg = Ores.Islands[ada]
	for _, id in cfg.ores do
		Ores.Info[id] = {
			id = id,
			displayName = id,
			island = ada,
			color = Ores.GemColors[id] or cfg.color,
			islandColor = cfg.color,
			shape = Ores.GemShapes[id],
			cps = Ores.MineCps,
		}
	end
end

function Ores.get(id: string?): OreInfo?
	if type(id) ~= "string" then
		return nil
	end
	return Ores.Info[id]
end

function Ores.island(island: string?): IslandOres?
	if type(island) ~= "string" then
		return nil
	end
	return Ores.Islands[island]
end

function Ores.roll(island: string?, rng: Random): string?
	local cfg = Ores.island(island)
	if not cfg then
		return nil
	end
	return cfg.ores[rng:NextInteger(1, #cfg.ores)]
end

return Ores
