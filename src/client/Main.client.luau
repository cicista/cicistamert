--!strict
--[[
	Istemci girisi  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Main
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local OyunConfig = require(Shared:WaitForChild("OyunConfig"))

print(`[{OyunConfig.oyunAdi}] istemci hazir`)
