--!strict
--[[
	=====================================================================
	KABARTMA BUTON  --  cizgi film / simulator arayuz stili
	=====================================================================

	Referans: populer simulator oyunlarindaki "RETRY" tarzi buton.
	3D kabartma, canli dikey gradyan, kalin siyah cerceve, ic doku ve
	basma animasyonu.

	KULLANIM

	    local Kabartma = require(script.Parent.Kabartma)

	    local buton = Kabartma.new({
	        parent = ekran,
	        size = UDim2.fromOffset(240, 70),
	        position = UDim2.fromScale(0.5, 0.5),
	        anchor = Vector2.new(0.5, 0.5),
	        color = Color3.fromRGB(255, 178, 40),
	        text = "RETRY",
	        onClick = function()
	            print("basildi")
	        end,
	    })

	    -- Sonradan degistirmek icin:
	    buton.setText("TEKRAR")
	    buton.setColor(Color3.fromRGB(90, 200, 120))

	DONEN TABLO
	    root      dis govde (ImageButton)  -- konumlandirma bunun uzerinden
	    face      yuz (Frame)              -- ustune ekleyecegin her sey buraya
	    setText / setColor / setEnabled

	BAGIMSIZ CALISIR
	Hicbir sey require etmez; StarterGui icine LocalScript olarak da
	yapistirabilirsin (o durumda asagidaki ORNEK bolumunu acik birak).
]]

local TweenService = game:GetService("TweenService")

local Kabartma = {}

------------------------------------------------------------------
-- AYARLAR
------------------------------------------------------------------
local AYAR = {
	-- Alt kabartmanin yuksekligi (3D derinlik)
	lip = 6,
	-- Yuzun kenardan iceri girme miktari
	inset = 4,
	-- Kose yuvarlakligi (oranli: buton boyutuna gore olceklenir)
	corner = UDim.new(0.2, 0),
	-- Dis cerceve
	strokeThickness = 5,
	strokeColor = Color3.fromRGB(0, 0, 0),
	-- Animasyon
	hoverScale = 1.05,
	pressScale = 0.95,
	tweenTime = 0.12,
}

local TWEEN = TweenInfo.new(AYAR.tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

------------------------------------------------------------------
-- RENK YARDIMCISI
------------------------------------------------------------------

-- amount > 0 aydinlatir, < 0 karartir
local function shade(color: Color3, amount: number): Color3
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, math.clamp(s - amount * 0.1, 0, 1), math.clamp(v + amount, 0, 1))
end

------------------------------------------------------------------
-- DOKU (grid / capraz desen)
------------------------------------------------------------------

--[[
	HAZIR DESEN GORSELI KULLANMAK ISTERSEN

	Roblox'ta tekrarlayan desen icin ImageLabel'i DOSEME (Tile) modunda
	kullanirsin. Kendi desen gorselini yukleyip id'sini yazman yeterli:

	    local desen = Instance.new("ImageLabel")
	    desen.Size = UDim2.fromScale(1, 1)
	    desen.BackgroundTransparency = 1
	    desen.Image = "rbxassetid://SENIN_DESEN_IDN"
	    desen.ScaleType = Enum.ScaleType.Tile
	    -- Tek bir karonun boyutu; kucultursen desen siklasir
	    desen.TileSize = UDim2.fromOffset(24, 24)
	    -- 0 = tam gorunur, 1 = gorunmez. 0.85 civari dokuyu belli eder
	    desen.ImageTransparency = 0.85
	    -- Desenin rengi butonun renginden gelsin istiyorsan:
	    desen.ImageColor3 = Color3.fromRGB(255, 255, 255)
	    desen.ZIndex = 2
	    desen.Parent = face

	Desen gorseli 45 derecelik ince cizgilerden olusan, kenarlari birbirine
	uyan (seamless) kare bir PNG olmali; yoksa karolarin birlesim yerleri
	belli olur.

	ASAGIDAKI KOD GORSEL GEREKTIRMEZ: ayni dokuyu gradyanla uretir.
]]

