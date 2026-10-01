--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Passler = require(Shared:WaitForChild("Passler"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Gelir = {}

function Gelir.ham(player: Player): number
	local toplam = 0
	for _, item in PlayerData.placedItems(player) do
		if item.revealed and item.name then
			toplam += Brainrots.income(item.name, item.condition :: any, item.mutation :: any)
		end
	end
	return toplam
end

function Gelir.carpan(player: Player): number
	return Passler.rotCarpani(player)
end

function Gelir.saniyelik(player: Player): number
	return Gelir.ham(player) * Gelir.carpan(player)
end

return Gelir
