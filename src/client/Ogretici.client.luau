--!strict
--[[
	Ogretici  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Ogretici

	Yeni oyuncunun ilk turunda ne yapmasi gerektigini gosterir. Adimlarin
	kendisi Shared > Ogretici'de, hangi adimda oldugumuz sunucudan geliyor
	(ServerScriptService > Modules > Ogretici); burasi YALNIZCA GOSTERIR.

	UC PARCA

	  1. Yonerge seridi  ekranin ustunde, "Dig in the sand!" gibi
	  2. Hedef isareti   hedefin etrafinda sari parlama + tepesinde nabiz
	                     atan bir nokta
	  3. Yol cizgisi     karakterle hedef arasinda uzanan sari isin

	HEPSI YEREL. Highlight ve BillboardGui PlayerGui'nin altinda duruyor ve
	dunyaya Adornee ile baglaniyor; Beam'in tutamaklari da istemcide
	olusturuluyor. Hedefin kendisine parent edilselerdi sunucudaki herkes
	gorurdu, ogreticiyi coktan bitirmis oyuncular dahil.

	HEDEFI BULMAK
	Isimle: dedektif ve fuse makinesi Config'teki adlariyla, base sunucunun
	yolladigi numarayla (Bases.baseName), kum ise oyuncuya EN YAKIN kum
	zemini. Hedef bulunamazsa isaretler KAPANIYOR ve her saniye yeniden
	araniyor -- onceki adimin hedefi ekranda kalmasin.
]]

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
-- Anlatici rozetindeki ikon
local Icons = require(Shared:WaitForChild("Icons"))

local UI = require(script.Parent:WaitForChild("UI"))

--[[
	KUM ADIMINDA "ALANDAYIM" MESAFESI

	Oyuncu kum isaretine bu kadar yaklastiysa isaretler kapanir; uzaklasinca
	geri gelir. "Uc tane kaz" adiminda sari cizginin pesini birakmamasi
	sikayet konusuydu.
]]
local KUM_YAKINLIK = 26

local OgreticiDurum = Net.event("OgreticiDurum")
local OgreticiIste = Net.event("OgreticiIste")
local BaseGuncelle = Net.event("BaseGuncelle")

local ISARET = Adimlar.IsaretRengi
local SIYAH = Color3.fromRGB(0, 0, 0)
local BEYAZ = Color3.fromRGB(255, 255, 255)

------------------------------------------------------------------
-- DURUM
------------------------------------------------------------------

-- Sunucudan gelen son durum; cevapGeldi ilk pakete kadar false
local cevapGeldi = false
local siraNo = 0
local bitti = true
local toplamAdim = Adimlar.adimSayisi()

-- Sunucunun bildirdigi base numarasi (hedef "base" iken kullaniliyor)
local baseIndex: number? = nil

-- O anki hedef; her saniye tazeleniyor
local hedef: Instance? = nil

-- Output'a ayni satiri tekrar tekrar yazmamak icin son teshis imzasi
local sonTeshis = ""

------------------------------------------------------------------
-- YONERGE SERIDI
------------------------------------------------------------------
local ekran = Instance.new("ScreenGui")
ekran.Name = "Ogretici"
--[[
	Menu butonlarinin (5) ustunde, panellerin (20) altinda: acilan bir
	pencere yonergeyi ortmesin ama yonerge de butonlarin onunde dursun.
	Katman sirasi UI.luau > PANEL KATMANI'nda.
]]
ekran.DisplayOrder = 6
ekran.ResetOnSpawn = false
ekran.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ekran.Parent = playerGui

local serit = Instance.new("Frame")
serit.Name = "Yonerge"
serit.AnchorPoint = Vector2.new(0.5, 0)
--[[
	GORUNUM  --  oyunun diger panelleriyle ayni dil

	Koyu mavi-mor degrade zemin, capraz desen, kalin siyah kontur ve
	cevresinde nabiz atan altin isilti. Solda yuvarlak ANLATICI rozeti
	duruyor; yazilar onun sagindan basliyor ve sola yaslaniyor.
]]
-- XP barinin hemen altinda (bar kucultuldu, serit de yukari alindi)
serit.Position = UDim2.new(0.5, 0, 0, 66)
serit.Size = UDim2.fromOffset(520, 86)
serit.BackgroundColor3 = BEYAZ
serit.BorderSizePixel = 0
serit.Visible = false
serit.Parent = ekran
UI.corner(serit, 16)
UI.stroke(serit, SIYAH, 3)

