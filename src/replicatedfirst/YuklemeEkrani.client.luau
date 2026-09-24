--!strict
--[[
	YuklemeEkrani  (LocalScript)
	Yeri: ReplicatedFirst > YuklemeEkrani

	Oyun acilirken gorunen ozel yukleme ekrani. Roblox'un kendi gri
	yukleme ekranini kaldirip yerine geciyor.

	    [ bulanik LoadingScreen resmi, hafifce yaklasiyor ]

	         L O A D I N G . . .
	    +---------------------------------+
	    |#############              70%   |
	    +---------------------------------+
	      Loading world assets...

	    (o)  <- donen disli                cicistamert

	NEDEN ReplicatedFirst
	Yukleme ekrani, oyunun geri kalani daha yuklenmeden gorunmek zorunda.
	ReplicatedFirst istemcide CALISAN ILK yer; StarterPlayerScripts'teki
	betikler sahne hazir olduktan sonra basliyor, oraya konsa ekran is
	bittikten sonra acilirdi.

	BURADA BASKA MODUL KULLANILMIYOR
	Shared klasoru (UI, Assets, Icons...) bu noktada daha replike olmamis
	olabilir; require etmek ekrani kilitler. Bu yuzden dosya kendi kendine
	yetiyor -- renkler, sekiller, yardimcilar hep burada.

	ILERLEME GERCEK
	Cubuk sahte degil: Assets altindaki mesh, doku, resim, ses ve
	animasyonlarin hepsi ContentProvider ile obek obek onbellege aliniyor
	ve yuzde gercekten yuklenen orandan cikiyor. Sirayla:

	    varliklar -> game.Loaded -> oyuncunun kaydi -> karakter

	Yani ekran kalktiginda oyuncunun hicbir seyi "yukleniyor" halinde
	olmuyor.

	EN AZ 5 SANIYE
	Her sey onbellekteyse yukleme bir saniyeden kisa suruyordu ve ekran
	goz kirpmasi gibi gelip geciyordu. Artik bir ALT SINIR var; cubuk da o
	sureye yayiliyor. Yukleme daha uzun surerse ekran acik kalmaya devam
	ediyor.

	KAPANMA KARARI OYUNCUNUN
	Yukleme bitince ekran kendiliginden kapanmiyor: PLAY dugmesi
	beliriyor ve oyuncu basana kadar bekliyor. Kendiliginden kapandiginda
	oyuncu daha ekrana bakarken kendini oyunun ortasinda buluyordu.

	ASILI KALMAZ
	Her sey ters giderse EN_COK_BEKLEME saniye sonunda dugme yine de
	cikiyor: oyuncu asla "yukleniyor" halinde kilitli kalmiyor.

	ROBLOX'UN ARAYUZU DE KAPALI
	Sohbet ve oyuncu listesi yukleme boyunca gizli (CoreGui bizim
	ScreenGui'mizin USTUNDE ciziliyor, baska turlu ortulemiyor); ekran
	kapanirken geri aciliyor.
]]

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

------------------------------------------------------------------
-- AYARLAR
------------------------------------------------------------------
--[[
	ARKA PLAN RESMI

	ReplicatedStorage > Assets > Backgrounds > LoadingScreen. Resmi tasiyan
	nesne Decal, Texture, ImageLabel ya da resim kimligini tutan bir
	StringValue olabilir.

	Resim gec gelebilir (Assets o an daha replike olmamis olabilir); o yuzden
	ekran once gradyanla aciliyor, resim gelince arkasina yerlesiyor.
]]
local ARKA_PLAN_KLASORU = { "Assets", "Backgrounds" }
local ARKA_PLAN_ADI = "LoadingScreen"

--[[
	RESIM EKRANI NASIL DOLDURUR

	ScaleType.Crop: resim, ekrani TAMAMEN kaplayana kadar buyutulur ve
	tasan kismi kirpilir. En-boy orani korunur, yani resim asla ezilmez --
	ama ekranin orani resmin oranindan farkliysa bir yerlerden kirpilir.

	  16:9 resim,  16:9 ekran  ->  hicbir sey kirpilmaz
	  1:1 resim,   16:9 ekran  ->  ustten ve alttan buyuk parca gider
	  16:9 resim,  4:3 ekran   ->  saglan ve soldan gider

	YANI: resmi 16:9 hazirla. 1920x1080 ideal. (Roblox yuklerken en buyuk
	kenari 1024'e indiriyor, 1024x576 oluyor; bulanik bir zemin icin bu
	fazlasiyla yeterli.)

	ODAK  --  kirpilirken NERESI kalsin

	Resmin onemli yeri ortada degilse burayi oynat. Yaklasma da bu
	noktadan yapiliyor, yani secilen nokta hic kaymadan yerinde kaliyor:

	    (0.5, 0.5)  orta          (varsayilan)
	    (0.5, 0.25) ust taraf     (gokyuzu / logo yukaridaysa)
	    (0.5, 0.75) alt taraf
	    (0.25, 0.5) sol taraf
]]
local RESIM_ODAK = Vector2.new(0.5, 0.5)

-- Yukleme boyunca resim bu orana kadar yavasca yaklasir (1 = hic yaklasma)
local RESIM_YAKLASMA = 1.12

-- Oyunun adi (alt kosede durur)
local OYUN_ADI = "CICISTAMERT"

-- Ne olursa olsun bu kadar saniye sonra ekran kapanir
local EN_COK_BEKLEME = 45

--[[
	EN AZ GORUNME SURESI

	Varliklar onbellekteyse (Studio'da her zaman, oyuna ikinci kez giren
	oyuncuda cogu zaman) yukleme bir saniyeden kisa suruyor; ekran
	dolmadan kapanip goz kirpmasi gibi duruyordu.

	Ekran bu sureden once KAPANMIYOR ve cubuk da bu sureye yayiliyor
	(bkz. asagida zamanSiniri): yukleme anlik bitse bile cubuk 0'dan
	100'e duzgunce doluyor.

	Yukleme daha UZUN surerse ekran acik kalmaya devam ediyor; bu bir
	alt sinir, ust sinir degil.
]]
local EN_AZ_GORUNME = 5

-- Renkler
local NEON = Color3.fromRGB(70, 190, 255)
local NEON_KOYU = Color3.fromRGB(20, 90, 160)
local BEYAZ = Color3.fromRGB(255, 255, 255)
local SOLGUN = Color3.fromRGB(170, 185, 200)

-- Cubugun olculeri
local CUBUK_EN = 520
local CUBUK_BOY = 34

--[[
	Cubugun etrafinda suzulen toz tanesi sayisi. Cok olmasi gerekmiyor;
	birkac tanesi bile ekrani "canli" yapiyor.
]]
local TOZ_SAYISI = 22

------------------------------------------------------------------
-- ROBLOX'UN KENDI EKRANINI KALDIR
------------------------------------------------------------------
--[[
	pcall: bazi baglamlarda (Studio'da bazi test modlari) bu cagri hata
	veriyor ve hatasi butun betigi durdururdu.
]]
pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

------------------------------------------------------------------
-- ROBLOX'UN KENDI ARAYUZU DE KAPALI
------------------------------------------------------------------
--[[
	Sohbet kutusu ve sag ustteki oyuncu listesi CoreGui'ye ait; bizim
	ScreenGui'miz DisplayOrder ne olursa olsun onlarin ALTINDA kaliyor.
	Yukleme ekraninin uzerinde durduklarinda ekran yarim kalmis gibi
	gorunuyordu.

	Kapatmanin tek yolu SetCoreGuiEnabled. Ekran kapanirken geri
	aciliyor (bkz. coreGuiGeriAc) -- oyuncu sohbetsiz kalmasin.

	Ilk karelerde bu cagri reddedilebiliyor; basarana kadar deneniyor.
]]
local KAPATILAN_COREGUI = {
	Enum.CoreGuiType.Chat,
	Enum.CoreGuiType.PlayerList,
	Enum.CoreGuiType.Backpack,
	Enum.CoreGuiType.EmotesMenu,
}

local StarterGui = game:GetService("StarterGui")

local function coreGuiAyarla(acik: boolean)
	for _, tur in KAPATILAN_COREGUI do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(tur, acik)
		end)
	end
end

--[[
	BIR KEZ KAPATMAK YETMIYOR

	Roblox kendi arayuz modullerini yuklerken bizim kapatmamizi eziyor:
	tek sefer kapatinca sohbet ve oyuncu listesi birkac saniye sonra geri
	geliyordu. Bu yuzden ekran kapanana kadar SUREKLI kapali tutuluyor.

	Ust seritteki dugmeler (sohbet, menu) da kapatiliyor; onlar CoreGui
	turlerine degil SetCore'a bakiyor.
]]
local coreGuiSuruyor = true

task.spawn(function()
	while coreGuiSuruyor do
		coreGuiAyarla(false)
		pcall(function()
			StarterGui:SetCore("TopbarEnabled", false)
		end)
		task.wait(0.25)
	end
end)

--[[
	GERI ACARKEN Backpack'e DOKUNULMUYOR: onu kendi hotbar'imiz bilerek
	kapali tutuyor (bkz. StarterPlayerScripts > Hotbar). Burada da acsaydik
	Roblox'un cubugu bizimkinin yanina geri gelirdi.
]]
local function coreGuiGeriAc()
	-- Once dongu dursun, yoksa actigimizi hemen geri kapatir
	coreGuiSuruyor = false

	for _, tur in KAPATILAN_COREGUI do
		if tur ~= Enum.CoreGuiType.Backpack then
			pcall(function()
				StarterGui:SetCoreGuiEnabled(tur, true)
			end)
		end
	end

	pcall(function()
		StarterGui:SetCore("TopbarEnabled", true)
	end)
end

------------------------------------------------------------------
-- KUCUK YARDIMCILAR  (Shared > UI burada kullanilamiyor)
------------------------------------------------------------------
local function kose(nesne: Instance, yaricap: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, yaricap)
	c.Parent = nesne
end

local function kontur(nesne: Instance, renk: Color3, kalinlik: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = renk
	s.Thickness = kalinlik
	s.Parent = nesne
	return s
end

local function yazi(ayar: { [string]: any }): TextLabel
	local etiket = Instance.new("TextLabel")
	etiket.Name = ayar.name or "Yazi"
	etiket.BackgroundTransparency = 1
	etiket.Size = ayar.size or UDim2.fromScale(1, 1)
	etiket.Position = ayar.position or UDim2.new()
	etiket.AnchorPoint = ayar.anchor or Vector2.zero
	etiket.Font = ayar.font or Enum.Font.GothamBold
	etiket.Text = ayar.text or ""
	etiket.TextColor3 = ayar.color or BEYAZ
	etiket.TextSize = ayar.textSize or 18
	etiket.TextXAlignment = ayar.align or Enum.TextXAlignment.Center
	etiket.ZIndex = ayar.zIndex or 5
	etiket.Parent = ayar.parent
	return etiket
end

------------------------------------------------------------------
-- EKRAN
------------------------------------------------------------------
local ekran = Instance.new("ScreenGui")
ekran.Name = "YuklemeEkrani"
-- Her seyin ustunde: hata ekrani bile (100) bunun altinda kalmali
ekran.DisplayOrder = 1000
ekran.IgnoreGuiInset = true
ekran.ResetOnSpawn = false
ekran.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ekran.Parent = playerGui

--[[
	KOK PERDE

	Tamami tek bir CanvasGroup: kapanirken tek bir GroupTransparency
	tweeni butun ekrani birlikte soluyor. Tek tek nesneleri soldurmak hem
	daha fazla tween hem de birinin geride kalma riski demekti.
]]
local perde = Instance.new("CanvasGroup")
perde.Name = "Perde"
perde.Size = UDim2.fromScale(1, 1)
perde.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
perde.BorderSizePixel = 0
perde.ZIndex = 1
perde.Parent = ekran

------------------------------------------------------------------
-- ARKA PLAN
------------------------------------------------------------------
--[[
	GRADYAN ZEMIN  --  resim gelene kadar (ve resmin altinda) duruyor.
	Sicak ust, koyu alt: gun batimi hissi.
]]
local gokyuzu = Instance.new("Frame")
gokyuzu.Name = "Gokyuzu"
gokyuzu.Size = UDim2.fromScale(1, 1)
gokyuzu.BackgroundColor3 = BEYAZ
gokyuzu.BorderSizePixel = 0
gokyuzu.ZIndex = 1
gokyuzu.Parent = perde

local gokGecis = Instance.new("UIGradient")
gokGecis.Rotation = 90
gokGecis.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(96, 74, 120)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(48, 44, 78)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 14, 26)),
})
gokGecis.Parent = gokyuzu

