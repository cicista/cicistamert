local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Assets = require(Shared:WaitForChild("Assets"))
local Condition = require(Shared:WaitForChild("Condition"))
local Fonts = require(Shared:WaitForChild("Fonts"))
local Format = require(Shared:WaitForChild("Format"))
local Fuse = require(Shared:WaitForChild("Fuse"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))
local GorevTakip = require(Modules:WaitForChild("GorevTakip"))
local Ogretici = {
	olay = function(_player: Player, _olay: string) end,
	ucKontrol = function(_player: Player) end,
}
do
	local modul = Modules:WaitForChild("Ogretici", 5)
	if modul and modul:IsA("ModuleScript") then
		local ok, sonuc = pcall(require, modul)
		if ok then
			Ogretici = sonuc
		else
			warn(`[Ogretici] module failed to load: {tostring(sonuc)}`)
		end
	end
end
local Seviye = require(Modules:WaitForChild("Seviye"))
local Patlama = require(Modules:WaitForChild("Patlama"))

local Bildirim = Net.event("Bildirim")
local FuseDurum = Net.event("FuseDurum")
local FuseGeriAl = Net.event("FuseGeriAl")
local FuseSecim = Net.event("FuseSecim")
local FuseEkle = Net.event("FuseEkle")
local FuseCikar = Net.event("FuseCikar")
local FuseBaslat = Net.event("FuseBaslat")
local FuseSonuc = Net.event("FuseSonuc")

local F = Config.Fuse
local rng = Random.new()

local UYARI = Color3.fromRGB(255, 200, 90)
local RED = Color3.fromRGB(255, 120, 120)

type Pending = {
	name: string,
	rarity: string,
	entries: { any },
	lastAt: number,
}

local pending: { [Player]: Pending } = {}

local fusing: { [Player]: boolean } = {}

local function buildStand(name: string, position: Vector3, label: string, color: Color3): Model
	local model = Instance.new("Model")
	model.Name = name

	local body = Instance.new("Part")
	body.Name = "Govde"
	body.Size = Vector3.new(7, 7, 5)
	body.Position = position
	body.Anchored = true
	body.Color = Color3.fromRGB(52, 58, 72)
	body.Material = Enum.Material.Metal
	body.Parent = model
	model.PrimaryPart = body

	local panel = Instance.new("Part")
	panel.Name = "Ekran"
	panel.Size = Vector3.new(5, 2.2, 0.3)
	panel.Position = position + Vector3.new(0, 2, -2.5)
	panel.Anchored = true
	panel.CanCollide = false
	panel.Color = color
	panel.Material = Enum.Material.Neon
	panel.Parent = model

	local sign = Instance.new("BillboardGui")
	sign.Name = "Tabela"
	sign.Size = UDim2.fromOffset(230, 44)
	sign.StudsOffset = Vector3.new(0, 5, 0)
	sign.MaxDistance = 120
	sign.Parent = body

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = label
	text.TextColor3 = color
	text.TextSize = 22
	Fonts.apply(text)
	text.Parent = sign

	model.Parent = Workspace
	return model
end

local function adEsit(a: string, b: string): boolean
	return string.lower((string.gsub(a, "%s", ""))) == string.lower((string.gsub(b, "%s", "")))
end

local function findNPC(name: string, altName: string?): Model?
	for _, candidate in { name, altName } do
		if not candidate then
			continue
		end
		for _, node in Workspace:GetDescendants() do
			if node:IsA("Model") and adEsit(node.Name, candidate) then
				return node
			end
		end
	end
	return nil
end

local function anchorOf(model: Model): BasePart?
	local primary = model.PrimaryPart
	if primary then
		return primary
	end

	local root = model:FindFirstChild("HumanoidRootPart", true)
	if root and root:IsA("BasePart") then
		return root
	end

	return model:FindFirstChildWhichIsA("BasePart", true)
end

local bulunanMakine = findNPC(F.machineName, F.machineAltName)

local machine: Model = bulunanMakine
	or buildStand(F.machineName, F.machineSpawnPosition, "FUSE MACHINE", Color3.fromRGB(120, 200, 255))

if not bulunanMakine then
	warn(`[Fuse] "{F.machineName}" / "{F.machineAltName}" not found -- built a fallback stand`)
end

