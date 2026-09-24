--!strict
--[[
	OLTA (Fishing Rod) seviyeleri.

	DENIZIN KUREGI VE GPS'I BIR ARADA.

	Karada iki ayri esya var: GPS suzmeyi bulur, kurek minigame'i belirler.
	Denizde ikisini de OLTA yapar:

	  luck        -> yuksek rarity girdap cikma sansini carpar   (GPS isi)
	  scanRadius  -> etrafta girdap aranan yaricap               (GPS isi)
	  spawnChance -> her taramada girdap cikma yuzdesi           (GPS isi)
	  maxWhirls   -> ayni anda kac girdap durabilir              (GPS isi)

	  digSpeed / barSize / barAcceleration / progressRate / drainRate
	              -> yakalama minigame'inin kolayligi            (KUREK isi)

	Minigame degerleri kuregin kademe egrisiyle BIRE BIR ayni: Lv1 olta Lv1
	kurek kadar zorlanir, Lv5 olta Lv5 kurek kadar rahat yakalar. Boylece
	denizde kuregin seviyesi hic isin icine girmez -- Bamboo ile Mythic
	girdap, tahta kurekle Mythic brainrot kadar zordur.

	Kurek ve dedektorde oldugu gibi tek olta tasinir, sirayla yukseltilir;
	alinan kademeler kalici, saticidan istenilen zaman geri kusanilir.
]]

local Rods = {}

export type RodId = "Bamboo" | "Steel" | "Carbon" | "Abyssal" | "Leviathan"

export type RodInfo = {
	id: RodId,
	displayName: string,
	level: number,
	rarity: string,
	price: number,
	-- Yuksek rarity girdaplarin agirlik carpani (1 = etkisiz)
	luck: number,
	-- Girdaplarin dogdugu ve istemciye gonderildigi yaricap (stud).
	-- Girdaplar birbirinden cok uzak durdugu icin bu sayi genis olmali:
	-- yaricapin disinda dogan girdap istemciye hic gitmez, gorunmez olur.
	scanRadius: number,
	spawnChance: number,
	maxWhirls: number,
	-- Minigame oncesi hazirlik suresi carpani (dusuk = hizli)
	digSpeed: number,
	-- Minigame: oyuncunun kontrol ettigi yesil barin yuksekligi
	barSize: number,
	-- Minigame: bar ivmesi; yuksek olan kontrolu kolaylastirir
	barAcceleration: number,
	-- Minigame: hedef bar icindeyken ilerleme hizi
	progressRate: number,
	-- Minigame: hedef bar disindayken gerileme hizi
	drainRate: number,
	color: Color3,
}

--[[
	ILK OLTANIN SARTI

	Deniz adalarin devami: ilk olta ancak son ada kuregi (Lv20) alininca
	satin alinabilir. Sonraki oltalarda sart yok (zaten sirayla alinir).
]]
Rods.RequiredShovelLevel = 20

Rods.Order = { "Bamboo", "Steel", "Carbon", "Abyssal", "Leviathan" } :: { RodId }

