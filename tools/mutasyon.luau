--!strict
--[[
	Mutasyon ve boyut dagilimi.
	Kullanim: lune run tools/mutasyon.luau

	Shared > Mutations ve Condition Roblox API'si (Color3) kullandigi icin
	Lune'da dogrudan require edilemez; asagidaki degerler onlarla ayni
	tutulmali.
]]

-- Mutations.luau ile ayni
local MUTATIONS = {
	{ id = "Normal", chance = 89, mult = 1, obtainable = true },
	{ id = "Gold", chance = 7, mult = 3, obtainable = true },
	{ id = "Diamond", chance = 3, mult = 5, obtainable = true },
	{ id = "Galaxy", chance = 1, mult = 8, obtainable = true },
	{ id = "Lava", chance = 0, mult = 6, obtainable = false },
	{ id = "Rainbow", chance = 0, mult = 10, obtainable = false },
	{ id = "Hacker", chance = 0, mult = 12, obtainable = false },
}

-- Condition.luau ile ayni
local SIZES = {
	{ id = "Tiny", chance = 32, scale = 0.25, mult = 1 },
	{ id = "Small", chance = 24, scale = 0.6, mult = 1.5 },
	{ id = "Normal", chance = 30, scale = 1, mult = 2 },
	{ id = "Large", chance = 11, scale = 1.4, mult = 2.5 },
	{ id = "Huge", chance = 3, scale = 2, mult = 3 },
}

print("=== MUTASYON ===")
print(string.format("%-10s %-10s %-10s %s", "ID", "SANS", "CARPAN", "DURUM"))
print(string.rep("-", 44))

local total = 0
for _, m in MUTATIONS do
	total += m.chance
	print(string.format(
		"%-10s %-10s %-10s %s",
		m.id,
		if m.obtainable then `%{m.chance}` else "-",
		`{m.mult}x`,
		if m.obtainable then "cikabilir" else "KAPALI (sadece panel)"
	))
end

print("")
print(`Cikabilirlerin toplami: %{total}` .. (if total == 100 then "  (dogru)" else "  <-- 100 OLMALI"))

print("")
print("=== BOYUT ===")
print(string.format("%-10s %-8s %-10s %s", "ID", "SANS", "OLCEK", "GELIR CARPANI"))
print(string.rep("-", 44))

local sizeTotal = 0
for _, s in SIZES do
	sizeTotal += s.chance
	print(string.format("%-10s %-8s %-10s %s", s.id, `%{s.chance}`, `{s.scale}x`, `{s.mult}x`))
end

print("")
print(`Toplam: %{sizeTotal}` .. (if sizeTotal == 100 then "  (dogru)" else "  <-- 100 OLMALI"))

--[[
	En iyi/en kotu durum yukaridaki TABLOLARDAN turetiliyor.

	Onceden bu satirlarin sayilari elle yazilmisti ve denge degisince
	guncellenmiyordu: Rainbow kapatildiktan sonra bile "en yuksek carpan
	Huge + Rainbow" yaziyordu.
]]
local function bestMutation(onlyObtainable: boolean)
	local best = MUTATIONS[1]
	for _, m in MUTATIONS do
		if (not onlyObtainable or m.obtainable) and m.mult > best.mult then
			best = m
		end
	end
	return best
end

local function bestSize()
	local best = SIZES[1]
	for _, s in SIZES do
		if s.mult > best.mult then
			best = s
		end
	end
	return best
end

local worstSize, worstMutation = SIZES[1], MUTATIONS[1]
local topSize = bestSize()
local topObtainable = bestMutation(true)
local topAny = bestMutation(false)

print("")
print("=== EN IYI / EN KOTU DURUM ===")
print(string.format(
	"En dusuk carpan : %.1fx  (%s + %s)",
	worstSize.mult * worstMutation.mult,
	worstSize.id,
	worstMutation.id
))
print(string.format(
	"En yuksek carpan: %.1fx  (%s + %s)",
	topSize.mult * topObtainable.mult,
	topSize.id,
	topObtainable.id
))
print(string.format(
	"Panelle         : %.1fx  (%s + %s)",
	topSize.mult * topAny.mult,
	topSize.id,
	topAny.id
))
