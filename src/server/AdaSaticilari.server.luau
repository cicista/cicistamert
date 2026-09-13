--[[
	AdaSaticilari  (Script)
	Yeri: ServerScriptService > AdaSaticilari

	Candy, Snow ve Volcano adalarindaki iki NPC:

	  KUREK SATICISI   CandyShovelSeller / FrostyShovelSeller / PhoenixShovelSeller
	      Adanin 5 kuregini satar. Bedel Rot + adanin UC madeninin her
	      birinden 2 / 3 / 5 / 7 / 10 tane (bkz. Shared > Shovels).

	  KAZMA SATICISI   CandySeller / FrostySeller / PhoenixSeller
	      Adanin kazmasini satar (Candy / Frosty / Phoenix Pickaxe) ve
	      madenler arasi TAKAS yapar: diger iki madenden birer tane verilir,
	      istenen madenden bir tane alinir.

	NPC ARANMASI
	Ad eslesmesi diger saticilarla ayni: buyuk/kucuk harf ve bosluk
	gozetmez, Model / Folder / Part kabul eder. Haritada bulunamazsa adanin
	spawn noktasinin yanina basit bir tezgah kurulur ve Output'a yazilir --
	boylece NPC eklenmeden de test edilebilir.

	Satin alma ve takas istekleri NPC'nin YANINDA yapilmali; uzaktan gelen
	istek sessizce yok sayilir.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))
