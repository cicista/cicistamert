--!strict

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Unvanlar = require(Shared:WaitForChild("Unvanlar"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Seviye = require(script.Parent:WaitForChild("Seviye"))

local Bildirim = Net.event("Bildirim")
local Duyuru = Net.event("Duyuru")
local UnvanDurum = Net.event("UnvanDurum")
local UnvanAc = Net.event("UnvanAc")
local UnvanKusan = Net.event("UnvanKusan")

local KONTROL_ARALIGI = 10
local KUSANMA_ARALIGI = 0.5

local Unvan = {}

local hazir: { [Player]: boolean } = {}
local sonKusanma: { [Player]: number } = {}

local function indexSayisi(player: Player): number
	local sayi = 0
	for _ in PlayerData.discovered(player) do
		sayi += 1
	end
	return sayi
end

local siradanKademe: { [number]: string } = {}
for _, id in Rarity.Order do
	local info = Rarity.Info[id]
	if info then
		siradanKademe[info.order] = id
	end
end

local function kademeBulundu(player: Player, data: any, sira: number): boolean
	local id = siradanKademe[sira]
	if not id then
		return false
	end
	if data.unvan.kademeler[id] then
		return true
	end
	for _, item in data.inventory or {} do
		if type(item) == "table" and item.rarity == id then
			data.unvan.kademeler[id] = true
			return true
		end
	end
	for ad in PlayerData.discovered(player) do
		local info = Brainrots.get(ad)
		if info and info.rarity == id then
			data.unvan.kademeler[id] = true
			return true
		end
	end
	return false
end

local function deger(player: Player, data: any, tur: string, hedef: number): number
	if tur == "level" then
		return data.level or 0
	elseif tur == "index" then
		return indexSayisi(player)
	elseif tur == "kademe" then
		return if kademeBulundu(player, data, hedef) then hedef else 0
	elseif tur == "rebirth" then
		return data.speedRebirth or 0
	end
	return data.unvan.sayac[tur] or 0
end

local function robloxRozeti(player: Player, rozet: Unvanlar.Rozet)
	if rozet.robloxId <= 0 then
		return
	end
	task.spawn(function()
		local ok, hata = pcall(function()
			if not BadgeService:UserHasBadgeAsync(player.UserId, rozet.robloxId) then
				BadgeService:AwardBadge(player.UserId, rozet.robloxId)
			end
		end)
		if not ok then
			warn(`[Unvan] Roblox badge {rozet.id} could not be awarded to {player.Name}: {hata}`)
		end
	end)
end

function Unvan.gonder(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	local liste = {}
	for _, rozet in Unvanlar.Liste do
		table.insert(liste, {
			id = rozet.id,
			ilerleme = math.min(deger(player, data, rozet.tur, rozet.hedef), rozet.hedef),
			kazanildi = data.unvan.kazanilan[rozet.id] == true,
		})
	end

	UnvanDurum:FireClient(player, {
		rozetler = liste,
		kusanilan = data.unvan.kusanilan,
	})
end

function Unvan.kontrol(player: Player, sessiz: boolean?)
	local data = PlayerData.get(player)
	if not data or not hazir[player] then
		return
	end

	local yeniler: { Unvanlar.Rozet } = {}
	for _, rozet in Unvanlar.Liste do
		if not data.unvan.kazanilan[rozet.id] and deger(player, data, rozet.tur, rozet.hedef) >= rozet.hedef then
			data.unvan.kazanilan[rozet.id] = true
			table.insert(yeniler, rozet)
			robloxRozeti(player, rozet)
		end
	end

	if #yeniler == 0 then
		return
	end

	if not data.unvan.kusanilan then
		local enIyi = yeniler[1]
		for _, rozet in yeniler do
			if rozet.seviye > enIyi.seviye then
				enIyi = rozet
			end
		end
		data.unvan.kusanilan = enIyi.id
		Seviye.etiketGuncelle(player)
	end

	if sessiz then
		Bildirim:FireClient(
			player,
			`You have {#yeniler} new badge{if #yeniler > 1 then "s" else ""}! Open the Badges menu to equip a title.`,
			Color3.fromRGB(255, 215, 60)
		)
	else
		for _, rozet in yeniler do
			Duyuru:FireClient(player, {
				tur = "rozet",
				rozet = rozet.id,
			})
		end
	end

	Unvan.gonder(player)
end

function Unvan.ilerlet(player: Player, tur: string, miktar: number?, kademe: string?)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	local artis = miktar or 1
	if artis > 0 and tur ~= "collect" then
		data.unvan.sayac[tur] = (data.unvan.sayac[tur] or 0) + artis
	end

	if kademe then
		local info = Rarity.Info[kademe :: Rarity.RarityId]
		if info then
			data.unvan.kademeler[info.id] = true
			if info.order > (data.unvan.kademe or 0) then
				data.unvan.kademe = info.order
			end
		end
	end

	Unvan.kontrol(player)
end

function Unvan.hepsiniVer(player: Player): number
	local data = PlayerData.get(player)
	if not data then
		return 0
	end
	local sayi = 0
	for _, rozet in Unvanlar.Liste do
		if not data.unvan.kazanilan[rozet.id] then
			data.unvan.kazanilan[rozet.id] = true
			sayi += 1
		end
	end
	Unvan.gonder(player)
	return sayi
end

function Unvan.sifirla(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	data.unvan = { sayac = {}, kademe = 0, kazanilan = {}, kusanilan = nil }
	Seviye.etiketGuncelle(player)
	Unvan.gonder(player)
end

UnvanAc.OnServerEvent:Connect(function(player)
	Unvan.gonder(player)
end)

UnvanKusan.OnServerEvent:Connect(function(player, id)
	local simdi = os.clock()
	if simdi - (sonKusanma[player] or 0) < KUSANMA_ARALIGI then
		return
	end
	sonKusanma[player] = simdi

	local data = PlayerData.get(player)
	if not data then
		return
	end

	if id == nil or id == "" then
		data.unvan.kusanilan = nil
	elseif type(id) == "string" and Unvanlar.get(id) and data.unvan.kazanilan[id] then
		data.unvan.kusanilan = id
	else
		return
	end

	Seviye.etiketGuncelle(player)
	Unvan.gonder(player)
end)

local function oyuncuGeldi(player: Player)
	local data = PlayerData.bekle(player)
	if not data or not player.Parent then
		return
	end

	for _, rozet in Unvanlar.Liste do
		if
			rozet.tur == "kademe"
			and data.unvan.kazanilan[rozet.id]
			and not kademeBulundu(player, data, rozet.hedef)
		then
			data.unvan.kazanilan[rozet.id] = nil
		end
	end

	if data.unvan.kusanilan and not data.unvan.kazanilan[data.unvan.kusanilan] then
		data.unvan.kusanilan = nil
	end

	for id in data.unvan.kazanilan do
		local rozet = Unvanlar.get(id)
		if rozet then
			robloxRozeti(player, rozet)
		end
	end

	hazir[player] = true
	Unvan.kontrol(player, true)
	Seviye.etiketGuncelle(player)
end

Players.PlayerAdded:Connect(oyuncuGeldi)
for _, player in Players:GetPlayers() do
	task.spawn(oyuncuGeldi, player)
end

Players.PlayerRemoving:Connect(function(player)
	hazir[player] = nil
	sonKusanma[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(KONTROL_ARALIGI)
		for _, player in Players:GetPlayers() do
			Unvan.kontrol(player)
		end
	end
end)

return Unvan
