--!strict
--[[
	Oyuncu verisinin tek kaynagi.

	Tutulan veri:
	  rot        -- ana para birimi (pasif gelirle artar)
	  luckyBlocks -- acilmayi bekleyen Lucky Block'lar, TURE gore: { Normal = 2 }
	  shovel     -- sahip olunan TEK kurek (yenisi alininca eskisi silinir)
	  inventory  -- envanterdeki brainrotlar (siyah veya acilmis)
	  base       -- atanmis base indeksi (oturum boyunca)
	  baseFloors -- base'te acilmis kat sayisi (1..3)
	  baseSlots  -- acilmis toplam slot sayisi (10..30)
	  lastReward -- son gunluk odulun alindigi an (os.time)
	  rewardDay  -- gunluk odul takviminde siradaki gun (1..7)
	  luckUntil  -- gecici sans carpaninin bitis ani (os.time)
	  luckBonus  -- gecici sans carpani (1 = bonus yok)

	Envanterdeki her brainrot:
	  { uid, rarity, condition, mutation, name?, revealed }
	  name yalnizca Detective temizledikten sonra dolar; o ana kadar
	  oyuncu sadece rarity'yi gorur (simsiyah hal).
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Shovels = require(Shared:WaitForChild("Shovels"))
local Detectors = require(Shared:WaitForChild("Detectors"))
local Flyboard = require(Shared:WaitForChild("Flyboard"))
local Rods = require(Shared:WaitForChild("Rods"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Passler = require(Shared:WaitForChild("Passler"))
-- Gunluk odul takviminin gun sayisi (rewardDay sinirlari)
local Rewards = require(Shared:WaitForChild("Rewards"))
local Ores = require(Shared:WaitForChild("Ores"))

export type InventoryItem = {
	uid: string,
	rarity: string,
	condition: string,
	-- Model ve gelir carpani (Normal, Gold, Lava, Diamond, Galaxy, Rainbow, Hacker)
	mutation: string,
	name: string?,
	revealed: boolean,
	-- Base'e yerlestirildiyse slot indeksi, degilse nil
	slot: number?,
	--[[
		Kazildigi ada (kum, sekerkum, snowkum, alevkum, deniz).

		Detective adi SECERKEN kullaniliyor: esya hangi adadan ciktiysa o
		adanin listesinden isim aliyor. Eski kayitlarda yok; nil gelirse
		ilk ada sayiliyor.
	]]
	island: string?,
}

export type QuestState = {
	cycle: number,
	progress: { [string]: number },
	done: { [string]: boolean },
}

export type Data = {
	rot: number,
	-- Ikinci para birimi (HUD'da Rot'un altinda)
	rotCoins: number,
	luckyBlocks: { [string]: number },
	--[[
		SURELI GECISLER  --  { [gecisAdi] = bitecegi an (os.time) }

		Playtime ve gunluk odullerden cikan gecici Auto Clicker / Teleporter
		burada duruyor. Suresi gecenler yuklenirken temizlenir.
	]]
	tempPasses: { [string]: number },
	-- Mutasyon scroll sayaclari (bkz. Shared > Scrolls)
	scrolls: { [string]: number },
	--[[
		KADEMELI ESYALAR

		Iki alan var: KUSANILAN kademe ve SAHIP OLUNAN EN YUKSEK kademe.
		Oyuncu satin aldigi butun kademeleri kalici olarak tasir; saticidan
		istedigi zaman alt kademeye geri donebilir (orn. daha kucuk barli
		kurek isteyen oyuncu). Satin alma hep en yuksek kademeye bakar.
	]]
	shovel: string,
	shovelMax: string,
	detector: string,
	detectorMax: string,
	-- Olta: kusanilan ve sahip olunan en yuksek (hic yoksa nil)
	rod: string?,
	rodMax: string?,
	-- Flyboard: kusanilan ve en yuksek (hic yoksa nil)
	flyboard: string?,
	flyboardMax: string?,
	inventory: { InventoryItem },
	base: number?,
	-- Base gelisimi: kac kat acik ve toplam kac slot kullanilabilir
	baseFloors: number,
	baseSlots: number,
	-- Gunluk odul ve gecici sans
	lastReward: number,
	-- Gunluk odul takviminde siradaki gun (bkz. Shared > Rewards)
	rewardDay: number,
	luckUntil: number,
	luckBonus: number,
	-- Level sistemi (bkz. Shared > Seviye)
	level: number,
	xp: number,
	-- Rewards > Social: alinan tek seferlik oduller ("group", "like") ve kullanilan kodlar
	socialClaimed: { [string]: boolean },
	redeemedCodes: { [string]: boolean },
	-- Detective'e birakilan toplu inceleme: { bitis = os.time, toplam, uids }
	detectiveJob: any?,
	-- Acilmis en yuksek ada indeksi (1 = sadece baslangic adasi)
	islands: number,
	--[[
		KAZI YAPILAN EN ILERI ADA (Brainrots.IslandOrder kimligi)

		Lucky Block, gunluk odul ve Fuse coin brainrotlari bu adaya KADAR
		olan havuzdan seciliyor; oyuncu henuz gitmedigi adanin brainrotunu
		bu yollardan da alamaz.
	]]
	reachedIsland: string,
	-- Madenler: { Amethyst = 3, ... } (bkz. Shared > Ores)
	ores: { [string]: number },
	-- Satin alinmis kazmalar: { CandyPickaxe = true }
	pickaxes: { [string]: boolean },
	-- Arayuz olcegi yuzdesi (Settings > Interface Scale); 100 = varsayilan
	uiScale: number,
	-- Arka plan muzigi: ses yuzdesi (0..100) ve kapali mi
	musicVolume: number,
	musicMuted: boolean,
	-- Ses efektleri (muzik haric butun sesler): yuzde ve kapali mi
	sfxVolume: number,
	sfxMuted: boolean,
	-- Ekran sarsintisi kapali mi (Settings > Screen Shake)
	shakeOff: boolean,
	-- Alinan hiz yukseltmesi sayisi (0..100, bkz. Shared > Hiz)
	speedLevel: number,
	-- Hiz rebirth sayisi (0..Hiz.MaxRebirth); arkadaki izin boyu ve rengi
	speedRebirth: number,
	-- Gorev panosu: hangi yarim saatlik dilimdeyiz ve o dilimin ilerlemesi
	quests: QuestState,
	--[[
		INDEX  --  kimligi ogrenilmis brainrot adlari

		Esyanin kendisi degil BILGISI tutuluyor: oyuncu brainrotu satsa,
		fuse etse, base'e koysa da Index'te kayitli kalir. Anahtar
		brainrotun katalogdaki tam adi.
	]]
	discovered: { [string]: boolean },
	--[[
		MUTASYONLU INDEX  --  { Gold = { [brainrot adi] = true }, ... }

		Yalnizca Mutations.IndexOrder'daki mutasyonlar tutulur. Normal
		kesif (discovered) mutasyondan bagimsiz; bu tablo ayrica "Gold
		haliyle de buldu mu" bilgisini tasir.
	]]
	discoveredMut: { [string]: { [string]: boolean } },
	--[[
		ISLENMIS ROBUX SATIN ALMALARI  --  { [PurchaseId] = os.time }

		Roblox ayni fisi (receipt) birden fazla kez yollayabiliyor. Fis
		burada kayitliysa urun ikinci kez VERILMEZ. Eski kayitlar yuklenirken
		budaniyor (bkz. SATIN_ALMA_OMRU).
	]]
	purchases: { [string]: number },
	--[[
		OGRETICI  --  yeni oyuncunun ilk turu (bkz. Shared > Ogretici)

		adim  : SIRADAKI adimin sira numarasi (1 = ilk adim)
		bitti : butun adimlar tamamlandi; bir daha hic baslamaz

		Eski kayitlarda bu alan yok; o oyuncular ogreticiyi gormus SAYILIR
		(bitti = true). Aylardir oynayan birine "kuma git" demek sacma
		olurdu.
	]]
	tutorial: { adim: number, bitti: boolean },
}

local PlayerData = {}

-- Ekip testi icin sifirlandi (v1 kayitlari silinmedi, kullanilmiyor)
local STORE_NAME = "BrainrotDig_v2"
local store = if RunService:IsStudio() then nil else DataStoreService:GetDataStore(STORE_NAME)

local cache: { [Player]: Data } = {}
local uidCounter = 0

local function defaultData(): Data
	return {
		rot = 0,
		rotCoins = 0,
		luckyBlocks = {},
		scrolls = {},
		tempPasses = {},
		shovel = Shovels.Default,
		shovelMax = Shovels.Default,
		detector = Detectors.Default,
		detectorMax = Detectors.Default,
		rod = nil,
		rodMax = nil,
		flyboard = nil,
		flyboardMax = nil,
		inventory = {},
		base = nil,
		-- 1. kat bedava gelir (bkz. Bases.Upgrade.startingSlots)
		baseFloors = 1,
		baseSlots = 10,
		lastReward = 0,
		rewardDay = 1,
		luckUntil = 0,
		luckBonus = 1,
		level = 1,
		xp = 0,
		socialClaimed = {},
		redeemedCodes = {},
		islands = 1,
		reachedIsland = Brainrots.IslandOrder[1],
		ores = {},
		pickaxes = {},
		uiScale = 100,
		musicVolume = 100,
		musicMuted = false,
		sfxVolume = 100,
		sfxMuted = false,
		shakeOff = false,
		speedLevel = 0,
		speedRebirth = 0,
		quests = { cycle = 0, progress = {}, done = {} },
		-- Yeni oyuncu ogreticinin ilk adiminda baslar
		tutorial = { adim = 1, bitti = false },
		discovered = {},
		discoveredMut = {},
		purchases = {},
	}
end

-- Kaydedilen veriyi mevcut sema ile birlestirir; eksik alanlari doldurur.
--[[
	OYUNDAN KALDIRILAN BRAINROTLAR

	Katalogdan bir brainrot cikarildiginda eski kayitlardaki kopyalari
	ortada kalir: adi artik taninmadigi icin geliri 0 hesaplanir ve satista
	da deger uretmez -- oyuncunun elinde ise yaramaz bir esya kalir.

	Bu yuzden kayit yuklenirken boyle bir esya AYNI rarity havuzundan baska
	bir brainrota cevriliyor. Oyuncu esyasini kaybetmiyor, kaldirilan isim de
	oyunda hicbir yerde gorunmuyor.
]]
local degistirmeRng = Random.new()

-- Islenmis Robux fisleri bu kadar saniye saklanir (30 gun)
local SATIN_ALMA_OMRU = 30 * 24 * 3600

local function gecerliAd(name: any, rarity: any): string?
	if type(name) ~= "string" then
		return nil
	end

	if Brainrots.get(name) then
		return name
	end

	local pool = Brainrots.pool(rarity)
	if #pool == 0 then
		return nil
	end

	return pool[degistirmeRng:NextInteger(1, #pool)].name
end

-- Kayittaki tek bir brainrot kaydini dogrular ve temiz bir kopya doner
local function esyaOku(item: any): InventoryItem?
	if type(item) ~= "table" or type(item.uid) ~= "string" or type(item.rarity) ~= "string" then
		return nil
	end

	-- Katalogdan kaldirilmis bir isimse ayni rarity'den bir baskasi gelir
	local ad = gecerliAd(item.name, item.rarity)

	return {
		uid = item.uid,
		rarity = item.rarity,
		condition = if type(item.condition) == "string" then item.condition else "Normal",
		-- Mutasyon oncesi kayitlar Normal sayilir
		mutation = if type(item.mutation) == "string" then item.mutation else "Normal",
		name = ad,
		-- Adsiz kalan esya "kimligi belirlenmemis" durumuna doner
		revealed = item.revealed == true and ad ~= nil,
		slot = tonumber(item.slot),
		--[[
			Ada KORUNMALI: eskiden burada dusuyordu ve yeniden girince
			kimliksiz esya adasiz kaliyor, Detective butun havuzdan
			isim veriyordu.
		]]
		island = if type(item.island) == "string" then item.island else nil,
	} :: any
end

local function migrate(raw: any): Data
	local data = defaultData()
	if type(raw) ~= "table" then
		return data
	end

	data.rot = tonumber(raw.rot) or 0
	-- Eski kayitlardaki Rot Coin bakiyesi de geri gelir
	data.rotCoins = tonumber(raw.rotCoins) or 0

	--[[
		OGRETICI DURUMU

		Alan YOKSA oyuncu ogreticiyi gormus sayilir: bu kayit ogretici
		eklenmeden once acilmis, yani oyuncu oyunu zaten biliyor. Yalnizca
		gercekten yeni kayitlar (defaultData) ogreticiye basliyor.
	]]
	local ogretici = if type(raw.tutorial) == "table" then raw.tutorial else nil
	if ogretici then
		data.tutorial = {
			adim = math.max(1, math.floor(tonumber(ogretici.adim) or 1)),
			bitti = ogretici.bitti == true,
		}
	else
		data.tutorial = { adim = 1, bitti = true }
	--[[
		SURELI GECISLER  --  suresi gecmis olanlar atilir

		Zaman os.time ile mutlak; sunucu yeniden baslasa da oyuncu cikip
		girse de kalan sure dogru hesaplanir.
	]]
	data.tempPasses = {}
	if type(raw.tempPasses) == "table" then
		local simdi = os.time()
		for ad, bitis in raw.tempPasses do
			local an = tonumber(bitis)
			if type(ad) == "string" and an and an > simdi then
				data.tempPasses[ad] = math.floor(an)
			end
		end
	end

	end
	--[[
		SCROLL SAYACLARI  --  eski kayitlarda yok, bos baslar
	]]
	data.scrolls = {}
	if type(raw.scrolls) == "table" then
		for id, adet in raw.scrolls do
			local sayi = tonumber(adet)
			if type(id) == "string" and sayi and sayi > 0 then
				data.scrolls[id] = math.floor(sayi)
			end
		end
	end

	--[[
		Eski kayitlarda luckyBlocks tek bir SAYIYDI (tur ayrimi yoktu).
		O kayitlar Normal ture aktariliyor, yoksa oyuncunun bloklari ucardi.
	]]
	if type(raw.luckyBlocks) == "number" then
		local count = math.max(0, math.floor(raw.luckyBlocks))
		if count > 0 then
			data.luckyBlocks.Normal = count
		end
	elseif type(raw.luckyBlocks) == "table" then
		for tierId, count in raw.luckyBlocks do
			if type(tierId) == "string" and tonumber(count) then
				data.luckyBlocks[tierId] = math.max(0, math.floor(tonumber(count) :: number))
			end
		end
	end
	data.islands = math.max(1, tonumber(raw.islands) or 1)
	data.reachedIsland = Brainrots.normalizeIsland(if type(raw.reachedIsland) == "string" then raw.reachedIsland else nil)

	-- Maden oncesi kayitlarda bu alanlar yok; bos baslanir. Bilinmeyen kimlikler atilir.
	if type(raw.ores) == "table" then
		for id, count in raw.ores do
			if Ores.get(id) and tonumber(count) then
				data.ores[id] = math.max(0, math.floor(tonumber(count) :: number))
			end
		end
	end
	if type(raw.pickaxes) == "table" then
		for id, owned in raw.pickaxes do
			if type(id) == "string" and Ores.Pickaxes[id] and owned == true then
				data.pickaxes[id] = true
			end
		end
	end

	-- Ayar oncesi kayitlarda uiScale yok; varsayilan %100 ile acilir
	data.uiScale = math.clamp(tonumber(raw.uiScale) or 100, 50, 150)
	-- Muzik ayari oncesi kayitlar: tam ses, acik
	data.musicVolume = math.clamp(tonumber(raw.musicVolume) or 100, 0, 100)
	data.musicMuted = raw.musicMuted == true
	-- Ses efekti ayari oncesi kayitlar: tam ses, acik
	data.sfxVolume = math.clamp(tonumber(raw.sfxVolume) or 100, 0, 100)
	data.sfxMuted = raw.sfxMuted == true
	data.shakeOff = raw.shakeOff == true
	-- Hiz yukseltmesi oncesi kayitlar 0'dan baslar
	data.speedLevel = math.clamp(math.floor(tonumber(raw.speedLevel) or 0), 0, 100)
	data.speedRebirth = math.clamp(math.floor(tonumber(raw.speedRebirth) or 0), 0, 6)

	-- Gelisim oncesi kayitlar 1 kat / 10 slot olarak acilir
	data.baseFloors = math.clamp(tonumber(raw.baseFloors) or 1, 1, 3)
	data.baseSlots = math.clamp(tonumber(raw.baseSlots) or 10, 10, 30)

	-- Odul oncesi kayitlarda bu alanlar yok; sifirdan baslarlar
	data.lastReward = math.max(0, tonumber(raw.lastReward) or 0)
	-- Takvim oncesi kayitlarda yok: 1. gunden baslarlar
	data.rewardDay = math.clamp(math.floor(tonumber(raw.rewardDay) or 1), 1, #Rewards.Days)
	data.luckUntil = math.max(0, tonumber(raw.luckUntil) or 0)
	data.luckBonus = math.max(1, tonumber(raw.luckBonus) or 1)
	-- Level sisteminden onceki kayitlar Level 1'den baslar
	data.level = math.clamp(math.floor(tonumber(raw.level) or 1), 1, 100)
	data.xp = math.max(0, math.floor(tonumber(raw.xp) or 0))
	--[[
		DETECTIVE ISI oyundan cikip girince de surer.

		Yeni bicim: brainrotlar envanterden CIKIP isin icinde durur (items);
		is bitince (bitti) oyuncu Detective'e gidip geri alir.
		Eski bicimde yalnizca uid listesi vardi, esyalar envanterdeydi: onlar
		asagida, envanter okunduktan sonra ise tasiniyor.
	]]
	local is = raw.detectiveJob
	local eskiIsUidleri: { string }? = nil
	if type(is) == "table" and type(is.bitis) == "number" then
		local items = {}
		if type(is.items) == "table" then
			for _, item in is.items do
				local kopya = esyaOku(item)
				if kopya then
					table.insert(items, kopya)
				end
			end
		end
		if type(is.uids) == "table" and not is.items then
			eskiIsUidleri = {}
			for _, uid in is.uids do
				if type(uid) == "string" then
					table.insert(eskiIsUidleri :: { string }, uid)
				end
			end
		end
		data.detectiveJob = {
			bitis = is.bitis,
			toplam = tonumber(is.toplam) or 0,
			items = items,
			bitti = is.bitti == true,
		}
	end

	-- Social Rewards (onceki kayitlarda yok: hic alinmamis sayilir)
	data.socialClaimed = {}
	data.redeemedCodes = {}
	for alan, hedef in { socialClaimed = data.socialClaimed, redeemedCodes = data.redeemedCodes } do
		if type(raw[alan]) == "table" then
			for anahtar, deger in raw[alan] do
				if type(anahtar) == "string" and deger == true then
					hedef[anahtar] = true
				end
			end
		end
	end

	-- Fuse coinleri (coin sisteminden onceki kayitlarda bu alan yok)
	--[[
		COIN SISTEMI KALDIRILDI  --  eski coinler brainrota cevrilir

		Fuse makinesi ve gorevler artik coin degil brainrot veriyor, Coin
		Trader da yok. Kayitta coin kalan oyuncu kaybetmesin: her coin,
		kendi kademesinden (oyuncunun ulastigi adaya gore) kimligi ACIK bir
		brainrota donusur; boyut ve mutasyon coinden aynen gecer.
	]]
	if type(raw.coins) == "table" then
		for _, coin in raw.coins do
			if type(coin) ~= "table" or type(coin.rarity) ~= "string" then
				continue
			end

			local kademe = Brainrots.clampRarity(coin.rarity, data.reachedIsland)
			if #Brainrots.pool(kademe :: any) == 0 then
				continue
			end

			local info = Brainrots.rollIsland(kademe :: any, data.reachedIsland, degistirmeRng)
			table.insert(data.inventory, {
				uid = if type(coin.uid) == "string" then coin.uid else PlayerData.newUid(),
				rarity = kademe,
				condition = if type(coin.condition) == "string" then coin.condition else "Normal",
				mutation = if type(coin.mutation) == "string" then coin.mutation else "Normal",
				name = info.name,
				revealed = true,
				slot = nil,
				island = data.reachedIsland,
			})
		end
	end

	if type(raw.shovel) == "string" and Shovels.Info[raw.shovel] then
		data.shovel = raw.shovel
	end

	if type(raw.detector) == "string" and Detectors.Info[raw.detector] then
		data.detector = raw.detector
	end

	-- Flyboard oncesi kayitlarda bu alan yok; tahtasiz baslanir
	if type(raw.flyboard) == "string" and Flyboard.exists(raw.flyboard) then
		data.flyboard = raw.flyboard
	end

	--[[
		EN YUKSEK KADEMELER

		"Alt kademeye geri don" ozelliginden ONCEKI kayitlarda bu alanlar yok:
		o kayitlarda kusanilan kademe ayni zamanda en yuksegidir, cunku satin
		alma eskiyi siliyordu. Bu yuzden yoklarsa kusanilandan dolduruluyor --
		hic kimse parasini verdigi kademeyi kaybetmiyor.
	]]
	if type(raw.shovelMax) == "string" and Shovels.Info[raw.shovelMax] then
		data.shovelMax = raw.shovelMax
	else
		data.shovelMax = data.shovel
	end

	if type(raw.detectorMax) == "string" and Detectors.Info[raw.detectorMax] then
		data.detectorMax = raw.detectorMax
	else
		data.detectorMax = data.detector
	end

	if type(raw.flyboardMax) == "string" and Flyboard.exists(raw.flyboardMax) then
		data.flyboardMax = raw.flyboardMax
	else
		data.flyboardMax = data.flyboard
	end

	-- Olta oncesi kayitlarda bu alanlar yok; oltasiz baslanir
	if type(raw.rod) == "string" and Rods.exists(raw.rod) then
		data.rod = raw.rod
	end

	if type(raw.rodMax) == "string" and Rods.exists(raw.rodMax) then
		data.rodMax = raw.rodMax
	else
		data.rodMax = data.rod
	end

	-- Skin sistemi kaldirildi: eski kayitlardaki skins/equipped okunmuyor, sonraki kayitta duser

	if type(raw.inventory) == "table" then
		for _, item in raw.inventory do
			local kopya = esyaOku(item)
			if kopya then
				table.insert(data.inventory, kopya)
			end
		end
	end

	-- Eski bicim Detective isi: esyalar envanterden isin icine tasinir
	local isVerisi = data.detectiveJob
	if eskiIsUidleri and isVerisi then
		local istenen: { [string]: boolean } = {}
		for _, uid in eskiIsUidleri do
			istenen[uid] = true
		end
		for i = #data.inventory, 1, -1 do
			local item = data.inventory[i]
			if istenen[item.uid] and not item.revealed then
				table.insert(isVerisi.items, table.remove(data.inventory, i))
			end
		end
	end

	--[[
		INDEX GERI YUKLENIYOR

		Katalogdan cikarilmis isimler ATILIYOR (envanterdeki esyalarda
		oldugu gibi baska bir brainrota cevrilmiyor): Index bir kayit
		defteri, oyuncuya gormedigi bir brainrotu gormus gibi yazmak
		yanlis olur. Artik var olmayan isim de panelde cizilemez.
	]]
	if type(raw.discovered) == "table" then
		for name, kesfedildi in raw.discovered do
			if kesfedildi == true and type(name) == "string" and Brainrots.get(name) then
				data.discovered[name] = true
			end
		end
	end

	-- Mutasyonlu Index: yalnizca Index'te gosterilen mutasyonlar ve katalogdaki adlar
	if type(raw.discoveredMut) == "table" then
		for _, mutasyon in Mutations.IndexOrder do
			local kayit = raw.discoveredMut[mutasyon]
			if type(kayit) == "table" then
				local hedef = {}
				for name, var in kayit do
					if var == true and type(name) == "string" and Brainrots.get(name) then
						hedef[name] = true
					end
				end
				data.discoveredMut[mutasyon] = hedef
			end
		end
	end

	-- Robux fisleri: Roblox en fazla birkac gun tekrar dener, eskileri tutulmaz
	data.purchases = {}
	if type(raw.purchases) == "table" then
		local sinir = os.time() - SATIN_ALMA_OMRU
		for fis, zaman in raw.purchases do
			if type(fis) == "string" and type(zaman) == "number" and zaman >= sinir then
				data.purchases[fis] = zaman
			end
		end
	end

	return data
end

function PlayerData.newUid(): string
	uidCounter += 1
	return string.format("%d_%d", os.time() % 1000000, uidCounter)
end

function PlayerData.load(player: Player): Data
	if cache[player] then
		return cache[player]
	end

	local raw: any = nil
	if store then
		local ok, result = pcall(function()
			return store:GetAsync(tostring(player.UserId))
		end)
		if ok then
			raw = result
		else
			warn(`[PlayerData] {player.Name} yuklenemedi: {tostring(result)}`)
		end
	end

	local data = migrate(raw)
	cache[player] = data
	return data
end

function PlayerData.get(player: Player): Data?
	return cache[player]
end

-- Kayit basarili mi doner (Studio'da store yok: true). Robux satin alma buna bakar.
function PlayerData.save(player: Player): boolean
	local data = cache[player]
	if not data then
		return false
	end
	if not store then
		return true
	end

	local ok, err = pcall(function()
		store:SetAsync(tostring(player.UserId), data)
	end)
	if not ok then
		warn(`[PlayerData] {player.Name} kaydedilemedi: {tostring(err)}`)
	end
	return ok
end

--[[
	OYUNCU AYRILIRKEN, VERI KAYDEDILMEDEN ONCE calisan kancalar.

	Baska sistemler oyuncunun esyalarini gecici olarak verisinden CIKARIP
	kendilerinde tutabiliyor (ornegin Fuse makinesi, icine konan brainrotlari).
	O esyalarin geri yazilmasi Players.PlayerRemoving'e baglansaydi kaybolma
	riski olurdu: bu modul de ayni sinyale bagli ve Roblox baglanti sirasini
	garanti etmiyor -- once burasi calisirsa cache silinir ve digerinin geri
	yazacagi bir yer kalmaz.

	Bu kancalar cache HALA DOLUYKEN calisir, yani geri yazma her zaman tutar.
]]
local beforeRelease: { (player: Player) -> () } = {}

function PlayerData.onBeforeRelease(callback: (player: Player) -> ())
	table.insert(beforeRelease, callback)
end

function PlayerData.release(player: Player)
	-- Biri patlarsa digerleri ve kayit yine de calissin
	for _, callback in beforeRelease do
		local ok, err = pcall(callback, player)
		if not ok then
			warn(`[PlayerData] {player.Name}: ayrilma kancasi hata verdi -- {tostring(err)}`)
		end
	end

	PlayerData.save(player)
	cache[player] = nil
end

------------------------------------------------------------------
-- ENVANTER YARDIMCILARI
------------------------------------------------------------------

--[[
	island: brainrotun HANGI ADADAN cikitigi.

	Kazi aninda adi henuz belli degil (Detective acana kadar gizli), o
	yuzden ada esyanin uzerinde tasiniyor ve isim SECILIRKEN kullaniliyor
	-- boylece Snow adasindan kazilan bir Epic, Snow'un Epic listesinden
	cikiyor.

	Eski kayitlarda bu alan yok; nil gelirse butun havuza dusuluyor.
]]
function PlayerData.addBrainrot(
	player: Player,
	rarity: string,
	condition: string,
	mutation: string?,
	island: string?
): InventoryItem?
	local data = cache[player]
	if not data then
		return nil
	end

	local item: InventoryItem = {
		uid = PlayerData.newUid(),
		rarity = rarity,
		condition = condition,
		mutation = mutation or "Normal",
		name = nil,
		revealed = false,
		slot = nil,
		island = island,
	}

	--[[
		DETECTIVE PASS  --  kimlik dedektife ugramadan acilir

		Pass sahibinin kazdigi ve oltadan cikardigi her brainrot ACIK gelir:
		isim burada, dedektifin yaptigi isin aynisiyla seciliyor (kazildigi
		adanin havuzundan). Mutasyon zaten esyanin uzerinde, acilinca
		gorunur oluyor.

		Kanca BURADA, cagiran yerlerde degil: kazi, olta ve sonradan
		eklenecek her yol bu fonksiyondan geciyor, tek satirla hepsi kapsanir.
	]]
	if Passler.sahip(player, "DetectivePass") then
		local secilen = Brainrots.rollIsland(rarity :: any, island, Random.new())
		if secilen then
			item.name = secilen.name
			item.revealed = true
		end
	end

	table.insert(data.inventory, item)
	return item
end

--[[
	INDEX'E BIR BRAINROT ISLE

	Yeni kayit eklendiyse true doner (cagiran taraf "yeni kesif" bildirimi
	gostermek isterse kullanir). Katalogda olmayan ad yok sayilir.
]]
-- Maden ekler (eksi deger duser); yeni adedi doner
function PlayerData.addOre(player: Player, oreId: string, amount: number): number
	local data = cache[player]
	if not data or not Ores.get(oreId) then
		return 0
	end
	local yeni = math.max(0, (data.ores[oreId] or 0) + amount)
	data.ores[oreId] = yeni
	return yeni
end

function PlayerData.oreCount(player: Player, oreId: string): number
	local data = cache[player]
	return if data then data.ores[oreId] or 0 else 0
end

function PlayerData.hasPickaxe(player: Player, pickaxeId: string?): boolean
	local data = cache[player]
	return data ~= nil and pickaxeId ~= nil and data.pickaxes[pickaxeId] == true
end

-- Kazi yapilan adayi kaydeder; yalnizca ILERI gider
function PlayerData.reachIsland(player: Player, island: string?)
	local data = cache[player]
	if not data or not island then
		return
	end
	data.reachedIsland = Brainrots.laterIsland(data.reachedIsland, island)
end

function PlayerData.reachedIsland(player: Player): string
	local data = cache[player]
	return if data then data.reachedIsland else Brainrots.IslandOrder[1]
end

function PlayerData.discover(player: Player, name: string?): boolean
	if type(name) ~= "string" then
		return false
	end

	local data = cache[player]
	if not data or data.discovered[name] then
		return false
	end

	if not Brainrots.get(name) then
		return false
	end

	data.discovered[name] = true
	return true
end

-- Index panelinin okudugu kesif tablosu; salt okunur kullanilmali
function PlayerData.discovered(player: Player): { [string]: boolean }
	local data = cache[player]
	return if data then data.discovered else {}
end

-- Index'te gosterilen mutasyonlar (Mutations.IndexOrder) kume olarak
local indexMutasyonu: { [string]: boolean } = {}
for _, mutasyon in Mutations.IndexOrder do
	indexMutasyonu[mutasyon] = true
end

-- Brainrotu bu mutasyonla bulunmus olarak isaretler; yeni kesifse true
function PlayerData.discoverMutation(player: Player, name: string?, mutation: string?): boolean
	if type(name) ~= "string" or type(mutation) ~= "string" or not indexMutasyonu[mutation] then
		return false
	end

	local data = cache[player]
	if not data or not Brainrots.get(name) then
		return false
	end

	local kayit = data.discoveredMut[mutation]
	if not kayit then
		kayit = {}
		data.discoveredMut[mutation] = kayit
	end
	if kayit[name] then
		return false
	end

	kayit[name] = true
	return true
end

-- Mutasyonlu kesif tablosu; salt okunur kullanilmali
function PlayerData.discoveredMutations(player: Player): { [string]: { [string]: boolean } }
	local data = cache[player]
	return if data then data.discoveredMut else {}
end

function PlayerData.findItem(player: Player, uid: string): InventoryItem?
	local data = cache[player]
	if not data then
		return nil
	end
	for _, item in data.inventory do
		if item.uid == uid then
			return item
		end
	end
	return nil
end

function PlayerData.removeItem(player: Player, uid: string): InventoryItem?
	local data = cache[player]
	if not data then
		return nil
	end
	for index, item in data.inventory do
		if item.uid == uid then
			table.remove(data.inventory, index)
			return item
		end
	end
	return nil
end

-- Base'e yerlestirilmis brainrotlar (gelir hesabi bunlari kullanir)
function PlayerData.placedItems(player: Player): { InventoryItem }
	local data = cache[player]
	if not data then
		return {}
	end

	local out = {}
	for _, item in data.inventory do
		if item.slot then
			table.insert(out, item)
		end
	end
	return out
end

-- Rot Coin ekler (eksi deger duser, sifirin altina inmez)
function PlayerData.addRotCoins(player: Player, amount: number)
	local data = cache[player]
	if not data then
		return
	end
	data.rotCoins = math.max(0, data.rotCoins + amount)
end

function PlayerData.addRot(player: Player, amount: number)
	local data = cache[player]
	if not data then
		return
	end
	data.rot = math.max(0, data.rot + amount)
end

--[[
	Gecici sans carpani. Suresi dolduysa 1 doner ve kayit temizlenir,
	boylece eski bonus veride birikmez.
]]
function PlayerData.luckBonus(player: Player): number
	local data = cache[player]
	if not data then
		return 1
	end

	if data.luckUntil <= os.time() then
		data.luckBonus = 1
		data.luckUntil = 0
		return 1
	end

	return math.max(1, data.luckBonus)
end

function PlayerData.grantLuck(player: Player, multiplier: number, seconds: number)
	local data = cache[player]
	if not data then
		return
	end

	data.luckBonus = math.max(1, multiplier)
	data.luckUntil = os.time() + math.max(0, seconds)
end

function PlayerData.addLuckyBlocks(player: Player, tierId: string, amount: number)
	local data = cache[player]
	if not data then
		return
	end

	local next = math.max(0, (data.luckyBlocks[tierId] or 0) + amount)
	data.luckyBlocks[tierId] = if next > 0 then next else nil
end

--[[
	SCROLL SAYACI  --  bkz. Shared > Scrolls

	Eksi miktar da gecerli: kullanilinca -1 ile cagriliyor. Sayac sifirin
	altina dusmez ve sifirlanan tur tablodan silinir (kayit sismesin).
]]
function PlayerData.addScroll(player: Player, scrollId: string, amount: number): number
	local data = cache[player]
	if not data then
		return 0
	end

	local yeni = math.max(0, (data.scrolls[scrollId] or 0) + math.floor(amount))
	data.scrolls[scrollId] = if yeni > 0 then yeni else nil
	return yeni
end

function PlayerData.scrollCount(player: Player, scrollId: string): number
	local data = cache[player]
	return if data then (data.scrolls[scrollId] or 0) else 0
end

function PlayerData.luckyBlockCount(player: Player, tierId: string): number
	local data = cache[player]
	if not data then
		return 0
	end
	return data.luckyBlocks[tierId] or 0
end

------------------------------------------------------------------
-- OTURUM
------------------------------------------------------------------

-- Periyodik otomatik kayit
task.spawn(function()
	while true do
		task.wait(120)
		for player in cache do
			if player.Parent then
				PlayerData.save(player)
			end
		end
	end
end)

game:BindToClose(function()
	for player in cache do
		PlayerData.save(player)
	end
	if not RunService:IsStudio() then
		task.wait(2)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerData.release(player)
end)

return PlayerData