-- Anlatici resminin boyu (seridin ICINDE, sag tarafta durur)
local ANLATICI = 78
-- Yazilarin seridin solundan boslugu ve sagda anlaticiya birakilan yer
local YAZI_SOL = 22
local YAZI_SAG = ANLATICI + 24

do
	local zemin = Instance.new("UIGradient")
	zemin.Rotation = 90
	zemin.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 52, 120)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(32, 30, 62)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(46, 30, 78)),
	})
	zemin.Parent = serit

	UI.caprazDesen(serit, ISARET, 3)

	-- Cevresinde nabiz atan altin isilti
	local isilti = Instance.new("Frame")
	isilti.Name = "Isilti"
	isilti.AnchorPoint = Vector2.new(0.5, 0.5)
	isilti.Position = UDim2.fromScale(0.5, 0.5)
	isilti.Size = UDim2.new(1, 10, 1, 10)
	isilti.BackgroundTransparency = 1
	isilti.ZIndex = 0
	isilti.Parent = serit
	UI.corner(isilti, 19)
	local isiltiCizgi = UI.stroke(isilti, ISARET, 4)
	isiltiCizgi.Transparency = 0.35
	TweenService:Create(
		isiltiCizgi,
		TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Thickness = 9, Transparency = 0.85 }
	):Play()
end

--[[
	ANLATICI RESMI  --  seridin ICINDE, SAG tarafta duran karakter

	Resimler Studio'ya elle konuyor: ReplicatedStorage > Assets > Icons
	icine "hosgeldin", "dusunce", "tesvik", "dans" adlariyla (bkz.
	Shared > Ogretici > Anlaticilar). Her adim kendi resmini gosteriyor.

	YUVARLAK MADALYON + ICINE SIGAN RESIM.
	Resimler dikdortgen. Bir ara madalyon CanvasGroup yapilip resim
	Crop ile doldurulmustu ama o haliyle hic gorunmedi; simdi yapi en
	sade haliyle duruyor: yuvarlak bir cerceve ve ICINDE, kenarlara
	degmeyecek kadar kucuk (yaklasik dortte uc) bir resim. Resim kucuk
	oldugu icin kirpmaya gerek kalmiyor, yuvarlagin disina tasmiyor.
]]
local anlaticiKap = Instance.new("Frame")
anlaticiKap.Name = "Anlatici"
anlaticiKap.AnchorPoint = Vector2.new(1, 0.5)
-- Seridin sag ucunda, dikeyde ortali
anlaticiKap.Position = UDim2.new(1, -12, 0.5, 0)
anlaticiKap.Size = UDim2.fromOffset(ANLATICI, ANLATICI)
anlaticiKap.BackgroundColor3 = ISARET
-- Hafif altin zemin: karakter koyu seritte kaybolmasin
anlaticiKap.BackgroundTransparency = 0.82
anlaticiKap.BorderSizePixel = 0
anlaticiKap.ZIndex = 7
anlaticiKap.Visible = false
anlaticiKap.Parent = serit
UI.corner(anlaticiKap, 1000)
UI.stroke(anlaticiKap, ISARET, 3)

local anlaticiResim = Instance.new("ImageLabel")
anlaticiResim.Name = "Resim"
anlaticiResim.AnchorPoint = Vector2.new(0.5, 0.5)
anlaticiResim.Position = UDim2.fromScale(0.5, 0.5)
-- Yuvarlagin icinde kalacak kadar: kose kose tasmasin
anlaticiResim.Size = UDim2.fromScale(0.74, 0.74)
anlaticiResim.BackgroundTransparency = 1
-- Fit: en-boy orani bozulmadan kutuya sigar
anlaticiResim.ScaleType = Enum.ScaleType.Fit
anlaticiResim.ZIndex = 8
anlaticiResim.Parent = anlaticiKap

do
	-- Hafif sallanma
	TweenService:Create(
		anlaticiKap,
		TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Rotation = 4 }
	):Play()
	anlaticiKap.Rotation = -4
