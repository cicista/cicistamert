--!strict
--[[
	Rarity kademeleri, GPS isik suzmesi renkleri ve pasif gelir araliklari.

	Kademe sirasi oyunun mevcut yapisiyla ayni:
		Common -> Rare -> Epic -> Legendary -> Mythic -> Secret

	income degerleri base'e yerlestirilen brainrot'un SANIYELIK Rot getirisidir.
	Nihai getiri: rastgele(incomeMin, incomeMax) * Condition carpani.
]]

export type RarityId = "Common" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Secret"

export type RarityInfo = {
	id: RarityId,
	displayName: string,
	order: number,
	color: Color3,
	-- Kumda gezerken bu kademede bir isik suzmesi cikma sansi (yuzde)
	beamChance: number,
	-- Base'e yerlestirildiginde saniyelik gelir araligi (condition carpani haric)
	incomeMin: number,
	incomeMax: number,
	-- Minigame zorlugu: brainrot ikonunun kacis agresifligi (bkz. DigMinigame)
	escapeDifficulty: number,
	-- Brainrot Detective'in bu kademeyi temizlemesi kac saniye surer
	revealTime: number,
}

local Rarity = {}

Rarity.Order = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" } :: { RarityId }

Rarity.Info = {
	Common = {
		id = "Common",
		displayName = "Common",
		order = 1,
		color = Color3.fromRGB(200, 200, 200),
		beamChance = 62,
		incomeMin = 10,
		incomeMax = 50,
		escapeDifficulty = 0.4,
		revealTime = 3,
	},

	Rare = {
		id = "Rare",
		displayName = "Rare",
		order = 2,
		color = Color3.fromRGB(80, 160, 255),
		beamChance = 25,
		incomeMin = 250,
		incomeMax = 1_250,
		escapeDifficulty = 1,
		revealTime = 5,
	},

	Epic = {
		id = "Epic",
		displayName = "Epic",
		order = 3,
		color = Color3.fromRGB(180, 100, 255),
		beamChance = 9,
		incomeMin = 7_000,
		incomeMax = 35_000,
		escapeDifficulty = 2,
		revealTime = 8,
	},

	Legendary = {
		id = "Legendary",
		displayName = "Legendary",
		order = 4,
		color = Color3.fromRGB(255, 240, 150),
		beamChance = 3,
		incomeMin = 200_000,
		incomeMax = 1_000_000,
		escapeDifficulty = 3.2,
		revealTime = 12,
	},

	Mythic = {
		id = "Mythic",
		displayName = "Mythic",
		order = 5,
		color = Color3.fromRGB(255, 70, 90),
		beamChance = 0.75,
		incomeMin = 3_000_000,
		incomeMax = 15_000_000,
		escapeDifficulty = 4.5,
		revealTime = 18,
	},

	--[[
		DIVINE  (kimligi hala "Secret")

		Ekranda gorunen adi Divine; kimlik "Secret" olarak kaldi, yoksa
		kayitli envanterlerdeki rarity alani gecersizlesirdi.

		Rengi TEK RENK DEGIL: sari ile beyaz arasinda hizla gidip gelir
		(bkz. Shared > Divine). Asagidaki renk yalnizca canlandirmanin
		olmadigi yerlerde kullanilan taban tondur -- Legendary ile
		renkleri takas edildi: Divine artik kehribar, Legendary soluk sari.
	]]
	Secret = {
		id = "Secret",
		displayName = "Divine",
		order = 6,
		color = Color3.fromRGB(255, 190, 60),
		beamChance = 0.2,
		incomeMin = 35_000_000,
		incomeMax = 165_000_000,
		escapeDifficulty = 6,
		revealTime = 25,
	},
} :: { [RarityId]: RarityInfo }

--[[
	LUCKY BLOCK

	Rot Coin gibi ayri bir suzme turu: kazinca siyah yumurta degil bir Lucky
	Block cikar. Icinden ne cikacagi Shared > LuckyBlock icinde ayarlanir.
]]
Rarity.LuckyBlock = {
	id = "LuckyBlock",
	displayName = "Lucky Block",
	colorA = Color3.fromRGB(255, 236, 90),
	colorB = Color3.fromRGB(120, 220, 255),
	--[[
		Kazidan cikma sansi (yuzde). Bloklar artik ETKINLIKLE geldigi icin
		kapali. Kazidan da cikmasini istersen 2 yap; dedektor ve zemin
		sansiyla carpilir, baslangicta ~%2 olur.
	]]
	beamChance = 0,
}

--[[
	Rot Coin bir brainrot degil, ayri bir suzme turu.
	Binde bir cikar, isigi sari-siyah gecisli olur (bkz. Beam.luau).
]]
Rarity.RotCoin = {
	id = "RotCoin",
	displayName = "Rot Coin",
	colorA = Color3.fromRGB(255, 214, 41),
	colorB = Color3.fromRGB(20, 20, 20),
	beamChance = 0.1,
	-- Bir suzmeden cikan Rot Coin adedi
	amountMin = 1,
	amountMax = 3,
}

