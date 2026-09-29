local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Assets = require(Shared:WaitForChild("Assets"))
local Condition = require(Shared:WaitForChild("Condition"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Detectors = require(Shared:WaitForChild("Detectors"))
local Rods = require(Shared:WaitForChild("Rods"))
local DigMinigame = require(Shared:WaitForChild("DigMinigame"))
local KaziMinigame = require(Shared:WaitForChild("KaziMinigame"))
local Net = require(Shared:WaitForChild("Net"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Sand = require(Modules:WaitForChild("Sand"))
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
local Tools = require(Modules:WaitForChild("Tools"))
local Olta = require(Modules:WaitForChild("Olta"))
local Beams = require(Modules:WaitForChild("Beams"))
local Adimlar = require(Shared:WaitForChild("Ogretici"))
local LuckyBlockOdul = require(Modules:WaitForChild("LuckyBlockOdul"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Ores = require(Shared:WaitForChild("Ores"))
local Hiz = require(Shared:WaitForChild("Hiz"))
local Envanter = require(Modules:WaitForChild("Envanter"))
local GorevTakip = require(Modules:WaitForChild("GorevTakip"))
local Patlama = require(Modules:WaitForChild("Patlama"))
local MadenPatlamasi = require(Modules:WaitForChild("MadenPatlamasi"))
local Arkadaslar = require(Modules:WaitForChild("Arkadaslar"))
local Seviye = require(Modules:WaitForChild("Seviye"))
local AfkSans = require(Modules:WaitForChild("AfkSans"))

local Bildirim = Net.event("Bildirim")
local GPSGuncelle = Net.event("GPSGuncelle")
local SuzmeKaz = Net.event("SuzmeKaz")
local MinigameBasla = Net.event("MinigameBasla")
local MinigameSonuc = Net.event("MinigameSonuc")
local KaziBitti = Net.event("KaziBitti")

local D = Config.Dig

local KESIF_NITELIGI = "KesifKisiti"
local G = Config.GPS

local rng = Random.new()

local digging: { [Player]: any } = {}
local lastDig: { [Player]: number } = {}

local GIRDAP_ARASI = 4
local lastWhirl: { [Player]: number } = {}

local TARAMA_ADIMI = 0.4
local TARAMA_MESAFESI = 35
local sonTarama: { [Player]: number } = {}
local sonKonum: { [Player]: Vector3 } = {}

local girdapBildirildi = false

local function luckFor(player: Player): number
	local ground = Sand.luckUnder(player)

	local data = PlayerData.get(player)
	local detector = if data then Detectors.get(data.detector :: any) else Detectors.get(Detectors.Default)

	return ground
		* detector.luck
		* PlayerData.luckBonus(player)
		* Arkadaslar.carpan(player)
		* Seviye.carpan(player)
		* AfkSans.carpan(player)
end

local function detectorFor(player: Player): Detectors.DetectorInfo
	local data = PlayerData.get(player)
	local id = if data then data.detector else Detectors.Default
	return Detectors.get(id :: any)
end

local function rodFor(player: Player): Rods.RodInfo?
	local data = PlayerData.get(player)
	return if data then Rods.get(data.rod) else nil
end

local lastOnSand: { [Player]: number } = {}

local function otoEkipman(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return
	end

	local oturum = digging[player]
	if oturum then
		player:SetAttribute(KESIF_NITELIGI, true)
		if oturum.pickaxeId then
			Envanter.equipPickaxe(player, oturum.pickaxeId)
		elseif not oturum.sea then
			Envanter.equipShovel(player)
		end
		return
	end

	if Olta.has(player) then
		player:SetAttribute(KESIF_NITELIGI, true)
		return
	end

	local now = os.clock()

	if Sand.isOnSand(player) then
		lastOnSand[player] = now
		player:SetAttribute(KESIF_NITELIGI, true)
		Envanter.equipGPS(player)
		return
	end

	local left = lastOnSand[player]
	if left and now - left < D.autoUnequipDelay then
		return
	end

	lastOnSand[player] = nil
	player:SetAttribute(KESIF_NITELIGI, false)
	Envanter.unequipTools(player)
end

local sabitlenen: { [Player]: BasePart } = {}

local function sabitle(player: Player, root: BasePart, hedef: Vector3?)
	if sabitlenen[player] then
		return
	end

	if hedef then
		local bakis = Vector3.new(hedef.X, root.Position.Y, hedef.Z)
		if (bakis - root.Position).Magnitude > 0.5 then
			root.CFrame = CFrame.lookAt(root.Position, bakis)
		end
	end

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.Anchored = true
	sabitlenen[player] = root
end

local function serbestBirak(player: Player)
	local root = sabitlenen[player]
	sabitlenen[player] = nil
	if root and root.Parent then
		root.Anchored = false
	end
end

local function finishDig(player: Player, won: boolean)
	local session = digging[player]
	if not session then
		return
	end
	digging[player] = nil
	lastDig[player] = os.clock()

	serbestBirak(player)

	local karakter = player.Character
	if karakter then
		Olta.reel(karakter)
		karakter:SetAttribute("Kaziyor", nil)
		karakter:SetAttribute("KaziHedef", nil)
	end

	local beam = Beams.get(session.beamId)
	KaziBitti:FireClient(player)

	otoEkipman(player)

	if not beam then
		return
	end

	Beams.remove(session.beamId, if won then "dig won" else "dig lost")

	local maden = Ores.get(beam.kind)

	if won and not session.sea and not maden then
		Patlama.oynat(player, beam.kind)
	elseif won and session.sea then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			Assets.playSoundAt({ "Catch" }, root)
		end
		Patlama.oynat(player, beam.kind, false)
	end

	if not won then
		local kayip = if maden then `The {maden.displayName} crumbled!` else "The brainrot got away!"
		Bildirim:FireClient(player, kayip, Color3.fromRGB(255, 120, 120))
		return
	end

	PlayerData.reachIsland(player, beam.island)

	if maden then
		local adet = PlayerData.addOre(player, maden.id, Ores.MineAmount)
		MadenPatlamasi.oynat(beam.position, maden.color)
		Seviye.xpVer(player, Seviye.XP.ore)
		Envanter.push(player)
		Bildirim:FireClient(player, `+{Ores.MineAmount} {maden.displayName} (x{adet})`, maden.color)
		return
	end

	if beam.kind == "LuckyBlock" then
		local tierId = LuckyBlock.rollTier(rng)
		local tier = LuckyBlock.get(tierId)

		PlayerData.addLuckyBlocks(player, tierId, 1)
		Envanter.syncLuckyBlocks(player)
		Envanter.push(player)
		LuckyBlockOdul.showDrop(beam.position, tierId)

		Bildirim:FireClient(
			player,
			`{string.upper(tier.displayName)} found! (x{PlayerData.luckyBlockCount(player, tierId)})`,
			tier.color
		)
		return
	end

	local condition = Condition.roll(rng)
	local mutation = Mutations.roll(rng)
	local item = PlayerData.addBrainrot(player, beam.kind, condition, mutation, beam.island)
	if not item then
		return
	end

	Envanter.syncBrainrots(player)
	Envanter.push(player)

	GorevTakip.ilerlet(player, "dig", 1)
	GorevTakip.ilerlet(player, "collect", 1, beam.kind)
	Seviye.xpVer(player, Seviye.rarityXp(beam.kind))

	Ogretici.olay(player, "kazdi")
	if Ogretici.kaziKaydet then
		Ogretici.kaziKaydet(player, item.uid)
	end
	Ogretici.ucKontrol(player)
end

local ogreticiSuzmesi: (player: Player, adet: number) -> ()
do
	local suzmem: { [Player]: { string } } = {}

	local ARALIK = 7

	function ogreticiSuzmesi(player: Player, adet: number)
		local liste = suzmem[player]
		if not liste then
			liste = {}
			suzmem[player] = liste
		end

		for i = #liste, 1, -1 do
			if not Beams.get(liste[i]) then
				table.remove(liste, i)
			end
		end

		if #liste >= adet then
			return
		end

		local karakter = player.Character
		local kok = karakter and karakter:FindFirstChild("HumanoidRootPart")
		if not kok or not kok:IsA("BasePart") then
			return
		end

		while #liste < adet do
			local sira = #liste
			local istenen: Vector3? = nil

			if sira > 0 then
				local ilk = Beams.get(liste[1])
				if ilk then
					local yon = if sira % 2 == 1 then 1 else -1
					local uzaklik = math.ceil(sira / 2) * ARALIK
					istenen = ilk.position + kok.CFrame.RightVector * (yon * uzaklik)
				end
			end

			local beam = Beams.spawnKind(player, Adimlar.IlkKademe, istenen)
			if not beam then
				return
			end
			table.insert(liste, beam.id)
		end

		local ilk = Beams.get(liste[1])
		if ilk and Ogretici.hedefKonumAyarla then
			Ogretici.hedefKonumAyarla(player, ilk.position)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		suzmem[player] = nil
	end)
end

local function startDig(player: Player, beamId: string)
	if digging[player] then
		return
	end

	local now = os.clock()
	if lastDig[player] and now - lastDig[player] < D.cooldown then
		return
	end

	local beam = Beams.get(beamId)
	if not beam or beam.owner ~= player or beam.claimed then
		return
	end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	local erisim = if beam.sea then G.seaDigDistance else G.digDistance

	if (beam.position - root.Position).Magnitude > erisim then
		local uyari = if beam.sea then "Get closer to the whirlpool!" else "Get closer to the beam!"
		Bildirim:FireClient(player, uyari, Color3.fromRGB(255, 160, 60))
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local maden = Ores.get(beam.kind)
	local pickaxeId: string? = nil
	if maden then
		local gerekenSira = table.find(Ores.IslandOrder, maden.island)
		local gerekenAda = Ores.island(maden.island)

		if gerekenSira then
			for i = #Ores.IslandOrder, gerekenSira, -1 do
				local ada = Ores.island(Ores.IslandOrder[i])
				local aday = if ada then ada.pickaxe else nil
				if aday and PlayerData.hasPickaxe(player, aday) then
					pickaxeId = aday
					break
				end
			end
		end

		if not pickaxeId then
			local gereken = if gerekenAda then Ores.Pickaxes[gerekenAda.pickaxe] else nil
			local kazmaAdi = if gereken then gereken.displayName else "the right pickaxe"
			Bildirim:FireClient(player, `You need the {kazmaAdi} (or a better one) to mine {maden.displayName}!`, maden.color)
			return
		end
	end

	beam.claimed = true

	sabitle(player, root :: BasePart, if beam.sea then nil else beam.position)

	if beam.sea then
		if char then
			Olta.cast(char, beam.position)
		end
	elseif pickaxeId then
		Envanter.equipPickaxe(player, pickaxeId)
	else
		Envanter.equipShovel(player)
	end

	local gearId = if beam.sea then (data.rod or Rods.Order[1]) elseif pickaxeId then pickaxeId else data.shovel
	local gear = DigMinigame.gear(gearId)

	local prepare = if beam.sea then Rods.CastTime else 0
	local _ = gear

	digging[player] = {
		beamId = beamId,
		startedAt = now,
		sea = beam.sea == true,
		gearId = gearId,
		rarityId = beam.kind,
		startPos = root.Position,
		pickaxeId = pickaxeId,
	}

	if not beam.sea and player.Character then
		player.Character:SetAttribute("Kaziyor", true)
		player.Character:SetAttribute("KaziHedef", beam.position)
	end

	task.wait(prepare)

	local session = digging[player]
	if not session or session.beamId ~= beamId then
		return
	end

	if beam.kind == "LuckyBlock" then
		finishDig(player, true)
		return
	end

	local seed = rng:NextInteger(1, 2 ^ 30)
	session.seed = seed
	MinigameBasla:FireClient(player, gearId, beam.kind, seed, if beam.sea then "sea" else "sand")

	task.delay(D.minigameTimeout, function()
		local stuck = digging[player]
		if stuck and stuck.beamId == beamId then
			finishDig(player, false)
		end
	end)
end

SuzmeKaz.OnServerEvent:Connect(function(player, beamId)
	if type(beamId) ~= "string" then
		return
	end
	task.spawn(startDig, player, beamId)
end)

MinigameSonuc.OnServerEvent:Connect(function(player, won)
	local session = digging[player]
	if not session then
		return
	end

	if Ogretici.adimId and Ogretici.adimId(player) == "ilkKazi" then
		finishDig(player, true)
		return
	end

	local elapsed = os.clock() - session.startedAt
	if elapsed > D.minigameTimeout then
		finishDig(player, false)
		return
	end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local pay = if session.sea then D.seaMoveDistance else D.maxMoveDistance
	if not root or (root.Position - session.startPos).Magnitude > pay then
		finishDig(player, false)
		return
	end

	if not session.sea and won == true then
		local enHizli = KaziMinigame.minDuration(session.gearId, session.rarityId)

		if enHizli == math.huge then
			warn(
				`[Kazi] {player.Name} claimed to win an unreachable tier `
					.. `({session.gearId} with {session.rarityId}), rejected`
			)
			finishDig(player, false)
			return
		end

		local altSinir = enHizli * 0.85
		if elapsed < altSinir then
			warn(
				`[Kazi] {player.Name} finished the minigame impossibly fast `
					.. `({string.format("%.2f", elapsed)}s < {string.format("%.2f", altSinir)}s), rejected`
			)
			finishDig(player, false)
			return
		end
	end

	if session.sea and won == true then
		local enHizli = DigMinigame.minDuration(session.gearId) * 0.9
		if elapsed < enHizli then
			warn(
				`[Kazi] {player.Name} finished the fishing game impossibly fast `
					.. `({string.format("%.2f", elapsed)}s < {string.format("%.2f", enHizli)}s), rejected`
			)
			finishDig(player, false)
			return
		end
	end

	finishDig(player, won == true)
end)

task.spawn(function()
	while true do
		task.wait(D.autoEquipInterval)

		for _, player in Players:GetPlayers() do
			local ok, err = pcall(otoEkipman, player)
			if not ok then
				warn(`[Kazi] {player.Name}: auto equip failed -- {tostring(err)}`)
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(TARAMA_ADIMI)

		Beams.cleanup()

		for _, player in Players:GetPlayers() do
			local govde = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local konum = if govde and govde:IsA("BasePart") then govde.Position else nil
			local simdiTarama = os.clock()
			local gidilen = if konum and sonKonum[player] then (konum - sonKonum[player]).Magnitude else math.huge
			local sirasiGeldi = (simdiTarama - (sonTarama[player] or 0) >= G.scanInterval)
				or gidilen >= TARAMA_MESAFESI

			if sirasiGeldi then
				sonTarama[player] = simdiTarama
				sonKonum[player] = konum
			end

			local gpsInHand = Tools.equipped(player, Tools.GPSName) ~= nil
			local rodInHand = player:GetAttribute("Flyboarding") == true
			local rod = rodFor(player)

			if sirasiGeldi and gpsInHand and not digging[player] and Sand.isOnSand(player) then
				local ogreticiAdim = if Ogretici.adimId then Ogretici.adimId(player) else nil
				if ogreticiAdim == "ilkKazi" then
					ogreticiSuzmesi(player, 1)
				elseif ogreticiAdim == "ucKazi" then
					ogreticiSuzmesi(player, Adimlar.UcAdet or 3)
				else
					local detector = detectorFor(player)

					if rng:NextNumber() * 100 <= detector.spawnChance then
						Beams.trySpawn(player, luckFor(player), rng, detector.maxBeams)
					end
				end
			end

			if sirasiGeldi and rodInHand and rod and not digging[player] then
				local simdi = os.clock()
				local sonGirdap = lastWhirl[player] or 0

				if simdi - sonGirdap >= GIRDAP_ARASI and rng:NextNumber() * 100 <= rod.spawnChance then
					local denizSansi = rod.luck
						* (G.seaLuck or 1)
						* PlayerData.luckBonus(player)
						* Arkadaslar.carpan(player)
						* Seviye.carpan(player)
						* AfkSans.carpan(player)
					if Beams.trySpawnSea(player, denizSansi, rng, rod.maxWhirls, rod.scanRadius) then
						lastWhirl[player] = simdi
						girdapBildirildi = true
					elseif not girdapBildirildi then
						girdapBildirildi = true
						warn(
							"[Girdap] Water not found: do the sea part names contain "
								.. "deniz/sea/ocean/water/su, and does the ray hit them?"
						)
					end
				end
			end

			local yaricap = if rodInHand and rod then rod.scanRadius else detectorFor(player).scanRadius

			local insan = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if insan then
				yaricap *= math.clamp(insan.WalkSpeed / Hiz.TabanHiz, 1, 3)
			end

			GPSGuncelle:FireClient(player, Beams.snapshotFor(player, yaricap))
		end
	end
end)

local UYARI_ARASI = 2
local sonUyari: { [Player]: number } = {}

local function kesifAraciMi(tool: Tool): boolean
	return tool:GetAttribute("ShovelId") ~= nil
		or tool:GetAttribute("DetectorId") ~= nil
		or tool:GetAttribute("PickaxeId") ~= nil
		or tool:GetAttribute("RodId") ~= nil
end

local function toolEngelle(player: Player, tool: Tool)
	if not player:GetAttribute(KESIF_NITELIGI) or kesifAraciMi(tool) then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:UnequipTools()
	end

	if Sand.isOnSand(player) then
		Envanter.equipGPS(player)
	end

	local now = os.clock()
	if now - (sonUyari[player] or 0) < UYARI_ARASI then
		return
	end
	sonUyari[player] = now

	Bildirim:FireClient(player, "You can't hold that while searching!", Color3.fromRGB(255, 160, 60))
end

local function onCharacterAdded(player: Player)
	local character = player.Character
	if character then
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				toolEngelle(player, child)
			end
		end)
	end

	task.wait(0.5)
	if PlayerData.bekle(player) then
		Envanter.refresh(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.spawn(onCharacterAdded, player)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	digging[player] = nil
	sabitlenen[player] = nil
	lastDig[player] = nil
	lastOnSand[player] = nil
	sonTarama[player] = nil
	sonKonum[player] = nil
	lastWhirl[player] = nil
end)

local refreshEvent = Instance.new("BindableEvent")
refreshEvent.Name = "KurekYenile"
refreshEvent.Parent = script
refreshEvent.Event:Connect(function(player: Player)
	Envanter.giveShovel(player)
end)
