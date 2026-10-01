--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig")) :: any

local A = Config.Admin

local Yetki = {}

local rutbeler: { [Player]: number } = {}
local hazir: { [Player]: boolean } = {}

local function rutbeOku(player: Player): number
	local grupId = tonumber(A.grupId) or 0
	if grupId <= 0 then
		return 0
	end
	for _ = 1, 3 do
		local ok, rutbe = pcall(function()
			return player:GetRankInGroup(grupId)
		end)
		if ok and type(rutbe) == "number" then
			return rutbe
		end
		if not player.Parent then
			return 0
		end
		task.wait(2)
	end
	return 0
end

function Yetki.admin(player: Player): boolean
	if A.allowInStudio and RunService:IsStudio() then
		return true
	end
	if table.find(A.userIds, player.UserId) then
		return true
	end
	local gereken = tonumber(A.grupRutbesi) or 255
	return (rutbeler[player] or 0) >= gereken
end

function Yetki.bekle(player: Player): boolean
	local basla = os.clock()
	while not hazir[player] and player.Parent and os.clock() - basla < 15 do
		task.wait(0.2)
	end
	return Yetki.admin(player)
end

local function geldi(player: Player)
	rutbeler[player] = rutbeOku(player)
	hazir[player] = true
end

Players.PlayerAdded:Connect(geldi)
for _, player in Players:GetPlayers() do
	task.spawn(geldi, player)
end

Players.PlayerRemoving:Connect(function(player)
	rutbeler[player] = nil
	hazir[player] = nil
end)

return Yetki
