--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Gorevler = require(Shared:WaitForChild("Gorevler"))
local Net = require(Shared:WaitForChild("Net"))

local Modules = script.Parent:WaitForChild("Modules")
local GorevTakip = require(Modules:WaitForChild("GorevTakip"))
local GorevOdul = require(Modules:WaitForChild("GorevOdul"))
local PlayerData = require(Modules:WaitForChild("PlayerData"))

local Bildirim = Net.event("Bildirim")
local GorevAc = Net.event("GorevAc")
local GorevAl = Net.event("GorevAl")

GorevAc.OnServerEvent:Connect(function(player)
	GorevTakip.gonder(player)
end)

GorevAl.OnServerEvent:Connect(function(player, id)
	if type(id) ~= "string" then
		return
	end
	GorevOdul.topla(player, id)
end)

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		if not PlayerData.bekle(player) then
			return
		end
		for _ = 1, 20 do
			task.wait(1)
			if not player.Parent then
				return
			end
			if GorevTakip.gonder(player) then
				return
			end
		end
	end)
end)

task.spawn(function()
	local sonCycle = Gorevler.cycle()

	while true do
		task.wait(5)

		local cycle = Gorevler.cycle()
		if cycle == sonCycle then
			continue
		end
		sonCycle = cycle

		for _, player in Players:GetPlayers() do
			GorevTakip.gonder(player)
			Bildirim:FireClient(player, "New quests available!", Color3.fromRGB(255, 214, 41))
		end
	end
end)
