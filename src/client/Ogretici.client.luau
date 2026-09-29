--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("OyunConfig"))
local Bases = require(Shared:WaitForChild("Bases"))
local Adimlar = require(Shared:WaitForChild("Ogretici"))
local Icons = require(Shared:WaitForChild("Icons"))

local UI = require(script.Parent:WaitForChild("UI"))

local KUM_YAKINLIK = 26

local OgreticiDurum = Net.event("OgreticiDurum")
local OgreticiIste = Net.event("OgreticiIste")
local BaseGuncelle = Net.event("BaseGuncelle")

local ISARET = Adimlar.IsaretRengi
local SIYAH = Color3.fromRGB(0, 0, 0)
local BEYAZ = Color3.fromRGB(255, 255, 255)

local cevapGeldi = false
local siraNo = 0
local bitti = true
local toplamAdim = Adimlar.adimSayisi()

local baseIndex: number? = nil

local hedef: Instance? = nil

local sonTeshis = ""

local ekran = Instance.new("ScreenGui")
ekran.Name = "Ogretici"
ekran.DisplayOrder = 6
ekran.ResetOnSpawn = false
ekran.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ekran.Parent = playerGui

local SERIT_EN = 460
local SERIT_DAR = 40
local SERIT_GENIS = 62
local GENIS_SURE = 6

local serit = Instance.new("Frame")
serit.Name = "Yonerge"
serit.AnchorPoint = Vector2.new(0.5, 0)
serit.Position = UDim2.new(0.5, 0, 0, 66)
serit.Size = UDim2.fromOffset(SERIT_EN, SERIT_DAR)
serit.BackgroundColor3 = BEYAZ
serit.BackgroundTransparency = 0.12
serit.BorderSizePixel = 0
serit.ClipsDescendants = true
serit.Visible = false
serit.Parent = ekran
UI.corner(serit, 12)
local seritKontur = UI.stroke(serit, SIYAH, 2)

do
	local zemin = Instance.new("UIGradient")
	zemin.Rotation = 90
	zemin.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 52, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(32, 30, 62)),
	})
	zemin.Parent = serit
end

local yonergeYazi = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -24, 0, SERIT_DAR),
	position = UDim2.fromOffset(12, 0),
	parent = serit,
	zIndex = 5,
})
yonergeYazi.RichText = true
yonergeYazi.TextTruncate = Enum.TextTruncate.AtEnd

local altYazi = UI.text({
	text = "",
	size = UI.Sizes.tiny,
	color = Color3.fromRGB(205, 210, 225),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -24, 0, 18),
	position = UDim2.fromOffset(12, SERIT_DAR - 4),
	parent = serit,
	zIndex = 5,
})
altYazi.TextTruncate = Enum.TextTruncate.AtEnd
altYazi.Visible = false

local sonYazi = ""
local genisSayac = 0

local function daralt()
	altYazi.Visible = false
	TweenService:Create(
		serit,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(SERIT_EN, SERIT_DAR) }
	):Play()
end

local function genislet(altVar: boolean)
	genisSayac += 1
	local bu = genisSayac

	seritKontur.Color = ISARET
	seritKontur.Thickness = 3
	TweenService:Create(seritKontur, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Color = SIYAH,
		Thickness = 2,
	}):Play()

	if not altVar then
		daralt()
		return
	end
	altYazi.Visible = true
	TweenService:Create(
		serit,
		TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(SERIT_EN, SERIT_GENIS) }
	):Play()
	task.delay(GENIS_SURE, function()
		if bu == genisSayac then
			daralt()
		end
	end)
end

local function seridiYaz(etiket: string, yazi: string, alt: string)
	yonergeYazi.Text = `<font color="#{ISARET:ToHex()}">{etiket}</font>   {yazi}`
	altYazi.Text = alt
	serit.Visible = true
	if yazi ~= sonYazi then
		sonYazi = yazi
		genislet(alt ~= "")
	end
end

