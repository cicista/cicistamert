--!strict

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ARKA_PLAN_KLASORU = { "Assets", "Backgrounds" }
local ARKA_PLAN_ADI = "LoadingScreen"

local RESIM_ODAK = Vector2.new(0.5, 0.5)

local RESIM_YAKLASMA = 1.04

local OYUN_ADI = "CICISTAMERT"

local EN_COK_BEKLEME = 45

local EN_AZ_GORUNME = 5

local AFK_DONUS_ANAHTARI = "AfkDonus"

local afkDonusu = false
do
	local ok, veri = pcall(function()
		return game:GetService("TeleportService"):GetLocalPlayerTeleportData()
	end)
	afkDonusu = ok and type(veri) == "table" and veri[AFK_DONUS_ANAHTARI] ~= nil
end

if afkDonusu then
	EN_AZ_GORUNME = 0.5
end

local NEON = Color3.fromRGB(70, 190, 255)
local NEON_KOYU = Color3.fromRGB(20, 90, 160)
local BEYAZ = Color3.fromRGB(255, 255, 255)
local SOLGUN = Color3.fromRGB(170, 185, 200)

local CUBUK_EN = 520
local CUBUK_BOY = 34

local TOZ_SAYISI = 22

pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local KAPATILAN_COREGUI = {
	Enum.CoreGuiType.Chat,
	Enum.CoreGuiType.PlayerList,
	Enum.CoreGuiType.Backpack,
	Enum.CoreGuiType.EmotesMenu,
}

local StarterGui = game:GetService("StarterGui")

local function coreGuiAyarla(acik: boolean)
	for _, tur in KAPATILAN_COREGUI do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(tur, acik)
		end)
	end
end

local coreGuiSuruyor = true

task.spawn(function()
	while coreGuiSuruyor do
		coreGuiAyarla(false)
		pcall(function()
			StarterGui:SetCore("TopbarEnabled", false)
		end)
		task.wait(0.25)
	end
end)

local function coreGuiGeriAc()
	coreGuiSuruyor = false

	for _, tur in KAPATILAN_COREGUI do
		if tur ~= Enum.CoreGuiType.Backpack then
			pcall(function()
				StarterGui:SetCoreGuiEnabled(tur, true)
			end)
		end
	end

	pcall(function()
		StarterGui:SetCore("TopbarEnabled", true)
	end)
end

local function kose(nesne: Instance, yaricap: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, yaricap)
	c.Parent = nesne
end

local function kontur(nesne: Instance, renk: Color3, kalinlik: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = renk
	s.Thickness = kalinlik
	s.Parent = nesne
	return s
end

local function yazi(ayar: { [string]: any }): TextLabel
	local etiket = Instance.new("TextLabel")
	etiket.Name = ayar.name or "Yazi"
	etiket.BackgroundTransparency = 1
	etiket.Size = ayar.size or UDim2.fromScale(1, 1)
	etiket.Position = ayar.position or UDim2.new()
	etiket.AnchorPoint = ayar.anchor or Vector2.zero
	etiket.Font = ayar.font or Enum.Font.GothamBold
	etiket.Text = ayar.text or ""
	etiket.TextColor3 = ayar.color or BEYAZ
	etiket.TextSize = ayar.textSize or 18
	etiket.TextXAlignment = ayar.align or Enum.TextXAlignment.Center
	etiket.ZIndex = ayar.zIndex or 5
	etiket.Parent = ayar.parent
	return etiket
end

local ekran = Instance.new("ScreenGui")
ekran.Name = "YuklemeEkrani"
ekran.DisplayOrder = 1000
ekran.IgnoreGuiInset = true
pcall(function()
	(ekran :: any).ScreenInsets = Enum.ScreenInsets.None
end)
ekran.ResetOnSpawn = false
ekran.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ekran:SetAttribute("OlcekDisi", true)
ekran.Parent = playerGui

local perde = Instance.new("Frame")
perde.Name = "Perde"
perde.ChildAdded:Connect(function(cocuk)
	if cocuk:IsA("UIScale") then
		task.defer(function()
			cocuk:Destroy()
		end)
	end
end)
perde.Size = UDim2.fromScale(1, 1)
perde.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
perde.BorderSizePixel = 0
perde.ZIndex = 1
perde.Parent = ekran

local gokyuzu = Instance.new("Frame")
gokyuzu.Name = "Gokyuzu"
gokyuzu.Size = UDim2.fromScale(1, 1)
gokyuzu.BackgroundColor3 = BEYAZ
gokyuzu.BorderSizePixel = 0
gokyuzu.ZIndex = 1
gokyuzu.Parent = perde

local gokGecis = Instance.new("UIGradient")
gokGecis.Rotation = 90
gokGecis.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(96, 74, 120)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(48, 44, 78)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 14, 26)),
})
gokGecis.Parent = gokyuzu

