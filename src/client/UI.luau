--!strict
--[[
	Ortak arayuz yardimcilari.

	METIN NETLIGI
	Eski arayuzdeki yazilar TextScaled kullaniyordu. TextScaled her karede
	yaziyi kesirli bir piksel boyutuna olceklediginden Roblox yaziyi tam
	piksel izgarasina oturtamiyor ve kenarlar bulaniklasiyor. Ustune kalin
	TextStroke binince ("kazi yapilamadi" gibi bildirimlerde) bulaniklik
	daha da belirginlesiyordu.

	Bu modul butun metinleri tek yerden uretir ve su kurallari uygular:
	  - TextScaled kapali, SABIT ve CIFT sayili TextSize
	  - TextStroke yok; onun yerine UIStroke -- cok daha keskin kenar
	  - Font ve kontur Shared > Fonts'tan gelir (FredokaOne + siyah kontur)
	  - Metin cerceveleri tam piksel konumlarina hizalanir

	Yazi boyutunu her yerde birden degistirmek icin SIZES tablosunu kullan.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Yazi kimligi (font + kontur) tek yerden gelir
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Fonts = require(Shared:WaitForChild("Fonts"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Divine = require(Shared:WaitForChild("Divine"))

local UI = {}

--[[
	Arayuz olceginin UIScale nesnesinin adi.

	Asagidaki olcek bolumu bunu her ust duzey arayuz nesnesine koyuyor.
	Panel acilis/kapanis animasyonu da AYNI nesneyi oynatiyor: Roblox ayni
	nesnedeki iki UIScale.den hangisini uygulayacagini garanti etmiyor, bu
	yuzden animasyon icin ikinci bir olcek eklenmiyor.
]]
local OLCEK_ADI = "AyarOlcek"

-- Merkezi yazi boyutlari (hepsi cift sayi -- yarim piksel kaymayi onler)
UI.Sizes = {
	tiny = 14,
	small = 16,
	body = 18,
	label = 20,
	heading = 24,
	title = 30,
	huge = 40,
}

-- Renk paleti
UI.Colors = {
	panel = Color3.fromRGB(24, 28, 38),
	panelLight = Color3.fromRGB(36, 42, 56),
	text = Color3.fromRGB(238, 242, 248),
	textDim = Color3.fromRGB(168, 178, 194),
	accent = Color3.fromRGB(90, 180, 255),
	good = Color3.fromRGB(120, 226, 150),
	warn = Color3.fromRGB(255, 190, 70),
	bad = Color3.fromRGB(255, 110, 110),
	gold = Color3.fromRGB(255, 214, 41),
}

local BOLD = Fonts.bold
local MEDIUM = Fonts.medium
local REGULAR = Fonts.regular

UI.Fonts = {
	bold = BOLD,
	medium = MEDIUM,
	regular = REGULAR,
}

export type TextOptions = {
	text: string?,
	size: number?,
	color: Color3?,
	font: Font?,
	align: Enum.TextXAlignment?,
	alignY: Enum.TextYAlignment?,
	position: UDim2?,
	anchor: Vector2?,
	frameSize: UDim2?,
	parent: Instance?,
	name: string?,
	-- Kontur varsayilan olarak ACIK (oyunun cizgi film gorunumu).
	-- Yalnizca kapatmak icin false ver.
	outline: boolean?,
	wrapped: boolean?,
	zIndex: number?,
	--[[
		Parilti rengi. Verilirse yaziya icinden isik geliyormus gibi bir
		gradyan konur (Epic ve ustu kademe isimleri icin). Verildiginde
		color yok sayilir -- rengi gradyan tasir.
	]]
	glow: Color3?,
}

--[[
	Net bir TextLabel uretir.
	TextScaled bilerek kullanilmaz; boyut SIZES tablosundan gelir.
]]
function UI.text(options: TextOptions): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = options.name or "Text"
	label.BackgroundTransparency = 1
	label.Size = options.frameSize or UDim2.new(1, 0, 0, (options.size or UI.Sizes.body) + 6)
	label.Position = options.position or UDim2.new()
	label.AnchorPoint = options.anchor or Vector2.zero

	label.FontFace = options.font or MEDIUM
	label.Text = options.text or ""
	label.TextColor3 = options.color or UI.Colors.text
	label.TextSize = options.size or UI.Sizes.body

	-- Bulanikligin ana kaynagi: kapali kalmali
	label.TextScaled = false
	label.RichText = false
	label.TextWrapped = options.wrapped == true
	label.TextTruncate = if options.wrapped then Enum.TextTruncate.None else Enum.TextTruncate.AtEnd

	label.TextXAlignment = options.align or Enum.TextXAlignment.Left
	label.TextYAlignment = options.alignY or Enum.TextYAlignment.Center

	-- Eski TextStroke yerine ince kontur: kenarlar keskin kalir
	label.TextStrokeTransparency = 1

	if options.zIndex then
		label.ZIndex = options.zIndex
	end

	-- Siyah kontur oyunun imzasi: aksi soylenmedikce her yaziya uygulanir
	if options.outline ~= false then
		Fonts.applyOutline(label)
	end

	-- Parilti konturdan SONRA: TextColor3'u beyaza cekiyor, sirasi onemli
	if options.glow then
		Fonts.applyGlow(label, options.glow)
	end

	if options.parent then
		label.Parent = options.parent
	end

	return label
end

--[[
	Bir yaziyi KADEMESININ gorunumune sokar.

	    Divine  -> rengi canli: sari <-> beyaz parildar (Shared > Divine)
	    Epic+   -> parilti gradyani; mavinin ustu daha degerli gorunsun
	    digeri  -> duz kademe rengi

	Isim yazilari icin. Cagirdiktan sonra TextColor3'u elle degistirme --
	parilti gradyani da parildama da onun uzerinden calisiyor.

	AYNI ETIKETTE TEKRAR CAGRILABILIR: ruletlerin sonuc yazisi her cevirimde
	baska bir kademeye ait olur. Bu yuzden her cagride onceki kademenin izi
	(parilti gradyani, parildama etiketi) once temizlenir -- yoksa bir kez
	Divine cikan yazi sonsuza dek parildamaya devam ederdi.
]]
--[[
	KADEME RENGI  --  DUZ

	Arayuzdeki isimler ve kademe yazilari kademenin KENDI renginde, tek
	renk. Eskiden Epic ve ustune parlak gradyan, ust kademelere de renk
	degistiren parildama takiliyordu; isimler rengarenk gorunuyordu.
	(Dunyadaki etiketin kademe satiri parlamaya devam ediyor, bkz. Etiket.)
]]
function UI.rarityStyle(label: TextLabel, rarityId: string): TextLabel
	-- textColor: cok koyu kademeler (Secret) yazida beyaza doner, okunsun
	local color = Rarity.textColor(rarityId)

	Divine.untag(label)
	Fonts.clearGlow(label, color)

	return label
end

--[[
	Kademe gorunumunu kaldirir: duz renk, parilti yok, parildama yok.
	Ruletlerin "..." bekleme yazisi gibi kademesiz durumlar icin.
]]
function UI.plainStyle(label: TextLabel, color: Color3): TextLabel
	Divine.untag(label)
	Fonts.clearGlow(label, color)
	return label
end

function UI.corner(parent: Instance, radius: number?): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

function UI.stroke(parent: Instance, color: Color3?, thickness: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color or UI.Colors.accent
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

function UI.padding(parent: Instance, amount: number): UIPadding
	local p = Instance.new("UIPadding")
	local offset = UDim.new(0, amount)
	p.PaddingTop = offset
	p.PaddingBottom = offset
	p.PaddingLeft = offset
	p.PaddingRight = offset
	p.Parent = parent
	return p
end

--[[
	=====================================================================
	PANEL KATMANI  --  acilan pencere HER ZAMAN ustte
	=====================================================================

	Paneller eskiden onlari acan scriptin kendi ScreenGui'sinde duruyordu ve
	iki ayri sebepten butonlarin ALTINDA kaliyorlardi:

	  1. Cogu ScreenGui'nin DisplayOrder'i 0. Roblox esit DisplayOrder'li
	     ekranlarin sirasini garanti etmez, yani NPC penceresi HUD'un altina
	     dusebiliyordu.
	  2. Menuler'de menu butonlari ile paneller AYNI ScreenGui'de. Orada sira
	     ZIndex'e kaliyor ve ZIndexBehavior.Sibling'de hiyerarsi sayilmaz:
	     menu butonunun ikonu (ZIndex 5) panel zemininin (ZIndex 1) onune
	     geciyordu.

	Cozum: panel hangi ekrana verilirse verilsin TEK ve YUKSEK DisplayOrder'li
	ortak bir ScreenGui'ye konur. Yuksek DisplayOrder'li bir ekranin ICINDEKI
	her sey, dusuk olanin her seyinin ustunde cizilir -- ZIndex'e hic
	bakilmadan. Boylece panel her zaman ustte kalir, panelin KENDI icindeki
	ZIndex duzeni de bozulmaz (hepsi ayni ekranda kaldigi icin).

	KATMAN SIRASI (ScreenGui.DisplayOrder)

	    0    HUD            XP bari, maden sayaci, kazi bari, ada menusu
	    5    menu butonlari sol/sag menu cubuklari
	   19    panel fonu     panelin arkasina serilen tam ekran perdeler
	   20    PANELLER       butun UI.panel pencereleri
	   50    mutasyon gosterisi
	  100    hata ekrani

	Yeni bir tam ekran ekran eklerken sirayi buraya isle.
]]
UI.FonKatmani = 19
UI.PanelKatmani = 20

-- Ortak bir katman ekranini bulur, yoksa kurar
local function katmanKur(ad: string, sira: number): ScreenGui?
	local player = Players.LocalPlayer
	if not player then
		return nil
	end

	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return nil
	end

	local mevcut = playerGui:FindFirstChild(ad)
	if mevcut and mevcut:IsA("ScreenGui") then
		return mevcut
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = ad
	gui.DisplayOrder = sira
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	return gui
end

local panelKatmani: ScreenGui? = nil
local fonKatmani: ScreenGui? = nil

--[[
	Butun panellerin durdugu ortak ekran. Ilk panel kurulurken olusur.
	PlayerGui henuz yoksa nil doner; o durumda UI.panel cagiranin verdigi
	ekranda birakir, yani eski davranisa duser.
]]
function UI.panelEkrani(): ScreenGui?
	if panelKatmani and panelKatmani.Parent then
		return panelKatmani
	end
	panelKatmani = katmanKur("PanelKatmani", UI.PanelKatmani)
	return panelKatmani
end

--[[
	Panelin ARKASINA serilen tam ekran perdeler icin ekran (Lucky Block'un
	karartmasi ve isik huzmeleri gibi). Panelin hemen altinda, butonlarin
	ustunde durur -- perde acilinca arkadaki butonlar da kararir.
]]
function UI.fonEkrani(): ScreenGui?
	if fonKatmani and fonKatmani.Parent then
		return fonKatmani
	end
	fonKatmani = katmanKur("PanelFonKatmani", UI.FonKatmani)
	return fonKatmani
end

--[[
	TEK PANEL KURALI

	Butun paneller ekranin TAM ORTASINDA duruyor; ikisi ayni anda acik olursa
	ust uste biniyorlar. Bu yuzden bir panel gorunur olur olmaz digerleri
	kapanir.

	Kural panelin nasil acildigina degil, Visible ozelliginin KENDISINE bagli:
	menu butonu, sunucudan gelen olay, klavye kisayolu -- hepsi ayni sekilde
	calisir, acan tarafin bir sey yapmasi gerekmez.

	Liste bu ModuleScript'te durdugu ve istemcide tek kopya oldugu icin kural
	scriptler ARASINDA da gecerli: Fuse makinesinin penceresi acilinca Menuler'in
	envanteri de kapanir.
]]
local paneller: { Frame } = {}

-- Digerlerini kapatmak yeni bir kapatma turu baslatmasin
local kapatmaSuruyor = false

local function digerPanelleriKapat(acilan: Frame)
	if kapatmaSuruyor then
		return
	end
	kapatmaSuruyor = true

	for _, panel in paneller do
		if panel ~= acilan and panel.Parent and panel.Visible then
			panel.Visible = false
		end
	end

	kapatmaSuruyor = false
end

--[[
	=====================================================================
	PANEL ACILIS / KAPANIS
	=====================================================================

	Paneller "pat" diye belirip kaybolmasin diye kisa bir olcek animasyonu
	var: acilirken kucukten gelip hafifce tasarak yerine oturur (Back),
	kapanirken kuculup soner.

	ACILIS panelin KENDI olceginde oynatiliyor. Kapanis boyle yapilamiyor:
	kapatan kod Visible = false yaziyor ve panel o anda ekrandan siliniyor,
	animasyona vakit kalmiyor. Paneli gecici olarak geri acmak ise "acik mi"
	bilgisini bozar -- panel kapanirken Visible hala true okunur ve o sirada
	gelen bir acma istegi sinyal uretmedigi icin kaybolur.

	Bu yuzden KAPANIS BIR HAYALET UZERINDE oynatiliyor: panelin gorunum
	kopyasi bir CanvasGroup icine konur, gercek panel ayni anda kapanir,
	kopya kuculerek solar ve silinir. Boylece kapanis animasyonu panelin
	durumuna hic dokunmuyor.

	CanvasGroup kullanilmasinin sebebi: GroupTransparency tek hamlede butun
	kopyayi soldurur, yoksa her yazinin/cercevenin seffafligini tek tek
	oynatmak gerekirdi.
]]
local ACILIS_SURE = 0.18
local KAPANIS_SURE = 0.13
-- Panel bu orandan buyuyerek gelir, kapanirken bu orana kuculur
local ACILIS_ORANI = 0.85
local KAPANIS_ORANI = 0.9

-- Ayarlardaki arayuz olceginin o anki gercek degeri
local function suankiOlcek(): number
	return UI.getScale() / 100 * UI.ScaleBase
end

--[[
	Panelin olcek nesnesi. Olcek bolumu bunu zaten ekliyor ama ChildAdded
	sinyali gecikmeli calistigi icin panel yeni kurulduysa henuz olmayabilir;
	o durumda ayni adla burada olusturuluyor (sonra olcek bolumu bunu bulup
	gunceller, ikinci bir UIScale eklemez).
]]
local function panelOlcegi(frame: Frame): UIScale
	local mevcut = frame:FindFirstChild(OLCEK_ADI)
	if mevcut and mevcut:IsA("UIScale") then
		return mevcut
	end

	local olcek = Instance.new("UIScale")
	olcek.Name = OLCEK_ADI
	olcek.Scale = suankiOlcek()
	olcek.Parent = frame
	return olcek
end

local function acilisOynat(frame: Frame)
	local olcek = panelOlcegi(frame)
	local hedef = suankiOlcek()

	olcek.Scale = hedef * ACILIS_ORANI
	TweenService:Create(
		olcek,
		TweenInfo.new(ACILIS_SURE, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = hedef }
	):Play()
end

local function kapanisOynat(frame: Frame)
	local parent = frame.Parent
	if not parent then
		return
	end

	local olcek = suankiOlcek()

	local kutu = Instance.new("CanvasGroup")
	kutu.Name = `{frame.Name}Kapanis`
	kutu.AnchorPoint = frame.AnchorPoint
	kutu.Position = frame.Position
	kutu.Size = frame.Size
	kutu.BackgroundTransparency = 1
	kutu.BorderSizePixel = 0
	kutu.ZIndex = frame.ZIndex
	kutu.Parent = parent

	-- Olcek hemen konuyor: ChildAdded gecikmeli, yoksa kopya bir kare
	-- yanlis boyutta gorunurdu
	local kutuOlcek = Instance.new("UIScale")
	kutuOlcek.Name = OLCEK_ADI
	kutuOlcek.Scale = olcek
	kutuOlcek.Parent = kutu

	local hayalet = frame:Clone()
	hayalet.Visible = true
	hayalet.AnchorPoint = Vector2.new(0.5, 0.5)
	hayalet.Position = UDim2.fromScale(0.5, 0.5)
	-- Kopyanin kendi olcegi kutununkiyle carpilmasin
	local kopyaOlcek = hayalet:FindFirstChild(OLCEK_ADI)
	if kopyaOlcek then
		kopyaOlcek:Destroy()
	end
	hayalet.Parent = kutu

	local sure = TweenInfo.new(KAPANIS_SURE, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(kutuOlcek, sure, { Scale = olcek * KAPANIS_ORANI }):Play()

	local sonme = TweenService:Create(kutu, sure, { GroupTransparency = 1 })
	sonme.Completed:Connect(function()
		kutu:Destroy()
	end)
	sonme:Play()
end

-- Standart panel: koyu zemin, yuvarlak kose, ince kontur
function UI.panel(parent: Instance, size: UDim2, name: string?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name or "Panel"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = size
	frame.BackgroundColor3 = UI.Colors.panel
	frame.BorderSizePixel = 0
	frame.Visible = false
	--[[
		Panel dogrudan bir ekrana veriliyorsa ortak PANEL KATMANINA alinir --
		cagiran tarafin bir sey yapmasi gerekmez, pencere kendiliginden en
		uste cikar. Baska bir cercevenin icine konuyorsa oraya birakilir.
	]]
	if parent:IsA("ScreenGui") then
		frame.Parent = UI.panelEkrani() or parent
	else
		frame.Parent = parent
	end
	UI.corner(frame, 14)
	UI.stroke(frame, UI.Colors.accent, 1)

	--[[
		Tek panel kurali + acilis/kapanis animasyonu.

		Ikisi de Visible ozelliginin KENDISINE bagli, acan tarafin bir sey
		yapmasi gerekmiyor: menu butonu, sunucudan gelen olay, kisayol --
		hepsi ayni sekilde calisir.
	]]
	table.insert(paneller, frame)
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if frame.Visible then
			digerPanelleriKapat(frame)
			acilisOynat(frame)
		else
			kapanisOynat(frame)
		end
	end)

	return frame
end

function UI.button(parent: Instance, text: string, size: UDim2, color: Color3?): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.BackgroundColor3 = color or UI.Colors.panelLight
	button.BorderSizePixel = 0
	-- Renk gecisi UI.hover.da; Roblox.un kendi karartmasi onunla cakisir
	button.AutoButtonColor = false
	button.Text = ""
	button.Parent = parent
	UI.corner(button, 10)

	UI.text({
		text = text,
		size = UI.Sizes.body,
		font = BOLD,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = button,
		name = "Label",
	})

	-- Tiklanabilir: uzerine gelince aydinlanir
	UI.hover(button)

	return button
end

-- Kapatma butonu (sag ust kose)
function UI.closeButton(parent: Instance): TextButton
	local button = Instance.new("TextButton")
	button.Name = "Kapat"
	button.Size = UDim2.fromOffset(34, 34)
	-- Sag kenardan tutuluyor: fare etkisiyle buyurken panelin disina tasmaz
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -10, 0, 12)
	button.BackgroundColor3 = Color3.fromRGB(188, 58, 68)
	button.BorderSizePixel = 0
	button.Text = ""
	button.Parent = parent
	UI.corner(button, 8)

	UI.text({
		text = "X",
		size = UI.Sizes.label,
		font = BOLD,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = button,
	})

	-- Kendi merkezinden buyuyebilir: sag ust koseye sabit
	UI.hover(button, nil, button)

	-- Panelde renkli baslik cubugu varsa dugme onun sag ucuna oturur
	if parent:GetAttribute("RenkliBaslik") then
		button.Position = UDim2.new(1, -18, 0, 18)
		button.ZIndex = 6
		UI.stroke(button, Color3.fromRGB(0, 0, 0), 2)
	end

	return button
end

--[[
	=====================================================================
	FARE ETKISI  --  yalnizca TIKLANABILIR seyler icin
	=====================================================================

	Uzerine gelince nesne yumusakca aydinlanir, istenirse hafifce buyur;
	basilinca kucuk bir geri tepme yapar. Boylece "buraya tiklanir"
	bilgisi durgun bir renkten degil HAREKETTEN geliyor.

	NEREYE KONUR
	Yalnizca gercekten tiklanan nesnelere. Kilitli menu butonlari, satis
	yapilamayan magaza satirlari gibi olu nesnelere KONMAZ -- yoksa
	arayuz calismayan bir seyi calisiyormus gibi gosterir.

	AutoButtonColor ile birlikte KULLANILMAZ: Roblox'un kendi karartmasi
	bu tweenle ayni ozelligi (BackgroundColor3) cekistirir ve renk
	titrer. Bu yuzden UI.hover cagrilan yerde AutoButtonColor kapatilir.

	PARAMETRELER
	    button  -- tiklama sinyallerini veren buton
	    face    -- rengi degisecek katman (yoksa butonun kendisi)
	    pop     -- olceklenecek katman (yoksa buyume yok)

	OLCEKLEME NEDEN OPSIYONEL
	UIScale nesneyi AnchorPoint'inden buyutur. Liste ve izgara icindeki
	satirlar (0,0) ile duruyor; buyudukleri anda saga/asagi tasip
	komsularinin ustune binerler. Bu yuzden buyume yalnizca merkezinden
	olceklenebilen nesnelere veriliyor, satirlarda sadece renk degisiyor.
]]

UI.HoverTime = 0.12
-- Renk ne kadar aydinlansin (UI.shade ile ayni olcek)
UI.HoverLift = 0.12
UI.HoverPop = 1.06
UI.PressPop = 0.96

function UI.hover(button: GuiButton, face: GuiObject?, pop: GuiObject?)
	local renkli: GuiObject = face or button

	--[[
		Temel renk ILK temasta okunuyor, kurulumda degil: cagiran taraf
		bazen rengi bu satirdan sonra veriyor (magaza satirlari gibi).
	]]
	local temelRenk: Color3? = nil

	local olcek: UIScale? = nil
	if pop then
		olcek = Instance.new("UIScale")
		olcek.Name = "FareOlcegi"
		olcek.Scale = 1
		olcek.Parent = pop
	end

	local function oynat(aydinlik: boolean, buyume: number)
		if not temelRenk then
			temelRenk = renkli.BackgroundColor3
		end

		local hedefRenk = if aydinlik
			then UI.shade(temelRenk :: Color3, UI.HoverLift)
			else temelRenk :: Color3

		TweenService:Create(
			renkli,
			TweenInfo.new(UI.HoverTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundColor3 = hedefRenk }
		):Play()

		if olcek then
			TweenService:Create(
				olcek,
				TweenInfo.new(UI.HoverTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = buyume }
			):Play()
		end
	end

	button.MouseEnter:Connect(function()
		oynat(true, UI.HoverPop)
	end)

	button.MouseLeave:Connect(function()
		oynat(false, 1)
	end)

	button.MouseButton1Down:Connect(function()
		oynat(true, UI.PressPop)
	end)

	button.MouseButton1Up:Connect(function()
		oynat(true, UI.HoverPop)
	end)
end

--[[
	=====================================================================
	CILALI YUZEY  --  cizgi film arayuz dokusu
	=====================================================================

	Populer simulator arayuzlerindeki buton yuzeyi uc seyden olusur:
	  1. Dikey gradyan   -- ustu parlak, alti koyu
	  2. Elmas izgara    -- ince capraz desen, yuzeye doku katar
	  3. Ust parlaklik   -- ustteki yarida cam yansimasi hissi

	TEKNIK NOT
	Desen dondurulmus Frame'lerle YAPILMAZ: Roblox'ta ClipsDescendants
	dondurulmus cocuklari kirpmiyor, desen kutunun disina tasiyor. Bunun
	yerine UIGradient'in SAYDAMLIK dizisi kullaniliyor -- gradyan her zaman
	kendi cercevesinin icinde kalir.
]]

-- Bir rengi aydinlatir (amount > 0) ya da karartir (amount < 0)
function UI.shade(color: Color3, amount: number): Color3
	local h, sat, v = color:ToHSV()
	return Color3.fromHSV(h, math.clamp(sat - amount * 0.1, 0, 1), math.clamp(v + amount, 0, 1))
end

--[[
	Tek yonlu serit katmani.
	rotation: seritlerin acisi, count: kac serit, alpha: koyuluk (0..1)
]]
--[[
	SERIT KATMANI  --  zeminin uzerinden gecen egik isik seritleri

	SERITLER AYRI BIRER CERCEVE, GRADYAN DEGIL.

	Eskiden tek bir UIGradient'in Transparency duraklariyla ciziliyorlardi.
	Roblox dondurulmus bir gradyani nesnenin KUTUSUNA sigdiriyor: gradyan
	ekseni nesnenin genisligi kadar uzun kaliyor ama 32 derece egik duruyor,
	yani yatayda ancak genisligin cos(32) kadarini kapsiyor. Kare kutularda
	fark edilmiyordu; uzun bir barda (XP bari, Store baslik cubugu) seritler
	ortada topaklanip iki uc bos kaliyordu.

	Artik her serit kendi cercevesi: konumu ORAN olarak veriliyor, yani kutu
	ne kadar uzarsa seritler de o kadar yayiliyor. Egiklik Frame.Rotation ile.

	KATMAN BIR CANVASGROUP, DUZ FRAME DEGIL.
	Roblox'ta ClipsDescendants DONDURULMUS cocuklari kirpmaz; duz bir Frame
	kullaninca seritler pencerenin disina, oyun ekranina tasiyordu.
	CanvasGroup cocuklarini once kendi yuzeyine cizdigi icin rotasyonlu
	olanlar da o yuzeyin disina cikamiyor. Boyu da (asagida) kutuya ancak
	yetecek kadar: kirpma bir sekilde devre disi kalsa bile tasma gozukmesin.

	ZINDEX PARENT'INKIYLE AYNI. Eskiden sabit 2 idi ve ZIndexBehavior.Sibling'de
	hiyerarsi sayilmadigi icin PANELIN deseni, panelin uzerindeki BUTONLARIN
	(ZIndex 1) onune geciyordu. Ayni ZIndex'te sira ekleme sirasina kaliyor ve
	desen her zaman once eklendigi icin artik butonlarin altinda kaliyor.
]]
function UI.stripeLayer(parent: GuiObject, tint: Color3, rotation: number, count: number, alpha: number): CanvasGroup
	local layer = Instance.new("CanvasGroup")
	layer.Name = "Desen"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	layer.BorderSizePixel = 0
	layer.ClipsDescendants = true
	layer.ZIndex = parent.ZIndex
	layer.Parent = parent

	--[[
		SERIT ENLERI AYNI DEGIL: kalin ve ince sirayla geliyor. Hepsi esit
		olunca desen tarama cizgisi gibi duruyordu. Deger kutu genisliginin
		orani, yani her boyutta ayni dengede gorunur.
	]]
	local ENLER = { 0.075, 0.025, 0.05, 0.02, 0.04 }

	--[[
		Egik duran seridin kutuyu bastan basa kesmesi icin boyu kutunun
		yuksekliginden UZUN olmali: cos(32) kadar kisaliyor, 1.25 kat yetiyor
		ve artani da neredeyse hic tasmiyor.
	]]
	local BOY = 1 / math.cos(math.rad(rotation)) + 0.07

	local step = 1 / count

	for i = 0, count - 1 do
		local serit = Instance.new("Frame")
		serit.Name = "Serit"
		serit.AnchorPoint = Vector2.new(0.5, 0.5)
		-- Her serit kendi diliminin ORTASINDA: iki uca da esit pay kalir
		serit.Position = UDim2.fromScale((i + 0.5) * step, 0.5)
		serit.Size = UDim2.new(ENLER[(i % #ENLER) + 1], 0, BOY, 0)
		serit.Rotation = rotation
		serit.BackgroundColor3 = tint
		serit.BackgroundTransparency = alpha
		serit.BorderSizePixel = 0
		serit.ZIndex = parent.ZIndex
		serit.Parent = layer
	end

	return layer
end

--[[
	ELMAS IZGARA
	Iki serit katmani zit acilarla ust uste binince capraz kafes olusur --
	referans butonlardaki doku tam olarak budur.
]]
--[[
	CAPRAZ DESEN  --  zeminin uzerinden gecen egik isik seritleri

	TEK YONLU. Eskiden iki katman vardi (+32 ve -32 derece) ve kesistikleri
	yerde elmas izgara cikiyordu; her pencerede ayni sik desen goze batiyordu.
	Simdi tek yon, daha az serit ve daha soluk: zemine doku katar, dikkat
	cekmez. Enler kalin-ince karisik, bkz. UI.stripeLayer.
]]
function UI.caprazDesen(parent: GuiObject, tint: Color3?, count: number?)
	UI.stripeLayer(parent, tint or Color3.fromRGB(255, 255, 255), 32, count or 5, 0.88)
end

--[[
	UST PARLAKLIK
	Ustteki yariyi beyaza dogru acar; cam/plastik yansimasi hissi verir.
]]
function UI.gloss(parent: GuiObject, strength: number?): Frame
	local layer = Instance.new("Frame")
	layer.Name = "Parlaklik"
	layer.Size = UDim2.new(1, 0, 0.5, 0)
	layer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	layer.BorderSizePixel = 0
	-- Parlaklik da parent ile ayni katmanda; bkz. UI.stripeLayer
	layer.ZIndex = parent.ZIndex
	layer.Parent = parent

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, strength or 0.72),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = layer

	return layer
end

--[[
	Bir yuzeyi tek adimda cilalar: dikey gradyan + elmas izgara + parlaklik.
	Kose yuvarlatmayi ve konturu cagiran taraf yapar.
]]
function UI.polish(face: GuiObject, color: Color3, radius: number?)
	face.BackgroundColor3 = color

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UI.shade(color, 0.22)),
		ColorSequenceKeypoint.new(0.55, color),
		ColorSequenceKeypoint.new(1, UI.shade(color, -0.14)),
	})
	gradient.Parent = face

	UI.caprazDesen(face)
	UI.gloss(face)

	if radius then
		-- Desen ve parlaklik katmanlarinin koseleri de yuvarlansin
		for _, child in face:GetChildren() do
			-- Desen bir CanvasGroup, Parlaklik duz Frame: ikisi de GuiObject
			if child:IsA("GuiObject") and (child.Name == "Desen" or child.Name == "Parlaklik") then
				UI.corner(child, radius)
			end
		end
	end
end

--[[
	=====================================================================
	ARAYUZ OLCEGI  --  Settings > Interface Scale
	=====================================================================

	Oyuncu butun arayuzu yuzde olarak buyutup kucultebiliyor (%50..%150).
	Olcek, her ScreenGui'nin UST DUZEY cocuklarina konan birer UIScale ile
	uygulaniyor.

	NEDEN DOGRUDAN ScreenGui'YE DEGIL
	UIScale yalnizca bir GuiObject'in altinda calisir; ScreenGui GuiObject
	degildir (LayerCollector'dur). Bu yuzden olcek ScreenGui'nin altindaki
	Frame / TextLabel gibi nesnelerin HER BIRINE ayri ayri konuyor.

	Paneller ve HUD kutulari calisma aninda da eklenebiliyor (bildirim
	satirlari, sonradan kurulan paneller). Bu yuzden her ScreenGui'nin
	ChildAdded sinyali dinleniyor: sonradan gelen nesne de ayni olcegi alir.

	Bu blok modul ilk require edildiginde bir kere calisir; hangi client
	scriptinin once yuklendigi fark etmez.
]]

-- (OLCEK_ADI dosyanin basinda: panel animasyonlari da ayni olcegi kullaniyor)

UI.ScaleMin = 50
UI.ScaleMax = 150
UI.ScaleStep = 5
UI.ScaleDefault = 100

--[[
	TABAN OLCEK

	Arayuz eskiden bir tik kucuk duruyordu. Panelin her yerini elle
	buyutmek yerine %100 secildiginde uygulanan GERCEK olcek burada
	tutuluyor: 1.25 = eski boyutun %125'i.

	Yani oyuncu ayarda "100%" gorur, ekranda eski %125 boyutu durur;
	%50 ile %150 sinirlari da bu tabana gore calisir.
]]
UI.ScaleBase = 1.25

-- Yuzdeden gercek UIScale degerine
local function gercekOlcek(yuzde: number): number
	return yuzde / 100 * UI.ScaleBase
end

local olcekYuzde = UI.ScaleDefault
local izlenenGui: { [Instance]: boolean } = {}
local olcekDinleyicileri: { (yuzde: number) -> () } = {}

-- Tek bir arayuz nesnesine olcegi koyar (varsa gunceller)
local function nesneyeUygula(nesne: Instance)
	if not nesne:IsA("GuiObject") then
		return
	end

	--[[
		Nesnede BASKA bir UIScale varsa (fare etkisinin "FareOlcegi"i gibi)
		ikinci bir tane eklenmez: Roblox ayni nesnedeki iki UIScale.den
		hangisini uygulayacagini garanti etmez. Boyle nesneler zaten ust
		duzey degil, olcegi atalarindan aliyorlar.
	]]
	local baskaOlcek = nesne:FindFirstChildOfClass("UIScale")
	if baskaOlcek and baskaOlcek.Name ~= OLCEK_ADI then
		return
	end

	local mevcut = nesne:FindFirstChild(OLCEK_ADI)
	if mevcut and mevcut:IsA("UIScale") then
		mevcut.Scale = gercekOlcek(olcekYuzde)
		return
	end

	local olcek = Instance.new("UIScale")
	olcek.Name = OLCEK_ADI
	olcek.Scale = gercekOlcek(olcekYuzde)
	olcek.Parent = nesne
end

-- Bir ScreenGui'yi olcege baglar; sonradan eklenen cocuklari da yakalar
local function guiIzle(gui: Instance)
	if not gui:IsA("ScreenGui") then
		return
	end

	for _, cocuk in gui:GetChildren() do
		nesneyeUygula(cocuk)
	end

	if izlenenGui[gui] then
		return
	end
	izlenenGui[gui] = true
	gui.ChildAdded:Connect(nesneyeUygula)
end

local function playerGuiBul(): Instance?
	local player = Players.LocalPlayer
	if not player then
		return nil
	end
	return player:FindFirstChildOfClass("PlayerGui")
end

local function hepsineUygula()
	local playerGui = playerGuiBul()
	if not playerGui then
		return
	end
	for _, gui in playerGui:GetChildren() do
		guiIzle(gui)
	end
end

-- Su anki olcek yuzdesi (100 = varsayilan)
function UI.getScale(): number
	return olcekYuzde
end

--[[
	Olcegi degistirir. Deger siniri asarsa kirpilir ve tam sayiya yuvarlanir.
	Gercekten uygulanan yuzdeyi dondurur.
]]
function UI.setScale(yuzde: number): number
	local yeni = math.clamp(math.round(yuzde), UI.ScaleMin, UI.ScaleMax)
	olcekYuzde = yeni

	hepsineUygula()

	for _, dinleyici in olcekDinleyicileri do
		task.spawn(dinleyici, yeni)
	end

	return yeni
end

-- Olcek her degistiginde haber verir (ayar panelindeki yazi icin)
function UI.onScaleChanged(dinleyici: (yuzde: number) -> ())
	table.insert(olcekDinleyicileri, dinleyici)
end

--[[
	PlayerGui'yi tarar ve sonradan eklenen ScreenGui'leri de yakalar.
	Her client scripti kendi ScreenGui'sini kendi zamaninda kuruyor, bu
	yuzden ChildAdded olmadan gec kurulan arayuzler olceksiz kalirdi.
]]
task.spawn(function()
	local player = Players.LocalPlayer
	if not player then
		return
	end

	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then
		return
	end

	hepsineUygula()
	playerGui.ChildAdded:Connect(guiIzle)
end)

--[[
	=====================================================================
	RENKLI PANEL PARCALARI  --  cocuklara hitap eden cizgi film gorunumu
	=====================================================================

	Magaza (STORE) paneliyle ayni dil: kalin siyah kontur, cilali renkli
	baslik cubugu, renkli kartlar ve 3B basilan dugmeler. Her panel kendi
	rengini verir, gerisi ayni.

	    UI.baslikCubugu(panel, "Quests", renkA, renkB, "quests")
	    UI.renkliKart(satir, renk)
	    local dugme, yuz, yazi = UI.dugme3B(parent, "Buy", boyut, renk)
	    UI.dugme3BRenk(dugme, yeniRenk)   -- durum degisince (para yetti/yetmedi)
	    UI.cubukCilasi(dolgu)             -- ilerleme cubugunun dolgusu
]]
local SIYAH = Color3.fromRGB(0, 0, 0)
local BEYAZ = Color3.fromRGB(255, 255, 255)
-- 3B dugmenin altinda birakilan kabartma payi
local DUGME_LIP = 5

-- Para yetmeyen / kilitli dugmelerin rengi
UI.KapaliRenk = Color3.fromRGB(105, 110, 124)

-- Desen ve parlaklik katmanlarinin koselerini de yuvarlar
local function katmanKoseleri(yuz: GuiObject, yaricap: number)
	for _, cocuk in yuz:GetChildren() do
		-- Desen bir CanvasGroup, Parlaklik duz Frame: ikisi de GuiObject
		if cocuk:IsA("GuiObject") and (cocuk.Name == "Desen" or cocuk.Name == "Parlaklik") then
			UI.corner(cocuk, yaricap)
		end
	end
end

--[[
	PANEL BASLIGI

	Panelin ustune cilali, soldan saga renk gecisli bir cubuk koyar; ustune
	(varsa) ikon ve beyaz baslik gelir. Panelin kendisi de hafifce o renge
	boyanir ve kalin siyah kontur alir. Kapatma dugmesi cubugun sag ucuna
	tasinir. Cubuk 62. piksele kadar yer kaplar; icerik 70'ten baslamali.
]]
function UI.baslikCubugu(panel: Frame, yazi: string, renkA: Color3, renkB: Color3, ikonId: string?): (Frame, TextLabel)
	local kontur = panel:FindFirstChildOfClass("UIStroke")
	if kontur then
		kontur.Color = SIYAH
		kontur.Thickness = 3
	end

	-- Zemin: ust kisim baslik renginde hafif isik alir, alta dogru koyulasir
	panel.BackgroundColor3 = BEYAZ
	local zemin = Instance.new("UIGradient")
	zemin.Name = "PanelRengi"
	zemin.Rotation = 90
	zemin.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UI.Colors.panel:Lerp(renkA, 0.22)),
		ColorSequenceKeypoint.new(0.45, UI.Colors.panel:Lerp(renkB, 0.08)),
		ColorSequenceKeypoint.new(1, UI.Colors.panel),
	})
	zemin.Parent = panel

	local cubuk = Instance.new("Frame")
	cubuk.Name = "Baslik"
	cubuk.Position = UDim2.fromOffset(8, 8)
	cubuk.Size = UDim2.new(1, -16, 0, 54)
	cubuk.BackgroundColor3 = BEYAZ
	cubuk.BorderSizePixel = 0
	cubuk.ClipsDescendants = true
	cubuk.Parent = panel
	UI.corner(cubuk, 10)
	UI.stroke(cubuk, SIYAH, 2)

	local gecis = Instance.new("UIGradient")
	gecis.Color = ColorSequence.new(renkA, renkB)
	gecis.Parent = cubuk

	UI.caprazDesen(cubuk)
	UI.gloss(cubuk, 0.7)
	katmanKoseleri(cubuk, 10)

	local baslik = UI.text({
		text = yazi,
		size = UI.Sizes.title,
		font = BOLD,
		color = BEYAZ,
		frameSize = UDim2.new(1, -80, 1, 0),
		position = UDim2.fromOffset(16, 0),
		parent = cubuk,
		zIndex = 5,
	})
	baslik.Name = "Yazi"

	-- Ikon bulunursa yazi saga kayar; bulunamazsa yazi solda kalir
	if ikonId then
		local ikon = Instance.new("ImageLabel")
		ikon.Name = "Ikon"
		ikon.BackgroundTransparency = 1
		ikon.Position = UDim2.fromOffset(8, 4)
		ikon.Size = UDim2.fromOffset(46, 46)
		ikon.ScaleType = Enum.ScaleType.Fit
		ikon.ZIndex = 5
		ikon.Visible = false
		ikon.Parent = cubuk

		local Icons = require(Shared:WaitForChild("Icons")) :: any
		Icons.bind(ikon, ikonId, function(ok: boolean)
			if ok then
				ikon.Visible = true
				baslik.Position = UDim2.fromOffset(62, 0)
			end
		end)
	end

	panel:SetAttribute("RenkliBaslik", true)
	local kapat = panel:FindFirstChild("Kapat")
	if kapat and kapat:IsA("GuiObject") then
		kapat.Position = UDim2.new(1, -18, 0, 18)
		kapat.ZIndex = 6
		UI.stroke(kapat, SIYAH, 2)
	end

	return cubuk, baslik
end

--[[
	RENKLI KART  --  liste satirlari icin

	Soldan saga: renkli -> koyu. Yazilar sagdaki koyu kisimda da okunur.
	Kalin siyah kontur verir (baska bir renk istenirse sonradan degistir).
]]
function UI.renkliKart(kart: GuiObject, renk: Color3): UIStroke
	kart.BackgroundColor3 = BEYAZ
	local gecis = Instance.new("UIGradient")
	gecis.Name = "KartRengi"
	gecis.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, renk:Lerp(SIYAH, 0.2)),
		ColorSequenceKeypoint.new(0.5, renk:Lerp(UI.Colors.panelLight, 0.7)),
		ColorSequenceKeypoint.new(1, UI.Colors.panelLight),
	})
	gecis.Parent = kart

	local kontur = kart:FindFirstChildOfClass("UIStroke")
	if kontur then
		kontur.Color = SIYAH
		kontur.Thickness = 2
		return kontur
	end
	return UI.stroke(kart, SIYAH, 2)
