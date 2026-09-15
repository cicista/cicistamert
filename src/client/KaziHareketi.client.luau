--[[
	KaziHareketi  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > KaziHareketi

	KAZARKEN GERCEK KAZI HAREKETI  --  animasyon dosyasi gerektirmez

	Sunucu karada kazi baslayinca karaktere iki nitelik yazar, kazi bitince
	kaldirir (bkz. ServerScriptService > KaziSistemi):
	    Kaziyor    -- hareket oynasin
	    KaziHedef  -- kazilan nokta (Vector3)

	UC PARCA BIRLIKTE CALISIR

	  1. YON      Kendi karakterin kazi baslayinca KaziHedef'e doner ve kazi
	              boyunca kendiliginden donmez (Humanoid.AutoRotate kapali).

	  2. KUREK    Bicagin DUNYADA bakacagi yon her karede hesaplanir:
	              karakterin onu, yataydan "bicakAci" derece asagi. Kuregin
	              eldeki acisi (RightGrip kaynaginin C1'i) bicagi tam o yone ceviren donus
	              olarak kurulur.

	              Onceki surum Grip'i sabit bir isaretle ceviriyordu ve bicak
	              havaya bakiyordu. Artik isaret tahmini yok: bicagin Handle'a
	              gore nerede oldugu kazi basinda MODELIN KENDISINDEN olculur
	              (Govde / Kenar parcalarinin ortasi), hedef yon de dunyada
	              verilir -- Roblox'un eksen duzeni ne olursa olsun bicak
	              istenen yone bakar.

	  3. VUCUT    Bel, kalca kok, sag omuz/dirsek, kalcalar ve dizler kurege
	              eslik eder. SOL EL IKControl ile sapin ortasina uzanir.

	BIR KAZI TURU (anahtar pozlar, aralari yumusak gecis)
	    1. HAZIR     bicak one-asagi hafif egik
	    2. SAPLAMA   one egil, dizleri buk, bicak dik bicimde topraga
	    3. KALDIRAC  sapi geri cek, bicak yataya yaklasir
	    4. ATIS      dogrul, bicak kalkar, govde yana donup topragi atar

	AYAR: POZLAR tablosu (bicakAci ve eklem dereceleri), PERIYOT, SOL_EL_SAPTA.

	EKLEMLER IKI TURLU OLABILIR
	  Motor6D             -- klasik eklem; poz C0'a eklenir
	  AnimationConstraint -- StarterPlayer.AvatarJointUpgrade ACIKKEN (bu oyunda
	                         acik). C0'i yok; ayni isi govde tarafindaki
	                         Attachment0.CFrame goruyor, poz oraya eklenir.
	Kazi bitince eklemler, kuregin acisi ve donme ayari tam eski haline doner.

	Gercek bir animasyon yuklenirse (Shared > Assets > Animations > shovelDig)
	elindeki aracta "DigAnimation" niteligi olur ve bu hareket devre disi kalir.
	Denizde (olta) nitelik hic yazilmaz.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

local NITELIK = "Kaziyor"
local HEDEF_NITELIGI = "KaziHedef"

-- Bir kazi turunun suresi (saniye)
local PERIYOT = 1.3

-- Kazi baslarken hareketin tam gucune ulasma suresi (ani sicrama olmasin)
local GIRIS_SURESI = 0.3

-- Sol elin tuttugu yer: sag elden bicaga dogru kac stud
local SOL_EL_SAPTA = 1.5

--[[
	KUREK POZLARI  --  t = turun neresinde (0..1)

	Hareket YATAY agirlikli: once kurek ARKAYA atilir, oradan guc alinip
	alcaktan ileri saplanir; yukaridan asagi vurus yok.

	  bicakAci   derece: kurek KAFASININ dunyada baktigi yon
	             0 = duz ileri, 90 = dik asagi, 90'dan buyuk = arkaya-asagi,
	             eksi = yukari kalkik
	  omuz / dirsek / kalca  +  -> ileri
	  diz                    -  -> bukum
	  bel / kok (egim)       -  -> one egilme
	  belDon                 +  -> govde sola doner (topragi atma), - saga-geri
	  alcal                  -  -> kalca asagi iner (stud)

	    1. HAZIR     kafa one-asagi hafif egik
	    2. GERI AT   kurek arkaya savrulur: kafa arka-asagi, kol geride,
	                 govde saga-geri doner, agirlik arka bacakta
	    3. SAPLA     sarkac gibi alcaktan gecip ILERI saplanir: kafa neredeyse
	                 yatay, kol onde, govde one hamle, dizler bukuk
	    4. ITTIR     ayni pozda kisa itis (toprak yukleniyor)
	    5. AT        dogrul, kafa kalkar, govde sola donup topragi atar
]]
local POZLAR = {
	{
		-- HAZIR
		t = 0,
		bicakAci = 25,
		bel = -8, belDon = 0, kok = 0, alcal = 0,
		sagOmuz = 25, sagDirsek = 20,
		sagKalca = 0, solKalca = 0, sagDiz = 0, solDiz = 0,
	},
	{
		-- GERI AT: kurek arkaya savrulur, guc toplanir
		t = 0.28,
		bicakAci = 130,
		bel = 6, belDon = -22, kok = 2, alcal = -0.1,
		sagOmuz = -40, sagDirsek = 30,
		sagKalca = -8, solKalca = 14, sagDiz = -12, solDiz = -18,
	},
	{
		-- SAPLA: alcaktan ileri, neredeyse yatay
		t = 0.5,
		bicakAci = 18,
		bel = -28, belDon = 12, kok = -4, alcal = -0.3,
		sagOmuz = 60, sagDirsek = 10,
		sagKalca = 24, solKalca = 6, sagDiz = -30, solDiz = -10,
	},
	{
		-- ITTIR: toprak yukleniyor
		t = 0.62,
		bicakAci = 22,
		bel = -30, belDon = 14, kok = -5, alcal = -0.32,
		sagOmuz = 62, sagDirsek = 8,
		sagKalca = 24, solKalca = 6, sagDiz = -30, solDiz = -10,
	},
	{
		-- AT: dogrul, govde sola donup topragi atar
		t = 0.82,
		bicakAci = -10,
		bel = -8, belDon = 28, kok = 0, alcal = -0.1,
		sagOmuz = 45, sagDirsek = 25,
		sagKalca = 8, solKalca = 4, sagDiz = -10, solDiz = -6,
	},
}

--[[
	KAZMA POZLARI  --  madende cevher kirma

	bicakAci burada kazma KAFASININ yonu: -90 dik yukari, -90'dan kucuk
	degerler basin ustunden ARKAYA gecer, arti degerler one-asagi (cevhere).

	    1. TOPARLAN  kafa onde, kol onde-asagi
	    2. KALDIR    kazma BASIN ARKASINA kadar kalkar: kol basin ustunde,
	                 dirsek bukuk, govde hafif geride
	    3. TEPE      kisa bekleme, en arkada
	    4. VUR       hizla one-asagi, cevhere: kol one uzanir, govde one
	                 egilir, dizler bukulur
	    5. CARPMA    darbe aninda kisa duraksama
]]
local KAZMA_POZLARI = {
	{
		-- TOPARLAN
		t = 0,
		bicakAci = 20,
		bel = -8, belDon = 0, kok = 0, alcal = 0,
		sagOmuz = 40, sagDirsek = 20,
		sagKalca = 0, solKalca = 0, sagDiz = 0, solDiz = 0,
	},
	{
		-- KALDIR: kafa basin arkasinda
		t = 0.4,
		bicakAci = -165,
		bel = 12, belDon = 0, kok = 3, alcal = 0,
		sagOmuz = 165, sagDirsek = 70,
		sagKalca = -4, solKalca = 8, sagDiz = -4, solDiz = -8,
	},
	{
		-- TEPE: en arkada kisa bekleme
		t = 0.5,
		bicakAci = -170,
		bel = 14, belDon = 0, kok = 3, alcal = 0,
		sagOmuz = 170, sagDirsek = 75,
		sagKalca = -4, solKalca = 8, sagDiz = -4, solDiz = -8,
	},
	{
		-- VUR: hizla one-asagi, cevhere
		t = 0.62,
		bicakAci = 60,
		bel = -32, belDon = 0, kok = -5, alcal = -0.25,
		sagOmuz = 45, sagDirsek = 10,
		sagKalca = 22, solKalca = 12, sagDiz = -26, solDiz = -18,
	},
	{
		-- CARPMA: darbe aninda duraksama
		t = 0.76,
		bicakAci = 58,
		bel = -30, belDon = 0, kok = -5, alcal = -0.25,
		sagOmuz = 42, sagDirsek = 12,
		sagKalca = 22, solKalca = 12, sagDiz = -26, solDiz = -18,
	},
}

--[[
	HAREKET SETLERI: elde KAZMA (PickaxeId) varsa "kazma", yoksa "kurek".
	    periyot -- bir turun suresi (saniye)
	    solEl   -- sol elin sapta, sag elden kafaya dogru kac stud otede tuttugu
]]
local POZ_SETLERI = {
	kurek = { periyot = PERIYOT, solEl = SOL_EL_SAPTA, pozlar = POZLAR },
	kazma = { periyot = 1.1, solEl = 0.9, pozlar = KAZMA_POZLARI },
}

-- rol -> hangi parca, hangi eklem (R15). Sol kol IKControl'e birakildi.
local R15_EKLEMLER = {
	{ rol = "bel", parca = "UpperTorso", eklem = "Waist" },
	{ rol = "kok", parca = "LowerTorso", eklem = "Root" },
	{ rol = "sagOmuz", parca = "RightUpperArm", eklem = "RightShoulder" },
	{ rol = "sagDirsek", parca = "RightLowerArm", eklem = "RightElbow" },
	{ rol = "sagKalca", parca = "RightUpperLeg", eklem = "RightHip" },
	{ rol = "solKalca", parca = "LeftUpperLeg", eklem = "LeftHip" },
	{ rol = "sagDiz", parca = "RightLowerLeg", eklem = "RightKnee" },
	{ rol = "solDiz", parca = "LeftLowerLeg", eklem = "LeftKnee" },
}

type Eklem = {
	-- C0'i degisecek Motor6D ya da CFrame'i degisecek Attachment
	hedef: Instance,
	asil: CFrame,
	rol: string,
	-- R15 eklemleri X etrafinda, R6 omzu Z etrafinda doner
	r6: boolean,
}

type Oynayan = {
	eklemler: { Eklem },
	basla: number,
	-- POZ_SETLERI.kurek ya da POZ_SETLERI.kazma
	set: any,
	arac: Tool?,
	-- Eli kurege baglayan RightGrip kaynagi ve kazi oncesi C1'i
	kaynak: Weld?,
	kaynakAsilC1: CFrame?,
	-- Handle'in YEREL uzayinda, elden bicaga dogru birim yon (modelden olculur)
	bicakYonu: Vector3?,
	solElNoktasi: Attachment?,
	ik: Instance?,
	otomatikDonus: boolean?,
}

local oynayanlar: { [Model]: Oynayan } = {}

local function hedefCFrame(hedef: Instance, deger: CFrame)
	if hedef:IsA("Motor6D") then
		hedef.C0 = deger
	elseif hedef:IsA("Attachment") then
		hedef.CFrame = deger
	end
end

local function eklemleriBul(character: Model): { Eklem }
	local out: { Eklem } = {}

	local function eklemAra(parcaAdi: string, eklemAdi: string): Instance?
		local parca = character:FindFirstChild(parcaAdi)
		local dogrudan = parca and parca:FindFirstChild(eklemAdi)
		if dogrudan then
			return dogrudan
		end
		for _, d in character:GetDescendants() do
			if d.Name == eklemAdi and (d:IsA("Motor6D") or d.ClassName == "AnimationConstraint") then
				return d
			end
		end
		return nil
	end

	local function ekle(eklem: Instance?, rol: string, r6: boolean)
		if not eklem then
			return
		end
		if eklem:IsA("Motor6D") then
			table.insert(out, { hedef = eklem, asil = eklem.C0, rol = rol, r6 = r6 })
		elseif eklem.ClassName == "AnimationConstraint" then
			local baglanti = (eklem :: any).Attachment0
			if baglanti and baglanti:IsA("Attachment") then
				table.insert(out, { hedef = baglanti, asil = baglanti.CFrame, rol = rol, r6 = r6 })
			end
		end
	end

	if character:FindFirstChild("UpperTorso") then
		for _, tanim in R15_EKLEMLER do
			ekle(eklemAra(tanim.parca, tanim.eklem), tanim.rol, false)
		end
	else
		-- R6: yalnizca sag omuz (diger eklemlerin eksenleri farkli, sade tutuldu)
		ekle(eklemAra("Torso", "Right Shoulder"), "sagOmuz", true)
	end

	return out
end

-- Eldeki kurek ya da kazma
local function kazmaAraci(character: Model): Tool?
	for _, item in character:GetChildren() do
		if item:IsA("Tool") and (item:GetAttribute("ShovelId") or item:GetAttribute("PickaxeId")) then
			return item
		end
	end
	return nil
end

-- Elindeki arac gercek bir kazma animasyonu tasiyor mu
local function gercekAnimasyonVar(character: Model): boolean
	local arac = kazmaAraci(character)
	local id = arac and arac:GetAttribute("DigAnimation")
	return type(id) == "string" and id ~= ""
end

--[[
	BICAK YONU  --  modelin kendisinden olculur

	Kurek ve kazma modellerinde bicak / kazma kafasi "Govde" ve "Kenar"
	klasorlerinde (bkz. Assets > Shovels, Pickaxes). Bu parcalarin ortasi
	Handle'in yerel uzayina cevrilir; Handle'dan oraya giden birim yon
	doner. Klasorler yoksa Handle'a en uzak parca kullanilir.
]]
local function bicakYonuBul(arac: Tool): Vector3?
	local handle = arac:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return nil
	end

	local toplam = Vector3.zero
	local adet = 0
	for _, klasorAdi in { "Govde", "Kenar" } do
		local klasor = arac:FindFirstChild(klasorAdi, true)
		if klasor then
			for _, d in klasor:GetDescendants() do
				if d:IsA("BasePart") then
					toplam += d.Position
					adet += 1
				end
			end
		end
	end

	local merkez: Vector3? = if adet > 0 then toplam / adet else nil
	if not merkez then
		local enUzak = 0
		for _, d in arac:GetDescendants() do
			if d:IsA("BasePart") and d ~= handle then
				local mesafe = (d.Position - handle.Position).Magnitude
				if mesafe > enUzak then
					enUzak = mesafe
					merkez = d.Position
				end
			end
		end
	end
	if not merkez then
		return nil
	end

	local yerel = handle.CFrame:VectorToObjectSpace(merkez - handle.Position)
	return if yerel.Magnitude > 0.05 then yerel.Unit else nil
end

-- a birim yonunu b birim yonune ceviren donus
local function yonDonus(a: Vector3, b: Vector3): CFrame
	local d = math.clamp(a:Dot(b), -1, 1)
	if d > 0.9999 then
		return CFrame.identity
	end
	if d < -0.9999 then
		local yardimci = if math.abs(a.X) < 0.9 then Vector3.xAxis else Vector3.yAxis
		return CFrame.fromAxisAngle(a:Cross(yardimci).Unit, math.pi)
	end
	return CFrame.fromAxisAngle(a:Cross(b).Unit, math.acos(d))
end

--[[
	ELI KUREGE BAGLAYAN KAYNAK  (RightGrip)

	Roblox bir Tool kusanilinca sag el ile Handle arasina "RightGrip" adli
	bir Weld kurar:  Handle = El * C0 * C1^-1  (C1, Tool.Grip'in karsiligi).

	Tool.Grip'i ISTEMCIDE degistirmek bu kaynagi GUNCELLEMIYOR (Roblox bunu
	sunucuda yapiyor); onceki surum bu yuzden kuregi hic kipirdatamadi. Artik
	dogrudan kaynagin C1'i degistiriliyor. Karakter parcalari oyuncunun kendi
	bilgisayarinda hesaplandigi icin sonuc ekranda gorunur ve diger oyunculara
	da gider.
]]
local function tutusKaynagi(character: Model, arac: Tool?): Weld?
	local handle = arac and arac:FindFirstChild("Handle")
	for _, d in character:GetDescendants() do
		if d:IsA("Weld") and d.Name == "RightGrip" and (not handle or d.Part1 == handle) then
			return d
		end
	end
	return nil
end

-- SOL EL: sapin ortasina IKControl ile uzanir
local function solEliBagla(character: Model, oynayan: Oynayan)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local arac = oynayan.arac
	local handle = arac and arac:FindFirstChild("Handle")
	local solUstKol = character:FindFirstChild("LeftUpperArm")
	local solEl = character:FindFirstChild("LeftHand")
	local yon = oynayan.bicakYonu
	if not humanoid or not handle or not handle:IsA("BasePart") or not solUstKol or not solEl or not yon then
		return
	end

	local nokta = Instance.new("Attachment")
	nokta.Name = "SolElTutus"
	nokta.Position = yon * (oynayan.set.solEl or SOL_EL_SAPTA)
	nokta.Parent = handle
	oynayan.solElNoktasi = nokta

	local ok, ik = pcall(function()
		local yeni = Instance.new("IKControl")
		yeni.Name = "KaziSolEl"
		yeni.Type = Enum.IKControlType.Position
		yeni.ChainRoot = solUstKol
		yeni.EndEffector = solEl
		yeni.Target = nokta
		yeni.Weight = 1
		yeni.SmoothTime = 0.04
		yeni.Parent = humanoid
		return yeni
	end)
	if ok then
		oynayan.ik = ik
	end
end

-- Kendi karakterin kazilan noktaya doner, kazi boyunca kendiliginden donmez
local function hedefeDon(character: Model, oynayan: Oynayan)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local kok = character:FindFirstChild("HumanoidRootPart")
	local hedef = character:GetAttribute(HEDEF_NITELIGI)
	if not humanoid or not kok or not kok:IsA("BasePart") or typeof(hedef) ~= "Vector3" then
		return
	end

	oynayan.otomatikDonus = humanoid.AutoRotate
	humanoid.AutoRotate = false

	local konum = kok.Position
	local bakis = Vector3.new(hedef.X, konum.Y, hedef.Z)
	if (bakis - konum).Magnitude > 0.5 then
		kok.CFrame = CFrame.lookAt(konum, bakis)
	end
end

local function yumusak(t: number): number
	return t * t * (3 - 2 * t)
end

-- Turun t anindaki poz degerleri (anahtar pozlar arasi yumusak gecis, 1'de basa doner)
local function pozAl(pozlar: { any }, t: number): { [string]: number }
	local adet = #pozlar
	for i = 1, adet do
		local a = pozlar[i]
		local b = pozlar[i + 1] or pozlar[1]
		local bT = if i < adet then b.t else 1
		if t >= a.t and t < bT then
			local oran = yumusak((t - a.t) / (bT - a.t))
			local sonuc = {}
			for anahtar, deger in a do
				if anahtar ~= "t" then
					sonuc[anahtar] = deger + ((b :: any)[anahtar] - deger) * oran
				end
			end
			return sonuc
		end
	end
	return pozlar[1] :: any
end

local function birak(character: Model)
	local oynayan = oynayanlar[character]
	if not oynayan then
		return
	end
	oynayanlar[character] = nil

	for _, eklem in oynayan.eklemler do
		if eklem.hedef.Parent then
			hedefCFrame(eklem.hedef, eklem.asil)
		end
	end

	local kaynak = oynayan.kaynak
	if kaynak and oynayan.kaynakAsilC1 and kaynak.Parent then
		kaynak.C1 = oynayan.kaynakAsilC1
	end

	if oynayan.ik then
		oynayan.ik:Destroy()
	end
	if oynayan.solElNoktasi then
		oynayan.solElNoktasi:Destroy()
	end

	if oynayan.otomatikDonus ~= nil then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.AutoRotate = oynayan.otomatikDonus
		end
	end
end

local function uygula(character: Model, oynayan: Oynayan, simdi: number)
	local gecen = simdi - oynayan.basla
	local set = oynayan.set
	local t = (gecen % set.periyot) / set.periyot
	local poz = pozAl(set.pozlar, t)
	local guc = math.clamp(gecen / GIRIS_SURESI, 0, 1)

	for _, eklem in oynayan.eklemler do
		local aci = math.rad((poz[eklem.rol] or 0) * guc)
		local donus: CFrame

		if eklem.r6 then
			donus = CFrame.Angles(0, 0, aci)
		elseif eklem.rol == "bel" then
			donus = CFrame.Angles(aci, math.rad((poz.belDon or 0) * guc), 0)
		elseif eklem.rol == "kok" then
			donus = CFrame.new(0, (poz.alcal or 0) * guc, 0) * CFrame.Angles(aci, 0, 0)
		else
			donus = CFrame.Angles(aci, 0, 0)
		end

		hedefCFrame(eklem.hedef, eklem.asil * donus)
	end

	--[[
		KUREGIN YONU

		Istenen: bicak karakterin ONUNDE, yataydan bicakAci derece asagi.
		RightGrip.C1'in tersi, Handle'in yerel uzayini El*C0 cercevesinin uzayina
		tasiyan donustur. Olculen bicak yonunu (Handle uzayi) istenen yone
		(tutus noktasi uzayi) ceviren donus bulunur, Grip onun tersi olur.
	]]
	local arac = oynayan.arac
	local bicak = oynayan.bicakYonu

	-- Kaynak kazi basladiginda henuz kurulmamis olabilir: bulunana kadar ara
	if arac and not oynayan.kaynak then
		local bulunan = tutusKaynagi(character, arac)
		if bulunan then
			oynayan.kaynak = bulunan
			oynayan.kaynakAsilC1 = bulunan.C1
		end
	end

	local kaynak = oynayan.kaynak
	local asilC1 = oynayan.kaynakAsilC1
	local el = kaynak and kaynak.Part0
	local kok = character:FindFirstChild("HumanoidRootPart")
	if kaynak and kaynak.Parent and asilC1 and el and bicak and kok and kok:IsA("BasePart") then
		local ileri = Vector3.new(kok.CFrame.LookVector.X, 0, kok.CFrame.LookVector.Z)
		if ileri.Magnitude > 0.01 then
			local aciRad = math.rad(poz.bicakAci or 0)
			local dunyaYon = ileri.Unit * math.cos(aciRad) - Vector3.yAxis * math.sin(aciRad)

			-- Kaynagin gercekten kullandigi cerceve: El * C0
			local cerceve = el.CFrame * kaynak.C0
			local yerelYon = cerceve:VectorToObjectSpace(dunyaYon)

			--[[
				C1'in KAYMASI korunur (Assets.ToolGrips.shovel.position: sap
				avuca otursun diye verilen kucuk kayma). Kayma yalnizca elin
				sapta nerede durdugunu degistirir; bicagin yonunu belirleyen
				donus kismidir, o da tamamen burada hesaplanir.
			]]
			local hedefC1 = CFrame.new(asilC1.Position) * yonDonus(bicak, yerelYon.Unit):Inverse()
			kaynak.C1 = asilC1:Lerp(hedefC1, guc)
		end
	end
end

RunService.RenderStepped:Connect(function()
	local simdi = os.clock()
	local gorulen: { [Model]: boolean } = {}

	for _, oyuncu in Players:GetPlayers() do
		local character = oyuncu.Character
		if not character then
			continue
		end

		if character:GetAttribute(NITELIK) == true and not gercekAnimasyonVar(character) then
			gorulen[character] = true
			local oynayan = oynayanlar[character]

			if not oynayan then
				local eklemler = eklemleriBul(character)
				if #eklemler == 0 then
					continue
				end
				local arac = kazmaAraci(character)
				local yeni: Oynayan = {
					eklemler = eklemler,
					basla = simdi,
					arac = arac,
					-- Madende kazma: yukaridan asagi cevher kirma; digeri kurek kazisi
					set = if arac and arac:GetAttribute("PickaxeId") ~= nil
						then POZ_SETLERI.kazma
						else POZ_SETLERI.kurek,
					bicakYonu = if arac then bicakYonuBul(arac) else nil,
				}
				oynayanlar[character] = yeni
				oynayan = yeni

				solEliBagla(character, yeni)
				if oyuncu == localPlayer then
					hedefeDon(character, yeni)
				end
			end

			-- Arac kazi sirasinda degistiyse (kurek sonradan ele geldi) yeniden bagla
			if kazmaAraci(character) ~= oynayan.arac then
				birak(character)
				continue
			end

			uygula(character, oynayan, simdi)
		end
	end

	-- Kazisi biten, karakteri degisen ya da oyundan cikan: her sey geri
	for character in oynayanlar do
		if not gorulen[character] then
			birak(character)
		end
	end
end)
