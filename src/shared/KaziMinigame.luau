--!strict
--[[
	KUMDAKI KAZI MINIOYUNU  --  tiklama tabanli

	Dig & Clean mantigi: oyuncu tikladikca bar dolar, tiklamayi birakinca
	geri kacar. Zorluk arttikca gereken tiklama sayisi artar.

	  - her tiklama ilerlemeye 1/gerekenTiklama ekler
	  - tiklanmadigi her saniye KUREGIN drainRate'i kadar geri gider
	  - bar dolarsa brainrot cikar, sure biterse kacar

	DENIZDEKI minioyun bu DEGIL: orada Stardew tarzi bar/hedef oyunu var
	(bkz. Shared > DigMinigame). Kumda kurek, denizde olta belirleyici.

	--------------------------------------------------------------
	MACRO KORUMASI

	Otomatik tiklayici saniyede yuzlerce tik gonderebilir; onlemezsen kazi
	minioyunu bir tus makrosuyla aninda gecilir.

	Burada JETON KOVASI (token bucket) kullaniliyor: saniyede en fazla
	MAX_CPS tiklama SAYILIR, kova en fazla BURST jeton biriktirir. Fazla
	tiklamalar cezalandirilmaz, yok sayilir -- yani makro ile saniyede 100
	tiklayan, eliyle MAX_CPS tiklayan oyuncudan daha hizli bitiremez.

	Ceza yerine yok saymanin sebebi: insan eliyle atilan hizli seriler
	(double-click, parmak titremesi) haksiz yere cezalandirilmasin.

	Sunucu ayrica ALT SINIR suresini dogruluyor (bkz. KaziSistemi): gereken
	tiklama MAX_CPS ile bile bu sureden once bitirilemez, daha erken "kazandim"
	diyen istemci reddedilir.
	--------------------------------------------------------------
]]

local DigMinigame = require(script.Parent.DigMinigame)
local Rarity = require(script.Parent.Rarity)

local KaziMinigame = {}
KaziMinigame.__index = KaziMinigame

--[[
	Insan elinin ustu. Olcum degil, oynanabilirlik karari: 12 cps hizli bir
	oyuncunun kisa sureli tepe degeri. Buyutursen makro avantaji artar,
	kucultursen hizli oyuncu cezalandirilmis olur.
]]
KaziMinigame.MAX_CPS = 12

-- Kova kapasitesi: kisa serilerde tiklamalar bosa gitmesin
KaziMinigame.BURST = 4

--[[
	KADEMEYE GORE TABAN TIKLAMA

	Kurek rarity'ye tam yetiyorken gereken tiklama sayisi. Kurek geride
	kaldikca asagidaki carpanla buyur.

	Divine'in kimligi hala "Secret" -- gorunen adi degisti, veri uyumu icin
	kimlik korundu (bkz. Shared > Rarity).
]]
local TABAN_TIKLAMA: { [string]: number } = {
	Common = 8,
	Rare = 12,
	Epic = 18,
	Legendary = 26,
	Mythic = 36,
	Secret = 50,
}

--[[
	KUREK FARKI

	gap = rarity.order - kurek.level

	  gap <= 0   kurek yetiyor          -> daha az tiklama
	  gap == 1   bir kademe yukarisi    -> zorlanir
	  gap == 2   iki kademe yukarisi    -> cok zor
	  gap >= 3   kuregin cok otesi      -> pratikte bitirilemez

	Bar oyunundaki (DigMinigame) kademe mantiginin aynisi; orada hedefin
	kacis agresifligini, burada gereken tiklama sayisini belirliyor.
]]
local GAP_CARPANI: { [number]: number } = {
	[0] = 0.7,
	[1] = 1.5,
	[2] = 2.4,
}

local function gapCarpani(gap: number): number
	if gap < 0 then
		-- Kurek rarity'nin uzerinde: her fazla kademe biraz daha kolaylastirir
		return math.max(0.45, 0.7 + gap * 0.08)
	end
	return GAP_CARPANI[gap] or 4
end

export type State = {
	progress: number,
	clicks: number,
	required: number,
	timeLeft: number,
	finished: boolean,
	won: boolean,
	-- Son tiklama makro sinirina takildi mi (arayuz uyarisi icin)
	throttled: boolean,
}

export type Game = typeof(setmetatable(
	{} :: {
		required: number,
		drain: number,
		duration: number,
		state: State,
		_tokens: number,
	},
	KaziMinigame
))

--[[
	Bu kurekle bu rarity icin gereken tiklama sayisi.
	Arayuz de (magaza ipuclari) ayni sayiyi gosterebilsin diye disarida.
]]
function KaziMinigame.requiredClicks(gearId: string, rarityId: string): number
	local gear = DigMinigame.gear(gearId)
	local info = Rarity.Info[rarityId]

	local taban = TABAN_TIKLAMA[rarityId] or 10
	local order = if info then info.order else 1

	return math.max(4, math.ceil(taban * gapCarpani(order - gear.level)))
end

--[[
	Bu kurek ve rarity icin minioyunun EN HIZLI bitirilebilecegi sure.
	Sunucu bunu dogrulama esigi olarak kullanir.
]]
function KaziMinigame.minDuration(gearId: string, rarityId: string): number
	return KaziMinigame.requiredClicks(gearId, rarityId) / KaziMinigame.MAX_CPS
end

function KaziMinigame.new(gearId: string, rarityId: string): Game
	local gear = DigMinigame.gear(gearId)
	local required = KaziMinigame.requiredClicks(gearId, rarityId)

	--[[
		SURE

		En hizli bitis suresinin katı. Insan eliyle rahat yetisilecek kadar
		bol, ama kurek yetmiyorken (tiklama sayisi katlanmisken) yine de
		bitirilemeyecek kadar dar.
	]]
	local duration = math.clamp(required / KaziMinigame.MAX_CPS * 2.4, 5, 20)

	local self = setmetatable({
		required = required,
		--[[
			Tiklanmadiginda saniyede ne kadar geri gider. Kuregin kendi
			drainRate'i kullaniliyor (0.16 tahta -> 0.08 Celestial): iyi
			kurek hem daha az tiklama ister hem daha yavas geri kacar.
		]]
		drain = gear.drainRate,
		duration = duration,
		_tokens = KaziMinigame.BURST,
		state = {
			progress = 0,
			clicks = 0,
			required = required,
			timeLeft = duration,
			finished = false,
			won = false,
			throttled = false,
		},
	}, KaziMinigame)

	return self
end

--[[
	BIR TIKLAMA

	Sayilirsa true, makro sinirina takilirsa false doner. Cagiran taraf
	false'u yalnizca gorsel uyari icin kullanir; oyun akisi degismez.
]]
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
	s.clicks += 1
	s.progress = math.min(1, s.progress + 1 / self.required)

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

	-- Kova dolar: saniyede MAX_CPS jeton, en fazla BURST
	self._tokens = math.min(KaziMinigame.BURST, self._tokens + dt * KaziMinigame.MAX_CPS)

	-- Tiklanmayan her an ilerleme geri kacar
	s.progress = math.max(0, s.progress - self.drain * dt)

	s.timeLeft = math.max(0, s.timeLeft - dt)
	if s.timeLeft <= 0 then
		s.finished = true
		s.won = false
	end

	return s
end

return KaziMinigame
