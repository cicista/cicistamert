--[[
	SeviyeArayuz  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > SeviyeArayuz

	Ekranin ust ortasinda LEVEL gostergesi:

	    (LEVEL 12) [ XP 340 / 1,000              ]
	               [=========>-------------------]
	                          +25 XP

	Gorunum: mavi-mor parlak panel, cevresinde nabiz atan camgobegi isilti,
	solda altin level rozeti, ustunden isik suzulen camgobegi dolum ve
	kenarlarda goz kirpan yildizlar.

	Level atlayinca ortada "LEVEL UP!" yazisi buyuyerek belirir; altinda
	kazanilan Rot Coin ve kalici sans yazar.

	Veriler sunucudan gelir (bkz. ServerScriptService > Modules > Seviye);
	burasi yalnizca gosterir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))

local UI = require(script.Parent:WaitForChild("UI"))

local SeviyeDurum = Net.event("SeviyeDurum")
local SeviyeAtladi = Net.event("SeviyeAtladi")
local SeviyeAc = Net.event("SeviyeAc")

local ALTIN = Color3.fromRGB(255, 215, 40)
local SIYAH = Color3.fromRGB(0, 0, 0)

local screen = Instance.new("ScreenGui")
screen.Name = "SeviyeArayuzu"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
-- Roblox'un ust cubugunun boslugu yok sayilir: bar ekranin en ustune, cubugun
-- bos orta kismina cikabilsin
screen.IgnoreGuiInset = true
screen.Parent = playerGui

------------------------------------------------------------------
-- XP BARI
------------------------------------------------------------------
-- Renkler
local CAMGOBEGI = Color3.fromRGB(90, 225, 255)
local BEYAZ = Color3.new(1, 1, 1)

--[[
	OLCULER (arayuz olceginden once; %100'de ekranda 1.25 kati)

	Yukseklik bilerek kisa tutuldu: bar ust cubugun ortasinda duruyor ve
	altinda Lucky Block yagmuru sayaci var (bkz. Menuler > sayacKutu).
]]
local GENISLIK = 270
local YUKSEKLIK = 38
local ROZET = 38

local kutu = Instance.new("Frame")
kutu.Name = "SeviyeBari"
kutu.AnchorPoint = Vector2.new(0.5, 0)
kutu.Position = UDim2.new(0.5, 0, 0, 6)
kutu.Size = UDim2.fromOffset(GENISLIK, YUKSEKLIK)
kutu.BackgroundTransparency = 1
kutu.Visible = false
kutu.Parent = screen

--[[
	PANEL: rozetin yarisindan baslar; rozet panelin sol kenarina oturup
	tasar (gorseldeki gibi), panel saga kadar uzanir.
]]
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0, 0.5)
panel.Position = UDim2.new(0, ROZET / 2, 0.5, 0)
panel.Size = UDim2.new(1, -ROZET / 2, 0, YUKSEKLIK - 8)
panel.BackgroundColor3 = BEYAZ
panel.BorderSizePixel = 0
panel.ZIndex = 2
panel.Parent = kutu
UI.corner(panel, 12)

do
	local zemin = Instance.new("UIGradient")
	zemin.Rotation = 90
	zemin.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 90, 210)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(45, 45, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(95, 45, 175)),
	})
	zemin.Parent = panel

	UI.caprazDesen(panel)
	for _, cocuk in panel:GetChildren() do
		-- Desen artik bir CanvasGroup (bkz. UI.stripeLayer), Frame degil
		if cocuk:IsA("GuiObject") and cocuk.Name == "Desen" then
			UI.corner(cocuk, 12)
		end
	end
end

-- Parlak camgobegi kenar + disinda koyu ince cizgi
local panelKontur = UI.stroke(panel, CAMGOBEGI, 3)

