--[[
	Fuse  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Fuse

	1. MAKINE PENCERESI
	   Makinede E'ye basinca acilir:

	       [ Fuse Machine                         X ]
	         Bring 3 Brainrots of the same tier
	         15-25% chance (same names = higher)
	       [ slot ]      [ slot ]      [ slot ]
	           \____________ | ____________/
	                  [ sonuc kutusu ]
	          If it fails, all 3 brainrots are lost
	              [ 2 Brainrot Left / FUSE! ]

	   Bos slotun "+" dugmesi secim listesini acar. Dolu slotta brainrotun
	   resmi, adi, kademesi ve "Return" dugmesi durur. Kurallar ve oranlar
	   sunucuda (bkz. ServerScriptService > Fuse, Shared > Fuse).

	2. BIRLESME GOSTERISI
	   FUSE'a basinca: ruhlar donerek merkeze kapanir ve parlar. Basarida
	   yeni kademenin renginde patlama ve kazanilan brainrotun adi; basarisizlikta
	   cekirdek sonup kaybolur.
]]

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Condition = require(Shared:WaitForChild("Condition"))
local Format = require(Shared:WaitForChild("Format"))
local Fuse = require(Shared:WaitForChild("Fuse"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))
local BrainrotOnizleme = require(script.Parent:WaitForChild("BrainrotOnizleme"))
-- Istege bagli: yoksa Fuse arayuzu yine kurulur, yalnizca mutasyon yazisi cikmaz
local MutasyonGosterisi = (function()
	local modul = script.Parent:WaitForChild("MutasyonGosterisi", 5)
	local ok, sonuc = pcall(function()
		return if modul then require(modul) else nil
	end)
	if ok and sonuc then
		return sonuc
	end
	warn("[Fuse] MutasyonGosterisi yuklenemedi; mutasyon yazisi gosterilmeyecek")
	return { goster = function() end }
end)()

local FuseDurum = Net.event("FuseDurum")
local FuseGeriAl = Net.event("FuseGeriAl")
local FuseSonuc = Net.event("FuseSonuc")
local FuseSecim = Net.event("FuseSecim")
local FuseEkle = Net.event("FuseEkle")
local FuseCikar = Net.event("FuseCikar")
local FuseBaslat = Net.event("FuseBaslat")

local TAKE_BACK = "FuseGeriAlEylemi"

local screen = Instance.new("ScreenGui")
screen.Name = "FuseEkrani"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

------------------------------------------------------------------
-- RENKLER VE OLCULER
------------------------------------------------------------------
--[[
	ANA_W: makinenin kendisi (slotlar, borular, sonuc kutusu, FUSE dugmesi).
	Pencere sagdan SAG_EN kadar genis: ayrinti kutulari orada durur.
]]
local ANA_W = 640
local SAG_EN = 250
local W, H = ANA_W + SAG_EN, 548
local BASLIK_BOY = 58

local MOR_A = Color3.fromRGB(150, 60, 230)
local MOR_B = Color3.fromRGB(235, 70, 190)
local GOVDE = Color3.fromRGB(44, 42, 66)
local KART = Color3.fromRGB(58, 56, 84)
local YESIL = Color3.fromRGB(70, 210, 80)
local KIRMIZI = Color3.fromRGB(235, 60, 60)
local SIYAH = Color3.fromRGB(0, 0, 0)
local BORU_DOLU = Color3.fromRGB(232, 240, 196)
local BORU_BOS = Color3.fromRGB(34, 36, 48)

local SLOT_EN, SLOT_BOY = 180, 132
local SLOT_Y = 128
local SLOT_X = { 30, 230, 430 }

local KUTU_EN, KUTU_BOY = 172, 116
local KUTU_X = (ANA_W - KUTU_EN) / 2
local KUTU_Y = 330

------------------------------------------------------------------
-- PENCERE
------------------------------------------------------------------
local pencere = UI.panel(screen, UDim2.fromOffset(W, H), "FuseMakinesi")
pencere.BackgroundColor3 = GOVDE
pencere.ClipsDescendants = true
UI.stroke(pencere, SIYAH, 4)

-- Mor-pembe baslik seridi
local baslik = Instance.new("Frame")
baslik.Name = "Baslik"
baslik.Size = UDim2.new(1, 0, 0, BASLIK_BOY)
baslik.BackgroundColor3 = Color3.new(1, 1, 1)
baslik.BorderSizePixel = 0
baslik.Parent = pencere
UI.corner(baslik, 14)

local baslikGecis = Instance.new("UIGradient")
baslikGecis.Color = ColorSequence.new(MOR_A, MOR_B)
baslikGecis.Parent = baslik

-- Baslik seridinin alt koselerini duz gostermek icin alt yariyi kapatan serit
local baslikAlt = Instance.new("Frame")
baslikAlt.Size = UDim2.new(1, 0, 0, 16)
baslikAlt.Position = UDim2.new(0, 0, 1, -16)
baslikAlt.BackgroundColor3 = Color3.new(1, 1, 1)
baslikAlt.BorderSizePixel = 0
baslikAlt.Parent = baslik
local baslikAltGecis = baslikGecis:Clone()
baslikAltGecis.Parent = baslikAlt

