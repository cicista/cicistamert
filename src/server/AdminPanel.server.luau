local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local OgreticiAdimlar = require(Shared:WaitForChild("Ogretici"))
local Config = require(Shared:WaitForChild("OyunConfig"))
local Shovels = require(Shared:WaitForChild("Shovels"))
local Detectors = require(Shared:WaitForChild("Detectors"))
local Flyboard = require(Shared:WaitForChild("Flyboard"))
local Rods = require(Shared:WaitForChild("Rods"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Condition = require(Shared:WaitForChild("Condition"))
local Bases = require(Shared:WaitForChild("Bases"))
local Fuse = require(Shared:WaitForChild("Fuse"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Assets = require(Shared:WaitForChild("Assets"))
local Ores = require(Shared:WaitForChild("Ores"))
local Passler = require(Shared:WaitForChild("Passler"))
local Hiz = require(Shared:WaitForChild("Hiz"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))
local Tools = require(Modules:WaitForChild("Tools"))
local Beams = require(Modules:WaitForChild("Beams"))
local Sand = require(Modules:WaitForChild("Sand"))
local HaftaSonu = require(Modules:WaitForChild("HaftaSonu"))
local Unvan = require(Modules:WaitForChild("Unvan"))
local Yetki = require(Modules:WaitForChild("Yetki"))
local Seviye = require(Modules:WaitForChild("Seviye"))
local SeviyeAyar = require(Shared:WaitForChild("Seviye"))

local baseYenile = script.Parent:WaitForChild("BaseSistemi"):WaitForChild("BaseYenile") :: BindableEvent
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local LuckyBlockOdul = require(Modules:WaitForChild("LuckyBlockOdul"))

local Bildirim = Net.event("Bildirim")
local AdminPanelAc = Net.event("AdminPanelAc")
local AdminKomut = Net.event("AdminKomut")

local A = Config.Admin
local rng = Random.new()

local function isAdmin(player: Player): boolean
	return Yetki.admin(player)
end

local commands: { [string]: (player: Player, data: any, arg: any) -> string? } = {}

function commands.giveAllTools(player, data)
	local topShovel = Shovels.Order[#Shovels.Order]
	local topDetector = Detectors.Order[#Detectors.Order]

	data.shovel = topShovel
	data.shovelMax = topShovel
	data.detector = topDetector
	data.detectorMax = topDetector

	Envanter.giveShovel(player)
	Envanter.giveGPS(player)

	return `{Shovels.get(topShovel).displayName} + {Detectors.get(topDetector).displayName} given`
end

function commands.giveRot(player, data)
	PlayerData.addRot(player, A.rotGrant)
	return `+{Format.short(A.rotGrant)} Rot`
end

local ROT_COIN_MIKTARLARI = { [10] = true, [100] = true, [1000] = true }

function commands.giveRotCoins(player, data, arg)
	local miktar = tonumber(arg)
	if not miktar or not ROT_COIN_MIKTARLARI[miktar] then
		return nil
	end
	PlayerData.addRotCoins(player, miktar)
	return `+{miktar} Rot Coin  (total {data.rotCoins})`
end

local function ipuclariniAyarla(player: Player, data: any, gorulmus: boolean)
	data.tutorial.adaIpucu = gorulmus
	data.tutorial.kurekIpucu = gorulmus
	player:SetAttribute(OgreticiAdimlar.AdaIpucu.nitelik, nil)
	player:SetAttribute(OgreticiAdimlar.KurekIpucu.nitelik, nil)
end

function commands.ogreticiSifirla(player, data)
	data.tutorial = { adim = 1, bitti = false, kazilan = {} }
	ipuclariniAyarla(player, data, false)

	local modul = script.Parent:FindFirstChild("Modules")
	local ogretici = modul and modul:FindFirstChild("Ogretici")
	if ogretici and ogretici:IsA("ModuleScript") then
		local ok, sonuc = pcall(require, ogretici)
		if ok then
			sonuc.gonder(player)
		end
	end

	return "Tutorial restarted: step 1"
end

local function ogreticiModulu(): any?
	local modul = script.Parent:FindFirstChild("Modules")
	local node = modul and modul:FindFirstChild("Ogretici")
	if node and node:IsA("ModuleScript") then
		local ok, sonuc = pcall(require, node)
		if ok then
			return sonuc
		end
	end
	return nil
end

function commands.ogreticiAtla(player, data)
	if data.tutorial.bitti then
		return "Tutorial is already finished"
	end

	local toplam = OgreticiAdimlar.adimSayisi()

	data.tutorial.adim = math.clamp(math.floor(data.tutorial.adim), 1, toplam)

	if data.tutorial.adim >= toplam then
		data.tutorial.bitti = true
	else
		data.tutorial.adim += 1
	end

	local ogretici = ogreticiModulu()
	if ogretici then
		ogretici.gonder(player)
	end

	return if data.tutorial.bitti
		then "Tutorial finished"
		else `Tutorial moved to step {data.tutorial.adim}`
end

function commands.ogreticiBitir(player, data)
	data.tutorial.bitti = true
	data.tutorial.adim = OgreticiAdimlar.adimSayisi()
	data.tutorial.kazilan = {}
	ipuclariniAyarla(player, data, true)
	player:SetAttribute("OgreticiAdim", nil)

	local ogretici = ogreticiModulu()
	if ogretici then
		ogretici.gonder(player)
	end

	return "Tutorial finished (hints included)"
end

function commands.adaIpucuSifirla(player, data)
	data.tutorial.adaIpucu = nil
	player:SetAttribute(OgreticiAdimlar.AdaIpucu.nitelik, nil)
	data.tutorial.kurekIpucu = nil
	player:SetAttribute(OgreticiAdimlar.KurekIpucu.nitelik, nil)
	return "Island and shovel hints reset (they show again once affordable)"
end

function commands.luckyEvent(player, data)
	LuckyBlockOdul.runEvent()
	return `Event started ({LuckyBlock.toplamBlok()} blocks)`
end

function commands.giveLuckyBlock(player, data, arg)
	local tierId = if type(arg) == "string" and LuckyBlock.exists(arg) then arg else LuckyBlock.Default
	local tier = LuckyBlock.get(tierId)

	PlayerData.addLuckyBlocks(player, tierId, 1)
	Envanter.syncLuckyBlocks(player)
	Envanter.push(player)

	return `+1 {tier.displayName}  (total {PlayerData.luckyBlockCount(player, tierId)})`
end

function commands.giveBrainrot(player, data, arg)
	local rarityId = "Common"
	local mutationId: string? = nil

	if type(arg) == "string" then
		if Rarity.Info[arg] then
			rarityId = arg
		end
	elseif type(arg) == "table" then
		if type(arg.rarity) == "string" and Rarity.Info[arg.rarity] then
			rarityId = arg.rarity
		end
		if type(arg.mutation) == "string" and Mutations.Info[arg.mutation] then
			mutationId = arg.mutation
		end
	end

	if not mutationId then
		mutationId = Mutations.roll(rng)
	end

	local condition = Condition.roll(rng)

	local item = PlayerData.addBrainrot(player, rarityId, condition, mutationId)
	if not item then
		return nil
	end

	item.name = Brainrots.roll(rarityId :: any, rng).name
	item.revealed = true

	Envanter.syncBrainrots(player)

	local mutationInfo = Mutations.get(mutationId)
	local suffix = if Mutations.isSpecial(mutationId)
		then `  <-- {mutationInfo.displayName} {mutationInfo.multiplier}x`
		else ""

	return `{item.name}  ({Rarity.displayName(rarityId)}, {Condition.get(condition).shortName}, {mutationInfo.displayName}){suffix}`
end

function commands.revealAll(player, data)
	local count = 0

	for _, item in data.inventory do
		if not item.revealed then
			local picked = Brainrots.rollIsland(item.rarity :: any, item.island, rng)
			item.name = picked.name
			item.revealed = true
			count += 1
		end
	end

	if count == 0 then
		return "No unidentified pets to reveal"
	end

	Envanter.syncBrainrots(player)
	return `{count} pet(s) revealed`
end

function commands.setMutation(player, data, arg)
	if type(arg) ~= "string" or not Mutations.Info[arg] then
		return nil
	end

	local _, heldUid = Tools.equippedBrainrot(player)
	if not heldUid then
		return "Hold a pet first"
	end

	local item = PlayerData.findItem(player, heldUid)
	if not item then
		return nil
	end

	if not item.revealed or not item.name then
		return "This pet is not identified"
	end

	if item.mutation == arg then
		return `Already {Mutations.get(arg).displayName}`
	end

	item.mutation = arg

	Envanter.syncBrainrots(player)

	local info = Mutations.get(arg)
	return `{item.name} -> {info.displayName} ({info.multiplier}x)`
end

function commands.testMutation(player, data)
	local counts: { [string]: number } = {}
	local rolls = 1000

	for _ = 1, rolls do
		local id = Mutations.roll(rng)
		counts[id] = (counts[id] or 0) + 1
	end

	print(`[ADMIN] {rolls} rolls:`)
	for _, id in Mutations.Order do
		local n = counts[id] or 0
		print(string.format("  %-10s %4d  (%%%.1f)", id, n, n / rolls * 100))
	end

	local special = rolls - (counts.Normal or 0)
	return `{special}/{rolls} mutated -- details in Output`
end

function commands.spawnBeam(player, data, arg)
	if type(arg) ~= "string" then
		return nil
	end

	local maden = Ores.get(arg)
	local valid = Rarity.Info[arg] ~= nil or arg == "LuckyBlock" or maden ~= nil
	if not valid then
		return nil
	end

	local beam = Beams.spawnKind(player, arg)
	if not beam then
		return "Could not spawn the beam -- no character?"
	end

	if maden then
		local cfg = Ores.island(maden.island)
		local kazma = if cfg then Ores.Pickaxes[cfg.pickaxe] else nil
		return `{maden.displayName} rock spawned -- needs {if kazma then kazma.displayName else "a pickaxe"}`
	end

	local label = if Rarity.Info[arg] then Rarity.displayName(arg) else Rarity.LuckyBlock.displayName

	return `{label} beam spawned -- hold your shovel and dig`
end

function commands.spawnGirdap(player, data, arg)
	if type(arg) ~= "string" or not Rarity.Info[arg] then
		return nil
	end

	local girdap, suda = Beams.spawnWhirlKind(player, arg)
	if not girdap then
		return "Could not spawn the whirlpool -- no character?"
	end

	local label = Rarity.displayName(arg)
	return if suda
		then `{label} whirlpool spawned in the sea -- hold your rod`
		else `{label} whirlpool placed IN FRONT of you (no water nearby)`
end

function commands.giveGizliBrainrot(player, data, arg)
	local rarityId = if type(arg) == "string" and Rarity.Info[arg] then arg else "Common"

	local item = PlayerData.addBrainrot(player, rarityId, Condition.roll(rng), Mutations.roll(rng))
	if not item then
		return nil
	end

	item.name = Brainrots.roll(rarityId :: any, rng).name
	item.revealed = false

	Envanter.syncBrainrots(player)
	Envanter.push(player)

	return `Unidentified {Rarity.displayName(rarityId)} pet given -- reveal it at the Detective`
end

local function vec(position: Vector3): string
	return string.format("%.1f, %.1f, %.1f", position.X, position.Y, position.Z)
end

local function anchorPosition(node: Instance?): Vector3?
	if not node then
		return nil
	end
	if node:IsA("BasePart") then
		return node.Position
	end
	if node:IsA("Model") then
		local part = node.PrimaryPart or node:FindFirstChildWhichIsA("BasePart", true)
		return if part then part.Position else nil
	end
	return nil
end

function commands.haritaRaporu(player, data)
	local eksik = 0

	print("========== MAP REPORT ==========")
	print("")
	print("ISLANDS  (the spawn part is checked first, else the config position is used)")

	for index, island in Config.Islands do
		local part = if island.spawnPartName
			then Workspace:FindFirstChild(island.spawnPartName, true)
			else nil
		local position = anchorPosition(part)

		if position then
			print(
				string.format(
					"  %d) %-14s %-16s FOUND     %s   (config: %s)",
					index,
					island.name,
					island.spawnPartName or "-",
					vec(position),
					vec(island.position)
				)
			)
		else
			eksik += 1
			print(
				string.format(
					"  %d) %-14s %-16s MISSING!  using config position: %s",
					index,
					island.name,
					island.spawnPartName or "-",
					vec(island.position)
				)
			)
		end
	end

	print("")
	print("BASES  (found by name, positions are not in code)")

	local bases = Bases.findFolder()

	if not bases then
		eksik += 1
		print(`  No "{Bases.FolderName}" folder anywhere in Workspace!`)
	else
		print(`  Folder: {bases:GetFullName()}`)

		local children = bases:GetChildren()
		print(string.format("  Folder contents: %d objects", #children))

		for _, child in children do
			local position = anchorPosition(child)
			local slots = 0
			for _, node in child:GetDescendants() do
				if string.match(node.Name, "^Slot%d+$") then
					slots += 1
				end
			end

			print(
				string.format(
					"    %-16s %-12s %-24s %d slot",
					child.Name,
					child.ClassName,
					if position then vec(position) else "(no part)",
					slots
				)
			)
		end

		print("")
		print("  Expected names:")

		for index = 1, Bases.Count do
			local base = bases:FindFirstChild(`Base{index}`)
			if base then
				print(string.format("    Base%d  found", index))
			else
				eksik += 1
				print(string.format("    Base%d  MISSING", index))
			end
		end
	end

	print("")
	print("NPCS / OBJECTS")

	local wanted = {
		Config.NPC.name,
		Config.NPC.altName,
		Config.Detective.name,
		Config.Seller.name,
		Config.Seller.altName,
		Config.Fuse.machineName,
		Config.Fuse.machineAltName,
		Fuse.VFX.name,
	}

	for _, name in wanted do
		if type(name) == "string" then
			local position = anchorPosition(Workspace:FindFirstChild(name, true))
			if position then
				print(string.format("  %-20s %s", name, vec(position)))
			end
		end
	end

	print("")
	print("===================================")

	return if eksik == 0
		then "Map OK -- details in Output"
		else `{eksik} objects MISSING -- details in Output`
end

function commands.kumRaporu(player, data)
	local onSand, lines = Sand.report(player)

	print("========== SAND REPORT ==========")
	for _, line in lines do
		print(line)
	end
	print("================================")

	return if onSand
		then "You are on sand -- the GPS should be in your hand"
		else "You are NOT on sand -- reason in Output"
end

local function hsvOf(color: Color3): string
	local h, s, v = color:ToHSV()
	return string.format("H=%.2f S=%.2f V=%.2f", h, s, v)
end

local function isGreenish(color: Color3): boolean
	local h, s, v = color:ToHSV()
	return h >= 0.22 and h <= 0.45 and s >= 0.35 and v >= 0.35
end

function commands.gizliRaporu(player, data)
	local cfg = Assets.HiddenBrainrot

	print("========== HIDDEN BRAINROT REPORT ==========")
	print(`  Searched name : "{cfg.name}"`)
	print(`  Kept part     : "{cfg.keepPart}"`)
	print("")

	print("  Names containing \"hidden\" (all services):")
	local seen = 0
	for _, root in Assets.searchRoots() do
		for _, node in root:GetDescendants() do
			if string.find(string.lower(node.Name), "hidden", 1, true) then
				seen += 1
				print(string.format("    %2d. %-14s %s", seen, node.ClassName, node:GetFullName()))
			end
		end
	end
	if seen == 0 then
		print("    (none)")
	end
	print("")

	local kids = Workspace:GetChildren()
	print(`  Direct children of Workspace ({#kids}):`)
	for index, node in kids do
		print(string.format("    %2d. %-14s %s", index, node.ClassName, node.Name))
	end
	print("")

	local model = Assets.hiddenBrainrotModel()

	if not model then
		print("  BUILD FAILED -- find the model in the list above and write its name")
		print("  exactly into Assets.HiddenBrainrot.name.")
		print("===========================================")
		return "Model could not be built -- details in Output"
	end

	local parts, keep = 0, 0
	for _, node in model:GetDescendants() do
		if node:IsA("BasePart") then
			parts += 1
			if node:GetAttribute(cfg.keepAttribute) then
				keep += 1
			end
		end
	end

	print("  BUILD OK")
	print(`    BasePart count         : {parts}`)
	print(`    Kept ("{cfg.keepPart}")    : {keep}`)

	if keep == 0 then
		print(`    WARNING: "{cfg.keepPart}" not found -- everything will be tinted with the tier color.`)
		print("    Part names inside the model:")
		for _, node in model:GetDescendants() do
			if node:IsA("BasePart") then
				print(`      {node.Name}`)
			end
		end
	end

	model:Destroy()
	print("===========================================")

	return `Model ready ({parts} parts, {keep} kept) -- details in Output`
end

function commands.vfxRaporu(player, data)
	local name = Config.BeamVFX.name
	local template = Assets.vfxTemplate(name)

	if not template then
		return `"{name}" not found -- put it in Workspace or Assets > VFX`
	end

	print("========== VFX REPORT ==========")
	print(`  Root : {template.ClassName} "{template.Name}"`)
	print("")

	local flagged = 0
	local total = 0

	for _, node in template:GetDescendants() do
		total += 1

		local detail = ""
		local mark = ""

		if node:IsA("BasePart") then
			local size = node.Size
			detail = string.format(
				"color=%d,%d,%d  %s  size=%.2f,%.2f,%.2f  %s",
				math.floor(node.Color.R * 255),
				math.floor(node.Color.G * 255),
				math.floor(node.Color.B * 255),
				hsvOf(node.Color),
				size.X,
				size.Y,
				size.Z,
				node.Material.Name
			)

			if isGreenish(node.Color) then
				mark = "   <-- GREEN"
				flagged += 1
			elseif math.max(size.X, size.Y, size.Z) <= 0.6 then
				mark = "   <-- very small"
				flagged += 1
			end
		elseif node:IsA("ParticleEmitter") or node:IsA("Trail") or node:IsA("Beam") then
			local first = node.Color.Keypoints[1].Value
			detail = string.format("first color %s", hsvOf(first))

			if node:IsA("ParticleEmitter") then
				detail ..= string.format("  LightEmission=%.2f  Rate=%.1f", node.LightEmission, node.Rate)
			end

			if isGreenish(first) then
				mark = "   <-- GREEN"
				flagged += 1
			end
		elseif node:IsA("Light") then
			detail = string.format("%s  Brightness=%.1f  Range=%.1f", hsvOf(node.Color), node.Brightness, node.Range)
			if isGreenish(node.Color) then
				mark = "   <-- GREEN"
				flagged += 1
			end
		elseif node:IsA("Attachment") then
			detail = "(particle holder -- invisible itself)"
		end

		print(string.format("  %-18s %-24s %s%s", node.ClassName, node.Name, detail, mark))
	end

	print("")
	print(`  Total {total} objects, {flagged} flagged`)
	print("  To remove one, add its name to Config.BeamVFX.hide.")
	print("================================")

	template:Destroy()

	return `{total} objects listed, {flagged} flagged -- details in Output`
end

function commands.givePickaxe(player, data, arg)
	if arg == "all" then
		for id in Ores.Pickaxes do
			data.pickaxes[id] = true
		end
		return "All pickaxes given"
	end

	if type(arg) ~= "string" or not Ores.Pickaxes[arg] then
		return nil
	end

	data.pickaxes[arg] = true
	return `{Ores.Pickaxes[arg].displayName} given`
end

local MADEN_ADEDI = 10

function commands.giveOres(player, data, arg)
	if type(arg) ~= "string" then
		return nil
	end

	local cfg = Ores.island(arg)
	if cfg then
		for _, id in cfg.ores do
			PlayerData.addOre(player, id, MADEN_ADEDI)
		end
		return `{cfg.name}: +{MADEN_ADEDI} of each ore`
	end

	local maden = Ores.get(arg)
	if not maden then
		return nil
	end

	local adet = PlayerData.addOre(player, maden.id, MADEN_ADEDI)
	return `+{MADEN_ADEDI} {maden.displayName} (x{adet})`
end

function commands.setShovel(player, data, arg)
	if type(arg) ~= "string" or not Shovels.Info[arg] then
		return nil
	end

	data.shovel = arg
	if Shovels.get(arg :: any).level > Shovels.get(data.shovelMax :: any).level then
		data.shovelMax = arg
	end
	Envanter.giveShovel(player)
	return `Shovel: {Shovels.get(arg).displayName}`
end

function commands.setRod(player, data, arg)
	if type(arg) ~= "string" or not Rods.exists(arg) then
		return nil
	end

	data.rod = arg
	if Rods.level(arg) > Rods.level(data.rodMax) then
		data.rodMax = arg
	end

	if player:GetAttribute("Flyboarding") == true then
		Envanter.removeRod(player)
		Envanter.equipRod(player)
	end

	local info = Rods.get(arg)
	return `Rod: {if info then info.displayName else arg}`
end

function commands.setFlyboard(player, data, arg)
	if type(arg) ~= "string" or not Flyboard.exists(arg) then
		return nil
	end

	data.flyboard = arg
	if Flyboard.level(arg) > Flyboard.level(data.flyboardMax) then
		data.flyboardMax = arg
	end
	local info = Flyboard.get(arg)
	return `Flyboard: {if info then info.displayName else arg}`
end

function commands.setDetector(player, data, arg)
	if type(arg) ~= "string" or not Detectors.Info[arg] then
		return nil
	end

	data.detector = arg
	if Detectors.get(arg :: any).level > Detectors.get(data.detectorMax :: any).level then
		data.detectorMax = arg
	end
	Envanter.giveGPS(player)
	return `Detector: {Detectors.get(arg).displayName}`
end

function commands.scriptRaporu(player, data)
	local ServerScriptService = game:GetService("ServerScriptService")
	local StarterPlayer = game:GetService("StarterPlayer")
	local bizim = {
		ServerScriptService,
		StarterPlayer:FindFirstChild("StarterPlayerScripts"),
		ReplicatedStorage:FindFirstChild("Shared"),
	}

	local function bizimMi(node: Instance): boolean
		for _, kok in bizim do
			if kok and node:IsDescendantOf(kok) then
				return true
			end
		end
		return false
	end

	local kokler = {
		Workspace,
		ReplicatedStorage,
		game:GetService("ServerStorage"),
		game:GetService("StarterGui"),
		game:GetService("StarterPack"),
		game:GetService("Lighting"),
		game:GetService("SoundService"),
		StarterPlayer,
	}

	local bulunan = {}
	for _, kok in kokler do
		for _, node in kok:GetDescendants() do
			if node:IsA("LuaSourceContainer") and not bizimMi(node) then
				table.insert(bulunan, `  {node.ClassName}  {node:GetFullName()}`)
			end
		end
	end

	print(`[Admin] Scripts outside our folders ({#bulunan}):`)
	for _, satir in bulunan do
		print(satir)
	end
	return `{#bulunan} foreign scripts -- list in Output`
end

function commands.togglePass(player, data, arg)
	local info = if type(arg) == "string" then Passler.get(arg) else nil
	if not info then
		return nil
	end
	local yeni = not Passler.sahip(player, arg)
	player:SetAttribute(info.nitelik, yeni)
	return `{info.ad}: {if yeni then "GIVEN" else "REMOVED"} (this session)`
end

local function hiziYenile(player: Player)
	local data = PlayerData.get(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if data and humanoid then
		local hiz = Hiz.hiz(Hiz.etkinSeviye(data.speedLevel, data.hizTercihi))
		if humanoid:GetAttribute("FlyboardTabanHiz") ~= nil then
			humanoid:SetAttribute("FlyboardTabanHiz", hiz)
		else
			humanoid.WalkSpeed = hiz
		end
	end

	local betik = script.Parent:FindFirstChild("Hiz")
	local olay = betik and betik:FindFirstChild("HizYenile")
	if olay and olay:IsA("BindableEvent") then
		olay:Fire(player)
	end
end

function commands.setRebirth(player, data, arg)
	local adet = tonumber(arg)
	if not adet then
		return nil
	end
	data.speedRebirth = math.clamp(math.floor(adet), 0, Hiz.MaxRebirth)
	hiziYenile(player)
	return `Speed rebirth: {data.speedRebirth}`
end

function commands.setSpeed(player, data, arg)
	local adet = tonumber(arg)
	if not adet then
		return nil
	end
	data.speedLevel = math.clamp(math.floor(adet), 0, Hiz.Max)
	data.hizTercihi = -1
	hiziYenile(player)
	return `Speed set: Speed {data.speedLevel + 1} (x{string.format("%.1f", Hiz.carpan(data.speedLevel))})`
end

function commands.levelAtla(player, data, arg)
	local adet = math.clamp(math.floor(tonumber(arg) or 0), 1, SeviyeAyar.Max)
	if data.level >= SeviyeAyar.Max then
		return `Already at max level ({SeviyeAyar.Max})`
	end
	local hedef = math.min(SeviyeAyar.Max, data.level + adet)
	local gereken = -data.xp
	for seviye = data.level, hedef - 1 do
		gereken += SeviyeAyar.gerekenXp(seviye)
	end
	Seviye.xpVer(player, math.max(1, gereken))
	return `Level {data.level}`
end

function commands.levelAyarla(player, data, arg)
	local hedef = math.clamp(math.floor(tonumber(arg) or 1), 1, SeviyeAyar.Max)
	data.level = hedef
	data.xp = 0
	Seviye.etiketGuncelle(player)
	Seviye.push(player)
	return `Level set to {hedef}`
end

function commands.tumRozetler(player)
	local sayi = Unvan.hepsiniVer(player)
	return `{sayi} badges given -- equip titles from the Badges menu`
end

function commands.rozetSifirla(player)
	Unvan.sifirla(player)
	return "Badges and badge progress reset"
end

function commands.haftaSonuBaslat()
	HaftaSonu.testBaslat()
	return "Weekend started: 2x luck for 48 hours (test)"
end

function commands.haftaSonuDurdur()
	HaftaSonu.testDurdur()
	return if HaftaSonu.aktif() then "Test stopped (it is a real weekend, still active)" else "Weekend test stopped"
end

function commands.clearInventory(player, data)
	local count = #data.inventory
	table.clear(data.inventory)

	Envanter.syncBrainrots(player)
	baseYenile:Fire(player)

	return `{count} pet(s) deleted`
end

AdminKomut.OnServerEvent:Connect(function(player, command, arg)
	if not isAdmin(player) then
		return
	end

	if type(command) ~= "string" then
		return
	end

	local handler = commands[command]
	if not handler then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local ok, message = pcall(handler, player, data, arg)

	if not ok then
		warn(`[ADMIN] "{command}" failed -- {tostring(message)}`)
		Bildirim:FireClient(player, `[ADMIN] {command} ERROR: {tostring(message)}`, Color3.fromRGB(255, 90, 90))
		return
	end

	Envanter.push(player)

	if message then
		Bildirim:FireClient(player, `[ADMIN] {message}`, Color3.fromRGB(255, 214, 41))
	end
end)

local function announce(player: Player)
	task.wait(1)
	local yetkili = Yetki.bekle(player)
	if not player.Parent then
		return
	end

	AdminPanelAc:FireClient(player, {
		allowed = yetkili,
		rotGrant = A.rotGrant,
		shovels = Shovels.Order,
		detectors = Detectors.Order,
		flyboards = Flyboard.Order,
		rods = Rods.Order,
		rarities = Rarity.Order,
	})
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(announce, player)
end)

for _, player in Players:GetPlayers() do
	task.spawn(announce, player)
end