--[[
	RESIM KABI  --  ekrani tam kaplar, tasani keser

	SABIT duruyor ve ekranin TAM ORTASINDA: AnchorPoint verilmeseydi
	(varsayilan 0,0) sol ust koseye yapisirdi.
]]
local resimKabi = Instance.new("Frame")
resimKabi.Name = "ResimKabi"
resimKabi.AnchorPoint = Vector2.new(0.5, 0.5)
resimKabi.Position = UDim2.fromScale(0.5, 0.5)
resimKabi.Size = UDim2.fromScale(1, 1)
resimKabi.BackgroundTransparency = 1
resimKabi.ClipsDescendants = true
resimKabi.ZIndex = 2
resimKabi.Parent = perde

--[[
	YAKLASAN KATMAN

	Resmin yavasca buyumesi BU cercevede; kirpan kap sabit kaliyor.

	Once buyuyen sey kabin KENDISIYDI ve kap sol ust koseden bagliydi:
	buyudukce sag alta dogru tasiyor, ekranda resmin ortasi degil bir
	kosesi kaliyordu. Simdi buyuyen cerceve ORTADAN bagli, yani her iki
	yana esit aciliyor ve resmin ortasi hep ortada duruyor.
]]
--[[
	AnchorPoint ile Position AYNI nokta (RESIM_ODAK): cerceve buyurken o
	nokta yerinde kaliyor, buyume onun etrafina dagiliyor. Ortada iken
	iki yana esit aciliyor; ust tarafa alinirsa yaklasma asagi dogru
	oluyor ve ustteki detay kadrajdan cikmiyor.
]]
local resimYaklasma = Instance.new("Frame")
resimYaklasma.Name = "Yaklasma"
resimYaklasma.AnchorPoint = RESIM_ODAK
resimYaklasma.Position = UDim2.fromScale(RESIM_ODAK.X, RESIM_ODAK.Y)
resimYaklasma.Size = UDim2.fromScale(1, 1)
resimYaklasma.BackgroundTransparency = 1
resimYaklasma.ZIndex = 2
resimYaklasma.Parent = resimKabi

