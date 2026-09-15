--[[
	OyunConfig  (ModuleScript)
	Yeri: ReplicatedStorage > Shared > OyunConfig

	Oyunun elle ayarlanan degerleri. Kod bilmeden buradakileri degistirebilirsin.

	NOT: Brainrot listesi, rarity gelirleri, kondisyon carpanlari, kurekler ve
	skinler artik ayri modullerde:
	    Shared > Brainrots     -- brainrot katalogu
	    Shared > Rarity        -- kademeler, isik rengi, saniyelik gelir
	    Shared > Condition     -- boyut carpanlari (Tiny..Huge)
	    Shared > Shovels       -- 5 kurek + minigame zorlugu
	    Shared > Bases         -- base ve slot duzeni
]]

local Config = {}

------------------------------------------------------------------
-- GEMI / ADA NPC AYARLARI
------------------------------------------------------------------
Config.NPC = {
	-- Workspace icindeki NPC modelinin ADI
	name = "Kaptan",
	-- Modeli bu adla da arar; ikisinden biri yeterli
	altName = "Captain",
	promptText = "Travel",
	promptSubText = "Captain",
	promptDistance = 12,
}

------------------------------------------------------------------
-- BRAINROT DETECTIVE NPC
-- Kazilan brainrotlar simsiyah gelir; bu NPC onlari temizler ve
-- hangi brainrot oldugunu ortaya cikarir.
------------------------------------------------------------------
Config.Detective = {
	-- Workspace icindeki NPC modelinin ADI (yoksa otomatik olusturulur)
	name = "BrainrotDetective",
	promptText = "Inspect",
	promptSubText = "Brainrot Detective",
	promptDistance = 12,
	-- NPC yoksa buraya bir stant kurulur
	spawnPosition = Vector3.new(24, 5, -40),
}

------------------------------------------------------------------
-- BRAINROT SATICISI
-- Kullanilmayacak brainrotlari Rot karsiligi satar.
--   E -> elindeki tek brainrotu satar
--   F -> envanterdeki (slota konmamis) butun brainrotlari satar
------------------------------------------------------------------
Config.Seller = {
	-- Workspace icindeki NPC modelinin ADI (yoksa otomatik tezgah kurulur)
	name = "BrainrotSaticisi",
	-- Workspace modelini bu adla da arar; ikisinden biri yeterli
	altName = "RotBuyer",
	promptSubText = "Rot Buyer",
	-- Oyuncu kac stud yaklasinca satis ekrani gorunur
	range = 14,
	spawnPosition = Vector3.new(0, 5, -64),
	-- Satis degeri = brainrot.un saniyelik getirisi * bu carpan
	valueMultiplier = 25,
	-- Kimligi belirlenmemis (siyah) brainrot: rarity.sindeki EN DUSUK gelirli
	-- brainrotun getirisi * bu carpan. Riskli oldugu icin daha dusuk.
	unknownMultiplier = 20,
}

------------------------------------------------------------------
-- ADMIN PANELI
-- Sadece buradaki UserId.ler paneli acabilir.
-- Kendi UserId.ni Roblox profil linkindeki sayidan alabilirsin.
------------------------------------------------------------------
Config.Admin = {
	userIds = {
		-- 123456789,
	},
	-- Studio.da test ederken paneli herkese ac (canlida etkisiz)
	allowInStudio = true,
	-- Panelin acilis tusu
	keyCode = Enum.KeyCode.F2,
	-- "Rot ver" butonunun verecegi miktar (1000 milyar = 1 trilyon)
	rotGrant = 1_000_000_000_000,
}

