--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Config = require(Shared:WaitForChild("OyunConfig"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Flyboard = require(Shared:WaitForChild("Flyboard"))
local Divine = require(Shared:WaitForChild("Divine"))
local Ores = require(Shared:WaitForChild("Ores"))
local Fonts = require(Shared:WaitForChild("Fonts"))

local Sand = require(script.Parent:WaitForChild("Sand"))

local Beams = {}

local G = Config.GPS
local V = Config.BeamVFX
local W = Config.WhirlVFX

export type Beam = {
	id: string,
	owner: Player?,
	kind: string,
	position: Vector3,
	model: Model,
	bornAt: number,
	claimed: boolean,
	sea: boolean?,
	island: string?,
	herkes: boolean?,
	omur: number?,
	kazan: Player?,
}

local active: { [string]: Beam } = {}
local beamCounter = 0

local folder = Workspace:FindFirstChild("IsikSuzmeleri")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "IsikSuzmeleri"
	folder.Parent = Workspace
end

local function buildFallbackModel(kind: string, position: Vector3): Model
	local special = if kind == "LuckyBlock" then Rarity.LuckyBlock else nil

	local colorA = if special then special.colorA else Rarity.color(kind)
	local colorB = if special then special.colorB else colorA

	local model = Instance.new("Model")
	model.Name = `Suzme_{kind}`

	local column = Instance.new("Part")
	column.Name = "Column"
	column.Size = Vector3.new(2.6, 26, 2.6)
	column.CFrame = CFrame.new(position + Vector3.new(0, 13, 0))
	column.Anchored = true
	column.CanCollide = false
	column.CanQuery = false
	column.CanTouch = false
	column.CastShadow = false
	column.Material = Enum.Material.Neon
	column.Color = colorA
	column.Transparency = 0.55
	column.Parent = model
	model.PrimaryPart = column

	if special then
		task.spawn(function()
			local toBlack = TweenService:Create(column, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Color = colorB })
			local toGold = TweenService:Create(column, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Color = colorA })
			while column.Parent do
				toBlack:Play()
				toBlack.Completed:Wait()
				if not column.Parent then break end
				toGold:Play()
				toGold.Completed:Wait()
			end
		end)
	end

	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 6, 6)
	ring.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = colorA
	ring.Transparency = 0.3
	ring.Parent = model

	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, -12, 0)
	attachment.Parent = column

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorA),
		ColorSequenceKeypoint.new(1, colorB),
	})
	particles.Lifetime = NumberRange.new(1.2, 2)
	particles.Rate = 22
	particles.Speed = NumberRange.new(6, 10)
	particles.SpreadAngle = Vector2.new(8, 8)
	particles.Size = NumberSequence.new(0.8)
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.LightEmission = 1
	particles.Parent = attachment

	local light = Instance.new("PointLight")
	light.Color = colorA
	light.Range = 22
	light.Brightness = 3
	light.Parent = column

	if kind == "Secret" then
		Divine.tag(column)
		Divine.tag(ring)
		Divine.tag(light)
		Divine.tag(particles)
	end

	return model
end

