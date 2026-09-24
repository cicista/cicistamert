--!strict
--[[
	Rarity kademeleri, GPS isik suzmesi renkleri ve pasif gelir araliklari.

	Kademe sirasi oyunun mevcut yapisiyla ayni:
		Common -> Rare -> Epic -> Legendary -> Mythic -> Secret

	income degerleri base'e yerlestirilen brainrot'un SANIYELIK Rot getirisidir.
	Nihai getiri: rastgele(incomeMin, incomeMax) * Condition carpani.
]]

export type RarityId =
	"Common"
	| "Rare"
	| "Epic"
	| "Legendary"
	| "Mythic"
	| "Secret"
	| "Cosmic"
	| "Gizli"
	| "Infernal"
	| "Abyssal"

export type RarityInfo = {
	id: RarityId,
	displayName: string,
	order: number,
	color: Color3,
	-- Kumda gezerken bu kademede bir isik suzmesi cikma sansi (yuzde)
	beamChance: number,
	-- Sans ussu: agirlik = beamChance * sans ^ luckExp (eksi = sans arttikca azalir)
	luckExp: number?,
	-- Base'e yerlestirildiginde saniyelik gelir araligi (condition carpani haric)
	incomeMin: number,
	incomeMax: number,
	-- Minigame zorlugu: brainrot ikonunun kacis agresifligi (bkz. DigMinigame)
	escapeDifficulty: number,
	--[[
		Detective'in bu kademeyi acma suresi (saniye). Toplu acmada
		sureler TOPLANIR.

		Mythic'e kadar saniyeler: oyuncu dedektifin yaninda bekleyip alir.
		DIVINE'DAN SONRA dakikalara ciktiyor -- degerli brainrot bir
		bekleyise degsin, oyuncu da o sure boyunca baska isine baksin:

		    Divine 2 dk    Cosmic 8 dk    Secret 15 dk
		    Infernal 30 dk    Abyssal 1 saat

		Sureyi beklemek istemeyen Robux ile atlayabiliyor
		(bkz. Shared > Passler > Detective ekrani).
	]]
	revealTime: number,
}
--[[
	Divine yalnizca parildayan kademelerin listesi icin isteniyor
	(Rarity.isDivine). Divine hicbir sey require etmiyor, dongu olusmaz.
]]
local Divine = require(script.Parent.Divine)
-- Maden suzmeleri GPS'te kendi ad ve renkleriyle gorunsun (Ores hicbir sey require etmiyor)
local Ores = require(script.Parent.Ores)


local Rarity = {}

--[[
	KADEME SIRASI

	Secret (gorunen adi Divine) 6. sirada bitiyordu; ondan sonrasi ADAYA
	BAGLI yeni kademeler. Her ada bir tanesini aciyor:

	  7  Cosmic    sekerkum
	  8  Gizli     snowkum   (ekranda "Secret")
	  9  Infernal  alevkum
	 10  Abyssal   deniz

	DIKKAT: bunlar su anki kureklerle KAZILAMAZ. Kazi zorlugu
	"rarity.order - kurek.level" farkindan geliyor ve fark 2 imkansiz
	demek (bkz. Shared > KaziMinigame); en ust kurek Lv5 oldugu icin
	sirasi 7 ve ustu olan her kademe simdilik erisilemez. Her ada icin
	yeni kurek kademesi eklendikce acilacaklar.
]]
Rarity.Order = {
	"Common",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Secret",
	"Cosmic",
	"Gizli",
	"Infernal",
	"Abyssal",
} :: { RarityId }

