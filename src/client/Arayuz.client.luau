local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Ogretici = require(Shared:WaitForChild("Ogretici"))

local UI = require(script.Parent:WaitForChild("UI"))

local AdaMenusuAc = Net.event("AdaMenusuAc")
local AdayaGit = Net.event("AdayaGit")
local Bildirim = Net.event("Bildirim")

local screen = Instance.new("ScreenGui")
screen.Name = "OyunArayuzu"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local menu = UI.panel(screen, UDim2.fromOffset(460, 420), "AdaMenusu")

UI.text({
	text = "Where to?",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	frameSize = UDim2.new(1, -80, 0, 36),
	position = UDim2.fromOffset(18, 14),
	parent = menu,
})

UI.closeButton(menu).MouseButton1Click:Connect(function()
	menu.Visible = false
end)

local list = Instance.new("ScrollingFrame")
list.Name = "Liste"
list.Position = UDim2.fromOffset(14, 62)
list.Size = UDim2.new(1, -28, 1, -76)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.ScrollBarImageColor3 = UI.Colors.panelLight
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = menu
UI.listePayi(list)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = list

AdaMenusuAc.OnClientEvent:Connect(function(islands)
	for _, child in list:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local IP = Ogretici.AdaIpucu
	local ipucuAcik = player:GetAttribute(IP.nitelik) == true

	for _, island in islands do
		local ipucuSatiri = ipucuAcik and island.index == IP.ada
		local color = if ipucuSatiri then IP.renk else (island.color or UI.Colors.accent)

		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -6, 0, 76)
		button.BackgroundColor3 = UI.Colors.panelLight
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = ""
		button.LayoutOrder = island.index
		button.Parent = list
		UI.corner(button, 10)
		local cerceve = UI.stroke(button, color, if ipucuSatiri then 3 else 1)

		if ipucuSatiri then
			TweenService:Create(
				cerceve,
				TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Thickness = 6, Transparency = 0.35 }
			):Play()
		end

		UI.text({
			text = island.name,
			size = UI.Sizes.label,
			font = UI.Fonts.bold,
			color = color,
			frameSize = UDim2.new(1, -130, 0, 24),
			position = UDim2.fromOffset(14, 12),
			parent = button,
		})

		UI.text({
			text = island.desc or "",
			size = UI.Sizes.small,
			color = UI.Colors.textDim,
			frameSize = UDim2.new(1, -130, 0, 20),
			position = UDim2.fromOffset(14, 40),
			parent = button,
		})

		local statusText, statusColor
		if island.state == "home" then
			statusText = "FREE"
			statusColor = UI.Colors.good
		elseif island.state == "locked" then
			statusText = "LOCKED"
			statusColor = UI.Colors.textDim
		elseif island.state == "buyable" then
			statusText = `{Format.short(island.price)} Rot`
			statusColor = if ipucuSatiri then IP.renk else UI.Colors.gold
		else
			statusText = "UNLOCKED"
			statusColor = UI.Colors.good
		end

		UI.text({
			text = statusText,
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = statusColor,
			align = Enum.TextXAlignment.Right,
			frameSize = UDim2.fromOffset(110, 24),
			position = UDim2.new(1, -124, 0.5, -12),
			parent = button,
		})

		if island.state == "locked" then
			button.BackgroundTransparency = 0.5
		else
			button.MouseButton1Click:Connect(function()
				AdayaGit:FireServer(island.index)
				menu.Visible = false
			end)

			UI.hover(button)
		end
	end

	menu.Visible = true
end)

local toastHolder = Instance.new("Frame")
toastHolder.Name = "Bildirimler"
toastHolder.AnchorPoint = Vector2.new(0.5, 0)
toastHolder.Size = UDim2.fromOffset(520, 240)
toastHolder.BackgroundTransparency = 1
toastHolder.Parent = screen

local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 6)
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toastHolder

local SAYAC_ALANI = 60

local function toastYerlestir()
	local carpan = UI.carpan()
	toastHolder.Position = UDim2.new(0.5, 0, 0, 12 + SAYAC_ALANI * carpan)
end

toastYerlestir()
UI.onScaleChanged(toastYerlestir)

local toastOrder = 0

Bildirim.OnClientEvent:Connect(function(text, color)
	toastOrder += 1

	local yazi = UI.text({
		text = tostring(text),
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = color or UI.Colors.text,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(0, 30),
		parent = toastHolder,
	})
	yazi.Name = "Bildirim"
	yazi.AutomaticSize = Enum.AutomaticSize.X
	yazi.LayoutOrder = toastOrder

	task.delay(3, function()
		if not yazi.Parent then
			return
		end

		local sure = TweenInfo.new(0.35)

		local kontur = yazi:FindFirstChildOfClass("UIStroke")
		if kontur then
			TweenService:Create(kontur, sure, { Transparency = 1 }):Play()
		end

		local sonme = TweenService:Create(yazi, sure, { TextTransparency = 1 })
		sonme:Play()
		sonme.Completed:Wait()
		yazi:Destroy()
	end)
end)
