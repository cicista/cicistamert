--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local ScrollSonuc = Net.event("ScrollSonuc")

local MutasyonGosterisi = (function()
	local modul = script.Parent:WaitForChild("MutasyonGosterisi", 5)
	if modul then
		local ok, sonuc = pcall(require, modul)
		if ok then
			return sonuc
		end
	end
	warn("[ScrollEfekti] MutasyonGosterisi yuklenemedi; gosteri oynatilmayacak")
	return nil
end)()

ScrollSonuc.OnClientEvent:Connect(function(veri)
	if type(veri) ~= "table" or veri.ok ~= true then
		return
	end
	if not MutasyonGosterisi then
		return
	end

	MutasyonGosterisi.goster(veri.mutation, veri.name)
end)
