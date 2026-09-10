--[[
	SlotMakinesi  (Script)
	Yeri: ServerScriptService > SlotMakinesi

	Rot Coin atilan slot makinesi. Cikan odul tamamen rastgele bir TOOL SKINI:
	kurege de gps'e de cikabilir -- havuz tek, tool ayrimi yapilmaz.

	Rot Coin yalnizca kazi sirasinda binde bir cikan sari-siyah isik
	suzmesinden gelir (bkz. Rarity.RotCoin).

	Ayni skin ikinci kez cikarsa Rot Coin olarak geri odenir.

	RULET IKI ASAMALIDIR (Lucky Block carkiyla ayni)
	  1. asama  Bolmelerde yalnizca "?" ve kademe rengi vardir; durunca
	            hangi KADEMENIN ciktigi belli olur.
	  2. asama  Serit yeniden kurulur, bu kez sadece o kademedeki skinler
	            doner ve odul aciga cikar.

	Sunucu yalnizca sonucu ve kademeyi gonderir; seridi istemci kendi kurar
	(Skins katalogu paylasimli). Zamanlama Skins.Wheel'den gelir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))
local Skins = require(Shared:WaitForChild("Skins"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Net = require(Shared:WaitForChild("Net"))
local Fonts = require(Shared:WaitForChild("Fonts"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))

local Bildirim = Net.event("Bildirim")
local SlotMakinesiAc = Net.event("SlotMakinesiAc")
local SlotMakinesiCevir = Net.event("SlotMakinesiCevir")
local SlotMakinesiSonuc = Net.event("SlotMakinesiSonuc")
local SkinTak = Net.event("SkinTak")
local SkinDongu = Net.event("SkinDongu")

local M = Config.SlotMachine
local rng = Random.new()

-- Ayni anda tek cevirim
local spinning: { [Player]: boolean } = {}

------------------------------------------------------------------
-- MAKINE KURULUMU
------------------------------------------------------------------
local function buildMachine(): Model
	local model = Instance.new("Model")
	model.Name = M.name

	local body = Instance.new("Part")
	body.Name = "Govde"
	body.Size = Vector3.new(5, 8, 3)
	body.Position = M.spawnPosition
	body.Anchored = true
	body.Color = Color3.fromRGB(180, 40, 52)
	body.Material = Enum.Material.Metal
	body.Parent = model
	model.PrimaryPart = body

	local screen = Instance.new("Part")
	screen.Name = "Ekran"
	screen.Size = Vector3.new(3.6, 2.4, 0.2)
	screen.Position = M.spawnPosition + Vector3.new(0, 1.6, -1.6)
	screen.Anchored = true
	screen.CanCollide = false
	screen.Color = Color3.fromRGB(255, 214, 41)
	screen.Material = Enum.Material.Neon
	screen.Parent = model

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 214, 41)
	light.Range = 18
	light.Brightness = 2
	light.Parent = screen

	local sign = Instance.new("BillboardGui")
	sign.Name = "Tabela"
	sign.Size = UDim2.new(0, 190, 0, 44)
	sign.StudsOffset = Vector3.new(0, 5.5, 0)
	sign.AlwaysOnTop = false
	sign.MaxDistance = 90
	sign.Parent = body

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Fonts.bold
	label.Text = "ROT SLOTS"
	label.TextColor3 = Color3.fromRGB(255, 214, 41)
	label.TextSize = 22
	label.TextScaled = false
	label.TextStrokeTransparency = 1
	label.Parent = sign

	model.Parent = Workspace
	return model
end

local function findMachine(): Model?
	local existing = Workspace:FindFirstChild(M.name, true)
	if existing and existing:IsA("Model") then
		return existing
	end
	return nil
end

local function attachPrompt(model: Model)
	local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if not anchor then
		warn("[SlotMakinesi] tutunulacak Part bulunamadi")
		return
	end

	local existing = anchor:FindFirstChildOfClass("ProximityPrompt")
	if existing then
		existing:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = M.promptText
	prompt.ObjectText = M.promptSubText
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = M.promptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor

	prompt.Triggered:Connect(function(player)
		local data = PlayerData.get(player)
		if not data then
			return
		end
		SlotMakinesiAc:FireClient(player, {
			rotCoins = data.rotCoins,
			cost = Skins.SpinCost,
			skins = data.skins,
			equipped = data.equipped,
		})
	end)
end

------------------------------------------------------------------
-- CEVIRIM
------------------------------------------------------------------
SlotMakinesiCevir.OnServerEvent:Connect(function(player)
	if spinning[player] then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	if data.rotCoins < Skins.SpinCost then
		Bildirim:FireClient(player, "Not enough Rot Coins! Look for the yellow-black beam while digging.", Rarity.RotCoin.colorA)
		return
	end

	spinning[player] = true
	PlayerData.addRotCoins(player, -Skins.SpinCost)
	Envanter.push(player)

	local skin = Skins.roll(rng)
	local duplicate = data.skins[skin.id] == true
	local refund = if duplicate then Skins.SpinCost else 0

	--[[
		AKIS (Lucky Block carkiyla ayni)

		Sonuc hemen hesaplanip TEK mesajda gonderilir; istemci iki asamali
		ruleti kendi cizer (1. asama kademe, 2. asama o kademedeki skinler).
		Odul ve bildirim Skins.totalSpinTime() kadar bekletilir -- yani
		istemcinin cizim suresiyle AYNI kaynaktan gelir. Onceden ikisi ayri
		sabitlerdi ve bildirim rulet durmadan once cikip sonucu ele veriyordu.
	]]
	SlotMakinesiSonuc:FireClient(player, {
		id = skin.id,
		displayName = skin.displayName,
		tool = skin.tool,
		rarity = skin.rarity,
		color = skin.color,
		duplicate = duplicate,
		refund = refund,
	})

	task.delay(Skins.totalSpinTime(), function()
		spinning[player] = nil
		if not player.Parent then
			return
		end

		local current = PlayerData.get(player)
		if not current then
			return
		end

		if duplicate then
			PlayerData.addRotCoins(player, refund)
		else
			current.skins[skin.id] = true
		end

		Envanter.push(player)

		local toolLabel = if skin.tool == "Shovel" then "Shovel" else "GPS"
		if duplicate then
			Bildirim:FireClient(
				player,
				`You already own {skin.displayName} ({toolLabel}) -- +{refund} Rot Coin refunded`,
				Rarity.color(skin.rarity)
			)
		else
			Bildirim:FireClient(
				player,
				`NEW SKIN: {skin.displayName} ({toolLabel}, {skin.rarity})`,
				Rarity.color(skin.rarity)
			)
		end
	end)
end)

------------------------------------------------------------------
-- SKIN TAKMA
------------------------------------------------------------------
SkinTak.OnServerEvent:Connect(function(player, skinId)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	-- nil / false gonderilirse skin cikarilir
	if skinId == nil or skinId == false then
		data.equipped.Shovel = nil
		data.equipped.GPS = nil
		Envanter.push(player)
		return
	end

	if type(skinId) ~= "string" then
		return
	end

	local skin = Skins.get(skinId)
	if not skin then
		return
	end

	if not data.skins[skinId] then
		Bildirim:FireClient(player, "You do not own this skin.", Color3.fromRGB(255, 160, 60))
		return
	end

	data.equipped[skin.tool] = skinId
	Envanter.push(player)

	-- Takili tool varsa aninda yenile
	if skin.tool == "Shovel" then
		Envanter.giveShovel(player)
	elseif skin.tool == "GPS" then
		Envanter.giveGPS(player)
	end

	Bildirim:FireClient(player, `{skin.displayName} equipped.`, Rarity.color(skin.rarity))
end)

------------------------------------------------------------------
-- SKIN DONGUSU (Z)
--
-- Elde tutulan tool'un gorunumunu sirayla degistirir:
--   varsayilan -> sahip olunan 1. skin -> 2. skin -> ... -> varsayilan
-- Seviye parlamasi degismez, sadece govde gorunumu doner.
------------------------------------------------------------------
local Tools = require(Modules:WaitForChild("Tools"))

SkinDongu.OnServerEvent:Connect(function(player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	-- Hangi tool elde? Kurek mi dedektor mu
	local toolKind: Skins.SkinTool? = nil
	if Tools.equipped(player, Tools.ShovelName) then
		toolKind = "Shovel"
	elseif Tools.equipped(player, Tools.GPSName) then
		toolKind = "GPS"
	end

	if not toolKind then
		Bildirim:FireClient(player, "Hold your shovel or GPS to change its skin.", Color3.fromRGB(255, 200, 90))
		return
	end

	local cycle = Skins.ownedCycle(toolKind, data.skins)
	if #cycle <= 1 then
		Bildirim:FireClient(player, "You have no skins for this tool. Spin at Rot Slots!", Rarity.RotCoin.colorA)
		return
	end

	local nextSkin = Skins.nextInCycle(toolKind, data.skins, data.equipped[toolKind])
	data.equipped[toolKind] = nextSkin

	if toolKind == "Shovel" then
		Envanter.giveShovel(player)
	else
		Envanter.giveGPS(player)
	end

	Envanter.push(player)

	local label = if nextSkin then (Skins.get(nextSkin) :: any).displayName else "Varsayilan"
	local color = if nextSkin then Rarity.color((Skins.get(nextSkin) :: any).rarity) else Color3.fromRGB(200, 210, 225)
	Bildirim:FireClient(player, `Skin: {label}`, color)
end)

Players.PlayerRemoving:Connect(function(player)
	spinning[player] = nil
end)

------------------------------------------------------------------
-- BASLAT
------------------------------------------------------------------
task.spawn(function()
	local machine = findMachine()
	if not machine then
		machine = buildMachine()
	end
	attachPrompt(machine)
end)
