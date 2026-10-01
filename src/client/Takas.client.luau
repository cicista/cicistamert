--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("Takas"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Condition = require(Shared:WaitForChild("Condition"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))
local BrainrotOnizleme = require(script.Parent:WaitForChild("BrainrotOnizleme"))
local LuckyOnizleme = require(script.Parent:WaitForChild("LuckyOnizleme"))
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

local TakasIslem = Net.event("TakasIslem")
local TakasDurum = Net.event("TakasDurum")

local BEYAZ = Color3.new(1, 1, 1)
local SIYAH = Color3.new(0, 0, 0)
local YESIL = Color3.fromRGB(70, 205, 85)
local KIRMIZI = Color3.fromRGB(225, 75, 75)
local GRI = Color3.fromRGB(110, 115, 130)
local TURKUAZ = Color3.fromRGB(40, 200, 220)
local MAVI = Color3.fromRGB(70, 110, 255)
local KOYU = Color3.fromRGB(26, 25, 38)

local KART_EN = 80
local KART_BOY = 114

local screen = Instance.new("ScreenGui")
screen.Name = "Takas"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.DisplayOrder = 8
screen.Parent = playerGui

local panel = UI.panel(screen, UDim2.fromOffset(840, 660), "Takas")
local kapatDugme = UI.closeButton(panel)
UI.baslikCubugu(panel, "Trade", TURKUAZ, MAVI, "trade")

local function seviyeOf(oyuncu: Player): number
	local stats = oyuncu:FindFirstChild("leaderstats")
	local deger = stats and stats:FindFirstChild("Level")
	return if deger and deger:IsA("IntValue") then deger.Value else 0
end

local function bolum(ad: string): Frame
	local f = Instance.new("Frame")
	f.Name = ad
	f.Position = UDim2.fromOffset(16, 72)
	f.Size = UDim2.new(1, -32, 1, -88)
	f.BackgroundTransparency = 1
	f.Visible = false
	f.Parent = panel
	return f
end

local lobi = bolum("Lobi")
local oturumAlani = bolum("Oturum")

local kilitYazi = UI.text({
	text = "",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 80),
	position = UDim2.new(0, 0, 0.5, -40),
	parent = lobi,
	wrapped = true,
})

local lobiBaslik = UI.text({
	text = "Pick a player to trade with",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	frameSize = UDim2.new(1, 0, 0, 28),
	parent = lobi,
})

local oyuncuListesi = Instance.new("ScrollingFrame")
oyuncuListesi.Name = "Oyuncular"
oyuncuListesi.Position = UDim2.fromOffset(0, 36)
oyuncuListesi.Size = UDim2.new(1, 0, 1, -36)
oyuncuListesi.BackgroundTransparency = 1
oyuncuListesi.BorderSizePixel = 0
oyuncuListesi.ScrollBarThickness = 6
oyuncuListesi.CanvasSize = UDim2.new()
oyuncuListesi.AutomaticCanvasSize = Enum.AutomaticSize.Y
oyuncuListesi.Parent = lobi
UI.listePayi(oyuncuListesi)
do
	local d = Instance.new("UIListLayout")
	d.Padding = UDim.new(0, 8)
	d.SortOrder = Enum.SortOrder.LayoutOrder
	d.Parent = oyuncuListesi
end

local gonderilenler: { [number]: number } = {}