local function step(label: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then
		Assets.warnOnce(
			`beam step: {label}`,
			`[Suzme] step "{label}" failed, skipped -- {tostring(err)}`
		)
	end
end

local function buildVFXModel(cfg, kind: string, position: Vector3): Model?
	local template = Assets.vfxTemplate(cfg.name)
	if not template then
		return nil
	end

	local color = Rarity.beamColor(kind)

	step("hide", function()
		for _, name in cfg.hide do
			local doomed = template:FindFirstChild(name, true)
			while doomed do
				doomed:Destroy()
				doomed = template:FindFirstChild(name, true)
			end
		end
	end)

	if cfg.stripScripts then
		step("script temizligi", function()
			Assets.stripScripts(template)
		end)
	end

	if cfg.removeDark then
		step("siyah katman", function()
			Assets.removeDarkEffects(template, cfg.darkThreshold, cfg.keepColor)
		end)
	end

	step("renklendirme", function()
		Assets.tintEffects(template, color, cfg.preserveShading, cfg.keepColor, cfg.vividness)
	end)

	if cfg.tintParts then
		step("yuzey renklendirme", function()
			Assets.tintSurfaces(template, color, cfg.preserveShading, cfg.keepColor, cfg.vividness)
		end)
	end

	if cfg.ramp then
		step("parcacik gecisi", function()
			Assets.rampEffects(template, color, cfg.ramp, cfg.keepColor)
		end)
	end

	if cfg.softenWhite then
		step("beyaz yumusatma", function()
			Assets.softenWhites(template, color, {
				saturation = cfg.whiteSaturation,
				value = cfg.whiteValue,
				grey = cfg.whiteGrey,
				saturationRef = cfg.whiteSaturationRef,
				maxValue = cfg.whiteMaxValue,
				highlight = cfg.whiteHighlight,
				highlightValue = cfg.whiteHighlightValue,
				glow = cfg.whiteGlow,
			}, cfg.keepColor)
		end)
	end

	local function yerlestirmeKaymasi(min: Vector3, max: Vector3): Vector3
		local tabanY = cfg.fixedY or position.Y
		local targetY = tabanY + cfg.height
		local shiftY = if cfg.alignToGround
			then targetY - min.Y
			else targetY - (min.Y + max.Y) / 2

		return Vector3.new(
			position.X - (min.X + max.X) / 2,
			shiftY,
			position.Z - (min.Z + max.Z) / 2
		)
	end

	type ZeminParcasi = {
		part: BasePart,
		cframe: CFrame,
		size: Vector3,
		meshes: { [SpecialMesh]: Vector3 },
	}
	local zeminParcalari: { ZeminParcasi } = {}
	local kademeOlcegi = (cfg.baseScale or 1) * (cfg.scaleByRarity[kind] or 1)

	if cfg.groundParts and #cfg.groundParts > 0 and kademeOlcegi ~= 1
		and (template:IsA("Model") or template:IsA("BasePart"))
	then
		step("ground parts", function()
			local gecici = Instance.new("Model")
			local eskiEbeveyn = template.Parent
			template.Parent = gecici
			local min, max = Assets.worldBounds(gecici)
			template.Parent = eskiEbeveyn
			gecici:Destroy()

			if not min or not max then
				return
			end

			local commonKaymasi = yerlestirmeKaymasi(min, max)

			local function zeminde(node: Instance): boolean
				local cursor: Instance? = node
				while cursor and cursor ~= template do
					for _, ad in cfg.groundParts do
						if cursor.Name == ad then
							return true
						end
					end
					cursor = cursor.Parent
				end
				return false
			end

			for _, node in template:GetDescendants() do
				if node:IsA("BasePart") and zeminde(node) then
					local meshes = {}
					for _, child in node:GetChildren() do
						if child:IsA("SpecialMesh") then
							meshes[child] = child.Scale
						end
					end

					table.insert(zeminParcalari, {
						part = node,
						cframe = node.CFrame + commonKaymasi,
						size = node.Size,
						meshes = meshes,
					})
				end
			end
		end)
	end

	local scale = (cfg.baseScale or 1) * (cfg.scaleByRarity[kind] or 1)
	if scale ~= 1 then
		step("olcekleme", function()
			Assets.scaleEffects(template, scale)

			if template:IsA("Model") then
				local asModel = template :: Model
				asModel:ScaleTo(asModel:GetScale() * scale)
			elseif template:IsA("BasePart") then
				template.Size *= scale
			end
		end)
	end

	local model = Instance.new("Model")
	model.Name = `{cfg.label}_{kind}`

	if template:IsA("Model") or template:IsA("BasePart") then
		template.Parent = model
	else
		for _, child in template:GetChildren() do
			child.Parent = model
		end
		template:Destroy()

		Assets.warnOnce(
			`{cfg.label} vfx sinifi: {cfg.name}`,
			`[{cfg.label}] "{cfg.name}" is a {template.ClassName}; its contents were moved.`
		)
	end

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end

	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end

	step("yerlestirme", function()
		local min, max = Assets.worldBounds(model)
		if not min or not max then
			return
		end

		local shift = yerlestirmeKaymasi(min, max)

		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.CFrame = part.CFrame + shift
			end
		end
	end)

	if #zeminParcalari > 0 then
		step("ground parts restore", function()
			local taslar: { [Instance]: boolean } = {}
			for _, kayit in zeminParcalari do
				taslar[kayit.part] = true
			end

			for _, node in model:GetDescendants() do
				if node:IsA("JointInstance") then
					if taslar[node.Part0 :: any] or taslar[node.Part1 :: any] then
						node:Destroy()
					end
				elseif node:IsA("WeldConstraint") or node:IsA("RigidConstraint") then
					local a = if node:IsA("WeldConstraint") then node.Part0 else nil
					local b = if node:IsA("WeldConstraint") then node.Part1 else nil
					if node:IsA("RigidConstraint") then
						a = node.Attachment0 and node.Attachment0.Parent :: any
						b = node.Attachment1 and node.Attachment1.Parent :: any
					end
					if taslar[a :: any] or taslar[b :: any] then
						node:Destroy()
					end
				end
			end

			for _, kayit in zeminParcalari do
				if kayit.part.Parent then
					kayit.part.Anchored = true
					kayit.part.Size = kayit.size
					kayit.part.CFrame = kayit.cframe
					for mesh, olcek in kayit.meshes do
						mesh.Scale = olcek
					end
				end
			end
		end)
	end

	if kind == "Secret" then
		for _, node in model:GetDescendants() do
			if node:IsA("Light") then
				Divine.tag(node)
			end
		end
	end

	return model
end

local function buildFallbackWhirl(kind: string, position: Vector3): Model
	local special = if kind == "LuckyBlock" then Rarity.LuckyBlock else nil

	local colorA = if special then special.colorA else Rarity.color(kind)
	local colorB = if special then special.colorB else colorA

	local model = Instance.new("Model")
	model.Name = `Girdap_{kind}`

	local core = Instance.new("Part")
	core.Name = "Govde"
	core.Size = Vector3.new(1, 6, 1)
	core.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	core.Transparency = 1
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.CanTouch = false
	core.Parent = model

	local dip = Instance.new("Attachment")
	dip.Name = "Dip"
	dip.Position = Vector3.new(0, -3, 0)
	dip.Parent = core

	local agiz = Instance.new("Attachment")
	agiz.Name = "Agiz"
	agiz.Position = Vector3.new(0, 3, 0)
	agiz.Parent = core

	local huni = Instance.new("Beam")
	huni.Name = "Huni"
	huni.Attachment0 = dip
	huni.Attachment1 = agiz
	huni.Width0 = 0.5
	huni.Width1 = 5
	huni.FaceCamera = true
	huni.LightEmission = 0.3
	huni.LightInfluence = 0
	huni.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorB),
		ColorSequenceKeypoint.new(1, colorA),
	})
	huni.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 0.55),
	})
	huni.Parent = core

	local halka = Instance.new("Part")
	halka.Name = "Halka"
	halka.Shape = Enum.PartType.Cylinder
	halka.Size = Vector3.new(0.2, 5, 5)
	halka.CFrame = CFrame.new(position + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	halka.Anchored = true
	halka.CanCollide = false
	halka.CanQuery = false
	halka.CanTouch = false
	halka.CastShadow = false
	halka.Material = Enum.Material.Neon
	halka.Color = colorA
	halka.Transparency = 0.35
	halka.Parent = model

	local serpinti = Instance.new("ParticleEmitter")
	serpinti.Name = "Serpinti"
	serpinti.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorA),
		ColorSequenceKeypoint.new(1, colorB),
	})
	serpinti.Lifetime = NumberRange.new(0.6, 1.1)
	serpinti.Rate = 26
	serpinti.Speed = NumberRange.new(5, 9)
	serpinti.SpreadAngle = Vector2.new(14, 14)
	serpinti.Size = NumberSequence.new(0.7)
	serpinti.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	serpinti.LightEmission = 0.4
	serpinti.Parent = dip

	local isik = Instance.new("PointLight")
	isik.Color = colorA
	isik.Range = 18
	isik.Brightness = 2
	isik.Parent = core

	model.PrimaryPart = core
	return model
