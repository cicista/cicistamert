--!strict
--[[
	INDEX  --  brainrot kesif defteri

	Soldaki mavi kitap dugmesi burayi acar. Katalogdaki BUTUN brainrotlar
	kademeye gore gruplanmis bir izgarada durur:

	  bulunmus   ->  modelin 3B onizlemesi + adi + saniyelik geliri
	  bulunmamis ->  koyu silueti ve "???"

	--------------------------------------------------------------
	RESIMLER NEREDEN GELIYOR

	Brainrotlarin hazir resmi (decal / asset id) YOK; oyunda yalnizca
	ReplicatedStorage > Assets > Brainrots altindaki MODELLER var. Bu
	yuzden onizleme ViewportFrame ile ciziliyor: modelin bir kopyasi
	kucuk bir sahneye konup kameraya oturtuluyor.

	Yan faydasi: model degistiginde/skin eklendiginde Index kendiliginden
	guncel kalir, ayrica elle resim yukleme isi hic olmaz.

	--------------------------------------------------------------
	NEDEN HEPSI BIR ANDA CIZILMIYOR  (GORUS PENCERESI)

	Katalog 87 brainrot tutuyor. Her hucreye bir ViewportFrame konsa 87
	ayri 3B sahne ayni anda cizilir -- kaydirma
	listesinin gorunmeyen kismindakiler dahil, cunku ViewportFrame kirpma
	disinda da render edilir. Dusuk makinede oyun bunun altinda kalir.

	Cozum: yalnizca EKRANDA OLAN (ve bir miktar pay birakilmis) hucrelerin
	onizlemesi kurulur, pencereden cikanlar yikilir. Boylece ayni anda
	yasayan sahne sayisi bir tutamda kalir. Hucrelerin kendisi (cerceve,
	yazi) bastan kuruluyor; yalnizca 3B icerik gelip gidiyor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Assets = require(Shared:WaitForChild("Assets"))
local Format = require(Shared:WaitForChild("Format"))
local Icons = require(Shared:WaitForChild("Icons"))
local Net = require(Shared:WaitForChild("Net"))

local UI = require(script.Parent:WaitForChild("UI"))

local IndexAc = Net.event("IndexAc")
local IndexDurum = Net.event("IndexDurum")

local Index = {}

-- Hucre olculeri
-- Ada satiri eklenince yukseklik 156'dan buyutuldu; yoksa yazi tasiyordu
local HUCRE = Vector2.new(132, 176)
local BOSLUK = 10

-- Gorus penceresinin ustune/altina birakilan pay (piksel)
local PAY = 260

--[[
	BULUNMAMIS BRAINROTUN ONIZLEME TONU

	Onizleme siyaha boyanip silue yapilmiyor: oyuncu brainrotun NE
	OLDUGUNU gorsun, yalnizca "henuz bende yok" bilgisini alsin. Bu ton
	modeli taninir birakip acikca soluklastiriyor.

	1'e yaklastirdikca kilitli hucre bulunmus gibi gorunur, 0'a
	yaklastirdikca siluete doner.
]]
local KILITLI_TON = Color3.fromRGB(120, 120, 132)

--[[
	KAMERANIN BAKTIGI YON  --  dunya ekseninde, TAM KARSIDAN

	Y bileseni 0: en ufak yukseklik payi bile kucuk hucrede tepeden
	bakisa benziyor. Goz hizasi kaldi.

	Z neden -1: brainrot modelleri yuzu -Z'ye bakacak sekilde hazirlanmis,
	yani onlerine gecmek icin kameranin -Z tarafinda durmasi gerekiyor.

	NEDEN MODELDEN OKUNMUYOR
	Bir ara yon modelin kendisinden (GetBoundingBox'in LookVector'u)
	okunuyordu, "model dondurulse de dogru kalir" diye. Olcum bunun bosa
	oldugunu gosterdi: Assets > Brainrots altindaki 617 modelin HEPSINDE
	PrimaryPart var ve hepsinin LookVector'u (0, 0, -1) -- yani hicbiri
	dondurulmemis, okunan deger her zaman ayni sabit. Ustelik PrimaryPart'in
	donmemis olmasi mesh'in GORSEL olarak hangi yone baktigini soylemiyor;
	ithal mesh'lerde ikisi alakasiz olabiliyor. Bu yuzden yon burada
	acikca yaziliyor: ne yaptigi belli ve tek yerden ayarlanir.
]]
local BAKIS_YONU = Vector3.new(0, 0, -1)

--[[
	ONIZLEME ISIGI

	ViewportFrame sahnenin Lighting'ini KULLANMAZ; kendi Ambient/LightColor
	alanlari var ve varsayilanlari kisik (200 / 140). Bu yuzden bulunmus
	brainrotlar da soluk cikiyor, oyuncu kilitliden ayirt edemiyordu.
	Ikisini de tavana cekmek modelin kendi renklerini oldugu gibi veriyor.
]]
local ISIK = Color3.fromRGB(255, 255, 255)
local ISIK_YONU = Vector3.new(-0.4, -0.7, -0.6)

-- Kilitli hucrenin zemini: kademe rengi yerine olu gri
local KILITLI_ZEMIN = Color3.fromRGB(58, 62, 74)

--[[
	FARE USTUNE GELDIGINDE

	Iki ayri his veriliyor:

	  BULUNAN   buyume + kademe renginde supurulen parilti + modelin
	            hafif sag-sol salinimi. "Bu benim" hissi.
	  KILITLI   yalnizca kucuk bir buyume ve konturun belirginlesmesi.
	            Hareket yok -- odul verilmemis bir seyi kutlamak yanlis.

	Buyume UIScale ile yapiliyor ve hucrenin ICINDEKI katmana uygulaniyor:
	UIScale nesneyi AnchorPoint'inden buyutuyor, izgara hucreleri ise
	(0,0) ile duruyor. Dogrudan hucreye verilse saga-asagi tasip
	komsularinin ustune binerdi (UI.hover'in kendi notu da bunu soyluyor).
]]
local HOVER_BUYUME = 1.07
local HOVER_BUYUME_KILITLI = 1.03

-- Pariltinin bir uctan bir uca supurme suresi (saniye)
--[[
	Bandin BASLANGIC ve BITIS yeri (kutu genisliginin orani).

	Iki uc da kutunun hemen disinda: band girip cikiyor, ortada beliriverip
	kaybolmuyor. Eskiden -0.35..1.35 idi; bant kucultulunce bu kadar genis
	paya gerek kalmadi.
]]
local PARILTI_BAS = -0.22
local PARILTI_BIT = 1.22

local PARILTI_SURE = 1.1

-- Modelin salinim genligi ve hizi. Tam tur atmiyor: arkasi gorunmesin.
local SALINIM_ACI = math.rad(24)
local SALINIM_HIZ = 1.7

------------------------------------------------------------------
-- KATALOGU KADEMEYE GORE SIRALA
--
-- Rarity.Order esas alinir; katalogda olup Order'da olmayan bir kademe
-- cikarsa sessizce dusmesin diye sona eklenir.
------------------------------------------------------------------
--[[
	ADA ADLARI

	Kimlik Studio'daki kum parcasinin adi; oyuncuya gosterilen ad ayri.
	4. ada oyunda "Alev Kum" ama parcanin adi hala "gizlikum".
]]
local ADA_ADI: { [string]: string } = {
	kum = "Main Island",
	sekerkum = "Candy Island",
	snowkum = "Snow Island",
	gizlikum = "Lava Island",
	deniz = "The Sea",
}

local function siraliKademeler(): { string }
	local sirali = {}
	local gorulen: { [string]: boolean } = {}

	for _, id in Rarity.Order do
		for _, info in Brainrots.List do
			if info.rarity == id and not gorulen[id] then
				gorulen[id] = true
				table.insert(sirali, id)
			end
		end
	end

	for _, info in Brainrots.List do
		if not gorulen[info.rarity] then
			gorulen[info.rarity] = true
			table.insert(sirali, info.rarity)
		end
	end

	return sirali
end

------------------------------------------------------------------
-- ARAYUZ
------------------------------------------------------------------
local ekran = Instance.new("ScreenGui")
ekran.Name = "IndexDefteri"
ekran.ResetOnSpawn = false
ekran.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ekran.Parent = playerGui

local panel = UI.panel(ekran, UDim2.fromOffset(620, 560), "Index")

UI.text({
	text = "INDEX",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Left,
	frameSize = UDim2.new(1, -120, 0, 36),
	position = UDim2.fromOffset(20, 16),
	parent = panel,
	name = "Baslik",
})

local sayac = UI.text({
	text = "",
	size = UI.Sizes.label,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Left,
	frameSize = UDim2.new(1, -120, 0, 22),
	position = UDim2.fromOffset(20, 52),
	parent = panel,
	name = "Sayac",
})

UI.closeButton(panel).Activated:Connect(function()
	panel.Visible = false
end)

local liste = Instance.new("ScrollingFrame")
liste.Name = "Liste"
liste.Position = UDim2.fromOffset(14, 84)
liste.Size = UDim2.new(1, -28, 1, -98)
liste.BackgroundTransparency = 1
liste.BorderSizePixel = 0
liste.ScrollBarThickness = 6
liste.CanvasSize = UDim2.new()
liste.AutomaticCanvasSize = Enum.AutomaticSize.Y
liste.ScrollingDirection = Enum.ScrollingDirection.Y
liste.Parent = panel

local dizilim = Instance.new("UIListLayout")
dizilim.Padding = UDim.new(0, 12)
dizilim.SortOrder = Enum.SortOrder.LayoutOrder
dizilim.Parent = liste

------------------------------------------------------------------
-- HUCRELER
------------------------------------------------------------------
type Hucre = {
	name: string,
	rarity: string,
	renk: Color3,
	-- Izgara hucresi: gorunmez buton, yalnizca fareyi yakalar
	kutu: TextButton,
	-- Gorunen kutu; buyume bunun uzerinde
	ic: Frame,
	olcek: UIScale,
	-- Kutunun cevresindeki kademe renkli kontur; bulundugunda kalinlasir
	cizgi: UIStroke,
	yuva: Frame,
	-- Bulunan hucrede supurulen isik bandi
	parilti: Frame,
	ad: TextLabel,
	gelir: TextLabel,
	-- Modeli bulunamayan brainrotta onizleme yerine bu gorunur
	yedek: TextLabel,
	-- Bulunmamis brainrotun kosesindeki kilit rozeti
	kilit: ImageLabel,
	kesif: boolean,
	-- Kurulmus 3B onizleme; pencereden cikinca yikilip nil'e doner
	onizleme: ViewportFrame?,
	--[[
		Salinim icin kameraya ve cercevelemeye tekrar erisim gerekiyor;
		onizleme yikilinca ucu de nil'e doner.
	]]
	kamera: Camera?,
	merkez: Vector3?,
	uzaklik: number?,
	--[[
		Model aramasi bir kez bos dondugunde isaretlenir. Olmasa her
		kaydirmada var olmayan model tekrar tekrar aranirdi.
	]]
	modelYok: boolean,
}

local hucreler: { Hucre } = {}

-- Kilit ikonu tek sefer cozulup buradaki butun rozetlere yaziliyor
local kilitRozetleri: { ImageLabel } = {}

-- Kademe basligindaki kesif sayaclari: rarityId -> yazi
local kademeSayaclari: { [string]: TextLabel } = {}

--[[
	3B ONIZLEMEYI KUR

	Model kopyasi ViewportFrame'e konur ve kamera modelin sinir kutusuna
	gore geri cekilir -- boyle yapilinca kucuk ve kocaman modeller ayni
	buyuklukte gorunur, elle kamera mesafesi ayarlamak gerekmez.
]]
--[[
	ONIZLEMENIN TONUNU DURUMA GORE AYARLA

	ViewportFrame.ImageColor3 cizilen sahnenin tamamini carpar; bulunmamis
	brainrot boylece tek satirla soluklasiyor. Modeli ya da malzemeleri
	degistirmek gerekmiyor.
]]
local function onizlemeTonla(hucre: Hucre)
	if hucre.onizleme then
		hucre.onizleme.ImageColor3 = if hucre.kesif then Color3.new(1, 1, 1) else KILITLI_TON
	end
end

--[[
	Onizleme BULUNMAMIS brainrotlar icin de kuruluyor.

	Once yalnizca bulunanlara kuruluyordu ve panel bastan sona "?" ile
	doluydu -- Index'in asil isi olan "neler var, neye benziyorlar"
	sorusunu cevaplamiyordu. Artik hepsi ciziliyor, bulunmamis olanlar
	KILITLI_TON ile soluk ve kosesinde kilit rozetiyle duruyor.
]]
local function onizlemeKur(hucre: Hucre)
	if hucre.onizleme or hucre.modelYok then
		return
	end

	local model = Assets.brainrotModel(hucre.name)
	if not model then
		--[[
			Katalogda olup modeli olmayan brainrot. Isaretleniyor ki her
			kaydirmada yeniden aranmasin; hucrede adi ve "?" kaliyor.
		]]
		hucre.modelYok = true
		hucre.yedek.Visible = true
		return
	end

	--[[
		BIR DAHA KLONLANMIYOR

		Assets.brainrotModel zaten Clone() donduruyor (bkz. Assets >
		findModel), yani elimizdeki nesne bize ait ozel bir kopya.
		Ustune bir Clone() daha atmak her hucre icin bosa bir kopya
		uretip sahipsiz birakiyordu.
	]]
	local kopya = model

	-- Onizlemede script/ses/parcacik calismasin: sahne sessiz ve sabit olsun
	for _, nesne in kopya:GetDescendants() do
		if
			nesne:IsA("BaseScript")
			or nesne:IsA("Sound")
			or nesne:IsA("ParticleEmitter")
			or nesne:IsA("Beam")
		then
			nesne:Destroy()
		end
	end

	local vp = Instance.new("ViewportFrame")
	vp.Name = "Onizleme"
	vp.Size = UDim2.fromScale(1, 1)
	vp.BackgroundTransparency = 1
	-- Bkz. ISIK: ViewportFrame sahne isigini kullanmaz, kendi isigi kisik gelir
	vp.Ambient = ISIK
	vp.LightColor = ISIK
	vp.LightDirection = ISIK_YONU
	-- Parilti bandi (ZIndex 3) modelin USTUNDEN gecsin
	vp.ZIndex = 2
	vp.Parent = hucre.yuva

	kopya.Parent = vp

	local kamera = Instance.new("Camera")
	kamera.Parent = vp
	vp.CurrentCamera = kamera

	--[[
		Kamerayi modele oturt.

		GetBoundingBox modelin merkezini ve kutu olcusunu verir; kutunun
		kosegeni (Magnitude) kadar geri cekilmek her boyuttaki modeli
		kadraja sigdirir. 0.9 carpani kutuyu hafifce doldurur, 1'in ustu
		bosluk birakir.
	]]
	local ok, cf, boyut = pcall(function()
		return kopya:GetBoundingBox()
	end)

	if ok and cf and boyut then
		local uzaklik = boyut.Magnitude * 0.9

		--[[
			Kamera modelin ONUNE, goz hizasina konur. Yon dunya ekseninde
			sabit; sebebi BAKIS_YONU'nun basinda yazili.
		]]
		kamera.CFrame = CFrame.lookAt(cf.Position + BAKIS_YONU * uzaklik, cf.Position)

		-- Fare ustundeyken salinim icin saklaniyor
		hucre.kamera = kamera
		hucre.merkez = cf.Position
		hucre.uzaklik = uzaklik
	end

	hucre.yedek.Visible = false
	hucre.onizleme = vp
	onizlemeTonla(hucre)
end

local function onizlemeYik(hucre: Hucre)
	if hucre.onizleme then
		hucre.onizleme:Destroy()
		hucre.onizleme = nil
	end
	-- Kamera onizlemenin cocuguydu, birlikte gitti
	hucre.kamera = nil
	hucre.merkez = nil
	hucre.uzaklik = nil
end

--[[
	HUCRENIN GORUNUMUNU DURUMA GORE CIZ

	Ad ve gelir HER ZAMAN gorunur. Once bulunmamis olanlarda gizliydi ve
	panel isimsiz "?" kutularindan olusuyordu; Index ayni zamanda bir
	basvuru listesi, "hangi brainrotlar var ve ne kadar getiriyor"
	sorusunun cevabi olmali.

	Bulundu/bulunmadi ayrimi artik uc yerden okunuyor: onizlemenin tonu,
	kosedeki kilit rozeti ve ustteki sayac.
]]
local function hucreCiz(hucre: Hucre)
	hucre.gelir.Visible = true
	hucre.kilit.Visible = not hucre.kesif

	--[[
		BULUNAN HUCRE PARLAR, KILITLI OLAN SOLAR

		Sasmasin: seffafligi ters kurmusum, kilitli hucre (0.3)
		bulunandan (0.55) DAHA canli duruyordu. Artik ayrim uc yerden
		birden geliyor ki kucuk hucrede bile bir bakista okunsun:

		  zemin  : bulunan kademe renginde ve canli, kilitli olu gri
		  kontur : bulunanda kalin, kilitlide ince
		  model  : bulunan kendi renginde, kilitli KILITLI_TON ile soluk
	]]
	-- Kontur rengi hover sirasinda aydinlatiliyor; burada tabanina doner
	hucre.cizgi.Color = hucre.renk

	if hucre.kesif then
		hucre.yuva.BackgroundColor3 = hucre.renk
		hucre.yuva.BackgroundTransparency = 0.12
		hucre.cizgi.Thickness = 3
		hucre.cizgi.Transparency = 0
	else
		hucre.yuva.BackgroundColor3 = KILITLI_ZEMIN
		hucre.yuva.BackgroundTransparency = 0.25
		hucre.cizgi.Thickness = 1.5
		hucre.cizgi.Transparency = 0.45
	end

	onizlemeTonla(hucre)
end

------------------------------------------------------------------
-- FARE USTUNDE
------------------------------------------------------------------
local ustundeki: Hucre? = nil
local hoverT = 0

local function hoverBaslat(hucre: Hucre)
	ustundeki = hucre
	hoverT = 0

	local hedef = if hucre.kesif then HOVER_BUYUME else HOVER_BUYUME_KILITLI
	TweenService:Create(
		hucre.olcek,
		TweenInfo.new(UI.HoverTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = hedef }
	):Play()

	if hucre.kesif then
		hucre.parilti.Position = UDim2.fromScale(PARILTI_BAS, 0.5)
		hucre.parilti.Visible = true
		hucre.cizgi.Color = UI.shade(hucre.renk, 0.3)
	else
		-- Kilitlide tek degisiklik: kontur biraz belirginlesir
		hucre.cizgi.Transparency = 0.1
	end
end

local function hoverBitir(hucre: Hucre)
	if ustundeki == hucre then
		ustundeki = nil
	end

	TweenService:Create(
		hucre.olcek,
		TweenInfo.new(UI.HoverTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()

	hucre.parilti.Visible = false

	-- Renk/kalinlik degerlerini duruma gore geri koy
	hucreCiz(hucre)

	--[[
		Kamerayi notr cerceveye dondur. Yapilmazsa model fare ciktigi
		andaki egik acida donup kaliyor ve izgara duzensiz gorunuyor.
	]]
	local kamera, merkez, uzaklik = hucre.kamera, hucre.merkez, hucre.uzaklik
	if kamera and merkez and uzaklik then
		kamera.CFrame = CFrame.lookAt(merkez + BAKIS_YONU * uzaklik, merkez)
	end
end

local function hucreKur(parent: Instance, info: Brainrots.BrainrotInfo, sira: number): Hucre
	local renk = Rarity.color(info.rarity)

	--[[
		HUCRE IKI KATMAN

		kutu : izgaranin hucresi. Gorunmez bir BUTON -- tek isi fareyi
		       yakalamak. Frame'in MouseEnter/MouseLeave'i cocuklarin
		       uzerinde gezerken tekrar tekrar tetikleniyor; buton
		       guvenilir.
		ic   : gorunen kutu. Buyume bunun uzerinde, cunku UIScale
		       AnchorPoint'ten buyutuyor ve bu katman MERKEZINDEN
		       olcekleniyor. Dogrudan hucreye verilse izgarada
		       komsularina bindirirdi.
	]]
	local kutu = Instance.new("TextButton")
	kutu.Name = info.name
	kutu.Size = UDim2.fromOffset(HUCRE.X, HUCRE.Y)
	kutu.BackgroundTransparency = 1
	kutu.BorderSizePixel = 0
	kutu.AutoButtonColor = false
	--[[
		Parilti bandi ve fareyle buyume hucrenin DISINA tasiyordu: ic
		cerceve UIScale ile buyurken kutunun sinirlarini asiyor, komsu
		hucrenin uzerine sarkiyordu. Kirpma en distaki kutuda.
	]]
	kutu.ClipsDescendants = true
	kutu.Text = ""
	kutu.LayoutOrder = sira
	kutu.Parent = parent

	local ic = Instance.new("Frame")
	ic.Name = "Ic"
	ic.AnchorPoint = Vector2.new(0.5, 0.5)
	ic.Position = UDim2.fromScale(0.5, 0.5)
	ic.Size = UDim2.fromScale(1, 1)
	ic.BackgroundColor3 = UI.Colors.panelLight
	ic.BorderSizePixel = 0
	ic.Parent = kutu
	UI.corner(ic, 10)
	local cizgi = UI.stroke(ic, renk, 2)

	local olcek = Instance.new("UIScale")
	olcek.Name = "HoverOlcegi"
	olcek.Scale = 1
	olcek.Parent = ic

	--[[
		3B onizlemenin oturdugu kare.

		ClipsDescendants: parilti bandi kutudan tasmasin -- kirpilmadan
		hucrenin disina, komsu hucrenin ustune sarkiyordu.
	]]
	local yuva = Instance.new("Frame")
	yuva.Name = "Yuva"
	yuva.Position = UDim2.fromOffset(8, 8)
	yuva.Size = UDim2.fromOffset(HUCRE.X - 16, 96)
	yuva.BackgroundColor3 = renk
	yuva.BackgroundTransparency = 0.2
	yuva.BorderSizePixel = 0
	yuva.ClipsDescendants = true
	yuva.Parent = ic
	UI.corner(yuva, 8)

	--[[
		PARILTI BANDI
	--[[
		PARILTI BANDI

		Yumusak kenarli bir isik seridi; bir uctan bir uca supuruluyor
		(bkz. RenderStepped surucusu).

		BANT DONDURULMUYOR -- SEBEBI ONEMLI
		Roblox, DONDURULMUS bir GuiObject'i ustundeki ClipsDescendants ile
		KIRPMAZ. Bant egik oldugu surece (Rotation ~= 0) onizleme kutusu
		"kirp" dese de bant disari tasiyor: ekranin yarisini kesen o beyaz
		cizgi buydu. Egimi kucultmek de ise yaramadi, cunku sorun egimin
		MIKTARI degil VARLIGI.

		Cozum: cerceve DIMDIK duruyor, egik gorunumu GRADYAN veriyor.
		UIGradient'in Rotation'i nesneyi dondurmez, yalnizca renk rampasini
		egik uygular -- kirpma bozulmadan capraz isik hissi kaliyor.
	]]
	local parilti = Instance.new("Frame")
	parilti.Name = "Parilti"
	parilti.AnchorPoint = Vector2.new(0.5, 0.5)
	parilti.Position = UDim2.fromScale(PARILTI_BAS, 0.5)
	-- Tam kutu yuksekligi: dondurulmedigi icin fazladan paya gerek yok
	-- Biraz genis: solma yoluna daha cok yer kalsin, kenarlar yumusasin
	parilti.Size = UDim2.fromScale(0.42, 1)
	parilti.Rotation = 0
	parilti.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	parilti.BorderSizePixel = 0
	-- Onizlemenin (2) ustunde, kilidin (4) altinda
	parilti.ZIndex = 3
	parilti.Visible = false
	parilti.Parent = yuva
	local pGecis = Instance.new("UIGradient")
	--[[
		SOLMA EKSENI BANDIN DAR YONUNDE  (Rotation = 0)

		22 dereceye cevrilmisti ki isik capraz gorunsun; ama o zaman solma
		ekseni de capraz oluyor ve bandin SOL/SAG kenarlari tam opaklikta
		kaliyor -- kenarlardan bicakla kesilmis gibi duruyordu.

		Solma soldan saga olunca bant iki kenarindan da yumusakca eriyor.
		Capraz gorunumden vazgecildi: cerceveyi dondurmek kirpmayi bozuyor
		(bkz. yukarisi), gradyani dondurmek de kenarlari kesiyor.
	]]
	pGecis.Rotation = 0
	pGecis.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, renk),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, renk),
	})
	--[[
		Uclar TAM saydam, orta parlak. Araya birer durak daha konuyor:
		gecis daha uzun bir yola yayiliyor, yani kenarlar daha yumusak
		eriyor.
	]]
	pGecis.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0.8),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(0.75, 0.8),
		NumberSequenceKeypoint.new(1, 1),
	})
	pGecis.Parent = parilti
	pGecis.Parent = parilti

	--[[
		Modeli bulunamayan brainrot icin yedek. Onizleme kurulabilirse
		gizlenir; bastan gizli baslar ki model varken bir kare bile
		gorunmesin.
	]]
	local yedek = UI.text({
		text = "?",
		size = UI.Sizes.huge,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(0, 0, 0),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = yuva,
		name = "Yedek",
	})
	yedek.Visible = false

	--[[
		KILIT ROZETI

		Bulunmamis brainrotun isareti.

		Image BOS kuruluyor, ikon sonradan yaziliyor: hucreler script
		yuklenirken kuruluyor ve Icons modulu kendi yorumunda "istemci
		acilirken paket henuz replike edilmemis olabilir" diyor. Burada
		Icons.of cagirsak 87 rozetin hepsi bos donerdi.

		Ikonsuz rozet hicbir sey cizmez (arka plani saydam), yani ikon
		gelene kadar gorsel bir bozukluk olmuyor.
	]]
	local kilit = Instance.new("ImageLabel")
	kilit.Name = "Kilit"
	kilit.AnchorPoint = Vector2.new(1, 0)
	kilit.Position = UDim2.new(1, -4, 0, 4)
	kilit.Size = UDim2.fromOffset(20, 20)
	kilit.BackgroundTransparency = 1
	kilit.Image = ""
	kilit.ZIndex = 4
	kilit.Parent = yuva
	table.insert(kilitRozetleri, kilit)

	local ad = UI.text({
		text = info.name,
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -8, 0, 28),
		position = UDim2.fromOffset(4, 108),
		parent = ic,
		wrapped = true,
		name = "Ad",
	})
	UI.rarityStyle(ad, info.rarity)

	local gelir = UI.text({
		text = Format.perSecond(Brainrots.income(info.name, "Normal")),
		size = UI.Sizes.tiny,
		color = UI.Colors.textDim,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -8, 0, 18),
		position = UDim2.fromOffset(4, 136),
		parent = ic,
		name = "Gelir",
	})

	--[[
		HANGI ADADAN CIKAR

		Ayni kademe her adada farkli brainrotlar veriyor, o yuzden hucrede
		adanin adi da yaziyor -- oyuncu "bunu nerede arayacagim" sorusunu
		Index'ten cevapliyor.

		Kilitli hucrelerde de gorunur: hangi adaya gidilecegi bilgisi
		brainrotun kendisini ele vermiyor, aksine yol gosteriyor.
	]]
	local ada = UI.text({
		text = ADA_ADI[string.lower(info.island or "")] or "?",
		size = UI.Sizes.tiny,
		color = UI.Colors.textDim,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -8, 0, 16),
		position = UDim2.fromOffset(4, 155),
		parent = ic,
		name = "Ada",
	})

	local hucre: Hucre = {
		name = info.name,
		rarity = info.rarity,
		renk = renk,
		kutu = kutu,
		ic = ic,
		olcek = olcek,
		cizgi = cizgi,
		yuva = yuva,
		parilti = parilti,
		ad = ad,
		gelir = gelir,
		yedek = yedek,
		kilit = kilit,
		kesif = false,
		onizleme = nil,
		kamera = nil,
		merkez = nil,
		uzaklik = nil,
		modelYok = false,
	}

	kutu.MouseEnter:Connect(function()
		hoverBaslat(hucre)
	end)
	kutu.MouseLeave:Connect(function()
		hoverBitir(hucre)
	end)

	return hucre