--[[
	BULANIKLIK

	Roblox'ta arayuz icin gercek bir blur YOK (BlurEffect yalnizca 3B
	kamerada calisir). Ayni resim birkac kez, birbirine gore birkac piksel
	kaydirilmis ve daha soluk olarak ust uste seriliyor; kenarlar birbirine
	karisiyor, goz bunu bulaniklik olarak okuyor.

	Katman sayisi az: yukleme ekrani, makine zaten mesgul.
]]
local BULANIK_KAYMA = {
	Vector2.new(0, 0),
	Vector2.new(6, 4),
	Vector2.new(-6, -4),
	Vector2.new(5, -6),
	Vector2.new(-5, 6),
	Vector2.new(9, 0),
	Vector2.new(-9, 0),
}
local resimKatmanlari: { ImageLabel } = {}

for sira, kayma in BULANIK_KAYMA do
	local katman = Instance.new("ImageLabel")
	katman.Name = `Resim{sira}`
	katman.AnchorPoint = Vector2.new(0.5, 0.5)
	katman.Position = UDim2.new(0.5, math.floor(kayma.X), 0.5, math.floor(kayma.Y))
	katman.Size = UDim2.fromScale(1, 1)
	katman.BackgroundTransparency = 1
	katman.ScaleType = Enum.ScaleType.Crop
	-- Ilk katman tam, digerleri gittikce soluk: uzerine bindikce yumusuyor
	katman.ImageTransparency = if sira == 1 then 0.1 else 0.55
	katman.ZIndex = 2
	katman.Visible = false
	katman.Parent = resimYaklasma
	table.insert(resimKatmanlari, katman)