Rarity.Info = {
	Common = {
		id = "Common",
		displayName = "Common",
		order = 1,
		color = Color3.fromRGB(200, 200, 200),
		beamChance = 62,
		luckExp = -0.6,
		incomeMin = 5,
		incomeMax = 25,
		escapeDifficulty = 0.4,
		revealTime = 1.5,
	},

	Rare = {
		id = "Rare",
		displayName = "Rare",
		order = 2,
		color = Color3.fromRGB(80, 160, 255),
		beamChance = 25,
		luckExp = -0.3,
		incomeMin = 50,
		incomeMax = 250,
		escapeDifficulty = 1,
		revealTime = 2.5,
	},

	Epic = {
		id = "Epic",
		displayName = "Epic",
		order = 3,
		color = Color3.fromRGB(180, 100, 255),
		beamChance = 9,
		luckExp = 0.4,
		incomeMin = 500,
		incomeMax = 2_500,
		escapeDifficulty = 2,
		revealTime = 4,
	},

	Legendary = {
		id = "Legendary",
		displayName = "Legendary",
		order = 4,
		color = Color3.fromRGB(255, 240, 150),
		beamChance = 3,
		luckExp = 0.7,
		incomeMin = 5_000,
		incomeMax = 25_000,
		escapeDifficulty = 3.2,
		revealTime = 6,
	},

	Mythic = {
		id = "Mythic",
		displayName = "Mythic",
		order = 5,
		color = Color3.fromRGB(255, 70, 90),
		beamChance = 0.75,
		luckExp = 1.0,
		incomeMin = 50_000,
		incomeMax = 250_000,
		escapeDifficulty = 4.5,
		revealTime = 9,
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
		-- 1.5 kati (0.2 idi)
		beamChance = 0.3,
		luckExp = 1.2,
		incomeMin = 500_000,
		incomeMax = 2_500_000,
		escapeDifficulty = 6,
		revealTime = 120,
	},

	--[[
		ADAYA BAGLI UST KADEMELER

		Dordu de Divine gibi TEK RENK DEGIL: iki uc renk arasinda parildar
		(bkz. Shared > Divine > Flashes). Asagidaki renk yalnizca
		canlandirmanin olmadigi yerlerde kullanilan taban tondur.

		Gelir her kademede oncekinin ~5 kati; kacis zorlugu ve Detective
		suresi de kademeli artiyor.
	]]

	-- SEKERKUM: parlak koyu mor <-> beyaz
	Cosmic = {
		id = "Cosmic",
		displayName = "Cosmic",
		order = 7,
		color = Color3.fromRGB(138, 43, 226),
		-- 3 kati (0.0168 idi)
		beamChance = 0.0504,
		luckExp = 1.4,
		incomeMin = 5_000_000,
		incomeMax = 25_000_000,
		escapeDifficulty = 7.5,
		revealTime = 480,
	},

	--[[
		SNOWKUM: siyah <-> beyaz

		Kimligi "Gizli", ekranda gorunen adi "Secret". Kimlik Secret
		OLAMAZDI: o ad zaten Divine'a ait (yukari bak) ve cakissaydi
		kayitli envanterlerdeki Divine'lar gecersizlesirdi.
	]]
	Gizli = {
		id = "Gizli",
		displayName = "Secret",
		order = 8,
		color = Color3.fromRGB(24, 24, 28),
		-- 3 kati (0.0044 idi)
		beamChance = 0.0132,
		luckExp = 1.6,
		incomeMin = 50_000_000,
		incomeMax = 250_000_000,
		escapeDifficulty = 9,
		revealTime = 900,
	},

	-- ALEVKUM: volkan turuncusu <-> beyaz
	Infernal = {
		id = "Infernal",
		displayName = "Infernal",
		order = 9,
		color = Color3.fromRGB(255, 102, 20),
		-- 3 kati (0.00103 idi)
		beamChance = 0.00309,
		luckExp = 1.8,
		incomeMin = 500_000_000,
		incomeMax = 2_500_000_000,
		escapeDifficulty = 11,
		revealTime = 1800,
	},

	-- DENIZ: derin deniz mavisi <-> beyaz
	Abyssal = {
		id = "Abyssal",
		displayName = "Abyssal",
		order = 10,
		color = Color3.fromRGB(12, 62, 140),
		-- 3 kati (0.0000494 idi)
		beamChance = 0.0001482,
		luckExp = 2.0,
		incomeMin = 5_000_000_000,
		incomeMax = 25_000_000_000,
		escapeDifficulty = 13,
		revealTime = 3600,
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

function Rarity.get(id: RarityId): RarityInfo
	local info = Rarity.Info[id]
	assert(info, `bilinmeyen rarity: {tostring(id)}`)
	return info
end

--[[
	ETIKET BUYUTME CARPANI

	Adaya bagli ust kademeler dunyadaki etikette daha iri gorunur: her yeni
	ada bir oncekinden biraz daha gosterisli olsun istendi.

	Divine'a kadar (sira 1-6) carpan 1 -- mevcut gorunum hic degismiyor.
	Sonrasi kademeli buyur ve EN FAZLA 1.5'te durur:

	     7  Cosmic    1.15
	     8  Secret    1.27
	     9  Infernal  1.38
	    10  Abyssal   1.50

	Ayni carpan hem yazi boyutlarina hem etiketin kendi olcusune uygulanir
	(bkz. Shared > Etiket), yoksa yazi buyuyup cerceveye sigmazdi.
]]
Rarity.LabelScaleMax = 1.5

--[[
	BOARD MODEL OLCEGI

	Divine SONRASI kademelerin modelleri base slotunda iki kat buyuk
	duruyor: o kademeler zaten nadir, boardda da oyle gorunsunler.

	Divine ve altinda 1 -- mevcut gorunum hic degismiyor.
]]
function Rarity.modelScale(id: string?): number
	local info = if id then Rarity.Info[id :: RarityId] else nil
	return if info and info.order >= 7 then 2 else 1
end

--[[
	YAZI RENGI

	Kademe rengi bazen YAZI icin kullanilamiyor: Secret neredeyse siyah
	(24,24,28) ve koyu zeminde okunmuyordu. Cok koyu kademelerde yazi
	beyaza cevriliyor; parlama efekti zaten rengi tasiyor.

	Parlaklik esigi 0.25: bunun altindaki her renk "okunmaz koyu" sayilir.
]]
function Rarity.textColor(id: string?): Color3
	local color = Rarity.color(id or "")
	local _, _, parlaklik = color:ToHSV()

	if parlaklik < 0.25 then
		return Color3.fromRGB(245, 245, 250)
	end

	return color
end

function Rarity.labelScale(id: string?): number
	local info = if id then Rarity.Info[id :: RarityId] else nil
	if not info or info.order <= 6 then
		return 1
	end

	--[[
		6'dan sonraki her kademe esit araliklarla tavana yaklasir.
		Kademe sayisi degisirse bolen de kendiliginden degisir.
	]]
	local sonSira = #Rarity.Order
	local adim = (Rarity.LabelScaleMax - 1) / math.max(sonSira - 6, 1)

	return 1 + adim * (info.order - 6)
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
	DUNYA ETIKETINDE YAZAN KADEME ADI

	Divine ve USTU BUYUK HARF: DIVINE, COSMIC, SECRET, INFERNAL, ABYSSAL.
	O kademelerin uzerinde parlama efekti var ve buyuk harf hem agirlik
	veriyor hem uzaktan okunmasini kolaylastiriyor.

	Altindakiler normal yazimda kaliyor: Common, Rare, Epic, Legendary,
	Mythic. Aralarindaki fark bir bakista gorulsun.
]]
function Rarity.labelText(id: string): string
	local info = Rarity.Info[id :: RarityId]
	if not info then
		return id
	end

	if info.order >= 6 then
		return string.upper(info.displayName)
	end

	return info.displayName
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
--[[
	Rengi CANLI olan kademeler: tek renk degil, iki uc arasinda parildar.

	Eskiden yalnizca Divine boyleydi; artik adaya bagli dort ust kademe de
	oyle. Hepsi Shared > Divine > Flashes icinde tanimli, burasi da orayi
	soruyor -- iki yerde ayri liste tutulursa biri unutulur.
]]
function Rarity.isDivine(id: string): boolean
	return Divine.Flashes[id] ~= nil