Rods.Info = {
	Bamboo = {
		id = "Bamboo",
		displayName = "Bamboo Rod",
		level = 1,
		rarity = "Common",
		price = 1_500_000_000_000,
		luck = 1,
		scanRadius = 165,
		spawnChance = 35,
		maxWhirls = 4,
		digSpeed = 1,
		barSize = 0.22,
		barAcceleration = 1.15,
		-- 5 kat uzun (eski 0.42 / 0.16): oran ayni, zorluk degismez
		progressRate = 0.084,
		drainRate = 0.032,
		color = Color3.fromRGB(190, 160, 95),
	},

	Steel = {
		id = "Steel",
		displayName = "Steel Rod",
		level = 2,
		rarity = "Rare",
		price = 1_850_000_000_000,
		luck = 1.6,
		scanRadius = 190,
		spawnChance = 42,
		maxWhirls = 5,
		digSpeed = 0.85,
		barSize = 0.26,
		barAcceleration = 1.25,
		-- 5 kat uzun (eski 0.48 / 0.14): oran ayni, zorluk degismez
		progressRate = 0.096,
		drainRate = 0.028,
		color = Color3.fromRGB(150, 170, 195),
	},

	Carbon = {
		id = "Carbon",
		displayName = "Carbon Rod",
		level = 3,
		rarity = "Epic",
		price = 2_200_000_000_000,
		luck = 2.4,
		scanRadius = 215,
		spawnChance = 50,
		maxWhirls = 6,
		digSpeed = 0.7,
		barSize = 0.30,
		barAcceleration = 1.40,
		-- 5 kat uzun (eski 0.55 / 0.12): oran ayni, zorluk degismez
		progressRate = 0.11,
		drainRate = 0.024,
		color = Color3.fromRGB(120, 90, 220),
	},

	Abyssal = {
		id = "Abyssal",
		displayName = "Abyssal Rod",
		level = 4,
		rarity = "Legendary",
		price = 2_600_000_000_000,
		luck = 3.6,
		scanRadius = 240,
		spawnChance = 58,
		maxWhirls = 7,
		digSpeed = 0.55,
		barSize = 0.34,
		barAcceleration = 1.55,
		-- 5 kat uzun (eski 0.62 / 0.1): oran ayni, zorluk degismez
		progressRate = 0.124,
		drainRate = 0.02,
		color = Color3.fromRGB(255, 225, 130),
	},

	Leviathan = {
		id = "Leviathan",
		displayName = "Leviathan Rod",
		level = 5,
		rarity = "Mythic",
		price = 3_000_000_000_000,
		luck = 5.5,
		scanRadius = 270,
		spawnChance = 66,
		maxWhirls = 8,
		digSpeed = 0.4,
		barSize = 0.40,
		barAcceleration = 1.75,
		-- 5 kat uzun (eski 0.72 / 0.08): oran ayni, zorluk degismez
		progressRate = 0.144,
		drainRate = 0.016,
		color = Color3.fromRGB(255, 70, 90),
	},
} :: { [RodId]: RodInfo }

--[[
	ELDEKI OLTA

	Tool DEGIL: hotbarda gorunmesin ve elden birakilamasin diye parcalar
	dogrudan sag ele kaynaklanan bir Model olarak duruyor. Asagidaki ad hem
	o modelin adi hem de "elinde olta var mi" kontrolunun anahtari.
]]
Rods.ToolName = "Fishing Rod"

-- Misinanin ucundaki nokta; kanca cizgisi buraya baglanir
Rods.TipName = "OltaUcu"

-- Atilan misinayi tutan gorunmez parcanin adi
Rods.LineName = "OltaMisinasi"

--[[
	SAVURMA ZAMANLAMASI

	Girdaba tiklayinca minigame ANINDA acilmaz: once olta savrulur.
	Uc sayi var, hepsi ayni 1.25 saniyenin icinde gecer:

	  0.00  tiklandi, savurma animasyonu basladi -- misina gorunmez
	  0.75  CastRelease  -- savurma one geldi, MISINA BIRAKILDI
	  1.25  CastFlight bitti -- samandira girdabin ortasina dustu
	  1.25  CastTime -- minigame penceresi acilir

	CastTime elle yazilmaz, CastRelease + CastFlight olarak hesaplanir:
	pencere her zaman misinanin suya dustugu anda acilir. Savurma
	animasyonunun suresini degistirirsen YALNIZCA CastRelease'i guncelle,
	gerisi kendiliginden uyar.

	Kum kazisindan farkli: orada bekleme suresini kurek belirliyor
	(Config.Dig.prepareTime * digSpeed), denizde ise animasyon belirliyor,
	yani olta kademesi bu sureyi degistirmez.
]]

-- Misinanin birakildigi an: savurma animasyonunun (RodCast, 1.733 sn) 0.75. saniyesi
Rods.CastRelease = 0.75

-- Misinanin havada gecirdigi sure: oltanin ucundan girdabin ortasina
Rods.CastFlight = 0.5

-- Misina ve ucundaki samandiranin neon rengi
Rods.LineColor = Color3.fromRGB(60, 255, 230)

-- Tiklamayla minigame penceresinin acilmasi arasindaki toplam sure
Rods.CastTime = Rods.CastRelease + Rods.CastFlight

function Rods.get(id: string?): RodInfo?
	if not id then
		return nil
	end
	return Rods.Info[id :: RodId]
end

function Rods.exists(id: string?): boolean
	return Rods.get(id) ~= nil
end

-- Kademe sirasi; oltasi olmayan icin 0
function Rods.level(id: string?): number
	local info = Rods.get(id)
	return if info then info.level else 0
end

return Rods
