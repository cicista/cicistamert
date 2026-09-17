--!strict
--[[
	OLTA SATICISI  (Script)
	Yeri: ServerScriptService > Olta

	RodSeller NPC'sinde 5 kademelik olta satilir. Kurallar kurek, dedektor
	ve flyboardla ayni:

	  - tek olta tasinir, sirayla yukseltilir
	  - alinan kademeler KALICI: saticidan istenilen zaman geri kusanilir
	  - satin alma en yuksek kademeye bakar

	Oltanin ne ise yaradigi Shared > Rods icinde: denizde flyboardla
	gezerken girdap dogurur, kademesi girdaplarin kademesini belirler.
	Elde tutma isini Flyboard yapiyor (binince verilir, inince alinir).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Rods = require(Shared:WaitForChild("Rods"))
local Shovels = require(Shared:WaitForChild("Shovels"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))

local Bildirim = Net.event("Bildirim")
local RodAc = Net.event("RodAc")
local RodAl = Net.event("RodAl")

------------------------------------------------------------------
-- PANEL VERISI
------------------------------------------------------------------
-- Oyuncunun en iyi kureginin seviyesi (ilk oltanin sarti icin)
local function kurekSeviyesi(data: any): number
	local info = data and Shovels.Info[data.shovelMax]
	return if info then info.level else 1
end

local function payload(player: Player)
	local data = PlayerData.get(player)
	local kusanilan = data and data.rod or nil
	local enYuksek = Rods.level(data and data.rodMax or nil)
	local kurekYetmiyor = kurekSeviyesi(data) < Rods.RequiredShovelLevel

	local liste = {}
	for _, id in Rods.Order do
		local info = Rods.Info[id]
		table.insert(liste, {
			id = info.id,
			displayName = info.displayName,
			level = info.level,
			rarity = info.rarity,
			price = info.price,
			luck = info.luck,
			scanRadius = info.scanRadius,
			color = info.color,
			owned = enYuksek >= info.level,
			equipped = kusanilan == info.id,
			-- Sirayla alinir: yalnizca bir sonraki kademe satin alinabilir
			next = enYuksek + 1 == info.level,
			-- Ilk olta: Lv20 kurek sarti karsilanmadiysa yazilir
			needs = if info.level == 1 and enYuksek < 1 and kurekYetmiyor
				then `Requires a Lv{Rods.RequiredShovelLevel} shovel`
				else nil,
		})
	end

	return {
		rot = if data then data.rot else 0,
		owned = kusanilan,
		rods = liste,
	}
end

------------------------------------------------------------------
-- SATIN ALMA / KUSANMA
------------------------------------------------------------------
RodAl.OnServerEvent:Connect(function(player, id)
	if type(id) ~= "string" then
		return
	end

	local info = Rods.get(id)
	local data = PlayerData.get(player)
	if not info or not data then
		return
	end

	local enYuksek = Rods.level(data.rodMax)

	-- Sahip olunan kademe: satin alma degil, ucretsiz kusanma
	if info.level <= enYuksek then
		if data.rod == info.id then
			Bildirim:FireClient(player, `{info.displayName} is already equipped.`, Color3.fromRGB(180, 200, 220))
			return
		end

		data.rod = info.id
		RodAc:FireClient(player, payload(player))
		Bildirim:FireClient(player, `{info.displayName} equipped.`, Rarity.color(info.rarity))

		--[[
			Denizdeyse elindeki olta hemen yenisiyle degissin: equipRod
			eldekini birakip yeni kademeyi kuruyor.
		]]
		-- Yalnizca flyboardla denizdeyse ele gelir; karada olta elde durmaz
		if player:GetAttribute("Flyboarding") == true then
			Envanter.removeRod(player)
			Envanter.equipRod(player)
		end
		return
	end

	if info.level ~= enYuksek + 1 then
		Bildirim:FireClient(player, "Buy the previous rod first.", Color3.fromRGB(255, 200, 90))
		return
	end

	if info.level == 1 and kurekSeviyesi(data) < Rods.RequiredShovelLevel then
		Bildirim:FireClient(
			player,
			`You need a Lv{Rods.RequiredShovelLevel} shovel before your first rod! (yours: Lv{kurekSeviyesi(data)})`,
			Color3.fromRGB(255, 90, 90)
		)
		return
	end

	if data.rot < info.price then
		Bildirim:FireClient(
			player,
			`Not enough Rot! You need {Format.short(info.price - data.rot)} more Rot for {info.displayName}.`,
			Color3.fromRGB(255, 90, 90)
		)
		return
	end

	PlayerData.addRot(player, -info.price)
	data.rod = info.id
	data.rodMax = info.id

	Envanter.push(player)
	RodAc:FireClient(player, payload(player))

	Bildirim:FireClient(player, `{info.displayName} purchased!`, Rarity.color(info.rarity))

	-- Denizdeyse yeni olta hemen ele gelsin; karadayken ele HIC gelmez
	if player:GetAttribute("Flyboarding") == true then
		Envanter.removeRod(player)
		Envanter.equipRod(player)
	end
end)

------------------------------------------------------------------
-- NPC
--
-- Ad eslesmesi diger saticilarla ayni sagliktadir: buyuk/kucuk harf ve
-- bosluk gozetmez, Model / Folder / Part kabul eder.
------------------------------------------------------------------
local SATICI_ADLARI = { "RodSeller", "OltaSatici", "Rod Seller" }

local function adEsit(a: string, b: string): boolean
	return string.lower(string.gsub(a, "%s", "")) == string.lower(string.gsub(b, "%s", ""))
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

local function attachPrompt()
	local anchor: BasePart? = nil

	for _, name in SATICI_ADLARI do
		for _, node in Workspace:GetDescendants() do
			if adEsit(node.Name, name) then
				anchor = anchorFrom(node)
				if anchor then
					break
				end
			end
		end
		if anchor then
			break
		end
	end

	if not anchor then
		warn(`[Olta] Satici bulunamadi: {table.concat(SATICI_ADLARI, ", ")}`)
		return
	end

	local existing = anchor:FindFirstChild("RodPrompt")
	if existing then
		existing:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RodPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = "Rod Seller"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = anchor

	prompt.Triggered:Connect(function(player)
		RodAc:FireClient(player, payload(player))
	end)

	print(`[Olta] Satici promptu kuruldu: {anchor:GetFullName()}`)
end

task.spawn(attachPrompt)