UI.text({
	text = "Fuse Machine",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	frameSize = UDim2.new(1, -90, 1, 0),
	position = UDim2.fromOffset(20, 0),
	parent = baslik,
	name = "Yazi",
})

UI.closeButton(pencere).MouseButton1Click:Connect(function()
	pencere.Visible = false
end)

local yonerge = UI.text({
	text = "",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromOffset(ANA_W - 20, 30),
	position = UDim2.fromOffset(10, BASLIK_BOY + 10),
	parent = pencere,
	name = "Yonerge",
})
yonerge.RichText = true

local sansYazi = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	color = YESIL,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromOffset(ANA_W - 20, 24),
	position = UDim2.fromOffset(10, BASLIK_BOY + 40),
	parent = pencere,
	name = "Sans",
})

--[[
	AYRINTI KUTULARI  (pencerenin sag seridinde, alt alta)

	Sol: basari sansi -- hepsi ayni brainrot %40, degilse %25, su anki sans.
	Sag: mutasyon aktarimi -- konan her mutasyonlu brainrot kendi
	mutasyonunu %10 ihtimalle kazanilan brainrota gecirir.
]]
local BILGI_BOY = 208

local function bilgiKutusu(y: number, ad: string): TextLabel
	local kutuB = Instance.new("Frame")
	kutuB.Name = ad
	kutuB.Position = UDim2.fromOffset(ANA_W, y)
	kutuB.Size = UDim2.fromOffset(SAG_EN - 20, BILGI_BOY)
	kutuB.BackgroundColor3 = Color3.fromRGB(58, 56, 84)
	kutuB.BorderSizePixel = 0
	kutuB.Parent = pencere
	UI.corner(kutuB, 10)
	UI.stroke(kutuB, Color3.fromRGB(0, 0, 0), 2)

	local yazi = UI.text({
		text = "",
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		color = Color3.new(1, 1, 1),
		frameSize = UDim2.new(1, -16, 1, -12),
		position = UDim2.fromOffset(8, 6),
		parent = kutuB,
		wrapped = true,
	})
	yazi.RichText = true
	yazi.TextYAlignment = Enum.TextYAlignment.Top
	return yazi
end

local sansBilgi = bilgiKutusu(BASLIK_BOY + 14, "SansBilgisi")
local mutasyonBilgi = bilgiKutusu(BASLIK_BOY + 14 + BILGI_BOY + 14, "MutasyonBilgisi")

-- Slot resimleri ve sonuc kutusu siluetinin 3B onizlemeleri
local onizleme = BrainrotOnizleme.seritPencere(pencere)

------------------------------------------------------------------
-- BORULAR  (slotlardan sonuc kutusuna)
------------------------------------------------------------------
type Boru = { parcalar: { Frame }, kapak: Frame }
local borular: { Boru } = {}

local function boruParca(x: number, y: number, en: number, boy: number): Frame
	local p = Instance.new("Frame")
	p.Position = UDim2.fromOffset(x, y)
	p.Size = UDim2.fromOffset(en, boy)
	p.BackgroundColor3 = BORU_BOS
	p.BorderSizePixel = 0
	p.Parent = pencere
	UI.stroke(p, SIYAH, 3)
	return p
end

do
	local kalinlik = 20
	local ustY = SLOT_Y + SLOT_BOY
	local ortaY = KUTU_Y + KUTU_BOY / 2 - kalinlik / 2

	for i = 1, 3 do
		local merkezX = SLOT_X[i] + SLOT_EN / 2
		local parcalar: { Frame } = {}

		if i == 2 then
			table.insert(parcalar, boruParca(merkezX - kalinlik / 2, ustY, kalinlik, KUTU_Y - ustY))
		else
			table.insert(parcalar, boruParca(merkezX - kalinlik / 2, ustY, kalinlik, ortaY - ustY + kalinlik))
			local kutuKenar = if i == 1 then KUTU_X else KUTU_X + KUTU_EN
			local solX = math.min(merkezX - kalinlik / 2, kutuKenar)
			local sagX = math.max(merkezX + kalinlik / 2, kutuKenar)
			table.insert(parcalar, boruParca(solX, ortaY, sagX - solX, kalinlik))
		end

		-- Slotun altindaki yesil baglanti kapagi
		local kapak = Instance.new("Frame")
		kapak.Position = UDim2.fromOffset(merkezX - 26, ustY - 4)
		kapak.Size = UDim2.fromOffset(52, 10)
		kapak.BackgroundColor3 = YESIL
		kapak.BorderSizePixel = 0
		kapak.ZIndex = 3
		kapak.Parent = pencere
		UI.corner(kapak, 4)
		UI.stroke(kapak, SIYAH, 2)

		borular[i] = { parcalar = parcalar, kapak = kapak }
	end
end

------------------------------------------------------------------
-- SONUC KUTUSU
------------------------------------------------------------------
local kutu = Instance.new("Frame")
kutu.Name = "Sonuc"
kutu.Position = UDim2.fromOffset(KUTU_X, KUTU_Y)
kutu.Size = UDim2.fromOffset(KUTU_EN, KUTU_BOY)
kutu.BackgroundColor3 = KART
kutu.BorderSizePixel = 0
kutu.ZIndex = 2
kutu.Parent = pencere
UI.corner(kutu, 8)
local kutuKontur = UI.stroke(kutu, SIYAH, 3)

