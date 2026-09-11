--!strict
--[[
	Stardew Valley balik minioyunu mantiginin saf (RenderStepped'siz) modeli.

	Dusey bir cubuk boyunca:
	  - "target" brainrot ikonu; rarity'ye gore artan agresiflikte zipzip hareket eder
	  - "bar" oyuncunun kontrol ettigi yesil alan; tus basiliyken yukari, birakinca asagi
	  - target barin icindeyken progress artar, disindayken azalir
	  - progress 1'e ulasirsa kazi basarili, 0'a duserse basarisiz

	EKIPMAN kim ise oyunu o kolaylastirir: KUMDA kurek, DENIZDE olta.
	Ikisi de ayni alanlari tasidigi icin (level / barSize / barAcceleration /
	progressRate / drainRate) burasi hangisi oldugunu bilmek zorunda degil --
	gelen kimlik once kurek tablosunda, bulunamazsa olta tablosunda aranir.

	Brainrot rarity'si escapeDifficulty uzerinden oyunu zorlastirir.

	Bu modul deterministik ve UI'dan bagimsizdir -- ayni step() cagrilari
	client'ta gorsel, server'da dogrulama icin kullanilabilir.
]]

local Rarity = require(script.Parent.Rarity)
local Rods = require(script.Parent.Rods)
local Shovels = require(script.Parent.Shovels)

local DigMinigame = {}
DigMinigame.__index = DigMinigame

-- Cubuk 0..1 normalize koordinatta calisir.
local GRAVITY = 1.6
local LIFT = 3.2
local MAX_BAR_SPEED = 1.4

--[[
	Kurek ve oltanin ORTAK yuzu. Minigame yalnizca bu alanlara bakar;
	esyanin kumda mi denizde mi kullanildigi onu ilgilendirmez.
]]
export type GearInfo = {
	displayName: string,
	level: number,
	-- Minigame oncesi hazirlik suresi carpani (dusuk = hizli)
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
	finished: boolean,
	won: boolean,
}

export type Minigame = typeof(setmetatable({} :: {
	gear: GearInfo,
	difficulty: number,
	rng: Random,
	state: State,
	_targetGoal: number,
	_targetTimer: number,
	_edgeTimer: number,
}, DigMinigame))

--[[
	ELDEKI EKIPMANI BULUR

	Kimlikler cakismiyor (Wooden..Celestial / Bamboo..Leviathan), bu yuzden
	tek bir ada bakmak yetiyor. Hicbiri tutmazsa tahta kurege duser: boylece
	bozuk bir kayit minigame'i cokertmek yerine en zor kademeden oynatir.
]]
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

--[[
	EKIPMAN SEVIYESI TAVANI

	Zorluk yalnizca brainrot'un rarity'sinden gelmez; EKIPMANIN o rarity'ye
	yetip yetmedigi belirleyicidir. Aradaki fark:

	    gap = rarity.order - gear.level

	    gap <= 0   ekipman rarity'ye yetiyor      -> kolay
	    gap == 1   bir kademe yukarisi            -> zorlanir ama alinabilir
	    gap == 2   iki kademe yukarisi            -> cok zor
	    gap >= 3   ekipmanin cok otesi            -> pratikte alinamaz

	Boylece yeni baslayan oyuncu Common ve Rare'i rahat alir, Epic'te
	zorlanir, Legendary'yi tahta kurekle pratikte hic alamaz. Kademe
	yukseldikce ust rarityler sirayla acilir:

	    Lv1  Common/Rare kolay   Epic cok zor      Legendary+ alinamaz
	    Lv2  Rare cok kolay      Epic zorlanir     Legendary cok zor
	    Lv3  Epic kolay          Legendary zorlanir Mythic cok zor
	    Lv4  Legendary kolay     Mythic zorlanir   Secret cok zor
	    Lv5  Mythic kolay        Secret zorlanir

	DENIZDE ayni tablo OLTA icin isler: Bamboo Lv1'dir, Leviathan Lv5.
	Oyuncunun kuregi denizde hicbir sey ifade etmez.
]]
local GAP_MULTIPLIER = {
	[0] = 0.6,
	[1] = 1.7,
	[2] = 3,
}

local function gapMultiplier(gap: number): number
	if gap < 0 then
		-- Ekipman rarity'nin uzerinde: her fazla kademe biraz daha kolaylastirir
		return math.max(0.4, 0.6 + gap * 0.08)
	end
	return GAP_MULTIPLIER[gap] or 4
end

--[[
	Etkin zorluk = rarity'nin kendi kacis zorlugu * ekipman farki carpani.
	Cagiran taraf (magaza ekrani, ipuclari) da bunu kullanabilir.
]]
function DigMinigame.difficultyFor(gearId: string, rarityId: Rarity.RarityId): number
	local gear = DigMinigame.gear(gearId)
	local rarity = Rarity.get(rarityId)

	return rarity.escapeDifficulty * gapMultiplier(rarity.order - gear.level)
end

--[[
	Bir rarity bu ekipmanla pratikte alinabilir mi?
	Arayuz "bununla alamazsin" uyarisi icin kullanir.
]]
function DigMinigame.isReachable(gearId: string, rarityId: Rarity.RarityId): boolean
	local gear = DigMinigame.gear(gearId)
	local rarity = Rarity.get(rarityId)

	return rarity.order - gear.level <= 2
end

--[[
	gearId:   oyuncunun elindeki kurek (kumda) ya da olta (denizde)
	rarityId: kazilan suzmenin / girdabin rarity'si
]]
function DigMinigame.new(gearId: string, rarityId: Rarity.RarityId, seed: number?): Minigame
	local gear = DigMinigame.gear(gearId)

	local self = setmetatable({
		gear = gear,
		difficulty = DigMinigame.difficultyFor(gearId, rarityId),
		rng = Random.new(seed or os.clock() * 1e6),
		state = {
			barPosition = 0.5,
			barVelocity = 0,
			barSize = gear.barSize,
			targetPosition = 0.5,
			targetVelocity = 0,
			progress = 0.42,
			finished = false,
			won = false,
		},
		_targetGoal = 0.5,
		_targetTimer = 0,
		_edgeTimer = 0,
	}, DigMinigame)

	return self
end

-- Hedefin ne siklikta yon degistirdigi ve ne kadar hizli hareket ettigi
-- tamamen rarity'ye baglidir. Mythic bir brainrot cok daha sik ve sert kacar.
--[[
	Hedef kenarda EN FAZLA EDGE_MAX_TIME saniye kalabilir.

	Onceden hedef 0.03 / 0.97 sinirina clamp ediliyordu ve arka arkaya gelen
	rastgele hedefler de disari duserse orada saniyelerce takili kaliyordu.
	Kenarda duran hedefi bar ile kapatmak cok kolay oldugu icin yuksek rarity
	brainrotlar bile rahatca yakalaniyordu.

	Artik kenarda gecen sure olculur; sinir asilinca hedef ZORUNLU olarak ic
	tarafa gonderilir.
]]
local EDGE_LOW = 0.12
local EDGE_HIGH = 0.88
local EDGE_MAX_TIME = 1.5

function DigMinigame._retarget(self: Minigame, dt: number)
	local d = self.difficulty
	local position = self.state.targetPosition

	-- Kenar bolgesinde gecen sureyi olc
	if position <= EDGE_LOW or position >= EDGE_HIGH then
		self._edgeTimer += dt
	else
		self._edgeTimer = 0
	end

	-- Cok uzun kaldiysa beklemeden ic tarafa firlat
	if self._edgeTimer >= EDGE_MAX_TIME then
		self._edgeTimer = 0
		self._targetTimer = self.rng:NextNumber(0.25, 0.5)

		local inward = if position <= EDGE_LOW then 1 else -1
		self._targetGoal = math.clamp(
			position + inward * self.rng:NextNumber(0.3, 0.5),
			0.08,
			0.92
		)
		return
	end

	self._targetTimer -= dt
	if self._targetTimer > 0 then
		return
	end

	-- Yuksek rarity -> daha kisa aralik -> daha sinirli hareket
	local minInterval = math.max(0.12, 0.9 - d * 0.12)
	local maxInterval = math.max(minInterval + 0.1, 1.7 - d * 0.2)
	self._targetTimer = self.rng:NextNumber(minInterval, maxInterval)

	-- Yuksek rarity -> daha uzaga sicrar
	local jump = 0.12 + d * 0.06
	local goal = position + self.rng:NextNumber(-jump, jump)

	-- Kenardaysa yeni hedef ic tarafa dogru egilir; kose kapaninda kalmaz
	if position <= EDGE_LOW then
		goal = math.max(goal, position + jump * 0.35)
	elseif position >= EDGE_HIGH then
		goal = math.min(goal, position - jump * 0.35)
	end

	self._targetGoal = math.clamp(goal, 0.06, 0.94)
end

--[[
	Bir simulasyon adimi.
	dt: gecen sure (saniye)
	holding: oyuncu tusa basili tutuyor mu
	Donen: guncel State
]]
function DigMinigame.step(self: Minigame, dt: number, holding: boolean): State
	local s = self.state
	if s.finished then
		return s
	end

	-- Oyuncunun kontrol ettigi bar
	local accel = if holding then LIFT * self.gear.barAcceleration else -GRAVITY
	s.barVelocity = math.clamp(s.barVelocity + accel * dt, -MAX_BAR_SPEED, MAX_BAR_SPEED)
	s.barPosition += s.barVelocity * dt

	local half = s.barSize * 0.5
	if s.barPosition - half < 0 then
		s.barPosition = half
		s.barVelocity = 0
	elseif s.barPosition + half > 1 then
		s.barPosition = 1 - half
		s.barVelocity = 0
	end

	-- Brainrot ikonu
	self:_retarget(dt)
	local chase = 2.2 + self.difficulty * 0.5
	s.targetVelocity += (self._targetGoal - s.targetPosition) * chase * dt
	s.targetVelocity *= 0.90
	s.targetPosition = math.clamp(s.targetPosition + s.targetVelocity, 0.02, 0.98)

	-- Ilerleme
	local inside = math.abs(s.targetPosition - s.barPosition) <= half
	if inside then
		s.progress += self.gear.progressRate * dt
	else
		s.progress -= self.gear.drainRate * dt
	end

	if s.progress >= 1 then
		s.progress = 1
		s.finished = true
		s.won = true
	elseif s.progress <= 0 then
		s.progress = 0
		s.finished = true
		s.won = false
	end

	return s
end

return DigMinigame