--[[
	ISILTI: panelin arkasinda biraz daha buyuk, kenari camgobegi bir
	cerceve; kalinligi ve saydamligi nabiz atar -> panel parliyormus gibi.
]]
local isilti = Instance.new("Frame")
isilti.Name = "Isilti"
isilti.AnchorPoint = Vector2.new(0.5, 0.5)
isilti.Position = UDim2.fromScale(0.5, 0.5)
isilti.Size = UDim2.new(1, 8, 1, 8)
isilti.BackgroundTransparency = 1
isilti.ZIndex = 1
isilti.Parent = panel
UI.corner(isilti, 15)
local isiltiKontur = UI.stroke(isilti, CAMGOBEGI, 4)
TweenService:Create(
	isiltiKontur,
	TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Thickness = 9, Transparency = 0.75 }
):Play()
isiltiKontur.Transparency = 0.25

-- Ust satir: XP yazisi (rozetin sagindan baslar)
local xpYazi = UI.text({
	text = "",
	size = 12,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Left,
	frameSize = UDim2.new(1, -(ROZET / 2 + 16), 0, 12),
	position = UDim2.fromOffset(ROZET / 2 + 6, 1),
	parent = panel,
	name = "XpYazi",
	zIndex = 5,
})

-- Bar yolu (koyu oluk)
local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.AnchorPoint = Vector2.new(0, 1)
bar.Position = UDim2.new(0, ROZET / 2 + 4, 1, -5)
bar.Size = UDim2.new(1, -(ROZET / 2 + 14), 0, 10)
bar.BackgroundColor3 = Color3.fromRGB(14, 18, 48)
bar.BorderSizePixel = 0
bar.ZIndex = 3
bar.Parent = panel
UI.corner(bar, 8)
UI.stroke(bar, SIYAH, 2)

local dolgu = Instance.new("Frame")
dolgu.Name = "Dolgu"
dolgu.Size = UDim2.fromScale(0, 1)
dolgu.BackgroundColor3 = BEYAZ
dolgu.BorderSizePixel = 0
dolgu.ZIndex = 4
dolgu.ClipsDescendants = true
dolgu.Parent = bar
UI.corner(dolgu, 8)

do
	-- Camgobegi dolum: ustu acik, alti koyu
	local renk = Instance.new("UIGradient")
	renk.Rotation = 90
	renk.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 250, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 215, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 140, 235)),
	})
	renk.Parent = dolgu

	--[[
		SUZULEN ISIK: dolumun uzerinden soldan saga beyaz bir bant gecer.
		Bant dondurulmus bir cerceve degil, kayan saydamlik gecisi: dolum
		ClipsDescendants ile kirpiyor ve gecis hep kendi sinirinda kalir.
	]]
	local isik = Instance.new("Frame")
	isik.Name = "Isik"
	isik.Size = UDim2.fromScale(1, 1)
	isik.BackgroundColor3 = BEYAZ
	isik.BorderSizePixel = 0
	isik.ZIndex = 5
	isik.Parent = dolgu
	UI.corner(isik, 8)

	local bant = Instance.new("UIGradient")
	bant.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 1),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(0.6, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	bant.Offset = Vector2.new(-1, 0)
	bant.Parent = isik
	TweenService:Create(
		bant,
		TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 0.6),
		{ Offset = Vector2.new(1, 0) }
	):Play()
end

--[[
	DOLUMUN UCU: parlayan beyaz bir nokta. Dolumun cocugu degil (dolum
	kirpiyor); barin cocugu olarak dolumun sag kenarini takip eder.
]]
local uc = Instance.new("Frame")
uc.Name = "Uc"
uc.AnchorPoint = Vector2.new(0.5, 0.5)
uc.Position = UDim2.fromScale(0, 0.5)
uc.Size = UDim2.fromOffset(9, 9)
uc.BackgroundColor3 = BEYAZ
uc.BorderSizePixel = 0
uc.ZIndex = 6
uc.Parent = bar
UI.corner(uc, 7)
local ucKontur = UI.stroke(uc, CAMGOBEGI, 3)
ucKontur.Transparency = 0.2

