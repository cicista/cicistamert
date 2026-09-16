--!strict
--[[
	BrainrotOnizleme  (ModuleScript)
	Yeri: StarterPlayer > StarterPlayerScripts > BrainrotOnizleme

	Kucuk bir kareye brainrotun 3B onizlemesini koyar. Kamera ve isik
	Index'tekiyle ayni: model tam karsidan, goz hizasindan, kendi renkleriyle.

	  kimligi acik    -> brainrotun kendi modeli (mutasyonluysa mutasyonlu model)
	  kimligi kapali  -> oyunun "simsiyah brainrot" modeli; kim oldugu ele verilmez

	Model bulunamazsa karenin eski gorunumu kalir.

	IKI TUR PENCERE
	  pencere(liste, panel)   Dikey kaydirma listesi (Envanter, Detective).
	                          Kaydirma konumuna gore tazelenir.
	  seritPencere(cerceve)   Yatay kayan cark seridi (Lucky Block, gunluk
	                          odul). Serit tween'le aktigi icin her karede
	                          tazelenir.

	--------------------------------------------------------------
	NEDEN GORUS PENCERESI + HAVUZ

	Listeler ve cark seritleri sik sik bastan kuruluyor (envanter her
	guncellemede, cark her cevirmede). Onizleme dogrudan kareye konsaydi her
	seferinde butun modeller yeniden klonlanirdi.

	  GORUS PENCERESI  Yalnizca gorunen (ve biraz pay birakilmis) karelere
	                   onizleme kurulur; cikanlar birakilir. ViewportFrame
	                   kirpma disinda da cizildigi icin bu fark ediyor.

	  HAVUZ            Birakilan onizleme silinmez, havuza doner. Ayni
	                   brainrot (ad + mutasyon) tekrar gerektiginde hazir
	                   alinir; model yeniden klonlanmaz. Cark seridinde ayni
	                   brainrot onlarca bolmede tekrarlandigi icin burada
	                   ozellikle ise yariyor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))

local BrainrotOnizleme = {}

------------------------------------------------------------------
-- AYARLAR
------------------------------------------------------------------

-- Dikey listede gorus penceresinin ustune/altina birakilan pay (piksel)
local PAY = 120

-- Havuzda ayni brainrottan en fazla kac onizleme bekler
local HAVUZ_ANAHTAR_TAVAN = 6
-- Havuzda toplam en fazla kac onizleme bekler (bellek tavani)
local HAVUZ_TOPLAM_TAVAN = 80

-- Modeli bulunamayan brainrot bu kadar saniye yeniden aranmaz
local YOK_BEKLEME = 10

--[[
	Kamera ve isik Index ile ayni (bkz. Index > BAKIS_YONU, ISIK):
	modeller yuzu -Z'ye bakacak sekilde hazirlanmis; ViewportFrame sahne
	isigini kullanmadigi icin kendi isigi tavana cekiliyor.
]]
local BAKIS_YONU = Vector3.new(0, 0, -1)
local ISIK = Color3.fromRGB(255, 255, 255)
local ISIK_YONU = Vector3.new(-0.4, -0.7, -0.6)
-- Kutunun kosegeninin bu kati kadar geri cekilir; 1'in alti kadraji doldurur
local CERCEVE = 0.9

------------------------------------------------------------------

export type Kaynak = {
	name: string?,
	mutation: string?,
	revealed: boolean,
}

local havuz: { [string]: { ViewportFrame } } = {}
local havuzToplam = 0

-- anahtar -> son basarisiz arama zamani
local yokZamani: { [string]: number } = {}

local function anahtarOf(k: Kaynak): string
	if k.revealed and k.name then
		return `{k.name}|{k.mutation or "Normal"}`
	end
	-- Kimligi kapali olanlarin hepsi ayni siyah model: tek anahtar
	return "__gizli"
end

