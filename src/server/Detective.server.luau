--[[
	Detective  (Script)
	Yeri: ServerScriptService > Detective

	Brainrot Detective NPC'si.

	Kazidan cikan brainrot envantere SIMSIYAH gelir: oyuncu sadece rarity'sini
	ve kondisyonunu gorur, hangi brainrot oldugunu bilmez. Bu NPC'ye teslim
	edilince inceleme suresi sonunda brainrot'un kimligi ortaya cikar ve
	normal haliyle envantere doner.

	Acilan brainrot artik base slotuna konabilir ve saniyelik gelir uretir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Condition = require(Shared:WaitForChild("Condition"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Fonts = require(Shared:WaitForChild("Fonts"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))

local Bildirim = Net.event("Bildirim")
local DetectiveAc = Net.event("DetectiveAc")
local DetectiveTeslim = Net.event("DetectiveTeslim")
local DetectiveSonuc = Net.event("DetectiveSonuc")

local D = Config.Detective
local rng = Random.new()

-- Su an inceleme surecinde olan oyuncular
local busy: { [Player]: boolean } = {}

------------------------------------------------------------------
-- NPC KURULUMU
------------------------------------------------------------------

-- Workspace'te hazir NPC yoksa basit bir inceleme stanti kurar.
local function buildStand(): Model
	local model = Instance.new("Model")
	model.Name = D.name

	local base = Instance.new("Part")
	base.Name = "Masa"
	base.Size = Vector3.new(8, 4, 4)
	base.Position = D.spawnPosition
	base.Anchored = true
	base.Color = Color3.fromRGB(58, 44, 36)
	base.Material = Enum.Material.WoodPlanks
	base.Parent = model
	model.PrimaryPart = base

	local lamp = Instance.new("Part")
	lamp.Name = "Lamba"
	lamp.Size = Vector3.new(1, 1, 1)
	lamp.Position = D.spawnPosition + Vector3.new(0, 3.5, 0)
	lamp.Anchored = true
	lamp.CanCollide = false
	lamp.Shape = Enum.PartType.Ball
	lamp.Color = Color3.fromRGB(255, 236, 180)
	lamp.Material = Enum.Material.Neon
	lamp.Parent = model

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 236, 180)
	light.Range = 20
	light.Brightness = 2
	light.Parent = lamp

	local sign = Instance.new("BillboardGui")
	sign.Name = "Tabela"
	sign.Size = UDim2.new(0, 200, 0, 44)
	sign.StudsOffset = Vector3.new(0, 4, 0)
	sign.AlwaysOnTop = false
	sign.MaxDistance = 90
	sign.Parent = base

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Fonts.bold
	label.Text = "Brainrot Detective"
	label.TextColor3 = Color3.fromRGB(255, 236, 180)
	label.TextSize = 20
	label.TextScaled = false
	label.TextStrokeTransparency = 1
	label.Parent = sign

	model.Parent = Workspace
	return model
end

local function findNPC(): Model?
	local existing = Workspace:FindFirstChild(D.name, true)
	if existing and existing:IsA("Model") then
		return existing
	end
	return nil
end

local function attachPrompt(model: Model)
	local anchor: BasePart? = model.PrimaryPart
		or model:FindFirstChild("HumanoidRootPart") :: BasePart?
		or model:FindFirstChildWhichIsA("BasePart")

	if not anchor then
		warn("[Detective] NPC'de tutunulacak bir Part bulunamadi")
		return
	end

	local existing = anchor:FindFirstChildOfClass("ProximityPrompt")
	if existing then
		existing:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = D.promptText
	prompt.ObjectText = D.promptSubText
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = D.promptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor

	prompt.Triggered:Connect(function(player)
		local data = PlayerData.get(player)
		if not data then
			return
		end

		-- Sadece henuz acilmamis brainrotlar teslim edilebilir
		local pending = {}
		for _, item in data.inventory do
			if not item.revealed then
				table.insert(pending, {
					uid = item.uid,
					rarity = item.rarity,
					condition = item.condition,
					mutation = item.mutation,
				})
			end
		end

		if #pending == 0 then
			Bildirim:FireClient(player, "You have no unidentified brainrots.", Color3.fromRGB(255, 200, 90))
			return
		end

		DetectiveAc:FireClient(player, pending)
	end)
end

------------------------------------------------------------------
-- INCELEME
------------------------------------------------------------------
DetectiveTeslim.OnServerEvent:Connect(function(player, uid)
	if type(uid) ~= "string" then
		return
	end
	if busy[player] then
		Bildirim:FireClient(player, "The Detective is still busy with the last one.", Color3.fromRGB(255, 200, 90))
		return
	end

	local item = PlayerData.findItem(player, uid)
	if not item or item.revealed then
		return
	end

	local rarityInfo = Rarity.get(item.rarity :: any)

	busy[player] = true
	Bildirim:FireClient(
		player,
		`Detective is working... ({rarityInfo.revealTime}s)`,
		rarityInfo.color
	)

	task.delay(rarityInfo.revealTime, function()
		busy[player] = nil

		-- Oyuncu bu arada ciktiysa veya esya kaybolduysa
		if not player.Parent then
			return
		end
		local current = PlayerData.findItem(player, uid)
		if not current or current.revealed then
			return
		end

		-- Rarity sabit kalir; hangi brainrot oldugu simdi belli olur
		local picked = Brainrots.roll(current.rarity :: any, rng)
		current.name = picked.name
		current.revealed = true

		local income = Brainrots.income(picked.name, current.condition :: any, current.mutation :: any)
		local conditionInfo = Condition.get(current.condition :: any)

		Envanter.syncBrainrots(player)
		Envanter.push(player)
		DetectiveSonuc:FireClient(player, {
			uid = uid,
			name = picked.name,
			rarity = current.rarity,
			condition = current.condition,
			mutation = current.mutation,
			income = income,
		})

		-- Mutasyon da bu anda ortaya cikar: ismi ve rengi ona gore yazilir
		local special = Mutations.isSpecial(current.mutation)
		Bildirim:FireClient(
			player,
			`{picked.name} {conditionInfo.shortName} ({Format.perSecond(income)})`,
			if special then Mutations.color(current.mutation) else rarityInfo.color
		)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	busy[player] = nil
end)

------------------------------------------------------------------
-- BASLAT
------------------------------------------------------------------
task.spawn(function()
	local npc = findNPC()
	if not npc then
		npc = buildStand()
	end
	attachPrompt(npc)
end)