end

-- Ilerleme cubugu dolgusuna ustten parlak, alttan koyu cila
function UI.cubukCilasi(dolgu: GuiObject)
	local gecis = Instance.new("UIGradient")
	gecis.Rotation = 90
	gecis.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, BEYAZ),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(235, 235, 235)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 170, 170)),
	})
	gecis.Parent = dolgu
end

--[[
	3B DUGME

	Koyu govde + ustte cilali yuz. Basilinca yuz asagi iner, fare ustune
	gelince aydinlanir. Rengi sonradan UI.dugme3BRenk ile degisebilir
	(fare etkisi her seferinde guncel rengi okur; UI.hover ilk rengi
	hafizada tuttugu icin burada kullanilmiyor).

	buyusun = true: fare ustune gelince merkezinden buyur. Liste icindeki
	dugmelerde kapali birak, komsularinin ustune tasar.
]]
function UI.dugme3B(parent: Instance, yazi: string?, boyut: UDim2, renk: Color3, buyusun: boolean?): (TextButton, Frame, TextLabel?)
	local dugme = Instance.new("TextButton")
	dugme.Name = "Dugme"
	dugme.Text = ""
	dugme.AutoButtonColor = false
	dugme.Size = boyut
	dugme.BackgroundColor3 = UI.shade(renk, -0.3)
	dugme.BorderSizePixel = 0
	dugme.Parent = parent
	UI.corner(dugme, 10)
	UI.stroke(dugme, SIYAH, 2)
	dugme:SetAttribute("Renk", renk)

	local yuz = Instance.new("Frame")
	yuz.Name = "Yuz"
	yuz.AnchorPoint = Vector2.new(0.5, 0)
	yuz.Position = UDim2.new(0.5, 0, 0, 3)
	yuz.Size = UDim2.new(1, -6, 1, -6 - DUGME_LIP)
	yuz.BackgroundColor3 = renk
	yuz.BorderSizePixel = 0
	yuz.ClipsDescendants = true
	yuz.Parent = dugme
	UI.corner(yuz, 8)

	-- Gri tonlu gecis: rengi carpar, yani her renkte ayni cila
	local gecis = Instance.new("UIGradient")
	gecis.Rotation = 90
	gecis.Color = ColorSequence.new(BEYAZ, Color3.fromRGB(205, 205, 205))
	gecis.Parent = yuz

	UI.caprazDesen(yuz)
	UI.gloss(yuz, 0.75)
	katmanKoseleri(yuz, 8)

	local etiket: TextLabel? = nil
	if yazi then
		etiket = UI.text({
			text = yazi,
			size = UI.Sizes.body,
			font = BOLD,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.new(1, -6, 1, 0),
			position = UDim2.fromOffset(3, 0),
			parent = yuz,
			zIndex = 5,
			name = "Label",
		})
	end

	local olcek: UIScale? = nil
	if buyusun then
		local yeni = Instance.new("UIScale")
		yeni.Name = "FareOlcegi"
		yeni.Parent = dugme
		olcek = yeni
	end

	local ustunde = false
	local function ciz(basili: boolean)
		local temel = dugme:GetAttribute("Renk")
		local c: Color3 = if typeof(temel) == "Color3" then temel else renk
		local bilgi = TweenInfo.new(UI.HoverTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(yuz, bilgi, {
			BackgroundColor3 = if ustunde then UI.shade(c, UI.HoverLift) else c,
		}):Play()
		yuz.Position = UDim2.new(0.5, 0, 0, if basili then 3 + DUGME_LIP / 2 else 3)
		if olcek then
			TweenService:Create(
				olcek,
				TweenInfo.new(UI.HoverTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = if basili then UI.PressPop elseif ustunde then UI.HoverPop else 1 }
			):Play()
		end
	end

	dugme.MouseEnter:Connect(function()
		ustunde = true
		ciz(false)
	end)
	dugme.MouseLeave:Connect(function()
		ustunde = false
		ciz(false)
	end)
	dugme.MouseButton1Down:Connect(function()
		ciz(true)
	end)
	dugme.MouseButton1Up:Connect(function()
		ciz(false)
	end)

	return dugme, yuz, etiket
end

-- 3B dugmenin rengini degistirir (govde + yuz)
function UI.dugme3BRenk(dugme: GuiObject, renk: Color3)
	if dugme:GetAttribute("Renk") == renk then
		return
	end
	dugme:SetAttribute("Renk", renk)
	dugme.BackgroundColor3 = UI.shade(renk, -0.3)
	local yuz = dugme:FindFirstChild("Yuz")
	if yuz and yuz:IsA("GuiObject") then
		yuz.BackgroundColor3 = renk
	end
end


------------------------------------------------------------------
-- IKON CANLANDIRMALARI
------------------------------------------------------------------

--[[
	SALLANMA

	Magaza ikonlari kendi etrafinda DONMEZ, sagli sollu sallanir: urunun
	yuzu her zaman ekrana bakar, goz yine de hareketi yakalar. Donen bir
	urun kartin icinde kendi arkasini gosterdigi icin garip duruyordu.

	Salinim SIFIR MERKEZLI: nesne -aci'da baslar, +aci'ya gider ve geri
	doner, yani ortalama durusu dimdik. Tween kendi tersine dondugu icin
	(TweenInfo'nun son alani) ayrica zamanlayici gerekmiyor.

	ORTAK RITIM: butun magaza ikonlari ayni acida ve ayni hizda sallanir,
	boylece Store ile Rot Coin Shop birbirinden kopuk gorunmez. Hizli ve
	genis tutuldu -- kart listesinde goz ilk buraya takilsin.
]]
UI.SallanmaAci = 17
UI.SallanmaSuresi = 0.75

function UI.sallan(nesne: GuiObject, aci: number?, sure: number?): Tween
	local genlik = aci or UI.SallanmaAci
	nesne.Rotation = -genlik
	local sallanma = TweenService:Create(
		nesne,
		TweenInfo.new(sure or UI.SallanmaSuresi, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Rotation = genlik }
	)
	sallanma:Play()
	return sallanma
end

export type HuzmeAyari = {
	-- Kac serit (cift sayi verilince desen simetrik olur)
	sayi: number,
	-- Seridin boyu ve eni, piksel
	uzunluk: number,
	kalinlik: number,
	-- Tam tur suresi, saniye
	tur: number,
	-- Ortadaki en parlak noktanin seffafligi (0 = tam parlak)
	parlaklik: number,
	-- Huzmelerin ZIndex'i; ONUNDE duracak ikondan KUCUK olmali
	zIndex: number,
	--[[
		Efektin rengi. Bos birakilirsa kademenin kendi rengi kullanilir; ama
		Golden gibi kartin zeminiyle ayni tonda olan kademelerde efekt o
		zeminde kayboluyor, orada acik bir renk veriliyor.
	]]
	renk: Color3?,
}

--[[
	ISIK HUZMELERI

	Bir ikonun ARKASINDAN disari uzanan, yavasca donen isik seritleri.
	Seritler ortak bir cercevenin cocugu: cerceve dondukce hepsi birlikte
	doner, tek tek dondurmek gerekmez.

	Her serit ortasi parlak, iki ucu seffaf bir gradyan tasir; boylece
	dikdortgen degil, merkezden disa suzulen bir isin gibi gorunur.

	ZIndex CAGIRANDAN GELIYOR. ZIndexBehavior.Sibling'de cocuk olmak one
	gecirmez, sira yalnizca ZIndex'e bakar -- huzmeler ikondan kucuk bir
	deger almazsa ikonun ONUNE gecer ve urunu ortarlar.
]]
function UI.isikHuzmeleri(parent: GuiObject, renk: Color3, ayar: HuzmeAyari): Frame
	local isik = Instance.new("Frame")
	isik.Name = "Huzmeler"
	isik.AnchorPoint = Vector2.new(0.5, 0.5)
	isik.Position = UDim2.fromScale(0.5, 0.5)
	isik.Size = UDim2.fromOffset(10, 10)
	isik.BackgroundTransparency = 1
	isik.ZIndex = ayar.zIndex
	isik.Parent = parent

	for i = 1, ayar.sayi do
		local huzme = Instance.new("Frame")
		huzme.Name = "Huzme"
		huzme.AnchorPoint = Vector2.new(0.5, 0.5)
		huzme.Position = UDim2.fromScale(0.5, 0.5)
		huzme.Size = UDim2.fromOffset(ayar.kalinlik, ayar.uzunluk)
		-- Seritler tam turu paylasir; 180 derece yeter, oburu yarisi ayni serit
		huzme.Rotation = (i - 1) * (180 / ayar.sayi)
		huzme.BackgroundColor3 = renk
		huzme.BorderSizePixel = 0
		huzme.ZIndex = ayar.zIndex
		huzme.Parent = isik

		local gecis = Instance.new("UIGradient")
		gecis.Rotation = 90
		gecis.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.34, math.clamp(ayar.parlaklik + 0.25, 0, 1)),
			NumberSequenceKeypoint.new(0.5, ayar.parlaklik),
			NumberSequenceKeypoint.new(0.66, math.clamp(ayar.parlaklik + 0.25, 0, 1)),
			NumberSequenceKeypoint.new(1, 1),
		})
		gecis.Parent = huzme
	end

	--[[
		Donus TEK YONLU oldugu icin tween tersine donmemeli; 360'a varinca
		aci basa sarilir. Rotation 360 ile 0 ayni goruntu, yani sicrama
		gozukmez.
	]]
	local donus = TweenService:Create(
		isik,
		TweenInfo.new(ayar.tur, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{ Rotation = 360 }
	)
	donus:Play()

	return isik
end

--[[
	YUMUSATILMIS ARKA PLAN RESMI

	Roblox'ta UI icin gercek bir blur YOK: BlurEffect yalnizca 3B kamerada
	calisir, bir ImageLabel'a uygulanamaz. Burada ayni resim birkac kez,
	birbirine gore birkac piksel kaydirilmis ve daha soluk olarak ust uste
	seriliyor. Kenarlar birbirine karisiyor, detay dagiliyor: goz bunu
	bulaniklik olarak okuyor. `yayilma` buyudukce bulaniklik artar.

	Resim kutuyu KIRPARAK dolduruyor (ScaleType.Crop): en-boy orani bozulmaz,
	tasan kismi kap kirpar.

	KAP BIR CANVASGROUP. Duz bir Frame'de ClipsDescendants dikdortgen kirpar
	ve UICorner yalnizca kabin KENDI zeminini yuvarlar -- kap saydam oldugu
	icin de hicbir ise yaramaz, resim kartin yuvarlak kosesinden disari
	tasardi. CanvasGroup once kendi yuzeyine ciziyor, UICorner o yuzeye
	uygulaniyor: kirpma da yuvarlak oluyor. Yaricapi cagiran veriyor.
]]
function UI.yumusakResim(
	parent: GuiObject,
	resim: string,
	saydamlik: number,
	yayilma: number,
	zIndex: number
): CanvasGroup
	local kap = Instance.new("CanvasGroup")
	kap.Name = "ArkaPlan"
	kap.Size = UDim2.fromScale(1, 1)
	kap.BackgroundTransparency = 1
	kap.BorderSizePixel = 0
	kap.ClipsDescendants = true
	kap.ZIndex = zIndex
	kap.Parent = parent

	-- Merkez katman + dort kosege kaydirilmis kopya
	local KAYMALAR = {
		Vector2.new(0, 0),
		Vector2.new(-1, -1),
		Vector2.new(1, -1),
		Vector2.new(-1, 1),
		Vector2.new(1, 1),
	}

	for i, yon in KAYMALAR do
		local kat = Instance.new("ImageLabel")
		kat.Name = "Katman"
		kat.BackgroundTransparency = 1
		kat.BorderSizePixel = 0
		kat.Image = resim
		kat.ScaleType = Enum.ScaleType.Crop
		kat.Size = UDim2.fromScale(1, 1)
		kat.Position = UDim2.fromOffset(yon.X * yayilma, yon.Y * yayilma)
		--[[
			Merkez katman verilen saydamlikta; kaydirilmislar daha soluk,
			yoksa resim bes kat koyulasip bulanik degil KIRLI gorunur.
		]]
		kat.ImageTransparency = if i == 1 then saydamlik else saydamlik + (1 - saydamlik) * 0.6
		kat.ZIndex = zIndex
		kat.Parent = kap
	end

	return kap
end

--[[
	PARLAMA  --  ViewportFrame'in cizemedigi isimayi UI ile yapmak

	ViewportFrame post-processing uygulamaz: icindeki Neon parca parlak
	RENKTE gorunur ama etrafina isik SACMAZ, ve ParticleEmitter / Beam /
	Trail hic cizilmez. Yani modelin kendi efektleri onizlemede kayboluyor.

	Buradaki hale onun yerini tutuyor: ic ice gecen yuvarlak katmanlar, her
	biri ayni saydamlikta. Ust uste bindikce merkez koyulasiyor, disa dogru
	acik kaliyor -- radyal bir gecisin ucuz ama ikna edici karsiligi
	(UIGradient yalnizca dogrusal, radyal secenegi yok).

	Hale yavasca nefes alir; sabit bir daire yapistirma gibi duruyordu.
]]
function UI.parlama(parent: GuiObject, renk: Color3, cap: number, zIndex: number): Frame
	local KATMAN = 5

	local kap = Instance.new("Frame")
	kap.Name = "Parlama"
	kap.AnchorPoint = Vector2.new(0.5, 0.5)
	kap.Position = UDim2.fromScale(0.5, 0.5)
	kap.Size = UDim2.fromOffset(cap, cap)
	kap.BackgroundTransparency = 1
	kap.ZIndex = zIndex
	kap.Parent = parent

	for i = 1, KATMAN do
		local halka = Instance.new("Frame")
		halka.Name = "Halka"
		halka.AnchorPoint = Vector2.new(0.5, 0.5)
		halka.Position = UDim2.fromScale(0.5, 0.5)
		halka.Size = UDim2.fromScale(i / KATMAN, i / KATMAN)
		halka.BackgroundColor3 = renk
		halka.BackgroundTransparency = 0.86
		halka.BorderSizePixel = 0
		halka.ZIndex = zIndex
		halka.Parent = kap
		-- Yaricap kenarin yarisindan buyuk olunca Roblox tam daireye kirpar
		UI.corner(halka, 1000)
	end

	local nefes = Instance.new("UIScale")
	nefes.Parent = kap
	TweenService:Create(
		nefes,
		TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Scale = 1.12 }
	):Play()

	return kap
