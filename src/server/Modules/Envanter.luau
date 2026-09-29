--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))

local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Tools = require(script.Parent:WaitForChild("Tools"))
local Scrolls = require(Shared:WaitForChild("Scrolls"))
local Assets = require(Shared:WaitForChild("Assets"))
local Canta = require(Shared:WaitForChild("Canta"))
local Format = require(Shared:WaitForChild("Format"))
local Olta = require(script.Parent:WaitForChild("Olta"))

local EnvanterGuncelle = Net.event("EnvanterGuncelle")

local Envanter = {}

function Envanter.push(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	for _, item in data.inventory do
		if item.revealed and item.name then
			PlayerData.discover(player, item.name)
			if item.mutation then
				PlayerData.discoverMutation(player, item.name, item.mutation)
			end
		end
	end

	EnvanterGuncelle:FireClient(player, {
		rot = data.rot,
		rotCoins = data.rotCoins,
		luckyBlocks = data.luckyBlocks,
		scrolls = data.scrolls,
		shovel = data.shovel,
		detector = data.detector,
		inventory = data.inventory,
		ores = data.ores,
		pickaxes = data.pickaxes,
		baseSlots = data.baseSlots,
		inventoryMax = PlayerData.cantaKapasitesi(player),
		inventoryUpgrade = Canta.fiyat(PlayerData.cantaKapasitesi(player)),
		islands = data.islands,
	})
end

local function held(player: Player, toolName: string): Tool?
	return Tools.equipped(player, toolName)
end

local function clearHands(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:UnequipTools()
	end
end

function Envanter.unequip(player: Player, toolName: string)
	Tools.remove(player, toolName)
end

function Envanter.unequipTools(player: Player)
	Tools.remove(player, Tools.ShovelName)
	Tools.remove(player, Tools.GPSName)
	Tools.remove(player, Tools.PickaxeName)
end

function Envanter.equipShovel(player: Player)
	local data = PlayerData.get(player)
	local character = player.Character
	if not data or not character then
		return
	end

	if held(player, Tools.ShovelName) then
		return
	end

	clearHands(player)
	Tools.remove(player, Tools.GPSName)
	Tools.remove(player, Tools.ShovelName)
	Tools.remove(player, Tools.PickaxeName)
	Tools.buildShovel(data.shovel).Parent = character
end

function Envanter.equipPickaxe(player: Player, pickaxeId: string)
	local character = player.Character
	if not character then
		return
	end

	local eldeki = held(player, Tools.PickaxeName)
	if eldeki and eldeki:GetAttribute("PickaxeId") == pickaxeId then
		return
	end

	clearHands(player)
	Tools.remove(player, Tools.GPSName)
	Tools.remove(player, Tools.ShovelName)
	Tools.remove(player, Tools.PickaxeName)
	Tools.buildPickaxe(pickaxeId).Parent = character
end

function Envanter.equipGPS(player: Player)
	local data = PlayerData.get(player)
	local character = player.Character
	if not data or not character then
		return
	end

	if held(player, Tools.GPSName) then
		return
	end

	clearHands(player)
	Tools.remove(player, Tools.ShovelName)
	Tools.remove(player, Tools.GPSName)
	Tools.remove(player, Tools.PickaxeName)
	Tools.buildGPS(data.detector).Parent = character
end

function Envanter.equipRod(player: Player)
	local data = PlayerData.get(player)
	local character = player.Character
	if not data or not character or not data.rod then
		return
	end

	if Olta.has(player) then
		return
	end

	clearHands(player)
	Tools.remove(player, Tools.ShovelName)
	Tools.remove(player, Tools.GPSName)
	Tools.remove(player, Tools.PickaxeName)

	local model = Olta.build(data.rod)
	if not Olta.attach(character, model) then
		model:Destroy()
	end
end

function Envanter.removeRod(player: Player)
	Olta.remove(player.Character)
end

function Envanter.hasRod(player: Player): boolean
	return Olta.izVar(player)
end

function Envanter.giveShovel(player: Player)
	if not held(player, Tools.ShovelName) then
		return
	end

	Tools.remove(player, Tools.ShovelName)
	Envanter.equipShovel(player)
end

function Envanter.giveGPS(player: Player)
	if not held(player, Tools.GPSName) then
		return
	end

	Tools.remove(player, Tools.GPSName)
	Envanter.equipGPS(player)
end

function Envanter.syncLuckyBlocks(player: Player)
	local data = PlayerData.get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then
		return
	end

	local existing: { [string]: Tool } = {}

	for _, place in { backpack :: Instance, player.Character } do
		if place then
			for _, item in place:GetChildren() do
				if item:IsA("Tool") and item:GetAttribute("LuckyBlock") then
					local tierId = item:GetAttribute("LuckyTier")
					if type(tierId) ~= "string" or existing[tierId] then
						item:Destroy()
					else
						existing[tierId] = item
					end
				end
			end
		end
	end

	for _, tier in LuckyBlock.Tiers do
		local count = data.luckyBlocks[tier.id] or 0
		local tool = existing[tier.id]

		if count <= 0 then
			if tool then
				tool:Destroy()
			end
			continue
		end

		if tool then
			tool.Name = Tools.luckyBlockLabel(tier.id, count)
			tool:SetAttribute(Assets.CountAttribute, count)
		else
			Tools.buildLuckyBlock(tier.id, count).Parent = backpack
		end
	end
end

function Envanter.syncScrolls(player: Player)
	local data = PlayerData.get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then
		return
	end

	local mevcut: { [string]: Tool } = {}
	for _, yer in { backpack :: Instance, player.Character } do
		if yer then
			for _, item in yer:GetChildren() do
				if item:IsA("Tool") then
					local id = item:GetAttribute(Scrolls.Nitelik)
					if type(id) == "string" then
						if mevcut[id] then
							item:Destroy()
						else
							mevcut[id] = item
						end
					end
				end
			end
		end
	end

	for _, id in Scrolls.Order do
		local adet = data.scrolls[id] or 0
		local tool = mevcut[id]

		if adet <= 0 then
			if tool then
				tool:Destroy()
			end
			continue
		end

		if tool then
			tool.Name = Scrolls.etiket(id, adet)
			tool:SetAttribute(Assets.CountAttribute, adet)
		else
			local yeni = Tools.buildScroll(id, adet)
			if yeni then
				yeni.Parent = backpack
			end
		end
	end
end

local PARK_ADI = "CantaSirasi"
local siralaniyor: { [Player]: boolean } = {}

local function parkKlasoru(player: Player): Folder
	local var = player:FindFirstChild(PARK_ADI)
	if var and var:IsA("Folder") then
		return var
	end
	local yeni = Instance.new("Folder")
	yeni.Name = PARK_ADI
	yeni.Parent = player
	return yeni
end

local function reorderBackpack(player: Player, backpack: Instance)
	if siralaniyor[player] then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local acik: { [string]: boolean } = {}
	local worth: { [string]: number } = {}
	for _, entry in data.inventory do
		if entry.revealed and entry.name then
			acik[entry.uid] = true
			worth[entry.uid] = Brainrots.income(entry.name, entry.condition, entry.mutation)
		else
			worth[entry.uid] = Brainrots.minIncome(entry.rarity, entry.condition)
		end
	end

	local mevcut: { Tool } = {}
	for _, tool in backpack:GetChildren() do
		if tool:IsA("Tool") and (tool:GetAttribute("BrainrotUid") or tool:GetAttribute(Scrolls.Nitelik)) then
			table.insert(mevcut, tool)
		end
	end
	if #mevcut < 2 then
		return
	end

	local function scrollMu(tool: Tool): boolean
		return type(tool:GetAttribute(Scrolls.Nitelik)) == "string"
	end

	local istenen = table.clone(mevcut)
	table.sort(istenen, function(a, b)
		if scrollMu(a) ~= scrollMu(b) then
			return scrollMu(a)
		end
		if scrollMu(a) then
			return a.Name < b.Name
		end

		local ua = a:GetAttribute("BrainrotUid") :: string
		local ub = b:GetAttribute("BrainrotUid") :: string
		if (acik[ua] == true) ~= (acik[ub] == true) then
			return acik[ua] == true
		end
		return (worth[ua] or 0) > (worth[ub] or 0)
	end)

	local ayni = true
	for i, tool in istenen do
		if mevcut[i] ~= tool then
			ayni = false
			break
		end
	end
	if ayni then
		return
	end

	siralaniyor[player] = true
	local park = parkKlasoru(player)
	for _, tool in istenen do
		tool.Parent = park
	end

	task.spawn(function()
		task.wait(0.15)
		for _, tool in istenen do
			if tool.Parent == park and backpack.Parent then
				tool.Parent = backpack
			end
		end
		siralaniyor[player] = nil
	end)
end

function Envanter.syncBrainrots(player: Player)
	local data = PlayerData.get(player)
	if not data then
		warn(`[Envanter] {player.Name}: data not loaded, brainrots could not be synced`)
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		backpack = player:WaitForChild("Backpack", 5) :: Backpack?
	end
	if not backpack then
		warn(`[Envanter] {player.Name}: Backpack not found, brainrots could not be synced`)
		return
	end

	local present: { [string]: Tool } = {}
	local places = { backpack :: Instance, player.Character, player:FindFirstChild(PARK_ADI) }

	for _, place in places do
		if place then
			for _, item in place:GetChildren() do
				if item:IsA("Tool") then
					local uid = item:GetAttribute("BrainrotUid")
					if type(uid) == "string" then
						present[uid] = item
					end
				end
			end
		end
	end

	local expected: { [string]: boolean } = {}

	local function spawnTool(entry: any)
		local ok, err = pcall(function()
			Tools.buildBrainrot(entry).Parent = backpack
		end)
		if not ok then
			warn(
				`[Envanter] {player.Name}: "{entry.name or "???"}" ({entry.rarity}) brainrot tool `
					.. `could not be built -- {tostring(err)}`
			)
		end
	end

	for _, entry in data.inventory do
		if entry.slot then
			continue
		end

		expected[entry.uid] = true
		local existing = present[entry.uid]

		if existing then
			local wasRevealed = existing:GetAttribute("Revealed") == true
			if wasRevealed ~= (entry.revealed == true) then
				existing:Destroy()
				spawnTool(entry)
			end
		else
			spawnTool(entry)
		end
	end

	for uid, tool in present do
		if not expected[uid] then
			tool:Destroy()
		end
	end

	reorderBackpack(player, backpack)
end

function Envanter.refresh(player: Player)
	Envanter.syncBrainrots(player)
	Envanter.syncLuckyBlocks(player)
	Envanter.syncScrolls(player)
	Envanter.push(player)
end

task.spawn(function()
	local CantaYukselt = Net.event("CantaYukselt")
	local Bildirim = Net.event("Bildirim")

	CantaYukselt.OnServerEvent:Connect(function(player)
		local data = PlayerData.get(player)
		if not data then
			return
		end

		local kapasite = PlayerData.cantaKapasitesi(player)
		local fiyat = Canta.fiyat(kapasite)

		if not fiyat then
			Bildirim:FireClient(
				player,
				`Your backpack is already at its maximum ({Canta.EnCok}).`,
				Color3.fromRGB(255, 200, 90)
			)
			return
		end

		if data.rot < fiyat then
			Bildirim:FireClient(
				player,
				`Not enough Rot! You need {Format.short(fiyat - data.rot)} more to upgrade your backpack.`,
				Color3.fromRGB(255, 120, 120)
			)
			return
		end

		if not PlayerData.cantayiYukselt(player) then
			return
		end

		PlayerData.addRot(player, -fiyat)
		Envanter.push(player)

		Bildirim:FireClient(
			player,
			`Backpack upgraded to {PlayerData.cantaKapasitesi(player)} brainrots!`,
			Color3.fromRGB(120, 255, 150)
		)
	end)
end)

return Envanter
