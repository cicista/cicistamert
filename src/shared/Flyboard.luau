--!strict
--[[
	FLYBOARD  --  denizde binilen su jeti tahtasi

	5 kademe; her kademe bir rarity rengi tasir:
	    1 Beyaz  2 Yesil  3 Mavi  4 Mor  5 Kirmizi

	Kurek ve dedektorle ayni kural: oyuncu TEK flyboard tasir, sirayla
	yukseltir (bir ust kademeyi almadan ustunu alamaz). Satin alma
	FlyboardSeller NPC'sinde.

	CALISMA SEKLI
	Oyuncu denize girdiginde envanterinde flyboard varsa kendiliginden
	binilir; denizden cikildiginda Physics.dismountDelay saniye icinde
	inilir. Binerken:
	  - karakter denizin Physics.hoverHeight kadar ustunde durur
	  - Space ile en fazla Physics.riseLimit stud yukselir, Shift ile iner
	    (taban yukseklige kadar; daha asagi inilemez)
	  - ziplama kapalidir
	  - yurume hizi kademenin speedBonus orani kadar artar (%10 .. %30)
	  - gidilen yone dogru Physics.tiltAngle derece yatar
]]

local Flyboard = {}

export type FlyboardId = "Basic" | "Wave" | "Storm" | "Nebula" | "Inferno"

export type FlyboardInfo = {
	id: FlyboardId,
	displayName: string,
	level: number,
	rarity: string,
	price: number,
	-- Tahtanin ve efektlerinin rengi (rarity rengi degil, kademeye ozel)
	color: Color3,
	--[[
		TAHTANIN KENDI VFX'ININ GUCU

		Workspace'teki Flyboard modelinin Bottom noktalarinda hazir Lightning
		ve ParticleEmitter'lar var. Bu carpan onlarin boyunu, hizini ve
		yayilma sikligini olcekler: 1. kademe oldugu gibi, son kademe cok
		daha coskun gorunur.
	]]
	-- Yurume hizina eklenen oran (0.1 = %10)
	speedBonus: number,
	vfxScale: number,
	--[[
		KADEMEYE OZEL RENK GECISI (istege bagli)

		Verilmezse gecis kademenin renginden hesaplanir (acik/koyu tonlari).
		Verilirse gecisin iki ucu dogrudan bunlar olur -- Inferno'nun ates
		gecisi boyle yapiliyor.
	]]
	rampLight: Color3?,
	rampDark: Color3?,
}

Flyboard.Order = { "Basic", "Wave", "Storm", "Nebula", "Inferno" } :: { FlyboardId }

Flyboard.Info = {
	Basic = {
		id = "Basic",
		displayName = "Basic Flyboard",
		level = 1,
		rarity = "Common",
		price = 600_000_000_000,
		-- Duz beyaz degil: buzlu, mavimsi bir beyaz
		color = Color3.fromRGB(225, 240, 255),
		speedBonus = 0.1,
		vfxScale = 1,
		-- Parlak beyazdan celik mavisine
		rampLight = Color3.fromRGB(255, 255, 255),
		rampDark = Color3.fromRGB(105, 140, 180),
	},

	Wave = {
		id = "Wave",
		displayName = "Wave Flyboard",
		level = 2,
		rarity = "Rare",
		price = 650_000_000_000,
		-- Doygun zumrut yesili
		color = Color3.fromRGB(40, 230, 110),
		speedBonus = 0.15,
		vfxScale = 1.4,
		-- Limondan koyu zumrute
		rampLight = Color3.fromRGB(185, 255, 130),
		rampDark = Color3.fromRGB(8, 105, 55),
	},

	Storm = {
		id = "Storm",
		displayName = "Storm Flyboard",
		level = 3,
		rarity = "Epic",
		price = 850_000_000_000,
		-- Elektrik mavisi
		color = Color3.fromRGB(30, 140, 255),
		speedBonus = 0.2,
		vfxScale = 1.9,
		-- Camgobeginden gece lacivertine
		rampLight = Color3.fromRGB(150, 235, 255),
		rampDark = Color3.fromRGB(10, 45, 155),
	},

	Nebula = {
		id = "Nebula",
		displayName = "Nebula Flyboard",
		level = 4,
		rarity = "Legendary",
		price = 1_000_000_000_000,
		-- Doygun galaksi moru
		color = Color3.fromRGB(170, 60, 255),
		speedBonus = 0.25,
		vfxScale = 2.5,
		-- Cirtlak pembeden derin menekseye
		rampLight = Color3.fromRGB(255, 130, 245),
		rampDark = Color3.fromRGB(55, 8, 115),
	},

	Inferno = {
		id = "Inferno",
		displayName = "Inferno Flyboard",
		level = 5,
		rarity = "Mythic",
		price = 1_200_000_000_000,
		-- Soluk kirmizi degil: doygun, yakici bir ton
		color = Color3.fromRGB(255, 40, 25),
		speedBonus = 0.3,
		vfxScale = 3.4,
		--[[
			INFERNO ATES GECISI

			Duz kirmizi sonuk duruyordu. Bu kademe kendi gecisini tasiyor:
			turuncu-sari ucta dogar, kirmiziya doner, koyu kanda soner.
		]]
		rampLight = Color3.fromRGB(255, 180, 40),
		rampDark = Color3.fromRGB(120, 12, 8),
	},
} :: { [FlyboardId]: FlyboardInfo }

