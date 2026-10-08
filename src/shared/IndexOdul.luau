--!strict

local Brainrots = require(script.Parent.Brainrots)
local Mutations = require(script.Parent.Mutations)

local IndexOdul = {}

IndexOdul.RotCoin = {
	kum = 3,
	sekerkum = 4,
	snowkum = 5,
	alevkum = 6,
	deniz = 10,
} :: { [string]: number }

IndexOdul.Mutasyonlar = { "Normal" } :: { string }
for _, mutasyon in Mutations.IndexOrder do
	table.insert(IndexOdul.Mutasyonlar, mutasyon)
end

local uyeler: { [string]: { string } } = {}
for _, info in Brainrots.List do
	local anahtar = `{Brainrots.normalizeIsland(info.island)}/{info.rarity}`
	local liste = uyeler[anahtar]
	if not liste then
		liste = {}
		uyeler[anahtar] = liste
	end
	table.insert(liste, info.name)
end

function IndexOdul.anahtar(mutasyon: string, ada: string, rarity: string): string
	return `{mutasyon}/{ada}/{rarity}`
end

function IndexOdul.miktar(ada: string): number
	return IndexOdul.RotCoin[ada] or 0
end

function IndexOdul.uyeler(ada: string, rarity: string): { string }
	return uyeler[`{ada}/{rarity}`] or {}
end

function IndexOdul.tamam(kesif: { [string]: boolean }?, ada: string, rarity: string): boolean
	local liste = uyeler[`{ada}/{rarity}`]
	if not liste or #liste == 0 or not kesif then
		return false
	end
	for _, ad in liste do
		if kesif[ad] ~= true then
			return false
		end
	end
	return true
end

return IndexOdul
