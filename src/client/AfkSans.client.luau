--[[
	AfkSans  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > AfkSans

	AFK sans sisteminin istemci tarafi (bkz. Shared > AfkSans,
	ServerScriptService > Modules > AfkSans):

	  YONCALAR     sunucunun yolladigi konumlara Assets > Clovers modelleri
	               dizilir (yalnizca bu oyuncu gorur). Model yoksa yedek
	               yonca cizilir.
	  TOPLAMA      karakter bir yoncanin yanina gelince ustunde 3'ten geri
	               sayan, titreyen bir bar cikar (kademe renginde). Bar
	               bitince sunucu puani verir ve yerine yeni yonca dogar.
	  OTOMATIK     alandayken sol tik (ya da ekrana dokunma / AUTO dugmesi)
	               karakteri en yakin yoncaya yurutur, toplar, siradakine
	               gecer. Oyuncu kendisi yururse, tekrar tiklarsa ya da
	               alandan cikarsa durur.
	  BARIKATLAR   acilmis alanin barikati bu istemcide gecilebilir ve
	               gorunmez olur; kilitli alanin ustunde "LOCKED" yazar.
	  LEPRECHAUN   alan yukseltme paneli.
]]

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
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))

local YoncaListesi = Net.event("YoncaListesi")
local YoncaTopla = Net.event("YoncaTopla")
local YoncaSonuc = Net.event("YoncaSonuc")
local LeprechaunAc = Net.event("LeprechaunAc")
local AfkAlanAl = Net.event("AfkAlanAl")

local SIYAH = Color3.new(0, 0, 0)
local BEYAZ = Color3.new(1, 1, 1)
local YONCA_YESIL = Color3.fromRGB(70, 200, 90)

-- Karakteri yoncaya yururken MoveTo'nun yenilenme araligi
local YURUME_YENILE = 0.5
-- Sunucunun reddettigi yonca bu kadar saniye hedef alinmaz
local RED_BEKLEME = 2
-- Bar bittikten sonra sunucu cevabi bu kadar gecikirse toplama birakilir
local CEVAP_BEKLEME = 3

------------------------------------------------------------------
-- YARDIMCILAR
------------------------------------------------------------------
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

local function puan(): number
	return tonumber(player:GetAttribute(Ayar.PuanNiteligi)) or 0
end

-- Oyuncunun kendi yurume girdisi (klavye, gamepad, mobil cubuk)
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

------------------------------------------------------------------
-- BARIKATLAR
------------------------------------------------------------------
-- Parcanin ilk hali (acilan barikat kilitlenirse geri donsun diye)
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

	local renk = Rarity.textColor(alan.id)
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

local function barikatlariGuncelle()
	local acik = seviye()
	for i, alan in Ayar.Alanlar do
		local z = zemin(alan.id)
		if not z then
			continue
		end

		local parcalar = barikatParcalari(z)
		local enBuyuk: BasePart? = nil
		for _, parca in parcalar do
			if not ilkHal[parca] then
				ilkHal[parca] = { cc = parca.CanCollide, tr = parca.Transparency }
			end
			local ilk = ilkHal[parca]
			if i <= acik then
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

		if enBuyuk and i > acik then
			kilitYazisi(alan, enBuyuk)
		elseif kilitYazilari[alan.id] then
			kilitYazilari[alan.id]:Destroy()
			kilitYazilari[alan.id] = nil
		end
	end
end

-- Akis (streaming) barikati sonradan getirebilir: duzenli yenilenir
task.spawn(function()
	while true do
		barikatlariGuncelle()
		task.wait(1)
	end
end)
player:GetAttributeChangedSignal(Ayar.SeviyeNiteligi):Connect(barikatlariGuncelle)

------------------------------------------------------------------
-- YONCA MODELLERI
------------------------------------------------------------------
local yoncaKlasoru = Instance.new("Folder")
yoncaKlasoru.Name = "AfkYoncalari"
yoncaKlasoru.Parent = Workspace

type YoncaGorsel = {
	id: number,
	pos: Vector3,
	yaricap: number,
	model: Model,
	-- Barin tutundugu gorunmez nokta (yoncanin tepesi)
	nokta: BasePart,
	-- Tam boydaki pivot ile yoncanin tabani arasindaki yukseklik
	altFark: number,
	aci: number,
	donus: CFrame,
	olcek: number,
}

local yoncalar: { [number]: YoncaGorsel } = {}
local aktifAlan: string? = nil
local reddedilen: { [number]: number } = {}

-- Model bulunamazsa: dort yaprakli basit yonca (yaricap ~1 stud)
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

