--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Fonts = require(Shared:WaitForChild("Fonts"))
local Divine = require(Shared:WaitForChild("Divine"))
local Assets = require(Shared:WaitForChild("Assets"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))

local UI = require(script.Parent:WaitForChild("UI"))
local KademeEfekti = require(script.Parent:WaitForChild("KademeEfekti"))

local IndexAc = Net.event("IndexAc")
local IndexDurum = Net.event("IndexDurum")

local Index = {}

local HUCRE = Vector2.new(132, 186)
local BOSLUK = 10

local PAY = 260

local KILITLI_TON = Color3.fromRGB(0, 0, 0)
local GIZLI_YAZI = "???"

local BAKIS_YONU = Vector3.new(0, 0, -1)

local ISIK = Color3.fromRGB(255, 255, 255)
local ISIK_YONU = Vector3.new(-0.4, -0.7, -0.6)

local KILITLI_ZEMIN = Color3.fromRGB(58, 62, 74)

local HOVER_BUYUME = 1.07
local HOVER_BUYUME_KILITLI = 1.03

local PARILTI_BAS = -0.22
local PARILTI_BIT = 1.22

local PARILTI_SURE = 1.1

local SALINIM_ACI = math.rad(24)
local SALINIM_HIZ = 1.7

local KILITLI_SALINIM_ACI = math.rad(10)
local KILITLI_SALINIM_HIZ = 0.9

local function kademeYazisi(label: TextLabel, rarityId: string)
	local renk = Rarity.textColor(rarityId)
	Fonts.apply(label)
	Divine.untag(label)
	if Rarity.isDivine(rarityId) then
		Fonts.applyGlow(label, renk)
		Divine.tagIf(label, rarityId)
	elseif Rarity.isGlowing(rarityId) then
		Fonts.applyGlow(label, renk)
	else
		Fonts.clearGlow(label, renk)
	end
end

local ZEMIN_GECIS_HIZ = 0.08
local ZEMIN_DONUS_HIZ = 25
local ZEMIN_DOYGUNLUK = 0.6
local ZEMIN_PARLAKLIK = 0.95

local ADA_ADI: { [string]: string } = {
	kum = "Main Island",
	sekerkum = "Candy Island",
	snowkum = "Snow Island",
	alevkum = "Lava Island",
	deniz = "The Sea",
}

local ADA_SEKME: { [string]: { ad: string, renk: Color3 } } = {
	kum = { ad = "Main", renk = Color3.fromRGB(95, 200, 90) },
	sekerkum = { ad = "Candy", renk = Color3.fromRGB(255, 110, 190) },
	snowkum = { ad = "Snow", renk = Color3.fromRGB(110, 190, 255) },
	alevkum = { ad = "Lava", renk = Color3.fromRGB(255, 110, 45) },
	deniz = { ad = "Sea", renk = Color3.fromRGB(40, 130, 240) },
}

local MUTASYON_SEKMELERI: { string } = { "Normal" }
for _, mutasyon in Mutations.IndexOrder do
	table.insert(MUTASYON_SEKMELERI, mutasyon)
end

local function mutasyonRengi(id: string): Color3
	if id == "Normal" then
		return Color3.fromRGB(150, 155, 170)
	end
	return Mutations.color(id)
end

local function adasi(info: any): string
	return Brainrots.normalizeIsland(info.island)
end

local function siraliKademeler(ada: string): { string }
	local sirali = {}
	local gorulen: { [string]: boolean } = {}

	for _, id in Rarity.Order do
		for _, info in Brainrots.List do
			if info.rarity == id and adasi(info) == ada and not gorulen[id] then
				gorulen[id] = true
				table.insert(sirali, id)
			end
		end
	end

	for _, info in Brainrots.List do
		if adasi(info) == ada and not gorulen[info.rarity] then
			gorulen[info.rarity] = true
			table.insert(sirali, info.rarity)
		end
	end

	return sirali
end

local ekran = Instance.new("ScreenGui")
ekran.Name = "IndexDefteri"
ekran.ResetOnSpawn = false
ekran.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ekran.Parent = playerGui

local panel = UI.panel(ekran, UDim2.fromOffset(640, 620), "Index")

UI.baslikCubugu(panel, "Index", Color3.fromRGB(186, 120, 255), Color3.fromRGB(80, 150, 255), "index")

