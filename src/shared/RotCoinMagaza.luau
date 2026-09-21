--!strict
--[[
	ROTCOIN MAGAZASI  --  urunler ve fiyatlar

	Sol menudeki Rot Coin butonu bu magazayi acar (eski Pets butonunun yeri).
	Satin alma SUNUCUDA dogrulanir (bkz. ServerScriptService > RotCoinMagaza);
	istemci yalnizca urunun id'sini yollar.

	URUN TURLERI
	  luckyblock -- cantaya Lucky Block girer
	  potion     -- belirli sure kazida sans carpani (PlayerData.grantLuck)

	SANS IKSIRI KURALLARI
	  - Ayni iksirden tekrar alinirsa SURE UZAR (en fazla MaxPotionSeconds).
	  - Daha guclu iksir alinirsa zayif olanin yerini alir.
	  - Guclu iksir aktifken zayif olan alinamaz (Rot Coin bosa gitmesin).
	  - Arkadas buffi ile carpilir, ikisi birlikte calisir.

	Fiyatlari degistirmek icin yalnizca bu dosyayi duzenle; panel de sunucu
	da buradan okuyor.
]]

local LuckyBlock = require(script.Parent.LuckyBlock)
local Scrolls = require(script.Parent.Scrolls)

local RotCoinMagaza = {}

-- Ust uste alinan iksirlerin toplam suresi en fazla (saniye). 7200 = 2 saat
RotCoinMagaza.MaxPotionSeconds = 7200

export type Urun = {
	id: string,
	kind: string,
	name: string,
	desc: string,
	price: number,
	-- Icons.Map kisa adi
	icon: string,
	color: Color3,
	-- Ikon urunun renginde hafifce boyansin mi
	tint: boolean?,
	-- luckyblock
	tier: string?,
	amount: number?,
	-- scroll (bkz. Shared > Scrolls)
	scroll: string?,
	-- potion
	multiplier: number?,
	seconds: number?,
}

-- Lucky Block fiyatlari (Rot Coin). Yazilmayan tur: sirasi x 5
local LUCKY_FIYAT: { [string]: number } = {
	Normal = 3,
	Golden = 8,
	Diamond = 20,
}

local urunler: { Urun } = {}

--[[
	Kazidan CIKMAYAN kademeler (dropWeight 0) burada satilmaz: Hacker Lucky
	Block yalnizca Robux magazasinda (bkz. Shared > RobuxMagaza).
]]
for _, tur in LuckyBlock.Tiers do
	if tur.dropWeight <= 0 then
		continue
	end

	table.insert(urunler, {
		id = `LuckyBlock_{tur.id}`,
		kind = "luckyblock",
		name = tur.displayName,
		desc = "Spin the wheel for a random brainrot!",
		price = LUCKY_FIYAT[tur.id] or tur.order * 5,
		icon = "luckyBlock",
		color = tur.color,
		tint = true,
		tier = tur.id,
		amount = 1,
	})
end

--[[
	MUTASYON SCROLL'LARI  --  bkz. Shared > Scrolls

	Fiyat ve aciklama scroll tanimindan geliyor; buraya yeni bir satir
	yazmak gerekmiyor, Scrolls.Order'a eklemek yetiyor.
]]
for _, id in Scrolls.Order do
	local info = Scrolls.get(id)
	if info then
		table.insert(urunler, {
			id = `Scroll_{info.id}`,
			kind = "scroll",
			name = info.ad,
			desc = info.aciklama,
			price = info.fiyat,
			icon = "scroll",
			color = info.renk,
			scroll = info.id,
			amount = 1,
		})
	end
end

table.insert(urunler, {
	id = "LuckPotion",
	kind = "potion",
	name = "Luck Potion",
	desc = "x1.5 Luck while digging for 15 minutes",
	price = 5,
	icon = "luck2",
	color = Color3.fromRGB(120, 255, 150),
	multiplier = 1.5,
	seconds = 900,
})

table.insert(urunler, {
	id = "SuperLuckPotion",
	kind = "potion",
	name = "Super Luck Potion",
	desc = "x2 Luck while digging for 15 minutes",
	price = 12,
	icon = "luck3",
	color = Color3.fromRGB(90, 220, 255),
	multiplier = 2,
	seconds = 900,
})

RotCoinMagaza.Urunler = urunler

local byId: { [string]: Urun } = {}
for _, urun in urunler do
	byId[urun.id] = urun
end

function RotCoinMagaza.get(id: string): Urun?
	return byId[id]
end

-- "x1.5", "x2"
function RotCoinMagaza.carpanYazisi(carpan: number): string
	return `x{string.format("%g", math.floor(carpan * 100 + 0.5) / 100)}`
end

-- Kalan sure: "14:59" ya da "1:05:00"
function RotCoinMagaza.sureYazisi(saniye: number): string
	local t = math.max(0, math.floor(saniye))
	if t >= 3600 then
		return string.format("%d:%02d:%02d", t // 3600, (t % 3600) // 60, t % 60)
	end
	return string.format("%d:%02d", t // 60, t % 60)
end

return RotCoinMagaza
