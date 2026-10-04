--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Hava = require(Shared:WaitForChild("Hava"))

local YORUNGE_SAYISI = 6
local ISIN_SAYISI = 8
local GORUS_MESAFESI = 160
local YORUNGE_HIZI = 1.1
local ISIN_HIZI = 40
local KOD_DEGISIM = 0.25
local GOKKUSAGI_HIZI = 0.25

local SIYAH = Color3.new(0, 0, 0)
local BEYAZ = Color3.new(1, 1, 1)

local EK_SEKILLER: { [string]: string } = {
	Lava = "kor",
	Rainbow = "yildiz",
}

local sekiller: { [string]: string } = {}
for _, tur in Hava.Turler do
	sekiller[tur.mutasyon] = tur.sekil
end
for mutasyon, sekil in EK_SEKILLER do
	if not sekiller[mutasyon] then
		sekiller[mutasyon] = sekil
	end
end

type Yorunge = {
	tutamak: Attachment,
	pano: BillboardGui,
	sekil: GuiObject,
	faz: number,
	kod: boolean,
	elmas: boolean,
}

type Kayit = {
	kok: Instance,
	govde: BasePart,
	mutasyon: string,
	renk: Color3,
	merkez: Attachment,
	isinPano: BillboardGui,
	donen: Frame,
	isinlar: { Frame },
	yorungeler: { Yorunge },
	parilti: ParticleEmitter,
	yaricap: number,
	yukseklik: number,
	merkezKonum: Vector3,
	kodSayaci: number,
	meshler: { SpecialMesh },
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

local function sekilYap(sekil: string, renk: Color3): GuiObject
	if sekil == "kod" or sekil == "yildiz" then
		local yazi = Instance.new("TextLabel")
		yazi.BackgroundTransparency = 1
		yazi.Size = UDim2.fromScale(1, 1)
		yazi.Text = if sekil == "kod" then (if math.random() < 0.5 then "0" else "1") else "✦"
		yazi.Font = if sekil == "kod" then Enum.Font.Code else Enum.Font.GothamBold
		yazi.TextScaled = true
		yazi.TextColor3 = renk
		yazi.TextStrokeTransparency = 0.3
		yazi.TextStrokeColor3 = renk:Lerp(SIYAH, 0.7)
		return yazi
	end

	local tanecik = Instance.new("Frame")
	tanecik.AnchorPoint = Vector2.new(0.5, 0.5)
	tanecik.Position = UDim2.fromScale(0.5, 0.5)
	tanecik.BackgroundColor3 = renk
	tanecik.BorderSizePixel = 0

	local kontur = Instance.new("UIStroke")
	kontur.Thickness = 2
	kontur.Parent = tanecik

	if sekil == "elmas" then
		tanecik.Size = UDim2.fromScale(0.62, 0.62)
		tanecik.Rotation = 45
		kontur.Color = BEYAZ
		kontur.Transparency = 0.3
	else
		tanecik.Size = UDim2.fromScale(if sekil == "kor" then 0.6 else 0.8, if sekil == "kor" then 0.6 else 0.8)
		local kose = Instance.new("UICorner")
		kose.CornerRadius = UDim.new(1, 0)
		kose.Parent = tanecik
		kontur.Color = renk:Lerp(SIYAH, 0.45)
		kontur.Transparency = 0.1
		if sekil == "kor" then
			kontur.Color = Color3.fromRGB(255, 220, 120)
			kontur.Transparency = 0.4
		end
	end

	return tanecik
end

local function sekilRengi(nesne: GuiObject, renk: Color3)
	if nesne:IsA("TextLabel") then
		nesne.TextColor3 = renk
		nesne.TextStrokeColor3 = renk:Lerp(SIYAH, 0.7)
	elseif nesne:IsA("Frame") then
		nesne.BackgroundColor3 = renk
	end
end

local function isinPanosu(merkez: Attachment, boy: number, renk: Color3): (BillboardGui, Frame, { Frame })
	local pano = Instance.new("BillboardGui")
	pano.Name = "MutasyonIsinlari"
	pano.Adornee = merkez
	pano.Size = UDim2.fromScale(boy * 1.7, boy * 1.7)
	pano.LightInfluence = 0
	pano.MaxDistance = GORUS_MESAFESI
	pano.ResetOnSpawn = false

	local donen = Instance.new("Frame")
	donen.AnchorPoint = Vector2.new(0.5, 0.5)
	donen.Position = UDim2.fromScale(0.5, 0.5)
	donen.Size = UDim2.fromScale(1, 1)
	donen.BackgroundTransparency = 1
	donen.Parent = pano

	local isinlar = {}
	for i = 1, ISIN_SAYISI do
		local isin = Instance.new("Frame")
		isin.AnchorPoint = Vector2.new(0.5, 1)
		isin.Position = UDim2.fromScale(0.5, 0.5)
		isin.Size = UDim2.fromScale(0.07, 0.5)
		isin.Rotation = (i - 1) * (360 / ISIN_SAYISI)
		isin.BackgroundColor3 = renk
		isin.BorderSizePixel = 0
		isin.Parent = donen

		local gecis = Instance.new("UIGradient")
		gecis.Rotation = 90
		gecis.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.6, 0.7),
			NumberSequenceKeypoint.new(1, 0.45),
		})
		gecis.Parent = isin

		local kose = Instance.new("UICorner")
		kose.CornerRadius = UDim.new(1, 0)
		kose.Parent = isin

		table.insert(isinlar, isin)
	end

	pano.Parent = merkez
	return pano, donen, isinlar
end

