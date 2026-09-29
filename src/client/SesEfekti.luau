--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local SesEfekti = {}

local MUZIK_ADLARI = {
	["Happy Shoppers"] = true,
	ArkaPlanMuzigi = true,
}

local yuzde = 100
local kapali = false

local grup = Instance.new("SoundGroup")
grup.Name = "SesEfektleri"
grup.Volume = 1
grup.Parent = SoundService

local function uygula()
	grup.Volume = if kapali then 0 else yuzde / 100
end

local function bagla(node: Instance)
	if not node:IsA("Sound") then
		return
	end
	if MUZIK_ADLARI[node.Name] or node.SoundGroup ~= nil then
		return
	end
	node.SoundGroup = grup
end

local function izle(kok: Instance)
	for _, d in kok:GetDescendants() do
		bagla(d)
	end
	kok.DescendantAdded:Connect(bagla)
end

function SesEfekti.ayarla(yeniYuzde: number?, yeniKapali: boolean?)
	if yeniYuzde then
		yuzde = math.clamp(math.round(yeniYuzde), 0, 100)
	end
	if yeniKapali ~= nil then
		kapali = yeniKapali
	end
	uygula()
end

function SesEfekti.yuzde(): number
	return yuzde
end

function SesEfekti.kapali(): boolean
	return kapali
end

task.spawn(function()
	izle(Workspace)
	izle(SoundService)
	izle(ReplicatedStorage)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	izle(playerGui)
end)

return SesEfekti