--[[
	Rig modelini sahneye hazirlar: carpismaz, tiklanmaz, dusmez.
	Motor6D ile bagli (animasyonlu) parcalar SABITLENMEZ, yoksa animasyon
	oynamaz; onlar kok parcaya bagli oldugu icin yine yerinde durur.
]]
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

-- k: tam boyun kaci (0..1); taban zeminde kalacak sekilde yerlestirir
local function boyutla(g: YoncaGorsel, k: number, yukari: number?)
	local hedef = g.model:GetAttribute("TabanOlcek") :: number
	g.model:ScaleTo(math.max(hedef * g.olcek * k, 0.01))
	local y = g.altFark * k + (yukari or 0)
	g.model:PivotTo(CFrame.new(g.pos + Vector3.new(0, y, 0)) * CFrame.Angles(0, g.aci, 0) * g.donus)
end

local function yoncaKur(alanId: string, v: any)
	if yoncalar[v.id] then
		return
	end

	local renk = Rarity.color(alanId)
	local model = Assets.cloverModel(alanId) or yedekYonca(renk)
	model.Name = `Yonca_{v.id}`
	hazirla(model)

	local taban = model:GetScale()
	model:SetAttribute("TabanOlcek", taban)
	model:ScaleTo(taban * v.olcek)

	-- Tam boyda pivot ile en alt nokta arasindaki fark
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
		pos = v.pos,
		yaricap = v.yaricap,
		model = model,
		nokta = nokta,
		altFark = altFark,
		aci = v.aci,
		donus = pivot - pivot.Position,
		olcek = v.olcek,
	}
	yoncalar[v.id] = g

	boyutla(g, 0.05)
	model.Parent = yoncaKlasoru
	Assets.playAnimations(model)

	-- Dogus: kucukten buyuyerek ziplar
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
		text = if miktar > 0 then `+{virgullu(miktar)} Luck Points` else "MAX Luck Points",
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

	-- Toplanma: yukari suzulup kuculerek kaybolur
	local deger = Instance.new("NumberValue")
	deger.Value = 1
	deger.Changed:Connect(function(k)
		boyutla(g, k, (1 - k) * 2.5)
	end)
	local tw = TweenService:Create(deger, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = 0.05 })
	tw.Completed:Once(function()
		deger:Destroy()
		g.model:Destroy()
	end)
	tw:Play()
end

------------------------------------------------------------------
-- TOPLAMA BARI (titreyen, kademe renginde, 3'ten geri sayar)
------------------------------------------------------------------
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
	kutu.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	kutu.BorderSizePixel = 0
	kutu.Parent = gui
	UI.corner(kutu, 12)
	UI.stroke(kutu, SIYAH, 3)

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

	-- Titreme: sure azaldikca siddetlenir
	local siddet = 1 + (1 - oran) * 3
	bar.kutu.Position = UDim2.new(0.5, math.random(-100, 100) / 100 * siddet, 0.5, math.random(-100, 100) / 100 * siddet)
	bar.kutu.Rotation = math.random(-100, 100) / 100 * siddet * 1.5
end

------------------------------------------------------------------
-- HUD
------------------------------------------------------------------
local screen = Instance.new("ScreenGui")
screen.Name = "AfkSans"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local hud = Instance.new("Frame")
hud.Name = "SansHUD"
hud.AnchorPoint = Vector2.new(0.5, 1)
hud.Position = UDim2.new(0.5, 0, 1, -140)
hud.Size = UDim2.fromOffset(340, 96)
hud.BackgroundColor3 = UI.Colors.panel
hud.BackgroundTransparency = 0.1
hud.BorderSizePixel = 0
hud.Visible = false
hud.Parent = screen
UI.corner(hud, 12)
local hudKontur = UI.stroke(hud, SIYAH, 3)

local hudBaslik = UI.text({
	text = "LUCK POINTS",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = YONCA_YESIL,
	frameSize = UDim2.new(1, -24, 0, 20),
	position = UDim2.fromOffset(12, 6),
	parent = hud,
})

local hudHiz = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = UI.Colors.good,
	align = Enum.TextXAlignment.Right,
	frameSize = UDim2.new(1, -24, 0, 20),
	position = UDim2.fromOffset(12, 6),
	parent = hud,
})

local hudPuan = UI.text({
	text = "0",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	color = BEYAZ,
	frameSize = UDim2.new(1, -24, 0, 28),
	position = UDim2.fromOffset(12, 26),
	parent = hud,
})

local hudCubuk = Instance.new("Frame")
hudCubuk.Position = UDim2.fromOffset(12, 58)
hudCubuk.Size = UDim2.new(1, -140, 0, 12)
hudCubuk.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
hudCubuk.BorderSizePixel = 0
hudCubuk.Parent = hud
UI.corner(hudCubuk, 6)
UI.stroke(hudCubuk, SIYAH, 2)

