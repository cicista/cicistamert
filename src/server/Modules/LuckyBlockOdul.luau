--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Condition = require(Shared:WaitForChild("Condition"))
local Fonts = require(Shared:WaitForChild("Fonts"))
local Format = require(Shared:WaitForChild("Format"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))
local GorevTakip = require(script.Parent:WaitForChild("GorevTakip"))
local Seviye = require(script.Parent:WaitForChild("Seviye"))
local Tools = require(script.Parent:WaitForChild("Tools"))
local Sand = require(script.Parent:WaitForChild("Sand"))
local Patlama = require(script.Parent:WaitForChild("Patlama"))

local Bildirim = Net.event("Bildirim")
local LuckyBlockAc = Net.event("LuckyBlockAc")
local LuckyBlockSonuc = Net.event("LuckyBlockSonuc")
local LuckyBlockBasladi = Net.event("LuckyBlockBasladi")

local GIRIS_EN_FAZLA = 8
local carkBasladi: { [Player]: boolean } = {}

LuckyBlockBasladi.OnServerEvent:Connect(function(player)
	carkBasladi[player] = true
end)

local LuckyBlockOdul = {}

local rng = Random.new()

local opening: { [Player]: boolean } = {}

local function buildBlock(tierId: string): Model
	local tier = LuckyBlock.get(tierId)

	local ready = Assets.luckyBlockModel(tier.modelName, tier.order)
	if ready then
		return ready
	end

	local model = Instance.new("Model")

	local body = Instance.new("Part")
	body.Name = "Govde"
	body.Size = Vector3.new(3, 3, 3)
	body.Color = tier.color
	body.Material = Enum.Material.Neon
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model
	model.PrimaryPart = body

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(120, 60)
	sign.StudsOffset = Vector3.new(0, 1, 0)
	sign.AlwaysOnTop = true
	sign.Parent = body

	local mark = Instance.new("TextLabel")
	mark.Size = UDim2.fromScale(1, 1)
	mark.BackgroundTransparency = 1
	mark.Text = "?"
	mark.TextColor3 = Color3.fromRGB(40, 30, 0)
	mark.TextSize = 48
	mark.Parent = sign

	return model
end

local SES_ARALIGI = 0.3
local SES_KOPYA_NITELIGI = "LuckyBlockSesKopyasi"

local sesSablonu: Sound? = nil
local sesUyarildi = false
local sonSes = 0

local function luckySesAdi(ad: string): boolean
	local sade = string.lower((string.gsub(ad, "[%s_%-]", "")))
	return string.find(sade, "luckyblock", 1, true) ~= nil
end

local function luckySesi(): Sound?
	if sesSablonu then
		return sesSablonu
	end

	for _, kok in { Workspace :: Instance, SoundService, ReplicatedStorage } do
		for _, d in kok:GetDescendants() do
			if d:IsA("Sound") and luckySesAdi(d.Name) and not d:GetAttribute(SES_KOPYA_NITELIGI) then
				local sablon = d:Clone()
				sablon.Looped = false
				sablon:SetAttribute(SES_KOPYA_NITELIGI, true)
				sesSablonu = sablon
				return sablon
			end
		end
	end

	if not sesUyarildi then
		sesUyarildi = true
		warn('[LuckyBlock] No Sound with "Lucky Block" in its name was found (Workspace / SoundService / ReplicatedStorage). Continuing without sound.')
	end
	return nil
end

function LuckyBlockOdul.sesCal()
	local simdi = os.clock()
	if simdi - sonSes < SES_ARALIGI then
		return
	end

	local sablon = luckySesi()
	if not sablon then
		return
	end
	sonSes = simdi

	local ses = sablon:Clone()
	ses.Parent = Workspace
	ses:Play()
	ses.Ended:Once(function()
		ses:Destroy()
	end)
	Debris:AddItem(ses, 15)
end