local function inMachineRange(player: Player): boolean
	local anchor = if machine and machine.Parent then anchorOf(machine) else nil
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if not anchor or not root or not root:IsA("BasePart") then
		return false
	end

	return (root.Position - anchor.Position).Magnitude <= F.machineRange
end

local DUYURU_KADEMELERI: { [string]: boolean } = {
	Gizli = true,
	Infernal = true,
	Abyssal = true,
}

local function fuseAdasi(player: Player): string
	local ulasilan = PlayerData.reachedIsland(player)
	local data = PlayerData.get(player)
	local acik = if data then Brainrots.IslandOrder[math.clamp(data.islands or 1, 1, 4)] else nil
	return Brainrots.laterIsland(ulasilan, acik)
end

local function uygunsuzluk(player: Player, item: any): string?
	if item.slot then
		return "A pet on your base cannot be fused."
	end
	if not item.revealed or type(item.name) ~= "string" then
		return "Unidentified pets cannot be fused. Take it to the Detective first."
	end

	local next = Fuse.nextRarity(item.rarity)
	if not next then
		return `{Rarity.displayName(item.rarity)} pets cannot be fused.`
	end

	if not Brainrots.availableOn(next, fuseAdasi(player)) then
		local ilk = Brainrots.firstIslandOf(next)
		local adaAdi = if ilk then Brainrots.IslandNames[ilk] else nil
		return if adaAdi
			then `Unlock {adaAdi} to fuse into {Rarity.displayName(next)}.`
			else `{Rarity.displayName(next)} pets unlock on a later island.`
	end

	local slot = pending[player]
	if slot and slot.rarity ~= item.rarity then
		return `The machine holds {Rarity.displayName(slot.rarity)} pets, add the same tier.`
	end

	return nil
end

local function eligibleItems(player: Player): { any }
	local data = PlayerData.get(player)
	if not data then
		return {}
	end

	local out = {}
	local sayac: { [string]: number } = {}

	for _, item in data.inventory do
		if not Fuse.sees(item.rarity) or item.slot or not item.revealed or type(item.name) ~= "string" then
			continue
		end

		local sebep = uygunsuzluk(player, item)
		local slot = pending[player]
		if sebep and slot and slot.rarity ~= item.rarity then
			continue
		end

		if not sebep then
			sayac[item.name] = (sayac[item.name] or 0) + 1
		end
		table.insert(out, {
			uid = item.uid,
			name = item.name,
			rarity = item.rarity,
			condition = item.condition,
			mutation = item.mutation,
			locked = sebep,
		})
	end

	local makinede: { [string]: boolean } = {}
	local dolu = pending[player]
	if dolu then
		for _, entry in dolu.entries do
			if type(entry.item.name) == "string" then
				makinede[entry.item.name] = true
			end
		end
	end

	for _, entry in out do
		entry.owned = sayac[entry.name] or 0
	end

	table.sort(out, function(a, b)
		if (a.locked ~= nil) ~= (b.locked ~= nil) then
			return a.locked == nil
		end
		local aMakinede = makinede[a.name] == true
		local bMakinede = makinede[b.name] == true
		if aMakinede ~= bMakinede then
			return aMakinede
		end
		if a.owned ~= b.owned then
			return a.owned > b.owned
		end
		return a.name < b.name
	end)

	return out
end

local function pushStatus(player: Player)
	local slot = pending[player]
	local slots = {}

	if slot then
		for _, entry in slot.entries do
			table.insert(slots, {
				uid = entry.item.uid,
				name = entry.item.name,
				rarity = entry.item.rarity,
				condition = entry.condition,
				mutation = entry.mutation,
			})
		end
	end

	FuseDurum:FireClient(player, {
		near = true,
		fusing = fusing[player] == true,
		name = if slot then slot.name else nil,
		rarity = if slot then slot.rarity else nil,
		nextRarity = if slot then Fuse.nextRarity(slot.rarity) else nil,
		required = Fuse.Required,
		chance = if slot and #slot.entries >= Fuse.Required then Fuse.chanceFor(slot.entries) else nil,
		chances = Fuse.Chances,
		slots = slots,
		mutations = if slot then Fuse.mutationChances(slot.entries) else {},
		timeout = if slot then math.max(0, Fuse.Timeout - (os.clock() - slot.lastAt)) else 0,
		items = eligibleItems(player),
	})
