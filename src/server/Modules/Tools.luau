--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Shovels = require(Shared:WaitForChild("Shovels"))
local Detectors = require(Shared:WaitForChild("Detectors"))
local Rods = require(Shared:WaitForChild("Rods"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Condition = require(Shared:WaitForChild("Condition"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Assets = require(Shared:WaitForChild("Assets"))
local Scrolls = require(Shared:WaitForChild("Scrolls"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local LevelGlow = require(Shared:WaitForChild("LevelGlow"))
local Divine = require(Shared:WaitForChild("Divine"))
local Icons = require(Shared:WaitForChild("Icons"))
local Fuse = require(Shared:WaitForChild("Fuse"))
local Etiket = require(Shared:WaitForChild("Etiket"))
local GPSEfekt = require(Shared:WaitForChild("GPSEfekt"))
local Fonts = require(Shared:WaitForChild("Fonts"))
local Ores = require(Shared:WaitForChild("Ores"))

local Tools = {}

Tools.ShovelName = "Shovel"
Tools.GPSName = "Pet GPS"
Tools.LuckyBlockName = "Lucky Block"
Tools.PickaxeName = "Pickaxe"

Tools.onLuckyBlockUsed = nil :: ((player: Player, tierId: string) -> ())?

local function ikonYonuKaydet(tool: Tool)
	local handle = tool:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		tool:SetAttribute("IkonYonu", handle.CFrame.Rotation)
	end
end

local function attachModel(tool: Tool, model: Model): BasePart?
	local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not primary then
		model:Destroy()
		return nil
	end

	primary.Name = "Handle"
	primary.Parent = tool

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = primary
			weld.Part1 = part
			weld.Parent = primary
		end
	end

	for _, child in model:GetChildren() do
		child.Parent = tool
	end
	model:Destroy()

	for _, part in tool:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
		end
	end

	return primary
end

local function setHoldAnimation(tool: Tool, animationId: string?)
	local id = Assets.id(animationId)
	if not id then
		return
	end
	tool:SetAttribute("HoldAnimation", id)
end

local function eksenler(part: BasePart): { Vector3 }
	local cf = part.CFrame
	return { cf.RightVector, cf.UpVector, -cf.LookVector }
end

local function serbestModeliBagla(tool: Tool, model: Model, ayar: any): BasePart?
	Assets.stripScripts(model)

	local parcalar: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parcalar, d)
		end
	end
	if #parcalar == 0 then
		model:Destroy()
		return nil
	end

	local function enUzunu(liste: { BasePart }): BasePart
		local secilen = liste[1]
		for _, p in liste do
			if math.max(p.Size.X, p.Size.Y, p.Size.Z) > math.max(secilen.Size.X, secilen.Size.Y, secilen.Size.Z) then
				secilen = p
			end
		end
		return secilen
	end

	local sopaParcalari: { BasePart } = {}
	local sopaKok = model:FindFirstChild("Sopa", true)
	if sopaKok then
		if sopaKok:IsA("BasePart") then
			table.insert(sopaParcalari, sopaKok)
		end
		for _, d in sopaKok:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(sopaParcalari, d)
			end
		end
	end
	if #sopaParcalari == 0 then
		table.insert(sopaParcalari, enUzunu(parcalar))
	end

	local sopaSet: { [BasePart]: boolean } = {}
	for _, p in sopaParcalari do
		sopaSet[p] = true
	end

	local sap = enUzunu(sopaParcalari)

	local boyutlar = { sap.Size.X, sap.Size.Y, sap.Size.Z }
	local uzunIndex = 1
	for i = 2, 3 do
		if boyutlar[i] > boyutlar[uzunIndex] then
			uzunIndex = i
		end
	end
	local eksenListesi = eksenler(sap)
	local eksen = eksenListesi[uzunIndex]

	local function eksenYarisi(p: BasePart): number
		local cf = p.CFrame
		return (
			math.abs(cf.RightVector:Dot(eksen)) * p.Size.X
			+ math.abs(cf.UpVector:Dot(eksen)) * p.Size.Y
			+ math.abs(cf.LookVector:Dot(eksen)) * p.Size.Z
		) / 2
	end

	local sopaAz, sopaCok = math.huge, -math.huge
	for _, p in sopaParcalari do
		local konum = (p.Position - sap.Position):Dot(eksen)
		local yari = eksenYarisi(p)
		sopaAz = math.min(sopaAz, konum - yari)
		sopaCok = math.max(sopaCok, konum + yari)
	end
	local merkez = sap.Position + eksen * ((sopaAz + sopaCok) / 2)
	local sopaYari = (sopaCok - sopaAz) / 2

	local kabza = model:FindFirstChild("Kabza", true)
	local toplam = 0
	if kabza then
		local liste = kabza:GetDescendants()
		table.insert(liste, kabza)
		for _, d in liste do
			if d:IsA("BasePart") and not sopaSet[d] then
				toplam += (d.Position - merkez):Dot(eksen)
			end
		end
	end
	if toplam == 0 then
		for _, p in parcalar do
			if not sopaSet[p] then
				toplam -= (p.Position - merkez):Dot(eksen)
			end
		end
	end
	if toplam < 0 then
		eksen = -eksen
	end

	local uc = 0
	for _, p in parcalar do
		uc = math.max(uc, (p.Position - merkez):Dot(eksen))
	end

	local tutus: Vector3
	if ayar.gripOn == "sopa" then
		tutus = merkez + eksen * (sopaYari * math.clamp(ayar.gripRatio or 0.5, 0, 1))
	else
		tutus = merkez + eksen * (uc - (ayar.gripFromEnd or 0.6))
	end
	local yukari = if ayar.bladeDown then eksen else -eksen

	local kafaParcalari: { BasePart } = {}
	for _, p in parcalar do
		if not sopaSet[p] and not (kabza and p:IsDescendantOf(kabza)) then
			table.insert(kafaParcalari, p)
		end
	end

	local referans = eksenListesi[1]
	if math.abs(referans:Dot(yukari)) > 0.9 then
		referans = eksenListesi[2]
	end
	local taban1 = (referans - yukari * referans:Dot(yukari)).Unit
	local taban2 = yukari:Cross(taban1)

	local kafaMerkezi = Vector3.zero
	local toplamHacim = 0
	for _, p in kafaParcalari do
		local hacim = p.Size.X * p.Size.Y * p.Size.Z
		kafaMerkezi += p.Position * hacim
		toplamHacim += hacim
	end
	kafaMerkezi = if toplamHacim > 0 then kafaMerkezi / toplamHacim else tutus

	local function genislikOf(yon: Vector3): number
		local enAz, enCok = math.huge, -math.huge
		for _, p in kafaParcalari do
			local cf = p.CFrame
			local yari = (
				math.abs(cf.RightVector:Dot(yon)) * p.Size.X
				+ math.abs(cf.UpVector:Dot(yon)) * p.Size.Y
				+ math.abs(cf.LookVector:Dot(yon)) * p.Size.Z
			) / 2
			local konum = (p.Position - kafaMerkezi):Dot(yon)
			enAz = math.min(enAz, konum - yari)
			enCok = math.max(enCok, konum + yari)
		end
		return if enCok >= enAz then enCok - enAz else 0
	end

	local enGenis, enDar = -1, math.huge
	local yayilma, ince = taban1, taban2
	for adim = 0, 35 do
		local aci = math.rad(adim * 5)
		local yon = taban1 * math.cos(aci) + taban2 * math.sin(aci)
		local genislik = genislikOf(yon)

		if genislik > enGenis then
			enGenis = genislik
			yayilma = yon
		end
		if genislik < enDar then
			enDar = genislik
			ince = yon
		end
	end

	local sag: Vector3
	if ayar.spread == "inward" then
		local function merkezi(ad: string): Vector3?
			local kok = model:FindFirstChild(ad, true)
			if not kok then
				return nil
			end
			local liste = kok:GetDescendants()
			table.insert(liste, kok)
			local toplamKonum, hacimler = Vector3.zero, 0
			for _, d in liste do
				if d:IsA("BasePart") then
					local hacim = d.Size.X * d.Size.Y * d.Size.Z
					toplamKonum += d.Position * hacim
					hacimler += hacim
				end
			end
			return if hacimler > 0 then toplamKonum / hacimler else nil
		end

		local govde = merkezi("Govde")
		local kenar = merkezi("Kenar")
		local isaret = if govde and kenar then (kenar - govde):Dot(ince) else 0

		if math.abs(isaret) < 0.02 then
			local sapNoktasi = merkez + eksen * (kafaMerkezi - merkez):Dot(eksen)
			isaret = (kafaMerkezi - sapNoktasi):Dot(ince)
		end

		local oyuk = if isaret < 0 then -ince else ince
		sag = (-oyuk):Cross(yukari).Unit
	elseif ayar.spread == "forward" then
		sag = yayilma:Cross(yukari).Unit
	else
		sag = yayilma
	end

	if ayar.flip and ayar.flip[model.Name] then
		sag = -sag
	end

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.2, 0.2, 0.2)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	handle.CFrame = CFrame.fromMatrix(tutus, sag, yukari)
	handle.Parent = tool

	for _, p in parcalar do
		if p.Name == "Handle" then
			p.Name = "HandleParca"
		end
		p.Anchored = false
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = p
		weld.Parent = handle
	end

	model.Parent = tool

	local r = ayar.rotation or Vector3.zero
	tool.Grip = CFrame.new(ayar.position or Vector3.zero)
		* CFrame.Angles(math.rad(r.X), math.rad(r.Y), math.rad(r.Z))

	return handle
end

local EFFECT_CLASSES = {
	"ParticleEmitter",
	"Trail",
	"Beam",
	"Highlight",
	"PointLight",
	"SpotLight",
	"SurfaceLight",
	"Sparkles",
	"Fire",
	"Smoke",
}

local EFFECT_NAMES = { "vfx", "effect", "efekt", "aura", "glow", "sparkle", "particle", "halo", "ring", "orb" }

local function isEffectPart(part: BasePart): boolean
	local lower = string.lower(part.Name)
	for _, word in EFFECT_NAMES do
		if string.find(lower, word, 1, true) then
			return true
		end
	end
	return false
end

function Tools.stripEffects(model: Instance)
	local doomed: { Instance } = {}

	for _, item in model:GetDescendants() do
		for _, class in EFFECT_CLASSES do
			if item:IsA(class) then
				table.insert(doomed, item)
				break
			end
		end

		if item:IsA("BasePart") and isEffectPart(item) then
			table.insert(doomed, item)
		end
	end

	for _, item in doomed do
		if item.Parent then
			item:Destroy()
		end
	end
end

function Tools.hotbarIkonu(tool: Tool, ikonAdi: string)
	local resim = Icons.assetTam(ikonAdi)
	if resim then
		tool.TextureId = resim
	end
end

function Tools.buildShovel(shovelId: string): Tool
	local info = Shovels.get(shovelId :: any)

	local tool = Instance.new("Tool")
	tool.RequiresHandle = true

	local model = Assets.shovelModel(info.id, info.level, info.island)
	local handle = if model then serbestModeliBagla(tool, model, Assets.ToolGrips.shovel) else nil
	local gercekModel = handle ~= nil

	if not handle then
		local body = Instance.new("Part")
		body.Name = "Handle"
		body.Size = Vector3.new(0.4, 3.2, 0.4)
		body.Color = Color3.fromRGB(120, 80, 45)
		body.Material = Enum.Material.Wood
		body.Parent = tool

		local blade = Instance.new("Part")
		blade.Name = "Blade"
		blade.Size = Vector3.new(1.2, 1.2, 0.2)
		blade.Color = Color3.fromRGB(178, 182, 190)
		blade.Material = Enum.Material.Metal
		blade.CanCollide = false
		blade.Massless = true
		blade.CFrame = body.CFrame * CFrame.new(0, -1.8, 0)
		blade.Parent = tool

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = blade
		weld.Parent = body
	end

	tool.Name = Tools.ShovelName
	Tools.hotbarIkonu(tool, "tool_shovel")
	tool.CanBeDropped = false
	tool.ToolTip = `{info.displayName}  |  Lv.{info.level}`
	tool:SetAttribute("ShovelId", info.id)

	setHoldAnimation(tool, Assets.Animations.shovelHold)

	if not gercekModel then
		LevelGlow.apply(tool, info.level)
	end

	ikonYonuKaydet(tool)
	return tool
end

function Tools.buildPickaxe(pickaxeId: string): Tool
	local info = Ores.Pickaxes[pickaxeId]
	assert(info, `unknown pickaxe: {tostring(pickaxeId)}`)

	local tool = Instance.new("Tool")
	tool.RequiresHandle = true

	local model = Assets.pickaxeModel(info.id)
	local handle = if model then serbestModeliBagla(tool, model, Assets.ToolGrips.pickaxe) else nil
	if handle then
		tool.Name = Tools.PickaxeName
		Tools.hotbarIkonu(tool, "tool_pickaxe")
		tool.CanBeDropped = false
		tool.ToolTip = info.displayName
		tool:SetAttribute("PickaxeId", info.id)
		setHoldAnimation(tool, Assets.Animations.shovelHold)
		return tool
	end

	local body = Instance.new("Part")
	body.Name = "Handle"
	body.Size = Vector3.new(0.35, 3.4, 0.35)
	body.Color = Color3.fromRGB(110, 76, 44)
	body.Material = Enum.Material.Wood
	body.CanCollide = false
	body.Parent = tool

	local head = Instance.new("Part")
	head.Name = "Bas"
	head.Size = Vector3.new(2.8, 0.45, 0.45)
	head.Color = info.color
	head.Material = Enum.Material.SmoothPlastic
	head.CanCollide = false
	head.Massless = true
	head.CFrame = body.CFrame * CFrame.new(0, 1.55, 0)
	head.Parent = tool

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = head
	weld.Parent = body

	tool.Name = Tools.PickaxeName
	Tools.hotbarIkonu(tool, "tool_pickaxe")
	tool.CanBeDropped = false
	tool.ToolTip = info.displayName
	tool:SetAttribute("PickaxeId", info.id)

	setHoldAnimation(tool, Assets.Animations.shovelHold)

	ikonYonuKaydet(tool)
	return tool
end

function Tools.buildGPS(detectorId: string): Tool
	local info = Detectors.get(detectorId :: any)

	local tool = Instance.new("Tool")
	tool.RequiresHandle = true

	local model = Assets.detectorModel(info.id)
	local handle = if model then attachModel(tool, model) else nil

	if not handle then
		local rod = Instance.new("Part")
		rod.Name = "Handle"
		rod.Size = Vector3.new(0.14, 2.4, 0.14)
		rod.Color = Color3.fromRGB(48, 52, 60)
		rod.Material = Enum.Material.Metal
		rod.TopSurface = Enum.SurfaceType.Smooth
		rod.BottomSurface = Enum.SurfaceType.Smooth
		rod.Parent = tool

		local ball = Instance.new("Part")
		ball.Name = GPSEfekt.BallName
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(0.55, 0.55, 0.55)
		ball.Color = info.color
		ball.Material = Enum.Material.Neon
		ball.CanCollide = false
		ball.Massless = true
		ball.CFrame = rod.CFrame * CFrame.new(0, rod.Size.Y / 2, 0)
		ball.Parent = tool

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rod
		weld.Part1 = ball
		weld.Parent = rod

		handle = rod
	end

	tool.Name = Tools.GPSName
	Tools.hotbarIkonu(tool, "tool_gps")
	tool.CanBeDropped = false
	tool.ToolTip = `{info.displayName}  |  Lv.{info.level}  |  Luck x{info.luck}`
	tool:SetAttribute("DetectorId", info.id)

	local ball = tool:FindFirstChild(GPSEfekt.BallName)
	if ball and ball:IsA("BasePart") then
		ball.Material = Enum.Material.Neon
		ball.Reflectance = 0
	end

	if not model then
		local grip = Assets.GPSGrip
		tool.Grip = CFrame.new(grip.position)
			* CFrame.Angles(
				math.rad(grip.rotation.X),
				math.rad(grip.rotation.Y),
				math.rad(grip.rotation.Z)
			)
	end

	setHoldAnimation(tool, Assets.Animations.gpsHold)

	LevelGlow.apply(tool, info.level)

	ikonYonuKaydet(tool)
	return tool
end

local HEAD_WELD = "KafaKaynagi"

local function holdOnHead(tool: Tool)
	local character = tool.Parent
	if not character or not character:IsA("Model") then
		return
	end

	local head = character:FindFirstChild("Head")
	local handle = tool:FindFirstChild("Handle")
	if not head or not head:IsA("BasePart") or not handle or not handle:IsA("BasePart") then
		return
	end

	local cfg = Assets.BrainrotHold

	local shift = (tool:GetAttribute("MerkezKaymasi") :: Vector3?) or Vector3.zero
	local half = (tool:GetAttribute("YariYukseklik") :: number?) or 1

	local old = handle:FindFirstChild(HEAD_WELD)
	if old then
		old:Destroy()
	end

	local offset = (tool:GetAttribute("TutusKaymasi") :: Vector3?) or cfg.headOffset
	local spin = (tool:GetAttribute("TutusDonusu") :: Vector3?) or cfg.headRotation

	local lift = head.Size.Y / 2 + half + cfg.headGap

	local weld = Instance.new("Weld")
	weld.Name = HEAD_WELD
	weld.Part0 = head
	weld.Part1 = handle
	weld.C0 = CFrame.new(offset + Vector3.new(0, lift, 0))
		* CFrame.Angles(
			math.rad(spin.X),
			math.rad(spin.Y),
			math.rad(spin.Z)
		)
		* CFrame.new(-shift)
	weld.Parent = handle

	local grip = character:FindFirstChild("RightGrip", true)
	if grip then
		grip:Destroy()
	end
end

local function releaseHead(tool: Tool)
	local handle = tool:FindFirstChild("Handle")
	local weld = handle and handle:FindFirstChild(HEAD_WELD)
	if weld then
		weld:Destroy()
	end
end

local KIVILCIM_DOKU = "rbxasset://textures/particles/sparkles_main.dds"
local BULUT_DOKU = "rbxasset://textures/particles/smoke_main.dds"

local function gizliEfektler(handle: BasePart, rarityId: string, boy: number)
	local info = Rarity.Info[rarityId :: any]
	if not info then
		return
	end

	local seviye = info.order
	local parilti = Divine.Flashes[rarityId]
	local renkA: Color3 = if parilti then parilti.colorA else info.color
	local renkB: Color3 = if parilti then parilti.colorB else info.color:Lerp(Color3.new(1, 1, 1), 0.5)
	local renkler = ColorSequence.new(renkA, renkB)

	if seviye >= 2 then
		local isik = Instance.new("PointLight")
		isik.Name = "KademeIsigi"
		isik.Color = renkA
		isik.Range = 4 + seviye * 2 + boy
		isik.Brightness = 0.5 + seviye * 0.3
		isik.Shadows = false
		isik.Parent = handle
		Divine.tagIf(isik, rarityId)
	end

	if seviye >= 3 then
		local k = Instance.new("ParticleEmitter")
		k.Name = "KademeKivilcim"
		k.Texture = KIVILCIM_DOKU
		k.Color = renkler
		k.LightEmission = 1
		k.LightInfluence = 0
		k.Rate = 3 + (seviye - 3) * 4
		k.Lifetime = NumberRange.new(0.6, 1.2)
		k.Speed = NumberRange.new(1, 2.5)
		k.SpreadAngle = Vector2.new(180, 180)
		k.Drag = 2
		k.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35 * boy),
			NumberSequenceKeypoint.new(1, 0),
		})
		k.Transparency = NumberSequence.new(0, 1)
		k.Parent = handle
	end

	if seviye >= 5 then
		local a = Instance.new("ParticleEmitter")
		a.Name = "KademeAura"
		a.Texture = BULUT_DOKU
		a.Color = renkler
		a.LightEmission = 1
		a.LightInfluence = 0
		a.Rate = 6 + (seviye - 5) * 3
		a.Lifetime = NumberRange.new(0.8, 1.4)
		a.Speed = NumberRange.new(1.5, 3)
		a.EmissionDirection = Enum.NormalId.Top
		a.SpreadAngle = Vector2.new(25, 25)
		a.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8 * boy),
			NumberSequenceKeypoint.new(1, 1.6 * boy),
		})
		a.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		a.Parent = handle
	end

	if seviye >= 6 then
		local y = Instance.new("ParticleEmitter")
		y.Name = "KademeYildiz"
		y.Texture = KIVILCIM_DOKU
		y.Color = renkler
		y.LightEmission = 1
		y.LightInfluence = 0
		y.Rate = 3 + (seviye - 6) * 2
		y.Lifetime = NumberRange.new(0.5, 0.9)
		y.Speed = NumberRange.new(0, 0.5)
		y.Rotation = NumberRange.new(0, 360)
		y.RotSpeed = NumberRange.new(-120, 120)
		y.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 1.3 * boy),
			NumberSequenceKeypoint.new(1, 0),
		})
		y.Parent = handle
	end
