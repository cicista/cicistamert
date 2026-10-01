--!strict

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MINIGAME_EKRANLARI = { "KaziBar", "KaziMinigame" }
local GIZLENECEKLER = { "OyunMenuleri", "Hotbar", "RobuxMagazasi" }

local gizlenenler: { ScreenGui } = {}
local gizli = false

local function minigameAcik(): boolean
	for _, ad in MINIGAME_EKRANLARI do
		local ekran = playerGui:FindFirstChild(ad)
		if ekran and ekran:IsA("ScreenGui") and ekran.Enabled then
			return true
		end
	end
	return false
end

local function tazele()
	local acik = minigameAcik()
	if acik == gizli then
		return
	end
	gizli = acik

	if acik then
		for _, ad in GIZLENECEKLER do
			local ekran = playerGui:FindFirstChild(ad)
			if ekran and ekran:IsA("ScreenGui") and ekran.Enabled then
				ekran.Enabled = false
				table.insert(gizlenenler, ekran)
			end
		end
		return
	end

	for _, ekran in gizlenenler do
		if ekran.Parent then
			ekran.Enabled = true
		end
	end
	table.clear(gizlenenler)
end

for _, ad in MINIGAME_EKRANLARI do
	task.spawn(function()
		local ekran = playerGui:WaitForChild(ad)
		if ekran:IsA("ScreenGui") then
			ekran:GetPropertyChangedSignal("Enabled"):Connect(tazele)
			tazele()
		end
	end)
end
