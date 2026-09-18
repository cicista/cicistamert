--!strict
--[[
	ParaSacma  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > ParaSacma

	Base'in TOPLA butonundan rot toplandiginda para desteleri etrafa sacilir,
	yerde bir an durur, sonra toplayan oyuncuya ucup kaybolur.

	ROT COIN: oyuncu NE SEKILDE OLURSA OLSUN Rot Coin kazandiginda (odul,
	gorev, Robux paketi, admin...) ayni animasyon altin paralarla oyuncunun
	ETRAFINDA oynar. Tetik istemcide: EnvanterGuncelle'deki rotCoins bir
	oncekinden buyukse fark kadar para sacilir. Boylece kazanc yolu ne olursa
	olsun sunucuda ayrica bir sey yazmak gerekmiyor. Yalnizca kazanan oyuncu
	kendi paralarini gorur.

	AKIS  (her deste icin)
	  gecikme : desteler ayni karede degil, pes pese firlar -- patlama hissi
	  sac     : gercek yercekimiyle ucar, yere carpip 1-2 kez seker
	  bekle   : yerde hafifce nefes alarak yatar
	  cek     : kavis cizip hizlanarak oyuncuya gider, kuculup kivilcimla kaybolur
	  sol     : oyuncu yoksa (oldu/cikti) yerinde solar

	--------------------------------------------------------------
	NEDEN BOYLE  --  "smooth ve canli" icin yapilanlar

	Ilk surumde dort sey sert duruyordu; hepsi burada ayri ayri cozuldu:

	  1. YERE DEGINCE ACI ANIDEN SIFIRLANIYORDU. Deste donerek dusup
	     degdigi karede dumduz oluyordu. Artik yere yaklasirken ve
	     degdikten sonra duz yatisa YUMUSAKCA donuyor (duzlestir).

	  2. SEKME YOKTU. Hazir bir parabolde suzulup duruyordu. Artik hiz +
	     yercekimi ile ucuyor; carpinca dikey hizin bir kismini koruyup
	     seker, surtunmeyle yavaslar.

	  3. CARPMA HISSI YOKTU. Carpinca deste ezilip (basik ve genis) bir yay
	     gibi esneyerek eski haline donuyor. Ayni yay dogarken "pop"
	     buyumesiyle de oynuyor.

	  4. OYUNCUYA DUZ CIZGIDE GIDIYORDU. Artik ikinci derece Bezier egrisiyle
	     once yukari kalkip kavis cizerek, basta yavas sonra hizlanarak
	     gidiyor. Arkasinda kisa bir isik izi (Trail) birakiyor.

	GORUNUM: tek kalip blok yerine uc katmanli banknot destesi (koyu alt,
	orta, acik ust; katmanlar hafif kaymis ve donuk) + ortadan gecen bant.
	Butonda firlama aninda ve oyuncuya ulasinca kivilcim cikiyor.

	--------------------------------------------------------------
	NEDEN ISTEMCIDE

	BaseGorsel ile ayni sebep: sunucuda yapilan hareket saniyede yaklasik
	20 kez replike edilir ve takilarak gorunur. Sunucu yalnizca "su oyuncu,
	su noktadan, su kadar topladi" der (Net > ParaSac); desteler her
	istemcide YEREL kurulur, aga yuk binmez.

	NEDEN HAZIR IKON PAKETI KULLANILMIYOR
	Simulator Icon Pack > Cash altindakiler 4x1x4 duz parca + tek Decal:
	resim yalnizca bir yuzde, donen destede yandan ince gri levha goruluyor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local ParaSac = Net.event("ParaSac")
-- Rot Coin bakiyesi buradan izleniyor (bkz. ust aciklama)
local EnvanterGuncelle = Net.event("EnvanterGuncelle")

------------------------------------------------------------------
-- AYARLAR
------------------------------------------------------------------

-- Kameranin bu kadar uzagindaki toplamalar hic cizilmez
local GORUNME_MESAFESI = 160

--[[
	DESTE SAYISI

	Toplanan miktarla artar ama logaritmik: 10 rot ile 1 milyon rot
	arasinda fark gorulsun, milyonda ekran desteye bogulmasin.
]]
local ADET_EN_AZ = 8
local ADET_EN_COK = 20

-- Ayni anda havada olabilecek en fazla deste (ust uste toplamalarda tavan)
local AKTIF_TAVAN = 120

-- Pes pese firlama araligi (saniye)
local GECIKME_ADIM = 0.02

-- Sacilma: butonun merkezinden ne kadar uzaga dusecekleri (stud)
local YARICAP_MIN = 2.5
local YARICAP_MAX = 7.5

-- Ilk dususe kadar havada kalma suresi ve kavisin tepe yuksekligi (stud)
local UCUS_SURE_MIN = 0.42
local UCUS_SURE_MAX = 0.58
local TEPE_MIN = 3
local TEPE_MAX = 5.5

--[[
	SEKME

	KATSAYI  : carpinca dikey hizin ne kadari geri doner (0 = sekmez)
	SURTUNME : her carpmada yatay hizin ne kadari kalir
	EN_AZ_HIZ: geri donen dikey hiz bunun altindaysa sekme biter, yatar
	EN_COK   : en fazla kac kez seker
]]
local SEKME_KATSAYI = 0.38
local SEKME_SURTUNME = 0.5
local SEKME_EN_AZ_HIZ = 2.6
local SEKME_EN_COK = 2

--[[
	EZILME YAYI

	Carpma ve dogma aninda destenin basilip esneyerek toparlanmasi.
	SERTLIK buyudukce hizli toparlanir; SONUM kucuk kaldikca bir iki kez
	titreyerek oturur (tamamen sonumlu yay cansiz duruyordu).
]]
local EZILME_SERTLIK = 220
local EZILME_SONUM = 16

-- Dogma "pop"u: bu surede kucukten buyuyerek normal boyuna gelir
local POP_SURE = 0.16

-- Yerde bekleme (her deste bu aralikta rastgele)
local BEKLEME_MIN = 0.25
local BEKLEME_MAX = 0.55

--[[
	OYUNCUYA CEKILME

	Sure mesafeyle olceklenir (mesafe / HIZ_OLCEK), ama MIN-MAX arasinda:
	cok yakindaki deste bir karede kaybolmasin, uzaktaki de oyalanmasin.
	KAVIS: egrinin ne kadar yukaridan gecegi.
]]
local CEKME_SURE_MIN = 0.3
local CEKME_SURE_MAX = 0.6
local CEKME_HIZ_OLCEK = 30
local CEKME_KAVIS_MIN = 2.5
local CEKME_KAVIS_MAX = 5

-- Takilan deste (ornegin oyuncu isinlandi) en gec bu surede silinir
local EN_UZUN_OMUR = 5

-- Renkler
local KOYU = Color3.fromRGB(38, 132, 56)
local ORTA = Color3.fromRGB(76, 196, 92)
local ACIK = Color3.fromRGB(128, 230, 126)
local BANT = Color3.fromRGB(252, 240, 196)

-- Destenin kapladigi yukseklik (zemine yatis hesabi bunu kullanir)
local DESTE_YUKSEKLIK = 0.54

--[[
	KATMANLAR  (destenin kendi uzayinda)

	Uc banknot katmani ust uste, her biri bir oncekinden hafif kucuk ve
	biraz kaymis/donuk: tek kalip blok gibi degil, gelisiguzel istiflenmis
	para gibi duruyor. Bant hepsini ortadan sariyor.
]]
type KatmanTanim = {
	ad: string,
	boy: Vector3,
	konum: Vector3,
	aci: number,
	renk: Color3,
	-- Silindir parca (Rot Coin); ekseni don ile dikeye cevrilir
	silindir: boolean?,
	-- Isik izi bu katmana takilir
	iz: boolean?,
}

local KATMAN_TANIM: { KatmanTanim } = {
	{ ad = "Alt", boy = Vector3.new(1.6, 0.18, 0.9), konum = Vector3.new(0, -0.18, 0), aci = 0, renk = KOYU },
	{ ad = "Orta", boy = Vector3.new(1.56, 0.18, 0.88), konum = Vector3.new(0.03, 0, 0.01), aci = 3, renk = ORTA, iz = true },
	{ ad = "Ust", boy = Vector3.new(1.52, 0.18, 0.86), konum = Vector3.new(-0.04, 0.18, 0.02), aci = -6, renk = ACIK },
	{ ad = "Bant", boy = Vector3.new(0.32, 0.58, 0.94), konum = Vector3.new(0, 0, 0), aci = 0, renk = BANT },
}

--[[
	ROT COIN  --  yere yatmis altin para

	Silindirin ekseni X; boy.X kalinlik, Y ve Z cap. Katmanlar ayni merkezde:
	koyu altin kenar, parlak yuz, ortada acik kabartma. Hepsi yatirilarak
	(eksen dikeye) kuruluyor, bkz. desteKur.
]]
local COIN_KENAR = Color3.fromRGB(205, 130, 15)
local COIN_YUZ = Color3.fromRGB(255, 205, 45)
local COIN_ORTA = Color3.fromRGB(255, 240, 150)

local COIN_TANIM: { KatmanTanim } = {
	{ ad = "Kenar", boy = Vector3.new(0.22, 1.3, 1.3), konum = Vector3.zero, aci = 0, renk = COIN_KENAR, silindir = true },
	{ ad = "Yuz", boy = Vector3.new(0.27, 1.0, 1.0), konum = Vector3.zero, aci = 0, renk = COIN_YUZ, silindir = true, iz = true },
	{ ad = "Kabartma", boy = Vector3.new(0.31, 0.46, 0.46), konum = Vector3.zero, aci = 0, renk = COIN_ORTA, silindir = true },
}

--[[
	TURLER

	para : base toplama (yesil deste), sunucu tetikler (ParaSac)
	coin : Rot Coin kazanci (altin para), istemci tetikler

	yukseklik: zemine yatarken kapladigi dikey boy
	adetMin/Max, adetCarpan: miktara gore kac tane sacilacagi (log10)
]]
type Tur = {
	katmanlar: { KatmanTanim },
	yukseklik: number,
	izRenk: Color3,
	adetMin: number,
	adetMax: number,
	adetCarpan: number,
}

local TURLER: { [string]: Tur } = {
	para = { katmanlar = KATMAN_TANIM, yukseklik = DESTE_YUKSEKLIK, izRenk = ACIK, adetMin = ADET_EN_AZ, adetMax = ADET_EN_COK, adetCarpan = 3 },
	coin = { katmanlar = COIN_TANIM, yukseklik = 0.32, izRenk = COIN_YUZ, adetMin = 6, adetMax = 16, adetCarpan = 4 },
}

------------------------------------------------------------------

local rng = Random.new()

-- Yerel desteler burada toplanir; istemcide kuruldugu icin kimseye replike olmaz
local klasor = Instance.new("Folder")
klasor.Name = "ParaSacma"
klasor.Parent = Workspace

type Katman = { parca: Part, boy: Vector3, konum: Vector3, don: CFrame }

type Deste = {
	-- "para" ya da "coin" (kivilcim rengi)
	tur: string,
	katmanlar: { Katman },
	iz: Trail,
	oyuncu: Player,
	evre: string,
	t: number,
	omur: number,
	gecikme: number,
	konum: Vector3,
	hiz: Vector3,
	yercekimi: number,
	zeminY: number,
	sekme: number,
	yerde: boolean,
	rot: CFrame,
	donus: Vector3,
	faz: number,
	bekleme: number,
	pop: number,
	ezilme: number,
	ezilmeHiz: number,
	kucul: number,
	sonOlcek: Vector3,
	cekBas: Vector3,
	cekKontrol: Vector3,
	cekSure: number,
}

local aktif: { Deste } = {}

local function parca(ad: string, boy: Vector3, renk: Color3, silindir: boolean?): Part
	local p = Instance.new("Part")
	p.Name = ad
	if silindir then
		p.Shape = Enum.PartType.Cylinder
		-- Hafif parlaklik: altin para metal gibi isik alsin
		p.Reflectance = 0.12
	end
	p.Size = boy
	p.Color = renk
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	-- Tamamen gorsel: carpmaz, isin almaz, dokunmaz, golge dusurmez
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	return p
end

------------------------------------------------------------------
-- KIVILCIM
--
-- Tek bir yayici butun kivilcimlari veriyor: once istenen noktaya
-- tasiniyor, sonra Emit. Parcaciklar dunyada kaldigi (LockedToPart
-- kapali) icin yayicinin sonradan baska yere gitmesi onlari tasimiyor.
-- Doku Roblox'un yerlesik kivilcimi; disaridan asset gerekmiyor.
------------------------------------------------------------------
local kivilcimParca = parca("Kivilcim", Vector3.new(0.2, 0.2, 0.2), Color3.new(1, 1, 1))
kivilcimParca.Transparency = 1
kivilcimParca.Parent = klasor

local kivilcim = Instance.new("ParticleEmitter")
kivilcim.Texture = "rbxasset://textures/particles/sparkles_main.dds"
kivilcim.Enabled = false
kivilcim.Rate = 0
kivilcim.LockedToPart = false
kivilcim.Lifetime = NumberRange.new(0.35, 0.6)
kivilcim.Speed = NumberRange.new(6, 14)
kivilcim.SpreadAngle = Vector2.new(180, 180)
kivilcim.Drag = 3
kivilcim.Acceleration = Vector3.new(0, -18, 0)
kivilcim.LightEmission = 1
kivilcim.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.55),
	NumberSequenceKeypoint.new(1, 0),
})
kivilcim.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(1, 1),
})
kivilcim.Color = ColorSequence.new(Color3.fromRGB(190, 255, 150), Color3.fromRGB(255, 240, 140))
kivilcim.Parent = kivilcimParca

