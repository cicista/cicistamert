--[[
	Detective  (Script)
	Yeri: ServerScriptService > Detective

	Brainrot Detective NPC'si.

	Kazidan cikan brainrot envantere SIMSIYAH gelir: oyuncu sadece rarity'sini
	ve kondisyonunu gorur, hangi brainrot oldugunu bilmez. Bu NPC'ye teslim
	edilince inceleme suresi sonunda brainrot'un kimligi ortaya cikar ve
	normal haliyle envantere doner.

	Acilan brainrot artik base slotuna konabilir ve saniyelik gelir uretir.

	TOPLU INCELEME
	  Oyuncu kimligi belirlenmemis BUTUN brainrotlarini tek seferde birakir.
	  Bekleme suresi hepsinin (Rarity.revealTime) TOPLAMIDIR. Is oyuncu
	  verisine yazilir (PlayerData.detectiveJob): oyuncu yanindan ayrilabilir,
	  oyundan cikip girse bile sure islemeye devam eder. Sure dolunca hepsi
	  birden acilir. Is surerken yeni teslim alinmaz.

	SECEREK INCELEME
	  Istemci DetectiveTeslim ile uid listesi yollarsa yalnizca o
	  brainrotlar birakilir (tek bir tane de olabilir); liste yoksa hepsi.
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
local DetectiveDurum = Net.event("DetectiveDurum")

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

-- Panel acma asagida tanimli (toplu inceleme bolumu); prompt ondan once kuruluyor
local panelAc: (player: Player) -> ()

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
		panelAc(player)
	end)
end

------------------------------------------------------------------
-- TOPLU INCELEME
------------------------------------------------------------------
local function sureYazisi(saniye: number): string
	local t = math.max(0, math.ceil(saniye))
	return string.format("%d:%02d", t // 60, t % 60)
end

-- Kimligi belirlenmemis brainrotlar (sure = kademesinin acilma suresi)
local function bekleyenler(data: any): { any }
	local out = {}
	for _, item in data.inventory do
		if not item.revealed then
			table.insert(out, {
				uid = item.uid,
				rarity = item.rarity,
				condition = item.condition,
				mutation = item.mutation,
				sure = Rarity.get(item.rarity :: any).revealTime,
			})
		end
	end
	return out
end

-- Istemciye giden is ozeti; is yoksa nil
local function isOzeti(data: any): any?
	local is = data.detectiveJob
	if not is then
		return nil
	end
	return {
		kalan = math.max(0, is.bitis - os.time()),
		toplam = is.toplam,
		adet = #is.uids,
	}
end

function panelAc(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	local liste = bekleyenler(data)
	local is = isOzeti(data)
	if #liste == 0 and not is then
		Bildirim:FireClient(player, "You have no unidentified brainrots.", Color3.fromRGB(255, 200, 90))
		return
	end

	DetectiveAc:FireClient(player, { pending = liste, job = is })
end

-- Sure doldu: isteki butun brainrotlar birden acilir
local function isiBitir(player: Player, data: any)
	local is = data.detectiveJob
	data.detectiveJob = nil
	if not is then
		return
	end

	local sonuclar = {}
	for _, uid in is.uids do
		local current = PlayerData.findItem(player, uid)
		-- Bu arada satilmis / makineye konmus / zaten acilmis olabilir
		if not current or current.revealed then
			continue
		end

		--[[
			Rarity sabit kalir; hangi brainrot oldugu simdi belli olur. Isim
			KAZILDIGI ADANIN listesinden seciliyor (eski kayitlarda ada yok,
			nil gelirse butun havuza dusuluyor).
		]]
		local picked = Brainrots.rollIsland(current.rarity :: any, current.island, rng)
		current.name = picked.name
		current.revealed = true

		table.insert(sonuclar, {
			uid = uid,
			name = picked.name,
			rarity = current.rarity,
			condition = current.condition,
			mutation = current.mutation,
			income = Brainrots.income(picked.name, current.condition :: any, current.mutation :: any),
		})
	end

	Envanter.syncBrainrots(player)
	Envanter.push(player)
	DetectiveSonuc:FireClient(player, sonuclar)
	DetectiveDurum:FireClient(player, nil)

	if #sonuclar > 0 then
		-- En degerlisi bildirimde yazar
		local enIyi = sonuclar[1]
		for _, sonuc in sonuclar do
			if sonuc.income > enIyi.income then
				enIyi = sonuc
			end
		end
		local special = Mutations.isSpecial(enIyi.mutation)
		Bildirim:FireClient(
			player,
			`Detective identified {#sonuclar} brainrot(s)! Best: {enIyi.name} ({Format.perSecond(enIyi.income)})`,
			if special then Mutations.color(enIyi.mutation) else Rarity.color(enIyi.rarity)
		)
	end
end

DetectiveTeslim.OnServerEvent:Connect(function(player, secilen)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	local mevcut = isOzeti(data)
	if mevcut then
		Bildirim:FireClient(
			player,
			`The Detective is still working ({sureYazisi(mevcut.kalan)} left).`,
			Color3.fromRGB(255, 200, 90)
		)
		DetectiveDurum:FireClient(player, mevcut)
		return
	end

	local liste = bekleyenler(data)

	-- Secim geldiyse yalnizca secilenler (istemciye guvenilmez: listede olmayan uid atlanir)
	if type(secilen) == "table" then
		local istenen: { [string]: boolean } = {}
		local sayi = 0
		for _, uid in secilen do
			if type(uid) == "string" and sayi < 500 then
				istenen[uid] = true
				sayi += 1
			end
		end

		local suzulen = {}
		for _, item in liste do
			if istenen[item.uid] then
				table.insert(suzulen, item)
			end
		end
		liste = suzulen
	end

	if #liste == 0 then
		Bildirim:FireClient(player, "You have no unidentified brainrots.", Color3.fromRGB(255, 200, 90))
		return
	end

	local toplam = 0
	local uids = {}
	for _, item in liste do
		toplam += item.sure
		table.insert(uids, item.uid)
	end
	toplam = math.max(1, math.ceil(toplam))

	data.detectiveJob = { bitis = os.time() + toplam, toplam = toplam, uids = uids }
	DetectiveDurum:FireClient(player, isOzeti(data))
	Bildirim:FireClient(
		player,
		`Detective is identifying {#uids} brainrot(s) ({sureYazisi(toplam)}). You can leave!`,
		Color3.fromRGB(255, 236, 180)
	)
end)

-- Suresi dolan isler (oyuncu nerede olursa olsun)
task.spawn(function()
	while true do
		task.wait(1)
		local simdi = os.time()
		for _, player in Players:GetPlayers() do
			local data = PlayerData.get(player)
			local is = data and data.detectiveJob
			if is and simdi >= is.bitis then
				local ok, hata = pcall(isiBitir, player, data)
				if not ok then
					warn(`[Detective] {player.Name} isi bitirilemedi: {tostring(hata)}`)
				end
			end
		end
	end
end)

-- Oyuna donen oyuncu suren isini gorsun
Players.PlayerAdded:Connect(function(player)
	task.delay(4, function()
		local data = player.Parent and PlayerData.get(player)
		if data and data.detectiveJob then
			DetectiveDurum:FireClient(player, isOzeti(data))
		end
	end)
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