end

------------------------------------------------------------------
-- IZGARAYI BIR KEZ KUR
--
-- Katalog oyun boyunca degismiyor, yani hucreler tek sefer kurulup
-- sonra yalnizca durumlari guncelleniyor.
------------------------------------------------------------------
local kademeSirasi = 0

for _, rarityId in siraliKademeler() do
	kademeSirasi += 1

	local baslik = Instance.new("Frame")
	baslik.Name = `Kademe_{rarityId}`
	baslik.Size = UDim2.new(1, -10, 0, 26)
	baslik.BackgroundTransparency = 1
	baslik.LayoutOrder = kademeSirasi * 10
	baslik.Parent = liste
	-- Doku basligin arkasinda kalsin, yazi onde olsun
	baslik.ZIndex = 1

	--[[
		KADEME BASLIGI

		Solda kademe adi, sagda o kademenin kesif sayaci (3 / 17).
		Ustteki genel sayacin ayni bilgiyi kademe kademe verdigi hali --
		oyuncu hangi kademede eksigi oldugunu bir bakista goruyor.
	]]
	local etiket = UI.text({
		text = Rarity.displayName(rarityId),
		size = UI.Sizes.label,
		font = UI.Fonts.bold,
		align = Enum.TextXAlignment.Left,
		frameSize = UDim2.new(1, -90, 1, 0),
		parent = baslik,
		name = "Etiket",
	})
	etiket.ZIndex = 2
	UI.rarityStyle(etiket, rarityId)

	local kademeSayac = UI.text({
		text = "",
		size = UI.Sizes.small,
		color = UI.Colors.textDim,
		align = Enum.TextXAlignment.Right,
		frameSize = UDim2.fromOffset(86, 26),
		position = UDim2.new(1, -86, 0, 0),
		parent = baslik,
		name = "Sayac",
	})
	kademeSayac.ZIndex = 2
	kademeSayaclari[rarityId] = kademeSayac

	--[[
		KADEMENIN KENDI DOKUSU

		Baslik duz ve sade duruyordu. Arkasina kademe renginde egik bir
		serit dokusu biniyor: her kademe kendi temasinda gorunuyor, liste
		bolumlere ayrilmis gibi okunuyor.

		Doku disaridan resim gerektirmiyor -- gecise bol sayida ANI
		saydamlik duragi konarak kesik seritler olusturuluyor.
	]]
	local doku = Instance.new("Frame")
	doku.Name = "Doku"
	doku.Size = UDim2.fromScale(1, 1)
	doku.BackgroundColor3 = Rarity.color(rarityId)
	doku.BackgroundTransparency = 0.78
	doku.BorderSizePixel = 0
	doku.ZIndex = 0
	doku.Parent = baslik
	UI.corner(doku, 6)

	do
		local stops = {}
		local sikilik = 13
		for i = 0, sikilik do
			table.insert(
				stops,
				NumberSequenceKeypoint.new(i / sikilik, if i % 2 == 0 then 0 else 1)
			)
		end

		local gecis = Instance.new("UIGradient")
		gecis.Rotation = 24
		gecis.Transparency = NumberSequence.new(stops)
		gecis.Parent = doku
	end

	local izgara = Instance.new("Frame")
	izgara.Name = `Izgara_{rarityId}`
	izgara.Size = UDim2.new(1, -10, 0, 0)
	izgara.AutomaticSize = Enum.AutomaticSize.Y
	izgara.BackgroundTransparency = 1
	izgara.LayoutOrder = kademeSirasi * 10 + 1
	izgara.Parent = liste

	local yerlesim = Instance.new("UIGridLayout")
	yerlesim.CellSize = UDim2.fromOffset(HUCRE.X, HUCRE.Y)
	yerlesim.CellPadding = UDim2.fromOffset(BOSLUK, BOSLUK)
	yerlesim.SortOrder = Enum.SortOrder.LayoutOrder
	yerlesim.Parent = izgara

	local sira = 0
	for _, info in Brainrots.List do
		if info.rarity == rarityId then
			sira += 1
			local hucre = hucreKur(izgara, info, sira)
			hucreCiz(hucre)
			table.insert(hucreler, hucre)
		end
	end
