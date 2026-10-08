--!strict

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
local Rewards = require(Shared:WaitForChild("Rewards"))
local Ores = require(Shared:WaitForChild("Ores"))
local Canta = require(Shared:WaitForChild("Canta"))
local AfkSans = require(Shared:WaitForChild("AfkSans"))
local Gacha = require(Shared:WaitForChild("Gacha"))
local KacanYumurta = require(Shared:WaitForChild("KacanYumurta"))
local Net = require(Shared:WaitForChild("Net"))

export type InventoryItem = {
	uid: string,
	rarity: string,
	condition: string,
	mutation: string,
	name: string?,
	revealed: boolean,
	slot: number?,
	island: string?,
}

export type QuestState = {
	cycle: number,
	progress: { [string]: number },
	done: { [string]: boolean },
}

export type Data = {
	rot: number,
	rotCoins: number,
	luckyBlocks: { [string]: number },
	tempPasses: { [string]: number },
	giftedPasses: { [string]: boolean },
	scrolls: { [string]: number },
	shovel: string,
	shovelMax: string,
	detector: string,
	detectorMax: string,
	rod: string?,
	rodMax: string?,
	flyboard: string?,
	flyboardMax: string?,
	inventory: { InventoryItem },
	base: number?,
	baseFloors: number,
	baseSlots: number,
	inventoryMax: number,
	lastReward: number,
	rewardDay: number,
	luckUntil: number,
	luckBonus: number,
	level: number,
	xp: number,
	socialClaimed: { [string]: boolean },
	redeemedCodes: { [string]: boolean },
	playtimeGun: number,
	playtimeSure: number,
	playtimeAlinan: { [string]: boolean },
	detectiveJob: any?,
	islands: number,
	reachedIsland: string,
	ores: { [string]: number },
	pickaxes: { [string]: boolean },
	uiScale: number,
	uiScaleMobile: number,
	musicVolume: number,
	musicMuted: boolean,
	sfxVolume: number,
	sfxMuted: boolean,
	shakeOff: boolean,
	hintsOff: boolean,
	beamSoundOff: boolean,
	fuseAnimOff: boolean,
	hideTitle: boolean,
	hideName: boolean,
	hideLevel: boolean,
	hideSpeed: boolean,
	hideOthers: boolean,
	speedLevel: number,
	speedRebirth: number,
	hizTercihi: number,
	afkPuan: number,
	afkSeviye: number,
	afkOzel: { [string]: boolean },
	gachaIska: number,
	sonGorulme: number,
	baslangicAlindi: boolean,
	unvan: { sayac: { [string]: number }, kademe: number, kademeler: { [string]: boolean }, kazanilan: { [string]: boolean }, kusanilan: string? },
	kacanYumurta: { rarity: string, island: string? }?,
	quests: QuestState,
	discovered: { [string]: boolean },
	discoveredMut: { [string]: { [string]: boolean } },
	purchases: { [string]: number },
	tutorial: {
		adim: number,
		bitti: boolean,
		kazilan: { string }?,
		adaIpucu: boolean?,
		kurekIpucu: boolean?,
	},
}

local PlayerData = {}

PlayerData.VarsayilanMuzik = 10
PlayerData.VarsayilanSfx = 30

local STORE_NAME = "GercekSunucu"
local ProfileStore = require(script.Parent:WaitForChild("ProfileStore"))

ProfileStore.SetConstant("AUTO_SAVE_PERIOD", 120)

local store = ProfileStore.New(STORE_NAME, {})

local STUDIO_GERCEK_KAYIT = false
local kaynak = if RunService:IsStudio() and not STUDIO_GERCEK_KAYIT then store.Mock else store

local cache: { [Player]: Data } = {}
local profiller: { [Player]: any } = {}
local yukleniyor: { [Player]: boolean } = {}
local YUKLEME_SINIRI = 90
local ayriliyor: { [Player]: boolean } = {}
local uidCounter = 0

