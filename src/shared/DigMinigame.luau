--!strict
--[[
	OLTA MINIOYUNU  --  Stardew Valley'nin balik oyununun (BobberBar) birebir
	modeli. RenderStepped'siz, UI'dan bagimsiz.

	Dusey bir su sutununda:
	  - BALIK kendi kafasina gore yuzer: ara ara yeni bir hedef secer ve
	    oraya ivmelenir. Zor balik daha sik, daha uzaga ve daha sert gider
	  - BAR oyuncunun: basili tutunca yukari ivmelenir, birakinca duser,
	    kenarlara carpinca geri seker
	  - balik barin icindeyken ilerleme artar, disindayken AZALIR -- hem de
	    artistan HIZLI (Stardew: +0.002 / -0.003 tik basina). Baligi yarim
	    yamalak takip eden kazanamaz
	  - ilerleme 1'e ulasirsa yakalandi, 0'a duserse kacti

	NEDEN BIREBIR STARDEW
	Eski model hizi dt'siz topluyordu (kare hizina bagli, "isik hizi") ve
	ilerleme gerilemenin 2.6 kati oldugu icin bar sabit tutulsa bile balik
	arada bir ustunden gecince oyun kazaniliyordu. Stardew'in dengesi
	yillardir oturmus: kolay balik rahat, efsanevi balik gercekten zor.

	SABIT TIK
	Stardew her seyi saniyede 60 tikle hesaplar. step() gelen dt'yi biriktirip
	1/60'lik tiklerle ilerler; boylece balik 30 FPS'te de 240 FPS'te de ayni
	hizda yuzer ve ayni tohum ayni oyunu uretir.

	Birimler de Stardew'in: sutun 568 piksel, balik 0..532 arasinda
	gezer. Disariya verilen State ise 0..1 (0 = dip, 1 = yuzey).

	ZORLUK NEREDEN GELIR
	  kademe (rarity)  -> baligin zorlugu ve hareket tipi (BALIKLAR tablosu)
	  olta   (Rods)    -> barin boyu, ilerleme / gerileme hizi, bar ivmesi

	Kademe tablosu Stardew'in baliklarina gore: Common bir sazan kadar
	uysal, Infernal ve Abyssal Legend / Glacierfish / Mutant Carp kadar zor.
	Iyi olta bari buyutur, geri kacisi yavaslatir; yani ust kademeler ancak
	ust oltalarla gercekten tutulabilir.

	Dengeyi degistirince tools/zorluk.luau ile bot simulasyonuna bak
	(sabitleri oraya da yaz).
]]

local Rarity = require(script.Parent.Rarity)
local Rods = require(script.Parent.Rods)
local Shovels = require(script.Parent.Shovels)

local DigMinigame = {}
DigMinigame.__index = DigMinigame

------------------------------------------------------------------
-- STARDEW SABITLERI  (piksel, tik)
------------------------------------------------------------------
local TIK = 1 / 60

-- Sutunun boyu ve baligin (~36 px) gezebildigi en alt nokta
local SUTUN = 568
local BALIK_ALT = 532

-- Bar yercekimi / kaldirma (tik basina hiz degisimi)
local BAR_IVME = 0.25
-- Balik bardayken bar agirlasir (daha yavas ivmelenir): tutmak kolaylasir
local BAR_ICERIDE_CARPAN = 0.6
-- Kenara carpan bar hizinin bu kadariyla geri seker
local SEKME = 2 / 3

-- Oyun bu ilerlemeyle baslar
local BASLANGIC = 0.3

--[[
	HAREKET TIPLERI  (Stardew'in motionType'i)

	  mixed   -- klasik: ara ara yeni hedef, bazen kisa ziplamalar
	  smooth  -- yalnizca hedefine varinca yenisini secer, ziplamaz; akici
	  floater -- surekli yukari suzulur (yuzeye kacar)
	  sinker  -- surekli dibe cekilir
	  dart    -- sik sik ani, uzun firlamalar; en sinir bozucusu
]]
export type Hareket = "mixed" | "smooth" | "floater" | "sinker" | "dart"

export type BalikAyari = {
	-- Stardew zorlugu: 15 kolay ... 110 efsanevi
	zorluk: number,
	hareket: Hareket,
}

