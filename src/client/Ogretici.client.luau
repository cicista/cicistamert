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
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("OyunConfig"))
local Bases = require(Shared:WaitForChild("Bases"))
local Adimlar = require(Shared:WaitForChild("Ogretici"))

local UI = require(script.Parent:WaitForChild("UI"))

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
-- XP barinin altinda: ust seridi ortmesin
serit.Position = UDim2.new(0.5, 0, 0, 92)
serit.Size = UDim2.fromOffset(460, 74)
serit.BackgroundColor3 = Color3.fromRGB(28, 26, 40)
serit.BorderSizePixel = 0
serit.Visible = false
serit.Parent = ekran
UI.corner(serit, 14)
UI.stroke(serit, ISARET, 3)
UI.caprazDesen(serit, ISARET, 3)

local sayacYazi = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = ISARET,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 18),
	position = UDim2.fromOffset(10, 6),
	parent = serit,
	zIndex = 5,
})

local yonergeYazi = UI.text({
	text = "",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	color = BEYAZ,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 28),
	position = UDim2.fromOffset(10, 24),
	parent = serit,
	zIndex = 5,
})

local altYazi = UI.text({
	text = "",
	size = UI.Sizes.tiny,
	color = Color3.fromRGB(205, 210, 225),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 18),
	position = UDim2.fromOffset(10, 52),
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
local function modelBul(adlar: { string }): Instance?
	for _, ad in adlar do
		local dogrudan = Workspace:FindFirstChild(ad, true)
		if dogrudan then
			return dogrudan
		end
	end
	return nil
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

local function hedefiBul(tur: Adimlar.Hedef, kok: BasePart): Instance?
	if tur == "dedektif" then
		return modelBul({ Config.Detective.name })
	elseif tur == "fuse" then
		return modelBul({ Config.Fuse.machineName, Config.Fuse.machineAltName })
	elseif tur == "base" then
		return if baseIndex then modelBul({ Bases.baseName(baseIndex) }) else nil
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
local function baglanacak(node: Instance): (Instance?, BasePart?)
	if node:IsA("BasePart") then
		return node, node
	end
	if node:IsA("Model") then
		local kok = node.PrimaryPart or node:FindFirstChildWhichIsA("BasePart")
		return node, kok
	end
	return nil, nil
end

------------------------------------------------------------------
-- GOSTERIM
------------------------------------------------------------------
local function isaretleriKapat()
	parlama.Enabled = false
	hedefTabela.Enabled = false
	cizgi.Enabled = false
	hedef = nil
end

local function gizle()
	serit.Visible = false
	isaretleriKapat()
end

local function yonergeyiYaz()
	local adim = Adimlar.adim(siraNo)
	if not adim then
		serit.Visible = false
		return
	end

	sayacYazi.Text = `STEP {siraNo} / {toplamAdim}`
	yonergeYazi.Text = adim.yazi
	altYazi.Text = adim.alt or ""
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
	if bitti or siraNo <= 0 then
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
	local parlamali = adim.hedef ~= "kum"
	parlama.Adornee = if parlamali then adornee else nil
	parlama.Enabled = parlamali

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
	siraNo = math.floor(tonumber(veri.adim) or 0)
	bitti = veri.bitti == true
	toplamAdim = math.floor(tonumber(veri.toplam) or Adimlar.adimSayisi())

	if bitti then
		gizle()
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
		if not bitti and siraNo > 0 then
			hedefiTazele()
		end
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