local resimKabi = Instance.new("Frame")
resimKabi.Name = "ResimKabi"
resimKabi.AnchorPoint = Vector2.new(0.5, 0.5)
resimKabi.Position = UDim2.fromScale(0.5, 0.5)
resimKabi.Size = UDim2.new(1, 12, 1, 12)
resimKabi.BackgroundTransparency = 1
resimKabi.ClipsDescendants = true
resimKabi.ZIndex = 2
resimKabi.Parent = perde

local resimYaklasma = Instance.new("Frame")
resimYaklasma.Name = "Yaklasma"
resimYaklasma.AnchorPoint = RESIM_ODAK
resimYaklasma.Position = UDim2.fromScale(RESIM_ODAK.X, RESIM_ODAK.Y)
resimYaklasma.Size = UDim2.fromScale(1, 1)
resimYaklasma.BackgroundTransparency = 1
resimYaklasma.ZIndex = 2
resimYaklasma.Parent = resimKabi

local BULANIK_KAYMA = {
	Vector2.new(0, 0),
}
local resimKatmanlari: { ImageLabel } = {}

for sira, kayma in BULANIK_KAYMA do
	local katman = Instance.new("ImageLabel")
	katman.Name = `Resim{sira}`
	katman.AnchorPoint = Vector2.new(0.5, 0.5)
	katman.Position = UDim2.new(0.5, math.floor(kayma.X), 0.5, math.floor(kayma.Y))
	katman.Size = UDim2.fromScale(1, 1)
	katman.BackgroundTransparency = 1
	katman.ScaleType = Enum.ScaleType.Crop
	katman.ImageTransparency = if sira == 1 then 0 else 0.55
	katman.ZIndex = 2
	katman.Visible = false
	katman.Parent = resimYaklasma
	table.insert(resimKatmanlari, katman)
end

task.spawn(function()
	local node: Instance? = ReplicatedStorage
	for _, ad in ARKA_PLAN_KLASORU do
		node = if node then node:WaitForChild(ad, 10) else nil
	end

	local hedef = if node then node:WaitForChild(ARKA_PLAN_ADI, 10) else nil
	if not hedef then
		return
	end

	local kimlik: string? = nil
	if hedef:IsA("Decal") or hedef:IsA("Texture") then
		kimlik = hedef.Texture
	elseif hedef:IsA("ImageLabel") or hedef:IsA("ImageButton") then
		kimlik = hedef.Image
	elseif hedef:IsA("StringValue") then
		kimlik = hedef.Value
	end

	if not kimlik or kimlik == "" then
		return
	end

	for _, katman in resimKatmanlari do
		katman.Image = kimlik
		katman.Visible = true
	end

	TweenService
		:Create(
			resimYaklasma,
			TweenInfo.new(18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Size = UDim2.fromScale(RESIM_YAKLASMA, RESIM_YAKLASMA) }
		)
		:Play()
end)

local karartma = Instance.new("Frame")
karartma.Name = "Karartma"
karartma.Size = UDim2.fromScale(1, 1)
karartma.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
karartma.BackgroundTransparency = 0.35
karartma.BorderSizePixel = 0
karartma.ZIndex = 3
karartma.Parent = perde

local vinyet = Instance.new("UIGradient")
vinyet.Rotation = 90
vinyet.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.55),
	NumberSequenceKeypoint.new(0.4, 1),
	NumberSequenceKeypoint.new(0.62, 1),
	NumberSequenceKeypoint.new(1, 0),
})
vinyet.Parent = karartma

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Size = UDim2.fromOffset(CUBUK_EN + 80, 262)
panel.BackgroundColor3 = Color3.fromRGB(14, 17, 26)
panel.BackgroundTransparency = 0.25
panel.BorderSizePixel = 0
panel.ZIndex = 4
panel.Parent = perde

perde.Position = UDim2.fromScale(0, 0)
perde.Size = UDim2.fromScale(1, 1)

panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -24)

local PANEL_OLCEK = 0.72
local panelOlcek = Instance.new("UIScale")
panelOlcek.Name = "PanelOlcek"
panelOlcek.Scale = PANEL_OLCEK
panelOlcek.Parent = panel
kose(panel, 18)
kontur(panel, Color3.fromRGB(45, 60, 82), 2)