end

--[[
	Resmi ARARKEN oyun beklemiyor: arama ayri bir iplikte, bulununca
	katmanlara yaziliyor ve yavasca beliriyor.
]]
task.spawn(function()
	--[[
		Assets gec replike olabilir. WaitForChild'in zaman asimi var ki
		klasor hic yoksa bu iplik sonsuza kadar beklemesin; o durumda
		ekran gradyanla kaliyor.
	]]
	local node: Instance? = ReplicatedStorage
	for _, ad in ARKA_PLAN_KLASORU do
		node = if node then node:WaitForChild(ad, 10) else nil
	end

	local hedef = if node then node:WaitForChild(ARKA_PLAN_ADI, 10) else nil
	if not hedef then
		return
	end

	--[[
		Resmi tasiyan nesne turu serbest: Decal/Texture'da Texture,
		ImageLabel'da Image, StringValue'da dogrudan kimlik.
	]]
	local kimlik: string? = nil
	if hedef:IsA("Decal") or hedef:IsA("Texture") then
		kimlik = hedef.Texture
	elseif hedef:IsA("ImageLabel") or hedef:IsA("ImageButton") then
		kimlik = hedef.Image
	elseif hedef:IsA("StringValue") then
		kimlik = hedef.Value
	end

	if not kimlik or kimlik == "" then
		return
	end

	for _, katman in resimKatmanlari do
		katman.Image = kimlik
		katman.Visible = true
	end

	--[[
		YAVAS YAKLASMA: resim %100'den %112'ye buyuyor. Tek yonlu ve uzun
		(yukleme ne kadar surerse sursun bitmiyor gibi duruyor).
	]]
	TweenService
		:Create(
			resimYaklasma,
			TweenInfo.new(18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Size = UDim2.fromScale(RESIM_YAKLASMA, RESIM_YAKLASMA) }
		)
		:Play()
end)

--[[
	KARARTMA: resmin uzerine koyu bir perde. Yazilarin okunmasi resme
	degil buna bagli -- hangi resim konursa konsun metin okunur kaliyor.
]]
local karartma = Instance.new("Frame")
karartma.Name = "Karartma"
karartma.Size = UDim2.fromScale(1, 1)
karartma.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
--[[
	Koyuluk yuksek: arka plan resmi ne kadar parlak ve kalabalik olursa
	olsun baslik ve cubuk okunur kalsin. Resmin kendisi yine seciliyor,
	ama artik yazilarla yarismiyor.
]]
karartma.BackgroundTransparency = 0.18
karartma.BorderSizePixel = 0
karartma.ZIndex = 3
karartma.Parent = perde

-- Kenarlara dogru koyulasan vinyet: goz ortaya, panele gidiyor
local vinyet = Instance.new("UIGradient")
vinyet.Rotation = 90
vinyet.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0.65),
	NumberSequenceKeypoint.new(1, 0),
})
vinyet.Parent = karartma

------------------------------------------------------------------
-- ORTADAKI PANEL
------------------------------------------------------------------
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(CUBUK_EN + 80, 262)
panel.BackgroundColor3 = Color3.fromRGB(14, 17, 26)
panel.BackgroundTransparency = 0.25
panel.BorderSizePixel = 0
panel.ZIndex = 4
panel.Parent = perde
kose(panel, 18)
kontur(panel, Color3.fromRGB(45, 60, 82), 2)

