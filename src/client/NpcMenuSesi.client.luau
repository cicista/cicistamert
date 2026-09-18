--!strict
--[[
	NpcMenuSesi  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > NpcMenuSesi

	NPC'lerin actigi menulere de sol menu butonlarindaki TIKLAMA SESI
	(ArayuzSesi, "Cartoon Bubble"):

	  - menu ACILDIGINDA bir kez
	  - menunun icindeki her dugmeye tiklandiginda (satin al, sat, kapat...)

	Menuler adlariyla taniniyor (UI.panel'e verilen ad). Yeni bir NPC
	menusu eklenirse adini NPC_MENULERI'ne yazmak yeterli.
]]

local Players = game:GetService("Players")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local ArayuzSesi = require(script.Parent:WaitForChild("ArayuzSesi"))

local NPC_MENULERI: { [string]: boolean } = {
	Magaza = true, -- Shopkeeper
	AdaKurekSaticisi = true, -- ada kurek saticilari
	KazmaSaticisi = true, -- kazma saticilari
	AdaMenusu = true, -- Teleporter NPC (ada menusu)
	FlyboardSatici = true,
	OltaSatici = true,
	FuseMakinesi = true,
	Detective = true,
	SaticiPenceresi = true, -- brainrot saticisi
}

local ISARET = "NpcMenuSesi"

-- Nesnenin icinde bulundugu NPC menusu (yoksa nil)
local function menusu(node: Instance): Frame?
	local cursor = node.Parent
	while cursor and cursor ~= playerGui do
		if cursor:IsA("Frame") and NPC_MENULERI[cursor.Name] then
			return cursor
		end
		cursor = cursor.Parent
	end
	return nil
end

local function menuBagla(menu: Frame)
	if menu:GetAttribute(ISARET) then
		return
	end
	menu:SetAttribute(ISARET, true)

	menu:GetPropertyChangedSignal("Visible"):Connect(function()
		if menu.Visible then
			ArayuzSesi.tikla()
		end
	end)
end

local function bagla(node: Instance)
	if node:IsA("Frame") and NPC_MENULERI[node.Name] and node.Parent and node.Parent:IsA("ScreenGui") then
		menuBagla(node)
		return
	end

	if node:IsA("GuiButton") and not node:GetAttribute(ISARET) and menusu(node) then
		node:SetAttribute(ISARET, true)
		node.MouseButton1Click:Connect(function()
			ArayuzSesi.tikla()
		end)
	end
end

for _, node in playerGui:GetDescendants() do
	bagla(node)
end
playerGui.DescendantAdded:Connect(bagla)
