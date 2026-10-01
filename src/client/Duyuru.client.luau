--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig")) :: any
local Divine = require(Shared:WaitForChild("Divine"))
local Icons = require(Shared:WaitForChild("Icons"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Unvanlar = require(Shared:WaitForChild("Unvanlar"))

local UI = require(script.Parent:WaitForChild("UI"))
local LuckyOnizleme = require(script.Parent:WaitForChild("LuckyOnizleme"))
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

local DuyuruOlayi = Net.event("Duyuru")

local BEYAZ = Color3.new(1, 1, 1)
local SIYAH = Color3.new(0, 0, 0)

local screen = Instance.new("ScreenGui")
screen.Name = "Duyurular"
screen.DisplayOrder = 45
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local function parlayanYazi(label: TextLabel, kademe: string?)
	local parilti = if kademe then Divine.Flashes[kademe] else nil
	if not parilti then
		return
	end
	local g = Instance.new("UIGradient")
	g.Name = "Parilti"
	g.Parent = label
	CollectionService:AddTag(label, parilti.tag)
end

local odulSirasi: { any } = {}
local odulAcik = false

local function yuklemeBitsin()
	local basla = os.clock()
	while playerGui:FindFirstChild("YuklemeEkrani") and os.clock() - basla < 180 do
		task.wait(0.5)
	end
	task.wait(0.6)
end

local function odulGoster(veri: any)
	odulAcik = true
	yuklemeBitsin()

	local tier = if type(veri.luckyBlock) == "string" then LuckyBlock.get(veri.luckyBlock) else nil
	local renk = if typeof(veri.renk) == "Color3"
		then veri.renk
		elseif tier then tier.color
		else Color3.fromRGB(255, 215, 60)

	local kap = Instance.new("Frame")
	kap.Name = "Odul"
	kap.AnchorPoint = Vector2.new(0.5, 0.5)
	kap.Position = UDim2.fromScale(0.5, 0.45)
	kap.Size = UDim2.fromOffset(560, 430)
	kap.BackgroundTransparency = 1
	kap.Parent = screen

	local olcek = Instance.new("UIScale")
	olcek.Scale = 0.2
	olcek.Parent = kap

	local sahne = Instance.new("Frame")
	sahne.Name = "Sahne"
	sahne.AnchorPoint = Vector2.new(0.5, 0.5)
	sahne.Position = UDim2.new(0.5, 0, 0, 150)
	sahne.Size = UDim2.fromOffset(240, 240)
	sahne.BackgroundTransparency = 1
	sahne.Parent = kap

	local huzme = UI.isikHuzmeleri(sahne, renk, {
		sayi = 14,
		uzunluk = 260,
		kalinlik = 30,
		tur = 14,
		parlaklik = 0.18,
		zIndex = 1,
	})
	huzme.Position = UDim2.fromScale(0.5, 0.5)
	UI.parlama(sahne, renk, 250, 2)
	UI.pariltilar(sahne, renk, 18, 6)

	local model = Instance.new("Frame")
	model.Name = "Model"
	model.AnchorPoint = Vector2.new(0.5, 0.5)
	model.Position = UDim2.fromScale(0.5, 0.5)
	model.Size = UDim2.fromOffset(200, 200)
	model.BackgroundTransparency = 1
	model.ZIndex = 4
	model.Parent = sahne
	if tier then
		LuckyOnizleme.ekle(model, tier, 4)
	elseif type(veri.ikon) == "string" then
		local ikon = Instance.new("ImageLabel")
		ikon.Name = "Ikon"
		ikon.AnchorPoint = Vector2.new(0.5, 0.5)
		ikon.Position = UDim2.fromScale(0.5, 0.5)
		ikon.Size = UDim2.fromScale(0.8, 0.8)
		ikon.BackgroundTransparency = 1
		ikon.ScaleType = Enum.ScaleType.Fit
		ikon.ZIndex = 5
		ikon.Parent = model
		Icons.bind(ikon, veri.ikon)
		UI.sallan(ikon)
	end
	TweenService:Create(
		model,
		TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Position = UDim2.new(0.5, 0, 0.5, -10) }
	):Play()

	local baslik = UI.text({
		text = tostring(veri.baslik or "REWARD!"),
		size = 46,
		font = UI.Fonts.bold,
		color = BEYAZ,
		glow = Color3.fromRGB(255, 215, 60),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 56),
		position = UDim2.fromOffset(0, 282),
		parent = kap,
		zIndex = 8,
	})
	local baslikOlcek = Instance.new("UIScale")
	baslikOlcek.Parent = baslik
	TweenService:Create(
		baslikOlcek,
		TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Scale = 1.06 }
	):Play()

	UI.text({
		text = tostring(veri.yazi or ""),
		size = UI.Sizes.title,
		font = UI.Fonts.bold,
		color = renk,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 36),
		position = UDim2.fromOffset(0, 340),
		parent = kap,
		zIndex = 8,
	})

	local rozet = Unvanlar.get(veri.unvanId)
	if rozet then
		local unvanYazi = UI.text({
			text = rozet.unvan,
			size = 30,
			font = UI.Fonts.bold,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.new(1, 0, 0, 36),
			position = UDim2.fromOffset(0, 378),
			parent = kap,
			zIndex = 8,
		})
		Unvanlar.stilUygula(unvanYazi, rozet.id)
	end

	UI.text({
		text = tostring(veri.alt or ""),
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 24),
		position = UDim2.fromOffset(0, if rozet then 418 else 380),
		parent = kap,
		zIndex = 8,
	})

	local kapat = Instance.new("TextButton")
	kapat.Name = "Kapat"
	kapat.Size = UDim2.fromScale(1, 1)
	kapat.BackgroundTransparency = 1
	kapat.Text = ""
	kapat.ZIndex = 10
	kapat.Parent = kap

	YerelSes.cal("LuckyBlock")

	TweenService:Create(olcek, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	local bitti = false
	local function kapan()
		if bitti then
			return
		end
		bitti = true
		local t = TweenService:Create(olcek, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 })
		t:Play()
		t.Completed:Wait()
		kap:Destroy()
		odulAcik = false
		local siradaki = table.remove(odulSirasi, 1)
		if siradaki then
			odulGoster(siradaki)
		end
	end

	kapat.Activated:Connect(kapan)
	task.delay(Config.Duyuru.odulSuresi or 4.5, kapan)
