--!strict
--[[
	KUMDAKI KAZI MINIOYUNU  --  tiklama vs geri tepme

	Dig & Clean mantigi. Tek bir imlec var:

	  - her tiklama imleci ILERI iter
	  - imlec kendiliginden GERI TEPER
	  - imlec dolarsa brainrot cikar, SIFIRA duserse kacar

	SURE YOK. Oyuncu imlec sifirlanana kadar minioyunda kalir; ne kadar
	dayanabildigi tamamen tiklama hizina bagli.

	--------------------------------------------------------------
	ZORLUK YALNIZCA FARKA BAGLI

	    fark = rarity.order - kurek.level

	Yani "Lv2 kurekle Epic" ile "Lv3 kurekle Legendary" tamamen ayni
	zorluktadir. Kurek yukseldikce ayni merdiven bir kademe yukari kayar.

	Zorlugun olcusu TIKLAMA HIZI: imleci yerinde tutmak (ne ilerlemek ne
	gerilemek) icin saniyede kac tiklama gerektigi.

	    fark  gereken hiz   his          tavan hiza (12) gore
	    -2       1.8 cps    cok cok kolay      %15
	    -1       2.7 cps    cok kolay          %22
	     0       4.0 cps    kolay              %33
	     1       6.0 cps    normal             %50
	     2       9.0 cps    zor                %75
	     3      13.5 cps    IMKANSIZ           tavanin USTUNDE

	Fark 3 olunca gereken hiz insan elinin ustundedir: imlec matematiksel
	olarak dolamaz. Oyuncu makro hiziyla tiklasa bile o brainrotu alamaz.

	KUREGE GORE TABLO
	    Lv1   Common kolay   Rare normal      Epic zor        Legendary+ YOK
	    Lv2   Common c.kolay Rare kolay       Epic normal     Legendary zor    Mythic+ YOK
	    Lv3   Rare c.kolay   Epic kolay       Legendary normal Mythic zor      Divine YOK
	    Lv4   Epic c.kolay   Legendary kolay  Mythic normal   Divine zor
	    Lv5   Legendary c.kolay Mythic kolay  Divine normal
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
local Rarity = require(script.Parent.Rarity)

local KaziMinigame = {}
KaziMinigame.__index = KaziMinigame

--[[
	Insan elinin ustu. Olcum degil, oynanabilirlik karari: 12 cps hizli bir
	oyuncunun kisa sureli tepe degeri.

	DIKKAT: bu sayi ayni zamanda DENGE esigi. "Fark 3 = imkansiz" kurali
	13.5 > 12 oldugu icin isliyor. Buyutursen alt kurekler ust kademeleri
	alabilir hale gelir. Tablo elle yazildigi icin (bkz. GEREKEN_CPS) bu
	sayi artik yalnizca TAVAN; imkansizlik esigi IMKANSIZ_FARK ile ayri.
]]
KaziMinigame.MAX_CPS = 12

-- Kova kapasitesi: kisa serilerde tiklamalar bosa gitmesin
KaziMinigame.BURST = 4

--[[
	Imlec buradan baslar: barin yarisindan.

	Iki yone de pay birakir -- oyuncu bastan hem kaybedebilecek hem
	kazanabilecek mesafededir. Minioyunun suresini de bu belirliyor:
	tavan hizda kalan mesafe (1 - START) kadar yol gider.
]]
KaziMinigame.START = 0.5

--[[
	Tiklama basina ilerleme. HER KUREKTE AYNI.

	Kurek gucu bu sayida degil, gereken tiklama hizinda kendini gosteriyor
	(bkz. gerekenCps). Boylece ayni FARK her kurekte ayni sureyi ve ayni
	tempoyu veriyor -- Lv5 ile Divine, Lv1 ile Rare kadar surer.
]]
KaziMinigame.GAIN = 0.03

--[[
	FARKA GORE GEREKEN TIKLAMA HIZI  (imleci yerinde tutmak icin, saniyede)

	Zorlugun tek olcusu bu; geri tepme dogrudan buradan turetiliyor.
	Formul degil ELLE YAZILMIS tablo: kademeler arasi fark istenildigi gibi
	ayarlanabilsin diye.

	    -1  cok kolay
	     0  kolay
	     1  normal
	     2  zor
	     3  IMKANSIZ  (tabloda yok, bkz. IMKANSIZ_FARK)
]]
local GEREKEN_CPS: { [number]: number } = {
	[-2] = 1.5,
	[-1] = 2,
	[0] = 3,
	[1] = 4,
	[2] = 5,
}

--[[
	Bu farktan itibaren kademe ERISILEMEZ.

	Tablodaki en zor deger (5 cps) tavanin (12) epey altinda oldugu icin
	imkansizlik artik sayidan degil BU KURALDAN geliyor. Onceden esik
	formulden cikiyordu (13.5 > 12); tablo elle yazilinca acikca
	belirtilmesi gerekti.
]]
KaziMinigame.IMKANSIZ_FARK = 3

export type State = {
	progress: number,
	finished: boolean,
	won: boolean,
	-- Son tiklama makro sinirina takildi mi (arayuz uyarisi icin)
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

-- Kurek ile kademe arasindaki fark; buyudukce zorlasir
function KaziMinigame.fark(gearId: string, rarityId: string): number
	local gear = DigMinigame.gear(gearId)
	local info = Rarity.Info[rarityId]
	local order = if info then info.order else 1

	return order - gear.level
end
--[[
	Imleci YERINDE tutmak icin gereken tiklama hizi.
	Zorlugun tek olcusu bu; her sey bundan turetiliyor.

	Erisilemez farkta math.huge doner -- boyle bir geri tepmeyi hicbir
	tiklama hizi karsilayamaz.
]]
function KaziMinigame.gerekenCps(gearId: string, rarityId: string): number
	local fark = KaziMinigame.fark(gearId, rarityId)

	if fark >= KaziMinigame.IMKANSIZ_FARK then
		return math.huge
	end

	-- Tablonun altina dusen farklar en kolay degerde kalir
	return GEREKEN_CPS[math.max(fark, -2)] or GEREKEN_CPS[-2]
end

-- Saniye basina geri tepme
function KaziMinigame.drain(gearId: string, rarityId: string): number
	return KaziMinigame.GAIN * KaziMinigame.gerekenCps(gearId, rarityId)
end

--[[
	Bu kurekle bu kademe ALINABILIR MI?

	Gereken hiz tavanin ustundeyse imlec asla dolmaz; ne kadar hizli
	tiklandiginin onemi yoktur.
]]
function KaziMinigame.reachable(gearId: string, rarityId: string): boolean
	return KaziMinigame.gerekenCps(gearId, rarityId) < KaziMinigame.MAX_CPS
end

--[[
	Minioyunun EN HIZLI bitirilebilecegi sure (saniye).
	Erisilemez kademede math.huge doner.

	Sunucu bunu dogrulama esigi olarak kullanir.
]]
function KaziMinigame.minDuration(gearId: string, rarityId: string): number
	local net = KaziMinigame.MAX_CPS * KaziMinigame.GAIN - KaziMinigame.drain(gearId, rarityId)
	if net <= 0 then
		return math.huge
	end
	return (1 - KaziMinigame.START) / net
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
	s.progress = math.min(1, s.progress + KaziMinigame.GAIN)

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
