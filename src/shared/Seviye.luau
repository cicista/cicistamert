--!strict
--[[
	LEVEL SISTEMI  --  ayarlar

	XP NEREDEN GELIR  --  KADEMEYE GORE ARTMAZ
	  Kumda isik suzmesi kazmak  -> XP.beam  (30, her kademe ayni)
	  Maden damari kirmak        -> XP.ore   (50)
	  Denizde balik tutmak       -> XP.fish  (100)
	  Lucky Block acmak          -> XP.luckyBlock
	  Fuse denemesi              -> XP.fuse
	  Gorev odulu toplamak       -> zorluguna gore 500 - 5000
	                                (bkz. Shared > Gorevler > XP)

	Kademeye gore XP verilmiyordu cunku ust adalarda her kazi yuzlerce XP
	getiriyor ve level dengesi kiriliyordu.

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
	beam = 30,
	ore = 50,
	fish = 100,
	luckyBlock = 30,
	fuse = 30,
}

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
	return if level % 10 == 0 then 5 else 1
end

return Seviye
