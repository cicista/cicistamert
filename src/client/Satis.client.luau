--[[
	Satis  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Satis

	Brainrot saticisinin ekran tarafi.

	NPC'ye E ile basinca SATIS PENCERESI acilir:
	    - envanterdeki satilabilir her brainrot fiyatiyla listelenir,
	      tiklayinca o brainrot satilir
	    - altta "Sell All" dugmesi hepsini birden satar

	Brainrotu ELDE TUTMAK yok; eskiden ekranin altinda "E ile elindekini
	sat / F ile hepsini sat" seridi vardi, o kalkti. Fiyatlar oyuncuya ozel
	oldugu icin liste sunucudan geliyor ve her satistan sonra tazeleniyor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarity = require(Shared:WaitForChild("Rarity"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))

local UI = require(script.Parent:WaitForChild("UI"))

local SaticiDurum = Net.event("SaticiDurum")
local BrainrotSat = Net.event("BrainrotSat")
local TumunuSat = Net.event("TumunuSat")

local screen = Instance.new("ScreenGui")
screen.Name = "SatisEkrani"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

------------------------------------------------------------------
-- PENCERE
------------------------------------------------------------------
local satilabilir: { any } = {}

local pencere = UI.panel(screen, UDim2.fromOffset(480, 470), "SaticiPenceresi")

UI.text({
	text = "Sell Brainrots",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	frameSize = UDim2.new(1, -80, 0, 36),
	position = UDim2.fromOffset(18, 14),
	parent = pencere,
})

local ozet = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 50),
	parent = pencere,
})

UI.closeButton(pencere).MouseButton1Click:Connect(function()
	pencere.Visible = false
end)

-- Liste ile "Sell All" dugmesi arasinda pay birakilir
local liste = Instance.new("ScrollingFrame")
liste.Name = "Liste"
liste.Position = UDim2.fromOffset(14, 82)
liste.Size = UDim2.new(1, -28, 1, -158)
liste.BackgroundTransparency = 1
liste.BorderSizePixel = 0
liste.ScrollBarThickness = 5
liste.ScrollBarImageColor3 = UI.Colors.panelLight
liste.CanvasSize = UDim2.new()
liste.AutomaticCanvasSize = Enum.AutomaticSize.Y
liste.Parent = pencere

local listeDizilim = Instance.new("UIListLayout")
listeDizilim.Padding = UDim.new(0, 8)
listeDizilim.SortOrder = Enum.SortOrder.LayoutOrder
listeDizilim.Parent = liste

local hepsiButon = UI.button(pencere, "Sell All", UDim2.new(1, -36, 0, 48), UI.Colors.good)
hepsiButon.AnchorPoint = Vector2.new(0.5, 1)
hepsiButon.Position = UDim2.new(0.5, 0, 1, -18)
local hepsiYazi = hepsiButon:FindFirstChild("Label") :: TextLabel

hepsiButon.MouseButton1Click:Connect(function()
	TumunuSat:FireServer()
end)

local function listeyiCiz()
	for _, child in liste:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	if #satilabilir == 0 then
		UI.text({
			text = "Nothing to sell. Dig up some brainrots first.",
			size = UI.Sizes.small,
			color = UI.Colors.textDim,
			frameSize = UDim2.new(1, -6, 0, 40),
			parent = liste,
		})
		return
	end

	for index, item in satilabilir do
		local renk = Rarity.color(item.rarity)
		-- Kimligi belirlenmemis brainrotun adi yok, yalnizca kademesi bilinir
		local ad = item.name or `Unidentified {Rarity.displayName(item.rarity)}`

		local row = Instance.new("TextButton")
		row.Name = item.uid
		row.Text = ""
		row.AutoButtonColor = false
		row.Size = UDim2.new(1, -6, 0, 52)
		row.BackgroundColor3 = UI.Colors.panelLight
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = liste
		UI.corner(row, 10)
		UI.stroke(row, renk, 1)

		UI.text({
			text = ad,
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = renk,
			frameSize = UDim2.new(1, -150, 0, 22),
			position = UDim2.fromOffset(14, 6),
			parent = row,
		})

		UI.text({
			text = Rarity.displayName(item.rarity),
			size = UI.Sizes.tiny,
			color = UI.Colors.textDim,
			frameSize = UDim2.new(1, -150, 0, 18),
			position = UDim2.fromOffset(14, 28),
			parent = row,
		})

		UI.text({
			text = `+{Format.short(item.value)} Rot`,
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = UI.Colors.gold,
			align = Enum.TextXAlignment.Right,
			frameSize = UDim2.new(0, 130, 0, 52),
			position = UDim2.new(1, -144, 0, 0),
			parent = row,
		})

		row.MouseButton1Click:Connect(function()
			-- Sunucu satisi yapar ve listeyi tazeler; satilan satir bir
			-- sonraki pakette kendiliginden kaybolur
			BrainrotSat:FireServer(item.uid)
		end)

		UI.hover(row)
	end
end

------------------------------------------------------------------
-- SUNUCU PAKETI
------------------------------------------------------------------
SaticiDurum.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" or not data.near then
		-- Saticidan uzaklasinca pencere kapanir
		pencere.Visible = false
		return
	end

	satilabilir = if type(data.items) == "table" then data.items else {}

	local toplam = tonumber(data.totalValue) or 0
	ozet.Text = `{#satilabilir} brainrots  --  {Format.short(toplam)} Rot total`

	if hepsiYazi then
		hepsiYazi.Text = if #satilabilir > 0
			then `Sell All  ({Format.short(toplam)} Rot)`
			else "Nothing To Sell"
	end
	hepsiButon.Active = #satilabilir > 0

	-- Prompt tetiklendiginde acilir; sonraki tazelemeler pencereyi acmaz
	if data.open then
		pencere.Visible = true
	end

	if pencere.Visible then
		listeyiCiz()
	end
end)
