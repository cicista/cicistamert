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

	    fark  gereken hiz   his                  tavan hiza (12) gore
	  -2 alti    1.5 cps    cok kolay                  %13
	    -1       2.5 cps    kolay                      %21
	     0       4.0 cps    normal                     %33
	     1       5.5 cps    ZOR (en ust kademe)        %46
	     2        --        IMKANSIZ

	Fark 2'den itibaren kademe hic alinamaz: gereken geri tepme tavanin
	kat kat ustune cikarilir, imlec bir saniye icinde dibe iner. Oyuncu
	minioyunu gorur ama alamayacagi hemen belli olur.

	KUREGE GORE TABLO
	    Lv1   Common normal   Rare normal   Epic+ YOK        <- Rare muaf
	    Lv2   Common kolay    Rare normal   Epic ZOR         Legendary+ YOK
	    Lv3   Rare kolay      Epic normal   Legendary ZOR    Mythic+ YOK
	    Lv4   Epic kolay      Legendary normal  Mythic ZOR   Divine YOK
	    Lv5   Legendary kolay Mythic normal     Divine ZOR

	Lv1'in Rare'i tabloya gore ZOR olurdu; baslangic kuregi oldugu icin
	bir basamak muaf tutuluyor (bkz. MUAF_KUREK_LEVEL).
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
local Ores = require(script.Parent.Ores)
local Shovels = require(script.Parent.Shovels)

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
	Formul degil ELLE YAZILMIS tablo: basamaklar istenildigi gibi
	ayarlanabilsin diye.

	    -2 ve alti  cok kolay
	    -1          kolay
	     0          normal
	     1          ZOR  -- ulasilabilen en ust kademe
	     2          IMKANSIZ  (tabloda yok, bkz. IMKANSIZ_FARK)
]]
local GEREKEN_CPS: { [number]: number } = {
	[-2] = 1.5,
	[-1] = 2.5,
	[0] = 4,
	[1] = 5.5,
}

--[[
	BASLANGIC KUREGINE MUAFIYET

	Lv1 tahta kurek oyuncunun eline oyunun ilk dakikasinda geciyor ve tek
	"zor" basamagi Rare oluyordu -- ikinci kazisinda duvara toslamasin diye
	o basamak NORMALE cekiliyor.

	Tek istisna budur; geri kalan her kurekte zorluk yalnizca farka bagli.
]]
local MUAF_KUREK_LEVEL = 1

--[[
	Bu farktan itibaren kademe ERISILEMEZ.

	2'ye cekildi: kurek kademeye IKI basamak geride kalirsa artik hic
	alinamiyor. Oncesinde 3'tu ve Lv2 kurekle Legendary, Lv3 ile Mythic,
	Lv4 ile Divine zor ama mumkundu.

	Tablodaki en zor deger tavanin (12 cps) epey altinda oldugu icin
	imkansizlik sayidan degil BU KURALDAN geliyor.
]]
KaziMinigame.IMKANSIZ_FARK = 2

--[[
	ERISILEMEZ KADEMENIN GERI TEPMESI  (tavanin kati)

	Bu deger ONCE math.huge idi ve imlec ilk karede sifira iniyordu:
	minioyun acilir acilmaz "kacti" diyip kapaniyor, oyuncu ne oldugunu
	anlamiyordu.

	Artik sonlu ama acik ara yetismez bir hiz: imlec tavan hizda tiklansa
	bile bir saniye civarinda dibe iner. Oyuncu minioyunu GORUR ve
	kaybettigini gozuyle gorur -- ama alamayacagi da belli olur.

	Kucultursen dusus yavaslar (bosuna umut verir), buyutursen yine ani
	kapanmaya doner.
]]
KaziMinigame.IMKANSIZ_KATI = 2.5

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

--[[
	Kurek ile kademe arasindaki fark; buyudukce zorlasir.

	Kurekte seviye degil KAZI GUCU kullaniliyor (bkz. Shovels.power): ada
	kureklerinde her 5 seviye bir kademe, yani fark ONDALIKLI olabilir
	(Lv7 ile Divine: 6 - 5.4 = 0.6).
]]
function KaziMinigame.fark(gearId: string, rarityId: string): number
	local gear = DigMinigame.gear(gearId)
	local info = Rarity.Info[rarityId]
	local order = if info then info.order else 1

	local guc = if Shovels.Info[gearId] then Shovels.power(gear.level) else gear.level
	return order - guc
end