local sayac = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	color = Color3.fromRGB(255, 225, 140),
	align = Enum.TextXAlignment.Left,
	frameSize = UDim2.new(1, -36, 0, 22),
	position = UDim2.fromOffset(18, 68),
	parent = panel,
	name = "Sayac",
})

UI.closeButton(panel).Activated:Connect(function()
	panel.Visible = false
end)

local function sekmeSirasi(y: number, yukseklik: number): Frame
	local sira = Instance.new("Frame")
	sira.BackgroundTransparency = 1
	sira.Position = UDim2.fromOffset(14, y)
	sira.Size = UDim2.new(1, -28, 0, yukseklik)
	sira.Parent = panel

	local yerlesim = Instance.new("UIListLayout")
	yerlesim.FillDirection = Enum.FillDirection.Horizontal
	yerlesim.Padding = UDim.new(0, 8)
	yerlesim.SortOrder = Enum.SortOrder.LayoutOrder
	yerlesim.Parent = sira

	return sira
end

local adaSirasi = sekmeSirasi(96, 42)
local mutasyonSirasi = sekmeSirasi(144, 36)

local liste = Instance.new("ScrollingFrame")
liste.Name = "Liste"
liste.Position = UDim2.fromOffset(14, 190)
liste.Size = UDim2.new(1, -28, 1, -204)
liste.BackgroundTransparency = 1
liste.BorderSizePixel = 0
liste.ScrollBarThickness = 6
liste.CanvasSize = UDim2.new()
liste.AutomaticCanvasSize = Enum.AutomaticSize.Y
liste.ScrollingDirection = Enum.ScrollingDirection.Y
liste.Parent = panel
UI.listePayi(liste)

local dizilim = Instance.new("UIListLayout")
dizilim.Padding = UDim.new(0, 12)
dizilim.SortOrder = Enum.SortOrder.LayoutOrder
dizilim.Parent = liste

local seciliAda = Brainrots.IslandOrder[1]
local seciliMutasyon = "Normal"

type Hucre = {
	name: string,
	rarity: string,
	ada: string,
	renk: Color3,
	kutu: TextButton,
	ic: Frame,
	olcek: UIScale,
	cizgi: UIStroke,
	yuva: Frame,
	parilti: Frame,
	ad: TextLabel,
	gelir: TextLabel,
	yedek: TextLabel,
	kesif: boolean,
	onizleme: ViewportFrame?,
	kamera: Camera?,
	merkez: Vector3?,
	uzaklik: number?,
	modelYok: boolean,
	gorunur: boolean,
	zeminGecis: UIGradient,
	faz: number,
	efekt: KademeEfekti.Efekt?,
}

local hucreler: { Hucre } = {}

local kademeSayaclari: { [string]: TextLabel } = {}

local function onizlemeTonla(hucre: Hucre)
	if hucre.onizleme then
		hucre.onizleme.ImageColor3 = if hucre.kesif then Color3.new(1, 1, 1) else KILITLI_TON
	end
end

local function onizlemeKur(hucre: Hucre)
	if hucre.onizleme or hucre.modelYok then
		return
	end

	local model = Assets.brainrotModel(hucre.name, if seciliMutasyon ~= "Normal" then seciliMutasyon else nil)
		or Assets.brainrotModel(hucre.name)
	if not model then
		hucre.modelYok = true
		hucre.yedek.Visible = true
		return
	end

	local kopya = model

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
	vp.Ambient = ISIK
	vp.LightColor = ISIK
	vp.LightDirection = ISIK_YONU
	vp.ZIndex = 2
	vp.Parent = hucre.yuva

	kopya.Parent = vp

	local kamera = Instance.new("Camera")
	kamera.Parent = vp
	vp.CurrentCamera = kamera

	local ok, cf, boyut = pcall(function()
		return kopya:GetBoundingBox()
	end)

	if ok and cf and boyut then
		local uzaklik = boyut.Magnitude * 0.9

		kamera.CFrame = CFrame.lookAt(cf.Position + BAKIS_YONU * uzaklik, cf.Position)

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
	hucre.kamera = nil
	hucre.merkez = nil
	hucre.uzaklik = nil
end