--[[
	KADEME -> BALIK  (Rarity.order ile)

	Stardew karsiliklari:
	  15 mixed   Carp            30 smooth  Bream
	  45 mixed   Largemouth Bass 55 floater Blobfish'in uysali
	  65 mixed   Catfish         75 sinker  Squid
	  82 dart    Mutant Carp     90 mixed   Lava Eel
	  100 mixed  Glacierfish     110 mixed  Legend
]]
DigMinigame.Baliklar = {
	[1] = { zorluk = 15, hareket = "mixed" }, -- Common
	[2] = { zorluk = 30, hareket = "smooth" }, -- Rare
	[3] = { zorluk = 45, hareket = "mixed" }, -- Epic
	[4] = { zorluk = 55, hareket = "floater" }, -- Legendary
	[5] = { zorluk = 65, hareket = "mixed" }, -- Mythic
	[6] = { zorluk = 75, hareket = "sinker" }, -- Divine
	[7] = { zorluk = 82, hareket = "dart" }, -- Cosmic
	[8] = { zorluk = 90, hareket = "mixed" }, -- Secret
	[9] = { zorluk = 100, hareket = "mixed" }, -- Infernal
	[10] = { zorluk = 110, hareket = "mixed" }, -- Abyssal
} :: { [number]: BalikAyari }

--[[
	Kurek ve oltanin ORTAK yuzu. Minigame yalnizca bu alanlara bakar.
]]
export type GearInfo = {
	displayName: string,
	level: number,
	-- Minigame oncesi hazirlik suresi carpani (dusuk = hizli)
	digSpeed: number,
	-- Barin boyu, sutunun orani (Stardew: 96..200 px = 0.17..0.35)
	barSize: number,
	-- Kaldirma carpani (1 = Stardew)
	barAcceleration: number,
	-- Balik icerideyken saniyedeki ilerleme (Stardew: 0.12)
	progressRate: number,
	-- Balik disaridayken saniyedeki gerileme (Stardew: 0.18)
	drainRate: number,
	color: Color3,
}