function LuckyBlockOdul.showDrop(position: Vector3, tierId: string)
	local model = buildBlock(tierId)
	local primary = model.PrimaryPart
	if not primary then
		model:Destroy()
		return
	end

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	local origin = position + Vector3.new(0, 3, 0)
	model:PivotTo(CFrame.new(origin))
	model.Parent = Workspace

	Assets.playAnimations(model)

	LuckyBlockOdul.sesCal()

	local glow = Instance.new("PointLight")
	glow.Color = LuckyBlock.get(tierId).color
	glow.Range = 16
	glow.Brightness = 3
	glow.Parent = primary

	Debris:AddItem(model, 2.5)

	task.spawn(function()
		local t = 0
		while model.Parent and t < 2.4 do
			t += task.wait(0.03)
			model:PivotTo(
				CFrame.new(origin + Vector3.new(0, t * 1.6, 0)) * CFrame.Angles(0, t * 6, 0)
			)
		end
	end)
end

local eventFolder: Folder? = nil

local function blocksFolder(): Folder
	if eventFolder and eventFolder.Parent then
		return eventFolder
	end

	local existing = Workspace:FindFirstChild("LuckyBlocklar")
	if existing and existing:IsA("Folder") then
		eventFolder = existing
		return existing
	end

	local created = Instance.new("Folder")
	created.Name = "LuckyBlocklar"
	created.Parent = Workspace
	eventFolder = created
	return created
end

local function gorunumOf(tierId: string): any
	local g = LuckyBlock.Event.gorunum
	return g[tierId] or g.Normal or { olcek = 1, isik = 26 }
end

local function buildOzelSus(parent: BasePart, tier: any, gorunum: any)
	if gorunum.kivilcim then
		local ek = Instance.new("Attachment")
		ek.Name = "KivilcimNoktasi"
		ek.Parent = parent

		local kivilcim = Instance.new("ParticleEmitter")
		kivilcim.Name = "Kivilcim"
		kivilcim.Color = ColorSequence.new(Color3.new(1, 1, 1), tier.color)
		kivilcim.LightEmission = 1
		kivilcim.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(1, 0),
		})
		kivilcim.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		kivilcim.Lifetime = NumberRange.new(0.8, 1.6)
		kivilcim.Rate = 26
		kivilcim.Speed = NumberRange.new(2, 5)
		kivilcim.SpreadAngle = Vector2.new(180, 180)
		kivilcim.Rotation = NumberRange.new(0, 360)
		kivilcim.Parent = ek
	end

	if gorunum.halka then
		local halka = Instance.new("Part")
		halka.Name = "Halka"
		halka.Shape = Enum.PartType.Cylinder
		halka.Size = Vector3.new(0.4, 14, 14)
		halka.CFrame = parent.CFrame * CFrame.new(0, -3, 0) * CFrame.Angles(0, 0, math.rad(90))
		halka.Anchored = true
		halka.CanCollide = false
		halka.CastShadow = false
		halka.Material = Enum.Material.Neon
		halka.Color = tier.color
		halka.Transparency = 0.45
		halka.Parent = parent.Parent

		task.spawn(function()
			local t = 0
			while halka.Parent and parent.Parent do
				t += task.wait(0.05)
				halka.CFrame = parent.CFrame
					* CFrame.new(0, -3, 0)
					* CFrame.Angles(0, 0, math.rad(90))
					* CFrame.Angles(t * 0.8, 0, 0)
			end
		end)
	end
end

local KONI_KATMANLARI = {
	{ ad = "IsikDis", uc = 1.4, agiz = 1.3, renk = 1, saydamUc = 0.62, saydamAgiz = 0.86 },
	{ ad = "Isik", uc = 0.7, agiz = 1, renk = 0.45, saydamUc = 0.35, saydamAgiz = 0.66 },
	{ ad = "IsikCekirdek", uc = 0.25, agiz = 0.38, renk = 0, saydamUc = 0.1, saydamAgiz = 0.55 },
}

local KONI_DILIMLERI = {
	{ oran = 0.36, saydam = 0.78 },
	{ oran = 0.68, saydam = 0.74 },
	{ oran = 0.94, saydam = 0.66 },
}