local parlama = Instance.new("Highlight")
parlama.Name = "OgreticiParlamasi"
parlama.FillColor = BEYAZ
parlama.FillTransparency = 0.72
parlama.OutlineColor = BEYAZ
parlama.OutlineTransparency = 0
parlama.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
parlama.Enabled = false
parlama.Parent = playerGui

local hedefTabela = Instance.new("BillboardGui")
hedefTabela.Name = "OgreticiHedefi"
hedefTabela.Size = UDim2.fromOffset(58, 58)
hedefTabela.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
hedefTabela.AlwaysOnTop = true
hedefTabela.ResetOnSpawn = false
hedefTabela.Enabled = false
hedefTabela.Parent = playerGui

local hedefKabi = Instance.new("Frame")
hedefKabi.Name = "Kap"
hedefKabi.AnchorPoint = Vector2.new(0.5, 0.5)
hedefKabi.Position = UDim2.fromScale(0.5, 0.5)
hedefKabi.Size = UDim2.fromScale(1, 1)
hedefKabi.BackgroundTransparency = 1
hedefKabi.Parent = hedefTabela

local hedefIkonu = Instance.new("ImageLabel")
hedefIkonu.Name = "Locate"
hedefIkonu.Size = UDim2.fromScale(1, 1)
hedefIkonu.BackgroundTransparency = 1
hedefIkonu.ScaleType = Enum.ScaleType.Fit
hedefIkonu.Visible = false
hedefIkonu.Parent = hedefKabi

local hedefNoktasi = Instance.new("Frame")
hedefNoktasi.Name = "Nokta"
hedefNoktasi.AnchorPoint = Vector2.new(0.5, 0.5)
hedefNoktasi.Position = UDim2.fromScale(0.5, 0.5)
hedefNoktasi.Size = UDim2.fromScale(0.52, 0.52)
hedefNoktasi.BackgroundColor3 = ISARET
hedefNoktasi.BorderSizePixel = 0
hedefNoktasi.Parent = hedefKabi
UI.corner(hedefNoktasi, 1000)
UI.stroke(hedefNoktasi, SIYAH, 3)

local noktaOlcek = Instance.new("UIScale")
noktaOlcek.Parent = hedefKabi
TweenService:Create(
	noktaOlcek,
	TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Scale = 1.2 }
):Play()

local function hedefIkonunuKoy()
	if hedefIkonu.Image == "" then
		Icons.apply(hedefIkonu, "ogreticiHedef")
	end
	local var = hedefIkonu.Image ~= ""
	hedefIkonu.Visible = var
	hedefNoktasi.Visible = not var
end

local KIRMIZI = Color3.fromRGB(255, 60, 60)

local kirmiziParlama = Instance.new("Highlight")
kirmiziParlama.Name = "OgreticiKirmiziParlamasi"
kirmiziParlama.FillColor = KIRMIZI
kirmiziParlama.FillTransparency = 0.4
kirmiziParlama.OutlineColor = KIRMIZI
kirmiziParlama.OutlineTransparency = 0
kirmiziParlama.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
kirmiziParlama.Enabled = false
kirmiziParlama.Parent = playerGui

local halkaKabi = Instance.new("Frame")
halkaKabi.Name = "HalkaKabi"
halkaKabi.BackgroundTransparency = 1
halkaKabi.Size = UDim2.fromScale(1, 1)
halkaKabi.Parent = ekran
do
	local sabit = Instance.new("UIScale")
	sabit.Name = "Sabit"
	sabit.Scale = 1
	sabit.Parent = halkaKabi
end

local halka = Instance.new("Frame")
halka.Name = "Halka"
halka.AnchorPoint = Vector2.new(0.5, 0.5)
halka.BackgroundTransparency = 1
halka.Visible = false
halka.Parent = halkaKabi
UI.corner(halka, 1000)
local halkaCizgi = UI.stroke(halka, ISARET, 5)