function Rarity.get(id: RarityId): RarityInfo
	local info = Rarity.Info[id]
	assert(info, `bilinmeyen rarity: {tostring(id)}`)
	return info
end

function Rarity.color(id: string): Color3
	local info = Rarity.Info[id :: RarityId]
	return if info then info.color else Color3.new(1, 1, 1)
end

--[[
	Ekranda gorunecek ad.

	Hicbir yerde ham kimlik ("Secret") yazilmasin diye: kimlik ile gorunen
	ad ayrildigindan beri her arayuz bunu kullanmali.
]]
function Rarity.displayName(id: string): string
	local info = Rarity.Info[id :: RarityId]
	return if info then info.displayName else id
end

--[[
	Bu kademenin ISMI parlak yazilsin mi?

	Mavinin (Rare) ustundeki her sey -- Epic, Legendary, Mythic, Divine --
	daha degerli gorunsun diye isim yazisina parilti gradyani konur.
	Modellere hicbir efekt eklenmez, yalnizca yazi.
]]
function Rarity.isGlowing(id: string): boolean
	local info = Rarity.Info[id :: RarityId]
	return info ~= nil and info.order >= 3
end

-- Divine ozel: rengi canli (sari <-> beyaz). Bkz. Shared > Divine
function Rarity.isDivine(id: string): boolean
	return id == "Secret"
end

--[[
	SUZME TURLERI

	Bir isik suzmesinin "kind" alani UC seyden biri olabilir:
	    bir kademe kimligi ("Common".."Secret")
	    "RotCoin"
	    "LuckyBlock"

	Son ikisi Rarity.Info icinde YOKTUR. Bu yuzden suzme adini/rengini
	Rarity.get ile almak hataya duser -- get bilinmeyen kimlikte assert atar
	ve cagiran taraf (ornegin GPS arayuzu) komple coker. Asagidaki iki
	fonksiyon uc turu de guvenle karsilar; suzmeyle ugrasan her yer bunlari
	kullanmali.
]]
function Rarity.isBeamKind(kind: string): boolean
	return Rarity.Info[kind :: RarityId] ~= nil or kind == "RotCoin" or kind == "LuckyBlock"
end

function Rarity.beamName(kind: string): string
	if kind == "RotCoin" then
		return Rarity.RotCoin.displayName
	end
	if kind == "LuckyBlock" then
		return Rarity.LuckyBlock.displayName
	end
	return Rarity.displayName(kind)
end

function Rarity.beamColor(kind: string): Color3
	if kind == "RotCoin" then
		return Rarity.RotCoin.colorA
	end
	if kind == "LuckyBlock" then
		return Rarity.LuckyBlock.colorA
	end
	return Rarity.color(kind)
end

--[[
	Kumda gezerken hangi suzmenin cikacagini secer.
	Donen deger bir RarityId, "RotCoin" ya da "LuckyBlock".
	Agirliklar toplanip oranlaniyor; toplamin tam 100 olmasi sart degil.

	luckMultiplier: 1'den buyuk degerler yuksek kademelere kayma sagligi verir
	(ada bonusu / gelecekteki sans iksirleri icin).
]]
function Rarity.rollBeam(rng: Random, luckMultiplier: number?): string
	local luck = luckMultiplier or 1

	-- Agirliklari topla: yuksek kademeler luck ile carpilir
	local weights: { { id: string, w: number } } = {}
	local total = 0

	for _, id in Rarity.Order do
		local info = Rarity.Info[id]
		local w = info.beamChance

		--[[
			Epic ve ustu sanstan etkilenir. Mythic ve Secret ise USTEL olarak
			etkilenir (luck^1.5): boylece en ust kurulum (Lv5 dedektor + volkan
			kumu) Secret.i gercekten bulunabilir kilar, dusuk sansta ise ikisi
			de nadir kalir.
		]]
		if info.order >= 5 then
			w *= luck ^ 1.5
		elseif info.order >= 3 then
			w *= luck
		end

		total += w
		table.insert(weights, { id = id, w = w })
	end

	local coinWeight = Rarity.RotCoin.beamChance
	total += coinWeight
	table.insert(weights, { id = "RotCoin", w = coinWeight })

	-- Lucky Block da sanstan etkilenir: iyi dedektor daha cok blok bulur
	local luckyWeight = Rarity.LuckyBlock.beamChance * luck
	total += luckyWeight
	table.insert(weights, { id = "LuckyBlock", w = luckyWeight })

	local roll = rng:NextNumber() * total
	local cursor = 0
	for _, entry in weights do
		cursor += entry.w
		if roll <= cursor then
			return entry.id
		end
	end

	return "Common"
end

return Rarity
