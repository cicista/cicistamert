--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("KacanYumurta"))
local Divine = require(Shared:WaitForChild("Divine"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))
local BrainrotOnizleme = require(script.Parent:WaitForChild("BrainrotOnizleme"))
local KademeEfekti = require(script.Parent:WaitForChild("KademeEfekti"))

local Teklif = Net.event("KacanYumurtaTeklif")
local RobuxUrunAl = Net.event("RobuxUrunAl")

local KIRMIZI = Color3.fromRGB(255, 60, 60)
local SARI = Color3.fromRGB(255, 210, 60)
local YESIL = Color3.fromRGB(60, 215, 90)
local BEYAZ = Color3.new(1, 1, 1)
local SIYAH = Color3.new(0, 0, 0)
local KOYU = Color3.fromRGB(26, 20, 34)
local BORDO = Color3.fromRGB(120, 16, 30)

local ACILIS_GECIKMESI = 0.4
local SON_SANIYELER = 5
local ISIN_SAYISI = 14
local KIVILCIM_SAYISI = 7

local screen = Instance.new("ScreenGui")
screen.Name = "KacanYumurta"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.DisplayOrder = 30
screen.Parent = playerGui

local panel = UI.panel(screen, UDim2.fromOffset(440, 520), "KacanYumurta")

UI.closeButton(panel).MouseButton1Click:Connect(function()
	panel.Visible = false
end)

local baslikCubuk, baslik = UI.baslikCubugu(panel, "TIME'S TICKING!", BORDO, KIRMIZI, nil, KOYU)
baslik.TextXAlignment = Enum.TextXAlignment.Center
baslik.Position = UDim2.fromOffset(0, 0)
baslik.Size = UDim2.fromScale(1, 1)

local baslikFlas = Instance.new("Frame")
baslikFlas.Name = "Flas"
baslikFlas.Size = UDim2.fromScale(1, 1)
baslikFlas.BackgroundColor3 = BEYAZ
baslikFlas.BackgroundTransparency = 1
baslikFlas.BorderSizePixel = 0
baslikFlas.ZIndex = 4
baslikFlas.Parent = baslikCubuk
UI.corner(baslikFlas, 10)

local panelKontur = panel:FindFirstChildOfClass("UIStroke")

local altBaslik = UI.text({
	text = "It's escaping! Catch it before it's gone!",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -40, 0, 24),
	position = UDim2.fromOffset(20, 298),
	parent = panel,
})

local sayac = UI.text({
	text = "",
	size = 46,
	font = UI.Fonts.bold,
	color = SARI,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -40, 0, 48),
	position = UDim2.fromOffset(20, 324),
	parent = panel,
})
local sayacOlcek = Instance.new("UIScale")
sayacOlcek.Parent = sayac

local cubukZemin = Instance.new("Frame")
cubukZemin.Name = "Sure"
cubukZemin.Position = UDim2.fromOffset(30, 376)
cubukZemin.Size = UDim2.new(1, -60, 0, 22)
cubukZemin.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
cubukZemin.BorderSizePixel = 0
cubukZemin.ClipsDescendants = true
cubukZemin.Parent = panel
UI.corner(cubukZemin, 11)
UI.stroke(cubukZemin, SIYAH, 3).ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local cubuk = Instance.new("Frame")
cubuk.Name = "Dolgu"
cubuk.Size = UDim2.fromScale(1, 1)
cubuk.BackgroundColor3 = YESIL
cubuk.BorderSizePixel = 0
cubuk.ClipsDescendants = true
cubuk.Parent = cubukZemin
UI.corner(cubuk, 11)
UI.cubukCilasi(cubuk)
UI.caprazDesen(cubuk, BEYAZ, 10)

local uyari = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -40, 0, 20),
	position = UDim2.fromOffset(20, 404),
	parent = panel,
})

local alDugme, alYuz = UI.dugme3B(panel, nil, UDim2.fromOffset(330, 70), YESIL, false)
alDugme.Name = "Al"
alDugme.AnchorPoint = Vector2.new(0.5, 1)
alDugme.Position = UDim2.new(0.5, 0, 1, -16)
do
	local kontur = alDugme:FindFirstChildOfClass("UIStroke")
	if kontur then
		kontur.Thickness = 3
	end