local function halkaHedefi(adimId: string): GuiObject?
	if adimId ~= "ilkCollect" then
		return nil
	end
	local menuler = playerGui:FindFirstChild("OyunMenuleri")
	local panel = menuler and menuler:FindFirstChild("Detective")
	if not panel or not panel:IsA("GuiObject") or not panel.Visible then
		return nil
	end
	local dugme = panel:FindFirstChild("HepsiniTanimla", true)
	return if dugme and dugme:IsA("GuiObject") and dugme.Visible then dugme else nil
end

local kokTutamak = Instance.new("Attachment")
kokTutamak.Name = "OgreticiBaslangic"
kokTutamak.Parent = Workspace.Terrain

local hedefTutamak = Instance.new("Attachment")
hedefTutamak.Name = "OgreticiBitis"
hedefTutamak.Parent = Workspace.Terrain

local cizgi = Instance.new("Beam")
cizgi.Name = "OgreticiYolu"
cizgi.Attachment0 = kokTutamak
cizgi.Attachment1 = hedefTutamak
cizgi.Color = ColorSequence.new(ISARET)
cizgi.LightInfluence = 0
cizgi.LightEmission = 1
cizgi.FaceCamera = true
cizgi.Width0 = 0.55
cizgi.Width1 = 0.55
cizgi.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.85),
	NumberSequenceKeypoint.new(0.15, 0.15),
	NumberSequenceKeypoint.new(0.85, 0.15),
	NumberSequenceKeypoint.new(1, 0.85),
})
cizgi.CurveSize0 = 0
cizgi.CurveSize1 = 0
cizgi.Enabled = false
cizgi.Parent = kokTutamak

local OK_ARALIK = 4
local OK_BOY = 2.4
local OK_SAYI = 30
local OK_HIZ = 1.4
local OK_BOSLUK_BAS = 3
local OK_BOSLUK_SON = 3
local OK_ALCALMA = 1.8
local OK_TARAMA_UST = 6
local OK_TARAMA_BOY = 40
local OK_YER = OK_BOY / 2 + 0.2

local okIsini = RaycastParams.new()
okIsini.FilterType = Enum.RaycastFilterType.Exclude
okIsini.RespectCanCollide = true
okIsini.IgnoreWater = false

type Ok = { tutamak: Attachment, tabela: BillboardGui, resim: ImageLabel }

local oklar: { Ok } = {}
for i = 1, OK_SAYI do
	local tutamak = Instance.new("Attachment")
	tutamak.Name = `OgreticiOk{i}`
	tutamak.Parent = Workspace.Terrain

	local tabela = Instance.new("BillboardGui")
	tabela.Name = `OgreticiOk{i}`
	tabela.Size = UDim2.fromScale(OK_BOY, OK_BOY)
	tabela.LightInfluence = 0
	tabela.ResetOnSpawn = false
	tabela.Adornee = tutamak
	tabela.Enabled = false
	tabela.Parent = playerGui

	local resim = Instance.new("ImageLabel")
	resim.Name = "Ok"
	resim.Size = UDim2.fromScale(1, 1)
	resim.BackgroundTransparency = 1
	resim.ScaleType = Enum.ScaleType.Fit
	resim.Parent = tabela

	table.insert(oklar, { tutamak = tutamak, tabela = tabela, resim = resim })
end

local yolKoku: BasePart? = nil
local yolHedefi: BasePart? = nil
local okluYol = false
local okFaz = 0

local function oklariGizle()
	for _, ok in oklar do
		ok.tabela.Enabled = false
	end
end

local function yoluKapat()
	yolKoku = nil
	yolHedefi = nil
	cizgi.Enabled = false
	oklariGizle()
end

local function yoluAc(kok: BasePart, isaretKoku: BasePart, haric: Instance?)
	yolKoku = kok
	yolHedefi = isaretKoku
	kokTutamak.WorldPosition = kok.Position
	hedefTutamak.WorldPosition = isaretKoku.Position

	local disarida: { Instance } = {}
	for _, oyuncu in Players:GetPlayers() do
		if oyuncu.Character then
			table.insert(disarida, oyuncu.Character)
		end
	end
	if haric then
		table.insert(disarida, haric)
	end
	okIsini.FilterDescendantsInstances = disarida

	local resim = Icons.of("ogreticiOk")
	okluYol = resim ~= nil
	if resim then
		for _, ok in oklar do
			ok.resim.Image = resim
		end
	else
		oklariGizle()
	end
	cizgi.Enabled = not okluYol
