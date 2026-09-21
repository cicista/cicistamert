--[[
	RobuxMagaza  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > RobuxMagaza

	Sag ustteki STORE butonu ve actigi Robux magazasi. Icinde YALNIZCA
	Robux ile alinan seyler var:
	  - Developer Product kartlari (Shared > RobuxMagaza.Kartlar)
	  - Game Pass kartlari (Shared > Passler; RobuxMagaza.Gecisler sirasiyla)

	Burasi yalnizca cizer ve istek yollar; satin alma penceresini SUNUCU
	acar, urunu de sunucu verir (ServerScriptService > RobuxMagaza).

	Menuler'den ayri script: Menuler Luau'nun 200 yerel sinirina yakin ve
	bu panelin oradaki hicbir seye ihtiyaci yok. Tek panel kurali UI
	modulunde oldugu icin burasi acilinca Menuler'in panelleri yine kapanir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Icons = require(Shared:WaitForChild("Icons"))
local Assets = require(Shared:WaitForChild("Assets"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Passler = require(Shared:WaitForChild("Passler"))
local RobuxMagaza = require(Shared:WaitForChild("RobuxMagaza"))

local UI = require(script.Parent:WaitForChild("UI"))

-- Tiklama sesi istege bagli: modul yoksa magaza yine kurulur
local ArayuzSesi = { tikla = function() end }
do
	local modul = script.Parent:WaitForChild("ArayuzSesi", 5)
	if modul then
		local ok, sonuc = pcall(require, modul)
		if ok then
			ArayuzSesi = sonuc
		end
	end
end

local RobuxUrunAl = Net.event("RobuxUrunAl")
local PassSatinAl = Net.event("PassSatinAl")

local SIYAH = Color3.fromRGB(0, 0, 0)
local BEYAZ = Color3.fromRGB(255, 255, 255)
local ALTIN = Color3.fromRGB(255, 200, 40)
local YESIL = Color3.fromRGB(70, 205, 85)
local KIRMIZI = Color3.fromRGB(255, 70, 70)

-- Butonun altinda birakilan 3B kabartma (Menuler'deki menu butonlariyla ayni)
local LIP = 5

--[[
	KARTIN SOLUNDAKI GORSEL

	Sira disi urunler (Lucky Block'lar) 3B modelleriyle ve buyuk duruyor;
	gerisi duz ikon. Lucky kartlarda sol bosluk daha genis cunku modelin
	arkasindaki isik huzmeleri ondan disari tasiyor -- dar biraksak huzmeler
	kartin sol kenarindan cikardi.
]]
local IKON_X = 12
local IKON_NORMAL = 88
local LUCKY_X = 26
local LUCKY_BOYU = 190
-- Lucky kartlari daha uzun: buyuk model ve huzmeler sigsin
local LUCKY_KART_BOYU = 240

--[[
	LUCKY BLOCK HUZMELERI

	Modelin arkasindan cikan donen isik seritleri. Diamond en nadir kademe:
	daha cok, daha uzun ve daha parlak serit alir. Golden'da ayni efektin
	kisik hali. Normal kademe magazada satilmiyor, burada da yok.

	UZUNLUK KARTIN BOYUNDAN UZUN OLMAMALI: seritler donerken kartin disina
	tasar ve listede ust/alt komsusunun uzerine biner. Lucky karti
	LUCKY_KART_BOYU piksel, modelin merkezi de onun tam ortasinda -- yani
	uzunluk o degeri asmamali. Yatayda da ayni sinir: merkez soldan
	LUCKY_X + LUCKY_BOYU/2 kadar iceride.
]]
local HUZME_AYARI: { [string]: UI.HuzmeAyari } = {
	-- Hacker: Diamond kadar gosterisli ama yesil
	Hacker = {
		sayi = 18,
		uzunluk = 240,
		kalinlik = 26,
		-- Diamond 16 saniyede bir tur atiyor; hacker bunun uc kati hizli
		tur = 5,
		parlaklik = 0.06,
		zIndex = 4,
		renk = Color3.fromRGB(70, 255, 120),
	},
	Diamond = { sayi = 12, uzunluk = 240, kalinlik = 34, tur = 16, parlaklik = 0.12, zIndex = 4 },
	--[[
		Golden'in kendi rengi (turuncu) kartin turuncu zemininde kayboluyordu;
		efekti sicak beyaz cizdirip gorunur kildik.
	]]
	Golden = {
		sayi = 8,
		uzunluk = 180,
		kalinlik = 26,
		tur = 20,
		parlaklik = 0.3,
		zIndex = 4,
		renk = Color3.fromRGB(255, 250, 230),
	},
}

--[[
	KART ARKA PLANLARI

	Kademenin kendi arka plan resmi varsa kartin renkli zemininin uzerine
	seriliyor. Resim ReplicatedStorage > Assets > Backgrounds icinden ADA
	GORE bulunuyor (Decal, ImageLabel ya da StringValue tasiyan bir nesne
	olabilir); yoksa kart eskisi gibi duz gradyanla kaliyor.
]]
local ARKA_PLAN: { [string]: string } = {
	Diamond = "diamondbackground",
	Hacker = "hackerbackground",
	Golden = "goldenbackground",
}

--[[
	KIVILCIM SAYISI kademeye gore. Varsayilan 16; Hacker karti "efekte
	bogulmus" gorunsun diye iki katindan fazla aliyor.
]]
local PARILTI_SAYISI: { [string]: number } = {
	Hacker = 34,
}
local PARILTI_VARSAYILAN = 16

-- Arka plan resminin saydamligi ve bulanikligi (bkz. UI.yumusakResim)
local ARKA_PLAN_SAYDAM = 0.42
local ARKA_PLAN_YAYILMA = 3

--[[
	URUN ADININ GORUNUMU

	Varsayilan altin parilti (bkz. urunKarti). Bir kademenin kendi gorunumu
	varsa o gecerli: Diamond magazanin en pahali urunu, adi kendi buz
	mavisiyle ve digerlerinden bir boy buyuk yaziliyor. Arka plan resmi
	geldigi icin mavi yazi artik mavi zeminde kaybolmuyor; yazinin kalin
	siyah konturu da ayirmaya yetiyor.
]]
local BASLIK_GORUNUM: { [string]: { renk: Color3, boyutEk: number } } = {
	Diamond = { renk = Color3.fromRGB(120, 235, 255), boyutEk = 8 },
	Hacker = { renk = Color3.fromRGB(80, 255, 130), boyutEk = 8 },
}

-- Game Pass kartlarindaki ikonlar (Icons.Map kisa adi) ve renkleri
local GECIS_GORUNUM = {
	AutoClicker = { ikon = "shovel", renkA = Color3.fromRGB(255, 120, 60), renkB = Color3.fromRGB(230, 60, 110) },
	Teleporter = { ikon = "teleporter", renkA = Color3.fromRGB(150, 120, 255), renkB = Color3.fromRGB(80, 90, 230) },
	DetectivePass = { ikon = "detective", renkA = Color3.fromRGB(90, 200, 255), renkB = Color3.fromRGB(40, 110, 220) },
}

local screen = Instance.new("ScreenGui")
screen.Name = "RobuxMagazasi"
--[[
	Buradaki tek sey Store BUTONU; panel ortak panel katmaninda duruyor
	(bkz. UI.luau > PANEL KATMANI). Buton XP barinin ustunde, panellerin
	altinda kalsin diye menu butonlariyla ayni katmanda.
]]
screen.DisplayOrder = 5
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

------------------------------------------------------------------
-- ORTAK PARCALAR
------------------------------------------------------------------

-- Kartin zemini: soldan saga gradyan + elmas desen + ust parlaklik
local function renkliZemin(frame: GuiObject, renkA: Color3, renkB: Color3, yaricap: number)
	frame.BackgroundColor3 = BEYAZ

	local gecis = Instance.new("UIGradient")
	gecis.Color = ColorSequence.new(renkA, renkB)
	gecis.Rotation = 0
	gecis.Parent = frame

	UI.caprazDesen(frame)
	UI.gloss(frame, 0.8)

	for _, cocuk in frame:GetChildren() do
		-- Desen bir CanvasGroup, Parlaklik duz Frame: ikisi de GuiObject
		if cocuk:IsA("GuiObject") and (cocuk.Name == "Desen" or cocuk.Name == "Parlaklik") then
			UI.corner(cocuk, yaricap)
		end
	end
end

--[[
	3B SATIN ALMA DUGMESI

	Koyu govde + ustte cilali yuz; basilinca yuz asagi iner (menu
	butonlariyla ayni his). Yazilar yuzun uzerinde. buyusun = true ise
	fare ustune gelince buton merkezinden buyur (listedeki dugmelerde
	kapali: komsularinin ustune tasardi).
]]
local function satinAlmaDugmesi(parent: Instance, renk: Color3, buyusun: boolean?): (TextButton, Frame)
	local buton = Instance.new("TextButton")
	buton.Name = "SatinAl"
	buton.Text = ""
	buton.AutoButtonColor = false
	buton.BackgroundColor3 = UI.shade(renk, -0.3)
	buton.BorderSizePixel = 0
	buton.Parent = parent
	UI.corner(buton, 10)
	--[[
		BEYAZ CERCEVE: kartlarla ayni dil.

		ApplyStrokeMode.Border ACIKCA veriliyor. Varsayilan Contextual bir
		TextButton'da yazinin KENDISINI konturlar; butonun yazisi burada bos
		oldugu icin gorunur bir etkisi olmazdi ama kod ne yaptigini soylesin.

		UI.hover yalnizca BackgroundColor3 ve UIScale oynatiyor, UIStroke'a
		dokunmuyor: fare ustune gelince cerceve bozulmaz, rengi degismez.
		Basilinca inen sey de butonun ICINDEKI yuz, cerceve butonda duruyor.
	]]
	local cerceve = UI.stroke(buton, BEYAZ, 3)
	cerceve.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local yuz = Instance.new("Frame")
	yuz.Name = "Yuz"
	yuz.AnchorPoint = Vector2.new(0.5, 0)
	yuz.Position = UDim2.new(0.5, 0, 0, 3)
	yuz.Size = UDim2.new(1, -6, 1, -6 - LIP)
	yuz.BorderSizePixel = 0
	yuz.ClipsDescendants = true
	yuz.Parent = buton
	UI.corner(yuz, 8)
	UI.polish(yuz, renk, 8)

	local function bas(asagi: boolean)
		yuz.Position = UDim2.new(0.5, 0, 0, if asagi then 3 + LIP / 2 else 3)
	end
	buton.MouseButton1Down:Connect(function()
		bas(true)
	end)
	buton.MouseButton1Up:Connect(function()
		bas(false)
	end)
	buton.MouseLeave:Connect(function()
		bas(false)
	end)

	UI.hover(buton, yuz, if buyusun then buton else nil)

	return buton, yuz
end

-- Dugme yuzune ortalanmis yazi
local function yuzYazisi(yuz: Frame, yazi: string, boyut: number, y: number, yukseklik: number): TextLabel
	return UI.text({
		text = yazi,
		size = boyut,
		font = UI.Fonts.bold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -4, 0, yukseklik),
		position = UDim2.new(0, 2, 0, y),
		parent = yuz,
		zIndex = 5,
	})
end

--[[
	ROBUX IKONU  --  once resim, olmazsa 3B nesne

	Assets > Icons > Robux bir MeshPart olarak konmus. Uzerinde doku
	(TextureID) varsa onu duz bir resim gibi kullanmak en ucuzu. Doku yoksa
	-- mesh rengiyle yapilmis olabilir -- nesnenin KENDISI kucuk bir
	ViewportFrame'de gosteriliyor.

	Ikisi de olmazsa eski "R$ 99" yazisina duseriz, yani ikon konmadan
	once de magaza dogru gorunur.
]]
local function robuxNesnesi(): Instance?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local ikonlar = assets and assets:FindFirstChild("Icons")
	local node = ikonlar and ikonlar:FindFirstChild("Robux", true)
	return if node and (node:IsA("BasePart") or node:IsA("Model")) then node:Clone() else nil
end

local function robuxYazisi(yuz: Frame, miktar: number, boyut: number, y: number, yukseklik: number): Frame?
	local resim = Icons.asset("Robux")
	local nesne = if resim then nil else robuxNesnesi()

	if not resim and not nesne then
		yuzYazisi(yuz, `R$ {miktar}`, boyut, y, yukseklik)
		return nil
	end

	local kutu = Instance.new("Frame")
	kutu.Name = "Fiyat"
	kutu.AnchorPoint = Vector2.new(0.5, 0)
	kutu.Position = UDim2.new(0.5, 0, 0, y)
	kutu.Size = UDim2.fromOffset(0, yukseklik)
	kutu.AutomaticSize = Enum.AutomaticSize.X
	kutu.BackgroundTransparency = 1
	kutu.ZIndex = 5
	kutu.Parent = yuz

	local dizilim = Instance.new("UIListLayout")
	dizilim.FillDirection = Enum.FillDirection.Horizontal
	dizilim.VerticalAlignment = Enum.VerticalAlignment.Center
	dizilim.Padding = UDim.new(0, 3)
	dizilim.SortOrder = Enum.SortOrder.LayoutOrder
	dizilim.Parent = kutu

	if resim then
		local ikon = Instance.new("ImageLabel")
		ikon.Name = "Ikon"
		ikon.BackgroundTransparency = 1
		ikon.Image = resim
		ikon.ScaleType = Enum.ScaleType.Fit
		ikon.Size = UDim2.fromOffset(boyut, boyut)
		ikon.LayoutOrder = 1
		ikon.ZIndex = 5
		ikon.Parent = kutu
	elseif nesne then
		local kare = UI.modelKaresi(kutu, nesne, boyut + 4, 5)
		if kare then
			kare.Name = "Ikon"
			kare.LayoutOrder = 1
		end
	end

	local sayi = UI.text({
		text = tostring(miktar),
		size = boyut,
		font = UI.Fonts.bold,
		frameSize = UDim2.fromOffset(0, yukseklik),
		parent = kutu,
		zIndex = 5,
	})
	sayi.AutomaticSize = Enum.AutomaticSize.X
	sayi.LayoutOrder = 2

	return kutu
end

-- Kartin sol ustundeki egik serit: "NEW!", "HOT!"
local function serit(kart: Frame, yazi: string)
	local etiket = UI.text({
		text = yazi,
		size = UI.Sizes.heading,
		font = UI.Fonts.bold,
		color = KIRMIZI,
		frameSize = UDim2.fromOffset(90, 30),
		position = UDim2.fromOffset(-12, -14),
		parent = kart,
		zIndex = 8,
	})
	etiket.Name = "Serit"
	etiket.Rotation = -14

	-- Hafif nabiz: gozden kacmasin ama goz yormasin
	local olcek = Instance.new("UIScale")
	olcek.Parent = etiket
	TweenService:Create(
		olcek,
		TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Scale = 1.12 }
	):Play()
end

-- Kartin solundaki buyuk ikon; ikon bulunamazsa yerinde yedek yazi durur
local function kartIkonu(kart: Frame, ikonAdi: string, boyut: number, renk: Color3?): ImageLabel
	local ikon = Instance.new("ImageLabel")
	ikon.Name = "Ikon"
	ikon.BackgroundTransparency = 1
	ikon.AnchorPoint = Vector2.new(0, 0.5)
	ikon.Position = UDim2.new(0, IKON_X, 0.5, 0)
	ikon.Size = UDim2.fromOffset(boyut, boyut)
	ikon.ScaleType = Enum.ScaleType.Fit
	ikon.ZIndex = 5
	ikon.Parent = kart
	if renk then
		ikon.ImageColor3 = BEYAZ:Lerp(renk, 0.35)
	end

	local yedek = UI.text({
		text = "?",
		size = UI.Sizes.huge,
		font = UI.Fonts.bold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = ikon,
		zIndex = 5,
	})

	Icons.bind(ikon, ikonAdi, function(ok)
		if ok then
			yedek.Visible = false
		end
	end)

	return ikon
end

------------------------------------------------------------------
-- PANEL
------------------------------------------------------------------
--[[
	Panel Lucky Block kartlari buyuyunce genisletildi: model + huzmeler
	soldan 188 piksel yiyor, eski 640'ta uc satin alma dugmesi sikisiyordu.
]]
local panel = UI.panel(screen, UDim2.fromOffset(720, 540), "RobuxMagaza")
do
	local kontur = panel:FindFirstChildOfClass("UIStroke")
	if kontur then
		kontur.Color = SIYAH
		kontur.Thickness = 3
	end
end

-- Ust baslik cubugu: altin, cilali
local baslik = Instance.new("Frame")
baslik.Name = "Baslik"
baslik.Position = UDim2.fromOffset(8, 8)
baslik.Size = UDim2.new(1, -16, 0, 54)
baslik.BorderSizePixel = 0
baslik.ClipsDescendants = true
baslik.Parent = panel
UI.corner(baslik, 10)
UI.polish(baslik, ALTIN, 10)
UI.stroke(baslik, SIYAH, 2)

do
	local ikon = Instance.new("ImageLabel")
	ikon.Name = "Ikon"
	ikon.BackgroundTransparency = 1
	ikon.Position = UDim2.fromOffset(8, 3)
	ikon.Size = UDim2.fromOffset(48, 48)
	ikon.ScaleType = Enum.ScaleType.Fit
	ikon.ZIndex = 5
	ikon.Parent = baslik
	Icons.bind(ikon, "shop")

	UI.text({
		text = "Store",
		size = UI.Sizes.title,
		font = UI.Fonts.bold,
		frameSize = UDim2.new(1, -140, 1, 0),
		position = UDim2.fromOffset(62, 0),
		parent = baslik,
		zIndex = 5,
	})
end

-- Kapatma dugmesi baslik cubugunun sag ucunda
local kapat = UI.closeButton(panel)
kapat.Position = UDim2.new(1, -18, 0, 18)
kapat.ZIndex = 6
UI.stroke(kapat, SIYAH, 2)
kapat.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

--[[
	LISTE BIR CanvasGroup ICINDE

	Kartlardaki bazi parcalar DONDURULMUS: sallanan Lucky Block ikonu, egik
	"NEW!/HOT!" seridi, ustu cizili eski fiyat. Roblox dondurulmus nesneleri
	ScrollingFrame'in ClipsDescendants'i ile KIRPMIYOR; kaydirinca bunlar
	listenin disina, altin baslik cubugunun ustune tasiyordu.

	CanvasGroup icerigini tek bir resim olarak cizip kendi sinirinda keser;
	dondurulmus olanlar dahil hicbir sey listenin disina cikamaz.
]]
local listeKabi = Instance.new("CanvasGroup")
listeKabi.Name = "ListeKabi"
listeKabi.Position = UDim2.fromOffset(12, 72)
listeKabi.Size = UDim2.new(1, -24, 1, -84)
listeKabi.BackgroundTransparency = 1
listeKabi.BorderSizePixel = 0
listeKabi.Parent = panel

local liste = Instance.new("ScrollingFrame")
liste.Name = "Liste"
liste.Size = UDim2.fromScale(1, 1)
liste.BackgroundTransparency = 1
liste.BorderSizePixel = 0
liste.ScrollBarThickness = 6
liste.ScrollBarImageColor3 = UI.Colors.panelLight
liste.CanvasSize = UDim2.new()
liste.AutomaticCanvasSize = Enum.AutomaticSize.Y
liste.Parent = listeKabi

do
	local dizilim = Instance.new("UIListLayout")
	dizilim.Padding = UDim.new(0, 16)
	dizilim.SortOrder = Enum.SortOrder.LayoutOrder
	dizilim.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dizilim.Parent = liste

	-- Seritler ve konturlar kartin disina tasiyor; kenarda pay birak
	local pay = Instance.new("UIPadding")
	pay.PaddingTop = UDim.new(0, 16)
	pay.PaddingBottom = UDim.new(0, 12)
	pay.PaddingLeft = UDim.new(0, 14)
	pay.PaddingRight = UDim.new(0, 14)
	pay.Parent = liste
end

local sira = 0
local function sonraki(): number
	sira += 1
	return sira
end

local function bolumBasligi(yazi: string)
	local etiket = UI.text({
		text = yazi,
		size = UI.Sizes.heading,
		font = UI.Fonts.bold,
		color = ALTIN,
		frameSize = UDim2.new(1, 0, 0, 28),
		parent = liste,
	})
	etiket.LayoutOrder = sonraki()
end

------------------------------------------------------------------
-- LUCKY BLOCK ONIZLEMESI  --  gercek 3B model
------------------------------------------------------------------
--[[
	Kartin solundaki kare bir ViewportFrame ve icinde blogun KENDI modeli
	duruyor, resmi degil: Lucky Block magazanin sattigi asil urun, oyuncu
	ne aldigini gormeli. Model bulunamazsa cagiran taraf ikona duser.

	MODEL DONMEZ, SALLANIR. Yuzu ekrana bakar ve kendi dikey ekseninde iki
	yana UI.SallanmaAci kadar gidip gelir -- ikonlarla ayni ritimde. Tam tur
	atan bir blok vaktin yarisinda kendi arkasini gosteriyordu.

	PAKETIN KENDI SCRIPTLERI SILINIYOR. Hazir Lucky Block paketleri modelin
	icine dondurme, ses ve parcacik scriptleri koyuyor; onizlemede calisip
	sahneyi kendi bildigince oynatirlardi (bkz. Assets.stripScripts, ayni
	sebeple).

	SALINIM RenderStepped'te, tween ile degil: CFrame tween'i icin araya bir
	CFrameValue koymak gerekirdi ve panel kapaliyken de donerdi. Burada
	panel gorunmuyorsa hic hesap yapilmiyor.
]]

-- Modeller yuzu -Z'ye bakacak sekilde hazirlanmis (bkz. BrainrotOnizleme)
local BAKIS_YONU = Vector3.new(0, 0, -1)
local ONIZLEME_ISIGI = Color3.fromRGB(255, 255, 255)
local ONIZLEME_ISIK_YONU = Vector3.new(-0.4, -0.7, -0.6)
--[[
	Kamera kutunun kosegeninin bu kati kadar geri cekilir. 1'in altinda kare
	dolar; pay birakildi cunku blok sallanirken kosesi kadraja giriyor.
]]
local ONIZLEME_CERCEVE = 0.78

--[[
	DURUS  --  blok tam karsidan degil, ucte-dortluk acidan gorunur

	Tam karsidan bakan bir kup duz bir kareye benziyor ve sert duruyor.
	Blok saga ve asagi cevrilince on yuzu hala okunur ama yan ve ust yuzleri
	de girer: hacimli ve yumusak gorunur.

	Isaretler kameraya gore -- model yuzu -Z'ye bakiyor, kamera da -Z'de:
	yatayda ARTI aci yuzu SAGA cevirir, dikeyde EKSI aci ASAGI egdirir.
]]
local DURUS = CFrame.Angles(0, math.rad(28), 0) * CFrame.Angles(math.rad(-16), 0, 0)

-- Sallanan onizlemeler; hepsi tek bir RenderStepped'te donuyor
local onizlemeler: { { model: Model, merkez: Vector3, taban: CFrame } } = {}

--[[
	KADRAJ YALNIZCA GORUNEN PARCALARDAN

	Model:GetBoundingBox() gorunmez parcalari da sayiyor -- efekt tasiyicilar,
	carpisma kutulari, bos tutamaklar -- ve blok o yuzden karenin ortasinda
	kucucuk kaliyor. Kutu burada yalnizca GORUNUR parcalardan ve DUNYA
	eksenlerinde hesaplaniyor. Ayni cozum BrainrotOnizleme'de de var.

	Merkez ve kutu boyutu doner; hic gorunur parca yoksa ikisi de nil.
]]
local function gorunenKutu(model: Model): (Vector3?, Vector3?)
	local enAz: Vector3? = nil
	local enCok: Vector3? = nil

	for _, parca in model:GetDescendants() do
		if not parca:IsA("BasePart") or parca.Transparency >= 0.99 then
			continue
		end

		local cf, olcu = parca.CFrame, parca.Size
		-- Parcanin sekiz kosesi: donuk parcalarda dunya kutusu boyle cikar
		for _, sx in { -0.5, 0.5 } do
			for _, sy in { -0.5, 0.5 } do
				for _, sz in { -0.5, 0.5 } do
					local kose = (cf * CFrame.new(olcu.X * sx, olcu.Y * sy, olcu.Z * sz)).Position
					enAz = if enAz then enAz:Min(kose) else kose
					enCok = if enCok then enCok:Max(kose) else kose
				end
			end
		end
	end

	if not enAz or not enCok then
		return nil, nil
	end
	return (enAz + enCok) / 2, enCok - enAz
end

--[[
	Model kademenin TAM ADIYLA araniyor ("Golden Lucky Block"), kimligiyle
	degil: klasordeki modeller o adi tasiyor. Yalnizca kimlik ("Golden")
	verildiginde eslesme tutmuyor, Assets siraya dusuyor ve sira ada gore
	oldugu icin Golden'in yerine Diamond geliyordu.
]]
local function luckyOnizleme(kart: Frame, tier: any, x: number, boyut: number): ViewportFrame?
	local model = Assets.luckyBlockModel(tier.modelName or tier.displayName, tier.order)
	if not model then
		return nil
	end

	--[[
		MODELIN EFEKTLERI KALIYOR; yalnizca script ve ses siliniyor. Paketin
		kendi scriptleri modeli kendi bildigince dondurur, sesleri de magaza
		acikken calardi.

		NOT: ViewportFrame ParticleEmitter, Beam, Trail ve isik kaynaklarini
		CIZMEZ, bu Roblox'un sinirlamasi. Duruyorlar ama gorunmuyorlar;
		kadraja giren sey modelin GORUNUR parcalari (neon halkalar, cam
		yuzeyler, mesh'ler). Blogun etrafindaki parlamayi UI.isikHuzmeleri
		yapiyor.
	]]
	for _, nesne in model:GetDescendants() do
		if nesne:IsA("BaseScript") or nesne:IsA("Sound") then
			nesne:Destroy()
		end
	end

	local merkez, kutuBoyut = gorunenKutu(model)
	if not merkez or not kutuBoyut then
		model:Destroy()
		return nil
	end

	local vp = Instance.new("ViewportFrame")
	vp.Name = "Onizleme"
	vp.AnchorPoint = Vector2.new(0, 0.5)
	vp.Position = UDim2.new(0, x, 0.5, 0)
	vp.Size = UDim2.fromOffset(boyut, boyut)
	vp.BackgroundTransparency = 1
	-- ViewportFrame sahnenin isigini KULLANMAZ; kendi isigi olmazsa model kararir
	vp.Ambient = ONIZLEME_ISIGI
	vp.LightColor = ONIZLEME_ISIGI
	vp.LightDirection = ONIZLEME_ISIK_YONU
	vp.ZIndex = 5
	vp.Parent = kart

	model.Parent = vp

	local kamera = Instance.new("Camera")
	kamera.Parent = vp
	vp.CurrentCamera = kamera

	kamera.CFrame = CFrame.lookAt(merkez + BAKIS_YONU * kutuBoyut.Magnitude * ONIZLEME_CERCEVE, merkez)

	table.insert(onizlemeler, { model = model, merkez = merkez, taban = model:GetPivot() })

	return vp
end

RunService.RenderStepped:Connect(function()
	if not panel.Visible then
		return
	end

	--[[
		UI.sallan ile AYNI RITIM: tween -aci ile +aci arasinda gidip geliyor,
		yani tam donem sallanma suresinin iki kati. Sinus de o donemde.
	]]
	local aci = math.rad(UI.SallanmaAci) * math.sin(os.clock() * math.pi / UI.SallanmaSuresi)

	for _, kayit in onizlemeler do
		if not kayit.model.Parent then
			continue
		end
		--[[
			Sabit DURUS'un uzerine salinim biniyor, ikisi de KUTUNUN MERKEZI
			etrafinda: modelin pivotu baska bir yerdeyse blok salinirken
			kadrajda kayardi.
		]]
		local donus = CFrame.new(kayit.merkez)
			* CFrame.Angles(0, aci, 0)
			* DURUS
			* CFrame.new(-kayit.merkez)
		kayit.model:PivotTo(donus * kayit.taban)
	end
end)

------------------------------------------------------------------
-- LUCKY BLOCK SANS ORANLARI
------------------------------------------------------------------
local function tierBul(id: string): any
	for _, tier in LuckyBlock.Tiers do
		if tier.id == id then
			return tier
		end
	end
	return nil
end

-- "40%", "1.5%"
local function yuzdeYazisi(oran: number): string
	local yuzde = oran * 100
	if yuzde >= 10 then
		return `{math.floor(yuzde + 0.5)}%`
	end
	return `{string.format("%g", math.floor(yuzde * 10 + 0.5) / 10)}%`
end

local function oranSatiri(parent: Instance, tierId: string, x: number, y: number)
	local tier = tierBul(tierId)
	if not tier then
		return
	end

	local toplam = 0
	for _, agirlik in tier.rarityWeights do
		toplam += agirlik
	end
	if toplam <= 0 then
		return
	end

	--[[
		BEYAZ SERIT: oranlar arka plan resminin uzerinde okunsun diye altlarina
		aciklik seriliyor. Yazilarin kendi siyah konturu var, bu yuzden serit
		opak degil -- altindaki resim hafifce gecer, yazi yine de secilir.

		Serit ICERIGE GORE UZUYOR (AutomaticSize): sabit genislikte olsaydi
		son cipten sonra bos beyaz bir kuyruk kalirdi.
	]]
	local satir = Instance.new("Frame")
	satir.Name = "Oranlar"
	satir.BackgroundColor3 = BEYAZ
	satir.BackgroundTransparency = 0.25
	satir.BorderSizePixel = 0
	satir.AutomaticSize = Enum.AutomaticSize.X
	satir.Position = UDim2.fromOffset(x, y)
	satir.Size = UDim2.fromOffset(0, 26)
	-- Arka plan resminin (ZIndex 1) ustunde, ciplerin (5) altinda
	satir.ZIndex = 4
	satir.Parent = parent
	UI.corner(satir, 8)

	local kenarPay = Instance.new("UIPadding")
	kenarPay.PaddingLeft = UDim.new(0, 8)
	kenarPay.PaddingRight = UDim.new(0, 8)
	kenarPay.Parent = satir

	local dizilim = Instance.new("UIListLayout")
	dizilim.FillDirection = Enum.FillDirection.Horizontal
	dizilim.Padding = UDim.new(0, 6)
	dizilim.SortOrder = Enum.SortOrder.LayoutOrder
	dizilim.Parent = satir

	-- Rarity sirasiyla (Rare, Epic, ..., Secret)
	for siraNo, rarityId in Rarity.Order do
		local agirlik = tier.rarityWeights[rarityId]
		if not agirlik or agirlik <= 0 then
			continue
		end

		-- Cipin kendi zemini yok: aciklik satirin tamamina seriliyor (yukarida)
		local cip = Instance.new("Frame")
		cip.Name = rarityId
		cip.BackgroundTransparency = 1
		cip.BorderSizePixel = 0
		cip.Size = UDim2.fromOffset(0, 26)
		cip.AutomaticSize = Enum.AutomaticSize.X
		cip.LayoutOrder = siraNo
		cip.ZIndex = 5
		cip.Parent = satir
		local ic = Instance.new("UIPadding")
		ic.PaddingLeft = UDim.new(0, 8)
		ic.PaddingRight = UDim.new(0, 8)
		ic.Parent = cip

		local yazi = UI.text({
			text = `{Rarity.displayName(rarityId)} {yuzdeYazisi(agirlik / toplam)}`,
			size = UI.Sizes.tiny,
			font = UI.Fonts.bold,
			color = Rarity.textColor(rarityId),
			frameSize = UDim2.fromOffset(0, 26),
			parent = cip,
			zIndex = 6,
		})
		yazi.AutomaticSize = Enum.AutomaticSize.X
	end
end

------------------------------------------------------------------
-- DEVELOPER PRODUCT KARTLARI
------------------------------------------------------------------
local function urunDugmesi(parent: Instance, urun: RobuxMagaza.Urun)
	local buton, yuz = satinAlmaDugmesi(parent, YESIL)

	robuxYazisi(yuz, urun.fiyat, UI.Sizes.label, 2, 24)
	yuzYazisi(yuz, urun.etiket, UI.Sizes.small, 24, 18)

	-- Indirimli urunde eski fiyat ustu cizili, dugmenin koseside egik
	if urun.eskiFiyat then
		local eski = UI.text({
			text = `<s>R$ {urun.eskiFiyat}</s>`,
			size = UI.Sizes.small,
			font = UI.Fonts.bold,
			color = KIRMIZI,
			align = Enum.TextXAlignment.Right,
			frameSize = UDim2.fromOffset(90, 20),
			position = UDim2.new(1, 4, 0, -14),
			anchor = Vector2.new(1, 0),
			parent = buton,
			zIndex = 8,
		})
		eski.RichText = true
		eski.Rotation = -8
	end

	buton.MouseButton1Click:Connect(function()
		ArayuzSesi.tikla()
		RobuxUrunAl:FireServer(urun.anahtar)
	end)

	return buton
end

local function urunKarti(kart: RobuxMagaza.Kart)
	local coklu = #kart.urunler > 1
	local oranli = kart.tier ~= nil

	local tier = if kart.tier then tierBul(kart.tier) else nil

	--[[
		LUCKY BLOCK KARTLARI magazanin asil urunu: gercek 3B modelleriyle,
		buyuk ve arkalarinda donen isik huzmeleriyle duruyorlar. Huzme ayari
		kademeye gore degisir -- Diamond en nadiri, en gosterisli o.
	]]
	local huzme = if tier then HUZME_AYARI[tier.id] else nil
	local gorselX = if huzme then LUCKY_X else IKON_X
	local gorselBoyu = if huzme then LUCKY_BOYU else IKON_NORMAL
	-- Yazilar ve dugmeler gorselin SAGINDA basliyor; gorsel buyuyunce kayarlar
	local yaziX = gorselX + gorselBoyu + 12

	--[[
		SAG TARAFIN DIKEY DAGILIMI

		Lucky karti normal kartin iki kati boyunda. Normal yerlesim oldugu
		gibi kullanilinca baslik tepeye, dugmeler dibe yapisiyor ve ortada
		kocaman bir bosluk kaliyor.

		Lucky kartinda ACIKLAMA SATIRI DA YOK (asagida atlaniyor), yani uc
		satir kaliyor: ad, oranlar, dugmeler. Degerler LUCKY_KART_BOYU = 240
		icin ustte 44, altta 28 bosluk birakiyor.
	]]
	local baslikY = if huzme then 44 elseif coklu then 8 else 22
	local altBaslikY = if coklu then 40 else 56
	local oranY = if huzme then 106 else 72
	local dugmeAlt = if huzme then 28 else 10

	--[[
		Yukseklik: baslik alani + (oranlar) + (dugme sirasi). Lucky kartlari
		bundan bagimsiz ve sabit: icindeki modelle huzmelerin sigmasi lazim.
	]]
	local yukseklik = if huzme
		then LUCKY_KART_BOYU
		elseif coklu then 72 + (if oranli then 32 else 0) + 64
		else 116

	local cerceve = Instance.new("Frame")
	cerceve.Name = kart.id
	cerceve.Size = UDim2.new(1, 0, 0, yukseklik)
	cerceve.BorderSizePixel = 0
	cerceve.LayoutOrder = sonraki()
	cerceve.Parent = liste
	UI.corner(cerceve, 12)
	-- Store kartlarinin imzasi: kalin BEYAZ kontur, koyu panel zemininden ayirir
	UI.stroke(cerceve, BEYAZ, 4)
	renkliZemin(cerceve, kart.renkA, kart.renkB, 12)

	--[[
		Kademenin arka plan resmi varsa renkli zeminin UZERINE seriliyor:
		gradyan altindan hafifce gecsin diye resim yari saydam. Resim yoksa
		(klasor bos ya da ad tutmadi) kart eskisi gibi duz gradyanla kaliyor.

		ZINDEX KARTIN KENDISIYLE AYNI (1), 2 DEGIL. Butonlar ve kartin
		govdesi de ZIndex 1'de; ZIndexBehavior.Sibling'de esit ZIndex'te sira
		EKLEME SIRASINA kaliyor ve resim buradan, butonlardan once ekleniyor.
		2 verildiginde resim butonlarin ve dugme yuzlerinin onune gecip
		hepsini soldurmustu.
	]]
	local arkaPlanAdi = if tier then ARKA_PLAN[tier.id] else nil
	local arkaPlan = if arkaPlanAdi
		then Icons.assetKlasorden(Assets.Categories.backgrounds, arkaPlanAdi)
		else nil
	if arkaPlan then
		local kap = UI.yumusakResim(cerceve, arkaPlan, ARKA_PLAN_SAYDAM, ARKA_PLAN_YAYILMA, 1)
		-- Kartinkiyle ayni yaricap: CanvasGroup kirpmayi da yuvarlatiyor
		UI.corner(kap, 12)
	end

	--[[
		HACKER TEMASI: arka planin uzerinden asagi akan yesil rakamlar.
		Kartin kendi resmi olsa da olmasa da ekleniyor; yagmur kademeye
		ozel, resme degil.
	]]
	if tier and tier.id == "Hacker" then
		-- Yogun ve hizli: 18 sutun, bastan asagi 1.8 saniyede iniyor
		UI.corner(UI.sayiYagmuru(cerceve, Color3.fromRGB(90, 255, 140), 18, 1, 1.8, 0.32), 12)
	end

	--[[
		LUCKY BLOCK'UN GORSEL KATMANLARI, arkadan one:

		  1  arka plan   kademenin kendi resmi (varsa), yumusatilmis
		  1  pariltilar  arka planin uzerinde, kart boyunca sonup yanan kivilcimlar
		  4  huzmeler    modelden disari uzanan donen seritler
		  4  parlama     modelin arkasindaki hale
		  5  MODEL       ViewportFrame

		Esit ZIndex'tekilerin sirasini EKLEME SIRASI belirliyor: arka plan,
		pariltilar, sonra (asagida) satin alma dugmeleri. Ayrintisi her birinin
		kendi notunda.

		Parlama ve pariltilar ViewportFrame'in cizemedigi seyin yerini
		tutuyor: onizleme ne ParticleEmitter/Beam/Trail ciziyor ne de Neon
		parcalarin isimasini (post-processing yok). Ayrintisi UI.parlama'da.
	]]
	local gorselMerkez = UDim2.fromOffset(gorselX + gorselBoyu / 2, yukseklik / 2)
	-- Efektin rengi ayarda verilmisse ondan, yoksa kademenin kendi renginden
	local efektRengi = if tier then (if huzme then huzme.renk else nil) or tier.color else nil

	if huzme and tier and efektRengi then
		UI.isikHuzmeleri(cerceve, efektRengi, huzme).Position = gorselMerkez
		UI.parlama(cerceve, efektRengi, gorselBoyu, 4).Position = gorselMerkez
	end

	--[[
		Lucky Block'lar 3B model; model bulunamazsa (Assets > LuckyBlocks bos)
		karti bos birakmak yerine ikona duser. Model kendi ekseninde sallanir,
		ikon ise 2B olarak -- ikisi de UI.sallan'in ritminde.
	]]
	local onizleme = if tier then luckyOnizleme(cerceve, tier, gorselX, gorselBoyu) else nil
	if not onizleme then
		local ikon = kartIkonu(cerceve, kart.ikon, gorselBoyu, if tier then tier.color else nil)
		ikon.Position = UDim2.new(0, gorselX, 0.5, 0)
		UI.sallan(ikon)
	end

	--[[
		KIVILCIMLAR ARKA PLANIN UZERINE, KARTIN TAMAMINA yayiliyor -- eskiden
		yalnizca modelin oturdugu kareyi kapliyorlardi ve arka plan resmi
		gelince onun deseninde kayboluyorlardi.

		ZINDEX 1, yani kartin kendisiyle ayni. Sibling davranisinda esit
		ZIndex'te sira EKLEME SIRASINA kaliyor: kivilcimlar arka plandan SONRA
		kuruldugu icin onun uzerinde, satin alma dugmelerinden ONCE kuruldugu
		icin onlarin altinda kaliyor. 2 verilseydi dugme govdelerinin onune
		gecerlerdi.
	]]
	if onizleme and tier then
		local pariltiAlani = Instance.new("Frame")
		pariltiAlani.Name = "PariltiAlani"
		pariltiAlani.Size = UDim2.fromScale(1, 1)
		pariltiAlani.BackgroundTransparency = 1
		-- Kartin yuvarlak kenarindan tasmasinlar
		pariltiAlani.ClipsDescendants = true
		pariltiAlani.ZIndex = 1
		pariltiAlani.Parent = cerceve
		UI.corner(pariltiAlani, 12)

		-- Hacker temasinda kivilcimlar rakam olarak ciziliyor
		UI.pariltilar(
			pariltiAlani,
			efektRengi or tier.color,
			PARILTI_SAYISI[tier.id] or PARILTI_VARSAYILAN,
			1,
			tier.id == "Hacker"
		)
	end

	-- Tek urunlu kartta dugme sagda; yazi alani ona gore daralir
	local yaziEni = if coklu
		then UDim2.new(1, -(yaziX + 12), 0, 32)
		else UDim2.new(1, -(yaziX + 198), 0, 32)

	--[[
		URUNUN ADI: BUYUK HARF + PARILTI

		Satilan seyin adi kartin en gorunur yazisi olsun diye buyuk harfle ve
		Fonts.applyGlow'un gecisiyle yaziliyor (ustte ve altta acik, ortada
		ana renk). Varsayilan altin: her kart renginde -- mavi, turuncu,
		yesil -- okunuyor. Kademenin kendi gorunumu varsa o gecerli
		(bkz. BASLIK_GORUNUM).

		Cerceve yuksekligi yazi boyutundan TURETILIYOR: Diamond'in bir boy
		buyuk adi sabit 32 pikselde kirpilirdi.
	]]
	local baslikGorunum = if tier then BASLIK_GORUNUM[tier.id] else nil
	local baslikBoyu = UI.Sizes.heading + 2 + (if baslikGorunum then baslikGorunum.boyutEk else 0)

	UI.text({
		text = string.upper(kart.baslik),
		size = baslikBoyu,
		font = UI.Fonts.bold,
		glow = if baslikGorunum then baslikGorunum.renk else ALTIN,
		frameSize = UDim2.new(yaziEni.X.Scale, yaziEni.X.Offset, 0, baslikBoyu + 12),
		position = UDim2.fromOffset(yaziX, baslikY),
		parent = cerceve,
		zIndex = 5,
	})

	--[[
		ACIKLAMA SATIRI LUCKY KARTLARINDA YOK: adin altindaki oran seridi
		zaten "ne alacagini" soyluyor ve kart modeliyle, huzmeleriyle
		fazlasiyla dolu. Diger kartlarda duruyor.
	]]
	if not huzme then
		UI.text({
			text = kart.altBaslik,
			size = UI.Sizes.small,
			font = UI.Fonts.bold,
			frameSize = UDim2.new(yaziEni.X.Scale, yaziEni.X.Offset, 0, 22),
			position = UDim2.fromOffset(yaziX, altBaslikY),
			parent = cerceve,
			zIndex = 5,
		})
	end

	if kart.serit then
		serit(cerceve, kart.serit)
	end

	if not coklu then
		local buton = urunDugmesi(cerceve, kart.urunler[1])
		buton.AnchorPoint = Vector2.new(1, 0.5)
		buton.Position = UDim2.new(1, -14, 0.5, 0)
		buton.Size = UDim2.fromOffset(170, 58)
		return
	end

	if oranli and kart.tier then
		oranSatiri(cerceve, kart.tier, yaziX, oranY)
	end

	local dugmeler = Instance.new("Frame")
	dugmeler.Name = "Dugmeler"
	dugmeler.BackgroundTransparency = 1
	dugmeler.AnchorPoint = Vector2.new(0, 1)
	dugmeler.Position = UDim2.new(0, yaziX, 1, -dugmeAlt)
	dugmeler.Size = UDim2.new(1, -(yaziX + 12), 0, 56)
	dugmeler.Parent = cerceve

	local dizilim = Instance.new("UIListLayout")
	dizilim.FillDirection = Enum.FillDirection.Horizontal
	dizilim.Padding = UDim.new(0, 10)
	dizilim.SortOrder = Enum.SortOrder.LayoutOrder
	dizilim.Parent = dugmeler

	local adet = #kart.urunler
	for siraNo, urun in kart.urunler do
		local buton = urunDugmesi(dugmeler, urun)
		buton.LayoutOrder = siraNo
		buton.Size = UDim2.new(1 / adet, -10 * (adet - 1) / adet, 1, 0)
	end
end

------------------------------------------------------------------
-- GAME PASS KARTLARI
------------------------------------------------------------------
-- Gecis alininca kartin dugmesi yeniden cizilir
local gecisCizimleri: { () -> () } = {}

local function gecisKarti(parent: Instance, ad: string, siraNo: number)
	local info = Passler.get(ad)
	if not info then
		return
	end
	local gorunum = GECIS_GORUNUM[ad] or GECIS_GORUNUM.Teleporter

	local kart = Instance.new("Frame")
	kart.Name = ad
	kart.BorderSizePixel = 0
	kart.LayoutOrder = siraNo
	kart.Parent = parent
	UI.corner(kart, 12)
	-- Urun kartlariyla ayni: kalin beyaz kontur
	UI.stroke(kart, BEYAZ, 4)
	renkliZemin(kart, gorunum.renkA, gorunum.renkB, 12)

	local ikon = kartIkonu(kart, gorunum.ikon, 56)
	ikon.AnchorPoint = Vector2.zero
	ikon.Position = UDim2.fromOffset(10, 10)

	-- Urun kartlariyla ayni: buyuk harf + altin parilti (bkz. urunKarti)
	UI.text({
		text = string.upper(info.ad),
		size = UI.Sizes.label,
		font = UI.Fonts.bold,
		glow = ALTIN,
		frameSize = UDim2.new(1, -80, 0, 26),
		position = UDim2.fromOffset(72, 10),
		parent = kart,
		zIndex = 5,
	})

	UI.text({
		text = info.aciklama,
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		frameSize = UDim2.new(1, -80, 0, 40),
		position = UDim2.fromOffset(72, 36),
		alignY = Enum.TextYAlignment.Top,
		wrapped = true,
		parent = kart,
		zIndex = 5,
	})

	local buton, yuz = satinAlmaDugmesi(kart, YESIL)
	buton.AnchorPoint = Vector2.new(0.5, 1)
	buton.Position = UDim2.new(0.5, 0, 1, -10)
	buton.Size = UDim2.new(1, -20, 0, 50)

	local yazi = yuzYazisi(yuz, "", UI.Sizes.label, 0, 36)
	yazi.Size = UDim2.new(1, -4, 1, 0)

	local function ciz()
		local sahip = Passler.sahip(player, ad)
		yazi.Text = if sahip then "OWNED" else `R$ {info.fiyat}`
		buton.Active = not sahip
		buton.AutoButtonColor = false
		-- Sahip olunan gecisin dugmesi gri; fare etkisi rengi tekrar okusun diye yuz degismiyor
		buton.BackgroundColor3 = if sahip then Color3.fromRGB(80, 82, 88) else UI.shade(YESIL, -0.3)
		yuz.BackgroundColor3 = if sahip then Color3.fromRGB(140, 145, 155) else YESIL
		local gecis = yuz:FindFirstChildOfClass("UIGradient")
		if gecis then
			gecis.Enabled = not sahip
		end
	end
	ciz()
	table.insert(gecisCizimleri, ciz)

	player:GetAttributeChangedSignal(info.nitelik):Connect(ciz)

	buton.MouseButton1Click:Connect(function()
		if Passler.sahip(player, ad) then
			return
		end
		ArayuzSesi.tikla()
		PassSatinAl:FireServer(ad)
	end)
end

------------------------------------------------------------------
-- KURULUM
------------------------------------------------------------------
bolumBasligi("Items")
for _, kart in RobuxMagaza.Kartlar do
	--[[
		HER KART KENDI BASINA CIZILIYOR.

		Bir kart cizilemezse eskiden butun script o satirda duruyordu: magaza
		yarim kaliyor ve ASAGIDA kurulan STORE BUTONU hic gelmiyordu -- yani
		tek bir kartin derdi magazayi tumden yok ediyordu. Bir kez oldu da:
		UI modulundeki bir fonksiyonun adi yanlis yazilmisti.

		Artik hata o kartta kalir, sebebi Output'a dusurulur, gerisi kurulur.
	]]
	local ok, hata = pcall(urunKarti, kart)
	if not ok then
		warn(`[RobuxMagaza] "{kart.id}" karti cizilemedi: {hata}`)
	end
end

bolumBasligi("Game Passes")
do
	local izgaraKutu = Instance.new("Frame")
	izgaraKutu.Name = "Gecisler"
	izgaraKutu.BackgroundTransparency = 1
	izgaraKutu.Size = UDim2.new(1, 0, 0, 0)
	izgaraKutu.AutomaticSize = Enum.AutomaticSize.Y
	izgaraKutu.LayoutOrder = sonraki()
	izgaraKutu.Parent = liste

	local izgara = Instance.new("UIGridLayout")
	izgara.CellSize = UDim2.new(0.5, -8, 0, 150)
	izgara.CellPadding = UDim2.fromOffset(16, 16)
	izgara.SortOrder = Enum.SortOrder.LayoutOrder
	izgara.Parent = izgaraKutu

	for siraNo, ad in RobuxMagaza.Gecisler do
		gecisKarti(izgaraKutu, ad, siraNo)
	end
end

------------------------------------------------------------------
-- STORE BUTONU  --  sol menunun USTUNDE
--
-- Sol menu (Menuler > SolMenu) 2 sutunlu ikon izgarasi. STORE butonu
-- onun hemen ustunde durur: yatayda 2 ikon (izgaranin tam genisligi),
-- dikeyde 1 ikon boyunda. Solda paketteki Store ikonu, yaninda yazi.
--
-- Izgaranin yeri sabit degil (Rot gostergesi, arkadas/iksir yazilari ve
-- arayuz olcegiyle kayiyor); buton her degisimde onun ust kenarina
-- yeniden oturtuluyor. Iki ekran da ust cubugu yok saymiyor
-- (IgnoreGuiInset kapali), yani ayni koordinat duzlemindeler.
------------------------------------------------------------------
-- Menuler ile ayni olculer: ikon 52, alttaki kabartma 5, aradaki bosluk 14
local MENU_IKON = 52
local MENU_BOSLUK = 14

--[[
	Dis cerceve (tutucu) UI modulunun arayuz olcegini alir; fare etkisinin
	buyumesi ise icteki butonda. Ikisi ayni nesnede olsaydi UI modulu
	olcegi koymuyordu (bir nesnede iki UIScale olmaz).

	AnchorPoint sol-alt: olcek buyurken buton yukari dogru buyur, izgarayla
	ayni sol kenarda kalir.
]]
local tutucu = Instance.new("Frame")
tutucu.Name = "StoreButonu"
tutucu.AnchorPoint = Vector2.new(0, 1)
tutucu.Position = UDim2.new(0, 16, 0.5, 0)
tutucu.Size = UDim2.fromOffset(MENU_IKON * 2 + MENU_BOSLUK, MENU_IKON + LIP)
tutucu.BackgroundTransparency = 1
tutucu.Parent = screen

local storeButon, storeYuz = satinAlmaDugmesi(tutucu, ALTIN, true)
storeButon.Name = "Store"
storeButon.AnchorPoint = Vector2.new(0.5, 0.5)
storeButon.Position = UDim2.fromScale(0.5, 0.5)
storeButon.Size = UDim2.fromScale(1, 1)

local storeIkon = Instance.new("ImageLabel")
storeIkon.Name = "Ikon"
storeIkon.BackgroundTransparency = 1
storeIkon.AnchorPoint = Vector2.new(0, 0.5)
storeIkon.Position = UDim2.new(0, 2, 0.5, 0)
storeIkon.Size = UDim2.fromOffset(40, 40)
storeIkon.ScaleType = Enum.ScaleType.Fit
storeIkon.ZIndex = 5
storeIkon.Parent = storeYuz
--[[
	Yazi butonun TAM ORTASINDA baslar. Store ikonu bulunursa solda ikona
	yer acilir ve yazi kalan alanda ortalanir; ikon yoksa (paket gelmediyse)
	solda bos yer kalip yazi saga yaslanmis gorunmesin.
]]
local storeYazi = UI.text({
	text = "STORE",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = storeYuz,
	zIndex = 5,
})

storeIkon.Visible = false
Icons.bind(storeIkon, "store", function(ok)
	if ok then
		storeIkon.Visible = true
		storeYazi.Size = UDim2.new(1, -42, 1, 0)
		storeYazi.Position = UDim2.fromOffset(40, 0)
	end
end)

-- Sol menunun ust kenarina oturt
task.spawn(function()
	local menuler = playerGui:WaitForChild("OyunMenuleri")
	local sol = menuler:WaitForChild("SolMenu") :: GuiObject

	local function yerlestir()
		local carpan = UI.getScale() / 100 * UI.ScaleBase
		tutucu.Position = UDim2.fromOffset(
			sol.AbsolutePosition.X,
			sol.AbsolutePosition.Y - MENU_BOSLUK * carpan
		)
	end

	yerlestir()
	sol:GetPropertyChangedSignal("AbsolutePosition"):Connect(yerlestir)
	sol:GetPropertyChangedSignal("AbsoluteSize"):Connect(yerlestir)
	UI.onScaleChanged(yerlestir)
end)

storeButon.MouseButton1Click:Connect(function()
	ArayuzSesi.tikla()
	panel.Visible = not panel.Visible
end)

-- Ikon ara ara sallanir: buton goze carpsin
task.spawn(function()
	local bilgi = TweenInfo.new(0.09, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	while storeIkon.Parent do
		task.wait(4)
		for _, aci in { -14, 12, -8, 5, 0 } do
			local t = TweenService:Create(storeIkon, bilgi, { Rotation = aci })
			t:Play()
			t.Completed:Wait()
		end
	end
end)

-- Panel her acilista gecis dugmeleri guncel olsun (nitelik gec gelebiliyor)
panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then
		for _, ciz in gecisCizimleri do
			ciz()
		end
	end
end)