end

local function closeStatus(player: Player)
	FuseDurum:FireClient(player, { near = false })
end

local function returnItems(player: Player, reason: string?)
	local slot = pending[player]
	if not slot then
		return
	end
	pending[player] = nil

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local count = #slot.entries
	for _, entry in slot.entries do
		table.insert(data.inventory, entry.item)
	end

	Envanter.syncBrainrots(player)
	Envanter.push(player)

	if count > 0 and reason then
		Bildirim:FireClient(player, `{count} pet(s) returned from the machine ({reason})`, UYARI)
	end
end

local function returnOne(player: Player, uid: string)
	local slot = pending[player]
	if not slot or fusing[player] then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	for index, entry in slot.entries do
		if entry.item.uid == uid then
			table.remove(slot.entries, index)
			table.insert(data.inventory, entry.item)
			break
		end
	end

	if #slot.entries == 0 then
		pending[player] = nil
	else
		slot.lastAt = os.clock()
	end

	Envanter.syncBrainrots(player)
	Envanter.push(player)
	pushStatus(player)
end

local function insertItem(player: Player, uid: string)
	if fusing[player] then
		return
	end

	local item = PlayerData.findItem(player, uid)
	if not item then
		Bildirim:FireClient(player, "That pet is no longer in your inventory.", UYARI)
		return
	end

	local sebep = uygunsuzluk(player, item)
	if sebep then
		Bildirim:FireClient(player, sebep, RED)
		return
	end

	local slot = pending[player]
	if slot and #slot.entries >= Fuse.Required then
		Bildirim:FireClient(player, `The machine is full ({Fuse.Required}/{Fuse.Required}). Press FUSE!`, UYARI)
		return
	end

	local taken = PlayerData.removeItem(player, uid)
	if not taken then
		return
	end

	if not slot then
		slot = { name = taken.name, rarity = taken.rarity, entries = {}, lastAt = os.clock() }
		pending[player] = slot
	end

	local active = slot :: Pending
	table.insert(active.entries, {
		condition = taken.condition,
		mutation = taken.mutation,
		item = taken,
	})
	active.lastAt = os.clock()

	Envanter.syncBrainrots(player)
	Envanter.push(player)
	pushStatus(player)
end

local function bodyOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function playFuseSound(player: Player, names: { string }): Sound?
	local body = bodyOf(player)
	return if body then Assets.playSoundAt(names, body) else nil
end

