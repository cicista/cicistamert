local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OyunConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AdaMenusuAc = Remotes:WaitForChild("AdaMenusuAc")
local AdayaGit = Remotes:WaitForChild("AdayaGit")
local Bildirim = Remotes:WaitForChild("Bildirim")
local PlayerData = require(script.Parent:WaitForChild("Modules"):WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Modules"):WaitForChild("Envanter"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Passler = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Passler"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local IsinlayiciGit = Net.event("IsinlayiciGit")

local COOLDOWN = 3
local lastUse = {}
local MENU_PAYI = 20
local acilanNpc: { [Player]: BasePart } = {}

local function findNPC()
	local direct = Workspace:FindFirstChild(Config.NPC.name)
	if direct and direct:IsA("Model") then
		return direct
	end
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and obj.Name == Config.NPC.name then
			return obj
		end
	end
	return nil
end

local function getIslandCFrame(island)
	if island.spawnPartName then
		local part = Workspace:FindFirstChild(island.spawnPartName, true)
		if part and part:IsA("BasePart") then
			return part.CFrame + Vector3.new(0, part.Size.Y / 2 + 4, 0)
		end
	end
	return CFrame.new(island.position)
end

local function buildIslandList(player: Player, fromIndex: number?)
	local data = PlayerData.get(player)
	local unlocked = if data then data.islands else 1
	local home = fromIndex or 1

	local list = {}

	if home ~= 1 then
		local first = Config.Islands[1]
		table.insert(list, {
			index = 1,
			name = `Back to {first.name}`,
			desc = "Free ride back to the starter island.",
			price = 0,
			color = Color3.fromRGB(120, 230, 150),
			state = "home",
		})
	end

	for i, island in ipairs(Config.Islands) do
		if not (home ~= 1 and i == 1) then
			if island.comingSoon then
				table.insert(list, {
					index = i,
					name = "Coming Soon",
					desc = island.desc,
					price = 0,
					color = Color3.fromRGB(120, 126, 138),
					state = "locked",
				})
			elseif i <= unlocked then
				table.insert(list, {
					index = i,
					name = island.name,
					desc = island.desc,
					price = 0,
					color = island.color,
					state = "owned",
				})
			elseif i == unlocked + 1 then
				table.insert(list, {
					index = i,
					name = island.name,
					desc = island.desc,
					price = island.price,
					color = island.color,
					state = "buyable",
				})
			else
				table.insert(list, {
					index = i,
					name = "???",
					desc = "Hidden until you unlock the previous island.",
					price = 0,
					color = Color3.fromRGB(120, 126, 138),
					state = "locked",
				})
			end
		end
	end

	return list
end

local npcAdlari: { [string]: boolean } = { [Config.NPC.name] = true }
for _, ad in Config.NPC.altNames or { Config.NPC.altName } do
	npcAdlari[ad] = true
end

local function npcMi(obj: Instance): boolean
	return obj:IsA("Model") and npcAdlari[obj.Name] == true
end

local function findNPCs(): { Model }
	local found: { Model } = {}

	for _, obj in Workspace:GetDescendants() do
		if npcMi(obj) then
			table.insert(found, obj :: Model)
		end
	end

	return found
end

local function islandPosition(island): Vector3
	if island.spawnPartName then
		local part = Workspace:FindFirstChild(island.spawnPartName, true)
		if part and part:IsA("BasePart") then
			return part.Position
		end
	end
	return island.position
end

local function nearestIslandIndex(position: Vector3): number
	local best, bestDistance = 1, math.huge

	for index, island in ipairs(Config.Islands) do
		local distance = if island.comingSoon then math.huge else (islandPosition(island) - position).Magnitude
		if distance < bestDistance then
			bestDistance = distance
			best = index
		end
	end

	return best
end

local function setupNPC(npc: Model)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	end

	local root = npc:FindFirstChild("HumanoidRootPart")
		or npc.PrimaryPart
		or npc:FindFirstChildWhichIsA("BasePart")
	if not root or not root:IsA("BasePart") then
		warn(`[AdaTeleport] {npc:GetFullName()}: no Part, skipped`)
		return
	end
	root.Anchored = true

	local homeIndex = nearestIslandIndex(root.Position)

	local old = root:FindFirstChild("AdaPrompt")
	if old then
		old:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "AdaPrompt"
	prompt.ActionText = Config.NPC.promptText
	prompt.ObjectText = Config.NPC.promptSubText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.NPC.promptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	prompt.Triggered:Connect(function(player)
		acilanNpc[player] = root
		AdaMenusuAc:FireClient(player, buildIslandList(player, homeIndex))
	end)

	print(`[AdaTeleport] Teleporter ready: {npc:GetFullName()} (island {homeIndex})`)
end

local kurulan: { [Model]: boolean } = {}

local function kur(npc: Model)
	if kurulan[npc] then
		return
	end
	kurulan[npc] = true
	npc.Destroying:Connect(function()
		kurulan[npc] = nil
	end)
	setupNPC(npc)
end

local function setupAllNPCs()
	local npcs = findNPCs()

	if #npcs == 0 then
		warn(
			`[AdaTeleport] NPC named '{Config.NPC.name}' not found. `
				.. `Rename the NPC model to '{Config.NPC.name}'.`
		)
	end

	for _, npc in npcs do
		kur(npc)
	end

	Workspace.DescendantAdded:Connect(function(obj)
		if npcMi(obj) then
			task.delay(1, function()
				if obj.Parent then
					kur(obj :: Model)
				end
			end)
		end
	end)
end

task.defer(setupAllNPCs)

AdayaGit.OnServerEvent:Connect(function(player, index)
	if typeof(index) ~= "number" then return end

	local island = Config.Islands[index]
	if not island or island.comingSoon then return end

	local now = os.clock()
	if lastUse[player] and now - lastUse[player] < COOLDOWN then
		return
	end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return end

	local npcParca = acilanNpc[player]
	if not npcParca or not npcParca.Parent then
		return
	end
	if (npcParca.Position - root.Position).Magnitude > Config.NPC.promptDistance + MENU_PAYI then
		Bildirim:FireClient(player, "Get closer to the Teleporter.", Color3.fromRGB(255, 200, 90))
		return
	end

	if char:GetAttribute("Kaziyor") == true or player:GetAttribute("Flyboarding") == true then
		Bildirim:FireClient(player, "Finish what you are doing first!", Color3.fromRGB(255, 200, 90))
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	if index > data.islands + 1 then
		Bildirim:FireClient(player, "Unlock the previous island first.", Color3.fromRGB(255, 200, 90))
		return
	end

	if index > data.islands then
		if data.rot < island.price then
			Bildirim:FireClient(
				player,
				`Not enough Rot! You need {Format.short(island.price - data.rot)} more Rot for {island.name}.`,
				Color3.fromRGB(255, 90, 90)
			)
			return
		end

		PlayerData.addRot(player, -island.price)
		data.islands = index
		Envanter.push(player)
		Bildirim:FireClient(player, `{island.name} unlocked!`, island.color or Color3.fromRGB(120, 220, 255))
	end

	lastUse[player] = now

	local target = getIslandCFrame(island)
	char:PivotTo(target)
	root.AssemblyLinearVelocity = Vector3.zero

	Bildirim:FireClient(player, "Welcome to " .. island.name .. "!", island.color or Color3.fromRGB(120, 220, 255))
end)

IsinlayiciGit.OnServerEvent:Connect(function(player, index)
	if typeof(index) ~= "number" then
		return
	end

	if not Passler.sahip(player, "Teleporter") then
		Bildirim:FireClient(player, "You need the Teleporter pass!", Color3.fromRGB(255, 200, 90))
		return
	end

	local island = Config.Islands[index]
	local data = PlayerData.get(player)
	if not island or island.comingSoon or not data then
		return
	end

	if index > data.islands then
		Bildirim:FireClient(player, `Unlock {island.name} at a Teleporter first!`, Color3.fromRGB(255, 200, 90))
		return
	end

	local now = os.clock()
	if lastUse[player] and now - lastUse[player] < COOLDOWN then
		return
	end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	if char:GetAttribute("Kaziyor") == true then
		Bildirim:FireClient(player, "Finish digging first!", Color3.fromRGB(255, 200, 90))
		return
	end
	if player:GetAttribute("Flyboarding") == true then
		Bildirim:FireClient(player, "Get off your flyboard first!", Color3.fromRGB(255, 200, 90))
		return
	end

	lastUse[player] = now
	char:PivotTo(getIslandCFrame(island))
	root.AssemblyLinearVelocity = Vector3.zero

	Bildirim:FireClient(player, "Welcome to " .. island.name .. "!", island.color or Color3.fromRGB(120, 220, 255))
end)

Players.PlayerRemoving:Connect(function(player)
	lastUse[player] = nil
	acilanNpc[player] = nil
end)
