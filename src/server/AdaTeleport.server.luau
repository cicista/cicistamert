--[[
	AdaTeleport  (Script)
	Yeri: ServerScriptService > AdaTeleport

	Geminin yanindaki NPC'ye ProximityPrompt takar.
	Oyuncu E'ye basinca ada menusu acilir, ada secilince isinlanir.
]]

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

local COOLDOWN = 3
local lastUse = {}

------------------------------------------------------------------
-- Yardimcilar
------------------------------------------------------------------

-- NPC modelini bul
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

-- Adanin hedef CFrame'i
local function getIslandCFrame(island)
	if island.spawnPartName then
		local part = Workspace:FindFirstChild(island.spawnPartName, true)
		if part and part:IsA("BasePart") then
			return part.CFrame + Vector3.new(0, part.Size.Y / 2 + 4, 0)
		end
	end
	return CFrame.new(island.position)
end

--[[
	Client'a gonderilecek ada listesi.

	Adalar SIRAYLA acilir: oyuncu bir adayi almadan sonrakinin ne oldugunu
	goremez. Acilmis adalar ve sirada olan (satin alinabilir) ada tam
	gorunur; daha ilerisi kilitli "???" satiri olarak gelir.

	fromIndex: konusulan kaptanin bulundugu ada. Ilk ada disindaki
	kaptanlarda listenin basina BEDAVA donus satiri eklenir.
]]
local function buildIslandList(player: Player, fromIndex: number?)
	local data = PlayerData.get(player)
	local unlocked = if data then data.islands else 1
	local home = fromIndex or 1

	local list = {}

	-- Baska bir adadaysan: ilk adaya bedava donus, listenin en ustunde
	if home ~= 1 then
		local first = Config.Islands[1]
		table.insert(list, {
			index = 1,
			name = `{first.name}'ya Don`,
			desc = "Free ride back to the starter island.",
			price = 0,
			color = Color3.fromRGB(120, 230, 150),
			state = "home",
		})
	end

	for i, island in ipairs(Config.Islands) do
		-- Donus satiri zaten eklendiyse ilk adayi tekrar listeleme
		if not (home ~= 1 and i == 1) then
			if i <= unlocked then
				-- Zaten acik: bedava gidilir
				table.insert(list, {
					index = i,
					name = island.name,
					desc = island.desc,
					price = 0,
					color = island.color,
					state = "owned",
				})
			elseif i == unlocked + 1 then
				-- Sirada olan ada: satin alinabilir
				table.insert(list, {
					index = i,
					name = island.name,
					desc = island.desc,
					price = island.price,
					color = island.color,
					state = "buyable",
				})
			else
				-- Henuz sirasi gelmedi: ne oldugu gizli
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

------------------------------------------------------------------
-- NPC hazirla
------------------------------------------------------------------
--[[
	NPC KURULUMU

	Haritada BIRDEN FAZLA kaptan olabilir (her adada bir tane). Onceki surum
	yalnizca ilk buldugu modele prompt takiyordu, bu yuzden diger adalardaki
	kaptanlarla konusulamiyordu.

	Artik "Kaptan" ya da "Captain" adli TUM modeller bulunur ve her birine
	ayri prompt takilir. Her kaptan hangi adada durdugunu bilir; ilk ada
	disindaki kaptanlar menude bedava donus secenegi sunar.
]]
local function findNPCs(): { Model }
	local names = { Config.NPC.name, Config.NPC.altName }
	local found: { Model } = {}

	for _, obj in Workspace:GetDescendants() do
		if obj:IsA("Model") then
			for _, name in names do
				if name and obj.Name == name then
					table.insert(found, obj)
					break
				end
			end
		end
	end

	return found
end

-- Bir adanin dunya konumu (spawn parti varsa onu kullanir)
local function islandPosition(island): Vector3
	if island.spawnPartName then
		local part = Workspace:FindFirstChild(island.spawnPartName, true)
		if part and part:IsA("BasePart") then
			return part.Position
		end
	end
	return island.position
end

-- Verilen konuma en yakin adanin indeksi
local function nearestIslandIndex(position: Vector3): number
	local best, bestDistance = 1, math.huge

	for index, island in ipairs(Config.Islands) do
		local distance = (islandPosition(island) - position).Magnitude
		if distance < bestDistance then
			bestDistance = distance
			best = index
		end
	end

	return best
end

local function setupNPC(npc: Model)
	-- NPC yerinden oynamasin
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
		warn(`[AdaTeleport] {npc:GetFullName()}: Part yok, atlandi`)
		return
	end
	root.Anchored = true

	-- Bu kaptan hangi adada duruyor
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
		AdaMenusuAc:FireClient(player, buildIslandList(player, homeIndex))
	end)

	print(`[AdaTeleport] Kaptan hazir: {npc:GetFullName()} (ada {homeIndex})`)
end

local function setupAllNPCs()
	local npcs = findNPCs()

	if #npcs == 0 then
		warn(
			`[AdaTeleport] '{Config.NPC.name}' ya da '{Config.NPC.altName}' adli NPC bulunamadi. `
				.. `NPC modelinin adini bunlardan biri yap.`
		)
		return
	end

	for _, npc in npcs do
		setupNPC(npc)
	end
end

task.defer(setupAllNPCs)

------------------------------------------------------------------
-- Isinlanma istegi
------------------------------------------------------------------
AdayaGit.OnServerEvent:Connect(function(player, index)
	if typeof(index) ~= "number" then return end

	local island = Config.Islands[index]
	if not island then return end

	local now = os.clock()
	if lastUse[player] and now - lastUse[player] < COOLDOWN then
		return
	end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return end

	--[[
		Rot kontrolu.
		Onceden leaderstats.Para okunuyordu; o alan artik yok (Rot'a gecildi)
		ve kontrol her zaman basarisiz oluyordu. Tek dogruluk kaynagi PlayerData.
	]]
	local data = PlayerData.get(player)
	if not data then
		return
	end

	-- Sirasi gelmemis adaya gidilemez
	if index > data.islands + 1 then
		Bildirim:FireClient(player, "Unlock the previous island first.", Color3.fromRGB(255, 200, 90))
		return
	end

	-- Yeni ada: ucreti odenir ve kalici olarak acilir
	if index > data.islands then
		if data.rot < island.price then
			Bildirim:FireClient(
				player,
				`Not enough Rot! {island.name} costs {Format.short(island.price)} Rot.`,
				Color3.fromRGB(255, 90, 90)
			)
			return
		end

		PlayerData.addRot(player, -island.price)
		data.islands = index
		-- Ekrandaki Rot gostergesi hemen dussun
		Envanter.push(player)
		Bildirim:FireClient(player, `{island.name} unlocked!`, island.color or Color3.fromRGB(120, 220, 255))
	end

	lastUse[player] = now

	local target = getIslandCFrame(island)
	char:PivotTo(target)
	root.AssemblyLinearVelocity = Vector3.zero

	Bildirim:FireClient(player, "Welcome to " .. island.name .. "!", island.color or Color3.fromRGB(120, 220, 255))
end)

Players.PlayerRemoving:Connect(function(player)
	lastUse[player] = nil
end)