local function defaultData(): Data
	return {
		rot = 0,
		rotCoins = 0,
		luckyBlocks = {},
		scrolls = {},
		tempPasses = {},
		giftedPasses = {},
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
		baseFloors = 1,
		baseSlots = 10,
		inventoryMax = Canta.Baslangic,
		lastReward = 0,
		rewardDay = 1,
		luckUntil = 0,
		luckBonus = 1,
		level = 1,
		xp = 0,
		socialClaimed = {},
		redeemedCodes = {},
		playtimeGun = 0,
		playtimeSure = 0,
		playtimeAlinan = {},
		islands = 1,
		reachedIsland = Brainrots.IslandOrder[1],
		ores = {},
		pickaxes = {},
		uiScale = 100,
		uiScaleMobile = 50,
		musicVolume = PlayerData.VarsayilanMuzik,
		musicMuted = false,
		sfxVolume = PlayerData.VarsayilanSfx,
		sfxMuted = false,
		shakeOff = false,
		hintsOff = false,
		beamSoundOff = false,
		fuseAnimOff = false,
		hideTitle = false,
		hideName = false,
		hideLevel = false,
		hideSpeed = false,
		hideOthers = false,
		speedLevel = 0,
		speedRebirth = 0,
		hizTercihi = -1,
		afkPuan = 0,
		afkSeviye = 1,
		afkOzel = {},
		gachaIska = 0,
		sonGorulme = 0,
		baslangicAlindi = false,
		unvan = { sayac = {}, kademe = 0, kademeler = {}, kazanilan = {}, kusanilan = nil },
		quests ={ cycle = 0, progress = {}, done = {} },
		tutorial = { adim = 1, bitti = false },
		discovered = {},
		discoveredMut = {},
		purchases = {},
	}
end

local degistirmeRng = Random.new()

local SATIN_ALMA_OMRU = 30 * 24 * 3600

local function gecerliAd(name: any, rarity: any, island: any): string?
	if type(name) ~= "string" then
		return nil
	end

	local info = Brainrots.get(name)
	if info and info.rarity == rarity then
		return name
	end

	if #Brainrots.pool(rarity) == 0 then
		return nil
	end

	return Brainrots.rollIsland(rarity, if type(island) == "string" then island else nil, degistirmeRng).name
end

local function esyaOku(item: any): InventoryItem?
	if type(item) ~= "table" or type(item.uid) ~= "string" or type(item.rarity) ~= "string" then
		return nil
	end

	local ad = gecerliAd(item.name, item.rarity, item.island)
	local slot = tonumber(item.slot)
	if slot and (slot ~= slot or slot < 1 or slot % 1 ~= 0 or slot == math.huge) then
		slot = nil
	end

	return {
		uid = item.uid,
		rarity = item.rarity,
		condition = if type(item.condition) == "string" then item.condition else "Normal",
		mutation = if type(item.mutation) == "string" then item.mutation else "Normal",
		name = ad,
		revealed = item.revealed == true and ad ~= nil,
		slot = slot,
		island = if type(item.island) == "string" then item.island else nil,
	} :: any
end

local function sonluSayi(deger: any): number
	local sayi = tonumber(deger)
	if not sayi or sayi ~= sayi or math.abs(sayi) == math.huge then
		return 0
	end
	return math.max(0, sayi)
end

