--[[
	SeviyeArayuz  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > SeviyeArayuz

	Ekranin ust ortasinda LEVEL gostergesi:

	    (12) [=========-------  340 / 1000 XP ]
	                  +25 XP

	Level atlayinca ortada "LEVEL UP!" yazisi buyuyerek belirir; altinda
	kazanilan Rot Coin ve kalici sans yazar.

	Veriler sunucudan gelir (bkz. ServerScriptService > Modules > Seviye);
	burasi yalnizca gosterir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
local kutu = Instance.new("Frame")
kutu.Name = "SeviyeBari"
kutu.AnchorPoint = Vector2.new(0.5, 0)
kutu.Position = UDim2.new(0.5, 0, 0, 8)
kutu.Size = UDim2.fromOffset(380, 48)
kutu.BackgroundTransparency = 1
kutu.Visible = false
kutu.Parent = screen

-- Barin zemini
local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.AnchorPoint = Vector2.new(0, 0.5)
bar.Position = UDim2.new(0, 30, 0.5, 0)
bar.Size = UDim2.new(1, -34, 0, 28)
bar.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
bar.BorderSizePixel = 0
bar.Parent = kutu
UI.corner(bar, 14)
UI.stroke(bar, SIYAH, 3)

local dolgu = Instance.new("Frame")
dolgu.Name = "Dolgu"
dolgu.Size = UDim2.fromScale(0, 1)
dolgu.BackgroundColor3 = Color3.new(1, 1, 1)
dolgu.BorderSizePixel = 0
dolgu.Parent = bar
UI.corner(dolgu, 14)

local dolguGecis = Instance.new("UIGradient")
dolguGecis.Color = ColorSequence.new(Color3.fromRGB(90, 230, 110), Color3.fromRGB(70, 200, 255))
dolguGecis.Parent = dolgu

local xpYazi = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 20, 1, 0),
	position = UDim2.fromOffset(10, 0),
	parent = bar,
	name = "XpYazi",
})
xpYazi.ZIndex = 3

-- Soldaki yuvarlak level rozeti (barin ustune biner)
local rozet = Instance.new("Frame")
rozet.Name = "Rozet"
rozet.AnchorPoint = Vector2.new(0, 0.5)
rozet.Position = UDim2.new(0, 0, 0.5, 0)
rozet.Size = UDim2.fromOffset(48, 48)
rozet.BackgroundColor3 = ALTIN
rozet.BorderSizePixel = 0
rozet.ZIndex = 4
rozet.Parent = kutu
UI.corner(rozet, 24)
UI.stroke(rozet, SIYAH, 3)

local rozetOlcek = Instance.new("UIScale")
rozetOlcek.Parent = rozet

local levelYazi = UI.text({
	text = "1",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = rozet,
	name = "Level",
})
levelYazi.ZIndex = 5

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
		xpYazi.Text = `{Format.short(xp)} / {Format.short(need)} XP`
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