end

--[[
	SUZME TURLERI

	Bir isik suzmesinin "kind" alani su seylerden biri olabilir:
	    bir kademe kimligi ("Common".."Secret")
	    bir maden kimligi (bkz. Shared > Ores)
	    "LuckyBlock"

	Son ikisi Rarity.Info icinde YOKTUR. Bu yuzden suzme adini/rengini
	Rarity.get ile almak hataya duser -- get bilinmeyen kimlikte assert atar
	ve cagiran taraf (ornegin GPS arayuzu) komple coker. Asagidaki iki
	fonksiyon uc turu de guvenle karsilar; suzmeyle ugrasan her yer bunlari
	kullanmali.
]]
function Rarity.isBeamKind(kind: string): boolean
	return Rarity.Info[kind :: RarityId] ~= nil or kind == "LuckyBlock"
end

function Rarity.beamName(kind: string): string
	if kind == "LuckyBlock" then
		return Rarity.LuckyBlock.displayName
	end
	local maden = Ores.get(kind)
	if maden then
		return maden.displayName
	end
	return Rarity.displayName(kind)
end

function Rarity.beamColor(kind: string): Color3
	if kind == "LuckyBlock" then
		return Rarity.LuckyBlock.colorA
	end
	local maden = Ores.get(kind)
	if maden then
		return maden.color
	end
	return Rarity.color(kind)