--[[
	HARITADAKI MODEL

	Workspace'te (ya da ReplicatedStorage > Assets > VFX icinde) bu adla bir
	MeshPart aranir ve her binis icin KOPYALANIR. Bulunamazsa basit bir
	tahta uretilir; oyun yine calisir.
]]
Flyboard.ModelName = "Flyboard"

--[[
	DENIZ ALGISI

	Once Humanoid'in kendi durumu ve zemin malzemesi (Terrain > Water)
	kontrol edilir. Harita denizi normal parcalarla yapildiysa asagidaki
	adlardan biri de deniz sayilir.
]]
Flyboard.SeaNames = { "deniz", "sea", "ocean", "water", "su" }

--[[
	TAHTANIN VFX AYARLARI

	Studio'daki efekt yuksek LightEmission ile cizilmis: eklemeli (additive)
	parlama renk ne olursa olsun ekranda BEYAZA patliyor ve gozu aliyordu.
	Asagidaki tavanlar onu kisip kademenin rengini one cikariyor.
]]
Flyboard.VFX = {
	-- Parcaciklarin eklemeli parlamasinin tavani (0 = hic, 1 = tam)
	lightEmission = 0.15,
	-- Butun parcaciklara eklenen saydamlik (buyudukce soluklasir)
	extraTransparency = 0.08,
	-- Isiklarin parlaklik tavani
	lightBrightness = 1,
	--[[
		RENK GECISI

		Duz tek renk yerine kademenin renginin ACIK ve KOYU tonlari arasinda
		bir gecis kullaniliyor: parcacik acik tonda dogar, kademe renginden
		gecer, koyu tonda soner. Beyaz hic kullanilmiyor -- beyaz cekirdek
		efektin rengini yutuyordu.

		lightMix: renk beyaza ne kadar yaklassin (0 = hic)
		darkMix : renk siyaha ne kadar yaklassin
	]]
	lightMix = 0.45,
	darkMix = 0.35,
}

