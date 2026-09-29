--!strict

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

			if text:find(".", 1, true) then
				text = text:gsub("0+$", ""):gsub("%.$", "")
			end
			return (if negative then "-" else "") .. text .. entry.suffix
		end
	end

	return (if negative then "-" else "") .. string.format("%d", abs)
end

function Format.perSecond(n: number): string
	return Format.short(n) .. "/s"
end

return Format