--[[
	ERISILEMEZ MI

	Tam sayi farklarda eskisiyle ayni: 2 ve ustu erisilemez. Ondalikli
	farklarda en zor basamagi (1) GECEN her fark erisilemez -- Lv9 ile
	Cosmic (7 - 5.8 = 1.2) alinamaz, Cosmic ancak Lv10'da zor olur.
]]
local function erisilemez(fark: number): boolean
	return fark > KaziMinigame.IMKANSIZ_FARK - 1 + 1e-6
end
--[[
	Imleci YERINDE tutmak icin gereken tiklama hizi.
	Zorlugun tek olcusu bu; her sey bundan turetiliyor.

	Erisilemez farkta math.huge doner -- boyle bir geri tepmeyi hicbir
	tiklama hizi karsilayamaz.
]]
function KaziMinigame.gerekenCps(gearId: string, rarityId: string): number
	-- Maden: kurek/kazma farki yok, sabit hiz (bkz. Shared > Ores)
	local maden = Ores.get(rarityId)
	if maden then
		return maden.cps
	end

	local fark = KaziMinigame.fark(gearId, rarityId)

	--[[
		Erisilemez kademede SONLU ama yetisilemez bir hiz doner. math.huge
		olsaydi imlec ilk karede sifira iner, minioyun acilir acilmaz
		kapanirdi.
	]]
	if erisilemez(fark) then
		return KaziMinigame.MAX_CPS * KaziMinigame.IMKANSIZ_KATI
	end

	--[[
		Baslangic kuregi bir basamak kolaylasir: tek "zor" basamagi
		(Rare) normale iner. Bkz. MUAF_KUREK_LEVEL.
	]]
	if fark > 0 and DigMinigame.gear(gearId).level == MUAF_KUREK_LEVEL then
		fark -= 1
	end

	--[[
		Tablonun altina dusen farklar en kolay degerde kalir. Ondalikli
		farklar (ada kurekleri) iki komsu basamak arasinda oranlanir:
		Lv7 ile Divine (0.6) normal (4) ile zor (5.5) arasinda 4.9 cps.
	]]
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
	-- Maden her kazmayla alinabilir
	if Ores.get(rarityId) then
		return true
	end

	-- Farka DOGRUDAN bakiliyor: gerekenCps artik erisilemezde de sonlu doner
	return not erisilemez(KaziMinigame.fark(gearId, rarityId))
end

--[[
	Minioyunun EN HIZLI bitirilebilecegi sure (saniye).
	Erisilemez kademede math.huge doner.

	Sunucu bunu dogrulama esigi olarak kullanir.
]]
function KaziMinigame.minDuration(gearId: string, rarityId: string): number
	--[[
		Erisilemez kademede math.huge: sunucu boyle bir zaferi dogrudan
		reddeder. Kontrol reachable uzerinden yapiliyor, cunku gerekenCps
		artik erisilemezde de SONLU bir sayi donuyor.
	]]
	if not KaziMinigame.reachable(gearId, rarityId) then
		return math.huge
	end

	local net = KaziMinigame.MAX_CPS * KaziMinigame.GAIN - KaziMinigame.drain(gearId, rarityId)
	if net <= 0 then
		return math.huge
	end

	--[[
		KOVADAKI HAZIR JETONLAR ALT SINIRDAN DUSULUR

		Minioyun kova DOLU baslar: ilk BURST tiklama beklemeden sayilir,
		yani imlec daha ilk karede BURST * GAIN kadar ilerleyebilir. Bu
		ilerleme zaman almadigi icin "en hizli sure" hesabina girmemeli.

		Once girmiyordu ve alt sinir GERCEKTEN ULASILABILIR SUREDEN
		yukari cikiyordu. Ornek (fark 0, normal kademe):

		    eski alt sinir : 0.50 / 0.24 = 2.08 s  ->  %85'i = 1.77 s
		    gercek en hizli: 0.38 / 0.24 = 1.58 s

		Yani basta hizli tiklayip kovayi bosaltan oyuncu 1.58 saniyede
		DOGRU kazaniyor, sunucu ise 1.77 saniyeden once biten zaferi
		reddediyordu. Otomatik tiklayici (bkz. OtoTiklayici) bunu her
		seferinde tetikliyor, hizli tiklayan insan ise ara ara.

		Burst dusuldukten sonra alt sinir gercek tabanin altinda kaliyor;
		KaziSistemi'ndeki %15 pay da uzerine binerek kare dususu ve ag
		gecikmesi payini veriyor.
	]]
	local mesafe = 1 - KaziMinigame.START - KaziMinigame.BURST * KaziMinigame.GAIN
	if mesafe <= 0 then
		-- Kova tek basina bari doldurabiliyor: zaman alt siniri yok
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
