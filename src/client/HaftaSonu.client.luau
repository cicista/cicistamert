--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("HaftaSonu"))

local BEYAZ = Color3.new(1, 1, 1)
local SIYAH = Color3.new(0, 0, 0)

type ParcaKaydi = { renk: Color3, malzeme: Enum.Material, faz: number }
type VfxKaydi = { rate: number, size: NumberSequence }

type Kule = {
	model: Model,
	parcalar: { [BasePart]: ParcaKaydi },
	vfxler: { [ParticleEmitter]: VfxKaydi },
	tabela: BillboardGui?,
	ust: TextLabel?,
	alt: TextLabel?,
	baglantilar: { RBXScriptConnection },
}

local kule: Kule? = nil
local aktif = false

local function kuleyiBul(): Model?
	local node: Instance? = Workspace
	for _, ad in Ayar.KuleYolu do
		node = if node then node:FindFirstChild(ad) else nil
	end
	return if node and node:IsA("Model") then node else nil
end

local function olcekli(seri: NumberSequence, carpan: number): NumberSequence
	local noktalar = {}
	for _, k in seri.Keypoints do
		table.insert(noktalar, NumberSequenceKeypoint.new(k.Time, k.Value * carpan, k.Envelope * carpan))
	end
	return NumberSequence.new(noktalar)
end

local function tabelaKur(k: Kule)
	local yazi = k.model:FindFirstChild(Ayar.YaziParcasi, true)
	if not yazi or not yazi:IsA("BasePart") then
		return
	end

	local ornek = yazi:FindFirstChildWhichIsA("TextLabel", true)

	local tabela = Instance.new("BillboardGui")
	tabela.Name = "HaftaSonuSayaci"
	tabela.Size = UDim2.fromScale(30, 3.2)
	tabela.StudsOffset = Vector3.new(0, -1.4, 0)
	tabela.MaxDistance = 150
	tabela.LightInfluence = 0
	tabela.Brightness = 2
	tabela.Enabled = false

	local function satir(ad: string, y: number, boy: number): TextLabel
		local etiket = Instance.new("TextLabel")
		etiket.Name = ad
		etiket.AnchorPoint = Vector2.new(0.5, 0)
		etiket.Position = UDim2.fromScale(0.5, y)
		etiket.Size = UDim2.fromScale(0.6, boy)
		etiket.BackgroundTransparency = 1
		etiket.TextScaled = true
		etiket.TextColor3 = BEYAZ
		etiket.Text = ""
		if ornek then
			etiket.FontFace = ornek.FontFace
		end
		etiket.Parent = tabela

		local kontur = Instance.new("UIStroke")
		kontur.Color = SIYAH
		kontur.Thickness = 3
		kontur.Parent = etiket
		return etiket
	end

	k.ust = satir("Aktif", 0, 0.5)
	k.alt = satir("Sure", 0.55, 0.4)
	k.tabela = tabela
	tabela.Parent = yazi
end

local function yaziTipiAl(k: Kule, ornek: TextLabel)
	local tabela = k.tabela
	if not tabela or ornek:IsDescendantOf(tabela) then
		return
	end
	for _, etiket in { k.ust, k.alt } do
		if etiket then
			etiket.FontFace = ornek.FontFace
		end
	end
end

local function parcaUygula(parca: BasePart, kayit: ParcaKaydi, acik: boolean)
	if acik then
		parca.Material = Enum.Material.Neon
	else
		parca.Material = kayit.malzeme
		parca.Color = kayit.renk
	end
end

local function vfxUygula(vfx: ParticleEmitter, kayit: VfxKaydi, acik: boolean)
	vfx.Rate = if acik then kayit.rate * Ayar.VfxCarpani else kayit.rate
	vfx.Size = if acik then olcekli(kayit.size, Ayar.VfxCarpani) else kayit.size
end

