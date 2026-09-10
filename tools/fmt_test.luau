local Format = require("../src/shared/Format")

local cases = {
	{ 0, "0" },
	{ 500, "500" },
	{ 500000, "500K" },
	{ 800000, "800K" },
	{ 8000000, "8M" },
	{ 25000000, "25M" },
	{ 40000000, "40M" },
	{ 600000000, "600M" },
	{ 800000000, "800M" },
	{ 8000000000, "8B" },
	{ 10000000000, "10B" },
	{ 12000000000, "12B" },
	{ 1500, "1.5K" },
	{ 1250, "1.25K" },
	{ 2000000, "2M" },
	{ 105000000, "105M" },
	{ 1200000000000, "1.2T" },
}

local fail = 0
print(string.format("%-16s %-10s %-10s", "DEGER", "BEKLENEN", "SONUC"))
for _, c in cases do
	local got = Format.short(c[1])
	local ok = got == c[2]
	if not ok then fail += 1 end
	print(string.format("%-16d %-10s %-10s %s", c[1], c[2], got, if ok then "" else "  <-- HATA"))
end

print("")
if fail == 0 then
	print("HEPSI DOGRU")
else
	print(fail .. " hata")
end
