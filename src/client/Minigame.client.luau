local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DigMinigame = require(Shared:WaitForChild("DigMinigame"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local KaziMinigame = require(Shared:WaitForChild("KaziMinigame"))
local OtoTiklayici = require(Shared:WaitForChild("OtoTiklayici"))
local Assets = require(Shared:WaitForChild("Assets"))

task.spawn(function()
	local liste = {}
	for _, ham in { Assets.Animations.shovelDig, Assets.Animations.pickaxeDig } do
		local gercek = Assets.id(ham)
		if gercek then
			local animasyon = Instance.new("Animation")
			animasyon.AnimationId = gercek
			table.insert(liste, animasyon)
		end
	end
	if #liste > 0 then
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync(liste)
		end)
	end
end)
local Ores = require(Shared:WaitForChild("Ores"))
local Icons = require(Shared:WaitForChild("Icons"))
local Net = require(Shared:WaitForChild("Net"))

local UI = require(script.Parent:WaitForChild("UI"))

local MinigameBasla = Net.event("MinigameBasla")
local MinigameSonuc = Net.event("MinigameSonuc")
local KaziBitti = Net.event("KaziBitti")
local Passler = require(Shared:WaitForChild("Passler"))
local PassSatinAl = Net.event("PassSatinAl")

local ACTION_NAME = "KaziMinigameTut"

local BalikPaneli = require(script.Parent:WaitForChild("BalikPaneli"))

local KUREK_IKONU = "rbxassetid://82895822894928"

local IKON_BOY = 96

local IKON_ACI = 90

local KAZMA_IKON_ADI = "pickaxe_icon"
local KAZMA_ACI = 0

local ikonAci = IKON_ACI
local kazmaUyarisiVerildi = false

local OTO_X = 0.72
local OTO_Y = 0.8
local OTO_X_DOKUNMATIK = 0.85
local OTO_Y_DOKUNMATIK = 0.76

local OTO_BOY = 92

local KAZI_ARA = 14

local KAZI_BOY = 360

local TEHLIKE_ORANI = 0.16

local kaziEkran = Instance.new("ScreenGui")
kaziEkran.Name = "KaziBar"
kaziEkran.ResetOnSpawn = false
kaziEkran.IgnoreGuiInset = true
kaziEkran.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
kaziEkran.Enabled = false
kaziEkran:SetAttribute(UI.OlcekDisiNitelik, true)
kaziEkran.Parent = playerGui

local kaziCerceve = Instance.new("Frame")
kaziCerceve.Name = "Cerceve"
kaziCerceve.AnchorPoint = Vector2.new(0.5, 1)
kaziCerceve.Position = UDim2.new(OTO_X, 0, OTO_Y, -(OTO_BOY / 2 + KAZI_ARA))
kaziCerceve.Size = UDim2.fromOffset(74, KAZI_BOY)
kaziCerceve.BackgroundColor3 = Color3.fromRGB(74, 55, 36)
kaziCerceve.BorderSizePixel = 0
kaziCerceve.ClipsDescendants = true
kaziCerceve.Parent = kaziEkran
UI.corner(kaziCerceve, 6)
UI.stroke(kaziCerceve, Color3.fromRGB(0, 0, 0), 4)

local function dokuKat(parent: Instance, renk: Color3, saydam: number, aci: number, sikilik: number)
	local kat = Instance.new("Frame")
	kat.Name = "Doku"
	kat.Size = UDim2.fromScale(1, 1)
	kat.BackgroundColor3 = renk
	kat.BackgroundTransparency = saydam
	kat.BorderSizePixel = 0
	kat.ZIndex = 2
	kat.Parent = parent

	local stops = {}
	for i = 0, sikilik do
		local t = i / sikilik
		local acikMi = i % 2 == 0
		table.insert(stops, NumberSequenceKeypoint.new(t, if acikMi then 0 else 1))
	end

	local gecis = Instance.new("UIGradient")
	gecis.Rotation = aci
	gecis.Transparency = NumberSequence.new(stops)
	gecis.Parent = kat

	return kat
end

dokuKat(kaziCerceve, Color3.fromRGB(38, 27, 16), 0.55, 28, 17)
dokuKat(kaziCerceve, Color3.fromRGB(214, 184, 132), 0.82, -14, 11)

local kaziDolgu = Instance.new("Frame")
kaziDolgu.Name = "Dolgu"
kaziDolgu.AnchorPoint = Vector2.new(0.5, 1)
kaziDolgu.Position = UDim2.fromScale(0.5, 1)
kaziDolgu.Size = UDim2.fromScale(1, 0)
kaziDolgu.BackgroundColor3 = UI.Colors.good
kaziDolgu.BorderSizePixel = 0
kaziDolgu.ZIndex = 3
kaziDolgu.Parent = kaziCerceve

dokuKat(kaziDolgu, Color3.fromRGB(0, 0, 0), 0.7, 28, 17).ZIndex = 4
dokuKat(kaziDolgu, Color3.fromRGB(255, 255, 255), 0.86, -14, 11).ZIndex = 4

local kaziTehlike = Instance.new("Frame")
kaziTehlike.Name = "Tehlike"
kaziTehlike.AnchorPoint = Vector2.new(0.5, 1)
kaziTehlike.Position = UDim2.fromScale(0.5, 1)
kaziTehlike.Size = UDim2.fromScale(1, TEHLIKE_ORANI)
kaziTehlike.BackgroundColor3 = Color3.fromRGB(10, 8, 6)
kaziTehlike.BackgroundTransparency = 0.15
kaziTehlike.BorderSizePixel = 0
kaziTehlike.ZIndex = 6
kaziTehlike.Parent = kaziCerceve

local kaziKatman = Instance.new("Frame")
kaziKatman.Name = "IkonKatmani"
kaziKatman.AnchorPoint = kaziCerceve.AnchorPoint
kaziKatman.Position = kaziCerceve.Position
kaziKatman.Size = kaziCerceve.Size
kaziKatman.BackgroundTransparency = 1
kaziKatman.ZIndex = 8
kaziKatman.Parent = kaziEkran

local kaziIkon = Instance.new("ImageLabel")
kaziIkon.Name = "Kurek"
kaziIkon.AnchorPoint = Vector2.new(0.5, 0.5)
kaziIkon.Size = UDim2.fromOffset(IKON_BOY, IKON_BOY)
kaziIkon.BackgroundTransparency = 1
kaziIkon.Image = KUREK_IKONU
kaziIkon.Rotation = IKON_ACI
kaziIkon.ZIndex = 8
kaziIkon.Parent = kaziKatman

local cerceveKonum = kaziCerceve.Position
local EFEKT_ALTIN = Color3.fromRGB(255, 214, 60)
local TOPRAK_RENKLERI = {
	Color3.fromRGB(150, 108, 64),
	Color3.fromRGB(112, 78, 44),
	Color3.fromRGB(214, 184, 132),
	Color3.fromRGB(236, 206, 150),
}

kaziDolgu.ClipsDescendants = true

local dolguBandi = Instance.new("Frame")
dolguBandi.Name = "Parilti"
dolguBandi.AnchorPoint = Vector2.new(0, 0.5)
dolguBandi.Position = UDim2.new(0, 0, 1.2, 0)
dolguBandi.Size = UDim2.new(1, 0, 0, 46)
dolguBandi.BackgroundColor3 = Color3.new(1, 1, 1)
dolguBandi.BackgroundTransparency = 0.55
dolguBandi.BorderSizePixel = 0
dolguBandi.ZIndex = 5
dolguBandi.Parent = kaziDolgu
do
	local gecis = Instance.new("UIGradient")
	gecis.Rotation = 90
	gecis.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	gecis.Parent = dolguBandi
	TweenService:Create(
		dolguBandi,
		TweenInfo.new(1.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{ Position = UDim2.new(0, 0, -0.2, 0) }
	):Play()
end

local dolguUst = Instance.new("Frame")
dolguUst.Name = "UstKenar"
dolguUst.Size = UDim2.new(1, 0, 0, 5)
dolguUst.BackgroundColor3 = Color3.new(1, 1, 1)
dolguUst.BackgroundTransparency = 0.15
dolguUst.BorderSizePixel = 0
dolguUst.ZIndex = 5
dolguUst.Parent = kaziDolgu

local aura = Instance.new("Frame")
aura.Name = "Aura"
aura.AnchorPoint = Vector2.new(0.5, 0.5)
aura.Position = UDim2.fromScale(0.5, 0.5)
aura.Size = UDim2.new(1, 10, 1, 10)
aura.BackgroundTransparency = 1
aura.ZIndex = 7
aura.Parent = kaziKatman
UI.corner(aura, 10)
local auraCizgi = UI.stroke(aura, UI.Colors.good, 5)
auraCizgi.Transparency = 0.4
TweenService:Create(
	auraCizgi,
	TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Thickness = 9, Transparency = 0.8 }
):Play()

local yuzdeYazi = UI.text({
	text = "",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	align = Enum.TextXAlignment.Center,
	anchor = Vector2.new(0.5, 1),
	position = UDim2.new(0.5, 0, 0, -12),
	frameSize = UDim2.fromOffset(120, 30),
	parent = kaziKatman,
	name = "Yuzde",
	zIndex = 9,
})
local yuzdeOlcek = Instance.new("UIScale")
yuzdeOlcek.Parent = yuzdeYazi

local komboYazi = UI.text({
	text = "",
	size = UI.Sizes.huge,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	align = Enum.TextXAlignment.Right,
	anchor = Vector2.new(1, 0.5),
	position = UDim2.new(0, -16, 0.45, 0),
	frameSize = UDim2.fromOffset(220, 50),
	parent = kaziKatman,
	name = "Kombo",
	zIndex = 9,
})
komboYazi.Visible = false
local komboOlcek = Instance.new("UIScale")
komboOlcek.Parent = komboYazi

local sonucYazi = UI.text({
	text = "",
	size = UI.Sizes.huge,
	font = UI.Fonts.bold,
	color = EFEKT_ALTIN,
	align = Enum.TextXAlignment.Center,
	anchor = Vector2.new(0.5, 1),
	position = UDim2.new(0.5, 0, 0, -48),
	frameSize = UDim2.fromOffset(300, 56),
	parent = kaziKatman,
	name = "Sonuc",
	zIndex = 10,
})
sonucYazi.Visible = false
local sonucOlcek = Instance.new("UIScale")
sonucOlcek.Parent = sonucYazi

local otoKutu = Instance.new("Frame")
otoKutu.Name = "OtoTiklayici"
otoKutu.AnchorPoint = Vector2.new(0.5, 0.5)
otoKutu.Position = UDim2.fromScale(OTO_X, OTO_Y)
otoKutu.Size = UDim2.fromOffset(176, OTO_BOY)
otoKutu.BackgroundTransparency = 1
otoKutu.Visible = true
otoKutu.ZIndex = 8
otoKutu.Parent = kaziEkran

UI.text({
	text = "AUTO CLICKER",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 22),
	position = UDim2.fromOffset(0, 0),
	parent = otoKutu,
	name = "Baslik",
})