end

RunService.RenderStepped:Connect(function(dt)
	local kok, uc = yolKoku, yolHedefi
	if not kok or not uc then
		return
	end
	if not kok.Parent or not uc.Parent then
		yoluKapat()
		return
	end

	kokTutamak.WorldPosition = kok.Position
	hedefTutamak.WorldPosition = uc.Position

	local kamera = Workspace.CurrentCamera
	if not okluYol or not kamera then
		return
	end

	local bas = kokTutamak.WorldPosition - Vector3.new(0, OK_ALCALMA, 0)
	local fark = hedefTutamak.WorldPosition - bas
	local uzunluk = fark.Magnitude

	okFaz = (okFaz + dt * OK_HIZ) % 1

	if uzunluk < OK_BOSLUK_BAS + OK_BOSLUK_SON + 1 then
		oklariGizle()
		return
	end

	local yon = fark / uzunluk
	local yatay = Vector3.new(yon.X, 0, yon.Z)
	local bakis = if yatay.Magnitude > 0.1 then yatay.Unit else yon
	local sinir = math.min(uzunluk - OK_BOSLUK_SON, OK_BOSLUK_BAS + (OK_SAYI - 1) * OK_ARALIK)

	for i, ok in oklar do
		local mesafe = OK_BOSLUK_BAS + (i - 1 + okFaz) * OK_ARALIK
		if mesafe > sinir then
			ok.tabela.Enabled = false
			continue
		end

		local konum = bas + yon * mesafe
		local carpan = Workspace:Raycast(
			konum + Vector3.new(0, OK_TARAMA_UST, 0),
			Vector3.new(0, -OK_TARAMA_BOY, 0),
			okIsini
		)
		if carpan then
			konum = carpan.Position + Vector3.new(0, OK_YER, 0)
		end
		ok.tutamak.WorldPosition = konum

		local a = kamera:WorldToViewportPoint(konum)
		local b = kamera:WorldToViewportPoint(konum + bakis)
		local dx, dy = b.X - a.X, b.Y - a.Y
		if dx * dx + dy * dy > 1e-4 then
			ok.resim.Rotation = math.deg(math.atan2(dy, dx)) + 90
		end

		local gorunurluk = math.clamp(
			math.min((mesafe - OK_BOSLUK_BAS) / OK_ARALIK, (sinir - mesafe) / OK_ARALIK),
			0,
			1
		)
		ok.resim.ImageTransparency = 1 - gorunurluk
		ok.tabela.Enabled = true
	end
end)

local function sadeAd(ad: string): string
	return (string.gsub(string.lower(ad), "[%s_%-]", ""))
end

local function modelBul(adlar: { string }): Instance?
	for _, ad in adlar do
		local dogrudan = Workspace:FindFirstChild(ad, true)
		if dogrudan then
			return dogrudan
		end
	end

	local hedefler: { string } = {}
	for _, ad in adlar do
		table.insert(hedefler, sadeAd(ad))
	end

	local icerenAday: Instance? = nil

	for _, node in Workspace:GetDescendants() do
		if node:IsA("Model") or node:IsA("BasePart") then
			local ad = sadeAd(node.Name)
			for _, hedef in hedefler do
				if ad == hedef then
					return node
				end
				if not icerenAday and #hedef >= 4 and string.find(ad, hedef, 1, true) then
					icerenAday = node
				end
			end
		end
	end

	return icerenAday
end

local adayOnbellek: { [string]: { zaman: number, liste: { Instance } } } = {}
local ADAY_OMRU = 5

