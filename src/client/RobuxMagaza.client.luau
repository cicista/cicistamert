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
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Icons = require(Shared:WaitForChild("Icons"))
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

-- Game Pass kartlarindaki ikonlar (Icons.Map kisa adi) ve renkleri
local GECIS_GORUNUM = {
	AutoClicker = { ikon = "shovel", renkA = Color3.fromRGB(255, 120, 60), renkB = Color3.fromRGB(230, 60, 110) },
	Teleporter = { ikon = "teleporter", renkA = Color3.fromRGB(150, 120, 255), renkB = Color3.fromRGB(80, 90, 230) },
}

local screen = Instance.new("ScreenGui")
screen.Name = "RobuxMagazasi"
--[[
	Ustteki XP bari (SeviyeArayuzu, DisplayOrder 0) panelin ustune binmesin.
	Katman sirasi: HUD 0 < menu panelleri 5 < Store / Index 10
	< mutasyon gosterisi 50 < hata ekrani 100.
]]
screen.DisplayOrder = 10
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

	UI.diamondGrid(frame)
	UI.gloss(frame, 0.8)

	for _, cocuk in frame:GetChildren() do
		if cocuk:IsA("Frame") and (cocuk.Name == "Desen" or cocuk.Name == "Parlaklik") then
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
	UI.stroke(buton, SIYAH, 2)

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
	ikon.Position = UDim2.new(0, 12, 0.5, 0)
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
local panel = UI.panel(screen, UDim2.fromOffset(640, 540), "RobuxMagaza")
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

local function oranSatiri(parent: Instance, tierId: string, y: number)
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

	local satir = Instance.new("Frame")
	satir.Name = "Oranlar"
	satir.BackgroundTransparency = 1
	satir.Position = UDim2.fromOffset(112, y)
	satir.Size = UDim2.new(1, -124, 0, 26)
	satir.Parent = parent

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

		local cip = Instance.new("Frame")
		cip.Name = rarityId
		cip.BackgroundColor3 = SIYAH
		cip.BackgroundTransparency = 0.45
		cip.BorderSizePixel = 0
		cip.Size = UDim2.fromOffset(0, 26)
		cip.AutomaticSize = Enum.AutomaticSize.X
		cip.LayoutOrder = siraNo
		cip.ZIndex = 5
		cip.Parent = satir
		UI.corner(cip, 8)
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

	yuzYazisi(yuz, `R$ {urun.fiyat}`, UI.Sizes.label, 2, 24)
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

	-- Yukseklik: baslik alani + (oranlar) + (dugme sirasi)
	local yukseklik = if coklu then 72 + (if oranli then 32 else 0) + 64 else 116

	local cerceve = Instance.new("Frame")
	cerceve.Name = kart.id
	cerceve.Size = UDim2.new(1, 0, 0, yukseklik)
	cerceve.BorderSizePixel = 0
	cerceve.LayoutOrder = sonraki()
	cerceve.Parent = liste
	UI.corner(cerceve, 12)
	UI.stroke(cerceve, SIYAH, 3)
	renkliZemin(cerceve, kart.renkA, kart.renkB, 12)

	local tier = if kart.tier then tierBul(kart.tier) else nil
	local ikon = kartIkonu(cerceve, kart.ikon, 88, if tier then tier.color else nil)

	-- Lucky Block ikonu hafifce sallanir
	if tier then
		TweenService:Create(
			ikon,
			TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Rotation = 6 }
		):Play()
		ikon.Rotation = -6
	end

	-- Tek urunlu kartta dugme sagda; yazi alani ona gore daralir
	local yaziEni = if coklu then UDim2.new(1, -124, 0, 32) else UDim2.new(1, -310, 0, 32)

	UI.text({
		text = kart.baslik,
		size = UI.Sizes.heading + 2,
		font = UI.Fonts.bold,
		frameSize = yaziEni,
		position = UDim2.fromOffset(112, if coklu then 8 else 22),
		parent = cerceve,
		zIndex = 5,
	})

	UI.text({
		text = kart.altBaslik,
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		frameSize = UDim2.new(yaziEni.X.Scale, yaziEni.X.Offset, 0, 22),
		position = UDim2.fromOffset(112, if coklu then 40 else 56),
		parent = cerceve,
		zIndex = 5,
	})

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
		oranSatiri(cerceve, kart.tier, 72)
	end

	local dugmeler = Instance.new("Frame")
	dugmeler.Name = "Dugmeler"
	dugmeler.BackgroundTransparency = 1
	dugmeler.AnchorPoint = Vector2.new(0, 1)
	dugmeler.Position = UDim2.new(0, 112, 1, -10)
	dugmeler.Size = UDim2.new(1, -124, 0, 56)
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
	UI.stroke(kart, SIYAH, 3)
	renkliZemin(kart, gorunum.renkA, gorunum.renkB, 12)

	local ikon = kartIkonu(kart, gorunum.ikon, 56)
	ikon.AnchorPoint = Vector2.zero
	ikon.Position = UDim2.fromOffset(10, 10)

	UI.text({
		text = info.ad,
		size = UI.Sizes.label,
		font = UI.Fonts.bold,
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
	urunKarti(kart)
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
-- SAG UST: STORE BUTONU
------------------------------------------------------------------
--[[
	Dis cerceve (tutucu) UI modulunun arayuz olcegini alir; fare etkisinin
	buyumesi ise icteki butonda. Ikisi ayni nesnede olsaydi UI modulu
	olcegi koymuyordu (bir nesnede iki UIScale olmaz).
]]
local tutucu = Instance.new("Frame")
tutucu.Name = "StoreButonu"
tutucu.AnchorPoint = Vector2.new(1, 0)
tutucu.Position = UDim2.new(1, -16, 0, 10)
tutucu.Size = UDim2.fromOffset(150, 58 + LIP)
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
storeIkon.Position = UDim2.new(0, 4, 0.5, 0)
storeIkon.Size = UDim2.fromOffset(46, 46)
storeIkon.ScaleType = Enum.ScaleType.Fit
storeIkon.ZIndex = 5
storeIkon.Parent = storeYuz
--[[
	Yazi butonun TAM ORTASINDA baslar. Magaza ikonu bulunursa solda ikona
	yer acilir ve yazi kalan alanda ortalanir; ikon yoksa (paket gelmediyse)
	solda bos yer kalip yazi saga yaslanmis gorunmesin.
]]
local storeYazi = UI.text({
	text = "STORE",
	size = UI.Sizes.heading + 2,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = storeYuz,
	zIndex = 5,
})

storeIkon.Visible = false
Icons.bind(storeIkon, "shop", function(ok)
	if ok then
		storeIkon.Visible = true
		storeYazi.Size = UDim2.new(1, -52, 1, 0)
		storeYazi.Position = UDim2.fromOffset(50, 0)
	end
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