--[[
	BASLIK

	Beyaz govde + neon mavi kontur. Konturun saydamligi nabiz gibi gidip
	geliyor: durgun bir ekranda tek hareketli sey bu olunca goz once
	buraya geliyor.
]]
local baslik = yazi({
	text = "LOADING...",
	textSize = 46,
	color = BEYAZ,
	size = UDim2.new(1, 0, 0, 56),
	position = UDim2.fromOffset(0, 26),
	parent = panel,
	zIndex = 6,
	name = "Baslik",
})

local baslikKontur = kontur(baslik, NEON, 3)

local baslikOlcek = Instance.new("UIScale")
baslikOlcek.Parent = baslik

TweenService
	:Create(
		baslikOlcek,
		TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Scale = 1.04 }
	)
	:Play()

TweenService
	:Create(
		baslikKontur,
		TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.55 }
	)
	:Play()

------------------------------------------------------------------
-- ILERLEME CUBUGU
------------------------------------------------------------------
local cubuk = Instance.new("Frame")
cubuk.Name = "Cubuk"
cubuk.AnchorPoint = Vector2.new(0.5, 0)
cubuk.Position = UDim2.new(0.5, 0, 0, 104)
cubuk.Size = UDim2.fromOffset(CUBUK_EN, CUBUK_BOY)
cubuk.BackgroundColor3 = Color3.fromRGB(28, 33, 44)
cubuk.BorderSizePixel = 0
-- Dolgu yuvarlak kosenin disina tasmasin
cubuk.ClipsDescendants = true
cubuk.ZIndex = 5
cubuk.Parent = panel
kose(cubuk, CUBUK_BOY // 2)
kontur(cubuk, Color3.fromRGB(52, 66, 88), 2)

local dolgu = Instance.new("Frame")
dolgu.Name = "Dolgu"
dolgu.Size = UDim2.fromScale(0, 1)
dolgu.BackgroundColor3 = BEYAZ
dolgu.BorderSizePixel = 0
dolgu.ZIndex = 6
dolgu.Parent = cubuk
kose(dolgu, CUBUK_BOY // 2)

-- Dolgunun kendi icinde koyudan parlaga gecisi: duz renk yerine isik
local dolguGecis = Instance.new("UIGradient")
dolguGecis.Color = ColorSequence.new(NEON_KOYU, NEON)
dolguGecis.Parent = dolgu

--[[
	DOLGUNUN UCUNDAKI PARLAMA

	Dolgunun sag ucunda duran, ileri geri kayan acik bir bant: cubuk
	"calisiyor" gibi duruyor, yuzde artmasa bile hareket var.
]]
local parlama = Instance.new("Frame")
parlama.Name = "Parlama"
parlama.AnchorPoint = Vector2.new(1, 0)
parlama.Position = UDim2.fromScale(1, 0)
parlama.Size = UDim2.new(0, 90, 1, 0)
parlama.BackgroundColor3 = BEYAZ
parlama.BorderSizePixel = 0
parlama.ZIndex = 7
parlama.Parent = dolgu

local parlamaGecis = Instance.new("UIGradient")
parlamaGecis.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.6, 0.72),
	NumberSequenceKeypoint.new(1, 0.45),
})
parlamaGecis.Parent = parlama

-- Cubugun ICINDE duran yuzde yazisi
local yuzdeYazi = yazi({
	text = "0% Completed",
	textSize = 18,
	color = BEYAZ,
	size = UDim2.fromScale(1, 1),
	parent = cubuk,
	zIndex = 9,
	name = "Yuzde",
})
kontur(yuzdeYazi, Color3.fromRGB(0, 0, 0), 2)

-- Cubugun altindaki aciklama satiri
local durumYazi = yazi({
	text = "Loading world assets... Please wait",
	textSize = 16,
	color = SOLGUN,
	font = Enum.Font.Gotham,
	size = UDim2.new(1, 0, 0, 22),
	position = UDim2.fromOffset(0, 146),
	parent = panel,
	zIndex = 6,
	name = "Durum",
})

------------------------------------------------------------------
-- BASLA DUGMESI
------------------------------------------------------------------
--[[
	EKRAN KENDILIGINDEN KAPANMIYOR

	Yukleme bitince ekran kapanmiyor, bu dugme beliriyor ve oyuncu
	basana kadar bekliyor. Sebebi: oyuncu oyuna hazir OLDUGUNDA girsin.
	Kendiliginden kapandiginda oyuncu daha ekrana bakarken kendini
	oyunun ortasinda buluyordu.

	Dugme yukleme bitene kadar GORUNMUYOR; hazir olunca asagidan
	yukari kucuk bir yaylanmayla giriyor.
]]
local baslaDugme = Instance.new("TextButton")
baslaDugme.Name = "Basla"
baslaDugme.AnchorPoint = Vector2.new(0.5, 0)
baslaDugme.Position = UDim2.new(0.5, 0, 0, 182)
baslaDugme.Size = UDim2.fromOffset(240, 52)
baslaDugme.BackgroundColor3 = NEON
baslaDugme.BorderSizePixel = 0
baslaDugme.AutoButtonColor = false
baslaDugme.Text = ""
baslaDugme.Visible = false
baslaDugme.ZIndex = 8
baslaDugme.Parent = panel
kose(baslaDugme, 12)
kontur(baslaDugme, Color3.fromRGB(0, 0, 0), 3)

