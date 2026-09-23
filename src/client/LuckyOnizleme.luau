--!strict
--[[
	LuckyOnizleme  (ModuleScript)
	Yeri: StarterPlayer > StarterPlayerScripts > LuckyOnizleme

	Arayuzde bir Lucky Block gosterilecegi her yerde, "?" kutusu ikonu
	yerine BLOGUN KENDI MODELINI donduren kucuk bir 3B pencere kurar
	(Rewards kartlari, Rot Coin magazasi, Store...). Boylece oyuncu
	alacagi blogu birebir goruyor: Hacker blogu Hacker gibi duruyor.

	Modeller ReplicatedStorage > Assets > LuckyBlocks icinden, turun
	modelName'ine gore secilir (bkz. Shared > LuckyBlock).

	CALISMA
	  ekle(kutu, tierId)  ->  kutunun icine ViewportFrame kurar, modeli
	  listeye yazar ve true doner. Model yoksa false doner; cagiran taraf
	  eski ikonuna duser (arayuz asla bos kalmaz).

	Butun onizlemeler TEK RenderStepped'te donuyor. Gizli olanlar (paneli
	kapali) atlaniyor, kart yeniden cizilince kayit listeden kendiliginden
	dusuyor.

	NOT: ViewportFrame parcacik, isin ve isik CIZMEZ (Roblox siniri).
	Blogun etrafindaki parlamayi cagiran taraf UI.parlama ile veriyor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))

local UI = require(script.Parent:WaitForChild("UI"))

local LuckyOnizleme = {}

-- Kamera blogu ucte-dortluk acidan goruyor: duz karsidan duran kutu yassi duruyordu
local BAKIS = Vector3.new(0, 0, -1)
local DURUS = CFrame.Angles(0, math.rad(28), 0) * CFrame.Angles(math.rad(-16), 0, 0)
local ISIK = Color3.fromRGB(255, 255, 255)

--[[
	KADRAJ

	Mesafe goz kararina degil, modelin CEVREL KURESINE gore hesaplaniyor:

	    mesafe = (yaricap * pay) / tan(FOV / 2)

	Kure kullanilmasinin sebebi blogun donuyor olmasi -- hangi aciya
	gelirse gelsin kareye sigiyor. Dar FOV (35 derece) perspektif
	bozulmasini kesiyor: kutunun yakin kosesi devasa gorunmuyor.
]]
local FOV = 35
local PAY = 1.15

type Kayit = { model: Model, kutu: ViewportFrame, merkez: Vector3, taban: CFrame }

local kayitlar: { Kayit } = {}

-- Hangi turun modelini Output'a yazdik (tur basina bir kez)
local raporlanan: { [string]: boolean } = {}

-- Kadraj yalnizca GORUNUR parcalardan: gorunmez tutamaklar blogu kucultmesin
local function gorunenKutu(model: Model): (Vector3?, Vector3?)
	local enAz: Vector3? = nil
	local enCok: Vector3? = nil

	for _, parca in model:GetDescendants() do
		if not parca:IsA("BasePart") or parca.Transparency >= 0.99 then
			continue
		end
		for _, sx in { -0.5, 0.5 } do
			for _, sy in { -0.5, 0.5 } do
				for _, sz in { -0.5, 0.5 } do
					local kose = parca.CFrame:PointToWorldSpace(parca.Size * Vector3.new(sx, sy, sz))
					enAz = if enAz then enAz:Min(kose) else kose
					enCok = if enCok then enCok:Max(kose) else kose
				end
			end
		end
	end

	if not enAz or not enCok then
		return nil, nil
	end
	return (enAz + enCok) / 2, enCok - enAz
end

-- Panel kapaliyken donmesin: ekranda gorunmeyen onizleme bos yere islenmesin
local function gorunuyorMu(nesne: Instance): boolean
	local node: Instance? = nesne
	while node do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		if node:IsA("LayerCollector") then
			return node.Enabled
		end
		node = node.Parent
	end
	return false
end

