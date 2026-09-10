--!strict
--[[
	Rarity gelir oranlari.
	Kullanim: lune run tools/gelir.luau

	Shared > Rarity Roblox API'si (Color3) kullandigi icin Lune'da dogrudan
	require edilemez; asagidaki araliklar oradakiyle ayni tutulmali.

	Gosterilen: her rarity'nin Tiny (1x) ve Huge (3x) boyutundaki saniyelik
	getirisi ve bir onceki kademeye orani.
]]

local TIERS = {
	{ id = "Common", min = 10, max = 50 },
	{ id = "Rare", min = 250, max = 1250 },
	{ id = "Epic", min = 7000, max = 35000 },
	{ id = "Legendary", min = 200000, max = 1000000 },
	{ id = "Mythic", min = 3000000, max = 15000000 },
	{ id = "Divine", min = 35000000, max = 165000000 },
}

-- En buyuk boyutun gelir carpani (Shared > Condition > Huge ile ayni)
local HUGE_MULTIPLIER = 3

local function short(n: number): string
	local units = { { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in units do
		if n >= u[1] then
			local scaled = n / u[1]
			local text = if scaled >= 100 then string.format("%.0f", scaled) else string.format("%.1f", scaled)
			text = (text:gsub("%.0$", ""))
			return text .. u[2]
		end
	end
	return string.format("%.0f", n)
end

print(string.format("%-11s %-16s %-16s %s", "RARITY", "Tiny (ortalama)", "Huge (ortalama)", "ONCEKINE ORAN"))
print(string.rep("-", 64))

local previous = 0
for _, t in TIERS do
	-- Ortalama incomeFactor 0.5 kabul
	local tiny = t.min + (t.max - t.min) * 0.5
	local huge = tiny * HUGE_MULTIPLIER

	local ratio = if previous > 0 then string.format("%.1fx", tiny / previous) else "-"
	previous = tiny

	print(string.format("%-11s %-16s %-16s %s", t.id, short(tiny), short(huge), ratio))
end