-- Rot Coin icin ayni kivilcimin altin renklisi
local altinKivilcim = kivilcim:Clone()
altinKivilcim.Color = ColorSequence.new(Color3.fromRGB(255, 250, 190), Color3.fromRGB(255, 190, 40))
altinKivilcim.Parent = kivilcimParca

local function kivilcimAt(nokta: Vector3, adet: number, altin: boolean?)
	kivilcimParca.CFrame = CFrame.new(nokta)
	if altin then
		altinKivilcim:Emit(adet)
	else
		kivilcim:Emit(adet)
	end
end

------------------------------------------------------------------
-- DESTE KURULUMU
------------------------------------------------------------------
local function desteKur(baslangic: Vector3, tur: Tur): ({ Katman }, Trail)
	local katmanlar: { Katman } = {}
	local ortaParca: Part? = nil

	for _, tanim in tur.katmanlar do
		local p = parca(tanim.ad, tanim.boy, tanim.renk, tanim.silindir)
		-- Firlama anina kadar gorunmez ve olacagi yerde bekler
		p.Transparency = 1
		p.CFrame = CFrame.new(baslangic)
		p.Parent = klasor

		-- Silindirin ekseni (X) dikeye cevrilir: para yere yatar
		local don = CFrame.Angles(0, math.rad(tanim.aci), 0)
		if tanim.silindir then
			don *= CFrame.Angles(0, 0, math.pi / 2)
		end

		table.insert(katmanlar, {
			parca = p,
			boy = tanim.boy,
			konum = tanim.konum,
			don = don,
		})

		if tanim.iz then
			ortaParca = p
		end
	end

	--[[
		ISIK IZI

		Yalnizca oyuncuya ucarken acik. Iz iki eklenti noktasi arasindan
		cekiliyor; kameraya dondugu icin her acidan serit gibi gorunuyor.
	]]
	local tasiyici = ortaParca :: Part
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.22, 0)
	a0.Parent = tasiyici
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.22, 0)
	a1.Parent = tasiyici

	local iz = Instance.new("Trail")
	iz.Attachment0 = a0
	iz.Attachment1 = a1
	iz.Lifetime = 0.18
	iz.MinLength = 0.02
	iz.FaceCamera = true
	iz.LightEmission = 0.6
	iz.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), tur.izRenk)
	iz.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	iz.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	iz.Enabled = false
	iz.Parent = tasiyici

	return katmanlar, iz