local function adaylariBul(adlar: { string }): { Instance }
	local anahtar = table.concat(adlar, "|")
	local kayit = adayOnbellek[anahtar]
	if kayit and os.clock() - kayit.zaman < ADAY_OMRU then
		local canli: { Instance } = {}
		for _, node in kayit.liste do
			if node.Parent then
				table.insert(canli, node)
			end
		end
		if #canli > 0 then
			return canli
		end
	end

	local hedefler: { string } = {}
	for _, ad in adlar do
		table.insert(hedefler, sadeAd(ad))
	end

	local liste: { Instance } = {}
	for _, node in Workspace:GetDescendants() do
		if node:IsA("Model") or node:IsA("BasePart") then
			local ad = sadeAd(node.Name)
			for _, hedef in hedefler do
				if ad == hedef then
					table.insert(liste, node)
					break
				end
			end
		end
	end

	adayOnbellek[anahtar] = { zaman = os.clock(), liste = liste }
	return liste
end

local function enYakinModel(adlar: { string }): Instance?
	local karakter = player.Character
	local kok = karakter and karakter:FindFirstChild("HumanoidRootPart")
	if not kok or not kok:IsA("BasePart") then
		return modelBul(adlar)
	end

	local enIyi: Instance? = nil
	local enIyiUzaklik = math.huge

	for _, node in adaylariBul(adlar) do
		local ok, konum = pcall(function()
			return if node:IsA("Model") then node:GetPivot().Position else (node :: BasePart).Position
		end)
		if ok and typeof(konum) == "Vector3" then
			local uzaklik = (konum - kok.Position).Magnitude
			if uzaklik < enIyiUzaklik then
				enIyiUzaklik = uzaklik
				enIyi = node
			end
		end
	end

	return enIyi or modelBul(adlar)
end

local kumIsareti = Instance.new("Part")
kumIsareti.Name = "OgreticiKumNoktasi"
kumIsareti.Size = Vector3.new(1, 1, 1)
kumIsareti.Transparency = 1
kumIsareti.Anchored = true
kumIsareti.CanCollide = false
kumIsareti.CanQuery = false
kumIsareti.CanTouch = false
kumIsareti.Parent = Workspace

local function karakterinIcinde(node: Instance): boolean
	local cursor: Instance? = node.Parent
	while cursor and cursor ~= Workspace do
		if cursor:IsA("Model") and cursor:FindFirstChildWhichIsA("Humanoid") then
			return true
		end
		cursor = cursor.Parent
	end
	return false
end

local function kumZeminiMi(node: BasePart): boolean
	if Config.Sand.materials[node.Material] ~= true then
		local ad = string.lower(node.Name)
		local adTutuyor = false
		for _, kelime in Config.Sand.nameKeywords do
			if string.find(ad, kelime, 1, true) then
				adTutuyor = true
				break
			end
		end
		if not adTutuyor then
			return false
		end
	end

	return not karakterinIcinde(node)
end

local kumParcasi: BasePart? = nil

local function kumBul(kok: BasePart): Instance?
	local merkez = kok.Position

	local enYakin: BasePart? = nil
	local enYakinUzaklik = math.huge

	for _, node in Workspace:GetDescendants() do
		if node:IsA("BasePart") and node ~= kumIsareti and kumZeminiMi(node) then
			local uzaklik = (node.Position - merkez).Magnitude
			if uzaklik < enYakinUzaklik then
				enYakin = node
				enYakinUzaklik = uzaklik
			end
		end
	end

	kumParcasi = enYakin
	if not enYakin then
		return nil
	end

	local yerel = enYakin.CFrame:PointToObjectSpace(merkez)
	local yari = enYakin.Size / 2
	kumIsareti.Position = enYakin.CFrame:PointToWorldSpace(Vector3.new(
		math.clamp(yerel.X, -yari.X, yari.X),
		yari.Y,
		math.clamp(yerel.Z, -yari.Z, yari.Z)
	))

	return kumIsareti
end

local sunucuKonumu: Vector3? = nil