end

--[[
	Adim icin anlatici resmini bulur.

	Once Assets > Icons icinde ADI BIREBIR tutan (assetTam), sonra adi
	ICEREN (asset) aranir. Bulunamazsa Output'a bir kez yazilir ve serit
	resimsiz gorunur -- ogretici yine calisir.
]]
local anlaticiOnbellek: { [string]: string } = {}
local anlaticiUyarildi: { [string]: boolean } = {}

local function anlaticiBul(anahtar: string): string?
	local hazir = anlaticiOnbellek[anahtar]
	if hazir then
		return hazir
	end

	local adaylar = Adimlar.Anlaticilar[anahtar]
	if not adaylar then
		return nil
	end

	for _, ad in adaylar do
		local resim = Icons.assetTam(ad) or Icons.asset(ad)
		if resim then
			anlaticiOnbellek[anahtar] = resim
			return resim
		end
	end

	if not anlaticiUyarildi[anahtar] then
		anlaticiUyarildi[anahtar] = true
		warn(
			`[Ogretici] Anlatici resmi yok: ReplicatedStorage > Assets > Icons icine `
				.. `"{table.concat(adaylar, "\" / \"")}" adlarindan biriyle koy.`
		)
	end
	return nil
end

local function anlaticiyiCiz(adim: Adimlar.Adim?)
	local anahtar = if adim then adim.resim or "tesvik" else nil
	local resim = if anahtar then anlaticiBul(anahtar) else nil

	anlaticiResim.Image = resim or ""
	anlaticiResim.Visible = resim ~= nil
end

local sayacYazi = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = ISARET,
	align = Enum.TextXAlignment.Left,
	frameSize = UDim2.new(1, -(YAZI_SOL + YAZI_SAG), 0, 18),
	position = UDim2.fromOffset(YAZI_SOL, 8),
	parent = serit,
	zIndex = 5,
})

local yonergeYazi = UI.text({
	text = "",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Left,
	frameSize = UDim2.new(1, -(YAZI_SOL + YAZI_SAG), 0, 30),
	position = UDim2.fromOffset(YAZI_SOL, 26),
	parent = serit,
	zIndex = 5,
})

local altYazi = UI.text({
	text = "",
	size = UI.Sizes.tiny,
	color = Color3.fromRGB(205, 210, 225),
	align = Enum.TextXAlignment.Left,
	frameSize = UDim2.new(1, -(YAZI_SOL + YAZI_SAG), 0, 18),
	position = UDim2.fromOffset(YAZI_SOL, 58),
	parent = serit,
	zIndex = 5,
})

------------------------------------------------------------------
-- HEDEF ISARETI  --  parlama + tepesinde nabiz atan nokta
------------------------------------------------------------------
local parlama = Instance.new("Highlight")
parlama.Name = "OgreticiParlamasi"
parlama.FillColor = ISARET
parlama.FillTransparency = 0.72
parlama.OutlineColor = ISARET
parlama.OutlineTransparency = 0
-- Duvar arkasindan da gorunsun: oyuncu hedefi ararken kaybolmasin
parlama.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
parlama.Enabled = false
parlama.Parent = playerGui

local hedefTabela = Instance.new("BillboardGui")
hedefTabela.Name = "OgreticiHedefi"
hedefTabela.Size = UDim2.fromOffset(46, 46)
hedefTabela.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
hedefTabela.AlwaysOnTop = true
hedefTabela.Enabled = false
hedefTabela.Parent = playerGui

--[[
	Hedefin tepesinde YALNIZCA BIR NOKTA duruyor.

	Once iki cubuktan bir ok cizilmisti; asagi cevrilince ok gibi degil
	CARPI gibi gorunuyordu. Yonu zaten yerdeki cizgi gosteriyor, tepedeki
	isaretin tek isi "burasi" demek -- sade bir nokta yetiyor.
]]
local hedefNoktasi = Instance.new("Frame")
hedefNoktasi.Name = "Nokta"
hedefNoktasi.AnchorPoint = Vector2.new(0.5, 0.5)
hedefNoktasi.Position = UDim2.fromScale(0.5, 0.5)
hedefNoktasi.Size = UDim2.fromScale(0.62, 0.62)
hedefNoktasi.BackgroundColor3 = ISARET
hedefNoktasi.BorderSizePixel = 0
hedefNoktasi.Parent = hedefTabela
UI.corner(hedefNoktasi, 1000)
UI.stroke(hedefNoktasi, SIYAH, 3)