end

local function buildWithVFX(
	cfg: any,
	kind: string,
	position: Vector3,
	fallback: (string, Vector3) -> Model
): Model
	local ok, result = pcall(buildVFXModel, cfg, kind, position)

	if ok and result then
		return result
	end

	if not ok then
		Assets.warnOnce(
			`{cfg.label} vfx hatasi`,
			`[{cfg.label}] VFX setup failed, using the fallback look -- {tostring(result)}`
		)
	end

	return fallback(kind, position)
end

local KAYA_BLOKLARI = {
	{ Vector3.new(3.4, 5.6, 3.0), Vector3.new(0, 2.8, 0), Vector3.new(0.08, 0, -0.1), Color3.fromRGB(78, 70, 64) },
	{ Vector3.new(2.8, 3.6, 2.6), Vector3.new(1.5, 1.8, 0.6), Vector3.new(0, 0.4, 0.18), Color3.fromRGB(64, 58, 54) },
	{ Vector3.new(2.4, 2.6, 2.4), Vector3.new(-1.5, 1.3, 0.3), Vector3.new(0.1, -0.3, -0.2), Color3.fromRGB(88, 80, 72) },
	{ Vector3.new(1.8, 2.0, 1.8), Vector3.new(0.1, 6.2, 0.2), Vector3.new(0.25, 0.5, 0.15), Color3.fromRGB(70, 64, 60) },
}

