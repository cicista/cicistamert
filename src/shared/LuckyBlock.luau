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
	-- Mutasyon kac kez cekilip en nadiri alinsin (buyudukce daha iyi mutasyon)
	mutationRolls: number,
}

LuckyBlock.Tiers = {
	{
		id = "Normal",
		displayName = "Lucky Block",
		modelName = nil,
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
		modelName = nil,
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
		modelName = nil,
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
	-- 1. asama: kademe carki
	cellCount = 44,
	winnerIndex = 36,
	spinTime = 3,

	-- Iki cark arasindaki bekleme (kademe rengi okunacak kadar)
	pause = 0.7,

	-- 2. asama: o kademedeki brainrotlarin carki
	revealCellCount = 30,
	revealWinnerIndex = 24,
	revealSpinTime = 2.6,

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
function LuckyBlock.rollMutation(_tierId: string, rng: Random): string
	return Mutations.roll(rng)
end

return LuckyBlock