local hudDolgu = Instance.new("Frame")
hudDolgu.Size = UDim2.fromScale(0, 1)
hudDolgu.BackgroundColor3 = YONCA_YESIL
hudDolgu.BorderSizePixel = 0
hudDolgu.Parent = hudCubuk
UI.corner(hudDolgu, 6)
UI.cubukCilasi(hudDolgu)

local hudIpucu = UI.text({
	text = "",
	size = UI.Sizes.tiny,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -140, 0, 18),
	position = UDim2.fromOffset(12, 74),
	parent = hud,
})

local otoDugme, _, otoYazi = UI.dugme3B(hud, "AUTO", UDim2.fromOffset(112, 44), UI.Colors.good)
otoDugme.AnchorPoint = Vector2.new(1, 1)
otoDugme.Position = UDim2.new(1, -10, 1, -8)

local function hudGuncelle()
	local p = puan()
	hudPuan.Text = `{virgullu(p)} / {Format.short(Ayar.MaxPuan)}`
	hudDolgu.Size = UDim2.fromScale(math.clamp(p / Ayar.MaxPuan, 0, 1), 1)
end
player:GetAttributeChangedSignal(Ayar.PuanNiteligi):Connect(hudGuncelle)
hudGuncelle()

------------------------------------------------------------------
-- TOPLAMA + OTOMATIK YURUME
------------------------------------------------------------------
local oto = false
local hedefId: number? = nil
local sonYurume = 0

type Toplanan = { id: number, basla: number, bar: Bar }
local toplanan: Toplanan? = nil

local function otoCiz()
	if otoYazi then
		otoYazi.Text = if oto then "STOP" else "AUTO"
	end
	UI.dugme3BRenk(otoDugme, if oto then UI.Colors.bad else UI.Colors.good)
	hudIpucu.Text = if oto then "Auto-collecting... move or click to stop" else "Click to auto-collect clovers"
end

local function dur()
	local h = insan()
	local root = kok()
	if h and root and hedefId then
		h:MoveTo(root.Position)
	end
	hedefId = nil
end

local function otoAyarla(acik: boolean)
	if acik and not aktifAlan then
		return
	end
	if oto == acik then
		return
	end
	oto = acik
	if not acik then
		dur()
	end
	otoCiz()
end

local function toplamaBirak(sunucuyaSoyle: boolean)
	local t = toplanan
	if not t then
		return
	end
	toplanan = nil
	t.bar.gui:Destroy()
	if sunucuyaSoyle then
		YoncaTopla:FireServer(nil)
	end
end

local function yataydaUzaklik(a: Vector3, b: Vector3): number
	return ((a - b) * Vector3.new(1, 0, 1)).Magnitude
end

local function enYakin(root: BasePart): YoncaGorsel?
	local simdi = os.clock()
	local secilen, enKisa = nil, math.huge
	for id, g in yoncalar do
		if (reddedilen[id] or 0) > simdi then
			continue
		end
		local d = yataydaUzaklik(g.pos, root.Position)
		if d < enKisa then
			secilen, enKisa = g, d
		end
	end
	return secilen
end

RunService.Heartbeat:Connect(function()
	local root = kok()
	local h = insan()
	if not root or not h or h.Health <= 0 or not aktifAlan then
		if toplanan then
			toplamaBirak(true)
		end
		return
	end

	-- Oyuncu kendisi yururse otomatik mod kapanir
	if oto and oyuncuYuruyor() then
		otoAyarla(false)
	end

	local simdi = os.clock()
	local t = toplanan
	if t then
		local g = yoncalar[t.id]
		if not g then
			toplamaBirak(false)
		elseif yataydaUzaklik(g.pos, root.Position) > g.yaricap + Ayar.Erisim + 1 then
			-- Yoncadan uzaklasti
			toplamaBirak(true)
		elseif simdi - t.basla > Ayar.ToplamaSuresi + CEVAP_BEKLEME then
			-- Sunucu cevap vermedi; baska yoncaya gec
			reddedilen[t.id] = simdi + RED_BEKLEME
			toplamaBirak(true)
		else
			barCiz(t.bar, simdi - t.basla)
			return
		end
	end

	-- Yaninda duran yonca varsa toplamaya basla
	local yakin = enYakin(root)
	if yakin and yataydaUzaklik(yakin.pos, root.Position) <= yakin.yaricap + Ayar.Erisim then
		if oto then
			dur()
		end
		toplanan = {
			id = yakin.id,
			basla = simdi,
			bar = barKur(yakin, Rarity.color(aktifAlan)),
		}
		YoncaTopla:FireServer(yakin.id)
		return
	end

	-- Otomatik: en yakin yoncaya yuru
	if oto and yakin then
		if hedefId ~= yakin.id or simdi - sonYurume >= YURUME_YENILE then
			hedefId = yakin.id
			sonYurume = simdi
			h:MoveTo(yakin.pos)
		end
	end
end)

