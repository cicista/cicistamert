--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("KacanYumurta"))
local Condition = require(Shared:WaitForChild("Condition"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local RobuxMagaza = require(Shared:WaitForChild("RobuxMagaza"))
local Canta = require(Shared:WaitForChild("Canta"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local PolitikaKontrol = require(script.Parent:WaitForChild("PolitikaKontrol"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))

local Bildirim = Net.event("Bildirim")
local Teklif = Net.event("KacanYumurtaTeklif")

local SARI = Color3.fromRGB(255, 200, 90)
local EK_PAY = 1

type Kayit = { rarity: string, island: string?, bitis: number, odemede: boolean }

local KacanYumurta = {}

local teklifler: { [Player]: Kayit } = {}
local rng = Random.new()

function KacanYumurta.teklifEt(player: Player, rarityId: string, island: string?)
	if not Ayar.uygun(rarityId) or PolitikaKontrol.rastgeleYasak(player) then
		return
	end

	local urun = RobuxMagaza.get(Ayar.UrunAnahtari)
	if not RunService:IsStudio() and not (urun and RobuxMagaza.satista(urun)) then
		return
	end

	teklifler[player] = { rarity = rarityId, island = island, bitis = os.clock() + Ayar.Sure, odemede = false }
	Teklif:FireClient(player, { rarity = rarityId, sure = Ayar.Sure, fiyat = Ayar.Fiyat })
end

function KacanYumurta.satinAlmaBasla(player: Player): boolean
	local kayit = teklifler[player]
	if not kayit or (not kayit.odemede and os.clock() > kayit.bitis + EK_PAY) then
		teklifler[player] = nil
		Bildirim:FireClient(player, "Too late, the egg is gone!", SARI)
		return false
	end

	local data = PlayerData.get(player)
	if not data then
		return false
	end

	if PlayerData.cantaSayisi(player) >= Canta.duzelt(data.inventoryMax) then
		Bildirim:FireClient(player, "Your backpack is full! Make room to catch the egg.", SARI)
		return false
	end

	kayit.odemede = true
	data.kacanYumurta = { rarity = kayit.rarity, island = kayit.island }
	return true
end

function KacanYumurta.ver(player: Player)
	local data = PlayerData.get(player)
	if not data then
		error("player data is not loaded")
	end

	local kayit = data.kacanYumurta or teklifler[player]
	local rarityId = if kayit then kayit.rarity else nil
	local island = if kayit then kayit.island else nil
	if not rarityId then
		warn(`[KacanYumurta] {player.Name} paid without a recorded egg, giving the lowest tier`)
		for _, id in Rarity.Order do
			if Ayar.uygun(id) then
				rarityId = id
				break
			end
		end
	end
	assert(rarityId, "no eligible rarity")

	local item = PlayerData.addBrainrot(player, rarityId, Condition.roll(rng), Mutations.roll(rng), island, true)
	if not item then
		error("brainrot could not be added")
	end

	data.kacanYumurta = nil
	teklifler[player] = nil

	Envanter.syncBrainrots(player)
	Envanter.push(player)
	Teklif:FireClient(player, { yakalandi = true, rarity = rarityId })
end

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId: number, productId: number, alindi: boolean)
	if alindi then
		return
	end

	local urun = RobuxMagaza.idIle(productId)
	if not urun or urun.anahtar ~= Ayar.UrunAnahtari then
		return
	end

	local player = Players:GetPlayerByUserId(userId)
	local data = player and PlayerData.get(player)
	if not player or not data then
		return
	end

	data.kacanYumurta = nil
	local kayit = teklifler[player]
	if kayit then
		kayit.odemede = false
	end
	if kayit and os.clock() > kayit.bitis then
		teklifler[player] = nil
		Teklif:FireClient(player, nil)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	teklifler[player] = nil
end)

return KacanYumurta