--[[
	KADRAJ: YALNIZCA GORUNEN PARCALAR

	Model:GetBoundingBox() gorunmez parcalari da (tutamak, carpisma kutusu,
	efekt tasiyicisi) sayiyor ve kutuyu PrimaryPart'in eksenine hizaliyor.
	Kimligi acilmamis brainrot modelinde bu yuzden kamera bos bir noktaya
	bakiyordu; kup karenin sol altinda kucucuk kaliyordu. Artik kutu
	yalnizca gorunen parcalardan, dunya eksenlerinde hesaplaniyor.
]]
local function gorunenSinir(model: Model): (Vector3?, Vector3?)
	local enAz: Vector3? = nil
	local enCok: Vector3? = nil

	for _, parca in model:GetDescendants() do
		if not parca:IsA("BasePart") or parca.Transparency >= 0.99 then
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

local function kur(k: Kaynak): ViewportFrame?
	-- Iki fonksiyon da zaten Clone() donduruyor; bir daha klonlanmiyor
	local model = if k.revealed and k.name
		then Assets.brainrotModel(k.name, k.mutation)
		else Assets.hiddenBrainrotModel()

	if not model then
		return nil
	end

	-- Onizlemede script/ses/parcacik calismasin: sahne sessiz ve sabit olsun
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
		--[[
			Olumsuz sonuc KALICI saklanmiyor: istemci acilirken modeller
			henuz replike edilmemis olabilir (Assets de ayni sebeple
			saklamiyor). Kisa bir sure sonra yeniden deneniyor.
		]]
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

------------------------------------------------------------------
-- KAYITLAR  (iki pencere turunun ortak isi)
------------------------------------------------------------------
export type Pencere = {
	-- Bir karenin kaydi; yedek, onizleme varken gizlenecek eski gorunum ("?")
	ekle: (yuva: GuiObject, kaynak: Kaynak, yedek: GuiObject?) -> (),
	-- Kareler silinmeden ONCE cagrilir: onizlemeler havuza doner
	temizle: () -> (),
	-- Gorunen kareleri yeniden hesaplar
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

-- Kareye onizlemeyi takar (zaten takiliysa bir sey yapmaz)
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

-- Karenin onizlemesini havuza birakir
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

--[[
	Nesne gercekten ekranda mi: kendisi ve butun GuiObject atalari Visible,
	ScreenGui'si Enabled. Kapali bir panelin ic karesi "Visible" gorunur ama
	cizilmez; onlara onizleme takmak bosuna bellek.
]]
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

------------------------------------------------------------------
-- DIKEY LISTE PENCERESI  (Envanter, Detective)
------------------------------------------------------------------
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

	--[[
		Satirlar ayni karede toplu ekleniyor; her ekleme icin ayri hesap
		yerine tek bir ertelenmis tazeleme. Ertelemenin ikinci faydasi:
		yeni satirlarin AbsolutePosition'i ancak yerlesimden sonra dogru.
	]]
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
			-- UI.panel acilista buyume animasyonu oynatiyor; bitince yerlesim kesinlesir
			task.delay(0.3, tazele)
		else
			-- Kapali panelin sahneleri bellekte durmasin
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

------------------------------------------------------------------
-- YATAY SERIT PENCERESI  (Lucky Block, gunluk odul carki)
--
-- Cark seridi tween'le kaydigi icin kaydirma sinyali yok; kareler her
-- RenderStepped'te cercevenin yatay sinirlarina gore degerlendiriliyor.
-- Cercevenin iki yanina BIR BOLME GENISLIGI pay birakiliyor: kenardan
-- girecek bolmenin resmi o goruldugunde hazir olsun.
--
-- Dongu yalnizca kayitli kare varken bagli; temizle() ile kopar.
------------------------------------------------------------------
function BrainrotOnizleme.seritPencere(cerceve: GuiObject): Pencere
	local kayitlar: { Kayit } = {}
	local baglanti: RBXScriptConnection? = nil

	local function hepsiniBirak()
		for _, kayit in kayitlar do
			serbest(kayit)
		end
	end

	local function tazele()
		-- Panel kapaliysa sahneler bellekte durmasin
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
