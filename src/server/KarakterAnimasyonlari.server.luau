local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))

local function idleUygula(character: Model)
	local id = Assets.id(Assets.Animations.idle)
	if not id then
		return
	end

	local animate = character:WaitForChild("Animate", 10)
	local idle = animate and animate:WaitForChild("idle", 10)
	if not idle then
		warn(`[KarakterAnimasyonlari] {character.Name}: Animate > idle bulunamadi, idle animasyonu takilamadi`)
		return
	end

	for _, child in idle:GetChildren() do
		if child:IsA("Animation") then
			child.AnimationId = id
		end
	end
end

local function oyuncuGeldi(player: Player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(idleUygula, character)
	end)

	if player.Character then
		task.spawn(idleUygula, player.Character)
	end
end

Players.PlayerAdded:Connect(oyuncuGeldi)

for _, player in Players:GetPlayers() do
	oyuncuGeldi(player)
end