local KRISTALLER = {
	{ Vector3.new(1.4, 3.8, 0.9), Vector2.new(0.3, -0.75), 1.7 },
	{ Vector3.new(1.9, 1.5, -0.6), Vector2.new(0, -1.1), 1.9 },
	{ Vector3.new(-1.8, 1.2, 0.8), Vector2.new(0.4, 1.0), 1.6 },
	{ Vector3.new(-0.4, 5.4, -0.3), Vector2.new(-0.3, 0.5), 1.3 },
	{ Vector3.new(0.2, 0.7, 1.8), Vector2.new(1.1, 0.1), 1.5 },
	{ Vector3.new(-1.0, 3.0, -1.4), Vector2.new(-0.9, 0.4), 1.4 },
}

local function kayaParcasi(parent: Instance, name: string): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function buildOreModel(kind: string, position: Vector3): Model
	local maden = Ores.get(kind)
	local renk = if maden then maden.color else Color3.new(1, 1, 1)
	local rng = Random.new()

	local koyu = (renk.R + renk.G + renk.B) / 3 < 0.25

	local model = Instance.new("Model")
	model.Name = `Maden_{kind}`

	local taban = CFrame.new(position) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)

	for i, blok in KAYA_BLOKLARI do
		local part = kayaParcasi(model, if i == 1 then "Govde" else "Kaya")
		part.Size = blok[1]
		part.Color = blok[4]
		part.Material = Enum.Material.Slate
		part.CFrame = taban * CFrame.new(blok[2]) * CFrame.Angles(blok[3].X, blok[3].Y, blok[3].Z)

		if i == 1 then
			model.PrimaryPart = part
		end
	end

	for i, kristal in KRISTALLER do
		local kok = taban * CFrame.new(kristal[1])
		local egim = CFrame.Angles(kristal[2].X, 0, kristal[2].Y)

		for j, olcek in { 1, 0.6 } do
			local uzunluk = kristal[3] * olcek
			local kalinlik = 0.5 * (if j == 1 then 1 else 0.75)

			local part = kayaParcasi(model, "Kristal")
			part.Color = renk
			part.CastShadow = false

			if koyu then
				part.Material = Enum.Material.Glass
				part.Reflectance = 0.5
			else
				part.Material = Enum.Material.Neon
			end

			local yan = if j == 1 then CFrame.identity else CFrame.new(0.35, 0, 0.2) * CFrame.Angles(0.35, 0, -0.3)

			if maden and maden.shape == "ball" then
				local cap = uzunluk * 0.55
				part.Shape = Enum.PartType.Ball
				part.Size = Vector3.new(cap, cap, cap)
				part.CFrame = kok * egim * yan * CFrame.new(0, cap * 0.2, 0)
			else
				part.Size = Vector3.new(kalinlik, uzunluk, kalinlik)
				part.CFrame = kok
					* egim
					* yan
					* CFrame.Angles(0, math.pi / 4 + i * 0.3, 0)
					* CFrame.new(0, uzunluk * 0.35, 0)
			end
		end
	end

	local isik = Instance.new("PointLight")
	isik.Color = if koyu then Color3.fromRGB(120, 90, 170) else renk
	isik.Range = 14
	isik.Brightness = if koyu then 0.8 else 2
	isik.Parent = model.PrimaryPart

	return model