end

local icerik = Instance.new("Frame")
icerik.Name = "Icerik"
icerik.Size = UDim2.fromScale(1, 1)
icerik.BackgroundTransparency = 1
icerik.ZIndex = alYuz.ZIndex + 2
icerik.Parent = alYuz

local dizilim = Instance.new("UIListLayout")
dizilim.FillDirection = Enum.FillDirection.Horizontal
dizilim.HorizontalAlignment = Enum.HorizontalAlignment.Center
dizilim.VerticalAlignment = Enum.VerticalAlignment.Center
dizilim.Padding = UDim.new(0, 12)
dizilim.SortOrder = Enum.SortOrder.LayoutOrder
dizilim.Parent = icerik

local alYazi = UI.text({
	text = "CATCH IT!",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromOffset(0, 40),
	parent = icerik,
	zIndex = icerik.ZIndex + 1,
})
alYazi.AutomaticSize = Enum.AutomaticSize.X
alYazi.TextTruncate = Enum.TextTruncate.None
alYazi.LayoutOrder = 1

local eskiKap = Instance.new("Frame")
eskiKap.Name = "EskiFiyat"
eskiKap.Size = UDim2.fromOffset(0, 30)
eskiKap.AutomaticSize = Enum.AutomaticSize.X
eskiKap.BackgroundTransparency = 1
eskiKap.ZIndex = icerik.ZIndex + 1
eskiKap.LayoutOrder = 2
eskiKap.Parent = icerik

local eskiFiyat = UI.robuxFiyati(eskiKap, Ayar.EskiFiyat, UI.Sizes.body, icerik.ZIndex + 1)
eskiFiyat.AnchorPoint = Vector2.new(0, 0.5)
eskiFiyat.Position = UDim2.fromScale(0, 0.5)
for _, d in eskiFiyat:GetDescendants() do
	if d:IsA("TextLabel") then
		d.TextColor3 = Color3.fromRGB(225, 225, 225)
		d.TextTransparency = 0.15
	elseif d:IsA("ImageLabel") then
		d.ImageTransparency = 0.15
	end
end