end

------------------------------------------------------------------
-- KILIT IKONUNU TEK SEFERDE COZ
--
-- Icons.bind her cagrisinda kendi yeniden deneme dongusunu aciyor; 87
-- rozet icin 87 dongu olurdu. Bir rozete baglanip sonucu digerlerine
-- kopyalamak tek dongude ayni isi yapiyor.
------------------------------------------------------------------
do
	local ilk = kilitRozetleri[1]
	if ilk then
		Icons.bind(ilk, "lockClosed", function(ok)
			if not ok then
				-- Ikon gelmedi: rozetler bos kalir, ayrim onizleme tonundan okunur
				return
			end
			for sira = 2, #kilitRozetleri do
				kilitRozetleri[sira].Image = ilk.Image
			end
		end)
	end
end

------------------------------------------------------------------
-- GORUS PENCERESI
--
-- Kaydirma konumuna gore hangi hucrelerin onizlemesi yasayacagina karar
-- verir. Hucrenin listenin ICINDEKI y konumu AbsolutePosition farkindan
-- okunuyor; boylece izgara/baslik yuksekliklerini elle hesaplamak
-- gerekmiyor.
------------------------------------------------------------------
local function pencereyiTazele()
	if not panel.Visible then
		return
	end

	local ustSinir = liste.AbsolutePosition.Y - PAY
	local altSinir = liste.AbsolutePosition.Y + liste.AbsoluteSize.Y + PAY

	for _, hucre in hucreler do
		local y = hucre.kutu.AbsolutePosition.Y
		local icinde = y + hucre.kutu.AbsoluteSize.Y >= ustSinir and y <= altSinir

		if icinde then
			onizlemeKur(hucre)
		else
			onizlemeYik(hucre)
		end
	end