local function koniDiski(parent: BasePart, ad: string, y: number, cap: number, renk: Color3, saydam: number)
	local disk = Instance.new("Part")
	disk.Name = ad
	disk.Shape = Enum.PartType.Cylinder
	disk.Size = Vector3.new(0.12, cap, cap)
	disk.CFrame = CFrame.new(parent.Position.X, y, parent.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
	disk.Anchored = true
	disk.CanCollide = false
	disk.CanQuery = false
	disk.CanTouch = false
	disk.CastShadow = false
	disk.Material = Enum.Material.Neon
	disk.Color = renk
	disk.Transparency = saydam
	disk.Parent = parent.Parent
end

local function buildBeacon(parent: BasePart, groundY: number, tier: any, gorunum: any)
	local E = LuckyBlock.Event
	local olcek = gorunum.olcek or 1
	local genislik = E.beaconWidth * olcek
	local yukseklik = parent.Position.Y - groundY
	local beyaz = Color3.new(1, 1, 1)

	local uc = Instance.new("Attachment")
	uc.Name = "KoniUc"
	uc.Position = Vector3.new(0, -yukseklik, 0)
	uc.Parent = parent

	local agiz = Instance.new("Attachment")
	agiz.Name = "KoniAgiz"
	agiz.Position = Vector3.new(0, 0, 0)
	agiz.Parent = parent

	for _, katman in KONI_KATMANLARI do
		local koni = Instance.new("Beam")
		koni.Name = katman.ad
		koni.Attachment0 = uc
		koni.Attachment1 = agiz
		koni.Width0 = katman.uc * olcek
		koni.Width1 = genislik * katman.agiz
		koni.FaceCamera = true
		koni.Color = ColorSequence.new(beyaz:Lerp(tier.color, katman.renk), beyaz:Lerp(tier.color, katman.renk * 0.6))
		koni.LightEmission = 1
		koni.LightInfluence = 0
		koni.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, katman.saydamUc),
			NumberSequenceKeypoint.new(0.5, (katman.saydamUc + katman.saydamAgiz) / 2 - 0.08),
			NumberSequenceKeypoint.new(1, katman.saydamAgiz),
		})
		koni.Segments = 8
		koni.Parent = parent
	end

	koniDiski(parent, "KoniTabani", groundY + 0.08, genislik * 0.55, tier.color, 0.5)
	koniDiski(parent, "KoniHalesi", groundY + 0.05, genislik * 1.1, tier.color, 0.82)
	for _, dilim in KONI_DILIMLERI do
		koniDiski(
			parent,
			"KoniDilimi",
			groundY + yukseklik * dilim.oran,
			math.max(0.4 * olcek, genislik * dilim.oran),
			beyaz:Lerp(tier.color, 0.5),
			dilim.saydam
		)
	end

	local yukselen = Instance.new("ParticleEmitter")
	yukselen.Name = "KoniParcaciklari"
	yukselen.Color = ColorSequence.new(beyaz, tier.color)
	yukselen.LightEmission = 1
	yukselen.LightInfluence = 0
	yukselen.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15 * olcek),
		NumberSequenceKeypoint.new(0.5, 0.45 * olcek),
		NumberSequenceKeypoint.new(1, 0),
	})
	yukselen.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.3, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	yukselen.Speed = NumberRange.new(3.5, 5)
	yukselen.Lifetime = NumberRange.new(yukseklik / 5, yukseklik / 3.5)
	yukselen.SpreadAngle = Vector2.new(22, 22)
	yukselen.Rotation = NumberRange.new(0, 360)
	yukselen.RotSpeed = NumberRange.new(-90, 90)
	yukselen.Rate = 14 * olcek
	yukselen.EmissionDirection = Enum.NormalId.Top
	yukselen.Parent = uc

	local light = Instance.new("PointLight")
	light.Color = beyaz:Lerp(tier.color, 0.4)
	light.Range = 26
	light.Brightness = 3
	light.Parent = parent
end

local etkinlikteAlan: { [Player]: number } = {}