local cizik = Instance.new("Frame")
cizik.Name = "Cizik"
cizik.AnchorPoint = Vector2.new(0.5, 0.5)
cizik.Position = UDim2.fromScale(0.5, 0.5)
cizik.Size = UDim2.new(1, 10, 0, 4)
cizik.Rotation = -14
cizik.BackgroundColor3 = KIRMIZI
cizik.BorderSizePixel = 0
cizik.ZIndex = icerik.ZIndex + 4
cizik.Parent = eskiKap
UI.corner(cizik, 2)
UI.stroke(cizik, SIYAH, 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local fiyatKutusu = UI.robuxFiyati(icerik, Ayar.Fiyat, UI.Sizes.title, icerik.ZIndex + 1)
fiyatKutusu.LayoutOrder = 3

local indirim = Instance.new("TextLabel")
indirim.Name = "Indirim"
indirim.AnchorPoint = Vector2.new(0.5, 0.5)
indirim.Position = UDim2.new(1, -8, 0, -2)
indirim.Size = UDim2.fromOffset(86, 28)
indirim.Rotation = 12
indirim.BackgroundColor3 = KIRMIZI
indirim.BorderSizePixel = 0
indirim.FontFace = UI.Fonts.bold
indirim.Text = `{math.floor((1 - Ayar.Fiyat / Ayar.EskiFiyat) * 100 + 0.5)}% OFF`
indirim.TextColor3 = BEYAZ
indirim.TextSize = UI.Sizes.small
indirim.ZIndex = 20
indirim.Parent = alDugme
UI.corner(indirim, 8)
UI.stroke(indirim, SIYAH, 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local isilti = Instance.new("Frame")
isilti.Name = "Isilti"
isilti.AnchorPoint = Vector2.new(0.5, 0.5)
isilti.Position = UDim2.fromScale(-0.3, 0.5)
isilti.Size = UDim2.new(0, 46, 2, 0)
isilti.Rotation = 20
isilti.BackgroundColor3 = BEYAZ
isilti.BorderSizePixel = 0
isilti.ZIndex = icerik.ZIndex + 3
isilti.Parent = alYuz
do
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = isilti
end

local dugmeOlcek = Instance.new("UIScale")
dugmeOlcek.Parent = alDugme
TweenService:Create(
	dugmeOlcek,
	TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Scale = 1.06 }
):Play()

alDugme.MouseButton1Click:Connect(function()
	RobuxUrunAl:FireServer(Ayar.UrunAnahtari)
end)

local onizleme = BrainrotOnizleme.seritPencere(panel)

type Sahne = {
	kap: Frame,
	isinlar: Frame,
	yuva: Frame,
	yuvaOlcek: UIScale,
	kivilcimlar: { Frame },
	kademe: TextLabel,
}

local sahne: Sahne? = nil

local function sahneKur(rarityId: string): Sahne
	local eski = sahne
	if eski then
		eski.kap:Destroy()
	end

	local renk = Rarity.color(rarityId)
	local parilti = Divine.Flashes[rarityId]
	local renkB = if parilti then parilti.colorB else renk:Lerp(BEYAZ, 0.5)

	local kap = Instance.new("Frame")
	kap.Name = "Sahne"
	kap.Position = UDim2.fromOffset(20, 74)
	kap.Size = UDim2.new(1, -40, 0, 218)
	kap.BackgroundColor3 = BEYAZ
	kap.BorderSizePixel = 0
	kap.ClipsDescendants = true
	kap.ZIndex = 2
	kap.Parent = panel
	UI.corner(kap, 14)
	local cizgi = UI.stroke(kap, renk, 4)
	cizgi.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local zemin = Instance.new("UIGradient")
	zemin.Rotation = 90
	zemin.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, renk:Lerp(SIYAH, 0.75)),
		ColorSequenceKeypoint.new(0.5, renk:Lerp(SIYAH, 0.45)),
		ColorSequenceKeypoint.new(1, renk:Lerp(SIYAH, 0.85)),
	})
	zemin.Parent = kap

	local isinlar = Instance.new("Frame")
	isinlar.Name = "Isinlar"
	isinlar.AnchorPoint = Vector2.new(0.5, 0.5)
	isinlar.Position = UDim2.fromScale(0.5, 0.45)
	isinlar.Size = UDim2.fromOffset(520, 520)
	isinlar.BackgroundTransparency = 1
	isinlar.ZIndex = 3
	isinlar.Parent = kap

	for i = 1, ISIN_SAYISI do
		local isin = Instance.new("Frame")
		isin.Name = "Isin"
		isin.AnchorPoint = Vector2.new(0.5, 1)
		isin.Position = UDim2.fromScale(0.5, 0.5)
		isin.Size = UDim2.new(0, 34, 0.5, 0)
		isin.Rotation = (i - 1) * 360 / ISIN_SAYISI
		isin.BackgroundColor3 = if i % 2 == 0 then renk else renkB
		isin.BackgroundTransparency = 0.55
		isin.BorderSizePixel = 0
		isin.ZIndex = 3
		isin.Parent = isinlar

		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0.2),
		})
		g.Parent = isin
	end

	local hale = UI.parlama(kap, renk, 200, 4)
	hale.Position = UDim2.fromScale(0.5, 0.45)

	local kivilcimlar: { Frame } = {}
	for i = 1, KIVILCIM_SAYISI do
		local k = Instance.new("Frame")
		k.Name = "Kivilcim"
		k.AnchorPoint = Vector2.new(0.5, 0.5)
		k.Position = UDim2.fromScale(0.12 + 0.76 * ((i * 0.618) % 1), 0.1 + 0.6 * ((i * 0.37) % 1))
		k.Size = UDim2.fromOffset(10, 10)
		k.Rotation = 45
		k.BackgroundColor3 = if i % 2 == 0 then BEYAZ else renkB
		k.BorderSizePixel = 0
		k.ZIndex = 7
		k.Parent = kap
		UI.corner(k, 2)
		table.insert(kivilcimlar, k)
	end

	local yuva = Instance.new("Frame")
	yuva.Name = "Yumurta"
	yuva.AnchorPoint = Vector2.new(0.5, 0.5)
	yuva.Position = UDim2.fromScale(0.5, 0.45)
	yuva.Size = UDim2.fromOffset(150, 150)
	yuva.BackgroundTransparency = 1
	yuva.ZIndex = 5
	yuva.Parent = kap
	local yuvaOlcek = Instance.new("UIScale")
	yuvaOlcek.Parent = yuva

	local kademe = UI.text({
		text = `{string.upper(Rarity.displayName(rarityId))} EGG`,
		size = UI.Sizes.title,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -20, 0, 36),
		position = UDim2.new(0, 10, 1, -42),
		parent = kap,
		zIndex = 8,
	})
	if parilti then
		local g = Instance.new("UIGradient")
		g.Name = "Parilti"
		g.Parent = kademe
		CollectionService:AddTag(kademe, parilti.tag)
	else
		kademe.TextColor3 = renk
	end

	KademeEfekti.tak(kap, cizgi, renk, rarityId, {
		aura = "ic",
		etkin = function()
			return panel.Visible
		end,
	})

	onizleme.temizle()
	onizleme.ekle(yuva, { revealed = false, rarity = rarityId })

	local yeni: Sahne = {
		kap = kap,
		isinlar = isinlar,
		yuva = yuva,
		yuvaOlcek = yuvaOlcek,
		kivilcimlar = kivilcimlar,
		kademe = kademe,
	}
	sahne = yeni
	return yeni
