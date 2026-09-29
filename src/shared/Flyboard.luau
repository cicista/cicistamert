--!strict

local Flyboard = {}

export type FlyboardId = "Basic" | "Wave" | "Storm" | "Nebula" | "Inferno"

export type FlyboardInfo = {
	id: FlyboardId,
	displayName: string,
	level: number,
	rarity: string,
	price: number,
	color: Color3,
	speedBonus: number,
	vfxScale: number,
	rampLight: Color3?,
	rampDark: Color3?,
}

Flyboard.Order = { "Basic", "Wave", "Storm", "Nebula", "Inferno" } :: { FlyboardId }

Flyboard.KurekSarti = 15

Flyboard.Info = {
	Basic = {
		id = "Basic",
		displayName = "Basic Flyboard",
		level = 1,
		rarity = "Common",
		price = 750_000_000_000,
		color = Color3.fromRGB(225, 240, 255),
		speedBonus = 0.1,
		vfxScale = 1,
		rampLight = Color3.fromRGB(255, 255, 255),
		rampDark = Color3.fromRGB(105, 140, 180),
	},

	Wave = {
		id = "Wave",
		displayName = "Wave Flyboard",
		level = 2,
		rarity = "Rare",
		price = 1_250_000_000_000,
		color = Color3.fromRGB(40, 230, 110),
		speedBonus = 0.15,
		vfxScale = 1.4,
		rampLight = Color3.fromRGB(185, 255, 130),
		rampDark = Color3.fromRGB(8, 105, 55),
	},

	Storm = {
		id = "Storm",
		displayName = "Storm Flyboard",
		level = 3,
		rarity = "Epic",
		price = 1_750_000_000_000,
		color = Color3.fromRGB(30, 140, 255),
		speedBonus = 0.2,
		vfxScale = 1.9,
		rampLight = Color3.fromRGB(150, 235, 255),
		rampDark = Color3.fromRGB(10, 45, 155),
	},

	Nebula = {
		id = "Nebula",
		displayName = "Nebula Flyboard",
		level = 4,
		rarity = "Legendary",
		price = 2_350_000_000_000,
		color = Color3.fromRGB(170, 60, 255),
		speedBonus = 0.25,
		vfxScale = 2.5,
		rampLight = Color3.fromRGB(255, 130, 245),
		rampDark = Color3.fromRGB(55, 8, 115),
	},

	Inferno = {
		id = "Inferno",
		displayName = "Inferno Flyboard",
		level = 5,
		rarity = "Mythic",
		price = 3_000_000_000_000,
		color = Color3.fromRGB(255, 40, 25),
		speedBonus = 0.3,
		vfxScale = 3.4,
		rampLight = Color3.fromRGB(255, 180, 40),
		rampDark = Color3.fromRGB(120, 12, 8),
	},
} :: { [FlyboardId]: FlyboardInfo }

Flyboard.ModelName = "Flyboard"

Flyboard.SeaNames = { "deniz", "sea", "ocean", "water", "su" }

Flyboard.VFX = {
	lightEmission = 0.15,
	extraTransparency = 0.08,
	lightBrightness = 1,
	lightMix = 0.45,
	darkMix = 0.35,
}

Flyboard.Physics = {
	boardScale = 0.75,
	hoverHeight = 1,
	riseLimit = 5,
	riseSpeed = 6,
	speedBonus = 0.2,
	tiltAngle = 25,
	tiltSmooth = 0.18,
	dismountDelay = 1,
	boardOffset = 3,
	noBoardDepth = 0.5,
	noBoardTick = 1,
	noBoardDamage = 0.1,
	damageTextTime = 0.5,
}

function Flyboard.colorRamp(info: FlyboardInfo): ColorSequence
	local V = Flyboard.VFX
	local color = info.color

	local acik = info.rampLight or color:Lerp(Color3.new(1, 1, 1), V.lightMix)
	local koyu = info.rampDark or color:Lerp(Color3.new(0, 0, 0), V.darkMix)

	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, acik),
		ColorSequenceKeypoint.new(0.5, color),
		ColorSequenceKeypoint.new(1, koyu),
	})
end

function Flyboard.get(id: string?): FlyboardInfo?
	if not id then
		return nil
	end
	return Flyboard.Info[id :: FlyboardId]
end

function Flyboard.exists(id: string?): boolean
	return Flyboard.get(id) ~= nil
end

function Flyboard.level(id: string?): number
	local info = Flyboard.get(id)
	return if info then info.level else 0
end

function Flyboard.next(id: string?): FlyboardInfo?
	local level = Flyboard.level(id)
	for _, boardId in Flyboard.Order do
		local info = Flyboard.Info[boardId]
		if info.level == level + 1 then
			return info
		end
	end
	return nil
end

function Flyboard.isSeaInstance(node: Instance?): boolean
	local cursor = node
	local derinlik = 0

	while cursor and derinlik < 6 do
		if cursor == workspace then
			return false
		end

		if Flyboard.isSeaName(cursor.Name) then
			return true
		end

		cursor = cursor.Parent
		derinlik += 1
	end

	return false
end

function Flyboard.isSeaName(name: string): boolean
	local lower = string.lower(name)
	for _, sea in Flyboard.SeaNames do
		if lower == sea or string.find(lower, sea, 1, true) then
			return true
		end
	end
	return false
end

return Flyboard