local Fonts = require(Shared:WaitForChild("Fonts"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Ores = require(Shared:WaitForChild("Ores"))
local Shovels = require(Shared:WaitForChild("Shovels"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))

-- KaziSistemi'ndeki kurek yenileme tetigi (eldeki kurek yenisiyle degissin)
local kurekYenile = script.Parent:WaitForChild("KaziSistemi"):WaitForChild("KurekYenile") :: BindableEvent

local Bildirim = Net.event("Bildirim")
local AdaKurekAc = Net.event("AdaKurekAc")
local AdaKurekAl = Net.event("AdaKurekAl")
local KazmaAc = Net.event("KazmaAc")
local KazmaAl = Net.event("KazmaAl")
local MadenTakas = Net.event("MadenTakas")

-- Prompt mesafesi; istek kontrolunde tezgah boyu kadar pay birakilir
local PROMPT_MESAFE = 12
local ISTEK_MESAFE = 24

local UYARI = Color3.fromRGB(255, 200, 90)
local HATA = Color3.fromRGB(255, 90, 90)

-- "sekerkum|kurek" / "sekerkum|kazma" -> NPC'nin tutunma parcasi
local anchors: { [string]: BasePart } = {}

------------------------------------------------------------------
-- NPC BULMA / YEDEK TEZGAH
------------------------------------------------------------------
local function adEsit(a: string, b: string): boolean
	return string.lower((string.gsub(a, "%s", ""))) == string.lower((string.gsub(b, "%s", "")))
end

local function anchorFrom(node: Instance): BasePart?
	if node:IsA("BasePart") then
		return node
	end

	if node:IsA("Model") then
		local primary = node.PrimaryPart
		if primary then
			return primary
		end
		local root = node:FindFirstChild("HumanoidRootPart", true)
		if root and root:IsA("BasePart") then
			return root
		end
	end

	return node:FindFirstChildWhichIsA("BasePart", true)
end

local function findAnchor(ad: string): BasePart?
	for _, node in Workspace:GetDescendants() do
		if adEsit(node.Name, ad) then
			local anchor = anchorFrom(node)
			if anchor then
				return anchor
			end
		end
	end
	return nil
end

local function spawnKonumu(cfg: Ores.IslandOres): Vector3?
	local part = Workspace:FindFirstChild(cfg.spawnPart, true)
	if part and part:IsA("BasePart") then
		return part.Position
	end

	for _, island in Config.Islands do
		if island.spawnPartName == cfg.spawnPart then
			return island.position
		end
	end

	return nil
end

local function standKur(ad: string, baslik: string, cfg: Ores.IslandOres, kayma: Vector3): BasePart?
	local merkez = spawnKonumu(cfg)
	if not merkez then
		return nil
	end

	local nokta = merkez + kayma
	local hit = Workspace:Raycast(nokta + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0))
	local zemin = if hit then hit.Position.Y else nokta.Y - 3

	local model = Instance.new("Model")
	model.Name = ad

	local tezgah = Instance.new("Part")
	tezgah.Name = "Tezgah"
	tezgah.Size = Vector3.new(8, 4, 4)
	tezgah.Position = Vector3.new(nokta.X, zemin + 2, nokta.Z)
	tezgah.Anchored = true
	tezgah.Color = cfg.color
	tezgah.Material = Enum.Material.WoodPlanks
	tezgah.Parent = model
	model.PrimaryPart = tezgah

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Tabela"
	billboard.Size = UDim2.fromOffset(240, 44)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.MaxDistance = 120
	billboard.Parent = tezgah

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Fonts.bold
	label.Text = baslik
	label.TextColor3 = cfg.color
	label.TextSize = 20
	label.TextStrokeTransparency = 0.4
	label.Parent = billboard

	model.Parent = Workspace
	return tezgah
end

-- Oyuncu bu NPC'nin yaninda mi
local function yakinda(player: Player, anahtar: string): boolean
	local anchor = anchors[anahtar]
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not anchor or not root or not root:IsA("BasePart") then
		return false
	end
	return (root.Position - anchor.Position).Magnitude <= ISTEK_MESAFE
end

------------------------------------------------------------------
-- PANEL VERISI
------------------------------------------------------------------
local function madenListesi(data: any, cfg: Ores.IslandOres)
	local liste = {}
	for _, id in cfg.ores do
		local info = Ores.Info[id]
		table.insert(liste, {
			id = id,
			displayName = info.displayName,
			count = data.ores[id] or 0,
			color = info.color,
		})
	end
	return liste
end

local function kurekPayload(player: Player, ada: string)
	local data = PlayerData.get(player)
	local cfg = Ores.island(ada)
	if not data or not cfg then
		return nil
	end

	local enYuksek = Shovels.get(data.shovelMax).level

	local liste = {}
	for _, info in Shovels.forIsland(ada) do
		table.insert(liste, {
			id = info.id,
			displayName = info.displayName,
			level = info.level,
			price = info.price,
			oreCost = info.oreCost or 0,
			color = info.color,
			owned = info.level <= enYuksek,
			equipped = data.shovel == info.id,
			-- Sirayla alinir: yalnizca bir sonraki seviye
			buyable = info.level == enYuksek + 1,
		})
	end

	return {
		island = ada,
		name = cfg.name,
		color = cfg.color,
		rot = data.rot,
		shovels = liste,
		ores = madenListesi(data, cfg),
	}
end

local function kazmaPayload(player: Player, ada: string)
	local data = PlayerData.get(player)
	local cfg = Ores.island(ada)
	if not data or not cfg then
		return nil
	end

	local kazma = Ores.Pickaxes[cfg.pickaxe]

	return {
		island = ada,
		name = cfg.name,
		color = cfg.color,
		rot = data.rot,
		tradeCost = Ores.TradeCost,
		pickaxe = {
			id = kazma.id,
			displayName = kazma.displayName,
			price = kazma.price,
			owned = data.pickaxes[kazma.id] == true,
		},
		ores = madenListesi(data, cfg),
	}
end

------------------------------------------------------------------
-- KUREK SATIN ALMA / KUSANMA
------------------------------------------------------------------
AdaKurekAl.OnServerEvent:Connect(function(player, shovelId)
	if type(shovelId) ~= "string" then
		return
	end

	local info = Shovels.Info[shovelId]
	if not info or not info.island then
		return
	end

	local ada = info.island :: string
	if not yakinda(player, `{ada}|kurek`) then
		return
	end

	local data = PlayerData.get(player)
	local cfg = Ores.island(ada)
	if not data or not cfg then
		return
	end

	local enYuksek = Shovels.get(data.shovelMax)

	-- Sahip olunan seviye: ucretsiz kusanma
	if info.level <= enYuksek.level then
		if data.shovel == info.id then
			Bildirim:FireClient(player, `{info.displayName} is already equipped.`, Color3.fromRGB(180, 200, 220))
			return
		end

		data.shovel = info.id
		kurekYenile:Fire(player)
		Envanter.push(player)
		AdaKurekAc:FireClient(player, kurekPayload(player, ada))
		Bildirim:FireClient(player, `{info.displayName} equipped.`, info.color)
		return
	end

	if info.level ~= enYuksek.level + 1 then
		Bildirim:FireClient(player, "Buy the previous shovel first.", UYARI)
		return
	end

	if data.rot < info.price then
		Bildirim:FireClient(player, `Not enough Rot! {info.displayName} costs {Format.short(info.price)} Rot.`, HATA)
		return
	end

	local bedel = info.oreCost or 0
	for _, id in cfg.ores do
		if (data.ores[id] or 0) < bedel then
			Bildirim:FireClient(
				player,
				`Not enough {Ores.Info[id].displayName}! You need {bedel} (you have {data.ores[id] or 0}).`,
				HATA
			)
			return
		end
	end

	PlayerData.addRot(player, -info.price)
	for _, id in cfg.ores do
		PlayerData.addOre(player, id, -bedel)
	end

	data.shovel = info.id
	data.shovelMax = info.id
	kurekYenile:Fire(player)

	Envanter.push(player)
	AdaKurekAc:FireClient(player, kurekPayload(player, ada))
	Bildirim:FireClient(player, `{info.displayName} purchased!`, info.color)
end)

------------------------------------------------------------------
-- KAZMA SATIN ALMA
------------------------------------------------------------------
KazmaAl.OnServerEvent:Connect(function(player, pickaxeId)
	if type(pickaxeId) ~= "string" then
		return
	end

	local kazma = Ores.Pickaxes[pickaxeId]
	if not kazma then
		return
	end

	if not yakinda(player, `{kazma.island}|kazma`) then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	if data.pickaxes[kazma.id] then
		Bildirim:FireClient(player, `You already own the {kazma.displayName}.`, Color3.fromRGB(180, 200, 220))
		return
	end

	if data.rot < kazma.price then
		Bildirim:FireClient(player, `Not enough Rot! {kazma.displayName} costs {Format.short(kazma.price)} Rot.`, HATA)
		return
	end

	PlayerData.addRot(player, -kazma.price)
	data.pickaxes[kazma.id] = true

	Envanter.push(player)
	KazmaAc:FireClient(player, kazmaPayload(player, kazma.island))
	Bildirim:FireClient(player, `{kazma.displayName} purchased! Click on ores to mine them.`, kazma.color)
end)

------------------------------------------------------------------
-- MADEN TAKASI
--
-- Diger iki madenden TradeCost'ar tane verilir, istenen madenden 1 alinir.
------------------------------------------------------------------
MadenTakas.OnServerEvent:Connect(function(player, oreId)
	if type(oreId) ~= "string" then
		return
	end

	local maden = Ores.get(oreId)
	if not maden then
		return
	end

	local cfg = Ores.island(maden.island)
	if not cfg or not yakinda(player, `{maden.island}|kazma`) then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local digerleri = {}
	for _, id in cfg.ores do
		if id ~= oreId then
			table.insert(digerleri, id)
		end
	end

	for _, id in digerleri do
		if (data.ores[id] or 0) < Ores.TradeCost then
			Bildirim:FireClient(
				player,
				`You need {Ores.TradeCost} {Ores.Info[id].displayName} to trade for {maden.displayName}.`,
				UYARI
			)
			return
		end
	end

	for _, id in digerleri do
		PlayerData.addOre(player, id, -Ores.TradeCost)
	end
	local adet = PlayerData.addOre(player, oreId, 1)

	Envanter.push(player)
	KazmaAc:FireClient(player, kazmaPayload(player, maden.island))
	Bildirim:FireClient(player, `Traded for 1 {maden.displayName} (x{adet})`, maden.color)
end)

------------------------------------------------------------------
-- PROMPTLAR
------------------------------------------------------------------
local function promptTak(anchor: BasePart, ad: string, nesne: string, tetik: (Player) -> ())
	local eski = anchor:FindFirstChild(ad)
	if eski then
		eski:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = ad
	prompt.ActionText = "Buy"
	prompt.ObjectText = nesne
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = PROMPT_MESAFE
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = anchor

	prompt.Triggered:Connect(tetik)
end

local function saticiKur(ada: string, npcAdi: string, baslik: string, kayma: Vector3): BasePart?
	local cfg = Ores.island(ada) :: Ores.IslandOres

	local anchor = findAnchor(npcAdi)
	if not anchor then
		warn(`[AdaSatici] '{npcAdi}' haritada bulunamadi -- {cfg.name} spawn noktasinin yanina yedek tezgah kuruldu`)
		anchor = standKur(npcAdi, baslik, cfg, kayma)
	end

	if not anchor then
		warn(`[AdaSatici] '{npcAdi}' kurulamadi: {cfg.spawnPart} bulunamadi`)
	end

	return anchor
end

local function kur()
	for _, ada in Ores.IslandOrder do
		local cfg = Ores.island(ada) :: Ores.IslandOres
		local kazma = Ores.Pickaxes[cfg.pickaxe]

		local kurekBaslik = `{cfg.name} Shovels`
		local kurek = saticiKur(ada, cfg.shovelSeller, kurekBaslik, Vector3.new(12, 0, 8))
		if kurek then
			anchors[`{ada}|kurek`] = kurek
			promptTak(kurek, "AdaKurekPrompt", kurekBaslik, function(player)
				local payload = kurekPayload(player, ada)
				if payload then
					AdaKurekAc:FireClient(player, payload)
				end
			end)
		end

		local kazmaBaslik = `{kazma.displayName} Seller`
		local satici = saticiKur(ada, cfg.pickaxeSeller, kazmaBaslik, Vector3.new(-12, 0, 8))
		if satici then
			anchors[`{ada}|kazma`] = satici
			promptTak(satici, "KazmaPrompt", kazmaBaslik, function(player)
				local payload = kazmaPayload(player, ada)
				if payload then
					KazmaAc:FireClient(player, payload)
				end
			end)
		end
	end

	print("[AdaSatici] Ada saticilari kuruldu")
end

task.spawn(kur)
