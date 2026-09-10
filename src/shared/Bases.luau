--!strict
--[[
	Oyuncu base'leri.

	Sunucu 6 kisiliktir; Workspace'te 6 adet base platformu bulunur ve
	her oyuncuya katildiginda bos olanlardan biri atanir.

	Base.ler HARITADA elle kurulur; script hicbir parca uretmez.
	Beklenen duzen:
	  Workspace > Bases > Base1..Base6
	     Slot1..Slot10 (BasePart)   -- dogrudan base.in altinda
	     ya da Slots (Folder) > Slot1..Slot10

	Script her base.e sunlari ekler:
	  - her Slot parcasina bir ProximityPrompt (E ile yerlestir / geri al)
	  - base.in onune sahiplik hologrami (nick / EMPTY)
	  - hologramin altina TOPLA butonu (uzerine basinca birikmis rot odenir)

	Brainrot bir slota konuldugunda saniyelik geliri base.te BIRIKIR; sahibinin
	Rot'una ancak TOPLA butonuna basildiginda gecer.
]]

local Workspace = game:GetService("Workspace")

local Bases = {}

Bases.MaxPlayers = 6
Bases.Count = 6

-- Her base.te kac brainrot slotu var (Workspace > Bases > BaseN > Slot1..SlotN)
--[[
	Bir base'te EN FAZLA kac slot olabilir: maxFloors x slotsPerFloor.
	Su an 2 kat x 10 slot. 3. kata gecmek istersen maxFloors'u 3, burayi 30 yap.
	Baslangicta yalnizca 1. kat (10 slot) aciktir; ustu tabeladan satin alinir.
]]
Bases.SlotCount = 20

--[[
	BASE GELISIMI

	1. kat bedava gelir (10 slot). Ustu tabeladan acilir:
	  - KAT acmak Rot ister ve yaninda o kattan 1 slot hediye gelir
	  - o kattaki diger slotlar TEK TEK Rot ile alinir
	  - su an en fazla 2 kat, yani 20 slot

	Haritada yapman gerekenler:
	  Base1 > Kat2 (Model)  -> icinde Slot11..Slot20
	  (3. kat acilirsa: Base1 > Kat3 -> Slot21..Slot30)
	Kilitli katlar oyunda gorunmez, acilinca belirir. Slot parcalarinin
	adi dogru oldugu surece nerede durduklari onemli degil.

	Tabelanin yerini de sen secebilirsin: base'in icine TabelaNoktasi adinda
	bir Part koy, tabela tam oraya kurulur. Koymazsan base'in onune konur.
]]
Bases.Upgrade = {
	slotsPerFloor = 10,
	maxFloors = 2,
	-- Bedava gelen slot sayisi (1. kat)
	startingSlots = 10,
	-- Kat acma bedeli (Rot)
	floorCost = { [2] = 250_000_000_000, [3] = 2_000_000_000_000 },
	-- Kat acilinca o kattan kac slot hediye gelir
	slotsWithFloor = 1,
	-- Tek slot bedeli (Rot). Her alinan slotta slotGrowth katina cikar.
	slotBaseCost = 5_000_000_000,
	slotGrowth = 1.55,
	-- Kilitli kat modellerinin adi: Kat2, Kat3
	floorPrefix = "Kat",
	-- Tabelanin yerini haritada belirleyen isaretci parca
	markerName = "TabelaNoktasi",
	-- Isaretci yoksa: base'in on kenarindan kac stud ileride dursun
	forward = 26,
	size = Vector3.new(18, 11, 0.8),
	-- Parcanin govde rengi (yazinin olmadigi yuzler)
	color = Color3.fromRGB(24, 62, 116),

	--[[
		Tabela paneli. Ustten alta gecisli mavi, kenarinda altin cerceve --
		fiyat yazisinin altin rengiyle ayni aile.
	]]
	panelTop = Color3.fromRGB(52, 126, 210),
	panelBottom = Color3.fromRGB(16, 48, 96),
	panelBorder = Color3.fromRGB(255, 202, 64),

	--[[
		Yazi parcanin hangi yuzune gelsin.
		Kod en genis yuzlerden birini secer; yanlis tarafa geldiyse bunu
		true yap, diger yuze gecer. Baska hicbir sey degistirmen gerekmez.
	]]
	flipFace = true,

	--[[
		Kat acilinca asagidan yukari cikma animasyonu.
		Kat once bu kadar stud asagida belirir ve yerine oturur; oyuna girer
		girmez hazir durmaz, satin alinca gozunun onunde yukselir.
	]]
	riseHeight = 30,
	riseTime = 0.75,
}

-- Bir slot hangi kata ait
function Bases.floorOf(slotIndex: number): number
	return math.ceil(slotIndex / Bases.Upgrade.slotsPerFloor)
end

function Bases.floorModelName(floorIndex: number): string
	return `{Bases.Upgrade.floorPrefix}{floorIndex}`
end

--[[
	Siradaki slotun bedeli.
	unlocked = su an acik olan slot sayisi. Bedava gelen 10 slottan sonrasi
	icin ussel artar: 11. slot temel fiyat, sonrasi her adimda slotGrowth kati.
]]
function Bases.slotCost(unlocked: number): number
	local U = Bases.Upgrade
	local step = math.max(0, unlocked - U.startingSlots)
	return math.floor(U.slotBaseCost * U.slotGrowth ^ step)