end

liste:GetPropertyChangedSignal("CanvasPosition"):Connect(pencereyiTazele)

--[[
	PANEL KAPANINCA SAHNELERI BOSALT

	Gorunmez bir panelin altindaki ViewportFrame'ler cizilmiyor, yani
	kare hizina zarari yok -- ama model kopyalari bellekte duruyor.
	Panel kapaninca hepsi atiliyor, acilista pencereye girenler yeniden
	kuruluyor.
]]
panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then
		return
	end

	--[[
		Panel fare bir hucrenin ustundeyken kapanabiliyor (kapat dugmesi,
		baska panelin acilmasi, kisayol). O durumda MouseLeave gelmiyor ve
		hucre buyumus + pariltisi acik kaliyordu; bir sonraki acilista
		yanlis gorunuyordu.
	]]
	local acik = ustundeki
	if acik then
		hoverBitir(acik)
	end

	for _, hucre in hucreler do
		onizlemeYik(hucre)
	end
end)

------------------------------------------------------------------
-- HAREKET SURUCUSU
--
-- Ayni anda YALNIZCA BIR hucrenin ustunde olunabildigi icin tek bir
-- RenderStepped yetiyor; her hucreye ayri dongu acmak 87 dongu olurdu.
--
-- Kilitli hucrede hic hareket yok: onun tepkisi hoverBaslat'taki buyume
-- ve kontur ile bitiyor.
------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
	local hucre = ustundeki
	if not hucre or not panel.Visible then
		return
	end

	if not hucre.kesif then
		return
	end

	hoverT += dt

	--[[
		PARILTI SUPURMESI

		Bant sol disindan sag disina gecer, sonra basa doner. Modulo ile
		dondugu icin bitis-baslangic arasinda sicrama gorunmez: iki uc da
		kutunun DISINDA.
	]]
	local ilerleme = (hoverT % PARILTI_SURE) / PARILTI_SURE
	hucre.parilti.Position = UDim2.fromScale(PARILTI_BAS + ilerleme * (PARILTI_BIT - PARILTI_BAS), 0.5)

	--[[
		MODELIN SALINIMI

		Tam tur DEGIL, sag-sol salinim: tam tur atsa modelin arkasi
		gorunurdu, ki oradan basladik. sin() ile gidip geliyor, uclarda
		kendiliginden yavasliyor.
	]]
	local kamera, merkez, uzaklik = hucre.kamera, hucre.merkez, hucre.uzaklik
	if kamera and merkez and uzaklik then
		local aci = math.sin(hoverT * SALINIM_HIZ) * SALINIM_ACI
		local yon = CFrame.Angles(0, aci, 0):VectorToWorldSpace(BAKIS_YONU)
		kamera.CFrame = CFrame.lookAt(merkez + yon * uzaklik, merkez)
	end
