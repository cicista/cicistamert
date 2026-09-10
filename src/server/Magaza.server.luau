--[[
	Magaza  (Script)
	Yeri: ServerScriptService > Magaza

	Kurek magazasi. Workspace'teki "Shop" modeline prompt takar.

	Tek kurek kurali: yeni kurek alindiginda eskisi envanterden silinir,
	yerine yenisi gecer (PlayerData.shovel tek bir id tutar).
	Kurekler sirayla alinir -- Lv.2 almadan Lv.3 alinamaz.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Shovels = require(Shared:WaitForChild("Shovels"))
local Detectors = require(Shared:WaitForChild("Detectors"))
local Format = require(Shared:WaitForChild("Format"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Net = require(Shared:WaitForChild("Net"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))

local Bildirim = Net.event("Bildirim")
local MagazaAc = Net.event("MagazaAc")
local KurekAl = Net.event("KurekAl")
local GPSAl = Net.event("GPSAl")

-- KaziSistemi'ndeki kurek yenileme tetigi
local kaziSistemi = script.Parent:WaitForChild("KaziSistemi")
local kurekYenile = kaziSistemi:WaitForChild("KurekYenile") :: BindableEvent

local function shovelList(player: Player)
	local data = PlayerData.get(player)
	local currentLevel = if data then Shovels.get(data.shovel :: any).level else 1

	local out = {}
	for _, id in Shovels.Order do
		local info = Shovels.get(id)
		table.insert(out, {
			id = info.id,
			displayName = info.displayName,
			level = info.level,
			rarity = info.rarity,
			price = info.price,
			digSpeed = info.digSpeed,
			barSize = info.barSize,
			owned = info.level <= currentLevel,
			-- Sadece bir sonraki kurek satin alinabilir
			buyable = info.level == currentLevel + 1,
		})
	end
	return out
end

local function detectorList(player: Player)
	local data = PlayerData.get(player)
	local currentLevel = if data then Detectors.get(data.detector :: any).level else 1

	local out = {}
	for _, id in Detectors.Order do
		local info = Detectors.get(id)
		table.insert(out, {
			id = info.id,
			displayName = info.displayName,
			level = info.level,
			rarity = info.rarity,
			price = info.price,
			luck = info.luck,
			scanRadius = info.scanRadius,
			owned = info.level <= currentLevel,
			buyable = info.level == currentLevel + 1,
		})
	end
	return out
end

local function shopPayload(player: Player)
	return {
		shovels = shovelList(player),
		detectors = detectorList(player),
	}
end

------------------------------------------------------------------
-- SATIN ALMA
------------------------------------------------------------------
KurekAl.OnServerEvent:Connect(function(player, shovelId)
	if type(shovelId) ~= "string" then
		return
	end

	local info = Shovels.Info[shovelId]
	if not info then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local current = Shovels.get(data.shovel :: any)

	if info.level <= current.level then
		Bildirim:FireClient(player, "You already own this shovel.", Color3.fromRGB(255, 200, 90))
		return
	end

	if info.level ~= current.level + 1 then
		Bildirim:FireClient(player, "Buy the previous shovel first.", Color3.fromRGB(255, 200, 90))
		return
	end

	if data.rot < info.price then
		Bildirim:FireClient(
			player,
			`Not enough Rot! {info.displayName} costs {Format.short(info.price)} Rot.`,
			Color3.fromRGB(255, 90, 90)
		)
		return
	end

	PlayerData.addRot(player, -info.price)

	-- Eski kurek silinir, yenisi gecer
	data.shovel = info.id
	kurekYenile:Fire(player)

	Envanter.push(player)
	MagazaAc:FireClient(player, shopPayload(player))

	Bildirim:FireClient(
		player,
		`{info.displayName} purchased! Your old shovel is gone.`,
		Rarity.color(info.rarity)
	)
end)

--[[
	Dedektor (GPS) satin alma.
	Kurekle ayni kural: tek dedektor tasinir, sirayla yukseltilir.
	Yuksek seviye dedektor yuksek rarity suzme sansini artirir.
]]
GPSAl.OnServerEvent:Connect(function(player, detectorId)
	if type(detectorId) ~= "string" then
		return
	end

	local info = Detectors.Info[detectorId]
	if not info then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local current = Detectors.get(data.detector :: any)

	if info.level <= current.level then
		Bildirim:FireClient(player, "You already own this detector.", Color3.fromRGB(255, 200, 90))
		return
	end

	if info.level ~= current.level + 1 then
		Bildirim:FireClient(player, "Buy the previous detector first.", Color3.fromRGB(255, 200, 90))
		return
	end

	if data.rot < info.price then
		Bildirim:FireClient(
			player,
			`Not enough Rot! {info.displayName} costs {Format.short(info.price)} Rot.`,
			Color3.fromRGB(255, 90, 90)
		)
		return
	end

	PlayerData.addRot(player, -info.price)

	data.detector = info.id
	Envanter.giveGPS(player)

	Envanter.push(player)
	MagazaAc:FireClient(player, shopPayload(player))

	Bildirim:FireClient(
		player,
		`{info.displayName} purchased! Luck multiplier x{info.luck}`,
		Rarity.color(info.rarity)
	)
end)

------------------------------------------------------------------
-- MAGAZA PROMPTU
------------------------------------------------------------------
--[[
	MAGAZA NPC'SI

	Haritadaki model her yerde ayni adla durmuyor; kabul edilen adlar
	asagida. Aranan sey MODEL OLMAK ZORUNDA DEGIL:

	  - Model  -> PrimaryPart, HumanoidRootPart ya da icindeki ilk parca
	  - Folder -> icindeki ilk parca (ic ice olsa da bulunur)
	  - Part   -> kendisi

	Onceden yalnizca Model kabul ediliyor ve parca aramasi da yalnizca
	DOGRUDAN cocuklara bakiyordu. NPC bir Folder'sa ya da parcalari alt
	modellerin icindeyse prompt hic kurulamiyor, magaza acilmiyordu.
]]
local MAGAZA_ADLARI = { "Shop", "Shopkeeper", "ShovelShop", "Magaza", "KurekMagazasi" }

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

	-- Model, Folder ya da baska bir kap: ICINDEKI ilk parca (derin arama)
	local part = node:FindFirstChildWhichIsA("BasePart", true)
	return part
end

--[[
	Ad karsilastirmasi BUYUK/KUCUK HARF ve bosluk gozetmez: haritada
	"SHOP", "Shop " ya da "shop" yazsa da bulunur. NPC'ler MAIN ISLAND gibi
	bir modelin icinde durabilir, o yuzden arama butun Workspace'i tarar.
]]
local function adEsit(a: string, b: string): boolean
	return string.lower(string.gsub(a, "%s", "")) == string.lower(string.gsub(b, "%s", ""))
end

local function findShopAnchor(): BasePart?
	for _, name in MAGAZA_ADLARI do
		for _, node in Workspace:GetDescendants() do
			if not adEsit(node.Name, name) then
				continue
			end

			local anchor = anchorFrom(node)
			if anchor then
				return anchor
			end
		end
	end

	return nil
end

local function attachPrompt()
	local anchor = findShopAnchor()

	if not anchor then
		--[[
			Haritada magaza yoksa Kaptan'in yanina basit bir tezgah kurulur.
			Bu bir YEDEK: normalde haritadaki model bulunur ve prompt ona
			takilir. Output'ta bu uyariyi goruyorsan model adi listede yok.
		]]
		warn(
			`[Magaza] Su adlarla model bulunamadi: {table.concat(MAGAZA_ADLARI, ", ")}`
				.. " -- yedek tezgah kuruldu"
		)

		local stand = Instance.new("Part")
		stand.Name = "KurekMagazasi"
		stand.Size = Vector3.new(6, 5, 4)
		stand.Position = Vector3.new(0, 5, -40)
		stand.Anchored = true
		stand.Color = Color3.fromRGB(72, 96, 124)
		stand.Material = Enum.Material.WoodPlanks
		stand.Parent = Workspace
		anchor = stand
	end

	local existing = anchor:FindFirstChild("MagazaPrompt")
	if existing then
		existing:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "MagazaPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = "Shovel Shop"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = anchor

	prompt.Triggered:Connect(function(player)
		MagazaAc:FireClient(player, shopPayload(player))
	end)

	print(`[Magaza] Prompt kuruldu: {anchor:GetFullName()}`)
end

task.spawn(attachPrompt)

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		local deadline = os.clock() + 10
		while not PlayerData.get(player) and os.clock() < deadline do
			task.wait(0.2)
		end
	end)
end)
