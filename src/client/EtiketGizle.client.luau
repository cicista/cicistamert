--!strict

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local NITELIK = "HerkesEtiketGizli"
local ETIKET_ADI = "SeviyeEtiketi"

local function uygula(nesne: Instance)
	if nesne:IsA("BillboardGui") and nesne.Name == ETIKET_ADI then
		nesne.Enabled = player:GetAttribute(NITELIK) ~= true
	end
end

local function karakterIzle(karakter: Model)
	for _, nesne in karakter:GetDescendants() do
		uygula(nesne)
	end
	karakter.DescendantAdded:Connect(uygula)
end

local function oyuncuIzle(oyuncu: Player)
	if oyuncu.Character then
		karakterIzle(oyuncu.Character)
	end
	oyuncu.CharacterAdded:Connect(karakterIzle)
end

for _, oyuncu in Players:GetPlayers() do
	oyuncuIzle(oyuncu)
end
Players.PlayerAdded:Connect(oyuncuIzle)

player:GetAttributeChangedSignal(NITELIK):Connect(function()
	for _, oyuncu in Players:GetPlayers() do
		local karakter = oyuncu.Character
		if karakter then
			for _, nesne in karakter:GetDescendants() do
				uygula(nesne)
			end
		end
	end
end)