export type State = {
	-- Barin ORTASI, 0 = dip, 1 = yuzey
	barPosition: number,
	barVelocity: number,
	barSize: number,
	-- Baligin ORTASI, 0 = dip, 1 = yuzey
	targetPosition: number,
	-- Baligin hizi (sutun / saniye, yukari arti); gorsel icin
	targetVelocity: number,
	progress: number,
	-- Son tikte balik barin icinde miydi (oyunun kurali; gorsel bunu kullanir)
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
	-- Stardew'in kendi degiskenleri (piksel, y ASAGI dogru artar)
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

--[[
	ELDEKI EKIPMANI BULUR

	Kimlikler cakismiyor (kurekler / oltalar), bu yuzden tek bir ada bakmak
	yetiyor. Kum kazisi (KaziMinigame) da kuregin seviyesini buradan okur.
	Hicbiri tutmazsa tahta kurege duser: bozuk bir kayit minigame'i
	cokertmez.
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

-- Kademenin baligi; bilinmeyen kademe (Lucky Block vb.) en uysal baliga duser
function DigMinigame.balik(rarityId: string): BalikAyari
	local info = Rarity.Info[rarityId :: Rarity.RarityId]
	local ayar = info and DigMinigame.Baliklar[info.order]
	return ayar or DigMinigame.Baliklar[1]
end

-- Stardew zorlugu (15..110). Arayuz ipuclari icin.
function DigMinigame.difficultyFor(_gearId: string, rarityId: Rarity.RarityId): number
	return DigMinigame.balik(rarityId).zorluk
end

--[[
	Bir kademe bu oltayla makul olcude tutulabilir mi?
	Olta kademesinin iki kati kadar kademe (Lv5 olta: hepsi) "denenebilir".
]]
function DigMinigame.isReachable(gearId: string, rarityId: Rarity.RarityId): boolean
	local gear = DigMinigame.gear(gearId)
	local info = Rarity.Info[rarityId]
	return info == nil or info.order <= gear.level * 2
end

--[[
	En hizli kazanma suresi: balik bastan sona bardayken ilerleme
	BASLANGIC'tan 1'e cikar. Sunucu bundan once gelen zaferi reddeder.
]]
function DigMinigame.minDuration(gearId: string): number
	local gear = DigMinigame.gear(gearId)
	-- Tik yuvarlamasi icin kucuk pay
	return (1 - BASLANGIC) / gear.progressRate - TIK * 2
end

--[[
	gearId:   oyuncunun oltasi
	rarityId: girdabin kademesi
	seed:     sunucudan gelen tohum (ayni tohum = ayni balik hareketi)
]]
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
		-- Stardew'deki gibi bar ve balik dipten baslar, balik barin icinde
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

-- Stardew'in Random.Next(a, b)'si: a dahil, b HARIC tam sayi
local function sonraki(rng: Random, a: number, b: number): number
	a = math.floor(a)
	b = math.floor(b)
	if b - 1 <= a then
		return a
	end
	return rng:NextInteger(a, b - 1)
end

--[[
	BALIK  (Stardew BobberBar.update, balik kismi)
]]
function DigMinigame._balikTik(self: Minigame)
	local rng = self.rng
	local d = self.balik.zorluk
	local tip = self.balik.hareket
	local smooth = tip == "smooth"

	-- Yeni hedef: zor balik daha sik secer ve daha uzaga gider
	if rng:NextNumber() < d * (if smooth then 20 else 1) / 4000 and (not smooth or self._hedef == -1) then
		local asagiBosluk = 548 - self._balik
		local yukariBosluk = self._balik
		local oran = math.min(99, d + sonraki(rng, 10, 45)) / 100
		self._hedef = self._balik + sonraki(rng, math.min(-yukariBosluk, asagiBosluk), asagiBosluk) * oran
	end

	-- Yuzen / batan: surekli bir yone suzulme (y asagi arti)
	if tip == "floater" then
		self._suzulme = math.max(self._suzulme - 0.01, -1.5)
	elseif tip == "sinker" then
		self._suzulme = math.min(self._suzulme + 0.01, 1.5)
	end

	if math.abs(self._balik - self._hedef) > 3 and self._hedef ~= -1 then
		-- Hedefe ivmelen: zor balik daha sert (bolen kuculur)
		local ivme = (self._hedef - self._balik) / (sonraki(rng, 10, 30) + (100 - math.min(100, d)))
		self._balikHiz += (ivme - self._balikHiz) / 5
	elseif not smooth and rng:NextNumber() < d / 2000 then
		-- Kisa zipla
		self._hedef = self._balik + (if rng:NextNumber() < 0.5 then sonraki(rng, -100, -51) else sonraki(rng, 50, 101))
	else
		self._hedef = -1
	end

	-- Dart: ani, uzun firlama
	if tip == "dart" and rng:NextNumber() < d / 1000 then
		self._hedef = self._balik
			+ (if rng:NextNumber() < 0.5 then sonraki(rng, -100 - d * 2, -51) else sonraki(rng, 50, 101 + d * 2))
	end

	self._hedef = math.clamp(self._hedef, -1, 548)
	self._balik += self._balikHiz + self._suzulme
	self._balik = math.clamp(self._balik, 0, BALIK_ALT)
end

--[[
	BAR  (Stardew BobberBar.update, bar kismi)
]]
function DigMinigame._barTik(self: Minigame, holding: boolean)
	local boy = self._barBoy
	local ivme = if holding then -BAR_IVME * self.gear.barAcceleration else BAR_IVME

	-- Kenara dayanmis bar basilinca yapisik kalmasin, temiz kalksin
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

	-- Balik barda mi (Stardew'in kenar paylariyla)
	local b = self._balik
	self._iceride = b + 12 <= self._barUst - 32 + boy and b - 16 >= self._barUst - 32
	-- Balik dipte, bar da dipteyse icerde sayilir
	if b >= 548 - boy and self._barUst >= SUTUN - boy - 4 then
		self._iceride = true
	end
end

-- Piksel degiskenlerini disariya verilen 0..1 State'e cevirir
function DigMinigame._yansit(self: Minigame)
	local s = self.state
	local boy = self._barBoy

	s.barPosition = 1 - (self._barUst + boy / 2) / SUTUN
	s.barVelocity = -self._barHiz / TIK / SUTUN
	s.barSize = boy / SUTUN

	--[[
		Gorselde "balik barin icinde" ile oyunun kurali birebir tutsun
		diye baligin ekrandaki yeri Stardew'in icerde olcusune gore
		kaydirilir: kural balik ustu [barUst - 16, barUst + boy - 44]
		araligini istiyor, yani ekrandaki ortasi (balik + 30) barin
		kenarlarindan 14'er piksel icerde kaldigi surece icerde.
	]]
	s.targetPosition = 1 - (self._balik + 30) / SUTUN
	s.targetVelocity = -(self._balikHiz + self._suzulme) / TIK / SUTUN
	s.inside = self._iceride
end

--[[
	Bir simulasyon adimi.
	dt: gecen sure (saniye); icerde 1/60'lik tiklere bolunur
	holding: oyuncu tusa basili tutuyor mu
	Donen: guncel State
]]
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
