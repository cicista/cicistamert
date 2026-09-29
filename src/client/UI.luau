--!strict

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Girdi = require(script.Parent:WaitForChild("Girdi"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Fonts = require(Shared:WaitForChild("Fonts"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Divine = require(Shared:WaitForChild("Divine"))
local Icons = require(Shared:WaitForChild("Icons"))

local UI = {}

local OLCEK_ADI = "AyarOlcek"

UI.Sizes = {
	tiny = 14,
	small = 16,
	body = 18,
	label = 20,
	heading = 24,
	title = 30,
	huge = 40,
}

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

UI.Girdi = Girdi

UI.EkranRef = Vector2.new(1500, 900)
UI.DokunmatikEkranRef = Vector2.new(1100, 700)
UI.DokunmatikOlcekNiteligi = "DokunmatikOlcek"
UI.EkranEnAz = 0.42

local function ekranBoyu(): Vector2
	local kamera = workspace.CurrentCamera
	local boyut = if kamera then kamera.ViewportSize else Vector2.zero
	if boyut.X < 2 or boyut.Y < 2 then
		return Vector2.new(1920, 1080)
	end
	return boyut
end

local function ekranCarpani(): number
	local ref = if Girdi.dokunmatik() then UI.DokunmatikEkranRef else UI.EkranRef
	local boyut = ekranBoyu()
	return math.clamp(math.min(boyut.X / ref.X, boyut.Y / ref.Y), UI.EkranEnAz, 1)
end

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
	outline: boolean?,
	wrapped: boolean?,
	zIndex: number?,
	glow: Color3?,
}

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

	label.TextScaled = false
	label.RichText = false
	label.TextWrapped = options.wrapped == true
	label.TextTruncate = if options.wrapped then Enum.TextTruncate.None else Enum.TextTruncate.AtEnd

	label.TextXAlignment = options.align or Enum.TextXAlignment.Left
	label.TextYAlignment = options.alignY or Enum.TextYAlignment.Center

	label.TextStrokeTransparency = 1

	if options.zIndex then
		label.ZIndex = options.zIndex
	end

	if options.outline ~= false then
		Fonts.applyOutline(label)
	end

	if options.glow then
		Fonts.applyGlow(label, options.glow)
	end

	if options.parent then
		label.Parent = options.parent
	end

	return label
end

function UI.rarityStyle(label: TextLabel, rarityId: string): TextLabel
	local color = Rarity.textColor(rarityId)

	Divine.untag(label)
	Fonts.clearGlow(label, color)

	return label
end

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

UI.FonKatmani = 19
UI.PanelKatmani = 20

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

function UI.panelEkrani(): ScreenGui?
	if panelKatmani and panelKatmani.Parent then
		return panelKatmani
	end
	panelKatmani = katmanKur("PanelKatmani", UI.PanelKatmani)
	return panelKatmani
end

function UI.fonEkrani(): ScreenGui?
	if fonKatmani and fonKatmani.Parent then
		return fonKatmani
	end
	fonKatmani = katmanKur("PanelFonKatmani", UI.FonKatmani)
	return fonKatmani
end

local paneller: { Frame } = {}

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

local ACILIS_SURE = 0.18
local KAPANIS_SURE = 0.13
local ACILIS_ORANI = 0.85
local KAPANIS_ORANI = 0.9

local PANEL_EN_PAYI = 0.96
local PANEL_BOY_PAYI = 0.92

local function panelHedef(frame: Frame): number
	local olcek = UI.carpan()
	local kap = frame.Parent
	local alan = if kap and kap:IsA("GuiBase2d") then kap.AbsoluteSize else Vector2.zero
	if alan.X < 2 or alan.Y < 2 then
		alan = ekranBoyu()
	end
	local en, boy = frame.Size.X.Offset, frame.Size.Y.Offset
	if en > 0 then
		olcek = math.min(olcek, alan.X * PANEL_EN_PAYI / en)
	end
	if boy > 0 then
		olcek = math.min(olcek, alan.Y * PANEL_BOY_PAYI / boy)
	end
	return olcek
end

local function panelOlcegi(frame: Frame): UIScale
	local mevcut = frame:FindFirstChild(OLCEK_ADI)
	if mevcut and mevcut:IsA("UIScale") then
		return mevcut
	end

	local olcek = Instance.new("UIScale")
	olcek.Name = OLCEK_ADI
	olcek.Scale = panelHedef(frame)
	olcek.Parent = frame
	return olcek
end

local function ekrandaMi(nesne: GuiObject): boolean
	local node: Instance? = nesne
	while node do
		if node:IsA("GuiObject") then
			if not node.Visible then
				return false
			end
		elseif node:IsA("LayerCollector") then
			return node.Enabled
		end
		node = node.Parent
	end
	return false
end

local function ilkDugme(panel: Frame): GuiObject?
	local secilen: GuiObject? = nil
	local enY, enX = math.huge, math.huge
	for _, d in panel:GetDescendants() do
		if d:IsA("GuiButton") and d.Selectable and d.Name ~= "Kapat" and ekrandaMi(d) then
			local konum = d.AbsolutePosition
			if konum.Y < enY - 4 or (math.abs(konum.Y - enY) <= 4 and konum.X < enX) then
				secilen = d
				enY, enX = konum.Y, konum.X
			end
		end
	end
	return secilen
end

local function gamepadSecimiKur(frame: Frame)
	if not Girdi.gamepad() then
		return
	end
	task.delay(0.2, function()
		if not frame.Visible then
			return
		end
		local secili = GuiService.SelectedObject
		if secili and secili:IsDescendantOf(frame) then
			return
		end
		local dugme = ilkDugme(frame)
		if dugme then
			GuiService.SelectedObject = dugme
		end
	end)
end

local function gamepadSecimiBirak(frame: Frame)
	local secili = GuiService.SelectedObject
	if secili and secili:IsDescendantOf(frame) then
		GuiService.SelectedObject = nil
	end
end

local function acilisOynat(frame: Frame)
	local olcek = panelOlcegi(frame)
	local hedef = panelHedef(frame)

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

	local olcek = panelHedef(frame)

	local kutu = Instance.new("CanvasGroup")
	kutu.Name = `{frame.Name}Kapanis`
	kutu.AnchorPoint = frame.AnchorPoint
	kutu.Position = frame.Position
	kutu.Size = frame.Size
	kutu.BackgroundTransparency = 1
	kutu.BorderSizePixel = 0
	kutu.ZIndex = frame.ZIndex
	kutu.Parent = parent

	local kutuOlcek = Instance.new("UIScale")
	kutuOlcek.Name = OLCEK_ADI
	kutuOlcek.Scale = olcek
	kutuOlcek.Parent = kutu

	local hayalet = frame:Clone()
	hayalet.Visible = true
	hayalet.AnchorPoint = Vector2.new(0.5, 0.5)
	hayalet.Position = UDim2.fromScale(0.5, 0.5)
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

UI.DokuBoyu = 64
UI.DokuSaydamlik = 0.86

local DOKU_YIV = Color3.fromRGB(0, 0, 0)
local DOKU_ISIK = Color3.fromRGB(255, 255, 255)

local DOKU_EN_COK_CIZGI = 40

local function dokuCizgisi(
	kap: Instance,
	x: number,
	y: number,
	uzunluk: number,
	aci: number,
	renk: Color3
)
	local cizgi = Instance.new("Frame")
	cizgi.Name = "Cizgi"
	cizgi.BorderSizePixel = 0
	cizgi.BackgroundColor3 = renk
	cizgi.AnchorPoint = Vector2.new(0.5, 0.5)
	cizgi.Size = UDim2.fromOffset(uzunluk, 1)
	cizgi.Position = UDim2.fromOffset(x, y)
	cizgi.Rotation = aci
	cizgi.Parent = kap
end

local function dokuAilesi(kap: Instance, en: number, boy: number, aci: number, adim: number)
	local r = math.rad(aci)
	local nx, ny = -math.sin(r), math.cos(r)

	local uzunluk = en + boy
	local adet = math.ceil((en + boy) / (2 * adim))
	local ortaX, ortaY = en / 2, boy / 2

	for k = -adet, adet do
		local x = ortaX + k * adim * nx
		local y = ortaY + k * adim * ny
		dokuCizgisi(kap, x, y, uzunluk, aci, DOKU_YIV)
		dokuCizgisi(kap, x + nx, y + ny, uzunluk, aci, DOKU_ISIK)
	end
end

local function dokuyuKur(kap: Frame, en: number, boy: number)
	for _, cocuk in kap:GetChildren() do
		if cocuk:IsA("Frame") then
			cocuk:Destroy()
		end
	end

	if en <= 0 or boy <= 0 then
		return
	end

	local adim = math.max(UI.DokuBoyu, math.ceil((en + boy) / DOKU_EN_COK_CIZGI))

	dokuAilesi(kap, en, boy, 45, adim)
	dokuAilesi(kap, en, boy, -45, adim)
end

function UI.dokuZemini(cerceve: GuiObject, kose: number?): Frame
	local katman = Instance.new("CanvasGroup")
	katman.Name = "Doku"
	katman.Size = UDim2.fromScale(1, 1)
	katman.BackgroundTransparency = 1
	katman.BorderSizePixel = 0
	katman.GroupTransparency = UI.DokuSaydamlik
	katman.ZIndex = cerceve.ZIndex
	katman.Active = false
	katman.Parent = cerceve

	if kose then
		UI.corner(katman, kose)
	end

	local function tazele()
		local olcu = katman.AbsoluteSize
		dokuyuKur(katman :: any, olcu.X, olcu.Y)
	end

	tazele()
	katman:GetPropertyChangedSignal("AbsoluteSize"):Connect(tazele)

	return katman
end

UI.ListePayi = 5

function UI.listePayi(liste: GuiObject, pay: number?): UIPadding
	local mevcut = liste:FindFirstChildOfClass("UIPadding")
	if mevcut then
		return mevcut
	end

	local p = pay or UI.ListePayi

	local dolgu = Instance.new("UIPadding")
	dolgu.Name = "KenarPayi"
	dolgu.PaddingLeft = UDim.new(0, p)
	dolgu.PaddingRight = UDim.new(0, p)
	dolgu.PaddingTop = UDim.new(0, p)
	dolgu.PaddingBottom = UDim.new(0, p)
	dolgu.Parent = liste

	if liste:IsA("ScrollingFrame") then
		liste.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	end

	return dolgu
end

UI.RobuxIkonOrani = 1.5

local function robuxNesnesi(): Instance?
	local assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
	local ikonlar = assets and assets:FindFirstChild("Icons")
	local node = ikonlar and ikonlar:FindFirstChild("Robux", true)
	return if node and (node:IsA("BasePart") or node:IsA("Model")) then node:Clone() else nil
end

function UI.robuxFiyati(parent: GuiObject, miktar: number, boyut: number, zIndex: number?): Frame
	local Icons = require(Shared:WaitForChild("Icons")) :: any
	local resim = Icons.asset("Robux")
	local nesne = if resim then nil else robuxNesnesi()
	local katman = zIndex or 5
	local ikonBoy = math.floor(boyut * UI.RobuxIkonOrani)

	local kutu = Instance.new("Frame")
	kutu.Name = "Fiyat"
	kutu.AnchorPoint = Vector2.new(0.5, 0.5)
	kutu.Position = UDim2.fromScale(0.5, 0.5)
	kutu.Size = UDim2.fromOffset(0, math.max(ikonBoy, boyut + 4))
	kutu.AutomaticSize = Enum.AutomaticSize.X
	kutu.BackgroundTransparency = 1
	kutu.ZIndex = katman
	kutu.Parent = parent

	local dizilim = Instance.new("UIListLayout")
	dizilim.FillDirection = Enum.FillDirection.Horizontal
	dizilim.VerticalAlignment = Enum.VerticalAlignment.Center
	dizilim.Padding = UDim.new(0, 5)
	dizilim.SortOrder = Enum.SortOrder.LayoutOrder
	dizilim.Parent = kutu

	if resim then
		local ikon = Instance.new("ImageLabel")
		ikon.Name = "Ikon"
		ikon.BackgroundTransparency = 1
		ikon.Image = resim
		ikon.ScaleType = Enum.ScaleType.Fit
		ikon.Size = UDim2.fromOffset(ikonBoy, ikonBoy)
		ikon.LayoutOrder = 1
		ikon.ZIndex = katman
		ikon.Parent = kutu
	elseif nesne then
		local kare = UI.modelKaresi(kutu, nesne, ikonBoy + 4, katman)
		if kare then
			kare.Name = "Ikon"
			kare.LayoutOrder = 1
		end
	end

	local sayi = UI.text({
		text = if resim or nesne then tostring(miktar) else `R$ {miktar}`,
		size = boyut,
		font = UI.Fonts.bold,
		frameSize = UDim2.fromOffset(0, math.max(ikonBoy, boyut + 4)),
		parent = kutu,
		zIndex = katman,
	})
	sayi.AutomaticSize = Enum.AutomaticSize.X
	sayi.LayoutOrder = 2

	return kutu
end

function UI.panel(parent: Instance, size: UDim2, name: string?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name or "Panel"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = size
	frame.BackgroundColor3 = UI.Colors.panel
	frame.BorderSizePixel = 0
	frame.Visible = false
	if parent:IsA("ScreenGui") then
		frame.Parent = UI.panelEkrani() or parent
	else
		frame.Parent = parent
	end
	UI.corner(frame, 14)
	UI.stroke(frame, UI.Colors.accent, 1)
	UI.dokuZemini(frame, 14)

	table.insert(paneller, frame)
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if frame.Visible then
			digerPanelleriKapat(frame)
			acilisOynat(frame)
			gamepadSecimiKur(frame)
		else
			gamepadSecimiBirak(frame)
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

	UI.hover(button)

	return button
end

function UI.closeButton(parent: Instance): TextButton
	local button = Instance.new("TextButton")
	button.Name = "Kapat"
	button.Size = UDim2.fromOffset(34, 34)
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

	UI.hover(button, nil, button)

	if parent:GetAttribute("RenkliBaslik") then
		button.Position = UDim2.new(1, -18, 0, 18)
		button.ZIndex = 6
		UI.stroke(button, Color3.fromRGB(0, 0, 0), 2)
	end

	return button
end

UI.HoverTime = 0.12
UI.HoverLift = 0.12
UI.HoverPop = 1.06
UI.PressPop = 0.96

function UI.hover(button: GuiButton, face: GuiObject?, pop: GuiObject?)
	local renkli: GuiObject = face or button

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

	button.SelectionGained:Connect(function()
		oynat(true, UI.HoverPop)
	end)

	button.SelectionLost:Connect(function()
		oynat(false, 1)
	end)
end

function UI.shade(color: Color3, amount: number): Color3
	local h, sat, v = color:ToHSV()
	return Color3.fromHSV(h, math.clamp(sat - amount * 0.1, 0, 1), math.clamp(v + amount, 0, 1))
end

function UI.stripeLayer(parent: GuiObject, tint: Color3, rotation: number, count: number, alpha: number): CanvasGroup
	local layer = Instance.new("CanvasGroup")
	layer.Name = "Desen"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	layer.BorderSizePixel = 0
	layer.ClipsDescendants = true
	layer.ZIndex = parent.ZIndex
	layer.Parent = parent

	local ENLER = { 0.075, 0.025, 0.05, 0.02, 0.04 }

	local BOY = 1 / math.cos(math.rad(rotation)) + 0.07

	local step = 1 / count

	for i = 0, count - 1 do
		local serit = Instance.new("Frame")
		serit.Name = "Serit"
		serit.AnchorPoint = Vector2.new(0.5, 0.5)
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

function UI.caprazDesen(parent: GuiObject, tint: Color3?, count: number?)
	UI.stripeLayer(parent, tint or Color3.fromRGB(255, 255, 255), 32, count or 5, 0.88)
end

function UI.gloss(parent: GuiObject, strength: number?): Frame
	local layer = Instance.new("Frame")
	layer.Name = "Parlaklik"
	layer.Size = UDim2.new(1, 0, 0.5, 0)
	layer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	layer.BorderSizePixel = 0
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
		for _, child in face:GetChildren() do
			if child:IsA("GuiObject") and (child.Name == "Desen" or child.Name == "Parlaklik") then
				UI.corner(child, radius)
			end
		end
	end
end

UI.ScaleMin = 50
UI.ScaleMax = 150
UI.ScaleStep = 5
UI.ScaleDefault = 100

UI.ScaleBase = 1.25

local function gercekOlcek(yuzde: number): number
	return yuzde / 100 * UI.ScaleBase * ekranCarpani()
end

local olcekYuzde = UI.ScaleDefault
local izlenenGui: { [Instance]: boolean } = {}
local olcekDinleyicileri: { (yuzde: number) -> () } = {}

function UI.carpan(): number
	return gercekOlcek(olcekYuzde)
end

function UI.nesneCarpani(nesne: Instance): number
	local carpan = gercekOlcek(olcekYuzde)
	if Girdi.dokunmatik() then
		local ek = nesne:GetAttribute(UI.DokunmatikOlcekNiteligi)
		if type(ek) == "number" and ek > 0 then
			carpan *= ek
		end
	end
	return carpan
end

local function nesneyeUygula(nesne: Instance)
	if not nesne:IsA("GuiObject") then
		return
	end

	local baskaOlcek = nesne:FindFirstChildOfClass("UIScale")
	if baskaOlcek and baskaOlcek.Name ~= OLCEK_ADI then
		return
	end

	local hedef = if nesne:IsA("Frame") and table.find(paneller, nesne)
		then panelHedef(nesne)
		else UI.nesneCarpani(nesne)

	local mevcut = nesne:FindFirstChild(OLCEK_ADI)
	if mevcut and mevcut:IsA("UIScale") then
		mevcut.Scale = hedef
		return
	end

	local olcek = Instance.new("UIScale")
	olcek.Name = OLCEK_ADI
	olcek.Scale = hedef
	olcek.Parent = nesne
end

UI.OlcekDisiNitelik = "OlcekDisi"

local function guiIzle(gui: Instance)
	if not gui:IsA("ScreenGui") then
		return
	end
	if gui:GetAttribute(UI.OlcekDisiNitelik) == true then
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

function UI.getScale(): number
	return olcekYuzde
end

function UI.setScale(yuzde: number): number
	local yeni = math.clamp(math.round(yuzde), UI.ScaleMin, UI.ScaleMax)
	olcekYuzde = yeni

	hepsineUygula()

	for _, dinleyici in olcekDinleyicileri do
		task.spawn(dinleyici, yeni)
	end

	return yeni
end

function UI.dokunmatikOlcekVer(nesne: GuiObject, carpan: number)
	if nesne:GetAttribute(UI.DokunmatikOlcekNiteligi) == carpan then
		return
	end
	nesne:SetAttribute(UI.DokunmatikOlcekNiteligi, carpan)
	nesneyeUygula(nesne)
	for _, dinleyici in olcekDinleyicileri do
		task.spawn(dinleyici, olcekYuzde)
	end
end

function UI.onScaleChanged(dinleyici: (yuzde: number) -> ())
	table.insert(olcekDinleyicileri, dinleyici)
end

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

do
	local bekliyor = false
	local function ekranDegisti()
		if bekliyor then
			return
		end
		bekliyor = true
		task.defer(function()
			bekliyor = false
			hepsineUygula()
			for _, dinleyici in olcekDinleyicileri do
				task.spawn(dinleyici, olcekYuzde)
			end
		end)
	end

	local kameraBagi: RBXScriptConnection? = nil
	local function kamerayiIzle()
		if kameraBagi then
			kameraBagi:Disconnect()
			kameraBagi = nil
		end
		local kamera = workspace.CurrentCamera
		if kamera then
			kameraBagi = kamera:GetPropertyChangedSignal("ViewportSize"):Connect(ekranDegisti)
		end
		ekranDegisti()
	end

	kamerayiIzle()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(kamerayiIzle)
	Girdi.degisince(ekranDegisti)
end

ContextActionService:BindActionAtPriority("PanelKapatGamepad", function(_, durum)
	if durum ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	for i = #paneller, 1, -1 do
		local panel = paneller[i]
		if panel.Parent and panel.Visible then
			panel.Visible = false
			return Enum.ContextActionResult.Sink
		end
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonB)

function UI.acikPanelVarMi(): boolean
	for _, panel in paneller do
		if panel.Parent and panel.Visible then
			return true
		end
	end
	return false
end

task.spawn(function()
	local player = Players.LocalPlayer
	local playerGui = player and player:WaitForChild("PlayerGui", 10)
	if not playerGui then
		return
	end

	local secim = Instance.new("Frame")
	secim.Name = "GamepadSecimi"
	secim.BackgroundTransparency = 1
	secim.Position = UDim2.fromOffset(-5, -5)
	secim.Size = UDim2.new(1, 10, 1, 10)
	UI.corner(secim, 12)
	local cizgi = UI.stroke(secim, Color3.fromRGB(255, 225, 60), 4)
	cizgi.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	TweenService:Create(
		cizgi,
		TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.45, Thickness = 6 }
	):Play()

	pcall(function()
		(playerGui :: any).SelectionImageObject = secim
	end)
end)

local SIYAH = Color3.fromRGB(0, 0, 0)
local BEYAZ = Color3.fromRGB(255, 255, 255)
local DUGME_LIP = 5

UI.KapaliRenk = Color3.fromRGB(105, 110, 124)

local function katmanKoseleri(yuz: GuiObject, yaricap: number)
	for _, cocuk in yuz:GetChildren() do
		if cocuk:IsA("GuiObject") and (cocuk.Name == "Desen" or cocuk.Name == "Parlaklik") then
			UI.corner(cocuk, yaricap)
		end
	end
end

function UI.baslikCubugu(
	panel: Frame,
	yazi: string,
	renkA: Color3,
	renkB: Color3,
	ikonId: string?,
	zeminRenk: Color3?
): (Frame, TextLabel)
	local kontur = panel:FindFirstChildOfClass("UIStroke")
	if kontur then
		kontur.Color = SIYAH
		kontur.Thickness = 3
	end

	local taban = zeminRenk or UI.Colors.panel
	panel.BackgroundColor3 = BEYAZ
	local zemin = Instance.new("UIGradient")
	zemin.Name = "PanelRengi"
	zemin.Rotation = 90
	zemin.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, taban:Lerp(renkA, 0.22)),
		ColorSequenceKeypoint.new(0.45, taban:Lerp(renkB, 0.08)),
		ColorSequenceKeypoint.new(1, taban),
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
	dugme.SelectionGained:Connect(function()
		ustunde = true
		ciz(false)
	end)
	dugme.SelectionLost:Connect(function()
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

UI.HackerZemin = Color3.fromRGB(10, 12, 12)
UI.HackerYesil = Color3.fromRGB(90, 255, 140)

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
	sayi: number,
	uzunluk: number,
	kalinlik: number,
	tur: number,
	parlaklik: number,
	zIndex: number,
	renk: Color3?,
}

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

	local donus = TweenService:Create(
		isik,
		TweenInfo.new(ayar.tur, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{ Rotation = 360 }
	)
	donus:Play()

	return isik
end

function UI.sayiYagmuru(
	parent: GuiObject,
	renk: Color3,
	sutun: number,
	zIndex: number,
	hiz: number?,
	koyuluk: number?
): CanvasGroup
	local kap = Instance.new("CanvasGroup")
	kap.Name = "SayiYagmuru"
	kap.Size = UDim2.fromScale(1, 1)
	kap.BackgroundTransparency = 1
	kap.BorderSizePixel = 0
	kap.ClipsDescendants = true
	kap.ZIndex = zIndex
	kap.Parent = parent

	local rastgele = Random.new()
	local SATIR = 14
	local sure = hiz or 5
	local taban = koyuluk or 0.55

	for i = 1, sutun do
		local yarim = {}
		for _ = 1, SATIR do
			table.insert(yarim, tostring(rastgele:NextInteger(0, 1)))
		end
		local metin = table.concat(yarim, "\n")

		local sutunYazi = Instance.new("TextLabel")
		sutunYazi.Name = "Sutun"
		sutunYazi.BackgroundTransparency = 1
		sutunYazi.Size = UDim2.new(1 / sutun, 0, 2, 0)
		sutunYazi.Position = UDim2.new((i - 1) / sutun, 0, -1, 0)
		sutunYazi.Text = `{metin}\n{metin}`
		sutunYazi.TextColor3 = renk
		sutunYazi.TextTransparency = rastgele:NextNumber(taban, taban + 0.2)
		sutunYazi.TextSize = 16
		sutunYazi.Font = Enum.Font.Code
		sutunYazi.TextXAlignment = Enum.TextXAlignment.Center
		sutunYazi.TextYAlignment = Enum.TextYAlignment.Top
		sutunYazi.ZIndex = zIndex
		sutunYazi.Parent = kap

		TweenService:Create(
			sutunYazi,
			TweenInfo.new(
				rastgele:NextNumber(sure * 0.7, sure * 1.3),
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.InOut,
				-1,
				false,
				rastgele:NextNumber(0, sure * 0.4)
			),
			{ Position = UDim2.new((i - 1) / sutun, 0, 0, 0) }
		):Play()
	end

	return kap
end

export type YagmurAyari = {
	renk: Color3,
	sayi: number?,
	boyut: number?,
	sure: number?,
	sekil: string?,
	saydam: number?,
	zIndex: number?,
}

function UI.parcaYagmuru(parent: GuiObject, ayar: YagmurAyari): CanvasGroup
	local kap = Instance.new("CanvasGroup")
	kap.Name = "ParcaYagmuru"
	kap.Size = UDim2.fromScale(1, 1)
	kap.BackgroundTransparency = 1
	kap.BorderSizePixel = 0
	kap.ClipsDescendants = true
	kap.ZIndex = ayar.zIndex or 2
	kap.Parent = parent

	local rastgele = Random.new()
	local adet = ayar.sayi or 14
	local boyut = ayar.boyut or 10
	local sure = ayar.sure or 4
	local sekil = ayar.sekil or "elmas"
	local saydam = ayar.saydam or 0.35

	for i = 1, adet do
		local olcek = rastgele:NextNumber(0.65, 1.25)
		local kenar = math.floor(boyut * olcek)

		local parca = Instance.new("Frame")
		parca.Name = "Parca"
		parca.AnchorPoint = Vector2.new(0.5, 0.5)
		parca.Size = UDim2.fromOffset(kenar, kenar)
		parca.Position = UDim2.new(rastgele:NextNumber(0.03, 0.97), 0, -0.2, 0)
		parca.BackgroundColor3 = ayar.renk
		parca.BackgroundTransparency = math.clamp(saydam + (1.25 - olcek) * 0.25, 0, 0.95)
		parca.BorderSizePixel = 0
		parca.Rotation = if sekil == "elmas" then 45 else 0
		parca.ZIndex = kap.ZIndex
		parca.Parent = kap

		if sekil == "daire" then
			local yuvarlak = Instance.new("UICorner")
			yuvarlak.CornerRadius = UDim.new(1, 0)
			yuvarlak.Parent = parca
		elseif sekil == "kare" then
			UI.corner(parca, 2)
		end

		local gecis = Instance.new("UIGradient")
		gecis.Rotation = 90
		gecis.Color = ColorSequence.new(Color3.new(1, 1, 1), ayar.renk)
		gecis.Parent = parca

		local inis = rastgele:NextNumber(sure * 0.7, sure * 1.4) / olcek
		TweenService:Create(
			parca,
			TweenInfo.new(inis, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, rastgele:NextNumber(0, sure)),
			{ Position = UDim2.new(parca.Position.X.Scale, 0, 1.2, 0) }
		):Play()

		if sekil == "elmas" then
			TweenService:Create(
				parca,
				TweenInfo.new(rastgele:NextNumber(4, 9), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
				{ Rotation = 45 + 360 }
			):Play()
		end
	end

	return kap
end

function UI.canliZemin(parent: GuiObject, renk: Color3, kose: number?, zIndex: number?): Frame
	local z = zIndex or 0
	local yaricap = kose or 12

	local kap = Instance.new("Frame")
	kap.Name = "CanliZemin"
	kap.Size = UDim2.fromScale(1, 1)
	kap.BackgroundColor3 = Color3.new(1, 1, 1)
	kap.BorderSizePixel = 0
	kap.ClipsDescendants = true
	kap.ZIndex = z
	kap.Parent = parent
	UI.corner(kap, yaricap)

	local zemin = Instance.new("UIGradient")
	zemin.Rotation = 90
	zemin.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UI.shade(renk, 0.24)),
		ColorSequenceKeypoint.new(0.45, renk),
		ColorSequenceKeypoint.new(1, UI.shade(renk, -0.3)),
	})
	zemin.Parent = kap

	for i, aci in { 26, -26 } do
		local doku = UI.stripeLayer(kap, Color3.new(1, 1, 1), aci, 4, if i == 1 then 0.88 else 0.92)
		doku.ZIndex = z
		UI.corner(doku, yaricap)

		local gecis = doku:FindFirstChildOfClass("UIGradient")
		if gecis then
			gecis.Offset = Vector2.new(if i == 1 then -0.5 else 0.5, 0)
			TweenService:Create(
				gecis,
				TweenInfo.new(if i == 1 then 9 else 12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
				{ Offset = Vector2.new(if i == 1 then 0.5 else -0.5, 0) }
			):Play()
		end
	end

	local isik = Instance.new("Frame")
	isik.Name = "Tarama"
	isik.Size = UDim2.fromScale(1, 1)
	isik.BackgroundColor3 = Color3.new(1, 1, 1)
	isik.BorderSizePixel = 0
	isik.ZIndex = z
	isik.Parent = kap
	UI.corner(isik, yaricap)

	local bant = Instance.new("UIGradient")
	bant.Rotation = 18
	bant.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.42, 1),
		NumberSequenceKeypoint.new(0.5, 0.72),
		NumberSequenceKeypoint.new(0.58, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	bant.Offset = Vector2.new(-1.3, 0)
	bant.Parent = isik
	TweenService:Create(
		bant,
		TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 1.6),
		{ Offset = Vector2.new(1.3, 0) }
	):Play()

	return kap
end

UI.BlokArkaPlani = {
	Diamond = "diamondbackground",
	Golden = "goldenbackground",
	Hacker = "hackerbackground",
} :: { [string]: string }

local ARKA_PLAN_KLASORU = "Backgrounds"
local ARKA_PLAN_SAYDAM = 0.45
local MAGAZA_SAYDAM = 0.12
local ARKA_PLAN_YAYILMA = 3

function UI.blokTemasi(kart: GuiObject, tierId: string?, zIndex: number?, kose: number?, renk: Color3?): GuiObject?
	if type(tierId) ~= "string" then
		return nil
	end

	local z = zIndex or 2
	local yaricap = kose or 12
	local kap: GuiObject? = nil

	local resimAdi = UI.BlokArkaPlani[tierId]
	local resim = if resimAdi then Icons.assetKlasorden(ARKA_PLAN_KLASORU, resimAdi) else nil
	local saydam = ARKA_PLAN_SAYDAM

	if not resim then
		local kucuk = string.lower(tierId)
		resim = Icons.assetTam(`rc_bg_{kucuk}`)
			or Icons.asset(`rc_bg_{kucuk}`)
			or Icons.assetTam("rc_bg")
			or Icons.asset("rc_bg")
		saydam = MAGAZA_SAYDAM
	end

	if resim then
		UI.corner(UI.yumusakResim(kart, resim, saydam, ARKA_PLAN_YAYILMA, z), yaricap)
	elseif renk then
		UI.canliZemin(kart, renk, yaricap, z)
	end

	if tierId == "Hacker" then
		kap = UI.sayiYagmuru(kart, UI.HackerYesil, 18, z, 1.8, 0.32)
	elseif tierId == "Diamond" then
		kap = UI.parcaYagmuru(kart, {
			renk = Color3.fromRGB(150, 235, 255),
			sayi = 16,
			boyut = 11,
			sure = 4.5,
			sekil = "elmas",
			saydam = 0.3,
			zIndex = z,
		})
	elseif tierId == "Golden" then
		kap = UI.parcaYagmuru(kart, {
			renk = Color3.fromRGB(255, 225, 120),
			sayi = 14,
			boyut = 10,
			sure = 5.5,
			sekil = "daire",
			saydam = 0.32,
			zIndex = z,
		})
	end

	if kap then
		UI.corner(kap, yaricap)
	end
	return kap
end

function UI.modelKaresi(parent: GuiObject, model: Instance, boyut: number, zIndex: number): ViewportFrame?
	local govde: Instance = model
	if model:IsA("Tool") then
		local kap = Instance.new("Model")
		for _, cocuk in model:GetChildren() do
			if cocuk:IsA("BasePart") then
				cocuk.Parent = kap
			end
		end
		model:Destroy()
		govde = kap
	end

	local kok: BasePart? = nil
	if govde:IsA("BasePart") then
		kok = govde
	elseif govde:IsA("Model") then
		kok = govde.PrimaryPart or govde:FindFirstChildWhichIsA("BasePart", true)
	end

	if not kok then
		govde:Destroy()
		return nil
	end

	for _, node in govde:GetDescendants() do
		if
			node:IsA("BaseScript")
			or node:IsA("Sound")
			or node:IsA("ParticleEmitter")
			or node:IsA("Beam")
			or node:IsA("Trail")
		then
			node:Destroy()
		end
	end

	for _, parca in govde:GetDescendants() do
		if parca:IsA("BasePart") then
			parca.Anchored = true
			parca.CanCollide = false
		end
	end
	if kok:IsA("BasePart") then
		kok.Anchored = true
		kok.CanCollide = false
	end

	local vp = Instance.new("ViewportFrame")
	vp.Name = "ModelKaresi"
	vp.Size = UDim2.fromOffset(boyut, boyut)
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(255, 255, 255)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.LightDirection = Vector3.new(-0.4, -0.7, -0.6)
	vp.ZIndex = zIndex
	vp.Parent = parent

	govde.Parent = vp

	local kamera = Instance.new("Camera")
	kamera.Parent = vp
	vp.CurrentCamera = kamera

	local merkez, olcu

	do
		local enAz: Vector3? = nil
		local enCok: Vector3? = nil

		for _, parca in govde:GetDescendants() do
			if not parca:IsA("BasePart") or parca.Transparency >= 0.99 then
				continue
			end

			local cf, boyut = parca.CFrame, parca.Size
			for _, sx in { -0.5, 0.5 } do
				for _, sy in { -0.5, 0.5 } do
					for _, sz in { -0.5, 0.5 } do
						local kose = (cf * CFrame.new(boyut.X * sx, boyut.Y * sy, boyut.Z * sz)).Position
						enAz = if enAz then enAz:Min(kose) else kose
						enCok = if enCok then enCok:Max(kose) else kose
					end
				end
			end
		end

		if govde:IsA("BasePart") and govde.Transparency < 0.99 then
			local cf, boyut = (govde :: BasePart).CFrame, (govde :: BasePart).Size
			for _, sx in { -0.5, 0.5 } do
				for _, sy in { -0.5, 0.5 } do
					for _, sz in { -0.5, 0.5 } do
						local kose = (cf * CFrame.new(boyut.X * sx, boyut.Y * sy, boyut.Z * sz)).Position
						enAz = if enAz then enAz:Min(kose) else kose
						enCok = if enCok then enCok:Max(kose) else kose
					end
				end
			end
		end

		if enAz and enCok then
			merkez, olcu = (enAz + enCok) / 2, enCok - enAz
		elseif govde:IsA("Model") then
			local cf, size = (govde :: Model):GetBoundingBox()
			merkez, olcu = cf.Position, size
		else
			merkez, olcu = kok.Position, kok.Size
		end
	end

	local uzaklik = math.max(olcu.Magnitude * 0.85, 1)
	kamera.CFrame = CFrame.lookAt(merkez + Vector3.new(0, 0, -1) * uzaklik, merkez)

	return vp
end

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
		kat.ImageTransparency = if i == 1 then saydamlik else saydamlik + (1 - saydamlik) * 0.6
		kat.ZIndex = zIndex
		kat.Parent = kap
	end

	return kap
end

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

function UI.pariltilar(parent: GuiObject, renk: Color3, sayi: number, zIndex: number, rakam: boolean?): Frame
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

		local kivilcim: GuiObject
		if rakam then
			local yazi = Instance.new("TextLabel")
			yazi.BackgroundTransparency = 1
			yazi.Size = UDim2.fromOffset(boy * 2, boy * 2)
			yazi.Text = tostring(rastgele:NextInteger(0, 1))
			yazi.TextColor3 = renk
			yazi.TextTransparency = 1
			yazi.TextSize = rastgele:NextInteger(14, 26)
			yazi.Font = Enum.Font.Code
			kivilcim = yazi
		else
			local kare = Instance.new("Frame")
			kare.Size = UDim2.fromOffset(boy, boy)
			kare.Rotation = 45
			kare.BackgroundColor3 = renk
			kare.BackgroundTransparency = 1
			kare.BorderSizePixel = 0
			kivilcim = kare
		end

		kivilcim.Name = "Kivilcim"
		kivilcim.AnchorPoint = Vector2.new(0.5, 0.5)
		kivilcim.Position = UDim2.fromScale(rastgele:NextNumber(0.05, 0.95), rastgele:NextNumber(0.05, 0.95))
		kivilcim.ZIndex = zIndex
		kivilcim.Parent = kap

		local sure = TweenInfo.new(
			rastgele:NextNumber(0.5, 1.1),
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1,
			true,
			rastgele:NextNumber(0, 1.2)
		)

		if rakam then
			TweenService:Create(kivilcim, sure, { TextTransparency = 0.12 }):Play()
		else
			TweenService:Create(kivilcim, sure, { BackgroundTransparency = 0.1 }):Play()
		end
	end

	return kap
end

function UI.bildirimNoktasi(hedef: GuiObject, zIndex: number?): (acik: boolean) -> ()
	local NOKTA = 16

	local nokta = Instance.new("Frame")
	nokta.Name = "Bildirim"
	nokta.AnchorPoint = Vector2.new(0.5, 0.5)
	nokta.Position = UDim2.new(1, -3, 0, 3)
	nokta.Size = UDim2.fromOffset(NOKTA, NOKTA)
	nokta.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	nokta.BorderSizePixel = 0
	nokta.Visible = false
	nokta.ZIndex = zIndex or 10
	nokta.Parent = hedef
	UI.corner(nokta, NOKTA / 2)
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
