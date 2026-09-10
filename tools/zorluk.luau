--!strict
--[[
	Kurek x rarity zorluk matrisi.
	Kullanim: lune run tools/zorluk.luau

	Shared > DigMinigame Roblox API'si kullandigi icin Lune'da dogrudan
	require edilemez; asagidaki degerler oradaki formulun aynisidir.
	Rarity.escapeDifficulty ya da gap carpanlari degisirse burayi da guncelle.
]]

-- Rarity.escapeDifficulty ile ayni
local RARITIES = {
	{ id = "Common", order = 1, escape = 0.4 },
	{ id = "Rare", order = 2, escape = 1 },
	{ id = "Epic", order = 3, escape = 2 },
	{ id = "Legendary", order = 4, escape = 3.2 },
	{ id = "Mythic", order = 5, escape = 4.5 },
	{ id = "Divine", order = 6, escape = 6 },
}

-- Shovels ile ayni
local SHOVELS = {
	{ id = "Wooden", level = 1, bar = 0.22 },
	{ id = "Iron", level = 2, bar = 0.26 },
	{ id = "Golden", level = 3, bar = 0.30 },
	{ id = "Diamond", level = 4, bar = 0.34 },
	{ id = "Celestial", level = 5, bar = 0.40 },
}

-- DigMinigame.gapMultiplier ile ayni
local GAP_MULTIPLIER = { [0] = 0.6, [1] = 1.7, [2] = 3 }

local function gapMultiplier(gap: number): number
	if gap < 0 then
		return math.max(0.4, 0.6 + gap * 0.08)
	end
	return GAP_MULTIPLIER[gap] or 4
end

--[[
	Etiket, hedefin sicrama mesafesini kuregin bar boyuyla karsilastirir:
	sicrama bardan kucukse tutulabilir, buyukse zorlasir.
	(DigMinigame'de jump = 0.12 + d * 0.06)
]]
local function label(difficulty: number, bar: number): string
	local jump = 0.12 + difficulty * 0.06
	local ratio = jump / bar

	if ratio < 0.45 then
		return "cok kolay"
	elseif ratio < 0.75 then
		return "kolay"
	elseif ratio < 1.05 then
		return "orta"
	elseif ratio < 1.45 then
		return "zor"
	elseif ratio < 2.2 then
		return "cok zor"
	end
	return "ALINAMAZ"
end

local header = string.format("%-14s", "KUREK")
for _, r in RARITIES do
	header ..= string.format("%-12s", r.id)
end
print(header)
print(string.rep("-", #header))

for _, s in SHOVELS do
	local row = string.format("Lv%d %-10s", s.level, s.id)

	for _, r in RARITIES do
		local d = r.escape * gapMultiplier(r.order - s.level)
		row ..= string.format("%-12s", label(d, s.bar))
	end

	print(row)
end
