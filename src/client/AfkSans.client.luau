local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("AfkSans"))
local Assets = require(Shared:WaitForChild("Assets"))
local Format = require(Shared:WaitForChild("Format"))
local Hiz = require(Shared:WaitForChild("Hiz"))
local Icons = require(Shared:WaitForChild("Icons"))
local Net = require(Shared:WaitForChild("Net"))
local RobuxMagaza = require(Shared:WaitForChild("RobuxMagaza"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))

local YoncaListesi = Net.event("YoncaListesi")
local YoncaTopla = Net.event("YoncaTopla")
local YoncaSonuc = Net.event("YoncaSonuc")
local YoncaIste = Net.event("YoncaIste")
local LeprechaunAc = Net.event("LeprechaunAc")
local AfkAlanAl = Net.event("AfkAlanAl")
local RobuxUrunAl = Net.event("RobuxUrunAl")

local SIYAH = Color3.new(0, 0, 0)
local BEYAZ = Color3.new(1, 1, 1)
local YONCA_YESIL = Color3.fromRGB(70, 200, 90)

local YURUME_YENILE = 0.5
local VARIS = 1.5
local RED_BEKLEME = 0.4
local RED_SINIRI = 3
local CEVAP_BEKLEME = 3
local FLYBOARD_TABAN = "FlyboardTabanHiz"

local function koyuMu(renk: Color3): boolean
	local _, _, parlaklik = renk:ToHSV()
	return parlaklik < 0.25
end

local function virgullu(n: number): string
	local metin = tostring(math.floor(n))
	local sonuc = metin:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (sonuc:gsub("^,", ""))
end

local function alanKlasoru(): Instance?
	return Workspace:FindFirstChild(Ayar.KlasorAdi)
end

local function zemin(id: string): BasePart?
	local klasor = alanKlasoru()
	local node = klasor and klasor:FindFirstChild(id)
	return if node and node:IsA("BasePart") then node else nil
end

local function kok(): BasePart?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function insan(): Humanoid?
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function seviye(): number
	return tonumber(player:GetAttribute(Ayar.SeviyeNiteligi)) or 1
end

local function robuxFiyati(alan: Ayar.Alan): number
	local urun = if alan.robux then RobuxMagaza.get(alan.robux) else nil
	return if urun then urun.fiyat else 0
end

local function acikMi(sira: number): boolean
	return Ayar.sahip(sira, seviye(), Ayar.ozelCoz(player:GetAttribute(Ayar.OzelNiteligi)))
end

local function puan(): number
	return tonumber(player:GetAttribute(Ayar.PuanNiteligi)) or 0
end

local function yataydaUzaklik(a: Vector3, b: Vector3): number
	return ((a - b) * Vector3.new(1, 0, 1)).Magnitude
end

local kontroller = nil
task.spawn(function()
	local ok, sonuc = pcall(function()
		local modul = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10)
		return if modul then (require(modul) :: any):GetControls() else nil
	end)
	if ok then
		kontroller = sonuc
	end
end)

local function oyuncuYuruyor(): boolean
	if not kontroller then
		return false
	end
	local ok, yon = pcall(function()
		return kontroller:GetMoveVector()
	end)
	return ok and typeof(yon) == "Vector3" and yon.Magnitude > 0.1
end

local ilkHal: { [BasePart]: { cc: boolean, tr: number } } = {}
local kilitYazilari: { [string]: BillboardGui } = {}

local function barikatParcalari(z: BasePart): { BasePart }
	local liste = {}
	for _, node in z:GetDescendants() do
		if string.find(string.lower(node.Name), "barricade", 1, true) then
			if node:IsA("BasePart") then
				table.insert(liste, node)
			end
			for _, ic in node:GetDescendants() do
				if ic:IsA("BasePart") then
					table.insert(liste, ic)
				end
			end
		end
	end
	return liste
end

local function kilitYazisi(alan: Ayar.Alan, parca: BasePart): BillboardGui
	local eski = kilitYazilari[alan.id]
	if eski and eski.Parent and eski.Adornee == parca then
		return eski
	end
	if eski then
		eski:Destroy()
	end

	local renk = Rarity.textColor(Ayar.kademe(alan.id))
	local bb = Instance.new("BillboardGui")
	bb.Name = "AfkKilit_" .. alan.id
	bb.Size = UDim2.fromOffset(260, 70)
	bb.StudsOffset = Vector3.new(0, parca.Size.Y / 2 + 2.5, 0)
	bb.MaxDistance = 90
	bb.LightInfluence = 0
	bb.Adornee = parca
	bb.Parent = playerGui

	UI.text({
		text = "LOCKED",
		size = UI.Sizes.heading,
		font = UI.Fonts.bold,
		color = renk,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 32),
		parent = bb,
	})
	UI.text({
		text = `Unlock {alan.displayName} at the {Ayar.NpcAdi}`,
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 24),
		position = UDim2.fromOffset(0, 34),
		parent = bb,
	})

	kilitYazilari[alan.id] = bb
	return bb
end

local uyariEkrani = Instance.new("ScreenGui")
uyariEkrani.Name = "AfkKilitUyarisi"
uyariEkrani.ResetOnSpawn = false
uyariEkrani.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
uyariEkrani.Parent = playerGui

local UYARI_ARALIGI = 3
local sonUyari = 0
local aktifUyari: Frame? = nil