end

local function buildBeamModel(kind: string, position: Vector3): Model
	return buildWithVFX(V, kind, position, buildFallbackModel)
end

local function buildWhirlModel(kind: string, position: Vector3): Model
	return buildWithVFX(W, kind, position, buildFallbackWhirl)
end

local ARAMA_YUKSEKLIK = 80
local ARAMA_DERINLIK = 200
local ATLANABILIR_EN_FAZLA = 8

local function kumBul(x: number, ustY: number, z: number, haric: { Instance }): Sand.GroundInfo?
	local liste = table.clone(haric)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	for _ = 1, ATLANABILIR_EN_FAZLA do
		params.FilterDescendantsInstances = liste
		local sonuc = Workspace:Raycast(Vector3.new(x, ustY, z), Vector3.new(0, -ARAMA_DERINLIK, 0), params)
		if not sonuc then
			return nil
		end

		local parca = sonuc.Instance
		if parca:IsA("BasePart") and (not parca.CanCollide or parca.Transparency >= 0.95) then
			table.insert(liste, parca)
			continue
		end

		local zemin = Sand.probe(sonuc.Position + Vector3.new(0, 0.5, 0), liste)
		if zemin and zemin.isSand then
			return zemin
		end
		return nil
	end

	return nil
end

local sorguParcasi = Instance.new("Part")
sorguParcasi.Name = "SuzmeYerSorgusu"
sorguParcasi.Size = Vector3.new(2.5, 4.5, 2.5)
sorguParcasi.Anchored = true
sorguParcasi.CanCollide = false
sorguParcasi.CanQuery = false
sorguParcasi.CanTouch = false
sorguParcasi.Transparency = 1

local function ustuBosMu(konum: Vector3, zeminParcasi: BasePart?, haric: { Instance }): boolean
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	local liste = table.clone(haric)
	if zeminParcasi then
		table.insert(liste, zeminParcasi)
	end
	overlap.FilterDescendantsInstances = liste

	sorguParcasi.CFrame = CFrame.new(konum + Vector3.new(0, 0.4 + sorguParcasi.Size.Y / 2, 0))
	if not sorguParcasi.Parent then
		sorguParcasi.Parent = Workspace
	end

	for _, parca in Workspace:GetPartsInPart(sorguParcasi, overlap) do
		if parca ~= sorguParcasi and parca.CanCollide and parca.Transparency < 0.95 then
			return false
		end
	end
	return true
end