--[[
	Kutunun icine turun donen 3B onizlemesini kurar.
	tier: LuckyBlock turu (tablo) ya da tur kimligi (metin).
	Model bulunamazsa false doner.
]]
function LuckyOnizleme.ekle(kutu: GuiObject, tier: any, zIndex: number?): boolean
	local tur = if type(tier) == "string" then LuckyBlock.get(tier) else tier
	if not tur then
		return false
	end

	local model = Assets.luckyBlockModel(tur.modelName or tur.displayName, tur.order)
	if not model then
		warn(`[LuckyOnizleme] Model bulunamadi: ReplicatedStorage > Assets > LuckyBlocks ({tur.id})`)
		return false
	end

	--[[
		HANGI TURE HANGI MODEL DUSTU  --  her tur icin bir kez Output'a.
		Yanlis blok gorunuyorsa once buraya bakilir; klasordeki modellerin
		tam listesi de Assets.listLuckyBlocks ile yaziliyor.
	]]
	if not raporlanan[tur.id] then
		raporlanan[tur.id] = true
		Assets.listLuckyBlocks()
		print(`[LuckyOnizleme] {tur.id} -> {model.Name}`)
	end

	-- Onizlemede script ve ses calismasin (efektler zaten cizilmiyor)
	for _, nesne in model:GetDescendants() do
		if nesne:IsA("BaseScript") or nesne:IsA("Sound") then
			nesne:Destroy()
		end
	end

	local merkez, boyut = gorunenKutu(model)
	if not merkez or not boyut then
		model:Destroy()
		return false
	end

	local vp = Instance.new("ViewportFrame")
	vp.Name = "Onizleme"
	vp.AnchorPoint = Vector2.new(0.5, 0.5)
	vp.Position = UDim2.fromScale(0.5, 0.5)
	vp.Size = UDim2.fromScale(1, 1)
	vp.BackgroundTransparency = 1
	vp.Ambient = ISIK
	vp.LightColor = ISIK
	vp.LightDirection = Vector3.new(-0.4, -0.7, -0.6)
	vp.ZIndex = zIndex or 4
	vp.Parent = kutu

	model.Parent = vp

	local kamera = Instance.new("Camera")
	kamera.FieldOfView = FOV
	kamera.Parent = vp
	vp.CurrentCamera = kamera

	local mesafe = (boyut.Magnitude / 2 * PAY) / math.tan(math.rad(FOV / 2))
	kamera.CFrame = CFrame.lookAt(merkez + BAKIS * mesafe, merkez)

	table.insert(kayitlar, { model = model, kutu = vp, merkez = merkez, taban = model:GetPivot() })
	return true
end

--[[
	HAZIR BIR IKONUN YERINE BLOGUN KENDISI

	Arayuzde blok gosteren yerlerin cogu once Icons paketinden gelen "?"
	kutusu ikonunu koyuyordu: paketteki o resim hangi blok oldugunu hic
	soylemiyor (Hacker da Elmas da ayni tahta kutu). Bu fonksiyon o
	ImageLabel'in resmini silip icine blogun DONEN MODELINI kuruyor.

	Ikon kutusu yerinde kaldigi icin yerlesim degismiyor; model
	bulunamazsa eski resim geri veriliyor ve false donuyor.
]]
function LuckyOnizleme.ikonaKoy(ikon: ImageLabel | ImageButton, tier: any): boolean
	-- Onceki onizleme (baska bir blok acilmis olabilir)
	local eski = ikon:FindFirstChild("Onizleme")
	if eski then
		eski:Destroy()
	end

	local resim = ikon.Image
	ikon.Image = ""

	if LuckyOnizleme.ekle(ikon, tier, ikon.ZIndex) then
		ikon.Visible = true
		--[[
			Icons.bind paketi gec bulursa resmi SONRADAN basiyor ve modelin
			arkasinda "?" kutusu beliriyordu. Bu nitelik degisince o dongu
			"artik ben bagli degilim" deyip cekiliyor (bkz. Shared > Icons).
		]]
		ikon:SetAttribute("IkonKimligi", "blokModeli")
		return true
	end

	-- Model yok: paket ikonuna geri don
	ikon.Image = resim
	return false
end

RunService.RenderStepped:Connect(function()
	if #kayitlar == 0 then
		return
	end

	-- UI.sallan ile ayni ritim: butun onizlemeler ayni anda salinsin
	local aci = math.rad(UI.SallanmaAci) * math.sin(os.clock() * math.pi / UI.SallanmaSuresi)

	for i = #kayitlar, 1, -1 do
		local kayit = kayitlar[i]

		if not kayit.kutu.Parent then
			-- Kart yeniden cizildi: kayit listeden duser
			kayitlar[i] = kayitlar[#kayitlar]
			kayitlar[#kayitlar] = nil
			continue
		end

		if not gorunuyorMu(kayit.kutu) then
			continue
		end

		local donus = CFrame.new(kayit.merkez) * CFrame.Angles(0, aci, 0) * DURUS * CFrame.new(-kayit.merkez)
		kayit.model:PivotTo(donus * kayit.taban)
	end
end)

return LuckyOnizleme
