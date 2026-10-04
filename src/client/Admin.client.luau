local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))
local Shovels = require(Shared:WaitForChild("Shovels"))
local Detectors = require(Shared:WaitForChild("Detectors"))
local Flyboard = require(Shared:WaitForChild("Flyboard"))
local Rods = require(Shared:WaitForChild("Rods"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Ores = require(Shared:WaitForChild("Ores"))
local Passler = require(Shared:WaitForChild("Passler"))
local Hiz = require(Shared:WaitForChild("Hiz"))
local Hava = require(Shared:WaitForChild("Hava"))

local UI = require(script.Parent:WaitForChild("UI"))

local AdminPanelAc = Net.event("AdminPanelAc")
local AdminKomut = Net.event("AdminKomut")

local allowed = false

local screen = Instance.new("ScreenGui")
screen.Name = "AdminPanel"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local panel = UI.panel(screen, UDim2.fromOffset(560, 520), "Panel")

UI.text({
	text = "Admin Panel",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = UI.Colors.gold,
	frameSize = UDim2.new(1, -80, 0, 36),
	position = UDim2.fromOffset(18, 14),
	parent = panel,
})

local subtitle = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 48),
	parent = panel,
})

UI.closeButton(panel).MouseButton1Click:Connect(function()
	panel.Visible = false
end)

local list = Instance.new("ScrollingFrame")
list.Name = "Liste"
list.Position = UDim2.fromOffset(14, 78)
list.Size = UDim2.new(1, -28, 1, -92)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.ScrollBarImageColor3 = UI.Colors.panelLight
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
UI.listePayi(list)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local order = 0

local function section(title: string)
	order += 1

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -6, 0, 24)
	holder.BackgroundTransparency = 1
	holder.LayoutOrder = order
	holder.Parent = list

	UI.text({
		text = title,
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		frameSize = UDim2.fromScale(1, 1),
		parent = holder,
	})
end

local function actionButton(label: string, command: string, arg: any?, color: Color3?)
	order += 1

	local button = UI.button(list, label, UDim2.new(1, -6, 0, 40), color)
	button.LayoutOrder = order

	button.MouseButton1Click:Connect(function()
		AdminKomut:FireServer(command, arg)
	end)
end

type ChipEntry = {
	label: string,
	command: string?,
	arg: any,
	getArg: (() -> any)?,
	onClick: ((index: number) -> ())?,
	color: Color3?,
}

local function chipRow(entries: { ChipEntry }): { TextButton }
	order += 1

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, 36)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = list

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.Padding = UDim.new(0, 6)
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Parent = row

	local width = 1 / #entries
	local chips: { TextButton } = {}

	for index, entry in entries do
		local chip = Instance.new("TextButton")
		chip.Size = UDim2.new(width, -6, 1, 0)
		chip.BackgroundColor3 = UI.Colors.panelLight
		chip.BorderSizePixel = 0
		chip.AutoButtonColor = true
		chip.Text = ""
		chip.LayoutOrder = index
		chip.Parent = row
		UI.corner(chip, 8)
		UI.stroke(chip, entry.color or UI.Colors.accent, 1)

		UI.text({
			text = entry.label,
			size = UI.Sizes.tiny,
			font = UI.Fonts.bold,
			color = entry.color or UI.Colors.text,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.fromScale(1, 1),
			parent = chip,
		})

		table.insert(chips, chip)

		chip.MouseButton1Click:Connect(function()
			if entry.onClick then
				entry.onClick(index)
				return
			end
			AdminKomut:FireServer(entry.command, if entry.getArg then entry.getArg() else entry.arg)
		end)
	end

	return chips
end

local built = false