local function migrate(raw: any): Data
	local data = defaultData()
	if type(raw) ~= "table" then
		return data
	end

	data.rot = sonluSayi(raw.rot)
	data.rotCoins = sonluSayi(raw.rotCoins)

	local ogretici = if type(raw.tutorial) == "table" then raw.tutorial else nil
	if ogretici then
		data.tutorial = {
			adim = math.max(1, math.floor(tonumber(ogretici.adim) or 1)),
			bitti = ogretici.bitti == true,
			adaIpucu = ogretici.adaIpucu == true,
			kurekIpucu = ogretici.kurekIpucu == true,
		}
	else
		data.tutorial = { adim = 1, bitti = true }
	end

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

	data.giftedPasses = {}
	if type(raw.giftedPasses) == "table" then
		for ad, var in raw.giftedPasses do
			if type(ad) == "string" and var == true then
				data.giftedPasses[ad] = true
			end
		end
	end

	data.scrolls = {}
	if type(raw.scrolls) == "table" then
		for id, adet in raw.scrolls do
			local sayi = tonumber(adet)
			if type(id) == "string" and sayi and sayi > 0 then
				data.scrolls[id] = math.floor(sayi)
			end
		end
	end

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

	data.uiScale = math.clamp(tonumber(raw.uiScale) or 100, 50, 150)
	data.uiScaleMobile = math.clamp(tonumber(raw.uiScaleMobile) or 50, 50, 150)
	data.musicVolume = math.clamp(tonumber(raw.musicVolume) or PlayerData.VarsayilanMuzik, 0, 100)
	data.musicMuted = raw.musicMuted == true
	data.sfxVolume = math.clamp(tonumber(raw.sfxVolume) or PlayerData.VarsayilanSfx, 0, 100)
	data.sfxMuted = raw.sfxMuted == true
	data.shakeOff = raw.shakeOff == true
	data.hintsOff = raw.hintsOff == true
	data.beamSoundOff = raw.beamSoundOff == true
	data.fuseAnimOff = raw.fuseAnimOff == true
	data.hideTitle = raw.hideTitle == true
	data.hideName = raw.hideName == true
	data.hideLevel = raw.hideLevel == true
	data.hideSpeed = raw.hideSpeed == true
	data.hideOthers = raw.hideOthers == true
	data.speedLevel = math.clamp(math.floor(tonumber(raw.speedLevel) or 0), 0, 100)
	data.speedRebirth = math.clamp(math.floor(tonumber(raw.speedRebirth) or 0), 0, 6)
	data.hizTercihi = math.clamp(math.floor(tonumber(raw.hizTercihi) or -1), -1, 100)
	data.afkPuan = math.clamp(tonumber(raw.afkPuan) or 0, 0, AfkSans.MaxPuan)
	data.afkSeviye = math.clamp(math.floor(tonumber(raw.afkSeviye) or 1), 1, AfkSans.siraliSayi())
	data.afkOzel = {}
	if type(raw.afkOzel) == "table" then
		for id, var in raw.afkOzel do
			local alan = if type(id) == "string" then AfkSans.get(id) else nil
			if alan and alan.robux and var == true then
				data.afkOzel[id] = true
			end
		end
	end
	data.gachaIska = math.clamp(math.floor(tonumber(raw.gachaIska) or 0), 0, Gacha.maxIska())
	data.sonGorulme = math.max(0, math.floor(tonumber(raw.sonGorulme) or 0))
	data.baslangicAlindi = raw.baslangicAlindi == true
	data.unvan = { sayac = {}, kademe = 0, kademeler = {}, kazanilan = {}, kusanilan = nil }
	if type(raw.unvan) == "table" then
		if type(raw.unvan.sayac) == "table" then
			for tur, deger in raw.unvan.sayac do
				local sayi = tonumber(deger)
				if type(tur) == "string" and sayi then
					data.unvan.sayac[tur] = math.max(0, sayi)
				end
			end
		end
		data.unvan.kademe = math.max(0, math.floor(tonumber(raw.unvan.kademe) or 0))
		if type(raw.unvan.kademeler) == "table" then
			for id, var in raw.unvan.kademeler do
				if type(id) == "string" and var == true then
					data.unvan.kademeler[id] = true
				end
			end
		end
		if type(raw.unvan.kazanilan) == "table" then
			for id, var in raw.unvan.kazanilan do
				if type(id) == "string" and var == true then
					data.unvan.kazanilan[id] = true
				end
			end
		end
		if type(raw.unvan.kusanilan) == "string" then
			data.unvan.kusanilan = raw.unvan.kusanilan
		end
	end
	if type(raw.kacanYumurta) == "table" and KacanYumurta.uygun(raw.kacanYumurta.rarity) then
		data.kacanYumurta = {
			rarity = raw.kacanYumurta.rarity,
			island = if type(raw.kacanYumurta.island) == "string" then raw.kacanYumurta.island else nil,
		}
	end

	data.baseFloors = math.clamp(tonumber(raw.baseFloors) or 1, 1, 3)
	data.baseSlots = math.clamp(tonumber(raw.baseSlots) or 10, 10, 30)
	data.inventoryMax = Canta.duzelt(tonumber(raw.inventoryMax))

	data.lastReward = math.max(0, tonumber(raw.lastReward) or 0)
	data.rewardDay = math.clamp(math.floor(tonumber(raw.rewardDay) or 1), 1, #Rewards.Days)
	data.luckUntil = math.max(0, tonumber(raw.luckUntil) or 0)
	data.luckBonus = math.max(1, tonumber(raw.luckBonus) or 1)
	data.level = math.clamp(math.floor(tonumber(raw.level) or 1), 1, 100)
	data.xp = math.max(0, math.floor(tonumber(raw.xp) or 0))
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

	data.playtimeGun = tonumber(raw.playtimeGun) or 0
	data.playtimeSure = math.max(0, tonumber(raw.playtimeSure) or 0)
	data.playtimeAlinan = {}
	if type(raw.playtimeAlinan) == "table" then
		for anahtar, deger in raw.playtimeAlinan do
			local sira = tonumber(anahtar)
			if sira and deger == true then
				data.playtimeAlinan[tostring(sira)] = true
			end
		end
	end
	if data.playtimeGun ~= os.time() // 86400 then
		data.playtimeGun = os.time() // 86400
		data.playtimeSure = 0
		data.playtimeAlinan = {}
	end

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

	if type(raw.flyboard) == "string" and Flyboard.exists(raw.flyboard) then
		data.flyboard = raw.flyboard
	end

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

	if type(raw.rod) == "string" and Rods.exists(raw.rod) then
		data.rod = raw.rod
	end

	if type(raw.rodMax) == "string" and Rods.exists(raw.rodMax) then
		data.rodMax = raw.rodMax
	else
		data.rodMax = data.rod
	end

	if type(raw.inventory) == "table" then
		for _, item in raw.inventory do
			local kopya = esyaOku(item)
			if kopya then
				table.insert(data.inventory, kopya)
			end
		end
	end

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

	if type(raw.discovered) == "table" then
		for name, kesfedildi in raw.discovered do
			if kesfedildi == true and type(name) == "string" and Brainrots.get(name) then
				data.discovered[name] = true
			end
		end
	end

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

local beforeRelease: { (player: Player) -> () } = {}

function PlayerData.onBeforeRelease(callback: (player: Player) -> ())
	table.insert(beforeRelease, callback)
end

local function kancalariCalistir(player: Player)
	for _, callback in beforeRelease do
		local ok, err = pcall(callback, player)
		if not ok then
			warn(`[PlayerData] {player.Name}: leave hook failed -- {tostring(err)}`)
		end
	end
end

local function oyunda(player: Player): boolean
	return player.Parent == Players
end

function PlayerData.load(player: Player): Data?
	if cache[player] then
		return cache[player]
	end

	if yukleniyor[player] then
		while yukleniyor[player] do
			task.wait(0.1)
		end
		return cache[player]
	end

	yukleniyor[player] = true

	local function vazgec(sebep: string): nil
		yukleniyor[player] = nil
		if oyunda(player) and not ProfileStore.IsClosing then
			warn(`[PlayerData] {player.Name} data could not be opened ({sebep}), kicking the player`)
			player:Kick("Your data could not be loaded. Please rejoin in a moment.")
		end
		return nil
	end

	local baslangic = os.clock()
	local basladi, profile = pcall(function()
		return kaynak:StartSessionAsync(tostring(player.UserId), {
			Cancel = function()
				return not oyunda(player) or os.clock() - baslangic > YUKLEME_SINIRI
			end,
		})
	end)

	if not basladi then
		return vazgec(tostring(profile))
	end
	if profile == nil then
		return vazgec("session could not be started")
	end

	if not oyunda(player) then
		yukleniyor[player] = nil
		profile:EndSession()
		return nil
	end

	profile:AddUserId(player.UserId)

	local okundu, data = pcall(function(): Data
		return if next(profile.Data) == nil then defaultData() else migrate(profile.Data)
	end)
	if not okundu then
		profile:EndSession()
		return vazgec(`record could not be read: {tostring(data)}`)
	end
	profile.Data = data

	profile.OnLastSave:Connect(function()
		kancalariCalistir(player)
	end)

	profile.OnSessionEnd:Connect(function()
		profiller[player] = nil
		cache[player] = nil
		local cikiyor = ayriliyor[player]
		ayriliyor[player] = nil
		if oyunda(player) and not cikiyor and not ProfileStore.IsClosing then
			player:Kick("Your data was opened on another server. Please rejoin.")
		end
	end)

	profiller[player] = profile
	cache[player] = data
	yukleniyor[player] = nil
	return data
end

function PlayerData.get(player: Player): Data?
	return cache[player]
end

function PlayerData.bekle(player: Player): Data?
	while oyunda(player) and cache[player] == nil do
		task.wait(0.25)
	end
	return cache[player]
end

local FIS_KAYIT_SURESI = 30

function PlayerData.fisKaydedildi(player: Player, fisId: string): boolean
	local profile = profiller[player]
	if not profile then
		return false
	end

	local function kayitli(): boolean
		local son = profile.LastSavedData
		return type(son) == "table" and type(son.purchases) == "table" and son.purchases[fisId] ~= nil
	end

	if kayitli() then
		return true
	end

	profile:Save()

	local sinir = os.clock() + FIS_KAYIT_SURESI
	while not kayitli() and profile:IsActive() and os.clock() < sinir do
		task.wait(0.25)
	end
	return kayitli()
end

function PlayerData.hemenKaydet(player: Player)
	local profile = profiller[player]
	if profile and profile:IsActive() then
		profile:Save()
	end
end

function PlayerData.release(player: Player)
	local profile = profiller[player]
	if profile then
		ayriliyor[player] = true
		profile:EndSession()
	end
end

local UYARI_ARASI = 6
local sonDoluUyarisi: { [Player]: number } = {}

local function cantaDoluUyar(player: Player, data: Data)
	local simdi = os.clock()
	if simdi - (sonDoluUyarisi[player] or -math.huge) < UYARI_ARASI then
		return
	end
	sonDoluUyarisi[player] = simdi

	local kapasite = Canta.duzelt(data.inventoryMax)
	local mesaj = if Canta.dolu(kapasite)
		then `Backpack full ({kapasite})! Sell some pets or place them on your base.`
		else `Backpack full ({kapasite})! Sell some, place them on your base, or upgrade in your Inventory.`

	pcall(function()
		Net.event("Bildirim"):FireClient(player, mesaj, Color3.fromRGB(255, 160, 90))
	end)
end

function PlayerData.cantaSayisi(player: Player): number
	local data = cache[player]
	if not data then
		return 0
	end

	local n = 0
	for _, item in data.inventory do
		if not item.slot then
			n += 1
		end
	end
	return n
end

function PlayerData.cantaKapasitesi(player: Player): number
	local data = cache[player]
	return if data then Canta.duzelt(data.inventoryMax) else Canta.Baslangic
end

function PlayerData.cantayiYukselt(player: Player): boolean
	local data = cache[player]
	if not data then
		return false
	end

	local simdiki = Canta.duzelt(data.inventoryMax)
	if simdiki >= Canta.EnCok then
		return false
	end

	data.inventoryMax = math.min(Canta.EnCok, simdiki + Canta.Adim)
	return true
end

function PlayerData.addBrainrot(
	player: Player,
	rarity: string,
	condition: string,
	mutation: string?,
	island: string?,
	kapasiteyiGec: boolean?
): InventoryItem?
	local data = cache[player]
	if not data then
		return nil
	end

	if not kapasiteyiGec and PlayerData.cantaSayisi(player) >= Canta.duzelt(data.inventoryMax) then
		cantaDoluUyar(player, data)
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

function PlayerData.addOre(player: Player, oreId: string, amount: number): number
	local data = cache[player]
	if not data or not Ores.get(oreId) or amount ~= amount or math.abs(amount) == math.huge then
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

function PlayerData.discovered(player: Player): { [string]: boolean }
	local data = cache[player]
	return if data then data.discovered else {}
end

local function playtimeGunuTazele(data: Data)
	local bugun = os.time() // 86400
	if data.playtimeGun ~= bugun then
		data.playtimeGun = bugun
		data.playtimeSure = 0
		data.playtimeAlinan = {}
	end
end

function PlayerData.playtimeEkle(player: Player, saniye: number): number
	local data = cache[player]
	if not data then
		return 0
	end
	playtimeGunuTazele(data)
	if saniye > 0 then
		data.playtimeSure += saniye
	end
	return data.playtimeSure
end

function PlayerData.playtimeSuresi(player: Player): number
	local data = cache[player]
	if not data then
		return 0
	end
	playtimeGunuTazele(data)
	return data.playtimeSure
end

function PlayerData.playtimeAlindi(player: Player, sira: number): boolean
	local data = cache[player]
	if not data then
		return false
	end
	playtimeGunuTazele(data)
	return data.playtimeAlinan[tostring(sira)] == true
end

function PlayerData.playtimeAl(player: Player, sira: number): boolean
	local data = cache[player]
	if not data then
		return false
	end
	playtimeGunuTazele(data)
	local anahtar = tostring(sira)
	if data.playtimeAlinan[anahtar] then
		return false
	end
	data.playtimeAlinan[anahtar] = true
	return true
end

local indexMutasyonu: { [string]: boolean } = {}
for _, mutasyon in Mutations.IndexOrder do
	indexMutasyonu[mutasyon] = true
end

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

function PlayerData.addRotCoins(player: Player, amount: number)
	local data = cache[player]
	if not data or amount ~= amount or math.abs(amount) == math.huge then
		return
	end
	data.rotCoins = math.max(0, data.rotCoins + amount)
end

function PlayerData.addRot(player: Player, amount: number)
	local data = cache[player]
	if not data or amount ~= amount or math.abs(amount) == math.huge then
		return
	end
	data.rot = math.max(0, data.rot + amount)
end

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
	if not data or amount ~= amount or math.abs(amount) == math.huge then
		return
	end

	local next = math.max(0, (data.luckyBlocks[tierId] or 0) + amount)
	data.luckyBlocks[tierId] = if next > 0 then next else nil
end

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

Players.PlayerRemoving:Connect(function(player)
	PlayerData.release(player)
	sonDoluUyarisi[player] = nil
	ayriliyor[player] = nil
end)

return PlayerData