-- Silueti tasiyan alan; ustune buyuk "?" biner
local kutuResim = Instance.new("Frame")
kutuResim.Name = "Resim"
kutuResim.Position = UDim2.fromOffset(6, 6)
kutuResim.Size = UDim2.new(1, -12, 1, -34)
kutuResim.BackgroundTransparency = 1
kutuResim.ZIndex = 2
kutuResim.Parent = kutu

local kutuSoru = UI.text({
	text = "?",
	size = UI.Sizes.huge,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 1, -28),
	parent = kutu,
	name = "Soru",
})
kutuSoru.ZIndex = 5

local kutuYazi = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -8, 0, 22),
	position = UDim2.new(0, 4, 1, -26),
	parent = kutu,
	name = "Yazi",
})
kutuYazi.ZIndex = 5

local uyari = UI.text({
	text = "",
	size = UI.Sizes.tiny,
	font = UI.Fonts.bold,
	color = Color3.fromRGB(255, 120, 120),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromOffset(ANA_W - 20, 18),
	position = UDim2.fromOffset(10, KUTU_Y + KUTU_BOY + 6),
	parent = pencere,
	name = "Uyari",
})

------------------------------------------------------------------
-- ALT DUGME  ("2 Brainrot Left" / "FUSE!")
------------------------------------------------------------------
local fuseDugme = Instance.new("TextButton")
fuseDugme.Name = "Fuse"
fuseDugme.AnchorPoint = Vector2.new(0.5, 1)
fuseDugme.Position = UDim2.new(0, ANA_W / 2, 1, -16)
fuseDugme.Size = UDim2.fromOffset(300, 58)
fuseDugme.BackgroundColor3 = YESIL
fuseDugme.AutoButtonColor = false
fuseDugme.Text = ""
fuseDugme.BorderSizePixel = 0
fuseDugme.Parent = pencere
UI.corner(fuseDugme, 8)
UI.stroke(fuseDugme, SIYAH, 3)

local fuseYazi = UI.text({
	text = "",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = fuseDugme,
	name = "Yazi",
})

local fuseOlcek = Instance.new("UIScale")
fuseOlcek.Parent = fuseDugme
local fuseNabiz: Tween? = nil

local makineDolu = false

fuseDugme.MouseButton1Click:Connect(function()
	if makineDolu then
		FuseBaslat:FireServer()
	end
end)

------------------------------------------------------------------
-- SECIM LISTESI  ("+" ile acilir, pencerenin ustune biner)
------------------------------------------------------------------
local secim = Instance.new("Frame")
secim.Name = "Secim"
secim.Position = UDim2.fromOffset(0, BASLIK_BOY)
secim.Size = UDim2.new(1, 0, 1, -BASLIK_BOY)
secim.BackgroundColor3 = GOVDE
secim.BorderSizePixel = 0
secim.ZIndex = 20
secim.Visible = false
secim.Parent = pencere

local secimBaslik = UI.text({
	text = "Choose a Brainrot",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	frameSize = UDim2.new(1, -150, 0, 30),
	position = UDim2.fromOffset(20, 12),
	parent = secim,
})
secimBaslik.ZIndex = 21

local geriDugme = UI.button(secim, "Back", UDim2.fromOffset(110, 36), KIRMIZI)
geriDugme.Position = UDim2.new(1, -126, 0, 10)
geriDugme.ZIndex = 21
UI.stroke(geriDugme, SIYAH, 2)
geriDugme.MouseButton1Click:Connect(function()
	secim.Visible = false
end)

local secimListe = Instance.new("ScrollingFrame")
secimListe.Name = "Liste"
secimListe.Position = UDim2.fromOffset(16, 58)
secimListe.Size = UDim2.new(1, -32, 1, -74)
secimListe.BackgroundTransparency = 1
secimListe.BorderSizePixel = 0
secimListe.ScrollBarThickness = 6
secimListe.CanvasSize = UDim2.new()
secimListe.AutomaticCanvasSize = Enum.AutomaticSize.Y
secimListe.ZIndex = 21
secimListe.Parent = secim

local secimDizilim = Instance.new("UIListLayout")
secimDizilim.Padding = UDim.new(0, 8)
secimDizilim.SortOrder = Enum.SortOrder.LayoutOrder
secimDizilim.Parent = secimListe

local secimOnizleme = BrainrotOnizleme.pencere(secimListe, secim)

------------------------------------------------------------------
-- DURUM
------------------------------------------------------------------
local durum: any = { slots = {}, items = {}, required = Fuse.Required, chance = Fuse.SuccessChance }
local sonImza = ""
local nearMachine = false
local merging = false

local function detayYazisi(entry: any): string
	local parca = `{Condition.get(entry.condition).shortName}`
	if Mutations.isSpecial(entry.mutation) then
		parca ..= `  {Mutations.get(entry.mutation).displayName}`
	end
	return parca
end