local function findSandSpot(player: Player): (Vector3?, string?)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end

	local origin = root.Position
	local haric: { Instance } = { folder }
	for _, diger in Players:GetPlayers() do
		if diger.Character then
			table.insert(haric, diger.Character)
		end
	end

	for _ = 1, 16 do
		local angle = math.random() * math.pi * 2
		local distance = math.random() * (G.maxSpawnDistance - G.minSpawnDistance) + G.minSpawnDistance
		local x = origin.X + math.cos(angle) * distance
		local z = origin.Z + math.sin(angle) * distance

		local ground = kumBul(x, origin.Y + ARAMA_YUKSEKLIK, z, haric)
		if ground and ground.isSand and ustuBosMu(ground.position, ground.part, haric) then
			return ground.position, Brainrots.islandOf(ground.part)
		end
	end

	return nil
end

function Beams.countFor(player: Player, sea: boolean?): number
	local count = 0
	for _, beam in active do
		if beam.owner == player and not beam.claimed then
			if sea == nil or (beam.sea == true) == sea then
				count += 1
			end
		end
	end
	return count
end

local ETIKET_ADI = "SuzmeEtiketi"

local function etiketKur(model: Model, player: Player, kind: string, spot: Vector3)
	local ana = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not ana then
		return
	end

	local renk = Rarity.beamColor(kind)

	local gui = Instance.new("BillboardGui")
	gui.Name = ETIKET_ADI
	gui.Size = UDim2.fromOffset(150, 52)
	gui.StudsOffsetWorldSpace = (spot + Vector3.new(0, 16, 0)) - ana.Position
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = G.scanRadius + 20
	gui:SetAttribute("Kind", kind)
	gui:SetAttribute("Owner", player.UserId)

	local kart = Instance.new("Frame")
	kart.Name = "Kart"
	kart.Size = UDim2.fromScale(1, 1)
	kart.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
	kart.BackgroundTransparency = 0.25
	kart.BorderSizePixel = 0
	kart.Parent = gui

	local kose = Instance.new("UICorner")
	kose.CornerRadius = UDim.new(0, 10)
	kose.Parent = kart

	local cerceve = Instance.new("UIStroke")
	cerceve.Name = "Cerceve"
	cerceve.Color = renk
	cerceve.Thickness = 2
	cerceve.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cerceve.Parent = kart

	local ad = Instance.new("TextLabel")
	ad.Name = "Kind"
	ad.BackgroundTransparency = 1
	ad.Size = UDim2.new(1, -8, 0.6, 0)
	ad.Position = UDim2.fromOffset(4, 2)
	ad.Text = string.upper(Rarity.beamName(kind))
	ad.TextColor3 = renk
	ad.TextSize = 20
	Fonts.apply(ad)
	ad.Parent = kart

	local sahip = Instance.new("TextLabel")
	sahip.Name = "Sahip"
	sahip.BackgroundTransparency = 1
	sahip.Size = UDim2.new(1, -8, 0.4, -2)
	sahip.Position = UDim2.new(0, 4, 0.6, 0)
	sahip.Text = `{player.DisplayName}'s`
	sahip.TextColor3 = Color3.fromRGB(200, 205, 215)
	sahip.TextSize = 14
	Fonts.apply(sahip)
	sahip.Parent = kart

	gui.Parent = ana
end

local function createBeam(player: Player, kind: string, spot: Vector3, sea: boolean?, island: string?): Beam
	beamCounter += 1
	local id = `beam_{beamCounter}`

	local model = if sea
		then buildWhirlModel(kind, spot)
		elseif Ores.get(kind) then buildOreModel(kind, spot)
		else buildBeamModel(kind, spot)
	model:SetAttribute("BeamId", id)
	model:SetAttribute("Owner", player.UserId)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	etiketKur(model, player, kind, spot)
	model.Parent = folder

	if sea and W.spin and W.spin ~= 0 then
		model:SetAttribute("DonusHizi", W.spin)
		CollectionService:AddTag(model, W.spinTag)
	end

	local beam: Beam = {
		id = id,
		owner = player,
		kind = kind,
		position = spot,
		model = model,
		bornAt = os.clock(),
		claimed = false,
		sea = sea,
		island = if sea then "deniz" else island,
	}
	active[id] = beam

	if Beams.Debug then
		print(`[Suzme] SPAWNED {id} ({kind}) owner={player.Name} total={Beams.countFor(player)}`)
	end

	return beam