local function spawnEventBlock(tierId: string, spot: Vector3?): boolean
	local nokta = spot or Sand.randomSpot(rng)
	if not nokta then
		return false
	end

	local tier = LuckyBlock.get(tierId)
	local gorunum = gorunumOf(tier.id)
	local model = buildBlock(tierId)
	local primary = model.PrimaryPart
	if not primary then
		model:Destroy()
		return false
	end

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	if (gorunum.olcek or 1) ~= 1 then
		pcall(function()
			model:ScaleTo(gorunum.olcek)
		end)
	end

	local origin = nokta + Vector3.new(0, LuckyBlock.Event.beaconHeight, 0)
	model.Name = `Etkinlik_{tier.id}`
	model:PivotTo(CFrame.new(origin))
	model.Parent = blocksFolder()

	Assets.playAnimations(model)
	buildBeacon(primary, nokta.Y, tier, gorunum)
	buildOzelSus(primary, tier, gorunum)

	local renkliIsik = Instance.new("PointLight")
	renkliIsik.Name = "KademeIsigi"
	renkliIsik.Color = tier.color
	renkliIsik.Range = gorunum.isik or 26
	renkliIsik.Brightness = 4
	renkliIsik.Parent = primary

	LuckyBlockOdul.sesCal()

	local ozel = (gorunum.olcek or 1) > 1

	local sign = Instance.new("BillboardGui")
	sign.Name = "Etiket"
	sign.Size = UDim2.fromOffset(if ozel then 300 else 230, if ozel then 52 else 40)
	sign.StudsOffset = Vector3.new(0, if ozel then 7 else 4, 0)
	sign.AlwaysOnTop = true
	sign.MaxDistance = math.huge
	sign.LightInfluence = 0
	sign.Parent = primary

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Fonts.bold
	label.Text = string.upper(tier.displayName)
	label.TextColor3 = tier.color
	label.TextSize = if ozel then 34 else 24
	label.TextScaled = false
	label.Parent = sign
	Fonts.applyOutline(label)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "AlPrompt"
	prompt.ActionText = "Take"
	prompt.ObjectText = tier.displayName
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = LuckyBlock.Event.pickupDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = primary

	local taken = false

	prompt.Triggered:Connect(function(player)
		if taken then
			return
		end

		local sinir = LuckyBlock.Event.oyuncuBasiLimit
		if sinir > 0 and (etkinlikteAlan[player] or 0) >= sinir then
			Bildirim:FireClient(
				player,
				`You can only take {sinir} Lucky Block per rain -- leave the rest to others!`,
				Color3.fromRGB(255, 200, 90)
			)
			return
		end
		etkinlikteAlan[player] = (etkinlikteAlan[player] or 0) + 1

		taken = true
		prompt.Enabled = false

		PlayerData.addLuckyBlocks(player, tier.id, 1)
		Envanter.syncLuckyBlocks(player)
		Envanter.push(player)

		LuckyBlockOdul.sesCal()

		model:Destroy()

		local kalan = 0
		for _, blok in blocksFolder():GetChildren() do
			local alPrompt = blok:FindFirstChild("AlPrompt", true)
			if alPrompt and alPrompt:IsA("ProximityPrompt") and alPrompt.Enabled then
				kalan += 1
			end
		end
		local kalanYazi = if kalan == 0 then "none left" else `{kalan} left`

		Bildirim:FireClient(
			player,
			`You got a {tier.displayName}! Take it from your backpack and use it. ({kalanYazi})`,
			tier.color
		)

		for _, diger in Players:GetPlayers() do
			if diger ~= player then
				Bildirim:FireClient(diger, `{player.DisplayName} took a {tier.displayName}! {kalanYazi}`, tier.color)
			end
		end
	end)

	task.spawn(function()
		local t = 0
		while model.Parent do
			t += task.wait(0.05)
			model:PivotTo(
				CFrame.new(origin + Vector3.new(0, math.sin(t * 1.5) * 0.4, 0)) * CFrame.Angles(0, t * 1.2, 0)
			)
		end
	end)

	if LuckyBlock.Event.despawn > 0 then
		Debris:AddItem(model, LuckyBlock.Event.despawn)
	end

	return true
end

local function normalAd(ad: string): string
	return string.lower((string.gsub(ad, "[%s_%-]", "")))
end

local function luckyZeminleri(): { BasePart }
	local aranan = normalAd(LuckyBlock.Event.zeminAdi or "luckyzemin")
	local liste: { BasePart } = {}

	for _, node in Workspace:GetDescendants() do
		if node:IsA("BasePart") and string.find(normalAd(node.Name), aranan, 1, true) then
			table.insert(liste, node)
		end
	end

	return liste