------------------------------------------------------------------
-- SLOT KARTLARI
------------------------------------------------------------------
local slotKartlari: { Frame } = {}

local function slotKur(i: number, entry: any?)
	local eski = slotKartlari[i]
	if eski then
		eski:Destroy()
	end

	local kart = Instance.new("Frame")
	kart.Name = `Slot{i}`
	kart.Position = UDim2.fromOffset(SLOT_X[i], SLOT_Y)
	kart.Size = UDim2.fromOffset(SLOT_EN, SLOT_BOY)
	kart.BackgroundColor3 = KART
	kart.BorderSizePixel = 0
	kart.ZIndex = 4
	kart.Parent = pencere
	UI.corner(kart, 8)
	UI.stroke(kart, SIYAH, 3)
	slotKartlari[i] = kart

	local boru = borular[i]
	for _, p in boru.parcalar do
		p.BackgroundColor3 = if entry then BORU_DOLU else BORU_BOS
	end

	if entry then
		local renk = Rarity.color(entry.rarity)

		local ad = UI.text({
			text = entry.name,
			size = UI.Sizes.small,
			font = UI.Fonts.bold,
			color = Color3.new(1, 1, 1),
			frameSize = UDim2.new(1, -12, 0, 20),
			position = UDim2.fromOffset(8, 6),
			parent = kart,
		})
		ad.TextTruncate = Enum.TextTruncate.AtEnd
		ad.ZIndex = 6

		local kademe = UI.text({
			text = Rarity.displayName(entry.rarity),
			size = UI.Sizes.tiny,
			font = UI.Fonts.bold,
			color = renk,
			frameSize = UDim2.fromOffset(90, 16),
			position = UDim2.fromOffset(8, 26),
			parent = kart,
		})
		kademe.ZIndex = 6
		UI.rarityStyle(kademe, entry.rarity)

		local detay = UI.text({
			text = detayYazisi(entry),
			size = UI.Sizes.tiny,
			color = UI.Colors.textDim,
			frameSize = UDim2.fromOffset(90, 16),
			position = UDim2.fromOffset(8, 44),
			parent = kart,
		})
		detay.ZIndex = 6

		local resim = Instance.new("Frame")
		resim.Name = "Resim"
		resim.Position = UDim2.fromOffset(84, 26)
		resim.Size = UDim2.fromOffset(92, 100)
		resim.BackgroundTransparency = 1
		resim.ZIndex = 5
		resim.Parent = kart
		onizleme.ekle(resim, { name = entry.name, mutation = entry.mutation, revealed = true })

		local geri = UI.button(kart, "Return", UDim2.fromOffset(84, 30), YESIL)
		geri.Position = UDim2.fromOffset(8, SLOT_BOY - 38)
		geri.ZIndex = 7
		UI.stroke(geri, SIYAH, 2)
		local geriYazi = geri:FindFirstChild("Label", true)
		if geriYazi and geriYazi:IsA("TextLabel") then
			geriYazi.ZIndex = 8
		end
		geri.MouseButton1Click:Connect(function()
			FuseCikar:FireServer(entry.uid)
		end)
	else
		local bos = UI.text({
			text = "Empty",
			size = UI.Sizes.heading,
			font = UI.Fonts.bold,
			color = Color3.new(1, 1, 1),
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.new(1, 0, 0, 30),
			position = UDim2.fromOffset(0, 12),
			parent = kart,
		})
		bos.ZIndex = 6

		local ekle = UI.button(kart, "+", UDim2.fromOffset(120, 50), YESIL)
		ekle.AnchorPoint = Vector2.new(0.5, 0)
		ekle.Position = UDim2.new(0.5, 0, 0, 58)
		ekle.ZIndex = 7
		UI.stroke(ekle, SIYAH, 3)
		local arti = ekle:FindFirstChild("Label", true)
		if arti and arti:IsA("TextLabel") then
			arti.TextSize = 40
			arti.ZIndex = 8
		end
		ekle.MouseButton1Click:Connect(function()
			secim.Visible = true
		end)
	end
end

