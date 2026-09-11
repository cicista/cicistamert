--!strict
--[[
	OLTA (Fishing Rod) seviyeleri.

	DENIZIN GPS'I.

	Karada dedektor ne yapiyorsa denizde olta onu yapar: oyuncu flyboardla
	dolasirken etrafinda GIRDAPLAR dogar, olta kademesi ne cikacagini
	belirler. Kazma minigame'i degismez -- zorlugu hala KUREK belirler,
	tipki karadaki suzmelerde oldugu gibi.

	  luck        -> yuksek rarity girdap cikma sansini carpar
	  scanRadius  -> etrafta girdap aranan yaricap
	  spawnChance -> her taramada girdap cikma yuzdesi
	  maxWhirls   -> ayni anda kac girdap durabilir

	Kurek ve dedektorde oldugu gibi tek olta tasinir, sirayla yukseltilir;
	alinan kademeler kalici, saticidan istenilen zaman geri kusanilir.
]]

local Rods = {}

export type RodId = "Bamboo" | "Steel" | "Carbon" | "Abyssal" | "Leviathan"

export type RodInfo = {
	id: RodId,
	displayName: string,
	level: number,
	rarity: string,
	price: number,
	-- Yuksek rarity girdaplarin agirlik carpani (1 = etkisiz)
	luck: number,
	scanRadius: number,
	spawnChance: number,
	maxWhirls: number,
	color: Color3,
}

Rods.Order = { "Bamboo", "Steel", "Carbon", "Abyssal", "Leviathan" } :: { RodId }

Rods.Info = {
	Bamboo = {
		id = "Bamboo",
		displayName = "Bamboo Rod",
		level = 1,
		rarity = "Common",
		price = 500_000,
		luck = 1,
		scanRadius = 60,
		spawnChance = 35,
		maxWhirls = 4,
		color = Color3.fromRGB(190, 160, 95),
	},

	Steel = {
		id = "Steel",
		displayName = "Steel Rod",
		level = 2,
		rarity = "Rare",
		price = 5_000_000,
		luck = 1.6,
		scanRadius = 72,
		spawnChance = 42,
		maxWhirls = 5,
		color = Color3.fromRGB(150, 170, 195),
	},

	Carbon = {
		id = "Carbon",
		displayName = "Carbon Rod",
		level = 3,
		rarity = "Epic",
		price = 50_000_000,
		luck = 2.4,
		scanRadius = 85,
		spawnChance = 50,
		maxWhirls = 6,
		color = Color3.fromRGB(120, 90, 220),
	},

	Abyssal = {
		id = "Abyssal",
		displayName = "Abyssal Rod",
		level = 4,
		rarity = "Legendary",
		price = 500_000_000,
		luck = 3.6,
		scanRadius = 95,
		spawnChance = 58,
		maxWhirls = 7,
		color = Color3.fromRGB(255, 225, 130),
	},

	Leviathan = {
		id = "Leviathan",
		displayName = "Leviathan Rod",
		level = 5,
		rarity = "Mythic",
		price = 5_000_000_000,
		luck = 5.5,
		scanRadius = 110,
		spawnChance = 66,
		maxWhirls = 8,
		color = Color3.fromRGB(255, 70, 90),
	},
} :: { [RodId]: RodInfo }

--[[
	ELDEKI OLTA

	Tool DEGIL: hotbarda gorunmesin ve elden birakilamasin diye parcalar
	dogrudan sag ele kaynaklanan bir Model olarak duruyor. Asagidaki ad hem
	o modelin adi hem de "elinde olta var mi" kontrolunun anahtari.
]]
Rods.ToolName = "Fishing Rod"

-- Misinanin ucundaki nokta; kanca cizgisi buraya baglanir
Rods.TipName = "OltaUcu"

-- Atilan misinayi tutan gorunmez parcanin adi
Rods.LineName = "OltaMisinasi"

function Rods.get(id: string?): RodInfo?
	if not id then
		return nil
	end
	return Rods.Info[id :: RodId]
end

function Rods.exists(id: string?): boolean
	return Rods.get(id) ~= nil
end

-- Kademe sirasi; oltasi olmayan icin 0
function Rods.level(id: string?): number
	local info = Rods.get(id)
	return if info then info.level else 0
end

return Rods
