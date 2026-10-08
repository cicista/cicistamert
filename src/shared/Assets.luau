--!strict

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Mutations = require(script.Parent.Mutations)
local Rarity = require(script.Parent.Rarity)
local LuckyBlock = require(script.Parent.LuckyBlock)
local Divine = require(script.Parent.Divine)
local Petler = require(script.Parent.Petler)
local Flyboard = require(script.Parent.Flyboard)

local Assets = {}

Assets.Sounds = {
	detectorBeep = "",
	detectorBeepVolume = 0.5,
	detectorBeepRange = 80,
	detectorBeepFastest = 0.18,
	detectorBeepSlowest = 1.4,

	digSuccess = "",
	digFail = "",
	beamSpawn = "",
	placeBrainrot = "",
	sell = "",
}

Assets.Animations = {
	shovelHold = "",

	shovelDig = "rbxassetid://131623390335887",

	pickaxeDig = "rbxassetid://88699767550436",

	gpsHold = "",

	brainrotHold = "rbxassetid://97748738133693",

	idle = "rbxassetid://97769694813645",

	flyboardIdle = "rbxassetid://98909993111524",
	rodCast = "rbxassetid://130735035595565",
	fishing = "rbxassetid://122968362803524",
}

Assets.DigEffects = {
	color1 = Color3.fromRGB(190, 185, 175),
	color2 = Color3.fromRGB(120, 115, 108),
	size = 0.8,
	lifetimeMin = 0.4,
	lifetimeMax = 0.8,
	gravity = 30,

	sparkColor = Color3.fromRGB(255, 255, 255),
	sparkSize = 0.2,
	sparkLifetimeMin = 0.15,
	sparkLifetimeMax = 0.35,

	shovel = {
		animation = "shovelDig",
		particleTime = 0.25,
		count = 40,
		spread = 40,
		speedMin = 10,
		speedMax = 18,
		sparkCount = 10,
		sparkSpeedMin = 14,
		sparkSpeedMax = 24,
	},

	pickaxe = {
		animation = "pickaxeDig",
		particleTime = 0.15,
		count = 35,
		spread = 180,
		speedMin = 7,
		speedMax = 14,
		sparkCount = 16,
		sparkSpeedMin = 16,
		sparkSpeedMax = 28,
	},
}

Assets.FolderName = "Assets"

Assets.Categories = {
	brainrots = "Brainrots",
	luckyBlocks = "LuckyBlocks",
	scrolls = "Scrolls",
	shovels = "Shovels",
	pickaxes = "Pickaxes",
	rods = "Rods",
	detectors = "Detectors",
	vfx = "VFX",
	backgrounds = "Backgrounds",
	sounds = "Sounds",
	eggs = "Eggs",
	clovers = "Clovers",
}

function Assets.ensureFolders()
	local root = ReplicatedStorage:FindFirstChild(Assets.FolderName)
	if not root then
		local created = Instance.new("Folder")
		created.Name = Assets.FolderName
		created.Parent = ReplicatedStorage
		root = created
	end

	for _, name in Assets.Categories do
		if not root:FindFirstChild(name) then
			local folder = Instance.new("Folder")
			folder.Name = name
			folder.Parent = root
		end
	end
end

local function categoryFolder(category: string): Instance?
	local root = ReplicatedStorage:FindFirstChild(Assets.FolderName)
	return if root then root:FindFirstChild(category) else nil
end

function Assets.klasor(category: string): Instance?
	return categoryFolder(category)
end

function Assets.cloverModel(rarityId: string): Model?
	local folder = categoryFolder(Assets.Categories.clovers)
	if not folder then
		return nil
	end

	local found: Instance? = folder:FindFirstChild(rarityId, true)
	if not (found and found:IsA("Model")) then
		found = nil
		local aranan = string.lower(rarityId)
		for _, node in folder:GetDescendants() do
			if node:IsA("Model") and string.find(string.lower(node.Name), aranan, 1, true) then
				found = node
				break
			end
		end
	end

	return if found then (found :: Model):Clone() else nil
end

local function findModel(category: string, name: string?): Model?
	if not name or name == "" then
		return nil
	end

	local folder = categoryFolder(category)
	if not folder then
		return nil
	end

	local found = folder:FindFirstChild(name)

	if not found then
		found = folder:FindFirstChild(name, true)
	end

	if found and found:IsA("Model") then
		return found:Clone()
	end

	return nil
end

function Assets.playAnimations(model: Instance)
	for _, controller in model:GetDescendants() do
		if not controller:IsA("AnimationController") and not controller:IsA("Humanoid") then
			continue
		end

		local animator = controller:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = controller
		end

		for _, anim in controller.Parent:GetDescendants() do
			if anim:IsA("Animation") and anim.AnimationId ~= "" then
				local ok, track = pcall(function()
					return (animator :: Animator):LoadAnimation(anim)
				end)
				if ok and track then
					track.Looped = true
					track:Play()
				end
			end
		end
	end
end

local luckyWarned = false

local function luckyModelList(): { Model }
	local folder = categoryFolder(Assets.Categories.luckyBlocks)
	local list: { Model } = {}

	if folder then
		for _, node in folder:GetDescendants() do
			if node:IsA("Model") then
				table.insert(list, node)
			end
		end
	end

	if #list == 0 then
		for _, node in ReplicatedStorage:GetDescendants() do
			if node:IsA("Model") and string.find(string.lower(node.Name), "lucky", 1, true) then
				table.insert(list, node)
			end
		end
	end

	table.sort(list, function(a, b)
		return a.Name < b.Name
	end)

	return list
end

local function siraListesi(): { Model }
	local sabitlenmis: { [string]: boolean } = {}
	for _, tier in LuckyBlock.Tiers do
		if tier.modelName and tier.modelName ~= "" then
			sabitlenmis[string.lower(tier.modelName)] = true
		end
	end

	local out: { Model } = {}
	for _, model in luckyModelList() do
		if not sabitlenmis[string.lower(model.Name)] then
			table.insert(out, model)
		end
	end
	return out
end

local luckyListed = false

function Assets.listLuckyBlocks()
	if luckyListed then
		return
	end
	luckyListed = true

	local list = luckyModelList()
	if #list == 0 then
		return
	end

	local names = {}
	for index, model in list do
		table.insert(names, `{index}) {model.Name}`)
	end
	print(`[Assets] Lucky Block models: {table.concat(names, "  ")}`)
