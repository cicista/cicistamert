--!strict

local GPSEfekt = {}

GPSEfekt.BallName = "Anten"

GPSEfekt.color = Color3.fromRGB(60, 220, 90)

GPSEfekt.cycle = 1

GPSEfekt.gap = 0.37

GPSEfekt.Antenna = {
	size = 195,
	maxDistance = 90,
	minScale = 0.18,
	thickness = 2,
	fadeFrom = 0.1,
	fadeTo = 1,
}

function GPSEfekt.phase(clock: number): number?
	local total = GPSEfekt.cycle + GPSEfekt.gap
	if total <= 0 then
		return nil
	end

	local t = clock % total
	if t > GPSEfekt.cycle then
		return nil
	end

	return t / GPSEfekt.cycle
end

return GPSEfekt