local function hucreCiz(hucre: Hucre)
	hucre.gelir.Visible = true
	hucre.ad.Text = if hucre.kesif then hucre.name else GIZLI_YAZI

	hucre.cizgi.Color = hucre.renk

	local efekt = hucre.efekt
	if efekt then
		efekt.kilitli = not hucre.kesif
		KademeEfekti.yenile(efekt)
	end

	if hucre.kesif then
		hucre.yuva.BackgroundColor3 = Color3.new(1, 1, 1)
		hucre.yuva.BackgroundTransparency = 0.12
		hucre.zeminGecis.Enabled = true
		if not efekt then
			hucre.cizgi.Thickness = 3
			hucre.cizgi.Transparency = 0
		end

		local kamera, merkez, uzaklik = hucre.kamera, hucre.merkez, hucre.uzaklik
		if kamera and merkez and uzaklik then
			kamera.CFrame = CFrame.lookAt(merkez + BAKIS_YONU * uzaklik, merkez)
		end
	else
		hucre.yuva.BackgroundColor3 = KILITLI_ZEMIN
		hucre.yuva.BackgroundTransparency = 0.25
		hucre.zeminGecis.Enabled = false
		if not efekt then
			hucre.cizgi.Thickness = 1.5
			hucre.cizgi.Transparency = 0.45
		end
	end

	onizlemeTonla(hucre)
end

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

	local isikli = hucre.efekt ~= nil and hucre.efekt.gecis ~= nil

	if hucre.kesif then
		hucre.parilti.Position = UDim2.fromScale(PARILTI_BAS, 0.5)
		hucre.parilti.Visible = true
		if not isikli then
			hucre.cizgi.Color = UI.shade(hucre.renk, 0.3)
		end
	else
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

	hucreCiz(hucre)

	local kamera, merkez, uzaklik = hucre.kamera, hucre.merkez, hucre.uzaklik
	if hucre.kesif and kamera and merkez and uzaklik then
		kamera.CFrame = CFrame.lookAt(merkez + BAKIS_YONU * uzaklik, merkez)
	end
end

local function hucreKur(parent: Instance, info: Brainrots.BrainrotInfo, sira: number): Hucre
	local renk = Rarity.color(info.rarity)

	local kutu = Instance.new("TextButton")
	kutu.Name = info.name
	kutu.Size = UDim2.fromOffset(HUCRE.X, HUCRE.Y)
	kutu.BackgroundTransparency = 1
	kutu.BorderSizePixel = 0
	kutu.AutoButtonColor = false
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

	local zeminGecis = Instance.new("UIGradient")
	zeminGecis.Name = "ZeminGecis"
	zeminGecis.Enabled = false
	zeminGecis.Parent = yuva

	local parilti = Instance.new("Frame")
	parilti.Name = "Parilti"
	parilti.AnchorPoint = Vector2.new(0.5, 0.5)
	parilti.Position = UDim2.fromScale(PARILTI_BAS, 0.5)
	parilti.Size = UDim2.fromScale(0.42, 1)
	parilti.Rotation = 0
	parilti.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	parilti.BorderSizePixel = 0
	parilti.ZIndex = 3
	parilti.Visible = false
	parilti.Parent = yuva
	local pGecis = Instance.new("UIGradient")
	pGecis.Rotation = 0
	pGecis.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, renk),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, renk),
	})
	pGecis.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0.8),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(0.75, 0.8),
		NumberSequenceKeypoint.new(1, 1),
	})
	pGecis.Parent = parilti
	pGecis.Parent = parilti

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

	local ad = UI.text({
		text = info.name,
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -8, 0, 36),
		position = UDim2.fromOffset(4, 107),
		parent = ic,
		wrapped = true,
		name = "Ad",
	})
	kademeYazisi(ad, info.rarity)

	local gelir = UI.text({
		text = Format.perSecond(Brainrots.income(info.name, "Normal")),
		size = UI.Sizes.tiny,
		color = UI.Colors.textDim,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -8, 0, 18),
		position = UDim2.fromOffset(4, 145),
		parent = ic,
		name = "Gelir",
	})

	local ada = UI.text({
		text = ADA_ADI[string.lower(info.island or "")] or "?",
		size = UI.Sizes.tiny,
		color = UI.Colors.textDim,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -8, 0, 16),
		position = UDim2.fromOffset(4, 164),
		parent = ic,
		name = "Ada",
	})

	local hucre: Hucre = {
		name = info.name,
		rarity = info.rarity,
		ada = adasi(info),
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
		kesif = false,
		onizleme = nil,
		kamera = nil,
		merkez = nil,
		uzaklik = nil,
		modelYok = false,
		gorunur = false,
		zeminGecis = zeminGecis,
		faz = #hucreler * 0.77,
		efekt = nil,
	}

	hucre.efekt = KademeEfekti.tak(ic, cizgi, renk, info.rarity, {
		aura = "ic",
		zemin = true,
		etkin = function()
			return panel.Visible and hucre.gorunur
		end,
	})

	kutu.MouseEnter:Connect(function()
		hoverBaslat(hucre)
	end)
	kutu.MouseLeave:Connect(function()
		hoverBitir(hucre)
	end)

	return hucre
