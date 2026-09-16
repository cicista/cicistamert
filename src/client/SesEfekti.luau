--!strict
--[[
	SES EFEKTLERI AYARI  (ModuleScript, istemci)
	Yeri: StarterPlayer > StarterPlayerScripts > SesEfekti

	Settings panelindeki "SOUND EFFECTS" ayari. Muzik DISINDAKI butun
	sesler (kazi, tiklama, toplama, adim sesleri...) bu oyuncuda tek bir
	SoundGroup'a baglanir; grubun sesi ayarla kisilir ya da kapanir.

	NASIL
	  SoundService > "SesEfektleri" (SoundGroup) istemcide kurulur.
	  Workspace, SoundService, ReplicatedStorage ve PlayerGui'deki her
	  Sound -- sonradan eklenenler dahil -- bu gruba baglanir. Degisiklik
	  yalnizca bu oyuncuda olur; baskalarinin sesi etkilenmez.

	  Muzik (bkz. Muzik modulu) gruba KATILMAZ: kendi ayari var.
	  Haritada elle bir SoundGroup'a konmus sesler de oldugu gibi kalir.

	    SesEfekti.ayarla(yuzde, kapali)   -- yuzde 0..100
	    SesEfekti.yuzde()  /  SesEfekti.kapali()
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local SesEfekti = {}

-- Muzik sesleri: Studio'daki asil parca ve Muzik modulunun kopyasi
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