--[[
	LEVEL ROZETI: altin, cilali, yuvarlak; ustte kucuk "LEVEL", altta sayi.
	Panelin sol kenarina oturur.
]]
local rozet = Instance.new("Frame")
rozet.Name = "Rozet"
rozet.AnchorPoint = Vector2.new(0, 0.5)
rozet.Position = UDim2.new(0, 0, 0.5, 0)
rozet.Size = UDim2.fromOffset(ROZET, ROZET)
rozet.BorderSizePixel = 0
rozet.ZIndex = 6
rozet.ClipsDescendants = true
rozet.Parent = kutu
UI.corner(rozet, ROZET / 2)
UI.polish(rozet, ALTIN, ROZET / 2)
UI.stroke(rozet, Color3.fromRGB(120, 60, 0), 3)

local rozetOlcek = Instance.new("UIScale")
rozetOlcek.Parent = rozet

UI.text({
	text = "LEVEL",
	size = 8,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 10),
	position = UDim2.fromOffset(0, 4),
	parent = rozet,
	name = "LevelBaslik",
	zIndex = 7,
})

local levelYazi = UI.text({
	text = "1",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 20),
	position = UDim2.fromOffset(0, 13),
	parent = rozet,
	name = "Level",
	zIndex = 7,
})

--[[
	GOZ KIRPAN YILDIZLAR: panelin koselerinde ve kenarlarinda sirayla
	parlayip sonen kucuk elmaslar.
]]
local yildizlar: { Frame } = {}
for i, yer in { Vector2.new(0.08, 0), Vector2.new(0.55, 0), Vector2.new(0.35, 1), Vector2.new(0.85, 1), Vector2.new(0.95, 0.1) } do
	local y = Instance.new("Frame")
	y.Name = `Yildiz{i}`
	y.AnchorPoint = Vector2.new(0.5, 0.5)
	y.Position = UDim2.fromScale(yer.X, yer.Y)
	y.Size = UDim2.fromOffset(8, 8)
	y.Rotation = 45
	y.BackgroundColor3 = Color3.fromRGB(220, 250, 255)
	y.BorderSizePixel = 0
	y.ZIndex = 7
	y.Parent = panel
	UI.corner(y, 2)
	table.insert(yildizlar, y)
end

local zaman = 0
RunService.RenderStepped:Connect(function(dt)
	if not kutu.Visible then
		return
	end
	zaman += dt

	for i, y in yildizlar do
		local parilti = math.max(0, math.sin(zaman * 2.4 + i * 1.3))
		y.BackgroundTransparency = 1 - parilti
		local boy = 3 + parilti * 8
		y.Size = UDim2.fromOffset(boy, boy)
		y.Rotation = 45 + zaman * 90
	end

	-- Dolumun ucu dolumu takip eder ve hafifce nabiz atar
	local oran = dolgu.Size.X.Scale
	uc.Visible = oran > 0.02 and oran < 0.999
	uc.Position = UDim2.fromScale(oran, 0.5)
	local nabiz = (math.sin(zaman * 6) + 1) * 0.5
	local ucBoy = 7 + nabiz * 4
	uc.Size = UDim2.fromOffset(ucBoy, ucBoy)
	ucKontur.Transparency = 0.1 + nabiz * 0.5

	-- Panel kenari da hafifce parlayip soner
	panelKontur.Color = CAMGOBEGI:Lerp(BEYAZ, nabiz * 0.35)
end)

------------------------------------------------------------------
-- LEVEL UP GOSTERISI
------------------------------------------------------------------
local gosteri = Instance.new("Frame")
gosteri.Name = "LevelUp"
gosteri.AnchorPoint = Vector2.new(0.5, 0.5)
gosteri.Position = UDim2.fromScale(0.5, 0.28)
gosteri.Size = UDim2.fromOffset(520, 130)
gosteri.BackgroundTransparency = 1
gosteri.Visible = false
gosteri.Parent = screen

local gosteriOlcek = Instance.new("UIScale")
gosteriOlcek.Parent = gosteri

local levelUpYazi = UI.text({
	text = "LEVEL UP!",
	size = UI.Sizes.huge + 16,
	font = UI.Fonts.bold,
	color = ALTIN,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 62),
	parent = gosteri,
	name = "Baslik",
})

