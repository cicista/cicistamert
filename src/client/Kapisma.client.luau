--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("Kapisma"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))

local Basla = Net.event("KapismaBasla")
local Durum = Net.event("KapismaDurum")
local Tik = Net.event("KapismaTik")
local Bitti = Net.event("KapismaBitti")

local EYLEM = "KapismaTiklama"
local TIK_ARALIGI = 1 / 15

local BEYAZ = Color3.new(1, 1, 1)
local SIYAH = Color3.new(0, 0, 0)
local MAVI = Color3.fromRGB(70, 170, 255)
local KIRMIZI = Color3.fromRGB(255, 80, 80)
local ALTIN = Color3.fromRGB(255, 210, 70)

local EN = 520
local CUBUK_EN = 460

local screen = Instance.new("ScreenGui")
screen.Name = "Kapisma"
screen.DisplayOrder = 30
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Enabled = false
screen.Parent = playerGui

local kap = Instance.new("Frame")
kap.Name = "Kap"
kap.AnchorPoint = Vector2.new(0.5, 0.5)
kap.Position = UDim2.fromScale(0.5, 0.3)
kap.Size = UDim2.fromOffset(EN, 190)
kap.BackgroundColor3 = BEYAZ
kap.BorderSizePixel = 0
kap.Parent = screen
UI.corner(kap, 18)
local kapKontur = UI.stroke(kap, SIYAH, 4)
kapKontur.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local zemin = Instance.new("UIGradient")
zemin.Rotation = 90
zemin.Color = ColorSequence.new(Color3.fromRGB(60, 24, 30), Color3.fromRGB(20, 10, 16))
zemin.Parent = kap

local kapOlcek = Instance.new("UIScale")
kapOlcek.Parent = kap

do
	local ic = Instance.new("Frame")
	ic.Name = "Ic"
	ic.Size = UDim2.fromScale(1, 1)
	ic.BackgroundTransparency = 1
	ic.ClipsDescendants = true
	ic.Parent = kap
	UI.corner(ic, 18)
	UI.caprazDesen(ic, BEYAZ, 8)
	UI.pariltilar(ic, Ayar.Renk, 12, 2)
end

local baslik = UI.text({
	text = "CLASH!",
	size = 40,
	font = UI.Fonts.bold,
	color = BEYAZ,
	glow = Ayar.Renk,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 44),
	position = UDim2.fromOffset(0, 6),
	parent = kap,
	zIndex = 5,
})
local baslikOlcek = Instance.new("UIScale")
baslikOlcek.Parent = baslik

local altBaslik = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = ALTIN,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 20),
	position = UDim2.fromOffset(0, 48),
	parent = kap,
	zIndex = 5,
})

local benimAd = UI.text({
	text = "YOU",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	color = MAVI,
	align = Enum.TextXAlignment.Left,
	frameSize = UDim2.fromOffset(220, 22),
	position = UDim2.fromOffset((EN - CUBUK_EN) / 2, 72),
	parent = kap,
	zIndex = 5,
})

local rakipAd = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	color = KIRMIZI,
	align = Enum.TextXAlignment.Right,
	frameSize = UDim2.fromOffset(220, 22),
	position = UDim2.new(1, -(EN - CUBUK_EN) / 2 - 220, 0, 72),
	parent = kap,
	zIndex = 5,
})

local cubuk = Instance.new("Frame")
cubuk.Name = "Cubuk"
cubuk.AnchorPoint = Vector2.new(0.5, 0)
cubuk.Position = UDim2.new(0.5, 0, 0, 98)
cubuk.Size = UDim2.fromOffset(CUBUK_EN, 30)
cubuk.BackgroundColor3 = KIRMIZI
cubuk.BorderSizePixel = 0
cubuk.ClipsDescendants = true
cubuk.ZIndex = 5
cubuk.Parent = kap
UI.corner(cubuk, 15)
UI.stroke(cubuk, SIYAH, 3)

local dolgu = Instance.new("Frame")
dolgu.Name = "Dolgu"
dolgu.Size = UDim2.fromScale(0.5, 1)
dolgu.BackgroundColor3 = MAVI
dolgu.BorderSizePixel = 0
dolgu.ZIndex = 6
dolgu.Parent = cubuk

local orta = Instance.new("Frame")
orta.Name = "Orta"
orta.AnchorPoint = Vector2.new(0.5, 0.5)
orta.Position = UDim2.fromScale(0.5, 0.5)
orta.Size = UDim2.new(0, 2, 1, 0)
orta.BackgroundColor3 = BEYAZ
orta.BackgroundTransparency = 0.4
orta.BorderSizePixel = 0
orta.ZIndex = 7
orta.Parent = cubuk

local dugum = Instance.new("Frame")
dugum.Name = "Dugum"
dugum.AnchorPoint = Vector2.new(0.5, 0.5)
dugum.Position = UDim2.new(0.5, 0, 0, 113)
dugum.Size = UDim2.fromOffset(42, 42)
dugum.BackgroundColor3 = ALTIN
dugum.BorderSizePixel = 0
dugum.ZIndex = 8
dugum.Parent = kap
UI.corner(dugum, 21)
UI.stroke(dugum, SIYAH, 3)

local dugumYazi = UI.text({
	text = "VS",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = dugum,
	zIndex = 9,
})

local ipucu = UI.text({
	text = "",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 24),
	position = UDim2.fromOffset(0, 138),
	parent = kap,
	zIndex = 5,
})
local ipucuOlcek = Instance.new("UIScale")
ipucuOlcek.Parent = ipucu

local sayac = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = Color3.fromRGB(220, 225, 235),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 20),
	position = UDim2.fromOffset(0, 164),
	parent = kap,
	zIndex = 5,
})