--[[
	Tek yonlu serit katmani.

	NEDEN GRADYAN: desen dondurulmus Frame'lerle yapilinca Roblox'ta
	ClipsDescendants onlari KIRPMIYOR ve desen butonun disina tasiyor.
	UIGradient'in saydamlik dizisi her zaman kendi cercevesinde kalir.
]]
local function seritKatmani(parent: GuiObject, rotation: number, count: number, alpha: number)
	local layer = Instance.new("Frame")
	layer.Name = "Desen"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	layer.BorderSizePixel = 0
	layer.ZIndex = 2
	layer.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = AYAR.corner
	corner.Parent = layer

	local step = 1 / count
	local band = step * 0.42
	local points: { NumberSequenceKeypoint } = { NumberSequenceKeypoint.new(0, 1) }

	for i = 0, count - 1 do
		local basla = step * 0.3 + i * step
		local bitis = basla + band
		if bitis < 0.99 then
			table.insert(points, NumberSequenceKeypoint.new(basla, 1))
			table.insert(points, NumberSequenceKeypoint.new(basla + 0.002, alpha))
			table.insert(points, NumberSequenceKeypoint.new(bitis, alpha))
			table.insert(points, NumberSequenceKeypoint.new(bitis + 0.002, 1))
		end
	end

	table.insert(points, NumberSequenceKeypoint.new(1, 1))

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Transparency = NumberSequence.new(points)
	gradient.Parent = layer
end

------------------------------------------------------------------
-- BUTON
------------------------------------------------------------------

export type Options = {
	parent: Instance,
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	color: Color3?,
	text: string?,
	textColor: Color3?,
	layoutOrder: number?,
	onClick: (() -> ())?,
}