end

local function zeminNoktasi(zemin: BasePart): Vector3
	return (zemin.CFrame * CFrame.new(0, zemin.Size.Y / 2, 0)).Position
end

local function runEvent()
	local E = LuckyBlock.Event

	table.clear(etkinlikteAlan)

	local sira: { string } = {}
	for _ = 1, E.blokSayisi do
		table.insert(sira, LuckyBlock.etkinlikKademesi(rng))
	end

	local zeminler = luckyZeminleri()
	if #zeminler == 0 then
		warn(`[LuckyBlock] Event: no part with "{E.zeminAdi}" in its name -- only the main islands get blocks`)
	end

	for i = #zeminler, 2, -1 do
		local j = rng:NextInteger(1, i)
		zeminler[i], zeminler[j] = zeminler[j], zeminler[i]
	end

	local spawned = 0
	local ozel = 0
	for index, tierId in sira do
		local zemin = zeminler[index]
		if not zemin then
			break
		end

		if spawnEventBlock(tierId, zeminNoktasi(zemin)) then
			spawned += 1
			if tierId ~= LuckyBlock.Default then
				ozel += 1
			end
		end
	end

	for _, ada in E.anaAdalar do
		local tierId = LuckyBlock.etkinlikKademesi(rng, ada.tierSanslari)
		local spot = Sand.randomSpotNamed({ ada.kum }, rng)
		if spot and spawnEventBlock(tierId, spot) then
			spawned += 1
			if tierId ~= LuckyBlock.Default then
				ozel += 1
			end
		end
	end

	if spawned == 0 then
		warn("[LuckyBlock] Event: no block could be dropped")
		return
	end

	Workspace:SetAttribute(E.nitelikBitis, os.time() + E.despawn)

	local ozelYazi = if ozel > 0 then ` ({ozel} special!)` else ""
	Bildirim:FireAllClients(
		`LUCKY BLOCK RAIN STARTED! {spawned} blocks on the islands{ozelYazi} -- `
			.. "hop on your flyboard and hunt them down!",
		Rarity.LuckyBlock.colorA
	)
end

local function kalanBlok(): number
	local kalan = 0
	for _, blok in blocksFolder():GetChildren() do
		local alPrompt = blok:FindFirstChild("AlPrompt", true)
		if alPrompt and alPrompt:IsA("ProximityPrompt") and alPrompt.Enabled then
			kalan += 1
		end
	end
	return kalan
end

if LuckyBlock.Event.enabled then
	task.spawn(function()
		local E = LuckyBlock.Event
		local sonraki = LuckyBlock.sonrakiYagmur(os.time())
		local uyarilan: { [number]: boolean } = {}

		while true do
			local simdi = os.time()
			Workspace:SetAttribute(E.nitelikSonraki, sonraki)

			local kalan = kalanBlok()
			Workspace:SetAttribute(E.nitelikKalan, kalan)
			if kalan == 0 then
				Workspace:SetAttribute(E.nitelikBitis, 0)
			end

			local saniye = sonraki - simdi
			for _, esik in E.uyariSaniyeleri do
				if saniye <= esik and saniye > esik - 5 and not uyarilan[esik] then
					uyarilan[esik] = true
					local yazi = if esik >= 60 then `{math.floor(esik / 60)} minute{if esik >= 120 then "s" else ""}` else `{esik} seconds`
					Bildirim:FireAllClients(`LUCKY BLOCK RAIN in {yazi}!`, Rarity.LuckyBlock.colorA)
				end
			end

			if simdi >= sonraki then
				sonraki = LuckyBlock.sonrakiYagmur(simdi)
				table.clear(uyarilan)
				runEvent()
			end

			task.wait(1)
		end
	end)
end

function LuckyBlockOdul.runEvent()
	runEvent()
end

local function buildRarityCells(tierId: string, winnerIndex: number, winnerRarity: string, ada: string): { string }
	local cells = {}

	for index = 1, LuckyBlock.Wheel.cellCount do
		if index == winnerIndex then
			table.insert(cells, winnerRarity)
		else
			table.insert(cells, Brainrots.clampRarity(LuckyBlock.rollRarity(tierId, rng), ada))
		end
	end

	return cells