end

local function herkesEtiketi(model: Model, spot: Vector3, kind: string)
	local ana = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not ana then
		return
	end

	local renk = Rarity.beamColor(kind)

	local gui = Instance.new("BillboardGui")
	gui.Name = ETIKET_ADI
	gui.Size = UDim2.fromOffset(240, 70)
	gui.StudsOffsetWorldSpace = (spot + Vector3.new(0, 28, 0)) - ana.Position
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = math.huge
	gui:SetAttribute("Kind", kind)

	local ad = Instance.new("TextLabel")
	ad.Name = "Kind"
	ad.BackgroundTransparency = 1
	ad.Size = UDim2.new(1, 0, 0.6, 0)
	ad.Text = string.upper(Rarity.beamName(kind))
	ad.TextColor3 = renk
	ad.TextSize = 30
	Fonts.apply(ad)
	ad.Parent = gui

	local alt = Instance.new("TextLabel")
	alt.Name = "Alt"
	alt.BackgroundTransparency = 1
	alt.Size = UDim2.new(1, 0, 0.4, 0)
	alt.Position = UDim2.fromScale(0, 0.6)
	alt.Text = "FIRST TO DIG WINS!"
	alt.TextColor3 = Color3.fromRGB(255, 255, 255)
	alt.TextSize = 18
	Fonts.apply(alt)
	alt.Parent = gui

	gui.Parent = ana
end

function Beams.spawnPublic(kind: string, spot: Vector3, island: string?, omur: number): Beam
	beamCounter += 1
	local id = `beam_{beamCounter}`

	local model = buildBeamModel(kind, spot)
	for _, parca in model:GetDescendants() do
		if parca:IsA("BasePart") then
			parca.CanCollide = false
			parca.CanQuery = false
			parca.CanTouch = false
		end
	end
	model:SetAttribute("BeamId", id)
	model:SetAttribute("Herkes", true)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	herkesEtiketi(model, spot, kind)
	model.Parent = folder

	local beam: Beam = {
		id = id,
		owner = nil,
		kind = kind,
		position = spot,
		model = model,
		bornAt = os.clock(),
		claimed = false,
		island = island,
		herkes = true,
		omur = omur,
	}
	active[id] = beam

	return beam
end

local function findSeaSpot(player: Player, maxDistance: number?): Vector3?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, folder }

	local origin = root.Position

	local function uygun(nokta: Vector3): boolean
		for _, beam in active do
			if beam.owner == player and (beam.position - nokta).Magnitude < G.seaSeparation then
				return false
			end
		end
		return true
	end

	local enUzak = math.max((maxDistance or G.seaMaxSpawnDistance) * 0.9, G.seaMinSpawnDistance + 10)
	local yaricap = enUzak - G.seaMinSpawnDistance

	for _ = 1, 30 do
		local angle = math.random() * math.pi * 2
		local distance = math.random() * yaricap + G.seaMinSpawnDistance
		local candidate = origin + Vector3.new(math.cos(angle) * distance, 12, math.sin(angle) * distance)

		local hit = Workspace:Raycast(candidate, Vector3.new(0, -80, 0), params)
		if hit then
			local suMu = hit.Material == Enum.Material.Water or Flyboard.isSeaInstance(hit.Instance)

			if suMu and uygun(hit.Position) then
				return hit.Position
			end
		end
	end

	return nil
end

local function adaIzni(ada: string?): (string) -> boolean
	return function(kademe: string): boolean
		return Brainrots.availableOn(kademe, ada)
	end
end

