--!strict

local Rarity = require(script.Parent.Rarity)

local Kapisma = {}

Kapisma.MinKademe = "Legendary"
Kapisma.MinSeviye = 5
Kapisma.SeviyeFarki = 10
Kapisma.Mesafe = 14

Kapisma.GeriSayim = 3
Kapisma.Sure = 15
Kapisma.Adim = 0.022
Kapisma.MaxCps = 12
Kapisma.Patlama = 4
Kapisma.GuncellemeAraligi = 0.1
Kapisma.SonucSuresi = 2.5

Kapisma.Renk = Color3.fromRGB(255, 90, 70)

function Kapisma.kademeUygun(kind: string): boolean
	if kind == Rarity.Mystery.id then
		return true
	end
	local info = Rarity.Info[kind :: Rarity.RarityId]
	local esik = Rarity.Info[Kapisma.MinKademe :: Rarity.RarityId]
	return info ~= nil and esik ~= nil and info.order >= esik.order
end

return Kapisma