Flyboard.Physics = {
	-- Tahtanin olcegi: haritadaki modelin kac kati cizilsin (1 = oldugu gibi)
	boardScale = 0.75,
	-- Tahta denizin kac stud ustunde durur (taban yukseklik)
	hoverHeight = 1,
	-- Space ile taban yukseklige EK olarak cikilabilecek en fazla yukseklik
	riseLimit = 5,
	-- Space / Shift ile saniyede kac stud yukselir ya da alcalir
	riseSpeed = 6,
	-- Kademesi bilinmeyen durumlar icin yedek hiz orani
	speedBonus = 0.2,
	-- Gidilen yone dogru yatma acisi (derece)
	tiltAngle = 25,
	-- Yatmanin ne kadar yumusak oturacagi (saniye)
	tiltSmooth = 0.18,
	-- Denizden cikilinca kac saniye sonra tahtadan inilir
	dismountDelay = 1,
	--[[
		Tahta karakterin KOK PARCASININ kac stud altinda durur.

		R15 karakterde ayaklar kok parcanin yaklasik 3 stud altinda; bu deger
		tahtayi tam ayagin altina oturtur. Yukseklik hesabi da buna dayanir:
		kok parca = deniz + hoverHeight + boardOffset, yani TAHTANIN ALTI
		denizin hoverHeight kadar ustunde kalir.
	]]
	boardOffset = 3,
	--[[
		TAHTASI OLMAYAN OYUNCU

		Suya giren ama flyboardi olmayan oyuncu DALAMAZ: suyun kaldirma
		kuvveti onu yuzeyde tutar. Kuvvet yalnizca asagi dogru calisir, yani
		ziplayip kiyiya cikmasi serbest -- yoksa suya dusen bir daha
		cikamazdi.

		Ustelik suda gecirdigi her noBoardTick saniyede CAN KAYBEDER; deniz
		tahtasiz gezilecek bir yer degil.
	]]
	-- Oyuncu en fazla bu kadar batabilir (yuzeyin kac stud altina)
	noBoardDepth = 0.5,
	noBoardTick = 1,
	-- Her tikta giden can: azami canin orani (0.1 = %10)
	noBoardDamage = 0.1,
	-- Kayip yazisi kac saniye ekranda kalir
	damageTextTime = 0.5,
}

--[[
	KADEMENIN RENK GECISI

	Acik ton -> kademe rengi -> koyu ton. Parcacik, iz ve isinlarda ayni
	gecis kullaniliyor, boylece efektin derinligi oluyor ama rengi hep
	kademenin rengi kaliyor.
]]
function Flyboard.colorRamp(info: FlyboardInfo): ColorSequence
	local V = Flyboard.VFX
	local color = info.color

	-- Kademe kendi uclarini veriyorsa onlar, yoksa renkten hesaplanan tonlar
	local acik = info.rampLight or color:Lerp(Color3.new(1, 1, 1), V.lightMix)
	local koyu = info.rampDark or color:Lerp(Color3.new(0, 0, 0), V.darkMix)

	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, acik),
		ColorSequenceKeypoint.new(0.5, color),
		ColorSequenceKeypoint.new(1, koyu),
	})
end

function Flyboard.get(id: string?): FlyboardInfo?
	if not id then
		return nil
	end
	return Flyboard.Info[id :: FlyboardId]
end

function Flyboard.exists(id: string?): boolean
	return Flyboard.get(id) ~= nil
end

-- Kademe sirasi: sahip olunmayan icin 0
function Flyboard.level(id: string?): number
	local info = Flyboard.get(id)
	return if info then info.level else 0
end

-- Bir sonraki kademe (hepsi alinmissa nil)
function Flyboard.next(id: string?): FlyboardInfo?
	local level = Flyboard.level(id)
	for _, boardId in Flyboard.Order do
		local info = Flyboard.Info[boardId]
		if info.level == level + 1 then
			return info
		end
	end
	return nil
end

--[[
	Bir NESNENIN deniz sayilip sayilmadigi.

	Yalnizca parcanin kendi adina bakmak yetmiyor: harita denizi cogu zaman
	"water" adli bir MODELIN icindeki parcalardan olusuyor ve o parcalarin
	adi "Part", "Mesh" gibi seyler oluyor. Bu yuzden ust klasorlere de
	bakiliyor (Workspace'e kadar).
]]
function Flyboard.isSeaInstance(node: Instance?): boolean
	local cursor = node
	local derinlik = 0

	while cursor and derinlik < 6 do
		if cursor == workspace then
			return false
		end

		if Flyboard.isSeaName(cursor.Name) then
			return true
		end

		cursor = cursor.Parent
		derinlik += 1
	end

	return false
end

-- Bir adin deniz sayilip sayilmadigi (buyuk/kucuk harf onemsiz)
function Flyboard.isSeaName(name: string): boolean
	local lower = string.lower(name)
	for _, sea in Flyboard.SeaNames do
		if lower == sea or string.find(lower, sea, 1, true) then
			return true
		end
	end
	return false
end

return Flyboard
