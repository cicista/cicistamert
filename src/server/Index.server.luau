--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local IndexOdul = require(Shared:WaitForChild("IndexOdul"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))

local IndexAc = Net.event("IndexAc")
local IndexDurum = Net.event("IndexDurum")
local IndexOdulAl = Net.event("IndexOdulAl")
local Bildirim = Net.event("Bildirim")

local BEKLEME = 0.25
local sonIstek: { [Player]: number } = {}

local function gonder(player: Player)
	IndexDurum:FireClient(
		player,
		PlayerData.discovered(player),
		PlayerData.discoveredMutations(player),
		PlayerData.indexOdulleri(player)
	)
end

local function erken(player: Player): boolean
	local simdi = os.clock()
	if (sonIstek[player] or 0) + BEKLEME > simdi then
		return true
	end
	sonIstek[player] = simdi
	return false
end

IndexAc.OnServerEvent:Connect(function(player)
	if erken(player) then
		return
	end
	gonder(player)
end)

IndexOdulAl.OnServerEvent:Connect(function(player, mutasyon, ada, rarity)
	if type(mutasyon) ~= "string" or type(ada) ~= "string" or type(rarity) ~= "string" then
		return
	end
	if not table.find(IndexOdul.Mutasyonlar, mutasyon) or IndexOdul.miktar(ada) <= 0 then
		return
	end
	if erken(player) then
		return
	end

	local odulleri = PlayerData.indexOdulleri(player)
	local anahtar = IndexOdul.anahtar(mutasyon, ada, rarity)
	if odulleri[anahtar] then
		return
	end

	local kesif = if mutasyon == "Normal"
		then PlayerData.discovered(player)
		else PlayerData.discoveredMutations(player)[mutasyon]
	if not IndexOdul.tamam(kesif, ada, rarity) then
		return
	end

	local miktar = IndexOdul.miktar(ada)
	odulleri[anahtar] = true
	PlayerData.addRotCoins(player, miktar)
	Envanter.push(player)

	local mutasyonAdi = if mutasyon == "Normal" then "" else `{mutasyon} `
	Bildirim:FireClient(
		player,
		`+{miktar} Rot Coin for completing {mutasyonAdi}{Rarity.displayName(rarity)}!`,
		Color3.fromRGB(255, 215, 40)
	)
	gonder(player)
end)

Players.PlayerRemoving:Connect(function(player)
	sonIstek[player] = nil
end)
