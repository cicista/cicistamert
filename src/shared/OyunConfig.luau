local Config = {}

Config.NPC = {
	name = "Teleporter",
	altName = "Captain",
	altNames = { "Captain", "Kaptan" },
	promptText = "Travel",
	promptSubText = "Teleporter",
	promptDistance = 12,
}

Config.Detective = {
	name = "BrainrotDetective",
	promptText = "Inspect",
	promptSubText = "Pet Detective",
	promptDistance = 12,
	spawnPosition = Vector3.new(24, 5, -40),
}

Config.Seller = {
	name = "BrainrotSaticisi",
	altName = "RotBuyer",
	promptSubText = "Rot Buyer",
	range = 14,
	spawnPosition = Vector3.new(0, 5, -64),
	valueMultiplier = 300,
	unknownMultiplier = 300,
}

Config.Admin = {
	userIds = {
		5501871609,
	},
	grupId = 283943894,
	grupRutbesi = 254,
	allowInStudio = true,
	keyCode = Enum.KeyCode.F2,
	rotGrant = 1_000_000_000_000,
}

Config.Fuse = {
	machineName = "FuseMakinesi",
	machineAltName = "FuseMachine",
	machinePromptText = "Insert",
	machinePromptSubText = "Fuse Machine",
	machineHoldDuration = 0.4,
	machinePromptDistance = 20,
	machineSpawnPosition = Vector3.new(-44, 5, -40),
	machineRange = 28,
}

Config.Islands = {
	{
		name = "Main Island",
		desc = "Starter island. Luck x1.",
		spawnPartName = "Spawn_AnaAda",
		position = Vector3.new(-1879, 22.9, 107),
		price = 0,
		luck = 1,
		color = Color3.fromRGB(245, 222, 140),
	},
	{
		name = "Candy Island",
		desc = "Sticky pink sands. Luck x2. Cosmic pets appear here.",
		spawnPartName = "Spawn_Sakiz",
		position = Vector3.new(-990.1, 28.6, -747.5),
				price = 1_000_000_000,
		luck = 2,
		color = Color3.fromRGB(255, 130, 200),
	},
	{
		name = "Snow Island",
		desc = "Frozen sands. Luck x4. Secret pets appear here.",
		spawnPartName = "Spawn_Buz",
		position = Vector3.new(-262.8, 30.5, 709.7),
		price = 30_000_000_000,
		luck = 4,
		color = Color3.fromRGB(140, 220, 245),
	},
	{
		name = "Volcano Island",
		desc = "Scorching sands. Luck x8. Infernal pets appear here.",
		spawnPartName = "Spawn_Volkan",
		position = Vector3.new(620.3, 16.3, -34.5),
		price = 250_000_000_000,
		luck = 8,
		color = Color3.fromRGB(230, 110, 70),
	},
	{
		comingSoon = true,
		name = "Coming Soon",
		desc = "A new island is on its way!",
		spawnPartName = "Spawn_Gizli",
		position = Vector3.new(-956.3, 28.6, -738.6),
		price = 5_000_000_000_000,
		luck = 10,
		color = Color3.fromRGB(180, 130, 245),
	},
}

Config.Sand = {
	materials = {
		[Enum.Material.Sand] = true,
	},
	nameKeywords = { "kum", "sand" },
	rayDepth = 12,

	luckByName = {
		sekerkum = 2,
		sakizkum = 2,
		snowkum = 4,
		buzkum = 4,
		alevkum = 8,
		volkankum = 8,
	},
}

Config.GPS = {
	scanInterval = 1.5,
	scanRadius = 75,
	spawnChance = 35,
	maxBeamsPerPlayer = 4,
	beamLifetime = 30,
	seaLuck = 16,
	minSpawnDistance = 18,
	maxSpawnDistance = 55,
	digDistance = 6,
	seaDigDistance = 32,

	seaMinSpawnDistance = 55,
	seaMaxSpawnDistance = 190,
	seaSeparation = 85,
}

Config.Dig = {
	prepareTime = 0.8,
	cooldown = 0.6,
	maxMoveDistance = 14,
	seaMoveDistance = 30,
	minigameTimeout = 120,

	autoEquipInterval = 0.3,

	autoUnequipDelay = 1,
}

Config.BeamVFX = {
	name = "DigLightVFX",

	keepColor = { "Rocks" },

	groundParts = { "Rocks" },

	hide = {},

	preserveShading = true,

	vividness = 0.9,

	scaleByRarity = {
		Legendary = 1.3,
		Mythic = 1.7,
		Secret = 2.4,

		Cosmic = 2.9,
		Gizli = 3.4,
		Infernal = 3.9,
		Abyssal = 4.5,
		Mystery = 5.5,
	},

	alignToGround = true,

	height = -1,

	removeDark = true,

	darkThreshold = 0.22,

	softenWhite = true,

	whiteSaturation = 0.5,
	whiteValue = 0.72,

	whiteGrey = 0.22,

	whiteSaturationRef = 0.5,

	whiteMaxValue = 0.35,

	whiteHighlight = 0,

	whiteHighlightValue = 0.65,

	whiteGlow = 0,

	label = "Suzme",
}

Config.WhirlVFX = {
	name = "VortexVFX",

	label = "Girdap",

	keepColor = {},
	hide = {},

	stripScripts = true,

	spin = 45,
	spinTag = "GirdapDonus",

	preserveShading = false,
	vividness = 1,

	tintParts = true,

	ramp = {
		coreMix = 0.88,

		lightMix = 0.5,

		darkMix = 0.3,

		lightEmission = 0.8,

		lightBrightness = 2,

		extraTransparency = 0.03,
	},

	removeDark = false,
	darkThreshold = 0.22,
	softenWhite = false,
	whiteSaturation = 0.5,
	whiteValue = 0.72,
	whiteGrey = 0.22,
	whiteSaturationRef = 0.5,
	whiteMaxValue = 0.35,
	whiteHighlight = 0,
	whiteHighlightValue = 0.65,
	whiteGlow = 0,

	baseScale = 1,

	scaleByRarity = {
		Common = 0.6,
		Rare = 0.75,
		Epic = 0.95,
		Legendary = 1.15,
		Mythic = 1.4,
		Secret = 1.7,

		Cosmic = 2.0,
		Gizli = 2.3,
		Infernal = 2.6,
		Abyssal = 3.0,
		LuckyBlock = 1,
	},

	alignToGround = false,

	fixedY = 20,

	height = 0,
}

Config.Duyuru = {
	kademeler = { "Infernal", "Abyssal" },
	seritSuresi = 6,
	odulSuresi = 4.5,
}

return Config