local function hedefiBul(tur: Adimlar.Hedef, kok: BasePart): Instance?
	local konum = sunucuKonumu
	if konum and tur == "kum" then
		kumBul(kok)
		kumIsareti.Position = konum
		return kumIsareti
	end

	if tur == "dedektif" then
		return enYakinModel({ Config.Detective.name })
	elseif tur == "fuse" then
		return enYakinModel({ Config.Fuse.machineName, Config.Fuse.machineAltName })
	elseif tur == "base" then
		local model = if baseIndex then modelBul({ Bases.baseName(baseIndex) }) else nil
		if not model then
			return nil
		end

		local adim = Adimlar.adim(siraNo)
		local parcaAdi = if adim and adim.id == "slot"
			then Bases.slotName(1)
			elseif adim and adim.id == "para" then "ToplaButonu"
			else nil

		if parcaAdi then
			local parca = model:FindFirstChild(parcaAdi, true)
			if parca then
				return parca
			end
		end

		return model
	elseif tur == "kum" then
		return kumBul(kok)
	end
	return nil
end

local function baglanacak(node: Instance): (Instance?, BasePart?)
	if node:IsA("BasePart") then
		return node, node
	end
	if node:IsA("Model") then
		local kok = node.PrimaryPart or node:FindFirstChildWhichIsA("BasePart", true)
		return node, kok
	end
	local kok = node:FindFirstChildWhichIsA("BasePart", true)
	return (if kok then node else nil), kok
end

local function isaretleriKapat()
	parlama.Enabled = false
	kirmiziParlama.Enabled = false
	kirmiziParlama.Adornee = nil
	halka.Visible = false
	hedefTabela.Enabled = false
	yoluKapat()
	hedef = nil
end

local function gizle()
	serit.Visible = false
	isaretleriKapat()
end

local IP = Adimlar.AdaIpucu
local KI = Adimlar.KurekIpucu

local function adaIpucuAcik(): boolean
	return player:GetAttribute(IP.nitelik) == true
end

local function kurekIpucuAcik(): boolean
	return player:GetAttribute(KI.nitelik) == true
end

local function ipucuOf(): ({ [string]: any }?, string?)
	if kurekIpucuAcik() then
		return KI :: any, "FIRST SHOVEL"
	elseif adaIpucuAcik() then
		return IP :: any, "NEW ISLAND"
	end
	return nil, nil
end

local function yonergeyiYaz()
	if bitti or siraNo <= 0 then
		local ipucu, baslik = ipucuOf()
		if ipucu then
			seridiYaz(baslik or "", ipucu.yazi, ipucu.alt or "")
		else
			serit.Visible = false
		end
		return
	end

	local adim = Adimlar.adim(siraNo)
	if not adim then
		serit.Visible = false
		return
	end

	seridiYaz(`{siraNo}/{toplamAdim}`, adim.yazi, adim.alt or "")
end

