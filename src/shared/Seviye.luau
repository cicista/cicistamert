--!strict
--[[
	LEVEL SISTEMI  --  ayarlar

	XP NEREDEN GELIR
	  Brainrot kazmak / balik tutmak -> kademesine gore (XP.rarity)
	                                    Common 10 ... Divine 300 ... Abyssal 1000
	  Maden damari kirmak            -> XP.ore   (50)
	  Lucky Block acmak          -> XP.luckyBlock
	  Fuse denemesi              -> XP.fuse
	  Gorev odulu toplamak       -> zorluguna gore 500 - 5000
	                                (bkz. Shared > Gorevler > XP)

	ROT COIN (level atlayinca)
	  Level 1-30   : her 3 levelde bir 1 Rot Coin (3, 6, 9 ... 30)
	  Level 31-50  : her level 1 Rot Coin
	  Level 51-100 : her level 2 Rot Coin

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
		Common = 10,
		Rare = 20,
		Epic = 40,
		Legendary = 80,
		Mythic = 150,
		Secret = 300, -- Divine
		Cosmic = 420,
		Gizli = 580, -- Secret
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

-- Her level icin kalici sans artisi (0.01 = %1)
Seviye.SansPerLevel = 0.01

--[[
	Bu levelden bir sonrakine gecmek icin gereken XP.
	    Level 1 -> 200 (7 kazi),  Level 10 -> ~2500,  Level 50 -> ~14800

	Saatte ~120 kazi ve gorevlerle oyuncu saatte ~9000 XP toplar:
	Level 10 ~1 saatte, Level 20 ~5 saatte gelir.
]]
function Seviye.gerekenXp(level: number): number
	return math.floor(200 * math.max(1, level) ^ 1.1)
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
	if level <= 30 then
		return if level % 3 == 0 then 1 else 0
	elseif level <= 50 then
		return 1
	end
	return 2
end

return Seviye