end

function Tools.buildBrainrot(item: any): Tool
	local rarityInfo = Rarity.get(item.rarity)
	local conditionInfo = Condition.get(item.condition)
	local mutationInfo = Mutations.get(item.mutation)
	local revealed = item.revealed and item.name

	local tool = Instance.new("Tool")
	tool.Name = if revealed
		then item.name
		else `??? ({rarityInfo.displayName})`
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("BrainrotUid", item.uid)
	tool:SetAttribute("Rarity", item.rarity)
	tool:SetAttribute("Condition", item.condition)
	tool:SetAttribute("Mutation", item.mutation)
	tool:SetAttribute("Revealed", revealed ~= nil and revealed ~= false)

	if not revealed then
		tool:SetAttribute("TutusKaymasi", Assets.HiddenBrainrot.offset)
		tool:SetAttribute("TutusDonusu", Assets.HiddenBrainrot.rotation)
	end

	local model = if revealed
		then Assets.brainrotModel(item.name, item.mutation)
		else Assets.hiddenBrainrotModel(item.rarity)
	local handle: BasePart? = nil

	if model then
		local prepared = model :: Model

		local ok, err = pcall(function()
			local gizli = Assets.HiddenBrainrot
			local sizeScale = if revealed
				then Condition.scale(item.condition)
				else (gizli.rarityScale[item.rarity or ""] or gizli.default)
			Assets.fitModel(prepared, Assets.BrainrotSize.toolSize, sizeScale)

			if revealed and not Mutations.isSpecial(item.mutation) then
				Tools.stripEffects(prepared)
			end

			local min, max = Assets.worldBounds(prepared)
			local primary = prepared.PrimaryPart
			if min and max and primary then
				tool:SetAttribute("MerkezKaymasi", (min + max) / 2 - primary.Position)
				tool:SetAttribute("YariYukseklik", (max.Y - min.Y) / 2)
			end

			local mutasyon = prepared:GetAttribute(Assets.MutasyonAttribute)
			handle = attachModel(tool, prepared)
			if handle and type(mutasyon) == "string" then
				tool:SetAttribute(Assets.MutasyonAttribute, mutasyon)
				tool:AddTag(Assets.MutasyonTag)
			end
		end)

		if not ok then
			Assets.warnOnce(
				`tool modeli: {item.name}`,
				`[Tools] "{item.name}" tool model could not be prepared, using the plain look -- {tostring(err)}`
			)

			for _, child in tool:GetChildren() do
				if child:IsA("BasePart") then
					child:Destroy()
				end
			end
			pcall(function()
				prepared:Destroy()
			end)

			model = nil
			handle = nil
		end
	end

	if not handle then
		local body = Instance.new("Part")
		body.Name = "Handle"
		body.CastShadow = false
		body.Size = Vector3.new(2, 2, 2)
		body.TopSurface = Enum.SurfaceType.Smooth
		body.BottomSurface = Enum.SurfaceType.Smooth
		body.Parent = tool
		handle = body

		tool:SetAttribute("MerkezKaymasi", Vector3.zero)
		tool:SetAttribute("YariYukseklik", body.Size.Y / 2)
	end

	for _, part in tool:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.Massless = true
			part.CanCollide = false

			if revealed then
				if not model then
					part.Color = if Mutations.isSpecial(item.mutation) then mutationInfo.color else rarityInfo.color
					part.Material = Enum.Material.Neon
				end
			elseif model and Assets.HiddenBrainrot.keepAll then
				continue
			elseif not part:GetAttribute(Assets.HiddenBrainrot.keepAttribute) then
				part.Color = rarityInfo.color

				if not model then
					part.Material = Enum.Material.Plastic
					part.Reflectance = 0
				end

				Divine.tagIf(part, item.rarity)
			end
		end
	end

	if not revealed and model then
		Assets.tintHidden(tool, item.rarity)
	end

	if not revealed and handle then
		local highlight = Instance.new("Highlight")
		highlight.Name = "RarityHighlight"
		highlight.FillColor = rarityInfo.color
		highlight.FillTransparency = if rarityInfo.order >= 5 then 0.78 else 1
		highlight.OutlineColor = rarityInfo.color
		highlight.OutlineTransparency = 0
		highlight.Adornee = handle
		highlight.Parent = handle

		Divine.tagIf(highlight, item.rarity)

		if model then
			gizliEfektler(handle, item.rarity, (tool:GetAttribute("YariYukseklik") :: number?) or 1)
		end
	end

	local mutationTip = if Mutations.isSpecial(item.mutation)
		then `  |  {mutationInfo.displayName} ({mutationInfo.multiplier}x)`
		else ""

	tool.ToolTip = if revealed
		then `{rarityInfo.displayName}  |  {conditionInfo.shortName} ({conditionInfo.multiplier}x){mutationTip}`
		else `Unidentified  |  {rarityInfo.displayName}  |  {conditionInfo.shortName}`

	if Assets.BrainrotHold.mode == "head" then
		tool.Equipped:Connect(function()
			holdOnHead(tool)
		end)
		tool.Unequipped:Connect(function()
			releaseHead(tool)
		end)
	else
		local grip = Assets.BrainrotGrip
		tool.Grip = CFrame.new(grip.position)
			* CFrame.Angles(
				math.rad(grip.rotation.X),
				math.rad(grip.rotation.Y),
				math.rad(grip.rotation.Z)
			)
	end

	if revealed and handle then
		local shift = (tool:GetAttribute("MerkezKaymasi") :: Vector3?) or Vector3.zero
		local half = (tool:GetAttribute("YariYukseklik") :: number?) or 1

		Etiket.build(item, handle, shift.Y + half + Assets.BrainrotHold.headGap + 0.6)
	end

	setHoldAnimation(tool, Assets.Animations.brainrotHold)

	if revealed and handle then
		Assets.attachRarityVFX(tool, item.rarity, handle, item.mutation)
	end

	ikonYonuKaydet(tool)
	return tool
