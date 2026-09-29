--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Gorevler = require(Shared:WaitForChild("Gorevler"))
local Condition = require(Shared:WaitForChild("Condition"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Net = require(Shared:WaitForChild("Net"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))
local GorevTakip = require(script.Parent:WaitForChild("GorevTakip"))
local Seviye = require(script.Parent:WaitForChild("Seviye"))
local Patlama = require(script.Parent:WaitForChild("Patlama"))

local Bildirim = Net.event("Bildirim")

local GorevOdul = {}

function GorevOdul.topla(player: Player, id: string): boolean
	local data = PlayerData.get(player)
	if not data then
		return false
	end

	local durum = data.quests

	if durum.cycle ~= Gorevler.cycle() then
		GorevTakip.gonder(player)
		return false
	end

	local gorev: Gorevler.QuestDef? = nil
	for _, aday in Gorevler.forCycle(durum.cycle) do
		if aday.id == id then
			gorev = aday
			break
		end
	end

	if not gorev then
		return false
	end

	local def = gorev :: Gorevler.QuestDef

	if durum.done[def.id] or (durum.progress[def.id] or 0) < def.target then
		return false
	end

	durum.done[def.id] = true

	local reward = Gorevler.reward(def)
	local adlar = GorevTakip.odulVer(player, def)
	Seviye.xpVer(player, Gorevler.xp(def))

	Patlama.oynat(player, reward.rarity)

	Bildirim:FireClient(
		player,
		`Quest Reward: {if #adlar > 0 then table.concat(adlar, ", ") else Gorevler.rewardText(def)}`,
		Rarity.color(reward.rarity)
	)

	GorevTakip.gonder(player)
	return true
end

return GorevOdul
