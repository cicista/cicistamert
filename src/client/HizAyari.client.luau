--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Hiz = require(Shared:WaitForChild("Hiz"))
local Net = require(Shared:WaitForChild("Net"))

local UI = require(script.Parent:WaitForChild("UI"))

local HizAyarla = Net.event("HizAyarla")

local EK_BOY = 96
local GONDERME_ARALIGI = 0.2

local katman = playerGui:WaitForChild("PanelKatmani", 60)
local panel = katman and katman:WaitForChild("Hiz", 60)
if not panel or not panel:IsA("Frame") then
	return
end

local tabanBoy = panel.Size.Y.Offset
panel.Size = UDim2.fromOffset(panel.Size.X.Offset, tabanBoy + EK_BOY)

local bolum = Instance.new("Frame")
bolum.Name = "HizAyari"
bolum.Position = UDim2.fromOffset(18, tabanBoy - 8)
bolum.Size = UDim2.new(1, -36, 0, EK_BOY)
bolum.BackgroundColor3 = Color3.fromRGB(22, 24, 36)
bolum.BorderSizePixel = 0
bolum.Parent = panel
UI.corner(bolum, 10)
UI.stroke(bolum, Color3.new(0, 0, 0), 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Border

UI.text({
	text = "WALK SPEED",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(0.5, 0, 0, 22),
	position = UDim2.fromOffset(12, 6),
	parent = bolum,
})

local degerYazi = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = Color3.fromRGB(110, 230, 255),
	align = Enum.TextXAlignment.Right,
	frameSize = UDim2.new(0.5, -12, 0, 22),
	position = UDim2.new(0.5, 0, 0, 6),
	parent = bolum,
})

local eksi = UI.dugme3B(bolum, "-", UDim2.fromOffset(40, 40), UI.Colors.panelLight, false)
eksi.Position = UDim2.fromOffset(10, 36)

local arti = UI.dugme3B(bolum, "+", UDim2.fromOffset(40, 40), UI.Colors.panelLight, false)
arti.AnchorPoint = Vector2.new(1, 0)
arti.Position = UDim2.new(1, -78, 0, 36)

local maks = UI.dugme3B(bolum, "MAX", UDim2.fromOffset(60, 40), Color3.fromRGB(60, 160, 255), false)
maks.AnchorPoint = Vector2.new(1, 0)
maks.Position = UDim2.new(1, -10, 0, 36)

local oluk = Instance.new("TextButton")
oluk.Name = "Oluk"
oluk.Text = ""
oluk.AutoButtonColor = false
oluk.Position = UDim2.fromOffset(62, 48)
oluk.Size = UDim2.new(1, -62 - 128, 0, 16)
oluk.BackgroundColor3 = Color3.fromRGB(12, 13, 20)
oluk.BorderSizePixel = 0
oluk.Parent = bolum
UI.corner(oluk, 8)

local dolgu = Instance.new("Frame")
dolgu.Name = "Dolgu"
dolgu.Size = UDim2.fromScale(1, 1)
dolgu.BackgroundColor3 = Color3.fromRGB(110, 230, 255)
dolgu.BorderSizePixel = 0
dolgu.Parent = oluk
UI.corner(dolgu, 8)
UI.cubukCilasi(dolgu)

local tutamak = Instance.new("Frame")
tutamak.Name = "Tutamak"
tutamak.AnchorPoint = Vector2.new(0.5, 0.5)
tutamak.Position = UDim2.fromScale(1, 0.5)
tutamak.Size = UDim2.fromOffset(28, 28)
tutamak.BackgroundColor3 = Color3.new(1, 1, 1)
tutamak.BorderSizePixel = 0
tutamak.ZIndex = 3
tutamak.Parent = oluk
UI.corner(tutamak, 14)
UI.stroke(tutamak, Color3.fromRGB(40, 120, 220), 3).ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local secilen = 0
local surukleniyor = false
local sonGonderim = 0
local bekleyen = false

local function maksimum(): number
	return math.clamp(tonumber(player:GetAttribute(Hiz.Nitelik)) or 0, 0, Hiz.Max)
end

local function sunucudanSecim(): number
	return Hiz.etkinSeviye(maksimum(), tonumber(player:GetAttribute(Hiz.TercihNitelik)))
end

local function ciz()
	local enCok = maksimum()
	local oran = if enCok > 0 then secilen / enCok else 1
	dolgu.Size = UDim2.fromScale(oran, 1)
	tutamak.Position = UDim2.fromScale(oran, 0.5)
	local hiz = math.floor(Hiz.hiz(secilen) + 0.5)
	local tepe = math.floor(Hiz.hiz(enCok) + 0.5)
	degerYazi.Text = if enCok == 0
		then "Buy Speed upgrades to unlock"
		elseif secilen >= enCok then `{hiz}  (MAX)`
		else `{hiz} / {tepe}`
end

local function gonder(zorla: boolean?)
	local simdi = os.clock()
	if not zorla and simdi - sonGonderim < GONDERME_ARALIGI then
		if not bekleyen then
			bekleyen = true
			task.delay(GONDERME_ARALIGI, function()
				bekleyen = false
				gonder(true)
			end)
		end
		return
	end
	sonGonderim = simdi
	HizAyarla:FireServer(secilen)
end

local function ayarla(seviye: number)
	local yeni = math.clamp(math.floor(seviye + 0.5), 0, maksimum())
	if yeni == secilen then
		return
	end
	secilen = yeni
	ciz()
	gonder()
end

local function konumdan(x: number)
	local sol = oluk.AbsolutePosition.X
	local en = math.max(1, oluk.AbsoluteSize.X)
	ayarla(math.clamp((x - sol) / en, 0, 1) * maksimum())
end

oluk.InputBegan:Connect(function(girdi)
	if girdi.UserInputType == Enum.UserInputType.MouseButton1 or girdi.UserInputType == Enum.UserInputType.Touch then
		surukleniyor = true
		konumdan(girdi.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(girdi)
	if not surukleniyor then
		return
	end
	if girdi.UserInputType == Enum.UserInputType.MouseMovement or girdi.UserInputType == Enum.UserInputType.Touch then
		konumdan(girdi.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(girdi)
	if girdi.UserInputType == Enum.UserInputType.MouseButton1 or girdi.UserInputType == Enum.UserInputType.Touch then
		if surukleniyor then
			surukleniyor = false
			gonder(true)
		end
	end
end)

eksi.MouseButton1Click:Connect(function()
	ayarla(secilen - math.max(1, math.floor(maksimum() / 20)))
end)

arti.MouseButton1Click:Connect(function()
	ayarla(secilen + math.max(1, math.floor(maksimum() / 20)))
end)

maks.MouseButton1Click:Connect(function()
	ayarla(maksimum())
end)

local function sunucuyuOku()
	if surukleniyor then
		return
	end
	secilen = sunucudanSecim()
	ciz()
end

player:GetAttributeChangedSignal(Hiz.Nitelik):Connect(sunucuyuOku)
player:GetAttributeChangedSignal(Hiz.TercihNitelik):Connect(sunucuyuOku)
panel:GetPropertyChangedSignal("Visible"):Connect(sunucuyuOku)
sunucuyuOku()