local baslik = yazi({
	text = "LOADING...",
	textSize = 46,
	color = BEYAZ,
	size = UDim2.new(1, 0, 0, 56),
	position = UDim2.fromOffset(0, 26),
	parent = panel,
	zIndex = 6,
	name = "Baslik",
})

local baslikKontur = kontur(baslik, NEON, 3)

local baslikOlcek = Instance.new("UIScale")
baslikOlcek.Parent = baslik

TweenService
	:Create(
		baslikOlcek,
		TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Scale = 1.04 }
	)
	:Play()

TweenService
	:Create(
		baslikKontur,
		TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.55 }
	)
	:Play()

local cubuk = Instance.new("Frame")
cubuk.Name = "Cubuk"
cubuk.AnchorPoint = Vector2.new(0.5, 0)
cubuk.Position = UDim2.new(0.5, 0, 0, 104)
cubuk.Size = UDim2.fromOffset(CUBUK_EN, CUBUK_BOY)
cubuk.BackgroundColor3 = Color3.fromRGB(28, 33, 44)
cubuk.BorderSizePixel = 0
cubuk.ClipsDescendants = true
cubuk.ZIndex = 5
cubuk.Parent = panel
kose(cubuk, CUBUK_BOY // 2)
kontur(cubuk, Color3.fromRGB(52, 66, 88), 2)

local dolgu = Instance.new("Frame")
dolgu.Name = "Dolgu"
dolgu.Size = UDim2.fromScale(0, 1)
dolgu.BackgroundColor3 = BEYAZ
dolgu.BorderSizePixel = 0
dolgu.ZIndex = 6
dolgu.Parent = cubuk
kose(dolgu, CUBUK_BOY // 2)

local dolguGecis = Instance.new("UIGradient")
dolguGecis.Color = ColorSequence.new(NEON_KOYU, NEON)
dolguGecis.Parent = dolgu

local parlama = Instance.new("Frame")
parlama.Name = "Parlama"
parlama.AnchorPoint = Vector2.new(1, 0)
parlama.Position = UDim2.fromScale(1, 0)
parlama.Size = UDim2.new(0, 90, 1, 0)
parlama.BackgroundColor3 = BEYAZ
parlama.BorderSizePixel = 0
parlama.ZIndex = 7
parlama.Parent = dolgu

local parlamaGecis = Instance.new("UIGradient")
parlamaGecis.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.6, 0.72),
	NumberSequenceKeypoint.new(1, 0.45),
})
parlamaGecis.Parent = parlama

local yuzdeYazi = yazi({
	text = "0% Completed",
	textSize = 18,
	color = BEYAZ,
	size = UDim2.fromScale(1, 1),
	parent = cubuk,
	zIndex = 9,
	name = "Yuzde",
})
kontur(yuzdeYazi, Color3.fromRGB(0, 0, 0), 2)

local durumYazi = yazi({
	text = "Loading world assets... Please wait",
	textSize = 16,
	color = SOLGUN,
	font = Enum.Font.Gotham,
	size = UDim2.new(1, 0, 0, 22),
	position = UDim2.fromOffset(0, 146),
	parent = panel,
	zIndex = 6,
	name = "Durum",
})

local baslaDugme = Instance.new("TextButton")
baslaDugme.Name = "Basla"
baslaDugme.AnchorPoint = Vector2.new(0.5, 0)
baslaDugme.Position = UDim2.new(0.5, 0, 0, 182)
baslaDugme.Size = UDim2.fromOffset(240, 52)
baslaDugme.BackgroundColor3 = NEON
baslaDugme.BorderSizePixel = 0
baslaDugme.AutoButtonColor = false
baslaDugme.Text = ""
baslaDugme.Visible = false
baslaDugme.ZIndex = 8
baslaDugme.Parent = panel
kose(baslaDugme, 12)
kontur(baslaDugme, Color3.fromRGB(0, 0, 0), 3)

local baslaGecis = Instance.new("UIGradient")
baslaGecis.Rotation = 90
baslaGecis.Color = ColorSequence.new(Color3.fromRGB(140, 220, 255), NEON)
baslaGecis.Parent = baslaDugme

local baslaYazi = yazi({
	text = "PLAY",
	textSize = 26,
	color = Color3.fromRGB(10, 22, 34),
	size = UDim2.fromScale(1, 1),
	parent = baslaDugme,
	zIndex = 9,
	name = "Yazi",
})

local baslaOlcek = Instance.new("UIScale")
baslaOlcek.Parent = baslaDugme

