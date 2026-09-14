--!strict
--[[
	LEVEL SISTEMI  --  ayarlar

	XP NEREDEN GELIR
	  Brainrot kazmak      -> kademesine gore (XP.rarity)
	  Maden damari kirmak  -> XP.ore
	  Lucky Block acmak    -> XP.luckyBlock
	  Fuse denemesi        -> XP.fuse (+ tutarsa cikan kademenin XP'si)
	  Gorev odulu toplamak -> XP.quest

	LEVEL ATLAYINCA
	  - Rot Coin: her level 1, her 10. level 5 (rotCoinOdulu)
	  - Kalici sans: her level +%1 kazi sansi (sansCarpani). Level 1'de
	    bonus yok; Level 100'de x1.99. Arkadas buffi ve iksirle carpilir.

	GORUNUM
	  Ekranin ust ortasinda XP bari, karakterin basinin ustunde "Lv. 12",
	  Tab listesinde Level sutunu.

	Degerleri degistirmek icin yalnizca bu dosyayi duzenle; sunucu da
	arayuz de buradan okuyor.
]]

local Seviye = {}

Seviye.Max = 100

Seviye.XP = {
	rarity = {
		Common = 5,
		Rare = 10,
		Epic = 25,
		Legendary = 60,
		Mythic = 150,
		Secret = 400, -- Divine
	} :: { [string]: number },
	ore = 8,
	luckyBlock = 10,
	fuse = 15,
	quest = 40,
}

-- Her level icin kalici sans artisi (0.01 = %1)
Seviye.SansPerLevel = 0.01

--[[
	Bu levelden bir sonrakine gecmek icin gereken XP.
	    Level 1 -> 50,  Level 10 -> ~1100,  Level 50 -> ~9800
]]
function Seviye.gerekenXp(level: number): number
	return math.floor(50 * math.max(1, level) ^ 1.35)
end

function Seviye.rarityXp(rarityId: string?): number
	return if rarityId then Seviye.XP.rarity[rarityId] or 0 else 0
end

function Seviye.sansCarpani(level: number): number
	return 1 + (math.clamp(math.floor(level), 1, Seviye.Max) - 1) * Seviye.SansPerLevel
end

-- Arayuzde yazan yuzde: Level 12 -> 11
function Seviye.sansYuzdesi(level: number): number
	return math.floor((Seviye.sansCarpani(level) - 1) * 100 + 0.5)
end

-- Bu LEVELE ulasinca verilen Rot Coin
function Seviye.rotCoinOdulu(level: number): number
	return if level % 10 == 0 then 5 else 1
end

return Seviye