local function uygula(k: Kule, acik: boolean)
	for parca, kayit in k.parcalar do
		parcaUygula(parca, kayit, acik)
	end
	for vfx, kayit in k.vfxler do
		vfxUygula(vfx, kayit, acik)
	end
	if k.tabela then
		k.tabela.Enabled = acik
	end
end

local function kaydet(k: Kule, d: Instance)
	if d:IsA("BasePart") then
		if k.parcalar[d] or d.Transparency >= 0.99 or d.Name == Ayar.YaziParcasi then
			return
		end
		local _, _, parlaklik = d.Color:ToHSV()
		local kayit = {
			renk = d.Color,
			malzeme = d.Material,
			faz = d.Position.Y * 0.12 + (if parlaklik < 0.6 then math.pi else 0),
		}
		k.parcalar[d] = kayit
		if aktif then
			parcaUygula(d, kayit, true)
		end
	elseif d:IsA("ParticleEmitter") then
		if k.vfxler[d] then
			return
		end
		local kayit = { rate = d.Rate, size = d.Size }
		k.vfxler[d] = kayit
		if aktif then
			vfxUygula(d, kayit, true)
		end
	end

	if not k.tabela and (d.Name == Ayar.YaziParcasi or d:IsA("TextLabel")) then
		tabelaKur(k)
		if k.tabela then
			k.tabela.Enabled = aktif
		end
	elseif d:IsA("TextLabel") then
		yaziTipiAl(k, d)
	end
end

local function kuleKur(model: Model): Kule
	local k: Kule = { model = model, parcalar = {}, vfxler = {}, tabela = nil, ust = nil, alt = nil, baglantilar = {} }

	tabelaKur(k)
	for _, d in model:GetDescendants() do
		kaydet(k, d)
	end

	table.insert(k.baglantilar, model.DescendantAdded:Connect(function(d)
		kaydet(k, d)
	end))
	table.insert(k.baglantilar, model.DescendantRemoving:Connect(function(d)
		if d:IsA("BasePart") then
			k.parcalar[d] = nil
		elseif d:IsA("ParticleEmitter") then
			k.vfxler[d] = nil
		end
	end))

	return k
end

local function kalanSure(): number
	local bitis = Workspace:GetAttribute(Ayar.Nitelik)
	if type(bitis) ~= "number" or bitis <= 0 then
		return 0
	end
	return math.max(0, bitis - Workspace:GetServerTimeNow())
end

local function denetle()
	local model = kuleyiBul()
	local mevcut = kule
	if mevcut and mevcut.model ~= model then
		if mevcut.model.Parent then
			uygula(mevcut, false)
		end
		if mevcut.tabela then
			mevcut.tabela:Destroy()
		end
		for _, b in mevcut.baglantilar do
			b:Disconnect()
		end
		kule = nil
		mevcut = nil
	end
	if not mevcut and model then
		mevcut = kuleKur(model)
		kule = mevcut
		if aktif then
			uygula(mevcut, true)
		end
	end

	local simdiAktif = kalanSure() > 0
	if simdiAktif ~= aktif then
		aktif = simdiAktif
		if mevcut then
			uygula(mevcut, aktif)
		end
	end
end

RunService.Heartbeat:Connect(function()
	local k = kule
	if not aktif or not k then
		return
	end

	local t = os.clock()
	for parca, kayit in k.parcalar do
		local oran = (math.sin(t * 2.5 - kayit.faz) + 1) * 0.5
		parca.Color = Ayar.RenkA:Lerp(Ayar.RenkB, oran)
	end

	local renk = Ayar.RenkA:Lerp(Ayar.RenkB, (math.sin(t * 3) + 1) * 0.5)
	if k.ust then
		k.ust.Text = `{Ayar.SansCarpani}X LUCK ACTIVE!`
		k.ust.TextColor3 = renk
	end
	if k.alt then
		k.alt.Text = `ENDS IN {Ayar.sureYazisi(kalanSure())}`
	end
end)

denetle()
task.spawn(function()
	while true do
		task.wait(1)
		denetle()
	end
end)
