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
function UI.rarityStyle(label: TextLabel, rarityId: string): TextLabel
	local color = Rarity.color(rarityId)

	Divine.untag(label)

	if Rarity.isDivine(rarityId) then
		-- Parildama TextColor3 uzerinden calisiyor; gradyan olmamali
		Fonts.clearGlow(label, color)
		-- tagIf: kademenin KENDI paleti takilir, hepsi Divine olmaz
		Divine.tagIf(label, rarityId)
	elseif Rarity.isGlowing(rarityId) then
		Fonts.applyGlow(label, color)
	else
		Fonts.clearGlow(label, color)
	end

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
	TEK PANEL KURALI

	Butun paneller ekranin TAM ORTASINDA duruyor; ikisi ayni anda acik olursa
	ust uste biniyorlar. Bu yuzden bir panel gorunur olur olmaz digerleri
	kapanir.

	Kural panelin nasil acildigina degil, Visible ozelliginin KENDISINE bagli:
	menu butonu, sunucudan gelen olay, klavye kisayolu -- hepsi ayni sekilde
	calisir, acan tarafin bir sey yapmasi gerekmez.

	Liste bu ModuleScript'te durdugu ve istemcide tek kopya oldugu icin kural
	scriptler ARASINDA da gecerli: Fuse'un bozdurucusu acilinca Menuler'in
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
	frame.Parent = parent
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
function UI.stripeLayer(parent: GuiObject, tint: Color3, rotation: number, count: number, alpha: number): Frame
	local layer = Instance.new("Frame")
	layer.Name = "Desen"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundColor3 = tint
	layer.BorderSizePixel = 0
	layer.ZIndex = 2
	layer.Parent = parent

	local step = 1 / count
	local band = step * 0.42

	local points: { NumberSequenceKeypoint } = { NumberSequenceKeypoint.new(0, 1) }

	for i = 0, count - 1 do
		local start = step * 0.3 + i * step
		local finish = start + band
		if finish < 0.99 then
			table.insert(points, NumberSequenceKeypoint.new(start, 1))
			table.insert(points, NumberSequenceKeypoint.new(start + 0.002, alpha))
			table.insert(points, NumberSequenceKeypoint.new(finish, alpha))
			table.insert(points, NumberSequenceKeypoint.new(finish + 0.002, 1))
		end
	end

	table.insert(points, NumberSequenceKeypoint.new(1, 1))

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Transparency = NumberSequence.new(points)
	gradient.Parent = layer

	return layer
end

--[[
	ELMAS IZGARA
	Iki serit katmani zit acilarla ust uste binince capraz kafes olusur --
	referans butonlardaki doku tam olarak budur.
]]
function UI.diamondGrid(parent: GuiObject, tint: Color3?, count: number?)
	local color = tint or Color3.fromRGB(255, 255, 255)
	local n = count or 4

	UI.stripeLayer(parent, color, 32, n, 0.86)
	UI.stripeLayer(parent, color, -32, n, 0.9)
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
	layer.ZIndex = 3
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

	UI.diamondGrid(face)
	UI.gloss(face)

	if radius then
		-- Desen ve parlaklik katmanlarinin koseleri de yuvarlansin
		for _, child in face:GetChildren() do
			if child:IsA("Frame") and (child.Name == "Desen" or child.Name == "Parlaklik") then
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

return UI
