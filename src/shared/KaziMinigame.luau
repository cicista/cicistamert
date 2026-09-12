--!strict
--[[
	KUMDAKI KAZI MINIOYUNU  --  tiklama vs geri tepme

	Dig & Clean mantigi. Tek bir imlec var:

	  - her tiklama imleci ILERI iter (kurek ne kadar iyiyse o kadar cok)
	  - imlec kendiliginden GERI TEPER (rarity ne kadar yuksekse o kadar hizli)
	  - imlec dolarsa brainrot cikar, SIFIRA duserse kacar

	SURE YOK. Oyuncu imlec sifirlanana kadar minioyunda kalir; ne kadar
	dayanabildigi tamamen tiklama hizina bagli.

	--------------------------------------------------------------
	KUREK KADEMEYI ACAR  --  matematiksel olarak

	Saniyede kazanilabilecek EN FAZLA ilerleme:  MAX_CPS * kazanc
	Saniyede kaybedilen ilerleme:                geriTepme

	    geriTepme >= MAX_CPS * kazanc   ->   imlec ASLA dolmaz

	Yani kurek yetmiyorsa oyuncu makro hiziyla tiklasa bile o brainrotu
	alamaz -- zorlanmaz, IMKANSIZDIR. Tablolar bu esik gozetilerek
	ayarlandi; her kurek kademesi tam bir rarity kademesi aciyor:

	    Lv1  Common rahat   Rare zor      Epic+ IMKANSIZ
	    Lv2  Rare rahat     Epic zor      Legendary+ IMKANSIZ
	    Lv3  Epic rahat     Legendary zor Mythic+ IMKANSIZ
	    Lv4  Legendary rahat Mythic zor   Divine IMKANSIZ
	    Lv5  Mythic rahat   Divine zor

	"Zor" = tiklama hizini neredeyse tavanda tutman gerekir.
	--------------------------------------------------------------

	MACRO KORUMASI

	Yukaridaki esigin anlamli olmasi MAX_CPS'in gercekten tavan olmasina
	bagli: otomatik tiklayici saniyede yuzlerce tik gonderebilseydi butun
	kademe duzeni cokerdi.

	JETON KOVASI (token bucket): saniyede en fazla MAX_CPS tiklama SAYILIR,
	kova en fazla BURST jeton biriktirir. Fazla tiklamalar cezalandirilmaz,
	yok sayilir -- makro ile saniyede 100 tiklayan, eliyle MAX_CPS tiklayan
	oyuncudan daha hizli ilerleyemez. Ceza yerine yok saymanin sebebi:
	insan elinin hizli serileri (cift tik, parmak titremesi) haksiz yere
	cezalandirilmasin.

	Sunucu ayrica bagimsiz dogruluyor (bkz. KaziSistemi): erisilemez bir
	kademede gelen zafer ve teorik alt sinirdan hizli biten minioyun
	reddedilir.
]]

local DigMinigame = require(script.Parent.DigMinigame)

local KaziMinigame = {}
KaziMinigame.__index = KaziMinigame

--[[
	Insan elinin ustu. Olcum degil, oynanabilirlik karari: 12 cps hizli bir
	oyuncunun kisa sureli tepe degeri.

	DIKKAT: bu sayi ayni zamanda DENGE esigi. Buyutursen alt kurekler ust
	kademeleri alabilir hale gelir, kucultursen ust kademeler kimse
	tarafindan alinamaz. Degistirirsen asagidaki iki tabloyu da gozden gecir.
]]
KaziMinigame.MAX_CPS = 12

-- Kova kapasitesi: kisa serilerde tiklamalar bosa gitmesin
KaziMinigame.BURST = 4

-- Imlec buradan baslar: oyuncunun toparlanmasi icin kucuk bir pay
KaziMinigame.START = 0.25

