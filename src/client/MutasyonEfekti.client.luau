--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Mutations = require(Shared:WaitForChild("Mutations"))

local GORUS_MESAFESI = 160
local GOKKUSAGI_HIZI = 0.25

local BEYAZ = Color3.new(1, 1, 1)
local PARILTI_DOKUSU = "rbxasset://textures/particles/sparkles_main.dds"

type Kayit = {
	govde: BasePart,
	mutasyon: string,
	yayicilar: { ParticleEmitter },
	meshler: { SpecialMesh },
	acik: boolean,
}

local kayitlar: { [Instance]: Kayit } = {}

local function govdeBul(kok: Instance): BasePart?
	local enBuyuk: BasePart? = nil
	local enHacim = 0
	for _, node in kok:GetDescendants() do
		if node:IsA("BasePart") and not node:GetAttribute(Assets.MeasureSkipAttribute) and node.Transparency < 1 then
			local hacim = node.Size.X * node.Size.Y * node.Size.Z
			if hacim > enHacim then
				enBuyuk, enHacim = node, hacim
			end
		end
	end
	return enBuyuk
end

local function yayiciYap(boy: number, renk: Color3, govde: BasePart): ParticleEmitter
	local yayici = Instance.new("ParticleEmitter")
	yayici.Name = "MutasyonParilti"
	yayici.Texture = PARILTI_DOKUSU
	yayici.Color = ColorSequence.new(renk, renk:Lerp(BEYAZ, 0.5))
	yayici.LightEmission = 1
	yayici.Shape = Enum.ParticleEmitterShape.Box
	yayici.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	yayici.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	yayici.EmissionDirection = Enum.NormalId.Top
	yayici.SpreadAngle = Vector2.new(180, 180)
	yayici.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, boy * 0.07),
		NumberSequenceKeypoint.new(0.4, boy * 0.09),
		NumberSequenceKeypoint.new(1, 0),
	})
	yayici.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.6, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	yayici.Lifetime = NumberRange.new(0.8, 1.4)
	yayici.Rate = 14
	yayici.Speed = NumberRange.new(boy * 0.25, boy * 0.55)
	yayici.Drag = 2
	yayici.RotSpeed = NumberRange.new(-120, 120)
	yayici.Rotation = NumberRange.new(0, 360)
	yayici.Parent = govde
	return yayici
end

local function temizle(kok: Instance)
	local kayit = kayitlar[kok]
	if not kayit then
		return
	end
	kayitlar[kok] = nil

	for _, yayici in kayit.yayicilar do
		yayici:Destroy()
	end
end

local function kur(kok: Instance)
	if kayitlar[kok] or kok:FindFirstAncestorWhichIsA("ViewportFrame") then
		return
	end

	local mutasyon = kok:GetAttribute(Assets.MutasyonAttribute)
	if type(mutasyon) ~= "string" or not Mutations.isSpecial(mutasyon) then
		return
	end

	local govde = govdeBul(kok)
	if not govde then
		return
	end

	local boy = math.max(govde.Size.X, govde.Size.Y, govde.Size.Z, 0.5)

	local meshler = {}
	for _, node in kok:GetDescendants() do
		if node:IsA("SpecialMesh") and node.Name == Assets.MutasyonMeshAdi then
			table.insert(meshler, node)
		end
	end

	kayitlar[kok] = {
		govde = govde,
		mutasyon = mutasyon,
		yayicilar = { yayiciYap(boy, Mutations.color(mutasyon), govde) },
		meshler = meshler,
		acik = true,
	}
end

local zaman = 0

RunService.RenderStepped:Connect(function(dt)
	zaman += dt
	local kamera = Workspace.CurrentCamera
	local bakis = if kamera then kamera.CFrame.Position else Vector3.zero

	for kok, kayit in kayitlar do
		if not kayit.govde.Parent then
			temizle(kok)
			continue
		end

		local yakin = kayit.govde:IsDescendantOf(Workspace)
			and (kayit.govde.Position - bakis).Magnitude <= GORUS_MESAFESI
		if yakin ~= kayit.acik then
			kayit.acik = yakin
			for _, yayici in kayit.yayicilar do
				yayici.Enabled = yakin
			end
		end

		if yakin and kayit.mutasyon == "Rainbow" then
			local ton = (zaman * GOKKUSAGI_HIZI) % 1
			local renk = Color3.fromHSV(ton, 0.75, 1)
			for _, yayici in kayit.yayicilar do
				yayici.Color = ColorSequence.new(renk, renk:Lerp(BEYAZ, 0.5))
			end
			local mesh = Color3.fromHSV(ton, 0.45, 1)
			for _, m in kayit.meshler do
				m.VertexColor = Vector3.new(mesh.R, mesh.G, mesh.B) * 1.3
			end
		end
	end
end)

CollectionService:GetInstanceAddedSignal(Assets.MutasyonTag):Connect(function(kok)
	task.defer(kur, kok)
end)

CollectionService:GetInstanceRemovedSignal(Assets.MutasyonTag):Connect(temizle)

for _, kok in CollectionService:GetTagged(Assets.MutasyonTag) do
	task.defer(kur, kok)
end
