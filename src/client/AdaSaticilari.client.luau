--[[
	AdaSaticilari  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > AdaSaticilari

	Candy, Snow ve Volcano adalarindaki saticilarin ekranlari:

	  KUREK SATICISI  adanin 5 kuregi; her satirda Rot bedeli ve adanin uc
	                  madeninden istenen adet. Yetmeyen bedel sari yazilir.
	  KAZMA SATICISI  adanin kazmasi + maden takasi ("GET 1": diger iki
	                  madenden birer tane verip bunu al).

	Panel verisini sunucu gonderir (bkz. ServerScriptService > AdaSaticilari);
	satin alma / takas sonrasi guncel veriyle yeniden cizilir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))

local UI = require(script.Parent:WaitForChild("UI"))

local AdaKurekAc = Net.event("AdaKurekAc")
local AdaKurekAl = Net.event("AdaKurekAl")
local KazmaAc = Net.event("KazmaAc")
local KazmaAl = Net.event("KazmaAl")
local MadenTakas = Net.event("MadenTakas")

local screen = Instance.new("ScreenGui")
screen.Name = "AdaSaticilari"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

------------------------------------------------------------------
-- ORTAK
------------------------------------------------------------------
local function liste(parent: Instance, position: UDim2, size: UDim2): ScrollingFrame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Liste"
	scroll.Position = position
	scroll.Size = size
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.ScrollBarImageColor3 = UI.Colors.panelLight
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	return scroll
end

local function temizle(scroll: ScrollingFrame)
	for _, child in scroll:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function bolumBasligi(parent: Instance, text: string, order: number)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -6, 0, 24)
	holder.BackgroundTransparency = 1
	holder.LayoutOrder = order
	holder.Parent = parent

	UI.text({
		text = text,
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		frameSize = UDim2.fromScale(1, 1),
		parent = holder,
	})
end

local function satir(parent: Instance, order: number, renk: Color3, vurgulu: boolean): TextButton
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, -6, 0, 74)
	row.BackgroundColor3 = UI.Colors.panelLight
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	row.Text = ""
	row.LayoutOrder = order
	row.Parent = parent
	UI.corner(row, 10)
	UI.stroke(row, if vurgulu then renk else UI.Colors.panelLight, if vurgulu then 2 else 1)
	return row
end

local function madenYazisi(ores: { any }): string
	local parcalar = {}
	for _, ore in ores do
		table.insert(parcalar, `{ore.displayName} x{ore.count}`)
	end
	return table.concat(parcalar, "     ")
end

local function durumYazisi(entry: any, fiyat: string): (string, Color3)
	if entry.equipped then
		return "EQUIPPED", UI.Colors.good
	elseif entry.owned then
		return "USE", UI.Colors.accent
	elseif entry.buyable then
		return fiyat, UI.Colors.gold
	end
	return "LOCKED", UI.Colors.textDim
end

local function panelBasligi(panel: Frame): (TextLabel, TextLabel)
	local baslik = UI.text({
		text = "",
		size = UI.Sizes.title,
		font = UI.Fonts.bold,
		frameSize = UDim2.new(1, -80, 0, 36),
		position = UDim2.fromOffset(18, 14),
		parent = panel,
	})

	local alt = UI.text({
		text = "",
		size = UI.Sizes.small,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -36, 0, 20),
		position = UDim2.fromOffset(18, 50),
		parent = panel,
	})

	UI.closeButton(panel).MouseButton1Click:Connect(function()
		panel.Visible = false
	end)

	return baslik, alt
end

------------------------------------------------------------------
-- KUREK SATICISI
------------------------------------------------------------------
local kurekPanel = UI.panel(screen, UDim2.fromOffset(600, 520), "AdaKurekSaticisi")
local kurekBaslik, kurekAlt = panelBasligi(kurekPanel)
local kurekListe = liste(kurekPanel, UDim2.fromOffset(14, 80), UDim2.new(1, -28, 1, -94))

