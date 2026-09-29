--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Scrolls = require(Shared:WaitForChild("Scrolls"))

local PROMPT_ADI = "SlotPrompt"

local function elindeki(): string
	local karakter = player.Character
	if not karakter then
		return "Slot"
	end

	for _, node in karakter:GetChildren() do
		if node:IsA("Tool") then
			if type(node:GetAttribute(Scrolls.Nitelik)) == "string" then
				return "Mutate"
			end
			if node:GetAttribute("BrainrotUid") then
				return "Place"
			end
		end
	end

	return "Slot"
end

local baglandi: { [Instance]: boolean } = {}

local function bagla(node: Instance)
	if not node:IsA("ProximityPrompt") or node.Name ~= PROMPT_ADI or baglandi[node] then
		return
	end
	baglandi[node] = true

	node.PromptShown:Connect(function()
		node.ActionText = elindeki()
	end)
end

for _, node in Workspace:GetDescendants() do
	bagla(node)
end
Workspace.DescendantAdded:Connect(bagla)
