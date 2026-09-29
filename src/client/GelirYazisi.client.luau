--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Bases = require(Shared:WaitForChild("Bases"))
local Format = require(Shared:WaitForChild("Format"))
local Icons = require(Shared:WaitForChild("Icons"))

local UI = require(script.Parent:WaitForChild("UI"))

local ARALIK = 1

local SERPME = 0.45

local YAZI_RENGI = Color3.fromRGB(105, 255, 130)
local KONTUR_RENGI = Color3.fromRGB(12, 70, 26)

local IKON_BOYU = 26

local DAGILIM_X = 3.6
local DAGILIM_Z = 2.2
local EN_ALCAK = 2
local EN_YUKSEK = 4.4

local EN_COK_ACI = 30

local POP_SURESI = 0.18
local BEKLEME = 0.5
local SONME_SURESI = 0.3

local BOY = 0.75

local YUKSELME = 1.2

local EN_COK_YAZI = 40

local sonPad: BasePart? = nil

local function benimButonum(): BasePart?
	local var = sonPad
	if var and var.Parent and var:GetAttribute("SahipId") == player.UserId then
		return var
	end

	local kok = Workspace:FindFirstChild(Bases.FolderName) or Workspace
	for _, node in kok:GetDescendants() do
		if
			node:IsA("BasePart")
			and node.Name == "ToplaButonu"
			and node:GetAttribute("SahipId") == player.UserId
		then
			sonPad = node
			return node
		end
	end

	sonPad = nil
	return nil
end

local acikYazi = 0

local function yaziCikar(pad: BasePart, gelir: number)
	if acikYazi >= EN_COK_YAZI then
		return
	end
	acikYazi += 1

	local rastgele = Random.new()

	local tabela = Instance.new("BillboardGui")
	tabela.Name = "GelirYazisi"
	tabela.Adornee = pad
	tabela.Size = UDim2.fromOffset(190, 54)
	tabela.AlwaysOnTop = true
	tabela.MaxDistance = 140
	tabela.StudsOffset = Vector3.new(
		rastgele:NextNumber(-DAGILIM_X, DAGILIM_X),
		rastgele:NextNumber(EN_ALCAK, EN_YUKSEK),
		rastgele:NextNumber(-DAGILIM_Z, DAGILIM_Z)
	)
	tabela.Parent = playerGui

	local kap = Instance.new("Frame")
	kap.Name = "Kap"
	kap.AnchorPoint = Vector2.new(0.5, 0.5)
	kap.Position = UDim2.fromScale(0.5, 0.5)
	kap.Size = UDim2.fromScale(1, 1)
	kap.BackgroundTransparency = 1
	kap.Parent = tabela

	local dizilim = Instance.new("UIListLayout")
	dizilim.FillDirection = Enum.FillDirection.Horizontal
	dizilim.Padding = UDim.new(0, 4)
	dizilim.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dizilim.VerticalAlignment = Enum.VerticalAlignment.Center
	dizilim.Parent = kap

	local ikon = Instance.new("ImageLabel")
	ikon.Name = "Ikon"
	ikon.LayoutOrder = 1
	ikon.Size = UDim2.fromOffset(IKON_BOYU, IKON_BOYU)
	ikon.BackgroundTransparency = 1
	ikon.ScaleType = Enum.ScaleType.Fit
	ikon.Visible = false
	ikon.Parent = kap
	Icons.bind(ikon, "rot", function(ok: boolean)
		ikon.Visible = ok
	end)

	local yazi = UI.text({
		text = `+{Format.short(gelir)}`,
		size = UI.Sizes.heading,
		font = UI.Fonts.bold,
		color = YAZI_RENGI,
		align = Enum.TextXAlignment.Left,
		frameSize = UDim2.fromOffset(120, 30),
		parent = kap,
		outline = false,
	})
	yazi.LayoutOrder = 2
	yazi.AutomaticSize = Enum.AutomaticSize.X
	local kontur = UI.stroke(yazi, KONTUR_RENGI, 3)

	kap.Rotation = rastgele:NextNumber(0, EN_COK_ACI) * (if rastgele:NextNumber() < 0.5 then -1 else 1)

	local olcek = Instance.new("UIScale")
	olcek.Scale = BOY * 0.35
	olcek.Parent = kap

	TweenService
		:Create(
			olcek,
			TweenInfo.new(POP_SURESI, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = BOY }
		)
		:Play()

	task.delay(POP_SURESI + BEKLEME, function()
		if not tabela.Parent then
			return
		end

		local bilgi = TweenInfo.new(SONME_SURESI, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		TweenService:Create(yazi, bilgi, { TextTransparency = 1 }):Play()
		TweenService:Create(kontur, bilgi, { Transparency = 1 }):Play()
		TweenService:Create(ikon, bilgi, { ImageTransparency = 1 }):Play()
		TweenService
			:Create(tabela, bilgi, { StudsOffset = tabela.StudsOffset + Vector3.new(0, YUKSELME, 0) })
			:Play()

		task.delay(SONME_SURESI, function()
			tabela:Destroy()
			acikYazi -= 1
		end)
	end)
end

local function gelirleriOku(pad: BasePart): { number }
	local ham = pad:GetAttribute("SlotGelirleri")
	if type(ham) ~= "string" or ham == "" then
		return {}
	end

	local liste: { number } = {}
	for parca in string.gmatch(ham, "[^,]+") do
		local sayi = tonumber(parca)
		if sayi and sayi > 0 then
			table.insert(liste, sayi)
		end
	end
	return liste
end

task.spawn(function()
	while true do
		task.wait(ARALIK)

		local pad = benimButonum()
		if not pad then
			continue
		end

		for _, gelir in gelirleriOku(pad) do
			task.delay(math.random() * SERPME, function()
				if pad.Parent and pad:GetAttribute("SahipId") == player.UserId then
					yaziCikar(pad, gelir)
				end
			end)
		end
	end
end)