local otoDugme = Instance.new("TextButton")
otoDugme.Name = "Dugme"
otoDugme.Position = UDim2.fromOffset(0, 30)
otoDugme.Size = UDim2.new(1, 0, 0, 58)
otoDugme.BackgroundColor3 = UI.Colors.bad
otoDugme.BorderSizePixel = 0
otoDugme.AutoButtonColor = false
otoDugme.Text = ""
otoDugme.ZIndex = 8
otoDugme.Parent = otoKutu
UI.corner(otoDugme, 10)
UI.stroke(otoDugme, Color3.fromRGB(0, 0, 0), 3)

local otoYazi = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = otoDugme,
	name = "Label",
	zIndex = 9,
})

local otoRenk = UI.Colors.bad

otoDugme.MouseEnter:Connect(function()
	otoDugme.BackgroundColor3 = UI.shade(otoRenk, UI.HoverLift)
end)

otoDugme.MouseLeave:Connect(function()
	otoDugme.BackgroundColor3 = otoRenk
end)

local otoSahip = Passler.sahip(player, "AutoClicker")

local otoAcik = true

local function otoCalisiyorMu(): boolean
	return otoSahip and otoAcik
end

local otoFiyat: Frame? = nil

local function otoDugmeyiCiz()
	otoKutu.Visible = true

	if not otoSahip then
		local pass = Passler.get("AutoClicker")

		if not otoFiyat then
			otoFiyat = UI.robuxFiyati(otoDugme, if pass then pass.fiyat else 0, UI.Sizes.label, 10)
		end
		local kutu = otoFiyat
		if kutu then
			kutu.Visible = true
		end

		otoYazi.Text = ""
		otoRenk = UI.Colors.gold
		otoDugme.BackgroundColor3 = otoRenk
		return
	end

	local kutu = otoFiyat
	if kutu then
		kutu.Visible = false
	end

	otoYazi.Text = if otoAcik then "ON" else "OFF"
	otoRenk = if otoAcik then UI.Colors.good else UI.Colors.bad
	otoDugme.BackgroundColor3 = otoRenk
