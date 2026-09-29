--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))

local BrainrotOnizleme = {}

local PAY = 120

local HAVUZ_ANAHTAR_TAVAN = 6
local HAVUZ_TOPLAM_TAVAN = 80

local YOK_BEKLEME = 10

local BAKIS_YONU = Vector3.new(0, 0, -1)
local ISIK = Color3.fromRGB(255, 255, 255)
local ISIK_YONU = Vector3.new(-0.4, -0.7, -0.6)
local CERCEVE = 0.9
local GORUS_YARI_ACI = math.rad(35)
local GIZLI_PAY = 1.3

export type Kaynak = {
	name: string?,
	mutation: string?,
	revealed: boolean,
	rarity: string?,
}

local havuz: { [string]: { ViewportFrame } } = {}
local havuzToplam = 0

local yokZamani: { [string]: number } = {}

local function anahtarOf(k: Kaynak): string
	if k.revealed and k.name then
		return `{k.name}|{k.mutation or "Normal"}`
	end
	return `__gizli|{k.rarity or ""}`
end

local function gorunenSinir(model: Model, yalnizcaNitelik: string?): (Vector3?, Vector3?)
	local enAz: Vector3? = nil
	local enCok: Vector3? = nil

	for _, parca in model:GetDescendants() do
		if not parca:IsA("BasePart") or parca.Transparency >= 0.99 then
			continue
		end
		if yalnizcaNitelik and not parca:GetAttribute(yalnizcaNitelik) then
			continue
		end
		if parca:GetAttribute(Assets.MeasureSkipAttribute) then
			continue
		end

		local cf, boyut = parca.CFrame, parca.Size
		local yari = Vector3.new(
			math.abs(cf.RightVector.X) * boyut.X + math.abs(cf.UpVector.X) * boyut.Y + math.abs(cf.LookVector.X) * boyut.Z,
			math.abs(cf.RightVector.Y) * boyut.X + math.abs(cf.UpVector.Y) * boyut.Y + math.abs(cf.LookVector.Y) * boyut.Z,
			math.abs(cf.RightVector.Z) * boyut.X + math.abs(cf.UpVector.Z) * boyut.Y + math.abs(cf.LookVector.Z) * boyut.Z
		) / 2

		local alt = cf.Position - yari
		local ust = cf.Position + yari
		enAz = if enAz then enAz:Min(alt) else alt
		enCok = if enCok then enCok:Max(ust) else ust
	end

	return enAz, enCok
end

local gizliRaporVerildi = false

local function gizliKupu(model: Model): BasePart?
	local adaylar: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute(Assets.HiddenBrainrot.keepAttribute) then
			table.insert(adaylar, d)
		end
	end
	if #adaylar == 0 then
		return nil
	end

	local secilen: BasePart? = nil
	local enBuyuk = -1
	for _, p in adaylar do
		local yazili = p:FindFirstChildWhichIsA("Decal") or p:FindFirstChildWhichIsA("SurfaceGui")
		local hacim = p.Size.X * p.Size.Y * p.Size.Z + (if yazili then 1e9 else 0)
		if hacim > enBuyuk then
			enBuyuk = hacim
			secilen = p
		end
	end
	return secilen
end

local function yaziliYuz(kup: BasePart): Vector3
	for _, d in kup:GetChildren() do
		local yuz: Enum.NormalId? = nil
		if d:IsA("Decal") then
			yuz = d.Face
		elseif d:IsA("SurfaceGui") then
			yuz = d.Face
		end
		if yuz then
			return kup.CFrame:VectorToWorldSpace(Vector3.FromNormalId(yuz))
		end
	end
	return kup.CFrame:VectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Front))
end