local function kilitUyarisi(alan: Ayar.Alan)
	local simdi = os.clock()
	if simdi - sonUyari < UYARI_ARALIGI then
		return
	end
	sonUyari = simdi
	if aktifUyari then
		aktifUyari:Destroy()
	end

	local kap = Instance.new("Frame")
	kap.Name = "Uyari"
	kap.AnchorPoint = Vector2.new(0.5, 0.5)
	kap.Position = UDim2.fromScale(0.5, 0.3)
	kap.Size = UDim2.fromOffset(620, 80)
	kap.BackgroundTransparency = 1
	kap.Parent = uyariEkrani
	aktifUyari = kap

	local olcek = Instance.new("UIScale")
	olcek.Scale = 0.4
	olcek.Parent = kap

	local baslik = UI.text({
		text = `{string.upper(alan.displayName)} IS LOCKED!`,
		size = UI.Sizes.huge,
		font = UI.Fonts.bold,
		color = Rarity.textColor(Ayar.kademe(alan.id)),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 46),
		parent = kap,
	})
	local alt = UI.text({
		text = if alan.robux
			then `Talk to the {Ayar.NpcAdi} to unlock it for {robuxFiyati(alan)} Robux`
			else `Talk to the {Ayar.NpcAdi} to unlock it for {Format.short(alan.fiyat)} Rot`,
		size = UI.Sizes.heading,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 30),
		position = UDim2.fromOffset(0, 48),
		parent = kap,
	})

	TweenService:Create(olcek, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(2.6, function()
		if aktifUyari ~= kap then
			return
		end
		local bitis = TweenInfo.new(0.35)
		for _, yazi in { baslik, alt } do
			TweenService:Create(yazi, bitis, { TextTransparency = 1 }):Play()
			local kontur = yazi:FindFirstChildOfClass("UIStroke")
			if kontur then
				TweenService:Create(kontur, bitis, { Transparency = 1 }):Play()
			end
		end
		task.wait(0.4)
		kap:Destroy()
		if aktifUyari == kap then
			aktifUyari = nil
		end
	end)
end

local dokunmaBagli: { [BasePart]: boolean } = {}

local function dokunmaBagla(parca: BasePart, sira: number, alan: Ayar.Alan)
	if dokunmaBagli[parca] then
		return
	end
	dokunmaBagli[parca] = true
	parca.Touched:Connect(function(hit)
		local char = player.Character
		if char and hit:IsDescendantOf(char) and not acikMi(sira) then
			kilitUyarisi(alan)
		end
	end)
end

local suzmeler: { [string]: BasePart } = {}

local function suzmeKur(alan: Ayar.Alan, z: BasePart)
	local eski = suzmeler[alan.id]
	if eski and eski.Parent then
		return
	end

	local renk = Rarity.color(Ayar.kademe(alan.id))
	local kutu = Instance.new("Part")
	kutu.Name = "AfkSuzme_" .. alan.id
	kutu.Anchored = true
	kutu.CanCollide = false
	kutu.CanTouch = false
	kutu.CanQuery = false
	kutu.Transparency = 1
	kutu.Size = Vector3.new(z.Size.X, 4, z.Size.Z)
	kutu.CFrame = z.CFrame * CFrame.new(0, z.Size.Y / 2 + 2, 0)
	kutu.Parent = Workspace

	local alanBoyu = z.Size.X * z.Size.Z

	local toz = Instance.new("ParticleEmitter")
	toz.Name = "Toz"
	toz.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	local koyu = koyuMu(renk)
	toz.Color = if koyu
		then ColorSequence.new(renk:Lerp(BEYAZ, 0.12), renk)
		else ColorSequence.new(renk:Lerp(BEYAZ, 0.35), renk)
	toz.LightEmission = if koyu then 0 else 1
	toz.LightInfluence = 0
	toz.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	toz.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	toz.Lifetime = NumberRange.new(3, 5)
	toz.Speed = NumberRange.new(0.5, 1.5)
	toz.SpreadAngle = Vector2.new(25, 25)
	toz.Acceleration = Vector3.new(0, 0.4, 0)
	toz.Rotation = NumberRange.new(0, 360)
	toz.RotSpeed = NumberRange.new(-40, 40)
	toz.Shape = Enum.ParticleEmitterShape.Box
	toz.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	toz.EmissionDirection = Enum.NormalId.Top
	toz.Rate = math.clamp(alanBoyu / 60, 6, 40)
	toz.Parent = kutu

	local isik = Instance.new("ParticleEmitter")
	isik.Name = "Isik"
	isik.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	isik.Color = ColorSequence.new(renk)
	isik.LightEmission = if koyu then 0 else 1
	isik.LightInfluence = 0
	isik.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 1.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	isik.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	isik.Lifetime = NumberRange.new(4, 6)
	isik.Speed = NumberRange.new(0.2, 0.6)
	isik.Acceleration = Vector3.new(0, 0.2, 0)
	isik.Shape = Enum.ParticleEmitterShape.Box
	isik.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	isik.EmissionDirection = Enum.NormalId.Top
	isik.Rate = math.clamp(alanBoyu / 300, 1, 8)
	isik.Parent = kutu

	suzmeler[alan.id] = kutu
end

local function barikatlariGuncelle()
	for i, alan in Ayar.Alanlar do
		local z = zemin(alan.id)
		if not z then
			continue
		end
		suzmeKur(alan, z)

		local parcalar = barikatParcalari(z)
		local enBuyuk: BasePart? = nil
		for _, parca in parcalar do
			dokunmaBagla(parca, i, alan)
			if not ilkHal[parca] then
				ilkHal[parca] = { cc = parca.CanCollide, tr = parca.Transparency }
			end
			local ilk = ilkHal[parca]
			if acikMi(i) then
				parca.CanCollide = false
				parca.Transparency = 1
			else
				parca.CanCollide = ilk.cc
				parca.Transparency = ilk.tr
			end
			if not enBuyuk or parca.Size.Magnitude > enBuyuk.Size.Magnitude then
				enBuyuk = parca
			end
		end

		if enBuyuk and not acikMi(i) then
			kilitYazisi(alan, enBuyuk)
		elseif kilitYazilari[alan.id] then
			kilitYazilari[alan.id]:Destroy()
			kilitYazilari[alan.id] = nil
		end
	end
end

task.spawn(function()
	while true do
		barikatlariGuncelle()
		task.wait(1)
	end
end)
player:GetAttributeChangedSignal(Ayar.SeviyeNiteligi):Connect(barikatlariGuncelle)
player:GetAttributeChangedSignal(Ayar.OzelNiteligi):Connect(barikatlariGuncelle)

local yoncaKlasoru = Instance.new("Folder")
yoncaKlasoru.Name = "AfkYoncalari"
yoncaKlasoru.Parent = Workspace

type YoncaGorsel = {
	id: number,
	alan: string,
	pos: Vector3,
	yaricap: number,
	model: Model,
	nokta: BasePart,
	altFark: number,
	aci: number,
	donus: CFrame,
	olcek: number,
	k: number,
	yukari: number,
	faz: number,
	tempo: number,
}

local yoncalar: { [number]: YoncaGorsel } = {}
local gidenler: { [YoncaGorsel]: boolean } = {}
local aktifAlan: string? = nil

local function yedekYonca(renk: Color3): Model
	local model = Instance.new("Model")
	model.Name = "YedekYonca"

	local sap = Instance.new("Part")
	sap.Name = "Sap"
	sap.Size = Vector3.new(0.2, 1, 0.2)
	sap.CFrame = CFrame.new(0, 0.5, 0)
	sap.Color = Color3.fromRGB(60, 140, 60)
	sap.Material = Enum.Material.SmoothPlastic
	sap.Parent = model
	model.PrimaryPart = sap

	for i = 0, 3 do
		local yaprak = Instance.new("Part")
		yaprak.Name = "Yaprak"
		yaprak.Shape = Enum.PartType.Cylinder
		yaprak.Size = Vector3.new(0.25, 1.1, 1.1)
		local aci = i * math.pi / 2
		yaprak.CFrame = CFrame.new(math.cos(aci) * 0.5, 1.05, math.sin(aci) * 0.5) * CFrame.Angles(0, 0, math.pi / 2)
		yaprak.Color = renk
		yaprak.Material = Enum.Material.SmoothPlastic
		yaprak.Parent = model
	end

	return model
end

local function hazirla(model: Model)
	Assets.stripScripts(model)

	local oynayan: { [BasePart]: boolean } = {}
	for _, node in model:GetDescendants() do
		if node:IsA("Motor6D") and node.Part1 then
			oynayan[node.Part1] = true
		end
	end

	for _, node in model:GetDescendants() do
		if node:IsA("BasePart") then
			node.Anchored = not oynayan[node]
			node.CanCollide = false
			node.CanTouch = false
			node.CanQuery = false
			node.Massless = true
		elseif node:IsA("Humanoid") then
			node.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			node.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end
	end
end

local SALINIM_ACI = math.rad(7)

local function konumla(g: YoncaGorsel, t: number)
	local s = t * g.tempo + g.faz
	local ax = (math.sin(s * 1.6) * 0.75 + math.sin(s * 3.7) * 0.25) * SALINIM_ACI
	local az = math.cos(s * 1.2 + 0.8) * 0.6 * SALINIM_ACI

	local taban = CFrame.new(g.pos) * CFrame.Angles(0, g.aci, 0) * CFrame.Angles(ax, 0, az)
	g.model:PivotTo(taban * CFrame.new(0, g.altFark * g.k + g.yukari, 0) * g.donus)
end

local function boyutla(g: YoncaGorsel, k: number, yukari: number?)
	g.k = k
	g.yukari = yukari or 0
	local hedef = g.model:GetAttribute("TabanOlcek") :: number
	g.model:ScaleTo(math.max(hedef * g.olcek * k, 0.01))
	konumla(g, os.clock())
end

local function yoncaKur(alanId: string, v: any)
	if yoncalar[v.id] then
		return
	end

	local renk = Rarity.color(Ayar.kademe(alanId))
	local model = Assets.cloverModel(alanId) or yedekYonca(renk)
	model.Name = `Yonca_{v.id}`
	hazirla(model)

	local taban = model:GetScale()
	model:SetAttribute("TabanOlcek", taban)
	model:ScaleTo(taban * v.olcek)

	local pivot = model:GetPivot()
	local kutu, boy = model:GetBoundingBox()
	local altFark = pivot.Position.Y - (kutu.Position.Y - boy.Y / 2)
	local tepe = boy.Y

	local nokta = Instance.new("Part")
	nokta.Name = `YoncaNoktasi_{v.id}`
	nokta.Anchored = true
	nokta.CanCollide = false
	nokta.CanTouch = false
	nokta.CanQuery = false
	nokta.Transparency = 1
	nokta.Size = Vector3.new(0.2, 0.2, 0.2)
	nokta.Position = v.pos + Vector3.new(0, tepe + 1.2, 0)
	nokta.Parent = yoncaKlasoru

	local g: YoncaGorsel = {
		id = v.id,
		alan = alanId,
		pos = v.pos,
		yaricap = v.yaricap,
		model = model,
		nokta = nokta,
		altFark = altFark,
		aci = v.aci,
		donus = pivot - pivot.Position,
		olcek = v.olcek,
		k = 1,
		yukari = 0,
		faz = math.random() * math.pi * 2,
		tempo = 0.8 + math.random() * 0.5,
	}
	yoncalar[v.id] = g

	boyutla(g, 0.05)
	model.Parent = yoncaKlasoru
	Assets.playAnimations(model)

	local deger = Instance.new("NumberValue")
	deger.Value = 0.05
	deger.Changed:Connect(function(k)
		if yoncalar[g.id] == g then
			boyutla(g, k)
		end
	end)
	local tw = TweenService:Create(deger, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 1 })
	tw.Completed:Once(function()
		deger:Destroy()
	end)
	tw:Play()