end

local function buildBrainrotCells(
	rarityId: string,
	winnerIndex: number,
	winnerName: string,
	ada: string
): { { name: string, rarity: string } }
	local cells = {}

	for index = 1, LuckyBlock.Wheel.revealCellCount do
		if index == winnerIndex then
			table.insert(cells, { name = winnerName, rarity = rarityId })
		else
			local info = Brainrots.rollIsland(rarityId :: any, ada, rng)
			table.insert(cells, { name = info.name, rarity = rarityId })
		end
	end

	return cells
end

local function openBlock(player: Player, tierId: string)
	if opening[player] then
		return
	end

	if not LuckyBlock.exists(tierId) then
		return
	end

	local data = PlayerData.get(player)
	if not data or PlayerData.luckyBlockCount(player, tierId) < 1 then
		Bildirim:FireClient(player, "You do not have that kind of Lucky Block.", Color3.fromRGB(255, 200, 90))
		return
	end

	local tier = LuckyBlock.get(tierId)

	opening[player] = true
	PlayerData.addLuckyBlocks(player, tierId, -1)
	Envanter.syncLuckyBlocks(player)

	local ada = PlayerData.reachedIsland(player)
	local rarityId = Brainrots.clampRarity(LuckyBlock.rollRarity(tierId, rng), ada)
	local info = Brainrots.rollIsland(rarityId :: any, ada, rng)
	local condition = Condition.roll(rng)
	local mutation = LuckyBlock.rollMutation(tierId, rng)

	local item = PlayerData.addBrainrot(player, rarityId, condition, mutation)
	if not item then
		opening[player] = false
		return
	end

	item.name = info.name
	item.revealed = true

	GorevTakip.ilerlet(player, "lucky", 1)
	GorevTakip.ilerlet(player, "collect", 1, rarityId)
	Seviye.xpVer(player, Seviye.XP.luckyBlock)

	local income = Brainrots.income(info.name, condition, mutation :: any)
	local winner = {
		name = info.name,
		rarity = rarityId,
		condition = condition,
		mutation = mutation,
		income = income,
	}

	local W = LuckyBlock.Wheel

	carkBasladi[player] = nil
	LuckyBlockSonuc:FireClient(player, {
		rarityCells = buildRarityCells(tierId, W.winnerIndex, rarityId, ada),
		rarityWinnerIndex = W.winnerIndex,
		raritySpinTime = W.spinTime,
		pause = W.pause,

		cells = buildBrainrotCells(rarityId, W.revealWinnerIndex, info.name, ada),
		winnerIndex = W.revealWinnerIndex,
		spinTime = W.revealSpinTime,

		winner = winner,
		tier = tierId,
		tierName = tier.displayName,
		tierMutation = tier.zorunluMutasyon,
		tierColor = tier.color,
		remaining = PlayerData.luckyBlockCount(player, tierId),
	})

	task.spawn(function()
		local basla = os.clock()
		while not carkBasladi[player] and player.Parent and os.clock() - basla < GIRIS_EN_FAZLA do
			task.wait(0.05)
		end
		carkBasladi[player] = nil

		task.delay(W.spinTime + W.pause + W.revealSpinTime, function()
			if player.Parent then
				Patlama.oynat(player, rarityId)
			end
		end)

		task.wait(LuckyBlock.totalSpinTime())
		opening[player] = false
		if not player.Parent then
			return
		end

		Envanter.syncBrainrots(player)
		Envanter.push(player)

		local special = Mutations.isSpecial(mutation)
		Bildirim:FireClient(
			player,
			`You got {info.name} {Condition.get(condition).shortName} ({Format.perSecond(income)})`,
			if special then Mutations.color(mutation) else Rarity.color(rarityId)
		)
	end)
end

Tools.onLuckyBlockUsed = openBlock

LuckyBlockAc.OnServerEvent:Connect(function(player, tierId)
	openBlock(player, if type(tierId) == "string" then tierId else LuckyBlock.Default)
end)

Players.PlayerRemoving:Connect(function(player)
	opening[player] = nil
end)

return LuckyBlockOdul