end

otoDugmeyiCiz()

otoDugme.Activated:Connect(function()
	if not otoSahip then
		PassSatinAl:FireServer("AutoClicker")
		return
	end

	otoAcik = not otoAcik
	otoDugmeyiCiz()
end)

do
	local pass = Passler.get("AutoClicker")
	if pass then
		player:GetAttributeChangedSignal(pass.nitelik):Connect(function()
			otoSahip = Passler.sahip(player, "AutoClicker")
			otoDugmeyiCiz()
		end)
	end
end

local SARSINTI_ADI = "KaziSarsinti"

local SONUM = 7

local TIK_GUCU = 1.1
local TIK_TAVAN = 2.6

local ZAFER_GUCU = 7

local sarsintiGucu = 0
local vurusGucu = 0

local vurusYon = 1
local sarsintiBagli = false
local rng = Random.new()

local function sarsintiKapali(): boolean
	return game:GetService("Players").LocalPlayer:GetAttribute("SarsintiKapali") == true
end

local function sarsintiyiBagla()
	if sarsintiBagli then
		return
	end
	sarsintiBagli = true

	RunService:BindToRenderStep(SARSINTI_ADI, Enum.RenderPriority.Camera.Value + 1, function(dt)
		sarsintiGucu = math.max(0, sarsintiGucu - dt * SONUM)
		vurusGucu = math.max(0, vurusGucu - dt * SONUM)

		local v = math.min(vurusGucu, 1)
		kaziIkon.Size = UDim2.fromOffset(IKON_BOY + v * 45, IKON_BOY + v * 45)
		kaziIkon.Rotation = ikonAci + vurusYon * v * 27

		if sarsintiGucu <= 0 or sarsintiKapali() then
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		local g = sarsintiGucu
		camera.CFrame = camera.CFrame
			* CFrame.new(rng:NextNumber(-g, g) * 0.5, rng:NextNumber(-g, g) * 0.5, 0)
			* CFrame.Angles(0, 0, math.rad(rng:NextNumber(-g, g) * 2.2))
	end)
end