------------------------------------------------------------------
-- SECIM LISTESINI CIZ
------------------------------------------------------------------
local function secimCiz()
	secimOnizleme.temizle()
	for _, child in secimListe:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local items = durum.items or {}
	secimBaslik.Text = if durum.rarity
		then `Add another {Rarity.displayName(durum.rarity)} brainrot`
		else "Choose a Brainrot"

	if #items == 0 then
		local yok = UI.text({
			text = if durum.rarity
				then `You have no more {Rarity.displayName(durum.rarity)} brainrots to add.`
				else "No brainrots you can fuse. You need identified brainrots that are not on your base.",
			size = UI.Sizes.small,
			color = UI.Colors.textDim,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.new(1, -10, 0, 44),
			parent = secimListe,
			wrapped = true,
		})
		yok.ZIndex = 22
		return
	end

	for index, item in items do
		local renk = Rarity.color(item.rarity)
		local yeter = (item.owned or 0) + #(durum.slots or {}) >= (durum.required or Fuse.Required)
		-- Sunucu konamayacaklari sebebiyle birlikte kilitli yolluyor
		local kilit = if type(item.locked) == "string" then item.locked else nil

		local satir = Instance.new("TextButton")
		satir.Name = item.uid
		satir.Text = ""
		satir.AutoButtonColor = false
		satir.Size = UDim2.new(1, -8, 0, 62)
		satir.BackgroundColor3 = KART
		satir.BorderSizePixel = 0
		satir.LayoutOrder = index
		satir.ZIndex = 22
		satir.Parent = secimListe
		UI.corner(satir, 8)
		UI.stroke(satir, renk, 2)

		local resim = Instance.new("Frame")
		resim.Position = UDim2.fromOffset(6, 6)
		resim.Size = UDim2.fromOffset(50, 50)
		resim.BackgroundColor3 = renk:Lerp(SIYAH, 0.5)
		resim.BorderSizePixel = 0
		resim.ClipsDescendants = true
		resim.ZIndex = 22
		resim.Parent = satir
		UI.corner(resim, 6)
		secimOnizleme.ekle(resim, { name = item.name, mutation = item.mutation, revealed = true })

		local ad = UI.text({
			text = item.name,
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = Color3.new(1, 1, 1),
			frameSize = UDim2.new(1, -200, 0, 24),
			position = UDim2.fromOffset(66, 8),
			parent = satir,
		})
		ad.ZIndex = 23

		local alt = UI.text({
			text = if kilit then kilit else `{Rarity.displayName(item.rarity)}  -  {detayYazisi(item)}`,
			size = UI.Sizes.tiny,
			font = UI.Fonts.bold,
			color = if kilit then UI.Colors.textDim else renk,
			frameSize = UDim2.new(1, -200, 0, 18),
			position = UDim2.fromOffset(66, 34),
			parent = satir,
		})
		alt.ZIndex = 23

		-- Ayni isimden kac tane var: 3'e yetiyorsa yesil
		local adet = UI.text({
			text = if kilit then "LOCKED" else `x{item.owned or 1}`,
			size = UI.Sizes.heading,
			font = UI.Fonts.bold,
			color = if yeter then YESIL else UI.Colors.textDim,
			align = Enum.TextXAlignment.Right,
			frameSize = UDim2.fromOffset(110, 62),
			position = UDim2.new(1, -126, 0, 0),
			parent = satir,
		})
		adet.ZIndex = 23

		if kilit then
			-- Kilitli satir soluk durur ve tiklanmaz
			satir.BackgroundTransparency = 0.45
			ad.TextTransparency = 0.35
			resim.BackgroundTransparency = 0.5
			continue
		end

		satir.MouseButton1Click:Connect(function()
			FuseEkle:FireServer(item.uid)
		end)
		UI.hover(satir)
	end
end

------------------------------------------------------------------
-- PENCEREYI CIZ
------------------------------------------------------------------
local function pencereCiz()
	local slots = durum.slots or {}
	local gerekli = durum.required or Fuse.Required
	local sayi = #slots

	yonerge.Text = `Bring <font color="#FF4040">{gerekli}</font> Brainrots of the same tier`
	local sanslar = durum.chances or Fuse.Chances
	if durum.chance then
		sansYazi.Text = `{durum.chance}% chance for a better Brainrot!`
	else
		sansYazi.Text = `{sanslar.mixed}-{sanslar.same3}% chance  -  same brainrots = higher!`
	end

	-- Ayrintilar
	local simdiki = if durum.chance then `<font color="#46D250">{durum.chance}%</font>` else "-"
	sansBilgi.Text = table.concat({
		`<font color="#FFD629">SUCCESS CHANCE</font>`,
		`3 same brainrots: <b>{sanslar.same3}%</b>`,
		`Different brainrots: <b>{sanslar.mixed}%</b>`,
		`Now: <b>{simdiki}</b>`,
		`If it fails, the brainrots are lost.`,
	}, "\n")

	local mutSatirlari = {
		`<font color="#FFD629">MUTATION TRANSFER</font>`,
		`Each mutated brainrot: <b>{Fuse.Mutation.chancePerItem}%</b> to pass its mutation on`,
	}
	local mutasyonlar = durum.mutations or {}
	if #mutasyonlar == 0 then
		table.insert(mutSatirlari, "No mutated brainrots in the machine")
	else
		for _, m in mutasyonlar do
			local info = Mutations.get(m.id)
			table.insert(
				mutSatirlari,
				`<font color="#{info.color:ToHex()}">{info.displayName}</font> x{m.count}: <b>{m.chance}%</b>`
			)
		end
	end
	mutasyonBilgi.Text = table.concat(mutSatirlari, "\n")

	onizleme.temizle()
	for i = 1, gerekli do
		slotKur(i, slots[i])
	end

	-- Sonuc kutusu
	local sonraki = durum.nextRarity
	if sonraki then
		local renk = Rarity.color(sonraki)
		kutu.BackgroundColor3 = renk:Lerp(SIYAH, 0.35)
		kutuKontur.Color = renk
		kutuYazi.Text = `{Rarity.displayName(sonraki)} Brainrot`
		UI.rarityStyle(kutuYazi, sonraki)
		kutuSoru.Visible = true
		-- Siyah siluet: ne cikacagi belli degil
		onizleme.ekle(kutuResim, { revealed = false })
		uyari.Text = `If it fails, all {gerekli} brainrots are lost`
	else
		kutu.BackgroundColor3 = KART
		kutuKontur.Color = SIYAH
		kutuYazi.Text = "Result"
		UI.plainStyle(kutuYazi, UI.Colors.textDim)
		kutuSoru.Visible = true
		uyari.Text = ""
	end

	-- Alt dugme
	makineDolu = sayi >= gerekli
	local eksik = gerekli - sayi

	if fuseNabiz then
		fuseNabiz:Cancel()
		fuseNabiz = nil
		fuseOlcek.Scale = 1
	end

	if makineDolu then
		fuseYazi.Text = "FUSE!"
		fuseDugme.BackgroundColor3 = Color3.fromRGB(255, 190, 40)
		local nabiz = TweenService:Create(
			fuseOlcek,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Scale = 1.06 }
		)
		nabiz:Play()
		fuseNabiz = nabiz
	else
		fuseYazi.Text = `{eksik} Brainrot Left`
		fuseDugme.BackgroundColor3 = YESIL
	end

	if secim.Visible then
		-- Makine doldu: secim listesi kapanir, FUSE sayfasi gorunur
		if makineDolu then
			secim.Visible = false
		else
			secimCiz()
		end
	end
