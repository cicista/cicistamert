--!strict
--[[
	HOTBAR  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Hotbar

	Roblox'un KENDI hotbar'inin yerini alan cubuk.

	NEDEN KENDIMIZ CIZIYORUZ
	Roblox'un hotbar'i bir Tool'un ya IKONUNU (Tool.TextureId) ya da ADINI
	gosterir, ikisini birden degil. Parsomenin adinda adet yaziyor
	("Hacker Mutation Scroll x3") ama ikonu oldugu icin o ad hic gorunmuyor;
	ikonun uzerine rozet basmanin da yolu yok. Adet rozeti isteniyorsa
	cubugu kendimiz cizmekten baska secenek kalmiyor.

	NE YAPIYOR
	  - Alt ortada 10 yuva; 1..9 ve 0 tuslari o yuvayi kusanir/birakir
	  - Yuvaya tiklamak da ayni sey
	  - Ikon: Tool.TextureId varsa o, yoksa Tool'un KENDI modeli kucuk bir
	    ViewportFrame'de (parsomen, lucky block, brainrot burada gorunur)
	  - Sag alt kosede ADET rozeti: "x3" (bkz. ADET NITELIGI)
	  - Yuvaya sigmayan esyalar "..." dugmesindeki cekmecede

	YUVA SIRASI SABIT
	Bir esya bir kez yuva aldi mi, kusanilip birakilsa da o yuvada kalir.
	Kusanilan Tool Backpack'ten cikip karaktere tasindigi icin her
	degisiklikte yeniden dagitsaydik esyalar yuva degistirip dururdu.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
-- Siralama icin: brainrotun degeri ve kademe sirasi
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Scrolls = require(Shared:WaitForChild("Scrolls"))

local UI = require(script.Parent:WaitForChild("UI"))

------------------------------------------------------------------
-- OLCULER
------------------------------------------------------------------
local SLOT_SAYISI = 10
local SLOT_BOY = 62
local SLOT_ARA = 6
-- Cubugun ekranin altindan yuksekligi
local ALT_PAY = 14

--[[
	Tuslar yuva sirasiyla: 1..9 sonra 0. Roblox'un kendi hotbar'inda da
	boyle.
]]
local TUSLAR = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
	Enum.KeyCode.Zero,
}

------------------------------------------------------------------
-- ROBLOX'UN HOTBAR'INI KAPAT
------------------------------------------------------------------
--[[
	Ilk karelerde CoreGui cagrilari reddedilebiliyor; basarana kadar
	deneniyor (Sistem.client'taki ayni kalip).
]]
task.spawn(function()
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		if ok then
			return
		end
		task.wait(0.25)
	end
end)

------------------------------------------------------------------
-- EKRAN
------------------------------------------------------------------
local ekran = Instance.new("ScreenGui")
ekran.Name = "Hotbar"
-- XP barinin (0) ustunde, menu butonlarinin (5) altinda
ekran.DisplayOrder = 3
ekran.ResetOnSpawn = false
ekran.IgnoreGuiInset = true
ekran.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ekran.Parent = playerGui

--[[
	KOK CERCEVE  --  cubuk + cekmece dugmesi birlikte

	Ikisi ayni kapta duruyor ki DAR EKRANDA birlikte kuculsunler: on yuva
	yan yana 670 piksel tutuyor, telefonda ekrana sigmiyor. Asagidaki
	UIScale kabin tamamini kucultuyor, yani yuvalar da dugme de ayni oranda
	kuculuyor ve aralari bozulmuyor.
]]
local CUBUK_EN = SLOT_SAYISI * (SLOT_BOY + SLOT_ARA) - SLOT_ARA
local CEKMECE_EN = 34

--[[
	BOS YUVA YER KAPLAMAZ

	Cubuk artik sabit 10 yuva genisliginde degil: dolu yuva kadar. Bos
	yuvalar Visible = false yapiliyor ve UIListLayout gorunmeyen cocugu
	saymadigi icin cubuk kendiliginden daraliyor, kalanlar ortada topluyor.

	Bu yuzden genislikler AutomaticSize ile olculuyor; kok da cubugu ve
	cekmece dugmesini yan yana tutan bir liste.
]]
local kok = Instance.new("Frame")
kok.Name = "HotbarKok"
kok.AnchorPoint = Vector2.new(0.5, 1)
kok.Position = UDim2.new(0.5, 0, 1, -ALT_PAY)
kok.Size = UDim2.fromOffset(0, SLOT_BOY)
kok.AutomaticSize = Enum.AutomaticSize.X
kok.BackgroundTransparency = 1
kok.Parent = ekran

local kokDizilim = Instance.new("UIListLayout")
kokDizilim.FillDirection = Enum.FillDirection.Horizontal
kokDizilim.Padding = UDim.new(0, SLOT_ARA)
kokDizilim.SortOrder = Enum.SortOrder.LayoutOrder
kokDizilim.HorizontalAlignment = Enum.HorizontalAlignment.Center
kokDizilim.VerticalAlignment = Enum.VerticalAlignment.Bottom
kokDizilim.Parent = kok

local kokOlcek = Instance.new("UIScale")
kokOlcek.Parent = kok

--[[
	Dar ekranda cubuk kuculur. Olcu kokun AbsoluteSize'indan alinamaz --
	UIScale onu zaten carpiyor, geri besleme olusur. Onun yerine gorunen
	yuva sayisindan HESAPLANIYOR.
]]
local gorunenYuva = 0
local cekmeceAcikMi = false

local function olcegiTazele()
	local en = ekran.AbsoluteSize.X
	if en <= 0 then
		return
	end

	local icerik = math.max(1, gorunenYuva) * (SLOT_BOY + SLOT_ARA) - SLOT_ARA
	if cekmeceAcikMi then
		icerik += SLOT_ARA + CEKMECE_EN
	end

	-- Iki yanda 16'sar piksel pay kalsin
	kokOlcek.Scale = math.clamp((en - 32) / icerik, 0.5, 1)
end

ekran:GetPropertyChangedSignal("AbsoluteSize"):Connect(olcegiTazele)

local cubuk = Instance.new("Frame")
cubuk.Name = "Cubuk"
cubuk.LayoutOrder = 1
cubuk.Size = UDim2.fromOffset(0, SLOT_BOY)
cubuk.AutomaticSize = Enum.AutomaticSize.X
cubuk.BackgroundTransparency = 1
cubuk.Parent = kok

local dizilim = Instance.new("UIListLayout")
dizilim.FillDirection = Enum.FillDirection.Horizontal
dizilim.Padding = UDim.new(0, SLOT_ARA)
dizilim.SortOrder = Enum.SortOrder.LayoutOrder
dizilim.HorizontalAlignment = Enum.HorizontalAlignment.Center
dizilim.VerticalAlignment = Enum.VerticalAlignment.Bottom
dizilim.Parent = cubuk

--[[
	IKON HAVUZU

	Uretilen ViewportFrame'ler burada saklaniyor. Esya yuva degistirince
	ikon YENIDEN KURULMUYOR, yalnizca yeni yuvaya tasiniyor: her tazelemede
	10 tane viewport kurmak goze carpan bir takilma yapiyordu.
]]
local havuz = Instance.new("Frame")
havuz.Name = "IkonHavuzu"
havuz.Size = UDim2.fromOffset(0, 0)
havuz.BackgroundTransparency = 1
havuz.Visible = false
havuz.Parent = ekran

------------------------------------------------------------------
-- YUVALAR
------------------------------------------------------------------
type Yuva = {
	kap: TextButton,
	ikonKap: Frame,
	yazi: TextLabel,
	adet: TextLabel,
	numara: TextLabel,
	kenar: UIStroke,
}

local yuvalar: { Yuva } = {}

-- Yuva -> Tool ve Tool -> yuva (ikisi de tek kaynaktan yazilir)
local yuvaninEsyasi: { [number]: Tool } = {}
local esyaninYuvasi: { [Tool]: number } = {}

-- Tool -> onun ikonu (havuzda ya da bir yuvada)
local ikonlar: { [Tool]: GuiObject } = {}
-- Tool -> ad/adet degisimini dinleyen baglantilar
local baglantilar: { [Tool]: { RBXScriptConnection } } = {}

local function yuvaKur(sira: number): Yuva
	local kap = Instance.new("TextButton")
	kap.Name = `Yuva{sira}`
	kap.LayoutOrder = sira
	kap.Size = UDim2.fromOffset(SLOT_BOY, SLOT_BOY)
	kap.BackgroundColor3 = Color3.fromRGB(26, 28, 34)
	kap.BackgroundTransparency = 0.25
	kap.BorderSizePixel = 0
	kap.AutoButtonColor = false
	kap.Text = ""
	kap.Parent = cubuk
	UI.corner(kap, 10)

	local kenar = UI.stroke(kap, Color3.fromRGB(0, 0, 0), 2)

	-- Ikonun oturdugu alan: yuvanin numara ve rozet paylari disinda kalani
	local ikonKap = Instance.new("Frame")
	ikonKap.Name = "Ikon"
	ikonKap.AnchorPoint = Vector2.new(0.5, 0.5)
	ikonKap.Position = UDim2.fromScale(0.5, 0.5)
	ikonKap.Size = UDim2.fromOffset(SLOT_BOY - 12, SLOT_BOY - 12)
	ikonKap.BackgroundTransparency = 1
	ikonKap.ZIndex = 2
	ikonKap.Parent = kap

	--[[
		IKON YOKSA AD YAZAR. Roblox'un hotbar'i da boyle yapiyordu; ikonu
		olmayan esyalarda (kimligi acilmamis brainrot gibi) yazi kaliyor.
	]]
	local yazi = UI.text({
		text = "",
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(235, 238, 245),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -6, 1, -14),
		position = UDim2.fromOffset(3, 7),
		parent = kap,
		zIndex = 3,
		name = "Ad",
	})
	yazi.TextWrapped = true

	-- Sol ust: tus numarasi
	local numara = UI.text({
		text = if sira == 10 then "0" else tostring(sira),
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(180, 188, 200),
		align = Enum.TextXAlignment.Left,
		outline = false,
		frameSize = UDim2.fromOffset(16, 14),
		position = UDim2.fromOffset(5, 3),
		parent = kap,
		zIndex = 4,
		name = "Numara",
	})

	--[[
		SAG ALT: ADET ROZETI  --  bu cubugun butun sebebi.
		Tek tane olan esyada gizli; "x3", "x12" diye yazar.
	]]
	local adet = UI.text({
		text = "",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(255, 226, 120),
		align = Enum.TextXAlignment.Right,
		frameSize = UDim2.fromOffset(SLOT_BOY - 10, 18),
		position = UDim2.new(1, -(SLOT_BOY - 6), 1, -20),
		parent = kap,
		zIndex = 5,
		name = "Adet",
	})
	UI.stroke(adet, Color3.fromRGB(0, 0, 0), 3)

	return {
		kap = kap,
		ikonKap = ikonKap,
		yazi = yazi,
		adet = adet,
		numara = numara,
		kenar = kenar,
	}
end

for sira = 1, SLOT_SAYISI do
	yuvalar[sira] = yuvaKur(sira)
end

------------------------------------------------------------------
-- ESYA BILGISI
------------------------------------------------------------------
--[[
	ADET NITELIGI

	Sunucu adedi hem Tool adina hem "Adet" niteligine yaziyor (bkz.
	ServerScriptService > Modules > Tools). Nitelik yoksa adin sonundaki
	"x3" ya da "(3)" okunuyor -- eski kayitlardan gelen ya da elle konmus
	Tool'lar da rozet gostersin.
]]
local function adetOf(tool: Tool): number
	local nitelik = tool:GetAttribute(Assets.CountAttribute)
	if type(nitelik) == "number" and nitelik > 0 then
		return math.floor(nitelik)
	end

	local xli = string.match(tool.Name, "x(%d+)%s*$")
	if xli then
		return tonumber(xli) or 1
	end

	local parantezli = string.match(tool.Name, "%((%d+)%)%s*$")
	if parantezli then
		return tonumber(parantezli) or 1
	end

	return 1
end

--[[
	Rozetin yaninda duracak ad: sondaki adet ekini atar, cunku adet zaten
	rozette yaziyor ("Hacker Mutation Scroll x3" -> "Hacker Mutation Scroll").
]]
local function adOf(tool: Tool): string
	local ad = string.gsub(tool.Name, "%s*x%d+%s*$", "")
	ad = string.gsub(ad, "%s*%(%d+%)%s*$", "")
	return ad
end

--[[
	ESYANIN IKONU

	Once Tool.TextureId (kurek, gps, olta). Yoksa Tool'un KENDI modeli
	kucuk bir ViewportFrame'de -- parsomen, lucky block ve brainrotlar
	boyle gorunuyor. Ikisi de olmazsa nil doner ve yuvada ad yazar.

	UI.modelKaresi verilen nesneyi TUKETIYOR (parcalari alip aslini
	siliyor), o yuzden Tool'un KOPYASI veriliyor.
]]
local function ikonOf(tool: Tool): GuiObject?
	local var = ikonlar[tool]
	if var and var.Parent then
		return var
	end

	--[[
		LUCKY BLOCK'TA IKON YOK, AD VAR.

		Paketteki blok modeli bu boyutta okunakli bir ikon vermiyor; hangi
		blok oldugu ancak adindan anlasiliyor. nil dondurunce yuva adi
		yaziyor (bkz. yuvayiCiz).
	]]
	if tool:GetAttribute("LuckyBlock") then
		return nil
	end

	if tool.TextureId ~= "" then
		local resim = Instance.new("ImageLabel")
		resim.Name = "Resim"
		resim.Size = UDim2.fromScale(1, 1)
		resim.BackgroundTransparency = 1
		resim.ScaleType = Enum.ScaleType.Fit
		resim.Image = tool.TextureId
		resim.ZIndex = 3
		resim.Parent = havuz
		ikonlar[tool] = resim
		return resim
	end

	if not tool:FindFirstChildWhichIsA("BasePart", true) then
		return nil
	end

	local kopya = tool:Clone()
	local kare = UI.modelKaresi(havuz, kopya, SLOT_BOY - 12, 3)
	if not kare then
		return nil
	end

	kare.AnchorPoint = Vector2.new(0.5, 0.5)
	kare.Position = UDim2.fromScale(0.5, 0.5)
	ikonlar[tool] = kare
	return kare
end

local function ikonuBirak(tool: Tool)
	local ikon = ikonlar[tool]
	if ikon then
		ikon:Destroy()
		ikonlar[tool] = nil
	end
	for _, baglanti in baglantilar[tool] or {} do
		baglanti:Disconnect()
	end
	baglantilar[tool] = nil
end

------------------------------------------------------------------
-- CIZIM
------------------------------------------------------------------
local karakter: Model? = nil

local function kusanilmisMi(tool: Tool): boolean
	return karakter ~= nil and tool.Parent == karakter
end

local function yuvayiCiz(sira: number)
	local yuva = yuvalar[sira]
	local tool = yuvaninEsyasi[sira]

	--[[
		BOS YUVA GIZLENIR. UIListLayout gorunmeyeni saymadigi icin cubuk
		o kadar daralir; ekranin altinda bomboş kutular durmaz.
	]]
	if not tool then
		yuva.kap.Visible = false
		yuva.yazi.Text = ""
		yuva.adet.Text = ""
		return
	end

	yuva.kap.Visible = true

	local ikon = ikonOf(tool)
	if ikon then
		ikon.Parent = yuva.ikonKap
		yuva.yazi.Text = ""
	else
		yuva.yazi.Text = adOf(tool)
	end

	local adet = adetOf(tool)
	yuva.adet.Text = if adet > 1 then `x{adet}` else ""

	-- Kusanilmis esya: zemin acilir, kenar sari
	local acik = kusanilmisMi(tool)
	yuva.kap.BackgroundTransparency = if acik then 0.05 else 0.25
	yuva.kenar.Color = if acik then Color3.fromRGB(255, 214, 60) else Color3.fromRGB(0, 0, 0)
	yuva.kenar.Thickness = if acik then 3 else 2
	yuva.numara.TextTransparency = 0
end

local function hepsiniCiz()
	gorunenYuva = 0
	for sira = 1, SLOT_SAYISI do
		yuvayiCiz(sira)
		if yuvaninEsyasi[sira] then
			gorunenYuva += 1
		end
	end
	olcegiTazele()
end

------------------------------------------------------------------
-- CEKMECE  (yuvaya sigmayanlar)
------------------------------------------------------------------
local cekmeceDugme = Instance.new("TextButton")
cekmeceDugme.Name = "Cekmece"
cekmeceDugme.LayoutOrder = 2
cekmeceDugme.Size = UDim2.fromOffset(CEKMECE_EN, SLOT_BOY)
cekmeceDugme.BackgroundColor3 = Color3.fromRGB(26, 28, 34)
cekmeceDugme.BackgroundTransparency = 0.25
cekmeceDugme.BorderSizePixel = 0
cekmeceDugme.AutoButtonColor = false
cekmeceDugme.Text = "..."
cekmeceDugme.TextColor3 = Color3.fromRGB(230, 234, 242)
cekmeceDugme.TextSize = 22
cekmeceDugme.FontFace = UI.Fonts.bold
cekmeceDugme.Visible = false
cekmeceDugme.Parent = kok
UI.corner(cekmeceDugme, 10)
UI.stroke(cekmeceDugme, Color3.fromRGB(0, 0, 0), 2)
UI.hover(cekmeceDugme)

local cekmece = Instance.new("Frame")
cekmece.Name = "CekmecePaneli"
cekmece.AnchorPoint = Vector2.new(0.5, 1)
cekmece.Position = UDim2.new(0.5, 0, 1, -(ALT_PAY + SLOT_BOY + 10))
-- Dar ekranda daralir, genis ekranda cubukla ayni eni gecmez
cekmece.Size = UDim2.new(1, -32, 0, 150)
cekmece.BackgroundColor3 = Color3.fromRGB(20, 22, 27)
cekmece.BackgroundTransparency = 0.12
cekmece.BorderSizePixel = 0
cekmece.Visible = false
cekmece.Parent = ekran
UI.corner(cekmece, 12)
UI.stroke(cekmece, Color3.fromRGB(0, 0, 0), 2)

local cekmeceSinir = Instance.new("UISizeConstraint")
cekmeceSinir.MaxSize = Vector2.new(CUBUK_EN, 150)
cekmeceSinir.Parent = cekmece

local cekmeceListe = Instance.new("ScrollingFrame")
cekmeceListe.Name = "Liste"
cekmeceListe.Position = UDim2.fromOffset(8, 8)
cekmeceListe.Size = UDim2.new(1, -16, 1, -16)
cekmeceListe.BackgroundTransparency = 1
cekmeceListe.BorderSizePixel = 0
cekmeceListe.ScrollBarThickness = 5
cekmeceListe.CanvasSize = UDim2.new()
cekmeceListe.AutomaticCanvasSize = Enum.AutomaticSize.Y
cekmeceListe.Parent = cekmece

local cekmeceDizilim = Instance.new("UIListLayout")
cekmeceDizilim.Padding = UDim.new(0, 4)
cekmeceDizilim.SortOrder = Enum.SortOrder.LayoutOrder
cekmeceDizilim.Parent = cekmeceListe

------------------------------------------------------------------
-- KUSANMA
------------------------------------------------------------------
local function esyaSec(tool: Tool?)
	if not tool then
		return
	end

	local govde = karakter
	local humanoid = govde and govde:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if kusanilmisMi(tool) then
		humanoid:UnequipTools()
	else
		humanoid:EquipTool(tool)
	end
end

for sira = 1, SLOT_SAYISI do
	yuvalar[sira].kap.Activated:Connect(function()
		esyaSec(yuvaninEsyasi[sira])
	end)
end

UserInputService.InputBegan:Connect(function(girdi, islendi)
	if islendi then
		return
	end
	for sira, tus in TUSLAR do
		if girdi.KeyCode == tus then
			esyaSec(yuvaninEsyasi[sira])
			return
		end
	end
end)

------------------------------------------------------------------
-- ESYA LISTESI
------------------------------------------------------------------
--[[
	TAZELEME TEK YERDEN

	Backpack ve karakterdeki butun Tool'lar taranip yuvalar guncelleniyor.
	Tek tek ChildAdded/ChildRemoved islenseydi KUSANMA sorun olurdu: esya
	Backpack'ten cikip karaktere giriyor, yani "silindi" gibi gorunuyor.
	Taramada ikisi de ayni torbada oldugu icin oyle bir an hic olusmuyor.

	Cagrilar bir kareye toplanir: on tane esya ayni anda gelince (giris
	anindaki envanter yuklemesi) tarama on kez degil bir kez calisir.
]]
local tazelemeBekliyor = false

local function esyalariTopla(): { Tool }
	local liste: { Tool } = {}

	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, node in backpack:GetChildren() do
			if node:IsA("Tool") then
				table.insert(liste, node)
			end
		end
	end

	if karakter then
		for _, node in karakter:GetChildren() do
			if node:IsA("Tool") then
				table.insert(liste, node)
			end
		end
	end

	return liste
end

--[[
	CEKMECE HER TAZELEMEDE YENIDEN CIZILMEZ

	tazele saniyede bir calisiyor; cekmecede onlarca brainrot olabiliyor.
	Icerik gercekten degismediyse (ayni esyalar, ayni adlar) listeye
	dokunulmuyor -- yoksa her saniye onlarca dugme yikilip yeniden
	kuruluyor ve tiklamaya calisan oyuncunun elinden kaciyordu.
]]
local sonCekmeceImzasi = ""

------------------------------------------------------------------
-- SIRALAMA
------------------------------------------------------------------
--[[
	YUVA SIRASI

	    1. Aletler      kurek, GPS, olta, kazma, flyboard
	    2. Parsomenler  (Scrolls.Nitelik)
	    3. Lucky Block  kullanilacak esya, parsomenle ayni mantik
	    4. Brainrotlar  PAHALIDAN UCUZA (saniyelik getirisine gore)
	    5. Yumurtalar   kimligi acilmamis olanlar, kademesi yuksekten dusuge

	Siralama HER TAZELEMEDE yeniden yapiliyor: kumdan cikip girince de,
	envanter degisince de kurek 1. yuvaya doner. Eskiden bir esya aldigi
	yuvada kalıyordu; o yuzden kazidan donunce alet arada bir yerde
	kaliyordu.
]]
local function oncelik(tool: Tool): number
	if type(tool:GetAttribute(Scrolls.Nitelik)) == "string" then
		return 2
	end
	if tool:GetAttribute("LuckyBlock") then
		return 3
	end
	if type(tool:GetAttribute("BrainrotUid")) == "string" then
		return if tool:GetAttribute("Revealed") == true then 4 else 5
	end
	-- Geri kalan her sey alet
	return 1
end

--[[
	Brainrotun siralama degeri: acilmissa saniyelik getirisi, acilmamissa
	kademesinin sirasi. Ikisi ayni sayida degil ama ayni GRUPTA olanlar
	kendi aralarinda karsilastirildigi icin sorun olmuyor.
]]
local function deger(tool: Tool): number
	local kademe = tool:GetAttribute("Rarity")
	local durum = tool:GetAttribute("Condition")
	local mutasyon = tool:GetAttribute("Mutation")

	if tool:GetAttribute("Revealed") == true and type(durum) == "string" then
		local gelir = Brainrots.income(adOf(tool), durum :: any, mutasyon :: any)
		if gelir > 0 then
			return gelir
		end
	end

	local info = if type(kademe) == "string" then Rarity.Info[kademe :: any] else nil
	return if info then info.order else 0
end

local function sirala(liste: { Tool })
	--[[
		Ayni grup ve ayni degerdeyse ADA gore: siralama kare kare
		degismesin. table.sort kararli degil, esitlikte kesin bir kural
		olmazsa ayni iki esya her tazelemede yer degistirebilir.
	]]
	table.sort(liste, function(a, b)
		local oa, ob = oncelik(a), oncelik(b)
		if oa ~= ob then
			return oa < ob
		end

		local da, db = deger(a), deger(b)
		if da ~= db then
			return da > db
		end

		return a.Name < b.Name
	end)
end

local function cekmeceyiCiz(disarida: { Tool })
	--[[
		Dugmenin gorunurlugu imza denetiminden ONCE: dugme cubukta yer
		kapladigi icin olcek hesabi ona bakiyor (bkz. olcegiTazele).
	]]
	cekmeceAcikMi = #disarida > 0
	cekmeceDugme.Visible = cekmeceAcikMi
	if not cekmeceAcikMi then
		cekmece.Visible = false
	end

	local imza = {}
	for _, tool in disarida do
		table.insert(imza, tool.Name)
	end
	local yeniImza = table.concat(imza, "|")
	if yeniImza == sonCekmeceImzasi then
		return
	end
	sonCekmeceImzasi = yeniImza

	for _, node in cekmeceListe:GetChildren() do
		if not node:IsA("UIListLayout") then
			node:Destroy()
		end
	end

	if #disarida == 0 then
		return
	end

	for sira, tool in disarida do
		local satir = Instance.new("TextButton")
		satir.Name = tool.Name
		satir.LayoutOrder = sira
		satir.Size = UDim2.new(1, -4, 0, 30)
		satir.BackgroundColor3 = Color3.fromRGB(34, 37, 45)
		satir.BorderSizePixel = 0
		satir.AutoButtonColor = false
		satir.Text = ""
		satir.Parent = cekmeceListe
		UI.corner(satir, 8)
		UI.hover(satir)

		local adet = adetOf(tool)
		UI.text({
			text = if adet > 1 then `{adOf(tool)}   x{adet}` else adOf(tool),
			size = UI.Sizes.small,
			font = UI.Fonts.bold,
			color = Color3.fromRGB(232, 236, 244),
			frameSize = UDim2.new(1, -16, 1, 0),
			position = UDim2.fromOffset(10, 0),
			parent = satir,
			zIndex = 2,
		})

		satir.Activated:Connect(function()
			esyaSec(tool)
		end)
	end
end

local function tazele()
	local mevcut = esyalariTopla()

	local var: { [Tool]: boolean } = {}
	for _, tool in mevcut do
		var[tool] = true
	end

	--[[
		Yuva tablolari asagida zaten sifirdan kuruluyor; burada yalnizca
		artik var olmayan esyalarin IKONU ve dinleyicileri birakiliyor.
		Ikisi ayri geziliyor cunku cekmecedeki (yuvasiz) esyalarin da
		dinleyicisi var.
	]]
	for tool in baglantilar do
		if not var[tool] then
			ikonuBirak(tool)
		end
	end
	for tool in ikonlar do
		if not var[tool] then
			ikonuBirak(tool)
		end
	end

	--[[
		YUVALAR HER SEFERINDE BASTAN DAGITILIYOR (bkz. YUVA SIRASI).
		Ilk on esya cubuga, kalani cekmeceye.
	]]
	sirala(mevcut)
	table.clear(yuvaninEsyasi)
	table.clear(esyaninYuvasi)

	local disarida: { Tool } = {}
	for sira, tool in mevcut do
		if sira <= SLOT_SAYISI then
			yuvaninEsyasi[sira] = tool
			esyaninYuvasi[tool] = sira
		else
			table.insert(disarida, tool)
		end
	end

	for _, tool in mevcut do
		--[[
			ADI ya da ADEDI degisince yalnizca rozet tazelenir. Sunucu
			parsomen harcandiginda Tool'u silmeyip adini degistiriyor
			("... x3" -> "... x2"); rozet ona bagli.
		]]
		if not baglantilar[tool] then
			local sira = esyaninYuvasi[tool]
			local function yeniden()
				local s = esyaninYuvasi[tool]
				if s then
					yuvayiCiz(s)
				end
			end
			baglantilar[tool] = {
				tool:GetPropertyChangedSignal("Name"):Connect(yeniden),
				tool:GetAttributeChangedSignal(Assets.CountAttribute):Connect(yeniden),
			}
			if sira then
				yuvayiCiz(sira)
			end
		end
	end

	-- Cekmece once: olcek hesabi dugmenin gorunurlugune bakiyor
	cekmeceyiCiz(disarida)
	hepsiniCiz()
end

local function tazelemeIste()
	if tazelemeBekliyor then
		return
	end
	tazelemeBekliyor = true
	task.defer(function()
		tazelemeBekliyor = false
		tazele()
	end)
end

cekmeceDugme.Activated:Connect(function()
	cekmece.Visible = not cekmece.Visible
end)

------------------------------------------------------------------
-- BAGLANTILAR
------------------------------------------------------------------
local karakterBaglantilari: { RBXScriptConnection } = {}

local function karakteriIzle(yeni: Model)
	for _, baglanti in karakterBaglantilari do
		baglanti:Disconnect()
	end
	table.clear(karakterBaglantilari)

	karakter = yeni
	table.insert(karakterBaglantilari, yeni.ChildAdded:Connect(tazelemeIste))
	table.insert(karakterBaglantilari, yeni.ChildRemoved:Connect(tazelemeIste))
	tazelemeIste()
end

if player.Character then
	karakteriIzle(player.Character)
end
player.CharacterAdded:Connect(karakteriIzle)

--[[
	BACKPACK HER DOGUMDA YENIDEN URETILIR: nesneye bir kez baglanmak
	yetmiyor, yenisi gelince ona da baglanmak gerekiyor.
]]
local backpackBaglantilari: { RBXScriptConnection } = {}

local function backpackiIzle(backpack: Instance)
	for _, baglanti in backpackBaglantilari do
		baglanti:Disconnect()
	end
	table.clear(backpackBaglantilari)

	table.insert(backpackBaglantilari, backpack.ChildAdded:Connect(tazelemeIste))
	table.insert(backpackBaglantilari, backpack.ChildRemoved:Connect(tazelemeIste))
	tazelemeIste()
end

local ilkBackpack = player:FindFirstChildOfClass("Backpack")
if ilkBackpack then
	backpackiIzle(ilkBackpack)
end

player.ChildAdded:Connect(function(node)
	if node:IsA("Backpack") then
		backpackiIzle(node)
	end
end)

--[[
	SON CARE TAZELEME

	Tool'lar sunucudan gelirken arada bir olay kacabiliyor (ayni karede
	Backpack yeniden uretilirse). Saniyede bir tarama hem ucuz hem de
	cubugun bayat kalmasini kesin olarak engelliyor.
]]
task.spawn(function()
	while true do
		task.wait(1)
		tazele()
	end
end)

-- Ilk cizim: Backpack henuz bos olabilir, zararsiz
RunService.Heartbeat:Wait()
tazele()