end)

------------------------------------------------------------------
-- SUNUCUDAN GELEN KESIF TABLOSU
------------------------------------------------------------------
IndexDurum.OnClientEvent:Connect(function(kesfedilen)
	if type(kesfedilen) ~= "table" then
		return
	end

	local bulunan = 0

	-- Kademe basina: rarityId -> { bulunan, toplam }
	local kademe: { [string]: { number } } = {}

	for _, hucre in hucreler do
		hucre.kesif = kesfedilen[hucre.name] == true

		local sayi = kademe[hucre.rarity]
		if not sayi then
			sayi = { 0, 0 }
			kademe[hucre.rarity] = sayi
		end
		sayi[2] += 1

		if hucre.kesif then
			bulunan += 1
			sayi[1] += 1
		end

		hucreCiz(hucre)
	end

	sayac.Text = `{bulunan} / {#hucreler} kesfedildi`

	-- Her kademe basligi kendi payini yaziyor
	for rarityId, etiket in kademeSayaclari do
		local sayi = kademe[rarityId]
		etiket.Text = if sayi then `{sayi[1]} / {sayi[2]}` else ""
	end

	pencereyiTazele()

	--[[
		hucreCiz butun renk/kalinlik degerlerini tabana cekiyor; fare o an
		bir hucrenin ustundeyse gorunumu yeniden kuruluyor. Onemi su:
		oyuncu kilitli bir hucrenin ustunde beklerken o brainrotu bulursa
		parilti aninda basliyor.
	]]
	local acik = ustundeki
	if acik then
		hoverBaslat(acik)
	end
end)

--[[
	Paneli ac.

	Veri her acilista yeniden isteniyor: oyuncu panel kapaliyken brainrot
	bulmus olabilir, bayat liste gostermek istemiyoruz.
]]
function Index.ac()
	panel.Visible = true
	IndexAc:FireServer()

	--[[
		Pencere hesabi AbsolutePosition okuyor; panel yeni gorunur oldugu
		ilk karede yerlesim henuz oturmamis olur (UI.panel acilista bir de
		buyume animasyonu oynatiyor). defer ile yerlesimden SONRAYA
		birakiliyor, yoksa ilk acilista yanlis hucrelerin onizlemesi
		kurulabiliyor.
	]]
	task.defer(pencereyiTazele)
end

function Index.kapat()
	panel.Visible = false
end

return Index