end

--[[
	PARILTILAR  --  modelin onunde sonup yanan kivilcimlar

	ViewportFrame parcacik cizmedigi icin blogun "canli" hissini bunlar
	veriyor: kucuk, 45 derece cevrilmis kareler (elmas) rastgele yerlerde
	kendi temposunda sonup yaniyor.

	Konum ve tempo RASTGELE ama bir kez seciliyor; her karede oynatmak
	gerekmiyor, sonme tween'i kendi basina donuyor.
]]
function UI.pariltilar(parent: GuiObject, renk: Color3, sayi: number, zIndex: number): Frame
	local kap = Instance.new("Frame")
	kap.Name = "Pariltilar"
	kap.AnchorPoint = Vector2.new(0.5, 0.5)
	kap.Position = UDim2.fromScale(0.5, 0.5)
	kap.Size = UDim2.fromScale(1, 1)
	kap.BackgroundTransparency = 1
	kap.ZIndex = zIndex
	kap.Parent = parent

	local rastgele = Random.new()

	for _ = 1, sayi do
		local boy = rastgele:NextInteger(6, 12)

		local kivilcim = Instance.new("Frame")
		kivilcim.Name = "Kivilcim"
		kivilcim.AnchorPoint = Vector2.new(0.5, 0.5)
		kivilcim.Position = UDim2.fromScale(rastgele:NextNumber(0.1, 0.9), rastgele:NextNumber(0.1, 0.9))
		kivilcim.Size = UDim2.fromOffset(boy, boy)
		kivilcim.Rotation = 45
		kivilcim.BackgroundColor3 = renk
		kivilcim.BackgroundTransparency = 1
		kivilcim.BorderSizePixel = 0
		kivilcim.ZIndex = zIndex
		kivilcim.Parent = kap

		--[[
			Her kivilcim kendi gecikmesiyle basliyor; hepsi ayni anda yanip
			sonerse kivilcim degil, yanip sonen tek bir lamba gibi duruyor.
		]]
		TweenService:Create(
			kivilcim,
			TweenInfo.new(
				rastgele:NextNumber(0.5, 1.1),
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut,
				-1,
				true,
				rastgele:NextNumber(0, 1.2)
			),
			{ BackgroundTransparency = 0.1 }
		):Play()
	end

	return kap