baslaDugme.MouseEnter:Connect(function()
	TweenService:Create(baslaOlcek, TweenInfo.new(0.12), { Scale = 1.06 }):Play()
end)
baslaDugme.MouseLeave:Connect(function()
	TweenService:Create(baslaOlcek, TweenInfo.new(0.12), { Scale = 1 }):Play()
end)

local tozKabi = Instance.new("Frame")
tozKabi.Name = "Toz"
tozKabi.AnchorPoint = Vector2.new(0.5, 0.5)
tozKabi.Position = UDim2.new(0.5, 0, 0, 120)
tozKabi.Size = UDim2.fromOffset(CUBUK_EN + 60, 150)
tozKabi.BackgroundTransparency = 1
tozKabi.ZIndex = 4
tozKabi.Parent = panel

local rastgele = Random.new()

for i = 1, TOZ_SAYISI do
	local tane = Instance.new("Frame")
	tane.Name = "Tane"
	tane.AnchorPoint = Vector2.new(0.5, 0.5)
	tane.BackgroundColor3 = NEON
	tane.BorderSizePixel = 0
	tane.ZIndex = 4

	local boy = rastgele:NextInteger(2, 5)
	tane.Size = UDim2.fromOffset(boy, boy)
	kose(tane, boy)
	tane.Parent = tozKabi

	task.spawn(function()
		task.wait(rastgele:NextNumber(0, 3))

		while tane.Parent do
			local x = rastgele:NextNumber(0.02, 0.98)
			local sure = rastgele:NextNumber(2.5, 5)

			tane.Position = UDim2.fromScale(x, 1.05)
			tane.BackgroundTransparency = rastgele:NextNumber(0.25, 0.6)

			local ucus = TweenService:Create(
				tane,
				TweenInfo.new(sure, Enum.EasingStyle.Linear),
				{ Position = UDim2.fromScale(x + rastgele:NextNumber(-0.05, 0.05), -0.05) }
			)
			TweenService
				:Create(tane, TweenInfo.new(sure, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
				:Play()

			ucus:Play()
			ucus.Completed:Wait()
		end
	end)
end

local disli = Instance.new("Frame")
disli.Name = "Disli"
disli.AnchorPoint = Vector2.new(0, 1)
disli.Position = UDim2.new(0, 36, 1, -36)
disli.Size = UDim2.fromOffset(44, 44)
disli.BackgroundTransparency = 1
disli.ZIndex = 5
disli.Parent = perde

for i = 1, 8 do
	local dis = Instance.new("Frame")
	dis.AnchorPoint = Vector2.new(0.5, 0.5)
	dis.Position = UDim2.fromScale(0.5, 0.5)
	dis.Size = UDim2.fromOffset(6, 44)
	dis.Rotation = (i - 1) * (180 / 8)
	dis.BackgroundColor3 = NEON
	dis.BackgroundTransparency = 0.25
	dis.BorderSizePixel = 0
	dis.ZIndex = 5
	dis.Parent = disli
	kose(dis, 3)
end

local dislGobek = Instance.new("Frame")
dislGobek.AnchorPoint = Vector2.new(0.5, 0.5)
dislGobek.Position = UDim2.fromScale(0.5, 0.5)
dislGobek.Size = UDim2.fromOffset(22, 22)
dislGobek.BackgroundColor3 = Color3.fromRGB(10, 13, 20)
dislGobek.BorderSizePixel = 0
dislGobek.ZIndex = 6
dislGobek.Parent = disli
kose(dislGobek, 11)

yazi({
	text = "SETTING UP",
	textSize = 13,
	color = SOLGUN,
	font = Enum.Font.Gotham,
	align = Enum.TextXAlignment.Left,
	size = UDim2.fromOffset(200, 20),
	anchor = Vector2.new(0, 1),
	position = UDim2.new(0, 92, 1, -48),
	parent = perde,
	zIndex = 5,
	name = "DisliYazi",
})

yazi({
	text = OYUN_ADI,
	textSize = 15,
	color = SOLGUN,
	align = Enum.TextXAlignment.Right,
	size = UDim2.fromOffset(300, 20),
	anchor = Vector2.new(1, 1),
	position = UDim2.new(1, -36, 1, -36),
	parent = perde,
	zIndex = 5,
	name = "OyunAdi",
})

local hedefYuzde = 0
local gorunenYuzde = 0

local basladi = os.clock()

local function gecenSure(): number
	return os.clock() - basladi
end

local function ilerle(deger: number, metin: string?)
	hedefYuzde = math.clamp(math.max(deger, hedefYuzde), 0, 1)
	if metin then
		durumYazi.Text = metin
	end
end

local cizimBagi: RBXScriptConnection? = nil

cizimBagi = RunService.RenderStepped:Connect(function(dt: number)
	local zamanSiniri = math.clamp(gecenSure() / EN_AZ_GORUNME, 0, 1)
	local hedef = math.min(hedefYuzde, zamanSiniri)

	gorunenYuzde += (hedef - gorunenYuzde) * math.min(1, dt * 5)

	dolgu.Size = UDim2.fromScale(gorunenYuzde, 1)
	yuzdeYazi.Text = `{math.floor(gorunenYuzde * 100)}% Completed`

	parlama.Visible = gorunenYuzde > 0.02
end)

local function varliklariYukle()
	ilerle(0.05, "Reaching the server...")

	local kok = ReplicatedStorage:WaitForChild("Assets", 15)
	if not kok then
		ilerle(0.6, "Loading world...")
		return
	end

	ilerle(0.12, "Loading world assets...")

	local liste: { Instance } = {}
	for _, node in kok:GetDescendants() do
		if
			node:IsA("MeshPart")
			or node:IsA("SpecialMesh")
			or node:IsA("Decal")
			or node:IsA("Texture")
			or node:IsA("ImageLabel")
			or node:IsA("Sound")
			or node:IsA("Animation")
		then
			table.insert(liste, node)
		end
	end

	if #liste == 0 then
		ilerle(0.6, "Loading world...")
		return
	end

	local OBEK = 12
	local islenen = 0

	for bas = 1, #liste, OBEK do
		local obek: { Instance } = {}
		for i = bas, math.min(bas + OBEK - 1, #liste) do
			table.insert(obek, liste[i])
		end

		pcall(function()
			ContentProvider:PreloadAsync(obek)
		end)

		islenen += #obek
		ilerle(0.12 + (islenen / #liste) * 0.63, `Loading world assets...  {islenen} / {#liste}`)
	end
end

local kapandi = false

local function kapat()
	if kapandi then
		return
	end
	kapandi = true

	coreGuiGeriAc()

	local solma = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local sonTween: Tween? = nil

	local function soldur(nesne: Instance, hedef: { [string]: any })
		local tween = TweenService:Create(nesne, solma, hedef)
		tween:Play()
		sonTween = tween
	end

	local nesneler = perde:GetDescendants()
	table.insert(nesneler, perde)

	for _, nesne in nesneler do
		if nesne:IsA("UIStroke") then
			soldur(nesne, { Transparency = 1 })
		elseif nesne:IsA("TextLabel") or nesne:IsA("TextButton") or nesne:IsA("TextBox") then
			soldur(nesne, { BackgroundTransparency = 1, TextTransparency = 1, TextStrokeTransparency = 1 })
		elseif nesne:IsA("ImageLabel") or nesne:IsA("ImageButton") or nesne:IsA("ViewportFrame") then
			soldur(nesne, { BackgroundTransparency = 1, ImageTransparency = 1 })
		elseif nesne:IsA("GuiObject") then
			soldur(nesne, { BackgroundTransparency = 1 })
		end
	end

	if sonTween then
		sonTween.Completed:Wait()
	end

	if cizimBagi then
		cizimBagi:Disconnect()
		cizimBagi = nil
	end

	ekran:Destroy()
end

local hazirlandi = false

local function hazirOl()
	if hazirlandi or kapandi then
		return
	end
	hazirlandi = true

	ilerle(1, "Everything is ready")

	local kalan = EN_AZ_GORUNME - gecenSure()
	if kalan > 0 then
		task.wait(kalan)
	end
	task.wait(0.35)

	if kapandi then
		return
	end

	if afkDonusu then
		kapat()
		return
	end

	durumYazi.Text = "Click PLAY to start"
	baslaDugme.Visible = true

	baslaOlcek.Scale = 0.6
	TweenService
		:Create(
			baslaOlcek,
			TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		)
		:Play()
end

baslaDugme.Activated:Connect(kapat)

task.delay(EN_COK_BEKLEME, hazirOl)

task.spawn(function()
	local ok, hata = pcall(varliklariYukle)
	if not ok then
		warn(`[YuklemeEkrani] Assets failed to preload: {tostring(hata)}`)
	end

	ilerle(0.8, "Waiting for the world...")

	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	ilerle(0.88, "Loading your progress...")
	player:WaitForChild("leaderstats", 15)

	ilerle(0.94, "Almost there...")

	if not player.Character then
		player.CharacterAdded:Wait()
	end

	hazirOl()
end)