end

local seritSirasi: { any } = {}
local seritAcik = false

local function seritGoster(veri: any)
	seritAcik = true

	local kademe = tostring(veri.kademe or "")
	local renk = Rarity.color(kademe)
	local parilti = Divine.Flashes[kademe]
	local renkA = if parilti then parilti.colorA else renk
	local renkB = renkA:Lerp(SIYAH, 0.55)

	local serit = Instance.new("Frame")
	serit.Name = "SunucuDuyurusu"
	serit.AnchorPoint = Vector2.new(0.5, 0)
	serit.Position = UDim2.new(0.5, 0, 0, -120)
	serit.Size = UDim2.fromOffset(560, 66)
	serit.BackgroundColor3 = BEYAZ
	serit.BorderSizePixel = 0
	serit.ClipsDescendants = true
	serit.Parent = screen
	UI.corner(serit, 16)
	local cerceve = UI.stroke(serit, renkA, 4)
	cerceve.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	if parilti then
		CollectionService:AddTag(cerceve, parilti.tag)
	end

	local zemin = Instance.new("UIGradient")
	zemin.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, renkB),
		ColorSequenceKeypoint.new(0.5, renkA:Lerp(SIYAH, 0.25)),
		ColorSequenceKeypoint.new(1, renkB),
	})
	zemin.Parent = serit
	UI.caprazDesen(serit, BEYAZ, 8)
	UI.pariltilar(serit, renkA:Lerp(BEYAZ, 0.4), 14, 2)

	local isik = Instance.new("Frame")
	isik.Name = "Isik"
	isik.AnchorPoint = Vector2.new(0.5, 0.5)
	isik.Position = UDim2.fromScale(-0.2, 0.5)
	isik.Size = UDim2.new(0, 80, 2, 0)
	isik.Rotation = 18
	isik.BackgroundColor3 = BEYAZ
	isik.BorderSizePixel = 0
	isik.ZIndex = 3
	isik.Parent = serit
	local isikGecis = Instance.new("UIGradient")
	isikGecis.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	isikGecis.Parent = isik
	TweenService:Create(
		isik,
		TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false, 0.4),
		{ Position = UDim2.fromScale(1.2, 0.5) }
	):Play()

	local fiil = if veri.kaynak == "sea" then "FISHED UP" else "DUG UP"
	UI.text({
		text = `{string.upper(tostring(veri.oyuncu or "Someone"))} {fiil} AN`,
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -20, 0, 20),
		position = UDim2.fromOffset(10, 4),
		parent = serit,
		zIndex = 5,
	})

	local buyuk = UI.text({
		text = `{string.upper(Rarity.displayName(kademe))} EGG!`,
		size = 34,
		font = UI.Fonts.bold,
		color = renkA,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -20, 0, 38),
		position = UDim2.fromOffset(10, 23),
		parent = serit,
		zIndex = 5,
	})
	parlayanYazi(buyuk, kademe)
	local buyukOlcek = Instance.new("UIScale")
	buyukOlcek.Parent = buyuk
	TweenService:Create(
		buyukOlcek,
		TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Scale = 1.07 }
	):Play()

	YerelSes.cal("Teleport")

	TweenService:Create(
		serit,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 50) }
	):Play()

	task.delay(Config.Duyuru.seritSuresi or 6, function()
		local t = TweenService:Create(
			serit,
			TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0, -120) }
		)
		t:Play()
		t.Completed:Wait()
		serit:Destroy()
		seritAcik = false
		local siradaki = table.remove(seritSirasi, 1)
		if siradaki then
			seritGoster(siradaki)
		end
	end)
end

DuyuruOlayi.OnClientEvent:Connect(function(veri)
	if type(veri) ~= "table" then
		return
	end

	if veri.tur == "rozet" then
		local rozet = Unvanlar.get(veri.rozet)
		if not rozet then
			return
		end
		veri = {
			tur = "odul",
			baslik = "BADGE UNLOCKED!",
			yazi = rozet.ad,
			alt = "Equip your new title from the Badges menu",
			ikon = "trophies",
			renk = Unvanlar.SeviyeRenkleri[rozet.seviye],
			unvanId = rozet.id,
		}
	end

	if veri.tur == "odul" then
		if odulAcik then
			table.insert(odulSirasi, veri)
		else
			odulGoster(veri)
		end
	elseif veri.tur == "sunucu" then
		if seritAcik then
			table.insert(seritSirasi, veri)
		else
			seritGoster(veri)
		end
	end
end)