local function lobiCiz()
	for _, c in oyuncuListesi:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end

	local benimSeviye = seviyeOf(player)
	local kilitli = benimSeviye < Ayar.GerekenSeviye
	kilitYazi.Visible = kilitli
	kilitYazi.Text = `Trading unlocks at Level {Ayar.GerekenSeviye}\n(you are Level {benimSeviye})`
	lobiBaslik.Visible = not kilitli
	oyuncuListesi.Visible = not kilitli
	if kilitli then
		return
	end

	local digerleri = {}
	for _, oyuncu in Players:GetPlayers() do
		if oyuncu ~= player then
			table.insert(digerleri, oyuncu)
		end
	end

	if #digerleri == 0 then
		UI.text({
			text = "No other players in this server yet.",
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = UI.Colors.textDim,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.new(1, -10, 0, 40),
			parent = oyuncuListesi,
		})
		return
	end

	for sira, oyuncu in digerleri do
		local satir = Instance.new("Frame")
		satir.Name = oyuncu.Name
		satir.LayoutOrder = sira
		satir.Size = UDim2.new(1, -8, 0, 64)
		satir.BackgroundColor3 = KOYU
		satir.BorderSizePixel = 0
		satir.Parent = oyuncuListesi
		UI.corner(satir, 10)
		UI.stroke(satir, SIYAH, 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local avatar = Instance.new("ImageLabel")
		avatar.Position = UDim2.fromOffset(8, 6)
		avatar.Size = UDim2.fromOffset(52, 52)
		avatar.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		avatar.Parent = satir
		UI.corner(avatar, 26)
		task.spawn(function()
			local ok, resim = pcall(function()
				return Players:GetUserThumbnailAsync(oyuncu.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			end)
			if ok and avatar.Parent then
				avatar.Image = resim
			end
		end)

		local seviye = seviyeOf(oyuncu)
		UI.text({
			text = oyuncu.DisplayName,
			size = UI.Sizes.label,
			font = UI.Fonts.bold,
			frameSize = UDim2.new(1, -260, 0, 28),
			position = UDim2.fromOffset(70, 6),
			parent = satir,
		})
		UI.text({
			text = `Lv. {seviye}`,
			size = UI.Sizes.small,
			font = UI.Fonts.bold,
			color = Color3.fromRGB(255, 215, 40),
			frameSize = UDim2.fromOffset(120, 22),
			position = UDim2.fromOffset(70, 34),
			parent = satir,
		})

		local uygun = seviye >= Ayar.GerekenSeviye
		local gonderildi = (gonderilenler[oyuncu.UserId] or 0) > os.clock()
		local yazi = if not uygun then `LV {Ayar.GerekenSeviye} NEEDED` elseif gonderildi then "SENT!" else "SEND REQUEST"
		local dugme = UI.dugme3B(satir, yazi, UDim2.fromOffset(170, 44), if uygun and not gonderildi then YESIL else GRI, false)
		dugme.AnchorPoint = Vector2.new(1, 0.5)
		dugme.Position = UDim2.new(1, -10, 0.5, 0)
		local hedefId = oyuncu.UserId
		dugme.MouseButton1Click:Connect(function()
			if not uygun or (gonderilenler[hedefId] or 0) > os.clock() then
				return
			end
			TakasIslem:FireServer({ tur = "gonder", hedef = hedefId })
		end)
	end
end

local function baslik(parent: Instance, yazi: string, x: UDim, y: number, en: UDim): TextLabel
	return UI.text({
		text = yazi,
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		frameSize = UDim2.new(en.Scale, en.Offset, 0, 24),
		position = UDim2.new(x.Scale, x.Offset, 0, y),
		parent = parent,
	})
end

local function teklifKutusu(ad: string, x: number): (Frame, ScrollingFrame, TextLabel)
	local kutu = Instance.new("Frame")
	kutu.Name = ad
	kutu.Position = UDim2.new(x, if x > 0 then 6 else 0, 0, 28)
	kutu.Size = UDim2.new(0.5, -6, 0, 262)
	kutu.BackgroundColor3 = KOYU
	kutu.BorderSizePixel = 0
	kutu.Parent = oturumAlani
	UI.corner(kutu, 12)
	local cizgi = UI.stroke(kutu, GRI, 3)
	cizgi.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local izgara = Instance.new("ScrollingFrame")
	izgara.Name = "Izgara"
	izgara.Position = UDim2.fromOffset(8, 8)
	izgara.Size = UDim2.new(1, -12, 1, -16)
	izgara.BackgroundTransparency = 1
	izgara.BorderSizePixel = 0
	izgara.ScrollBarThickness = 5
	izgara.CanvasSize = UDim2.new()
	izgara.AutomaticCanvasSize = Enum.AutomaticSize.Y
	izgara.Parent = kutu
	local g = Instance.new("UIGridLayout")
	g.CellSize = UDim2.fromOffset(KART_EN, KART_BOY)
	g.CellPadding = UDim2.fromOffset(6, 6)
	g.SortOrder = Enum.SortOrder.LayoutOrder
	g.Parent = izgara

	local durum = UI.text({
		text = "NOT READY",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		align = Enum.TextXAlignment.Right,
		frameSize = UDim2.new(0.5, -10, 0, 24),
		position = UDim2.new(x, if x > 0 then 6 else 0, 0, 0),
		parent = oturumAlani,
	})
	durum.Position = UDim2.new(x + 0.5, -10 - (if x > 0 then 0 else 6), 0, 0)
	durum.AnchorPoint = Vector2.new(1, 0)

	return kutu, izgara, durum
end

local benimBaslik = baslik(oturumAlani, "YOUR OFFER", UDim.new(0, 0), 0, UDim.new(0.5, -110))
local onunBaslik = baslik(oturumAlani, "THEIR OFFER", UDim.new(0.5, 6), 0, UDim.new(0.5, -110))
local benimKutu, benimIzgara, benimDurum = teklifKutusu("Benim", 0)
local onunKutu, onunIzgara, onunDurum = teklifKutusu("Onun", 0.5)

baslik(oturumAlani, "YOUR BACKPACK", UDim.new(0, 0), 298, UDim.new(0, 160)).TextColor3 = UI.Colors.textDim

local filtre = "hepsi"
local sonVeri: any = nil
local filtreDugmeleri: { [string]: TextButton } = {}
local envanterCiz: (veri: any) -> ()

do
	local sekmeler = Instance.new("Frame")
	sekmeler.Name = "Filtreler"
	sekmeler.AnchorPoint = Vector2.new(1, 0)
	sekmeler.Position = UDim2.new(1, 0, 0, 296)
	sekmeler.Size = UDim2.fromOffset(420, 26)
	sekmeler.BackgroundTransparency = 1
	sekmeler.Parent = oturumAlani
	local d = Instance.new("UIListLayout")
	d.FillDirection = Enum.FillDirection.Horizontal
	d.HorizontalAlignment = Enum.HorizontalAlignment.Right
	d.Padding = UDim.new(0, 6)
	d.SortOrder = Enum.SortOrder.LayoutOrder
	d.Parent = sekmeler

	for sira, satir in { { "hepsi", "ALL" }, { "pet", "PETS" }, { "blok", "BLOCKS" } } do
		local anahtar, yazi = satir[1], satir[2]
		local dugme = Instance.new("TextButton")
		dugme.Name = anahtar
		dugme.LayoutOrder = sira
		dugme.Size = UDim2.fromOffset(98, 26)
		dugme.AutoButtonColor = false
		dugme.BackgroundColor3 = KOYU
		dugme.BorderSizePixel = 0
		dugme.Text = ""
		dugme.Parent = sekmeler
		UI.corner(dugme, 8)
		UI.stroke(dugme, SIYAH, 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		UI.text({
			text = yazi,
			size = UI.Sizes.tiny,
			font = UI.Fonts.bold,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.fromScale(1, 1),
			parent = dugme,
			zIndex = 2,
		})
		filtreDugmeleri[anahtar] = dugme
		dugme.MouseButton1Click:Connect(function()
			filtre = anahtar
			for ad, d2 in filtreDugmeleri do
				d2.BackgroundColor3 = if ad == filtre then TURKUAZ:Lerp(SIYAH, 0.3) else KOYU
			end
			if sonVeri then
				envanterCiz(sonVeri)
			end
		end)
	end
	filtreDugmeleri.hepsi.BackgroundColor3 = TURKUAZ:Lerp(SIYAH, 0.3)
end

local envanterListe = Instance.new("ScrollingFrame")
envanterListe.Name = "Envanter"
envanterListe.Position = UDim2.fromOffset(0, 324)
envanterListe.Size = UDim2.new(1, 0, 0, 184)
envanterListe.BackgroundColor3 = Color3.fromRGB(18, 17, 26)
envanterListe.BorderSizePixel = 0
envanterListe.ScrollBarThickness = 6
envanterListe.CanvasSize = UDim2.new()
envanterListe.AutomaticCanvasSize = Enum.AutomaticSize.Y
envanterListe.Parent = oturumAlani
UI.corner(envanterListe, 10)
UI.listePayi(envanterListe, 6)
do
	local g = Instance.new("UIGridLayout")
	g.CellSize = UDim2.fromOffset(KART_EN, KART_BOY)
	g.CellPadding = UDim2.fromOffset(6, 6)
	g.SortOrder = Enum.SortOrder.LayoutOrder
	g.Parent = envanterListe
end

local kabulDugme, _, kabulYazi = UI.dugme3B(oturumAlani, "ACCEPT", UDim2.fromOffset(220, 56), YESIL, false)
kabulDugme.AnchorPoint = Vector2.new(0.5, 1)
kabulDugme.Position = UDim2.new(0.5, -120, 1, 0)

local iptalDugme = UI.dugme3B(oturumAlani, "CANCEL", UDim2.fromOffset(180, 56), KIRMIZI, false)
iptalDugme.AnchorPoint = Vector2.new(0.5, 1)
iptalDugme.Position = UDim2.new(0.5, 120, 1, 0)

local benimOnizleme = BrainrotOnizleme.seritPencere(benimKutu)
local onunOnizleme = BrainrotOnizleme.seritPencere(onunKutu)
local envanterOnizleme = BrainrotOnizleme.pencere(envanterListe, panel)

local function gelirOf(bilgi: any): number
	if not (bilgi.revealed and bilgi.name) then
		return 0
	end
	local ok, gelir = pcall(Brainrots.income, bilgi.name, bilgi.condition, bilgi.mutation)
	return if ok and type(gelir) == "number" then gelir else 0
end

local function kartKur(parent: Instance, sira: number, onizleme: any, bilgi: any, blok: string?, adet: number?, tikla: (() -> ())?)
	local renk = if blok then LuckyBlock.get(blok).color else Rarity.color(bilgi.rarity)

	local kart = Instance.new("TextButton")
	kart.Name = "Kart"
	kart.Text = ""
	kart.AutoButtonColor = false
	kart.LayoutOrder = sira
	kart.BackgroundColor3 = renk:Lerp(SIYAH, 0.72)
	kart.BorderSizePixel = 0
	kart.Parent = parent
	UI.corner(kart, 8)
	local cizgi = UI.stroke(kart, renk, 2)
	cizgi.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local resim = Instance.new("Frame")
	resim.Name = "Resim"
	resim.Position = UDim2.fromOffset(4, 4)
	resim.Size = UDim2.new(1, -8, 0, 50)
	resim.BackgroundTransparency = 1
	resim.ZIndex = 2
	resim.Parent = kart

	local function satir(metin: string, y: number, boyut: number, satirRengi: Color3, zengin: boolean?): TextLabel
		local etiket = UI.text({
			text = metin,
			size = boyut,
			font = UI.Fonts.bold,
			color = satirRengi,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.new(1, -4, 0, 14),
			position = UDim2.fromOffset(2, y),
			parent = kart,
			zIndex = 4,
		})
		etiket.TextTruncate = Enum.TextTruncate.AtEnd
		if zengin then
			etiket.RichText = true
		end
		return etiket
	end

	if blok then
		local tier = LuckyBlock.get(blok)
		LuckyOnizleme.ekle(resim, blok, 3)
		satir(tier.displayName, 56, 11, BEYAZ)
		satir("LUCKY BLOCK", 70, 10, renk)
		satir(`x{adet or 1}`, 86, 18, BEYAZ)
	else
		local acik = bilgi.revealed == true and bilgi.name ~= nil
		onizleme.ekle(resim, {
			name = bilgi.name,
			mutation = bilgi.mutation,
			revealed = acik,
			rarity = bilgi.rarity,
		})

		satir(if acik then bilgi.name else `{Rarity.displayName(bilgi.rarity)} Egg`, 55, 11, BEYAZ)
		satir(Rarity.displayName(bilgi.rarity), 68, 10, Rarity.textColor(bilgi.rarity))
		satir(
			if acik then Format.perSecond(gelirOf(bilgi)) else "?/s",
			81,
			12,
			Color3.fromRGB(110, 255, 140)
		)

		local kosul = Condition.get(bilgi.condition)
		local parcalar = { `<font color="#{kosul.color:ToHex()}">{kosul.shortName}</font>` }
		if Mutations.isSpecial(bilgi.mutation) then
			table.insert(
				parcalar,
				`<font color="#{Mutations.color(bilgi.mutation):ToHex()}">{Mutations.get(bilgi.mutation).displayName}</font>`
			)
		end
		satir(table.concat(parcalar, " "), 96, 10, BEYAZ, true)
	end

	if tikla then
		kart.MouseButton1Click:Connect(tikla)
		UI.hover(kart)
	end
	return kart
end

local function temizle(kap: Instance)
	for _, c in kap:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function teklifCiz(izgara: GuiObject, onizleme: any, teklif: any, benim: boolean): (number, boolean)
	onizleme.temizle()
	temizle(izgara)
	local sira = 0
	local toplam = 0
	local bilinmeyen = false
	for _, bilgi in teklif.esyalar or {} do
		sira += 1
		toplam += gelirOf(bilgi)
		if not (bilgi.revealed and bilgi.name) then
			bilinmeyen = true
		end
		local uid = bilgi.uid
		kartKur(izgara, sira, onizleme, bilgi, nil, nil, if benim
			then function()
				TakasIslem:FireServer({ tur = "cikar", uid = uid })
			end
			else nil)
	end
	for _, tier in LuckyBlock.Tiers do
		local adet = (teklif.bloklar or {})[tier.id]
		if adet and adet > 0 then
			sira += 1
			local tierId = tier.id
			kartKur(izgara, sira, onizleme, nil, tierId, adet, if benim
				then function()
					TakasIslem:FireServer({ tur = "blok", tier = tierId, adet = -1 })
				end
				else nil)
		end
	end
	return toplam, bilinmeyen
end

local function baslikYazisi(etiket: TextLabel, ad: string, toplam: number, bilinmeyen: boolean)
	etiket.RichText = true
	etiket.Text = `{ad}  <font color="#6EFF8C">{Format.perSecond(toplam)}</font>{if bilinmeyen then " +?" else ""}`
end

function envanterCiz(veri: any)
	sonVeri = veri
	envanterOnizleme.temizle()
	temizle(envanterListe)
	local sira = 0
	if filtre == "hepsi" or filtre == "blok" then
		for _, tier in LuckyBlock.Tiers do
			local adet = (veri.bloklarim or {})[tier.id]
			if adet and adet > 0 then
				sira += 1
				local tierId = tier.id
				kartKur(envanterListe, sira, envanterOnizleme, nil, tierId, adet, function()
					TakasIslem:FireServer({ tur = "blok", tier = tierId, adet = 1 })
				end)
			end
		end
	end

	local liste = if filtre == "blok" then {} else table.clone(veri.envanter or {})
	table.sort(liste, function(a, b)
		local ra = Rarity.Info[a.rarity]
		local rb = Rarity.Info[b.rarity]
		local oa = if ra then ra.order else 0
		local ob = if rb then rb.order else 0
		if oa ~= ob then
			return oa > ob
		end
		return tostring(a.name) < tostring(b.name)
	end)

	for _, bilgi in liste do
		sira += 1
		local uid = bilgi.uid
		kartKur(envanterListe, sira, envanterOnizleme, bilgi, nil, nil, function()
			TakasIslem:FireServer({ tur = "ekle", uid = uid })
		end)
	end

	if sira == 0 then
		local bos = UI.text({
			text = if filtre == "pet"
				then "No pets in your backpack"
				elseif filtre == "blok" then "No Lucky Blocks"
				else "Nothing to trade",
			size = UI.Sizes.tiny,
			font = UI.Fonts.bold,
			color = UI.Colors.textDim,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.fromOffset(KART_EN, KART_BOY),
			parent = envanterListe,
			wrapped = true,
		})
		bos.LayoutOrder = 1
	end
end

local sayacKatmani = Instance.new("Frame")
sayacKatmani.Name = "GeriSayim"
sayacKatmani.AnchorPoint = Vector2.new(0.5, 0.5)
sayacKatmani.Position = UDim2.fromScale(0.5, 0.42)
sayacKatmani.Size = UDim2.fromOffset(260, 260)
sayacKatmani.BackgroundTransparency = 1
sayacKatmani.Visible = false
sayacKatmani.ZIndex = 20
sayacKatmani.Parent = panel

local sayacHuzme = UI.isikHuzmeleri(sayacKatmani, Color3.fromRGB(120, 255, 160), {
	sayi = 12,
	uzunluk = 200,
	kalinlik = 26,
	tur = 12,
	parlaklik = 0.25,
	zIndex = 20,
})
sayacHuzme.Position = UDim2.fromScale(0.5, 0.5)
UI.parlama(sayacKatmani, Color3.fromRGB(120, 255, 160), 230, 21)

UI.text({
	text = "TRADING IN",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	glow = Color3.fromRGB(120, 255, 160),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 36),
	position = UDim2.fromOffset(0, 50),
	parent = sayacKatmani,
	zIndex = 22,
})

local sayacYazi = UI.text({
	text = "5",
	size = 96,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 110),
	position = UDim2.fromOffset(0, 90),
	parent = sayacKatmani,
	zIndex = 22,
})
local sayacOlcek = Instance.new("UIScale")
sayacOlcek.Parent = sayacYazi

local geriSayimBitis: number? = nil
local sonSaniye = -1
local oturumda = false
local benimKabul = false

RunService.Heartbeat:Connect(function()
	local bitis = geriSayimBitis
	if not bitis or not sayacKatmani.Visible then
		return
	end
	local kalan = math.max(0, bitis - os.clock())
	local saniye = math.ceil(kalan)
	sayacHuzme.Rotation = (os.clock() * 60) % 360
	if saniye ~= sonSaniye then
		sonSaniye = saniye
		sayacYazi.Text = tostring(math.max(1, saniye))
		sayacYazi.TextColor3 = Color3.fromRGB(120, 255, 160):Lerp(BEYAZ, saniye / Ayar.GeriSayim)
		sayacOlcek.Scale = 1.6
		TweenService:Create(sayacOlcek, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		YerelSes.cal("Cartoon bubble button Sound")
	end
end)

local function modGoster(oturum: boolean)
	oturumda = oturum
	lobi.Visible = not oturum
	oturumAlani.Visible = oturum
	if not oturum then
		sayacKatmani.Visible = false
		geriSayimBitis = nil
		benimOnizleme.temizle()
		onunOnizleme.temizle()
		envanterOnizleme.temizle()
		lobiCiz()
	end
end

local function oturumCiz(veri: any)
	modGoster(true)
	panel.Visible = true

	local karsiAd = if type(veri.karsi) == "table" then tostring(veri.karsi.ad) else "?"
	local benimToplam, benimBilinmeyen = teklifCiz(benimIzgara, benimOnizleme, veri.benim or {}, true)
	local onunToplam, onunBilinmeyen = teklifCiz(onunIzgara, onunOnizleme, veri.onun or {}, false)
	baslikYazisi(benimBaslik, "YOUR OFFER", benimToplam, benimBilinmeyen)
	baslikYazisi(onunBaslik, `{string.upper(karsiAd)}'S OFFER`, onunToplam, onunBilinmeyen)
	envanterCiz(veri)

	benimKabul = veri.benimKabul == true
	local onunKabul = veri.onunKabul == true
	benimDurum.Text = if benimKabul then "READY!" else "NOT READY"
	benimDurum.TextColor3 = if benimKabul then YESIL else UI.Colors.textDim
	onunDurum.Text = if onunKabul then "READY!" else "NOT READY"
	onunDurum.TextColor3 = if onunKabul then YESIL else UI.Colors.textDim

	local bk = benimKutu:FindFirstChildOfClass("UIStroke")
	if bk then
		bk.Color = if benimKabul then YESIL else GRI
	end
	local ok = onunKutu:FindFirstChildOfClass("UIStroke")
	if ok then
		ok.Color = if onunKabul then YESIL else GRI
	end

	if kabulYazi then
		kabulYazi.Text = if benimKabul then "UNREADY" else "ACCEPT"
	end
	UI.dugme3BRenk(kabulDugme, if benimKabul then Color3.fromRGB(230, 170, 40) else YESIL)

	local kalan = tonumber(veri.geriSayim)
	if kalan and kalan > 0 then
		geriSayimBitis = os.clock() + kalan
		sonSaniye = -1
		sayacKatmani.Visible = true
	else
		geriSayimBitis = nil
		sayacKatmani.Visible = false
	end
end

kabulDugme.MouseButton1Click:Connect(function()
	TakasIslem:FireServer({ tur = "kabul", deger = not benimKabul })
end)

iptalDugme.MouseButton1Click:Connect(function()
	TakasIslem:FireServer({ tur = "iptal" })
end)

kapatDugme.MouseButton1Click:Connect(function()
	if oturumda then
		TakasIslem:FireServer({ tur = "iptal" })
	end
	panel.Visible = false
end)

panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then
		if not oturumda then
			modGoster(false)
		end
	elseif oturumda then
		TakasIslem:FireServer({ tur = "iptal" })
	end
end)

local istekKatmani = Instance.new("ScreenGui")
istekKatmani.Name = "TakasIstegi"
istekKatmani.ResetOnSpawn = false
istekKatmani.DisplayOrder = 40
istekKatmani.Parent = playerGui

local function istekGoster(veri: any)
	local gonderen = tonumber(veri.gonderen)
	if not gonderen then
		return
	end
	local sure = tonumber(veri.sure) or Ayar.IstekSuresi

	local kutu = Instance.new("Frame")
	kutu.Name = "Istek"
	kutu.AnchorPoint = Vector2.new(0.5, 0)
	kutu.Position = UDim2.new(0.5, 0, 0, -140)
	kutu.Size = UDim2.fromOffset(440, 124)
	kutu.BackgroundColor3 = BEYAZ
	kutu.BorderSizePixel = 0
	kutu.Parent = istekKatmani
	UI.corner(kutu, 14)
	UI.stroke(kutu, SIYAH, 3).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local zemin = Instance.new("UIGradient")
	zemin.Rotation = 90
	zemin.Color = ColorSequence.new(Color3.fromRGB(30, 120, 170), Color3.fromRGB(20, 50, 110))
	zemin.Parent = kutu
	UI.caprazDesen(kutu, BEYAZ, 6)

	UI.text({
		text = `{string.upper(tostring(veri.ad))} WANTS TO TRADE!`,
		size = UI.Sizes.label,
		font = UI.Fonts.bold,
		glow = TURKUAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -20, 0, 30),
		position = UDim2.fromOffset(10, 10),
		parent = kutu,
		zIndex = 3,
	})

	local evet = UI.dugme3B(kutu, "ACCEPT", UDim2.fromOffset(170, 46), YESIL, false)
	evet.Position = UDim2.fromOffset(40, 46)
	local hayir = UI.dugme3B(kutu, "DECLINE", UDim2.fromOffset(170, 46), KIRMIZI, false)
	hayir.Position = UDim2.new(1, -210, 0, 46)

	local cubuk = Instance.new("Frame")
	cubuk.Name = "Sure"
	cubuk.AnchorPoint = Vector2.new(0, 1)
	cubuk.Position = UDim2.new(0, 12, 1, -8)
	cubuk.Size = UDim2.new(1, -24, 0, 8)
	cubuk.BackgroundColor3 = TURKUAZ
	cubuk.BorderSizePixel = 0
	cubuk.ZIndex = 3
	cubuk.Parent = kutu
	UI.corner(cubuk, 4)

	YerelSes.cal("Teleport")
	TweenService:Create(kutu, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, 70) }):Play()
	TweenService:Create(cubuk, TweenInfo.new(sure, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 8) }):Play()

	local kapandi = false
	local function kapan(kabul: boolean?)
		if kapandi then
			return
		end
		kapandi = true
		if kabul ~= nil then
			TakasIslem:FireServer({ tur = "yanit", gonderen = gonderen, kabul = kabul })
		end
		local t = TweenService:Create(kutu, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, -140),
		})
		t:Play()
		t.Completed:Wait()
		kutu:Destroy()
	end

	evet.MouseButton1Click:Connect(function()
		kapan(true)
	end)
	hayir.MouseButton1Click:Connect(function()
		kapan(false)
	end)
	task.delay(sure, function()
		kapan(nil)
	end)