end

local adaKutulari: { [string]: Frame } = {}

for adaSira, ada in Brainrots.IslandOrder do
	local kutu = Instance.new("Frame")
	kutu.Name = `Ada_{ada}`
	kutu.Size = UDim2.new(1, 0, 0, 0)
	kutu.AutomaticSize = Enum.AutomaticSize.Y
	kutu.BackgroundTransparency = 1
	kutu.LayoutOrder = adaSira
	kutu.Visible = ada == seciliAda
	kutu.Parent = liste
	adaKutulari[ada] = kutu

	local kutuDizilim = Instance.new("UIListLayout")
	kutuDizilim.Padding = UDim.new(0, 12)
	kutuDizilim.SortOrder = Enum.SortOrder.LayoutOrder
	kutuDizilim.Parent = kutu

	local kademeSirasi = 0

	for _, rarityId in siraliKademeler(ada) do
		kademeSirasi += 1

		local baslik = Instance.new("Frame")
		baslik.Name = `Kademe_{rarityId}`
		baslik.Size = UDim2.new(1, -10, 0, 30)
		baslik.BackgroundTransparency = 1
		baslik.LayoutOrder = kademeSirasi * 10
		baslik.Parent = kutu
		baslik.ZIndex = 1

		local etiket = UI.text({
			text = Rarity.labelText(rarityId),
			size = UI.Sizes.label,
			font = UI.Fonts.bold,
			align = Enum.TextXAlignment.Left,
			frameSize = UDim2.new(1, -100, 1, 0),
			position = UDim2.fromOffset(10, 0),
			parent = baslik,
			name = "Etiket",
		})
		etiket.ZIndex = 2
		kademeYazisi(etiket, rarityId)

		local kademeSayac = UI.text({
			text = "",
			size = UI.Sizes.small,
			font = UI.Fonts.bold,
			color = Color3.fromRGB(235, 238, 245),
			align = Enum.TextXAlignment.Right,
			frameSize = UDim2.fromOffset(86, 30),
			position = UDim2.new(1, -96, 0, 0),
			parent = baslik,
			name = "Sayac",
		})
		kademeSayac.ZIndex = 2
		kademeSayaclari[`{ada}/{rarityId}`] = kademeSayac

		local doku = Instance.new("Frame")
		doku.Name = "Doku"
		doku.Size = UDim2.fromScale(1, 1)
		doku.BackgroundColor3 = Rarity.color(rarityId)
		doku.BackgroundTransparency = 0.7
		doku.BorderSizePixel = 0
		doku.ZIndex = 0
		doku.Parent = baslik
		UI.corner(doku, 8)
		UI.stroke(doku, Color3.fromRGB(0, 0, 0), 2)

		do
			local stops = {}
			local sikilik = 13
			for i = 0, sikilik do
				table.insert(
					stops,
					NumberSequenceKeypoint.new(i / sikilik, if i % 2 == 0 then 0 else 0.45)
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
		izgara.Parent = kutu

		local yerlesim = Instance.new("UIGridLayout")
		yerlesim.CellSize = UDim2.fromOffset(HUCRE.X, HUCRE.Y)
		yerlesim.CellPadding = UDim2.fromOffset(BOSLUK, BOSLUK)
		yerlesim.SortOrder = Enum.SortOrder.LayoutOrder
		yerlesim.Parent = izgara

		local sira = 0
		for _, info in Brainrots.List do
			if info.rarity == rarityId and adasi(info) == ada then
				sira += 1
				local hucre = hucreKur(izgara, info, sira)
				hucreCiz(hucre)
				table.insert(hucreler, hucre)
			end
		end
	end
end

local function pencereyiTazele()
	if not panel.Visible then
		return
	end

	local ustSinir = liste.AbsolutePosition.Y - PAY
	local altSinir = liste.AbsolutePosition.Y + liste.AbsoluteSize.Y + PAY

	for _, hucre in hucreler do
		local y = hucre.kutu.AbsolutePosition.Y
		local icinde = hucre.ada == seciliAda
			and y + hucre.kutu.AbsoluteSize.Y >= ustSinir
			and y <= altSinir

		hucre.gorunur = icinde

		if icinde then
			onizlemeKur(hucre)
		else
			onizlemeYik(hucre)
		end
	end
end

liste:GetPropertyChangedSignal("CanvasPosition"):Connect(pencereyiTazele)

panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then
		return
	end

	local acik = ustundeki
	if acik then
		hoverBitir(acik)
	end

	for _, hucre in hucreler do
		hucre.gorunur = false
		onizlemeYik(hucre)
	end
end)

