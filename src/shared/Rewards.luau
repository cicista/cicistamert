--!strict

local LuckyBlock = require(script.Parent.LuckyBlock)
local Format = require(script.Parent.Format)
local Passler = require(script.Parent.Passler)

local Rewards = {}

Rewards.cooldown = 86400

Rewards.MinSessionSeconds = 15 * 60

Rewards.streakReset = 172800

local function uctakiTur(enPahali: boolean): string
	local secilen = LuckyBlock.Tiers[1]
	for _, tur in LuckyBlock.Tiers do
		if (enPahali and tur.order > secilen.order) or (not enPahali and tur.order < secilen.order) then
			secilen = tur
		end
	end
	return secilen.id
end

local EN_UCUZ = uctakiTur(false)
local EN_PAHALI = uctakiTur(true)

export type Day = {
	day: number,
	kind: string,
	amount: number,
	tier: string?,
	rotCoins: number?,
	pass: string?,
	passSeconds: number?,
}

Rewards.Days = {
	{ day = 1, kind = "rot", amount = 150000, rotCoins = 1 },
	{ day = 2, kind = "rot", amount = 3000000, rotCoins = 1 },
	{ day = 3, kind = "pass", amount = 0, pass = "DetectivePass", passSeconds = 86400, rotCoins = 1 },
	{ day = 4, kind = "luckyblock", amount = 1, tier = EN_UCUZ, rotCoins = 1 },
	{ day = 5, kind = "luckyblock", amount = 2, tier = EN_UCUZ, rotCoins = 2, pass = "Teleporter", passSeconds = 43200 },
	{ day = 6, kind = "luckyblock", amount = 3, tier = EN_UCUZ, rotCoins = 1 },
	{ day = 7, kind = "luckyblock", amount = 1, tier = EN_PAHALI, rotCoins = 1 },
} :: { Day }

function Rewards.get(day: number): Day
	return Rewards.Days[math.clamp(math.floor(day), 1, #Rewards.Days)]
end

function Rewards.nextDay(day: number): number
	return day % #Rewards.Days + 1
end

function Rewards.passSuresi(saniye: number): string
	local t = math.max(0, math.floor(saniye))
	if t >= 86400 and t % 86400 == 0 then
		local gun = t // 86400
		return if gun == 1 then "1 Day" else `{gun} Days`
	end
	if t >= 3600 then
		return `{t // 3600}h`
	end
	return `{t // 60} min`
end

function Rewards.label(day: number): string
	local odul = Rewards.get(day)
	if odul.kind == "rot" then
		return `+{Format.short(odul.amount)} Rot`
	elseif odul.kind == "pass" then
		local bilgi = Passler.get(odul.pass or "")
		local ad = if bilgi then bilgi.ad else (odul.pass or "Pass")
		return `{ad} ({Rewards.passSuresi(odul.passSeconds or 0)})`
	end

	local tur = LuckyBlock.get(odul.tier)
	return if odul.amount > 1 then `{odul.amount}x {tur.displayName}` else tur.displayName
end

function Rewards.color(day: number): Color3
	local odul = Rewards.get(day)
	if odul.kind == "rot" then
		return Color3.fromRGB(255, 214, 41)
	elseif odul.kind == "pass" then
		return Color3.fromRGB(170, 120, 255)
	end
	return LuckyBlock.get(odul.tier).color
end

export type State = {
	day: number,
	ready: boolean,
	remaining: number,
}

function Rewards.state(lastReward: number, rewardDay: number, now: number): State
	local day = math.clamp(math.floor(rewardDay), 1, #Rewards.Days)

	if lastReward <= 0 then
		return { day = day, ready = true, remaining = 0 }
	end

	local elapsed = now - lastReward

	if elapsed >= Rewards.streakReset then
		return { day = 1, ready = true, remaining = 0 }
	end

	if elapsed >= Rewards.cooldown then
		return { day = day, ready = true, remaining = 0 }
	end

	return { day = day, ready = false, remaining = Rewards.cooldown - elapsed }
end

function Rewards.formatRemaining(seconds: number): string
	local total = math.max(0, math.floor(seconds))
	local hours = math.floor(total / 3600)
	local minutes = math.floor((total % 3600) / 60)
	local secs = total % 60

	if hours > 0 then
		return `{hours}h {minutes}m`
	end
	if minutes > 0 then
		return `{minutes}m {secs}s`
	end
	return `{secs}s`
end

function Rewards.formatClock(seconds: number): string
	local t = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d:%02d", t // 3600, (t % 3600) // 60, t % 60)
end

return Rewards