function Kabartma.new(options: Options)
	local color = options.color or Color3.fromRGB(255, 178, 40)

	--------------------------------------------------------------
	-- 1) DIS GOVDE  --  ayni zamanda alt kabartma (koyu ton)
	--------------------------------------------------------------
	local root = Instance.new("ImageButton")
	root.Name = "KabartmaButon"
	root.Size = options.size or UDim2.fromOffset(220, 68)
	root.Position = options.position or UDim2.fromOffset(0, 0)
	root.AnchorPoint = options.anchor or Vector2.zero
	root.LayoutOrder = options.layoutOrder or 0
	root.BackgroundColor3 = shade(color, -0.34)
	root.BorderSizePixel = 0
	root.AutoButtonColor = false
	root.Image = ""
	root.Parent = options.parent

	local rootCorner = Instance.new("UICorner")
	rootCorner.CornerRadius = AYAR.corner
	rootCorner.Parent = root

	--------------------------------------------------------------
	-- 2) DIS CERCEVE  --  kalin siyah kontur
	--------------------------------------------------------------
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = AYAR.strokeThickness
	stroke.Color = AYAR.strokeColor
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = root

	--------------------------------------------------------------
	-- 3) OLCEKLEME  --  hover/tiklama animasyonu icin
	--
	-- Size yerine UIScale kullaniliyor: buton bir UIListLayout ya da
	-- UIGridLayout icindeyse Size'i degistirmek diziyi bozar, UIScale
	-- ise yalnizca cizimi olcekler.
	--------------------------------------------------------------
	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = root

	--------------------------------------------------------------
	-- 4) YUZ  --  asil renk, alt kabartmayi acikta birakir
	--------------------------------------------------------------
	local face = Instance.new("Frame")
	face.Name = "Yuz"
	face.Size = UDim2.new(1, -AYAR.inset * 2, 1, -AYAR.inset * 2 - AYAR.lip)
	face.Position = UDim2.fromOffset(AYAR.inset, AYAR.inset)
	face.BackgroundColor3 = color
	face.BorderSizePixel = 0
	-- Desen ve parlaklik kenardan tasmasin
	face.ClipsDescendants = true
	face.ZIndex = 1
	face.Parent = root

	local faceCorner = Instance.new("UICorner")
	faceCorner.CornerRadius = AYAR.corner
	faceCorner.Parent = face

	--------------------------------------------------------------
	-- 5) DIKEY GRADYAN  --  ustu parlak, alti koyu
	--------------------------------------------------------------
	local gradient = Instance.new("UIGradient")
	gradient.Name = "Gradyan"
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, shade(color, 0.24)),
		ColorSequenceKeypoint.new(0.55, color),
		ColorSequenceKeypoint.new(1, shade(color, -0.16)),
	})
	gradient.Parent = face

	--------------------------------------------------------------
	-- 6) DOKU  --  iki capraz serit katmani = elmas izgara
	--------------------------------------------------------------
	seritKatmani(face, 32, 5, 0.86)
	seritKatmani(face, -32, 5, 0.9)

	--------------------------------------------------------------
	-- 7) UST PARLAKLIK  --  cam yansimasi
	--------------------------------------------------------------
	local gloss = Instance.new("Frame")
	gloss.Name = "Parlaklik"
	gloss.Size = UDim2.new(1, 0, 0.5, 0)
	gloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	gloss.BorderSizePixel = 0
	gloss.ZIndex = 3
	gloss.Parent = face

	local glossCorner = Instance.new("UICorner")
	glossCorner.CornerRadius = AYAR.corner
	glossCorner.Parent = gloss

	local glossGradient = Instance.new("UIGradient")
	glossGradient.Rotation = 90
	glossGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.72),
		NumberSequenceKeypoint.new(1, 1),
	})
	glossGradient.Parent = gloss

	--------------------------------------------------------------
	-- 8) IC GOLGE  --  alt kenarda karartma, derinlik hissi
	--------------------------------------------------------------
	local innerShadow = Instance.new("Frame")
	innerShadow.Name = "IcGolge"
	innerShadow.Size = UDim2.new(1, 0, 0.4, 0)
	innerShadow.Position = UDim2.fromScale(0, 0.6)
	innerShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	innerShadow.BorderSizePixel = 0
	innerShadow.ZIndex = 3
	innerShadow.Parent = face

	local shadowGradient = Instance.new("UIGradient")
	shadowGradient.Rotation = 90
	shadowGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.78),
	})
	shadowGradient.Parent = innerShadow

	--------------------------------------------------------------
	-- 9) YAZI
	--------------------------------------------------------------
	local label = Instance.new("TextLabel")
	label.Name = "Yazi"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = options.text or ""
	label.TextColor3 = options.textColor or Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.TextStrokeTransparency = 1
	label.ZIndex = 5
	label.Parent = face

	local labelStroke = Instance.new("UIStroke")
	labelStroke.Thickness = 3
	labelStroke.Color = Color3.fromRGB(0, 0, 0)
	labelStroke.LineJoinMode = Enum.LineJoinMode.Round
	labelStroke.Parent = label

	local labelPadding = Instance.new("UIPadding")
	labelPadding.PaddingLeft = UDim.new(0, 10)
	labelPadding.PaddingRight = UDim.new(0, 10)
	labelPadding.PaddingTop = UDim.new(0, 6)
	labelPadding.PaddingBottom = UDim.new(0, 6)
	labelPadding.Parent = label

	--------------------------------------------------------------
	-- 10) ANIMASYON  --  hover buyur, tiklayinca coker
	--------------------------------------------------------------
	local basili = false
	local uzerinde = false

	local function olcekle(hedef: number)
		TweenService:Create(scale, TWEEN, { Scale = hedef }):Play()
	end

	local function yuzKonumu(asagi: boolean)
		local hedef = UDim2.fromOffset(AYAR.inset, if asagi then AYAR.inset + AYAR.lip else AYAR.inset)
		TweenService:Create(face, TWEEN, { Position = hedef }):Play()
	end

	root.MouseEnter:Connect(function()
		uzerinde = true
		if not basili then
			olcekle(AYAR.hoverScale)
		end
	end)

	root.MouseLeave:Connect(function()
		uzerinde = false
		basili = false
		olcekle(1)
		yuzKonumu(false)
	end)

	root.MouseButton1Down:Connect(function()
		basili = true
		olcekle(AYAR.pressScale)
		yuzKonumu(true)
	end)

	root.MouseButton1Up:Connect(function()
		basili = false
		olcekle(if uzerinde then AYAR.hoverScale else 1)
		yuzKonumu(false)
	end)

	if options.onClick then
		root.MouseButton1Click:Connect(options.onClick)
	end

	--------------------------------------------------------------
	-- DISARIYA ACILAN ARAYUZ
	--------------------------------------------------------------
	return {
		root = root,
		face = face,
		label = label,

		setText = function(text: string)
			label.Text = text
		end,

		--[[
			Rengi degistirir; gradyan ve alt kabartma da birlikte guncellenir,
			boylece tek satirla butonun tum tonlamasi degisir.
		]]
		setColor = function(newColor: Color3)
			face.BackgroundColor3 = newColor
			root.BackgroundColor3 = shade(newColor, -0.34)
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, shade(newColor, 0.24)),
				ColorSequenceKeypoint.new(0.55, newColor),
				ColorSequenceKeypoint.new(1, shade(newColor, -0.16)),
			})
		end,

		-- Kilitli gorunum: soluklasir ve tiklanamaz
		setEnabled = function(enabled: boolean)
			root.Active = enabled
			root.AutoButtonColor = false
			face.BackgroundTransparency = if enabled then 0 else 0.45
			label.TextTransparency = if enabled then 0 else 0.5
		end,
	}
end

return Kabartma