local function completeFuse(player: Player)
	local slot = pending[player]
	if not slot or fusing[player] then
		return
	end

	if #slot.entries < Fuse.Required then
		Bildirim:FireClient(player, `You need {Fuse.Required} pets of the same tier to fuse.`, UYARI)
		return
	end

	local nextRarity = Fuse.nextRarity(slot.rarity)
	local ada = fuseAdasi(player)

	if not nextRarity or not Brainrots.availableOn(nextRarity, ada) then
		returnItems(player, "cannot fuse this pet")
		pushStatus(player)
		return
	end

	local sans = Fuse.chanceFor(slot.entries)
	local basari = Fuse.rollSuccess(rng, sans)

	local kazanilan: any = nil
	local condition = Fuse.rollSize(slot.entries, rng)
	local mutation = Fuse.rollMutation(slot.entries, rng)

	if basari then
		local info = Brainrots.rollIsland(nextRarity :: any, ada, rng)
		kazanilan = PlayerData.addBrainrot(player, nextRarity, condition, mutation, ada)
		if not kazanilan then
			returnItems(player, "try again")
			pushStatus(player)
			return
		end

		kazanilan.name = info.name
		kazanilan.revealed = true
		GorevTakip.ilerlet(player, "collect", 1, nextRarity)

		if DUYURU_KADEMELERI[nextRarity] then
			local ad = info.name
			local kademe = nextRarity
			task.delay(Fuse.mergeTime(), function()
				Bildirim:FireAllClients(
					`{player.DisplayName} fused a {Rarity.displayName(kademe)} {ad}!`,
					Rarity.color(kademe)
				)
			end)
		end
	end

	GorevTakip.ilerlet(player, "fuse", 1)
	Seviye.xpVer(player, Seviye.XP.fuse)

	local fromRarity = slot.rarity
	local souls = #slot.entries

	local kaynaklar = {}
	local hepsiAyni = true
	for _, entry in slot.entries do
		table.insert(kaynaklar, { name = entry.item.name, mutation = entry.mutation })
		if entry.item.name ~= slot.name then
			hepsiAyni = false
		end
	end
	local fromName = if hepsiAyni then slot.name else `{Rarity.displayName(fromRarity)} pets`

	pending[player] = nil
	fusing[player] = true
	pushStatus(player)

	Ogretici.olay(player, "fuseYapti")

	FuseSonuc:FireClient(player, {
		success = basari,
		fromName = fromName,
		fromRarity = fromRarity,
		toRarity = nextRarity,
		name = if kazanilan then kazanilan.name else nil,
		condition = condition,
		mutation = mutation,
		income = if kazanilan then Brainrots.income(kazanilan.name, condition :: any, mutation :: any) else 0,
		souls = souls,
		sources = kaynaklar,
		chance = sans,
	})

	local charge = playFuseSound(player, Fuse.VFX.charge)

	task.delay(Fuse.burstDelay(), function()
		if charge and charge.Parent then
			charge:Stop()
			charge:Destroy()
		end
		if basari and player.Parent then
			Patlama.oynat(player, nextRarity :: string)
		elseif not basari and player.Parent then
			playFuseSound(player, Fuse.VFX.fail)
		end
	end)

	task.delay(Fuse.mergeTime(), function()
		fusing[player] = nil
		if not player.Parent then
			return
		end

		Envanter.syncBrainrots(player)
		Envanter.push(player)

		if kazanilan then
			local tam = Mutations.get(mutation).prefix .. kazanilan.name
			Bildirim:FireClient(
				player,
				`FUSE SUCCESS! {tam} {Condition.get(condition).shortName} ({Format.perSecond(Brainrots.income(kazanilan.name, condition :: any, mutation :: any))})`,
				Rarity.color(nextRarity :: string)
			)
		else
			Bildirim:FireClient(player, `Fuse failed... your {souls} pets were lost.`, RED)
		end

		pushStatus(player)
	end)
end

local function attachMachinePrompt()
	local anchor = anchorOf(machine)
	if not anchor then
		warn("[Fuse] No Part found on the machine to attach to")
		return
	end

	local existing = anchor:FindFirstChild("FusePrompt")
	if existing then
		existing:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "FusePrompt"
	prompt.ActionText = F.machinePromptText
	prompt.ObjectText = F.machinePromptSubText
	prompt.HoldDuration = F.machineHoldDuration
	prompt.MaxActivationDistance = F.machinePromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = anchor

	prompt.Triggered:Connect(function(player: Player)
		pushStatus(player)
		FuseSecim:FireClient(player)
	end)

	print(`[Fuse] Machine prompt set up: {anchor:GetFullName()}`)
end

task.spawn(attachMachinePrompt)

FuseEkle.OnServerEvent:Connect(function(player, uid)
	if type(uid) == "string" then
		insertItem(player, uid)
	end
end)

FuseCikar.OnServerEvent:Connect(function(player, uid)
	if type(uid) == "string" then
		returnOne(player, uid)
	end
end)

FuseBaslat.OnServerEvent:Connect(function(player)
	completeFuse(player)
end)

FuseGeriAl.OnServerEvent:Connect(function(player)
	if fusing[player] then
		return
	end
	returnItems(player, "taken back")
	pushStatus(player)
end)

local nearby: { [Player]: boolean } = {}

task.spawn(function()
	while true do
		task.wait(0.4)

		for _, player in Players:GetPlayers() do
			if inMachineRange(player) then
				nearby[player] = true
				pushStatus(player)
			elseif nearby[player] then
				nearby[player] = nil
				closeStatus(player)
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)

		local now = os.clock()
		for player, slot in pending do
			if not player.Parent then
				pending[player] = nil
				continue
			end

			if now - slot.lastAt >= Fuse.Timeout then
				returnItems(player, `no action for {Fuse.Timeout}s`)
				if nearby[player] then
					pushStatus(player)
				end
			end
		end
	end
end)

PlayerData.onBeforeRelease(function(player: Player)
	returnItems(player, nil)
end)

Players.PlayerRemoving:Connect(function(player)
	returnItems(player, nil)
	nearby[player] = nil
	fusing[player] = nil
end)
