--!strict

local LuckyBlock = require(script.Parent.LuckyBlock)
local Scrolls = require(script.Parent.Scrolls)

local RotCoinMagaza = {}

RotCoinMagaza.MaxPotionSeconds = 7200

export type Urun = {
	id: string,
	kind: string,
	name: string,
	desc: string,
	price: number,
	icon: string,
	color: Color3,
	tint: boolean?,
	tier: string?,
	amount: number?,
	scroll: string?,
	multiplier: number?,
	seconds: number?,
}

local LUCKY_FIYAT: { [string]: number } = {
	Normal = 3,
	Golden = 8,
	Diamond = 20,
}

local urunler: { Urun } = {}

for _, tur in LuckyBlock.Tiers do
	if tur.dropWeight <= 0 then
		continue
	end

	table.insert(urunler, {
		id = `LuckyBlock_{tur.id}`,
		kind = "luckyblock",
		name = tur.displayName,
		desc = "Spin the wheel for a random pet!",
		price = LUCKY_FIYAT[tur.id] or tur.order * 5,
		icon = "luckyBlock",
		color = tur.color,
		tint = true,
		tier = tur.id,
		amount = 1,
	})
end

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

local IKSIRLER = {
	{
		id = "LuckPotion5",
		name = "Luck",
		price = 3,
		icon = "luck1",
		color = Color3.fromRGB(150, 255, 170),
		multiplier = 1.5,
		dakika = 5,
	},
	{
		id = "LuckPotion15",
		name = "Super Luck",
		price = 10,
		icon = "luck2",
		color = Color3.fromRGB(120, 255, 150),
		multiplier = 2,
		dakika = 15,
	},
}

for _, iksir in IKSIRLER do
	table.insert(urunler, {
		id = iksir.id,
		kind = "potion",
		name = iksir.name,
		desc = `x{string.format("%g", iksir.multiplier)} Luck while digging for {iksir.dakika} minutes`,
		price = iksir.price,
		icon = iksir.icon,
		color = iksir.color,
		multiplier = iksir.multiplier,
		seconds = iksir.dakika * 60,
	})
end

RotCoinMagaza.Urunler = urunler

local byId: { [string]: Urun } = {}
for _, urun in urunler do
	byId[urun.id] = urun
end

function RotCoinMagaza.get(id: string): Urun?
	return byId[id]
end

function RotCoinMagaza.carpanYazisi(carpan: number): string
	return `x{string.format("%g", math.floor(carpan * 100 + 0.5) / 100)}`
end

function RotCoinMagaza.sureYazisi(saniye: number): string
	local t = math.max(0, math.floor(saniye))
	if t >= 3600 then
		return string.format("%d:%02d:%02d", t // 3600, (t % 3600) // 60, t % 60)
	end
	return string.format("%d:%02d", t // 60, t % 60)
end

return RotCoinMagaza