end

function Tools.luckyBlockLabel(tierId: string, count: number): string
	local tier = LuckyBlock.get(tierId)
	return if count > 1 then `{tier.displayName} ({count})` else tier.displayName
end

function Tools.buildScroll(scrollId: string, count: number): Tool?
	local info = Scrolls.get(scrollId)
	if not info then
		return nil
	end

	local klasor = Assets.klasor(Assets.Categories.scrolls)
	local sablon = klasor and klasor:FindFirstChild(info.modelAdi, true)
	if not sablon or not sablon:IsA("Tool") then
		warn(`[Tools] Scroll not found: Assets > {Assets.Categories.scrolls} > {info.modelAdi}`)
		return nil
	end

	local tool = sablon:Clone()
	tool.Name = Scrolls.etiket(scrollId, count)
	tool:SetAttribute(Scrolls.Nitelik, scrollId)
	tool:SetAttribute(Assets.CountAttribute, count)
	tool.CanBeDropped = false

	for _, parca in tool:GetDescendants() do
		if parca:IsA("BasePart") then
			parca.Anchored = false
			parca.CanCollide = false
			parca.Massless = true
		end
	end

	local handle = tool:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then
		local ilk = tool:FindFirstChildWhichIsA("BasePart", true)
		if ilk then
			ilk.Name = "Handle"
			ilk.Parent = tool
			for _, parca in tool:GetDescendants() do
				if parca:IsA("BasePart") and parca ~= ilk then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = ilk
					weld.Part1 = parca
					weld.Parent = ilk
				end
			end
		else
			tool.RequiresHandle = false
		end
	end

	ikonYonuKaydet(tool)
	return tool