end

local bitis = 0
local toplamSure = Ayar.Sure
local surum = 0
local sonSaniye = -1
local baglanti: RBXScriptConnection? = nil
local isiltiTween: Tween? = nil
local kapaniyor = false

local function durdur()
	if baglanti then
		baglanti:Disconnect()
		baglanti = nil
	end
	if isiltiTween then
		isiltiTween:Cancel()
		isiltiTween = nil
	end
end

local function saniyeVurusu(sonAn: boolean)
	sayacOlcek.Scale = if sonAn then 1.6 else 1.3
	TweenService:Create(
		sayacOlcek,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()

	baslikFlas.BackgroundTransparency = if sonAn then 0.35 else 0.65
	TweenService:Create(
		baslikFlas,
		TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	):Play()
end

local function kactiGoster()
	local s = sahne
	if kapaniyor or not s then
		panel.Visible = false
		return
	end
	kapaniyor = true

	baslik.Text = "IT GOT AWAY..."
	sayac.Text = "0s"
	uyari.Text = "Better luck next time!"
	uyari.TextColor3 = UI.Colors.textDim

	local bilgi = TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	TweenService:Create(s.yuva, bilgi, { Position = UDim2.new(1.3, 0, -0.5, 0) }):Play()
	TweenService:Create(s.yuvaOlcek, bilgi, { Scale = 0.3 }):Play()

	local benim = surum
	task.delay(1.1, function()
		if benim == surum then
			panel.Visible = false
		end
	end)
end

local function yakalandiGoster()
	local s = sahne
	durdur()
	kapaniyor = true

	baslik.Text = "CAUGHT IT!"
	altBaslik.Text = "The egg is in your backpack!"
	sayac.Text = "GOT IT!"
	sayac.TextColor3 = YESIL
	sayac.Rotation = 0
	uyari.Text = ""
	cubuk.BackgroundColor3 = YESIL
	cubuk.Size = UDim2.fromScale(1, 1)
	saniyeVurusu(false)

	if s then
		s.yuva.Position = UDim2.fromScale(0.5, 0.45)
		s.yuvaOlcek.Scale = 1.5
		TweenService:Create(
			s.yuvaOlcek,
			TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
			{ Scale = 1.1 }
		):Play()
	end

	local benim = surum
	task.delay(1.8, function()
		if benim == surum then
			panel.Visible = false
		end
	end)
end

local function tik()
	if kapaniyor then
		return
	end

	local simdi = os.clock()
	local kalan = math.max(0, bitis - simdi)
	local oran = if toplamSure > 0 then kalan / toplamSure else 0
	local sonAn = kalan <= SON_SANIYELER

	cubuk.Size = UDim2.fromScale(oran, 1)
	cubuk.BackgroundColor3 = if oran > 0.5
		then YESIL:Lerp(SARI, (1 - oran) * 2)
		else SARI:Lerp(KIRMIZI, (0.5 - oran) * 2)

	local saniye = math.ceil(kalan)
	if saniye ~= sonSaniye then
		sonSaniye = saniye
		saniyeVurusu(sonAn)
	end
	sayac.Text = `{saniye}s`
	sayac.TextColor3 = if sonAn then KIRMIZI else SARI
	sayac.Rotation = if sonAn then math.sin(simdi * 40) * 5 else 0

	uyari.Text = if sonAn then "LAST CHANCE! It's almost gone!" else "Don't miss it! This offer won't come back."
	uyari.TextColor3 = if sonAn then KIRMIZI else UI.Colors.textDim

	if panelKontur then
		local yanip = sonAn and math.sin(simdi * 18) > 0
		panelKontur.Color = if yanip then KIRMIZI else SIYAH
		panelKontur.Thickness = if yanip then 5 else 3
	end

	local s = sahne
	if s then
		s.isinlar.Rotation = (simdi * (if sonAn then 70 else 30)) % 360

		local kacis = if sonAn then 1 + (SON_SANIYELER - kalan) / SON_SANIYELER else 1
		local x = math.sin(simdi * 1.7) * 26 * kacis + (if sonAn then math.sin(simdi * 30) * 3 else 0)
		local y = math.sin(simdi * 3.4) * 8 - math.abs(math.sin(simdi * 1.7)) * 6
		s.yuva.Position = UDim2.new(0.5, x, 0.45, y)
		s.yuvaOlcek.Scale = 1 + math.sin(simdi * 4) * 0.05

		for i, k in s.kivilcimlar do
			local p = math.max(0, math.sin(simdi * 3 + i * 1.9))
			k.BackgroundTransparency = 1 - p
			k.Rotation = 45 + simdi * 140
			local boy = 4 + p * 12
			k.Size = UDim2.fromOffset(boy, boy)
		end
	end

	if kalan <= 0 then
		kactiGoster()
	end
end

local function isiltiBaslat()
	isilti.Position = UDim2.fromScale(-0.3, 0.5)
	local t = TweenService:Create(
		isilti,
		TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false, 0.6),
		{ Position = UDim2.fromScale(1.3, 0.5) }
	)
	t:Play()
	isiltiTween = t
end

panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if not panel.Visible then
		durdur()
		onizleme.temizle()
		if panelKontur then
			panelKontur.Color = SIYAH
			panelKontur.Thickness = 3
		end
	end
end)

Teklif.OnClientEvent:Connect(function(veri)
	surum += 1
	local benim = surum

	if type(veri) ~= "table" then
		if not kapaniyor then
			panel.Visible = false
		end
		return
	end

	if veri.yakalandi == true then
		if panel.Visible then
			yakalandiGoster()
		end
		return
	end

	if type(veri.rarity) ~= "string" then
		return
	end

	local rarityId: string = veri.rarity
	toplamSure = tonumber(veri.sure) or Ayar.Sure
	bitis = os.clock() + toplamSure

	task.wait(ACILIS_GECIKMESI)
	if benim ~= surum then
		return
	end

	durdur()
	kapaniyor = false
	sonSaniye = -1
	baslik.Text = "TIME'S TICKING!"
	altBaslik.Text = "It's escaping! Catch it before it's gone!"
	sahneKur(rarityId)

	tik()
	panel.Visible = true
	isiltiBaslat()
	baglanti = RunService.Heartbeat:Connect(tik)
end)
