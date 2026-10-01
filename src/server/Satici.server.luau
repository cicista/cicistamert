local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Fonts = require(Shared:WaitForChild("Fonts"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Format = require(Shared:WaitForChild("Format"))
local Bases = require(Shared:WaitForChild("Bases"))
local Net = require(Shared:WaitForChild("Net"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Tools = require(Modules:WaitForChild("Tools"))
local Envanter = require(Modules:WaitForChild("Envanter"))
local GorevTakip = require(Modules:WaitForChild("GorevTakip"))

local Bildirim = Net.event("Bildirim")
local SaticiDurum = Net.event("SaticiDurum")
local BrainrotSat = Net.event("BrainrotSat")
local TumunuSat = Net.event("TumunuSat")

local S = Config.Seller

local function valueOf(item: any): number
	if item.revealed and item.name then
		return math.floor(Brainrots.income(item.name, item.condition, item.mutation) * S.valueMultiplier)
	end

	return math.floor(Brainrots.minIncome(item.rarity, item.condition) * S.unknownMultiplier)
end

local function sellableItems(player: Player): ({ any }, number)
	local data = PlayerData.get(player)
	if not data then
		return {}, 0
	end

	local list = {}
	local total = 0
	for _, item in data.inventory do
		if not item.slot then
			table.insert(list, item)
			total += valueOf(item)
		end
	end

	return list, total
end

local function buildStand(): Model
	local model = Instance.new("Model")
	model.Name = S.name

	local counter = Instance.new("Part")
	counter.Name = "Tezgah"
	counter.Size = Vector3.new(9, 4, 4)
	counter.Position = S.spawnPosition
	counter.Anchored = true
	counter.Color = Color3.fromRGB(48, 62, 44)
	counter.Material = Enum.Material.WoodPlanks
	counter.Parent = model
	model.PrimaryPart = counter

	local sign = Instance.new("Part")
	sign.Name = "Levha"
	sign.Size = Vector3.new(7, 2.4, 0.4)
	sign.Position = S.spawnPosition + Vector3.new(0, 4, 0)
	sign.Anchored = true
	sign.CanCollide = false
	sign.Color = Color3.fromRGB(120, 200, 130)
	sign.Material = Enum.Material.Neon
	sign.Parent = model

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(120, 200, 130)
	light.Range = 18
	light.Brightness = 2
	light.Parent = sign

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Tabela"
	billboard.Size = UDim2.fromOffset(220, 44)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 120
	billboard.Parent = counter

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Fonts.bold
	label.Text = S.promptSubText
	label.TextColor3 = Color3.fromRGB(150, 230, 160)
	label.TextSize = 20
	label.TextScaled = false
	label.TextStrokeTransparency = 1
	label.Parent = billboard

	model.Parent = Workspace
	return model
end

local function findNPC(): Model?
	for _, name in { S.altName, S.name } do
		local existing = if name then Workspace:FindFirstChild(name, true) else nil
		if existing and existing:IsA("Model") then
			return existing
		end
	end
	return nil
end

local npc: Model? = findNPC() or buildStand()

local function npcPosition(): Vector3?
	if not npc or not npc.Parent then
		return nil
	end

	local anchor = npc.PrimaryPart
		or npc:FindFirstChild("HumanoidRootPart")
		or npc:FindFirstChildWhichIsA("BasePart")

	return if anchor and anchor:IsA("BasePart") then anchor.Position else nil
end

local pushStatus: (player: Player, open: boolean?) -> ()

local function sellItem(player: Player, uid: string): boolean
	local item = PlayerData.findItem(player, uid)
	if not item then
		return false
	end

	if item.slot then
		Bildirim:FireClient(player, "A pet on your base cannot be sold.", Color3.fromRGB(255, 200, 90))
		return false
	end

	local value = valueOf(item)
	PlayerData.removeItem(player, uid)
	PlayerData.addRot(player, value)

	Envanter.syncBrainrots(player)
	Envanter.push(player)

	GorevTakip.ilerlet(player, "sell", 1)

	local label = if item.revealed and item.name
		then item.name
		else `Unidentified {Rarity.displayName(item.rarity)}`
	Bildirim:FireClient(player, `Sold {label} (+{Format.short(value)} Rot)`, Rarity.color(item.rarity))
	return true
end

local function inRange(player: Player): boolean
	local position = npcPosition()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if not position or not root or not root:IsA("BasePart") then
		return false
	end

	return (root.Position - position).Magnitude <= S.range
end

BrainrotSat.OnServerEvent:Connect(function(player, uid)
	if not inRange(player) then
		return
	end

	local hedef: string? = if type(uid) == "string" then uid else nil

	if not hedef then
		local _, heldUid = Tools.equippedBrainrot(player)
		hedef = heldUid
	end

	if not hedef then
		Bildirim:FireClient(player, "Pick a pet from the list to sell it.", Color3.fromRGB(255, 200, 90))
		return
	end

	if sellItem(player, hedef) then
		pushStatus(player)
	end
end)

TumunuSat.OnServerEvent:Connect(function(player)
	if not inRange(player) then
		return
	end

	local items, total = sellableItems(player)
	if #items == 0 then
		Bildirim:FireClient(player, "Nothing to sell.", Color3.fromRGB(255, 200, 90))
		return
	end

	local count = #items
	for _, item in items do
		PlayerData.removeItem(player, item.uid)
	end
	PlayerData.addRot(player, total)

	Envanter.syncBrainrots(player)
	Envanter.push(player)

	GorevTakip.ilerlet(player, "sell", count)

	pushStatus(player)

	Bildirim:FireClient(
		player,
		`Sold {count} pets (+{Format.short(total)} Rot)`,
		Bases.RotColor
	)
end)
local panelOpen: { [Player]: boolean } = {}

local function liste(player: Player): { any }
	local items = select(1, sellableItems(player))
	local out = {}

	for _, item in items do
		table.insert(out, {
			uid = item.uid,
			rarity = item.rarity,
			name = if item.revealed and item.name then item.name else nil,
			condition = item.condition,
			mutation = item.mutation,
			value = valueOf(item),
		})
	end

	return out
end

function pushStatus(player: Player, open: boolean?)
	local items, total = sellableItems(player)

	SaticiDurum:FireClient(player, {
		near = true,
		open = open == true,
		totalCount = #items,
		totalValue = total,
		multiplier = S.valueMultiplier,
		items = liste(player),
	})
end

local function closePanel(player: Player)
	if not panelOpen[player] then
		return
	end
	panelOpen[player] = nil
	SaticiDurum:FireClient(player, { near = false })
end

local function attachPrompt()
	if not npc then
		return
	end

	local anchor = npc.PrimaryPart
		or npc:FindFirstChild("HumanoidRootPart")
		or npc:FindFirstChildWhichIsA("BasePart")

	if not anchor or not anchor:IsA("BasePart") then
		warn("[Satici] No Part found on the NPC to attach to")
		return
	end

	local existing = anchor:FindFirstChild("SaticiPrompt")
	if existing then
		existing:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SaticiPrompt"
	prompt.ActionText = "Sell"
	prompt.ObjectText = S.promptSubText
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = S.range
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = anchor

	prompt.Triggered:Connect(function(player)
		panelOpen[player] = true
		pushStatus(player, true)
	end)
end

task.spawn(attachPrompt)

task.spawn(function()
	while true do
		task.wait(0.4)

		for player in panelOpen do
			if not player.Parent then
				panelOpen[player] = nil
				continue
			end

			if not inRange(player) then
				closePanel(player)
			else
				pushStatus(player)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	panelOpen[player] = nil
end)