-- Sol tik / ekrana dokunma: alandayken otomatik modu ac-kapa
UserInputService.InputBegan:Connect(function(input, islendi)
	if islendi or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	if aktifAlan then
		otoAyarla(not oto)
	end
end)

UserInputService.TouchTapInWorld:Connect(function(_, islendi)
	if not islendi and aktifAlan then
		otoAyarla(not oto)
	end
end)

otoDugme.MouseButton1Click:Connect(function()
	otoAyarla(not oto)
end)

------------------------------------------------------------------
-- SUNUCU OLAYLARI
------------------------------------------------------------------
local function hepsiniSil()
	toplamaBirak(false)
	for id in yoncalar do
		yoncaSil(id, false)
	end
	table.clear(reddedilen)
end

YoncaListesi.OnClientEvent:Connect(function(alanId, liste)
	hepsiniSil()
	aktifAlan = if type(alanId) == "string" then alanId else nil

	if not aktifAlan then
		otoAyarla(false)
		hud.Visible = false
		return
	end

	local alan = Ayar.get(aktifAlan)
	local renk = Rarity.textColor(aktifAlan)
	hudBaslik.Text = "LUCK POINTS"
	hudBaslik.TextColor3 = renk
	hudKontur.Color = SIYAH
	hudDolgu.BackgroundColor3 = Rarity.color(aktifAlan)
	hudHiz.Text = if alan then `+{alan.puanSaniye}/s  {alan.displayName}` else ""
	hudGuncelle()
	otoCiz()
	hud.Visible = true

	if type(liste) == "table" then
		for _, v in liste do
			yoncaKur(aktifAlan, v)
		end
	end
end)

YoncaSonuc.OnClientEvent:Connect(function(id, ok, kazanc, yeni)
	if type(id) ~= "number" then
		return
	end

	local t = toplanan
	if t and t.id == id then
		toplamaBirak(false)
	end

	if not ok then
		reddedilen[id] = os.clock() + RED_BEKLEME
		return
	end

	local g = yoncalar[id]
	if g and aktifAlan then
		yazdirKazanc(g.pos, tonumber(kazanc) or 0, Rarity.textColor(aktifAlan))
	end
	yoncaSil(id, true)

	if hedefId == id then
		hedefId = nil
	end
	if type(yeni) == "table" and aktifAlan then
		yoncaKur(aktifAlan, yeni)
	end
end)

player.CharacterAdded:Connect(function()
	otoAyarla(false)
end)

------------------------------------------------------------------
-- LEPRECHAUN PANELI
------------------------------------------------------------------
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
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	color = BEYAZ,
	frameSize = UDim2.new(1, -24, 0, 24),
	position = UDim2.fromOffset(12, 8),
	parent = ozet,
})

local ozetCubuk = Instance.new("Frame")
ozetCubuk.Position = UDim2.fromOffset(12, 40)
ozetCubuk.Size = UDim2.new(1, -24, 0, 16)
ozetCubuk.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
ozetCubuk.BorderSizePixel = 0
ozetCubuk.Parent = ozet
UI.corner(ozetCubuk, 8)
UI.stroke(ozetCubuk, SIYAH, 2)

local ozetDolgu = Instance.new("Frame")
ozetDolgu.Size = UDim2.fromScale(0, 1)
ozetDolgu.BackgroundColor3 = YONCA_YESIL
ozetDolgu.BorderSizePixel = 0
ozetDolgu.Parent = ozetCubuk
UI.corner(ozetDolgu, 8)
UI.cubukCilasi(ozetDolgu)

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
	ozetPuan.Text = `Luck Points: {virgullu(p)} / {virgullu(Ayar.MaxPuan)}`
	ozetDolgu.Size = UDim2.fromScale(math.clamp(p / Ayar.MaxPuan, 0, 1), 1)

	for i, alan in veri.alanlar do
		local renk = Rarity.color(alan.id)
		local yaziRengi = Rarity.textColor(alan.id)

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -6, 0, 76)
		row.BackgroundColor3 = UI.Colors.panelLight
		row.BorderSizePixel = 0
		row.LayoutOrder = i
		row.Parent = panelListe
		UI.corner(row, 10)
		UI.stroke(row, if alan.buyable then renk else SIYAH, if alan.buyable then 3 else 2)
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
			text = `+{alan.puanSaniye} Luck Points / second`,
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
