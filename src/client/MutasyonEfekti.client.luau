--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Mutations = require(Shared:WaitForChild("Mutations"))

local YORUNGE_SAYISI = 3
local GORUS_MESAFESI = 160
local YORUNGE_HIZI = 1.6
local GOKKUSAGI_HIZI = 0.25
local YARICAP_ORANI = 0.55
local YUKSEKLIK_ORANI = 0.1

local BEYAZ = Color3.new(1, 1, 1)
local PARILTI_DOKUSU = "rbxasset://textures/particles/sparkles_main.dds"

type Yorunge = {
	tutamak: Attachment,
	parilti: ParticleEmitter,
	faz: number,
}

type Kayit = {
	govde: BasePart,
	mutasyon: string,
	yorungeler: { Yorunge },
	yaricap: number,
	merkezKonum: Vector3,
	meshler: { SpecialMesh },
	acik: boolean,
}

local kayitlar: { [Instance]: Kayit } = {}

local function govdeBul(kok: Instance): BasePart?
	if kok:IsA("Tool") then
		local handle = kok:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			return handle
		end
	elseif kok:IsA("Model") and kok.PrimaryPart then
		return kok.PrimaryPart
	end
	return kok:FindFirstChildWhichIsA("BasePart", true)
end

local function parilti(boy: number, renk: Color3): ParticleEmitter
	local yayici = Instance.new("ParticleEmitter")
	yayici.Name = "MutasyonParilti"
	yayici.Texture = PARILTI_DOKUSU
	yayici.Color = ColorSequence.new(renk, renk:Lerp(BEYAZ, 0.5))
	yayici.LightEmission = 1
	yayici.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, boy * 0.1),
		NumberSequenceKeypoint.new(1, 0),
	})
	yayici.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0.6),
	})
	yayici.Lifetime = NumberRange.new(0.5, 0.8)
	yayici.Rate = 22
	yayici.Speed = NumberRange.new(0)
	yayici.RotSpeed = NumberRange.new(-120, 120)
	yayici.Rotation = NumberRange.new(0, 360)
	return yayici
end

local function temizle(kok: Instance)
	local kayit = kayitlar[kok]
	if not kayit then
		return
	end
	kayitlar[kok] = nil

	for _, yorunge in kayit.yorungeler do
		yorunge.tutamak:Destroy()
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

	local enAz, enCok = Assets.worldBounds(kok :: any)
	if not enAz or not enCok then
		return
	end

	local boyut = enCok - enAz
	local boy = math.max(boyut.X, boyut.Y, boyut.Z, 0.5)
	local merkezKonum = govde.CFrame:PointToObjectSpace((enAz + enCok) / 2)
		+ Vector3.new(0, boyut.Y * YUKSEKLIK_ORANI, 0)
	local renk = Mutations.color(mutasyon)

	local yorungeler = {}
	for i = 1, YORUNGE_SAYISI do
		local tutamak = Instance.new("Attachment")
		tutamak.Name = "MutasyonYorunge"
		tutamak.Position = merkezKonum
		tutamak.Parent = govde

		local yayici = parilti(boy, renk)
		yayici.Parent = tutamak

		table.insert(yorungeler, {
			tutamak = tutamak,
			parilti = yayici,
			faz = (i - 1) * (math.pi * 2 / YORUNGE_SAYISI),
		})
	end

	local meshler = {}
	for _, node in kok:GetDescendants() do
		if node:IsA("SpecialMesh") and node.Name == Assets.MutasyonMeshAdi then
			table.insert(meshler, node)
		end
	end

	kayitlar[kok] = {
		govde = govde,
		mutasyon = mutasyon,
		yorungeler = yorungeler,
		yaricap = math.max(boyut.X, boyut.Z) * YARICAP_ORANI,
		merkezKonum = merkezKonum,
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
		local ilk = kayit.yorungeler[1]
		if not kayit.govde.Parent or not ilk or not ilk.tutamak.Parent then
			temizle(kok)
			continue
		end

		local yakin = kayit.govde:IsDescendantOf(Workspace)
			and (ilk.tutamak.WorldPosition - bakis).Magnitude <= GORUS_MESAFESI
		if yakin ~= kayit.acik then
			kayit.acik = yakin
			for _, yorunge in kayit.yorungeler do
				yorunge.parilti.Enabled = yakin
			end
		end
		if not yakin then
			continue
		end

		local gokkusagi: Color3? = nil
		if kayit.mutasyon == "Rainbow" then
			local ton = (zaman * GOKKUSAGI_HIZI) % 1
			gokkusagi = Color3.fromHSV(ton, 0.75, 1)
			local mesh = Color3.fromHSV(ton, 0.45, 1)
			for _, m in kayit.meshler do
				m.VertexColor = Vector3.new(mesh.R, mesh.G, mesh.B) * 1.3
			end
		end

		for _, yorunge in kayit.yorungeler do
			local aci = zaman * YORUNGE_HIZI + yorunge.faz
			yorunge.tutamak.Position = kayit.merkezKonum
				+ Vector3.new(math.cos(aci) * kayit.yaricap, 0, math.sin(aci) * kayit.yaricap)
			if gokkusagi then
				yorunge.parilti.Color = ColorSequence.new(gokkusagi, gokkusagi:Lerp(BEYAZ, 0.5))
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
