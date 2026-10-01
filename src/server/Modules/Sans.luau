--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Detectors = require(Shared:WaitForChild("Detectors"))
local Passler = require(Shared:WaitForChild("Passler"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Sand = require(script.Parent:WaitForChild("Sand"))
local Arkadaslar = require(script.Parent:WaitForChild("Arkadaslar"))
local Seviye = require(script.Parent:WaitForChild("Seviye"))
local AfkSans = require(script.Parent:WaitForChild("AfkSans"))
local HaftaSonu = require(script.Parent:WaitForChild("HaftaSonu"))

export type Parca = { ad: string, carpan: number }

local Sans = {}

Sans.Nitelik = "SansCarpani"
Sans.AyrintiNiteligi = "SansAyrinti"
Sans.GeciciNiteligi = "SansGeciciBitis"

local ARALIK = 0.5

local sonKum: { [Player]: number } = {}

local function kumSansi(player: Player): number
	local ground = Sand.underPlayer(player)
	if ground and ground.isSand then
		sonKum[player] = ground.luck
		return ground.luck
	end
	return sonKum[player] or 1
end

function Sans.parcalar(player: Player): { Parca }
	local data = PlayerData.get(player)
	local dedektor = Detectors.get((if data then data.detector else Detectors.Default) :: any)

	return {
		{ ad = "Island", carpan = kumSansi(player) },
		{ ad = "Detector", carpan = dedektor.luck },
		{ ad = "Clovers", carpan = AfkSans.carpan(player) },
		{ ad = "Level", carpan = Seviye.carpan(player) },
		{ ad = "Potion", carpan = PlayerData.luckBonus(player) },
		{ ad = "Friends", carpan = Arkadaslar.carpan(player) },
		{ ad = "Weekend", carpan = HaftaSonu.carpan() },
		{ ad = "2x Luck Pass", carpan = Passler.sansCarpani(player) },
	}
end

function Sans.kazi(player: Player): number
	local ground = Sand.luckUnder(player)
	local toplam = ground
	for _, parca in Sans.parcalar(player) do
		if parca.ad ~= "Island" then
			toplam *= parca.carpan
		end
	end
	return toplam
end

local function yuvarla(deger: number): number
	if deger >= 100 then
		return math.floor(deger + 0.5)
	end
	return math.floor(deger * 100 + 0.5) / 100
end

local function yayinla(player: Player)
	if not PlayerData.get(player) then
		return
	end

	local toplam = 1
	local satirlar: { string } = {}
	for _, parca in Sans.parcalar(player) do
		toplam *= parca.carpan
		if math.abs(parca.carpan - 1) > 1e-3 then
			table.insert(satirlar, `{parca.ad} x{yuvarla(parca.carpan)}`)
		end
	end

	local deger = yuvarla(toplam)
	if player:GetAttribute(Sans.Nitelik) ~= deger then
		player:SetAttribute(Sans.Nitelik, deger)
	end

	local ayrinti = table.concat(satirlar, "|")
	if player:GetAttribute(Sans.AyrintiNiteligi) ~= ayrinti then
		player:SetAttribute(Sans.AyrintiNiteligi, ayrinti)
	end

	local data = PlayerData.get(player)
	local bitis = if data and data.luckUntil > os.time() then data.luckUntil else 0
	if player:GetAttribute(Sans.GeciciNiteligi) ~= bitis then
		player:SetAttribute(Sans.GeciciNiteligi, bitis)
	end
end

local calisti = false

function Sans.calistir()
	if calisti then
		return
	end
	calisti = true

	Players.PlayerRemoving:Connect(function(player)
		sonKum[player] = nil
	end)

	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				local ok, hata = pcall(yayinla, player)
				if not ok then
					warn(`[Sans] {player.Name}: luck update failed -- {tostring(hata)}`)
				end
			end
			task.wait(ARALIK)
		end
	end)
end

return Sans