local function buildPanel(info: any)
	if built then
		return
	end
	built = true

	subtitle.Text = `{Config.Admin.keyCode.Name} to open/close  --  all commands are validated on the server`

	section("QUICK")
	actionButton("Give all tools (max level)", "giveAllTools", nil, UI.Colors.good)
	actionButton(`Give Rot  (+{Format.short(info.rotGrant or 0)})`, "giveRot", nil, UI.Colors.gold)
	for _, miktar in { 10, 100, 1000 } do
		actionButton(`Give Rot Coin  (+{miktar})`, "giveRotCoins", miktar, Color3.fromRGB(120, 226, 150))
	end
	actionButton(
		`Start block rain  ({LuckyBlock.toplamBlok()} blocks)`,
		"luckyEvent",
		nil,
		UI.Colors.warn
	)

	section("EVENTS  --  Mystery Beam and weather")
	actionButton("Drop a Mystery Beam now", "gizemIsini", nil, Color3.fromRGB(255, 210, 70))
	for _, tur in Hava.Turler do
		actionButton(`Start {tur.ad}  ({tur.sans}% {tur.mutasyon})`, "havaBaslat", tur.id, tur.renk)
	end
	actionButton("Stop weather", "havaDurdur", nil, UI.Colors.bad)

	section("BADGES  --  test the titles")
	actionButton("Give all badges", "tumRozetler", nil, Color3.fromRGB(255, 200, 40))
	actionButton("Reset badges", "rozetSifirla", nil, UI.Colors.bad)

	section("WEEKEND  --  2x luck, tower effects, 48h timer")
	actionButton("Start weekend (48h test)", "haftaSonuBaslat", nil, Color3.fromRGB(80, 160, 255))
	actionButton("Stop weekend test", "haftaSonuDurdur", nil, UI.Colors.bad)

	for _, tier in LuckyBlock.Tiers do
		actionButton(`Give {tier.displayName}  (+1)`, "giveLuckyBlock", tier.id, tier.color)
	end
	actionButton("Reveal all pets in inventory", "revealAll", nil, UI.Colors.accent)
	actionButton("Fill index (all pets + mutations)", "indexDoldur", nil, Color3.fromRGB(120, 220, 140))
	actionButton("Restart tutorial (step 1)", "ogreticiSifirla", nil, Color3.fromRGB(255, 215, 60))
	actionButton("Tutorial: skip to next step", "ogreticiAtla", nil, Color3.fromRGB(255, 190, 90))
	actionButton("Finish tutorial", "ogreticiBitir", nil, Color3.fromRGB(200, 170, 110))
	actionButton("Reset island hint (650M > Candy)", "adaIpucuSifirla", nil, Color3.fromRGB(255, 120, 120))
	actionButton("Test mutation rolls (1000x, prints to Output)", "testMutation", nil, UI.Colors.textDim)
	actionButton("Map report (island/base/NPC positions, prints to Output)", "haritaRaporu", nil, UI.Colors.textDim)
	actionButton("Sand report (ground under you, prints to Output)", "kumRaporu", nil, UI.Colors.textDim)
	actionButton("VFX report (beam effect contents)", "vfxRaporu", nil, UI.Colors.textDim)
	actionButton("Hidden pet report (HiddenPart model)", "gizliRaporu", nil, UI.Colors.textDim)
	actionButton("Foreign script report (scripts in the map, prints to Output)", "scriptRaporu", nil, UI.Colors.warn)

	section("PLAYER LEVEL  --  level up (with rewards) or set directly")
	local LEVEL_RENGI = Color3.fromRGB(255, 215, 40)
	chipRow({
		{ label = "+1 Level", command = "levelAtla", arg = 1, color = LEVEL_RENGI },
		{ label = "+5 Levels", command = "levelAtla", arg = 5, color = LEVEL_RENGI },
		{ label = "+10 Levels", command = "levelAtla", arg = 10, color = LEVEL_RENGI },
	})
	chipRow({
		{ label = "Lv 15 (trade)", command = "levelAyarla", arg = 15, color = Color3.fromRGB(40, 200, 220) },
		{ label = "Lv 30", command = "levelAyarla", arg = 30, color = Color3.fromRGB(190, 110, 255) },
		{ label = "Max", command = "levelAyarla", arg = 1000, color = Color3.fromRGB(255, 120, 60) },
		{ label = "Reset (Lv 1)", command = "levelAyarla", arg = 1, color = UI.Colors.bad },
	})

	section("SHOVEL LEVEL  --  Main / Candy / Snow / Volcano")
	for _, ada in { "main", "sekerkum", "snowkum", "alevkum" } do
		local shovelChips = {}
		for _, shovel in Shovels.forIsland(if ada == "main" then nil else ada) do
			table.insert(shovelChips, {
				label = `Lv{shovel.level}`,
				command = "setShovel",
				arg = shovel.id,
				color = if shovel.island then shovel.color else Rarity.color(shovel.rarity),
			})
		end
		if #shovelChips > 0 then
			chipRow(shovelChips)
		end
	end

	section("SPEED  --  upgrades bought (Speed = count + 1)")
	local hizChips = {}
	for _, adet in { 0, 10, 25, 50, 75, 99, 100 } do
		table.insert(hizChips, {
			label = tostring(adet),
			command = "setSpeed",
			arg = adet,
			color = Hiz.renk(adet + 1),
		})
	end
	chipRow(hizChips)

	section("SPEED REBIRTH  --  trail color and size")
	local rebirthChips = {}
	for adet = 0, Hiz.MaxRebirth do
		table.insert(rebirthChips, {
			label = `R{adet}`,
			command = "setRebirth",
			arg = adet,
			color = Hiz.rebirthRengi(adet) or UI.Colors.textDim,
		})
	end
	chipRow(rebirthChips)

	section("ROBUX PASSES  --  give / take for this session")
	local passChips = {}
	for ad, pass in Passler.Info do
		table.insert(passChips, {
			label = pass.ad,
			command = "togglePass",
			arg = ad,
			color = UI.Colors.gold,
		})
	end
	chipRow(passChips)

	section("DETECTOR LEVEL")
	local detectorChips = {}
	for _, id in Detectors.Order do
		local detector = Detectors.get(id)
		table.insert(detectorChips, {
			label = `Lv{detector.level}`,
			command = "setDetector",
			arg = id,
			color = Rarity.color(detector.rarity),
		})
	end
	chipRow(detectorChips)

	section("FLYBOARD TIER")
	local flyboardChips = {}
	for _, id in Flyboard.Order do
		local board = Flyboard.Info[id]
		table.insert(flyboardChips, {
			label = `Lv{board.level}`,
			command = "setFlyboard",
			arg = id,
			color = board.color,
		})
	end
	chipRow(flyboardChips)

	section("ROD TIER")
	local rodChips = {}
	for _, id in Rods.Order do
		local rod = Rods.Info[id]
		table.insert(rodChips, {
			label = `Lv{rod.level}`,
			command = "setRod",
			arg = id,
			color = rod.color,
		})
	end
	chipRow(rodChips)

	section("GIVE PICKAXE")
	local pickaxeChips: { any } = {}
	for _, ada in Ores.IslandOrder do
		local kazma = Ores.Pickaxes[Ores.Islands[ada].pickaxe]
		table.insert(pickaxeChips, {
			label = string.gsub(kazma.displayName, " Pickaxe", ""),
			command = "givePickaxe",
			arg = kazma.id,
			color = kazma.color,
		})
	end
	table.insert(pickaxeChips, {
		label = "All",
		command = "givePickaxe",
		arg = "all",
		color = UI.Colors.good,
	})
	chipRow(pickaxeChips)

	section("GIVE ORES  (+10)")
	for _, ada in Ores.IslandOrder do
		local cfg = Ores.Islands[ada]
		local oreChips: { any } = {
			{
				label = `{string.gsub(cfg.name, " Island", "")} x3`,
				command = "giveOres",
				arg = ada,
				color = cfg.color,
			},
		}
		for _, id in cfg.ores do
			table.insert(oreChips, {
				label = id,
				command = "giveOres",
				arg = id,
				color = cfg.color,
			})
		end
		chipRow(oreChips)
	end

	section("SPAWN ORE  --  mine it with a pickaxe")
	for _, ada in Ores.IslandOrder do
		local cfg = Ores.Islands[ada]
		local spawnChips: { any } = {}
		for _, id in cfg.ores do
			table.insert(spawnChips, {
				label = id,
				command = "spawnBeam",
				arg = id,
				color = cfg.color,
			})
		end
		chipRow(spawnChips)
	end

	section("MUTATION  --  converts the HELD pet")

	local mutationChips: { TextButton }
	local mutationEntries: { any } = {}

	for _, id in Mutations.Order do
		local info = Mutations.get(id)
		table.insert(mutationEntries, {
			label = string.sub(info.displayName, 1, 4),
			color = info.color,
			onClick = function(index: number)
				AdminKomut:FireServer("setMutation", id)

				local chip = mutationChips[index]
				local stroke = chip and chip:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Thickness = 3
					task.delay(0.35, function()
						if stroke.Parent then
							stroke.Thickness = 1
						end
					end)
				end
			end,
		})
	end

	mutationChips = chipRow(mutationEntries)

	section("SPAWN BEAM  --  test digging and difficulty")

	local beamChips: { any } = {}
	for _, id in Rarity.Order do
		table.insert(beamChips, {
			label = string.sub(Rarity.get(id).displayName, 1, 4),
			command = "spawnBeam",
			arg = id,
			color = Rarity.color(id),
		})
	end
	chipRow(beamChips)

	chipRow({
		{
			label = "Lucky",
			command = "spawnBeam",
			arg = "LuckyBlock",
			color = Rarity.LuckyBlock.colorA,
		},
	})

	section("SPAWN WHIRLPOOL  --  the sea version")

	local girdapChips: { any } = {}
	for _, id in Rarity.Order do
		table.insert(girdapChips, {
			label = string.sub(Rarity.get(id).displayName, 1, 4),
			command = "spawnGirdap",
			arg = id,
			color = Rarity.color(id),
		})
	end
	chipRow(girdapChips)

	section("GIVE PET  --  random mutation")
	local rarityChips: { any } = {}
	for _, id in Rarity.Order do
		table.insert(rarityChips, {
			label = string.sub(Rarity.get(id).displayName, 1, 4),
			command = "giveBrainrot",
			arg = id,
			color = Rarity.color(id),
		})
	end
	chipRow(rarityChips)

	section("GIVE UNIDENTIFIED PET  --  reveal it at the Detective")
	local gizliChips: { any } = {}
	for _, id in Rarity.Order do
		table.insert(gizliChips, {
			label = string.sub(Rarity.get(id).displayName, 1, 4),
			command = "giveGizliBrainrot",
			arg = id,
			color = Rarity.color(id),
		})
	end
	chipRow(gizliChips)

	section("DANGEROUS")
	actionButton("Clear inventory", "clearInventory", nil, UI.Colors.bad)
end

AdminPanelAc.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" or not info.allowed then
		allowed = false
		panel.Visible = false
		return
	end

	allowed = true
	buildPanel(info)
end)

ContextActionService:BindAction("AdminPanelAc", function(_, state)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	if not allowed then
		return Enum.ContextActionResult.Pass
	end

	panel.Visible = not panel.Visible
	return Enum.ContextActionResult.Sink
end, false, Config.Admin.keyCode)
