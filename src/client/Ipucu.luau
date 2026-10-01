--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local UI = require(script.Parent:WaitForChild("UI"))

local Ipucu = {}

export type Icerik = { baslik: string, renk: Color3, satirlar: { string } }

local EN = 270
local BOSLUK = 10

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screen = Instance.new("ScreenGui")
screen.Name = "EtkinlikIpucu"
screen.DisplayOrder = 20
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local balon = Instance.new("Frame")
balon.Name = "Balon"
balon.AnchorPoint = Vector2.new(1, 0)
balon.Size = UDim2.fromOffset(EN, 0)
balon.AutomaticSize = Enum.AutomaticSize.Y
balon.BackgroundColor3 = Color3.fromRGB(16, 18, 30)
balon.BackgroundTransparency = 0.06
balon.BorderSizePixel = 0
balon.Visible = false
balon.Parent = screen
UI.corner(balon, 12)
local kontur = UI.stroke(balon, Color3.new(1, 1, 1), 2)

local pay = Instance.new("UIPadding")
pay.PaddingTop = UDim.new(0, 8)
pay.PaddingBottom = UDim.new(0, 10)
pay.PaddingLeft = UDim.new(0, 12)
pay.PaddingRight = UDim.new(0, 12)
pay.Parent = balon

local duzen = Instance.new("UIListLayout")
duzen.SortOrder = Enum.SortOrder.LayoutOrder
duzen.Padding = UDim.new(0, 3)
duzen.Parent = balon

local baslik = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	frameSize = UDim2.new(1, 0, 0, 24),
	parent = balon,
})
baslik.LayoutOrder = 0

local satirlar: { TextLabel } = {}

local function satir(sira: number): TextLabel
	local etiket = satirlar[sira]
	if etiket then
		return etiket
	end
	etiket = UI.text({
		text = "",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(225, 230, 240),
		wrapped = true,
		alignY = Enum.TextYAlignment.Top,
		frameSize = UDim2.new(1, 0, 0, 0),
		parent = balon,
	})
	etiket.AutomaticSize = Enum.AutomaticSize.Y
	etiket.LayoutOrder = sira
	satirlar[sira] = etiket
	return etiket
end

local function gorunur(nesne: GuiObject): boolean
	local node: Instance? = nesne
	while node do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		if node:IsA("LayerCollector") then
			return node.Enabled
		end
		node = node.Parent
	end
	return false
end

local aktifHedef: GuiObject? = nil
local aktifIcerik: (() -> Icerik)? = nil

local function doldur()
	local hedef, icerik = aktifHedef, aktifIcerik
	if not hedef or not icerik or not gorunur(hedef) or hedef.AbsoluteSize.X <= 0 then
		balon.Visible = false
		return
	end

	local veri = icerik()
	baslik.Text = veri.baslik
	baslik.TextColor3 = veri.renk
	kontur.Color = veri.renk

	for i, metin in veri.satirlar do
		local etiket = satir(i)
		etiket.Text = metin
		etiket.Visible = true
	end
	for i = #veri.satirlar + 1, #satirlar do
		satirlar[i].Visible = false
	end

	balon.Position = UDim2.fromOffset(hedef.AbsolutePosition.X - BOSLUK, hedef.AbsolutePosition.Y)
	balon.Visible = true
end

local function kapat(hedef: GuiObject?)
	if hedef == nil or aktifHedef == hedef then
		aktifHedef = nil
		aktifIcerik = nil
		balon.Visible = false
	end
end

local sonYenileme = 0
RunService.Heartbeat:Connect(function()
	if not aktifHedef then
		return
	end
	local simdi = os.clock()
	if simdi - sonYenileme >= 0.25 then
		sonYenileme = simdi
		doldur()
	end
end)

function Ipucu.bagla(hedef: GuiObject, icerik: () -> Icerik)
	local dugme = Instance.new("TextButton")
	dugme.Name = "IpucuAlani"
	dugme.BackgroundTransparency = 1
	dugme.Text = ""
	dugme.Size = UDim2.fromScale(1, 1)
	dugme.ZIndex = 20
	dugme.Parent = hedef

	local function ac()
		aktifHedef = hedef
		aktifIcerik = icerik
		doldur()
	end

	dugme.MouseEnter:Connect(ac)
	dugme.MouseLeave:Connect(function()
		kapat(hedef)
	end)
	dugme.Activated:Connect(function()
		if UI.Girdi.dokunmatik() then
			if aktifHedef == hedef and balon.Visible then
				kapat(hedef)
			else
				ac()
			end
		end
	end)
	hedef:GetPropertyChangedSignal("Visible"):Connect(function()
		if not hedef.Visible then
			kapat(hedef)
		end
	end)
end

return Ipucu
