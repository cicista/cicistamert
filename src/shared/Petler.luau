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

Petler.Paketler = { "Yeni Petler" }

Petler.ModelAdlari = {} :: { [string]: string }

Petler.Ters = {
	["Lava Lamp Jelly"] = true,
	["Frost Slime"] = true,
	["Frost Bunny"] = true,
	["Snow Globe Frog"] = true,
} :: { [string]: boolean }

Petler.GelirAraligi = {
	kum = { 0.1, 0.45 },
	sekerkum = { 0.45, 0.6 },
	snowkum = { 0.6, 0.75 },
	alevkum = { 0.76, 0.92 },
	deniz = { 0.5, 0.95 },
} :: { [string]: { number } }

Petler.Gruplar = {
	{
		island = "kum",
		rarity = "Common",
		pets = {
			"Wheat Mouse",
			"Twig Bug",
			"Lantern Firefly",
			"Leaf Squirrel",
			"Bee Pup",
			"Acorn Owl",
			"Lucky Ladybug",
			"Sprout Turtle",
			"Orange Capybara",
			"Log Beaver",
		},
	},
	{
		island = "kum",
		rarity = "Rare",
		pets = {
			"Blossom Bunny",
			"Clover Calf",
			"Pebble Golem",
			"Honey Bear",
			"Bamboo Panda",
			"Sleepy Sloth",
			"Leaf Koala",
			"Meadow Goat",
			"Nightcap Badger",
			"Banana Monkey",
		},
	},
	{
		island = "kum",
		rarity = "Epic",
		pets = {
			"Miner Mole",
			"Butterfly Kitty",
			"Rainbow Chameleon",
			"Poncho Llama",
			"Peacock Chick",
			"Explorer Platypus",
			"Golden Armadillo",
			"Lookout Meerkat",
			"Moss Bear",
			"Shroom Frog",
		},
	},
	{
		island = "kum",
		rarity = "Legendary",
		pets = {
			"Crystal Horn Pup",
			"Three-Eyed Hamster",
			"Gem Shell Turtle",
			"Twin Tail Cat",
			"Cloud Duckling",
			"Winged Hippo",
			"Horned Toucan",
			"Twin Head Parrot",
			"Cyber Raccoon",
		},
	},
	{
		island = "kum",
		rarity = "Mythic",
		pets = {
			"Crystal Fawn",
			"Shadow Pup",
			"Bolt Rhino",
			"Ghost Kitten",
			"Golden Ram",
			"Emerald Beetle",
			"Storm Owl",
			"Void Raven",
			"Thunder Kitten",
		},
	},
	{
		island = "kum",
		rarity = "Secret",
		pets = { "Star Griffin", "Celestial Owl King", "Spirit Wolf", "Emerald Dragon", "Ancient Forest Stag" },
	},

	{
		island = "sekerkum",
		rarity = "Common",
		pets = { "Marshmallow Chick", "Candy Corn Chick", "Jellybean Caterpillar", "Lollipop Snail", "Cake Mouse" },
	},
	{
		island = "sekerkum",
		rarity = "Rare",
		pets = { "Gummy Cub", "Donut Pup", "Choco Bunny", "Jelly Frog", "Pudding Pup" },
	},
	{
		island = "sekerkum",
		rarity = "Epic",
		pets = { "Cupcake Kitty", "Cotton Candy Lamb", "Waffle Turtle", "Macaron Hamster", "Caramel Otter" },
	},
	{
		island = "sekerkum",
		rarity = "Legendary",
		pets = { "Gingerbread Fox", "Popsicle Penguin", "Pretzel Ferret", "Licorice Snake", "Honeycomb Bee" },
	},
	{
		island = "sekerkum",
		rarity = "Mythic",
		pets = { "Sugar Cookie Cat", "Churro Dachshund", "Taffy Giraffe", "Soda Axolotl", "Gumdrop Golem" },
	},
	{
		island = "sekerkum",
		rarity = "Secret",
		pets = { "Rock Candy Lizard", "Candy Hedgehog", "Peppermint Dragon", "Sundae Unicorn" },
	},
	{
		island = "sekerkum",
		rarity = "Cosmic",
		pets = { "Prism Unicorn", "Royal Cake Golem", "Candy Empress Cat", "Lollipop Phoenix", "Rainbow Sugar Dragon" },
	},

	{
		island = "snowkum",
		rarity = "Common",
		pets = { "Mitten Mouse", "Ski Lemming", "Igloo Snail", "Frost Slime", "Ice Block Fish" },
	},
	{
		island = "snowkum",
		rarity = "Rare",
		pets = { "Frost Bunny", "Scarf Owl", "Snowball Seal", "Frost Ermine", "Scarf Puffin" },
	},
	{
		island = "snowkum",
		rarity = "Epic",
		pets = { "Beanie Polar Cub", "Snowman Pup", "Ice Crab", "Musk Ox Calf", "Icicle Bat" },
	},
	{
		island = "snowkum",
		rarity = "Legendary",
		pets = { "Arctic Fox", "Goggle Husky", "Lynx Kitten", "Ice Cube Golem", "Snow Globe Frog" },
	},
	{
		island = "snowkum",
		rarity = "Mythic",
		pets = { "Penguin Knight", "Glacier Tortoise", "Icicle Walrus", "Ice Crystal Hedgehog" },
	},
	{
		island = "snowkum",
		rarity = "Secret",
		pets = { "Frost Moth", "Crystal Reindeer", "Snow Leopard Cub", "Yeti Cub" },
	},
	{
		island = "snowkum",
		rarity = "Cosmic",
		pets = { "Crystal Penguin", "Snowflake Dragon", "Galaxy Mammoth", "Nebula Fox" },
	},
	{
		island = "snowkum",
		rarity = "Gizli",
		pets = { "Blizzard Yeti King", "Frost Phoenix", "Ice Empress Fox", "Frost Titan Dragon" },
	},

	{
		island = "alevkum",
		rarity = "Common",
		pets = { "Fire Ant", "Lava Duckling", "Ember Bat", "Coal Mole" },
	},
	{
		island = "alevkum",
		rarity = "Rare",
		pets = { "Magma Snail", "Ash Crow", "Smoke Skunk", "Ember Squirrel" },
	},
	{
		island = "alevkum",
		rarity = "Epic",
		pets = { "Fire Kiwi", "Lava Slime", "Flame Salamander", "Brimstone Beetle", "Fire Monkey" },
	},
	{
		island = "alevkum",
		rarity = "Legendary",
		pets = { "Ember Hedgehog", "Ember Fennec", "Volcano Turtle", "Magma Crab" },
	},
	{
		island = "alevkum",
		rarity = "Mythic",
		pets = { "Flame Pony", "Lava Lamp Jelly", "Furnace Bot", "Molten Octopus" },
	},
	{
		island = "alevkum",
		rarity = "Secret",
		pets = { "Fire Sprite", "Obsidian Scorpion", "Magma Golem", "Magma Lizard" },
	},
	{ island = "alevkum", rarity = "Cosmic", pets = { "Ember Fox", "Phoenix Chick", "Blaze Lion Cub" } },
	{ island = "alevkum", rarity = "Gizli", pets = { "Inferno Wyvern", "Thunder Kirin", "Ruby Dragon" } },
	{
		island = "alevkum",
		rarity = "Infernal",
		pets = { "Ember Cerberus Pup", "Magma Titan", "Inferno Hydra", "Volcano Dragon Lord" },
	},

	{ island = "deniz", rarity = "Common", pets = { "Starfish Buddy", "Sea Urchin", "Pink Squid", "Ocean Sunfish" } },
	{ island = "deniz", rarity = "Rare", pets = { "Anemone Clownfish", "Sea Bunny", "Blobfish", "Seaweed Turtle" } },
	{ island = "deniz", rarity = "Epic", pets = { "Chef Shrimp", "Shell House Crab", "Pelican Chick", "Sailor Seagull" } },
	{
		island = "deniz",
		rarity = "Legendary",
		pets = { "Balloon Puffer", "Spiral Nautilus", "Frilly Lionfish", "Shell Sea Otter" },
	},
	{ island = "deniz", rarity = "Mythic", pets = { "Coral Seahorse", "Crowned Jelly", "Pearl Clam", "Knight Lobster" } },
	{ island = "deniz", rarity = "Secret", pets = { "Hammerhead Pup", "Wave Dolphin", "Orca Calf", "Beluga Calf" } },
	{ island = "deniz", rarity = "Cosmic", pets = { "Lantern Angler", "Glow Manta", "Winged Goldfish", "Swordfish" } },
	{ island = "deniz", rarity = "Gizli", pets = { "Horned Octopus", "Tri-Fin Shark", "Glow Eel", "Leafy Sea Dragon" } },
	{ island = "deniz", rarity = "Infernal", pets = { "Treasure Chest Mimic", "Ice Narwhal" } },
	{
		island = "deniz",
		rarity = "Abyssal",
		pets = {
			"Celestial Whale",
			"Void Kraken",
			"Coral Titan Turtle",
			"Tidal Sea Dragon",
			"Storm Megalodon",
			"Abyss Leviathan",
		},
	},
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

function Petler.tersMi(name: string): boolean
	return Petler.Ters[name] == true
end

return Petler
