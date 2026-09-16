--[[
	SuzmeEtiketleri  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > SuzmeEtiketleri

	Suzme / girdap / maden etiketlerine KIME AIT OLDUGUNA gore sus verir.

	Etiketin kendisi sunucuda kuruluyor ve herkese gidiyor (bkz.
	ServerScriptService > Modules > Beams): kademe + "Ahmet's". Burasi yalnizca
	bu oyuncunun ekraninda gorunusu ayarlar:

	    KENDI SUZMEN    buyuk, "YOURS" yesil, kalin cerceve, kademe parlamasi
	    BASKASININKI    kucuk, soluk, sahibinin adi, yakina gelmeden gorunmez
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))

local ETIKET_ADI = "SuzmeEtiketi"
local KLASOR_ADI = "IsikSuzmeleri"

local BENIM_RENK = Color3.fromRGB(120, 255, 150)
-- Baskasinin suzmesinin etiketi bu mesafeden uzakta gorunmez
local BASKASI_MESAFE = 70

local function sus(gui: BillboardGui)
	if gui:GetAttribute("Suslendi") then
		return
	end
	gui:SetAttribute("Suslendi", true)

	local kart = gui:FindFirstChild("Kart")
	local ad = kart and kart:FindFirstChild("Kind")
	local sahip = kart and kart:FindFirstChild("Sahip")
	local cerceve = kart and kart:FindFirstChild("Cerceve")
	if not kart or not kart:IsA("Frame") or not ad or not ad:IsA("TextLabel") or not sahip or not sahip:IsA("TextLabel") then
		return
	end

	local kind = gui:GetAttribute("Kind")
	local benim = gui:GetAttribute("Owner") == localPlayer.UserId

	if benim then
		gui.Size = UDim2.fromOffset(170, 58)
		sahip.Text = "YOURS"
		sahip.TextColor3 = BENIM_RENK
		sahip.TextSize = 16
		if cerceve and cerceve:IsA("UIStroke") then
			cerceve.Thickness = 3
		end
		-- Epic ve ustu parlar, Divine parildar
		if type(kind) == "string" and Rarity.Info[kind] then
			UI.rarityStyle(ad, kind)
		end
	else
		gui.Size = UDim2.fromOffset(120, 42)
		gui.MaxDistance = BASKASI_MESAFE
		kart.BackgroundTransparency = 0.55
		ad.TextSize = 15
		ad.TextTransparency = 0.25
		sahip.TextSize = 12
		sahip.TextTransparency = 0.2
		if cerceve and cerceve:IsA("UIStroke") then
			cerceve.Transparency = 0.5
		end
	end
end

local function incele(nesne: Instance)
	if nesne:IsA("BillboardGui") and nesne.Name == ETIKET_ADI then
		-- Cocuklar etiketten hemen sonra gelebilir: bir kare bekle
		task.defer(sus, nesne)
	end
end

local klasor = Workspace:WaitForChild(KLASOR_ADI)
for _, d in klasor:GetDescendants() do
	incele(d)
end
klasor.DescendantAdded:Connect(incele)