local function sarsintiyiCoz()
	if not sarsintiBagli then
		return
	end
	sarsintiBagli = false
	RunService:UnbindFromRenderStep(SARSINTI_ADI)

	sarsintiGucu = 0
	vurusGucu = 0
	kaziIkon.Size = UDim2.fromOffset(IKON_BOY, IKON_BOY)
	kaziIkon.Rotation = ikonAci
end
local kaziRenk = UI.Colors.good

type Parcacik = {
	f: Frame,
	vx: number,
	vy: number,
	yercekimi: number,
	omur: number,
	sure: number,
	donus: number,
	saydam: number,
}

local efekt = {
	parcaciklar = {} :: { Parcacik },
	ilerleme = 0.5,
	kombo = 0,
	sonTik = 0,
	esik = 0,
	kabarcik = 0,
	oyunNo = 0,
}

local function parcacikAt(x: number, y: number, renk: Color3, boy: number, vx: number, vy: number, omur: number, yercekimi: number, yuvarlak: boolean?, saydam: number?)
	if #efekt.parcaciklar >= 140 then
		return
	end
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(boy, boy)
	f.Rotation = rng:NextNumber(0, 360)
	f.BackgroundColor3 = renk
	f.BackgroundTransparency = saydam or 0
	f.BorderSizePixel = 0
	f.ZIndex = 9
	f.Parent = kaziKatman
	UI.corner(f, if yuvarlak then 1000 else 2)
	table.insert(efekt.parcaciklar, {
		f = f,
		vx = vx,
		vy = vy,
		yercekimi = yercekimi,
		omur = omur,
		sure = 0,
		donus = rng:NextNumber(-360, 360),
		saydam = saydam or 0,
	})
end

RunService.RenderStepped:Connect(function(dt)
	local liste = efekt.parcaciklar
	for i = #liste, 1, -1 do
		local p = liste[i]
		p.sure += dt
		local oran = p.sure / p.omur
		if oran >= 1 or not p.f.Parent then
			p.f:Destroy()
			table.remove(liste, i)
			continue
		end
		p.vy += p.yercekimi * dt
		local konum = p.f.Position
		p.f.Position = UDim2.fromOffset(konum.X.Offset + p.vx * dt, konum.Y.Offset + p.vy * dt)
		p.f.Rotation += p.donus * dt
		p.f.BackgroundTransparency = p.saydam + (1 - p.saydam) * oran * oran
	end

	if komboYazi.Visible and os.clock() - efekt.sonTik > 0.6 then
		komboYazi.TextTransparency = math.min(1, komboYazi.TextTransparency + dt * 4)
		if komboYazi.TextTransparency >= 1 then
			komboYazi.Visible = false
			efekt.kombo = 0
		end
	end
end)

local function ikonNoktasi(): (number, number)
	return kaziCerceve.Size.X.Offset / 2, (1 - efekt.ilerleme) * KAZI_BOY
end

