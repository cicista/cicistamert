--!strict

export type Pet = {
	name: string,
	rarity: string,
	island: string,
	incomeFactor: number,
	modelName: string?,
}

type Grup = {
	island: string,
	rarity: string,
	pets: { string },
}

local Petler = {}

Petler.Paketler = { "BGC Pets Pack" }

Petler.ModelAdlari = {
	["Fall Triumph"] = "Fall Triumpth",
} :: { [string]: string }

Petler.GelirAraligi = {
	kum = { 0.1, 0.45 },
	sekerkum = { 0.45, 0.6 },
	snowkum = { 0.6, 0.75 },
	alevkum = { 0.76, 0.92 },
	deniz = { 0.5, 0.95 },
} :: { [string]: { number } }

Petler.Gruplar = {
	{ island = "kum", rarity = "Common", pets = { "Mouse", "Piggy", "Dino", "Deer", "Fox", "Bruh", "Panda" } },
	{
		island = "kum",
		rarity = "Rare",
		pets = { "Wolf", "Leafy Bunny", "Leafy Kitty", "Leafy Bear", "Leafy Deer", "Castle Deer", "Castle Bear" },
	},
	{
		island = "kum",
		rarity = "Epic",
		pets = { "Dragon", "Leafy Dragon", "Castle Dragon", "Flying Acorn", "Flying Pig", "Bruh Bandit", "Fall Cloud" },
	},
	{
		island = "kum",
		rarity = "Legendary",
		pets = { "Castle Orb", "Smiling Orb", "Stuffed Paragon", "Puppet Dragon", "Old Dolly", "Rainbow Shock" },
	},
	{
		island = "kum",
		rarity = "Mythic",
		pets = {
			"Fall Triumph",
			"Throne Guard",
			"Duke",
			"Giant Fall Turkey",
			"Goof Bot",
			"Fall Star",
			"Dream Clock",
			"Release Orb",
			"Fall Queen",
		},
	},
	{
		island = "kum",
		rarity = "Secret",
		pets = {
			"King Doggy",
			"King Kitty",
			"Unicorn",
			"Baron Bunny",
			"Release Robot",
			"Mythic Baron Bunny",
			"King Bruh",
			"Mythic Fall Queen",
			"Immortality Stone",
			"Fall Champion",
			"Mythic Immortality Stone",
		},
	},

	{
		island = "sekerkum",
		rarity = "Common",
		pets = { "Yummy Doggy", "Yummy Bear", "Yummy Bunny", "Yummy Kitty", "Candy Fox", "Lemon Fox" },
	},
	{
		island = "sekerkum",
		rarity = "Rare",
		pets = { "Candy Deer", "Orange Deer", "Candy Dino", "Cherry Dino", "Candy Golem", "Cherry Golem", "Yummy Crawler" },
	},
	{
		island = "sekerkum",
		rarity = "Epic",
		pets = { "Candy Dragon", "Lime Dragon", "Candy Angel", "Lime Angel", "Bubble Blowing Alien" },
	},
	{ island = "sekerkum", rarity = "Legendary", pets = { "Candy Lord", "Caramel Demise", "Electra" } },
	{ island = "sekerkum", rarity = "Mythic", pets = { "Candy Paladin", "Inky Guardian" } },
	{ island = "sekerkum", rarity = "Secret", pets = { "Mythic Candy Paladin", "Unlucky Clover" } },
	{ island = "sekerkum", rarity = "Cosmic", pets = { "Celestial Wisp" } },

	{ island = "snowkum", rarity = "Common", pets = { "Ornament Doggy", "Ornament Kitty", "Polar Bear", "Frost Deer" } },
	{
		island = "snowkum",
		rarity = "Rare",
		pets = { "Ornament Bunny", "Ornament Bear", "Frost Wolf", "Frost Kitty", "Opened Giftbox" },
	},
	{ island = "snowkum", rarity = "Epic", pets = { "Ornament Angel", "Frost Dragon", "Ice Dragon", "Flying Giftbag" } },
	{
		island = "snowkum",
		rarity = "Legendary",
		pets = { "Flying Peppermint", "Xmas Bronze Trophy", "Starlight Dragon" },
	},
	{ island = "snowkum", rarity = "Mythic", pets = { "Xmas Gold Trophy", "Christmas Robot", "Snowpuff" } },
	{
		island = "snowkum",
		rarity = "Secret",
		pets = { "Jolly Star", "Clock Flake", "North Pole Moon", "Mythic Christmas Robot" },
	},
	{ island = "snowkum", rarity = "Cosmic", pets = { "Royal Santa", "Christmas Future", "Grinch" } },
	{ island = "snowkum", rarity = "Gizli", pets = { "Mythic Royal Santa", "Glacier Lord" } },

	{ island = "alevkum", rarity = "Common", pets = { "Pumpkin Mouse", "Pumpkin Doggy", "Void Bear", "Void Kitty" } },
	{ island = "alevkum", rarity = "Rare", pets = { "Pumpkin Kitty", "Pumpkin Bat", "Void Fox", "Void Deer" } },
	{
		island = "alevkum",
		rarity = "Epic",
		pets = { "Void Bat", "Void Demon", "Void Dragon", "Dark Phoenix", "Inferno Dragon" },
	},
	{ island = "alevkum", rarity = "Legendary", pets = { "Ruby Dragon", "Dark Dragon", "Demonic Furnace" } },
	{ island = "alevkum", rarity = "Mythic", pets = { "Soulfly", "Redemption", "Overlord" } },
	{
		island = "alevkum",
		rarity = "Secret",
		pets = { "Enchanted Pumpkin", "Guardian Knight", "Crimson Knight", "Mythic Soulfly" },
	},
	{ island = "alevkum", rarity = "Cosmic", pets = { "Lavender Dominator", "Mythic Enchanted Pumpkin" } },

	{ island = "deniz", rarity = "Rare", pets = { "Lunar Serpent" } },
	{ island = "deniz", rarity = "Legendary", pets = { "Koi" } },
	{ island = "deniz", rarity = "Mythic", pets = { "Admiral" } },
	{ island = "deniz", rarity = "Secret", pets = { "Immortal Pufferfish" } },
	{ island = "deniz", rarity = "Cosmic", pets = { "King Koi" } },
	{ island = "deniz", rarity = "Gizli", pets = { "The Moon" } },
	{ island = "deniz", rarity = "Abyssal", pets = { "Mythic The Moon" } },
} :: { Grup }

local liste: { Pet } = {}
local adlar: { [string]: boolean } = {}

for _, grup in Petler.Gruplar do
	local aralik = Petler.GelirAraligi[grup.island] or { 0.1, 0.9 }
	local adet = #grup.pets

	for i, ad in grup.pets do
		local oran = if adet > 1 then (i - 1) / (adet - 1) else 0.5
		local faktor = aralik[1] + (aralik[2] - aralik[1]) * oran

		table.insert(liste, {
			name = ad,
			rarity = grup.rarity,
			island = grup.island,
			incomeFactor = math.floor(faktor * 100 + 0.5) / 100,
			modelName = Petler.ModelAdlari[ad],
		})
		adlar[ad] = true
	end
end

function Petler.liste(): { Pet }
	return liste
end

function Petler.mi(name: string?): boolean
	return name ~= nil and adlar[name] == true
end

function Petler.modelAdi(name: string): string
	return Petler.ModelAdlari[name] or name
end

return Petler