-- Ustten asagi hafif isik: duz renk yerine kabarik dugme
local baslaGecis = Instance.new("UIGradient")
baslaGecis.Rotation = 90
baslaGecis.Color = ColorSequence.new(Color3.fromRGB(140, 220, 255), NEON)
baslaGecis.Parent = baslaDugme

local baslaYazi = yazi({
	text = "PLAY",
	textSize = 26,
	color = Color3.fromRGB(10, 22, 34),
	size = UDim2.fromScale(1, 1),
	parent = baslaDugme,
	zIndex = 9,
	name = "Yazi",
})

local baslaOlcek = Instance.new("UIScale")
baslaOlcek.Parent = baslaDugme

-- Fare ustundeyken hafifce buyur: tiklanabilir oldugu belli olsun
baslaDugme.MouseEnter:Connect(function()
	TweenService:Create(baslaOlcek, TweenInfo.new(0.12), { Scale = 1.06 }):Play()
end)
baslaDugme.MouseLeave:Connect(function()
	TweenService:Create(baslaOlcek, TweenInfo.new(0.12), { Scale = 1 }):Play()
end)

------------------------------------------------------------------
-- TOZ TANELERI
------------------------------------------------------------------
--[[
	Cubugun etrafinda yavasca yukari suzulen kucuk isiklar. Her biri kendi
	hizinda ve kendi gecikmesiyle basliyor; hepsi ayni anda hareket etse
	yagmur gibi gorunurdu.
]]
local tozKabi = Instance.new("Frame")
tozKabi.Name = "Toz"
tozKabi.AnchorPoint = Vector2.new(0.5, 0.5)
tozKabi.Position = UDim2.new(0.5, 0, 0, 120)
tozKabi.Size = UDim2.fromOffset(CUBUK_EN + 60, 150)
tozKabi.BackgroundTransparency = 1
tozKabi.ZIndex = 4
tozKabi.Parent = panel

local rastgele = Random.new()

