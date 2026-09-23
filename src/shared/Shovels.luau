--!strict
--[[
	20 kademeli kurek sistemi.

	    Lv 1-5    Main Island     Shopkeeper            yalnizca Rot
	    Lv 6-10   Candy Island    CandyShovelSeller     Rot + Amethyst, Opal, Morganite
	    Lv 11-15  Snow Island     FrostyShovelSeller    Rot + Sapphire, Lapis, Quartz
	    Lv 16-20  Volcano Island  PhoenixShovelSeller   Rot + Ruby, Obsidian, Basalt

	Ada kureklerinde adanin UC madeninin HER BIRINDEN istenen adet, kuregin
	adadaki sirasina gore (bkz. OreCosts):

	    1. kurek 0   2. kurek 3   3. kurek 5   4. kurek 7   5. kurek 9

	Adanin ilk kuregi maden ISTEMEZ: oyuncu adaya yeni gelmistir, maden
	toplamaya henuz baslamamistir.

	KAZI GUCU
	Kazi zorlugu "rarity.order - kurek gucu" farkindan gelir (bkz. Shared >
	KaziMinigame). Guc ilk bes kurekte seviyenin kendisi; ada kureklerinde
	her 5 seviye BIR kademe ekler:

	    Lv5   guc 5   Divine ZOR
	    Lv10  guc 6   Cosmic ZOR
	    Lv15  guc 7   Secret ZOR
	    Lv20  guc 8   Infernal ZOR

	Aradaki seviyeler oranli ilerler: Lv7'nin gucu 5.4 -- Divine normal ile
	zor arasinda, Cosmic ise ancak Lv10'da alinabilir hale gelir.

	Kurek iki seyi daha belirler:
	  digSpeed  -- kazi hazirlik suresi carpani (dusuk = hizli)
	  bar*      -- denizdeki bar oyununun ortak yuzu (bkz. DigMinigame)
]]

local Shovels = {}

export type ShovelId = string

export type ShovelInfo = {
	id: ShovelId,
	displayName: string,
	level: number,
	rarity: string,
	price: number,
	-- Kazi hazirlik suresi carpani; 1.0 = taban, dusuk olan daha hizli kazar
	digSpeed: number,
	-- Minigame: oyuncunun kontrol ettigi yesil barin ekran yuksekligine orani
	barSize: number,
	-- Minigame: bar ivmesi; yuksek olan bari daha tepkisel/kolay kontrol edilir yapar
	barAcceleration: number,
	-- Minigame: hedef bar icindeyken ilerleme hizi (saniyede oran)
	progressRate: number,
	-- Minigame: hedef bar disindayken gerileme hizi (saniyede oran)
	drainRate: number,
	color: Color3,
	-- Ada kuregi ise satildigi ada (Brainrots.IslandOrder kimligi); ana adada nil
	island: string?,
	-- Ada kuregi ise adanin her madeninden istenen adet
	oreCost: number?,
}

-- Ada kureklerinin maden bedeli: adadaki sirasina gore (1..5)
Shovels.OreCosts = { 0, 3, 5, 7, 9 }

Shovels.Order = { "Wooden", "Iron", "Golden", "Diamond", "Celestial" } :: { ShovelId }

Shovels.Info = {
	Wooden = {
		id = "Wooden",
		displayName = "Basic Shovel",
		level = 1,
		rarity = "Common",
		price = 0,
		digSpeed = 1,
		barSize = 0.22,
		barAcceleration = 1.15,
		progressRate = 0.42,
		drainRate = 0.16,
		color = Color3.fromRGB(150, 111, 68),
	},

	Iron = {
		id = "Iron",
		displayName = "Emerald Shovel",
		level = 2,
		rarity = "Rare",
		price = 750_000,
		digSpeed = 0.85,
		barSize = 0.26,
		barAcceleration = 1.25,
		progressRate = 0.48,
		drainRate = 0.14,
		color = Color3.fromRGB(176, 182, 192),
	},

	Golden = {
		id = "Golden",
		displayName = "Diamond Shovel",
		level = 3,
		rarity = "Epic",
		price = 2_000_000,
		digSpeed = 0.7,
		barSize = 0.30,
		barAcceleration = 1.40,
		progressRate = 0.55,
		drainRate = 0.12,
		color = Color3.fromRGB(240, 190, 62),
	},

	Diamond = {
		id = "Diamond",
		displayName = "Amethyst Shovel",
		level = 4,
		rarity = "Legendary",
		price = 15_000_000,
		digSpeed = 0.55,
		barSize = 0.34,
		barAcceleration = 1.55,
		progressRate = 0.62,
		drainRate = 0.10,
		color = Color3.fromRGB(120, 226, 240),
	},

	Celestial = {
		id = "Celestial",
		displayName = "Celestial Shovel",
		level = 5,
		rarity = "Mythic",
		price = 110_000_000,
		digSpeed = 0.4,
		barSize = 0.40,
		barAcceleration = 1.75,
		progressRate = 0.72,
		drainRate = 0.08,
		color = Color3.fromRGB(196, 150, 255),
	},
} :: { [ShovelId]: ShovelInfo }