end

local function sonucGoster(basarili: boolean, mesaj: string?)
	local renk = if basarili then Color3.fromRGB(120, 255, 160) else Color3.fromRGB(255, 120, 120)
	local dis = Instance.new("Frame")
	dis.Name = "Sonuc"
	dis.AnchorPoint = Vector2.new(0.5, 0.5)
	dis.Position = UDim2.fromScale(0.5, 0.4)
	dis.Size = UDim2.fromOffset(520, 200)
	dis.BackgroundTransparency = 1
	dis.Parent = istekKatmani
	local kap = Instance.new("Frame")
	kap.AnchorPoint = Vector2.new(0.5, 0.5)
	kap.Position = UDim2.fromScale(0.5, 0.5)
	kap.Size = UDim2.fromScale(1, 1)
	kap.BackgroundTransparency = 1
	kap.Parent = dis
	local olcek = Instance.new("UIScale")
	olcek.Scale = 0.2
	olcek.Parent = kap

	if basarili then
		UI.isikHuzmeleri(kap, renk, { sayi = 12, uzunluk = 240, kalinlik = 30, tur = 14, parlaklik = 0.2, zIndex = 1 }).Position =
			UDim2.fromScale(0.5, 0.5)
		UI.pariltilar(kap, renk, 16, 2)
		YerelSes.cal("LuckyBlock")
	end

	UI.text({
		text = if basarili then "TRADE COMPLETE!" else "TRADE CANCELLED",
		size = 46,
		font = UI.Fonts.bold,
		glow = renk,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 56),
		position = UDim2.fromOffset(0, 50),
		parent = kap,
		zIndex = 4,
	})
	UI.text({
		text = mesaj or (if basarili then "Check your backpack!" else ""),
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 26),
		position = UDim2.fromOffset(0, 110),
		parent = kap,
		zIndex = 4,
	})

	TweenService:Create(olcek, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(2.6, function()
		local t = TweenService:Create(olcek, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 })
		t:Play()
		t.Completed:Wait()
		dis:Destroy()
	end)
end

TakasDurum.OnClientEvent:Connect(function(veri)
	if type(veri) ~= "table" then
		return
	end

	if veri.tur == "istek" then
		istekGoster(veri)
	elseif veri.tur == "gonderildi" then
		local hedef = tonumber(veri.hedef)
		if hedef then
			gonderilenler[hedef] = os.clock() + Ayar.IstekSuresi
			if panel.Visible and not oturumda then
				lobiCiz()
			end
		end
	elseif veri.tur == "oturum" then
		oturumCiz(veri)
	elseif veri.tur == "bitti" then
		local acikti = oturumda
		oturumda = false
		modGoster(false)
		if acikti then
			panel.Visible = false
		end
		sonucGoster(veri.basarili == true, if type(veri.mesaj) == "string" then veri.mesaj else nil)
	end
end)

Players.PlayerAdded:Connect(function()
	if panel.Visible and not oturumda then
		lobiCiz()
	end
end)
Players.PlayerRemoving:Connect(function()
	if panel.Visible and not oturumda then
		task.defer(lobiCiz)
	end
end)

task.spawn(function()
	UI.sagMenuyeEkle("trade", "Trade", TURKUAZ, function()
		panel.Visible = not panel.Visible
	end)
end)

modGoster(false)
