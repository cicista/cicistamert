--!strict

local Rarity = require(script.Parent.Rarity)
local Rods = require(script.Parent.Rods)
local Shovels = require(script.Parent.Shovels)

local DigMinigame = {}
DigMinigame.__index = DigMinigame

local TIK = 1 / 60

local SUTUN = 568
local BALIK_ALT = 532

local BAR_IVME = 0.25
local BAR_ICERIDE_CARPAN = 0.6
local SEKME = 2 / 3

local BASLANGIC = 0.3

export type Hareket = "mixed" | "smooth" | "floater" | "sinker" | "dart"

export type BalikAyari = {
	zorluk: number,
	hareket: Hareket,
}

DigMinigame.Baliklar = {
	[1] = { zorluk = 15, hareket = "mixed" },
	[2] = { zorluk = 30, hareket = "smooth" },
	[3] = { zorluk = 45, hareket = "mixed" },
	[4] = { zorluk = 55, hareket = "floater" },
	[5] = { zorluk = 65, hareket = "mixed" },
	[6] = { zorluk = 75, hareket = "sinker" },
	[7] = { zorluk = 82, hareket = "dart" },
	[8] = { zorluk = 90, hareket = "mixed" },
	[9] = { zorluk = 100, hareket = "mixed" },
	[10] = { zorluk = 110, hareket = "mixed" },
} :: { [number]: BalikAyari }

export type GearInfo = {
	displayName: string,
	level: number,
	digSpeed: number,
	barSize: number,
	barAcceleration: number,
	progressRate: number,
	drainRate: number,
	color: Color3,
}

export type State = {
	barPosition: number,
	barVelocity: number,
	barSize: number,
	targetPosition: number,
	targetVelocity: number,
	progress: number,
	inside: boolean,
	finished: boolean,
	won: boolean,
}

export type Minigame = typeof(setmetatable({} :: {
	gear: GearInfo,
	balik: BalikAyari,
	difficulty: number,
	rng: Random,
	state: State,
	_barUst: number,
	_barHiz: number,
	_barBoy: number,
	_balik: number,
	_balikHiz: number,
	_hedef: number,
	_suzulme: number,
	_iceride: boolean,
	_birikim: number,
}, DigMinigame))

function DigMinigame.gear(gearId: string): GearInfo
	local shovel = Shovels.Info[gearId :: Shovels.ShovelId]
	if shovel then
		return shovel :: any
	end

	local rod = Rods.Info[gearId :: Rods.RodId]
	if rod then
		return rod :: any
	end

	return Shovels.Info[Shovels.Default] :: any
end

function DigMinigame.balik(rarityId: string): BalikAyari
	local info = Rarity.Info[rarityId :: Rarity.RarityId]
	local ayar = info and DigMinigame.Baliklar[info.order]
	return ayar or DigMinigame.Baliklar[1]
end

function DigMinigame.difficultyFor(_gearId: string, rarityId: Rarity.RarityId): number
	return DigMinigame.balik(rarityId).zorluk
end

function DigMinigame.isReachable(gearId: string, rarityId: Rarity.RarityId): boolean
	local gear = DigMinigame.gear(gearId)
	local info = Rarity.Info[rarityId]
	return info == nil or info.order <= gear.level * 2
end

function DigMinigame.minDuration(gearId: string): number
	local gear = DigMinigame.gear(gearId)
	return (1 - BASLANGIC) / gear.progressRate - TIK * 2
end

function DigMinigame.new(gearId: string, rarityId: Rarity.RarityId, seed: number?): Minigame
	local gear = DigMinigame.gear(gearId)
	local balik = DigMinigame.balik(rarityId)
	local barBoy = math.floor(gear.barSize * SUTUN + 0.5)

	local self = setmetatable({
		gear = gear,
		balik = balik,
		difficulty = balik.zorluk,
		rng = Random.new(seed or os.clock() * 1e6),
		state = {
			barPosition = 0,
			barVelocity = 0,
			barSize = barBoy / SUTUN,
			targetPosition = 0,
			targetVelocity = 0,
			progress = BASLANGIC,
			inside = true,
			finished = false,
			won = false,
		},
		_barUst = SUTUN - barBoy,
		_barHiz = 0,
		_barBoy = barBoy,
		_balik = 508,
		_balikHiz = 0,
		_hedef = -1,
		_suzulme = 0,
		_iceride = true,
		_birikim = 0,
	}, DigMinigame)

	self:_yansit()
	return self