local zaman = 0

local function kameraCevir(hucre: Hucre, aci: number)
	local kamera, merkez, uzaklik = hucre.kamera, hucre.merkez, hucre.uzaklik
	if kamera and merkez and uzaklik then
		local yon = CFrame.Angles(0, aci, 0):VectorToWorldSpace(BAKIS_YONU)
		kamera.CFrame = CFrame.lookAt(merkez + yon * uzaklik, merkez)
	end
end

local function zeminRengi(bas: number): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHSV(bas % 1, ZEMIN_DOYGUNLUK, ZEMIN_PARLAKLIK)),
		ColorSequenceKeypoint.new(0.5, Color3.fromHSV((bas + 0.22) % 1, ZEMIN_DOYGUNLUK, ZEMIN_PARLAKLIK)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV((bas + 0.44) % 1, ZEMIN_DOYGUNLUK, ZEMIN_PARLAKLIK)),
	})
end

RunService.RenderStepped:Connect(function(dt)
	if not panel.Visible then
		return
	end

	zaman += dt
	local fareHucre = ustundeki

	for _, hucre in hucreler do
		if not hucre.gorunur then
			continue
		end

		if hucre.kesif then
			local ton = hucre.renk:ToHSV()
			hucre.zeminGecis.Color = zeminRengi(ton + zaman * ZEMIN_GECIS_HIZ)
			hucre.zeminGecis.Rotation = (zaman * ZEMIN_DONUS_HIZ + hucre.faz * 40) % 360
		else
			kameraCevir(hucre, math.sin(zaman * KILITLI_SALINIM_HIZ + hucre.faz) * KILITLI_SALINIM_ACI)
		end
	end

	if fareHucre and fareHucre.kesif then
		hoverT += dt
		local ilerleme = (hoverT % PARILTI_SURE) / PARILTI_SURE
		fareHucre.parilti.Position =
			UDim2.fromScale(PARILTI_BAS + ilerleme * (PARILTI_BIT - PARILTI_BAS), 0.5)
		kameraCevir(fareHucre, math.sin(hoverT * SALINIM_HIZ) * SALINIM_ACI)
	end
end)

local sonKesif: { [string]: boolean } = {}
local sonMutasyonKesif: { [string]: { [string]: boolean } } = {}

local function kesifMi(hucre: Hucre): boolean
	if seciliMutasyon == "Normal" then
		return sonKesif[hucre.name] == true
	end
	local kayit = sonMutasyonKesif[seciliMutasyon]
	return kayit ~= nil and kayit[hucre.name] == true
end

local adaDugmeleri: { [string]: TextButton } = {}
local mutasyonDugmeleri: { [string]: TextButton } = {}
local adaYazilari: { [string]: TextLabel } = {}

local SEKME_KAPALI = Color3.fromRGB(78, 84, 100)

