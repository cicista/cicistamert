--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))

local IndexAc = Net.event("IndexAc")
local IndexDurum = Net.event("IndexDurum")

local BEKLEME = 0.25
local sonIstek: { [Player]: number } = {}

local function gonder(player: Player)
	IndexDurum:FireClient(player, PlayerData.discovered(player), PlayerData.discoveredMutations(player))
end

IndexAc.OnServerEvent:Connect(function(player)
	local simdi = os.clock()
	if (sonIstek[player] or 0) + BEKLEME > simdi then
		return
	end
	sonIstek[player] = simdi

	gonder(player)
end)

Players.PlayerRemoving:Connect(function(player)
	sonIstek[player] = nil
end)
