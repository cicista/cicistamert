--!strict

local ExperienceNotificationService = game:GetService("ExperienceNotificationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("Hatirlatma"))
local Net = require(Shared:WaitForChild("Net"))

local soruldu = false

Net.event("OdulSonuc").OnClientEvent:Connect(function()
	if soruldu or Workspace:GetAttribute(Ayar.AktifNiteligi) ~= true then
		return
	end
	soruldu = true

	task.delay(Ayar.IzinGecikmesi, function()
		local ok, uygun = pcall(function()
			return ExperienceNotificationService:CanPromptOptInAsync()
		end)
		if ok and uygun then
			pcall(function()
				ExperienceNotificationService:PromptOptIn()
			end)
		end
	end)
end)
