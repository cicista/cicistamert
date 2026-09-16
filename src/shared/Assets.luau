--!strict
--[[
	=====================================================================
	ASSET MERKEZI  --  MODEL / SES / ANIMASYON EKLEMEK ICIN TEK DOSYA
	=====================================================================

	MODEL EKLEME (Studio'da, kod yazmadan)
	--------------------------------------
	Sunucu acilista su klasorleri kendisi olusturur:

	    ReplicatedStorage > Assets > Brainrots
	    ReplicatedStorage > Assets > Shovels
	    ReplicatedStorage > Assets > Detectors
	    ReplicatedStorage > Assets > VFX
	    ReplicatedStorage > Assets > Sounds

	Modeli ilgili klasore surukleyip ADINI asagidaki isimle ayni yap:

	  Brainrots :  brainrot'un tam adi        ("Tralalero Tralala")
	              mutasyonlu surum:            "Gold Tralalero Tralala"
	  LuckyBlocks: kazidan cikan blok modeli   (klasordeki ILK model kullanilir,
	              yani adi ne olursa olsun surukleyip birakman yeterli)
	  Shovels   :  ADA KLASORU > "<Ad><sira>"  (Main > Main1..Main5, Candy > Candy1..5,
	              Snow > Frosty1..5, Volcano > Volcano1..5). Sira = kuregin
	              adadaki sirasi; ornek Candy1 = Lv6 kurek. Bkz. Assets.ShovelIslandFolders
	  Pickaxes  :  kazma id'si                 (CandyPickaxe, FrostyPickaxe, PhoenixPickaxe)
	  Rods      :  "Rod<level>" Tool'u         (Rod1 = Bamboo ... Rod5 = Leviathan)
	  Detectors :  dedektor id'si              (Basic, Pro, Quantum, Cosmic, Divine)

	Model bulunamazsa oyun otomatik olusturulan basit gorunumu kullanir,
	yani klasorleri bos birakabilirsin.

	SES  --  IKI AYRI YOL
	---------------------
	1) ASSET ID  : asagidaki Assets.Sounds tablosuna "rbxassetid://..." yaz.
	                Bos ("") birakilan alan kullanilmaz, hata vermez.
	2) HAZIR SES : Studio'da bir Sound nesnesini VFX gibi surukleyip birak
	                (Workspace ya da Assets > Sounds). Kod onu adiyla bulur,
	                kopyalayip calar. Bkz. Assets.playSoundAt.

	VFX ve hazir sesler AYNI mantikla calisir: sablon ilk bulusta bellege
	alinir, haritadaki orijinal susturulur, her oynatma tertemiz kopyadan
	uretilir.

	ANIMASYON
	---------
	Assets.Animations tablosuna asset id yaz.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Mutations = require(script.Parent.Mutations)

local Assets = {}

------------------------------------------------------------------
-- SESLER
-- "rbxassetid://123456789" bicimde yaz. Bos = ses yok.
------------------------------------------------------------------
Assets.Sounds = {
	-- Dedektor (GPS) elde tutulurken calan bip sesi.
	-- Yakinda suzme varsa daha SIK, uzaksa daha SEYREK calar.
	detectorBeep = "",
	-- Bip sesinin temel ses seviyesi
	detectorBeepVolume = 0.5,
	-- En yakin suzme kac studa kadar bip hizlandirir
	detectorBeepRange = 80,
	-- Bip araligi (saniye): suzme cok yakinken / cok uzakken
	detectorBeepFastest = 0.18,
	detectorBeepSlowest = 1.4,

	-- Kazi minigame kazanildiginda
	digSuccess = "",
	-- Kazi minigame kaybedildiginde
	digFail = "",
	-- Isik suzmesi dogdugunda (yalnizca sahibi duyar)
	beamSpawn = "",
	-- Brainrot slota yerlestirildiginde
	placeBrainrot = "",
	-- Satis yapildiginda
	sell = "",
}

------------------------------------------------------------------
-- ANIMASYONLAR
-- Tool elde tutulurken oynatilacak animasyonlar.
-- "rbxassetid://123456789" bicimde yaz. Bos = animasyon yok.
------------------------------------------------------------------
Assets.Animations = {
	-- Kurek elde tutulurken donen idle animasyonu
	shovelHold = "",

	--[[
		KAZMA ANIMASYONU  --  BURAYA ID YAZILACAK

		Minigame BASLAR BASLAMAZ oynar, minigame biter bitmez durur;
		yani oyuncu kazdigi surece doner. Tutma animasyonunun (shovelHold)
		uzerine biner, o yuzden ikisi ayni anda dolu olabilir.

		Animasyonu yukleyince asagiyi soyle doldur:
		    shovelDig = "rbxassetid://1234567890",

		Bos birakildigi surece hicbir sey oynamaz, hata da vermez.
	]]
	-- Kurek kazi animasyonu (0.40 sn), kazi boyunca dongude
	shovelDig = "rbxassetid://131623390335887",

	-- Madende kazma animasyonu (0.43 sn), kazi boyunca dongude
	pickaxeDig = "rbxassetid://88699767550436",

	--[[
		GPS elde tutulurken.

		BOS BIRAKILDI: dedektor Roblox'un varsayilan tutusuyla tasiniyor.
		Brainrot animasyonu (iki kol yukarida) denendi ama anteni tuhaf
		gosteriyordu. Baska bir tutus animasyonu yaptirirsan id'yi buraya
		yaz, kod degistirmen gerekmez.
	]]
	gpsHold = "",

	--[[
		Brainrot tasinirken donen idle animasyonu.
		Iki kol yukarida, kafanin ustundeki brainrotu tutuyormus gibi.
	]]
	brainrotHold = "rbxassetid://97748738133693",

	--[[
		KARAKTER DURURKEN (idle): zeminde hicbir sey yapmiyorken oynar.
		Roblox'un Animate scriptindeki idle animasyonlarinin yerine gecer
		(bkz. ServerScriptService > KarakterAnimasyonlari).
	]]
	idle = "rbxassetid://97769694813645",

	-- DENIZ (flyboard ustunde; bkz. StarterPlayerScripts > DenizAnimasyonlari)
	-- Tahtadayken surekli durus
	flyboardIdle = "rbxassetid://98909993111524",
	-- Olta savurma (1.733 sn); misina 1. saniyede birakilir (Rods.CastRelease)
	rodCast = "rbxassetid://130735035595565",
	-- Balik tutma minigame'i boyunca
	fishing = "rbxassetid://122968362803524",
}

------------------------------------------------------------------
-- KAZI EFEKTLERI  (bkz. StarterPlayerScripts > KaziEfekti)
--
-- Kazi animasyonunun belli bir aninda aletin ucundan gri parcacik cikar:
-- kurekte kum fiskirir, kazmada tas kirilir. Animasyon dongude oynadigi
-- icin her turda o anda tekrar eder.
--
--   animation     -- Assets.Animations icindeki anahtar
--   particleTime  -- animasyonun kacinci saniyesinde (tur basina bir kez)
--   count         -- kac parcacik
--   spread        -- yayilma acisi (derece): kucuk = yukari fiskirma,
--                    180 = her yone sacilma
--   speedMin/Max  -- parcacik hizi
------------------------------------------------------------------
Assets.DigEffects = {
	-- Toz / tas parcalari
	color1 = Color3.fromRGB(190, 185, 175),
	color2 = Color3.fromRGB(120, 115, 108),
	size = 0.8,
	lifetimeMin = 0.4,
	lifetimeMax = 0.8,
	gravity = 30,

	-- Kivilcim: kucuk, parlak beyaz, hizli ve kisa omurlu
	sparkColor = Color3.fromRGB(255, 255, 255),
	sparkSize = 0.2,
	sparkLifetimeMin = 0.15,
	sparkLifetimeMax = 0.35,

	shovel = {
		animation = "shovelDig",
		particleTime = 0.25,
		count = 40,
		spread = 40,
		speedMin = 10,
		speedMax = 18,
		sparkCount = 10,
		sparkSpeedMin = 14,
		sparkSpeedMax = 24,
	},

	pickaxe = {
		animation = "pickaxeDig",
		particleTime = 0.15,
		count = 35,
		spread = 180,
		speedMin = 7,
		speedMax = 14,
		sparkCount = 16,
		sparkSpeedMin = 16,
		sparkSpeedMax = 28,
	},
}

------------------------------------------------------------------
-- KLASORLER
------------------------------------------------------------------
Assets.FolderName = "Assets"

Assets.Categories = {
	brainrots = "Brainrots",
	luckyBlocks = "LuckyBlocks",
	shovels = "Shovels",
	pickaxes = "Pickaxes",
	rods = "Rods",
	detectors = "Detectors",
	vfx = "VFX",
	sounds = "Sounds",
}

-- Sunucu acilista cagirir; eksik klasorleri olusturur.
function Assets.ensureFolders()
	local root = ReplicatedStorage:FindFirstChild(Assets.FolderName)
	if not root then
		local created = Instance.new("Folder")
		created.Name = Assets.FolderName
		created.Parent = ReplicatedStorage
		root = created
	end

	for _, name in Assets.Categories do
		if not root:FindFirstChild(name) then
			local folder = Instance.new("Folder")
			folder.Name = name
			folder.Parent = root
		end
	end
end

local function categoryFolder(category: string): Instance?
	local root = ReplicatedStorage:FindFirstChild(Assets.FolderName)
	return if root then root:FindFirstChild(category) else nil
end

--[[
	Bir kategoriden isimle model arar ve KOPYASINI dondurur.
	Bulamazsa nil doner -- cagiran taraf otomatik gorunume duser.
]]
local function findModel(category: string, name: string?): Model?
	if not name or name == "" then
		return nil
	end

	local folder = categoryFolder(category)
	if not folder then
		return nil
	end

	local found = folder:FindFirstChild(name)

	--[[
		Dogrudan altinda yoksa alt klasorlere de bak.
		Boylece hazir bir model paketini (orn. BrainrotPack klasoru) icindeki
		modelleri tek tek disari cikarmadan oldugu gibi surukleyebilirsin.
	]]
	if not found then
		found = folder:FindFirstChild(name, true)
	end

	if found and found:IsA("Model") then
		return found:Clone()
	end

	return nil
end

------------------------------------------------------------------
-- MODEL ARAMA
------------------------------------------------------------------

--[[
	Brainrot modeli.
	Once mutasyonlu ad aranir ("Gold Tralalero Tralala"), o yoksa duz ad.
	Boylece pakete eklenmemis bir mutasyon icin Normal model kullanilir.
]]
--[[
	MODELDEKI ANIMASYONLARI OYNATIR

	Hazir paketler (orn. Animated Lucky Blocks) modelin icine bir
	AnimationController + Animation koyar ama kimse oynatmaz. Klonladigimiz
	model bu yuzden donmus gorunur. Burada icindeki butun animasyonlar
	bulunup dongu halinde baslatiliyor.

	AnimationId bos olan Animation'lar atlanir (bazi paketlerde bos duruyor).
]]
function Assets.playAnimations(model: Instance)
	for _, controller in model:GetDescendants() do
		if not controller:IsA("AnimationController") and not controller:IsA("Humanoid") then
			continue
		end

		local animator = controller:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = controller
		end

		for _, anim in controller.Parent:GetDescendants() do
			if anim:IsA("Animation") and anim.AnimationId ~= "" then
				local ok, track = pcall(function()
					return (animator :: Animator):LoadAnimation(anim)
				end)
				if ok and track then
					track.Looped = true
					track:Play()
				end
			end
		end
	end
end

--[[
	Lucky Block modeli.

	Model nerede olursa olsun bulunmaya calisilir; klasor yapisiyla ugrastirmaz:
	  1. Assets > LuckyBlocks altindaki ilk Model (ic ice klasorler dahil)
	  2. Bulunamazsa ReplicatedStorage'in HER YERINDE adinda "lucky" gecen
	     bir Model

	Hicbiri yoksa nil doner ve cagiran taraf yedek kupu cizer. O durumda
	Output'a bir uyari dusuyor: model bulunamadigini oradan anlarsin.
]]
local luckyWarned = false

--[[
	Klasordeki butun Lucky Block modellerini ADA GORE sirali dondurur.
	Blok turleri bu siraya gore eslesir: 1. model 1. tur, 2. model 2. tur...
]]
local function luckyModelList(): { Model }
	local folder = categoryFolder(Assets.Categories.luckyBlocks)
	local list: { Model } = {}

	if folder then
		for _, node in folder:GetDescendants() do
			if node:IsA("Model") then
				table.insert(list, node)
			end
		end
	end

	-- Klasore konmamissa: adinda "lucky" gecen modelleri topla
	if #list == 0 then
		for _, node in ReplicatedStorage:GetDescendants() do
			if node:IsA("Model") and string.find(string.lower(node.Name), "lucky", 1, true) then
				table.insert(list, node)
			end
		end
	end

	table.sort(list, function(a, b)
		return a.Name < b.Name
	end)

	return list
end

-- Bulunan modelleri bir kez Output'a yazar: hangi model kacinci sirada, gorunsun
local luckyListed = false

function Assets.listLuckyBlocks()
	if luckyListed then
		return
	end
	luckyListed = true

	local list = luckyModelList()
	if #list == 0 then
		return
	end

	local names = {}
	for index, model in list do
		table.insert(names, `{index}) {model.Name}`)
	end
	print(`[Assets] Lucky Block modelleri: {table.concat(names, "  ")}`)
end

--[[
	Lucky Block modeli.

	modelName verilirse o isimde aranir; verilmezse klasordeki ada gore
	sirali listeden order. sirdaki model alinir. Liste kisaysa son model
	kullanilir, yani tek model koysan da uc tur birden calisir.
]]
function Assets.luckyBlockModel(modelName: string?, order: number?): Model?
	local list = luckyModelList()

	local found: Model? = nil

	if modelName and modelName ~= "" then
		for _, model in list do
			if model.Name == modelName then
				found = model
				break
			end
		end
	end

	if not found and #list > 0 then
		local index = math.clamp(order or 1, 1, #list)
		found = list[index]
	end

	if not found then
		if not luckyWarned then
			luckyWarned = true
			warn(
				"[Assets] Lucky Block modeli bulunamadi. Modelleri "
					.. "ReplicatedStorage > Assets > LuckyBlocks icine koy "
					.. "(ya da adlarinda 'Lucky' gecsin). Simdilik yedek kup kullaniliyor."
			)
		end
		return nil
	end

	local clone = found:Clone()
	if not clone.PrimaryPart then
		clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart")
	end
	return clone
end

--[[
	GOLGE KAPALI

	Brainrot modelleri golge dusurmuyor. Base'te yan yana onlarca model
	duruyor ve her biri kendi golgesini cizerse hem kare hizi duser hem
	modellerin altina koyu bir leke birikir.

	Tek yerden: bu fonksiyon hem envanter tool'unun hem base'teki modelin
	hem Index onizlemesinin kaynagi.
]]
local function golgeyiKapat(model: Model?): Model?
	if not model then
		return nil
	end

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CastShadow = false
		end
	end

	return model
end

function Assets.brainrotModel(name: string?, mutationId: string?): Model?
	if name and mutationId then
		--[[
			Mutasyonlu model adi ("Gold Tralalero Tralala") burada DOGRUDAN
			prefix'ten kuruluyor, Mutations'taki bir yardimci FONKSIYON
			uzerinden degil.

			Sebep: bu iki modul Studio'ya ayri ayri senkronlanir. Aradaki bag
			bir fonksiyon adi olursa, adi degistiginde ve karsi modul eski
			surumde kalirsa cagri nil'e duser; hata Envanter'in pcall'una
			takilip yutulur ve brainrot tool'u HIC uretilmez. Tam olarak bu
			yasandi (Mutations.fullName -> modelName degisiminde).

			prefix bir VERI alani: basindan beri var ve adi degismiyor.
			Iki modul arasindaki bagi veri uzerinden kurmak, fonksiyon adi
			uzerinden kurmaktan cok daha dayanikli.
		]]
		local prefix = Mutations.get(mutationId).prefix
		local mutated = findModel(Assets.Categories.brainrots, prefix .. name)
		if mutated then
			return golgeyiKapat(mutated)
		end
	end

	return golgeyiKapat(findModel(Assets.Categories.brainrots, name))
end

--[[
	KUREK MODELLERI  --  adaya gore klasorlenmis

	    Assets > Shovels > Main    > Main1 .. Main5        (Lv 1-5)
	    Assets > Shovels > Candy   > Candy1 .. Candy5      (Lv 6-10)
	    Assets > Shovels > Snow    > Frosty1 .. Frosty5    (Lv 11-15)
	    Assets > Shovels > Volcano > Volcano1 .. Volcano5  (Lv 16-20)

	Modelin ADI onemli degil, SONUNDAKI SAYI onemli: kuregin adadaki sirasi.
	Yani Frosty3 = Snow adasinin 3. kuregi = Lv13.
]]
Assets.ShovelIslandFolders = {
	kum = "Main",
	sekerkum = "Candy",
	snowkum = "Snow",
	alevkum = "Volcano",
} :: { [string]: string }

-- Klasorde adi "<herhangi><sira>" olan ilk Model/Tool (Main3, Frosty3, Rod3)
local function siraliModel(folder: Instance, sira: number): Instance?
	for _, child in folder:GetChildren() do
		if child:IsA("Model") or child:IsA("Tool") then
			if tonumber(string.match(child.Name, "(%d+)$")) == sira then
				return child
			end
		end
	end
	return nil
end

--[[
	Kurek modelinin KOPYASI.
	Once eski usul (kurek id'siyle ayni adli model), yoksa ada klasoru + sira.
]]
function Assets.shovelModel(shovelId: string, level: number?, island: string?): Model?
	local dogrudan = findModel(Assets.Categories.shovels, shovelId)
	if dogrudan or not level then
		return dogrudan
	end

	local kok = categoryFolder(Assets.Categories.shovels)
	local klasorAdi = Assets.ShovelIslandFolders[island or "kum"]
	local klasor = if kok and klasorAdi then kok:FindFirstChild(klasorAdi) else nil
	if not klasor then
		return nil
	end

	local bulunan = siraliModel(klasor, ((level - 1) % 5) + 1)
	return if bulunan and bulunan:IsA("Model") then bulunan:Clone() else nil
end

-- Kazma modeli: Assets > Pickaxes icinde kazma id'siyle ayni adli model
function Assets.pickaxeModel(pickaxeId: string): Model?
	return findModel(Assets.Categories.pickaxes, pickaxeId)
end

--[[
	Olta: Assets > Rods > Rod<level>. Hazir bir TOOL (Handle + Main + Manifest,
	parcalar Handle'a kaynakli). KOPYASI doner; Olta modulu onu ele kaynaklanan
	bir modele cevirir.
]]
function Assets.rodTool(level: number): Instance?
	local kok = categoryFolder(Assets.Categories.rods)
	if not kok then
		return nil
	end
	local bulunan = kok:FindFirstChild(`Rod{level}`) or siraliModel(kok, level)
	return if bulunan then bulunan:Clone() else nil
end

--[[
	ELDE TUTUS AYARLARI  --  kurek, kazma, olta

	HEPSI ROBLOX'UN VARSAYILAN TUTUSUNDA: elde DIK, kafa/bicak YUKARIDA,
	el sapin alt ucunda. Tutma animasyonlari bu duruma gore yapilacak;
	position / rotation SIFIR kaldikca arac tam o sekilde durur.

	Kurek ve kazma modelleri gevsek parcalardan olusuyor (Sopa + Kabza/Kenar/
	Govde klasorleri). Kod her birine gorunmez bir Handle ekler:

	    gripOn      -- "sopa": el sopanin uzerinde, kabzanin hemen ustunde
	    gripRatio   -- gripOn = "sopa" iken: 0 = sapin tam ortasi, 1 = sapin alt ucu
	    gripFromEnd -- gripOn yoksa: el, KABZANIN UCUNDAN kac stud iceride
	    bladeDown   -- false: kafa elin USTUNDE (dik tutus), true: altinda
	    spread      -- kafanin yonu: "forward" genis yon one, "right" yanlara,
	                   "inward" kurek kafasinin OYUK tarafi karaktere baksin
	    flip        -- { [model adi] = true }: o model yine ters duruyorsa
	                   180 derece cevrilir (orn. { Candy3 = true })
	    position    -- ele gore ek kayma (stud)
	    rotation    -- ek donus (derece). Bicagin duz yuzu ters bakiyorsa
	                   Y'ye 180 ver.

	Olta (Rod) hazir Tool; Handle'i elin tutus noktasina (RightGripAttachment)
	Roblox'un bir Tool'u tuttugu gibi oturtulur:
	    position / rotation -- o noktaya gore ek kayma ve donus
]]
Assets.ToolGrips = {
	shovel = {
		gripFromEnd = 0.6,
		bladeDown = false,
		-- Kafanin oyuk tarafi karaktere bakar; butun kurekler ayni yone
		spread = "inward",
		-- Kodun yonu yine ters buldugu modeller: { Main2 = true, Frosty4 = true }
		flip = {},
		-- El sopanin uzerinde, ortanin biraz altinda (0 = orta, 1 = alt uc)
		gripOn = "sopa",
		gripRatio = 0.5,
		-- Sap bilege degil AVUCA otursun: ele gore ileri (parmaklara dogru) kayma
		position = Vector3.new(0, 0, 0.2),
		rotation = Vector3.new(0, 0, 0),
	},
	pickaxe = {
		gripFromEnd = 0.6,
		bladeDown = false,
		spread = "forward",
		position = Vector3.new(0, 0, 0),
		rotation = Vector3.new(0, 0, 0),
	},
	rod = {
		-- El oltanin sapinda: 0 = sapin ortasi, 1 = alt ucu
		gripRatio = 0.6,
		-- Bas asagi duran olta seviyeleri: cevrilir, misina ucu ustte kalir
		flip = { [3] = true },
		position = Vector3.new(0, 0, 0),
		rotation = Vector3.new(0, 0, 0),
	},
}

--[[
	GOVDE ESYALARI  --  sirtta kurek ve kazma (X), belde GPS
	(bkz. ServerScriptService > SirtEsyalari)

	Esyanin tutus noktasi (Handle) govde parcasina gore bu konuma oturur:
	kurek UpperTorso'ya, GPS LowerTorso'ya (R6'da ikisi de Torso'ya).

	    position   -- R15 icin kayma (stud). X sag, Y yukari, Z ARKA
	    positionR6 -- R6 (Torso) icin kayma
	    rotation   -- derece. Y 180: esya disa baksin; Z: govde duzleminde egim
	    scale      -- model boyu carpani
	    anchor     -- "center": tutus noktasi yerine MODELIN ORTASI konuma oturur
	    spin       -- derece: esya KENDI SAPI etrafinda doner (capraz acisi bozulmaz)
	                  (farkli boydaki kurekler ayni yerde durur)
]]
Assets.BodyItems = {
	--[[
		REFERANS GOVDE  --  konumlarin ayarlandigi karakterin govde boylari

		Doluyken her oyuncuda konum ve esya boyu, o oyuncunun govde
		parcasinin buna ORANIYLA carpilir: genis govdede esyalar disari,
		dar govdede iceri kayar, iri karakterde esya da buyur.

		Bos (nil) kalirsa oranlama yapilmaz ve oyuncu girince govde boylari
		Output'a buraya yapistirilacak sekilde yazilir.
	]]
	-- LetCicistaCook karakteri (konumlar bu karakterde ayarlandi)
	reference = {
		UpperTorso = Vector3.new(1.246, 1.166, 1.086),
		LowerTorso = Vector3.new(0.864, 0.759, 0.672),
	} :: { [string]: Vector3 }?,
	shovel = {
		-- Modelin ORTASI bu noktaya oturur (anchor): butun kurekler ayni yerde
		anchor = "center",
		position = Vector3.new(0, 0.1, 0.55),
		positionR6 = Vector3.new(0, 0.1, 0.55),
		-- 45 derece capraz: arkadan bakinca kafa SAG omuzda, sap ucu SOL kalcada;
		-- kurek kafasinin ici DISARI bakar
		rotation = Vector3.new(0, 0, -45),
		scale = 0.6,
	},
	--[[
		SIRTTA KAZMA  --  kuregin DIGER CAPRAZI (ikisi sirtta X yapar)

		Kurekle ayni nokta ve boy; yalnizca aci ayna: arkadan bakinca kafa
		SOL omuzda, sap ucu SAG kalcada. Z biraz daha disarida (0.62) ki
		iki model ortada birbirinin icine girmesin.
		Oyuncunun sahip oldugu EN IYI kazma gorunur (Ores.IslandOrder sirasi).
	]]
	pickaxe = {
		anchor = "center",
		position = Vector3.new(0, 0.1, 0.62),
		positionR6 = Vector3.new(0, 0.1, 0.62),
		rotation = Vector3.new(0, 0, 45),
		-- Kafa sirta paralel yatsin, kurek gibi duz gorunsun (tutmazsa 0 / 180 / 270 dene)
		spin = 90,
		scale = 0.6,
	},
	gps = {
		-- SOL kalcanin yaninda, sarkan elin hizasinda
		position = Vector3.new(-0.6, -0.3, -0.1),
		positionR6 = Vector3.new(-0.6, -1.2, -0.1),
		-- Yandan bakinca capraz: basi one-yukari, sapi arkaya-asagi
		rotation = Vector3.new(-40, 0, 0),
		scale = 0.6,
		-- Cepteyken isik ve efekt yok (parlama, parcacik)
		lights = false,
	},
}

-- Dedektor (GPS) modeli; kurekle ayni mantik
function Assets.detectorModel(detectorId: string): Model?
	return findModel(Assets.Categories.detectors, detectorId)
end

------------------------------------------------------------------
-- VFX
------------------------------------------------------------------

--[[
	VFX SABLONU

	Efekt iki yerden biri olabilir:
	    ReplicatedStorage > Assets > VFX > <ad>      (duzenli yer)
	    Workspace icinde herhangi bir yerde <ad>     (haritaya birakilmis)

	Bulunanin KOPYASI dondurulur; orijinale asla dokunulmaz... haric bir sey:
	haritada duruyorsa parcaciklari ve isiklari kapatilip kendisi gizlenir.
	Yoksa efekt oyun boyunca birakildigi yerde durmadan patlar. Bu degisiklik
	yalnizca calisan sunucuda olur, Studio'daki dosyayi bozmaz.
]]
local function hush(node: Instance)
	if node:IsA("ParticleEmitter") or node:IsA("Light") then
		node.Enabled = false
	elseif node:IsA("Sound") then
		node:Stop()
		node.Playing = false
		node.Looped = false
	end
end

local function conceal(node: Instance)
	if node:IsA("BasePart") then
		node.Transparency = 1
		node.CanCollide = false
		node.CanQuery = false
		node.CanTouch = false
	end
end

--[[
	Haritada birakilmis orijinali gizler ve susturur.

	DIKKAT: gizleme ICE DE islemeli. Onceden yalnizca kokun kendisi
	saydamlastiriliyordu; efekt bir MODEL ise (ki cogu oyle) icindeki
	parcalar gorunur kaliyor ve orijinal haritada oldugu yerde duruyordu.
	Oyuncuya bu, "kazilan suzme yok olmadi" gibi gorunuyordu.
]]
local function silence(root: Instance)
	hush(root)
	conceal(root)

	for _, node in root:GetDescendants() do
		hush(node)
		conceal(node)
	end
end

--[[
	Sablon BIR KEZ bulunup bellekte tutulur.

	Onceden her patlamada Workspace yeniden taraniyordu. Ama ilk aramadan
	sonra haritadaki orijinal SUSTURULUYOR (yoksa oyun boyunca durdugu yerde
	patlar); ikinci arama da o susturulmus halden kopya aliyordu ve efekt bir
	daha oynamiyordu. "Ilkinde oldu, sonrakilerde olmadi" bundandi -- sunucuyu
	yeniden baslatmak da tam bu yuzden ise yariyordu.

	Artik ilk aramada alinan TERTEMIZ kopya saklaniyor ve her patlama ondan
	uretiliyor; kacinci patlama oldugunun onemi yok.
]]
local templateCache: { [string]: Instance } = {}

--[[
	Adi verilen nesneyi bulup KOPYASINI dondurur.

	quiet = true ise bulunamadiginda uyari yazilmaz. Aday isim listesi
	denenirken kullanilir: yalnizca hicbiri bulunamazsa uyarmak icin.
]]
--[[
	Sablonu adiyla bulur ve KOPYASINI dondurur.

	ARAMA SIRASI
	  1. kendi kategori klasoru   Assets > VFX > <ad>
	  2. Assets'in KOKU           Assets > <ad>      (alt klasorler dahil)
	  3. Workspace                herhangi bir yerde

	2. adim sonradan eklendi: dosya kategori klasorune degil dogrudan
	Assets'in altina birakildiginda "bulunamadi" deyip vazgeciliyordu.
	Nereye birakilirsa birakilsin bulunmasi, hangi klasore ait oldugunu
	hatirlamaktan daha onemli.
]]
local function grabTemplate(name: string, category: string, hint: string, quiet: boolean?): Instance?
	local key = `{category}/{name}`

	local cached = templateCache[key]
	if cached then
		return cached:Clone()
	end

	local folder = categoryFolder(category)
	local found: Instance? = if folder then folder:FindFirstChild(name, true) else nil

	if not found then
		local root = ReplicatedStorage:FindFirstChild(Assets.FolderName)
		found = if root then root:FindFirstChild(name, true) else nil
	end

	local inWorkspace = false
	if not found then
		found = Workspace:FindFirstChild(name, true)
		inWorkspace = found ~= nil
	end

	if not found then
		if not quiet then
			Assets.warnOnce(`sablon yok: {key}`, `[Assets] "{name}" bulunamadi. {hint}`)
		end
		return nil
	end

	-- Sablon: her sey acikken alinan kopya. Bundan sonrasi hep bunun kopyasi.
	local template = found:Clone()
	templateCache[key] = template

	if inWorkspace then
		silence(found)
	end

	return template:Clone()
end

--[[
	VFX sablonunu getirir.

	ATTACHMENT ISARETCILERI KAPATILIR
	Parcacik yayicilari birer Attachment'a bagli durur ve Attachment.Visible
	acikken Studio o noktayi kucuk renkli bir eksen/nokta olarak cizer.
	Efektin tam ortasinda beliren yesil nokta buydu.

	Bu yalnizca EDITOR cizimi -- canli oyuncular hicbir zaman gormez -- ama
	Studio'da test ederken efektin onune geciyor. Uretilen her kopyada
	kapatiliyor; haritadaki orijinal sablona dokunulmuyor.
]]
function Assets.vfxTemplate(name: string): Instance?
	local template = grabTemplate(
		name,
		Assets.Categories.vfx,
		"Workspace'e ya da ReplicatedStorage > Assets > VFX icine koy. Efekt olmadan devam ediliyor."
	)

	if not template then
		return nil
	end

	for _, node in template:GetDescendants() do
		if node:IsA("Attachment") then
			node.Visible = false
		end
	end

	return template
end

------------------------------------------------------------------
-- KIMLIGI BELIRLENMEMIS BRAINROT
--
-- Kazidan cikan brainrot, Detective onu acana kadar gercek modeliyle
-- gosterilmez. Onun yerine Studio'ya elle konulmus hazir bir model
-- kullanilir (Workspace > HiddenPart): kendi VFX'i ve gorunumu vardir.
--
-- Model BEYAZ hazirlanmistir; parcalari calisma aninda suzmenin kademe
-- rengine boyanir. Yalnizca keepPart adli parca kendi gorunumunde kalir.
------------------------------------------------------------------
Assets.HiddenBrainrot = {
	-- Modelin adi. Yeri: ReplicatedStorage > Assets (ya da Workspace).
	name = "HiddenPart",

	-- Bu adli parca BOYANMAZ; modelin kendi gorunumunde kalir
	keepPart = "Cube",

	--[[
		Rengi korunacak parcalara konan nitelik.

		Isim yerine NITELIK kullaniliyor cunku Tools.attachModel govde
		parcasini "Handle" olarak yeniden adlandiriyor -- Cube govde ise
		isimle aramak sonradan tutmazdi. Nitelik yeniden adlandirmadan
		etkilenmez.
	]]
	keepAttribute = "OzgunRenk",

	--[[
		ELDE NEREDE DURUR

		Gizli model duz bir kup; kendi tutus ayari var. Buradaki degerler
		yalnizca kimligi belirlenmemis brainrotlara uygulanir, acilmislarin
		yerlesimi degismez.

		offset -- kafaya gore kayma (stud), kafanin KENDI eksenlerinde:
		            X arti  = karakterin SAGINA
		            X eksi  = karakterin SOLUNA
		            Y       = yukseklik (0 birak; yukseklik modelin kendi
		                      boyundan otomatik hesaplaniyor)
		            Z eksi  = one, Z arti = arkaya

		NOT: Onden bakarken karakterin SAGI ekranin SOLUNDA gorunur.
		Kutu ekranda saga kaymissa X'i BUYUT, sola kaymissa KUCULT.

		rotation -- derece cinsinden donus
		            Y = 180 kupu arkaya cevirir
	]]
	offset = Vector3.new(1.4, 0, -0.2),
	rotation = Vector3.new(0, 180, 0),
}

--[[
	Gelen nesneyi Model'e cevirir.

	Sablon her zaman Model olmayabilir: Studio'da bir Part ya da Folder
	olarak durabilir. Boyle bir durumda vazgecmek yerine icerik bir
	Model'in altina tasinir ve kullanilmaya devam edilir.
]]
local function asModel(source: Instance): Model?
	if source:IsA("Model") then
		return source
	end

	local model = Instance.new("Model")
	model.Name = source.Name

	if source:IsA("BasePart") then
		source.Parent = model
	else
		for _, child in source:GetChildren() do
			child.Parent = model
		end
		source:Destroy()
	end

	if not model:FindFirstChildWhichIsA("BasePart", true) then
		model:Destroy()
		return nil
	end

	return model
end

--[[
	TARANACAK KOKLER

	Sabit bir servis listesi YOK: game:GetChildren() ile o an erisilebilen
	BUTUN servisler alinir. Boylece model Workspace'te de olsa,
	ReplicatedStorage'da da, ServerStorage'da da, aklina gelmeyecek bir
	serviste de olsa bulunur -- listeye ekleme yapmak gerekmez.

	Terrain gibi devasa ve icinde model barindirmayan dallar atlanir,
	yoksa her arama gereksiz yere butun arazi voksellerini dolasir.
]]
local SKIP_ROOTS = {
	Terrain = true,
	Chat = true,
	TextChatService = true,
	MaterialService = true,
	CoreGui = true,
}

function Assets.searchRoots(): { Instance }
	local roots: { Instance } = {}

	local ok, services = pcall(function()
		return game:GetChildren()
	end)

	if not ok or not services then
		return roots
	end

	for _, service in services do
		if not SKIP_ROOTS[service.ClassName] and not SKIP_ROOTS[service.Name] then
			table.insert(roots, service)
		end
	end

	return roots
end

--[[
	Adiyla nesne arar.

	Once TAM ad, sonra BUYUK/KUCUK HARF farki yok sayilarak; en son da
	adin BASINDA/SONUNDA bosluk varsa diye kirpilmis haliyle karsilastirir.
	Studio'da "HiddenPart " (sonda bosluk) yazmak cok kolay ve gozle
	ayirt edilmiyor.
]]
local function findHidden(name: string): Instance?
	--[[
		ONCE BELGELENMIS YER: ReplicatedStorage > Assets

		Modelin durmasi gereken yer burasi. Once buraya bakiliyor; hem
		en hizlisi hem de dogru yere konuldugunda aramanin geri kalanina
		hic girilmiyor.
	]]
	local assetRoot = ReplicatedStorage:FindFirstChild(Assets.FolderName)
	if assetRoot then
		local direct = assetRoot:FindFirstChild(name, true)
		if direct then
			return direct
		end
	end

	local roots = Assets.searchRoots()

	for _, root in roots do
		local exact = root:FindFirstChild(name, true)
		if exact then
			return exact
		end
	end

	local target = string.lower(name)

	for _, root in roots do
		local ok, nodes = pcall(function()
			return root:GetDescendants()
		end)

		if ok and nodes then
			for _, node in nodes do
				local candidate = string.lower(node.Name)
				if candidate == target or string.gsub(candidate, "^%s*(.-)%s*$", "%1") == target then
					return node
				end
			end
		end
	end

	return nil
end

--[[
	Sablon BIR KEZ bulunur ve bellekte tutulur; her brainrot onun
	kopyasindan uretilir. Haritadaki orijinal ilk bulusta gizlenir --
	yoksa sahnede oldugu yerde durmaya devam ederdi.
]]
local hiddenCache: Model? = nil

--[[
	Kimligi belirlenmemis brainrotun modelini KOPYA olarak dondurur.

	Bulunamazsa nil doner; cagiran taraf duz kutu gorunumune duser
	(bkz. Modules > Tools > buildBrainrot).
]]
function Assets.hiddenBrainrotModel(): Model?
	local cfg = Assets.HiddenBrainrot

	if hiddenCache then
		return golgeyiKapat(hiddenCache:Clone())
	end

	local found = findHidden(cfg.name)

	if not found then
		--[[
			Uyari, sorunun NE oldugunu tek satirda soylesin.

			Taranan servis sayisi ve Workspace'teki nesne sayisi burada
			yaziyor: model Studio'da duruyor gorunup burada bulunamiyorsa,
			duzenledigin place ile test ettigin place ayni degil demektir.
			Bu sayilar Explorer'da gordugunle karsilastirilabilir.
		]]
		Assets.warnOnce(
			`gizli brainrot yok: {cfg.name}`,
			`[Assets] "{cfg.name}" bulunamadi. {#Assets.searchRoots()} servis tarandi, `
				.. `Workspace'te {#Workspace:GetChildren()} nesne var. `
				.. `Explorer'da gordugun sayi farkliysa test ettigin place baska bir dosyadir. `
				.. `Duz kutuya dusuldu.`
		)
		return nil
	end

	local model = asModel(found:Clone())
	if not model then
		Assets.warnOnce(
			`gizli brainrot bos: {cfg.name}`,
			`[Assets] "{cfg.name}" icinde hic BasePart yok. Duz kutuya dusuldu.`
		)
		return nil
	end

	-- Rengi korunacak parcalari, yeniden adlandirilmadan once isaretle
	local kept = 0
	for _, node in model:GetDescendants() do
		if node:IsA("BasePart") and string.lower(node.Name) == string.lower(cfg.keepPart) then
			node:SetAttribute(cfg.keepAttribute, true)
			kept += 1
		end
	end

	if kept == 0 then
		Assets.warnOnce(
			`gizli brainrot keepPart: {cfg.keepPart}`,
			`[Assets] "{cfg.name}" icinde "{cfg.keepPart}" adli parca yok -- her sey kademe rengine boyanacak.`
		)
	end

	hiddenCache = model

	-- Haritadaki orijinal sahnede durmasin
	if found:IsDescendantOf(Workspace) then
		silence(found)
	end

	print(`[Assets] Gizli brainrot modeli hazir: {found:GetFullName()} ({found.ClassName}), korunan parca: {kept}`)

	-- Gizli brainrot da golge dusurmesin: base'te acilmamis olanlar da duruyor
	return golgeyiKapat(model:Clone())
end

------------------------------------------------------------------
-- SES NESNELERI
--
-- Assets.Sounds (yukarisi) asset ID'leri tutar; burasi ise Studio'ya
-- ELLE KONULMUS Sound nesneleri icindir. Ikisi ayri seyler: birinde
-- id yaziyorsun, digerinde hazir bir sesi surukleyip birakiyorsun.
------------------------------------------------------------------

local function soundTemplate(name: string, quiet: boolean?): Sound?
	local template = grabTemplate(
		name,
		Assets.Categories.sounds,
		"Workspace'e ya da ReplicatedStorage > Assets > Sounds icine koy. Ses olmadan devam ediliyor.",
		quiet
	)

	if not template then
		return nil
	end

	if not template:IsA("Sound") then
		template:Destroy()
		return nil
	end

	return template
end

--[[
	Sesi verilen parcada calar -- yani 3B, kaynagindan duyulur ve
	yakindaki herkes duyar.

	names: aday adlar; ILK BULUNAN calinir. Studio'da ad yanlis yazilmis
	olabilir diye yedek ad verilebiliyor (NPC'lerdeki altName mantigi).

	Ses bitince kendini siler; bitmezse (dongu ya da bozuk id) Debris yakalar.
]]
function Assets.playSoundAt(names: { string }, part: BasePart, maxLifetime: number?): Sound?
	for index, name in names do
		-- Yalnizca SON aday da bulunamazsa uyar
		local sound = soundTemplate(name, index < #names)

		if sound then
			sound.Parent = part
			sound:Play()

			sound.Ended:Once(function()
				sound:Destroy()
			end)
			Debris:AddItem(sound, maxLifetime or 12)

			return sound
		end
	end

	return nil
end

--[[
	Efektin BUYUKLUGUNU olcekler.

	Parcacik boyu ve hizi ile isik menzili carpilir; ayni efekt daha genis
	bir patlama olarak gorunur. Ust kademelerde patlamayi buyutmek icin.

	PointLight.Range'in ust siniri 60; asilirsa Roblox hata verir.
]]
function Assets.scaleEffects(root: Instance, factor: number)
	if factor == 1 then
		return
	end

	for _, node in root:GetDescendants() do
		if node:IsA("ParticleEmitter") then
			local keys = {}
			for _, key in node.Size.Keypoints do
				table.insert(keys, NumberSequenceKeypoint.new(key.Time, key.Value * factor, key.Envelope * factor))
			end
			node.Size = NumberSequence.new(keys)
			node.Speed = NumberRange.new(node.Speed.Min * factor, node.Speed.Max * factor)
		elseif node:IsA("Light") then
			node.Range = math.min(node.Range * factor, 60)
		end
	end
end

--[[
	EFEKTLERI YENIDEN RENKLENDIRIR

	Parcaciklarin, isiklarin, iz ve isinlarin rengini verilen renge cevirir.

	preserveShading (varsayilan): parcaciklarin KENDI parlaklik ve doygunluk
	yapisi korunur, yalnizca RENK TONU degistirilir. Boylece efektin beyaz
	cekirdegi beyaz kalir, renkli uclari hedef renge doner ve paketi yapan
	kisinin tasarladigi gecis bozulmaz.

	false verilirse her sey duz tek renk olur.
]]
--[[
	CANLILIK  (Config.BeamVFX.vividness -- cagiran taraf gecer)

	Eski hesap doygunlugu CARPIYORDU: sonuc = orijinalS * hedefS. Iki sayi
	da 1 in altinda oldugu icin carpim ikisinden de kucuk cikiyor ve renk
	soluyordu -- Mythic kirmizisi pembemsi, Epic moru soluk lila oluyordu.

	Artik carpim ile hedefin TAM doygunlugu arasinda geciliyor:
	    0 = eski davranis (soluk)
	    1 = kademe rengi tam doygunlukta (en baskin)

	Parlaklik (V) hala paketten geliyor, yani efektin kendi isik-golge
	yapisi bozulmuyor; degisen yalnizca rengin ne kadar baskin oldugu.
]]
local function tint(original: Color3, target: Color3, preserveShading: boolean, vividness: number): Color3
	if not preserveShading then
		return target
	end

	local _, originalS, originalV = original:ToHSV()
	local targetH, targetS = target:ToHSV()

	local blended = originalS * targetS
	local saturation = blended + (targetS - blended) * vividness

	-- Ton ve doygunluk hedeften, parlaklik orijinalden
	return Color3.fromHSV(targetH, math.clamp(saturation, 0, 1), originalV)
end

--[[
	Bu nesne, adi keep listesinde gecen bir seyin ICINDE mi (ya da kendisi mi)?

	Hazir paketlerde kademeye gore RENGI DEGISMEMESI gereken parcalar var --
	isik suzmesi efektindeki "Rocks" gibi: onlar tasarimin kendi parcasi,
	mor tonlari degil. Boyle bir dalin tamami renklendirmenin disinda kalir.
]]
local function isProtected(node: Instance, root: Instance, keep: { string }?): boolean
	if not keep or #keep == 0 then
		return false
	end

	local cursor: Instance? = node
	while cursor do
		for _, name in keep do
			if cursor.Name == name then
				return true
			end
		end

		-- Kokun disina cikma: efektin durdugu yerdeki adlar bizi ilgilendirmez
		if cursor == root then
			return false
		end
		cursor = cursor.Parent
	end

	return false
end

--[[
	keep: adi burada gecen nesneler ve BUTUN ICERIKLERI renklendirilmez.
	Verilmezse efektin tamami renklendirilir (eski davranis).
]]
function Assets.tintEffects(root: Instance, color: Color3, preserveShading: boolean?, keep: { string }?, vividness: number?)
	local keepShading = preserveShading ~= false
	local vivid = math.clamp(vividness or 0.85, 0, 1)

	local nodes = root:GetDescendants()
	table.insert(nodes, root)

	for _, node in nodes do
		if isProtected(node, root, keep) then
			continue
		end

		if node:IsA("ParticleEmitter") or node:IsA("Beam") or node:IsA("Trail") then
			local keys = {}
			for _, key in node.Color.Keypoints do
				table.insert(keys, ColorSequenceKeypoint.new(key.Time, tint(key.Value, color, keepShading, vivid)))
			end
			node.Color = ColorSequence.new(keys)
		elseif node:IsA("Light") then
			node.Color = tint(node.Color, color, keepShading, vivid)
		end
	end
end

--[[
	YUZEYLERI YENIDEN RENKLENDIRIR

	tintEffects yalnizca PARCACIK, Beam, Trail ve isiklara dokunur. Bazi
	paketler ise efekti dokulu PARCALARLA kuruyor: donen bir disk, uzerine
	yapistirilmis bir Decal, neon bir mesh... Onlarin rengi Color / Color3
	ozelliginde durur ve tintEffects oralara hic bakmaz.

	Girdap (VortexVFX) tam boyle bir paket: kademe rengine boyanmis
	olmasina ragmen ekranda hep ayni mavi duruyordu, cunku renk parcacikta
	degil parcanin kendisindeydi.

	Ayni tint() kurallari gecerli: preserveShading acikken parcanin kendi
	parlaklik/doygunluk yapisi korunur, yalnizca renk TONU kademeninkine
	doner -- yani koyu bir kenar koyu, parlak bir cekirdek parlak kalir.

	keep: adi gecen dallar ve icerikleri disarida kalir (tintEffects ile ayni).
]]
function Assets.tintSurfaces(root: Instance, color: Color3, preserveShading: boolean?, keep: { string }?, vividness: number?)
	local keepShading = preserveShading ~= false
	local vivid = math.clamp(vividness or 0.85, 0, 1)

	local nodes = root:GetDescendants()
	table.insert(nodes, root)

	for _, node in nodes do
		if isProtected(node, root, keep) then
			continue
		end

		--[[
			Tamamen saydam parcalara dokunulmuyor: onlar genelde efektin
			tasiyicisi (parcaciklarin bagli oldugu gorunmez govde) ve
			renklendirilirse gorunur hale gelmezler ama isi da yok.
		]]
		if node:IsA("BasePart") then
			if node.Transparency < 1 then
				node.Color = tint(node.Color, color, keepShading, vivid)
			end
		elseif node:IsA("Decal") or node:IsA("Texture") then
			node.Color3 = tint(node.Color3, color, keepShading, vivid)
		elseif node:IsA("ImageLabel") then
			node.ImageColor3 = tint(node.ImageColor3, color, keepShading, vivid)
		end
	end
end

--[[
	SABLONDAKI SCRIPTLERI SILER

	Toolbox'tan gelen efekt paketlerinin icinde cogu zaman kendi kucuk
	scriptleri olur: dondurme, yanip sonme, olcek animasyonu... Iki sebeple
	temizleniyor:

	  1. CAKISMA. Girdabin donusunu oyunun kendisi yonetiyor; paketin kendi
	     dondurme scripti ayni modeli ayri bir eksende cevirince efekt yan
	     yatmis gibi donuyordu.

	  2. GUVENLIK. 12 Eylul 2026'da haritada toolbox modellerine saklanmis
	     72 arka kapi bulundu (bkz. tools/scan.luau). Efekt paketinin icinde
	     script CALISTIRMAK icin bir sebep yok; olmayan script zarar veremez.

	Silinen scriptler yalnizca OYUNUN kullandigi kopyadan gider; Studio'daki
	orijinal sablona dokunulmaz.
]]
function Assets.stripScripts(root: Instance): number
	local doomed: { Instance } = {}

	for _, node in root:GetDescendants() do
		if node:IsA("LuaSourceContainer") then
			table.insert(doomed, node)
		end
	end

	for _, node in doomed do
		node:Destroy()
	end

	return #doomed
end

--[[
	PARCACIKLARI RENGIN KENDI TONLARINA CEVIRIR

	Duz tek renk verildiginde parcaciklar ekranda BEYAZA patliyordu. Sebep
	renk degil LightEmission: 1'e yakin oldugunda parcacik EKLEMELI cizilir,
	yani rengi ne olursa olsun arkasindaki goruntunun uzerine parlaklik
	biner ve merkez bembeyaz olur.

	Burada iki sey birden yapiliyor:

	  1. GECIS   Kademe renginin ACIK tonundan KOYU tonuna bir gecis
	             kuruluyor (tam olarak flyboard tahtalarindaki gibi).
	             Boylece efektin derinligi oluyor ama rengi hep kademenin
	             rengi kaliyor -- beyaz hic girmiyor.

	  2. TAVAN   LightEmission ve isik parlakligi tavana cekiliyor, yani
	             eklemeli patlama kisiliyor.

	opts:
	  lightMix        acik uc ne kadar beyaza yaklassin (0 = hic)
	  darkMix         koyu uc ne kadar siyaha yaklassin
	  lightEmission   parcacik parlamasinin tavani
	  lightBrightness isiklarin parlaklik tavani
	  extraTransparency  butun parcaciklara eklenen saydamlik

	keep: adi gecen dallar ve icerikleri disarida kalir.
]]
function Assets.rampEffects(root: Instance, color: Color3, opts: any, keep: { string }?)
	local lightMix = opts.lightMix or 0.45
	local darkMix = opts.darkMix or 0.35
	local emission = opts.lightEmission
	local brightness = opts.lightBrightness
	local extra = opts.extraTransparency or 0

	--[[
		GECIS: cekirdek -> acik -> renk -> koyu

		Parcaciklarin parlamasini TAMAMEN kismak da kotu duruyordu -- efekt
		duz ve cansiz kaliyor. Bu yuzden en basta kisa bir CEKIRDEK durak
		var: rengin cok acik tonu, yani parlak ama hala kademenin rengi.
		Beyaz degil, beyaza YAKIN.

		coreMix bunu ayarlar; verilmezse acik tonun kendisi kullanilir ve
		gecis eski uc duragina doner.
	]]
	local cekirdek = color:Lerp(Color3.new(1, 1, 1), opts.coreMix or lightMix)
	local acik = color:Lerp(Color3.new(1, 1, 1), lightMix)
	local koyu = color:Lerp(Color3.new(0, 0, 0), darkMix)

	local gecis = ColorSequence.new({
		ColorSequenceKeypoint.new(0, cekirdek),
		ColorSequenceKeypoint.new(0.18, acik),
		ColorSequenceKeypoint.new(0.55, color),
		ColorSequenceKeypoint.new(1, koyu),
	})

	local nodes = root:GetDescendants()
	table.insert(nodes, root)

	for _, node in nodes do
		if isProtected(node, root, keep) then
			continue
		end

		if node:IsA("ParticleEmitter") or node:IsA("Beam") or node:IsA("Trail") then
			node.Color = gecis

			if emission and node:IsA("ParticleEmitter") then
				node.LightEmission = math.min(node.LightEmission, emission)
			end

			--[[
				Saydamlik EKLENEREK uygulanir, ustune yazilmaz: paketin
				kendi solma egrisi (dogarken belirip olurken kaybolma)
				korunmali. Zarf de birlikte kirpiliyor -- zarf degeri
				degerin disina tasarsa Roblox NumberSequence'i reddediyor
				ve efektin tamami curuyor.
			]]
			if extra > 0 then
				local keys = {}
				for _, key in node.Transparency.Keypoints do
					local value = math.clamp(key.Value + extra, 0, 1)
					local envelope = math.min(key.Envelope, value, 1 - value)
					table.insert(keys, NumberSequenceKeypoint.new(key.Time, value, envelope))
				end
				node.Transparency = NumberSequence.new(keys)
			end
		elseif node:IsA("Light") then
			node.Color = color
			if brightness then
				node.Brightness = math.min(node.Brightness, brightness)
			end
		end
	end
end

--[[
	SIYAH EFEKTLERI KALDIRIR

	Hazir paketlerde efektin icinde bir de KOYU duman/golge katmani oluyor.
	Renklendirme onlara dokunmuyor (parlaklik 0 olan bir renk her tonda
	yine siyahtir), o yuzden kademe rengi ne olursa olsun siyah bulut
	oldugu gibi kaliyor ve efektin onune geciyor.

	Burada o katmanlar tamamen siliniyor: bir yayicinin BUTUN renk
	duraklarinin parlakligi threshold'un altindaysa o yayici "siyah
	katman" sayilir ve kaldirilir. Icinde tek bir aydinlik durak bile
	olan yayiciya dokunulmaz -- karanlikta baslayip renge acilan gecisler
	efektin kendi tasarimidir.

	keep: adi burada gecen dallar (orn. Rocks) hic incelenmez.
]]
function Assets.removeDarkEffects(root: Instance, threshold: number, keep: { string }?)
	local doomed: { Instance } = {}

	for _, node in root:GetDescendants() do
		if isProtected(node, root, keep) then
			continue
		end

		if node:IsA("ParticleEmitter") or node:IsA("Trail") or node:IsA("Beam") then
			local brightest = 0
			for _, key in node.Color.Keypoints do
				local _, _, value = key.Value:ToHSV()
				if value > brightest then
					brightest = value
				end
			end

			if brightest <= threshold then
				table.insert(doomed, node)
			end
		end
	end

	for _, node in doomed do
		if node.Parent then
			node:Destroy()
		end
	end
end

--[[
	GOZ ALAN BEYAZLARI YUMUSATIR

	Paketteki efektin ici bembeyaz parliyor. Renklendirme oraya dokunamaz:
	doygunlugu sifir olan bir renk hangi tona cevrilirse cevrilsin beyaz
	kalir. Bu yuzden beyazlar AYRICA ele aliniyor.

	NE YAPAR
	  1. Efektin HER yerinde beyaz sayilan renk duraklarini bulur --
	     yayicinin cogunlugu beyaz olmasa bile. (Onceki surum yalnizca
	     "cogunlugu beyaz" yayicilari isliyordu; mor bir gradyanin
	     ortasindaki beyaz cekirdek elenmiyor ve parlamaya devam ediyordu.)
	  2. Cogunu kademe renginin KISILMIS haliyle degistirir.
	  3. Cok kucuk bir kismini (opts.highlight orani) sonuk bir beyaz
	     olarak birakir -- efekt tamamen duzlesmesin, azicik highlight kalsin.
	  4. Dokundugu yayicilarin LightEmission degerini kisar.

	NEDEN KADEMEYE GORE FARKLI KISILIYOR
	Goz alan sey "parlak + renksiz" birlesimidir. Kademe rengi ne kadar
	DOYGUNSA parlakligi o kadar korunur:
	    Common  (renksiz)  -> tamamen griye iner
	    Mythic  (kirmizi)  -> rengini korur
	Boylece Common gri, digerleri kendi renginde ama beyazsiz gorunur.

	TINTEFFECTS'TEN SONRA cagrilmali: renklendirme parlakligi korudugu
	icin beyazlar ondan sonra da beyaz kalir, yani hala bulunabilirler --
	ve buradaki sonuclari sonradan ezen bir sey olmaz.

	opts:
	    saturation     -- bu doygunlugun ALTINDAKI renk beyaz sayilir
	    value          -- ve bu parlakligin USTUNDE olmali
	    grey           -- RENKSIZ kademelerde parlaklik tavani (Common)
	    maxValue       -- DOYGUN kademelerde parlaklik tavani (Mythic, Rare...)
	    saturationRef  -- bu doygunlugun ustundeki kademeler hic kisilmaz
	    highlight      -- beyazlarin kaci highlight olarak kalir (0..1)
	    highlightValue -- o highlight ne kadar parlak olsun (0..1)
	    glow           -- dokunulan yayicilarin LightEmission tavani
]]
function Assets.softenWhites(root: Instance, color: Color3, opts: any, keep: { string }?)
	local maxSaturation = opts.saturation or 0.35
	local minValue = opts.value or 0.8
	local greyValue = math.clamp(opts.grey or 0.35, 0, 1)
	local satRef = math.max(opts.saturationRef or 0.5, 0.01)
	local maxValue = math.clamp(opts.maxValue or 0.6, 0, 1)
	local highlightRatio = math.clamp(opts.highlight or 0.15, 0, 1)
	local glow = math.clamp(opts.glow or 0.05, 0, 1)

	-- Beyazin yerine gececek renk: kademenin tonu, kisilmis parlaklikla
	local hue, saturation, value = color:ToHSV()
	local ceiling = greyValue + (maxValue - greyValue) * math.min(saturation / satRef, 1)
	local replacement = Color3.fromHSV(hue, saturation, math.min(value, ceiling))

	-- Korunacak azicik highlight: sonuk, kirik bir beyaz
	local highlight = Color3.fromHSV(0, 0, math.clamp(opts.highlightValue or 0.8, 0, 1))

	local function isWhite(shade: Color3): boolean
		local _, s, v = shade:ToHSV()
		return s <= maxSaturation and v >= minValue
	end

	--[[
		Highlight dagitimi: her beyaz durakta "simdiye kadar kaci highlight
		kalmaliydi" hesaplanir, eksikse bu durak highlight olur. Boylece
		korunan beyazlar efektin icine esit araliklarla serpistirilir.
	]]
	local seen, kept = 0, 0

	local function pick(): Color3
		seen += 1
		local quota = math.floor(seen * highlightRatio + 0.5)
		if quota > kept then
			kept += 1
			return highlight
		end
		return replacement
	end

	for _, node in root:GetDescendants() do
		if isProtected(node, root, keep) then
			continue
		end

		if node:IsA("ParticleEmitter") or node:IsA("Trail") or node:IsA("Beam") then
			local touched = false
			local keys = {}

			for _, key in node.Color.Keypoints do
				local shade = key.Value
				if isWhite(shade) then
					shade = pick()
					touched = true
				end
				table.insert(keys, ColorSequenceKeypoint.new(key.Time, shade))
			end

			if touched then
				node.Color = ColorSequence.new(keys)

				--[[
					LightEmission 1 iken parcacik EKLEMELI cizilir: rengi ne
					olursa olsun arkasindaki her seyin uzerine parlaklik
					biner ve koyu bir parcacik bile bembeyaz gorunur.
				]]
				if node:IsA("ParticleEmitter") then
					node.LightEmission = math.min(node.LightEmission, glow)
				end
			end
		elseif node:IsA("Light") and isWhite(node.Color) then
			node.Color = replacement
		elseif node:IsA("BasePart") and isWhite(node.Color) then
			-- Neon beyaz parcalar da en az parcaciklar kadar goz aliyor
			node.Color = replacement
		end
	end
end

--[[
	Tek seferlik patlama: butun parcacik yayicilar ayni anda bir yumak atar.

	Rate'i sifir olmayan yayicilar bundan sonra akmaya devam eder; cagiran
	taraf kisa bir sure sonra Assets.stopEmitters ile onlari susturmali.
]]
function Assets.playBurst(root: Instance, amount: number)
	for _, node in root:GetDescendants() do
		if node:IsA("ParticleEmitter") then
			node:Emit(amount)
		end
	end
end

function Assets.stopEmitters(root: Instance)
	for _, node in root:GetDescendants() do
		if node:IsA("ParticleEmitter") then
			node.Enabled = false
		end
	end
end

------------------------------------------------------------------
-- MODEL OLCUSU
------------------------------------------------------------------

--[[
	BRAINROT MODEL BOYUTU  --  neden normalize ediyoruz

	Paketteki modeller birbirinden cok farkli olculerde export edilmis:
	bir tanesi 3 stud, digeri 120 stud. Boyut carpani (Tiny 0.25 .. Huge 2)
	dogrudan uygulaninca 120 studluk bir model Huge'da 240 stud oluyor ve
	haritayi kapatiyordu -- "Bananita Dolphinita ve Orcalero Orcala harita
	kadar buyuk" sikayetinin sebebi buydu.

	Cozum: model ONCE ortak bir tabana indirilir (en uzun kenari targetSize
	kadar olur), boyut carpani ONDAN SONRA uygulanir. Boylece Huge bir
	Bananita ile Huge bir Tralalero ayni buyuklukte durur ve model paketine
	yeni bir sey eklendiginde olcusuyle ugrasmak gerekmez.
]]
--[[
	BRAINROT ELDE NEREDE DURUYOR

	Tool'un Handle'i, esya kusanildiginda Roblox'un kendiliginden kurdugu
	RightGrip baglantisiyla SAG ELE yapisir. Animasyon yalnizca KARAKTERIN
	kemiklerini oynatir; brainrot eli zaten takip eder. Yani animasyona
	brainrot'u temsil eden bir parca koymana GEREK YOK.

	Brainrot'un ele gore nerede duracagi buradan ayarlanir:
	    position -- ele gore kayma, stud  (X sag, Y yukari, Z ileri/-geri)
	    rotation -- derece cinsinden donus

	Iki elle gogsun onunde tasiniyor gibi gostermek icin ornegin:
	    position = Vector3.new(0, -1, -1.5)

	Butun brainrotlar ortak tabana indirildigi icin (BrainrotSize.toolSize)
	tek ayar hepsinde tutar -- Tiny de Huge de ayni noktada durur, sadece
	boyutlari farkli olur.
]]
Assets.BrainrotGrip = {
	position = Vector3.new(0, 0, 0),
	rotation = Vector3.new(0, 0, 0),
}

--[[
	BRAINROT NEREDE TASINIYOR

	mode = "head"  ->  KAFANIN USTUNDE tasinir (Steal a Brainrot tarzi)
	mode = "hand"  ->  normal Roblox tutusu, sag elde (BrainrotGrip gecerli)

	"head" modunda Roblox'un ele takan RightGrip baglantisi kaldirilip
	yerine KAFAYA giden kendi kaynagimiz konur. Boylece brainrot animasyonda
	elin nereye gittiginden BAGIMSIZ olarak hep kafanin tam ortasinda durur;
	animasyon yalnizca kollari poz verir.

	YUKSEKLIK OTOMATIK

	Sabit bir yukseklik verilmiyor: brainrot'un KENDI boyundan hesaplaniyor.
	Boyutlar Tiny'de 0.6 studdan Huge'da 5 studa cikiyor; sabit degerde
	Tiny havada asili kalir, Huge kafanin icine gomulurdu.

	Hesap modelin GORSEL MERKEZINE gore yapilir, Handle'a gore degil --
	paket modellerinde Handle govdenin ortasinda olmayabiliyor.

	headGap       -- kafanin tepesi ile brainrot'un alti arasindaki bosluk
	headOffset    -- yana (X) ve one/arkaya (Z) kaydirma; Y'ye dokunma,
	                 yukseklik zaten otomatik
	headRotation  -- brainrot'un kendi ekseninde donusu (derece)
]]
Assets.BrainrotHold = {
	mode = "head",
	headGap = 0.25,
	headOffset = Vector3.new(0, 0, 0),
	headRotation = Vector3.new(0, 0, 0),
}

--[[
	GPS ELDE NEREDE DURUYOR

	Dedektor artik telefon degil, ucunda top olan bir ANTEN; brainrot
	tasima animasyonuyla (iki kol yukarida) tasiniyor. Antenin elin
	neresinden tutuluyor gorunecegi buradan ayarlanir:

	    position -- ele gore kayma, stud. Y'yi BUYUTURSEN anten yukari
	                kayar (el sapin dibine yaklasir), kucultursen asagi.
	    rotation -- derece cinsinden donus. Anten yatik duruyorsa X'e
	                90 ya da -90 vererek dikey hale getir.

	Model KODDA uretildigi icin bu tek ayar butun seviyelerde ve butun
	skinlerde tutar.
]]
Assets.GPSGrip = {
	position = Vector3.new(0, 0, 0),
	--[[
		SIFIR = Roblox'un varsayilan tutusu.

		Bir ara X'te 90 derece cevriliyordu (anteni dikmek icin); tutus
		animasyonuyla birlikte kaldirildi. Dedektor artik hicbir ozel
		ayara tabi degil, normal bir tool gibi tutuluyor. Ileride yeri
		degistirilmek istenirse ayar burada duruyor.
	]]
	rotation = Vector3.new(0, 0, 0),
}

Assets.BrainrotSize = {
	-- Base slotunda duran modelin taban boyu (Regular = tam bu kadar)
	slotSize = 5,
	-- Elde tasinirken; ele sigmasi icin daha kucuk
	toolSize = 4.5,
	-- Guvenlik siniri: olcu hesabi sacmalarsa model bu araligin disina cikmaz
	minScale = 0.01,
	maxScale = 25,
}

--[[
	Modelin DUNYA UZAYINDAKI gercek sinir kutusu.

	Model:GetBoundingBox() kutuyu PrimaryPart'in eksenine gore hizalar;
	parcalar o eksene gore donukse kutu gercek sinirlari yansitmaz. Burada
	her parcanin donmus kutusu tek tek hesaplanip birlestiriliyor.

	OLCUME KATILMAYAN PARCALAR
	Modele sonradan eklenen gorunmez yardimcilar (ornegin etiket tutamagi)
	gercek boyutu bozar: 1x1x1 bir kup bile kucuk bir modelin merkezini
	kaydirabilir. Bu yuzden Assets.MeasureSkipAttribute niteligi konmus
	parcalar hesaba katilmaz.

	Donen: en kucuk kose, en buyuk kose. Parca yoksa nil.
]]
Assets.MeasureSkipAttribute = "OlcuDisi"

--[[
	Ayni uyariyi Output'ta tekrarlamaz.
	Her brainrot uretiminde tetiklenen uyarilar saniyede onlarca satir
	yazip Output'u kullanilamaz hale getiriyor; sebebi bir kez gormek yeter.
]]
local warned: { [string]: boolean } = {}

function Assets.warnOnce(key: string, message: string)
	if warned[key] then
		return
	end
	warned[key] = true
	warn(message)
end

function Assets.worldBounds(model: Model): (Vector3?, Vector3?)
	local min: Vector3? = nil
	local max: Vector3? = nil

	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		-- Gorunmez yardimci parcalar modelin olcusune karismaz
		if part:GetAttribute(Assets.MeasureSkipAttribute) then
			continue
		end

		local cf, size = part.CFrame, part.Size

		-- Donmus kutunun eksenlere izdusumu (yari genislikler)
		local half = Vector3.new(
			math.abs(cf.RightVector.X) * size.X / 2
				+ math.abs(cf.UpVector.X) * size.Y / 2
				+ math.abs(cf.LookVector.X) * size.Z / 2,
			math.abs(cf.RightVector.Y) * size.X / 2
				+ math.abs(cf.UpVector.Y) * size.Y / 2
				+ math.abs(cf.LookVector.Y) * size.Z / 2,
			math.abs(cf.RightVector.Z) * size.X / 2
				+ math.abs(cf.UpVector.Z) * size.Y / 2
				+ math.abs(cf.LookVector.Z) * size.Z / 2
		)

		local low = cf.Position - half
		local high = cf.Position + half

		min = if min then Vector3.new(math.min(min.X, low.X), math.min(min.Y, low.Y), math.min(min.Z, low.Z)) else low
		max = if max
			then Vector3.new(math.max(max.X, high.X), math.max(max.Y, high.Y), math.max(max.Z, high.Z))
			else high
	end

	return min, max
end

--[[
	Modeli ortak tabana indirip boyut carpanini uygular.

	targetSize: bu modelin Regular boyuttaki hedef en uzun kenari
	conditionScale: Condition.scale(item.condition)  (Tiny 0.25 .. Huge 2)

	GetScale() ile carpiyoruz cunku ScaleTo mutlak olcek bekler: paket
	modeli 1'den farkli bir olcekle kaydedilmisse dogrudan ScaleTo yanlis
	sonuc verirdi.
]]
function Assets.fitModel(model: Model, targetSize: number, conditionScale: number)
	local cfg = Assets.BrainrotSize

	--[[
		PRIMARYPART GARANTISI

		GetScale ve ScaleTo modelin PIVOTU uzerinden calisir ve PrimaryPart'i
		olmayan modelde hata verir. Paketten klonlanan brainrot modellerinin
		cogunda PrimaryPart bos geliyor.

		Bu yuzden base slotunda calisip elde patliyordu: buildDisplay
		PrimaryPart'i kendisi atiyordu, buildBrainrot atmiyordu. Tool uretimi
		pcall icinde oldugu icin hata Output'a bir uyari olarak dusuyor ve
		brainrot envanter verisine giriyor ama CANTADA hic gorunmuyordu.

		Garantiyi cagiranlara birakmak yerine buraya koyuyoruz -- olcekleyen
		fonksiyon neye ihtiyaci oldugunu kendi saglasin.
	]]
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end

	if not model.PrimaryPart then
		return
	end

	local min, max = Assets.worldBounds(model)
	if not min or not max then
		return
	end

	local size = max - min
	local largest = math.max(size.X, size.Y, size.Z)
	if largest <= 0 then
		return
	end

	--[[
		OLCEKLEME ASLA OLUMCUL OLMAMALI

		ScaleTo/GetScale bircok sebeple hata verebiliyor; en yaygini modelin
		icinde eksik olcek degerleri olan bir Humanoid bulunmasi (paket
		modellerinin cogunda Humanoid var -- bkz. Assets.playAnimations).

		Bu hata yukari firladiginda Envanter'in tool uretimindeki pcall onu
		yutuyor ve BRAINROT CANTADA HIC OLUSMUYOR: veride duruyor, esya yok.
		Yani kozmetik bir sorun esyayi yok ediyordu.

		Artik hata burada durduruluyor: model olceklenmemis haliyle kullanilir
		-- boyutu yanlis olabilir ama esya her zaman olusur. Sebep Output'a
		bir kez yazilir ki gercek hata gorunmez kalmasin.
	]]
	local factor = (targetSize * conditionScale) / largest

	-- GetScale de ScaleTo ile ayni sebeplerden patlayabilir; ikisi de iceride
	local ok, err = pcall(function()
		local scale = math.clamp(model:GetScale() * factor, cfg.minScale, cfg.maxScale)
		model:ScaleTo(scale)
	end)

	if not ok then
		Assets.warnOnce(`olceklenemedi: {model.Name}`, `[Assets] "{model.Name}" olceklenemedi -- {tostring(err)}`)
	end
end

------------------------------------------------------------------
-- YARDIMCILAR
------------------------------------------------------------------

-- Bos string'i nil'e cevirir; "id verilmis mi?" kontrolu icin
function Assets.id(value: string?): string?
	if value and value ~= "" then
		return value
	end
	return nil
end

return Assets
