--!strict
--[[
	LUCKY BLOCK

	Kazi sirasinda siyah yumurta yerine bazen bir Lucky Block cikar. Yumurtanin
	aksine Detective'e goturmek gerekmez: acilinca CARK doner ve durdugu
	brainrot dogrudan envantere ACILMIS olarak girer.

	UC AYRI BLOK TURU var. Her turun kendi modeli, kendi cikma sansi ve kendi
	odul tablosu var; asagi turden ust ture gittikce hem daha nadir cikar hem
	daha degerli brainrot verir.

	MODELLER
	Modeller ReplicatedStorage > Assets > LuckyBlocks icine konur. Eslesme
	sirayla yapilir: klasordeki modeller ADA GORE siralanir, ilki 1. ture,
	ikincisi 2. ture, ucuncusu 3. ture gider. Sira yanlissa asagidaki
	modelName alanina modelin tam adini yaz, o zaman sira degil isim gecerli
	olur. Sunucu acilirken bulunan model adlarini Output'a yazar.
]]

local Rarity = require(script.Parent.Rarity)
local Mutations = require(script.Parent.Mutations)

local LuckyBlock = {}

export type Tier = {
	id: string,
	displayName: string,
	-- Klasordeki modelin adi. nil ise sira kullanilir (order alani).
	modelName: string?,
	-- Klasordeki kacinci model bu ture ait (ada gore siralanmis halde)
	order: number,
	color: Color3,
	-- Kazidan hangi turun cikacagi (agirlik; toplamlari 100 olmak zorunda degil)
	dropWeight: number,
	-- Carktan cikacak kademenin agirliklari
	rarityWeights: { [string]: number },
	--[[
		Bu turden cikan HER brainrot bu mutasyonla gelir (cekilis yapilmaz).
		Bos birakilirsa mutationRolls ile normal cekilis yapilir.
	]]
	zorunluMutasyon: string?,
	-- Mutasyon kac kez cekilip en nadiri alinsin (buyudukce daha iyi mutasyon)
	mutationRolls: number,
}

LuckyBlock.Tiers = {
	{
		id = "Normal",
		-- ADI ACIKCA YAZILI: klasordeki alfabetik sira ile tur sirasi tutmuyor
		-- (Hacker Lucky Block basta geliyor), sirayla eslestirmek karistiriyordu
		displayName = "Lucky Block",
		modelName = "New Lucky Block",
		order = 1,
		color = Color3.fromRGB(255, 236, 90),
		dropWeight = 70,
		rarityWeights = {
			Rare = 24,
			Epic = 44,
			Legendary = 24,
			Mythic = 7,
			Secret = 1,
		},
		mutationRolls = 1,
	},
	{
		id = "Golden",
		displayName = "Golden Lucky Block",
		modelName = "New Gold Lucky Block",
		order = 2,
		color = Color3.fromRGB(255, 190, 40),
		dropWeight = 24,
		rarityWeights = {
			Rare = 6,
			Epic = 30,
			Legendary = 38,
			Mythic = 21,
			Secret = 5,
		},
		mutationRolls = 2,
	},
	{
		id = "Diamond",
		displayName = "Diamond Lucky Block",
		modelName = "New Diamond Lucky Block",
		order = 3,
		color = Color3.fromRGB(110, 230, 255),
		dropWeight = 6,
		rarityWeights = {
			Epic = 10,
			Legendary = 34,
			Mythic = 40,
			Secret = 16,
		},
		mutationRolls = 3,
	},
	--[[
		HACKER  --  yalnizca Robux'la, kazidan CIKMAZ

		dropWeight = 0: kazi cekilisinde hic secilmez. Magazada satiliyor
		(bkz. Shared > RobuxMagaza) ve carkta Diamond'dan da iyi oranlar
		veriyor. Modeli Assets > LuckyBlocks > Hacker Lucky Block.
	]]
	{
		id = "Hacker",
		displayName = "Hacker Lucky Block",
		modelName = "Hacker Lucky Block",
		order = 4,
		color = Color3.fromRGB(60, 255, 110),
		dropWeight = 0,
		--[[
			En ust kademelere ulasan TEK blok: Cosmic ve Infernal yalnizca
			buradan cikiyor. Kalan agirlik Legendary ve Mythic'e veriliyor,
			yani "kotu" bir cekilis bile Legendary altina inmiyor.
		]]
		rarityWeights = {
			Legendary = 35,
			Mythic = 52,
			Secret = 4,
			Cosmic = 8,
			Infernal = 1,
		},
		mutationRolls = 4,
		zorunluMutasyon = "Hacker",
	},
} :: { Tier }

