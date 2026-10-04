--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Hava = require(Shared:WaitForChild("Hava"))

local GORUS_MESAFESI = 110
local TABAN_SIKLIK = 5
local TABAN_HIZ = 0.8
local NADIRLIK_ARTISI = 0.35
local OMUR_EN_AZ = 0.45
local OMUR_EN_COK = 0.7
local SURTUNME = 1.6
local PARCA_BOYU = 0.13
local AZAMI_PARCA = 320
local GOKKUSAGI_HIZI = 0.25
local YUKARI_EGILIM = 0.7

local SIKLIK_EKI: { [string]: number } = {
	Hacker = 1.7,
}

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

local nadirlikSirasi: { [string]: number } = {}
for i, id in Mutations.Order do
	nadirlikSirasi[id] = i - 1
end

type Parca = {
	tutamak: Attachment,
	pano: BillboardGui,
	nesne: GuiObject,
	kontur: UIStroke?,
	hiz: Vector3,
	yas: number,
	omur: number,
	boy: number,
}

type Kayit = {
	govde: BasePart,
	mutasyon: string,
	sekil: string,
	renk: Color3,
	boy: number,
	siklik: number,
	hizCarpani: number,
	birikim: number,
	meshler: { SpecialMesh },
}

local kayitlar: { [Instance]: Kayit } = {}
local parcalar: { Parca } = {}

local tasiyici = Instance.new("Part")
tasiyici.Name = "MutasyonParcalari"
tasiyici.Anchored = true
tasiyici.CanCollide = false
tasiyici.CanQuery = false
tasiyici.CanTouch = false
tasiyici.Transparency = 1
tasiyici.Size = Vector3.one
tasiyici.CFrame = CFrame.new()
tasiyici.Parent = Workspace

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

local function sekilYap(sekil: string, renk: Color3): (GuiObject, UIStroke?)
	if sekil == "kod" or sekil == "yildiz" then
		local yazi = Instance.new("TextLabel")
		yazi.BackgroundTransparency = 1
		yazi.Size = UDim2.fromScale(1, 1)
		yazi.Text = if sekil == "kod" then (if math.random() < 0.5 then "0" else "1") else "✦"
		yazi.Font = if sekil == "kod" then Enum.Font.Code else Enum.Font.GothamBold
		yazi.TextScaled = true
		yazi.TextColor3 = renk
		yazi.TextStrokeTransparency = 0.4
		yazi.TextStrokeColor3 = renk:Lerp(SIYAH, 0.7)
		return yazi, nil
	end

	local tanecik = Instance.new("Frame")
	tanecik.AnchorPoint = Vector2.new(0.5, 0.5)
	tanecik.Position = UDim2.fromScale(0.5, 0.5)
	tanecik.BackgroundColor3 = renk
	tanecik.BorderSizePixel = 0

	local kontur = Instance.new("UIStroke")
	kontur.Thickness = 1.5
	kontur.Parent = tanecik

	if sekil == "elmas" then
		tanecik.Size = UDim2.fromScale(0.6, 0.6)
		tanecik.Rotation = 45
		kontur.Color = BEYAZ
		kontur.Transparency = 0.3
	else
		local oran = if sekil == "kor" then 0.6 else 0.8
		tanecik.Size = UDim2.fromScale(oran, oran)
		local kose = Instance.new("UICorner")
		kose.CornerRadius = UDim.new(1, 0)
		kose.Parent = tanecik
		if sekil == "kor" then
			kontur.Color = Color3.fromRGB(255, 220, 120)
			kontur.Transparency = 0.4
		else
			kontur.Color = renk:Lerp(SIYAH, 0.45)
			kontur.Transparency = 0.1
		end
	end

	return tanecik, kontur
end

local function saydamlik(parca: Parca, oran: number)
	local nesne = parca.nesne
	if nesne:IsA("TextLabel") then
		nesne.TextTransparency = oran
		nesne.TextStrokeTransparency = 0.4 + 0.6 * oran
	elseif nesne:IsA("Frame") then
		nesne.BackgroundTransparency = oran
	end
	if parca.kontur then
		parca.kontur.Transparency = math.max(parca.kontur.Transparency, oran)
	end
end