end

function Assets.luckyBlockModel(modelName: string?, order: number?): Model?
	local list = luckyModelList()

	local found: Model? = nil

	if modelName and modelName ~= "" then
		for _, model in list do
			if model.Name == modelName then
				found = model
				break
			end
		end

		if not found then
			local aranan = string.lower(modelName)
			for _, model in list do
				if string.find(string.lower(model.Name), aranan, 1, true) then
					found = model
					break
				end
			end
		end
	end

	if not found then
		local sira = siraListesi()
		if #sira > 0 then
			found = sira[math.clamp(order or 1, 1, #sira)]
		elseif #list > 0 then
			found = list[math.clamp(order or 1, 1, #list)]
		end
	end

	if not found then
		if not luckyWarned then
			luckyWarned = true
			warn(
				"[Assets] Lucky Block model not found. Put the models in "
					.. "ReplicatedStorage > Assets > LuckyBlocks "
					.. "(or include 'Lucky' in their names). Using a fallback cube for now."
			)
		end
		return nil
	end

	local clone = found:Clone()
	if not clone.PrimaryPart then
		clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart")
	end
	return clone
end

local function golgeyiKapat(model: Model?): Model?
	if not model then
		return nil
	end

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CastShadow = false
		end
	end

	return model
end

local function petHazirla(model: Model, ters: boolean?): Model
	local root = model:FindFirstChild("Root")
	local kok: BasePart? = if root and root:IsA("BasePart")
		then root
		else model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)

	for _, parca in model:GetDescendants() do
		if parca:IsA("BasePart") and parca.Transparency >= 0.99 then
			parca:SetAttribute(Assets.MeasureSkipAttribute, true)
		end
	end

	if not kok then
		return model
	end

	if ters then
		local donuk = Instance.new("Part")
		donuk.Name = "Root"
		donuk.Size = Vector3.one * 0.2
		donuk.Transparency = 1
		donuk.CanCollide = false
		donuk.CanQuery = false
		donuk.CanTouch = false
		donuk.Massless = true
		donuk.Anchored = kok.Anchored
		donuk.CFrame = kok.CFrame * CFrame.Angles(0, math.pi, 0)
		donuk:SetAttribute(Assets.MeasureSkipAttribute, true)
		donuk.Parent = model
		kok = donuk
	end

	local on = kok.CFrame.LookVector
	local duz = Vector3.new(on.X, 0, on.Z)
	if duz.Magnitude > 1e-3 then
		local aci = math.atan2(-duz.X, -duz.Z)
		local merkez = kok.Position
		model:PivotTo(CFrame.new(merkez) * CFrame.Angles(0, -aci, 0) * CFrame.new(-merkez) * model:GetPivot())
	end

	model.PrimaryPart = kok
	return model
end

local function petModeli(name: string, sessiz: boolean?): Model?
	local root = ReplicatedStorage:FindFirstChild(Assets.FolderName)
	if not root then
		return nil
	end

	local modelAdi = Petler.modelAdi(name)
	for _, paketAdi in Petler.Paketler do
		local paket = root:FindFirstChild(paketAdi)
		local bulunan = if paket then paket:FindFirstChild(modelAdi) else nil
		if bulunan and bulunan:IsA("Model") then
			return petHazirla(bulunan:Clone(), Petler.tersMi(name))
		end
	end

	if not sessiz then
		Assets.warnOnce(
			`pet missing: {modelAdi}`,
			`[Assets] pet model "{modelAdi}" not found in {table.concat(Petler.Paketler, ", ")}`
		)
	end
	return nil
end

local function karaIsaretle(model: Model?): Model?
	if model then
		model:SetAttribute(Flyboard.KaraNiteligi, true)
	end
	return golgeyiKapat(model)
end

function Assets.brainrotModel(name: string?, mutationId: string?): Model?
	if not name or name == "" then
		return nil
	end

	local pet = Petler.mi(name)

	if mutationId then
		local prefix = Mutations.get(mutationId).prefix
		if prefix ~= "" then
			local mutated = if pet
				then petModeli(prefix .. Petler.modelAdi(name), true)
				else findModel(Assets.Categories.brainrots, prefix .. name)
			if mutated then
				return karaIsaretle(mutated)
			end
		end
	end

	local model = if pet then petModeli(name) else findModel(Assets.Categories.brainrots, name)
	if model and Mutations.isSpecial(mutationId) then
		if pet then
			model:SetAttribute(Assets.MutasyonAttribute, Mutations.get(mutationId).id)
			CollectionService:AddTag(model, Assets.MutasyonTag)
		else
			Assets.mutasyonBoya(model, mutationId)
		end
	end

	return karaIsaretle(model)
end

function Assets.boyaliModel(name: string, mutationId: string?): Model?
	local root = ReplicatedStorage:FindFirstChild(Assets.FolderName)
	local bulunan = root and root:FindFirstChild(name)
	if not (bulunan and bulunan:IsA("Model")) then
		return nil
	end

	local model = bulunan:Clone()
	Assets.mutasyonBoya(model, mutationId)
	return golgeyiKapat(model)
end

Assets.ShovelIslandFolders = {
	kum = "Main",
	sekerkum = "Candy",
	snowkum = "Snow",
	alevkum = "Volcano",
} :: { [string]: string }

local function siraliModel(folder: Instance, sira: number): Instance?
	for _, child in folder:GetChildren() do
		if child:IsA("Model") or child:IsA("Tool") then
			if tonumber(string.match(child.Name, "(%d+)$")) == sira then
				return child
			end
		end
	end
	return nil
end

function Assets.shovelModel(shovelId: string, level: number?, island: string?): Model?
	local dogrudan = findModel(Assets.Categories.shovels, shovelId)
	if dogrudan or not level then
		return dogrudan
	end

	local kok = categoryFolder(Assets.Categories.shovels)
	local klasorAdi = Assets.ShovelIslandFolders[island or "kum"]
	local klasor = if kok and klasorAdi then kok:FindFirstChild(klasorAdi) else nil
	if not klasor then
		return nil
	end

	local bulunan = siraliModel(klasor, ((level - 1) % 5) + 1)
	return if bulunan and bulunan:IsA("Model") then bulunan:Clone() else nil
end

function Assets.pickaxeModel(pickaxeId: string): Model?
	return findModel(Assets.Categories.pickaxes, pickaxeId)
end

function Assets.rodTool(level: number): Instance?
	local kok = categoryFolder(Assets.Categories.rods)
	if not kok then
		return nil
	end
	local bulunan = kok:FindFirstChild(`Rod{level}`) or siraliModel(kok, level)
	return if bulunan then bulunan:Clone() else nil
end

Assets.ToolGrips = {
	shovel = {
		gripFromEnd = 0.6,
		bladeDown = false,
		spread = "inward",
		flip = {},
		gripOn = "sopa",
		gripRatio = 0.5,
		position = Vector3.new(0, 0, 0.2),
		rotation = Vector3.new(0, 0, 0),
	},
	pickaxe = {
		gripFromEnd = 0.6,
		bladeDown = false,
		spread = "forward",
		position = Vector3.new(0, 0, 0),
		rotation = Vector3.new(0, 0, 0),
	},
	rod = {
		gripRatio = 0.6,
		flip = { [3] = true },
		position = Vector3.new(0, 0, 0),
		rotation = Vector3.new(0, 0, 0),
	},
}

Assets.BodyItems = {
	reference = {
		UpperTorso = Vector3.new(1.246, 1.166, 1.086),
		LowerTorso = Vector3.new(0.864, 0.759, 0.672),
	} :: { [string]: Vector3 }?,
	shovel = {
		anchor = "center",
		position = Vector3.new(0, 0.1, 0.55),
		positionR6 = Vector3.new(0, 0.1, 0.55),
		rotation = Vector3.new(0, 0, -45),
		scale = 0.6,
	},
	pickaxe = {
		anchor = "center",
		position = Vector3.new(0, 0.1, 0.62),
		positionR6 = Vector3.new(0, 0.1, 0.62),
		rotation = Vector3.new(0, 0, 45),
		spin = 90,
		scale = 0.6,
	},
	gps = {
		position = Vector3.new(-0.6, -0.3, -0.1),
		positionR6 = Vector3.new(-0.6, -1.2, -0.1),
		rotation = Vector3.new(-40, 0, 0),
		scale = 0.6,
		lights = false,
	},
}

function Assets.detectorModel(detectorId: string): Model?
	return findModel(Assets.Categories.detectors, detectorId)
end

local function hush(node: Instance)
	if node:IsA("ParticleEmitter") or node:IsA("Light") then
		node.Enabled = false
	elseif node:IsA("Sound") then
		node:Stop()
		node.Playing = false
		node.Looped = false
	end
end

local function conceal(node: Instance)
	if node:IsA("BasePart") then
		node.Transparency = 1
		node.CanCollide = false
		node.CanQuery = false
		node.CanTouch = false
	end
end

local function silence(root: Instance)
	hush(root)
	conceal(root)

	for _, node in root:GetDescendants() do
		hush(node)
		conceal(node)
	end
end

local templateCache: { [string]: Instance } = {}

local function grabTemplate(name: string, category: string, hint: string, quiet: boolean?): Instance?
	local key = `{category}/{name}`

	local cached = templateCache[key]
	if cached then
		return cached:Clone()
	end

	local folder = categoryFolder(category)
	local found: Instance? = if folder then folder:FindFirstChild(name, true) else nil

	if not found then
		local root = ReplicatedStorage:FindFirstChild(Assets.FolderName)
		found = if root then root:FindFirstChild(name, true) else nil
	end

	local inWorkspace = false
	if not found then
		found = Workspace:FindFirstChild(name, true)
		inWorkspace = found ~= nil
	end

	if not found then
		if not quiet then
			Assets.warnOnce(`no template: {key}`, `[Assets] "{name}" not found. {hint}`)
		end
		return nil
	end

	local template = found:Clone()
	templateCache[key] = template

	if inWorkspace then
		silence(found)
	end

	return template:Clone()
end

local RARITY_VFX: { [string]: string } = {
	Secret = "DivineVFX",
	Cosmic = "CosmicVFX",
	Gizli = "SecretVFX",
	Infernal = "InfernalVFX",
	Abyssal = "AbyssalVFX",
}

Assets.RarityVFXScale = {} :: { [string]: number }

Assets.RarityVFXRate = {
	Secret = 0.5,
} :: { [string]: number }

local function vfxSikligi(root: Instance, carpan: number)
	if carpan == 1 then
		return
	end
	for _, node in root:GetDescendants() do
		if node:IsA("ParticleEmitter") then
			node.Rate *= carpan
		end
	end
end

Assets.RarityVFXAttribute = "KademeEfekti"

Assets.CountAttribute = "Adet"

Assets.RarityVFXMinScale = 0.1

function Assets.rarityVFXScale(model: Instance): number
	if model:IsA("Model") then
		local olcek = model:GetScale()
		if olcek > 0 then
			return math.max(olcek, Assets.RarityVFXMinScale)
		end
	end

	local enAz, enCok = Assets.worldBounds(model :: any)
	if not enAz or not enCok then
		return 1
	end

	local boy = enCok - enAz
	local uzun = math.max(boy.X, boy.Y, boy.Z)
	local taban = Assets.BrainrotSize.slotSize
	if taban > 0 and uzun > 0 then
		return math.max(uzun / taban, Assets.RarityVFXMinScale)
	end
	return 1
end

local function nadirlikVFXEkle(model: Instance, rarityId: string?, kok: BasePart?): Instance?
	local ad = if type(rarityId) == "string" then RARITY_VFX[rarityId] else nil
	if not ad then
		return nil
	end

	for _, node in model:GetDescendants() do
		if node:GetAttribute(Assets.RarityVFXAttribute) then
			return node
		end
	end

	local govde = kok
	if not govde then
		if model:IsA("BasePart") then
			govde = model
		elseif model:IsA("Model") then
			govde = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		elseif model:IsA("Tool") then
			local handle = model:FindFirstChild("Handle")
			govde = if handle and handle:IsA("BasePart") then handle else model:FindFirstChildWhichIsA("BasePart", true)
		end
	end

	if not govde then
		return nil
	end

	local bulunanSablon = Assets.vfxTemplate(ad)
	if not bulunanSablon then
		return nil
	end
	local sablon: Instance = bulunanSablon

	local parcaVar = sablon:IsA("BasePart") or sablon:FindFirstChildWhichIsA("BasePart", true) ~= nil

	if not parcaVar then
		local tutamak = Instance.new("Attachment")
		tutamak.Name = ad
		tutamak.Visible = false
		tutamak:SetAttribute(Assets.RarityVFXAttribute, true)

		local function topla(node: Instance)
			if node:IsA("Attachment") or node:IsA("Folder") or node:IsA("Model") or node:IsA("Configuration") then
				for _, cocuk in node:GetChildren() do
					topla(cocuk)
				end
			else
				node.Parent = tutamak
			end
		end
		topla(sablon)
		sablon:Destroy()

		if #tutamak:GetChildren() == 0 then
			tutamak:Destroy()
			Assets.warnOnce(
				`vfx empty: {ad}`,
				`[Assets] "{ad}" has no effects (no parts, particles or lights found).`
			)
			return nil
		end

		tutamak.Parent = govde
		Assets.scaleEffects(tutamak, Assets.rarityVFXScale(model) * (Assets.RarityVFXScale[rarityId :: string] or 1))
		vfxSikligi(tutamak, Assets.RarityVFXRate[rarityId :: string] or 1)
		return tutamak
	end

	if not sablon:IsA("BasePart") and not sablon:IsA("Model") then
		local sarici = Instance.new("Model")
		for _, cocuk in sablon:GetChildren() do
			cocuk.Parent = sarici
		end
		sablon:Destroy()
		sablon = sarici
	end

	sablon.Name = ad
	sablon.Parent = model

	local function yerlestir(parca: BasePart)
		parca:SetAttribute(Assets.RarityVFXAttribute, true)
		parca.Anchored = false
		parca.CanCollide = false
		parca.CanQuery = false
		parca.CanTouch = false
		parca.Massless = true

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = govde
		weld.Part1 = parca
		weld.Parent = parca
	end

	local carpan = Assets.rarityVFXScale(model) * (Assets.RarityVFXScale[rarityId :: string] or 1)

	local function olcekle(parca: BasePart)
		parca.Size *= carpan
	end

	if sablon:IsA("BasePart") then
		if carpan ~= 1 then
			olcekle(sablon)
		end
		sablon.CFrame = govde.CFrame
		yerlestir(sablon)
	elseif sablon:IsA("Model") then
		local kutuCF, kutuBoy = sablon:GetBoundingBox()
		local pivot = sablon:GetPivot()
		if (pivot.Position - kutuCF.Position).Magnitude > math.max(kutuBoy.X, kutuBoy.Y, kutuBoy.Z) then
			local yeniPivot = CFrame.new(kutuCF.Position) * pivot.Rotation
			local ana = sablon.PrimaryPart
			if ana then
				ana.PivotOffset = ana.CFrame:ToObjectSpace(yeniPivot)
			else
				sablon.WorldPivot = yeniPivot
			end
		end

		if carpan ~= 1 then
			if not sablon.PrimaryPart then
				sablon.PrimaryPart = sablon:FindFirstChildWhichIsA("BasePart", true)
			end

			local ok = pcall(function()
				sablon:ScaleTo(carpan)
			end)
			if not ok then
				for _, parca in sablon:GetDescendants() do
					if parca:IsA("BasePart") then
						olcekle(parca)
					end
				end
			end
		end

		sablon:PivotTo(govde.CFrame)
		for _, parca in sablon:GetDescendants() do
			if parca:IsA("BasePart") then
				yerlestir(parca)
			end
		end
	end

	Assets.scaleEffects(sablon, carpan)
	vfxSikligi(sablon, Assets.RarityVFXRate[rarityId :: string] or 1)

	return sablon
end

function Assets.attachRarityVFX(model: Instance, rarityId: string?, kok: BasePart?, mutationId: string?): Instance?
	for _, node in model:GetDescendants() do
		if node:GetAttribute(Assets.RarityVFXAttribute) then
			return node
		end
	end

	local vfx = nadirlikVFXEkle(model, rarityId, kok)
	if vfx and Mutations.isSpecial(mutationId) then
		Assets.tintEffects(vfx, Mutations.color(mutationId))
	end
	return vfx
end

local function vfxAra(name: string): Instance?
	local hedef = string.lower((string.gsub(name, "[%s_%-]", "")))

	local koklar: { Instance } = {}
	local assetKok = ReplicatedStorage:FindFirstChild(Assets.FolderName)
	if assetKok then
		table.insert(koklar, assetKok)
	end
	table.insert(koklar, ReplicatedStorage)
	table.insert(koklar, Workspace)

	for _, kok in koklar do
		for _, node in kok:GetDescendants() do
			if string.lower((string.gsub(node.Name, "[%s_%-]", ""))) == hedef then
				return node
			end
		end
	end

	return nil
end

local vfxAraOnbellek: { [string]: Instance } = {}

function Assets.vfxTemplate(name: string): Instance?
	local template = grabTemplate(
		name,
		Assets.Categories.vfx,
		"Put it in ReplicatedStorage > Assets (or Workspace). Continuing without the effect.",
		true
	)

	if not template then
		local onbellek = vfxAraOnbellek[name]
		if onbellek then
			template = onbellek:Clone()
		else
			local bulunan = vfxAra(name)
			if bulunan then
				vfxAraOnbellek[name] = bulunan:Clone()
				template = bulunan:Clone()
				if bulunan:IsDescendantOf(Workspace) then
					silence(bulunan)
				end
			end
		end
	end

	if not template then
		Assets.warnOnce(
			`vfx missing: {name}`,
			`[Assets] "{name}" not found. Put it in ReplicatedStorage > Assets `
				.. "(subfolder not required). Continuing without the effect."
		)
		return nil
	end

	for _, node in template:GetDescendants() do
		if node:IsA("Attachment") then
			node.Visible = false
		end
	end

	return template
end

Assets.HiddenBrainrot = {
	name = "Gold Ore",
	altNames = { "GoldOre", "Gold_Ore" },

	keepAll = true,

	tint = 0.6,

	paketAdi = "EggPack",
	kademeAdlari = {
	} :: { [string]: string },

	yumurtaTabani = 0.35,
	yumurtaOrani = 1.2,
	rarityScale = {} :: { [string]: number },
	default = 0.5,

	keepPart = "Cube",

	keepAttribute = "OzgunRenk",

	offset = Vector3.new(0, 0, 0),
	rotation = Vector3.new(0, 0, 0),
}

do
	local cfg = Assets.HiddenBrainrot
	for sira, kademe in Rarity.Order do
		if cfg.rarityScale[kademe] == nil then
			cfg.rarityScale[kademe] = cfg.yumurtaTabani * cfg.yumurtaOrani ^ (sira - 1)
		end
	end
end

function Assets.tintHidden(root: Instance, rarityId: string?)
	local cfg = Assets.HiddenBrainrot
	if not cfg.keepAll or type(rarityId) ~= "string" then
		return
	end

	if root:GetAttribute("KademeModeli") == true then
		return
	end
	local info = Rarity.Info[rarityId :: any]
	if not info then
		return
	end

	for _, node in root:GetDescendants() do
		if node:IsA("BasePart") and node.Transparency < 1 then
			node.Color = node.Color:Lerp(info.color, cfg.tint)
			Divine.tagIf(node, rarityId)
		end
	end
end

local function asModel(source: Instance): Model?
	if source:IsA("Model") then
		return source
	end

	local model = Instance.new("Model")
	model.Name = source.Name

	if source:IsA("BasePart") then
		source.Parent = model
	else
		for _, child in source:GetChildren() do
			child.Parent = model
		end
		source:Destroy()
	end

	if not model:FindFirstChildWhichIsA("BasePart", true) then
		model:Destroy()
		return nil
	end

	return model
end

local SKIP_ROOTS = {
	Terrain = true,
	Chat = true,
	TextChatService = true,
	MaterialService = true,
	CoreGui = true,
}

function Assets.searchRoots(): { Instance }
	local roots: { Instance } = {}

	local ok, services = pcall(function()
		return game:GetChildren()
	end)

	if not ok or not services then
		return roots
	end

	for _, service in services do
		if not SKIP_ROOTS[service.ClassName] and not SKIP_ROOTS[service.Name] then
			table.insert(roots, service)
		end
	end

	return roots
end

local function findHidden(name: string): Instance?
	local assetRoot = ReplicatedStorage:FindFirstChild(Assets.FolderName)
	if assetRoot then
		local direct = assetRoot:FindFirstChild(name, true)
		if direct then
			return direct
		end
	end

	local roots = Assets.searchRoots()

	for _, root in roots do
		local exact = root:FindFirstChild(name, true)
		if exact then
			return exact
		end
	end

	local target = string.lower(name)

	for _, root in roots do
		local ok, nodes = pcall(function()
			return root:GetDescendants()
		end)

		if ok and nodes then
			for _, node in nodes do
				local candidate = string.lower(node.Name)
				if candidate == target or string.gsub(candidate, "^%s*(.-)%s*$", "%1") == target then
					return node
				end
			end
		end
	end

	return nil
end

local hiddenCache: Model? = nil

local yumurtaListesi: { Instance }? = nil

local function yumurtalar(): { Instance }
	if yumurtaListesi then
		return yumurtaListesi
	end

	local liste: { Instance } = {}
	local cfg = Assets.HiddenBrainrot

	local TAM_ADLAR = { string.lower(cfg.paketAdi), "eggs", "egg", "yumurtalar", "yumurta" }

	local function sade(node: Instance): string
		return string.lower((string.gsub(node.Name, "[%s_%-]", "")))
	end

	local function tamPaket(node: Instance): boolean
		local ad = sade(node)
		for _, hedef in TAM_ADLAR do
			if ad == hedef then
				return true
			end
		end
		return false
	end

	local function paketMi(node: Instance): boolean
		local ad = sade(node)
		return string.find(ad, "egg", 1, true) ~= nil or string.find(ad, "yumurta", 1, true) ~= nil
	end

	local koklar: { Instance } = {}
	local assetKok = ReplicatedStorage:FindFirstChild(Assets.FolderName)
	if assetKok then
		table.insert(koklar, assetKok)
	end
	for _, kok in Assets.searchRoots() do
		table.insert(koklar, kok)
	end

	local function topla(kok: Instance, sinama: (Instance) -> boolean)
		for _, node in kok:GetDescendants() do
			if (node:IsA("Folder") or node:IsA("Model")) and sinama(node) then
				for _, cocuk in node:GetChildren() do
					if cocuk:IsA("Model") or cocuk:IsA("BasePart") then
						table.insert(liste, cocuk)
					end
				end
				return
			end
		end
	end

	for _, kok in koklar do
		topla(kok, tamPaket)
		if #liste > 0 then
			break
		end
	end

	if #liste == 0 then
		for _, kok in koklar do
			topla(kok, paketMi)
			if #liste > 0 then
				break
			end
		end
	end

	table.sort(liste, function(a, b)
		return a.Name < b.Name
	end)

	yumurtaListesi = liste
	return liste
end

local function sadeYumurtaAdi(ad: string): string
	local s = string.lower((string.gsub(ad, "[%s_%-]", "")))
	s = string.gsub(s, "egg", "")
	s = string.gsub(s, "yumurta", "")
	return s
end

local yumurtaHaritasi: { [string]: Instance }? = nil

local function yumurtaEslesmesi(): { [string]: Instance }
	if yumurtaHaritasi then
		return yumurtaHaritasi
	end

	local liste = yumurtalar()
	local harita: { [string]: Instance } = {}
	local kapili: { [Instance]: boolean } = {}

	local function bul(hedef: string, birebir: boolean?): Instance?
		local sade = if birebir then string.lower(hedef) else sadeYumurtaAdi(hedef)
		for _, model in liste do
			if kapili[model] then
				continue
			end
			local ad = if birebir then string.lower(model.Name) else sadeYumurtaAdi(model.Name)
			if ad == sade then
				return model
			end
		end
		return nil
	end

	for _, kademe in Rarity.Order do
		local elle = Assets.HiddenBrainrot.kademeAdlari[kademe]
		if elle then
			local model = bul(elle, true)
			if model then
				harita[kademe] = model
				kapili[model] = true
			end
		end
	end

	for _, kademe in Rarity.Order do
		if not harita[kademe] then
			local info = Rarity.Info[kademe]
			local model = if info then bul(info.displayName) else nil
			if model then
				harita[kademe] = model
				kapili[model] = true
			end
		end
	end

	for _, kademe in Rarity.Order do
		if not harita[kademe] then
			local model = bul(kademe)
			if model then
				harita[kademe] = model
				kapili[model] = true
			end
		end
	end

	if #liste > 0 then
		local satirlar, eksik = {}, {}
		for _, kademe in Rarity.Order do
			local info = Rarity.Info[kademe]
			local gorunen = if info then info.displayName else kademe
			if harita[kademe] then
				table.insert(satirlar, `{gorunen}={harita[kademe].Name}`)
			else
				table.insert(eksik, gorunen)
			end
		end
		print(`[Assets] Egg mapping ({#liste} models): {table.concat(satirlar, "  ")}`)
		if #eksik > 0 then
			warn(
				`[Assets] No egg found for these tiers: {table.concat(eksik, ", ")}. `
					.. "The egg name must contain the tier's display name "
					.. '(e.g. "Divine Egg").'
			)
		end
	end

	yumurtaHaritasi = harita
	return harita
end

local function yumurtaModeli(rarityId: string?): Instance?
	if type(rarityId) ~= "string" then
		return nil
	end
	return yumurtaEslesmesi()[rarityId]
end

function Assets.hiddenBrainrotModel(rarityId: string?): Model?
	local cfg = Assets.HiddenBrainrot

	local yumurta = yumurtaModeli(rarityId)
	if yumurta then
		local kopya = asModel(yumurta:Clone())
		if kopya then
			kopya:SetAttribute("KademeModeli", true)
			for _, node in kopya:GetDescendants() do
				if node:IsA("BasePart") then
					node:SetAttribute(cfg.keepAttribute, true)
				end
			end
			if yumurta:IsDescendantOf(Workspace) then
				silence(yumurta)
			end
			return golgeyiKapat(kopya)
		end
	end

	if hiddenCache then
		return golgeyiKapat(hiddenCache:Clone())
	end

	local found = findHidden(cfg.name)
	if not found then
		for _, ad in cfg.altNames do
			found = findHidden(ad)
			if found then
				break
			end
		end
	end

	if not found then
		Assets.warnOnce(
			`hidden brainrot missing: {cfg.name}`,
			`[Assets] "{cfg.name}" not found. Searched {#Assets.searchRoots()} services, `
				.. `Workspace has {#Workspace:GetChildren()} objects. `
				.. `If Explorer shows a different count, you are testing a different place file. `
				.. `Duz kutuya dusuldu.`
		)
		return nil
	end

	local model = asModel(found:Clone())
	if not model then
		Assets.warnOnce(
			`hidden brainrot empty: {cfg.name}`,
			`[Assets] "{cfg.name}" has no BasePart. Falling back to a plain box.`
		)
		return nil
	end

	local kept = 0
	for _, node in model:GetDescendants() do
		if node:IsA("BasePart") and (cfg.keepAll or string.lower(node.Name) == string.lower(cfg.keepPart)) then
			node:SetAttribute(cfg.keepAttribute, true)
			kept += 1
		end
	end

	if kept == 0 and not cfg.keepAll then
		Assets.warnOnce(
			`hidden brainrot keepPart: {cfg.keepPart}`,
			`[Assets] "{cfg.name}" has no part named "{cfg.keepPart}" -- everything will be tinted with the tier color.`
		)
	end

	hiddenCache = model

	if found:IsDescendantOf(Workspace) then
		silence(found)
	end

	print(`[Assets] Hidden brainrot model ready: {found:GetFullName()} ({found.ClassName}), kept parts: {kept}`)

	return golgeyiKapat(model:Clone())
end

local function soundTemplate(name: string, quiet: boolean?): Sound?
	local template = grabTemplate(
		name,
		Assets.Categories.sounds,
		"Put it in Workspace or ReplicatedStorage > Assets > Sounds. Continuing without sound.",
		quiet
	)

	if not template then
		return nil
	end

	if not template:IsA("Sound") then
		template:Destroy()
		return nil
	end

	return template
end

function Assets.playSoundAt(names: { string }, part: BasePart, maxLifetime: number?): Sound?
	for index, name in names do
		local sound = soundTemplate(name, index < #names)

		if sound then
			sound.Parent = part
			sound:Play()

			sound.Ended:Once(function()
				sound:Destroy()
			end)
			Debris:AddItem(sound, maxLifetime or 12)

			return sound
		end
	end

	return nil
end

function Assets.scaleEffects(root: Instance, factor: number)
	if factor == 1 then
		return
	end

	for _, node in root:GetDescendants() do
		if node:IsA("ParticleEmitter") then
			local keys = {}
			for _, key in node.Size.Keypoints do
				table.insert(keys, NumberSequenceKeypoint.new(key.Time, key.Value * factor, key.Envelope * factor))
			end
			node.Size = NumberSequence.new(keys)
			node.Speed = NumberRange.new(node.Speed.Min * factor, node.Speed.Max * factor)
		elseif node:IsA("Light") then
			node.Range = math.min(node.Range * factor, 60)
		end
	end
end

local function tint(original: Color3, target: Color3, preserveShading: boolean, vividness: number): Color3
	if not preserveShading then
		return target
	end

	local _, originalS, originalV = original:ToHSV()
	local targetH, targetS = target:ToHSV()

	local blended = originalS * targetS
	local saturation = blended + (targetS - blended) * vividness

	return Color3.fromHSV(targetH, math.clamp(saturation, 0, 1), originalV)
end

local function isProtected(node: Instance, root: Instance, keep: { string }?): boolean
	if not keep or #keep == 0 then
		return false
	end

	local cursor: Instance? = node
	while cursor do
		for _, name in keep do
			if cursor.Name == name then
				return true
			end
		end

		if cursor == root then
			return false
		end
		cursor = cursor.Parent
	end

	return false
end

function Assets.tintEffects(root: Instance, color: Color3, preserveShading: boolean?, keep: { string }?, vividness: number?)
	local keepShading = preserveShading ~= false
	local vivid = math.clamp(vividness or 0.85, 0, 1)

	local nodes = root:GetDescendants()
	table.insert(nodes, root)

	for _, node in nodes do
		if isProtected(node, root, keep) then
			continue
		end

		if node:IsA("ParticleEmitter") or node:IsA("Beam") or node:IsA("Trail") then
			local keys = {}
			for _, key in node.Color.Keypoints do
				table.insert(keys, ColorSequenceKeypoint.new(key.Time, tint(key.Value, color, keepShading, vivid)))
			end
			node.Color = ColorSequence.new(keys)
		elseif node:IsA("Light") then
			node.Color = tint(node.Color, color, keepShading, vivid)
		end
	end
end

function Assets.tintSurfaces(root: Instance, color: Color3, preserveShading: boolean?, keep: { string }?, vividness: number?)
	local keepShading = preserveShading ~= false
	local vivid = math.clamp(vividness or 0.85, 0, 1)

	local nodes = root:GetDescendants()
	table.insert(nodes, root)

	for _, node in nodes do
		if isProtected(node, root, keep) then
			continue
		end

		if node:IsA("BasePart") then
			if node.Transparency < 1 then
				node.Color = tint(node.Color, color, keepShading, vivid)
			end
		elseif node:IsA("Decal") or node:IsA("Texture") then
			node.Color3 = tint(node.Color3, color, keepShading, vivid)
		elseif node:IsA("ImageLabel") then
			node.ImageColor3 = tint(node.ImageColor3, color, keepShading, vivid)
		end
	end
end

export type MutasyonBoyasi = {
	alt: Color3,
	ust: Color3,
	yansima: number,
	canlilik: number,
	koyu: number?,
	gokkusagi: boolean?,
}

Assets.MutasyonBoyasi = {
	Gold = {
		alt = Color3.fromRGB(214, 150, 30),
		ust = Color3.fromRGB(255, 226, 110),
		yansima = 0.3,
		canlilik = 0.95,
	},
	Diamond = {
		alt = Color3.fromRGB(70, 175, 255),
		ust = Color3.fromRGB(205, 250, 255),
		yansima = 0.4,
		canlilik = 0.85,
	},
	Galaxy = {
		alt = Color3.fromRGB(95, 45, 210),
		ust = Color3.fromRGB(255, 90, 215),
		yansima = 0.15,
		canlilik = 0.95,
	},
	Lava = {
		alt = Color3.fromRGB(255, 70, 15),
		ust = Color3.fromRGB(255, 185, 50),
		yansima = 0,
		canlilik = 1,
		koyu = 0.6,
	},
	Rainbow = {
		alt = Color3.fromRGB(255, 80, 80),
		ust = Color3.fromRGB(180, 90, 255),
		yansima = 0.1,
		canlilik = 0.9,
		gokkusagi = true,
	},
	Hacker = {
		alt = Color3.fromRGB(40, 255, 100),
		ust = Color3.fromRGB(170, 255, 200),
		yansima = 0,
		canlilik = 1,
		koyu = 0.45,
	},
} :: { [string]: MutasyonBoyasi }

Assets.MutasyonTag = "MutasyonPet"
Assets.MutasyonAttribute = "Mutasyon"
function Assets.mutasyonBoya(root: Instance, mutationId: string?)
	local boya = Assets.MutasyonBoyasi[Mutations.get(mutationId).id]
	if not boya then
		return
	end

	local parcalar: { BasePart } = {}
	local enAlt, enUst = math.huge, -math.huge
	for _, node in root:GetDescendants() do
		if node:IsA("BasePart") and node.Transparency < 1 then
			table.insert(parcalar, node)
			enAlt = math.min(enAlt, node.Position.Y)
			enUst = math.max(enUst, node.Position.Y)
		end
	end

	local boy = math.max(enUst - enAlt, 1e-3)

	for _, parca in parcalar do
		local oran = math.clamp((parca.Position.Y - enAlt) / boy, 0, 1)
		local hedef = if boya.gokkusagi then Color3.fromHSV(oran * 0.83, 1, 1) else boya.alt:Lerp(boya.ust, oran)
		local neon = parca.Material == Enum.Material.Neon

		local renk = tint(parca.Color, hedef, true, boya.canlilik)
		local koyu = boya.koyu
		if koyu and not neon then
			local h, doygunluk, v = renk:ToHSV()
			renk = Color3.fromHSV(h, doygunluk, v * koyu)
		end

		parca.Color = renk
		if not neon then
			parca.Reflectance = math.max(parca.Reflectance, boya.yansima)
		end
	end

	Assets.tintEffects(root, boya.ust)
end

function Assets.stripScripts(root: Instance): number
	local doomed: { Instance } = {}

	for _, node in root:GetDescendants() do
		if node:IsA("LuaSourceContainer") then
			table.insert(doomed, node)
		end
	end

	for _, node in doomed do
		node:Destroy()
	end

	return #doomed
end

function Assets.rampEffects(root: Instance, color: Color3, opts: any, keep: { string }?)
	local lightMix = opts.lightMix or 0.45
	local darkMix = opts.darkMix or 0.35
	local emission = opts.lightEmission
	local brightness = opts.lightBrightness
	local extra = opts.extraTransparency or 0

	local cekirdek = color:Lerp(Color3.new(1, 1, 1), opts.coreMix or lightMix)
	local acik = color:Lerp(Color3.new(1, 1, 1), lightMix)
	local koyu = color:Lerp(Color3.new(0, 0, 0), darkMix)

	local gecis = ColorSequence.new({
		ColorSequenceKeypoint.new(0, cekirdek),
		ColorSequenceKeypoint.new(0.18, acik),
		ColorSequenceKeypoint.new(0.55, color),
		ColorSequenceKeypoint.new(1, koyu),
	})

	local nodes = root:GetDescendants()
	table.insert(nodes, root)

	for _, node in nodes do
		if isProtected(node, root, keep) then
			continue
		end

		if node:IsA("ParticleEmitter") or node:IsA("Beam") or node:IsA("Trail") then
			node.Color = gecis

			if emission and node:IsA("ParticleEmitter") then
				node.LightEmission = math.min(node.LightEmission, emission)
			end

			if extra > 0 then
				local keys = {}
				for _, key in node.Transparency.Keypoints do
					local value = math.clamp(key.Value + extra, 0, 1)
					local envelope = math.min(key.Envelope, value, 1 - value)
					table.insert(keys, NumberSequenceKeypoint.new(key.Time, value, envelope))
				end
				node.Transparency = NumberSequence.new(keys)
			end
		elseif node:IsA("Light") then
			node.Color = color
			if brightness then
				node.Brightness = math.min(node.Brightness, brightness)
			end
		end
	end
end

function Assets.removeDarkEffects(root: Instance, threshold: number, keep: { string }?)
	local doomed: { Instance } = {}

	for _, node in root:GetDescendants() do
		if isProtected(node, root, keep) then
			continue
		end

		if node:IsA("ParticleEmitter") or node:IsA("Trail") or node:IsA("Beam") then
			local brightest = 0
			for _, key in node.Color.Keypoints do
				local _, _, value = key.Value:ToHSV()
				if value > brightest then
					brightest = value
				end
			end

			if brightest <= threshold then
				table.insert(doomed, node)
			end
		end
	end

	for _, node in doomed do
		if node.Parent then
			node:Destroy()
		end
	end
end

function Assets.softenWhites(root: Instance, color: Color3, opts: any, keep: { string }?)
	local maxSaturation = opts.saturation or 0.35
	local minValue = opts.value or 0.8
	local greyValue = math.clamp(opts.grey or 0.35, 0, 1)
	local satRef = math.max(opts.saturationRef or 0.5, 0.01)
	local maxValue = math.clamp(opts.maxValue or 0.6, 0, 1)
	local highlightRatio = math.clamp(opts.highlight or 0.15, 0, 1)
	local glow = math.clamp(opts.glow or 0.05, 0, 1)

	local hue, saturation, value = color:ToHSV()
	local ceiling = greyValue + (maxValue - greyValue) * math.min(saturation / satRef, 1)
	local replacement = Color3.fromHSV(hue, saturation, math.min(value, ceiling))

	local highlight = Color3.fromHSV(0, 0, math.clamp(opts.highlightValue or 0.8, 0, 1))

	local function isWhite(shade: Color3): boolean
		local _, s, v = shade:ToHSV()
		return s <= maxSaturation and v >= minValue
	end

	local seen, kept = 0, 0

	local function pick(): Color3
		seen += 1
		local quota = math.floor(seen * highlightRatio + 0.5)
		if quota > kept then
			kept += 1
			return highlight
		end
		return replacement
	end

	for _, node in root:GetDescendants() do
		if isProtected(node, root, keep) then
			continue
		end

		if node:IsA("ParticleEmitter") or node:IsA("Trail") or node:IsA("Beam") then
			local touched = false
			local keys = {}

			for _, key in node.Color.Keypoints do
				local shade = key.Value
				if isWhite(shade) then
					shade = pick()
					touched = true
				end
				table.insert(keys, ColorSequenceKeypoint.new(key.Time, shade))
			end

			if touched then
				node.Color = ColorSequence.new(keys)

				if node:IsA("ParticleEmitter") then
					node.LightEmission = math.min(node.LightEmission, glow)
				end
			end
		elseif node:IsA("Light") and isWhite(node.Color) then
			node.Color = replacement
		elseif node:IsA("BasePart") and isWhite(node.Color) then
			node.Color = replacement
		end
	end
end

function Assets.playBurst(root: Instance, amount: number)
	for _, node in root:GetDescendants() do
		if node:IsA("ParticleEmitter") then
			node:Emit(amount)
		end
	end
end

function Assets.stopEmitters(root: Instance)
	for _, node in root:GetDescendants() do
		if node:IsA("ParticleEmitter") then
			node.Enabled = false
		end
	end
end

Assets.BrainrotGrip = {
	position = Vector3.new(0, 0, 0),
	rotation = Vector3.new(0, 0, 0),
}

Assets.BrainrotHold = {
	mode = "head",
	headGap = 0.25,
	headOffset = Vector3.new(0, 0, 0),
	headRotation = Vector3.new(0, 0, 0),
}

Assets.GPSGrip = {
	position = Vector3.new(0, 0, 0),
	rotation = Vector3.new(0, 0, 0),
}

Assets.BrainrotSize = {
	slotSize = 5,
	toolSize = 4.5,
	minScale = 0.01,
	maxScale = 25,
}

Assets.MeasureSkipAttribute = "OlcuDisi"

local warned: { [string]: boolean } = {}

function Assets.warnOnce(key: string, message: string)
	if warned[key] then
		return
	end
	warned[key] = true
	warn(message)
end

function Assets.worldBounds(model: Model): (Vector3?, Vector3?)
	local min: Vector3? = nil
	local max: Vector3? = nil

	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		if part:GetAttribute(Assets.MeasureSkipAttribute) then
			continue
		end

		local cf, size = part.CFrame, part.Size

		local half = Vector3.new(
			math.abs(cf.RightVector.X) * size.X / 2
				+ math.abs(cf.UpVector.X) * size.Y / 2
				+ math.abs(cf.LookVector.X) * size.Z / 2,
			math.abs(cf.RightVector.Y) * size.X / 2
				+ math.abs(cf.UpVector.Y) * size.Y / 2
				+ math.abs(cf.LookVector.Y) * size.Z / 2,
			math.abs(cf.RightVector.Z) * size.X / 2
				+ math.abs(cf.UpVector.Z) * size.Y / 2
				+ math.abs(cf.LookVector.Z) * size.Z / 2
		)

		local low = cf.Position - half
		local high = cf.Position + half

		min = if min then Vector3.new(math.min(min.X, low.X), math.min(min.Y, low.Y), math.min(min.Z, low.Z)) else low
		max = if max
			then Vector3.new(math.max(max.X, high.X), math.max(max.Y, high.Y), math.max(max.Z, high.Z))
			else high
	end

	return min, max
end

function Assets.fitModel(model: Model, targetSize: number, conditionScale: number)
	local cfg = Assets.BrainrotSize

	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end

	if not model.PrimaryPart then
		return
	end

	local min, max = Assets.worldBounds(model)
	if not min or not max then
		return
	end

	local size = max - min
	local largest = math.max(size.X, size.Y, size.Z)
	if largest <= 0 then
		return
	end

	local factor = (targetSize * conditionScale) / largest

	local ok, err = pcall(function()
		local scale = math.clamp(model:GetScale() * factor, cfg.minScale, cfg.maxScale)
		model:ScaleTo(scale)
	end)

	if not ok then
		Assets.warnOnce(`could not scale: {model.Name}`, `[Assets] "{model.Name}" could not be scaled -- {tostring(err)}`)
	end
end

function Assets.id(value: string?): string?
	if value and value ~= "" then
		return value
	end
	return nil
end

return Assets