end

local function saydamlik(d: Deste, deger: number)
	for _, k in d.katmanlar do
		k.parca.Transparency = deger
	end
end

local function sil(d: Deste)
	-- Iz ve eklentiler orta katmanin cocugu, onunla birlikte gidiyor
	for _, k in d.katmanlar do
		k.parca:Destroy()
	end
end

-- Asiri tasarak yerlesme: once hedefi hafif gecer, sonra geri oturur
local function popOlcegi(x: number): number
	local c1 = 1.70158
	local c3 = c1 + 1
	local y = 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
	return 0.35 + 0.65 * y
end

--[[
	DUZ YATISA YUMUSAKCA DON

	Destenin yalnizca kendi dikey ekseni etrafindaki acisi (yaw) korunuyor,
	egimi sifira ceviriliyor. Ustel yaklasim kare hizindan bagimsiz: 30 ve
	144 FPS'te ayni surede yatiyor.
]]
local function duzlestir(d: Deste, sertlik: number, dt: number)
	local _, yaw, _ = d.rot:ToEulerAnglesYXZ()
	d.rot = d.rot:Lerp(CFrame.Angles(0, yaw, 0), 1 - math.exp(-sertlik * dt))
end

------------------------------------------------------------------
-- KAREDE UYGULAMA
--
-- Butun parcalarin yeni CFrame'i bu listelere yigiliyor ve karenin sonunda
-- TEK bir BulkMoveTo ile yaziliyor: 20 deste x 4 katman = 80 ayri CFrame
-- atamasi yerine tek cagri.
------------------------------------------------------------------
local tasinacak: { BasePart } = {}
local hedefler: { CFrame } = {}

