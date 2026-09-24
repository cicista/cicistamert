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

	--[[
		NE ZAMAN OLUR

		Iki sart birden: sunucuda gerekenOyuncu kadar kisi olacak VE son
		yagmurun uzerinden interval kadar gecmis olacak. Sart tamamlaninca
		geriSayim saniye beklenir (herkes ekrandaki "6/6" yazisini gorup
		hazirlansin), sonra bloklar duser.

		Sayim basladiktan sonra biri cikarsa yagmur yine de olur: oyuncular
		son saniyede oyundan atilmasin diye.
	]]
	gerekenOyuncu = 6,
	--[[
		Sunucu doldugunda baslayan geri sayim (saniye). 300 = 5 dakika:
		oyuncularin flyboardlarini alip adalara yayilmasina yetecek kadar.
	]]
	geriSayim = 300,
	--[[
		BILDIRIM KAC KISIDEN SONRA GORUNUR

		Ekranin sag ustundeki "4/6 PLAYERS" kutusu bu sayidan itibaren
		cikiyor. Altina dusunce kayboluyor: iki kisilik bir sunucuda
		"2/6" yazisi umut vermiyor, yalnizca yer kapliyor.
	]]
	bildirimOyuncu = 4,
	-- Iki yagmur arasindaki en az sure (3600 = 1 saat)
	interval = 3600,
	--[[
		BLOKLARIN DUSTUGU YERLER  --  "luckyzemin" parcalari

		Haritadaki adalarin (Island modelleri) icine konmus, adinda
		"luckyzemin" gecen parcalar. Her yagmurda bunlarin arasindan
		RASTGELE secim yapilir ve HER ZEMINE EN COK BIR BLOK duser:
		ayni yere iki blok cikmaz, zeminlerin hepsi de dolmaz.

		Buyuk/kucuk harf, bosluk ve alt cizgi onemsiz; "LuckyZemin 3",
		"lucky_zemin" hepsi olur.
	]]
	zeminAdi = "luckyzemin",

	-- Her yagmurda kac blok duser
	blokSayisi = 5,

	--[[
		HER BLOK AYRI CEKILIYOR

		Bloklarin hepsi Normal olarak baslar; her biri icin asagidaki
		liste SIRAYLA deneniyor ve ilk tutan kademe kazaniyor. Sira
		NADIRDEN BOLA: Hacker'in %0.5'i Golden'in %30'unun icinde
		kaybolmasin.

		Hicbiri tutmazsa blok Normal kalir (su degerlerle ~%59.5).

		Bloklar birbirinden bagimsiz: bes blogun besi de Normal cikabilir,
		ikisi birden Diamond da cikabilir.
	]]
	tierSanslari = {
		{ tier = "Hacker", sans = 0.5 },
		{ tier = "Diamond", sans = 10 },
		{ tier = "Golden", sans = 30 },
	},

	--[[
		BIR OYUNCU BIR YAGMURDA EN COK KAC BLOK ALABILIR

		Bes blok var ve hepsi herkese acik; sinir olmasa en hizli oyuncu
		besini birden toplardi. 1 = herkes en fazla bir tane.
	]]
	oyuncuBasiLimit = 1,

	--[[
		KADEME GORUNUMU  --  ozel bloklar uzaktan bagirsin

		olcek     modelin boy carpani
		sutun     gokyuzune uzanan isik sutununun yuksekligi (stud)
		kalinlik  sutunun yerdeki genisligi
		isik      PointLight menzili
		kivilcim  blogun etrafinda parildayan parcaciklar
		halka     blogun altinda donen isik halkasi
	]]
	gorunum = {
		Normal = { olcek = 1, sutun = 140, kalinlik = 4, isik = 26 },
		Golden = { olcek = 1.45, sutun = 320, kalinlik = 7, isik = 45, kivilcim = true },
		Diamond = { olcek = 1.7, sutun = 420, kalinlik = 9, isik = 60, kivilcim = true, halka = true },
		Hacker = { olcek = 1.7, sutun = 420, kalinlik = 9, isik = 60, kivilcim = true, halka = true },
	},

	--[[
		YEDEK: zemin bulunamazsa eski davranis

		Adinda "luckyzemin" gecen tek bir parca yoksa bloklar eskisi gibi
		asagidaki kum parcalarinin uzerine duser (her adaya bir tane) ve
		Output'a bir uyari yazilir.
	]]
	islandSands = { "kum", "sekerkum", "snowkum", "alevkum", "deniz" },

	--[[
		Sunucu acildiktan sonraki ilk bekleme. Yeni acilan (ya da Studio'da
		Play'e basilan) sunucuda oyuncu sayisi hemen dolarsa bloklar aninda
		yagmasin diye kisa bir nefes payi.
	]]
	firstDelay = 60,
	-- Toplanmayan blok kac saniye sonra kaybolur (0 = hic kaybolmasin)
	despawn = 120,
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

-- Bir yagmurda dusen toplam blok sayisi (zemin yeterse)
function LuckyBlock.toplamBlok(): number
	return LuckyBlock.Event.blokSayisi
end

--[[
	BIR BLOGUN KADEMESI  --  her blok icin ayri cekilis

	Liste nadirden bola sirali (bkz. Event.tierSanslari); ilk tutan kademe
	kazaniyor, hicbiri tutmazsa Normal.
]]
function LuckyBlock.etkinlikKademesi(rng: Random): string
	for _, satir in LuckyBlock.Event.tierSanslari do
		if rng:NextNumber() * 100 < satir.sans then
			return satir.tier
		end
	end
	return LuckyBlock.Default
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