-- Nokta nabiz atar; UIScale bir GuiObject'in altinda olmali (BillboardGui degil)
local noktaOlcek = Instance.new("UIScale")
noktaOlcek.Parent = hedefNoktasi
TweenService:Create(
	noktaOlcek,
	TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Scale = 1.25 }
):Play()

--[[
	KIRMIZI PARLAMA  --  "buraya birak / buraya bas" adimlari

	Slot ve toplama butonu adimlarinda hedef SARI degil KIRMIZI parlar:
	oyuncu yerdeki kucuk bir parcayi ararken sari cizgiye degil, bariz
	kirmizi parlamaya baksin. Nabzi asagidaki dongu ayarliyor.
]]
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

--[[
	ARAYUZ HALKASI  --  ekrandaki bir dugmeyi cember icine alir

	2. adimda Detective penceresindeki "IDENTIFY ALL" dugmesi. Halka her
	karede dugmenin ekrandaki yerine oturuyor (dugme panelle birlikte
	kayabiliyor, arayuz olcegi degisebiliyor).

	KAP KENDI OLCEGINI TASIYOR: UI modulu her ScreenGui'nin ust duzey
	cocuklarina arayuz olcegini koyuyor. Halkanin olculeri zaten EKRAN
	PIKSELI (AbsolutePosition/AbsoluteSize) oldugu icin bir kez daha
	olceklenmemeli; kaba kendi UIScale'ini koyuyoruz ki modul ona
	dokunmasin (bkz. UI.luau > nesneyeUygula).
]]
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

-- Halkanin isaret edecegi dugme (yoksa halka gizli)
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

------------------------------------------------------------------
-- YOL CIZGISI  --  karakterden hedefe uzanan sari isin
------------------------------------------------------------------
--[[
	Basin ustunde donen bir ok yerine karakterle hedef ARASINDA bir Beam
	var: oyuncu gidecegi yonu cizginin uzandigi taraftan goruyor, kamerayi
	cevirip bir oku yorumlamasi gerekmiyor.

	Beam iki Attachment arasinda cizilir. Baslangic tutamagi karakterin
	govdesine, bitis tutamagi hedefe takiliyor; ikisi de burada, yani
	ISTEMCIDE olusturuldugu icin cizgiyi yalnizca bu oyuncu goruyor.
]]
local kokTutamak = Instance.new("Attachment")
kokTutamak.Name = "OgreticiBaslangic"

local hedefTutamak = Instance.new("Attachment")
hedefTutamak.Name = "OgreticiBitis"

local cizgi = Instance.new("Beam")
cizgi.Name = "OgreticiYolu"
cizgi.Attachment0 = kokTutamak
cizgi.Attachment1 = hedefTutamak
cizgi.Color = ColorSequence.new(ISARET)
-- Isik almasin, kendi parlasin: gecede ve golgede de ayni sarida kalir
cizgi.LightInfluence = 0
cizgi.LightEmission = 1
cizgi.FaceCamera = true
cizgi.Width0 = 0.55
cizgi.Width1 = 0.55
--[[
	Uclari soluk, ortasi parlak: cizgi karakterin ve hedefin uzerine
	yapisik durmasin, aralarindan geciyormus gibi gorunsun.
]]
cizgi.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.85),
	NumberSequenceKeypoint.new(0.15, 0.15),
	NumberSequenceKeypoint.new(0.85, 0.15),
	NumberSequenceKeypoint.new(1, 0.85),
})
-- Hafif kavis: dumduz bir cizgi zeminle ic ice girip kayboluyordu
cizgi.CurveSize0 = 6
cizgi.CurveSize1 = 6
cizgi.Enabled = false
cizgi.Parent = kokTutamak

------------------------------------------------------------------
-- HEDEF ARAMA
------------------------------------------------------------------