function Beams.trySpawnSea(player: Player, luck: number, rng: Random, maxWhirls: number?, scanRadius: number?): Beam?
	if Beams.countFor(player, true) >= (maxWhirls or G.maxBeamsPerPlayer) then
		return nil
	end

	local spot = findSeaSpot(player, scanRadius)
	if not spot then
		return nil
	end

	return createBeam(player, Rarity.rollBeam(rng, luck, adaIzni("deniz")), spot, true)
end

function Beams.trySpawn(player: Player, luck: number, rng: Random, maxBeams: number?): Beam?
	if Beams.countFor(player, false) >= (maxBeams or G.maxBeamsPerPlayer) then
		return nil
	end

	local spot, ada = findSandSpot(player)
	if not spot then
		return nil
	end

	if Ores.island(ada) and rng:NextNumber() * 100 < Ores.SpawnChance then
		local maden = Ores.roll(ada, rng)
		if maden then
			return createBeam(player, maden, spot, false, ada)
		end
	end

	return createBeam(player, Rarity.rollBeam(rng, luck, adaIzni(ada)), spot, false, ada)
end

function Beams.spawnKind(player: Player, kind: string, istenen: Vector3?): Beam?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end

	local spot, ada = findSandSpot(player)

	if istenen then
		local zemin = Sand.probe(istenen + Vector3.new(0, 8, 0), { char, folder })
		spot = if zemin then zemin.position else istenen
	end

	if not spot then
		local ground = Sand.probe(root.Position + root.CFrame.LookVector * 12, { char, folder })
		spot = if ground then ground.position else root.Position - Vector3.new(0, 3, 0)
	end

	return createBeam(player, kind, spot :: Vector3, false, ada)
end

function Beams.spawnWhirlKind(player: Player, kind: string): (Beam?, boolean)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil, false
	end

	local spot = findSeaSpot(player, 400)
	local suda = spot ~= nil

	if not spot then
		spot = root.Position + root.CFrame.LookVector * 14 - Vector3.new(0, 3, 0)
	end

	return createBeam(player, kind, spot :: Vector3, true), suda
end

function Beams.get(id: string): Beam?
	return active[id]
end

Beams.Debug = false

function Beams.remove(id: string, reason: string?)
	local beam = active[id]
	if not beam then
		return
	end

	if Beams.Debug then
		local sahip = beam.owner
		print(`[Suzme] REMOVED {id} ({beam.kind}) owner={if sahip then sahip.Name else "server"} reason={reason or "unspecified"}`)
	end

	if beam.model.Parent then
		for _, node in beam.model:GetDescendants() do
			if node:IsA("ParticleEmitter") then
				node.Enabled = false
				node:Clear()
			elseif node:IsA("Light") then
				node.Enabled = false
			end
		end

		beam.model:Destroy()
	end
	active[id] = nil
end

function Beams.clearFor(player: Player, reason: string?)
	for id, beam in active do
		if beam.owner == player then
			Beams.remove(id, reason or "clearFor")
		end
	end
end

function Beams.snapshotFor(player: Player, scanRadius: number?): { { id: string, kind: string, position: Vector3 } }
	local out = {}
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return out
	end

	for id, beam in active do
		if (beam.owner == player or beam.herkes) and not beam.claimed then
			local distance = (beam.position - root.Position).Magnitude
			if distance <= (scanRadius or G.scanRadius) then
				table.insert(out, {
					id = id,
					kind = beam.kind,
					position = beam.position,
					sea = beam.sea == true,
				})
			end
		end
	end

	return out
end

function Beams.cleanup()
	local now = os.clock()
	local claimedLimit = G.beamLifetime + 120

	for id, beam in active do
		local age = now - beam.bornAt
		local sahip = beam.owner
		local ownerGone = sahip ~= nil and sahip.Parent == nil
		local omur = beam.omur or G.beamLifetime
		local expired = if beam.claimed then (not beam.herkes and age > claimedLimit) else age > omur

		if expired or ownerGone then
			Beams.remove(id, if ownerGone then "sahip cikti" else `omur doldu ({math.floor(age)}sn)`)
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	Beams.clearFor(player, "player left")
end)

return Beams