end

function Tools.buildLuckyBlock(tierId: string, count: number): Tool
	local tier = LuckyBlock.get(tierId)

	local tool = Instance.new("Tool")
	tool.Name = Tools.luckyBlockLabel(tierId, count)
	tool:SetAttribute(Assets.CountAttribute, count)
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = `{tier.displayName} -- use it to spin the wheel`
	tool:SetAttribute("LuckyBlock", true)
	tool:SetAttribute("LuckyTier", tier.id)

	local model = Assets.luckyBlockModel(tier.modelName, tier.order)
	local handle = if model then attachModel(tool, model) else nil

	if handle then
		Assets.playAnimations(tool)
	end

	if not handle then
		local body = Instance.new("Part")
		body.Name = "Handle"
		body.Size = Vector3.new(1.8, 1.8, 1.8)
		body.Color = tier.color
		body.Material = Enum.Material.Neon
		body.TopSurface = Enum.SurfaceType.Smooth
		body.BottomSurface = Enum.SurfaceType.Smooth
		body.CanCollide = false
		body.Massless = true
		body.Parent = tool
		handle = body
	end

	if handle then
		local glow = Instance.new("PointLight")
		glow.Name = "Parilti"
		glow.Color = tier.color
		glow.Range = 10
		glow.Brightness = 2
		glow.Parent = handle
	end

	tool.Activated:Connect(function()
		local player = Players:GetPlayerFromCharacter(tool.Parent)
		local handler = Tools.onLuckyBlockUsed
		if player and handler then
			handler(player, tier.id)
		end
	end)

	ikonYonuKaydet(tool)
	return tool