end

--[[
	Kumda gezerken hangi suzmenin cikacagini secer.
	Donen deger bir RarityId ya da "LuckyBlock".
	Agirliklar toplanip oranlaniyor; toplamin tam 100 olmasi sart degil.

	luckMultiplier: 1'den buyuk degerler yuksek kademelere kayma sagligi verir
	(ada bonusu / gelecekteki sans iksirleri icin).

	izin (istege bagli): kademenin bu zeminde dogup dogamayacagini soyler.
	Beams adaya gore veriyor; o adada (onceki adalar dahil) brainrotu
	olmayan kademenin isini orada hic dogmaz. Lucky Block bundan
	etkilenmez.
]]
function Rarity.rollBeam(rng: Random, luckMultiplier: number?, izin: ((string) -> boolean)?): string
	local luck = luckMultiplier or 1

	-- Agirliklari topla: yuksek kademeler luck ile carpilir
	local weights: { { id: string, w: number } } = {}
	local total = 0

	for _, id in Rarity.Order do
		-- Bu adada brainrotu olmayan kademe cekilise girmez
		if izin and not izin(id) then
			continue
		end

		local info = Rarity.Info[id]
		local w = info.beamChance

		--[[
			HER KADEMENIN KENDI SANS USSU  (luckExp)

			    agirlik = beamChance * sans ^ luckExp

			Common (-0.6) ve Rare (-0.3) sans arttikca AZALIR; Epic (0.4)'ten
			Abyssal (2.0)'a kadar usler buyudukce ust kademeler hizla artar.
			Sans = zemin (ada) * GPS * level * arkadas; denizde olta * deniz.

			DENGE HEDEFI (level 5 GPS / olta, kazmadan gezen, isin omru 30 sn):
			yeni acilan kademe kendi adasinda saatte ~2 -- Candy'de Cosmic,
			Snow'da Secret, Volcano'da Infernal; denizde Abyssal saatte ~1.
			Sans 1 iken (Main Island, Basic GPS) oranlar eskisiyle ayni.
		]]
		w *= luck ^ (info.luckExp or 0)

		total += w
		table.insert(weights, { id = id, w = w })
	end

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