local buyukSayi = UI.text({
	text = "",
	size = 96,
	font = UI.Fonts.bold,
	color = ALTIN,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromOffset(300, 110),
	position = UDim2.new(0.5, -150, 1, 10),
	parent = kap,
	zIndex = 10,
})
local buyukOlcek = Instance.new("UIScale")
buyukOlcek.Parent = buyukSayi

local aktif = false
local yaris = false
local taraf = 1
local hedefPay = 0.5
local gorunenPay = 0.5
local kalan = 0
local sonTik = 0
local surum = 0

local function pay(p: number): number
	return if taraf == 1 then p else 1 - p
end

local function tikla()
	if not yaris then
		return
	end
	local simdi = os.clock()
	if simdi - sonTik < TIK_ARALIGI then
		return
	end
	sonTik = simdi

	Tik:FireServer()
	hedefPay = math.clamp(hedefPay + Ayar.Adim * 0.6, 0, 1)

	ipucuOlcek.Scale = 1.15
	TweenService:Create(ipucuOlcek, TweenInfo.new(0.12), { Scale = 1 }):Play()
	dugum.Rotation = math.random(-15, 15)
end

local function baglantiyiKur()
	ContextActionService:BindActionAtPriority(EYLEM, function(_, durum)
		if durum == Enum.UserInputState.Begin then
			tikla()
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.KeyCode.Space, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonR2)
end

local function baglantiyiCoz()
	ContextActionService:UnbindAction(EYLEM)
end

local function sayiGoster(metin: string, renk: Color3)
	buyukSayi.Text = metin
	buyukSayi.TextColor3 = renk
	buyukOlcek.Scale = 1.6
	TweenService:Create(buyukOlcek, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

Basla.OnClientEvent:Connect(function(veri)
	if type(veri) ~= "table" then
		return
	end
	surum += 1
	local benim = surum

	aktif = true
	yaris = false
	taraf = if veri.taraf == -1 then -1 else 1
	hedefPay = 0.5
	gorunenPay = 0.5
	kalan = tonumber(veri.sure) or Ayar.Sure

	local kind = tostring(veri.kind or "")
	baslik.Text = "CLASH!"
	altBaslik.Text = if taraf == 1 then `DEFEND YOUR {string.upper(Rarity.beamName(kind))}!` else `STEAL THE {string.upper(Rarity.beamName(kind))}!`
	altBaslik.TextColor3 = Rarity.beamColor(kind)
	rakipAd.Text = string.upper(tostring(veri.rakip or "RIVAL"))
	ipucu.Text = "GET READY..."
	sayac.Text = ""

	screen.Enabled = true
	kapOlcek.Scale = 0.6
	TweenService:Create(kapOlcek, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	baglantiyiKur()

	local sayim = math.max(1, math.floor(tonumber(veri.sayim) or Ayar.GeriSayim))
	for i = sayim, 1, -1 do
		if benim ~= surum then
			return
		end
		sayiGoster(tostring(i), ALTIN)
		task.wait(1)
	end
	if benim ~= surum then
		return
	end

	sayiGoster("GO!", Color3.fromRGB(120, 255, 140))
	yaris = true
	ipucu.Text = UI.Girdi.sec("CLICK AS FAST AS YOU CAN!", "TAP AS FAST AS YOU CAN!", "MASH A AS FAST AS YOU CAN!")
	task.delay(0.6, function()
		if benim == surum and buyukSayi.Text == "GO!" then
			buyukSayi.Text = ""
		end
	end)
end)

Durum.OnClientEvent:Connect(function(p, sureKalan)
	if not aktif or type(p) ~= "number" then
		return
	end
	hedefPay = pay(p)
	kalan = if type(sureKalan) == "number" then sureKalan else kalan
end)

Bitti.OnClientEvent:Connect(function(veri)
	if not aktif then
		return
	end
	surum += 1
	local benim = surum
	yaris = false
	baglantiyiCoz()

	local kazandin = type(veri) == "table" and veri.kazandin == true
	hedefPay = if kazandin then 1 else 0
	baslik.Text = if kazandin then "YOU WON!" else "YOU LOST!"
	ipucu.Text = if kazandin then "The pet is yours!" else "They got away with it..."
	sayiGoster(if kazandin then "WIN!" else "LOSE", if kazandin then ALTIN else KIRMIZI)

	task.delay(Ayar.SonucSuresi, function()
		if benim ~= surum then
			return
		end
		local kapan = TweenService:Create(kapOlcek, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 })
		kapan.Completed:Connect(function()
			if benim == surum then
				aktif = false
				screen.Enabled = false
				buyukSayi.Text = ""
			end
		end)
		kapan:Play()
	end)
end)

RunService.RenderStepped:Connect(function(dt)
	if not aktif then
		return
	end

	gorunenPay += (hedefPay - gorunenPay) * math.min(1, dt * 12)
	dolgu.Size = UDim2.fromScale(gorunenPay, 1)
	dugum.Position = UDim2.new(0.5, (gorunenPay - 0.5) * CUBUK_EN, 0, 113)
	dugum.Rotation *= 0.85

	local t = os.clock()
	baslikOlcek.Scale = 1 + math.sin(t * 8) * 0.04
	kapKontur.Color = if gorunenPay >= 0.5 then MAVI:Lerp(BEYAZ, (math.sin(t * 10) + 1) * 0.2) else KIRMIZI:Lerp(BEYAZ, (math.sin(t * 10) + 1) * 0.2)
	dugumYazi.Text = if yaris then `{math.floor(gorunenPay * 100)}%` else "VS"

	if yaris then
		kalan = math.max(0, kalan - dt)
		sayac.Text = `{string.format("%.1f", kalan)}s left`
	end
end)