local function patlat(x: number, y: number, sayi: number, renkler: { Color3 }, hiz: number, yukari: number, omur: number)
	for _ = 1, sayi do
		local yon = if rng:NextNumber() < 0.5 then -1 else 1
		parcacikAt(
			x + rng:NextNumber(-6, 6),
			y + rng:NextNumber(-6, 6),
			renkler[rng:NextInteger(1, #renkler)],
			rng:NextNumber(5, 11),
			yon * rng:NextNumber(hiz * 0.35, hiz),
			-rng:NextNumber(yukari * 0.4, yukari),
			rng:NextNumber(omur * 0.7, omur),
			620
		)
	end
end

local function olcekPop(olcek: UIScale, tepe: number, sure: number)
	olcek.Scale = tepe
	TweenService:Create(olcek, TweenInfo.new(sure, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

local function auraParlat(renk: Color3)
	auraCizgi.Color = renk
	TweenService:Create(auraCizgi, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Color = kaziRenk,
	}):Play()
end

local function tikEfekti()
	local x, y = ikonNoktasi()
	patlat(x, y, 5, { TOPRAK_RENKLERI[1], TOPRAK_RENKLERI[2], TOPRAK_RENKLERI[3], TOPRAK_RENKLERI[4], kaziRenk }, 170, 230, 0.7)

	local simdi = os.clock()
	efekt.kombo = if simdi - efekt.sonTik < 0.45 then efekt.kombo + 1 else 1
	efekt.sonTik = simdi

	if efekt.kombo >= 5 then
		komboYazi.Visible = true
		komboYazi.TextTransparency = 0
		komboYazi.Text = `{efekt.kombo} COMBO`
		komboYazi.TextColor3 = if efekt.kombo >= 30
			then Color3.fromRGB(255, 110, 60)
			elseif efekt.kombo >= 15 then EFEKT_ALTIN
			else Color3.new(1, 1, 1)
		komboYazi.Rotation = rng:NextNumber(-7, 7)
		olcekPop(komboOlcek, 1.35, 0.18)
		if efekt.kombo % 10 == 0 then
			patlat(x, y, 10, { EFEKT_ALTIN, Color3.new(1, 1, 1) }, 240, 300, 0.8)
			auraParlat(EFEKT_ALTIN)
		end
	end
end

local function efektleriSifirla()
	for _, p in efekt.parcaciklar do
		p.f:Destroy()
	end
	table.clear(efekt.parcaciklar)
	efekt.kombo = 0
	efekt.sonTik = 0
	efekt.esik = 0
	efekt.kabarcik = 0
	komboYazi.Visible = false
	sonucYazi.Visible = false
	yuzdeYazi.TextColor3 = Color3.new(1, 1, 1)
	auraCizgi.Color = kaziRenk
	kaziCerceve.Position = cerceveKonum
	kaziKatman.Position = cerceveKonum
end

local ESIKLER = { 0.25, 0.5, 0.75 }

local function ilerlemeEfekti(dt: number, ilerleme: number, tehlikede: boolean)
	efekt.ilerleme = ilerleme
	yuzdeYazi.Text = `{math.floor(ilerleme * 100 + 0.5)}%`
	yuzdeYazi.TextColor3 = if tehlikede then Color3.fromRGB(255, 90, 90) else Color3.new(1, 1, 1)

	for i, esik in ESIKLER do
		if ilerleme >= esik and efekt.esik < i then
			efekt.esik = i
			local x, y = ikonNoktasi()
			patlat(x, y, 12, { EFEKT_ALTIN, Color3.new(1, 1, 1), kaziRenk }, 220, 280, 0.8)
			auraParlat(EFEKT_ALTIN)
			olcekPop(yuzdeOlcek, 1.5, 0.3)
		end
	end

	efekt.kabarcik += dt
	while efekt.kabarcik >= 0.12 do
		efekt.kabarcik -= 0.12
		if ilerleme > 0.05 then
			parcacikAt(
				rng:NextNumber(10, kaziCerceve.Size.X.Offset - 10),
				KAZI_BOY - rng:NextNumber(0, ilerleme * KAZI_BOY),
				Color3.new(1, 1, 1),
				rng:NextNumber(4, 7),
				0,
				-rng:NextNumber(40, 80),
				0.7,
				0,
				true,
				0.55
			)
		end
	end

	if tehlikede then
		local sars = UDim2.fromOffset(rng:NextNumber(-3, 3), rng:NextNumber(-2, 2))
		kaziCerceve.Position = cerceveKonum + sars
		kaziKatman.Position = cerceveKonum + sars
	elseif kaziCerceve.Position ~= cerceveKonum then
		kaziCerceve.Position = cerceveKonum
		kaziKatman.Position = cerceveKonum
	end
end

local function sonucEfekti(kazandi: boolean)
	komboYazi.Visible = false
	kaziCerceve.Position = cerceveKonum
	kaziKatman.Position = cerceveKonum

	sonucYazi.Visible = true
	sonucYazi.TextTransparency = 0
	sonucYazi.Rotation = if kazandi then -6 else 4
	sonucYazi.Text = if kazandi then "DUG UP!" else "IT GOT AWAY!"
	sonucYazi.TextColor3 = if kazandi then EFEKT_ALTIN else Color3.fromRGB(255, 80, 80)
	sonucOlcek.Scale = 0.2
	TweenService:Create(sonucOlcek, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	local x, y = ikonNoktasi()
	if kazandi then
		patlat(x, y, 36, { kaziRenk, EFEKT_ALTIN, Color3.new(1, 1, 1), TOPRAK_RENKLERI[3] }, 320, 440, 1.1)
		auraParlat(Color3.new(1, 1, 1))
		yuzdeYazi.Text = "100%"
		olcekPop(yuzdeOlcek, 1.6, 0.35)
	else
		patlat(x, y, 14, { TOPRAK_RENKLERI[1], TOPRAK_RENKLERI[2], Color3.fromRGB(60, 40, 24) }, 140, 120, 0.8)
		auraParlat(Color3.fromRGB(255, 60, 60))
		kaziDolgu.BackgroundColor3 = Color3.fromRGB(70, 20, 20)
	end
end

local OGRETICI_NITELIK = "OgreticiAdim"
local OGRETICI_ADIM = "ilkKazi"
local OGRETICI_TABAN = 0.06

local function ogreticiKazisi(): boolean
	return player:GetAttribute(OGRETICI_NITELIK) == OGRETICI_ADIM
end

local tiklaYazilari: { TextLabel } = {}
local TIKLA_SAYI = 3
local TIKLA_OMUR = 0.85
local TIKLA_RENKLERI = {
	Color3.fromRGB(255, 240, 120),
	Color3.fromRGB(255, 170, 60),
	Color3.fromRGB(130, 235, 255),
	Color3.fromRGB(255, 255, 255),
}
local tiklaDurum: { { t: number, x: number, y: number, aci: number } } = {}

local function tiklaYeri(haric: number): (number, number)
	local x, y = 0.35, 0.4
	for _ = 1, 16 do
		x, y = rng:NextNumber(0.14, 0.6), rng:NextNumber(0.2, 0.74)
		local uygun = not (math.abs(x - 0.5) < 0.09 and math.abs(y - 0.5) < 0.15)
		if uygun then
			for j, d in tiklaDurum do
				if j ~= haric and math.abs(d.x - x) < 0.17 and math.abs(d.y - y) < 0.13 then
					uygun = false
					break
				end
			end
		end
		if uygun then
			break
		end
	end
	return x, y
end

local function tiklaYenile(i: number)
	local d = tiklaDurum[i]
	d.x, d.y = tiklaYeri(i)
	d.aci = rng:NextNumber(-16, 16)
	tiklaYazilari[i].TextColor3 = TIKLA_RENKLERI[rng:NextInteger(1, #TIKLA_RENKLERI)]
end

for i = 1, TIKLA_SAYI do
	local yazi = UI.text({
		text = "CLICK!",
		size = UI.Sizes.huge,
		font = UI.Fonts.bold,
		color = TIKLA_RENKLERI[1],
		align = Enum.TextXAlignment.Center,
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.35, 0.4),
		frameSize = UDim2.fromOffset(220, 60),
		parent = kaziEkran,
		name = `Tikla{i}`,
	})
	yazi.Visible = false
	yazi.ZIndex = 20
	table.insert(tiklaYazilari, yazi)
	table.insert(tiklaDurum, { t = -(i - 1) / TIKLA_SAYI, x = 0.35, y = 0.4, aci = 0 })
	tiklaYenile(i)
end

local tiklaZaman = 0

local function kaziOlcegiTazele()
	local alan = kaziEkran.AbsoluteSize
	local genel = UI.carpan()
	local bar = genel
	local dokunmatik = UI.Girdi.dokunmatik()
	local x = if dokunmatik then OTO_X_DOKUNMATIK else OTO_X
	local y = if dokunmatik then OTO_Y_DOKUNMATIK else OTO_Y
	cerceveKonum = UDim2.new(x, 0, y, -(OTO_BOY / 2 + KAZI_ARA))
	kaziCerceve.Position = cerceveKonum
	kaziKatman.Position = cerceveKonum
	otoKutu.Position = UDim2.fromScale(x, y)
	if alan.Y > 0 then
		local yer = alan.Y * y - (OTO_BOY / 2 + KAZI_ARA) - 16
		bar = math.min(bar, yer / (KAZI_BOY + 70))
	end
	for _, cocuk in kaziEkran:GetChildren() do
		if cocuk:IsA("GuiObject") then
			local olcek = cocuk:FindFirstChild("KaziOlcek")
			if not olcek then
				olcek = Instance.new("UIScale")
				olcek.Name = "KaziOlcek"
				olcek.Parent = cocuk
			end
			local hedef = if cocuk == kaziCerceve or cocuk == kaziKatman then bar else genel;
			(olcek :: UIScale).Scale = hedef
		end
	end
	for _, yazi in tiklaYazilari do
		yazi.Text = UI.Girdi.sec("CLICK!", "TAP!", "PRESS A!")
	end
end

kaziOlcegiTazele()
kaziEkran:GetPropertyChangedSignal("AbsoluteSize"):Connect(kaziOlcegiTazele)
UI.onScaleChanged(kaziOlcegiTazele)
UI.Girdi.degisince(kaziOlcegiTazele)

local function tiklaYazisiCiz(dt: number, acik: boolean)
	if not acik then
		if tiklaZaman > 0 then
			tiklaZaman = 0
			for i, yazi in tiklaYazilari do
				yazi.Visible = false
				tiklaDurum[i].t = -(i - 1) / TIKLA_SAYI
				tiklaYenile(i)
			end
		end
		return
	end

	tiklaZaman += dt
	for i, yazi in tiklaYazilari do
		local d = tiklaDurum[i]
		d.t += dt / TIKLA_OMUR
		if d.t >= 1 then
			d.t -= 1
			tiklaYenile(i)
		end

		if d.t < 0 then
			yazi.Visible = false
			continue
		end

		local boy, saydam, kayma = 1, 0, 0
		if d.t < 0.2 then
			boy = 0.3 + 0.8 * TweenService:GetValue(d.t / 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		elseif d.t < 0.65 then
			boy = 1.1 - 0.1 * (d.t - 0.2) / 0.45
		else
			local f = (d.t - 0.65) / 0.35
			boy = 1 + 0.15 * f
			saydam = f
			kayma = 0.03 * f
		end

		yazi.Visible = true
		yazi.Position = UDim2.fromScale(d.x, d.y - kayma)
		yazi.Rotation = d.aci
		yazi.TextSize = math.floor(UI.Sizes.huge * 1.15 * boy)
		yazi.TextTransparency = saydam
		local kontur = yazi:FindFirstChildOfClass("UIStroke")
		if kontur then
			kontur.Transparency = saydam
		end
	end
end

local mod: string = "sea"
local active: DigMinigame.Minigame? = nil
local kazi: KaziMinigame.Game? = nil
local holding = false
local connection: RBXScriptConnection? = nil

local throttleUntil = 0

local function calisiyor(): boolean
	return active ~= nil or kazi ~= nil
end

local digTrack: AnimationTrack? = nil

local donusHumanoid: Humanoid? = nil
local donusEski: boolean? = nil

local function stopDigAnimation()
	if digTrack then
		digTrack:Stop(0.15)
		digTrack:Destroy()
		digTrack = nil
	end

	if donusHumanoid and donusEski ~= nil and donusHumanoid.Parent then
		donusHumanoid.AutoRotate = donusEski
	end
	donusHumanoid = nil
	donusEski = nil
end

local function startDigAnimation()
	stopDigAnimation()

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not character or not animator then
		return
	end

	local id: string? = nil
	for deneme = 1, 10 do
		for _, item in character:GetChildren() do
			if item:IsA("Tool") then
				if item:GetAttribute("PickaxeId") then
					id = Assets.id(Assets.Animations.pickaxeDig)
					break
				elseif item:GetAttribute("ShovelId") then
					id = Assets.id(Assets.Animations.shovelDig)
					break
				end
			end
		end
		if id or deneme == 10 then
			break
		end
		task.wait(0.05)
		if not calisiyor() then
			return
		end
	end

	if not id or id == "" then
		return
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = id

	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	animation:Destroy()

	if not ok or not track then
		return
	end

	track.Priority = Enum.AnimationPriority.Action2
	track.Looped = true
	track:Play(0.1)
	digTrack = track

	local humanoidDon = character:FindFirstChildOfClass("Humanoid")
	local kok = character:FindFirstChild("HumanoidRootPart")
	local hedef = character:GetAttribute("KaziHedef")
	if humanoidDon and kok and kok:IsA("BasePart") and typeof(hedef) == "Vector3" then
		donusHumanoid = humanoidDon
		donusEski = humanoidDon.AutoRotate
		humanoidDon.AutoRotate = false
		local bakis = Vector3.new(hedef.X, kok.Position.Y, hedef.Z)
		if (bakis - kok.Position).Magnitude > 0.5 then
			kok.CFrame = CFrame.lookAt(kok.Position, bakis)
		end
	end
end

local function setHolding(value: boolean)
	holding = value
end

local GIRDI_KILIDI = 0.4
local sonGirdi: EnumItem? = nil
local sonGirdiZamani = 0

local function girdiKabulMu(girdi: EnumItem): boolean
	local simdi = os.clock()
	if sonGirdi ~= nil and girdi ~= sonGirdi and simdi - sonGirdiZamani < GIRDI_KILIDI then
		return false
	end
	sonGirdi = girdi
	sonGirdiZamani = simdi
	return true
end

local function girdiOf(input: InputObject): EnumItem
	if input.KeyCode ~= Enum.KeyCode.Unknown then
		return input.KeyCode
	end
	return input.UserInputType
end

local function tikla(girdi: EnumItem?)
	local oyun = kazi
	if not oyun then
		return
	end

	if girdi and not girdiKabulMu(girdi) then
		return
	end

	if not oyun:click() then
		throttleUntil = os.clock() + 0.4
		return
	end

	sarsintiGucu = math.min(TIK_TAVAN, sarsintiGucu + TIK_GUCU)
	vurusGucu = math.min(TIK_TAVAN, vurusGucu + TIK_GUCU)

	vurusYon = -vurusYon
	tikEfekti()
end

local aktifDokunuslar: { [InputObject]: boolean } = {}
local tutanGirdi: any = nil

local function bittiMi(state: Enum.UserInputState): boolean
	return state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel
end

local function bindInput()
	table.clear(aktifDokunuslar)
	tutanGirdi = nil

	if mod == "sand" then
		sonGirdi = nil
		ContextActionService:BindAction(ACTION_NAME, function(_, state, input)
			if input.UserInputType == Enum.UserInputType.Touch then
				if state == Enum.UserInputState.Begin then
					for eski in aktifDokunuslar do
						if bittiMi(eski.UserInputState) then
							aktifDokunuslar[eski] = nil
						end
					end
					local tekParmak = next(aktifDokunuslar) == nil
					aktifDokunuslar[input] = true
					if tekParmak then
						tikla(Enum.UserInputType.Touch)
					end
				elseif bittiMi(state) then
					aktifDokunuslar[input] = nil
				end
				return Enum.ContextActionResult.Sink
			end

			if state == Enum.UserInputState.Begin then
				tikla(girdiOf(input))
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)
		return
	end

	ContextActionService:BindAction(ACTION_NAME, function(_, state, input)
		local kimlik: any = if input.UserInputType == Enum.UserInputType.Touch then input else girdiOf(input)
		if state == Enum.UserInputState.Begin then
			if typeof(tutanGirdi) == "Instance" and bittiMi(tutanGirdi.UserInputState) then
				tutanGirdi = nil
			end
			if tutanGirdi == nil then
				tutanGirdi = kimlik
				setHolding(true)
			end
		elseif bittiMi(state) and tutanGirdi == kimlik then
			tutanGirdi = nil
			setHolding(false)
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)
end

local function unbindInput()
	ContextActionService:UnbindAction(ACTION_NAME)
	table.clear(aktifDokunuslar)
	tutanGirdi = nil
	setHolding(false)
end

local function stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	active = nil
	kazi = nil
	unbindInput()
	stopDigAnimation()
	BalikPaneli.gizle()
	kaziEkran.Enabled = false
	sarsintiyiCoz()
end

local function finish(won: boolean)
	if not calisiyor() then
		return
	end

	local kumdu = mod == "sand"
	active = nil
	kazi = nil

	if connection then
		connection:Disconnect()
		connection = nil
	end
	unbindInput()
	stopDigAnimation()

	if kumdu then
		if won then
			sarsintiGucu = ZAFER_GUCU
			vurusGucu = TIK_TAVAN
		end

		sonucEfekti(won)
		local bu = efekt.oyunNo
		task.delay(0.9, function()
			if efekt.oyunNo == bu and not calisiyor() then
				kaziEkran.Enabled = false
			end
		end)
		task.delay(0.8, sarsintiyiCoz)

		MinigameSonuc:FireServer(won)
		return
	end

	BalikPaneli.bitir(won)

	MinigameSonuc:FireServer(won)

	task.delay(1.2, function()
		if not calisiyor() then
			BalikPaneli.gizle()
		end
	end)
end

local function renderKazi(state: KaziMinigame.State, dt: number)
	kaziDolgu.Size = UDim2.fromScale(1, state.progress)

	kaziIkon.Position = UDim2.fromScale(0.5, 1 - state.progress)

	local kisildi = os.clock() < throttleUntil
	kaziDolgu.BackgroundColor3 = if kisildi then UI.Colors.warn else kaziRenk

	local tehlikede = state.progress <= TEHLIKE_ORANI
	kaziTehlike.BackgroundTransparency = if tehlikede then 0 else 0.15
	kaziTehlike.BackgroundColor3 = if tehlikede
		then Color3.fromRGB(90, 12, 12):Lerp(Color3.fromRGB(200, 30, 30), (math.sin(os.clock() * 14) + 1) * 0.5)
		else Color3.fromRGB(10, 8, 6)

	ilerlemeEfekti(dt, state.progress, tehlikede)
end

local function modKur(yeniMod: string, rarityId: string)
	mod = yeniMod
	local kumdu = yeniMod == "sand"

	if kumdu then
		BalikPaneli.gizle()
	end
	kaziEkran.Enabled = kumdu

	if kumdu then
		kaziOlcegiTazele()
		local maden = Ores.get(rarityId)
		kaziRenk = if maden then maden.islandColor else Rarity.beamColor(rarityId)

		local kazmaResmi = if maden then Icons.asset(KAZMA_IKON_ADI) else nil
		if maden and not kazmaResmi and not kazmaUyarisiVerildi then
			kazmaUyarisiVerildi = true
			warn(
				`[Minigame] Pickaxe icon not found: ReplicatedStorage > Assets > Icons `
					.. `- add a Decal or ImageLabel named "{KAZMA_IKON_ADI}". Showing the shovel for now.`
			)
		end
		kaziIkon.Image = kazmaResmi or KUREK_IKONU
		ikonAci = if kazmaResmi then KAZMA_ACI else IKON_ACI
		kaziIkon.Rotation = ikonAci
		kaziDolgu.BackgroundColor3 = kaziRenk
		kaziDolgu.Size = UDim2.fromScale(1, KaziMinigame.START)
		sarsintiyiBagla()
	else
		sarsintiyiCoz()
	end
end

MinigameBasla.OnClientEvent:Connect(function(gearId, rarityId, seed, gelenMod, zorlukId)
	if calisiyor() then
		return
	end

	local gearInfo = DigMinigame.gear(gearId)

	modKur(if gelenMod == "sand" then "sand" else "sea", rarityId)

	throttleUntil = 0
	task.spawn(startDigAnimation)

	if mod == "sand" then
		local oyun = KaziMinigame.new(gearId, if type(zorlukId) == "string" then zorlukId else rarityId)
		kazi = oyun

		efekt.oyunNo += 1
		efektleriSifirla()
		efekt.esik = math.floor(KaziMinigame.START * 4)
		bindInput()
		renderKazi(oyun.state, 0)

		local otoBirikim = 0

		connection = RunService.RenderStepped:Connect(function(dt)
			local g = kazi
			if not g then
				return
			end

			local step = math.min(dt, 1 / 20)
			local state = g:step(step)

			local ogreticide = ogreticiKazisi()
			if ogreticide and state.finished and not state.won then
				state.finished = false
				state.won = false
				state.progress = OGRETICI_TABAN
			end

			tiklaYazisiCiz(step, ogreticide and not state.finished)

			if otoCalisiyorMu() then
				otoBirikim += step
				while otoBirikim >= OtoTiklayici.ARALIK do
					otoBirikim -= OtoTiklayici.ARALIK
					tikla()
				end
			end

			renderKazi(state, step)

			if state.finished then
				tiklaYazisiCiz(step, false)
				finish(state.won)
			end
		end)
		return
	end

	BalikPaneli.basla(gearInfo, rarityId)

	local oyun = DigMinigame.new(gearId, rarityId, seed)
	active = oyun
	bindInput()
	BalikPaneli.ciz(oyun.state, holding)

	connection = RunService.RenderStepped:Connect(function(dt)
		local g = active
		if not g then
			return
		end

		local step = math.min(dt, 1 / 20)
		local state = g:step(step, holding)
		BalikPaneli.ciz(state, holding)

		if state.finished then
			finish(state.won)
		end
	end)
end)

KaziBitti.OnClientEvent:Connect(function()
	if calisiyor() then
		stop()
	end
end)

player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		if calisiyor() then
			MinigameSonuc:FireServer(false)
			stop()
		end
	end)
end)