end

function Tools.remove(player: Player, toolName: string)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, item in backpack:GetChildren() do
			if item:IsA("Tool") and item.Name == toolName then
				item:Destroy()
			end
		end
	end

	local char = player.Character
	if char then
		for _, item in char:GetChildren() do
			if item:IsA("Tool") and item.Name == toolName then
				item:Destroy()
			end
		end
	end
end

function Tools.has(player: Player, toolName: string): boolean
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and backpack:FindFirstChild(toolName) then
		return true
	end
	local char = player.Character
	return char ~= nil and char:FindFirstChild(toolName) ~= nil
end

function Tools.equipped(player: Player, toolName: string): Tool?
	local char = player.Character
	if not char then
		return nil
	end
	local tool = char:FindFirstChild(toolName)
	return if tool and tool:IsA("Tool") then tool else nil
end

function Tools.equippedBrainrot(player: Player): (Tool?, string?)
	local char = player.Character
	if not char then
		return nil, nil
	end

	for _, item in char:GetChildren() do
		if item:IsA("Tool") and item:GetAttribute("BrainrotUid") then
			return item, item:GetAttribute("BrainrotUid") :: string
		end
	end

	return nil, nil
end

function Tools.findBrainrot(player: Player, uid: string): Tool?
	local backpack = player:FindFirstChildOfClass("Backpack")
	local places = { backpack, player.Character }

	for _, place in places do
		if place then
			for _, item in place:GetChildren() do
				if item:IsA("Tool") and item:GetAttribute("BrainrotUid") == uid then
					return item
				end
			end
		end
	end

	return nil
end

return Tools
