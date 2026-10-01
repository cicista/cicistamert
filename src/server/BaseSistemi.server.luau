local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Bases = require(Shared:WaitForChild("Bases"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Condition = require(Shared:WaitForChild("Condition"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Assets = require(Shared:WaitForChild("Assets"))
local Scrolls = require(Shared:WaitForChild("Scrolls"))
local Fonts = require(Shared:WaitForChild("Fonts"))
local Divine = require(Shared:WaitForChild("Divine"))
local Etiket = require(Shared:WaitForChild("Etiket"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Gelir = require(Modules:WaitForChild("Gelir"))
require(Modules:WaitForChild("OfflineGelir"))
local Tools = require(Modules:WaitForChild("Tools"))
local Envanter = require(Modules:WaitForChild("Envanter"))
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
local GorevTakip = require(Modules:WaitForChild("GorevTakip"))
local Unvan = require(Modules:WaitForChild("Unvan"))

local Bildirim = Net.event("Bildirim")
local ScrollSonuc = Net.event("ScrollSonuc")
local BaseGuncelle = Net.event("BaseGuncelle")
local SlotaKoy = Net.event("SlotaKoy")
local SlottanAl = Net.event("SlottanAl")
local ParaSac = Net.event("ParaSac")
local BaseyeIsinlan = Net.event("BaseyeIsinlan")

local owners: { [number]: Player? } = {}
local slotModels: { [number]: { [number]: Model } } = {}
local pending: { [number]: number } = {}
local collectPads: { [number]: BasePart } = {}
local upgradeSigns: { [number]: BasePart } = {}
local collectUntil: { [number]: number } = {}

local lastTouch: { [Player]: number } = {}

local placeInSlot: (player: Player, uid: string, slotIndex: number) -> ()
local removeFromSlot: (player: Player, uid: string) -> ()
local collectRot: (player: Player, baseIndex: number) -> ()
local updateSign: (baseIndex: number) -> ()
local buyUpgrade: (player: Player, baseIndex: number) -> ()
local showInSlot: (baseIndex: number, slotIndex: number, item: any) -> ()
local pushBase: (player: Player) -> ()
local finishCollectButton: (pad: Part, model: Model, baseIndex: number, cfg: any) -> BasePart

local function basesFolder(): Instance
	local found = Bases.findFolder()
	if found then
		return found
	end

	warn(
		`[Base] No "{Bases.FolderName}" folder in Workspace. `
			.. `Creating an empty one -- put your bases there or `
			.. `rename the existing folder to this name.`
	)

	local created = Instance.new("Folder")
	created.Name = Bases.FolderName
	created.Parent = Workspace
	return created
end

local function baseBounds(base: Model): (CFrame?, Vector3?)
	local ok, cf, size = pcall(function()
		return base:GetBoundingBox()
	end)

	if not ok or not cf then
		return nil, nil
	end
	return cf, size
end

local function buildHologram(model: Model, bounds: CFrame, size: Vector3)
	local existing = model:FindFirstChild("Hologram")
	if existing then
		existing:Destroy()
	end

	local anchor = Instance.new("Part")
	anchor.Name = "Hologram"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = bounds * CFrame.new(0, size.Y / 2 + Bases.HologramHeight, -size.Z / 2 - 4)
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Parent = model

	local glow = Instance.new("PointLight")
	glow.Name = "Parilti"
	glow.Color = Color3.fromRGB(255, 255, 255)
	glow.Range = 16
	glow.Brightness = 1.2
	glow.Parent = anchor

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Yazi"
	billboard.Size = UDim2.fromOffset(345, 113)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 1200
	billboard.LightInfluence = 0
	billboard.Parent = anchor

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Sahip"
	nameLabel.Size = UDim2.new(1, 0, 0, 72)
	nameLabel.Position = UDim2.fromOffset(0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.FontFace = Fonts.bold
	nameLabel.Text = "EMPTY"
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 51
	nameLabel.TextScaled = false
	nameLabel.TextStrokeTransparency = 1
	nameLabel.TextTransparency = 0.1
	nameLabel.Parent = billboard

	local gradient = Instance.new("UIGradient")
	gradient.Name = "Hologram"
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.65, 0.1),
		NumberSequenceKeypoint.new(1, 0.55),
	})
	gradient.Parent = nameLabel

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "Gelir"
	incomeLabel.Size = UDim2.new(1, 0, 0, 38)
	incomeLabel.Position = UDim2.fromOffset(0, 74)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = ""
	incomeLabel.TextColor3 = Bases.RotColor
	incomeLabel.TextSize = 32
	incomeLabel.TextScaled = false
	incomeLabel.TextTransparency = 0
	Fonts.apply(incomeLabel)
	incomeLabel.Parent = billboard
end

local function buildCollectButton(model: Model, bounds: CFrame, size: Vector3, baseIndex: number): BasePart
	local cfg = Bases.CollectPad

	local existing = model:FindFirstChild("ToplaButonu")
	if existing then
		existing:Destroy()
	end

	local marker = model:FindFirstChild(Bases.CollectMarkerName)
	if marker and marker:IsA("BasePart") then
		local pad = Instance.new("Part")
		pad.Name = "ToplaButonu"
		pad.Size = marker.Size
		pad.CFrame = marker.CFrame

		pad:SetAttribute("Malzeme", marker.Material.Name)

		marker.Transparency = 1
		marker.CanCollide = false
		marker.CanQuery = false
		marker.CanTouch = false

		return finishCollectButton(pad, model, baseIndex, cfg)
	end

	local front = bounds * CFrame.new(0, size.Y / 2, -size.Z / 2 - cfg.forward)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model }
	local hit = Workspace:Raycast(front.Position, Vector3.new(0, -(size.Y + 250), 0), params)
	local groundY = if hit then hit.Position.Y else bounds.Position.Y - size.Y / 2

	local pad = Instance.new("Part")
	pad.Name = "ToplaButonu"
	pad.Size = cfg.size
	pad.CFrame = CFrame.new(front.Position.X, groundY + cfg.size.Y / 2 + 0.05, front.Position.Z) * bounds.Rotation
	return finishCollectButton(pad, model, baseIndex, cfg)
end

function finishCollectButton(pad: Part, model: Model, baseIndex: number, cfg: any): BasePart
	pad.Anchored = true
	pad.CanCollide = false
	local malzeme = pad:GetAttribute("Malzeme")
	pad.Material = if type(malzeme) == "string" and (Enum.Material :: any)[malzeme]
		then (Enum.Material :: any)[malzeme]
		else Enum.Material.SmoothPlastic
	pad.Transparency = 0
	pad.Reflectance = 0
	pad.Color = cfg.idleColor
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.BottomSurface = Enum.SurfaceType.Smooth
	pad.Parent = model

	local glow = Instance.new("PointLight")
	glow.Name = "Parilti"
	glow.Color = cfg.color
	glow.Range = 14
	glow.Brightness = 1.4
	glow.Enabled = false
	glow.Parent = pad

	local surface = Instance.new("SurfaceGui")
	surface.Name = "Yuzey"
	surface.Face = Enum.NormalId.Top
	surface.PixelsPerStud = 50
	surface.LightInfluence = 0
	surface.Parent = pad

	local sign = Instance.new("BillboardGui")
	sign.Name = "Yazi"
	sign.Size = UDim2.fromOffset(240, 64)
	sign.StudsOffset = Vector3.new(0, 8, 0)
	sign.AlwaysOnTop = false
	sign.MaxDistance = 400
	sign.LightInfluence = 0
	sign.Parent = pad

	local amount = Instance.new("TextLabel")
	amount.Name = "Miktar"
	amount.Size = UDim2.fromScale(1, 1)
	amount.BackgroundTransparency = 1
	amount.FontFace = Fonts.bold
	amount.Text = "EMPTY"
	amount.TextColor3 = cfg.idleColor
	amount.TextSize = 34
	amount.TextScaled = false
	amount.TextStrokeTransparency = 1
	amount.Parent = sign

	pad.Touched:Connect(function(toucher: BasePart)
		local character = toucher.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local now = os.clock()
		if lastTouch[player] and now - lastTouch[player] < cfg.cooldown then
			return
		end
		lastTouch[player] = now

		collectRot(player, baseIndex)
	end)

	return pad
end

local function unlockedSlots(data: any): number
	local floors = math.clamp(data.baseFloors or 1, 1, Bases.Upgrade.maxFloors)
	return math.clamp(data.baseSlots or Bases.Upgrade.startingSlots, 0, floors * Bases.Upgrade.slotsPerFloor)
end

local function nextUpgrade(data: any): { kind: string, cost: number, label: string }?
	local U = Bases.Upgrade
	local floors = math.clamp(data.baseFloors or 1, 1, U.maxFloors)
	local slots = unlockedSlots(data)

	if slots >= floors * U.slotsPerFloor then
		if floors >= U.maxFloors then
			return nil
		end
		return {
			kind = "floor",
			cost = U.floorCost[floors + 1] or 0,
			label = `FLOOR {floors + 1}`,
		}
	end

	return {
		kind = "slot",
		cost = Bases.slotCost(slots),
		label = `SLOT {slots + 1}`,
	}
end

local SLOT_NUMARA_KALINLIK = 0.05

local function dunyaYariBoyut(pad: BasePart): Vector3
	local cf = pad.CFrame
	local yari = pad.Size / 2
	local x = math.abs(cf.RightVector.X) * yari.X + math.abs(cf.UpVector.X) * yari.Y + math.abs(cf.LookVector.X) * yari.Z
	local y = math.abs(cf.RightVector.Y) * yari.X + math.abs(cf.UpVector.Y) * yari.Y + math.abs(cf.LookVector.Y) * yari.Z
	local z = math.abs(cf.RightVector.Z) * yari.X + math.abs(cf.UpVector.Z) * yari.Y + math.abs(cf.LookVector.Z) * yari.Z
	return Vector3.new(x, y, z)
end

local function slotYuzeyi(node: Instance, pad: BasePart): (Vector3, number)
	local parcalar: { BasePart } = {}
	if node:IsA("BasePart") then
		table.insert(parcalar, node)
	end
	for _, d in node:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "SlotNumarasi" and d.Transparency < 1 then
			table.insert(parcalar, d)
		end
	end
	if #parcalar == 0 then
		table.insert(parcalar, pad)
	end

	local enAz, enCok = nil, nil
	for _, p in parcalar do
		local yari = dunyaYariBoyut(p)
		local alt, ust = p.Position - yari, p.Position + yari
		enAz = if enAz then enAz:Min(alt) else alt
		enCok = if enCok then enCok:Max(ust) else ust
	end

	local merkez = ((enAz :: Vector3) + (enCok :: Vector3)) / 2
	local boyut = (enCok :: Vector3) - (enAz :: Vector3)
	local ustY = (enCok :: Vector3).Y

	local ayar = RaycastParams.new()
	ayar.FilterType = Enum.RaycastFilterType.Include
	ayar.FilterDescendantsInstances = parcalar
	local isin = Workspace:Raycast(Vector3.new(merkez.X, ustY + 5, merkez.Z), Vector3.new(0, -(boyut.Y + 10), 0), ayar)
	if isin then
		ustY = isin.Position.Y
	end

	return Vector3.new(merkez.X, ustY, merkez.Z), math.min(boyut.X, boyut.Z)
end

local function buildSlotNumber(pad: BasePart, slotIndex: number, ust: Vector3, node: Instance?)
	local eski = pad:FindFirstChild("SlotNumarasi")
	if eski then
		eski:Destroy()
	end

	local yuzey, genislik = slotYuzeyi(node or pad, pad)
	local kenar = math.max(1, genislik * 0.7)
	local merkez = yuzey + Vector3.new(0, SLOT_NUMARA_KALINLIK / 2 + 0.03, 0)

	local tasiyici = Instance.new("Part")
	tasiyici.Name = "SlotNumarasi"
	tasiyici.Size = Vector3.new(kenar, kenar, SLOT_NUMARA_KALINLIK)
	tasiyici.CFrame = CFrame.lookAt(merkez, merkez + Vector3.yAxis, ust)
	tasiyici.Anchored = true
	tasiyici.CanCollide = false
	tasiyici.CanQuery = false
	tasiyici.CanTouch = false
	tasiyici.CastShadow = false
	tasiyici.Transparency = 1
	tasiyici:SetAttribute(Assets.MeasureSkipAttribute, true)
	tasiyici.Parent = pad

	local yuzey = Instance.new("SurfaceGui")
	yuzey.Name = "Yazi"
	yuzey.Face = Enum.NormalId.Front
	yuzey.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	yuzey.PixelsPerStud = 40
	yuzey.LightInfluence = 0
	yuzey.Parent = tasiyici

	local yazi = Instance.new("TextLabel")
	yazi.Size = UDim2.fromScale(1, 1)
	yazi.BackgroundTransparency = 1
	yazi.Text = tostring(slotIndex)
	yazi.TextScaled = true
	yazi.TextColor3 = Color3.fromRGB(255, 255, 255)
	yazi.TextTransparency = 0
	Fonts.apply(yazi)
	yazi.Parent = yuzey

	local sinir = Instance.new("UITextSizeConstraint")
	sinir.MaxTextSize = 120
	sinir.Parent = yazi

	local kontur = Instance.new("UIStroke")
	kontur.Color = Color3.fromRGB(0, 0, 0)
	kontur.Thickness = 4
	kontur.Transparency = 0
	kontur.Parent = yazi
end

local function elindekiScroll(player: Player): (string?, Tool?)
	local karakter = player.Character
	if not karakter then
		return nil, nil
	end
	for _, node in karakter:GetChildren() do
		if node:IsA("Tool") then
			local id = node:GetAttribute(Scrolls.Nitelik)
			if type(id) == "string" then
				return id, node
			end
		end
	end
	return nil, nil
end

local function scrollKullan(player: Player, data: any, scrollId: string, slotIndex: number)
	local info = Scrolls.get(scrollId)
	if not info then
		return
	end

	local hedef: any = nil
	for _, item in data.inventory do
		if item.slot == slotIndex then
			hedef = item
			break
		end
	end

	if not hedef then
		Bildirim:FireClient(player, "Put a brainrot in the slot first.", Color3.fromRGB(255, 200, 90))
		return
	end

	if hedef.mutation == info.mutasyon then
		Bildirim:FireClient(
			player,
			`This one is already {info.mutasyon}.`,
			Color3.fromRGB(255, 200, 90)
		)
		return
	end

	if PlayerData.scrollCount(player, scrollId) <= 0 then
		return
	end
	PlayerData.addScroll(player, scrollId, -1)
	Envanter.syncScrolls(player)

	local basarili = math.random() < info.sans
	local govde = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

	if basarili then
		hedef.mutation = info.mutasyon
		showInSlot(data.base, slotIndex, hedef)
		pushBase(player)

		if govde and govde:IsA("BasePart") then
			Assets.playSoundAt({ "Catch" }, govde)
		end
	else
		if govde and govde:IsA("BasePart") then
			Assets.playSoundAt({ "FuseFail" }, govde)
		end
		Bildirim:FireClient(
			player,
			`The scroll fizzled out. No {info.mutasyon} this time.`,
			Color3.fromRGB(255, 140, 140)
		)
	end

	ScrollSonuc:FireClient(player, {
		ok = basarili,
		mutation = info.mutasyon,
		name = if hedef.revealed then hedef.name else nil,
		renk = info.renk,
	})
end

local function buildSlotPrompt(pad: BasePart, baseIndex: number, slotIndex: number)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SlotPrompt"
	prompt.ActionText = "Slot"
	prompt.ObjectText = `Slot {slotIndex}`
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = pad

	prompt.Triggered:Connect(function(player)
		if Bases.OwnerOnlyPlacement and owners[baseIndex] ~= player then
			Bildirim:FireClient(player, "This is not your base!", Color3.fromRGB(255, 120, 120))
			return
		end

		local data = PlayerData.get(player)
		if not data then
			return
		end

		if slotIndex > unlockedSlots(data) then
			Bildirim:FireClient(
				player,
				`Slot {slotIndex} is locked`,
				Color3.fromRGB(255, 200, 90)
			)
			return
		end

		local scrollId = elindekiScroll(player)
		if scrollId then
			scrollKullan(player, data, scrollId, slotIndex)
			return
		end

		local _, heldUid = Tools.equippedBrainrot(player)
		if heldUid then
			placeInSlot(player, heldUid, slotIndex)
			return
		end

		for _, item in data.inventory do
			if item.slot == slotIndex then
				removeFromSlot(player, item.uid)
				return
			end
		end

		Bildirim:FireClient(player, "Hold a brainrot to place it.", Color3.fromRGB(255, 200, 90))
	end)
end

local function resolveSlotSurface(node: Instance?): BasePart?
	if not node then
		return nil
	end

	if node:IsA("BasePart") then
		return node
	end

	if node:IsA("Model") then
		local platform = node:FindFirstChild("Platform")
		if platform and platform:IsA("BasePart") then
			return platform
		end
		if node.PrimaryPart then
			return node.PrimaryPart
		end
		return node:FindFirstChildWhichIsA("BasePart", true)
	end

	return nil
end

local slotAdlari: { [Model]: { [number]: string } } = {}
local onYonleri: { [number]: Vector3 } = {}
local slotYonleri: { [Model]: { [number]: Vector3 } } = {}

local function slotAdi(base: Model, slotIndex: number): string
	local harita = slotAdlari[base]
	return (harita and harita[slotIndex]) or Bases.slotName(slotIndex)
end

local function findSlotPart(base: Model, slotIndex: number): BasePart?
	local name = slotAdi(base, slotIndex)

	local direct = resolveSlotSurface(base:FindFirstChild(name))
	if direct then
		return direct
	end

	local folder = base:FindFirstChild("Slots")
	if folder then
		local inFolder = resolveSlotSurface(folder:FindFirstChild(name))
		if inFolder then
			return inFolder
		end
	end

	return resolveSlotSurface(base:FindFirstChild(name, true))
end

type SlotKaydi = { ad: string, konum: Vector3 }

local function slotSirasiKur(base: Model, on: Vector3)
	slotAdlari[base] = nil
	slotYonleri[base] = nil

	local adlar: { [number]: string } = {}
	local yonler: { [number]: Vector3 } = {}
	local geri = -on
	local sag = geri:Cross(Vector3.yAxis).Unit
	local aSayi = Bases.Upgrade.slotsPerFloor

	for kat = 1, Bases.Upgrade.maxFloors do
		local ilk = (kat - 1) * aSayi

		local kayitlar: { SlotKaydi } = {}
		local toplam = Vector3.zero
		for no = ilk + 1, ilk + aSayi do
			local ad = Bases.slotName(no)
			local pad = findSlotPart(base, no)
			if pad then
				table.insert(kayitlar, { ad = ad, konum = pad.Position })
				toplam += pad.Position
			end
		end

		if #kayitlar == 0 then
			continue
		end

		local merkez = toplam / #kayitlar
		local sol: { SlotKaydi } = {}
		local sagda: { SlotKaydi } = {}
		for _, k in kayitlar do
			if (k.konum - merkez):Dot(sag) < 0 then
				table.insert(sol, k)
			else
				table.insert(sagda, k)
			end
		end

		table.sort(sol, function(a, b)
			return (a.konum - merkez):Dot(on) > (b.konum - merkez):Dot(on)
		end)
		table.sort(sagda, function(a, b)
			return (a.konum - merkez):Dot(on) < (b.konum - merkez):Dot(on)
		end)

		local koridora = Bases.SlotNumberFacing ~= "wall"
		local solUst = if koridora then -sag else sag

		local sira = ilk
		for _, k in sol do
			sira += 1
			adlar[sira] = k.ad
			yonler[sira] = solUst
		end
		for _, k in sagda do
			sira += 1
			adlar[sira] = k.ad
			yonler[sira] = -solUst
		end
	end

	slotAdlari[base] = adlar
	slotYonleri[base] = yonler
end

local baseModels: { [number]: Model } = {}

local function mapBases()
	local folder = basesFolder()
	table.clear(baseModels)

	for index = 1, Bases.Count do
		local named = folder:FindFirstChild(Bases.baseName(index))
		if named and named:IsA("Model") then
			baseModels[index] = named
		end
	end

	local leftovers: { Model } = {}
	for _, child in folder:GetChildren() do
		if child:IsA("Model") then
			local claimed = false
			for _, taken in baseModels do
				if taken == child then
					claimed = true
					break
				end
			end
			if not claimed then
				table.insert(leftovers, child)
			end
		end
	end

	table.sort(leftovers, function(a, b)
		return a.Name < b.Name
	end)

	local cursor = 1
	for index = 1, Bases.Count do
		if not baseModels[index] and leftovers[cursor] then
			baseModels[index] = leftovers[cursor]
			cursor += 1
		end
	end
end

local function getBase(index: number): Model?
	return baseModels[index]
end

local function getSlotPart(baseIndex: number, slotIndex: number): BasePart?
	local base = getBase(baseIndex)
	return if base then findSlotPart(base, slotIndex) else nil
end

local function setVisible(node: Instance, visible: boolean)
	if node:IsA("BasePart") then
		if node:GetAttribute("OzgunSaydamlik") == nil then
			node:SetAttribute("OzgunSaydamlik", node.Transparency)
			node:SetAttribute("OzgunCarpisma", node.CanCollide)
		end

		if visible then
			local saved = node:GetAttribute("OzgunSaydamlik")
			node.Transparency = if typeof(saved) == "number" then saved else 0
			node.CanCollide = node:GetAttribute("OzgunCarpisma") ~= false
		else
			node.Transparency = 1
			node.CanCollide = false
		end
	elseif node:IsA("ProximityPrompt") then
		node.Enabled = visible
	end
end

local function applyFloors(baseIndex: number, floors: number)
	local base = getBase(baseIndex)
	if not base then
		return
	end

	for floorIndex = 2, Bases.Upgrade.maxFloors do
		local model = base:FindFirstChild(Bases.floorModelName(floorIndex))
		if not model then
			continue
		end

		local visible = floorIndex <= floors

		for _, node in model:GetDescendants() do
			setVisible(node, visible)
		end
	end
end

local slotStore: Folder? = nil

local function stashFolder(): Folder
	if slotStore and slotStore.Parent then
		return slotStore
	end

	local existing = ServerStorage:FindFirstChild("KilitliSlotlar")
	if existing and existing:IsA("Folder") then
		slotStore = existing
		return existing
	end

	local created = Instance.new("Folder")
	created.Name = "KilitliSlotlar"
	created.Parent = ServerStorage
	slotStore = created
	return created
end

local stashed: { [number]: { [number]: { node: Instance, parent: Instance } } } = {}

local function slotNode(baseIndex: number, slotIndex: number): Instance?
	local base = getBase(baseIndex)
	if not base then
		return nil
	end

	local name = slotAdi(base, slotIndex)

	local direct = base:FindFirstChild(name)
	if direct then
		return direct
	end

	local folder = base:FindFirstChild("Slots")
	if folder then
		local inFolder = folder:FindFirstChild(name)
		if inFolder then
			return inFolder
		end
	end

	return base:FindFirstChild(name, true)
end

local function setSlotVisible(baseIndex: number, slotIndex: number, visible: boolean)
	stashed[baseIndex] = stashed[baseIndex] or {}
	local store = stashed[baseIndex]

	if visible then
		local saved = store[slotIndex]
		if saved then
			if saved.node.Parent ~= saved.parent and saved.parent.Parent then
				saved.node.Parent = saved.parent
			end

			local nodes: { Instance } = saved.node:GetDescendants()
			table.insert(nodes, saved.node)
			for _, child in nodes do
				setVisible(child, true)
			end

			store[slotIndex] = nil
		end
		return
	end

	if store[slotIndex] then
		return
	end

	local node = slotNode(baseIndex, slotIndex)
	local parent = node and node.Parent
	if not node or not parent then
		return
	end

	store[slotIndex] = { node = node, parent = parent }
	node.Parent = stashFolder()
end

local function applySlots(baseIndex: number, unlocked: number)
	for slotIndex = Bases.Upgrade.startingSlots + 1, Bases.SlotCount do
		setSlotVisible(baseIndex, slotIndex, slotIndex <= unlocked)
	end
end

local rising: { [Model]: boolean } = {}

local function riseFloor(baseIndex: number, floorIndex: number)
	local base = getBase(baseIndex)
	local model = base and base:FindFirstChild(Bases.floorModelName(floorIndex))
	if not model or not model:IsA("Model") or rising[model] then
		return
	end

	local U = Bases.Upgrade
	local home = model:GetPivot()
	local start = home.Position - Vector3.new(0, U.riseHeight, 0)

	rising[model] = true
	model:PivotTo(CFrame.new(start) * home.Rotation)

	task.spawn(function()
		local elapsed = 0
		while elapsed < U.riseTime and model.Parent do
			elapsed += task.wait()
			local alpha = math.clamp(elapsed / U.riseTime, 0, 1)
			local eased = 1 - (1 - alpha) ^ 3
			model:PivotTo(CFrame.new(start:Lerp(home.Position, eased)) * home.Rotation)
		end

		if model.Parent then
			model:PivotTo(home)
		end
		rising[model] = nil
	end)
end

local function buildSignFace(board: BasePart, face: Enum.NormalId)
	local sign = Instance.new("SurfaceGui")
	sign.Name = "Yazi"
	sign.Face = face
	sign.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sign.PixelsPerStud = 50
	sign.LightInfluence = 0
	sign.Parent = board

	local U = Bases.Upgrade

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Zemin"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = U.panelBottom
	backdrop.BackgroundTransparency = 0
	backdrop.BorderSizePixel = 0
	backdrop.Parent = sign

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(U.panelTop, U.panelBottom)
	gradient.Parent = backdrop

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.06, 0)
	corner.Parent = backdrop

	local border = Instance.new("UIStroke")
	border.Color = U.panelBorder
	border.Thickness = 5
	border.Parent = backdrop

	local function line(name: string, height: number, y: number, color: Color3): TextLabel
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = UDim2.new(0.92, 0, height, 0)
		label.Position = UDim2.new(0.04, 0, y, 0)
		label.BackgroundTransparency = 1
		label.Text = ""
		label.TextColor3 = color
		label.TextScaled = true
		label.Parent = sign
		Fonts.apply(label)
		return label
	end

	line("Baslik", 0.18, 0.03, Color3.fromRGB(255, 255, 255)).Text = "BASE UPGRADES"
	line("Durum", 0.16, 0.25, Color3.fromRGB(186, 218, 255))
	line("Sonraki", 0.17, 0.45, Color3.fromRGB(255, 214, 41))
	line("Fiyat", 0.30, 0.66, Color3.fromRGB(140, 230, 160))
end

local function buildUpgradeSign(base: Model, bounds: CFrame, size: Vector3, baseIndex: number): BasePart
	local U = Bases.Upgrade

	local marker: Instance? = base:FindFirstChild(U.markerName)
		or base:FindFirstChild(U.markerName, true)

	if not marker then
		local wanted = string.lower(U.markerName)
		for _, node in base:GetDescendants() do
			if node:IsA("BasePart") and string.lower(node.Name) == wanted then
				marker = node
				break
			end
		end
	end

	local board: BasePart

	if marker and marker:IsA("BasePart") then
		board = marker

		for _, child in board:GetChildren() do
			if child:IsA("SurfaceGui") or child:IsA("ProximityPrompt") then
				child:Destroy()
			end
		end

		print(`[Base] {base.Name}: tabela '{board.Name}' parcasinin uzerine yazildi`)
	else
		local old = base:FindFirstChild("GelisimTabelasi")
		if old then
			old:Destroy()
		end

		local created = Instance.new("Part")
		created.Name = "GelisimTabelasi"
		created.Anchored = true
		created.CanCollide = false
		created.Material = Enum.Material.SmoothPlastic
		created.Color = U.color
		created.TopSurface = Enum.SurfaceType.Smooth
		created.BottomSurface = Enum.SurfaceType.Smooth
		created.Size = U.size

		local front = bounds * CFrame.new(0, 0, size.Z / 2 + U.forward)
		created.CFrame = CFrame.new(
			front.Position.X,
			bounds.Position.Y - size.Y / 2 + U.size.Y / 2 + 1,
			front.Position.Z
		) * bounds.Rotation

		created.Parent = base
		board = created

		warn(`[Base] {base.Name}: no Part named '{U.markerName}', sign placed in front of the base`)
	end

	local boardSize = board.Size
	local away = board.Position - bounds.Position
	local face: Enum.NormalId

	local flip = U.flipFace == true

	if boardSize.Y <= boardSize.X and boardSize.Y <= boardSize.Z then
		face = if flip then Enum.NormalId.Bottom else Enum.NormalId.Top
	elseif boardSize.Z <= boardSize.X then
		local frontSide = board.CFrame.LookVector:Dot(away) >= 0
		if flip then
			frontSide = not frontSide
		end
		face = if frontSide then Enum.NormalId.Front else Enum.NormalId.Back
	else
		local rightSide = board.CFrame.RightVector:Dot(away) >= 0
		if flip then
			rightSide = not rightSide
		end
		face = if rightSide then Enum.NormalId.Right else Enum.NormalId.Left
	end

	buildSignFace(board, face)

	board.Color = U.color
	board.Material = Enum.Material.SmoothPlastic
	board.CanCollide = false

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GelistirPrompt"
	prompt.ActionText = "Upgrade"
	prompt.ObjectText = "Base"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = board

	prompt.Triggered:Connect(function(player)
		buyUpgrade(player, baseIndex)
	end)

	return board
end

function updateSign(baseIndex: number)
	local board = upgradeSigns[baseIndex]
	if not board then
		return
	end

	local owner = owners[baseIndex]
	local data = if owner then PlayerData.get(owner) else nil

	local durumText, sonrakiText, fiyatText

	if not data then
		durumText, sonrakiText, fiyatText = "Unclaimed base", "", ""
	else
		local floors = math.clamp(data.baseFloors or 1, 1, Bases.Upgrade.maxFloors)
		local slots = unlockedSlots(data)
		durumText = `Floor {floors}/{Bases.Upgrade.maxFloors}   Slot {slots}/{Bases.SlotCount}`

		local up = nextUpgrade(data)
		if up then
			sonrakiText = up.label
			fiyatText = `{Format.short(up.cost)} ROT`
		else
			sonrakiText = ""
			fiyatText = "FULLY UPGRADED"
		end
	end

	for _, sign in board:GetChildren() do
		if not sign:IsA("SurfaceGui") then
			continue
		end

		local durum = sign:FindFirstChild("Durum")
		local sonraki = sign:FindFirstChild("Sonraki")
		local fiyat = sign:FindFirstChild("Fiyat")

		if durum and durum:IsA("TextLabel") then
			durum.Text = durumText
		end
		if sonraki and sonraki:IsA("TextLabel") then
			sonraki.Text = sonrakiText
		end
		if fiyat and fiyat:IsA("TextLabel") then
			fiyat.Text = fiyatText
		end
	end
end

function buyUpgrade(player: Player, baseIndex: number)
	if owners[baseIndex] ~= player then
		Bildirim:FireClient(player, "This is not your base!", Color3.fromRGB(255, 120, 120))
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local up = nextUpgrade(data)
	if not up then
		Bildirim:FireClient(player, "Base is already fully upgraded (3 floors / 30 slots).", Color3.fromRGB(180, 200, 220))
		return
	end

	if data.rot < up.cost then
		Bildirim:FireClient(
			player,
			`Not enough Rot! You need {Format.short(up.cost - data.rot)} more Rot for {up.label}.`,
			Color3.fromRGB(255, 120, 120)
		)
		return
	end

	PlayerData.addRot(player, -up.cost)

	if up.kind == "floor" then
		data.baseFloors = math.clamp((data.baseFloors or 1) + 1, 1, Bases.Upgrade.maxFloors)
		data.baseSlots = math.clamp(
			unlockedSlots(data) + Bases.Upgrade.slotsWithFloor,
			0,
			Bases.SlotCount
		)

		applyFloors(baseIndex, data.baseFloors)

		applySlots(baseIndex, unlockedSlots(data))

		riseFloor(baseIndex, data.baseFloors)

		Bildirim:FireClient(player, `{up.label} unlocked! New slot added.`, Color3.fromRGB(140, 230, 160))
	else
		data.baseSlots = math.clamp(unlockedSlots(data) + 1, 0, Bases.SlotCount)

		applySlots(baseIndex, unlockedSlots(data))

		Bildirim:FireClient(player, `{up.label} unlocked!`, Color3.fromRGB(140, 230, 160))
	end

	updateSign(baseIndex)
	Envanter.push(player)
	pushBase(player)
end

local function setupBases()
	mapBases()

	for index = 1, Bases.Count do
		slotModels[index] = slotModels[index] or {}

		local base = getBase(index)
		if not base then
			warn(`[Base] {Bases.baseName(index)} not found -- it must be under Workspace > Bases`)
			continue
		end

		local oldSign = base:FindFirstChild("Sign")
		if oldSign and oldSign:FindFirstChild("Tabela") then
			oldSign:Destroy()
		end

		local oldHologram = base:FindFirstChild("Hologram")
		if oldHologram then
			oldHologram:Destroy()
		end

		local oldButton = base:FindFirstChild("ToplaButonu")
		if oldButton then
			oldButton:Destroy()
		end
		collectPads[index] = nil

		if base:IsA("Model") then
			base.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		end

		local oldSign = base:FindFirstChild("GelisimTabelasi")
		if oldSign then
			oldSign:Destroy()
		end
		upgradeSigns[index] = nil

		local bounds, size = baseBounds(base)
		if bounds and size then
			buildHologram(base, bounds, size)
			collectPads[index] = buildCollectButton(base, bounds, size, index)
			upgradeSigns[index] = buildUpgradeSign(base, bounds, size, index)

			local pad = collectPads[index]
			local fark = if pad then pad.Position - bounds.Position else bounds.LookVector
			local on = Vector3.new(fark.X, 0, fark.Z)
			if on.Magnitude < 0.01 then
				on = Vector3.new(bounds.LookVector.X, 0, bounds.LookVector.Z)
			end
			onYonleri[index] = on.Unit
			slotSirasiKur(base, on.Unit)
		else
			warn(`[Base] {base.Name}: bounding box could not be computed, hologram not placed`)
		end

		local found = 0
		for slotIndex = 1, Bases.SlotCount do
			local pad = getSlotPart(index, slotIndex)
			if not pad then
				continue
			end
			found += 1
			if not pad:FindFirstChild("SlotPrompt") then
				buildSlotPrompt(pad, index, slotIndex)
			end
			local yonler = slotYonleri[base]
			local ust = (yonler and yonler[slotIndex]) or Vector3.new(0, 0, -1)
			buildSlotNumber(pad, slotIndex, ust, slotNode(index, slotIndex))
		end

		if found < Bases.SlotCount then
			local eksik: { string } = {}
			for slotIndex = 1, Bases.SlotCount do
				if not getSlotPart(index, slotIndex) then
					table.insert(eksik, slotAdi(base, slotIndex))
				end
			end
			warn(
				`[Base] {base.Name}: {found}/{Bases.SlotCount} slot bulundu. `
					.. `BULUNAMAYANLAR: {table.concat(eksik, ", ")}`
			)
		else
			print(`[Base] {index} -> {base.Name} ready ({found} slots)`)
		end

		applyFloors(index, 1)
		applySlots(index, Bases.Upgrade.startingSlots)
		updateSign(index)

	end
end

setupBases()

local function buildDisplay(item: any): Model
	local rarityInfo = Rarity.get(item.rarity)
	local mutationInfo = Mutations.get(item.mutation)
	local special = Mutations.isSpecial(item.mutation)

	local source = Assets.brainrotModel(item.name, item.mutation)

	local model: Model
	if source then
		model = source
		if not model.PrimaryPart then
			model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
		end
	else
		model = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name = "Govde"
		body.Size = Vector3.new(3, 3, 3)
		body.Color = if special then mutationInfo.color else rarityInfo.color
		body.Material = Enum.Material.Neon
		body.TopSurface = Enum.SurfaceType.Smooth
		body.BottomSurface = Enum.SurfaceType.Smooth
		body.Parent = model
		model.PrimaryPart = body
	end

	model.Name = item.name

	local boyutOlcegi = Condition.scaleFor(item.condition, rarityInfo.order)
		* Rarity.modelScale(item.rarity)

	Assets.fitModel(model, Assets.BrainrotSize.slotSize, boyutOlcegi)

	if not special then
		Tools.stripEffects(model)
	end

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	local primary = model.PrimaryPart
	if not primary then
		return model
	end

	local labelAnchor = Instance.new("Part")
	labelAnchor.Name = "EtiketTutamagi"
	labelAnchor.Size = Vector3.one
	labelAnchor.Transparency = 1
	labelAnchor.Anchored = true
	labelAnchor.CanCollide = false
	labelAnchor.CanQuery = false
	labelAnchor.CanTouch = false
	labelAnchor.Massless = true
	labelAnchor.CFrame = primary.CFrame
	labelAnchor:SetAttribute(Assets.MeasureSkipAttribute, true)
	labelAnchor.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = primary
	weld.Part1 = labelAnchor
	weld.Parent = labelAnchor

	Etiket.build(item, labelAnchor)

	if item.revealed then
		Assets.attachRarityVFX(model, item.rarity, primary)
	end

	return model
end

local function clearSlotModel(baseIndex: number, slotIndex: number)
	local models = slotModels[baseIndex]
	if not models then
		return
	end
	local model = models[slotIndex]
	if model and model.Parent then
		model:Destroy()
	end
	models[slotIndex] = nil
end

local function slotSurfaceY(pad: BasePart): number
	local cf = pad.CFrame
	local size = pad.Size

	local halfHeight = math.abs(cf.RightVector.Y) * size.X / 2
		+ math.abs(cf.UpVector.Y) * size.Y / 2
		+ math.abs(cf.LookVector.Y) * size.Z / 2

	local top = pad.Position.Y + halfHeight

	local ignore: { Instance } = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	for _, models in slotModels do
		for _, placed in models do
			table.insert(ignore, placed)
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore

	local hit = Workspace:Raycast(
		Vector3.new(pad.Position.X, top + 4, pad.Position.Z),
		Vector3.new(0, -8, 0),
		params
	)

	if hit and hit.Position.Y > top and hit.Position.Y - top <= 2 then
		return hit.Position.Y
	end

	return top
end

local function playSlotSound(baseIndex: number, slotIndex: number?)
	local part = (if slotIndex then getSlotPart(baseIndex, slotIndex) else nil) or collectPads[baseIndex]
	if part then
		Assets.playSoundAt(Bases.SlotSound, part)
	end
end

function showInSlot(baseIndex, slotIndex, item)
	clearSlotModel(baseIndex, slotIndex)

	local pad = getSlotPart(baseIndex, slotIndex)
	if not pad then
		return
	end

	local model = buildDisplay(item)
	local D = Bases.Display

	local correction = CFrame.Angles(math.rad(D.rotation.X), math.rad(D.rotation.Y), math.rad(D.rotation.Z))

	local pivot = model:GetPivot()
	model:PivotTo(CFrame.new(pivot.Position) * correction * pivot.Rotation)

	local min, max = Assets.worldBounds(model)

	if not min or not max then
		model:Destroy()
		return
	end

	local lowest = min.Y
	local highest = max.Y
	local centerX = (min.X + max.X) / 2
	local centerZ = (min.Z + max.Z) / 2

	local surfaceY = slotSurfaceY(pad)

	local shift = Vector3.new(
		pad.Position.X - centerX,
		(surfaceY + D.gap) - lowest,
		pad.Position.Z - centerZ
	)

	model:PivotTo(model:GetPivot() + shift)

	local anchor = model:FindFirstChild("EtiketTutamagi")
	if anchor and anchor:IsA("BasePart") then
		anchor.CFrame = CFrame.new(pad.Position.X, highest + shift.Y + 2.5, pad.Position.Z)
	end

	model.Parent = pad

	slotModels[baseIndex] = slotModels[baseIndex] or {}
	slotModels[baseIndex][slotIndex] = model

	local home = model:GetPivot()

	model:SetAttribute("SpinDisplay", true)
	model:SetAttribute("Mutation", item.mutation or "Normal")
	model:SetAttribute("SpinHome", home)
	model:SetAttribute("SpinPivot", CFrame.new(pad.Position.X, surfaceY, pad.Position.Z))
	model:SetAttribute("SpinEnabled", D.spin)
	model:SetAttribute("SpinSpeed", D.spinSpeed)
	model:SetAttribute("BobHeight", D.bobHeight)
	model:SetAttribute("BobSpeed", D.bobSpeed)
end

local function totalIncome(player: Player): number
	return Gelir.saniyelik(player)
end

local OWNED_COLOR = Color3.fromRGB(90, 235, 130)
local EMPTY_COLOR = Color3.fromRGB(255, 255, 255)

local function setSignText(baseIndex: number, ownerName: string?, income: number)
	local base = getBase(baseIndex)
	local anchor = base and base:FindFirstChild("Hologram")
	local billboard = anchor and anchor:FindFirstChild("Yazi")
	if not billboard then
		return
	end

	local color = if ownerName then OWNED_COLOR else EMPTY_COLOR

	local nameLabel = billboard:FindFirstChild("Sahip")
	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.Text = if ownerName then string.upper(ownerName) else "EMPTY"
		nameLabel.TextColor3 = color
	end

	local incomeLabel = billboard:FindFirstChild("Gelir")
	if incomeLabel and incomeLabel:IsA("TextLabel") then
		incomeLabel.Text = if ownerName and income > 0 then Format.perSecond(income) else ""
	end

	local glow = anchor and anchor:FindFirstChild("Parilti")
	if glow and glow:IsA("PointLight") then
		glow.Color = color
	end
end

local function collectPadBul(baseIndex: number): BasePart?
	local pad = collectPads[baseIndex]
	if pad and pad.Parent then
		return pad
	end

	local base = getBase(baseIndex)
	local aday = base and base:FindFirstChild("ToplaButonu")
	if aday and aday:IsA("BasePart") then
		collectPads[baseIndex] = aday
		return aday
	end

	collectPads[baseIndex] = nil
	return nil
end

local function updateCollectButton(baseIndex: number)
	local pad = collectPadBul(baseIndex)
	if not pad then
		return
	end

	local cfg = Bases.CollectPad
	local waiting = pending[baseIndex] or 0

	local sahip = owners[baseIndex]
	pad:SetAttribute("SahipId", if sahip then sahip.UserId else nil)

	local gelirler: { string } = {}
	local toplam = 0
	if sahip then
		for _, item in PlayerData.placedItems(sahip) do
			if item.revealed and item.name then
				local gelir = Brainrots.income(item.name, item.condition :: any, item.mutation :: any) * Gelir.carpan(sahip)
				if gelir > 0 then
					table.insert(gelirler, string.format("%.2f", gelir))
					toplam += gelir
				end
			end
		end
	end

	pad:SetAttribute("SaniyelikGelir", toplam)
	pad:SetAttribute("SlotGelirleri", table.concat(gelirler, ","))

	local bekleme = math.max(0, (collectUntil[baseIndex] or 0) - os.clock())
	local ready = owners[baseIndex] ~= nil and waiting >= 1 and bekleme <= 0

	local renk = if bekleme > 0
		then cfg.cooldownColor
		elseif ready then cfg.color
		else cfg.idleColor

	pad.Color = renk

	local glow = pad:FindFirstChild("Parilti")
	if glow and glow:IsA("PointLight") then
		glow.Color = renk
		glow.Enabled = ready or bekleme > 0
	end

	local sign = pad:FindFirstChild("Yazi")
	local amount = sign and sign:FindFirstChild("Miktar")
	if amount and amount:IsA("TextLabel") then
		amount.Text = if bekleme > 0
			then `WAIT {math.ceil(bekleme)}s`
			elseif owners[baseIndex] then `{Format.short(math.floor(waiting))} Rot`
			else "EMPTY"
		amount.TextColor3 = if bekleme > 0
			then cfg.cooldownColor
			elseif ready then Bases.RotColor
			else cfg.idleColor
	end
end

function collectRot(player: Player, baseIndex: number)
	if owners[baseIndex] ~= player then
		return
	end

	if os.clock() < (collectUntil[baseIndex] or 0) then
		return
	end

	local waiting = pending[baseIndex] or 0
	local payout = math.floor(waiting)
	if payout < 1 then
		return
	end

	pending[baseIndex] = waiting - payout
	PlayerData.addRot(player, payout)
	Unvan.ilerlet(player, "rot", payout)

	local cfg = Bases.CollectPad
	collectUntil[baseIndex] = os.clock() + cfg.collectCooldown

	local pad = collectPads[baseIndex]
	if pad then
		Assets.playSoundAt(cfg.collectSound, pad)

		ParaSac:FireAllClients(player, pad.Position + Vector3.new(0, pad.Size.Y * 0.5, 0), payout)
	end

	updateCollectButton(baseIndex)

	task.delay(cfg.collectCooldown, function()
		updateCollectButton(baseIndex)
	end)

	Envanter.push(player)

	Bildirim:FireClient(player, `+{Format.short(payout)} Rot collected!`, Bases.RotColor)

	Ogretici.olay(player, "parayiAldi")
end

function pushBase(player: Player)
	local data = PlayerData.get(player)
	if not data or not data.base then
		return
	end

	local slots = {}
	for _, item in data.inventory do
		if item.slot then
			slots[item.slot] = {
				uid = item.uid,
				name = item.name,
				rarity = item.rarity,
				condition = item.condition,
				mutation = item.mutation,
				income = if item.name
					then Brainrots.income(item.name, item.condition :: any, item.mutation :: any) * Gelir.carpan(player)
					else 0,
			}
		end
	end

	local income = totalIncome(player)
	setSignText(data.base, player.DisplayName, income)

	BaseGuncelle:FireClient(player, {
		baseIndex = data.base,
		slotCount = Bases.SlotCount,
		floors = math.clamp(data.baseFloors or 1, 1, Bases.Upgrade.maxFloors),
		unlockedSlots = unlockedSlots(data),
		slots = slots,
		totalIncome = income,
		pending = pending[data.base] or 0,
	})
end

local function assignBase(player: Player): number?
	local data = PlayerData.get(player)
	if not data then
		return nil
	end

	for index, owner in owners do
		if owner == player then
			data.base = index
			return index
		end
	end

	for index = 1, Bases.Count do
		if owners[index] == nil then
			owners[index] = player
			data.base = index
			pending[index] = 0
			collectUntil[index] = 0
			setSignText(index, player.DisplayName, 0)
			updateCollectButton(index)

			applyFloors(index, data.baseFloors or 1)
			applySlots(index, unlockedSlots(data))
			updateSign(index)

			for _, item in data.inventory do
				if item.slot and item.revealed and item.name then
					showInSlot(index, item.slot, item)
				end
			end

			return index
		end
	end

	Bildirim:FireClient(player, "No free bases left!", Color3.fromRGB(255, 120, 120))
	return nil
end

local function releaseBase(player: Player)
	lastTouch[player] = nil

	local index: number? = nil
	for baseIndex, owner in owners do
		if owner == player then
			index = baseIndex
			break
		end
	end

	if not index then
		return
	end

	for slotIndex = 1, Bases.SlotCount do
		clearSlotModel(index, slotIndex)
	end

	owners[index] = nil
	pending[index] = nil
	setSignText(index, nil, 0)
	updateCollectButton(index)

	applyFloors(index, 1)
	applySlots(index, Bases.Upgrade.startingSlots)
	updateSign(index)
end

function bosBaseVar(): boolean
	for index = 1, Bases.Count do
		if owners[index] == nil then
			return true
		end
	end
	return false
end

local function baseGuvence(player: Player, data: any): number?
	if data.base and owners[data.base] == player then
		return data.base
	end

	data.base = nil
	if not bosBaseVar() then
		Bildirim:FireClient(player, "No free bases left!", Color3.fromRGB(255, 120, 120))
		return nil
	end

	local index = assignBase(player)
	if index then
		pushBase(player)
		return index
	end

	Bildirim:FireClient(player, "Your base is still loading, try again in a moment.", Color3.fromRGB(255, 200, 90))
	return nil
end

function placeInSlot(player: Player, uid: string, slotIndex: number)
	if slotIndex < 1 or slotIndex > Bases.SlotCount then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		Bildirim:FireClient(player, "Your data is still loading, try again in a moment.", Color3.fromRGB(255, 200, 90))
		return
	end
	if not baseGuvence(player, data) then
		return
	end

	local item = PlayerData.findItem(player, uid)
	if not item then
		return
	end

	if not item.revealed or not item.name then
		Bildirim:FireClient(player, "Take it to the Brainrot Detective first!", Color3.fromRGB(255, 200, 90))
		return
	end

	if slotIndex > unlockedSlots(data) then
		Bildirim:FireClient(player, `Slot {slotIndex} is locked.`, Color3.fromRGB(255, 200, 90))
		return
	end

	if item.slot then
		return
	end

	local swapped: any = nil
	for _, other in data.inventory do
		if other.slot == slotIndex then
			swapped = other
			break
		end
	end

	if swapped then
		clearSlotModel(data.base, slotIndex)
		swapped.slot = nil
	end

	item.slot = slotIndex
	showInSlot(data.base, slotIndex, item)

	playSlotSound(data.base, slotIndex)

	Envanter.syncBrainrots(player)
	Envanter.push(player)
	pushBase(player)

	GorevTakip.ilerlet(player, "place", 1)

	Ogretici.olay(player, "slotladi")

	local income = Brainrots.income(item.name, item.condition :: any, item.mutation :: any) * Gelir.carpan(player)
	local color = Rarity.color(item.rarity)

	if swapped then
		Bildirim:FireClient(
			player,
			`{item.name} placed ({swapped.name or "Brainrot"} returned)`,
			color
		)
	else
		Bildirim:FireClient(
			player,
			`{item.name} placed ({Format.perSecond(income)})`,
			color
		)
	end
end

function removeFromSlot(player: Player, uid: string)
	local data = PlayerData.get(player)
	if not data or not data.base then
		return
	end

	local item = PlayerData.findItem(player, uid)
	if not item or not item.slot then
		return
	end

	local eskiSlot = item.slot
	clearSlotModel(data.base, item.slot)
	item.slot = nil

	playSlotSound(data.base, eskiSlot)

	Envanter.syncBrainrots(player)
	Envanter.push(player)
	pushBase(player)

	Bildirim:FireClient(player, `{item.name or "Brainrot"} went back to your backpack.`, Color3.fromRGB(200, 210, 225))
end

local function refreshSlots(player: Player)
	local data = PlayerData.get(player)
	if not data or not data.base then
		return
	end

	local baseIndex = data.base

	local expected: { [number]: any } = {}
	for _, item in data.inventory do
		if item.slot and item.revealed and item.name then
			expected[item.slot] = item
		end
	end

	local models = slotModels[baseIndex] or {}

	for slotIndex = 1, Bases.SlotCount do
		local item = expected[slotIndex]
		local shown = models[slotIndex]

		if not item and shown then
			clearSlotModel(baseIndex, slotIndex)
		elseif item and not shown then
			showInSlot(baseIndex, slotIndex, item)
		end
	end

	pushBase(player)
end

local refreshEvent = Instance.new("BindableEvent")
refreshEvent.Name = "BaseYenile"
refreshEvent.Parent = script
refreshEvent.Event:Connect(refreshSlots)

SlotaKoy.OnServerEvent:Connect(function(player, uid, slotIndex)
	if type(uid) ~= "string" or type(slotIndex) ~= "number" then
		return
	end
	placeInSlot(player, uid, math.floor(slotIndex))
end)

SlottanAl.OnServerEvent:Connect(function(player, uid)
	if type(uid) ~= "string" then
		return
	end
	removeFromSlot(player, uid)
end)

local function gelirTuru()
	for _, player in Players:GetPlayers() do
		local data = PlayerData.get(player)
		local index = data and data.base
		if index then
			local income = totalIncome(player)
			if income > 0 then
				pending[index] = (pending[index] or 0) + income * Bases.PayoutInterval
			end
		end
	end

	for index = 1, Bases.Count do
		updateCollectButton(index)
	end
end

task.spawn(function()
	while true do
		task.wait(Bases.PayoutInterval)

		local ok, hata = pcall(gelirTuru)
		if not ok then
			warn(`[Base] Income loop error (loop continues): {tostring(hata)}`)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(3)
		for _, player in Players:GetPlayers() do
			local data = PlayerData.get(player)
			if data and data.base and owners[data.base] == player then
				pushBase(player)
			elseif data then
				data.base = nil
				if bosBaseVar() and assignBase(player) then
					pushBase(player)
				end
			end
		end
	end
end)

local function setupPlayer(player: Player)
	while player.Parent and not PlayerData.get(player) do
		task.wait(0.25)
	end
	if not player.Parent then
		return
	end

	local index = assignBase(player)
	if index then
		pushBase(player)
		Bildirim:FireClient(
			player,
			`Base {index} is yours`,
			Color3.fromRGB(140, 230, 160)
		)
	end
end

local ISINLANMA_BEKLEME = 3
local ISINLANMA_MESAFE = 7
local sonIsinlanma: { [Player]: number } = {}

BaseyeIsinlan.OnServerEvent:Connect(function(player)
	local simdi = os.clock()
	if simdi - (sonIsinlanma[player] or 0) < ISINLANMA_BEKLEME then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return
	end

	if character:GetAttribute("Kaziyor") == true then
		Bildirim:FireClient(player, "Finish digging first!", Color3.fromRGB(255, 200, 90))
		return
	end
	if player:GetAttribute("Flyboarding") == true then
		Bildirim:FireClient(player, "Get off your flyboard first!", Color3.fromRGB(255, 200, 90))
		return
	end

	local index = baseGuvence(player, data)
	if not index then
		return
	end

	local base = getBase(index)
	local pad = collectPads[index]
	local on = onYonleri[index]
	if not base or not pad or not on then
		Bildirim:FireClient(player, "Your base is not ready yet.", Color3.fromRGB(255, 200, 90))
		return
	end

	sonIsinlanma[player] = simdi

	local hedef = pad.Position + on * ISINLANMA_MESAFE + Vector3.new(0, 3.5, 0)
	local bakis = Vector3.new(pad.Position.X, hedef.Y, pad.Position.Z)
	character:PivotTo(CFrame.lookAt(hedef, bakis))
	root.AssemblyLinearVelocity = Vector3.zero

	Bildirim:FireClient(player, "Welcome home!", Color3.fromRGB(140, 230, 160))
end)

Players.PlayerAdded:Connect(function(player)
	task.spawn(setupPlayer, player)
end)

Players.PlayerRemoving:Connect(function(player)
	sonIsinlanma[player] = nil
end)

Players.PlayerRemoving:Connect(releaseBase)

for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end
