--!strict
--[[
	5 kademeli kurek sistemi.

	Kurek iki seyi belirler:
	  1. digSpeed  -- kazi animasyonu / hazirlik suresi carpani (dusuk = hizli)
	  2. minigame parametreleri -- Stardew Valley balik minioyunundaki
	     yesil barin buyuklugu ve kontrol tepkiselligi

	Yeni kurek satin alinip envantere girdiginde eskisi silinir (tek slot).
]]

local Shovels = {}

export type ShovelId = "Wooden" | "Iron" | "Golden" | "Diamond" | "Celestial"

export type ShovelInfo = {
	id: ShovelId,
	displayName: string,
	level: number,
	rarity: string,
	price: number,
	-- Kazi hazirlik suresi carpani; 1.0 = taban, dusuk olan daha hizli kazar
	digSpeed: number,
	-- Minigame: oyuncunun kontrol ettigi yesil barin ekran yuksekligine orani
	barSize: number,
	-- Minigame: bar ivmesi; yuksek olan bari daha tepkisel/kolay kontrol edilir yapar
	barAcceleration: number,
	-- Minigame: hedef bar icindeyken ilerleme hizi (saniyede oran)
	progressRate: number,
	-- Minigame: hedef bar disindayken gerileme hizi (saniyede oran)
	drainRate: number,
	color: Color3,
}

Shovels.Order = { "Wooden", "Iron", "Golden", "Diamond", "Celestial" } :: { ShovelId }

Shovels.Info = {
	Wooden = {
		id = "Wooden",
		displayName = "Wooden Shovel",
		level = 1,
		rarity = "Common",
		price = 0,
		digSpeed = 1,
		barSize = 0.22,
		barAcceleration = 1.15,
		progressRate = 0.42,
		drainRate = 0.16,
		color = Color3.fromRGB(150, 111, 68),
	},

	Iron = {
		id = "Iron",
		displayName = "Iron Shovel",
		level = 2,
		rarity = "Rare",
		price = 500_000,
		digSpeed = 0.85,
		barSize = 0.26,
		barAcceleration = 1.25,
		progressRate = 0.48,
		drainRate = 0.14,
		color = Color3.fromRGB(176, 182, 192),
	},

	Golden = {
		id = "Golden",
		displayName = "Golden Shovel",
		level = 3,
		rarity = "Epic",
		price = 25_000_000,
		digSpeed = 0.7,
		barSize = 0.30,
		barAcceleration = 1.40,
		progressRate = 0.55,
		drainRate = 0.12,
		color = Color3.fromRGB(240, 190, 62),
	},

	Diamond = {
		id = "Diamond",
		displayName = "Diamond Shovel",
		level = 4,
		rarity = "Legendary",
		price = 600_000_000,
		digSpeed = 0.55,
		barSize = 0.34,
		barAcceleration = 1.55,
		progressRate = 0.62,
		drainRate = 0.10,
		color = Color3.fromRGB(120, 226, 240),
	},

	Celestial = {
		id = "Celestial",
		displayName = "Celestial Shovel",
		level = 5,
		rarity = "Mythic",
		price = 8_000_000_000,
		digSpeed = 0.4,
		barSize = 0.40,
		barAcceleration = 1.75,
		progressRate = 0.72,
		drainRate = 0.08,
		color = Color3.fromRGB(196, 150, 255),
	},
} :: { [ShovelId]: ShovelInfo }

Shovels.Default = "Wooden" :: ShovelId

function Shovels.get(id: ShovelId): ShovelInfo
	local info = Shovels.Info[id]
	assert(info, `bilinmeyen kurek: {tostring(id)}`)
	return info
end

function Shovels.next(id: ShovelId): ShovelInfo?
	local current = Shovels.get(id)
	for _, candidate in Shovels.Order do
		local info = Shovels.Info[candidate]
		if info.level == current.level + 1 then
			return info
		end
	end
	return nil
end

return Shovels
