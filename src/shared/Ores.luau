--!strict
--[[
	MADENLER VE KAZMALAR

	Candy, Snow ve Volcano adalarinda ucer maden var:

	    Candy Island    Amethyst, Opal, Morganite       Candy Pickaxe
	    Snow Island     Sapphire, Lapis, Quartz         Frosty Pickaxe
	    Volcano Island  Ruby, Obsidian, Basalt          Phoenix Pickaxe

	NASIL CIKAR
	Kumda isik suzmesi dogacagi zaman SpawnChance yuzde ihtimalle suzme
	yerine o adanin madenlerinden biri cikar (bkz. Modules > Beams >
	trySpawn). GPS listesinde maden adiyla gorunur.

	NASIL KAZILIR
	Yalnizca ADANIN KAZMASI ile. Kazi minioyununun aynisi oynanir; imlec ve
	kaya adanin renginde. Madenlerde kurek farki yok: gereken tiklama hizi
	sabit (cps).

	NE ISE YARAR
	Ada kurekleri (Lv 6-20) Rot'un yaninda o adanin UC madeninden de ister
	(bkz. Shared > Shovels > OreCosts).

	TAKAS
	Kazma saticisinda: diger iki madenden TradeCost'ar tane verilir, istenen
	madenden 1 tane alinir.
]]

local Ores = {}

export type OreInfo = {
	id: string,
	displayName: string,
	island: string,
	-- Gemin kendi rengi (kristaller, GPS etiketi, bildirim)
	color: Color3,
	-- Adanin rengi (kazi minioyununun imleci)
	islandColor: Color3,
	-- Kazi minioyununda imleci yerinde tutmak icin gereken tiklama hizi
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
	-- Haritadaki NPC model adlari
	pickaxeSeller: string,
	shovelSeller: string,
	-- NPC haritada yoksa yedek tezgah bu spawn noktasinin yanina kurulur
	spawnPart: string,
}

-- Suzme dogacagi zaman madenin cikma ihtimali (yuzde)
-- TEST ICIN 50; oyun icin 5'e geri cekilecek
Ores.SpawnChance = 50

-- Madenin kazi zorlugu: 4 cps = kurek tablosundaki "normal"
Ores.MineCps = 4

-- Kazanilan her kazida gelen adet
Ores.MineAmount = 1

-- Takasta diger iki madenin HER BIRINDEN verilen adet
Ores.TradeCost = 1

Ores.IslandOrder = { "sekerkum", "snowkum", "alevkum" }

Ores.Islands = {
	sekerkum = {
		island = "sekerkum",
		name = "Candy Island",
		-- Imlec ve kaya rengi: pembe
		color = Color3.fromRGB(255, 120, 200),
		ores = { "Amethyst", "Opal", "Morganite" },
		pickaxe = "CandyPickaxe",
		pickaxeSeller = "CandySeller",
		shovelSeller = "CandyShovelSeller",
		spawnPart = "Spawn_Sakiz",
	},
	snowkum = {
		island = "snowkum",
		name = "Snow Island",
		-- Buz mavisi
		color = Color3.fromRGB(130, 215, 255),
		ores = { "Sapphire", "Lapis", "Quartz" },
		pickaxe = "FrostyPickaxe",
		pickaxeSeller = "FrostySeller",
		shovelSeller = "FrostyShovelSeller",
		spawnPart = "Spawn_Buz",
	},
	alevkum = {
		island = "alevkum",
		name = "Volcano Island",
		-- Turuncu
		color = Color3.fromRGB(255, 140, 40),
		ores = { "Ruby", "Obsidian", "Basalt" },
		pickaxe = "PhoenixPickaxe",
		pickaxeSeller = "PhoenixSeller",
		shovelSeller = "PhoenixShovelSeller",
		spawnPart = "Spawn_Volkan",
	},
} :: { [string]: IslandOres }

Ores.Pickaxes = {
	CandyPickaxe = {
		id = "CandyPickaxe",
		displayName = "Candy Pickaxe",
		island = "sekerkum",
		price = 25_000_000_000,
		color = Ores.Islands.sekerkum.color,
	},
	FrostyPickaxe = {
		id = "FrostyPickaxe",
		displayName = "Frosty Pickaxe",
		island = "snowkum",
		price = 150_000_000_000,
		color = Ores.Islands.snowkum.color,
	},
	PhoenixPickaxe = {
		id = "PhoenixPickaxe",
		displayName = "Phoenix Pickaxe",
		island = "alevkum",
		price = 1_500_000_000_000,
		color = Ores.Islands.alevkum.color,
	},
} :: { [string]: PickaxeInfo }

--[[
	GEM RENKLERI  --  parlak, her gem kendi renginde

	Kayanin damarlarindan cikan kristaller bu renkte parlar. Cok koyu
	renkler (Obsidian) neon ile parlayamadigi icin cam gibi yansitici
	cizilir (bkz. Modules > Beams > buildOreModel).
]]
Ores.GemColors = {
	Amethyst = Color3.fromRGB(176, 80, 255), -- mor
	Opal = Color3.fromRGB(255, 222, 50), -- sari
	Morganite = Color3.fromRGB(255, 130, 195), -- pembe
	Sapphire = Color3.fromRGB(25, 100, 255), -- safir mavisi
	Lapis = Color3.fromRGB(40, 55, 175), -- lacivert
	Quartz = Color3.fromRGB(242, 246, 255), -- beyaz
	Ruby = Color3.fromRGB(240, 25, 50), -- kirmizi
	Obsidian = Color3.fromRGB(28, 22, 38), -- siyah
	Basalt = Color3.fromRGB(150, 152, 162), -- gri
} :: { [string]: Color3 }

-- Maden kayitlari ada tablosundan uretilir: ad bir kez yazilsin
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

-- Adanin madenlerinden rastgele biri; madensiz adada nil
function Ores.roll(island: string?, rng: Random): string?
	local cfg = Ores.island(island)
	if not cfg then
		return nil
	end
	return cfg.ores[rng:NextInteger(1, #cfg.ores)]
end

return Ores
