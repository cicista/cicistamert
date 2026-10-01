--!strict

local KacanYumurta = {}

KacanYumurta.UrunAnahtari = "KacanYumurta"

KacanYumurta.Fiyat = 29

KacanYumurta.EskiFiyat = 59

KacanYumurta.Sure = 15

KacanYumurta.Kademeler = {
	Cosmic = true,
	Secret = true,
	Infernal = true,
	Abyssal = true,
} :: { [string]: boolean }

function KacanYumurta.uygun(rarityId: string?): boolean
	return type(rarityId) == "string" and KacanYumurta.Kademeler[rarityId] == true
end

return KacanYumurta
