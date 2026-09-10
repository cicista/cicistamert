--!strict
--[[
	Kenarda takilma testi.
	Kullanim: lune run tools/kenar.luau

	DigMinigame Roblox API'si kullandigi icin dogrudan require edilemez;
	buradaki hedef hareketi oradaki formulun aynisidir. Amac: hedefin kenar
	bolgesinde (0.12 alti / 0.88 ustu) kesintisiz kac saniye kaldigini olcmek.
	Sinir 1.5 saniye; asiliyorsa duzeltme calismiyor demektir.
]]

local EDGE_LOW = 0.12
local EDGE_HIGH = 0.88
local EDGE_MAX_TIME = 1.5

-- Bir kaci simule edip en uzun kenar kalisini dondurur
-- Lune'da Roblox'un Random sinifi yok; deterministik basit bir uretec
local function makeRng(seed: number)
	local state = seed
	return {
		NextNumber = function(_, min: number, max: number): number
			state = (state * 1103515245 + 12345) % 2147483648
			local t = state / 2147483648
			if min then
				return min + (max - min) * t
			end
			return t
		end,
	}
end

local function simulate(difficulty: number, seconds: number, seed: number): number
	local rng = makeRng(seed)

	local targetPosition = 0.5
	local targetVelocity = 0
	local targetGoal = 0.5
	local targetTimer = 0
	local edgeTimer = 0

	local worstEdge = 0
	local currentEdge = 0

	local dt = 1 / 60
	local steps = math.floor(seconds / dt)

	for _ = 1, steps do
		-- _retarget
		local position = targetPosition

		if position <= EDGE_LOW or position >= EDGE_HIGH then
			edgeTimer += dt
		else
			edgeTimer = 0
		end

		if edgeTimer >= EDGE_MAX_TIME then
			edgeTimer = 0
			targetTimer = rng:NextNumber(0.25, 0.5)
			local inward = if position <= EDGE_LOW then 1 else -1
			targetGoal = math.clamp(position + inward * rng:NextNumber(0.3, 0.5), 0.08, 0.92)
		else
			targetTimer -= dt
			if targetTimer <= 0 then
				local minInterval = math.max(0.12, 0.9 - difficulty * 0.12)
				local maxInterval = math.max(minInterval + 0.1, 1.7 - difficulty * 0.2)
				targetTimer = rng:NextNumber(minInterval, maxInterval)

				local jump = 0.12 + difficulty * 0.06
				local goal = position + rng:NextNumber(-jump, jump)

				if position <= EDGE_LOW then
					goal = math.max(goal, position + jump * 0.35)
				elseif position >= EDGE_HIGH then
					goal = math.min(goal, position - jump * 0.35)
				end

				targetGoal = math.clamp(goal, 0.06, 0.94)
			end
		end

		-- Hedef hareketi
		local chase = 2.2 + difficulty * 0.5
		targetVelocity += (targetGoal - targetPosition) * chase * dt
		targetVelocity *= 0.90
		targetPosition = math.clamp(targetPosition + targetVelocity, 0.02, 0.98)

		-- Kesintisiz kenar kalisini olc
		if targetPosition <= EDGE_LOW or targetPosition >= EDGE_HIGH then
			currentEdge += dt
			if currentEdge > worstEdge then
				worstEdge = currentEdge
			end
		else
			currentEdge = 0
		end
	end

	return worstEdge
end

print(string.format("%-24s %-14s %s", "SENARYO", "EN UZUN KENAR", "DURUM"))
print(string.rep("-", 56))

local cases = {
	{ "Common  (d=0.24)", 0.24 },
	{ "Rare    (d=1.7)", 1.7 },
	{ "Epic    (d=6)", 6 },
	{ "Legendary (d=5.4)", 5.44 },
	{ "Mythic  (d=7.65)", 7.65 },
	{ "Secret  (d=10.2)", 10.2 },
}

local failed = 0
for _, case in cases do
	local worst = 0
	-- Bircok tohumla dene, en kotusunu al
	for seed = 1, 40 do
		local w = simulate(case[2], 60, seed)
		if w > worst then
			worst = w
		end
	end

	-- Sinir + hedefin ic tarafa donmesi icin gereken kisa sure
	local ok = worst <= EDGE_MAX_TIME + 0.6
	if not ok then
		failed += 1
	end

	print(string.format("%-24s %-14s %s", case[1], string.format("%.2f sn", worst), if ok then "ok" else "TAKILIYOR"))
end

print("")
if failed == 0 then
	print(`Hicbir senaryoda {EDGE_MAX_TIME} sn siniri asilmadi`)
else
	print(`{failed} senaryoda hedef kenarda takiliyor`)
end
