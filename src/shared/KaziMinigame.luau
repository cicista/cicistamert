--!strict

local DigMinigame = require(script.Parent.DigMinigame)
local Rarity = require(script.Parent.Rarity)
local Ores = require(script.Parent.Ores)
local Shovels = require(script.Parent.Shovels)

local KaziMinigame = {}
KaziMinigame.__index = KaziMinigame

KaziMinigame.MAX_CPS = 12

KaziMinigame.BURST = 4

KaziMinigame.START = 0.5

KaziMinigame.GAIN = 0.03

local GEREKEN_CPS: { [number]: number } = {
	[-2] = 1.5,
	[-1] = 2.5,
	[0] = 4,
	[1] = 5.5,
}

local MUAF_KUREK_LEVEL = 1

KaziMinigame.IMKANSIZ_FARK = 2

KaziMinigame.IMKANSIZ_KATI = 2.5

export type State = {
	progress: number,
	finished: boolean,
	won: boolean,
	throttled: boolean,
}

export type Game = typeof(setmetatable(
	{} :: {
		drain: number,
		state: State,
		_tokens: number,
	},
	KaziMinigame
))

function KaziMinigame.fark(gearId: string, rarityId: string): number
	local gear = DigMinigame.gear(gearId)
	local info = Rarity.Info[rarityId]
	local order = if info then info.order else 1

	local guc = if Shovels.Info[gearId] then Shovels.power(gear.level) else gear.level
	return order - guc
end

local function erisilemez(fark: number): boolean
	return fark > KaziMinigame.IMKANSIZ_FARK - 1 + 1e-6
end
function KaziMinigame.gerekenCps(gearId: string, rarityId: string): number
	local maden = Ores.get(rarityId)
	if maden then
		return maden.cps
	end

	local fark = KaziMinigame.fark(gearId, rarityId)

	if erisilemez(fark) then
		return KaziMinigame.MAX_CPS * KaziMinigame.IMKANSIZ_KATI
	end

	if fark > 0 and DigMinigame.gear(gearId).level == MUAF_KUREK_LEVEL then
		fark -= 1
	end

	local f = math.max(fark, -2)
	local alt = math.floor(f)
	local ust = math.ceil(f)
	local altCps = GEREKEN_CPS[alt] or GEREKEN_CPS[-2]
	if alt == ust then
		return altCps
	end
	local ustCps = GEREKEN_CPS[ust] or altCps
	return altCps + (ustCps - altCps) * (f - alt)
end

function KaziMinigame.drain(gearId: string, rarityId: string): number
	return KaziMinigame.GAIN * KaziMinigame.gerekenCps(gearId, rarityId)
end

function KaziMinigame.reachable(gearId: string, rarityId: string): boolean
	if Ores.get(rarityId) then
		return true
	end

	return not erisilemez(KaziMinigame.fark(gearId, rarityId))
end

function KaziMinigame.enYuksekKademe(gearId: string): string?
	local secilen: string? = nil
	for _, id in Rarity.Order do
		if KaziMinigame.reachable(gearId, id) then
			secilen = id
		end
	end
	return secilen
end

function KaziMinigame.minDuration(gearId: string, rarityId: string): number
	if not KaziMinigame.reachable(gearId, rarityId) then
		return math.huge
	end

	local net = KaziMinigame.MAX_CPS * KaziMinigame.GAIN - KaziMinigame.drain(gearId, rarityId)
	if net <= 0 then
		return math.huge
	end

	local mesafe = 1 - KaziMinigame.START - KaziMinigame.BURST * KaziMinigame.GAIN
	if mesafe <= 0 then
		return 0
	end

	return mesafe / net
end

function KaziMinigame.new(gearId: string, rarityId: string): Game
	local self = setmetatable({
		drain = KaziMinigame.drain(gearId, rarityId),
		_tokens = KaziMinigame.BURST,
		state = {
			progress = KaziMinigame.START,
			finished = false,
			won = false,
			throttled = false,
		},
	}, KaziMinigame)

	return self
end

function KaziMinigame.click(self: Game): boolean
	local s = self.state
	if s.finished then
		return false
	end

	if self._tokens < 1 then
		s.throttled = true
		return false
	end

	self._tokens -= 1
	s.throttled = false
	s.progress = math.min(1, s.progress + KaziMinigame.GAIN)

	if s.progress >= 1 then
		s.finished = true
		s.won = true
	end

	return true
end

function KaziMinigame.step(self: Game, dt: number): State
	local s = self.state
	if s.finished then
		return s
	end

	self._tokens = math.min(KaziMinigame.BURST, self._tokens + dt * KaziMinigame.MAX_CPS)

	s.progress -= self.drain * dt

	if s.progress <= 0 then
		s.progress = 0
		s.finished = true
		s.won = false
	end

	return s
end

return KaziMinigame