end

local function sonraki(rng: Random, a: number, b: number): number
	a = math.floor(a)
	b = math.floor(b)
	if b - 1 <= a then
		return a
	end
	return rng:NextInteger(a, b - 1)
end

function DigMinigame._balikTik(self: Minigame)
	local rng = self.rng
	local d = self.balik.zorluk
	local tip = self.balik.hareket
	local smooth = tip == "smooth"

	if rng:NextNumber() < d * (if smooth then 20 else 1) / 4000 and (not smooth or self._hedef == -1) then
		local asagiBosluk = 548 - self._balik
		local yukariBosluk = self._balik
		local oran = math.min(99, d + sonraki(rng, 10, 45)) / 100
		self._hedef = self._balik + sonraki(rng, math.min(-yukariBosluk, asagiBosluk), asagiBosluk) * oran
	end

	if tip == "floater" then
		self._suzulme = math.max(self._suzulme - 0.01, -1.5)
	elseif tip == "sinker" then
		self._suzulme = math.min(self._suzulme + 0.01, 1.5)
	end

	if math.abs(self._balik - self._hedef) > 3 and self._hedef ~= -1 then
		local ivme = (self._hedef - self._balik) / (sonraki(rng, 10, 30) + (100 - math.min(100, d)))
		self._balikHiz += (ivme - self._balikHiz) / 5
	elseif not smooth and rng:NextNumber() < d / 2000 then
		self._hedef = self._balik + (if rng:NextNumber() < 0.5 then sonraki(rng, -100, -51) else sonraki(rng, 50, 101))
	else
		self._hedef = -1
	end

	if tip == "dart" and rng:NextNumber() < d / 1000 then
		self._hedef = self._balik
			+ (if rng:NextNumber() < 0.5 then sonraki(rng, -100 - d * 2, -51) else sonraki(rng, 50, 101 + d * 2))
	end

	self._hedef = math.clamp(self._hedef, -1, 548)
	self._balik += self._balikHiz + self._suzulme
	self._balik = math.clamp(self._balik, 0, BALIK_ALT)
end

function DigMinigame._barTik(self: Minigame, holding: boolean)
	local boy = self._barBoy
	local ivme = if holding then -BAR_IVME * self.gear.barAcceleration else BAR_IVME

	if holding and (self._barUst == 0 or self._barUst == SUTUN - boy) then
		self._barHiz = 0
	end

	if self._iceride then
		ivme *= BAR_ICERIDE_CARPAN
	end

	self._barHiz += ivme
	self._barUst += self._barHiz

	if self._barUst + boy > SUTUN then
		self._barUst = SUTUN - boy
		self._barHiz = -self._barHiz * SEKME
	elseif self._barUst < 0 then
		self._barUst = 0
		self._barHiz = -self._barHiz * SEKME
	end

	local b = self._balik
	self._iceride = b + 12 <= self._barUst - 32 + boy and b - 16 >= self._barUst - 32
	if b >= 548 - boy and self._barUst >= SUTUN - boy - 4 then
		self._iceride = true
	end
end

function DigMinigame._yansit(self: Minigame)
	local s = self.state
	local boy = self._barBoy

	s.barPosition = 1 - (self._barUst + boy / 2) / SUTUN
	s.barVelocity = -self._barHiz / TIK / SUTUN
	s.barSize = boy / SUTUN

	s.targetPosition = 1 - (self._balik + 30) / SUTUN
	s.targetVelocity = -(self._balikHiz + self._suzulme) / TIK / SUTUN
	s.inside = self._iceride
end

function DigMinigame.step(self: Minigame, dt: number, holding: boolean): State
	local s = self.state
	if s.finished then
		return s
	end

	self._birikim += dt
	while self._birikim >= TIK do
		self._birikim -= TIK

		self:_balikTik()
		self:_barTik(holding)

		if self._iceride then
			s.progress += self.gear.progressRate * TIK
		else
			s.progress -= self.gear.drainRate * TIK
		end

		if s.progress >= 1 then
			s.progress = 1
			s.finished = true
			s.won = true
			break
		elseif s.progress <= 0 then
			s.progress = 0
			s.finished = true
			s.won = false
			break
		end
	end

	self:_yansit()
	return s
end

return DigMinigame