local function gizliSahne(model: Model, kamera: Camera): boolean
	local kup = gizliKupu(model)
	local enAz, enCok = nil, nil
	if kup then
		enAz, enCok = gorunenSinir(model, Assets.HiddenBrainrot.keepAttribute)
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and not d:GetAttribute(Assets.HiddenBrainrot.keepAttribute) then
				d.LocalTransparencyModifier = 1
				d.Transparency = 1
			end
		end
	end
	if not enAz or not enCok then
		enAz, enCok = gorunenSinir(model)
	end
	if not enAz or not enCok then
		return false
	end
	local merkez = (enAz + enCok) / 2

	local normal = BAKIS_YONU

	local yukari = Vector3.yAxis
	if math.abs(normal.Y) > 0.9 then
		yukari = Vector3.new(0, 0, -1)
	end
	local sag = normal:Cross(yukari).Unit
	local ust = sag:Cross(normal).Unit

	local yariEn, yariBoy, derinlik = 0, 0, 0
	for _, x in { enAz.X, enCok.X } do
		for _, y in { enAz.Y, enCok.Y } do
			for _, z in { enAz.Z, enCok.Z } do
				local fark = Vector3.new(x, y, z) - merkez
				yariEn = math.max(yariEn, math.abs(fark:Dot(sag)))
				yariBoy = math.max(yariBoy, math.abs(fark:Dot(ust)))
				derinlik = math.max(derinlik, fark:Dot(normal))
			end
		end
	end

	local mesafe = math.max(yariEn, yariBoy) / math.tan(GORUS_YARI_ACI) * GIZLI_PAY + derinlik
	kamera.FieldOfView = 70
	kamera.CFrame = CFrame.lookAt(merkez + normal * mesafe, merkez, ust)

	if not gizliRaporVerildi then
		gizliRaporVerildi = true
		local satirlar = {}
		for _, d in model:GetDescendants() do
			if #satirlar >= 25 then
				break
			end
			if d:IsA("BasePart") or d:IsA("Decal") or d:IsA("SurfaceGui") then
				local ek = if d:IsA("BasePart")
					then ` size={d.Size} position={d.Position} transparency={d.Transparency} cube={d:GetAttribute(Assets.HiddenBrainrot.keepAttribute) == true}`
					else ` face={(d :: any).Face}`
				table.insert(satirlar, `  {d.ClassName} {d.Name}{ek}`)
			end
		end
		print(`[BrainrotOnizleme] Hidden model ({model.Name}) view {normal}, box {enCok - enAz}:\n{table.concat(satirlar, "\n")}`)
	end
	return true
end

local function kur(k: Kaynak): ViewportFrame?
	local model = if k.revealed and k.name
		then Assets.brainrotModel(k.name, k.mutation)
		else Assets.hiddenBrainrotModel(k.rarity)

	if not model then
		return nil
	end

	if not (k.revealed and k.name) then
		Assets.tintHidden(model, k.rarity)
	end

	for _, nesne in model:GetDescendants() do
		if
			nesne:IsA("BaseScript")
			or nesne:IsA("Sound")
			or nesne:IsA("ParticleEmitter")
			or nesne:IsA("Beam")
			or nesne:IsA("Trail")
		then
			nesne:Destroy()
		end
	end

	local vp = Instance.new("ViewportFrame")
	vp.Name = "Onizleme"
	vp.Size = UDim2.fromScale(1, 1)
	vp.BackgroundTransparency = 1
	vp.Ambient = ISIK
	vp.LightColor = ISIK
	vp.LightDirection = ISIK_YONU

	model.Parent = vp

	local kamera = Instance.new("Camera")
	kamera.Parent = vp
	vp.CurrentCamera = kamera

	local gizli = not (k.revealed and k.name)
	if gizli and gizliSahne(model, kamera) then
		return vp
	end
	local enAz, enCok = gorunenSinir(model)
	if enAz and enCok then
		local merkez = (enAz + enCok) / 2
		local kosegen = (enCok - enAz).Magnitude
		kamera.CFrame = CFrame.lookAt(merkez + BAKIS_YONU * kosegen * CERCEVE, merkez)
	else
		local ok, cf, boyut = pcall(function()
			return model:GetBoundingBox()
		end)
		if ok and cf and boyut then
			kamera.CFrame = CFrame.lookAt(cf.Position + BAKIS_YONU * boyut.Magnitude * CERCEVE, cf.Position)
		end
	end

	return vp
end

local function al(anahtar: string, k: Kaynak): ViewportFrame?
	local liste = havuz[anahtar]
	if liste and #liste > 0 then
		havuzToplam -= 1
		return table.remove(liste)
	end

	local son = yokZamani[anahtar]
	if son and os.clock() - son < YOK_BEKLEME then
		return nil
	end

	local vp = kur(k)
	if not vp then
		yokZamani[anahtar] = os.clock()
	end
	return vp
end

local function birak(anahtar: string, vp: ViewportFrame)
	vp.Parent = nil

	local liste = havuz[anahtar]
	if not liste then
		liste = {}
		havuz[anahtar] = liste
	end

	if #liste >= HAVUZ_ANAHTAR_TAVAN or havuzToplam >= HAVUZ_TOPLAM_TAVAN then
		vp:Destroy()
		return
	end

	table.insert(liste, vp)
	havuzToplam += 1
end