end

--[[
	BILDIRIM NOKTASI

	Hedefin sag ust kosesine oturan kirmizi nokta: "burada alinacak bir sey
	var". Gorunur oldugu surece nabiz atar, kapaninca nabiz durur.

	Doner deger noktayi acip kapatan fonksiyondur; cagiran tarafin nesneyi
	saklamasi gerekmez.
]]
function UI.bildirimNoktasi(hedef: GuiObject, zIndex: number?): (acik: boolean) -> ()
	local NOKTA = 16

	local nokta = Instance.new("Frame")
	nokta.Name = "Bildirim"
	nokta.AnchorPoint = Vector2.new(0.5, 0.5)
	-- Kosenin BIRAZ DISINA tasar: butonun icindeki ikonu ortmesin
	nokta.Position = UDim2.new(1, -3, 0, 3)
	nokta.Size = UDim2.fromOffset(NOKTA, NOKTA)
	nokta.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	nokta.BorderSizePixel = 0
	nokta.Visible = false
	nokta.ZIndex = zIndex or 10
	nokta.Parent = hedef
	UI.corner(nokta, NOKTA / 2)
	-- Kalin siyah kontur: acik renkli butonlarin uzerinde de secilir
	UI.stroke(nokta, Color3.fromRGB(0, 0, 0), 2)

	local nabiz: Tween? = nil

	return function(acik: boolean)
		if nokta.Visible == acik then
			return
		end
		nokta.Visible = acik

		local eski = nabiz
		if eski then
			eski:Cancel()
			nabiz = nil
			nokta.Size = UDim2.fromOffset(NOKTA, NOKTA)
		end

		if not acik then
			return
		end

		local yeni = TweenService:Create(
			nokta,
			TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Size = UDim2.fromOffset(NOKTA + 5, NOKTA + 5) }
		)
		yeni:Play()
		nabiz = yeni
	end
end

return UI