local function hedefiTazele()
	if bitti or siraNo <= 0 then
		isaretleriKapat()

		local ipucu = ipucuOf()
		if not ipucu then
			return
		end

		local karakter = player.Character
		local kok = karakter and karakter:FindFirstChild("HumanoidRootPart")
		if not kok or not kok:IsA("BasePart") then
			return
		end

		local npc = enYakinModel(
			if kurekIpucuAcik() then KI.modeller else { Config.NPC.name, Config.NPC.altName }
		)
		if not npc then
			return
		end

		local adornee, isaretKoku = baglanacak(npc)
		if not adornee or not isaretKoku then
			return
		end

		hedef = npc
		parlama.Adornee = adornee
		parlama.Enabled = true
		hedefIkonunuKoy()
		hedefTabela.Adornee = isaretKoku
		hedefTabela.Enabled = true
		yoluAc(kok, isaretKoku, npc)
		return
	end

	isaretleriKapat()

	local adim = Adimlar.adim(siraNo)
	local karakter = player.Character
	local kok = karakter and karakter:FindFirstChild("HumanoidRootPart")
	if not adim or not kok or not kok:IsA("BasePart") then
		return
	end

	local bulunan = hedefiBul(adim.hedef, kok)
	if not bulunan then
		return
	end

	local adornee, isaretKoku = baglanacak(bulunan)
	if not adornee or not isaretKoku then
		return
	end

	hedef = bulunan

	local imza = `{siraNo}|{adim.hedef}|{bulunan:GetFullName()}`
	if imza ~= sonTeshis then
		sonTeshis = imza
		print(`[Ogretici] step {siraNo} ({adim.hedef}) -> {bulunan:GetFullName()}`)
	end

	if adim.hedef == "kum" and not sunucuKonumu then
		if (kok.Position - kumIsareti.Position).Magnitude <= KUM_YAKINLIK then
			isaretleriKapat()
			return
		end
	end

	local kirmiziMi = adim.id == "slot" or adim.id == "para"

	kirmiziParlama.Adornee = if kirmiziMi then adornee else nil
	kirmiziParlama.Enabled = kirmiziMi

	local sariAdornee: Instance? = if adim.hedef == "kum" then kumParcasi else adornee

	parlama.Adornee = if not kirmiziMi then sariAdornee else nil
	parlama.Enabled = not kirmiziMi and sariAdornee ~= nil

	hedefIkonunuKoy()
	hedefTabela.Adornee = isaretKoku
	hedefTabela.Enabled = true

	local haric = if adim.hedef == "dedektif" or adim.hedef == "fuse" then bulunan else nil
	yoluAc(kok, isaretKoku, haric)
end

OgreticiDurum.OnClientEvent:Connect(function(veri)
	if type(veri) ~= "table" then
		return
	end

	cevapGeldi = true
	sunucuKonumu = if typeof(veri.konum) == "Vector3" then veri.konum else nil
	siraNo = math.floor(tonumber(veri.adim) or 0)
	bitti = veri.bitti == true
	toplamAdim = math.floor(tonumber(veri.toplam) or Adimlar.adimSayisi())

	if bitti then
		gizle()
		yonergeyiYaz()
		hedefiTazele()
		return
	end

	yonergeyiYaz()
	hedefiTazele()
end)

BaseGuncelle.OnClientEvent:Connect(function(veri)
	if type(veri) ~= "table" then
		return
	end
	local index = tonumber(veri.baseIndex)
	if index then
		baseIndex = math.floor(index)
	end
end)

player.CharacterAdded:Connect(isaretleriKapat)

task.spawn(function()
	while true do
		task.wait(1)
		hedefiTazele()
	end
end)

player:GetAttributeChangedSignal(IP.nitelik):Connect(function()
	yonergeyiYaz()
	hedefiTazele()
end)

RunService.RenderStepped:Connect(function()
	if bitti or siraNo <= 0 then
		return
	end

	local adim = Adimlar.adim(siraNo)
	if not adim then
		return
	end

	local nabiz = (math.sin(os.clock() * 5) + 1) * 0.5

	if kirmiziParlama.Enabled then
		kirmiziParlama.FillTransparency = 0.25 + nabiz * 0.45
		kirmiziParlama.OutlineTransparency = nabiz * 0.35
	end

	local dugme = halkaHedefi(adim.id)
	if dugme then
		local boy = math.max(dugme.AbsoluteSize.X, dugme.AbsoluteSize.Y) + 26 + nabiz * 10
		halka.Visible = true
		halka.Size = UDim2.fromOffset(boy, boy)
		halka.Position = UDim2.fromOffset(
			dugme.AbsolutePosition.X + dugme.AbsoluteSize.X / 2,
			dugme.AbsolutePosition.Y + dugme.AbsoluteSize.Y / 2
		)
		halkaCizgi.Transparency = nabiz * 0.45
		halkaCizgi.Thickness = 4 + nabiz * 3
	else
		halka.Visible = false
	end
end)

task.spawn(function()
	for _ = 1, 20 do
		if cevapGeldi then
			return
		end
		OgreticiIste:FireServer()
		task.wait(1.5)
	end
end)
