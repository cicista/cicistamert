--!strict
--[[
	Sunucu girisi  (Script)
	Yeri: ServerScriptService > Main

	Rojo bagli mi diye bakmak icin: burayi degistirip kaydet, Studio'nun
	Output penceresinde yeni yazi cikmali.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local OyunConfig = require(Shared:WaitForChild("OyunConfig"))

print(`[{OyunConfig.oyunAdi}] sunucu hazir`)