LuckyBlock.Default = "Normal"

--[[
	ETKINLIK

	Bloklar kaziyla degil, belirli araliklarla haritadaki kumlarin uzerinde
	belirerek gelir. Herkese acik: ilk giden alir.
]]
LuckyBlock.Event = {
	enabled = true,
	-- Kac saniyede bir dussun (7200 = 2 saat)
	interval = 7200,
	-- Sayac ekranda ne zaman gorunsun: yagmira bu kadar saniye kala
	-- (3600 = son 1 saat). Oncesinde yazi hic cikmaz.
	showBefore = 3600,
	--[[
		HER ADAYA EN COK BIR BLOK

		Asagidaki liste 1. adadan sonuncuya dogru her adanin KUM PARCASININ
		ADI. Yagmurda her ad icin bir blok dusuruluyor, o addan parca yoksa
		o ada atlaniyor.

		En degerli kademe HER ZAMAN listenin SONUNCU adasina duser: ulasmasi
		en zor ada en iyi odulu tasisin.
	]]
	islandSands = { "kum", "sekerkum", "snowkum", "alevkum", "deniz" },
	--[[
		Sunucu acildiktan kac saniye sonra ilk etkinlik olsun.
		Eskiden 180'di: her yeni sunucuda (Studio'da her Play'de) 3. dakikada
		blok yagiyordu. Artik ilk yagmur da normal aralikta gelir.
	]]
	firstDelay = 7200,
	-- Toplanmayan blok kac saniye sonra kaybolur (0 = hic kaybolmasin)
	despawn = 1200,
	--[[
		ISIK KONISI

		Uzun sari sutun yerine BEYAZ bir koni: ince ucu yerden cikar, en
		kalin yeri blogun durdugu yuksekliktir. Blok da bu yukseklikte
		durur, yani koninin genis agzinin uzerine oturur.
	]]
	beaconHeight = 7,
	-- Koninin en genis yerinin genisligi (stud)
	beaconWidth = 7,
	-- Oyuncu kac stud yaklasinca alabilir
	pickupDistance = 12,
}

--[[
	CARK  --  IKI ASAMA

	1. ASAMA (kademe):  bolmelerde yalnizca "?" ve kademe rengi vardir.
	   Cark durunca hangi KADEMENIN ciktigi belli olur (orn. kirmizi = Mythic)
	   ama hangi brainrot oldugu hala bilinmez.

	2. ASAMA (brainrot): serit yeniden kurulur; bu kez SADECE o kademeden
	   cikabilecek brainrotlar doner. Cark durunca odul aciga cikar.

	Butun sureler burada. Sunucu odulu bu surenin sonunda envantere yaziyor,
	istemci de ayni degerlerle ciziyor -- ikisi ayrisamasin diye tek kaynak.
]]
LuckyBlock.Wheel = {
	--[[
		IKI CARK DA 4 SANIYE: carkin donme sesi 4 saniyelik, her cark sesle
		birlikte baslayip sesle birlikte durur. Sure uzadigi icin seritler de
		uzatildi: cark daha cok bolme gecirerek doner, yavaslama uzun surer.
	]]
	-- 1. asama: kademe carki
	cellCount = 58,
	winnerIndex = 48,
	spinTime = 4,

	-- Iki cark arasindaki bekleme (kademe rengi okunacak kadar)
	pause = 0.7,

	-- 2. asama: o kademedeki brainrotlarin carki
	revealCellCount = 40,
	revealWinnerIndex = 33,
	revealSpinTime = 4,

	--[[
		CARK SESI: her cark donmeye baslarken bir kez calar (yalnizca acan
		oyuncu duyar). Studio'daki Sound'un adi; SoundService, Workspace ya
		da ReplicatedStorage icinde aranir. Listedeki ilk bulunan calar;
		hicbiri yoksa adinda "spin" ya da "wheel" gecen ilk Sound denenir.
	]]
	spinSounds = { "WheelSpin", "SpinWheel", "SpinSound", "Wheel Spin", "Spin" },

	-- Cark durduktan sonra odulun cantaya girmesi icin beklenen ek sure
	settle = 0.4,
}