local function temizle(kok: Instance)
	local kayit = kayitlar[kok]
	if not kayit then
		return
	end
	kayitlar[kok] = nil

	kayit.merkez:Destroy()
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
	local renk = Mutations.color(mutasyon)
	local sekil = sekiller[mutasyon] or "yildiz"

	local merkez = Instance.new("Attachment")
	merkez.Name = "MutasyonMerkezi"
	merkez.Position = merkezKonum
	merkez.Parent = govde

	local isinPano, donen, isinlar = isinPanosu(merkez, boy, renk)

	local parilti = Instance.new("ParticleEmitter")
	parilti.Name = "MutasyonParilti"
	parilti.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	parilti.Color = ColorSequence.new(renk, renk:Lerp(BEYAZ, 0.5))
	parilti.LightEmission = 1
	parilti.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, boy * 0.09),
		NumberSequenceKeypoint.new(1, 0),
	})
	parilti.Transparency = NumberSequence.new(0.1)
	parilti.Lifetime = NumberRange.new(0.9, 1.6)
	parilti.Rate = 7
	parilti.Speed = NumberRange.new(boy * 0.15, boy * 0.35)
	parilti.SpreadAngle = Vector2.new(180, 180)
	parilti.RotSpeed = NumberRange.new(-90, 90)
	parilti.Parent = merkez

	local yorungeler = {}
	for i = 1, YORUNGE_SAYISI do
		local tutamak = Instance.new("Attachment")
		tutamak.Name = "MutasyonYorunge"
		tutamak.Position = merkezKonum
		tutamak.Parent = govde

		local pano = Instance.new("BillboardGui")
		pano.Adornee = tutamak
		pano.Size = UDim2.fromScale(boy * 0.17, boy * 0.17)
		pano.LightInfluence = 0
		pano.MaxDistance = GORUS_MESAFESI
		pano.ResetOnSpawn = false

		local nesne = sekilYap(sekil, renk)
		nesne.Parent = pano
		pano.Parent = tutamak

		table.insert(yorungeler, {
			tutamak = tutamak,
			pano = pano,
			sekil = nesne,
			faz = (i - 1) * (math.pi * 2 / YORUNGE_SAYISI),
			kod = sekil == "kod",
			elmas = sekil == "elmas",
		})
	end

	local meshler = {}
	for _, node in kok:GetDescendants() do
		if node:IsA("SpecialMesh") and node.Name == Assets.MutasyonMeshAdi then
			table.insert(meshler, node)
		end
	end

	kayitlar[kok] = {
		kok = kok,
		govde = govde,
		mutasyon = mutasyon,
		renk = renk,
		merkez = merkez,
		isinPano = isinPano,
		donen = donen,
		isinlar = isinlar,
		yorungeler = yorungeler,
		parilti = parilti,
		yaricap = boy * 0.62,
		yukseklik = boy * 0.18,
		merkezKonum = merkezKonum,
		kodSayaci = 0,
		meshler = meshler,
	}
end

local function gorunurluk(kayit: Kayit, acik: boolean)
	if kayit.isinPano.Enabled == acik then
		return
	end
	kayit.isinPano.Enabled = acik
	kayit.parilti.Enabled = acik
	for _, yorunge in kayit.yorungeler do
		yorunge.pano.Enabled = acik
	end
end

local zaman = 0

RunService.RenderStepped:Connect(function(dt)
	zaman += dt
	local kamera = Workspace.CurrentCamera
	local bakis = if kamera then kamera.CFrame.Position else Vector3.zero

	for kok, kayit in kayitlar do
		if not kayit.govde.Parent or not kayit.merkez.Parent then
			temizle(kok)
			continue
		end

		local yakin = kayit.govde:IsDescendantOf(Workspace)
			and (kayit.merkez.WorldPosition - bakis).Magnitude <= GORUS_MESAFESI
		gorunurluk(kayit, yakin)
		if not yakin then
			continue
		end

		kayit.donen.Rotation = (zaman * ISIN_HIZI) % 360

		local renk: Color3? = nil
		if kayit.mutasyon == "Rainbow" then
			renk = Color3.fromHSV((zaman * GOKKUSAGI_HIZI) % 1, 0.75, 1)
			for _, isin in kayit.isinlar do
				isin.BackgroundColor3 = renk :: Color3
			end
			local ton = Color3.fromHSV((zaman * GOKKUSAGI_HIZI) % 1, 0.45, 1)
			for _, mesh in kayit.meshler do
				mesh.VertexColor = Vector3.new(ton.R, ton.G, ton.B) * 1.3
			end
		end

		kayit.kodSayaci += dt
		local kodDegis = kayit.kodSayaci >= KOD_DEGISIM
		if kodDegis then
			kayit.kodSayaci = 0
		end

		for i, yorunge in kayit.yorungeler do
			local aci = zaman * YORUNGE_HIZI + yorunge.faz
			yorunge.tutamak.Position = kayit.merkezKonum
				+ Vector3.new(
					math.cos(aci) * kayit.yaricap,
					math.sin(aci * 2 + i) * kayit.yukseklik,
					math.sin(aci) * kayit.yaricap
				)

			local nesne = yorunge.sekil
			if renk then
				sekilRengi(nesne, Color3.fromHSV((zaman * GOKKUSAGI_HIZI + i / YORUNGE_SAYISI) % 1, 0.75, 1))
			end
			if kodDegis and yorunge.kod and nesne:IsA("TextLabel") and math.random() < 0.4 then
				nesne.Text = if nesne.Text == "0" then "1" else "0"
			end
			if yorunge.elmas then
				nesne.Rotation = 45 + math.sin(zaman * 3 + i) * 20
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