-- Adi bu olan ilk nesne (ic ice klasorler dahil)
--[[
	Karsilastirma icin ad: kucuk harf, bosluk/alt cizgi/tire yok.
	Haritadaki model "Fuse Machine" ya da "fuse_machine" diye adlandirilmis
	olabiliyor; ogretici yine de bulsun.
]]
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

	--[[
		Birebir ad tutmadi: buyuk/kucuk harf ve bosluk farkini yok sayarak,
		sonra da ADIN ICINDE gecmesine bakarak ara. Fuse makinesinin
		isaretlenmemesinin sebebi buydu.
	]]
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

--[[
	KUM HEDEFI ICIN GORUNMEZ BIR ISARET NOKTASI

	Kum plaji cogu zaman kocaman tek bir parca. Isaretleri dogrudan ona
	baglayinca nokta plajin ORTASINDA beliriyor ve parlama butun plaji
	sariya boyuyor; oyuncu uzaktayken de "en yakin kum" olarak NPC'lerin
	durdugu zemin parcasi secilip isaret dedektifin dibinde cikiyordu.

	Bunun yerine burada gorunmez bir parca var: kumun oyuncuya EN YAKIN
	noktasina tasiniyor ve isaretler ona baglaniyor.
]]
local kumIsareti = Instance.new("Part")
kumIsareti.Name = "OgreticiKumNoktasi"
kumIsareti.Size = Vector3.new(1, 1, 1)
kumIsareti.Transparency = 1
kumIsareti.Anchored = true
kumIsareti.CanCollide = false
kumIsareti.CanQuery = false
kumIsareti.CanTouch = false
kumIsareti.Parent = Workspace

--[[
	Parca bir karakterin ya da NPC'nin icinde mi.

	Dedektif, satici ve fuse makinesi kum zemininin uzerinde duruyor ve
	bazilarinin kendi tabani da kum. Oyuncu plajdan uzaklasinca en yakin
	kum olarak O taban secilip isaret NPC'nin dibinde cikiyordu.
]]
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

--[[
	Kazilabilir bir kum zemini mi.

	Tanim sunucudakiyle ayni (Config.Sand): Sand materyali ya da adinda
	"kum"/"sand" gecen bir Part. BOYUT VE SABITLIK SARTI YOK -- kum parcaya
	bolunmus olabilir. Tek eleme karakterlerin ve NPC'lerin kendi parcalari:
	bazilarinin tabani da kum ve oyuncu plajdan uzaklasinca "en yakin kum"
	olarak onlar secilip isaret NPC'nin dibinde cikiyordu.
]]
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

--[[
	Oyuncuya EN YAKIN kumun uzerindeki isaret noktasi.

	MESAFE SINIRI YOK: once bir yaricap vardi, oyuncu kumdan uzaklasinca
	isaret kayboluyordu. Ogreticinin isi zaten oyuncuyu oraya goturmek --
	uzaksa cizgi daha uzun olur, o kadar.
]]
--[[
	ISARETLENEN KUM PARCASI

	Kum adimlarinda cizgi gorunmez bir noktaya gidiyor (bkz. kumIsareti) ama
	PARLAMA plajin kendisine takiliyor: butun alan sari parliyor, oyuncu
	nereyi kazacagini uzaktan goruyor. kumBul her cagrildiginda buraya
	yaziyor.
]]
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

	--[[
		Parcanin UST yuzeyinde, oyuncunun tam karsisina gelen nokta: plajin
		merkezi degil, oyuncunun kosup varacagi kenari.
	]]
	local yerel = enYakin.CFrame:PointToObjectSpace(merkez)
	local yari = enYakin.Size / 2
	kumIsareti.Position = enYakin.CFrame:PointToWorldSpace(Vector3.new(
		math.clamp(yerel.X, -yari.X, yari.X),
		yari.Y,
		math.clamp(yerel.Z, -yari.Z, yari.Z)
	))

	return kumIsareti
end

--[[
	SUNUCUNUN VERDIGI KONUM

	Ilk kazida isaret kumun kenarina degil, oyuncu icin dogurulan GARANTI
	suzmeye gider; konumu sunucudan geliyor (bkz. Modules > Ogretici).
	Konum geldiginde kum isareti o noktaya tasinir, gerisi ayni: cizgi ve
	ucundaki nokta oraya bakar.
]]
local sunucuKonumu: Vector3? = nil

