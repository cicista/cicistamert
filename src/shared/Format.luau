--!strict
--[[
	Buyuk sayilari kisa gosterim icin bicimlendirir.
	Pasif gelirler milyar mertebesine cikabildigi icin her yerde bu kullanilir.
	  1250       -> "1.25K"
	  50000000   -> "50M"
	  2000000000 -> "2B"
]]

local Format = {}

local SUFFIXES = {
	{ value = 1e12, suffix = "T" },
	{ value = 1e9, suffix = "B" },
	{ value = 1e6, suffix = "M" },
	{ value = 1e3, suffix = "K" },
}

function Format.short(n: number): string
	local negative = n < 0
	local abs = math.abs(n)

	for _, entry in SUFFIXES do
		if abs >= entry.value then
			local scaled = abs / entry.value
			local text = if scaled >= 100
				then string.format("%.0f", scaled)
				elseif scaled >= 10 then string.format("%.1f", scaled)
				else string.format("%.2f", scaled)

			--[[
				Sondaki gereksiz ondalik sifirlari at: "1.50K" -> "1.5K", "2.00M" -> "2M"

				YALNIZCA ondalik kisimda calisir. Onceki desen ("%.?0+$") noktayi
				opsiyonel yaptigi icin tam sayilarin anlamli sifirlarini da siliyordu:
				"800" -> "8", "600" -> "6", "500" -> "5". Yani 800M ekranda 8M
				gorunuyordu.
			]]
			if text:find(".", 1, true) then
				text = text:gsub("0+$", ""):gsub("%.$", "")
			end
			return (if negative then "-" else "") .. text .. entry.suffix
		end
	end

	return (if negative then "-" else "") .. string.format("%d", abs)
end

-- Saniyelik gelir etiketi: "1.5M/s"
function Format.perSecond(n: number): string
	return Format.short(n) .. "/s"
end

return Format