end

------------------------------------------------------------------
-- F: makinedeki hepsini geri al
------------------------------------------------------------------
local function bindTakeBack()
	ContextActionService:BindAction(TAKE_BACK, function(_, state)
		if state == Enum.UserInputState.Begin then
			FuseGeriAl:FireServer()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.F)
end

local function unbindTakeBack()
	ContextActionService:UnbindAction(TAKE_BACK)
end

FuseSecim.OnClientEvent:Connect(function()
	if merging then
		return
	end
	secim.Visible = false
	pencere.Visible = true
	pencereCiz()
end)

-- Pencere kapaninca secim listesi de kapansin, sahneler bosalsin
pencere:GetPropertyChangedSignal("Visible"):Connect(function()
	if not pencere.Visible then
		secim.Visible = false
		onizleme.temizle()
		sonImza = ""
	end
end)

secim:GetPropertyChangedSignal("Visible"):Connect(function()
	if secim.Visible then
		secimCiz()
	end
end)

--[[
	Sunucu menzildeyken 0.4 saniyede bir durum yolluyor. Her pakette bastan
	cizmek resimleri titretirdi; yalnizca ICERIK degistiyse cizilir.
]]
local function imzaOf(data: any): string
	local parcalar = { tostring(data.name), tostring(data.chance), tostring(data.fusing) }
	for _, s in data.slots or {} do
		table.insert(parcalar, s.uid)
	end
	table.insert(parcalar, "|")
	for _, it in data.items or {} do
		table.insert(parcalar, `{it.uid}:{it.owned}`)
	end
	return table.concat(parcalar, ",")
end

FuseDurum.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" or not data.near then
		if nearMachine then
			nearMachine = false
			unbindTakeBack()
			pencere.Visible = false
		end
		return
	end

	if not nearMachine then
		nearMachine = true
		bindTakeBack()
	end

	durum = data

	if merging then
		pencere.Visible = false
		return
	end

	local imza = imzaOf(data)
	if pencere.Visible and imza ~= sonImza then
		sonImza = imza
		pencereCiz()
	end
end)

------------------------------------------------------------------
-- 2. BIRLESME GOSTERISI
------------------------------------------------------------------
local M = Fuse.Merge

local SOUL_RADIUS = 130
local SOUL_SIZE = 38

local mergeRoot = Instance.new("Frame")
mergeRoot.Name = "BirlesmeGosterisi"
-- Merkezden ankorlu: arayuz olcegi (UIScale) sahneyi kaydirmasin
mergeRoot.AnchorPoint = Vector2.new(0.5, 0.5)
mergeRoot.Position = UDim2.fromScale(0.5, 0.5)
mergeRoot.Size = UDim2.fromScale(1, 1)
mergeRoot.BackgroundColor3 = SIYAH
mergeRoot.BackgroundTransparency = 1
mergeRoot.BorderSizePixel = 0
mergeRoot.Visible = false
mergeRoot.Active = false
mergeRoot.Parent = screen

local stage = Instance.new("Frame")
stage.Name = "Sahne"
stage.AnchorPoint = Vector2.new(0.5, 0.5)
stage.Position = UDim2.fromScale(0.5, 0.45)
stage.Size = UDim2.fromOffset(400, 400)
stage.BackgroundTransparency = 1
stage.Parent = mergeRoot

local mergeTitle = UI.text({
	text = "FUSING",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 30),
	position = UDim2.new(0, 0, 0.5, -200),
	parent = mergeRoot,
})

local mergeName = UI.text({
	text = "",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 36),
	position = UDim2.new(0, 0, 0.5, 130),
	parent = mergeRoot,
})

local mergeSub = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 22),
	position = UDim2.new(0, 0, 0.5, 170),
	parent = mergeRoot,
})