local function hedefiBul(tur: Adimlar.Hedef, kok: BasePart): Instance?
	local konum = sunucuKonumu
	if konum and tur == "kum" then
		--[[
			Ilk kazida cizgi garanti suzmeye gider; PARLAMA yine plaja
			takilsin diye kum parcasi ayrica aranir (kumBul onu yaziyor).
		]]
		kumBul(kok)
		kumIsareti.Position = konum
		return kumIsareti
	end

	if tur == "dedektif" then
		return modelBul({ Config.Detective.name })
	elseif tur == "fuse" then
		return modelBul({ Config.Fuse.machineName, Config.Fuse.machineAltName })
	elseif tur == "base" then
		local model = if baseIndex then modelBul({ Bases.baseName(baseIndex) }) else nil
		if not model then
			return nil
		end

		--[[
			BASE ADIMLARINDA HEDEF BASENIN KENDISI DEGIL, ISIN YAPILACAGI PARCA:
			  slot adimi -> 1. slot (oraya brainrot birakilacak)
			  para adimi -> ToplaButonu (ustune basilacak)
			Ikisi de bulunamazsa base modeline dusulur.
		]]
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

--[[
	Isaretlerin baglanacagi nesne ve parca.

	Highlight bir Model'e ya da BasePart'a, BillboardGui ile Attachment ise
	yalnizca bir BasePart'a baglanabiliyor. Model'in govdesi yoksa ikisi de
	nil doner ve cagiran taraf isaretleri kapatir.
]]
--[[
	Isaretlerin baglanacagi nesne ve tutunacak parca.

	PARCA DERIN ARANIR: Fuse makinesinin parcalari alt klasorlerde duruyor
	(Workspace.FuseMachine.Decor.Part). Yalnizca DOGRUDAN cocuklara bakan
	eski surumde kok parca bulunamiyor, fonksiyon sessizce nil donuyor ve
	7. adimda hicbir isaret cikmiyordu.
]]
local function baglanacak(node: Instance): (Instance?, BasePart?)
	if node:IsA("BasePart") then
		return node, node
	end
	if node:IsA("Model") then
		local kok = node.PrimaryPart or node:FindFirstChildWhichIsA("BasePart", true)
		return node, kok
	end
	-- Model bile degil (Folder gibi): icinde parca varsa ona baglanilir
	local kok = node:FindFirstChildWhichIsA("BasePart", true)
	return (if kok then node else nil), kok
end

------------------------------------------------------------------
-- GOSTERIM
------------------------------------------------------------------
local function isaretleriKapat()
	parlama.Enabled = false
	kirmiziParlama.Enabled = false
	kirmiziParlama.Adornee = nil
	halka.Visible = false
	hedefTabela.Enabled = false
	cizgi.Enabled = false
	hedef = nil
end

local function gizle()
	serit.Visible = false
	isaretleriKapat()
end

--[[
	ADA IPUCU  --  ogreticiden sonraki tek yonlendirme

	Sunucu, oyuncunun parasi ikinci adaya yetince IpucuAda niteligini
	yaziyor (bkz. Modules > Ogretici). O acikken serit "yeni ada alabilirsin"
	der ve Teleporter isaretlenir; ada alinip gidilince nitelik silinir,
	serit ve isaret kendiliginden kapanir.
]]
local IP = Adimlar.AdaIpucu
local KI = Adimlar.KurekIpucu

local function adaIpucuAcik(): boolean
	return player:GetAttribute(IP.nitelik) == true
end

local function kurekIpucuAcik(): boolean
	return player:GetAttribute(KI.nitelik) == true
end

--[[
	OGRETICI BITTIKTEN SONRA acik olan ipucu (yoksa nil). Sunucu ikisini
	ayni anda acmiyor; yine de kurek once geliyor cunku oyunun sirasi o.

	Serit ve isaret ayni secimi kullansin diye tek yerde duruyor.
]]
local function ipucuOf(): ({ [string]: any }?, string?)
	if kurekIpucuAcik() then
		return KI :: any, "FIRST SHOVEL"
	elseif adaIpucuAcik() then
		return IP :: any, "NEW ISLAND"
	end
	return nil, nil
end

