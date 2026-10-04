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

local VFX_KLASORU = "LuckyBlocks"
local VFX_TABAN_BOY = 3
local VFX_OLCEGI = 0.85

local ALTIN_BLOK = "New Gold Lucky Block"
local ELMAS_BLOK = "New Diamond Lucky Block"
local HACKER_BLOK = "Hacker Lucky Block"

local GALAKSI_MOR = ColorSequence.new(Color3.fromRGB(150, 70, 255), Color3.fromRGB(255, 110, 220))
local GALAKSI_PEMBE = ColorSequence.new(Color3.fromRGB(255, 120, 230), Color3.fromRGB(120, 60, 255))
local GALAKSI_KOYU = ColorSequence.new(Color3.fromRGB(70, 30, 170), Color3.fromRGB(190, 80, 255))
local GALAKSI_YILDIZ = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 170, 245))

type VfxGirdisi = { kaynak: string, ad: string, renk: ColorSequence? }

local MUTASYON_VFX: { [string]: { VfxGirdisi } } = {
	Gold = {
		{ kaynak = ALTIN_BLOK, ad = "aura1" },
		{ kaynak = ALTIN_BLOK, ad = "aura2" },
		{ kaynak = ALTIN_BLOK, ad = "aura3" },
		{ kaynak = ALTIN_BLOK, ad = "crescents" },
		{ kaynak = ALTIN_BLOK, ad = "spec1" },
		{ kaynak = ALTIN_BLOK, ad = "stars" },
	},
	Diamond = {
		{ kaynak = ELMAS_BLOK, ad = "Cos" },
		{ kaynak = ELMAS_BLOK, ad = "Energy Esque" },
		{ kaynak = ELMAS_BLOK, ad = "Smoke12" },
		{ kaynak = ELMAS_BLOK, ad = "Star" },
		{ kaynak = ELMAS_BLOK, ad = "Spec12" },
		{ kaynak = ELMAS_BLOK, ad = "Star129" },
	},
	Galaxy = {
		{ kaynak = ALTIN_BLOK, ad = "aura1", renk = GALAKSI_MOR },
		{ kaynak = ALTIN_BLOK, ad = "aura2", renk = GALAKSI_PEMBE },
		{ kaynak = ALTIN_BLOK, ad = "aura3", renk = GALAKSI_KOYU },
		{ kaynak = ALTIN_BLOK, ad = "stars", renk = GALAKSI_YILDIZ },
		{ kaynak = ELMAS_BLOK, ad = "Energy Esque", renk = GALAKSI_MOR },
		{ kaynak = ELMAS_BLOK, ad = "Smoke4", renk = GALAKSI_KOYU },
		{ kaynak = ELMAS_BLOK, ad = "Spec12", renk = GALAKSI_YILDIZ },
		{ kaynak = ELMAS_BLOK, ad = "Star129", renk = GALAKSI_YILDIZ },
	},
	Hacker = {
		{ kaynak = HACKER_BLOK, ad = "Dust" },
		{ kaynak = HACKER_BLOK, ad = "Glitch" },
		{ kaynak = HACKER_BLOK, ad = "Glitch2" },
		{ kaynak = HACKER_BLOK, ad = "Light" },
		{ kaynak = HACKER_BLOK, ad = "Numbers" },
	},
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
	vfx: { ParticleEmitter },
	acik: boolean,
}

local kayitlar: { [Instance]: Kayit } = {}
local parcalar: { Parca } = {}
local sablonlar: { [string]: ParticleEmitter | false } = {}

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

local function sablonBul(kaynak: string, ad: string): ParticleEmitter?
	local anahtar = `{kaynak}/{ad}`
	local bulunan = sablonlar[anahtar]
	if bulunan ~= nil then
		return bulunan or nil
	end

	local kok = ReplicatedStorage:FindFirstChild(Assets.FolderName)
	local klasor = kok and kok:FindFirstChild(VFX_KLASORU)
	local blok = klasor and klasor:FindFirstChild(kaynak)
	local sonuc: ParticleEmitter? = nil
	if blok then
		for _, node in blok:GetDescendants() do
			if node:IsA("ParticleEmitter") and node.Name == ad then
				sonuc = node
				break
			end
		end
	end

	if not sonuc then
		Assets.warnOnce(`mutation vfx: {anahtar}`, `[MutasyonEfekti] effect "{ad}" not found in Assets > {VFX_KLASORU} > {kaynak}`)
	end
	sablonlar[anahtar] = sonuc or false
	return sonuc
end

local function vfxEkle(govde: BasePart, mutasyon: string, boy: number): { ParticleEmitter }
	local liste = {}
	local girdiler = MUTASYON_VFX[mutasyon]
	if not girdiler then
		return liste
	end

	local carpan = boy / VFX_TABAN_BOY * VFX_OLCEGI
	for _, girdi in girdiler do
		local sablon = sablonBul(girdi.kaynak, girdi.ad)
		if not sablon then
			continue
		end

		local klon = sablon:Clone()
		klon.Name = "MutasyonVFX"
		klon.Enabled = true
		if girdi.renk then
			klon.Color = girdi.renk
		end
		klon.Acceleration *= carpan

		local kap = Instance.new("Folder")
		klon.Parent = kap
		Assets.scaleEffects(kap, carpan)
		klon.Parent = govde
		kap:Destroy()

		table.insert(liste, klon)
	end
	return liste
end

local function birak(kok: Instance)
	local kayit = kayitlar[kok]
	if not kayit then
		return
	end
	kayitlar[kok] = nil
	for _, yayici in kayit.vfx do
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

	local carpan = 1 + math.max((nadirlikSirasi[mutasyon] or 1) - 1, 0) * NADIRLIK_ARTISI
	local boy = math.max(govde.Size.X, govde.Size.Y, govde.Size.Z, 0.5)

	kayitlar[kok] = {
		govde = govde,
		mutasyon = mutasyon,
		sekil = sekiller[mutasyon] or "yildiz",
		renk = Mutations.color(mutasyon),
		boy = boy,
		siklik = TABAN_SIKLIK * carpan * (SIKLIK_EKI[mutasyon] or 1),
		hizCarpani = carpan,
		birikim = math.random(),
		vfx = vfxEkle(govde, mutasyon, boy),
		acik = true,
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

		local yakin = kayit.govde:IsDescendantOf(Workspace)
			and (kayit.govde.Position - bakis).Magnitude <= GORUS_MESAFESI
		if yakin ~= kayit.acik then
			kayit.acik = yakin
			for _, yayici in kayit.vfx do
				yayici.Enabled = yakin
			end
		end
		if not yakin then
			continue
		end

		local renk = kayit.renk
		if kayit.mutasyon == "Rainbow" then
			renk = gokkusagi
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

CollectionService:GetInstanceRemovedSignal(Assets.MutasyonTag):Connect(birak)

for _, kok in CollectionService:GetTagged(Assets.MutasyonTag) do
	task.defer(kur, kok)
end
