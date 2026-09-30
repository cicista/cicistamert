--!strict

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UI = require(script.Parent:WaitForChild("UI"))
local Girdi = UI.Girdi

type Satir = { tuslar: { Enum.KeyCode | string }, yazi: string }

local KC = Enum.KeyCode

local YUZ_RENKLERI: { [Enum.KeyCode]: Color3 } = {
	[KC.ButtonA] = Color3.fromRGB(96, 200, 90),
	[KC.ButtonB] = Color3.fromRGB(226, 76, 76),
	[KC.ButtonX] = Color3.fromRGB(70, 140, 235),
	[KC.ButtonY] = Color3.fromRGB(240, 196, 40),
}

local REHBERLER: { [string]: { Satir } } = {
	gamepadTemel = {
		{ tuslar = { KC.ButtonA }, yazi = "Jump" },
		{ tuslar = { KC.ButtonX }, yazi = "Dig / Interact" },
		{ tuslar = { KC.ButtonR2 }, yazi = "Use item" },
		{ tuslar = { KC.ButtonL1, KC.ButtonR1 }, yazi = "Switch item" },
		{ tuslar = { KC.ButtonY }, yazi = "Backpack" },
		{ tuslar = { KC.ButtonSelect }, yazi = "Menus" },
	},
	gamepadUcus = {
		{ tuslar = { KC.ButtonA }, yazi = "Fly up" },
		{ tuslar = { KC.ButtonL2 }, yazi = "Fly down" },
		{ tuslar = { KC.ButtonX }, yazi = "Fish / Interact" },
		{ tuslar = { KC.ButtonR2 }, yazi = "Use item" },
	},
	gamepadKazi = {
		{ tuslar = { KC.ButtonA }, yazi = "Tap fast to dig!" },
	},
	gamepadBalik = {
		{ tuslar = { KC.ButtonA }, yazi = "Hold to reel in" },
	},
	gamepadPanel = {
		{ tuslar = { KC.DPadUp }, yazi = "Move" },
		{ tuslar = { KC.ButtonA }, yazi = "Select" },
		{ tuslar = { KC.ButtonB }, yazi = "Close" },
	},
	gamepadSecim = {
		{ tuslar = { KC.DPadUp }, yazi = "Move" },
		{ tuslar = { KC.ButtonA }, yazi = "Select" },
		{ tuslar = { KC.ButtonSelect }, yazi = "Back to game" },
	},
	klavyeTemel = {
		{ tuslar = { KC.E }, yazi = "Interact" },
		{ tuslar = { "CLICK" }, yazi = "Dig / Use item" },
		{ tuslar = { "1-9" }, yazi = "Items" },
		{ tuslar = { KC.B }, yazi = "Backpack" },
	},
	klavyeUcus = {
		{ tuslar = { KC.Space }, yazi = "Fly up" },
		{ tuslar = { "SHIFT" }, yazi = "Fly down" },
	},
	klavyeKazi = {
		{ tuslar = { "CLICK", KC.Space }, yazi = "Tap fast to dig!" },
	},
	klavyeBalik = {
		{ tuslar = { "CLICK", KC.Space }, yazi = "Hold to reel in" },
	},
}

local ekran = Instance.new("ScreenGui")
ekran.Name = "KontrolRehberi"
ekran.DisplayOrder = 25
ekran.ResetOnSpawn = false
ekran.IgnoreGuiInset = true
ekran.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ekran.Parent = playerGui

local serit = Instance.new("Frame")
serit.Name = "Rehber"
serit.AnchorPoint = Vector2.new(0.5, 1)
serit.Position = UDim2.new(0.5, 0, 1, -94)
serit.Size = UDim2.fromOffset(0, 34)
serit.AutomaticSize = Enum.AutomaticSize.X
serit.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
serit.BackgroundTransparency = 0.35
serit.BorderSizePixel = 0
serit.Visible = false
serit.Parent = ekran
UI.corner(serit, 17)

do
	local dolgu = Instance.new("UIPadding")
	dolgu.PaddingLeft = UDim.new(0, 10)
	dolgu.PaddingRight = UDim.new(0, 12)
	dolgu.Parent = serit

	local dizilim = Instance.new("UIListLayout")
	dizilim.FillDirection = Enum.FillDirection.Horizontal
	dizilim.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dizilim.VerticalAlignment = Enum.VerticalAlignment.Center
	dizilim.Padding = UDim.new(0, 16)
	dizilim.SortOrder = Enum.SortOrder.LayoutOrder
	dizilim.Parent = serit
end