local function uygula(d: Deste)
	local pop = if d.pop < POP_SURE then popOlcegi(d.pop / POP_SURE) else 1
	local s = pop * d.kucul

	--[[
		Ezilme hacmi korur gibi davraniyor: basildikca (ezilme < 0) boy
		kisalir, en ve derinlik genisler.
	]]
	local e = d.ezilme
	local olcek = Vector3.new(s * (1 - e * 0.5), s * (1 + e), s * (1 - e * 0.5))

	-- Boyut yazmak pahali; yalnizca gercekten degistiyse
	local degisti = (olcek - d.sonOlcek).Magnitude > 0.002
	if degisti then
		d.sonOlcek = olcek
	end

	local ana = CFrame.new(d.konum) * d.rot
	for _, k in d.katmanlar do
		if degisti then
			k.parca.Size = k.boy * olcek
		end
		table.insert(tasinacak, k.parca)
		table.insert(hedefler, ana * CFrame.new(k.konum * olcek) * k.don)
	end
end

------------------------------------------------------------------
-- SACMA
------------------------------------------------------------------
local isin = RaycastParams.new()
isin.FilterType = Enum.RaycastFilterType.Exclude

--[[
	ZEMIN YUKSEKLIGI

	Desteler dustukleri yerin zeminine yatiyor: buton yerden biraz yuksek,
	hepsi o hizada kalsa cevresinde havada asili duruyordu.
]]
local function zemin(nokta: Vector3, yedek: number): number
	local sonuc = Workspace:Raycast(nokta + Vector3.new(0, 6, 0), Vector3.new(0, -20, 0), isin)
	return if sonuc then sonuc.Position.Y else yedek