------------------------------------------------------------------
-- FUSE  --  ILK ADADAKI IKI NPC
--
-- Ikisi de haritada elle konur; script yalnizca ad ile arar. Model
-- bulunamazsa o noktaya basit bir tezgah kurulur (diger NPC'lerdeki gibi).
--
--   Makine  : 3 ayni brainrot alir, %25 ihtimalle bir ust kademe brainrot verir
------------------------------------------------------------------
Config.Fuse = {
	-- MAKINE
	machineName = "FuseMakinesi",
	-- Modeli bu adla da arar; ikisinden biri yeterli
	machineAltName = "FuseMachine",
	machinePromptText = "Insert",
	machinePromptSubText = "Fuse Machine",
	-- Esya koymak icin E'ye BASILI TUTMA suresi
	machineHoldDuration = 0.4,
	machinePromptDistance = 12,
	machineSpawnPosition = Vector3.new(-44, 5, -40),
	--[[
		Panel kac stud yaklasinca gorunur.
		Prompt'tan bagimsizdir: oyuncu yaklasinca ne yapmasi gerektigini
		("Same Rarity Brainrot 0/5") tetiklemeden gorsun diye.
	]]
	machineRange = 18,
}

------------------------------------------------------------------
-- ADALAR
-- LISTEDEKI SIRA = ACILIS SIRASI. Adalar sirayla satin alinir; oyuncu bir
-- adayi acmadan sonrakine gidemez. Sira degistirirsen fiyatlar da artan
-- olmali, yoksa 4. ada 2. adadan ucuz kalir.
-- spawnPartName -> Workspace'te bu isimde Part varsa oraya isinlanir
-- price -> gitmek icin gereken Rot (0 = bedava)
-- luck  -> bilgi amacli; gercek sans carpani ZEMIN adindan gelir
--          (bkz. Config.Sand.luckByName)
------------------------------------------------------------------
Config.Islands = {
	{
		name = "Main Island",
		desc = "Starter island. Luck x1.",
		spawnPartName = "Spawn_AnaAda",
		position = Vector3.new(-1879, 22.9, 107),
		price = 0,
		luck = 1,
		color = Color3.fromRGB(245, 222, 140),
	},
	-- Sira brainrot adalariyla ayni: kum > sekerkum > snowkum > alevkum
	{
		name = "Candy Island",
		desc = "Sticky pink sands. Luck x2. Cosmic brainrots appear here.",
		spawnPartName = "Spawn_Sakiz",
		position = Vector3.new(-990.1, 28.6, -747.5),
		-- Ana adada Epic/Legendary base ile ~1 saat farm
		price = 20_000_000_000,
		luck = 2,
		color = Color3.fromRGB(255, 130, 200),
	},
	{
		name = "Snow Island",
		desc = "Frozen sands. Luck x4. Secret brainrots appear here.",
		spawnPartName = "Spawn_Buz",
		position = Vector3.new(-262.8, 30.5, 709.7),
		price = 120_000_000_000,
		luck = 4,
		color = Color3.fromRGB(140, 220, 245),
	},
	{
		name = "Volcano Island",
		desc = "Scorching sands. Luck x8. Infernal brainrots appear here.",
		spawnPartName = "Spawn_Volkan",
		position = Vector3.new(620.3, 16.3, -34.5),
		price = 1_200_000_000_000,
		luck = 8,
		color = Color3.fromRGB(230, 110, 70),
	},
	{
		-- Henuz oyunda yok: kaptanda "Coming Soon" olarak kilitli durur
		comingSoon = true,
		name = "Coming Soon",
		desc = "A new island is on its way!",
		spawnPartName = "Spawn_Gizli",
		position = Vector3.new(-956.3, 28.6, -738.6),
		price = 8_000_000_000_000,
		luck = 10,
		color = Color3.fromRGB(180, 130, 245),
	},
}

------------------------------------------------------------------
-- KUM ALGILAMA
-- GPS yalnizca kum uzerindeyken calisir, isik suzmeleri sadece kumda cikar.
------------------------------------------------------------------
Config.Sand = {
	materials = {
		[Enum.Material.Sand] = true,
	},
	-- Adinda bu kelimeler gecen Part.lar da kum sayilir
	nameKeywords = { "kum", "sand" },
	-- Oyuncunun ayagindan asagi kac stud isin gonderilir
	rayDepth = 12,

	--[[
		ZEMINE OZEL SANS CARPANI
		Ustunde durulan Part.in adi (kucuk harfe cevrilip) burada aranir.
		Bulunursa o carpan dedektorun sansiyla CARPILIR.
		Yeni bir ada zemini eklemek icin buraya bir satir yazman yeterli.
	]]
	luckByName = {
		-- Main Island (kum) listede yok: x1
		-- Candy Island x2
		sekerkum = 2,
		sakizkum = 2,
		-- Snow Island x4
		snowkum = 4,
		buzkum = 4,
		-- Volcano Island x8
		alevkum = 8,
		volkankum = 8,
	},
}

------------------------------------------------------------------
-- GPS AYARLARI
-- Kumlu alana girince elde otomatik belirir. Etrafta isik suzmeleri arar.
------------------------------------------------------------------
Config.GPS = {
	-- Kac saniyede bir tarama yapilir
	scanInterval = 1.5,
	-- Oyuncunun etrafinda suzme aranan yaricap (stud)
	scanRadius = 75,
	-- Bir taramada suzme cikma sansi (yuzde)
	spawnChance = 35,
	-- Ayni anda bir oyuncunun etrafinda en fazla kac suzme durabilir
	maxBeamsPerPlayer = 4,
	-- Suzme / girdap kac saniye sonra kendiliginden kaybolur
	beamLifetime = 30,
	-- Denizin sans carpani: girdap sansi = olta sansi * bu (kaptandaki adalar gibi)
	seaLuck = 16,
	-- Suzmenin oyuncudan en az/en cok kac stud uzakta dogacagi
	minSpawnDistance = 18,
	maxSpawnDistance = 55,
	-- Kazmak icin suzmeye / madene kac stud yaklasmak gerekir.
	-- Kisa tutuldu: uzaktan tiklayinca kazi animasyonu havaya vuruyordu.
	digDistance = 6,
	--[[
		GIRDABA OLTA ATMA MESAFESI

		Kumda suzmenin dibine kadar gitmen gerekir; DENIZDE oyle degil --
		olta UZAKTAN atilir. Onceden ikisi de 10 studdu ve girdabin tam
		icinde durmadan tiklanamiyordu, misina atacak pay kalmiyordu.

		Girdaplar hep seaMinSpawnDistance otesinde dogar, yani bu sayi ondan
		KUCUK kalmali: girdap asla ayaginin dibinde belirmez, ona dogru
		gidersin ve bu paya girince oltayi atarsin.
	]]
	seaDigDistance = 32,

	--[[
		GIRDAPLAR DENIZE DAGILIR

		Deniz kumdan cok daha genis, bu yuzden girdaplarin kendi mesafeleri
		var. Onceden kumun sayilari (18-55 stud, 28 stud ayrik) kullaniliyordu
		ve girdaplar birbirinin dibinde doguyordu.

		seaMinSpawnDistance  en yakin dogum noktasi. seaDigDistance'tan buyuk:
		                     girdap asla ayaginin dibinde belirmez, ona dogru
		                     GITMEN gerekir.
		seaSeparation        ayni oyuncunun iki girdabi arasindaki EN AZ mesafe.
		                     Dogum yaricapi bunun yaninda genis kalmali, yoksa
		                     yeni girdaba yer bulunamaz ve hic dogmaz.
		seaMaxSpawnDistance  YEDEK ust sinir. Normalde ust siniri OLTA verir
		                     (Rods > scanRadius): istemciye yalnizca o yaricap
		                     icindeki girdaplar gonderildigi icin disarida
		                     dogan girdap gorunmez ve tiklanamaz olurdu.
	]]
	seaMinSpawnDistance = 55,
	seaMaxSpawnDistance = 190,
	seaSeparation = 85,
}

------------------------------------------------------------------
-- KAZI AYARLARI
------------------------------------------------------------------
Config.Dig = {
	-- Minigame baslamadan onceki hazirlik suresi (kurek digSpeed ile carpilir)
	prepareTime = 0.8,
	-- Iki kazi arasi bekleme
	cooldown = 0.6,
	-- Minigame sirasinda bu kadar uzaklasirsan kazi iptal
	maxMoveDistance = 14,
	--[[
		DENIZDE daha genis: oyuncu tahtanin uzerinde, misinayi 30 stud
		oteye atmis durumda. Kumdaki dar pay burada haksiz yere iptal
		ettiriyordu.
	]]
	seaMoveDistance = 30,
	-- Minigame icin sunucunun taniyacagi en uzun sure (guvenlik siniri)
	minigameTimeout = 60,

	--[[
		OTOMATIK EKIPMAN

		Kurek ve GPS artik CANTAYA HIC GIRMEZ. Oyuncu kumun uzerine
		basinca GPS kendiliginden ELINE gelir ve orada kalir; bir
		suzmeye tiklayinca yerini kurege birakir, kazi bitince GPS geri
		gelir. Kumdan cikinca ikisi de kaybolur.

		checkInterval: bu kontrolun kac saniyede bir yapilacagi. Kucuk
		deger daha tepkisel ama daha cok is; 0.3 sn goze aninda gelir.
	]]
	autoEquipInterval = 0.3,

	--[[
		GPS ELDEN KAC SANIYE SONRA GITSIN

		Ziplayinca ya da kumun kenarindan bir an cikinca GPS aninda
		elden dusuyordu -- Humanoid havadayken zemin malzemesi
		bildirmiyor, oyuncu da bir kare icin "kumda degil" sayiliyor.

		Artik kumdan ciktigin an degil, kumdan cikali BU KADAR saniye
		gectiginde iniyor. Ziplamak, kosarken kenardan tasmak ya da
		egimde bir an havada kalmak GPS'i elden dusurmez.
	]]
	autoUnequipDelay = 1,
}

------------------------------------------------------------------
-- ISIK SUZMESI EFEKTI
--
-- Suzmeler artik koddan cizilen isik sutunu degil, Studio'ya elle
-- konulmus bir VFX. Efekt su iki yerden birinde aranir:
--     Workspace icinde herhangi bir yerde <name>
--     ReplicatedStorage > Assets > VFX > <name>
--
-- Bulunamazsa oyun eski basit sutunla devam eder (uyari Output'a duser).
------------------------------------------------------------------
Config.BeamVFX = {
	-- Studio'daki VFX'in adi
	name = "DigLightVFX",

	--[[
		RENGE DOKUNULMAYACAK PARCALAR

		Adi burada gecen bir nesnenin KENDISI ve ICINDEKILER renklendirme
		disinda tutulur. Rocks paketin kendi tasarimi -- rengi kademeye
		gore degismemeli.
	]]
	keepColor = { "Rocks" },

	--[[
		KADEMEYLE BUYUMEYEN ZEMIN PARCALARI

		Adi burada gecen nesne (ve icindekiler) kademe olcegine ragmen
		COMMON'daki boyunda ve yerinde kalir. Nadir suzmelerde efekt
		buyurken taslar sutunla birlikte yukari kayip havada kaliyordu;
		artik yalnizca isik buyuyor, taslar zeminde duruyor.
	]]
	groundParts = { "Rocks" },

	--[[
		EFEKTTEN SILINECEK NESNELER

		Adi burada gecen nesne (ve icindekiler) suzme dogarken tamamen
		kaldirilir. Pakette gorunmesini istemedigin bir isaretci, kucuk
		bir yardimci parca ya da fazlalik bir efekt varsa adini buraya yaz:

		    hide = { "YesilNokta", "Marker" },

		Hangi nesnenin ne oldugunu admin panelindeki "VFX raporu" butonu
		Output icine listeler.
	]]
	hide = {},

	--[[
		true : parcaciklarin kendi parlaklik/doygunluk yapisi korunur,
		       yalnizca RENK TONU kademeninkine doner. Efektteki SIYAH ve
		       BEYAZ kisimlar oldugu gibi kalir -- mor ve tonlari degisir.
		false: her sey duz tek renk olur.
	]]
	preserveShading = true,

	--[[
		CANLILIK  --  kademe rengi ne kadar baskin olsun

		Renklendirme eskiden doygunluklari CARPIYORDU (orijinal * hedef);
		iki sayi da 1 in altinda oldugu icin sonuc ikisinden de soluk
		cikiyor, Mythic kirmizisi pembemsi gorunuyordu.

		0   = eski davranis, soluk
		1   = kademe rengi tam doygunlukta, en baskin
		0.9 = kirmizi gercekten kirmizi, mor gercekten mor

		Parlaklik paketten gelmeye devam eder; degisen yalnizca rengin
		ne kadar guclu bastigi.
	]]
	vividness = 0.9,

	--[[
		KADEMEYE GORE BUYUKLUK

		Legendary'den itibaren efekt buyumeye baslar; Divine capi belirgin
		sekilde genis parlar. Yazilmayan kademe 1 (normal boy) sayilir.

		Divine'in kimligi hala "Secret" -- gorunen adi degisti, veri
		uyumlulugu icin kimlik korundu (bkz. Shared > Rarity).
	]]
	scaleByRarity = {
		Legendary = 1.3,
		Mythic = 1.7,
		Secret = 2.4,

		-- Adaya bagli ust kademeler Divine'in USTUNE devam eder
		Cosmic = 2.9,
		Gizli = 3.4,
		Infernal = 3.9,
		Abyssal = 4.5,
	},

	--[[
		ZEMINE OTURTMA

		true iken efektin ALT UCU zemine hizalanir. Yani pivotu nerede
		olursa olsun efekt kumun uzerine yapisik durur ve taslar zemine
		oturur -- yukselen isik da onlarin arasindan cikiyormus gibi olur.

		Onceden efekt PIVOTUNDAN konumlaniyordu; paketin pivotu ortasinda
		oldugu icin alt yarisi (taslar dahil) zeminin altinda kaliyor ve
		gorunmuyordu. "Rocks hic cikmiyor" sikayetinin sebebi buydu.

		false yaparsan eski davranisa doner ve konumu height ile elle
		ayarlaman gerekir.
	]]
	alignToGround = true,

	--[[
		Ince ayar: efekt zeminden kac stud YUKARI kaydirilsin.

		EKSI deger efekti kuma GOMER. Taslar zeminin uzerinde havada
		duruyor gibi gorunmesin diye biraz asagi cekildi; daha derine
		gommek icin degeri kucult (-1, -1.5...), yukari kaldirmak icin
		buyut.
	]]
	height = -1,

	--[[
		SIYAH KATMANI KALDIR

		Paketteki koyu duman/golge yayicilari kademe rengine cevrilemiyor
		(parlakligi sifir olan renk her tonda siyahtir) ve efektin onune
		geciyordu. Acikken butun renk duraklari darkThreshold'un altinda
		kalan yayicilar tamamen silinir.

		Karanlikta baslayip renge acilan gecisler KALIR -- yalnizca bastan
		sona koyu olanlar gider. Rocks zaten keepColor'da oldugu icin
		incelenmez bile.
	]]
	removeDark = true,

	--[[
		"Siyah" sayilma esigi (0..1 parlaklik). Buyutursen daha koyu-gri
		katmanlar da silinir, kucultursen yalnizca tam siyahlar gider.
	]]
	darkThreshold = 0.22,

	--[[
		GOZ ALAN BEYAZI YUMUSAT

		Efektin ici bembeyaz parliyordu. Acikken efektin HER yerindeki
		beyaz renk duraklari bulunur; cogu kademe renginin kisilmis
		haliyle degistirilir, cok kucuk bir kismi azicik highlight olarak
		birakilir.

		Common gibi RENKSIZ kademelerde sonuc griye iner; Mythic gibi
		DOYGUN kademeler rengini korur (bkz. whiteSaturationRef).
	]]
	softenWhite = true,

	-- Beyaz sayilma esikleri: doygunluk BUNUN ALTINDA, parlaklik USTUNDE
	whiteSaturation = 0.5,
	whiteValue = 0.72,

	--[[
		RENKSIZ kademelerde (Common) parlaklik tavani.
		0 = simsiyah, 1 = bembeyaz. Common hala parlaksa kucult.
	]]
	whiteGrey = 0.22,

	--[[
		Bu doygunlugun USTUNDEKI kademeler hic kisilmaz.
		Kucultursen daha cok kademe rengini tam korur; buyutursen
		Rare/Secret gibi ortalar da sonuklesir.
	]]
	whiteSaturationRef = 0.5,

	--[[
		DOYGUN kademelerde (Rare, Mythic, Legendary...) parlaklik tavani.

		Onceden doygun kademeler HIC kisilmiyordu: beyaz cekirdek tam
		parlaklikta kademe rengine donuyor, yani hala goz aliyordu.
		Artik onlarin da bir tavani var.

		Kucultursen merkez daha koyu olur, buyutursen eski parlak haline
		yaklasir. 1 yaparsan doygun kademeler yine hic kisilmaz.
	]]
	whiteMaxValue = 0.35,

	--[[
		Beyazlarin kaci highlight olarak KALIR (0..1).
		0.15 = onda birinden biraz fazlasi. Sifir yaparsan efektte hic
		beyaz kalmaz; buyutursen eski parlak haline yaklasir.
	]]
	whiteHighlight = 0,

	-- O highlight ne kadar parlak olsun (1 = bembeyaz)
	whiteHighlightValue = 0.65,

	--[[
		PARLAMA TAVANI  --  asil goz alan sey

		LightEmission 1 iken parcacik EKLEMELI cizilir: rengi ne olursa
		olsun ekranin uzerine parlaklik biner ve koyu bir parcacik bile
		bembeyaz gorunur. Dokunulan yayicilar en fazla buraya cekilir.

		0 = hic parlamaz (duz renk), 1 = tam parlar.
	]]
	whiteGlow = 0,

	-- Uretilen modelin adi ve Output uyarilarindaki etiket
	label = "Suzme",
}

------------------------------------------------------------------
-- GIRDAP VFX  --  denizdeki suzmenin karsiligi
--
-- Kumdaki DigLightVFX ne ise denizde VortexVFX odur. Ayni borudan gecer
-- (sil > siyahi at > kademeye boya > beyazi yumusat > olcekle > yerlestir),
-- yalnizca ayarlari ayri: deniz efekti kuma gore daha genis ve su
-- yuzeyine oturuyor.
--
-- Bulunamazsa oyun kodla cizilen eski huni gorunumune duser (uyari
-- Output'a duser), yani girdap her halukarda dogar.
------------------------------------------------------------------
Config.WhirlVFX = {
	-- Studio'daki VFX'in adi (ReplicatedStorage > Assets icinde)
	name = "VortexVFX",

	-- Uretilen modelin adi ve Output uyarilarindaki etiket
	label = "Girdap",

	keepColor = {},
	hide = {},

	--[[
		PAKETIN KENDI SCRIPTLERINI SIL

		Girdap paketinin icinde iki dondurme scripti vardi ve modeli kendi
		yerel eksenlerinde ceviriyorlardi -- girdap yan yatmis gibi
		donuyordu. Donusu artik oyun yonetiyor (bkz. spin), o yuzden
		paketin scriptlerine ihtiyac yok.

		Ikinci fayda guvenlik: toolbox paketlerinin icindeki scriptler bu
		haritada bir kez 72 arka kapi olarak cikti (bkz. tools/scan.luau).
		Olmayan script arka kapi da olamaz.
	]]
	stripScripts = true,

	--[[
		YATAY DONUS

		Derece/saniye, DUNYA Y ekseni etrafinda. Donduren taraf istemci
		(bkz. StarterPlayerScripts > GirdapDonus): gorsel bir detay icin
		her karede CFrame replike etmenin anlami yok.

		0 yaparsan girdap sabit durur.
	]]
	spin = 45,
	spinTag = "GirdapDonus",

	--[[
		RENKLENDIRME

		Girdap PNG dokusuyla cizilmis. Doku rengi CARPILARAK uygulanir:
		Color3 beyazken doku kendi rengiyle gorunur, baska bir renk
		verilince doku o renge boyanir.

		preserveShading KAPALI: acikken dokunun kendi koyu/mavi yapisi
		korunuyor ve kademe rengi uzerine oturmuyordu -- Legendary girdap
		bile mavi kaliyor, uzerine kirli lekeler biniyordu. Kapaliyken
		doku duz olarak kademe renginde gorunur.
	]]
	preserveShading = false,
	vividness = 1,

	--[[
		DOKULU PARCALARI DA BOYA

		Renklendirme normalde yalnizca parcacik/Beam/Trail/isik renklerine
		dokunur. Girdap ise dokulu parcalardan kurulu; acik olmazsa rengi
		hic degismez.
	]]
	tintParts = true,

	--[[
		PARCACIK GECISI  --  ustteki beyaz patlamaya karsi

		Girdabin ustunden savrulan parcaciklar bembeyaz patliyordu. Sebep
		renk degil LIGHTEMISSION: 1'e yakin oldugunda parcacik EKLEMELI
		cizilir, yani rengi ne olursa olsun arkasindaki goruntunun uzerine
		parlaklik biner ve merkez beyaza doner.

		Cozum flyboard tahtalarindakiyle ayni: parcaciklar kademe renginin
		ACIK tonundan KOYU tonuna bir gecise cevriliyor ve parlama tavana
		cekiliyor. Boylece derinlik kaliyor, beyaz hic girmiyor.

		  lightMix   acik uc ne kadar beyaza yaklassin (buyutursen aydinlanir)
		  darkMix    koyu uc ne kadar siyaha yaklassin
		  lightEmission  parlamanin tavani -- HALA BEYAZ PATLIYORSA BURAYI KUCULT
		  lightBrightness  isiklarin parlaklik tavani
		  extraTransparency  parcaciklara eklenen saydamlik (yoguntsa buyut)
	]]
	ramp = {
		--[[
			CEKIRDEK  --  parcacigin dogdugu andaki en parlak ton

			Paketin kendi hali tam beyazdi ve goz aliyordu; tamamen kismak
			da efekti duz ve cansiz biraktti. Burasi ikisinin arasi: neredeyse
			beyaz, ama icinde hala kademenin rengi var.

			1 = tam beyaz (paketin kendi hali)
			0 = hic beyaz yok, duz kademe rengi
		]]
		coreMix = 0.88,

		-- Gecisin orta-acik ucu
		lightMix = 0.5,

		-- Koyu uc ne kadar siyaha yaklassin
		darkMix = 0.3,

		--[[
			PARLAMA TAVANI  --  goz almanin asil ayari

			LightEmission yuksekken parcacik EKLEMELI cizilir: rengi ne
			olursa olsun arkasindaki goruntunun uzerine parlaklik biner.
			Paket 1 ile geliyordu (goz alan hal); burasi TAVAN, yani paketin
			degeri bundan dusukse kendi degeri kalir.

			Gecmis denemeler:
			  0.15  tamamen sondu, efekt cansiz kaldi
			  0.35  hala az
			  0.8   paketin kendi hali, bir tik kisik  <-- su anki

			Fazla gelirse KUCULT, sonuk gelirse 1'e kadar buyut.
		]]
		lightEmission = 0.8,

		-- Isiklarin parlaklik tavani
		lightBrightness = 2,

		-- Parcaciklara eklenen saydamlik (yogunsa buyut)
		extraTransparency = 0.03,
	},

	--[[
		SIYAH KATMAN VE BEYAZ YUMUSATMA -- GIRDAPTA KAPALI

		Ikisi de PARCACIK paketleri icin yazildi. Doku tabanli girdapta
		ters tepiyor: koyu bolgeler dokunun kendi cizgileri, silinince
		girdap dagiliyor; beyaz yumusatma da parlak merkezi kirletiyordu.
	]]
	removeDark = false,
	darkThreshold = 0.22,
	softenWhite = false,
	whiteSaturation = 0.5,
	whiteValue = 0.72,
	whiteGrey = 0.22,
	whiteSaturationRef = 0.5,
	whiteMaxValue = 0.35,
	whiteHighlight = 0,
	whiteHighlightValue = 0.65,
	whiteGlow = 0,

	--[[
		TABAN BUYUKLUK

		Kademe carpaniyla CARPILIR. Girdap butun kademelerde buyuk/kucuk
		geliyorsa once BURAYI oynat; kademeler arasi fark icin asagidaki
		tabloyu kullan.
	]]
	baseScale = 1,

	--[[
		KADEMEYE GORE BUYUKLUK

		Kumdan farkli olarak HER kademe yaziliyor: girdap Common'da kucuk
		baslayip Divine'a dogru buyusun isteniyor. Kumda yalnizca
		Legendary'den itibaren buyuyor, orada taban boy zaten dogru.
	]]
	scaleByRarity = {
		Common = 0.6,
		Rare = 0.75,
		Epic = 0.95,
		Legendary = 1.15,
		Mythic = 1.4,
		Secret = 1.7,

		-- Adaya bagli ust kademeler Divine'in USTUNE devam eder
		Cosmic = 2.0,
		Gizli = 2.3,
		Infernal = 2.6,
		Abyssal = 3.0,
		LuckyBlock = 1,
	},

	--[[
		SU YUZEYINE OTURTMA

		Kumda efektin ALT UCU zemine hizalanir. Girdapta oyle degil: girdap
		suyun hem altina iner hem ustune sicrar, o yuzden efekt su yuzeyine
		ORTALANIR.
	]]
	alignToGround = false,

	--[[
		DENIZ YUZEYININ Y'SI

		Girdabin dikey yeri isinin carptigi noktadan DEGIL buradan gelir.
		Isin dalganin tepesine ya da cukuruna denk gelebiliyor ve girdap
		bazen suyun biraz altinda/ustunde kaliyordu.

		Denizin yuksekligini degistirirsen BURAYI guncelle. nil yaparsan
		isinin buldugu yukseklik kullanilir.
	]]
	fixedY = 20,

	-- Ince ayar: yuzeyden kac stud yukari kaydirilsin (eksi = suya gomer)
	height = 0,
}

return Config