local function cip(tus: Enum.KeyCode | string, parent: Instance, sira: number)
	local ad = if typeof(tus) == "EnumItem" then Girdi.tusAdi(tus :: Enum.KeyCode) else tus :: string
	local resim = if typeof(tus) == "EnumItem" and Girdi.gamepad() then Girdi.tusResmi(tus :: Enum.KeyCode) else nil

	if resim then
		local ikon = Instance.new("ImageLabel")
		ikon.Name = "Tus"
		ikon.LayoutOrder = sira
		ikon.Size = UDim2.fromOffset(26, 26)
		ikon.BackgroundTransparency = 1
		ikon.Image = resim
		ikon.ScaleType = Enum.ScaleType.Fit
		ikon.Parent = parent
		return
	end

	local yuzRengi = if typeof(tus) == "EnumItem" then YUZ_RENKLERI[tus :: Enum.KeyCode] else nil
	local gamepadMi = Girdi.gamepad()

	local kutu = Instance.new("TextLabel")
	kutu.Name = "Tus"
	kutu.LayoutOrder = sira
	kutu.AutomaticSize = Enum.AutomaticSize.X
	kutu.Size = UDim2.fromOffset(if yuzRengi then 26 else 0, 26)
	kutu.BackgroundColor3 = yuzRengi or (if gamepadMi then Color3.fromRGB(60, 64, 76) else Color3.fromRGB(236, 238, 244))
	kutu.BorderSizePixel = 0
	kutu.Text = ad
	kutu.TextColor3 = if yuzRengi or gamepadMi then Color3.new(1, 1, 1) else Color3.fromRGB(30, 32, 40)
	kutu.TextSize = if #ad > 2 then 13 else 16
	kutu.FontFace = UI.Fonts.bold
	kutu.Parent = parent
	UI.corner(kutu, if yuzRengi then 13 else 7)
	UI.stroke(kutu, Color3.fromRGB(0, 0, 0), 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	if not yuzRengi then
		local dolgu = Instance.new("UIPadding")
		dolgu.PaddingLeft = UDim.new(0, 7)
		dolgu.PaddingRight = UDim.new(0, 7)
		dolgu.Parent = kutu
	end
end

local function satirKur(satir: Satir, sira: number)
	local kap = Instance.new("Frame")
	kap.Name = "Satir"
	kap.LayoutOrder = sira
	kap.AutomaticSize = Enum.AutomaticSize.X
	kap.Size = UDim2.fromOffset(0, 30)
	kap.BackgroundTransparency = 1
	kap.Parent = serit

	local dizilim = Instance.new("UIListLayout")
	dizilim.FillDirection = Enum.FillDirection.Horizontal
	dizilim.VerticalAlignment = Enum.VerticalAlignment.Center
	dizilim.Padding = UDim.new(0, 4)
	dizilim.SortOrder = Enum.SortOrder.LayoutOrder
	dizilim.Parent = kap

	for i, tus in satir.tuslar do
		cip(tus, kap, i)
	end

	local yazi = UI.text({
		text = satir.yazi,
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = Color3.new(1, 1, 1),
		frameSize = UDim2.fromOffset(0, 30),
		parent = kap,
	})
	yazi.AutomaticSize = Enum.AutomaticSize.X
	yazi.LayoutOrder = #satir.tuslar + 1
	yazi.TextTruncate = Enum.TextTruncate.None
	local bosluk = Instance.new("UIPadding")
	bosluk.PaddingLeft = UDim.new(0, 4)
	bosluk.Parent = yazi
end

local function ekranAcikMi(ad: string): boolean
	local gui = playerGui:FindFirstChild(ad)
	return gui ~= nil and gui:IsA("ScreenGui") and gui.Enabled
end

local function baglam(): string?
	local tur = Girdi.tur()
	if tur == "dokunmatik" or player:GetAttribute("RehberKapali") == true then
		return nil
	end
	local onEk = if tur == "gamepad" then "gamepad" else "klavye"

	if ekranAcikMi("KaziBar") then
		return onEk .. "Kazi"
	end
	if ekranAcikMi("KaziMinigame") then
		return onEk .. "Balik"
	end
	if UI.acikPanelVarMi() then
		return if tur == "gamepad" then "gamepadPanel" else nil
	end
	if tur == "gamepad" and GuiService.SelectedObject ~= nil then
		return "gamepadSecim"
	end
	if player:GetAttribute("Flyboarding") == true then
		return onEk .. "Ucus"
	end
	return onEk .. "Temel"
end

local sonImza = ""

local function tazele()
	local anahtar = baglam()
	local imza = `{anahtar or "yok"}|{Girdi.tur()}`
	if imza == sonImza then
		return
	end
	sonImza = imza

	for _, cocuk in serit:GetChildren() do
		if cocuk:IsA("GuiObject") then
			cocuk:Destroy()
		end
	end

	local liste = if anahtar then REHBERLER[anahtar] else nil
	if not liste then
		serit.Visible = false
		return
	end

	for i, satir in liste do
		satirKur(satir, i)
	end

	local panelde = anahtar == "gamepadPanel" or anahtar == "gamepadSecim"
	serit.Position = UDim2.new(0.5, 0, 1, if panelde then -10 else -94)
	serit.Visible = true
end

tazele()
Girdi.degisince(tazele)
player:GetAttributeChangedSignal("RehberKapali"):Connect(tazele)

task.spawn(function()
	while true do
		task.wait(0.25)
		tazele()
	end
end)
