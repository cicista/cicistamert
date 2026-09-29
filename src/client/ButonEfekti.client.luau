--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local SURE = 0.12
local BUYUME = 1.06
local BASMA = 0.96

local EN_BUYUK = 460
local LISTEDE_EN_BUYUK = 250

local OLCEK_ADI = "ButonEfektOlcek"
local ISARET = "ButonEfekti"

local bilgi = TweenInfo.new(SURE, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function listedeMi(buton: GuiButton): boolean
	local node = buton.Parent
	while node and node ~= playerGui do
		if node:IsA("ScrollingFrame") then
			return true
		end
		node = node.Parent
	end
	return false
end

local function uygunMu(buton: GuiButton): boolean
	if buton:GetAttribute("EfektYok") then
		return false
	end

	for _, d in buton:GetDescendants() do
		if d:IsA("UIScale") and d.Name ~= OLCEK_ADI then
			return false
		end
	end

	local boyut = buton.AbsoluteSize
	if boyut.X <= 0 or boyut.Y <= 0 then
		return false
	end
	if boyut.X > EN_BUYUK or boyut.Y > EN_BUYUK then
		return false
	end
	if boyut.X > LISTEDE_EN_BUYUK and listedeMi(buton) then
		return false
	end

	return true
end

local function olcek(buton: GuiButton): UIScale
	local var = buton:FindFirstChild(OLCEK_ADI)
	if var and var:IsA("UIScale") then
		return var
	end
	local yeni = Instance.new("UIScale")
	yeni.Name = OLCEK_ADI
	yeni.Scale = 1
	yeni.Parent = buton
	return yeni
end

local function oynat(buton: GuiButton, hedef: number)
	local var = buton:FindFirstChild(OLCEK_ADI)
	if not var then
		if hedef == 1 or not uygunMu(buton) then
			return
		end
	end
	TweenService:Create(olcek(buton), bilgi, { Scale = hedef }):Play()
end

local function bagla(node: Instance)
	if not node:IsA("GuiButton") or node:GetAttribute(ISARET) then
		return
	end
	local buton = node :: GuiButton
	buton:SetAttribute(ISARET, true)

	local ustunde = false

	buton.MouseEnter:Connect(function()
		ustunde = true
		oynat(buton, BUYUME)
	end)
	buton.MouseLeave:Connect(function()
		ustunde = false
		oynat(buton, 1)
	end)
	buton.MouseButton1Down:Connect(function()
		oynat(buton, BASMA)
	end)
	buton.MouseButton1Up:Connect(function()
		oynat(buton, if ustunde then BUYUME else 1)
	end)
	buton:GetPropertyChangedSignal("Visible"):Connect(function()
		ustunde = false
		local var = buton:FindFirstChild(OLCEK_ADI)
		if var and var:IsA("UIScale") then
			var.Scale = 1
		end
	end)
end

for _, node in playerGui:GetDescendants() do
	bagla(node)
end
playerGui.DescendantAdded:Connect(bagla)