end

local function yazdirKazanc(pos: Vector3, miktar: number, renk: Color3)
	local nokta = Instance.new("Part")
	nokta.Anchored = true
	nokta.CanCollide = false
	nokta.CanTouch = false
	nokta.CanQuery = false
	nokta.Transparency = 1
	nokta.Size = Vector3.new(0.2, 0.2, 0.2)
	nokta.Position = pos + Vector3.new(0, 2.5, 0)
	nokta.Parent = yoncaKlasoru

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 40)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Adornee = nokta
	bb.Parent = playerGui

	local yazi = UI.text({
		text = if miktar > 0 then `+{virgullu(miktar)} Clover Luck` else "MAX Clover Luck!",
		size = UI.Sizes.heading,
		font = UI.Fonts.bold,
		color = renk,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = bb,
	})

	local bilgi = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(nokta, bilgi, { Position = nokta.Position + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(yazi, bilgi, { TextTransparency = 1 }):Play()
	local kontur = yazi:FindFirstChildOfClass("UIStroke")
	if kontur then
		TweenService:Create(kontur, bilgi, { Transparency = 1 }):Play()
	end
	task.delay(1.2, function()
		bb:Destroy()
		nokta:Destroy()
	end)
end

local function yoncaSil(id: number, toplandi: boolean)
	local g = yoncalar[id]
	if not g then
		return
	end
	yoncalar[id] = nil
	g.nokta:Destroy()

	if not toplandi then
		g.model:Destroy()
		return
	end

	gidenler[g] = true
	local deger = Instance.new("NumberValue")
	deger.Value = 1
	deger.Changed:Connect(function(k)
		boyutla(g, k, (1 - k) * 2.5)
	end)
	local tw = TweenService:Create(deger, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = 0.05 })
	tw.Completed:Once(function()
		deger:Destroy()
		gidenler[g] = nil
		g.model:Destroy()
	end)
	tw:Play()
end

local SALINIM_MESAFE = 160

RunService.RenderStepped:Connect(function()
	local kamera = Workspace.CurrentCamera
	if not kamera then
		return
	end
	local t = os.clock()
	local goz = kamera.CFrame.Position
	for _, g in yoncalar do
		if (g.pos - goz).Magnitude <= SALINIM_MESAFE then
			konumla(g, t)
		end
	end
	for g in gidenler do
		konumla(g, t)
	end
end)

type Bar = {
	gui: BillboardGui,
	kutu: Frame,
	dolgu: Frame,
	sayi: TextLabel,
	olcek: UIScale,
	sonSaniye: number,
}

local function barKur(g: YoncaGorsel, renk: Color3): Bar
	local gui = Instance.new("BillboardGui")
	gui.Name = "YoncaBari"
	gui.Size = UDim2.fromOffset(190, 50)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Adornee = g.nokta
	gui.Parent = playerGui

	local kutu = Instance.new("Frame")
	kutu.Name = "Kutu"
	kutu.AnchorPoint = Vector2.new(0.5, 0.5)
	kutu.Position = UDim2.fromScale(0.5, 0.5)
	kutu.Size = UDim2.fromOffset(160, 24)
	local koyu = koyuMu(renk)
	kutu.BackgroundColor3 = if koyu then Color3.fromRGB(205, 205, 215) else Color3.fromRGB(20, 22, 30)
	kutu.BorderSizePixel = 0
	kutu.Parent = gui
	UI.corner(kutu, 12)
	UI.stroke(kutu, if koyu then BEYAZ else SIYAH, 3)

	local olcek = Instance.new("UIScale")
	olcek.Parent = kutu

	local dolgu = Instance.new("Frame")
	dolgu.Name = "Dolgu"
	dolgu.Size = UDim2.fromScale(1, 1)
	dolgu.BackgroundColor3 = renk
	dolgu.BorderSizePixel = 0
	dolgu.Parent = kutu
	UI.corner(dolgu, 12)
	UI.cubukCilasi(dolgu)

	local sayi = UI.text({
		text = tostring(Ayar.ToplamaSuresi),
		size = UI.Sizes.label,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = kutu,
		zIndex = 3,
	})

	return {
		gui = gui,
		kutu = kutu,
		dolgu = dolgu,
		sayi = sayi,
		olcek = olcek,
		sonSaniye = Ayar.ToplamaSuresi,
	}
end

local function barCiz(bar: Bar, gecen: number)
	local sure = Ayar.ToplamaSuresi
	local kalan = math.max(sure - gecen, 0)
	local oran = kalan / sure

	bar.dolgu.Size = UDim2.fromScale(oran, 1)
	bar.dolgu.Visible = oran > 0.01

	local saniye = math.max(math.ceil(kalan), 1)
	bar.sayi.Text = tostring(saniye)
	if saniye ~= bar.sonSaniye then
		bar.sonSaniye = saniye
		bar.olcek.Scale = 1.25
		TweenService:Create(bar.olcek, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end

	if kalan <= Ayar.TitremeSuresi then
		local siddet = 1.5 + (1 - kalan / Ayar.TitremeSuresi) * 3
		bar.kutu.Position = UDim2.new(0.5, math.random(-100, 100) / 100 * siddet, 0.5, math.random(-100, 100) / 100 * siddet)
		bar.kutu.Rotation = math.random(-100, 100) / 100 * siddet * 1.5
	else
		bar.kutu.Position = UDim2.fromScale(0.5, 0.5)
		bar.kutu.Rotation = 0
	end
end

local efektEkrani = Instance.new("ScreenGui")
efektEkrani.Name = "AfkSansEfekt"
efektEkrani.ResetOnSpawn = false
efektEkrani.IgnoreGuiInset = true
efektEkrani.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
efektEkrani.Parent = playerGui

local LUCK_TURLERI = {
	{ ikon = "luck1", agirlik = 60, boyMin = 44, boyMax = 80, renk = Color3.fromRGB(90, 230, 110) },
	{ ikon = "luck2", agirlik = 30, boyMin = 60, boyMax = 100, renk = Color3.fromRGB(90, 170, 255) },
	{ ikon = "luck3", agirlik = 10, boyMin = 80, boyMax = 130, renk = Color3.fromRGB(255, 210, 60) },
}
local LUCK_TOPLAM = 0
for _, tur in LUCK_TURLERI do
	LUCK_TOPLAM += tur.agirlik
end
local LUCK_ARALIK = 0.07

local ikonOnbellek: { [string]: string } = {}

local function luckResmi(ad: string): string?
	local resim = ikonOnbellek[ad]
	if resim then
		return resim
	end
	local ok, sonuc = pcall(Icons.of, ad)
	if ok and type(sonuc) == "string" and sonuc ~= "" then
		ikonOnbellek[ad] = sonuc
		return sonuc
	end
	return nil
end

local function luckSec()
	local zar = math.random() * LUCK_TOPLAM
	for _, tur in LUCK_TURLERI do
		zar -= tur.agirlik
		if zar <= 0 then
			return tur
		end
	end
	return LUCK_TURLERI[1]
end

local function luckIkonu()
	local tur = luckSec()
	local resim = luckResmi(tur.ikon)
	if not resim then
		return
	end

	local boy = math.random(tur.boyMin, tur.boyMax)
	local kap = Instance.new("Frame")
	kap.Name = "LuckIkonu"
	kap.AnchorPoint = Vector2.new(0.5, 0.5)
	local x = math.random(8, 92) / 100
	local y = math.random(12, 88) / 100
	if math.abs(x - 0.5) < 0.15 and math.abs(y - 0.5) < 0.18 then
		x += if x < 0.5 then -0.18 else 0.18
	end
	kap.Position = UDim2.fromScale(x, y)
	kap.Size = UDim2.fromOffset(boy, boy)
	kap.BackgroundTransparency = 1
	kap.Rotation = math.random(-25, 25)
	kap.Parent = efektEkrani

	local olcek = Instance.new("UIScale")
	olcek.Scale = 0
	olcek.Parent = kap

	local hale = UI.parlama(kap, tur.renk, boy * 1.5, 1)

	local ikon = Instance.new("ImageLabel")
	ikon.Name = "Ikon"
	ikon.BackgroundTransparency = 1
	ikon.Size = UDim2.fromScale(1, 1)
	ikon.Image = resim
	ikon.ScaleType = Enum.ScaleType.Fit
	ikon.ZIndex = 2
	ikon.Parent = kap

	local omur = 0.7 + math.random() * 0.4
	TweenService:Create(olcek, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(kap, TweenInfo.new(omur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = kap.Position - UDim2.fromOffset(0, math.random(30, 70)),
		Rotation = kap.Rotation + math.random(-30, 30),
	}):Play()

	task.delay(omur * 0.6, function()
		local bitis = TweenInfo.new(omur * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(ikon, bitis, { ImageTransparency = 1 }):Play()
		TweenService:Create(olcek, bitis, { Scale = 1.35 }):Play()
		for _, halka in hale:GetDescendants() do
			if halka:IsA("Frame") then
				TweenService:Create(halka, bitis, { BackgroundTransparency = 1 }):Play()
			end
		end
	end)
	task.delay(omur + 0.05, function()
		kap:Destroy()
	end)
end

local screen = Instance.new("ScreenGui")
screen.Name = "AfkSans"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local hud = Instance.new("Frame")
hud.Name = "SansHUD"
hud.AnchorPoint = Vector2.new(0.5, 1)
hud.Position = UDim2.new(0.5, 0, 1, -140)
hud.Size = UDim2.fromOffset(480, 84)
hud.BackgroundColor3 = UI.Colors.panel
hud.BackgroundTransparency = 0.1
hud.BorderSizePixel = 0
hud.Visible = false
hud.Parent = screen
UI.corner(hud, 12)
UI.stroke(hud, SIYAH, 3)

local SUTUN_GENISLIK = 170
local XP_SUTUN_X = 14 + SUTUN_GENISLIK + 12

local hudBaslik = UI.text({
	text = "CLOVER LUCK",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = YONCA_YESIL,
	frameSize = UDim2.fromOffset(SUTUN_GENISLIK, 20),
	position = UDim2.fromOffset(14, 6),
	parent = hud,
})

local hudPuan = UI.text({
	text = "0",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = BEYAZ,
	frameSize = UDim2.fromOffset(SUTUN_GENISLIK, 32),
	position = UDim2.fromOffset(14, 25),
	parent = hud,
})
local hudPuanOlcek = Instance.new("UIScale")
hudPuanOlcek.Parent = hudPuan

local toplamXp = 0
local hudXpBaslik = UI.text({
	text = "XP GAIN",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = YONCA_YESIL,
	frameSize = UDim2.fromOffset(140, 20),
	position = UDim2.fromOffset(XP_SUTUN_X, 6),
	parent = hud,
})

local hudXpMiktar = UI.text({
	text = "+0",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = BEYAZ,
	frameSize = UDim2.fromOffset(140, 32),
	position = UDim2.fromOffset(XP_SUTUN_X, 25),
	parent = hud,
})
local hudXpOlcek = Instance.new("UIScale")
hudXpOlcek.Parent = hudXpMiktar

local function xpGainYaz()
	hudXpMiktar.Text = `+{virgullu(toplamXp)}`
end

local function xpGainGoster(miktar: number)
	toplamXp += miktar
	xpGainYaz()
	hudXpOlcek.Scale = 1.2
	hudXpMiktar.TextColor3 = UI.Colors.gold
	TweenService:Create(hudXpOlcek, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(hudXpMiktar, TweenInfo.new(0.6), { TextColor3 = BEYAZ }):Play()
end

local function xpGainSifirla()
	toplamXp = 0
	xpGainYaz()
end

local IPUCLARI = {
	"Every clover makes your digs LUCKIER!",
	"AFK here and come back with rarer Brainrots!",
	"Clover Luck never runs out - it's permanent!",
	"Better fields give WAY more Clover Luck!",
	"Up to x20 Luck on every dig!",
	"Stand still and collecting starts by itself!",
}
local hudIpucu = UI.text({
	text = IPUCLARI[1],
	size = UI.Sizes.tiny,
	font = UI.Fonts.bold,
	color = UI.Colors.gold,
	frameSize = UDim2.new(1, -150, 0, 18),
	position = UDim2.fromOffset(14, 60),
	parent = hud,
})

task.spawn(function()
	local sira = 1
	while true do
		task.wait(5)
		sira = sira % #IPUCLARI + 1
		hudIpucu.Text = IPUCLARI[sira]
	end
end)

local otoDugme, _, otoYazi = UI.dugme3B(hud, "AUTO", UDim2.fromOffset(120, 50), UI.Colors.good)
otoDugme.AnchorPoint = Vector2.new(1, 0.5)
otoDugme.Position = UDim2.new(1, -10, 0.5, 0)

local gosterilen = 0
local sayac = Instance.new("NumberValue")
sayac.Changed:Connect(function(v)
	gosterilen = v
	hudPuan.Text = virgullu(v)
end)

local function hudGuncelle()
	local p = puan()
	if player:GetAttribute(Ayar.PuanNiteligi) == nil or p <= gosterilen or not hud.Visible then
		sayac.Value = p
		return
	end

	TweenService:Create(sayac, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = p }):Play()
	hudPuanOlcek.Scale = 1.2
	hudPuan.TextColor3 = UI.Colors.gold
	TweenService:Create(hudPuanOlcek, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(hudPuan, TweenInfo.new(0.6), { TextColor3 = BEYAZ }):Play()
end
player:GetAttributeChangedSignal(Ayar.PuanNiteligi):Connect(hudGuncelle)
hudGuncelle()

local oto = false
local elleKapatildi = false
local sonKendiYurume = os.clock()
local hedefId: number? = nil
local sonYurume = 0
local reddedilen: { [number]: number } = {}
local redSayisi: { [number]: number } = {}

type Toplanan = { id: number, basla: number, bar: Bar }
local toplanan: Toplanan? = nil

local function flyboardda(h: Humanoid): boolean
	return h:GetAttribute(FLYBOARD_TABAN) ~= nil
end

local function normalHiz(): number
	return Hiz.hiz(tonumber(player:GetAttribute(Hiz.Nitelik)) or 0)
end

local function hiziSabitle(h: Humanoid)
	if not flyboardda(h) and h.WalkSpeed ~= Hiz.TabanHiz then
		h.WalkSpeed = Hiz.TabanHiz
	end
end

local function hiziGeriVer()
	local h = insan()
	if h and not flyboardda(h) then
		h.WalkSpeed = normalHiz()
	end
end

local function otoCiz()
	if otoYazi then
		otoYazi.Text = if oto then "STOP" else "AUTO"
	end
	UI.dugme3BRenk(otoDugme, if oto then UI.Colors.bad else UI.Colors.good)
end

local function yurumeyiKes()
	local h = insan()
	local root = kok()
	if h and root then
		h:MoveTo(root.Position)
	end
end

local TOPLAMA_NITELIGI = "YoncaTopluyor"

local animIzleri: { [Humanoid]: AnimationTrack } = {}

local function toplamaIzi(h: Humanoid): AnimationTrack?
	local iz = animIzleri[h]
	if iz then
		return iz
	end

	local animator = h:FindFirstChildOfClass("Animator")
	if not animator then
		return nil
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = Ayar.ToplamaAnimasyonu
	local ok, sonuc = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if not ok or not sonuc then
		warn(`[AfkSans] collect animation failed to load: {tostring(sonuc)}`)
		return nil
	end

	sonuc.Priority = Enum.AnimationPriority.Action
	sonuc.Looped = false
	animIzleri[h] = sonuc
	h.Destroying:Once(function()
		animIzleri[h] = nil
	end)
	return sonuc
end

local function toplamaDurusu(acik: boolean)
	local char = player.Character
	local h = insan()
	if char then
		char:SetAttribute(TOPLAMA_NITELIGI, acik)
	end
	if not h then
		return
	end
	h.AutoRotate = not acik

	local iz = toplamaIzi(h)
	if not iz then
		return
	end
	if acik then
		iz:Play(0.15)
		if iz.Length > 0 then
			iz:AdjustSpeed(iz.Length / Ayar.ToplamaSuresi)
		end
	else
		iz:Stop(0.2)
	end
end

local function yoncayaDon(root: BasePart, hedef: Vector3, dt: number)
	local bak = Vector3.new(hedef.X, root.Position.Y, hedef.Z)
	if (bak - root.Position).Magnitude < 0.05 then
		return
	end
	local hedefCf = CFrame.lookAt(root.Position, bak)
	root.CFrame = root.CFrame:Lerp(hedefCf, math.clamp(dt * 14, 0, 1))
end

local function toplamaBirak(sunucuyaSoyle: boolean)
	local t = toplanan
	if not t then
		return
	end
	toplanan = nil
	t.bar.gui:Destroy()
	toplamaDurusu(false)
	if sunucuyaSoyle then
		YoncaTopla:FireServer(nil)
	end
end

local function otoAyarla(acik: boolean)
	if acik then
		local h = insan()
		if not aktifAlan or not h or h.Health <= 0 or flyboardda(h) then
			return
		end
	end
	if oto == acik then
		return
	end

	oto = acik
	hedefId = nil
	if acik then
		table.clear(reddedilen)
		table.clear(redSayisi)
	else
		toplamaBirak(true)
		yurumeyiKes()
		hiziGeriVer()
	end
	otoCiz()
end

local function hedefUygun(id: number, simdi: number): boolean
	local g = yoncalar[id]
	return g ~= nil and g.alan == aktifAlan and (reddedilen[id] or 0) <= simdi
end

local function enYakin(root: BasePart, simdi: number): YoncaGorsel?
	local secilen, enKisa = nil, math.huge
	for id, g in yoncalar do
		if not hedefUygun(id, simdi) then
			continue
		end
		local d = yataydaUzaklik(g.pos, root.Position)
		if d < enKisa then
			secilen, enKisa = g, d
		end
	end
	return secilen
end

local sonIkon = 0

RunService.Heartbeat:Connect(function(dt)
	if oyuncuYuruyor() then
		sonKendiYurume = os.clock()
	end

	if not oto then
		if aktifAlan and not elleKapatildi and os.clock() - sonKendiYurume >= Ayar.OtoBaslamaBekleme then
			otoAyarla(true)
		end
		return
	end

	local root = kok()
	local h = insan()
	if not root or not h or h.Health <= 0 or not aktifAlan or flyboardda(h) then
		otoAyarla(false)
		return
	end

	if oyuncuYuruyor() then
		otoAyarla(false)
		return
	end

	hiziSabitle(h)
	local simdi = os.clock()

	local t = toplanan
	if t then
		local g = yoncalar[t.id]
		if not g then
			toplamaBirak(false)
		elseif yataydaUzaklik(g.pos, root.Position) > g.yaricap + Ayar.Erisim + 1 then
			toplamaBirak(true)
		elseif simdi - t.basla > Ayar.ToplamaSuresi + CEVAP_BEKLEME then
			reddedilen[t.id] = simdi + 2
			hedefId = nil
			toplamaBirak(true)
		else
			yoncayaDon(root, g.pos, dt)
			barCiz(t.bar, simdi - t.basla)
			if simdi - sonIkon >= LUCK_ARALIK then
				sonIkon = simdi
				luckIkonu()
			end
			return
		end
	end

	local hedef = if hedefId and hedefUygun(hedefId, simdi) then yoncalar[hedefId] else nil
	if not hedef then
		hedef = enYakin(root, simdi)
		hedefId = if hedef then hedef.id else nil
		sonYurume = 0
	end
	if not hedef then
		return
	end

	if yataydaUzaklik(hedef.pos, root.Position) <= hedef.yaricap + VARIS then
		yurumeyiKes()
		toplamaDurusu(true)
		yoncayaDon(root, hedef.pos, dt)
		toplanan = {
			id = hedef.id,
			basla = simdi,
			bar = barKur(hedef, Rarity.color(Ayar.kademe(aktifAlan))),
		}
		YoncaTopla:FireServer(hedef.id)
		return
	end

	if simdi - sonYurume >= YURUME_YENILE then
		sonYurume = simdi
		h:MoveTo(hedef.pos)
	end
end)

local function elleCevir()
	local acilsin = not oto
	otoAyarla(acilsin)
	elleKapatildi = not acilsin
end

UserInputService.InputBegan:Connect(function(input, islendi)
	if islendi or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	if aktifAlan then
		elleCevir()
	end
end)

UserInputService.TouchTapInWorld:Connect(function(_, islendi)
	if not islendi and aktifAlan then
		elleCevir()
	end
end)

otoDugme.MouseButton1Click:Connect(elleCevir)

local AfkYenidenBaglan = Net.event("AfkYenidenBaglan")
local sonGirdi = os.clock()
local istendi = false

local function girdiGeldi()
	sonGirdi = os.clock()
end
UserInputService.InputBegan:Connect(girdiGeldi)
UserInputService.InputChanged:Connect(girdiGeldi)

local function yenidenBaglanIste()
	if istendi or not aktifAlan then
		return
	end
	istendi = true
	AfkYenidenBaglan:FireServer()
	task.delay(30, function()
		istendi = false
	end)
end

player.Idled:Connect(function(sure)
	if sure >= Ayar.YenidenBaglanSuresi then
		yenidenBaglanIste()
	end
end)

task.spawn(function()
	while true do
		task.wait(5)
		if os.clock() - sonGirdi >= Ayar.YenidenBaglanSuresi then
			yenidenBaglanIste()
		end
	end
end)

YoncaListesi.OnClientEvent:Connect(function(alanId, liste)
	if type(alanId) ~= "string" or not Ayar.get(alanId) then
		return
	end

	for id, g in yoncalar do
		if g.alan == alanId then
			if toplanan and toplanan.id == id then
				toplamaBirak(false)
			end
			yoncaSil(id, false)
		end
	end

	if type(liste) == "table" then
		for _, v in liste do
			yoncaKur(alanId, v)
		end
	end
end)

Net.event("AfkAlan").OnClientEvent:Connect(function(alanId)
	otoAyarla(false)
	elleKapatildi = false
	xpGainSifirla()
	aktifAlan = if type(alanId) == "string" and Ayar.get(alanId) then alanId else nil

	if not aktifAlan then
		hud.Visible = false
		return
	end

	hudBaslik.TextColor3 = Rarity.textColor(Ayar.kademe(aktifAlan))
	hudXpBaslik.TextColor3 = hudBaslik.TextColor3
	hudGuncelle()
	otoCiz()
	hud.Visible = true
end)

YoncaIste:FireServer()

YoncaSonuc.OnClientEvent:Connect(function(id, ok, kazanc, yeni, yok)
	if type(id) ~= "number" then
		return
	end

	local t = toplanan
	if t and t.id == id then
		toplamaBirak(false)
	end

	if not ok and yok == true then
		yoncaSil(id, false)
		if hedefId == id then
			hedefId = nil
		end
		return
	end

	if not ok then
		local sayi = (redSayisi[id] or 0) + 1
		redSayisi[id] = sayi
		if sayi >= RED_SINIRI then
			reddedilen[id] = os.clock() + 3
			if hedefId == id then
				hedefId = nil
			end
		else
			reddedilen[id] = os.clock() + RED_BEKLEME
		end
		return
	end

	redSayisi[id] = nil
	local g = yoncalar[id]
	if g then
		yazdirKazanc(g.pos, tonumber(kazanc) or 0, Rarity.textColor(Ayar.kademe(g.alan)))
	end
	xpGainGoster(Ayar.YoncaXp)
	yoncaSil(id, true)

	if hedefId == id then
		hedefId = nil
	end
	if type(yeni) == "table" and type(yeni.alan) == "string" then
		yoncaKur(yeni.alan, yeni)
	end
end)

player.CharacterAdded:Connect(function()
	oto = false
	hedefId = nil
	toplamaBirak(true)
	otoCiz()
end)

local panel = UI.panel(screen, UDim2.fromOffset(620, 560), "Leprechaun")
UI.closeButton(panel).MouseButton1Click:Connect(function()
	panel.Visible = false
end)
UI.baslikCubugu(panel, "LEPRECHAUN", Color3.fromRGB(80, 220, 100), Color3.fromRGB(20, 120, 60))

local ozet = Instance.new("Frame")
ozet.Name = "Ozet"
ozet.Position = UDim2.fromOffset(16, 72)
ozet.Size = UDim2.new(1, -32, 0, 70)
ozet.BackgroundColor3 = UI.Colors.panelLight
ozet.BorderSizePixel = 0
ozet.Parent = panel
UI.corner(ozet, 10)
UI.stroke(ozet, SIYAH, 2)

local ozetPuan = UI.text({
	text = "",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	color = YONCA_YESIL,
	frameSize = UDim2.new(1, -24, 0, 28),
	position = UDim2.fromOffset(12, 6),
	parent = ozet,
})

UI.text({
	text = "AFK in a clover field to boost your dig luck forever. Better fields = WAY more luck!",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = UI.Colors.gold,
	frameSize = UDim2.new(1, -24, 0, 22),
	position = UDim2.fromOffset(12, 40),
	parent = ozet,
})

local panelListe = Instance.new("ScrollingFrame")
panelListe.Name = "Liste"
panelListe.Position = UDim2.fromOffset(14, 152)
panelListe.Size = UDim2.new(1, -28, 1, -166)
panelListe.BackgroundTransparency = 1
panelListe.BorderSizePixel = 0
panelListe.ScrollBarThickness = 5
panelListe.ScrollBarImageColor3 = UI.Colors.panelLight
panelListe.CanvasSize = UDim2.new()
panelListe.AutomaticCanvasSize = Enum.AutomaticSize.Y
panelListe.Parent = panel
UI.listePayi(panelListe)

local panelDizi = Instance.new("UIListLayout")
panelDizi.Padding = UDim.new(0, 8)
panelDizi.SortOrder = Enum.SortOrder.LayoutOrder
panelDizi.Parent = panelListe

local function panelCiz(veri: any)
	for _, child in panelListe:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local p = tonumber(veri.puan) or 0
	ozetPuan.Text = `Your Clover Luck: {virgullu(p)}`

	for i, alan in veri.alanlar do
		local renk = Rarity.color(Ayar.kademe(alan.id))
		local yaziRengi = Rarity.textColor(Ayar.kademe(alan.id))

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -6, 0, 76)
		row.BackgroundColor3 = UI.Colors.panelLight
		row.BorderSizePixel = 0
		row.LayoutOrder = i
		row.Parent = panelListe
		UI.corner(row, 10)
		UI.stroke(row, if alan.buyable then (if koyuMu(renk) then yaziRengi else renk) else SIYAH, if alan.buyable then 3 else 2)
		if not alan.owned and not alan.buyable then
			row.BackgroundTransparency = 0.35
		end

		UI.text({
			text = alan.displayName,
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = yaziRengi,
			frameSize = UDim2.new(1, -190, 0, 24),
			position = UDim2.fromOffset(14, 10),
			parent = row,
		})

		UI.text({
			text = `+{alan.puanYonca} Clover Luck per clover`,
			size = UI.Sizes.small,
			color = UI.Colors.textDim,
			frameSize = UDim2.new(1, -190, 0, 20),
			position = UDim2.fromOffset(14, 40),
			parent = row,
		})

		if alan.owned then
			UI.text({
				text = "UNLOCKED",
				size = UI.Sizes.body,
				font = UI.Fonts.bold,
				color = UI.Colors.good,
				align = Enum.TextXAlignment.Right,
				frameSize = UDim2.fromOffset(160, 24),
				position = UDim2.new(1, -174, 0.5, -12),
				parent = row,
			})
		elseif alan.buyable and type(alan.robux) == "string" then
			local urun = RobuxMagaza.get(alan.robux)
			local dugme, yuz = UI.dugme3B(row, "", UDim2.fromOffset(160, 50), Color3.fromRGB(150, 60, 255))
			dugme.Position = UDim2.new(1, -172, 0.5, -25)
			local fiyat = UI.robuxFiyati(yuz, if urun then urun.fiyat else 0, UI.Sizes.label, (yuz.ZIndex or 1) + 1)
			fiyat.AnchorPoint = Vector2.new(0.5, 0.5)
			fiyat.Position = UDim2.fromScale(0.5, 0.5)
			local robuxAnahtari = alan.robux
			dugme.MouseButton1Click:Connect(function()
				RobuxUrunAl:FireServer(robuxAnahtari)
			end)

			UI.text({
				text = "ROBUX ONLY",
				size = UI.Sizes.tiny,
				font = UI.Fonts.bold,
				color = UI.Colors.gold,
				align = Enum.TextXAlignment.Right,
				frameSize = UDim2.fromOffset(120, 18),
				position = UDim2.new(1, -300, 0, 12),
				parent = row,
			})
		elseif alan.buyable then
			local yeterli = (tonumber(veri.rot) or 0) >= alan.fiyat
			local dugme = UI.dugme3B(
				row,
				`{Format.short(alan.fiyat)} Rot`,
				UDim2.fromOffset(160, 50),
				if yeterli then UI.Colors.good else UI.Colors.warn
			)
			dugme.Position = UDim2.new(1, -172, 0.5, -25)
			dugme.MouseButton1Click:Connect(function()
				AfkAlanAl:FireServer(alan.id)
			end)
		else
			UI.text({
				text = "LOCKED",
				size = UI.Sizes.body,
				font = UI.Fonts.bold,
				color = UI.Colors.textDim,
				align = Enum.TextXAlignment.Right,
				frameSize = UDim2.fromOffset(160, 24),
				position = UDim2.new(1, -174, 0.5, -12),
				parent = row,
			})
		end
	end
end

LeprechaunAc.OnClientEvent:Connect(function(veri)
	if type(veri) ~= "table" or type(veri.alanlar) ~= "table" then
		return
	end
	panelCiz(veri)
	panel.Visible = true
end)