local function yonergeyiYaz()
	--[[
		Ogretici bittiyse yalnizca ipuclari kalir: adim yazisi yerine
		ipucunun kendi yazisi gosterilir.
	]]
	if bitti or siraNo <= 0 then
		local ipucu, baslik = ipucuOf()
		if ipucu then
			sayacYazi.Text = baslik or ""
			yonergeYazi.Text = ipucu.yazi
			altYazi.Text = ipucu.alt or ""
			anlaticiyiCiz({ resim = ipucu.resim } :: any)
			serit.Visible = true
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

	sayacYazi.Text = `STEP {siraNo} / {toplamAdim}`
	yonergeYazi.Text = adim.yazi
	altYazi.Text = adim.alt or ""
	-- Adimin anlatici resmi (bkz. Shared > Ogretici > Anlaticilar)
	anlaticiyiCiz(adim)
	serit.Visible = true
end

--[[
	Hedefi arar ve isaretleri ona baglar.

	Her saniye cagriliyor: hedef bulunamamis olabilir (harita gec yuklenir),
	oyuncu baska adaya gecmis olabilir (en yakin kum degisir), base yeni
	atanmis olabilir.

	HER CIKIS YOLU ISARETLERI KAPATIYOR. Eskiden "hedef bulundu ama
	baglanacak bir parcasi yok" durumunda fonksiyon sessizce donuyordu ve
	ONCEKI adimin isareti ekranda kaliyordu: kum gosterilmesi gerekirken
	dedektif, fuse gosterilmesi gerekirken yine dedektif parliyordu.
]]
local function hedefiTazele()
	--[[
		Ogretici bitti: kurek ipucu aciksa KUREK MAGAZASI, ada ipucu aciksa
		TELEPORTER isaretlenir; ikisi de kapaliysa hicbir sey.
	]]
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

		--[[
			Kurek ipucunun hedefi listeden geliyor (Magaza betigiyle ayni
			adlar); ada ipucununki Teleporter NPC'si.
		]]
		local npc = modelBul(
			if kurekIpucuAcik() then KI.modeller else { Config.NPC.name, Config.NPC.altName }
		)
		if not npc then
			return
		end

		--[[
			IF-IFADESI IKI DEGER DONDURMEZ: baglanacak iki sey donduruyor,
			"if ... then baglanacak(npc) else nil" yazilsaydi ikincisi
			kaybolur ve isaret hic kurulmazdi.
		]]
		local adornee, isaretKoku = baglanacak(npc)
		if not adornee or not isaretKoku then
			return
		end

		hedef = npc
		parlama.Adornee = adornee
		parlama.Enabled = true
		hedefTabela.Adornee = isaretKoku
		hedefTabela.Enabled = true
		kokTutamak.Parent = kok
		hedefTutamak.Parent = isaretKoku
		cizgi.Enabled = true
		return
	end

	--[[
		HER TAZELEMEDE ONCE TEMIZLE.

		Eskiden isaretler yalnizca "hedef bulunamadi" dallarinda kapatiliyordu
		ve arada bir dal gozden kacinca ONCEKI adimin hedefi ekranda kaliyordu:
		yonerge "Dig in the sand!" derken cizgi hala dedektife gidiyordu.

		Simdi her tazeleme bos bir sayfayla basliyor. Hedef bulunursa ayni
		karede yeniden aciliyor, bulunamazsa hicbir sey gorunmuyor -- yanlis
		hedef gostermek imkansiz.
	]]
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

	--[[
		TESHIS: hangi adimda neyin isaretlendigi Output'a bir kez dusuyor.
		Adim ya da hedef degismedikce tekrar yazmiyor. "Kum kaz" derken
		dedektifin isaretlenmesi gibi bir durum olursa sebebi buradan
		gorulebilsin diye.
	]]
	local imza = `{siraNo}|{adim.hedef}|{bulunan:GetFullName()}`
	if imza ~= sonTeshis then
		sonTeshis = imza
		print(`[Ogretici] adim {siraNo} ({adim.hedef}) -> {bulunan:GetFullName()}`)
	end

	--[[
		KUM HEDEFINDE PARLAMA YOK: isaret gorunmez bir noktaya bagli, onu
		parlatmanin anlami yok. Kum adiminda yol gosteren sey cizgi ve
		ucundaki nokta.
	]]
	--[[
		KUM ADIMINDA OYUNCU ZATEN ORADAYSA ISARET KAPANIR

		"Uc tane ayni kademe kaz" adiminda oyuncu kumun uzerinde gezerken
		sari cizgi pesini birakmiyordu. Artik kum isaretine yaklasinca
		isaretler kapaniyor, alandan cikinca geri geliyor.

		Ilk kazi bunun DISINDA: orada isaret oyuncunun yanindaki garanti
		suzmeyi gosteriyor (sunucudan konum geliyor), kapanmamali.
	]]
	if adim.hedef == "kum" and not sunucuKonumu then
		if (kok.Position - kumIsareti.Position).Magnitude <= KUM_YAKINLIK then
			isaretleriKapat()
			return
		end
	end

	--[[
		KIRMIZI ADIMLAR: slot ve para. Yerdeki kucuk parca bariz gorunsun
		diye sari yerine kirmizi parlar (bkz. kirmiziParlama).
	]]
	local kirmiziMi = adim.id == "slot" or adim.id == "para"

	kirmiziParlama.Adornee = if kirmiziMi then adornee else nil
	kirmiziParlama.Enabled = kirmiziMi

	--[[
		KUM ADIMINDA PLAJIN TAMAMI SARI PARLAR

		Isaret noktasi gorunmez oldugu icin parlama ONA degil, altindaki kum
		parcasina takiliyor. Cizgi ve nokta yine hedefi (ilk kazida garanti
		suzmeyi) gosteriyor; parlama "kazi alani burasi" diyor.
	]]
	local sariAdornee: Instance? = if adim.hedef == "kum" then kumParcasi else adornee

	parlama.Adornee = if not kirmiziMi then sariAdornee else nil
	parlama.Enabled = not kirmiziMi and sariAdornee ~= nil

	hedefTabela.Adornee = isaretKoku
	hedefTabela.Enabled = true

	-- Cizginin iki ucu: karakterin govdesinde ve hedefin govdesinde
	kokTutamak.Parent = kok
	hedefTutamak.Parent = isaretKoku
	cizgi.Enabled = true