--[[
	KUREGE GORE TIKLAMA KAZANCI  (imlecin orani, tiklama basina)

	Kademe basina tavan hiz (MAX_CPS * kazanc):
	    Lv1 0.240   Lv2 0.336   Lv3 0.456   Lv4 0.600   Lv5 0.780
]]
local KAZANC: { [number]: number } = {
	[1] = 0.020,
	[2] = 0.028,
	[3] = 0.038,
	[4] = 0.050,
	[5] = 0.065,
}

--[[
	KADEMEYE GORE GERI TEPME  (imlecin orani, saniye basina)

	Her deger, bir alt kuregin tavan hizinin biraz USTUNDE secildi:
	    Epic 0.25      > Lv1 tavani 0.240   -> Lv1 ile IMKANSIZ
	    Legendary 0.35 > Lv2 tavani 0.336   -> Lv2 ile IMKANSIZ
	    Mythic 0.48    > Lv3 tavani 0.456   -> Lv3 ile IMKANSIZ
	    Secret 0.64    > Lv4 tavani 0.600   -> Lv4 ile IMKANSIZ

	Divine'in kimligi hala "Secret" -- gorunen adi degisti, veri uyumu icin
	kimlik korundu (bkz. Shared > Rarity).
]]
local GERI_TEPME: { [string]: number } = {
	Common = 0.06,
	Rare = 0.13,
	Epic = 0.25,
	Legendary = 0.35,
	Mythic = 0.48,
	Secret = 0.64,
}

export type State = {
	progress: number,
	finished: boolean,
	won: boolean,
	-- Son tiklama makro sinirina takildi mi (arayuz uyarisi icin)
	throttled: boolean,
}

export type Game = typeof(setmetatable(
	{} :: {
		gain: number,
		drain: number,
		state: State,
		_tokens: number,
	},
	KaziMinigame
))

-- Bu kurekle tiklama basina kazanilan ilerleme
function KaziMinigame.gain(gearId: string): number
	local gear = DigMinigame.gear(gearId)
	return KAZANC[gear.level] or KAZANC[1]
end

-- Bu kademenin saniye basina geri tepmesi
function KaziMinigame.drain(rarityId: string): number
	return GERI_TEPME[rarityId] or GERI_TEPME.Common
end

--[[
	Bu kurekle bu kademe ALINABILIR MI?

	Tavan hiz geri tepmeyi gecmiyorsa imlec asla dolmaz; ne kadar hizli
	tiklandiginin onemi yoktur.
]]
function KaziMinigame.reachable(gearId: string, rarityId: string): boolean
	return KaziMinigame.MAX_CPS * KaziMinigame.gain(gearId) > KaziMinigame.drain(rarityId)
end

--[[
	Minioyunun EN HIZLI bitirilebilecegi sure (saniye).
	Erisilemez kademede math.huge doner.

	Sunucu bunu dogrulama esigi olarak kullanir.
]]
function KaziMinigame.minDuration(gearId: string, rarityId: string): number
	local net = KaziMinigame.MAX_CPS * KaziMinigame.gain(gearId) - KaziMinigame.drain(rarityId)
	if net <= 0 then
		return math.huge
	end
	return (1 - KaziMinigame.START) / net
end

function KaziMinigame.new(gearId: string, rarityId: string): Game
	local self = setmetatable({
		gain = KaziMinigame.gain(gearId),
		drain = KaziMinigame.drain(rarityId),
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
	s.progress = math.min(1, s.progress + self.gain)

	if s.progress >= 1 then
		s.finished = true
		s.won = true
	end

	return true
end

--[[
	GERI TEPME

	Sure siniri YOK: oyun yalnizca imlec dolunca (kazanma) ya da sifira
	dusunce (kaybetme) biter. Oyuncu tiklamayi surdurdugu surece minioyunda
	kalir.
]]
function KaziMinigame.step(self: Game, dt: number): State
	local s = self.state
	if s.finished then
		return s
	end

	-- Kova dolar: saniyede MAX_CPS jeton, en fazla BURST
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
