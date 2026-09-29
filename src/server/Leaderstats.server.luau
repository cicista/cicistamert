local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Assets = require(Shared:WaitForChild("Assets"))
local Icons = require(Shared:WaitForChild("Icons"))

local Hiz = require(Shared:WaitForChild("Hiz"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local SureliGecis = require(Modules:WaitForChild("SureliGecis"))

Assets.ensureFolders()
Net.init()

Assets.listLuckyBlocks()

Icons.report()

require(Modules:WaitForChild("Odul"))
require(Modules:WaitForChild("Arkadaslar"))
require(Modules:WaitForChild("Seviye"))

local function saniyelikGelir(player: Player): number
	local toplam = 0
	for _, item in PlayerData.placedItems(player) do
		if item.revealed and item.name then
			toplam += Brainrots.income(item.name, item.condition :: any, item.mutation :: any)
		end
	end
	return math.round(toplam)
end

local function setupStats(player: Player)
	local data = PlayerData.load(player)
	if not data then
		return
	end

	SureliGecis.kur(player)

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	local rot = Instance.new("NumberValue")
	rot.Name = "Rot/s"
	rot.Value = saniyelikGelir(player)
	rot.Parent = stats

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = data.level
	level.Parent = stats

	local function toplamHiz(d: any): number
		return (d.speedRebirth or 0) * Hiz.Max + (d.speedLevel or 0) + 1
	end

	local speed = Instance.new("IntValue")
	speed.Name = "Speed"
	speed.Value = toplamHiz(data)
	speed.Parent = stats

	stats.Parent = player

	task.spawn(function()
		while player.Parent do
			local current = PlayerData.get(player)
			if current then
				rot.Value = saniyelikGelir(player)
				level.Value = current.level
				speed.Value = toplamHiz(current)
			end
			task.wait(0.5)
		end
	end)
end

Players.PlayerAdded:Connect(setupStats)

for _, player in Players:GetPlayers() do
	task.spawn(setupStats, player)
end