end

-- Gelir kac saniyede bir hesaplanir (dusuk deger = daha akici sayac, daha cok is)
Bases.PayoutInterval = 1

--[[
	TOPLA BUTONU

	Yerlestirilen brainrotlarin geliri dogrudan Rot'a gitmez: base'de birikir.
	Oyuncu base'inin onundeki butonun UZERINE BASINCA birikmis rot hesabina
	gecer. Buton haritaya elle konmaz, script uretir (hologram gibi).
]]
--[[
	Butonun yerini haritada elle belirlemek icin kullanilan isaretci parcanin
	adi. Base modelinin altina bu isimde bir Part koyarsan buton TAM ORAYA,
	o parcanin boyutunda kurulur ve asagidaki forward/size degerleri yok
	sayilir. Isaretci yoksa buton otomatik olarak base'in onune konur.
]]
Bases.CollectMarkerName = "ToplaNoktasi"

--[[
	SAHIPLIK HOLOGRAMI

	Base'in onunde havada duran buyuk nick yazisi. Yukseklik base'in
	tepesinden itibaren olculur.

	Onceden 7 studdu ve TOPLA butonunun uzerindeki miktar yazisiyla ust uste
	biniyordu. Yukseltirken asiri kacirmamak lazim: cok yukari cikarsa
	oyuncu base'in onunde dururken yaziyi gormek icin kafasini kaldirmak
	zorunda kalir.
]]
Bases.HologramHeight = 15

-- Para (Rot) miktarlarinin her yerde kullandigi renk
Bases.RotColor = Color3.fromRGB(255, 214, 41)

Bases.CollectPad = {
	-- Butonun boyutu (genislik, kalinlik, derinlik)
	size = Vector3.new(9, 0.6, 9),
	-- Base'in on kenarindan kac stud UZAKTA dursun.
	-- Buyudukce base'den uzaklasir, kucudukce yaklasir; eksi deger butonu
	-- base platformunun uzerine tasir.
	forward = 2,
	-- Ayni oyuncu iki toplama arasinda kac saniye beklesin
	cooldown = 0.5,
	-- Icinde toplanacak rot varken
	color = Color3.fromRGB(70, 210, 120),
	-- Bosken
	idleColor = Color3.fromRGB(90, 100, 115),
}

--[[
	SLOTTAKI BRAINROT GORUNUMU

	rotation: yerlestirilen BUTUN brainrotlara uygulanan duzeltme donusu
	(derece). Model paketi ters eksende export edilmisse burayi degistir --
	kodda hicbir sey degistirmen gerekmez:

	    dik duruyor        -> Vector3.new(0, 0, 0)
	    sirtustu yatiyor   -> Vector3.new(-90, 0, 0)
	    yuzustu yatiyor    -> Vector3.new(90, 0, 0)
	    bas asagi          -> Vector3.new(180, 0, 0)
	    arkasi donuk       -> Vector3.new(0, 180, 0)
	    yan yatmis         -> Vector3.new(0, 0, 90)

	spin: kendi ekseninde donsun mu. Uzun modeller (10 studluk kopekbaligi)
	donerken dagink gorunuyorsa false yap, sabit dursunlar.
]]
Bases.Display = {
	rotation = Vector3.new(0, 0, 0),
	-- Yuzey ile modelin alti arasindaki bosluk.
	-- Model hala plakanin icine giriyorsa bu degeri buyut.
	gap = 0.15,
	spin = true,
	spinSpeed = 0.8,
	-- Havada suzulme yuksekligi (0 = sabit dursun).
	-- Salinim yalnizca yukari dogrudur; model hicbir zaman gap'in altina inmez.
	bobHeight = 0.35,
	bobSpeed = 1.6,
}

-- Base'e erisimi olanlar: sadece sahibi brainrot koyabilir/alabilir.
Bases.OwnerOnlyPlacement = true

-- Base'leri tutan klasorun adi
Bases.FolderName = "Bases"

--[[
	BASE KLASORUNU BULUR

	Klasor Workspace'in DOGRUDAN altinda olmak ZORUNDA DEGIL: harita
	duzenlenirken base'ler cogu zaman adanin modelinin icine tasiniyor.
	Bu iyi bir sey de -- ada tasindiginda base'ler onunla birlikte gider,
	kodda hicbir sey degistirmek gerekmez. O yuzden butun Workspace taranir.

	Birden fazla "Bases" varsa ICI DOLU olan secilir. Eski surumler
	Workspace kokune bos bir klasor birakmis olabiliyor (bulunamayinca
	kendileri olusturuyorlardi); dolu olani tercih etmek o kalintiya
	takilmayi onler.
]]
function Bases.findFolder(): Instance?
	local empty: Instance? = nil

	for _, node in Workspace:GetDescendants() do
		if node.Name ~= Bases.FolderName then
			continue
		end

		if not node:IsA("Folder") and not node:IsA("Model") then
			continue
		end

		if #node:GetChildren() > 0 then
			return node
		end

		empty = empty or node
	end

	return empty
end

function Bases.baseName(index: number): string
	return `Base{index}`
end

function Bases.slotName(index: number): string
	return `Slot{index}`
end

return Bases