--[[
	ADA KUREGI EKLER

	Kimliklerin sonunda "Shovel" var: DigMinigame.gear once kurek, sonra
	olta tablosuna bakiyor; bir olta ile ayni kimlik denizde yanlis ekipmani
	secerdi.

	rarity yalnizca arayuz rengi icin: kuregin ACTIGI kademe.
]]
local function adaKuregi(id: string, displayName: string, level: number, island: string, rarity: string, price: number, color: Color3)
	local ilerleme = level - 5
	local sira = ((level - 6) % 5) + 1

	Shovels.Info[id] = {
		id = id,
		displayName = displayName,
		level = level,
		rarity = rarity,
		price = price,
		digSpeed = math.max(0.2, 0.4 - ilerleme * 0.012),
		barSize = 0.40,
		barAcceleration = 1.75,
		progressRate = 0.72,
		drainRate = 0.08,
		color = color,
		island = island,
		oreCost = Shovels.OreCosts[sira],
	}
	table.insert(Shovels.Order, id)
end

-- CANDY ISLAND  (Lv 6-10) -- Lv10 Cosmic'i zor alir
adaKuregi("LollipopShovel", "Lollipop Shovel", 6, "sekerkum", "Cosmic", 3_500_000_000, Color3.fromRGB(255, 150, 210))
adaKuregi("GummyShovel", "Gummy Shovel", 7, "sekerkum", "Cosmic", 4_500_000_000, Color3.fromRGB(255, 130, 200))
adaKuregi("CandyCaneShovel", "Candy Cane Shovel", 8, "sekerkum", "Cosmic", 5_500_000_000, Color3.fromRGB(255, 110, 170))
adaKuregi("CaramelShovel", "Caramel Shovel", 9, "sekerkum", "Cosmic", 7_000_000_000, Color3.fromRGB(240, 120, 190))
adaKuregi("SugarCrystalShovel", "Sugar Crystal Shovel", 10, "sekerkum", "Cosmic", 8_000_000_000, Color3.fromRGB(255, 90, 200))

-- SNOW ISLAND  (Lv 11-15) -- Lv15 Secret'i zor alir
adaKuregi("FrostShovel", "Frost Shovel", 11, "snowkum", "Gizli", 35_000_000_000, Color3.fromRGB(170, 230, 255))
adaKuregi("GlacierShovel", "Glacier Shovel", 12, "snowkum", "Gizli", 38_000_000_000, Color3.fromRGB(140, 215, 255))
adaKuregi("BlizzardShovel", "Blizzard Shovel", 13, "snowkum", "Gizli", 43_000_000_000, Color3.fromRGB(120, 200, 250))
adaKuregi("PermafrostShovel", "Permafrost Shovel", 14, "snowkum", "Gizli", 50_000_000_000, Color3.fromRGB(100, 185, 245))
adaKuregi("AuroraShovel", "Aurora Shovel", 15, "snowkum", "Gizli", 55_000_000_000, Color3.fromRGB(110, 240, 230))

-- VOLCANO ISLAND  (Lv 16-20) -- Lv20 Infernal'i zor alir
adaKuregi("EmberShovel", "Ember Shovel", 16, "alevkum", "Infernal", 300_000_000_000, Color3.fromRGB(255, 170, 70))
adaKuregi("MagmaShovel", "Magma Shovel", 17, "alevkum", "Infernal", 330_000_000_000, Color3.fromRGB(255, 145, 50))
adaKuregi("BlazeShovel", "Blaze Shovel", 18, "alevkum", "Infernal", 370_000_000_000, Color3.fromRGB(255, 120, 40))
adaKuregi("InfernoShovel", "Inferno Shovel", 19, "alevkum", "Infernal", 420_000_000_000, Color3.fromRGB(255, 95, 30))
adaKuregi("EruptionShovel", "Eruption Shovel", 20, "alevkum", "Infernal", 490_000_000_000, Color3.fromRGB(255, 70, 20))

Shovels.Default = "Wooden" :: ShovelId

function Shovels.get(id: ShovelId): ShovelInfo
	local info = Shovels.Info[id]
	assert(info, `bilinmeyen kurek: {tostring(id)}`)
	return info
end

function Shovels.next(id: ShovelId): ShovelInfo?
	local current = Shovels.get(id)
	for _, candidate in Shovels.Order do
		local info = Shovels.Info[candidate]
		if info.level == current.level + 1 then
			return info
		end
	end
	return nil
end

--[[
	KAZI GUCU  (bkz. baslik)

	Ilk bes seviyede seviyenin kendisi, sonrasinda her 5 seviye 1 kademe.
]]
function Shovels.power(level: number): number
	if level <= 5 then
		return level
	end
	return 5 + (level - 5) / 5
end

-- Bir adanin kurekleri seviyeye gore; island nil ise ana adanin kurekleri
function Shovels.forIsland(island: string?): { ShovelInfo }
	local out = {}
	for _, id in Shovels.Order do
		local info = Shovels.Info[id]
		if info.island == island then
			table.insert(out, info)
		end
	end
	table.sort(out, function(a, b)
		return a.level < b.level
	end)
	return out
end

return Shovels