end

local function sac(oyuncu: Player, nokta: Vector3, miktar: number, turAdi: string?)
	local kamera = Workspace.CurrentCamera
	if kamera and (kamera.CFrame.Position - nokta).Magnitude > GORUNME_MESAFESI then
		return
	end

	local ad = turAdi or "para"
	local tur = TURLER[ad] or TURLER.para
	local yukseklik = tur.yukseklik

	local adet = tur.adetMin + math.floor(math.log10(math.max(miktar, 1)) * tur.adetCarpan)
	adet = math.clamp(adet, tur.adetMin, tur.adetMax)
	adet = math.min(adet, AKTIF_TAVAN - #aktif)
	if adet <= 0 then
		return
	end

	-- Isin filtresi bu patlama icin bir kez kuruluyor
	local haric: { Instance } = { klasor }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(haric, p.Character)
		end
	end
	isin.FilterDescendantsInstances = haric

	local baslangic = nokta + Vector3.new(0, yukseklik, 0)

	-- Butonda kivilcim patlamasi: desteler firlamadan hemen once
	kivilcimAt(baslangic, 16, ad == "coin")

	for i = 1, adet do
		--[[
			Acilar tur boyunca ESIT dagiliyor, ustune biraz sapma: tamamen
			rastgele olunca desteler bir tarafa yigilip digeri bos kaliyordu.
		]]
		local yon = (i / adet) * math.pi * 2 + rng:NextNumber(-0.35, 0.35)
		local r = rng:NextNumber(YARICAP_MIN, YARICAP_MAX)
		local yatay = nokta + Vector3.new(math.cos(yon) * r, 0, math.sin(yon) * r)
		local zeminY = zemin(yatay, nokta.Y) + yukseklik * 0.5

		--[[
			ATIS HIZI

			Istenen ucus suresi (sure) ve tepe yuksekliginden (tepe) geriye
			hesaplaniyor: yercekimi g = 8*tepe/sure^2 secilince kavis tam o
			yukseklige cikip tam o surede zemine iniyor. Dikey hiz baslangic
			ile zemin arasindaki yukseklik farkini da karsiliyor.
		]]
		local sure = rng:NextNumber(UCUS_SURE_MIN, UCUS_SURE_MAX)
		local tepe = rng:NextNumber(TEPE_MIN, TEPE_MAX)
		local g = 8 * tepe / (sure * sure)
		local dikey = ((zeminY - baslangic.Y) + 0.5 * g * sure * sure) / sure
		local hiz = Vector3.new((yatay.X - baslangic.X) / sure, dikey, (yatay.Z - baslangic.Z) / sure)

		local katmanlar, iz = desteKur(baslangic, tur)

		local d: Deste = {
			tur = ad,
			katmanlar = katmanlar,
			iz = iz,
			oyuncu = oyuncu,
			evre = "gecikme",
			t = 0,
			omur = 0,
			gecikme = (i - 1) * GECIKME_ADIM,
			konum = baslangic,
			hiz = hiz,
			yercekimi = g,
			zeminY = zeminY,
			sekme = 0,
			yerde = false,
			rot = CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28)),
			donus = Vector3.new(rng:NextNumber(-9, 9), rng:NextNumber(-6, 6), rng:NextNumber(-9, 9)),
			faz = rng:NextNumber(0, 6.28),
			bekleme = rng:NextNumber(BEKLEME_MIN, BEKLEME_MAX),
			pop = 0,
			ezilme = 0,
			ezilmeHiz = 0,
			kucul = 1,
			sonOlcek = Vector3.new(-1, -1, -1),
			cekBas = baslangic,
			cekKontrol = baslangic,
			cekSure = CEKME_SURE_MIN,
		}
		table.insert(aktif, d)
	end