end

------------------------------------------------------------------
-- SUNUCU
------------------------------------------------------------------
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
		-- Ogretici bitti ama ada ipucu acik olabilir
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

--[[
	Karakter yeniden dogunca cizginin baslangic tutamagi eski govdeyle
	birlikte siliniyor. Isaretler kapatiliyor; asagidaki dongu bir saniye
	icinde hepsini yeni govdeye baglayacak.
]]
player.CharacterAdded:Connect(isaretleriKapat)

--[[
	Hedef aramasi saniyede bir. Her karede butun Workspace'i taramak pahali
	ve gereksiz: hedefler yerinde duruyor, degisen sey oyuncunun nerede
	oldugu.
]]
task.spawn(function()
	while true do
		task.wait(1)
		-- Ogretici bittiyse de calisir: ada ipucu Teleporter'i isaretliyor
		hedefiTazele()
	end
end)

-- Ipucu acilip kapandikca serit ve isaret aninda guncellensin
player:GetAttributeChangedSignal(IP.nitelik):Connect(function()
	yonergeyiYaz()
	hedefiTazele()
end)

--[[
	HER KARE: arayuz halkasini dugmenin ustunde tut, kirmizi parlamayi
	ve halkayi nabizlandir. Ogretici bittiyse ilk satirda cikar.
]]
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
		--[[
			Halka dugmeyi cember icine alir: en uzun kenarindan biraz genis
			bir daire. Konum ekran pikseli; kabin ust cubuk boslugu ayni
			oldugu icin AbsolutePosition dogrudan kullanilabiliyor.
		]]
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

--[[
	DURUM GELENE KADAR SOR.

	Sunucudaki kayit oyuncu girer girmez hazir olmuyor (DataStore okumasi);
	tek bir istek yuklemeden once giderse cevapsiz kalir ve ogretici hic
	baslamazdi. Cevap gelince dongu kendiliginden duruyor.
]]
task.spawn(function()
	for _ = 1, 20 do
		if cevapGeldi then
			return
		end
		OgreticiIste:FireServer()
		task.wait(1.5)
	end
end)
