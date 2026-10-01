--!strict

local LuckyBlock = require(script.Parent.LuckyBlock)
local Gacha = require(script.Parent.Gacha)
local KacanYumurta = require(script.Parent.KacanYumurta)
local Format = require(script.Parent.Format)

local RobuxMagaza = {}

export type Urun = {
	anahtar: string,
	id: number,
	fiyat: number,
	eskiFiyat: number?,
	etiket: string,
	ad: string,
	tur: string,
	tier: string?,
	adet: number?,
	carpan: number?,
	saniye: number?,
	rotCoin: number?,
	alan: string?,
	luckyBlocks: { [string]: number }?,
	rot: number?,
}

export type Kart = {
	id: string,
	baslik: string,
	altBaslik: string,
	serit: string?,
	ikon: string,
	renkA: Color3,
	renkB: Color3,
	tier: string?,
	urunler: { Urun },
}

local function tierBul(id: string): LuckyBlock.Tier?
	for _, tier in LuckyBlock.Tiers do
		if tier.id == id then
			return tier
		end
	end
	return nil
end

local DIAMOND = tierBul("Diamond")
local GOLDEN = tierBul("Golden")
local HACKER = tierBul("Hacker")

RobuxMagaza.Kartlar = {
	{
		id = "HackerBlock",
		baslik = if HACKER then HACKER.displayName else "Hacker Lucky Block",
		altBaslik = "The rarest block in the game",
		serit = "NEW!",
		ikon = "luckyBlock",
		renkA = Color3.fromRGB(20, 120, 60),
		renkB = Color3.fromRGB(60, 220, 110),
		tier = "Hacker",
		urunler = {
			{ anahtar = "Hacker1", id = 0, fiyat = 250, etiket = "x1", ad = "1 Hacker Lucky Block", tur = "luckyblock", tier = "Hacker", adet = 1 },
			{ anahtar = "Hacker3", id = 0, fiyat = 690, eskiFiyat = 750, etiket = "x3", ad = "3 Hacker Lucky Blocks", tur = "luckyblock", tier = "Hacker", adet = 3 },
			{ anahtar = "Hacker5", id = 0, fiyat = 1050, eskiFiyat = 1250, etiket = "x5", ad = "5 Hacker Lucky Blocks", tur = "luckyblock", tier = "Hacker", adet = 5 },
		},
	},
	{
		id = "DiamondBlock",
		baslik = if DIAMOND then `{DIAMOND.displayName}!` else "Diamond Lucky Block!",
		altBaslik = "Best odds in the game",
		serit = "HOT!",
		ikon = "luckyBlock",
		renkA = Color3.fromRGB(70, 150, 255),
		renkB = Color3.fromRGB(170, 90, 255),
		tier = "Diamond",
		urunler = {
			{ anahtar = "Diamond1", id = 0, fiyat = 99, etiket = "x1", ad = "1 Diamond Lucky Block", tur = "luckyblock", tier = "Diamond", adet = 1 },
			{ anahtar = "Diamond3", id = 0, fiyat = 249, etiket = "x3", ad = "3 Diamond Lucky Blocks", tur = "luckyblock", tier = "Diamond", adet = 3 },
			{ anahtar = "Diamond5", id = 0, fiyat = 375, eskiFiyat = 495, etiket = "x5", ad = "5 Diamond Lucky Blocks", tur = "luckyblock", tier = "Diamond", adet = 5 },
		},
	},
	{
		id = "GoldenBlock",
		baslik = if GOLDEN then GOLDEN.displayName else "Golden Lucky Block",
		altBaslik = "Great Mythic and Secret chances",
		serit = nil,
		ikon = "luckyBlock",
		renkA = Color3.fromRGB(255, 170, 30),
		renkB = Color3.fromRGB(255, 110, 40),
		tier = "Golden",
		urunler = {
			{ anahtar = "Golden1", id = 0, fiyat = 39, etiket = "x1", ad = "1 Golden Lucky Block", tur = "luckyblock", tier = "Golden", adet = 1 },
			{ anahtar = "Golden3", id = 0, fiyat = 99, etiket = "x3", ad = "3 Golden Lucky Blocks", tur = "luckyblock", tier = "Golden", adet = 3 },
			{ anahtar = "Golden5", id = 0, fiyat = 150, eskiFiyat = 195, etiket = "x5", ad = "5 Golden Lucky Blocks", tur = "luckyblock", tier = "Golden", adet = 5 },
		},
	},
	{
		id = "MegaLuck",
		baslik = "MEGA LUCK  x3",
		altBaslik = "x3 Luck while digging for 30 minutes",
		serit = "HOT!",
		ikon = "luck3",
		renkA = Color3.fromRGB(40, 200, 90),
		renkB = Color3.fromRGB(150, 230, 40),
		tier = nil,
		urunler = {
			{ anahtar = "MegaLuck30", id = 0, fiyat = 149, etiket = "30 min", ad = "x3 Mega Luck (30 min)", tur = "luck", carpan = 3, saniye = 1800 },
		},
	},
	{
		id = "RotCoins",
		baslik = "Rot Coin Packs",
		altBaslik = "Spend them in the Rot Coin Shop",
		serit = nil,
		ikon = "rotCoin",
		renkA = Color3.fromRGB(255, 200, 40),
		renkB = Color3.fromRGB(240, 140, 30),
		tier = nil,
		urunler = {
			{ anahtar = "RotCoin10", id = 0, fiyat = 49, etiket = "+10", ad = "10 Rot Coin", tur = "rotcoin", rotCoin = 10 },
			{ anahtar = "RotCoin35", id = 0, fiyat = 149, etiket = "+35", ad = "35 Rot Coin", tur = "rotcoin", rotCoin = 35 },
			{ anahtar = "RotCoin120", id = 0, fiyat = 449, eskiFiyat = 588, etiket = "+120", ad = "120 Rot Coin", tur = "rotcoin", rotCoin = 120 },
		},
	},
} :: { Kart }