AdaKurekAc.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end

	temizle(kurekListe)

	kurekBaslik.Text = `{payload.name} Shovel Seller`
	kurekBaslik.TextColor3 = payload.color
	kurekAlt.Text = `Your ores:  {madenYazisi(payload.ores)}`

	local sayac: { [string]: number } = {}
	for _, ore in payload.ores do
		sayac[ore.id] = ore.count
	end

	for i, entry in payload.shovels do
		local row = satir(kurekListe, i, entry.color, entry.equipped or entry.buyable)
		if entry.owned and not entry.equipped then
			row.BackgroundTransparency = 0.4
		end

		UI.text({
			text = `Lv.{entry.level}  {entry.displayName}`,
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = entry.color,
			frameSize = UDim2.new(1, -170, 0, 22),
			position = UDim2.fromOffset(14, 9),
			parent = row,
		})

		-- Bedel satiri: yetiyorsa yesil, sirasi gelmis ama yetmiyorsa sari
		local yeterli = payload.rot >= entry.price
		local parcalar = {}
		for _, ore in payload.ores do
			table.insert(parcalar, `{entry.oreCost} {ore.displayName}`)
			if (sayac[ore.id] or 0) < entry.oreCost then
				yeterli = false
			end
		end

		local bedelRengi = if entry.owned
			then UI.Colors.textDim
			elseif entry.buyable and yeterli then UI.Colors.good
			elseif entry.buyable then UI.Colors.warn
			else UI.Colors.textDim

		UI.text({
			text = if entry.owned then "Owned" else `Needs: {table.concat(parcalar, ", ")}`,
			size = UI.Sizes.small,
			color = bedelRengi,
			frameSize = UDim2.new(1, -170, 0, 20),
			position = UDim2.fromOffset(14, 34),
			parent = row,
		})

		local yazi, renk = durumYazisi(entry, `{Format.short(entry.price)} Rot`)
		UI.text({
			text = yazi,
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = renk,
			align = Enum.TextXAlignment.Right,
			frameSize = UDim2.fromOffset(150, 24),
			position = UDim2.new(1, -164, 0.5, -12),
			parent = row,
		})

		if entry.buyable or (entry.owned and not entry.equipped) then
			row.MouseButton1Click:Connect(function()
				AdaKurekAl:FireServer(entry.id)
			end)
			UI.hover(row)
		end
	end

	kurekPanel.Visible = true
end)

------------------------------------------------------------------
-- KAZMA SATICISI + TAKAS
------------------------------------------------------------------
local kazmaPanel = UI.panel(screen, UDim2.fromOffset(540, 480), "KazmaSaticisi")
local kazmaBaslik, kazmaAlt = panelBasligi(kazmaPanel)
local kazmaListe = liste(kazmaPanel, UDim2.fromOffset(14, 80), UDim2.new(1, -28, 1, -94))

KazmaAc.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end

	temizle(kazmaListe)

	kazmaBaslik.Text = `{payload.name} Pickaxe Seller`
	kazmaBaslik.TextColor3 = payload.color
	kazmaAlt.Text = `Your ores:  {madenYazisi(payload.ores)}`

	local order = 0

	-- KAZMA
	order += 1
	bolumBasligi(kazmaListe, "PICKAXE  --  needed to mine this island's ores", order)

	order += 1
	local kazma = payload.pickaxe
	local kazmaSatiri = satir(kazmaListe, order, payload.color, not kazma.owned)

	UI.text({
		text = kazma.displayName,
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = payload.color,
		frameSize = UDim2.new(1, -170, 0, 22),
		position = UDim2.fromOffset(14, 9),
		parent = kazmaSatiri,
	})

	local madenAdlari = {}
	for _, ore in payload.ores do
		table.insert(madenAdlari, ore.displayName)
	end

	UI.text({
		text = `Mines {table.concat(madenAdlari, ", ")}`,
		size = UI.Sizes.small,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -170, 0, 20),
		position = UDim2.fromOffset(14, 34),
		parent = kazmaSatiri,
	})

	UI.text({
		text = if kazma.owned then "OWNED" else `{Format.short(kazma.price)} Rot`,
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = if kazma.owned then UI.Colors.good else UI.Colors.gold,
		align = Enum.TextXAlignment.Right,
		frameSize = UDim2.fromOffset(150, 24),
		position = UDim2.new(1, -164, 0.5, -12),
		parent = kazmaSatiri,
	})

	if not kazma.owned then
		kazmaSatiri.MouseButton1Click:Connect(function()
			KazmaAl:FireServer(kazma.id)
		end)
		UI.hover(kazmaSatiri)
	end

	-- TAKAS
	order += 1
	bolumBasligi(kazmaListe, `TRADE  --  give {payload.tradeCost} of each other ore, get 1`, order)

	for _, ore in payload.ores do
		order += 1
		local row = satir(kazmaListe, order, ore.color, false)

		UI.text({
			text = `{ore.displayName}  x{ore.count}`,
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = ore.color,
			frameSize = UDim2.new(1, -150, 0, 22),
			position = UDim2.fromOffset(14, 9),
			parent = row,
		})

		local bedel = {}
		local yeterli = true
		for _, diger in payload.ores do
			if diger.id ~= ore.id then
				table.insert(bedel, `{payload.tradeCost} {diger.displayName}`)
				if diger.count < payload.tradeCost then
					yeterli = false
				end
			end
		end

		UI.text({
			text = `Costs {table.concat(bedel, " + ")}`,
			size = UI.Sizes.small,
			color = if yeterli then UI.Colors.textDim else UI.Colors.warn,
			frameSize = UDim2.new(1, -150, 0, 20),
			position = UDim2.fromOffset(14, 34),
			parent = row,
		})

		local dugme = UI.button(row, "GET 1", UDim2.fromOffset(110, 42), if yeterli then UI.Colors.good else UI.Colors.panel)
		dugme.Position = UDim2.new(1, -124, 0.5, -21)
		dugme.MouseButton1Click:Connect(function()
			MadenTakas:FireServer(ore.id)
		end)
	end

	kazmaPanel.Visible = true
end)