local levelUpAlt = UI.text({
	text = "",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 30),
	position = UDim2.fromOffset(0, 64),
	parent = gosteri,
	name = "Level",
})

local levelUpOdul = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	color = Color3.fromRGB(120, 255, 150),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 26),
	position = UDim2.fromOffset(0, 96),
	parent = gosteri,
	name = "Odul",
})

local gosteriSirasi = 0

local function levelUpOynat(data: any)
	gosteriSirasi += 1
	local sira = gosteriSirasi

	levelUpAlt.Text = `Level {data.level}`
	-- Rot Coin her levelde gelmiyor (bkz. Shared > Seviye); gelmediyse yazilmaz
	local coin = tonumber(data.rotCoins) or 0
	levelUpOdul.Text = if coin > 0
		then `+{coin} Rot Coin   +{data.luck or 0}% Luck`
		else `+{data.luck or 0}% Luck`

	for _, yazi in { levelUpYazi, levelUpAlt, levelUpOdul } do
		yazi.TextTransparency = 0
	end

	gosteri.Visible = true
	gosteriOlcek.Scale = 0.2
	TweenService:Create(gosteriOlcek, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()

	-- Rozet de bir kez ziplar
	rozetOlcek.Scale = 1.5
	TweenService:Create(rozetOlcek, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()

	task.delay(2.4, function()
		if sira ~= gosteriSirasi then
			return
		end
		local bilgi = TweenInfo.new(0.4)
		for _, yazi in { levelUpYazi, levelUpAlt, levelUpOdul } do
			TweenService:Create(yazi, bilgi, { TextTransparency = 1 }):Play()
		end
		task.wait(0.45)
		if sira == gosteriSirasi then
			gosteri.Visible = false
		end
	end)
end

------------------------------------------------------------------
-- "+25 XP" YAZISI
------------------------------------------------------------------
local function xpUcur(miktar: number)
	local yazi = UI.text({
		text = `+{Format.short(miktar)} XP`,
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(120, 255, 150),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(160, 24),
		anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 15, 1, 0),
		parent = kutu,
	})

	local bilgi = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(yazi, bilgi, {
		Position = UDim2.new(0.5, 15, 1, 22),
		TextTransparency = 1,
	}):Play()

	task.delay(1.2, function()
		yazi:Destroy()
	end)
end

------------------------------------------------------------------
-- DURUM
------------------------------------------------------------------
local sonLevel = 0

SeviyeDurum.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end

	local level = tonumber(data.level) or 1
	local xp = tonumber(data.xp) or 0
	local need = math.max(1, tonumber(data.need) or 1)
	local maxLevel = tonumber(data.max) or 100

	kutu.Visible = true
	levelYazi.Text = tostring(level)

	local oran: number
	if level >= maxLevel then
		oran = 1
		xpYazi.Text = "MAX LEVEL"
	else
		oran = math.clamp(xp / need, 0, 1)
		xpYazi.Text = `XP: {Format.short(xp)} / {Format.short(need)}`
	end

	local bilgi = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	if sonLevel > 0 and level > sonLevel then
		-- Level atladi: bar once dolar, sifirlanir, sonra yeni orana gider
		local dol = TweenService:Create(dolgu, bilgi, { Size = UDim2.fromScale(1, 1) })
		dol:Play()
		dol.Completed:Once(function()
			dolgu.Size = UDim2.fromScale(0, 1)
			TweenService:Create(dolgu, bilgi, { Size = UDim2.fromScale(oran, 1) }):Play()
		end)
	else
		TweenService:Create(dolgu, bilgi, { Size = UDim2.fromScale(oran, 1) }):Play()
	end

	sonLevel = level

	local kazanilan = tonumber(data.gained) or 0
	if kazanilan > 0 then
		xpUcur(kazanilan)
	end
end)

SeviyeAtladi.OnClientEvent:Connect(function(data)
	if type(data) == "table" then
		levelUpOynat(data)
	end
end)

SeviyeAc:FireServer()