--[[
	Iki carkin toplam suresi.
	Sunucu odulu ve bildirimi bu kadar bekletir; istemci de tam bu kadar
	surede cizer.
]]
function LuckyBlock.totalSpinTime(): number
	local W = LuckyBlock.Wheel
	return W.spinTime + W.pause + W.revealSpinTime + W.settle
end

local byId: { [string]: Tier } = {}
for _, tier in LuckyBlock.Tiers do
	byId[tier.id] = tier
end

function LuckyBlock.get(id: string?): Tier
	return byId[id or LuckyBlock.Default] or LuckyBlock.Tiers[1]
end

function LuckyBlock.exists(id: string?): boolean
	return id ~= nil and byId[id] ~= nil
end

-- Kazidan hangi turun cikacagi
function LuckyBlock.rollTier(rng: Random): string
	local total = 0
	for _, tier in LuckyBlock.Tiers do
		total += tier.dropWeight
	end

	local roll = rng:NextNumber() * total
	local cursor = 0
	for _, tier in LuckyBlock.Tiers do
		cursor += tier.dropWeight
		if roll <= cursor then
			return tier.id
		end
	end

	return LuckyBlock.Default
end

-- Carkin duracagi kademeyi secer (ture gore)
function LuckyBlock.rollRarity(tierId: string, rng: Random): string
	local tier = LuckyBlock.get(tierId)

	local pool: { string } = {}
	local total = 0
	for _, id in Rarity.Order do
		local weight = tier.rarityWeights[id]
		if weight and weight > 0 then
			table.insert(pool, id)
			total += weight
		end
	end

	if #pool == 0 then
		return "Epic"
	end

	local roll = rng:NextNumber() * total
	local cursor = 0
	for _, id in pool do
		cursor += tier.rarityWeights[id]
		if roll <= cursor then
			return id
		end
	end

	return pool[#pool]
end

--[[
	Mutasyon cekilisi.

	Onceden blok turune gore birden cok cekim yapilip EN NADIRI seciliyordu;
	bu yuzden elmas bloklardan surekli en ust mutasyon cikiyordu. Artik
	mutasyon her kaynakta (kazi, lucky block, panel) AYNI ve TEK cekilistir:
	Gold %7, Diamond %3, Galaxy %1.

	tierId imzada kaliyor -- cagiran taraflar degismesin diye.
]]
function LuckyBlock.rollMutation(tierId: string, rng: Random): string
	--[[
		ZORUNLU MUTASYON cekilisin ONUNDE: Hacker Lucky Block'tan cikan her
		brainrot Hacker gelmek zorunda; "mutasyonsuz" ya da baska bir
		mutasyon ihtimali yok.
	]]
	local tier = LuckyBlock.get(tierId)
	if tier and tier.zorunluMutasyon then
		return tier.zorunluMutasyon
	end
	return Mutations.roll(rng)
end

return LuckyBlock
