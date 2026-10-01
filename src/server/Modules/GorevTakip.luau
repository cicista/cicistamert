--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Gorevler = require(Shared:WaitForChild("Gorevler"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Condition = require(Shared:WaitForChild("Condition"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Net = require(Shared:WaitForChild("Net"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))
local Unvan = require(script.Parent:WaitForChild("Unvan"))

local Bildirim = Net.event("Bildirim")
local GorevDurum = Net.event("GorevDurum")

local GorevTakip = {}

local ILERLEME_RENGI = Color3.fromRGB(190, 205, 225)
local BITTI_RENGI = Color3.fromRGB(140, 230, 160)

local function tazele(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return nil
	end

	local durum = data.quests
	local cycle = Gorevler.cycle()

	if durum.cycle ~= cycle then
		durum.cycle = cycle
		durum.progress = {}
		durum.done = {}
	end

	return durum
end

local function paket(player: Player)
	local durum = tazele(player)
	if not durum then
		return nil
	end

	local liste = {}
	for _, def in Gorevler.forCycle(durum.cycle) do
		local reward = Gorevler.reward(def)
		local ilerleme = math.min(durum.progress[def.id] or 0, def.target)
		local alindi = durum.done[def.id] == true

		table.insert(liste, {
			id = def.id,
			text = def.text,
			target = def.target,
			progress = ilerleme,
			done = alindi,
			ready = not alindi and ilerleme >= def.target,
			reward = Gorevler.rewardText(def),
			xp = Gorevler.xp(def),
			color = Rarity.color(reward.rarity),
		})
	end

	return {
		remaining = Gorevler.remaining(),
		quests = liste,
	}
end

function GorevTakip.gonder(player: Player): boolean
	local veri = paket(player)
	if not veri then
		return false
	end

	GorevDurum:FireClient(player, veri)
	return true
end

local odulRng = Random.new()

function GorevTakip.odulVer(player: Player, def: Gorevler.QuestDef): { string }
	local reward = Gorevler.reward(def)
	local ada = PlayerData.reachedIsland(player)
	local kademe = Brainrots.clampRarity(reward.rarity, ada)
	local adlar: { string } = {}

	for _ = 1, reward.count do
		local item = PlayerData.addBrainrot(player, kademe, Condition.Default, "Normal", ada)
		if item then
			local info = Brainrots.rollIsland(kademe :: any, ada, odulRng)
			item.name = info.name
			item.revealed = true
			table.insert(adlar, info.name)
		end
	end

	Envanter.syncBrainrots(player)
	Envanter.push(player)
	return adlar
end

function GorevTakip.ilerlet(player: Player, kind: string, amount: number?, rarity: string?)
	Unvan.ilerlet(player, kind, amount, rarity)

	local durum = tazele(player)
	if not durum then
		return
	end

	local adet = math.max(1, math.floor(amount or 1))
	local degisti = false

	for _, def in Gorevler.forCycle(durum.cycle) do
		if def.kind ~= kind or durum.done[def.id] then
			continue
		end
		if def.rarity and def.rarity ~= rarity then
			continue
		end

		local yeni = math.min((durum.progress[def.id] or 0) + adet, def.target)
		if yeni == durum.progress[def.id] then
			continue
		end

		durum.progress[def.id] = yeni
		degisti = true

		if yeni >= def.target then
			Bildirim:FireClient(
				player,
				`Quest Ready: {def.text}`,
				BITTI_RENGI
			)
		else
			Bildirim:FireClient(player, `{def.short}  {yeni} / {def.target}`, ILERLEME_RENGI)
		end
	end

	if degisti then
		GorevTakip.gonder(player)
	end
end

return GorevTakip