local function parcaCikar(kayit: Kayit, renk: Color3)
	if #parcalar >= AZAMI_PARCA then
		return
	end

	local govde = kayit.govde
	local yari = govde.Size / 2
	local yerel = Vector3.new(
		(math.random() * 2 - 1) * yari.X,
		(math.random() * 2 - 1) * yari.Y,
		(math.random() * 2 - 1) * yari.Z
	)
	local konum = govde.CFrame:PointToWorldSpace(yerel * 0.8)

	local yon = govde.CFrame:VectorToWorldSpace(yerel)
	if yon.Magnitude < 1e-3 then
		yon = Vector3.yAxis
	end
	yon = (yon.Unit + Vector3.new(math.random() - 0.5, math.random() - 0.3, math.random() - 0.5) * 0.8).Unit
	yon = Vector3.new(yon.X, math.abs(yon.Y) + YUKARI_EGILIM, yon.Z).Unit

	local tutamak = Instance.new("Attachment")
	tutamak.WorldPosition = konum
	tutamak.Parent = tasiyici

	local boy = kayit.boy * PARCA_BOYU * (0.75 + math.random() * 0.5)
	local pano = Instance.new("BillboardGui")
	pano.Adornee = tutamak
	pano.Size = UDim2.fromScale(boy, boy)
	pano.LightInfluence = 0
	pano.MaxDistance = GORUS_MESAFESI
	pano.ResetOnSpawn = false

	local nesne, kontur = sekilYap(kayit.sekil, renk)
	nesne.Parent = pano
	pano.Parent = tutamak

	table.insert(parcalar, {
		tutamak = tutamak,
		pano = pano,
		nesne = nesne,
		kontur = kontur,
		hiz = yon * kayit.boy * TABAN_HIZ * kayit.hizCarpani * (0.7 + math.random() * 0.6),
		yas = 0,
		omur = OMUR_EN_AZ + math.random() * (OMUR_EN_COK - OMUR_EN_AZ),
		boy = boy,
	})
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

	local meshler = {}
	for _, node in kok:GetDescendants() do
		if node:IsA("SpecialMesh") and node.Name == Assets.MutasyonMeshAdi then
			table.insert(meshler, node)
		end
	end

	local carpan = 1 + math.max((nadirlikSirasi[mutasyon] or 1) - 1, 0) * NADIRLIK_ARTISI

	kayitlar[kok] = {
		govde = govde,
		mutasyon = mutasyon,
		sekil = sekiller[mutasyon] or "yildiz",
		renk = Mutations.color(mutasyon),
		boy = math.max(govde.Size.X, govde.Size.Y, govde.Size.Z, 0.5),
		siklik = TABAN_SIKLIK * carpan * (SIKLIK_EKI[mutasyon] or 1),
		hizCarpani = carpan,
		birikim = math.random(),
		meshler = meshler,
	}
end

local zaman = 0

RunService.RenderStepped:Connect(function(dt)
	zaman += dt
	local kamera = Workspace.CurrentCamera
	local bakis = if kamera then kamera.CFrame.Position else Vector3.zero
	local gokkusagi = Color3.fromHSV((zaman * GOKKUSAGI_HIZI) % 1, 0.75, 1)

	for kok, kayit in kayitlar do
		if not kayit.govde.Parent then
			kayitlar[kok] = nil
			continue
		end

		if not kayit.govde:IsDescendantOf(Workspace) or (kayit.govde.Position - bakis).Magnitude > GORUS_MESAFESI then
			continue
		end

		local renk = kayit.renk
		if kayit.mutasyon == "Rainbow" then
			renk = gokkusagi
			local mesh = Color3.fromHSV((zaman * GOKKUSAGI_HIZI) % 1, 0.45, 1)
			for _, m in kayit.meshler do
				m.VertexColor = Vector3.new(mesh.R, mesh.G, mesh.B) * 1.3
			end
		end

		kayit.birikim += dt * kayit.siklik
		while kayit.birikim >= 1 do
			kayit.birikim -= 1
			parcaCikar(kayit, renk)
		end
	end

	local surtunme = math.exp(-SURTUNME * dt)
	for i = #parcalar, 1, -1 do
		local parca = parcalar[i]
		parca.yas += dt
		local oran = parca.yas / parca.omur
		if oran >= 1 then
			parca.tutamak:Destroy()
			table.remove(parcalar, i)
			continue
		end

		parca.tutamak.WorldPosition += parca.hiz * dt
		parca.hiz *= surtunme

		local solma = math.clamp((oran - 0.45) / 0.55, 0, 1)
		saydamlik(parca, solma)
		local olcek = parca.boy * (1 - 0.5 * solma)
		parca.pano.Size = UDim2.fromScale(olcek, olcek)
	end
end)

CollectionService:GetInstanceAddedSignal(Assets.MutasyonTag):Connect(function(kok)
	task.defer(kur, kok)
end)

CollectionService:GetInstanceRemovedSignal(Assets.MutasyonTag):Connect(function(kok)
	kayitlar[kok] = nil
end)

for _, kok in CollectionService:GetTagged(Assets.MutasyonTag) do
	task.defer(kur, kok)
end