local function durumuCiz()
	local bulunan, toplam = 0, 0
	local kademe: { [string]: { number } } = {}
	local adaSayi: { [string]: { number } } = {}

	for _, hucre in hucreler do
		hucre.kesif = kesifMi(hucre)

		local mutasyon = if seciliMutasyon ~= "Normal" then seciliMutasyon else nil
		hucre.gelir.Text = if hucre.kesif
			then Format.perSecond(Brainrots.income(hucre.name, "Normal", mutasyon :: any))
			else GIZLI_YAZI

		local anahtar = `{hucre.ada}/{hucre.rarity}`
		local sayi = kademe[anahtar]
		if not sayi then
			sayi = { 0, 0 }
			kademe[anahtar] = sayi
		end
		sayi[2] += 1

		local adaninki = adaSayi[hucre.ada]
		if not adaninki then
			adaninki = { 0, 0 }
			adaSayi[hucre.ada] = adaninki
		end
		adaninki[2] += 1

		if hucre.kesif then
			sayi[1] += 1
			adaninki[1] += 1
		end

		if hucre.ada == seciliAda then
			toplam += 1
			if hucre.kesif then
				bulunan += 1
			end
		end

		hucreCiz(hucre)
	end

	local adaAdi = ADA_ADI[seciliAda] or seciliAda
	local mutasyonAdi = if seciliMutasyon == "Normal" then "" else `{seciliMutasyon} `
	sayac.Text = `{adaAdi}  -  {bulunan} / {toplam} {mutasyonAdi}discovered`

	for anahtar, etiket in kademeSayaclari do
		local sayi = kademe[anahtar]
		etiket.Text = if sayi then `{sayi[1]} / {sayi[2]}` else ""
	end

	for ada, yazi in adaYazilari do
		local sayi = adaSayi[ada]
		local sekme = ADA_SEKME[ada]
		yazi.Text = `{if sekme then sekme.ad else ada}  {if sayi then sayi[1] else 0}/{if sayi then sayi[2] else 0}`
	end

	for ada, dugme in adaDugmeleri do
		local sekme = ADA_SEKME[ada]
		UI.dugme3BRenk(dugme, if ada == seciliAda and sekme then sekme.renk else SEKME_KAPALI)
	end
	for id, dugme in mutasyonDugmeleri do
		UI.dugme3BRenk(dugme, if id == seciliMutasyon then mutasyonRengi(id) else SEKME_KAPALI)
	end
end

local function sekmeSec(ada: string?, mutasyon: string?)
	local mutasyonDegisti = mutasyon ~= nil and mutasyon ~= seciliMutasyon

	if ada then
		seciliAda = ada
	end
	if mutasyon then
		seciliMutasyon = mutasyon
	end

	for id, kutu in adaKutulari do
		kutu.Visible = id == seciliAda
	end

	if mutasyonDegisti then
		for _, hucre in hucreler do
			onizlemeYik(hucre)
			hucre.modelYok = false
		end
	end

	local acik = ustundeki
	if acik then
		hoverBitir(acik)
	end

	liste.CanvasPosition = Vector2.zero
	durumuCiz()
	task.defer(pencereyiTazele)
end

for sira, ada in Brainrots.IslandOrder do
	local sekme = ADA_SEKME[ada] or { ad = ada, renk = UI.Colors.accent }
	local dugme, yuz = UI.dugme3B(adaSirasi, nil, UDim2.new(1 / #Brainrots.IslandOrder, -7, 1, 0), SEKME_KAPALI)
	dugme.Name = `Ada_{ada}`
	dugme.LayoutOrder = sira
	adaYazilari[ada] = UI.text({
		text = sekme.ad,
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = yuz,
		zIndex = 5,
	})
	adaDugmeleri[ada] = dugme
	dugme.MouseButton1Click:Connect(function()
		sekmeSec(ada, nil)
	end)
end

for sira, id in MUTASYON_SEKMELERI do
	local dugme = UI.dugme3B(
		mutasyonSirasi,
		if id == "Normal" then "Normal" else Mutations.get(id).displayName,
		UDim2.new(1 / #MUTASYON_SEKMELERI, -6, 1, 0),
		SEKME_KAPALI
	)
	dugme.Name = `Mutasyon_{id}`
	dugme.LayoutOrder = sira
	mutasyonDugmeleri[id] = dugme
	dugme.MouseButton1Click:Connect(function()
		sekmeSec(nil, id)
	end)
end

durumuCiz()

IndexDurum.OnClientEvent:Connect(function(kesfedilen, mutasyonlar)
	if type(kesfedilen) ~= "table" then
		return
	end

	sonKesif = kesfedilen
	sonMutasyonKesif = if type(mutasyonlar) == "table" then mutasyonlar else {}

	durumuCiz()
	pencereyiTazele()

	local acik = ustundeki
	if acik then
		hoverBaslat(acik)
	end
end)

function Index.ac()
	panel.Visible = true
	IndexAc:FireServer()

	task.defer(pencereyiTazele)
end

function Index.kapat()
	panel.Visible = false
end

function Index.acikMi(): boolean
	return panel.Visible
end

return Index