for i = 1, TOZ_SAYISI do
	local tane = Instance.new("Frame")
	tane.Name = "Tane"
	tane.AnchorPoint = Vector2.new(0.5, 0.5)
	tane.BackgroundColor3 = NEON
	tane.BorderSizePixel = 0
	tane.ZIndex = 4

	local boy = rastgele:NextInteger(2, 5)
	tane.Size = UDim2.fromOffset(boy, boy)
	kose(tane, boy)
	tane.Parent = tozKabi

	task.spawn(function()
		-- Baslangic gecikmesi: hepsi ayni anda dogmasin
		task.wait(rastgele:NextNumber(0, 3))

		while tane.Parent do
			local x = rastgele:NextNumber(0.02, 0.98)
			local sure = rastgele:NextNumber(2.5, 5)

			tane.Position = UDim2.fromScale(x, 1.05)
			tane.BackgroundTransparency = rastgele:NextNumber(0.25, 0.6)

			local ucus = TweenService:Create(
				tane,
				TweenInfo.new(sure, Enum.EasingStyle.Linear),
				{ Position = UDim2.fromScale(x + rastgele:NextNumber(-0.05, 0.05), -0.05) }
			)
			-- Yol boyunca sonuyor: tepeye varinca yok olmus oluyor
			TweenService
				:Create(tane, TweenInfo.new(sure, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
				:Play()

			ucus:Play()
			ucus.Completed:Wait()
		end
	end)
end

------------------------------------------------------------------
-- DONEN DISLI  (sol alt)
------------------------------------------------------------------
--[[
	Disli bir resim degil, CIZIM: sekiz cubuk bir daire etrafinda. Boylece
	hicbir varliga bagli degil ve yukleme ekrani bir resmin yuklenmesini
	beklemiyor -- ki bu ekranin butun amaci o beklemeyi doldurmak.
]]
local disli = Instance.new("Frame")
disli.Name = "Disli"
disli.AnchorPoint = Vector2.new(0, 1)
disli.Position = UDim2.new(0, 36, 1, -36)
disli.Size = UDim2.fromOffset(44, 44)
disli.BackgroundTransparency = 1
disli.ZIndex = 5
disli.Parent = perde

for i = 1, 8 do
	local dis = Instance.new("Frame")
	dis.AnchorPoint = Vector2.new(0.5, 0.5)
	dis.Position = UDim2.fromScale(0.5, 0.5)
	dis.Size = UDim2.fromOffset(6, 44)
	dis.Rotation = (i - 1) * (180 / 8)
	dis.BackgroundColor3 = NEON
	dis.BackgroundTransparency = 0.25
	dis.BorderSizePixel = 0
	dis.ZIndex = 5
	dis.Parent = disli
	kose(dis, 3)
end

-- Ortadaki koyu goz: cubuklar disli gibi gorunsun
local dislGobek = Instance.new("Frame")
dislGobek.AnchorPoint = Vector2.new(0.5, 0.5)
dislGobek.Position = UDim2.fromScale(0.5, 0.5)
dislGobek.Size = UDim2.fromOffset(22, 22)
dislGobek.BackgroundColor3 = Color3.fromRGB(10, 13, 20)
dislGobek.BorderSizePixel = 0
dislGobek.ZIndex = 6
dislGobek.Parent = disli
kose(dislGobek, 11)

yazi({
	text = "SETTING UP",
	textSize = 13,
	color = SOLGUN,
	font = Enum.Font.Gotham,
	align = Enum.TextXAlignment.Left,
	size = UDim2.fromOffset(200, 20),
	anchor = Vector2.new(0, 1),
	position = UDim2.new(0, 92, 1, -48),
	parent = perde,
	zIndex = 5,
	name = "DisliYazi",
})

------------------------------------------------------------------
-- ALT KOSE  (oyunun adi)
------------------------------------------------------------------
--[[
	Burada ROBLOX LOGOSU ve "(c) Roblox Corporation" YOK, bilerek: bu senin
	oyunun yukleme ekrani, Roblox'un degil. Baskasinin markasini kendi
	ekranina koymak hem yaniltici olur hem de Roblox'un marka kurallarina
	girer. Yerine oyunun kendi adi duruyor; degistirmek icin yukaridaki
	OYUN_ADI yeter.
]]
yazi({
	text = OYUN_ADI,
	textSize = 15,
	color = SOLGUN,
	align = Enum.TextXAlignment.Right,
	size = UDim2.fromOffset(300, 20),
	anchor = Vector2.new(1, 1),
	position = UDim2.new(1, -36, 1, -36),
	parent = perde,
	zIndex = 5,
	name = "OyunAdi",
})

------------------------------------------------------------------
-- ILERLEME
------------------------------------------------------------------
--[[
	CUBUK GERIYE GITMEZ, SICRAMAZ

	Hedef yuzde adim adim degisiyor ama cubuk ona YUMUSAKCA yaklasiyor:
	her karede aradaki farkin bir kismi kapaniyor. Bir obek aninda yuklenip
	yuzde birden ziplasa bile cubuk akici kaliyor.
]]
local hedefYuzde = 0
local gorunenYuzde = 0

-- Ekranin acildigi an; hem cubugun hizi hem kapanma izni buna bagli
local basladi = os.clock()

local function gecenSure(): number
	return os.clock() - basladi
end

local function ilerle(deger: number, metin: string?)
	hedefYuzde = math.clamp(math.max(deger, hedefYuzde), 0, 1)
	if metin then
		durumYazi.Text = metin
	end
end

local cizimBagi: RBXScriptConnection? = nil

cizimBagi = RunService.RenderStepped:Connect(function(dt: number)
	--[[
		CUBUK ZAMANI GECEMEZ

		Gercek ilerleme anlik %100 olsa bile cubuk en az EN_AZ_GORUNME
		saniyede doluyor. Yukleme daha yavassa bu sinir devreye girmiyor:
		ikisinden KUCUK olan kullaniliyor, yani cubuk her zaman gercek
		ilerlemenin gerisinde ya da esitinde.
	]]
	local zamanSiniri = math.clamp(gecenSure() / EN_AZ_GORUNME, 0, 1)
	local hedef = math.min(hedefYuzde, zamanSiniri)

	-- Kare hizindan bagimsiz yumusatma
	gorunenYuzde += (hedef - gorunenYuzde) * math.min(1, dt * 5)

	dolgu.Size = UDim2.fromScale(gorunenYuzde, 1)
	yuzdeYazi.Text = `{math.floor(gorunenYuzde * 100)}% Completed`

	-- Uctaki parlama yalnizca dolgu gorunurken anlamli
	parlama.Visible = gorunenYuzde > 0.02
end)

--[[
	VARLIKLARI ONBELLEGE AL

	ContentProvider varliklari obek obek indiriyor; her obekten sonra yuzde
	ilerliyor. Obek kucuk tutuluyor ki cubuk sik sik ilerlesin -- tek
	seferde hepsini vermek yuzdeyi 0'dan 100'e ziplatirdi.

	PreloadAsync bir varlikta patlarsa butun yukleme durmasin diye her obek
	pcall icinde.
]]
local function varliklariYukle()
	ilerle(0.05, "Reaching the server...")

	local kok = ReplicatedStorage:WaitForChild("Assets", 15)
	if not kok then
		-- Assets gelmedi: yalniz oyunun kendi yuklenmesini bekleyecegiz
		ilerle(0.6, "Loading world...")
		return
	end

	ilerle(0.12, "Loading world assets...")

	--[[
		NE YUKLENIYOR

		Assets altindaki icerik tasiyan HER sey: brainrot ve blok
		modellerinin mesh'leri, dokular, resimler, sesler, animasyonlar.
		Oyuncu oyuna girdiginde hicbiri "yukleniyor" halinde olmasin.

		Modellerin KENDISI listeye girmiyor, icindeki parcalar giriyor:
		PreloadAsync bir Model verilince zaten icini geziyor, ama parca
		parca vermek ilerlemeyi olcmeyi sagliyor -- tek bir devasa model
		verilseydi cubuk o model bitene kadar hic kimildamazdi.
	]]
	local liste: { Instance } = {}
	for _, node in kok:GetDescendants() do
		if
			node:IsA("MeshPart")
			or node:IsA("SpecialMesh")
			or node:IsA("Decal")
			or node:IsA("Texture")
			or node:IsA("ImageLabel")
			or node:IsA("Sound")
			or node:IsA("Animation")
		then
			table.insert(liste, node)
		end
	end

	if #liste == 0 then
		ilerle(0.6, "Loading world...")
		return
	end

	local OBEK = 12
	local islenen = 0

	for bas = 1, #liste, OBEK do
		local obek: { Instance } = {}
		for i = bas, math.min(bas + OBEK - 1, #liste) do
			table.insert(obek, liste[i])
		end

		pcall(function()
			ContentProvider:PreloadAsync(obek)
		end)

		islenen += #obek
		-- Varliklar toplamin %12 ile %75'i arasini dolduruyor
		ilerle(0.12 + (islenen / #liste) * 0.63, `Loading world assets...  {islenen} / {#liste}`)
	end
end

------------------------------------------------------------------
-- KAPANIS
------------------------------------------------------------------
local kapandi = false

local function kapat()
	if kapandi then
		return
	end
	kapandi = true

	-- Sohbet ve oyuncu listesi geri gelsin
	coreGuiGeriAc()

	local sonme = TweenService:Create(
		perde,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ GroupTransparency = 1 }
	)
	sonme:Play()
	sonme.Completed:Wait()

	-- Her kare calisan cizim dongusu ekranla birlikte bitsin
	if cizimBagi then
		cizimBagi:Disconnect()
		cizimBagi = nil
	end

	ekran:Destroy()
end

------------------------------------------------------------------
-- HAZIR: DUGMEYI GOSTER
------------------------------------------------------------------
--[[
	Her sey yuklendiginde (ya da guvenlik agi devreye girdiginde) ekran
	KAPANMIYOR: cubuk doluyor, PLAY dugmesi beliriyor ve oyuncu basana
	kadar bekliyor.

	EN AZ GORUNME burada da gecerli: yukleme anlik bitse bile cubuk o
	sureye yayildigi icin dugme ancak cubuk dolunca cikiyor.
]]
local hazirlandi = false

local function hazirOl()
	if hazirlandi or kapandi then
		return
	end
	hazirlandi = true

	ilerle(1, "Everything is ready")

	-- Cubuk dolana kadar bekle (bkz. zamanSiniri)
	local kalan = EN_AZ_GORUNME - gecenSure()
	if kalan > 0 then
		task.wait(kalan)
	end
	task.wait(0.35)

	if kapandi then
		return
	end

	durumYazi.Text = "Click PLAY to start"
	baslaDugme.Visible = true

	-- Asagidan kucuk bir yaylanmayla girer
	baslaOlcek.Scale = 0.6
	TweenService
		:Create(
			baslaOlcek,
			TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		)
		:Play()
end

baslaDugme.Activated:Connect(kapat)

--[[
	GUVENLIK AGI

	Yukleme takilirsa EN_COK_BEKLEME saniye sonunda dugme yine de cikar.
	Ekrani KAPATMIYOR -- kapatma karari oyuncunun; bu yalnizca "artik
	bekleme" demek.
]]
task.delay(EN_COK_BEKLEME, hazirOl)

task.spawn(function()
	local ok, hata = pcall(varliklariYukle)
	if not ok then
		warn(`[YuklemeEkrani] Varliklar yuklenemedi: {tostring(hata)}`)
	end

	ilerle(0.8, "Waiting for the world...")

	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	--[[
		OYUNCUNUN KENDI VERISI

		leaderstats, sunucu oyuncunun kaydini yukledikten SONRA olusuyor
		(bkz. ServerScriptService > Leaderstats). Yani o geldiyse oyuncunun
		rotu, seviyesi, envanteri hazir demektir.

		Zaman asimi var: veri bir sebeple hic gelmezse ekran burada
		takilmasin, oyuncu yine de oyuna girsin.
	]]
	ilerle(0.88, "Loading your progress...")
	player:WaitForChild("leaderstats", 15)

	ilerle(0.94, "Almost there...")

	-- Karakter gelene kadar bekle: ekran kalkinca oyuncu bosluga dusmesin
	if not player.Character then
		player.CharacterAdded:Wait()
	end

	hazirOl()
end)