export type Pencere = {
	ekle: (yuva: GuiObject, kaynak: Kaynak, yedek: GuiObject?) -> (),
	temizle: () -> (),
	tazele: () -> (),
}

type Kayit = {
	yuva: GuiObject,
	kaynak: Kaynak,
	anahtar: string,
	yedek: GuiObject?,
	vp: ViewportFrame?,
}

local function yeniKayit(yuva: GuiObject, kaynak: Kaynak, yedek: GuiObject?): Kayit
	return {
		yuva = yuva,
		kaynak = kaynak,
		anahtar = anahtarOf(kaynak),
		yedek = yedek,
		vp = nil,
	}
end

local function tak(kayit: Kayit)
	if kayit.vp then
		return
	end

	local vp = al(kayit.anahtar, kayit.kaynak)
	if not vp then
		return
	end

	vp.ZIndex = kayit.yuva.ZIndex + 1
	vp.Parent = kayit.yuva
	kayit.vp = vp

	local yedek = kayit.yedek
	if yedek then
		yedek.Visible = false
	end
end

local function serbest(kayit: Kayit)
	local vp = kayit.vp
	if not vp then
		return
	end
	kayit.vp = nil
	birak(kayit.anahtar, vp)

	local yedek = kayit.yedek
	if yedek then
		yedek.Visible = true
	end
end

local function ekrandaMi(nesne: GuiObject): boolean
	local node: Instance? = nesne
	while node do
		if node:IsA("GuiObject") then
			if not node.Visible then
				return false
			end
		elseif node:IsA("LayerCollector") then
			return node.Enabled
		end
		node = node.Parent
	end
	return false
end

function BrainrotOnizleme.pencere(liste: ScrollingFrame, panel: GuiObject): Pencere
	local kayitlar: { Kayit } = {}
	local bekliyor = false

	local function hepsiniBirak()
		for _, kayit in kayitlar do
			serbest(kayit)
		end
	end

	local function tazele()
		if not panel.Visible then
			hepsiniBirak()
			return
		end

		local ust = liste.AbsolutePosition.Y - PAY
		local alt = liste.AbsolutePosition.Y + liste.AbsoluteSize.Y + PAY

		for _, kayit in kayitlar do
			local yuva = kayit.yuva
			if not yuva.Parent then
				continue
			end

			local y = yuva.AbsolutePosition.Y
			if y + yuva.AbsoluteSize.Y >= ust and y <= alt then
				tak(kayit)
			else
				serbest(kayit)
			end
		end
	end

	local function sonraTazele()
		if bekliyor then
			return
		end
		bekliyor = true
		task.defer(function()
			bekliyor = false
			tazele()
		end)
	end

	liste:GetPropertyChangedSignal("CanvasPosition"):Connect(tazele)

	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then
			sonraTazele()
			task.delay(0.3, tazele)
		else
			hepsiniBirak()
		end
	end)

	return {
		ekle = function(yuva: GuiObject, kaynak: Kaynak, yedek: GuiObject?)
			table.insert(kayitlar, yeniKayit(yuva, kaynak, yedek))
			sonraTazele()
		end,

		temizle = function()
			hepsiniBirak()
			table.clear(kayitlar)
		end,

		tazele = tazele,
	}
end

function BrainrotOnizleme.seritPencere(cerceve: GuiObject): Pencere
	local kayitlar: { Kayit } = {}
	local baglanti: RBXScriptConnection? = nil

	local function hepsiniBirak()
		for _, kayit in kayitlar do
			serbest(kayit)
		end
	end

	local function tazele()
		if not ekrandaMi(cerceve) then
			hepsiniBirak()
			return
		end

		local sol = cerceve.AbsolutePosition.X
		local sag = sol + cerceve.AbsoluteSize.X

		for _, kayit in kayitlar do
			local yuva = kayit.yuva
			if not yuva.Parent then
				continue
			end

			local x = yuva.AbsolutePosition.X
			local w = yuva.AbsoluteSize.X
			if x + w >= sol - w and x <= sag + w then
				tak(kayit)
			else
				serbest(kayit)
			end
		end
	end

	return {
		ekle = function(yuva: GuiObject, kaynak: Kaynak, yedek: GuiObject?)
			table.insert(kayitlar, yeniKayit(yuva, kaynak, yedek))
			if not baglanti then
				baglanti = RunService.RenderStepped:Connect(tazele)
			end
		end,

		temizle = function()
			hepsiniBirak()
			table.clear(kayitlar)
			local b = baglanti
			if b then
				b:Disconnect()
				baglanti = nil
			end
		end,

		tazele = tazele,
	}
end

return BrainrotOnizleme