RobuxMagaza.Gecisler = { "SansX2", "RotX15", "AutoClicker", "Teleporter", "DetectivePass" }

RobuxMagaza.BaslangicPaketi = {
	anahtar = "BaslangicPaketi",
	id = 0,
	fiyat = 49,
	etiket = "ONE TIME",
	ad = "Starter Pack",
	tur = "baslangic",
	luckyBlocks = { Normal = 3, Golden = 1 },
	rot = 1_000_000,
} :: Urun

RobuxMagaza.BaslangicNiteligi = "BaslangicAlindi"

RobuxMagaza.GizliUrunler = {
	{
		anahtar = "DetectiveSkip",
		id = 0,
		fiyat = 99,
		etiket = "SKIP",
		ad = "Instant Identify",
		tur = "detectiveSkip",
	},

	{
		anahtar = Gacha.UrunAnahtari,
		id = 0,
		fiyat = Gacha.Fiyat,
		etiket = "OPEN",
		ad = "Premium Spin",
		tur = "gacha",
	},

	{
		anahtar = "AfkSecretAlan",
		id = 0,
		fiyat = 300,
		etiket = "UNLOCK",
		ad = "Secret Clover Field",
		tur = "afkAlan",
		alan = "Secret",
	},

	{
		anahtar = KacanYumurta.UrunAnahtari,
		id = 0,
		fiyat = KacanYumurta.Fiyat,
		eskiFiyat = KacanYumurta.EskiFiyat,
		etiket = "GET IT",
		ad = "Missed Egg",
		tur = "kacanYumurta",
	},
} :: { Urun }

local anahtarla: { [string]: Urun } = {}
local idile: { [number]: Urun } = {}

local function kaydet(urun: Urun)
	assert(anahtarla[urun.anahtar] == nil, `[RobuxMagaza] duplicate key: {urun.anahtar}`)
	anahtarla[urun.anahtar] = urun
	if urun.id > 0 then
		assert(idile[urun.id] == nil, `[RobuxMagaza] duplicate ID in two products: {urun.id}`)
		idile[urun.id] = urun
	end
end

for _, kart in RobuxMagaza.Kartlar do
	for _, urun in kart.urunler do
		kaydet(urun)
	end
end

for _, urun in RobuxMagaza.GizliUrunler do
	kaydet(urun)
end

kaydet(RobuxMagaza.BaslangicPaketi)

function RobuxMagaza.paketIcerigi(urun: Urun): { { yazi: string, tier: string? } }
	local satirlar: { { yazi: string, tier: string? } } = {}
	for _, tier in LuckyBlock.Tiers do
		local adet = urun.luckyBlocks and urun.luckyBlocks[tier.id]
		if adet and adet > 0 then
			table.insert(satirlar, { yazi = `{adet}x {tier.displayName}`, tier = tier.id })
		end
	end
	if urun.rot and urun.rot > 0 then
		table.insert(satirlar, { yazi = `{Format.short(urun.rot)} Rot`, tier = nil })
	end
	return satirlar
end

function RobuxMagaza.get(anahtar: string): Urun?
	return anahtarla[anahtar]
end

function RobuxMagaza.idIle(id: number): Urun?
	return idile[id]
end

function RobuxMagaza.satista(urun: Urun): boolean
	return urun.id > 0
end

function RobuxMagaza.AtlaFiyati(): number
	local urun = anahtarla["DetectiveSkip"]
	return if urun then urun.fiyat else 0
end

return RobuxMagaza