end

------------------------------------------------------------------
-- TEK SURUCU
--
-- Butun desteler tek RenderStepped'te ilerliyor. Hic deste yokken dongu
-- ilk satirda donuyor, yani bosta sifir maliyet.
------------------------------------------------------------------
RunService.RenderStepped:Connect(function(ham)
	if #aktif == 0 then
		return
	end

	-- Kare dususunde desteler bir anda ucup gitmesin
	local dt = math.min(ham, 1 / 20)

	table.clear(tasinacak)
	table.clear(hedefler)

	-- Sondan basa: silinen destenin yerine sondaki geliyor, o zaten islendi
	for i = #aktif, 1, -1 do
		local d = aktif[i]
		d.omur += dt
		local bitti = false

		if d.evre ~= "gecikme" then
			d.pop += dt

			-- Ezilme yayi her evrede isliyor (carpma, dogma)
			d.ezilmeHiz += (-EZILME_SERTLIK * d.ezilme - EZILME_SONUM * d.ezilmeHiz) * dt
			d.ezilme += d.ezilmeHiz * dt
		end

		if d.evre == "gecikme" then
			d.gecikme -= dt
			if d.gecikme <= 0 then
				d.evre = "sac"
				saydamlik(d, 0)
			end
		elseif d.evre == "sac" then
			d.hiz += Vector3.new(0, -d.yercekimi * dt, 0)
			d.konum += d.hiz * dt
			d.rot = CFrame.Angles(d.donus.X * dt, d.donus.Y * dt, d.donus.Z * dt) * d.rot

			if d.konum.Y <= d.zeminY and d.hiz.Y < 0 then
				d.konum = Vector3.new(d.konum.X, d.zeminY, d.konum.Z)
				d.sekme += 1
				d.yerde = true

				-- Carpma ne kadar sertse o kadar ezilir
				d.ezilme = -math.clamp(-d.hiz.Y / 40, 0.12, 0.34)
				d.ezilmeHiz = 0

				local geriDonen = -d.hiz.Y * SEKME_KATSAYI
				if d.sekme > SEKME_EN_COK or geriDonen < SEKME_EN_AZ_HIZ then
					d.hiz = Vector3.zero
					d.evre = "bekle"
					d.t = 0
				else
					d.hiz = Vector3.new(d.hiz.X * SEKME_SURTUNME, geriDonen, d.hiz.Z * SEKME_SURTUNME)
					-- Her sekmede donus da sonumlenir
					d.donus *= 0.35
				end
			end

			--[[
				Yere yaklasirken hafifce, degdikten sonra kuvvetle duz yatisa
				doner. Yuksekteyken hic karismaz: havadaki donus serbest.
			]]
			local yukseklik = d.konum.Y - d.zeminY
			if d.yerde then
				duzlestir(d, 14, dt)
			elseif d.hiz.Y < 0 and yukseklik < 1.5 then
				duzlestir(d, 6, dt)
			end
		elseif d.evre == "bekle" then
			d.t += dt
			duzlestir(d, 14, dt)

			-- Nefes: yerden hafifce kalkip iner, yavasca kendi ekseninde doner
			local nefes = (1 - math.cos(d.t * 6 + d.faz)) * 0.04
			d.konum = Vector3.new(d.konum.X, d.zeminY + nefes, d.konum.Z)
			d.rot = CFrame.Angles(0, 1.2 * dt, 0) * d.rot

			if d.t >= d.bekleme then
				local karakter = d.oyuncu.Character
				local kok = karakter and karakter:FindFirstChild("HumanoidRootPart")

				if kok and kok:IsA("BasePart") then
					local mesafe = (kok.Position - d.konum).Magnitude
					d.evre = "cek"
					d.t = 0
					d.cekBas = d.konum
					d.cekSure = math.clamp(mesafe / CEKME_HIZ_OLCEK, CEKME_SURE_MIN, CEKME_SURE_MAX)

					--[[
						Egrinin kontrol noktasi: baslangicla oyuncunun ortasi,
						yukari kaldirilmis ve hafif yana kaydirilmis. Her
						deste farkli kavisten gelsin diye yan kayma rastgele.
					]]
					local orta = d.konum:Lerp(kok.Position, 0.5)
					d.cekKontrol = orta
						+ Vector3.new(
							rng:NextNumber(-2, 2),
							rng:NextNumber(CEKME_KAVIS_MIN, CEKME_KAVIS_MAX),
							rng:NextNumber(-2, 2)
						)
					d.iz.Enabled = true
				else
					d.evre = "sol"
					d.t = 0
				end
			end
		elseif d.evre == "cek" then
			local karakter = d.oyuncu.Character
			local kok = karakter and karakter:FindFirstChild("HumanoidRootPart")

			if kok and kok:IsA("BasePart") then
				d.t += dt
				local u = math.min(d.t / d.cekSure, 1)
				-- Basta yavas, sona dogru hizlanir: toplanma hissi
				local e = u * u

				-- Hedef her karede yeniden okunuyor: oyuncu kacarken desteler pesinden gider
				local hedef = kok.Position + Vector3.new(0, 0.6, 0)
				local a = d.cekBas:Lerp(d.cekKontrol, e)
				local b = d.cekKontrol:Lerp(hedef, e)
				d.konum = a:Lerp(b, e)
				d.rot = CFrame.Angles(0, 10 * dt, 0) * d.rot

				-- Son kisimda kuculerek oyuncunun icine girer
				d.kucul = if u > 0.55 then 1 - 0.7 * ((u - 0.55) / 0.45) else 1

				if u >= 1 then
					kivilcimAt(d.konum, 3, d.tur == "coin")
					bitti = true
				end
			else
				d.evre = "sol"
				d.t = 0
				d.iz.Enabled = false
			end
		else
			-- sol: karakter yok (oldu ya da oyundan cikti), yerinde solup gider
			d.t += dt
			local solma = math.min(d.t / 0.3, 1)
			saydamlik(d, solma)
			if solma >= 1 then
				bitti = true
			end
		end

		if d.omur > EN_UZUN_OMUR then
			bitti = true
		end

		if bitti then
			sil(d)
			aktif[i] = aktif[#aktif]
			aktif[#aktif] = nil
		elseif d.evre ~= "gecikme" then
			uygula(d)
		end
	end

	if #tasinacak > 0 then
		Workspace:BulkMoveTo(tasinacak, hedefler, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)

ParaSac.OnClientEvent:Connect(function(oyuncu, nokta, miktar)
	if typeof(oyuncu) ~= "Instance" or not oyuncu:IsA("Player") then
		return
	end
	if typeof(nokta) ~= "Vector3" or type(miktar) ~= "number" then
		return
	end

	sac(oyuncu :: Player, nokta, miktar)
end)

------------------------------------------------------------------
-- ROT COIN KAZANCI
--
-- Ilk gelen veri yalnizca baslangic degeri (oyuna girerken para sacilmaz).
-- Sonrasinda bakiye artarsa, fark kadar altin para oyuncunun ayaginin
-- dibinden etrafa sacilip ona geri ucar. Harcama (azalma) sessiz.
------------------------------------------------------------------
local oyuncu = Players.LocalPlayer
local sonCoin: number? = nil

EnvanterGuncelle.OnClientEvent:Connect(function(veri)
	if type(veri) ~= "table" or type(veri.rotCoins) ~= "number" then
		return
	end

	local yeni = veri.rotCoins
	local once = sonCoin
	sonCoin = yeni

	if not once or yeni <= once then
		return
	end

	local karakter = oyuncu.Character
	local kok = karakter and karakter:FindFirstChild("HumanoidRootPart")
	local insan = karakter and karakter:FindFirstChildOfClass("Humanoid")
	if not kok or not kok:IsA("BasePart") then
		return
	end

	local govde = kok :: BasePart

	-- Ayak hizasi: kok parcanin altindaki bacak boyu kadar asagi
	local bacak = if insan then insan.HipHeight + govde.Size.Y * 0.5 else 3
	sac(oyuncu, govde.Position - Vector3.new(0, bacak, 0), yeni - once, "coin")
end)
