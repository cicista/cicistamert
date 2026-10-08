--!strict

local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Politika = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Politika"))

local PolitikaKontrol = {}

type Durum = { rastgeleYasak: boolean, takasYasak: boolean }

local DENEME = 3

local durumlar: { [Player]: Durum } = {}

local function oku(player: Player): Durum
	for deneme = 1, DENEME do
		local ok, bilgi = pcall(function()
			return PolicyService:GetPolicyInfoForPlayerAsync(player)
		end)
		if ok and type(bilgi) == "table" then
			return {
				rastgeleYasak = bilgi.ArePaidRandomItemsRestricted == true,
				takasYasak = bilgi.IsPaidItemTradingAllowed ~= true,
			}
		end
		if not player.Parent then
			break
		end
		task.wait(deneme)
	end

	if RunService:IsStudio() then
		return { rastgeleYasak = false, takasYasak = false }
	end
	warn(`[PolitikaKontrol] policy info could not be read for {player.Name}; restricting paid random items and trading`)
	return { rastgeleYasak = true, takasYasak = true }
end

local function hazirla(player: Player): Durum
	local mevcut = durumlar[player]
	if mevcut then
		return mevcut
	end
	local durum = oku(player)
	if player.Parent then
		durumlar[player] = durum
		player:SetAttribute(Politika.RastgeleNiteligi, durum.rastgeleYasak)
		player:SetAttribute(Politika.TakasNiteligi, durum.takasYasak)
	end
	return durum
end

function PolitikaKontrol.rastgeleYasak(player: Player): boolean
	return hazirla(player).rastgeleYasak
end

function PolitikaKontrol.takasYasak(player: Player): boolean
	return hazirla(player).takasYasak
end

Players.PlayerAdded:Connect(function(player)
	hazirla(player)
end)
for _, player in Players:GetPlayers() do
	task.spawn(hazirla, player)
end
Players.PlayerRemoving:Connect(function(player)
	durumlar[player] = nil
end)

return PolitikaKontrol