local function makeOrb(color: Color3, size: number): Frame
	local orb = Instance.new("Frame")
	orb.AnchorPoint = Vector2.new(0.5, 0.5)
	orb.Position = UDim2.fromScale(0.5, 0.5)
	orb.Size = UDim2.fromOffset(size, size)
	orb.BackgroundColor3 = color
	orb.BorderSizePixel = 0
	orb.Parent = stage

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = orb

	local halo = Instance.new("UIStroke")
	halo.Color = color:Lerp(Color3.new(1, 1, 1), 0.6)
	halo.Thickness = 3
	halo.Transparency = 0.2
	halo.Parent = orb

	return orb
end

local function clearStage()
	for _, child in stage:GetChildren() do
		child:Destroy()
	end
end

local function burstStars(color: Color3, count: number)
	for index = 1, count do
		local angle = (index - 1) / count * math.pi * 2 + math.random() * 0.4
		local distance = 90 + math.random() * 90
		local size = 10 + math.random() * 10

		local star = Instance.new("Frame")
		star.AnchorPoint = Vector2.new(0.5, 0.5)
		star.Position = UDim2.fromScale(0.5, 0.5)
		star.Size = UDim2.fromOffset(size, size)
		star.Rotation = 45
		star.BackgroundColor3 = if index % 2 == 0 then color else Color3.new(1, 1, 1)
		star.BorderSizePixel = 0
		star.Parent = stage

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 3)
		corner.Parent = star

		TweenService:Create(star, TweenInfo.new(M.burstTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(angle) * distance, 0.5, math.sin(angle) * distance),
			Size = UDim2.fromOffset(0, 0),
			Rotation = 45 + 180,
			BackgroundTransparency = 1,
		}):Play()
	end
end

local function shockwave(color: Color3)
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromOffset(40, 40)
	ring.BackgroundTransparency = 1
	ring.BorderSizePixel = 0
	ring.Parent = stage

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring

	local edge = Instance.new("UIStroke")
	edge.Color = color
	edge.Thickness = 6
	edge.Parent = ring

	local info = TweenInfo.new(M.burstTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, { Size = UDim2.fromOffset(340, 340) }):Play()
	TweenService:Create(edge, info, { Transparency = 1, Thickness = 0 }):Play()
end

-- Kamera sarsintisi: Roblox'un kamera guncellemesinden SONRA uygulanir
local SHAKE_NAME = "FuseSarsinti"
local shaking = false

-- Settings > Screen Shake kapaliysa sarsinti yok (nitelik Ayarlar'dan gelir)
local function sarsintiKapali(): boolean
	return game:GetService("Players").LocalPlayer:GetAttribute("SarsintiKapali") == true
end

local function shakeCamera(duration: number, strength: number)
	if shaking or sarsintiKapali() then
		return
	end
	shaking = true

	local elapsed = 0
	RunService:BindToRenderStep(SHAKE_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt)
		elapsed += dt
		local alpha = elapsed / duration
		if alpha >= 1 then
			RunService:UnbindFromRenderStep(SHAKE_NAME)
			shaking = false
			return
		end

		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end

		local power = strength * (1 - alpha) ^ 2
		camera.CFrame = camera.CFrame
			* CFrame.new((math.random() - 0.5) * power, (math.random() - 0.5) * power, 0)
			* CFrame.Angles(0, 0, (math.random() - 0.5) * power * 0.03)
	end)
end

-- Gosteride donen resimler (ruhlar ve sonuc)
local gosteriOnizleme = BrainrotOnizleme.seritPencere(stage)

-- Icinde brainrot resmi olan yuvarlak ruh
local function resimliRuh(renk: Color3, boy: number, kaynak: any?): Frame
	local ruh = makeOrb(renk, boy)
	ruh.BackgroundTransparency = 0.35
	if type(kaynak) == "table" and type(kaynak.name) == "string" then
		local resim = Instance.new("Frame")
		resim.Name = "Resim"
		resim.AnchorPoint = Vector2.new(0.5, 0.5)
		resim.Position = UDim2.fromScale(0.5, 0.5)
		resim.Size = UDim2.fromScale(1.25, 1.25)
		resim.BackgroundTransparency = 1
		resim.ZIndex = 3
		resim.Parent = ruh
		gosteriOnizleme.ekle(resim, { name = kaynak.name, mutation = kaynak.mutation, revealed = true })
	end
	return ruh
end

