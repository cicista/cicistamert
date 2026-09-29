--!strict

local Seviye = {}

Seviye.Max = 100

Seviye.XP = {
	rarity = {
		Common = 10,
		Rare = 20,
		Epic = 40,
		Legendary = 80,
		Mythic = 150,
		Secret = 300,
		Cosmic = 420,
		Gizli = 580,
		Infernal = 780,
		Abyssal = 1000,
	} :: { [string]: number },
	ore = 50,
	luckyBlock = 30,
	fuse = 30,
}

function Seviye.rarityXp(rarityId: string?): number
	return if rarityId then Seviye.XP.rarity[rarityId] or 0 else 0
end

Seviye.SansPerLevel = 0.01

function Seviye.gerekenXp(level: number): number
	return math.floor(200 * math.max(1, level) ^ 1.1)
end

function Seviye.sansCarpani(level: number): number
	return 1 + (math.clamp(math.floor(level), 1, Seviye.Max) - 1) * Seviye.SansPerLevel
end

function Seviye.sansYuzdesi(level: number): number
	return math.floor((Seviye.sansCarpani(level) - 1) * 100 + 0.5)
end

function Seviye.rotCoinOdulu(level: number): number
	if level <= 30 then
		return if level % 3 == 0 then 1 else 0
	elseif level <= 50 then
		return 1
	end
	return 2
end

return Seviye
