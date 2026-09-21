--!strict
--[[
	ROBUX MAGAZASI  --  urunler ve fiyatlar

	Sag ustteki STORE butonu bu magazayi acar. Icinde YALNIZCA Robux ile
	alinan seyler var:
	  - Developer Product'lar (tekrar tekrar alinabilir): Lucky Block
	    paketleri, sans takviyesi, Rot Coin paketleri
	  - Game Pass'ler: Shared > Passler'daki gecisler (Auto Clicker,
	    Teleporter). Onlarin fiyati ve id'si Passler'da, burada degil.

	Satin alma SUNUCUDA verilir (ServerScriptService > RobuxMagaza,
	ProcessReceipt). Istemci yalnizca urunun anahtarini yollar.

	--------------------------------------------------------------
	URUNU BAGLAMAK  (her urun icin bir kez)

	  1. create.roblox.com > deneyim > Monetization > Developer Products
	     > Create a Developer Product
	  2. Fiyatini asagidaki 'fiyat' ile ayni yap (fiyat yalnizca arayuzde
	     yazar; oyuncudan kesilen tutari Roblox belirler)
	  3. Urunun ID'sini asagidaki 'id' alanina yaz

	id = 0 iken urun SATILMAZ: dugme gorunur, basinca "Coming soon!" der.

	--------------------------------------------------------------
	TEST

	ID girildikten sonra Studio'da satin alma penceresi "test purchase"
	olarak acilir, Robux kesilmez. Urun gercekten verilir.
]]

local LuckyBlock = require(script.Parent.LuckyBlock)

local RobuxMagaza = {}

export type Urun = {
	-- Kodun kullandigi kalici anahtar (degistirme: alinmis urunleri eslestiriyor)
	anahtar: string,
	-- Developer Product ID'si (0 = henuz satista degil)
	id: number,
	-- Arayuzde yazan Robux fiyati
	fiyat: number,
	-- Ustu cizili eski fiyat (indirim gostermek icin, istege bagli)
	eskiFiyat: number?,
	-- Dugmenin altinda yazan kisa ad: "x3", "+35"
	etiket: string,
	-- Bildirimde yazan tam ad
	ad: string,
	tur: string, -- "luckyblock" | "luck" | "rotcoin"
	-- luckyblock
	tier: string?,
	adet: number?,
	-- luck
	carpan: number?,
	saniye: number?,
	-- rotcoin
	rotCoin: number?,
}

export type Kart = {
	id: string,
	baslik: string,
	altBaslik: string,
	-- Kosede egik duran serit ("NEW!", "BEST!"); nil = yok
	serit: string?,
	ikon: string,
	-- Kartin zemin renkleri (soldan saga gradyan)
	renkA: Color3,
	renkB: Color3,
	-- Lucky Block kartinda sans oranlari gosterilir
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

--[[
	KARTLAR  --  magazada yukaridan asagi bu sirayla durur
]]
RobuxMagaza.Kartlar = {
	--[[
		HACKER  --  yalnizca burada satiliyor, kazidan cikmiyor.

		Paket buyudukce birim fiyat DUSUYOR: tanesi 250, x3'te 230, x5'te
		210 Robux. eskiFiyat alani ustu cizili yaziliyor, oyuncu indirimi
		gorsun. Tekli satista indirim olmadigi icin eskiFiyat da yok.
	]]
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
		serit = "NEW!",
		ikon = "luckyBlock",
		renkA = Color3.fromRGB(70, 150, 255),
		renkB = Color3.fromRGB(170, 90, 255),
		tier = "Diamond",
		urunler = {
			{ anahtar = "Diamond1", id = 0, fiyat = 99, etiket = "x1", ad = "1 Diamond Lucky Block", tur = "luckyblock", tier = "Diamond", adet = 1 },
			{ anahtar = "Diamond3", id = 0, fiyat = 249, etiket = "x3", ad = "3 Diamond Lucky Blocks", tur = "luckyblock", tier = "Diamond", adet = 3 },
			{ anahtar = "Diamond8", id = 0, fiyat = 599, eskiFiyat = 792, etiket = "x8", ad = "8 Diamond Lucky Blocks", tur = "luckyblock", tier = "Diamond", adet = 8 },
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
			{ anahtar = "Golden10", id = 0, fiyat = 299, eskiFiyat = 390, etiket = "x10", ad = "10 Golden Lucky Blocks", tur = "luckyblock", tier = "Golden", adet = 10 },
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

-- Magazada gosterilen Game Pass'ler (Shared > Passler adlari), bu sirayla
RobuxMagaza.Gecisler = { "AutoClicker", "Teleporter", "DetectivePass" }

local anahtarla: { [string]: Urun } = {}
local idile: { [number]: Urun } = {}

for _, kart in RobuxMagaza.Kartlar do
	for _, urun in kart.urunler do
		assert(anahtarla[urun.anahtar] == nil, `[RobuxMagaza] ayni anahtar iki kez: {urun.anahtar}`)
		anahtarla[urun.anahtar] = urun
		if urun.id > 0 then
			assert(idile[urun.id] == nil, `[RobuxMagaza] ayni ID iki urunde: {urun.id}`)
			idile[urun.id] = urun
		end
	end
end

function RobuxMagaza.get(anahtar: string): Urun?
	return anahtarla[anahtar]
end

-- Developer Product ID'sine karsilik gelen urun (ProcessReceipt icin)
function RobuxMagaza.idIle(id: number): Urun?
	return idile[id]
end

function RobuxMagaza.satista(urun: Urun): boolean
	return urun.id > 0
end

return RobuxMagaza