local function playMerge(data: any)
	if merging then
		return
	end
	merging = true
	pencere.Visible = false

	local fromColor = Rarity.color(data.fromRarity)
	local basari = data.success == true
	local toColor = if basari and data.toRarity then Rarity.color(data.toRarity) else Color3.fromRGB(90, 90, 100)
	local soulCount = math.clamp(tonumber(data.souls) or Fuse.Required, 2, 12)

	clearStage()
	mergeName.Text = ""
	mergeSub.Text = ""
	UI.plainStyle(mergeName, UI.Colors.text)
	Mutations.untag(mergeSub)

	mergeTitle.Text = `FUSING {string.upper(tostring(data.fromName or ""))}`
	if tonumber(data.chance) then
		mergeSub.Text = `{data.chance}% chance for a better brainrot...`
		mergeSub.TextColor3 = UI.Colors.textDim
	end
	UI.plainStyle(mergeTitle, fromColor)

	mergeRoot.Visible = true
	TweenService:Create(mergeRoot, TweenInfo.new(0.25), { BackgroundTransparency = 0.55 }):Play()

	-- 1. ASAMA: ruhlar donerek merkeze kapanir
	local souls: { Frame } = {}
	local kaynaklar = if type(data.sources) == "table" then data.sources else {}
	for index = 1, soulCount do
		souls[index] = resimliRuh(fromColor, SOUL_SIZE * 2, kaynaklar[index])
	end

	local elapsed = 0
	local spin: RBXScriptConnection
	spin = RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		local alpha = math.min(elapsed / M.gatherTime, 1)
		local eased = alpha * alpha * (3 - 2 * alpha)
		local radius = SOUL_RADIUS * (1 - eased)
		local turn = eased * math.pi * 3

		for index, soul in souls do
			if soul.Parent then
				local angle = (index - 1) / soulCount * math.pi * 2 + turn
				soul.Position = UDim2.new(0.5, math.cos(angle) * radius, 0.5, math.sin(angle) * radius)
				local size = SOUL_SIZE * 2 * (1 - eased * 0.6)
				soul.Size = UDim2.fromOffset(size, size)
				soul.Rotation = eased * 360
			end
		end

		if alpha >= 1 then
			spin:Disconnect()
		end
	end)

	task.wait(M.gatherTime)
	if spin.Connected then
		spin:Disconnect()
	end
	gosteriOnizleme.temizle()
	for _, soul in souls do
		soul:Destroy()
	end
	mergeSub.Text = ""

	-- 2. ASAMA: parlama
	local core = makeOrb(Color3.new(1, 1, 1), 24)
	TweenService:Create(core, TweenInfo.new(M.flashTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(120, 120),
		BackgroundColor3 = toColor,
	}):Play()

	task.wait(M.flashTime)

	-- 3. ASAMA: sonuc
	if basari then
		shakeCamera(M.shakeTime, M.shakeStrength)
		shockwave(toColor)
		burstStars(toColor, 18)

		TweenService:Create(core, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(170, 170),
			BackgroundTransparency = 0.45,
		}):Play()

		-- Kazanilan brainrotun resmi cekirdegin icinde belirir
		if type(data.name) == "string" then
			local sonuc = Instance.new("Frame")
			sonuc.Name = "Sonuc"
			sonuc.AnchorPoint = Vector2.new(0.5, 0.5)
			sonuc.Position = UDim2.fromScale(0.5, 0.5)
			sonuc.Size = UDim2.fromScale(1.2, 1.2)
			sonuc.BackgroundTransparency = 1
			sonuc.ZIndex = 3
			sonuc.Parent = core
			gosteriOnizleme.ekle(sonuc, { name = data.name, mutation = data.mutation, revealed = true })
		end

		-- Mutasyon ciktiysa ekranda buyuk yaziyla
		MutasyonGosterisi.goster(data.mutation, data.name)

		mergeTitle.Text = "FUSE SUCCESS!"
		UI.plainStyle(mergeTitle, YESIL)

		local mutationInfo = Mutations.get(data.mutation)
		mergeName.Text = mutationInfo.prefix .. tostring(data.name or "")
		UI.rarityStyle(mergeName, data.toRarity)

		local boyut = Condition.get(data.condition)
		mergeSub.Text =
			`{Rarity.displayName(data.toRarity)}  -  {boyut.shortName}  -  {Format.perSecond(tonumber(data.income) or 0)}  -  added to your inventory`
		mergeSub.TextColor3 = boyut.color
		if Mutations.isSpecial(data.mutation) then
			mergeSub.TextColor3 = mutationInfo.color
			Mutations.tagIf(mergeSub, data.mutation)
		end
	else
		-- Basarisizlik: cekirdek sonup kuculur, kirmizi yazi
		shakeCamera(0.3, 0.8)
		TweenService:Create(core, TweenInfo.new(M.burstTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Color3.fromRGB(40, 40, 45),
			BackgroundTransparency = 0.6,
		}):Play()

		mergeTitle.Text = "FUSE FAILED"
		UI.plainStyle(mergeTitle, KIRMIZI)
		mergeName.Text = "Better luck next time!"
		UI.plainStyle(mergeName, Color3.new(1, 1, 1))
		mergeSub.Text = `All {soulCount} brainrots were lost`
		mergeSub.TextColor3 = Color3.fromRGB(255, 120, 120)
	end

	task.wait(M.burstTime + M.holdTime)

	local fade = TweenService:Create(mergeRoot, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
	fade:Play()
	fade.Completed:Wait()

	gosteriOnizleme.temizle()
	clearStage()
	mergeRoot.Visible = false
	merging = false

	--[[
		Pencere yalnizca BASARILI birlestirmeden sonra geri acilir.
		Basarisizlikta esyalar yandi; pencerenin kendiliginden acilmasi
		"bir sey daha mi koyayim" baskisi yaratiyordu.
	]]
	if nearMachine and basari then
		pencere.Visible = true
		sonImza = ""
		pencereCiz()
	end
end

FuseSonuc.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" or type(data.fromRarity) ~= "string" then
		return
	end
	task.spawn(playMerge, data)
end)
