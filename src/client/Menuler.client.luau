--[[
	Menuler  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Menuler

	Ekranlar:
	  ENVANTER (B tusu)   -- kurek, dedektor ve butun brainrotlar
	  DETECTIVE           -- siyah brainrotu teslim et
	  SLOT MAKINESI       -- Rot Coin ile skin cevir
	  MAGAZA              -- kurek ve dedektor yukseltme

	Brainrotlar fiziksel Tool olarak cantada durur. Base slotuna yerlestirme
	dunyada yapilir: brainrotu eline al, slota yaklas, E bas.
	Satis ekrani ayri bir scriptte (Satis).
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
-- Friends sekmesindeki "Invite Friends" dugmesi
local SocialService = game:GetService("SocialService")
-- Rewards > Social: "Like And Favorite" favori penceresi
local AvatarEditorService = game:GetService("AvatarEditorService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarity = require(Shared:WaitForChild("Rarity"))
local Condition = require(Shared:WaitForChild("Condition"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Shovels = require(Shared:WaitForChild("Shovels"))
local Detectors = require(Shared:WaitForChild("Detectors"))
local Format = require(Shared:WaitForChild("Format"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Net = require(Shared:WaitForChild("Net"))
local Icons = require(Shared:WaitForChild("Icons"))
local Rewards = require(Shared:WaitForChild("Rewards"))
local RotCoinMagaza = require(Shared:WaitForChild("RotCoinMagaza"))

local UI = require(script.Parent:WaitForChild("UI"))
-- Iki asamali rulet (Lucky Block carki)
local Rulet = require(script.Parent:WaitForChild("Rulet"))
-- Brainrot kesif defteri (mavi kitap dugmesi)
local Index = require(script.Parent:WaitForChild("Index"))
-- Liste satirlarindaki brainrot resimleri (Envanter, Detective)
local BrainrotOnizleme = require(script.Parent:WaitForChild("BrainrotOnizleme"))
-- Mutasyon ortaya cikinca ekranda buyuk yazi
--[[
	ISTEGE BAGLI MODULLER  --  MENUYU KILITLEMEZ

	Asagidaki uc modul (mutasyon gosterisi, muzik, tiklama sesi) scriptin EN
	BASINDA bekleniyordu. Biri o an Studio'da yoksa (Rojo henuz aktarmamis
	olabilir) script hata vermeden SONSUZA KADAR bekliyor ve butun arayuz
	(sol menu, Rot gostergesi, paneller) hic kurulmuyordu.

	Artik her biri en fazla 5 saniye beklenir; bulunamaz ya da yuklenemezse
	Output'a uyari yazilir ve bos bir yedekle devam edilir -- menu yine
	kurulur, yalnizca o ozellik calismaz.
]]
local function istegeBagli(ad: string, yedek: any): any
	local modul = script.Parent:WaitForChild(ad, 5)
	if not modul then
		warn(`[Menuler] "{ad}" modulu bulunamadi; bu ozellik kapali, arayuz devam ediyor`)
		return yedek
	end
	local ok, sonuc = pcall(require, modul)
	if not ok then
		warn(`[Menuler] "{ad}" yuklenemedi: {tostring(sonuc)}`)
		return yedek
	end
	return sonuc
end

local MutasyonGosterisi = istegeBagli("MutasyonGosterisi", {
	goster = function() end,
})
-- Arka plan muzigi (Happy Shoppers); ses ayari Settings panelinde
local Muzik = istegeBagli("Muzik", {
	ayarla = function() end,
	yuzde = function()
		return 100
	end,
	kapali = function()
		return false
	end,
})
-- Menu butonlarina tiklama sesi (Cartoon Bubble)
local ArayuzSesi = istegeBagli("ArayuzSesi", {
	tikla = function() end,
})
-- Muzik disindaki butun seslerin ayari (Settings > Sound Effects)
local SesEfekti = istegeBagli("SesEfekti", {
	ayarla = function() end,
	yuzde = function()
		return 100
	end,
	kapali = function()
		return false
	end,
})

local EnvanterGuncelle = Net.event("EnvanterGuncelle")
local DetectiveAc = Net.event("DetectiveAc")
local DetectiveTeslim = Net.event("DetectiveTeslim")
local DetectiveSonuc = Net.event("DetectiveSonuc")
-- Yeni remote: yoksa menu beklemesin (yalnizca Detective ilerleme gostergesi guncellenmez)
local DetectiveDurum = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DetectiveDurum", 5) :: RemoteEvent?
if not DetectiveDurum then
	warn("[Menuler] DetectiveDurum remote'u yok; Detective ilerlemesi gosterilmeyecek")
end
local BaseGuncelle = Net.event("BaseGuncelle")
local SlottanAl = Net.event("SlottanAl")
local EtkinlikSayaci = Net.event("EtkinlikSayaci")
local LuckyBlockSonuc = Net.event("LuckyBlockSonuc")
local OdulAc = Net.event("OdulAc")
local OdulAl = Net.event("OdulAl")
local OdulDurum = Net.event("OdulDurum")
local OdulSonuc = Net.event("OdulSonuc")
local ArkadasDurum = Net.event("ArkadasDurum")
local ArkadasAc = Net.event("ArkadasAc")
local RotCoinMagazaAc = Net.event("RotCoinMagazaAc")
local RotCoinMagazaAl = Net.event("RotCoinMagazaAl")
local RotCoinMagazaDurum = Net.event("RotCoinMagazaDurum")
local MagazaAc = Net.event("MagazaAc")
local KurekAl = Net.event("KurekAl")
local GPSAl = Net.event("GPSAl")
local AyarDurum = Net.event("AyarDurum")
local AyarKaydet = Net.event("AyarKaydet")
local GorevDurum = Net.event("GorevDurum")
local GorevAc = Net.event("GorevAc")
local GorevAl = Net.event("GorevAl")

local screen = Instance.new("ScreenGui")
screen.Name = "OyunMenuleri"
-- Menu butonlari XP barinin (DisplayOrder 0) ustunde; paneller ortak panel
-- katmaninda ve butonlarin ustunde (bkz. UI.luau > PANEL KATMANI).
screen.DisplayOrder = 5
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

-- Client tarafinda tutulan son envanter
local inventory = {
	rot = 0,
	rotCoins = 0,
	shovel = "Wooden",
	detector = "Basic",
	inventory = {},
}


------------------------------------------------------------------
-- ORTAK
------------------------------------------------------------------
local function makeScroll(parent: Instance, position: UDim2, size: UDim2): ScrollingFrame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Liste"
	scroll.Position = position
	scroll.Size = size
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.ScrollBarImageColor3 = UI.Colors.panelLight
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	return scroll
end

--[[
	Listeyi bosaltir.
	Onceden yalnizca GuiButton ve Frame siliniyordu; UI.text ile uretilen
	TextLabel.lar kaliyor ve her acilista ust uste birikiyordu
	("Henuz brainrot yok" satirinin tekrarlamasi bundandi).
]]
local function clearRows(scroll: ScrollingFrame)
	for _, child in scroll:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Brainrot satiri: siyah halde sadece rarity, acilmisken isim + gelir
local function brainrotRow(
	parent: Instance,
	item: any,
	order: number,
	pencere: BrainrotOnizleme.Pencere?
): TextButton
	local rarityInfo = Rarity.get(item.rarity)
	local conditionInfo = Condition.get(item.condition)
	local mutationInfo = Mutations.get(item.mutation)
	-- Mutasyon da isim gibi: Detective acana kadar gosterilmez
	local revealed = item.revealed and item.name
	local special = revealed and Mutations.isSpecial(item.mutation)

	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, -6, 0, 68)
	-- Kademe renginde canli zemin: soldan saga koyulasir
	row.BackgroundColor3 = Color3.new(1, 1, 1)
	row.BorderSizePixel = 0
	-- Fare etkisi tiklanabilir satirlarda ayrica veriliyor (UI.hover)
	row.AutoButtonColor = false
	row.Text = ""
	row.LayoutOrder = order
	row.Parent = parent
	UI.corner(row, 12)
	UI.stroke(row, rarityInfo.color, 2)

	local zemin = Instance.new("UIGradient")
	zemin.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rarityInfo.color:Lerp(Color3.new(0, 0, 0), 0.35)),
		ColorSequenceKeypoint.new(0.45, rarityInfo.color:Lerp(Color3.fromRGB(28, 30, 42), 0.72)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 30, 42)),
	})
	zemin.Parent = row

	--[[
		BRAINROT RESMI

		Kare artik brainrotun 3B onizlemesini tasiyor (bkz. BrainrotOnizleme);
		onizleme kurulana kadar ya da model bulunamazsa eski gorunum kalir.
		Kare 42'den 50'ye buyutuldu: 42 pikselde model secilmiyordu.

		Zemin kademe renginin koyulastirilmis hali: duz kademe rengi
		modelin kendi renkleriyle karisip onu bogiyordu.
	]]
	local icon = Instance.new("Frame")
	icon.Size = UDim2.fromOffset(50, 50)
	icon.Position = UDim2.fromOffset(6, 6)
	icon.BackgroundColor3 = if revealed
		then rarityInfo.color:Lerp(Color3.new(0, 0, 0), 0.45)
		else Color3.fromRGB(10, 10, 12)
	icon.BorderSizePixel = 0
	icon.ClipsDescendants = true
	icon.Parent = row
	UI.corner(icon, 8)
	UI.stroke(icon, rarityInfo.color, 1)

	-- Simsiyah brainrot: onizleme gelene kadar "?" durur
	local soru: TextLabel? = nil
	if not revealed then
		soru = UI.text({
			text = "?",
			size = UI.Sizes.heading,
			font = UI.Fonts.bold,
			color = rarityInfo.color,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.fromScale(1, 1),
			parent = icon,
		})
	end

	if pencere then
		pencere.ekle(icon, {
			name = item.name,
			mutation = item.mutation,
			rarity = item.rarity,
			revealed = if revealed then true else false,
		}, soru)
	end

	--[[
		Isim HER ZAMAN kademe renginde. Epic ve ustunde parilti gradyani,
		Divine'da sari <-> beyaz parildama devreye girer (UI.rarityStyle).
	]]
	UI.rarityStyle(
		UI.text({
			text = if revealed then item.name else `??? ({rarityInfo.displayName})`,
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = rarityInfo.color,
			frameSize = UDim2.new(1, -186, 0, 22),
			position = UDim2.fromOffset(68, 9),
			parent = row,
		}),
		item.rarity
	)

	local mutationTag = if special then `  {mutationInfo.displayName} ({mutationInfo.multiplier}x)` else ""
	local detail = if revealed
		then `{conditionInfo.shortName} ({conditionInfo.multiplier}x){mutationTag}  -  {Format.perSecond(Brainrots.income(item.name, item.condition, item.mutation))}`
		else `{conditionInfo.displayName}  -  take it to the Detective`

	UI.text({
		text = detail,
		size = UI.Sizes.small,
		--[[
			BOYUT SATIRI HER ZAMAN BOYUT RENGINDE.

			Onceden mutasyonlu brainrotlarda bu satir mutasyon rengine
			donuyordu; Galaxy bir brainrotun "Regular" yazisi mora kayiyordu.
			Artik mutasyon boyutun rengini ele geciremez -- boyut renkleri
			kendi kimliginde kalir, mutasyon zaten ISIMDE gorunuyor.
		]]
		color = if revealed then conditionInfo.color else UI.Colors.textDim,
		frameSize = UDim2.new(1, -186, 0, 20),
		position = UDim2.fromOffset(68, 32),
		parent = row,
	})

	-- Sagda kondisyon rozeti
	local badge = Instance.new("Frame")
	badge.Size = UDim2.fromOffset(56, 24)
	badge.Position = UDim2.new(1, -66, 0, 34)
	badge.BackgroundColor3 = conditionInfo.color
	badge.BackgroundTransparency = 0.75
	badge.BorderSizePixel = 0
	badge.Parent = row
	UI.corner(badge, 6)

	UI.text({
		text = conditionInfo.shortName,
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = conditionInfo.color,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = badge,
	})

	--[[
		NEREDE DURUYOR: base'teyse yesil "ON BASE #3", cantadaysa mavi
		"BACKPACK" etiketi. Base'dekinin resminin kosesinde de slot numarasi.
	]]
	local yerEtiketi = Instance.new("Frame")
	yerEtiketi.AnchorPoint = Vector2.new(1, 0)
	yerEtiketi.Position = UDim2.new(1, -10, 0, 6)
	yerEtiketi.Size = UDim2.fromOffset(if item.slot then 104 else 92, 20)
	yerEtiketi.BackgroundColor3 = if item.slot then Color3.fromRGB(60, 190, 90) else Color3.fromRGB(60, 130, 230)
	yerEtiketi.BorderSizePixel = 0
	yerEtiketi.Parent = row
	UI.corner(yerEtiketi, 10)
	UI.stroke(yerEtiketi, Color3.fromRGB(0, 0, 0), 1)

	UI.text({
		text = if item.slot then `ON BASE #{item.slot}` else "BACKPACK",
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		color = Color3.new(1, 1, 1),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = yerEtiketi,
	})

	if item.slot then
		local numara = Instance.new("Frame")
		numara.Position = UDim2.fromOffset(2, 2)
		numara.Size = UDim2.fromOffset(22, 22)
		numara.BackgroundColor3 = Color3.fromRGB(60, 190, 90)
		numara.BorderSizePixel = 0
		numara.ZIndex = 5
		numara.Parent = icon
		UI.corner(numara, 11)
		UI.stroke(numara, Color3.fromRGB(0, 0, 0), 1)

		local numaraYazi = UI.text({
			text = tostring(item.slot),
			size = UI.Sizes.tiny,
			font = UI.Fonts.bold,
			color = Color3.new(1, 1, 1),
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.fromScale(1, 1),
			parent = numara,
		})
		numaraYazi.ZIndex = 6
	end

	return row
end

------------------------------------------------------------------
-- ENVANTER
------------------------------------------------------------------
local envanter = UI.panel(screen, UDim2.fromOffset(600, 580), "Envanter")

--[[
	ENVANTER  --  canli, iki bolumlu

	    [ Inventory                               X ]   <- renkli baslik
	    ( 12 Brainrots ) ( 3 Unidentified ) ( 4/10 On Base )
	    ON YOUR BASE  4/10
	      #1 ....  #2 ....  #3 (bos)  ...            <- slot sirasiyla, bos slotlar da
	    IN YOUR BACKPACK  (8)
	      pahalidan ucuza ...

	Base'deki bir brainrota tiklamak onu cantaya geri alir.
]]
-- Cilali mavi-mor baslik cubugu (bkz. UI.baslikCubugu)
UI.baslikCubugu(envanter, "Inventory", Color3.fromRGB(50, 150, 255), Color3.fromRGB(170, 90, 255), "inventory")

UI.closeButton(envanter).MouseButton1Click:Connect(function()
	envanter.Visible = false
end)

-- Ozet cipleri
local envanterCipler = Instance.new("Frame")
envanterCipler.Position = UDim2.fromOffset(14, 70)
envanterCipler.Size = UDim2.new(1, -28, 0, 30)
envanterCipler.BackgroundTransparency = 1
envanterCipler.Parent = envanter

local ciplerDizilim = Instance.new("UIListLayout")
ciplerDizilim.FillDirection = Enum.FillDirection.Horizontal
ciplerDizilim.Padding = UDim.new(0, 8)
ciplerDizilim.SortOrder = Enum.SortOrder.LayoutOrder
ciplerDizilim.Parent = envanterCipler

local function cip(renk: Color3, sira: number): TextLabel
	local kutu = Instance.new("Frame")
	kutu.Size = UDim2.fromOffset(170, 30)
	kutu.BackgroundColor3 = renk
	kutu.BorderSizePixel = 0
	kutu.LayoutOrder = sira
	kutu.Parent = envanterCipler
	UI.corner(kutu, 15)
	UI.stroke(kutu, Color3.fromRGB(0, 0, 0), 2)
	-- Ustu parlak, alti koyu: dugme gibi kabarik dursun
	UI.cubukCilasi(kutu)

	return UI.text({
		text = "",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = Color3.new(1, 1, 1),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = kutu,
		zIndex = 5,
	})
end

local cipToplam = cip(Color3.fromRGB(60, 130, 230), 1)
local cipGizli = cip(Color3.fromRGB(90, 90, 110), 2)
local cipBase = cip(Color3.fromRGB(60, 190, 90), 3)

local envanterListe = makeScroll(envanter, UDim2.fromOffset(14, 112), UDim2.new(1, -28, 1, -126))

-- Yalnizca ekrandaki satirlara brainrot resmi kurulur (bkz. BrainrotOnizleme)
local envanterPencere = BrainrotOnizleme.pencere(envanterListe, envanter)

-- Renkli bolum basligi
local function sectionHeader(parent: Instance, text: string, order: number, renk: Color3?)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -6, 0, 32)
	holder.BackgroundColor3 = renk or UI.Colors.panelLight
	holder.BorderSizePixel = 0
	holder.LayoutOrder = order
	holder.Parent = parent
	UI.corner(holder, 10)
	UI.stroke(holder, Color3.fromRGB(0, 0, 0), 2)

	UI.cubukCilasi(holder)

	UI.text({
		text = text,
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = Color3.new(1, 1, 1),
		frameSize = UDim2.new(1, -20, 1, 0),
		position = UDim2.fromOffset(12, 0),
		parent = holder,
		zIndex = 5,
	})
end

-- Bos base slotu: numarasi ve nasil doldurulacagi
local function bosSlotSatiri(parent: Instance, slotNo: number, order: number)
	local satir = Instance.new("Frame")
	satir.Size = UDim2.new(1, -6, 0, 40)
	satir.BackgroundColor3 = Color3.fromRGB(30, 32, 44)
	satir.BackgroundTransparency = 0.2
	satir.BorderSizePixel = 0
	satir.LayoutOrder = order
	satir.Parent = parent
	UI.corner(satir, 10)
	local cerceve = UI.stroke(satir, Color3.fromRGB(60, 190, 90), 1)
	cerceve.Transparency = 0.6

	local numara = Instance.new("Frame")
	numara.AnchorPoint = Vector2.new(0, 0.5)
	numara.Position = UDim2.new(0, 10, 0.5, 0)
	numara.Size = UDim2.fromOffset(28, 28)
	numara.BackgroundColor3 = Color3.fromRGB(60, 190, 90)
	numara.BackgroundTransparency = 0.5
	numara.BorderSizePixel = 0
	numara.Parent = satir
	UI.corner(numara, 14)

	UI.text({
		text = tostring(slotNo),
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = Color3.new(1, 1, 1),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = numara,
	})

	UI.text({
		text = `Empty slot  -  hold a brainrot and press E on slot {slotNo}`,
		size = UI.Sizes.small,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -60, 1, 0),
		position = UDim2.fromOffset(50, 0),
		parent = satir,
	})
end

local function refreshEnvanter()
	--[[
		Satirlar silinmeden ONCE resimler havuza aliniyor: bu fonksiyon her
		EnvanterGuncelle'de calisiyor, yeni satirlar ayni brainrotlari
		havuzdan hazir alsin, modeller her seferinde yeniden klonlanmasin.
	]]
	envanterPencere.temizle()
	clearRows(envanterListe)

	local items = inventory.inventory or {}
	local slotSayisi = math.max(1, math.floor(tonumber(inventory.baseSlots) or 10))

	local hidden = 0
	local slotta: { [number]: any } = {}
	local cantada: { any } = {}
	local fazlaSlot: { any } = {}
	for _, item in items do
		if not item.revealed then
			hidden += 1
		end
		if item.slot then
			if item.slot <= slotSayisi and not slotta[item.slot] then
				slotta[item.slot] = item
			else
				table.insert(fazlaSlot, item)
			end
		else
			table.insert(cantada, item)
		end
	end

	local placed = 0
	for _ in slotta do
		placed += 1
	end
	placed += #fazlaSlot

	cipToplam.Text = `{#items} Brainrots`
	cipGizli.Text = `{hidden} Unidentified`
	cipBase.Text = `{placed}/{slotSayisi} On Base`

	--[[
		SIRALAMA: pahalidan ucuza. Getiri kademe, boyut ve mutasyonu birlikte
		hesaba kattigi icin "pahali" olan gercekten en cok kazandirandir.
	]]
	local function worth(item: any): number
		if item.revealed and item.name then
			return Brainrots.income(item.name, item.condition, item.mutation)
		end
		-- Acilmamis: rarity'nin en dusuk uyesi kadar sayilir
		return Brainrots.minIncome(item.rarity, item.condition)
	end

	--[[
		CANTADAKI BRAINROTA TIKLAYINCA ELE ALINIR

		Hotbar'daki gibi: brainrot cantada bir Tool olarak duruyor (nitelik:
		BrainrotUid). Tiklaninca kusanilir, zaten eldeyse birakilir; envanter
		kapanir ki oyuncu elindekini gorsun. Base'teki brainrotlar bu yolla
		alinmaz (onlarin tiklamasi slottan geri alir).
	]]
	local function eleAlTikla(row: TextButton, item: any)
		row.MouseButton1Click:Connect(function()
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				return
			end

			for _, tool in character:GetChildren() do
				if tool:IsA("Tool") and tool:GetAttribute("BrainrotUid") == item.uid then
					humanoid:UnequipTools()
					return
				end
			end

			local backpack = player:FindFirstChildOfClass("Backpack")
			if not backpack then
				return
			end
			for _, tool in backpack:GetChildren() do
				if tool:IsA("Tool") and tool:GetAttribute("BrainrotUid") == item.uid then
					humanoid:EquipTool(tool)
					envanter.Visible = false
					return
				end
			end
		end)
		UI.hover(row)
	end

	local function tabanaTikla(row: TextButton, item: any)
		row.MouseButton1Click:Connect(function()
			SlottanAl:FireServer(item.uid)
		end)
		UI.hover(row)
	end

	------------------------------------------------------------------
	-- BASE: slot sirasiyla, bos slotlar da
	------------------------------------------------------------------
	sectionHeader(envanterListe, `ON YOUR BASE   {placed}/{slotSayisi}`, 1, Color3.fromRGB(60, 190, 90))

	for slotNo = 1, slotSayisi do
		local item = slotta[slotNo]
		if item then
			tabanaTikla(brainrotRow(envanterListe, item, 1 + slotNo, envanterPencere), item)
		else
			bosSlotSatiri(envanterListe, slotNo, 1 + slotNo)
		end
	end
	for index, item in fazlaSlot do
		tabanaTikla(brainrotRow(envanterListe, item, 1 + slotSayisi + index, envanterPencere), item)
	end

	------------------------------------------------------------------
	-- CANTA: once acilmislar pahalidan ucuza, sonra acilmamislar
	------------------------------------------------------------------
	sectionHeader(envanterListe, `IN YOUR BACKPACK   ({#cantada})`, 1000, Color3.fromRGB(60, 130, 230))

	if #cantada == 0 then
		UI.text({
			text = "Your backpack is empty. Hold your GPS and look for light beams in the sand.",
			size = UI.Sizes.small,
			color = UI.Colors.textDim,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.new(1, 0, 0, 36),
			parent = envanterListe,
			wrapped = true,
		}).LayoutOrder = 1001
		return
	end

	table.sort(cantada, function(a, b)
		local acikA = a.revealed == true and a.name ~= nil
		local acikB = b.revealed == true and b.name ~= nil
		if acikA ~= acikB then
			return acikA
		end
		return worth(a) > worth(b)
	end)

	for index, item in cantada do
		eleAlTikla(brainrotRow(envanterListe, item, 1000 + index, envanterPencere), item)
	end
end

EnvanterGuncelle.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end
	inventory = data
	if envanter.Visible then
		refreshEnvanter()
	end
end)

local function toggleEnvanter()
	envanter.Visible = not envanter.Visible
	if envanter.Visible then
		refreshEnvanter()
	end
end

-- B tusu
ContextActionService:BindAction("EnvanterAc", function(_, state)
	if state == Enum.UserInputState.Begin then
		toggleEnvanter()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.B)

------------------------------------------------------------------
-- ROT GOSTERGESI (sol alt)
--
-- Bakiye artik yalnizca Tab listesinde degil ekranda da duruyor: oyuncu
-- kazi yaparken ya da magazadayken Tab'a basmadan parasini gorebilsin.
-- Para birimleri her yerde SARI (Bases.RotColor ile ayni ton).
------------------------------------------------------------------
local rotKutu = Instance.new("Frame")
rotKutu.Name = "RotGostergesi"
rotKutu.AnchorPoint = Vector2.new(0, 1)
-- Envanter butonunun hemen ustunde
-- Zemin, cerceve ve ikon yok: ekranda yalnizca beyaz rakam durur
rotKutu.Position = UDim2.new(0, 16, 1, -16)
-- Ustte Rot (96), hemen altinda ikonlu Rot Coin satiri (44)
-- Satir yukseklikleri: ustte Rot, hemen altinda Rot Coin. IKISI AYNI olcude
-- (ikon, yazi boyu, bosluk) ki gosterge dengeli dursun.
local ROT_SATIR = 66
local COIN_SATIR = 66
rotKutu.Size = UDim2.fromOffset(460, ROT_SATIR + COIN_SATIR)
rotKutu.BackgroundTransparency = 1
rotKutu.BorderSizePixel = 0
rotKutu.Parent = screen

--[[
	PARA SATIRLARI  --  solda ikon, yaninda gradyanli kalin rakam

	Simulator oyunlarindaki para gostergesi gibi: rakam ustten acik
	tondan alta koyu tona gecen gradyanli, kalin koyu konturlu. Para
	birimi yazisi yok ("5.6M"), neyin sayildigini ikon soyluyor.

	  Rot       yesil rakam, para destesi ikonu (Icons "rotPara")
	  Rot Coin  altin rakam, oyunun Rot Coin ikonu (Icons "rotCoin")

	Deger artinca rakam kisa bir "zipla" animasyonu yapar.

	DIKKAT: Bu script Luau'nun 200 ust seviye yerel sinirinda. Buradaki
	yardimcilar bu yuzden tek tabloda (rotAnim); yeni ust seviye yerel
	eklemek butun menuyu kirar ("Out of local registers").
]]
local rotAnim = {
	-- satir anahtari -> zipla olcegi ve son deger
	olcek = {} :: { [string]: UIScale },
	son = {} :: { [string]: number },
	satir = nil :: any,
	zipla = nil :: any,
}

function rotAnim.satir(
	ad: string,
	y: number,
	yukseklik: number,
	yaziBoyu: number,
	ikonId: string,
	yedekYazi: string,
	renkler: { Color3 },
	konturRengi: Color3,
	konturKalinligi: number
): TextLabel
	local ikonBoyu = yukseklik - 8

	local ikon = Instance.new("ImageLabel")
	ikon.Name = `{ad}Ikon`
	ikon.BackgroundTransparency = 1
	ikon.AnchorPoint = Vector2.new(0.5, 0.5)
	-- Iki satirin ikonlari ayni dikey eksende ortalansin
	ikon.Position = UDim2.fromOffset(34, y + yukseklik / 2)
	ikon.Size = UDim2.fromOffset(ikonBoyu, ikonBoyu)
	ikon.ScaleType = Enum.ScaleType.Fit
	ikon.Parent = rotKutu

	-- Ikon gelmezse yerinde emoji durur
	local yedek = UI.text({
		text = yedekYazi,
		size = math.floor(ikonBoyu * 0.7),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = ikon,
		outline = false,
	})
	Icons.bind(ikon, ikonId, function(ok)
		if ok then
			yedek.Visible = false
		end
	end)

	local yazi = UI.text({
		text = "",
		size = yaziBoyu,
		font = UI.Fonts.bold,
		-- Beyaz taban: rengi gradyan veriyor (gradyan yaziyla carpilir)
		color = Color3.fromRGB(255, 255, 255),
		align = Enum.TextXAlignment.Left,
		--[[
			Oyunun standart konturu kapali; yerine sabit kalinlikta kontur:
			applyOutline kalinligi yazi boyuyla buyudugu icin buyuk rakamda
			kontur asiri kalinlasiyordu.
		]]
		outline = false,
		frameSize = UDim2.new(1, -76, 0, yukseklik),
		position = UDim2.fromOffset(76, y),
		parent = rotKutu,
		name = `{ad}Yazi`,
	})

	local gecis = Instance.new("UIGradient")
	gecis.Name = "ParaRengi"
	gecis.Rotation = 90
	gecis.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, renkler[1]),
		ColorSequenceKeypoint.new(0.5, renkler[2]),
		ColorSequenceKeypoint.new(1, renkler[3]),
	})
	gecis.Parent = yazi

	local kontur = UI.stroke(yazi, konturRengi, konturKalinligi)
	kontur.LineJoinMode = Enum.LineJoinMode.Round

	-- Yazinin sol kenarindan buyuyen zipla olcegi
	local olcek = Instance.new("UIScale")
	olcek.Name = "Zipla"
	olcek.Parent = yazi
	rotAnim.olcek[ad] = olcek

	return yazi
end

-- Deger artmissa rakami ziplatir, son degeri saklar
function rotAnim.zipla(ad: string, deger: number)
	local olcek = rotAnim.olcek[ad]
	local once = rotAnim.son[ad]
	if olcek and once and deger > once then
		olcek.Scale = 1.12
		TweenService:Create(
			olcek,
			TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		):Play()
	end
	rotAnim.son[ad] = deger
end

-- ROT: yesil, 48px (ayarlardaki %100'de ekranda 60px)
local rotYazi = rotAnim.satir(
	"Rot",
	0,
	ROT_SATIR,
	48,
	"rotPara",
	"\u{1F4B5}",
	{ Color3.fromRGB(190, 255, 110), Color3.fromRGB(90, 235, 60), Color3.fromRGB(35, 175, 45) },
	Color3.fromRGB(12, 45, 12),
	4
)

-- ROT COIN: altin sarisi, Rot ile ayni boy
local coinYazi = rotAnim.satir(
	"RotCoin",
	ROT_SATIR,
	COIN_SATIR,
	48,
	"rotCoin",
	"\u{1FA99}",
	{ Color3.fromRGB(255, 245, 150), Color3.fromRGB(255, 205, 40), Color3.fromRGB(235, 140, 20) },
	Color3.fromRGB(70, 35, 0),
	4
)

local function refreshRot(rot: number?, rotCoins: number?)
	rotYazi.Text = Format.short(rot or 0)
	coinYazi.Text = Format.short(rotCoins or 0)

	rotAnim.zipla("Rot", rot or 0)
	rotAnim.zipla("RotCoin", rotCoins or 0)
end

refreshRot(inventory.rot, inventory.rotCoins)

--[[
	ARKADAS BUFFI YAZISI  --  Rot'un hemen ustunde

	Ayni sunucuda Roblox arkadasi varken gorunur: "Friend Boost: +15% Luck".
	Konumu ve sol menunun ona gore yukari itilmesi solSutunuYerlestir'de;
	gorunurlugu ArkadasDurum gelince degisir (bkz. FRIENDS bolumu).
]]
local arkadasBuff = UI.text({
	text = "",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	color = Color3.fromRGB(120, 255, 150),
	align = Enum.TextXAlignment.Left,
	frameSize = UDim2.fromOffset(360, 28),
	anchor = Vector2.new(0, 1),
	position = UDim2.new(0, 20, 1, -112),
	parent = screen,
	name = "ArkadasBuffu",
})
arkadasBuff.Visible = false

--[[
	SANS IKSIRI YAZISI  --  arkadas buffinin ustunde (o yoksa Rot'un ustunde)
	Rot Coin magazasindan alinan iksir aktifken gorunur, suresi geri sayar.
]]
local iksirBuff = UI.text({
	text = "",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	color = Color3.fromRGB(90, 220, 255),
	align = Enum.TextXAlignment.Left,
	frameSize = UDim2.fromOffset(360, 28),
	anchor = Vector2.new(0, 1),
	position = UDim2.new(0, 20, 1, -140),
	parent = screen,
	name = "IksirBuffu",
})
iksirBuff.Visible = false

--[[
	Ayri bir baglanti: gelen veriyi DOGRUDAN okuyor, yukaridaki envanter
	baglantisinin once calismasina guvenmiyor. Roblox ayni sinyaldeki
	baglantilarin sirasini garanti etmez.
]]
EnvanterGuncelle.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end
	refreshRot(data.rot, data.rotCoins)
end)

------------------------------------------------------------------
-- DETECTIVE
------------------------------------------------------------------
local detective = UI.panel(screen, UDim2.fromOffset(640, 540), "Detective")

--[[
	BRAINROT DETECTIVE PANELI  --  toplu inceleme

	Kimligi belirlenmemis butun brainrotlar buyuk kartlarda gorunur; tek
	dugmeyle HEPSI birden birakilir. Bekleme hepsinin suresinin toplami;
	oyuncu yanindan ayrilabilir (sure sunucuda, kayitta isler). Is surerken
	panel ilerleme cubugunu ve kalan sureyi gosterir.
]]
UI.text({
	text = "Brainrot Detective",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = Color3.fromRGB(255, 236, 180),
	frameSize = UDim2.new(1, -80, 0, 36),
	position = UDim2.fromOffset(18, 14),
	parent = detective,
})

UI.text({
	text = "Tap cards to pick some, or leave them ALL with me. Come back to collect them!",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 50),
	parent = detective,
})

UI.closeButton(detective).MouseButton1Click:Connect(function()
	detective.Visible = false
end)

local DETEKTIF_ALT = 100

local detectiveListe = makeScroll(detective, UDim2.fromOffset(14, 80), UDim2.new(1, -28, 1, -(80 + DETEKTIF_ALT + 14)))
-- Kartlar izgarada: liste duzeni yerine izgara
for _, child in detectiveListe:GetChildren() do
	if child:IsA("UIListLayout") then
		child:Destroy()
	end
end
local detektifIzgara = Instance.new("UIGridLayout")
detektifIzgara.CellSize = UDim2.fromOffset(112, 178)
detektifIzgara.CellPadding = UDim2.fromOffset(10, 10)
detektifIzgara.SortOrder = Enum.SortOrder.LayoutOrder
detektifIzgara.Parent = detectiveListe

local detectivePencere = BrainrotOnizleme.pencere(detectiveListe, detective)

-- Alt cubuk: ozet / ilerleme + buyuk dugme
local detektifAlt = Instance.new("Frame")
detektifAlt.AnchorPoint = Vector2.new(0, 1)
detektifAlt.Position = UDim2.new(0, 14, 1, -14)
detektifAlt.Size = UDim2.new(1, -28, 0, DETEKTIF_ALT)
detektifAlt.BackgroundColor3 = UI.Colors.panelLight
detektifAlt.BorderSizePixel = 0
detektifAlt.Parent = detective
UI.corner(detektifAlt, 12)
UI.stroke(detektifAlt, Color3.fromRGB(255, 236, 180), 2)

local detektifOzet = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	color = Color3.fromRGB(255, 236, 180),
	frameSize = UDim2.new(1, -270, 0, 26),
	position = UDim2.fromOffset(16, 12),
	parent = detektifAlt,
})

local detektifBar = Instance.new("Frame")
detektifBar.Position = UDim2.fromOffset(16, 48)
detektifBar.Size = UDim2.new(1, -270, 0, 32)
detektifBar.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
detektifBar.BorderSizePixel = 0
detektifBar.Parent = detektifAlt
UI.corner(detektifBar, 16)
UI.stroke(detektifBar, Color3.fromRGB(0, 0, 0), 2)

local detektifDolgu = Instance.new("Frame")
detektifDolgu.Size = UDim2.fromScale(0, 1)
detektifDolgu.BackgroundColor3 = Color3.new(1, 1, 1)
detektifDolgu.BorderSizePixel = 0
detektifDolgu.Parent = detektifBar
UI.corner(detektifDolgu, 16)
local detektifDolguGecis = Instance.new("UIGradient")
detektifDolguGecis.Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(120, 230, 120))
detektifDolguGecis.Parent = detektifDolgu

local detektifBarYazi = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = detektifBar,
})
detektifBarYazi.ZIndex = 3

local detektifDugme = Instance.new("TextButton")
-- Ogretici bu adi arayip etrafina halka ciziyor (bkz. StarterPlayerScripts > Ogretici)
detektifDugme.Name = "HepsiniTanimla"
detektifDugme.AnchorPoint = Vector2.new(1, 0.5)
detektifDugme.Position = UDim2.new(1, -16, 0.5, 0)
detektifDugme.Size = UDim2.fromOffset(226, 64)
detektifDugme.BackgroundColor3 = UI.Colors.good
detektifDugme.AutoButtonColor = false
detektifDugme.BorderSizePixel = 0
detektifDugme.Text = ""
detektifDugme.Parent = detektifAlt
UI.corner(detektifDugme, 12)
UI.stroke(detektifDugme, Color3.fromRGB(0, 0, 0), 3)

local detektifDugmeYazi = UI.text({
	text = "",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = detektifDugme,
})

-- Durum
local detektifBekleyen: { any } = {}
-- Secilen kartlar (uid -> true); bossa dugme hepsini birakir
local detektifSecili: { [string]: boolean } = {}
local detektifIs: any = nil
local detektifBitis = 0

local function detektifSure(saniye: number): string
	local t = math.max(0, math.ceil(saniye))
	return string.format("%d:%02d", t // 60, t % 60)
end

local function detektifCalisiyor(): boolean
	return detektifIs ~= nil and detektifIs.bitti ~= true and detektifBitis > os.clock()
end

local function detektifSeciliSayisi(): number
	local n = 0
	for _ in detektifSecili do
		n += 1
	end
	return n
end

-- Ileri bildirim: kart tiklamasi dugme yazisini tazeler
local detektifDurumCiz: () -> ()

local function detektifKarti(item: any, sira: number)
	local rarityInfo = Rarity.get(item.rarity)
	local conditionInfo = Condition.get(item.condition)

	--[[
		Kart bir dugme: tiklayinca SECILIR (altin cerceve + tik). Altindaki
		kucuk IDENTIFY dugmesi yalnizca bu brainrotu birakir.
	]]
	local kart = Instance.new("TextButton")
	kart.Name = item.uid
	kart.Text = ""
	kart.AutoButtonColor = false
	kart.BackgroundColor3 = rarityInfo.color:Lerp(Color3.new(0, 0, 0), 0.55)
	kart.BorderSizePixel = 0
	kart.LayoutOrder = sira
	kart.Parent = detectiveListe
	UI.corner(kart, 12)
	local kartKontur = UI.stroke(kart, rarityInfo.color, 2)
	-- Kart artik TextButton: kontur yaziya degil kenara gitsin
	kartKontur.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local tik = UI.text({
		text = "\u{2713}",
		size = UI.Sizes.heading,
		font = UI.Fonts.bold,
		color = UI.Colors.gold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(28, 28),
		position = UDim2.new(1, -30, 0, 2),
		parent = kart,
	})
	tik.ZIndex = 6

	local function secimiCiz()
		local secili = detektifSecili[item.uid] == true
		kartKontur.Color = if secili then UI.Colors.gold else rarityInfo.color
		kartKontur.Thickness = if secili then 4 else 2
		tik.Visible = secili
	end
	secimiCiz()

	kart.MouseButton1Click:Connect(function()
		if detektifSecili[item.uid] then
			detektifSecili[item.uid] = nil
		else
			detektifSecili[item.uid] = true
		end
		secimiCiz()
		detektifDurumCiz()
	end)

	local tek = UI.button(kart, "IDENTIFY", UDim2.new(1, -12, 0, 24), UI.Colors.good)
	tek.Name = "TekTanimla"
	tek.Position = UDim2.new(0, 6, 1, -28)
	tek.ZIndex = 4
	local tekYazi = tek:FindFirstChild("Label")
	if tekYazi and tekYazi:IsA("TextLabel") then
		tekYazi.TextSize = UI.Sizes.tiny
		tekYazi.ZIndex = 5
	end
	UI.stroke(tek, Color3.fromRGB(0, 0, 0), 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	tek.MouseButton1Click:Connect(function()
		if not detektifCalisiyor() then
			DetectiveTeslim:FireServer({ item.uid })
		end
	end)

	local gecis = Instance.new("UIGradient")
	gecis.Rotation = 90
	gecis.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150))
	gecis.Parent = kart

	local resim = Instance.new("Frame")
	resim.AnchorPoint = Vector2.new(0.5, 0)
	resim.Position = UDim2.new(0.5, 0, 0, 8)
	resim.Size = UDim2.fromOffset(92, 92)
	resim.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	resim.BorderSizePixel = 0
	resim.ClipsDescendants = true
	resim.Parent = kart
	UI.corner(resim, 10)

	local soru = UI.text({
		text = "?",
		size = UI.Sizes.huge,
		font = UI.Fonts.bold,
		color = rarityInfo.color,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = resim,
	})
	detectivePencere.ekle(resim, { mutation = item.mutation, revealed = false, rarity = item.rarity }, soru)

	local ad = UI.text({
		text = rarityInfo.displayName,
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = rarityInfo.color,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -8, 0, 20),
		position = UDim2.fromOffset(4, 104),
		parent = kart,
	})
	UI.rarityStyle(ad, item.rarity)

	UI.text({
		text = `{conditionInfo.shortName}  -  {detektifSure(tonumber(item.sure) or 0)}`,
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(230, 230, 240),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -8, 0, 18),
		position = UDim2.fromOffset(4, 126),
		parent = kart,
	})
end

-- Yalnizca cubuk ve dugme yazilari (her saniye)
function detektifDurumCiz()
	if detektifCalisiyor() then
		local kalan = detektifBitis - os.clock()
		local toplam = math.max(1, tonumber(detektifIs.toplam) or 1)
		detektifBar.Visible = true
		detektifDolgu.Size = UDim2.fromScale(math.clamp(1 - kalan / toplam, 0, 1), 1)
		detektifBarYazi.Text = `{detektifSure(kalan)} left  -  you can leave!`
		detektifOzet.Text = `Identifying {detektifIs.adet or 0} brainrot(s)...`
		detektifDugme.BackgroundColor3 = UI.Colors.panel
		detektifDugmeYazi.Text = "WORKING..."
	elseif detektifIs and detektifIs.bitti then
		--[[
			IS BITTI: TESLIM ALMA

			Brainrotlar kendiliginden verilmiyor; oyuncu bu dugmeye basinca
			cantaya giriyorlar (bkz. ServerScriptService > Detective).
		]]
		local adet = tonumber(detektifIs.adet) or 0
		detektifBar.Visible = true
		detektifDolgu.Size = UDim2.fromScale(1, 1)
		detektifBarYazi.Text = "READY"
		detektifOzet.Text = `{adet} brainrot(s) identified -- take them back!`
		detektifDugme.BackgroundColor3 = UI.Colors.good
		detektifDugmeYazi.Text = `COLLECT {adet}`
	else
		detektifBar.Visible = false
		local toplam = 0
		for _, item in detektifBekleyen do
			toplam += tonumber(item.sure) or 0
		end
		-- Secim varsa ozet ve dugme yalnizca secilenleri anlatir
		local secili = detektifSeciliSayisi()
		local seciliSure = 0
		for _, item in detektifBekleyen do
			if detektifSecili[item.uid] then
				seciliSure += tonumber(item.sure) or 0
			end
		end
		detektifOzet.Text = if secili > 0
			then `{secili} selected  -  {detektifSure(seciliSure)}`
			elseif #detektifBekleyen > 0 then `{#detektifBekleyen} unidentified  -  total {detektifSure(toplam)}`
			else "No unidentified brainrots"
		detektifDugme.BackgroundColor3 = if #detektifBekleyen > 0 then UI.Colors.good else UI.Colors.panel
		detektifDugmeYazi.Text = if secili > 0
			then `IDENTIFY {secili}`
			elseif #detektifBekleyen > 0 then "IDENTIFY ALL"
			else "NOTHING LEFT"
	end
end

local function detektifCiz()
	detectivePencere.temizle()
	clearRows(detectiveListe)

	if detektifCalisiyor() then
		local bilgi = UI.text({
			text = "The Detective is working on your brainrots. Come back when the bar is full!",
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = UI.Colors.textDim,
			align = Enum.TextXAlignment.Center,
			wrapped = true,
			parent = detectiveListe,
		})
		bilgi.Size = UDim2.fromOffset(560, 60)
	else
		table.sort(detektifBekleyen, function(a, b)
			return (tonumber(a.sure) or 0) > (tonumber(b.sure) or 0)
		end)
		-- Artik listede olmayanlarin secimi dusurulur
		local mevcut: { [string]: boolean } = {}
		for _, item in detektifBekleyen do
			mevcut[item.uid] = true
		end
		for uid in detektifSecili do
			if not mevcut[uid] then
				detektifSecili[uid] = nil
			end
		end
		for sira, item in detektifBekleyen do
			detektifKarti(item, sira)
		end
	end

	detektifDurumCiz()
end

detektifDugme.MouseButton1Click:Connect(function()
	--[[
		Is bitmisse dugme YALNIZCA teslim alir: "collect" isteginde sunucu
		brainrotlari verip durur, bekleyenleri yeniden ise sokmaz.
	]]
	if detektifIs and detektifIs.bitti then
		DetectiveTeslim:FireServer("collect")
		return
	end

	if not detektifCalisiyor() and #detektifBekleyen > 0 then
		local secilen = {}
		for uid in detektifSecili do
			table.insert(secilen, uid)
		end
		if #secilen > 0 then
			DetectiveTeslim:FireServer(secilen)
		else
			DetectiveTeslim:FireServer()
		end
	end
end)

DetectiveAc.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	detektifBekleyen = if type(payload.pending) == "table" then payload.pending else {}
	detektifIs = if type(payload.job) == "table" then payload.job else nil
	detektifBitis = os.clock() + (if detektifIs then tonumber(detektifIs.kalan) or 0 else 0)
	detektifCiz()
	detective.Visible = true
end)

local detektifDurumOlayi = DetectiveDurum
if detektifDurumOlayi then detektifDurumOlayi.OnClientEvent:Connect(function(is)
	detektifIs = if type(is) == "table" then is else nil
	detektifBitis = os.clock() + (if detektifIs then tonumber(detektifIs.kalan) or 0 else 0)
	if detektifIs then
		-- Birakilanlar artik isin icinde: kart listesi bosalir
		detektifBekleyen = {}
	end
	if detective.Visible then
		detektifCiz()
	end
end)
end

DetectiveSonuc.OnClientEvent:Connect(function(sonuclar)
	detektifIs = nil
	detektifBekleyen = {}
	if detective.Visible then
		detektifCiz()
	end

	-- Mutasyonlu cikanlar ekranda buyuk yaziyla (sirayla)
	if type(sonuclar) == "table" then
		for _, sonuc in sonuclar do
			if type(sonuc) == "table" then
				MutasyonGosterisi.goster(sonuc.mutation, sonuc.name)
			end
		end
	end
end)

-- Geri sayim
task.spawn(function()
	while true do
		task.wait(0.5)
		if detective.Visible and detektifIs then
			detektifDurumCiz()
		end
	end
end)

------------------------------------------------------------------
-- BASE
------------------------------------------------------------------
-- Yerlestirme tamamen dunyada yapiliyor: brainrotu eline al, slota E bas.
-- Burada sadece envanter aciksa listeyi tazeliyoruz.
BaseGuncelle.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end
	if envanter.Visible then
		refreshEnvanter()
	end
end)

------------------------------------------------------------------
-- MAGAZA
------------------------------------------------------------------
-- Iki sutun: solda kurekler, sagda GPS'ler (kaydirmadan hepsi gorunsun)
local magaza = UI.panel(screen, UDim2.fromOffset(1040, 520), "Magaza")

UI.text({
	text = "Shopkeeper",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	frameSize = UDim2.new(1, -80, 0, 36),
	position = UDim2.fromOffset(18, 14),
	parent = magaza,
})

UI.text({
	text = "A new shovel replaces the old one -- the old one is gone.",
	size = UI.Sizes.small,
	color = UI.Colors.warn,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 48),
	parent = magaza,
})

UI.closeButton(magaza).MouseButton1Click:Connect(function()
	magaza.Visible = false
end)

local magazaKurekler = makeScroll(magaza, UDim2.fromOffset(14, 78), UDim2.new(0.5, -21, 1, -92))
local magazaGpsler = makeScroll(magaza, UDim2.new(0.5, 7, 0, 78), UDim2.new(0.5, -21, 1, -92))
-- Kurekte "Can dig up to Divine" yazisi icin
local KaziMinigame = require(Shared:WaitForChild("KaziMinigame"))

--[[
	Magaza satiri.
	detail: o toola ozgu ikinci satir (kurekte bar/hiz, gpste sans/menzil)
	onBuy:  satin alma remote'unu tetikleyen fonksiyon
]]
local function shopRow(parent: ScrollingFrame, entry: any, detail: string, order: number, onBuy: () -> (), detail2: string?)
	local color = Rarity.color(entry.rarity)

	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, -6, 0, if detail2 then 88 else 70)
	row.BackgroundColor3 = UI.Colors.panelLight
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	row.Text = ""
	row.LayoutOrder = order
	row.Parent = parent
	UI.corner(row, 10)
	-- Kusanili olan kademe kendi renginde kalin cerceve alir
	UI.stroke(
		row,
		if entry.equipped or entry.buyable then color else UI.Colors.panelLight,
		if entry.equipped then 2 else 1
	)

	-- Sahip olunan ama kusanili OLMAYAN kademe soluk durur
	if entry.owned and not entry.equipped then
		row.BackgroundTransparency = 0.4
	end

	UI.text({
		text = `Lv.{entry.level}  {entry.displayName}`,
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = color,
		frameSize = UDim2.new(1, -160, 0, 22),
		position = UDim2.fromOffset(14, 9),
		parent = row,
	})

	UI.text({
		text = detail,
		size = UI.Sizes.small,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -160, 0, 20),
		position = UDim2.fromOffset(14, 32),
		parent = row,
	}).RichText = true

	if detail2 then
		local satir3 = UI.text({
			text = detail2,
			size = UI.Sizes.small,
			font = UI.Fonts.bold,
			color = UI.Colors.text,
			frameSize = UDim2.new(1, -160, 0, 20),
			position = UDim2.fromOffset(14, 56),
			parent = row,
		})
		satir3.RichText = true
	end

	--[[
		DURUM YAZISI

		Sahip olunan kademeler kalici: kusanili olmayanina tiklayinca
		ucretsiz kusanilir, o yuzden "USE" yazar.
	]]
	local statusText, statusColor
	if entry.equipped then
		statusText = "EQUIPPED"
		statusColor = UI.Colors.good
	elseif entry.owned then
		statusText = "USE"
		statusColor = UI.Colors.accent
	elseif entry.buyable then
		statusText = `{Format.short(entry.price)} Rot`
		statusColor = UI.Colors.gold
	else
		statusText = "LOCKED"
		statusColor = UI.Colors.textDim
	end

	UI.text({
		text = statusText,
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = statusColor,
		align = Enum.TextXAlignment.Right,
		frameSize = UDim2.fromOffset(140, 24),
		position = UDim2.new(1, -154, 0.5, -12),
		parent = row,
	})

	-- Satin alinabilir ya da kusanilabilir satirlar tiklanabilir
	if entry.buyable or (entry.owned and not entry.equipped) then
		row.MouseButton1Click:Connect(onBuy)
		UI.hover(row)
	end
end

-- "Can dig up to <Divine>" (kademe kendi renginde)
local function kazabilir(gearId: string): string?
	local kademe = KaziMinigame.enYuksekKademe(gearId)
	if not kademe then
		return nil
	end
	local renk = Rarity.textColor(kademe)
	return `Can dig up to <font color="#{renk:ToHex()}">{Rarity.displayName(kademe)}</font>`
end

MagazaAc.OnClientEvent:Connect(function(payload)
	clearRows(magazaKurekler)
	clearRows(magazaGpsler)

	if type(payload) ~= "table" then
		return
	end

	local order = 0

	------------------------------------------------------------------
	-- KUREKLER: minigame kolayligi
	------------------------------------------------------------------
	order += 1
	sectionHeader(magazaKurekler, "SHOVELS  --  easier minigame", order)

	for _, entry in payload.shovels or {} do
		order += 1
		-- Ikinci satir yalnizca kazabildigi en yuksek kademe; GPS satirlariyla ayni boy
		shopRow(magazaKurekler, entry, kazabilir(entry.id) or "", order, function()
			KurekAl:FireServer(entry.id)
		end)
	end

	------------------------------------------------------------------
	-- DEDEKTORLER: yuksek rarity sansi
	------------------------------------------------------------------
	order += 1
	sectionHeader(magazaGpsler, "DETECTORS  --  better rarity odds", order)

	for _, entry in payload.detectors or {} do
		order += 1
		shopRow(
			magazaGpsler,
			entry,
			`Luck x{entry.luck}  -  Range {entry.scanRadius} studs`,
			order,
			function()
				GPSAl:FireServer(entry.id)
			end
		)
	end

	magaza.Visible = true
end)


------------------------------------------------------------------
-- LUCKY BLOCK CARKI  --  IKI ASAMALI
--
-- Blok cantada bir Tool olarak duruyor: eline alip tiklayinca sunucu
-- odulu belirliyor ve bu panel acilip donuyor.
--
-- 1. ASAMA  Bolmelerde yalnizca "?" ve KADEME RENGI doner. Cark durunca
--           hangi kademenin ciktigi belli olur (orn. kirmizi = Mythic)
--           ama hangi brainrot oldugu hala bilinmez.
-- 2. ASAMA  Serit yeniden kurulur; bu kez SADECE o kademeden cikabilecek
--           brainrotlar adiyla doner ve odul aciga cikar.
--
-- Cark yalnizca GOSTERIM: iki asamanin da nerede duracagini sunucu daha
-- cark donmeye baslamadan secmis olur.
------------------------------------------------------------------
--[[
	GORUNUM
	  - Cilali baslik cubugu; rengi acilan blogun turune boyanir
	  - Panelin arkasinda yavasca donen isik huzmeleri + ekran karartmasi
	  - Parlak kart bolmeler ve kazananda kutlama (bkz. Rulet)

	DIKKAT: bu script 200 ust seviye yerel sinirinda. Asagidaki suslemeler
	bu yuzden do-blogunda; yeni ust seviye yerel ekleme.
]]
local luckyPanel = UI.panel(screen, UDim2.fromOffset(540, 360), "LuckyBlock")

UI.baslikCubugu(luckyPanel, "LUCKY BLOCK", Color3.fromRGB(255, 215, 40), Color3.fromRGB(255, 120, 40), "luckyBlock")

-- Hangi turden blok acildi (Lucky Block / Altin / Elmas)
local luckyTier = UI.text({
	text = "",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -36, 0, 26),
	position = UDim2.fromOffset(18, 68),
	parent = luckyPanel,
})

UI.closeButton(luckyPanel).MouseButton1Click:Connect(function()
	luckyPanel.Visible = false
end)

local luckyReel = Rulet.new(luckyPanel, {
	position = UDim2.new(0.5, 0, 0, 108),
	width = 496,
	height = 124,
	color = Rarity.LuckyBlock.colorA,
	name = "Cark",
})

local luckyResult = UI.text({
	text = "",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 38),
	position = UDim2.fromOffset(10, 250),
	parent = luckyPanel,
})

local luckyDetail = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 24),
	position = UDim2.fromOffset(10, 292),
	parent = luckyPanel,
})

do
	--[[
		ISIK HUZMELERI + KARARTMA

		Panelin arkasinda: once ekrani hafifce karartan bir ortu, ustunde
		merkezden disa uzanan ve yavasca donen isik huzmeleri. Huzmeler
		panelin ortasindan gecen uzun seritler; kapsayici cerceve dondukce
		cocuklari da onunla doner. Panel acikken gorunur.
	]]
	local karartma = Instance.new("Frame")
	karartma.Name = "LuckyKarartma"
	karartma.AnchorPoint = Vector2.new(0.5, 0.5)
	karartma.Position = UDim2.fromScale(0.5, 0.5)
	karartma.Size = UDim2.fromScale(3, 3)
	karartma.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	karartma.BackgroundTransparency = 0.45
	karartma.BorderSizePixel = 0
	karartma.ZIndex = 0
	karartma.Visible = false
	karartma.Parent = UI.fonEkrani() or screen

	local isik = Instance.new("Frame")
	isik.Name = "LuckyIsik"
	isik.AnchorPoint = Vector2.new(0.5, 0.5)
	isik.Position = UDim2.fromScale(0.5, 0.5)
	isik.Size = UDim2.fromOffset(10, 10)
	isik.BackgroundTransparency = 1
	isik.ZIndex = 0
	isik.Visible = false
	isik.Parent = UI.fonEkrani() or screen

	local HUZME = 8
	for i = 1, HUZME do
		local huzme = Instance.new("Frame")
		huzme.Name = "Huzme"
		huzme.AnchorPoint = Vector2.new(0.5, 0.5)
		huzme.Position = UDim2.fromScale(0.5, 0.5)
		huzme.Size = UDim2.fromOffset(90, 1400)
		huzme.Rotation = (i - 1) * (180 / HUZME)
		huzme.BackgroundColor3 = Rarity.LuckyBlock.colorA
		huzme.BorderSizePixel = 0
		huzme.ZIndex = 0
		huzme.Parent = isik

		-- Ortada parlak, uclara dogru eriyen serit
		local gecis = Instance.new("UIGradient")
		gecis.Rotation = 90
		gecis.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.32, 0.55),
			NumberSequenceKeypoint.new(0.5, 0.3),
			NumberSequenceKeypoint.new(0.68, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		gecis.Parent = huzme
	end

	local donus = TweenService:Create(
		isik,
		TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{ Rotation = 360 }
	)

	luckyPanel:GetPropertyChangedSignal("Visible"):Connect(function()
		local acik = luckyPanel.Visible
		karartma.Visible = acik
		isik.Visible = acik
		if acik then
			isik.Rotation = 0
			donus:Play()
		else
			donus:Cancel()
		end
	end)
end

LuckyBlockSonuc.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" or type(data.rarityCells) ~= "table" or type(data.cells) ~= "table" then
		return
	end

	--[[
		ACILIS SESLERI
		  1. "LuckyBlock" calar; bitene kadar rulet ekrani GELMEZ
		  2. sunucuya "basladi" denir (odul zamanlamasi buradan sayilir)
		  3. "LuckyBlockOpening" calar ve rulet doner
		  4. brainrot gelince sunucu FuseExplosion + FuseVFX oynatir
	]]
	local YerelSes = require(script.Parent:WaitForChild("YerelSes"))
	local _, girisSuresi = YerelSes.cal("LuckyBlock")
	if girisSuresi > 0 then
		task.wait(math.min(girisSuresi, 6))
	end
	Net.event("LuckyBlockBasladi"):FireServer()
	-- Iki carkta da calar: 2. cark baslarken ayni ses bastan
	local acilisSesi = YerelSes.cal("LuckyBlockOpening")

	--[[
		2. ASAMA bolmeleri.
		Kademe o asamada zaten belli oldugu icin serit tek renktir; oyuncu
		"bu kirmizidan hangisi cikacak" diye bekler.
	]]
	--[[
		Her bolmede brainrotun resmi de var (bkz. Rulet > Cell.brainrot).
		Kazanan bolmede MUTASYONLU model: Gold cikacaksa carkin durdugu
		bolme de altin gorunsun, oyuncunun eline gecenle ayni olsun.
	]]
	local kazananSira = tonumber(data.winnerIndex) or LuckyBlock.Wheel.revealWinnerIndex
	local kazanan = if type(data.winner) == "table" then data.winner else nil
	local turMutasyonu = if type(data.tierMutation) == "string" then data.tierMutation else nil

	local cells: { Rulet.Cell } = {}
	for index, entry in data.cells do
		table.insert(cells, {
			text = entry.name,
			color = Rarity.color(entry.rarity),
			-- Cercevedeki canli efekt kademeye gore (bkz. Rulet > KADEME EFEKTLERI)
			rarity = entry.rarity,
			brainrot = if type(entry.name) == "string"
				then {
					name = entry.name,
					--[[
						Turun zorunlu mutasyonu varsa (Hacker) BUTUN bolmeler
						o mutasyonun modeliyle ciziliyor; yoksa yalnizca
						kazanan bolme oyuncunun eline gececek haliyle.
					]]
					mutation = turMutasyonu
						or (if index == kazananSira and kazanan then kazanan.mutation else nil),
				}
				else nil,
		})
	end

	--[[
		Zamanlama ve indeksler sunucudan geliyor. Eksik/bozuk bir alan gelirse
		cark ortasinda hata verip panelin kilitli kalmamasi icin paylasimli
		ayarlara duseriz -- iki taraf da ayni tabloyu okudugu icin degerler
		zaten ayni.
	]]
	local W = LuckyBlock.Wheel

	local started = Rulet.run(luckyReel, {
		rarityCells = data.rarityCells,
		rarityWinner = tonumber(data.rarityWinnerIndex) or W.winnerIndex,
		rarityTime = tonumber(data.raritySpinTime) or W.spinTime,
		pause = tonumber(data.pause) or W.pause,
		cells = cells,
		winner = tonumber(data.winnerIndex) or W.revealWinnerIndex,
		time = tonumber(data.spinTime) or W.revealSpinTime,

		-- 2. cark baslarken acilis sesi bastan
		onSecondSpin = function()
			YerelSes.durdur(acilisSesi)
			acilisSesi = YerelSes.cal("LuckyBlockOpening")
		end,

		-- 1. cark durdu: yalnizca kademe aciklanir, brainrot hala gizli
		onRarity = function(rarityId: string)
			-- Kademe belli oldu: kucuk bir kutlama, asil patlama brainrotta
			Rulet.kutla(luckyReel, Rarity.color(rarityId))
			luckyResult.Text = string.upper(Rarity.displayName(rarityId))
			UI.rarityStyle(luckyResult, rarityId)
			luckyDetail.Text = "Tier locked in, now which brainrot?"
			luckyDetail.TextColor3 = UI.Colors.textDim
		end,

		-- 2. cark durdu: odul aciga cikar
		onFinish = function()
			local winner = data.winner
			if type(winner) ~= "table" then
				return
			end

			Rulet.shake(luckyPanel)
			-- Halka + yildizlar kazananin kademe renginde
			Rulet.kutla(luckyReel, Rarity.color(winner.rarity))

			local mutationInfo = Mutations.get(winner.mutation)
			local special = Mutations.isSpecial(winner.mutation)
			local conditionInfo = Condition.get(winner.condition)

			-- Isim HER ZAMAN kademe renginde; Epic+ parlar, Divine parildar
			luckyResult.Text = winner.name
			UI.rarityStyle(luckyResult, winner.rarity)

			local tag = if special then `  {mutationInfo.displayName} ({mutationInfo.multiplier}x)` else ""
			luckyDetail.Text = `{Rarity.displayName(winner.rarity)} {conditionInfo.shortName}{tag} ({Format.perSecond(winner.income or 0)})`
			-- Boyut satiri her zaman boyut renginde; mutasyon rengini ele gecirmez
			luckyDetail.TextColor3 = conditionInfo.color

			-- Mutasyon ciktiysa ekranda buyuk yaziyla
			if special then
				MutasyonGosterisi.goster(winner.mutation, winner.name)
			end
		end,
	})

	if not started then
		return
	end

	luckyTier.Text = if type(data.tierName) == "string" then string.upper(data.tierName) else ""
	luckyTier.TextColor3 = if typeof(data.tierColor) == "Color3" then data.tierColor else UI.Colors.textDim

	--[[
		TURUN RENGI: baslik cubugu, isik huzmeleri ve rulet cercevesi acilan
		blogun renginde (Lucky sari, Golden turuncu, Diamond mavi).
	]]
	do
		local turRengi: Color3 = if typeof(data.tierColor) == "Color3" then data.tierColor else Rarity.LuckyBlock.colorA
		local cubuk = luckyPanel:FindFirstChild("Baslik")
		local cubukGecis = cubuk and cubuk:FindFirstChildOfClass("UIGradient")
		if cubukGecis then
			cubukGecis.Color = ColorSequence.new(turRengi, UI.shade(turRengi, -0.3))
		end
		local huzmeler = (UI.fonEkrani() or screen):FindFirstChild("LuckyIsik")
		if huzmeler then
			for _, huzme in huzmeler:GetChildren() do
				if huzme:IsA("Frame") then
					huzme.BackgroundColor3 = turRengi
				end
			end
		end
	end

	luckyResult.Text = "..."
	UI.plainStyle(luckyResult, UI.Colors.text)
	luckyDetail.Text = ""
	Rulet.tint(luckyReel, if typeof(data.tierColor) == "Color3" then data.tierColor else Rarity.LuckyBlock.colorA)

	luckyPanel.Visible = true
end)


------------------------------------------------------------------
-- BLOK YAGMURU SAYACI (ekranin ust ortasi)
--
-- Sunucu 5 saniyede bir kalan sureyi gonderiyor; arada client kendi
-- icinde geri sayiyor. Boylece yazi her saniye ilerliyor ama sunucuyla
-- arasi acilmiyor.
------------------------------------------------------------------
local sayacKutu = Instance.new("Frame")
sayacKutu.Name = "EtkinlikSayaci"
sayacKutu.AnchorPoint = Vector2.new(0.5, 0)
-- Ust ortada, LEVEL barinin hemen altinda. Bar ust cubugun icinde (ekranin
-- 8..56 pikseli, bkz. StarterPlayerScripts > SeviyeArayuz); bu ekran ust
-- cubugun ALTINDAN olculuyor; cubuk 36 ya da 58 piksel olabildigi icin 24
-- pikselle ikisinde de barin altinda kaliyor
sayacKutu.Position = UDim2.new(0.5, 0, 0, 24)
sayacKutu.Size = UDim2.fromOffset(260, 54)
-- Kutu degil: bildirimler gibi bu da yalnizca yazi. Cerceve ve zemin yok,
-- okunurlugu yazilarin kendi siyah konturu sagliyor
sayacKutu.BackgroundTransparency = 1
sayacKutu.BorderSizePixel = 0
sayacKutu.Visible = false
sayacKutu.Parent = screen

UI.text({
	text = "LUCKY BLOCK RAIN",
	size = UI.Sizes.tiny,
	font = UI.Fonts.bold,
	color = Rarity.LuckyBlock.colorA,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -10, 0, 18),
	position = UDim2.fromOffset(5, 6),
	parent = sayacKutu,
})

local sayacYazi = UI.text({
	text = "--:--",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -10, 0, 28),
	position = UDim2.fromOffset(5, 24),
	parent = sayacKutu,
})

local kalanSure = -1

-- 3725 -> "1:02:05", 125 -> "02:05"
local function sureMetni(seconds: number): string
	local total = math.max(0, math.floor(seconds))
	local hours = math.floor(total / 3600)
	local minutes = math.floor((total % 3600) / 60)
	local secs = total % 60

	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%02d:%02d", minutes, secs)
end

--[[
	Sayac yalnizca yagmira LuckyBlock.Event.showBefore saniye kala gorunur.
	Iki saatlik araligin tamamini geri saymak ekranda gereksiz duruyordu.
]]
local function tazeleGorunurluk()
	sayacKutu.Visible = kalanSure >= 0 and kalanSure <= LuckyBlock.Event.showBefore
end

EtkinlikSayaci.OnClientEvent:Connect(function(seconds)
	kalanSure = math.max(0, tonumber(seconds) or 0)
	tazeleGorunurluk()
end)

task.spawn(function()
	while true do
		task.wait(1)

		if kalanSure < 0 then
			continue
		end

		if kalanSure <= 0 then
			sayacYazi.Text = "NOW!"
			sayacYazi.TextColor3 = Rarity.LuckyBlock.colorA
			continue
		end

		kalanSure -= 1
		tazeleGorunurluk()
		sayacYazi.Text = sureMetni(kalanSure)
		-- Son bir dakikada dikkat cekmesi icin renk degisir
		sayacYazi.TextColor3 = if kalanSure <= 60
			then Color3.fromRGB(255, 120, 120)
			else UI.Colors.text
	end
end)


------------------------------------------------------------------
-- SOL MENU CUBUGU
--
-- Para gostergesinin ustunde yukari dogru dizilen ikon butonlari.
-- Calisan sistemler panelini acar; henuz yazilmamis olanlar "yakinda"
-- der. Boylece duzen simdiden yerinde olur, sistem geldiginde sadece
-- tiklama islevi baglanir.
------------------------------------------------------------------
--[[
	Butonlar IKI sutuna bolundu: hepsi tek sutunda dizilince ekranin ustunden
	tasiyordu. Oyun ici sistemler solda (para gostergesinin ustunde), sosyal
	olanlar sagda.
]]
-- Odul paneli dosyanin sonunda kuruluyor; buton ondan once dizildigi
-- icin acma fonksiyonu once bildirilip sonra atanir
local odulPaneliniAc: () -> ()
-- Friends sekmesi de dosyanin sonunda kuruluyor
local arkadasPaneliniAc: () -> ()
-- Ayarlar paneli de dosyanin sonunda kuruluyor; ayni sebeple once bildirilir
local ayarPaneliniAc: () -> ()
-- Gorev panosu da oyle
local gorevPaneliniAc: () -> ()
-- Rot Coin magazasi da dosyanin sonunda kuruluyor
local rotCoinMagazaAc: () -> ()
--[[
	Isinlayici ve hiz panelleri de dosyanin sonunda kuruluyor. Ayri yerel
	yerine tek tablo: Luau ust seviyede en fazla 200 yerel kabul ediyor.
]]
local ekMenu = {
	isinlayiciAc = function() end,
	hizAc = function() end,
	detektifAc = function() end,
}

local MENU_BOYU = 52

--[[
	KABARTMA PAYI

	Butonun altinda birakilan 3B kenar. Hem buton yuksekligine hem izgara
	hucre boyuna girdigi icin menuSutunu.dan ONCE tanimli olmali -- asagida
	tanimliyken menuSutunu icinde global (nil) olarak cozuluyor ve sutun
	kurulurken "52 + nil" hatasi veriyordu.
]]
local LIP = 5

local function menuSutunu(name: string, sagda: boolean): Frame
	local sutun = Instance.new("Frame")
	sutun.Name = name
	sutun.AnchorPoint = Vector2.new(if sagda then 1 else 0, 1)

	--[[
		Sol taraf 2x2 izgara: dik dizilince ekranin ustune tirmaniyordu.
		Sag taraf tek sutun olarak kaliyor.
	]]
	if sagda then
		sutun.Position = UDim2.new(1, -16, 1, -16)
		sutun.Size = UDim2.fromOffset(MENU_BOYU, 0)
	else
		-- Para gostergesinin hemen ustu
		sutun.Position = UDim2.new(0, 16, 1, -64)
		sutun.Size = UDim2.fromOffset(MENU_BOYU * 2 + 14, 0)
	end

	sutun.AutomaticSize = Enum.AutomaticSize.Y
	sutun.BackgroundTransparency = 1
	sutun.Parent = screen

	if sagda then
		local dizilim = Instance.new("UIListLayout")
		dizilim.Padding = UDim.new(0, 14)
		dizilim.SortOrder = Enum.SortOrder.LayoutOrder
		dizilim.VerticalAlignment = Enum.VerticalAlignment.Bottom
		dizilim.Parent = sutun
	else
		local izgara = Instance.new("UIGridLayout")
		izgara.CellSize = UDim2.fromOffset(MENU_BOYU, MENU_BOYU + LIP)
		izgara.CellPadding = UDim2.fromOffset(14, 14)
		izgara.SortOrder = Enum.SortOrder.LayoutOrder
		izgara.VerticalAlignment = Enum.VerticalAlignment.Bottom
		izgara.Parent = sutun
	end

	return sutun
end

local solSutun = menuSutunu("SolMenu", false)
local sagSutun = menuSutunu("SagMenu", true)

--[[
	SOL SUTUNUN YUKSEKLIGI OLCEGE BAGLI

	Sutun para gostergesinin hemen ustunde durur. UIScale bir nesnenin
	BOYUTUNU carpar ama KENDI konum ofsetini carpmaz; yani arayuz olcegi
	buyudugunde para kutusu uzuyor, sutunun sabit ofseti ise yerinde
	kaliyor ve ikisi ust uste biniyordu.

	Bu yuzden konum her olcek degisiminde yeniden hesaplaniyor.
]]
local SUTUN_BOSLUK = 40

local function solSutunuYerlestir()
	local carpan = UI.getScale() / 100 * UI.ScaleBase
	local paraYuksekligi = rotKutu.Size.Y.Offset * carpan
	local altBosluk = -rotKutu.Position.Y.Offset

	--[[
		Arkadas buffi yazisi Rot kutusunun hemen ustunde. Gorunurken sol
		menu onun yuksekligi kadar daha yukari itilir: yazi butonlarin
		altinda kalmasin.
	]]
	arkadasBuff.Position = UDim2.new(0, 20, 1, -(altBosluk + paraYuksekligi))
	local buffYuksekligi = if arkadasBuff.Visible then arkadasBuff.Size.Y.Offset * carpan else 0

	-- Sans iksiri yazisi arkadas buffinin ustunde; gorunurken menu onun kadar da yukari
	iksirBuff.Position = UDim2.new(0, 20, 1, -(altBosluk + paraYuksekligi + buffYuksekligi))
	if iksirBuff.Visible then
		buffYuksekligi += iksirBuff.Size.Y.Offset * carpan
	end

	solSutun.Position = UDim2.new(0, 16, 1, -(altBosluk + paraYuksekligi + buffYuksekligi + SUTUN_BOSLUK))
end

solSutunuYerlestir()
UI.onScaleChanged(solSutunuYerlestir)

local menuSirasi = 0

--[[
	MENU BUTONU  --  cizgi film tarzi

	Referans oyunlardaki gorunum iki katmandan olusuyor:
	  1. Dis govde  : koyu ton, altta 5px'lik kabartma kenar birakir
	  2. Yuz        : asil renk; ustunde ikon durur

	Uzerinde kalin SIYAH kontur var; butun cizgi film arayuzlerin ortak
	ozelligi bu. Basilinca yuz asagi iner, gercekten basiliyormus gibi olur.
]]

-- amount > 0 aydinlatir, < 0 karartir
local function tonla(color: Color3, amount: number): Color3
	local h, sat, v = color:ToHSV()
	return Color3.fromHSV(h, math.clamp(sat - amount * 0.1, 0, 1), math.clamp(v + amount, 0, 1))
end

--[[
	PARILTI  --  yumusak

	Iki ince dokunus; ikisi de rengin ustunu beyazla ORTMEZ:

	1. IC GECIS
	   Yuzun KENDI arka planina uygulanan dikey gradient: ust kenar oldugu
	   gibi, alt kenar bir tik koyu. Ayri bir katman olmadigi icin renk
	   solmuyor, sadece hafif bir derinlik veriyor.

	2. SUZULEN ISIK
	   Genis, kenarlari eriyen beyaz bir bant sik araliklarla yuzun
	   uzerinden gecer. Ortasi bile yari saydam, yani parlama sert bir
	   flash degil ama gozden de kacmiyor.

	   Bant dondurulmus bir Frame degil, UIGradient'in kayan seffaflik
	   bandi: ClipsDescendants dondurulmus alt nesneleri kirpmadigi icin
	   Frame olsaydi butonun yuvarlak kosesinden tasardi.

	Ilk surumde ust yariyi kaplayan yari saydam beyaz bir kutu vardi;
	renkleri soldurup butonu ortadan ikiye bolen sert bir cizgi birakiyordu.

	Ikon ZIndex 5'te, yani isigin ustunde kaliyor.
]]
local PARILTI_SURE = 0.75 -- bandin bir gecis suresi
local PARILTI_ARA = 2 -- iki gecis arasi bekleme

local function pariltiKatmani(yuz: Frame, sira: number): Frame
	local icGecis = Instance.new("UIGradient")
	icGecis.Rotation = 90
	--[[
		Ustteki beyaz "rengi aynen birak" demek (gradient rengi carpar),
		alttaki gri ise onu %15 karartir. Yani ton hep butonun kendi rengi.
	]]
	icGecis.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(217, 217, 217)),
	})
	icGecis.Parent = yuz

	local isik = Instance.new("Frame")
	isik.Name = "Parilti"
	isik.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	isik.BorderSizePixel = 0
	isik.Size = UDim2.fromScale(1, 1)
	isik.ZIndex = 3
	isik.Parent = yuz
	-- Yuzle AYNI kose yaricapi: ClipsDescendants koseyi kesmedigi icin
	-- bandin ucu buton kosesinin disinda kare bir cikinti birakiyordu
	UI.corner(isik, 10)

	local isikGecis = Instance.new("UIGradient")
	isikGecis.Rotation = 20
	-- Kenarlarda tamamen seffaf, ortasinda yari saydam: yumusak ama gorunur
	isikGecis.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 1),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(0.7, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	isikGecis.Offset = Vector2.new(-1.2, 0)
	isikGecis.Parent = isik

	task.spawn(function()
		-- Butonlar sirayla parlasin; hepsi ayni anda olursa goz yorar
		task.wait(sira * 0.22)

		while isik.Parent do
			if isik.Visible then
				isikGecis.Offset = Vector2.new(-1.2, 0)
				local gecis = TweenService:Create(
					isikGecis,
					TweenInfo.new(PARILTI_SURE, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{ Offset = Vector2.new(1.2, 0) }
				)
				gecis:Play()
				gecis.Completed:Wait()
			end
			task.wait(PARILTI_ARA)
		end
	end)

	return isik
end

local function menuButonu(
	sutun: Frame,
	iconId: string,
	isim: string,
	renk: Color3,
	onClick: (() -> ())?,
	yedekYazi: string?
)
	menuSirasi += 1

	local buton = Instance.new("ImageButton")
	buton.Name = isim
	--[[
		BUTON KARE DEGIL, KAREDEN LIP KADAR UZUN.

		Yuz (renkli katman) butonun icinde 4px kenar birakir ve altta LIP
		kadar kabartma payi vardir. Buton tam kare olsaydi yuz 44x39 kalir,
		ikon o dikdortgene sigdirilirken hem kuculur hem butonun ortasindan
		yukarida durur -- ikonlar "yamuk" gorunuyordu.
		Butonu LIP kadar uzatinca yuz TAM KARE oluyor.
	]]
	buton.Size = UDim2.fromOffset(MENU_BOYU, MENU_BOYU + LIP)
	buton.BackgroundColor3 = tonla(renk, -0.32)
	buton.BorderSizePixel = 0
	buton.AutoButtonColor = false
	buton.Image = ""
	buton.LayoutOrder = menuSirasi
	buton.Parent = sutun
	UI.corner(buton, 14)
	-- Kalin siyah kontur oyunun imzasi; menu butonlari da ona uyar
	UI.stroke(buton, Color3.fromRGB(0, 0, 0), 2)

	local yuz = Instance.new("Frame")
	yuz.Name = "Yuz"
	yuz.Size = UDim2.new(1, -8, 1, -8 - LIP)
	--[[
		Yuz butonun MERKEZINDEN tutuluyor. Boylece fare etkisi onu
		buyuturken dort yana esit acilir; (0,0) ile tutulsaydi yalnizca
		saga ve asagi tasardi. Kabartma payi merkezi LIP/2 kadar yukari
		kaydiriyor -- ust kenarda 4px, altta 4+LIP px bosluk kalir.
	]]
	yuz.AnchorPoint = Vector2.new(0.5, 0.5)
	yuz.Position = UDim2.new(0.5, 0, 0.5, -LIP / 2)
	yuz.BackgroundColor3 = renk
	yuz.BorderSizePixel = 0
	-- Ikon yuvarlatilmis kosenin disina tasmasin
	yuz.ClipsDescendants = true
	yuz.Parent = buton
	UI.corner(yuz, 10)

	-- Yumusak ic gecis + ara ara suzulen isik; ikon bunlarin ustunde kalir
	local parilti = pariltiKatmani(yuz, menuSirasi)

	local ikon = Instance.new("ImageLabel")
	ikon.Name = "Ikon"
	ikon.BackgroundTransparency = 1
	-- Yuzun tam ortasi; ScaleType.Fit en-boy oranini korur
	ikon.AnchorPoint = Vector2.new(0.5, 0.5)
	ikon.Size = UDim2.new(1, -8, 1, -8)
	ikon.Position = UDim2.fromScale(0.5, 0.5)
	ikon.ScaleType = Enum.ScaleType.Fit
	ikon.Visible = false
	-- Desen (2) ve parlaklik (3) katmanlarinin ustunde
	ikon.ZIndex = 5
	ikon.Parent = yuz

	local yedek = UI.text({
		text = yedekYazi or string.upper(string.sub(isim, 1, 3)),
		size = if yedekYazi then UI.Sizes.huge else UI.Sizes.small,
		font = UI.Fonts.bold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = yuz,
		zIndex = 5,
	})

	Icons.bind(ikon, iconId, function(ok)
		if ok then
			ikon.Visible = true
			yedek.Visible = false

			--[[
				IKON SABITLENIR: bir kez gelen resim bir daha degismez.
				Teleporter butonunda iki farkli resim arasinda gidip gelme
				vardi; artik ilk gelen resim kalir.
			]]
			local sabit = ikon.Image
			if sabit ~= "" then
				ikon:GetPropertyChangedSignal("Image"):Connect(function()
					if ikon.Image ~= sabit then
						ikon.Image = sabit
					end
				end)
			end
		end
	end)

	if onClick then
		local function bas(asagi: boolean)
			yuz.Position = UDim2.new(0.5, 0, 0.5, if asagi then LIP / 2 else -LIP / 2)
		end

		buton.MouseButton1Down:Connect(function()
			bas(true)
		end)
		buton.MouseButton1Up:Connect(function()
			bas(false)
		end)
		buton.MouseLeave:Connect(function()
			bas(false)
		end)
		buton.MouseButton1Click:Connect(function()
			-- Tiklama sesi (sol menu ve Settings butonu)
			ArayuzSesi.tikla()
			onClick()
		end)

		-- Aydinlanma + buyume yalnizca CALISAN butonlarda
		UI.hover(buton, yuz, yuz)
	else
		--[[
			Islevi olmayan buton KILITLI gorunur: soluk ve uzerinde asma kilit.
			Basinca hicbir sey olmamasi yerine neden olmadigi bellidir.
		]]
		yuz.BackgroundTransparency = 0.35
		-- Kilitli buton parlamaz; sonuk durmasi kilidin bir parcasi
		parilti.Visible = false
		ikon.ImageTransparency = 0.5
		yedek.TextTransparency = 0.5

		local kilit = Icons.of("lockClosed")
		if kilit then
			local rozet = Instance.new("ImageLabel")
			rozet.Name = "Kilit"
			rozet.BackgroundTransparency = 1
			rozet.Size = UDim2.fromOffset(18, 18)
			-- Kabartma payinin ustunde kalsin, butonun alt kenarina yapismasin
			rozet.Position = UDim2.new(1, -20, 1, -20 - LIP)
			rozet.ScaleType = Enum.ScaleType.Fit
			rozet.Image = kilit
			rozet.ZIndex = 4
			rozet.Parent = buton
		end
	end

	return buton
end

--[[
	HER BUTONUN KENDI RENGI

	Hicbir renk iki butonda tekrar etmiyor: oyuncu ikona bakmadan da
	hangi butona bastigini renkten cikarabilsin diye. Tonlar UI.Colors
	paletiyle ayni doygunlukta tutuldu, aksi halde menu alacali duruyor.
]]
local MenuRenk = {
	inventory = Color3.fromRGB(90, 180, 255), -- mavi
	rotcoin = Color3.fromRGB(120, 226, 150), -- yesil (eski Pets butonunun rengi)
	quests = Color3.fromRGB(255, 150, 70), -- turuncu
	rewards = Color3.fromRGB(255, 214, 41), -- altin
	index = Color3.fromRGB(186, 120, 255), -- mor
	friends = Color3.fromRGB(255, 120, 190), -- pembe
	settings = Color3.fromRGB(90, 220, 210), -- turkuaz
	speed = Color3.fromRGB(110, 230, 255), -- buz mavisi
	teleporter = Color3.fromRGB(150, 120, 255), -- lila
	home = Color3.fromRGB(120, 220, 110), -- cimen yesili
	detective = Color3.fromRGB(150, 150, 165), -- gri (ilerledikce yesile dolar)
}

-- Sagdaki ev butonu: sunucu dogrular ve base'in onune isinlar
local BaseyeIsinlan = Net.event("BaseyeIsinlan")


--[[
	=====================================================================
	BILDIRIM NOKTALARI
	=====================================================================

	Sol menu butonunun -- ve Rewards panelindeki sekmenin -- sag ust
	kosesindeki kirmizi nokta: "burada alinacak bir sey var". Oyuncu menuyu
	hic acmadan gorur, acinca da hangi sekmede oldugunu bulur.

	HEPSI TEK TABLODA. Bu script ust seviye yerel sinirina yakin (bkz.
	tools/check.luau uyarisi), her nokta icin ayri bir yerel acilmiyor.

	Anahtarlar:
	  "quests" / "rewards"  sol menu butonlari
	  "sekme_<id>"          Rewards panelindeki Playtime / Daily / Social

	Noktalari kuran yer menu butonlarinin ve sekmelerin kuruldugu yer;
	durumu besleyen yer sunucudan durum gelen her olay isleyicisi.
]]
local Bildirim = {
	-- Nokta nesnesini acip kapatan fonksiyonlar (bkz. UI.bildirimNoktasi)
	noktalar = {} :: { [string]: (acik: boolean) -> () },
	-- Rewards sekmelerinin son durumu; menu butonu bunlarin toplami
	odulSekmeleri = {} :: { [string]: boolean },
}

--[[
	Noktayi acar/kapatir. Nokta henuz kurulmamissa sessizce gecer: sunucudan
	durum, arayuz kurulmadan once gelebiliyor.
]]
function Bildirim.ayarla(anahtar: string, acik: boolean)
	local nokta = Bildirim.noktalar[anahtar]
	if nokta then
		nokta(acik)
	end
end

--[[
	Bir Rewards sekmesinin durumunu yazar ve menu butonunu tazeler: sekmelerden
	HERHANGI birinde alinacak bir sey varsa Rewards butonu da yanar.
]]
function Bildirim.odulSekmesi(id: string, acik: boolean)
	Bildirim.odulSekmeleri[id] = acik
	Bildirim.ayarla(`sekme_{id}`, acik)

	local herhangi = false
	for _, durum in Bildirim.odulSekmeleri do
		if durum then
			herhangi = true
			break
		end
	end
	Bildirim.ayarla("rewards", herhangi)
end

-- SOL: oyunun kendi sistemleri
menuButonu(solSutun, "inventory", "Inventory", MenuRenk.inventory, toggleEnvanter)
-- Pet sistemi iptal edildi; yerinde Rot Coin magazasi
menuButonu(solSutun, "rotCoin", "Rot Coin Shop", MenuRenk.rotcoin, function()
	rotCoinMagazaAc()
end)
-- Quests ve Rewards toplanacak bir sey olunca kirmizi nokta tasir
Bildirim.noktalar.quests = UI.bildirimNoktasi(
	menuButonu(solSutun, "quests", "Quests", MenuRenk.quests, function()
		gorevPaneliniAc()
	end)
)
Bildirim.noktalar.rewards = UI.bildirimNoktasi(
	menuButonu(solSutun, "rewards", "Rewards", MenuRenk.rewards, function()
		odulPaneliniAc()
	end)
)
menuButonu(solSutun, "index", "Index", MenuRenk.index, function()
	-- Ikinci tiklama kapatir
	if Index.acikMi() then
		Index.kapat()
	else
		Index.ac()
	end
end)
menuButonu(solSutun, "friends", "Friends", MenuRenk.friends, function()
	arkadasPaneliniAc()
end)
-- Hiz yukseltmesi (ayakkabi); pakette ikon yoksa emoji
menuButonu(solSutun, "speed", "Speed", MenuRenk.speed, function()
	ekMenu.hizAc()
end, "\u{1F45F}")
-- Detective takibi: buton alttan yesile dolar, is bitince parlar
menuButonu(solSutun, "detective", "Detective", MenuRenk.detective, function()
	ekMenu.detektifAc()
end)

--[[
	SAG: yukaridan asagi Teleporter, base'e don, Settings.
	Sutun alttan dizildigi icin once eklenen ustte durur.
	Isimler onemli: MadenSayaci "Teleporter" butonunun ustune oturuyor.
]]
menuButonu(sagSutun, "teleporter", "Teleporter", MenuRenk.teleporter, function()
	ekMenu.isinlayiciAc()
end)
menuButonu(sagSutun, "home", "Base", MenuRenk.home, function()
	BaseyeIsinlan:FireServer()
end, "\u{1F3E0}")
menuButonu(sagSutun, "settings", "Settings", MenuRenk.settings, function()
	ayarPaneliniAc()
end)


------------------------------------------------------------------
-- GUNLUK ODUL PANELI  --  7 gunluk takvim
--
-- Kartlar bir kez kuruluyor; sunucudan gelen durumla (hangi gun, alinabilir
-- mi, kalan sure) yalnizca dugme yazilari ve renkleri degisiyor. Oduller ve
-- dogrulama SUNUCUDA (bkz. Modules > Odul, Shared > Rewards); "Claim"
-- yalnizca istek gonderir.
--
--   gecmis gun     karartilmis, "Claimed"
--   bugun (hazir)  yesil "Claim", dugme nabiz atar
--   bugun (bekle)  turuncu, kalan sure (sa:dk:sn)
--   gelecek gun    sari, "2 Days" gibi
------------------------------------------------------------------
local ODUL_KART = 150
local ODUL_BOSLUK = 10
-- Baslik (ust) + sekme dugmeleri (58..100) ve altinda sayfa icerigi
local ODUL_UST = 112
-- 7. gun karti daha genis ve iki satir boyu
local ODUL_BUYUK_EN = ODUL_KART + 20

-- Kart zeminleri (canli takvim gorunumu); 7. gunun zemini gokkusagi
local ODUL_RENK: { [number]: Color3 } = {
	[1] = Color3.fromRGB(40, 170, 255),
	[2] = Color3.fromRGB(255, 160, 30),
	[3] = Color3.fromRGB(30, 200, 220),
	[4] = Color3.fromRGB(255, 190, 40),
	[5] = Color3.fromRGB(220, 60, 230),
	[6] = Color3.fromRGB(30, 200, 220),
	[7] = Color3.fromRGB(255, 255, 255),
}

local odulPanel = UI.panel(
	screen,
	UDim2.fromOffset(
		ODUL_BOSLUK + 3 * (ODUL_KART + ODUL_BOSLUK) + ODUL_BUYUK_EN + ODUL_BOSLUK,
		ODUL_UST + 2 * ODUL_KART + ODUL_BOSLUK * 2
	),
	"GunlukOdul"
)

UI.text({
	text = "Rewards",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = UI.Colors.gold,
	frameSize = UDim2.new(1, -80, 0, 34),
	position = UDim2.fromOffset(18, 14),
	parent = odulPanel,
})

UI.closeButton(odulPanel).MouseButton1Click:Connect(function()
	odulPanel.Visible = false
end)

--[[
	SEKMELER  --  Playtime / Daily / Social Rewards

	Her sekmenin kendi sayfasi var (panel boyunda seffaf bir Frame). Daily
	sayfasi eski 7 gunluk takvimin aynisi; kartlar ona kuruluyor. Panel
	acilinca son secilen sekme kalir, ilk acilista Daily.
]]
local odulSayfalari: { [string]: Frame } = {}
local odulSekmeDugmeleri: { [string]: TextButton } = {}

local ODUL_SEKMELER = {
	{ id = "playtime", ad = "Playtime", renk = Color3.fromRGB(70, 200, 240) },
	{ id = "daily", ad = "Daily", renk = Color3.fromRGB(215, 80, 230) },
	{ id = "social", ad = "Social Rewards", renk = Color3.fromRGB(245, 205, 45) },
}

local function odulSekmeSec(id: string)
	for sekme, sayfa in odulSayfalari do
		sayfa.Visible = sekme == id
	end
	for sekme, dugme in odulSekmeDugmeleri do
		local secili = sekme == id
		dugme.BackgroundTransparency = if secili then 0 else 0.5
		local cizgi = dugme:FindFirstChild("SekmeKontur")
		if cizgi and cizgi:IsA("UIStroke") then
			cizgi.Color = if secili then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(0, 0, 0)
		end
	end
end

do
	local sekmeEn = (odulPanel.Size.X.Offset - 20 - 2 * 10) / 3
	for i, sekme in ODUL_SEKMELER do
		local sayfa = Instance.new("Frame")
		sayfa.Name = `Sayfa_{sekme.id}`
		sayfa.Size = UDim2.fromScale(1, 1)
		sayfa.BackgroundTransparency = 1
		sayfa.Parent = odulPanel
		odulSayfalari[sekme.id] = sayfa

		local dugme = Instance.new("TextButton")
		dugme.Name = `Sekme_{sekme.id}`
		dugme.Size = UDim2.fromOffset(sekmeEn, 40)
		dugme.Position = UDim2.fromOffset(10 + (i - 1) * (sekmeEn + 10), 58)
		dugme.BackgroundColor3 = sekme.renk
		dugme.AutoButtonColor = false
		dugme.BorderSizePixel = 0
		dugme.Text = ""
		dugme.Parent = odulPanel
		UI.corner(dugme, 10)

		local kontur = Instance.new("UIStroke")
		kontur.Name = "SekmeKontur"
		kontur.Thickness = 3
		kontur.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		kontur.Parent = dugme

		UI.text({
			text = sekme.ad,
			size = UI.Sizes.heading,
			font = UI.Fonts.bold,
			color = Color3.fromRGB(255, 255, 255),
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.fromScale(1, 1),
			parent = dugme,
			name = "Label",
		})

		odulSekmeDugmeleri[sekme.id] = dugme
		-- Sekmenin kendi kirmizi noktasi: hangi sayfada alinacak sey var
		Bildirim.noktalar[`sekme_{sekme.id}`] = UI.bildirimNoktasi(dugme)
		dugme.MouseButton1Click:Connect(function()
			odulSekmeSec(sekme.id)
		end)
	end
	odulSekmeSec("daily")
end

type OdulKart = {
	gun: number,
	olcek: UIScale,
	cubuk: Frame,
	cubukOlcek: UIScale,
	cubukYazi: TextLabel,
	karartma: Frame,
}

local odulKartlari: { [number]: OdulKart } = {}

-- Sunucudan gelen son durum
local odulGun = 1
local odulHazir = false
local odulKalan = 0

local function odulKartiKur(gun: number, x: number, y: number, en: number, boy: number)
	local buyuk = gun == #Rewards.Days

	local kart = Instance.new("Frame")
	kart.Name = `Gun{gun}`
	kart.AnchorPoint = Vector2.new(0.5, 0.5)
	kart.Position = UDim2.fromOffset(x + en / 2, y + boy / 2)
	kart.Size = UDim2.fromOffset(en, boy)
	kart.BackgroundColor3 = ODUL_RENK[gun] or UI.Colors.accent
	kart.BorderSizePixel = 0
	kart.Parent = odulSayfalari.daily
	UI.corner(kart, 10)
	UI.stroke(kart, Color3.fromRGB(0, 0, 0), 3)

	--[[
		ZEMIN GECISI
		Normal kartlar ustten asagi hafifce koyulasiyor (duz renk yerine
		parlak kart hissi). Son gunun zemini gokkusagi: en buyuk odul
		ilk bakista ayrilsin. Gecis zemin rengiyle carpildigi icin son
		gunun zemini beyaz.
	]]
	local gecis = Instance.new("UIGradient")
	gecis.Rotation = 90
	gecis.Color = if buyuk
		then ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
			ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 160, 40)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 230, 60)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(90, 220, 90)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(60, 160, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 80, 255)),
		})
		else ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(175, 175, 175))
	gecis.Parent = kart

	local olcek = Instance.new("UIScale")
	olcek.Parent = kart

	UI.text({
		text = `Day {gun}`,
		size = if buyuk then UI.Sizes.heading else UI.Sizes.label,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(255, 255, 255),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 28),
		position = UDim2.fromOffset(0, 6),
		parent = kart,
	})

	local odul = Rewards.get(gun)

	-- Ana odulun yaninda Rot Coin varsa basligin altinda sari yazi: "+1 Rot Coin"
	local coinVar = (odul.rotCoins or 0) > 0
	if coinVar then
		local coinYazisi = UI.text({
			text = `+{odul.rotCoins} Rot Coin`,
			size = UI.Sizes.tiny,
			font = UI.Fonts.bold,
			color = Color3.fromRGB(255, 215, 40),
			align = Enum.TextXAlignment.Center,
			outline = false,
			frameSize = UDim2.new(1, 0, 0, 16),
			position = UDim2.fromOffset(0, 31),
			parent = kart,
			name = "RotCoinOdulu",
		})
		UI.stroke(coinYazisi, Color3.fromRGB(0, 0, 0), 2)
	end

	-- Rot Coin yazisi olan kartta gorsel biraz kucuk ve asagida: yaziyla cakismasin
	local ikonBoy = if buyuk then 120 elseif coinVar then 48 else 62
	local ikonKonum = UDim2.new(0.5, 0, 0.5, if coinVar then 0 else -10)

	--[[
		LUCKY BLOCK GUNLERI: "?" kutusu ikonu yerine blogun KENDI modeli
		doner -- oyuncu Hacker gununde Hacker blogunu goruyor.

		Modul burada isteniyor (ust seviyede degil): dosya 200 yerel
		sinirinin dibinde, ustte yeni local acmak arayuzu komple kirar.
		require zaten onbellekli, tekrari bedava.
	]]
	local modelKondu = false
	if odul.kind == "luckyblock" then
		local LuckyOnizleme = require(script.Parent:WaitForChild("LuckyOnizleme"))

		local yuva = Instance.new("Frame")
		yuva.Name = "BlokYuvasi"
		yuva.AnchorPoint = Vector2.new(0.5, 0.5)
		yuva.Position = ikonKonum
		yuva.Size = UDim2.fromOffset(ikonBoy, ikonBoy)
		yuva.BackgroundTransparency = 1
		yuva.Parent = kart

		-- Blogun arkasinda turun renginde yumusak parlama (viewport isik cizmiyor)
		UI.parlama(yuva, Rewards.color(gun), math.floor(ikonBoy * 1.3), 2)

		modelKondu = LuckyOnizleme.ekle(yuva, odul.tier, 4)
		if not modelKondu then
			yuva:Destroy()
		end
	end

	-- Model yoksa eski ikon: Rot icin para, Lucky Block icin paketteki blok
	if not modelKondu then
		local ikon = Instance.new("ImageLabel")
		ikon.Name = "Ikon"
		ikon.AnchorPoint = Vector2.new(0.5, 0.5)
		ikon.Position = ikonKonum
		ikon.Size = UDim2.fromOffset(ikonBoy, ikonBoy)
		ikon.BackgroundTransparency = 1
		ikon.ScaleType = Enum.ScaleType.Fit
		ikon.Parent = kart
		Icons.bind(ikon, if odul.kind == "rot" then "rot" else "luckyBlock")

		-- Blok ikonu turun renginde hafifce boyanir: en pahali blok ucuzundan ayrilsin
		if odul.kind == "luckyblock" then
			ikon.ImageColor3 = Color3.new(1, 1, 1):Lerp(Rewards.color(gun), 0.35)
		end
	end

	UI.text({
		text = Rewards.label(gun),
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(255, 255, 255),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -8, 0, 20),
		position = UDim2.new(0, 4, 1, -66),
		parent = kart,
	})

	-- Alt dugme cubugu: durum yazisi + (yalnizca bugun hazirken) tiklanir
	local cubuk = Instance.new("Frame")
	cubuk.Name = "Dugme"
	cubuk.AnchorPoint = Vector2.new(0.5, 1)
	cubuk.Position = UDim2.new(0.5, 0, 1, -8)
	cubuk.Size = UDim2.new(1, -20, 0, 36)
	cubuk.BackgroundColor3 = UI.Colors.gold
	cubuk.BorderSizePixel = 0
	cubuk.Parent = kart
	UI.corner(cubuk, 8)
	UI.stroke(cubuk, Color3.fromRGB(0, 0, 0), 2)

	-- Nabiz bu olcekte; kartin kendi olcegi kutlamaya ayrildi, ikisi karismasin
	local cubukOlcek = Instance.new("UIScale")
	cubukOlcek.Parent = cubuk

	local cubukYazi = UI.text({
		text = "",
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(255, 255, 255),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = cubuk,
	})

	local tikla = Instance.new("TextButton")
	tikla.Name = "Tikla"
	tikla.Size = UDim2.fromScale(1, 1)
	tikla.BackgroundTransparency = 1
	tikla.AutoButtonColor = false
	tikla.Text = ""
	tikla.Parent = cubuk
	tikla.MouseButton1Click:Connect(function()
		-- Yalnizca istek: gun ve odul sunucuda belirleniyor
		if gun == odulGun and odulHazir then
			OdulAl:FireServer()
		end
	end)

	-- Alinmis gunun karartmasi
	local karartma = Instance.new("Frame")
	karartma.Name = "Karartma"
	karartma.Size = UDim2.fromScale(1, 1)
	karartma.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	karartma.BackgroundTransparency = 0.5
	karartma.BorderSizePixel = 0
	karartma.ZIndex = 5
	karartma.Visible = false
	karartma.Parent = kart
	UI.corner(karartma, 10)

	odulKartlari[gun] = {
		gun = gun,
		olcek = olcek,
		cubuk = cubuk,
		cubukOlcek = cubukOlcek,
		cubukYazi = cubukYazi,
		karartma = karartma,
	}
end

-- Gun 1-6: 3 sutun x 2 satir; son gun sagda iki satir boyunda
for gun = 1, #Rewards.Days - 1 do
	local sutun = (gun - 1) % 3
	local satir = (gun - 1) // 3
	odulKartiKur(
		gun,
		ODUL_BOSLUK + sutun * (ODUL_KART + ODUL_BOSLUK),
		ODUL_UST + satir * (ODUL_KART + ODUL_BOSLUK),
		ODUL_KART,
		ODUL_KART
	)
end

odulKartiKur(
	#Rewards.Days,
	ODUL_BOSLUK + 3 * (ODUL_KART + ODUL_BOSLUK),
	ODUL_UST,
	ODUL_BUYUK_EN,
	ODUL_KART * 2 + ODUL_BOSLUK
)

local function odulCiz()
	for gun, kart in odulKartlari do
		if gun < odulGun then
			kart.karartma.Visible = true
			kart.cubuk.BackgroundColor3 = UI.Colors.panelLight
			kart.cubukYazi.Text = "Claimed"
		elseif gun == odulGun then
			kart.karartma.Visible = false
			if odulHazir then
				kart.cubuk.BackgroundColor3 = UI.Colors.good
				kart.cubukYazi.Text = "Claim"
			else
				kart.cubuk.BackgroundColor3 = UI.Colors.warn
				kart.cubukYazi.Text = Rewards.formatClock(odulKalan)
			end
		else
			kart.karartma.Visible = false
			kart.cubuk.BackgroundColor3 = UI.Colors.gold
			local kalanGun = gun - odulGun
			kart.cubukYazi.Text = if kalanGun == 1 then "1 Day" else `{kalanGun} Days`
		end
	end
end

--[[
	NABIZ: alinabilir gunun dugmesi hafifce buyuyup kuculur.
	Durum her degistiginde eski nabiz durdurulup yenisi kuruluyor.
]]
local odulNabiz: Tween? = nil
local odulNabizOlcek: UIScale? = nil

local function nabizGuncelle()
	local eski = odulNabiz
	if eski then
		eski:Cancel()
		odulNabiz = nil
	end
	local eskiOlcek = odulNabizOlcek
	if eskiOlcek then
		eskiOlcek.Scale = 1
		odulNabizOlcek = nil
	end

	if not odulHazir then
		return
	end

	local kart = odulKartlari[odulGun]
	if not kart then
		return
	end

	odulNabizOlcek = kart.cubukOlcek
	local yeni = TweenService:Create(
		kart.cubukOlcek,
		TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Scale = 1.08 }
	)
	yeni:Play()
	odulNabiz = yeni
end

odulCiz()

OdulDurum.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end

	odulGun = math.clamp(math.floor(tonumber(data.day) or 1), 1, #Rewards.Days)
	odulHazir = data.ready == true
	odulKalan = tonumber(data.remaining) or 0

	odulCiz()
	nabizGuncelle()
	-- Gunluk odul alinabilir durumdaysa Daily sekmesinde ve menu butonunda nokta
	Bildirim.odulSekmesi("daily", odulHazir)
end)

-- Odulu alinan kart kisaca buyuyup yerine oturur
OdulSonuc.OnClientEvent:Connect(function(data)
	local gun = if type(data) == "table" then tonumber(data.day) else nil
	local kart = if gun then odulKartlari[gun] else nil
	if not kart then
		return
	end

	local buyu = TweenService:Create(
		kart.olcek,
		TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1.12 }
	)
	buyu:Play()
	buyu.Completed:Once(function()
		TweenService:Create(kart.olcek, TweenInfo.new(0.2), { Scale = 1 }):Play()
	end)
end)

--[[
	GERI SAYIM istemcide de ilerliyor. Sifira inince sunucudan taze durum
	isteniyor: "Claim" gercekten acildi mi, sunucu karar versin.
]]
task.spawn(function()
	while true do
		task.wait(1)
		if not odulHazir and odulKalan > 0 then
			odulKalan -= 1
			if odulKalan <= 0 then
				OdulAc:FireServer()
			end
			if odulPanel.Visible then
				odulCiz()
			end
		end
	end
end)

------------------------------------------------------------------
-- REWARDS > PLAYTIME ve SOCIAL REWARDS SAYFALARI
--
-- Ayarlar Shared > SosyalOdul, dogrulama ServerScriptService > SosyalOdul.
-- Durumu degisen dugmeler UI.button ile kurulmuyor: UI.hover ilk uzerine
-- gelmede rengi hafizaya aliyor ve Claim -> Claimed renk degisimini geri
-- ceviriyordu. Asagidaki dugmeler hover'siz.
------------------------------------------------------------------
--
-- BEKLEME MENUYU KILITLEMESIN: yeni modul (Shared > SosyalOdul) ve remote'lar
-- WaitForChild ile aliniyor. Scriptin basinda beklenseydi, biri Studio'da
-- henuz yokken butun sol menu ve paneller hic kurulmuyordu. Bu bolum kendi
-- is parcaciginda kuruluyor; eksik olursa yalnizca bu iki sekme bos kalir.
------------------------------------------------------------------
local EkOdulAc: RemoteEvent? = nil

function odulPaneliniAc()
	odulPanel.Visible = not odulPanel.Visible
	if odulPanel.Visible then
		OdulAc:FireServer()
		if EkOdulAc then
			EkOdulAc:FireServer()
		end
	end
end

task.spawn(function()
	local SosyalOdul = require(Shared:WaitForChild("SosyalOdul"))
	local ekAc = Net.event("EkOdulAc")
	local EkOdulAl = Net.event("EkOdulAl")
	local EkOdulDurum = Net.event("EkOdulDurum")
	local KodKullan = Net.event("KodKullan")
	local KodSonuc = Net.event("KodSonuc")
	local ODUL_W = odulPanel.Size.X.Offset
	local ODUL_H = odulPanel.Size.Y.Offset
	local SIYAH = Color3.fromRGB(0, 0, 0)
	local BEYAZ = Color3.fromRGB(255, 255, 255)
	local ALTIN = Color3.fromRGB(255, 215, 40)
	local GRI = Color3.fromRGB(95, 95, 110)

	local function durumDugmesi(parent: Instance, size: UDim2, renk: Color3): (TextButton, TextLabel)
		local dugme = Instance.new("TextButton")
		dugme.Size = size
		dugme.BackgroundColor3 = renk
		dugme.AutoButtonColor = false
		dugme.BorderSizePixel = 0
		dugme.Text = ""
		dugme.Parent = parent
		UI.corner(dugme, 8)
		UI.stroke(dugme, SIYAH, 2)

		local yazi = UI.text({
			text = "",
			size = UI.Sizes.label,
			font = UI.Fonts.bold,
			color = BEYAZ,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.fromScale(1, 1),
			parent = dugme,
			name = "Label",
		})
		return dugme, yazi
	end

	local function kutu(parent: Instance, pos: UDim2, size: UDim2, cerceve: Color3): Frame
		local f = Instance.new("Frame")
		f.Position = pos
		f.Size = size
		f.BackgroundColor3 = Color3.fromRGB(34, 30, 44)
		f.BorderSizePixel = 0
		f.Parent = parent
		UI.corner(f, 12)
		UI.stroke(f, cerceve, 3)
		return f
	end

	-- Sunucudan gelen son durum
	local ekDurum: any = nil
	-- Oturumun istemcideki baslangici: sure her saniye burada ilerliyor
	local ptBaslangic = os.clock()

	------------------------------------------------------------------
	-- PLAYTIME
	------------------------------------------------------------------
	local ptSayfa = odulSayfalari.playtime

	UI.text({
		text = "Stay in the game to earn rewards!",
		size = UI.Sizes.heading,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -20, 0, 30),
		position = UDim2.fromOffset(10, ODUL_UST),
		parent = ptSayfa,
	})

	local ptSureYazi = UI.text({
		text = "",
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(120, 220, 255),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -20, 0, 24),
		position = UDim2.fromOffset(10, ODUL_UST + 32),
		parent = ptSayfa,
	})

	type PtKart = { dugme: TextButton, yazi: TextLabel }
	local ptKartlari: { PtKart } = {}

	do
		local adet = #SosyalOdul.Playtime
		local en = (ODUL_W - 10 * (adet + 1)) / adet
		local y = ODUL_UST + 66
		local boy = ODUL_H - y - 12
		local renkler = {
			Color3.fromRGB(40, 170, 255),
			Color3.fromRGB(255, 160, 30),
			Color3.fromRGB(220, 60, 230),
			Color3.fromRGB(30, 200, 220),
			Color3.fromRGB(255, 190, 40),
		}

		for i, odul in SosyalOdul.Playtime do
			local kart = Instance.new("Frame")
			kart.Name = `Playtime{i}`
			kart.Position = UDim2.fromOffset(10 + (i - 1) * (en + 10), y)
			kart.Size = UDim2.fromOffset(en, boy)
			kart.BackgroundColor3 = renkler[(i - 1) % #renkler + 1]
			kart.BorderSizePixel = 0
			kart.Parent = ptSayfa
			UI.corner(kart, 10)
			UI.stroke(kart, SIYAH, 3)

			local gecis = Instance.new("UIGradient")
			gecis.Rotation = 90
			gecis.Color = ColorSequence.new(BEYAZ, Color3.fromRGB(175, 175, 175))
			gecis.Parent = kart

			UI.text({
				text = if odul.minutes >= 60 then `{odul.minutes // 60} hr` else `{odul.minutes} min`,
				size = UI.Sizes.heading,
				font = UI.Fonts.bold,
				color = BEYAZ,
				align = Enum.TextXAlignment.Center,
				frameSize = UDim2.new(1, 0, 0, 30),
				position = UDim2.fromOffset(0, 8),
				parent = kart,
			})

			-- Lucky Block odulunde donen blok modeli (bkz. Daily kartlari)
			local blokKondu = false
			if odul.kind == "luckyblock" then
				local LuckyOnizleme = require(script.Parent:WaitForChild("LuckyOnizleme"))

				local yuva = Instance.new("Frame")
				yuva.Name = "BlokYuvasi"
				yuva.AnchorPoint = Vector2.new(0.5, 0.5)
				yuva.Position = UDim2.new(0.5, 0, 0.5, -12)
				yuva.Size = UDim2.fromOffset(68, 68)
				yuva.BackgroundTransparency = 1
				yuva.Parent = kart

				UI.parlama(yuva, LuckyBlock.get(SosyalOdul.enUcuzLuckyBlock()).color, 86, 2)

				blokKondu = LuckyOnizleme.ekle(yuva, SosyalOdul.enUcuzLuckyBlock(), 4)
				if not blokKondu then
					yuva:Destroy()
				end
			end

			if not blokKondu then
				local ikon = Instance.new("ImageLabel")
				ikon.AnchorPoint = Vector2.new(0.5, 0.5)
				ikon.Position = UDim2.new(0.5, 0, 0.5, -12)
				ikon.Size = UDim2.fromOffset(64, 64)
				ikon.BackgroundTransparency = 1
				ikon.ScaleType = Enum.ScaleType.Fit
				ikon.Parent = kart
				Icons.bind(ikon, SosyalOdul.ikon(odul))
			end

			UI.text({
				text = SosyalOdul.etiket(odul),
				size = UI.Sizes.small,
				font = UI.Fonts.bold,
				color = BEYAZ,
				align = Enum.TextXAlignment.Center,
				frameSize = UDim2.new(1, -6, 0, 20),
				position = UDim2.new(0, 3, 1, -70),
				parent = kart,
			})

			local dugme, yazi = durumDugmesi(kart, UDim2.new(1, -16, 0, 38), UI.Colors.gold)
			dugme.AnchorPoint = Vector2.new(0.5, 1)
			dugme.Position = UDim2.new(0.5, 0, 1, -8)
			dugme.MouseButton1Click:Connect(function()
				EkOdulAl:FireServer("playtime", i)
			end)

			ptKartlari[i] = { dugme = dugme, yazi = yazi }
		end
	end

	--[[
		Suresi dolmus ama henuz alinmamis bir Playtime odulu var mi.

		PANEL KAPALIYKEN DE BILINMELI: nokta oyuncuyu panele cagiran sey,
		panel acilana kadar bekleseydi hic gorunmezdi. Bu yuzden asagidaki
		sayac her saniye bunu hesapliyor, cizimi ise yalnizca sayfa acikken
		yapiyor.
	]]
	local function playtimeHazirMi(): boolean
		local gecen = os.clock() - ptBaslangic
		for i, odul in SosyalOdul.Playtime do
			local bilgi = if ekDurum and ekDurum.playtime then ekDurum.playtime[i] else nil
			if not (bilgi and bilgi.claimed) and odul.minutes * 60 - gecen <= 0 then
				return true
			end
		end
		return false
	end

	local function playtimeCiz()
		local gecen = os.clock() - ptBaslangic
		ptSureYazi.Text = `Time played: {SosyalOdul.sure(gecen)}`

		for i, odul in SosyalOdul.Playtime do
			local kart = ptKartlari[i]
			local bilgi = if ekDurum and ekDurum.playtime then ekDurum.playtime[i] else nil
			local kalan = odul.minutes * 60 - gecen

			if bilgi and bilgi.claimed then
				kart.dugme.BackgroundColor3 = GRI
				kart.yazi.Text = "Claimed"
			elseif kalan <= 0 then
				kart.dugme.BackgroundColor3 = UI.Colors.good
				kart.yazi.Text = "Claim"
			else
				kart.dugme.BackgroundColor3 = UI.Colors.warn
				kart.yazi.Text = SosyalOdul.sure(kalan)
			end
		end
	end

	------------------------------------------------------------------
	-- SOCIAL REWARDS
	------------------------------------------------------------------
	local soSayfa = odulSayfalari.social
	local KART_EN = (ODUL_W - 30) / 2
	local KART_BOY = 176

	-- Grup karti
	local grupKart = kutu(soSayfa, UDim2.fromOffset(10, ODUL_UST), UDim2.fromOffset(KART_EN, KART_BOY), ALTIN)

	local grupBaslik = UI.text({
		text = "",
		size = UI.Sizes.label,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -20, 0, 52),
		position = UDim2.fromOffset(10, 8),
		parent = grupKart,
		wrapped = true,
	})
	grupBaslik.RichText = true
	local grupAdi = if SosyalOdul.GroupName ~= "" then `"{SosyalOdul.GroupName}"` else "our Group"
	grupBaslik.Text = `Join <font color="#FFD728">{grupAdi}</font> for free Rot Coin!`

	local grupIkon = Instance.new("ImageLabel")
	grupIkon.AnchorPoint = Vector2.new(0.5, 0.5)
	grupIkon.Position = UDim2.new(0.5, 0, 0, 84)
	grupIkon.Size = UDim2.fromOffset(56, 56)
	grupIkon.BackgroundTransparency = 1
	grupIkon.ScaleType = Enum.ScaleType.Fit
	grupIkon.Parent = grupKart
	Icons.bind(grupIkon, "rotCoin")

	UI.text({
		text = `+{SosyalOdul.GroupReward} Rot Coin`,
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = ALTIN,
		align = Enum.TextXAlignment.Left,
		frameSize = UDim2.fromOffset(120, 24),
		position = UDim2.new(0.5, 34, 0, 72),
		parent = grupKart,
	})

	local grupDugme, grupYazi = durumDugmesi(grupKart, UDim2.fromOffset(170, 40), UI.Colors.good)
	grupDugme.AnchorPoint = Vector2.new(0.5, 1)
	grupDugme.Position = UDim2.new(0.5, 0, 1, -12)
	grupDugme.MouseButton1Click:Connect(function()
		EkOdulAl:FireServer("group")
	end)

	-- Like + Favorite karti
	local likeKart = kutu(
		soSayfa,
		UDim2.fromOffset(20 + KART_EN, ODUL_UST),
		UDim2.fromOffset(KART_EN, KART_BOY),
		Color3.fromRGB(90, 220, 110)
	)

	UI.text({
		text = "Like And Favorite!",
		size = UI.Sizes.heading,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -20, 0, 30),
		position = UDim2.fromOffset(10, 8),
		parent = likeKart,
	})

	local favoriSatir = UI.text({
		text = `<font color="#FFD728">Favorite</font> the game!`,
		size = UI.Sizes.label,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -20, 0, 26),
		position = UDim2.fromOffset(10, 44),
		parent = likeKart,
	})
	favoriSatir.RichText = true

	local likeSatir = UI.text({
		text = `<font color="#78FF96">Like</font> the game!  (+{SosyalOdul.LikeReward} Rot Coin)`,
		size = UI.Sizes.label,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -20, 0, 26),
		position = UDim2.fromOffset(10, 74),
		parent = likeKart,
	})
	likeSatir.RichText = true

	local likeDugme, likeYazi = durumDugmesi(likeKart, UDim2.fromOffset(170, 40), UI.Colors.good)
	likeDugme.AnchorPoint = Vector2.new(0.5, 1)
	likeDugme.Position = UDim2.new(0.5, 0, 1, -12)
	likeDugme.MouseButton1Click:Connect(function()
		if ekDurum and ekDurum.like and ekDurum.like.claimed then
			return
		end
		-- Roblox'un favori penceresi; begeni dogrulanamadigi icin odul bir kez verilir
		pcall(function()
			AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
		end)
		EkOdulAl:FireServer("like")
	end)

	-- Kod kutusu
	local KOD_Y = ODUL_UST + KART_BOY + 10
	local kodKart = kutu(
		soSayfa,
		UDim2.fromOffset(10, KOD_Y),
		UDim2.fromOffset(ODUL_W - 20, ODUL_H - KOD_Y - 12),
		Color3.fromRGB(170, 90, 230)
	)

	UI.text({
		text = "Redeem Codes for Rewards!",
		size = UI.Sizes.heading,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -20, 0, 28),
		position = UDim2.fromOffset(10, 6),
		parent = kodKart,
	})

	UI.text({
		text = "Like the game for codes! Find them in the description & on our socials!",
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -20, 0, 18),
		position = UDim2.fromOffset(10, 34),
		parent = kodKart,
	})

	local kodKutusu = Instance.new("TextBox")
	kodKutusu.Name = "KodKutusu"
	kodKutusu.AnchorPoint = Vector2.new(1, 0)
	kodKutusu.Position = UDim2.new(0.5, -6, 0, 58)
	kodKutusu.Size = UDim2.fromOffset(260, 46)
	kodKutusu.BackgroundColor3 = Color3.fromRGB(20, 18, 26)
	kodKutusu.BorderSizePixel = 0
	kodKutusu.ClearTextOnFocus = false
	kodKutusu.Text = ""
	kodKutusu.PlaceholderText = "Enter Code"
	kodKutusu.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
	kodKutusu.TextColor3 = BEYAZ
	kodKutusu.FontFace = UI.Fonts.bold
	kodKutusu.TextSize = UI.Sizes.heading
	kodKutusu.Parent = kodKart
	UI.corner(kodKutusu, 8)
	UI.stroke(kodKutusu, Color3.fromRGB(70, 60, 90), 2)

	local kodDugme, kodDugmeYazi = durumDugmesi(kodKart, UDim2.fromOffset(180, 46), Color3.fromRGB(70, 160, 230))
	kodDugme.Position = UDim2.new(0.5, 6, 0, 58)
	kodDugmeYazi.Text = "Redeem"
	kodDugmeYazi.TextSize = UI.Sizes.heading

	local kodSonucYazi = UI.text({
		text = "",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -20, 0, 20),
		position = UDim2.new(0, 10, 1, -24),
		parent = kodKart,
	})

	local function koduGonder()
		local kod = kodKutusu.Text
		if string.gsub(kod, "%s", "") == "" then
			return
		end
		KodKullan:FireServer(kod)
	end
	kodDugme.MouseButton1Click:Connect(koduGonder)
	kodKutusu.FocusLost:Connect(function(enter)
		if enter then
			koduGonder()
		end
	end)

	KodSonuc.OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then
			return
		end
		kodSonucYazi.Text = tostring(data.message or "")
		kodSonucYazi.TextColor3 = if data.ok then Color3.fromRGB(120, 255, 150) else Color3.fromRGB(255, 120, 120)
		if data.ok then
			kodKutusu.Text = ""
		end
	end)

	local function socialCiz()
		local grup = ekDurum and ekDurum.group
		if grup and grup.claimed then
			grupDugme.BackgroundColor3 = GRI
			grupYazi.Text = "Claimed"
		elseif SosyalOdul.GroupId == 0 then
			grupDugme.BackgroundColor3 = GRI
			grupYazi.Text = "Coming Soon"
		else
			grupDugme.BackgroundColor3 = UI.Colors.good
			grupYazi.Text = "Claim"
		end

		local like = ekDurum and ekDurum.like
		if like and like.claimed then
			likeDugme.BackgroundColor3 = GRI
			likeYazi.Text = "Claimed"
		else
			likeDugme.BackgroundColor3 = UI.Colors.good
			likeYazi.Text = "Claim"
		end

		--[[
			Grup ve like odulleri bir kereliktir: alinmamis biri varsa nokta
			yanar ve oyuncu alana kadar yanik kalir. Grup kimligi 0 iken odul
			"Coming Soon" demektir, sayilmaz.
		]]
		local grupAlinabilir = SosyalOdul.GroupId ~= 0 and not (grup and grup.claimed)
		Bildirim.odulSekmesi("social", grupAlinabilir or not (like and like.claimed))
	end

	EkOdulDurum.OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then
			return
		end
		ekDurum = data
		ptBaslangic = os.clock() - (tonumber(data.elapsed) or 0)
		playtimeCiz()
		Bildirim.odulSekmesi("playtime", playtimeHazirMi())
		socialCiz()
	end)

	playtimeCiz()
	Bildirim.odulSekmesi("playtime", playtimeHazirMi())
	socialCiz()

	--[[
		Playtime geri sayimi. Cizim yalnizca sayfa acikken yapilir ama
		BILDIRIM her saniye tazelenir: oyuncuyu panele cagiran sey o.
	]]
	task.spawn(function()
		while true do
			task.wait(1)
			Bildirim.odulSekmesi("playtime", playtimeHazirMi())
			if odulPanel.Visible and odulSayfalari.playtime.Visible then
				playtimeCiz()
			end
		end
	end)

	-- Artik hazir: panel acilinca durum istenir; acik ise hemen iste
	EkOdulAc = ekAc
	if odulPanel.Visible then
		ekAc:FireServer()
	end
end)


-- FRIENDS SEKMESI: yerelleri kendi blogunda (Luau ust seviyede en fazla 200 yerel kabul ediyor)
do
	------------------------------------------------------------------
	-- FRIENDS SEKMESI  --  arkadas buffi
	--
	-- Ayni sunucuda Roblox arkadasi olan oyuncu kazida +%15 sans alir. Bonus
	-- sunucuda hesaplanir (bkz. Modules > Arkadaslar); burasi yalnizca
	-- gosterir: buffun durumu, sunucudaki arkadaslar ve davet dugmesi.
	------------------------------------------------------------------
	local arkadasPanel = UI.panel(screen, UDim2.fromOffset(440, 440), "Arkadaslar")

	UI.text({
		text = "Friends",
		size = UI.Sizes.title,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(255, 120, 190),
		frameSize = UDim2.new(1, -80, 0, 34),
		position = UDim2.fromOffset(18, 14),
		parent = arkadasPanel,
	})

	UI.closeButton(arkadasPanel).MouseButton1Click:Connect(function()
		arkadasPanel.Visible = false
	end)

	local arkadasDurumYazi = UI.text({
		text = "",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -36, 0, 40),
		position = UDim2.fromOffset(18, 50),
		parent = arkadasPanel,
		wrapped = true,
	})

	local arkadasListe = makeScroll(arkadasPanel, UDim2.fromOffset(14, 98), UDim2.new(1, -28, 1, -172))

	local davetButon = UI.button(arkadasPanel, "Invite Friends", UDim2.new(1, -40, 0, 48), Color3.fromRGB(255, 120, 190))
	davetButon.AnchorPoint = Vector2.new(0.5, 1)
	davetButon.Position = UDim2.new(0.5, 0, 1, -16)

	-- Sunucudan gelen son durum
	local arkadasSayisi = 0
	local arkadasYuzde = 15
	local arkadasListesi: { any } = {}

	local function arkadasCiz()
		if arkadasSayisi > 0 then
			arkadasDurumYazi.Text = `Friend Boost active: +{arkadasYuzde}% Luck`
				.. `  ({arkadasSayisi} friend{if arkadasSayisi == 1 then "" else "s"} in this server)`
			arkadasDurumYazi.TextColor3 = Color3.fromRGB(120, 255, 150)
		else
			arkadasDurumYazi.Text = `Play in the same server with a friend to get +{arkadasYuzde}% Luck!`
			arkadasDurumYazi.TextColor3 = UI.Colors.textDim
		end

		clearRows(arkadasListe)

		if #arkadasListesi == 0 then
			UI.text({
				text = "No friends in this server yet. Invite them below!",
				size = UI.Sizes.small,
				color = UI.Colors.textDim,
				align = Enum.TextXAlignment.Center,
				frameSize = UDim2.new(1, 0, 0, 36),
				parent = arkadasListe,
				wrapped = true,
			})
			return
		end

		for sira, arkadas in arkadasListesi do
			local satir = Instance.new("Frame")
			satir.Name = `Arkadas{sira}`
			satir.Size = UDim2.new(1, -6, 0, 56)
			satir.BackgroundColor3 = UI.Colors.panelLight
			satir.BorderSizePixel = 0
			satir.LayoutOrder = sira
			satir.Parent = arkadasListe
			UI.corner(satir, 10)

			local avatar = Instance.new("ImageLabel")
			avatar.Name = "Avatar"
			avatar.Position = UDim2.fromOffset(6, 6)
			avatar.Size = UDim2.fromOffset(44, 44)
			avatar.BackgroundColor3 = UI.Colors.panel
			avatar.BorderSizePixel = 0
			avatar.Parent = satir
			UI.corner(avatar, 22)

			-- Avatar resmi web'den gelir ve bekletir: listeyi tutmasin
			local userId = tonumber(arkadas.userId)
			if userId then
				task.spawn(function()
					local ok, resim = pcall(function()
						return Players:GetUserThumbnailAsync(
							userId,
							Enum.ThumbnailType.HeadShot,
							Enum.ThumbnailSize.Size100x100
						)
					end)
					if ok and avatar.Parent then
						avatar.Image = resim
					end
				end)
			end

			UI.text({
				text = tostring(arkadas.displayName or arkadas.name or "?"),
				size = UI.Sizes.body,
				font = UI.Fonts.bold,
				frameSize = UDim2.new(1, -150, 0, 22),
				position = UDim2.fromOffset(60, 8),
				parent = satir,
			})

			UI.text({
				text = `@{tostring(arkadas.name or "?")}`,
				size = UI.Sizes.small,
				color = UI.Colors.textDim,
				frameSize = UDim2.new(1, -150, 0, 18),
				position = UDim2.fromOffset(60, 30),
				parent = satir,
			})

			UI.text({
				text = `+{arkadasYuzde}% Luck`,
				size = UI.Sizes.small,
				font = UI.Fonts.bold,
				color = Color3.fromRGB(120, 255, 150),
				align = Enum.TextXAlignment.Right,
				frameSize = UDim2.fromOffset(90, 22),
				position = UDim2.new(1, -100, 0.5, -11),
				parent = satir,
			})
		end
	end

	ArkadasDurum.OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then
			return
		end

		arkadasSayisi = tonumber(data.sayi) or 0
		arkadasYuzde = tonumber(data.yuzde) or arkadasYuzde
		arkadasListesi = if type(data.arkadaslar) == "table" then data.arkadaslar else {}

		-- Rot'un ustundeki buff yazisi
		arkadasBuff.Text = `Friend Boost: +{arkadasYuzde}% Luck`
		arkadasBuff.Visible = arkadasSayisi > 0
		solSutunuYerlestir()

		if arkadasPanel.Visible then
			arkadasCiz()
		end
	end)

	--[[
		DAVET
		Roblox'un kendi davet penceresi. Studio'da ve davete izin vermeyen
		hesaplarda acilamaz; o durumda panel sebebini yazar.
	]]
	davetButon.MouseButton1Click:Connect(function()
		local oyuncu = Players.LocalPlayer
		local ok, izin = pcall(function()
			return SocialService:CanSendGameInviteAsync(oyuncu)
		end)

		if ok and izin then
			pcall(function()
				SocialService:PromptGameInvite(oyuncu)
			end)
		else
			arkadasDurumYazi.Text = "Invites are not available right now (they don't work in Studio)."
			arkadasDurumYazi.TextColor3 = UI.Colors.warn
		end
	end)

	function arkadasPaneliniAc()
		arkadasPanel.Visible = not arkadasPanel.Visible
		if arkadasPanel.Visible then
			arkadasCiz()
			ArkadasAc:FireServer()
		end
	end
end


-- ROTCOIN MAGAZASI: yerelleri kendi blogunda (Luau ust seviyede en fazla 200 yerel kabul ediyor)
do
	------------------------------------------------------------------
	-- ROTCOIN MAGAZASI  (sol menude eski Pets butonunun yeri)
	--
	-- Urunler ve fiyatlar Shared > RotCoinMagaza'da; satin alma sunucuda
	-- dogrulanir. Panel yalnizca listeyi cizer ve id yollar.
	------------------------------------------------------------------
	local RC_SARI = Color3.fromRGB(255, 215, 40)
	--[[
		Lucky Block satirlarinda ikon yerine blogun kendi modeli gosteriliyor.
		Require BLOK ICINDE: ust seviye 195 yerelle sinira yakin (bkz. dosya
		basindaki not ve tools/check.luau).
	]]
	local Assets = require(Shared:WaitForChild("Assets"))
	--[[
		Parsomen (scroll) modelleri. Bu require KAYIPTI: satir dongusu scroll
		urunune gelince "attempt to index nil with 'model'" hatasi veriyor ve
		ondan SONRAKI urunler (sans iksirleri) hic cizilmiyordu.
	]]
	local Scrolls = require(Shared:WaitForChild("Scrolls"))

	local rcPanel = UI.panel(screen, UDim2.fromOffset(520, 540), "RotCoinMagaza")

	UI.baslikCubugu(rcPanel, "Rot Coin Shop", RC_SARI, Color3.fromRGB(255, 130, 40), "rotCoin")

	UI.closeButton(rcPanel).MouseButton1Click:Connect(function()
		rcPanel.Visible = false
	end)

	local rcBakiyeYazi = UI.text({
		text = "",
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = RC_SARI,
		frameSize = UDim2.new(1, -36, 0, 24),
		position = UDim2.fromOffset(18, 72),
		parent = rcPanel,
	})

	local rcIksirYazi = UI.text({
		text = "",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -36, 0, 20),
		position = UDim2.fromOffset(18, 98),
		parent = rcPanel,
	})

	--[[
		LISTE BIR CanvasGroup ICINDE

		Satirlardaki ikonlar UI.sallan ile DONDURULUYOR; Roblox dondurulmus
		nesneyi ScrollingFrame'in kirpmasiyla kesmiyor. Kaydirinca yonca ve
		Lucky Block gorselleri listenin disina tasiyordu (Store'da ayni sorun
		ayni yolla cozuldu). CanvasGroup once kendi yuzeyine ciziyor ve o
		yuzeyi kendi sinirinda kesiyor.
	]]
	local rcListeKabi = Instance.new("CanvasGroup")
	rcListeKabi.Name = "ListeKabi"
	rcListeKabi.Position = UDim2.fromOffset(14, 126)
	rcListeKabi.Size = UDim2.new(1, -28, 1, -140)
	rcListeKabi.BackgroundTransparency = 1
	rcListeKabi.BorderSizePixel = 0
	rcListeKabi.Parent = rcPanel

	local rcListe = makeScroll(rcListeKabi, UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1))

	-- Sunucudan gelen son durum
	local rcBakiye = inventory.rotCoins or 0
	local iksirCarpan = 1
	-- Iksirin bitecegi an (os.clock); istemci kendi sayar, sunucu her alista duzeltir
	local iksirBitis = 0

	local function iksirKalan(): number
		return if iksirCarpan > 1 then math.max(0, iksirBitis - os.clock()) else 0
	end

	local function iksirYazilariniGuncelle()
		local kalan = iksirKalan()
		local aktif = kalan > 0

		if aktif then
			local yazi = `{RotCoinMagaza.carpanYazisi(iksirCarpan)} Luck ({RotCoinMagaza.sureYazisi(kalan)})`
			iksirBuff.Text = yazi
			rcIksirYazi.Text = `Active: {yazi}`
			rcIksirYazi.TextColor3 = Color3.fromRGB(90, 220, 255)
		else
			rcIksirYazi.Text = "No luck active"
			rcIksirYazi.TextColor3 = UI.Colors.textDim
		end

		if iksirBuff.Visible ~= aktif then
			iksirBuff.Visible = aktif
			solSutunuYerlestir()
		end
	end

	--[[
		CANLI KART ZEMINI  --  kristal dokusu + kayan isik

		Satir urunun renginde PARLAK bir levha: ustu acik, alti koyu; uzerine
		capraz kristal yuzeyleri ve butun satiri sagdan sola tarayan genis
		bir isik bandi biniyor. Ikisi de surekli hareket ettigi icin kart
		canli duruyor.

		Bandi DONDURMUYORUZ: dondurulmus nesneyi ClipsDescendants kirpmiyor
		(bkz. UI.luau notlari), bant kartin disina tasardi. Egik gorunumu
		UIGradient'in acisi veriyor.
	]]
	local function canliZemin(kart: Frame, renk: Color3)
		kart.BackgroundColor3 = Color3.new(1, 1, 1)
		kart.ClipsDescendants = true

		-- Ustu acik, alti koyu: madeni levha hissi
		local zemin = Instance.new("UIGradient")
		zemin.Rotation = 90
		zemin.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, UI.shade(renk, 0.24)),
			ColorSequenceKeypoint.new(0.45, renk),
			ColorSequenceKeypoint.new(1, UI.shade(renk, -0.3)),
		})
		zemin.Parent = kart

		-- Kristal yuzeyleri: iki capraz serit katmani, agir agir kayiyor
		for i, aci in { 26, -26 } do
			local doku = UI.stripeLayer(kart, Color3.new(1, 1, 1), aci, 4, if i == 1 then 0.88 else 0.92)
			doku.ZIndex = 2
			UI.corner(doku, 12)

			local gecis = doku:FindFirstChildOfClass("UIGradient")
			if gecis then
				gecis.Offset = Vector2.new(if i == 1 then -0.5 else 0.5, 0)
				TweenService:Create(
					gecis,
					TweenInfo.new(if i == 1 then 9 else 12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
					{ Offset = Vector2.new(if i == 1 then 0.5 else -0.5, 0) }
				):Play()
			end
		end

		-- Satiri tarayan genis isik bandi
		local isik = Instance.new("Frame")
		isik.Name = "Tarama"
		isik.Size = UDim2.fromScale(1, 1)
		isik.BackgroundColor3 = Color3.new(1, 1, 1)
		isik.BorderSizePixel = 0
		isik.ZIndex = 3
		isik.Parent = kart
		UI.corner(isik, 12)

		local bant = Instance.new("UIGradient")
		bant.Rotation = 18
		bant.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.42, 1),
			NumberSequenceKeypoint.new(0.5, 0.72),
			NumberSequenceKeypoint.new(0.58, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		bant.Offset = Vector2.new(-1.3, 0)
		bant.Parent = isik
		TweenService:Create(
			bant,
			TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 1.6),
			{ Offset = Vector2.new(1.3, 0) }
		):Play()
	end

	--[[
		KART RESIMLERI  (Assets > Icons)

		Satir zeminleri ve buton resmi Studio'ya elle konuyor; kod once
		onlari arar, bulamazsa yukaridaki canliZemin cizimine duser.

		  rc_bg_normal / rc_bg_golden / rc_bg_diamond   Lucky Block zeminleri
		  rc_bg_<urun id>                               tek bir urune ozel zemin
		  rc_bg                                         kalan urunlerin zemini
		  rc_button / rc_button_pasif                   fiyat dugmesi (alinabilir / alinamaz)

		Ad kuralsiz: buyuk/kucuk harf, bosluk ve alt cizge farki onemsiz.
	]]
	local function kartResmi(urun: any): string?
		local adaylar: { string } = {}
		if urun.kind == "luckyblock" and urun.tier then
			table.insert(adaylar, `rc_bg_{string.lower(urun.tier)}`)
		end
		table.insert(adaylar, `rc_bg_{string.lower(urun.id)}`)
		--[[
			GENEL "rc_bg" BILEREK EN SONDA VE TUR BASINA:
			iksir/parsomen satirlari Lucky Block zeminine (turkuaz kristal)
			dusunce magaza tek tip ve yanlis gorunuyordu. Once turune ozel
			resim aranir; hicbiri yoksa satir KENDI renginde cizilir.
		]]
		table.insert(adaylar, `rc_bg_{string.lower(urun.kind)}`)

		for _, ad in adaylar do
			local resim = Icons.assetTam(ad) or Icons.asset(ad)
			if resim then
				return resim
			end
		end
		return nil
	end

	--[[
		RESIMLI ZEMIN  --  akan doku + tarayan isik

		Resim satirdan GENIS kuruluyor ve icinde saga sola suzuluyor; satir
		kirptigi icin disari tasmiyor. Boylece kristal yuzey donuk bir
		fotograf gibi durmuyor, akiyor. Ustunden ayrica genis bir isik bandi
		geciyor.

		faz: her satir farkli anda baslasin diye gecikme (sira numarasi).
	]]
	local function resimliZemin(kart: Frame, resim: string, faz: number)
		kart.BackgroundTransparency = 1
		kart.ClipsDescendants = true

		local zemin = Instance.new("ImageLabel")
		zemin.Name = "Zemin"
		zemin.AnchorPoint = Vector2.new(0.5, 0.5)
		zemin.Position = UDim2.fromScale(0.44, 0.5)
		-- Satirdan genis: kayarken kenarda bosluk acilmasin
		zemin.Size = UDim2.fromScale(1.3, 1.16)
		zemin.BackgroundTransparency = 1
		zemin.Image = resim
		zemin.ScaleType = Enum.ScaleType.Stretch
		zemin.ZIndex = 1
		zemin.Parent = kart

		-- Doku ileri geri akar (her satir kendi gecikmesiyle)
		TweenService:Create(
			zemin,
			TweenInfo.new(5.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, faz * 0.5),
			{ Position = UDim2.fromScale(0.56, 0.5) }
		):Play()

		local isik = Instance.new("Frame")
		isik.Name = "Tarama"
		isik.Size = UDim2.fromScale(1, 1)
		isik.BackgroundColor3 = Color3.new(1, 1, 1)
		isik.BorderSizePixel = 0
		isik.ZIndex = 2
		isik.Parent = kart
		UI.corner(isik, 12)

		local bant = Instance.new("UIGradient")
		bant.Rotation = 18
		bant.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.44, 1),
			NumberSequenceKeypoint.new(0.5, 0.82),
			NumberSequenceKeypoint.new(0.56, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		bant.Offset = Vector2.new(-1.3, 0)
		bant.Parent = isik
		TweenService:Create(
			bant,
			TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 2 + faz * 0.35),
			{ Offset = Vector2.new(1.3, 0) }
		):Play()
	end

	--[[
		DONEN LUCKY BLOCK ONIZLEMESI  --  Store'daki ile ayni

		Blok tam karsidan degil ucte-dortluk acidan duruyor ve UI.sallan'in
		ritminde kendi ekseninde salliniyor. Hepsi TEK RenderStepped'te
		donuyor; panel kapaliyken dongu ilk satirda cikiyor.

		ViewportFrame parcacik/isin/isik CIZMEZ (Roblox siniri); blogun
		etrafindaki parlamayi UI.parlama veriyor.
	]]
	local RC_BAKIS = Vector3.new(0, 0, -1)
	local RC_DURUS = CFrame.Angles(0, math.rad(28), 0) * CFrame.Angles(math.rad(-16), 0, 0)
	local RC_CERCEVE = 0.78
	local RC_ISIK = Color3.fromRGB(255, 255, 255)

	-- Sallanan onizlemeler (satirlar yeniden cizilince listeden dusuyorlar)
	local rcOnizlemeler: { { model: Model, merkez: Vector3, taban: CFrame } } = {}

	-- Kadraj yalnizca GORUNUR parcalardan: gorunmez tutamaklar blogu kucultmesin
	local function rcGorunenKutu(model: Model): (Vector3?, Vector3?)
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

	--[[
		Madalyonun icine blogun donen 3B onizlemesini kurar.
		Model bulunamazsa false doner; cagiran taraf ikona duser.
	]]
	local function rcLuckyOnizleme(kutu: GuiObject, tier: any): boolean
		local model = Assets.luckyBlockModel(tier.modelName or tier.displayName, tier.order)
		if not model then
			return false
		end

		-- Onizlemede script ve ses calismasin; efektler dursun (zaten cizilmiyorlar)
		for _, nesne in model:GetDescendants() do
			if nesne:IsA("BaseScript") or nesne:IsA("Sound") then
				nesne:Destroy()
			end
		end

		local merkez, kutuBoyut = rcGorunenKutu(model)
		if not merkez or not kutuBoyut then
			model:Destroy()
			return false
		end

		local vp = Instance.new("ViewportFrame")
		vp.Name = "Onizleme"
		vp.AnchorPoint = Vector2.new(0.5, 0.5)
		vp.Position = UDim2.fromScale(0.5, 0.5)
		vp.Size = UDim2.fromScale(0.92, 0.92)
		vp.BackgroundTransparency = 1
		vp.Ambient = RC_ISIK
		vp.LightColor = RC_ISIK
		vp.LightDirection = Vector3.new(-0.4, -0.7, -0.6)
		vp.ZIndex = 6
		vp.Parent = kutu

		model.Parent = vp

		local kamera = Instance.new("Camera")
		kamera.Parent = vp
		vp.CurrentCamera = kamera
		kamera.CFrame = CFrame.lookAt(merkez + RC_BAKIS * kutuBoyut.Magnitude * RC_CERCEVE, merkez)

		table.insert(rcOnizlemeler, { model = model, merkez = merkez, taban = model:GetPivot() })
		return true
	end

	-- RunService ust seviyede yerel degil (200 yerel siniri): servis burada alinir
	game:GetService("RunService").RenderStepped:Connect(function()
		if not rcPanel.Visible then
			return
		end

		-- UI.sallan ile ayni ritim: tam donem sallanma suresinin iki kati
		local aci = math.rad(UI.SallanmaAci) * math.sin(os.clock() * math.pi / UI.SallanmaSuresi)

		for i = #rcOnizlemeler, 1, -1 do
			local kayit = rcOnizlemeler[i]
			if not kayit.model.Parent then
				-- Satir yeniden cizildi: kayit listeden duser
				rcOnizlemeler[i] = rcOnizlemeler[#rcOnizlemeler]
				rcOnizlemeler[#rcOnizlemeler] = nil
				continue
			end

			local donus = CFrame.new(kayit.merkez)
				* CFrame.Angles(0, aci, 0)
				* RC_DURUS
				* CFrame.new(-kayit.merkez)
			kayit.model:PivotTo(donus * kayit.taban)
		end
	end)

	local function rcCiz()
		rcBakiyeYazi.Text = `You have {Format.short(rcBakiye)} Rot Coin`
		iksirYazilariniGuncelle()

		clearRows(rcListe)

		for sira, urun in RotCoinMagaza.Urunler do
			local yeter = rcBakiye >= urun.price

			local satir = Instance.new("Frame")
			satir.Name = urun.id
			satir.Size = UDim2.new(1, -6, 0, 84)
			satir.BorderSizePixel = 0
			satir.LayoutOrder = sira
			satir.Parent = rcListe
			UI.corner(satir, 12)
			--[[
				Zemin: Assets > Icons icinde resim varsa O, yoksa renkli
				canli levha cizimi (bkz. kartResmi / canliZemin).
			]]
			--[[
				HACKER SCROLL: zemin SIYAH. Yesil zeminde yesil rakam yagmuru
				kayboluyordu; siyahta Matrix gibi okunuyor.
			]]
			local zeminRenk = if urun.scroll == "HackerMutation"
				then Color3.fromRGB(10, 12, 12)
				else urun.color

			local kartZemini = kartResmi(urun)
			if kartZemini then
				resimliZemin(satir, kartZemini, sira)
			else
				canliZemin(satir, zeminRenk)
			end
			UI.stroke(satir, Color3.fromRGB(0, 0, 0), 3)

			local ikon = Instance.new("ImageLabel")
			ikon.Name = "Ikon"
			ikon.Position = UDim2.fromOffset(10, 10)
			ikon.Size = UDim2.fromOffset(64, 64)
			ikon.ZIndex = 5
			-- Ikon koyu yuvarlak bir rozetin icinde: renkli zeminde kaybolmasin
			ikon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			ikon.BackgroundTransparency = 0.55
			ikon.ScaleType = Enum.ScaleType.Fit
			ikon.Parent = satir
			UI.corner(ikon, 32)
			-- Koyu madalyonun kenari: zeminde kaybolmasin
			UI.stroke(ikon, Color3.fromRGB(0, 0, 0), 2)
			-- Store'la ayni ritimde sallanir; donmez, urunun yuzu ekranda kalir
			UI.sallan(ikon)
			--[[
				SCROLL'DA IKON YERINE MODEL

				Parsomenin ikonu yok; onun yerine kendi Tool modeli kucuk bir
				ViewportFrame'de gosteriliyor (hotbarda gorunenle ayni sey).
				Model bulunamazsa Output'a yazilir ve ikona dusulur.
			]]
			local modelKondu = false

			--[[
				LUCKY BLOCK'TA DA IKON YERINE MODEL

				Paketteki "?" kutusu yerine blogun KENDI modeli gosteriliyor
				(Assets > LuckyBlocks); oyuncu satin alacagi blogu birebir
				goruyor. Model bulunamazsa eski ikona dusulur.
			]]
			if urun.kind == "luckyblock" and urun.tier then
				local tur = LuckyBlock.get(urun.tier)
				modelKondu = tur ~= nil and rcLuckyOnizleme(ikon, tur)

				if modelKondu then
					-- Blogun arkasinda kendi renginde yumusak parlama
					UI.parlama(satir, urun.color, 74, 4).Position =
						UDim2.fromOffset(ikon.Position.X.Offset + 32, 42)
				else
					warn(
						`[RotCoinMagaza] Lucky Block modeli bulunamadi: ReplicatedStorage > `
							.. `Assets > LuckyBlocks ({urun.tier})`
					)
				end
			end

			--[[
				HACKER TEMASI: Store'daki Hacker Lucky Block kartinin aynisi --
				satirin uzerinden asagi akan yesil rakamlar.
			]]
			if urun.kind == "scroll" and urun.scroll == "HackerMutation" then
				UI.corner(UI.sayiYagmuru(satir, Color3.fromRGB(90, 255, 140), 18, 2, 1.8, 0.32), 12)
			end

			if urun.kind == "scroll" and urun.scroll then
				local model = Scrolls.model(urun.scroll)
				if model then
					local kare = UI.modelKaresi(ikon, model, 54, 3)
					if kare then
						kare.AnchorPoint = Vector2.new(0.5, 0.5)
						kare.Position = UDim2.fromScale(0.5, 0.5)
						modelKondu = true
					end
				else
					local info = Scrolls.get(urun.scroll)
					warn(
						`[RotCoinMagaza] Scroll modeli bulunamadi: ReplicatedStorage > Assets > `
							.. `Scrolls > {if info then info.modelAdi else urun.scroll}`
					)
				end
			end

			if not modelKondu then
				--[[
					IKON YOKSA BOS DAIRE KALMASIN

					Paketteki sans iksiri ikonlari (luck2 / luck3) bazi
					paketlerde yok; madalyon bombos duruyordu. Ikon gelene
					kadar yerinde urunun kisa etiketi durur: iksirde carpan
					("x1.5"), digerlerinde adin ilk harfi.
				]]
				local kisa = if urun.kind == "potion" and urun.multiplier
					then RotCoinMagaza.carpanYazisi(urun.multiplier)
					else string.upper(string.sub(urun.name, 1, 1))

				local yedek = UI.text({
					text = kisa,
					size = UI.Sizes.label,
					font = UI.Fonts.bold,
					color = Color3.new(1, 1, 1),
					align = Enum.TextXAlignment.Center,
					frameSize = UDim2.fromScale(1, 1),
					parent = ikon,
					zIndex = 6,
				})

				Icons.bind(ikon, urun.icon, function(ok)
					if ok then
						yedek.Visible = false
					end
				end)

				-- Renk tonu yalnizca IKONA; model kendi rengiyle kalir
				if urun.tint then
					ikon.ImageColor3 = Color3.new(1, 1, 1):Lerp(urun.color, 0.35)
				end
			end

			UI.text({
				text = urun.name,
				size = UI.Sizes.body,
				font = UI.Fonts.bold,
				color = Color3.new(1, 1, 1),
				frameSize = UDim2.new(1, -240, 0, 26),
				position = UDim2.fromOffset(86, 14),
				parent = satir,
				zIndex = 5,
			})

			UI.text({
				text = urun.desc,
				size = UI.Sizes.tiny,
				color = Color3.fromRGB(240, 244, 252),
				frameSize = UDim2.new(1, -240, 0, 30),
				position = UDim2.fromOffset(86, 42),
				parent = satir,
				wrapped = true,
				zIndex = 5,
			})

			--[[
				FIYAT DUGMESI

				Para yetiyorsa yesil, yetmiyorsa gri. Yazinin sagindaki
				kucuk madeni para (Icons "rotCoin") fiyatin neyle odendigini
				bir bakista soyluyor.
			]]
			--[[
				Dugme resmi varsa (rc_button / rc_button_pasif) o kullanilir;
				yoksa oyunun 3B cizim dugmesi.
			]]
			local butonResmi = if yeter
				then (Icons.assetTam("rc_button") or Icons.asset("rc_button"))
				else (Icons.assetTam("rc_button_pasif") or Icons.asset("rc_button_pasif"))

			local buton: GuiButton
			local butonYuz: GuiObject
			local butonYazi: TextLabel?

			if butonResmi then
				local resimli = Instance.new("ImageButton")
				resimli.Name = "SatinAl"
				resimli.BackgroundTransparency = 1
				resimli.Image = butonResmi
				resimli.ScaleType = Enum.ScaleType.Stretch
				resimli.AutoButtonColor = false
				resimli.Size = UDim2.fromOffset(150, 56)
				resimli.Parent = satir
				UI.hover(resimli, nil, resimli)

				butonYazi = UI.text({
					text = tostring(urun.price),
					size = UI.Sizes.label,
					font = UI.Fonts.bold,
					align = Enum.TextXAlignment.Center,
					frameSize = UDim2.fromScale(1, 1),
					parent = resimli,
					zIndex = 6,
				})

				buton = resimli
				butonYuz = resimli
			else
				local dugme, yuz, yazi = UI.dugme3B(
					satir,
					tostring(urun.price),
					UDim2.fromOffset(150, 56),
					if yeter then Color3.fromRGB(70, 205, 85) else UI.KapaliRenk
				)
				buton = dugme
				butonYuz = yuz
				butonYazi = yazi
			end

			buton.AnchorPoint = Vector2.new(1, 0.5)
			buton.Position = UDim2.new(1, -12, 0.5, 0)
			buton.ZIndex = 5

			if butonYazi then
				-- Yazi solda, para ikonuna yer birakir
				butonYazi.Size = UDim2.new(1, -34, 1, 0)
				butonYazi.Position = UDim2.fromOffset(2, 0)
			end

			do
				local para = Instance.new("ImageLabel")
				para.Name = "Coin"
				para.AnchorPoint = Vector2.new(1, 0.5)
				para.Position = UDim2.new(1, -8, 0.5, 0)
				para.Size = UDim2.fromOffset(26, 26)
				para.BackgroundTransparency = 1
				para.ScaleType = Enum.ScaleType.Fit
				para.ZIndex = 6
				para.Parent = butonYuz
				Icons.bind(para, "rotCoin")
			end
			buton.MouseButton1Click:Connect(function()
				RotCoinMagazaAl:FireServer(urun.id)
			end)
		end
	end

	function rotCoinMagazaAc()
		rcPanel.Visible = not rcPanel.Visible
		if rcPanel.Visible then
			rcCiz()
			RotCoinMagazaAc:FireServer()
		end
	end

	-- Bakiye degisince (odul, satin alma) acik panel tazelensin
	EnvanterGuncelle.OnClientEvent:Connect(function(data)
		if type(data) ~= "table" or type(data.rotCoins) ~= "number" then
			return
		end
		rcBakiye = data.rotCoins
		if rcPanel.Visible then
			rcCiz()
		end
	end)

	RotCoinMagazaDurum.OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then
			return
		end
		iksirCarpan = tonumber(data.carpan) or 1
		iksirBitis = os.clock() + (tonumber(data.kalan) or 0)
		iksirYazilariniGuncelle()
	end)

	-- Geri sayim: saniyede bir yazilar guncellenir, sure bitince yazi kalkar
	task.spawn(function()
		while true do
			task.wait(1)
			iksirYazilariniGuncelle()
		end
	end)

	RotCoinMagazaAc:FireServer()
end

-- AYARLAR PANELI: yerelleri kendi blogunda (Luau ust seviyede en fazla 200 yerel kabul ediyor)
do
	------------------------------------------------------------------
	-- AYARLAR PANELI  (Settings)
	--
	-- Panelin butun metinleri INGILIZCE -- oyuncunun gordugu her yer oyle.
	--
	-- Iki ayar var:
	--   ARAYUZ OLCEGI  -- UI modulu uyguluyor (UI.setScale butun ScreenGui'lere
	--                     UIScale koyar)
	--   MUZIK          -- arka plan muziginin sesi ve ac/kapat (bkz. Muzik modulu)
	--   SES EFEKTLERI  -- muzik disindaki butun sesler (bkz. SesEfekti modulu)
	-- Burasi yalnizca paneli cizer ve secilen degerleri sunucuya kaydeder.
	--
	-- Deger sunucuda PlayerData icinde durur (uiScale), boylece oyuncu
	-- cikip girince ayari yerinde kalir.
	------------------------------------------------------------------
	local ayarPanel = UI.panel(screen, UDim2.fromOffset(430, 560), "Ayarlar")

	UI.text({
		text = "Settings",
		size = UI.Sizes.title,
		font = UI.Fonts.bold,
		frameSize = UDim2.new(1, -80, 0, 36),
		position = UDim2.fromOffset(18, 14),
		parent = ayarPanel,
	})

	UI.closeButton(ayarPanel).MouseButton1Click:Connect(function()
		ayarPanel.Visible = false
	end)

	UI.text({
		text = "INTERFACE SCALE",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -36, 0, 20),
		position = UDim2.fromOffset(18, 62),
		parent = ayarPanel,
	})

	UI.text({
		text = "Resizes every menu and HUD element.",
		size = UI.Sizes.small,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -36, 0, 20),
		position = UDim2.fromOffset(18, 84),
		parent = ayarPanel,
	})

	-- Buyutme/kucultme ikilisi ve aralarindaki yuzde yazisi
	local kucultButon = UI.button(ayarPanel, "-", UDim2.fromOffset(62, 52), UI.Colors.panelLight)
	kucultButon.Name = "Kucult"
	kucultButon.Position = UDim2.fromOffset(18, 116)

	local olcekYazi = UI.text({
		text = "100%",
		size = UI.Sizes.title,
		font = UI.Fonts.bold,
		color = UI.Colors.gold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(250, 52),
		position = UDim2.fromOffset(90, 116),
		parent = ayarPanel,
	})

	local buyutButon = UI.button(ayarPanel, "+", UDim2.fromOffset(62, 52), UI.Colors.panelLight)
	buyutButon.Name = "Buyut"
	buyutButon.Position = UDim2.fromOffset(350, 116)

	-- "+" ve "-" isaretleri govde yazisi boyunda kucuk kaliyordu
	local function isaretiBuyut(buton: TextButton)
		local etiket = buton:FindFirstChild("Label")
		if etiket and etiket:IsA("TextLabel") then
			etiket.TextSize = UI.Sizes.heading
		end
	end

	isaretiBuyut(kucultButon)
	isaretiBuyut(buyutButon)

	local sifirlaButon = UI.button(ayarPanel, "Reset to 100%", UDim2.new(1, -36, 0, 44), UI.Colors.panelLight)
	sifirlaButon.Name = "Sifirla"
	sifirlaButon.Position = UDim2.fromOffset(18, 182)

	UI.text({
		text = `Range {UI.ScaleMin}% - {UI.ScaleMax}%   -   saved automatically`,
		size = UI.Sizes.small,
		color = UI.Colors.textDim,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -36, 0, 20),
		position = UDim2.fromOffset(18, 240),
		parent = ayarPanel,
	})

	------------------------------------------------------------------
	-- MUZIK: ses seviyesi (-/+) ve ac/kapat
	------------------------------------------------------------------
	UI.text({
		text = "MUSIC",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -36, 0, 20),
		position = UDim2.fromOffset(18, 276),
		parent = ayarPanel,
	})

	local MUZIK_ADIM = 10

	--[[
		SES SATIRI: [-] yuzde [+] [ON/OFF]

		Muzik ve ses efektleri ayni duzende, alt alta. Ac/kapat dugmesinin
		rengi durumla degisir: UI.hover kullanilmaz (rengi geri cevirirdi).
	]]
	local function sesSatiri(ad: string, y: number)
		local kis = UI.button(ayarPanel, "-", UDim2.fromOffset(52, 52), UI.Colors.panelLight)
		kis.Name = `{ad}Kis`
		kis.Position = UDim2.fromOffset(18, y)

		local yazi = UI.text({
			text = "100%",
			size = UI.Sizes.title,
			font = UI.Fonts.bold,
			color = UI.Colors.gold,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.fromOffset(110, 52),
			position = UDim2.fromOffset(74, y),
			parent = ayarPanel,
		})

		local ac = UI.button(ayarPanel, "+", UDim2.fromOffset(52, 52), UI.Colors.panelLight)
		ac.Name = `{ad}Ac`
		ac.Position = UDim2.fromOffset(188, y)

		isaretiBuyut(kis)
		isaretiBuyut(ac)

		local dugme = Instance.new("TextButton")
		dugme.Name = `{ad}AcKapat`
		dugme.Position = UDim2.fromOffset(252, y)
		dugme.Size = UDim2.fromOffset(160, 52)
		dugme.AutoButtonColor = false
		dugme.BorderSizePixel = 0
		dugme.Text = ""
		dugme.Parent = ayarPanel
		UI.corner(dugme, 10)
		UI.stroke(dugme, Color3.fromRGB(0, 0, 0), 2)

		local dugmeYazi = UI.text({
			text = "",
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = Color3.new(1, 1, 1),
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.fromScale(1, 1),
			parent = dugme,
		})

		return kis, yazi, ac, dugme, dugmeYazi
	end

	local muzikKisButon, muzikYazi, muzikAcButon, muzikDugme, muzikDugmeYazi = sesSatiri("Muzik", 302)

	UI.text({
		text = "SOUND EFFECTS",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -36, 0, 20),
		position = UDim2.fromOffset(18, 370),
		parent = ayarPanel,
	})

	local efektKisButon, efektYazi, efektAcButon, efektDugme, efektDugmeYazi = sesSatiri("Efekt", 396)

	--[[
		EKRAN SARSINTISI: tek ac/kapat. Deger oyuncunun "SarsintiKapali"
		niteliginde durur; kazi, Fuse ve Lucky Block sarsintilari onu okur.
	]]
	UI.text({
		text = "SCREEN SHAKE",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -36, 0, 20),
		position = UDim2.fromOffset(18, 464),
		parent = ayarPanel,
	})

	local sarsintiDugme = Instance.new("TextButton")
	sarsintiDugme.Name = "SarsintiAcKapat"
	sarsintiDugme.Position = UDim2.fromOffset(18, 490)
	sarsintiDugme.Size = UDim2.new(1, -36, 0, 48)
	sarsintiDugme.AutoButtonColor = false
	sarsintiDugme.BorderSizePixel = 0
	sarsintiDugme.Text = ""
	sarsintiDugme.Parent = ayarPanel
	UI.corner(sarsintiDugme, 10)
	UI.stroke(sarsintiDugme, Color3.fromRGB(0, 0, 0), 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local sarsintiYazi = UI.text({
		text = "",
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = Color3.new(1, 1, 1),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = sarsintiDugme,
	})

	local function sarsintiKapaliMi(): boolean
		return player:GetAttribute("SarsintiKapali") == true
	end

	local function sarsintiCiz()
		local kapali = sarsintiKapaliMi()
		sarsintiDugme.BackgroundColor3 = if kapali then Color3.fromRGB(200, 70, 80) else UI.Colors.good
		sarsintiYazi.Text = if kapali then "Screen Shake: OFF" else "Screen Shake: ON"
	end
	player:GetAttributeChangedSignal("SarsintiKapali"):Connect(sarsintiCiz)

	--[[
		SUNUCUYA KAYIT

		Butona her basista remote atilmasin diye son degisiklikten 0.4 saniye
		sonra TEK sefer gonderilir. Oyuncu ard arda bassa bile sunucuya tek
		istek gider.
	]]
	local ayarKaydiBekliyor = false

	local function ayarKaydiniPlanla()
		if ayarKaydiBekliyor then
			return
		end
		ayarKaydiBekliyor = true

		task.delay(0.4, function()
			ayarKaydiBekliyor = false
			AyarKaydet:FireServer({
				uiScale = UI.getScale(),
				musicVolume = Muzik.yuzde(),
				musicMuted = Muzik.kapali(),
				sfxVolume = SesEfekti.yuzde(),
				sfxMuted = SesEfekti.kapali(),
				shakeOff = player:GetAttribute("SarsintiKapali") == true,
			})
		end)
	end

	local function olcekYazisiTazele(yuzde: number)
		olcekYazi.Text = `{yuzde}%`
	end

	local function olcegiDegistir(fark: number)
		olcekYazisiTazele(UI.setScale(UI.getScale() + fark))
		ayarKaydiniPlanla()
	end

	kucultButon.MouseButton1Click:Connect(function()
		olcegiDegistir(-UI.ScaleStep)
	end)

	buyutButon.MouseButton1Click:Connect(function()
		olcegiDegistir(UI.ScaleStep)
	end)

	sifirlaButon.MouseButton1Click:Connect(function()
		olcekYazisiTazele(UI.setScale(UI.ScaleDefault))
		ayarKaydiniPlanla()
	end)

	local function muzikCiz()
		local kapali = Muzik.kapali()
		muzikYazi.Text = if kapali then "OFF" else `{Muzik.yuzde()}%`
		muzikYazi.TextColor3 = if kapali then UI.Colors.textDim else UI.Colors.gold
		muzikDugme.BackgroundColor3 = if kapali then Color3.fromRGB(200, 70, 80) else UI.Colors.good
		muzikDugmeYazi.Text = if kapali then "OFF" else "ON"
	end

	local function efektCiz()
		local kapali = SesEfekti.kapali()
		efektYazi.Text = if kapali then "OFF" else `{SesEfekti.yuzde()}%`
		efektYazi.TextColor3 = if kapali then UI.Colors.textDim else UI.Colors.gold
		efektDugme.BackgroundColor3 = if kapali then Color3.fromRGB(200, 70, 80) else UI.Colors.good
		efektDugmeYazi.Text = if kapali then "OFF" else "ON"
	end

	local function efektSesDegistir(fark: number)
		-- Ses degistirmek kapali efektleri de acar
		SesEfekti.ayarla(SesEfekti.yuzde() + fark, false)
		efektCiz()
		ayarKaydiniPlanla()
	end

	efektKisButon.MouseButton1Click:Connect(function()
		efektSesDegistir(-MUZIK_ADIM)
	end)

	efektAcButon.MouseButton1Click:Connect(function()
		efektSesDegistir(MUZIK_ADIM)
	end)

	sarsintiDugme.MouseButton1Click:Connect(function()
		-- Hemen etkili olsun; sunucu kaydedip ayni degeri geri yazar
		player:SetAttribute("SarsintiKapali", not sarsintiKapaliMi())
		sarsintiCiz()
		ayarKaydiniPlanla()
	end)

	efektDugme.MouseButton1Click:Connect(function()
		SesEfekti.ayarla(nil, not SesEfekti.kapali())
		efektCiz()
		ayarKaydiniPlanla()
	end)

	local function muzikSesDegistir(fark: number)
		-- Ses degistirmek kapali muzigi de acar
		Muzik.ayarla(Muzik.yuzde() + fark, false)
		muzikCiz()
		ayarKaydiniPlanla()
	end

	muzikKisButon.MouseButton1Click:Connect(function()
		muzikSesDegistir(-MUZIK_ADIM)
	end)

	muzikAcButon.MouseButton1Click:Connect(function()
		muzikSesDegistir(MUZIK_ADIM)
	end)

	muzikDugme.MouseButton1Click:Connect(function()
		Muzik.ayarla(nil, not Muzik.kapali())
		muzikCiz()
		ayarKaydiniPlanla()
	end)

	--[[
		Sunucudan gelen kayitli ayar. Hem oyuncu girdiginde hem de her
		kaydetmeden sonra geliyor; ikisinde de yazi ile olcek ayni degere
		oturur.
	]]
	AyarDurum.OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then
			return
		end

		local yuzde = tonumber(data.uiScale)
		if yuzde then
			olcekYazisiTazele(UI.setScale(yuzde))
		end

		local ses = tonumber(data.musicVolume)
		Muzik.ayarla(ses, if type(data.musicMuted) == "boolean" then data.musicMuted else nil)
		muzikCiz()

		local efekt = tonumber(data.sfxVolume)
		SesEfekti.ayarla(efekt, if type(data.sfxMuted) == "boolean" then data.sfxMuted else nil)
		efektCiz()
	end)

	olcekYazisiTazele(UI.getScale())
	muzikCiz()
	efektCiz()
	sarsintiCiz()

	function ayarPaneliniAc()
		ayarPanel.Visible = not ayarPanel.Visible

		--[[
			Panel acilirken sunucudaki degeri tazeler. AyarKaydet gecerli bir
			deger tasimadiginda sunucu yalnizca mevcut ayari geri yollar
			(bkz. ServerScriptService > Ayarlar).
		]]
		if ayarPanel.Visible then
			AyarKaydet:FireServer(nil)
		end
	end
end


-- GOREV PANOSU: yerelleri kendi blogunda (Luau ust seviyede en fazla 200 yerel kabul ediyor)
do
	------------------------------------------------------------------
	-- GOREV PANOSU  (Quests)
	--
	-- Pano herkeste ayni ve YARIM SAATTE BIR yenilenir (bkz. Shared >
	-- Gorevler). Burasi yalnizca gosterir: gorevleri, ilerlemeyi ve
	-- yenilenmeye kalan sureyi sunucu yolluyor.
	--
	-- SAYAC ISTEMCIDE ISLER
	-- Sunucu her saniye paket gondermesin diye kalan sure bir kez gelir ve
	-- burada geri sayilir. Sifira inince yeni pano istenir; sunucu da dilim
	-- degisince kendiliginden yolladigi icin iki taraf ayni yerde bulusur.
	------------------------------------------------------------------
	local gorevPanel = UI.panel(screen, UDim2.fromOffset(540, 500), "Gorevler")

	UI.baslikCubugu(gorevPanel, "Quests", Color3.fromRGB(255, 170, 50), Color3.fromRGB(255, 90, 110), "quests")

	local gorevSayacYazi = UI.text({
		text = "",
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(255, 225, 140),
		frameSize = UDim2.new(1, -36, 0, 22),
		position = UDim2.fromOffset(18, 70),
		parent = gorevPanel,
	})

	UI.closeButton(gorevPanel).MouseButton1Click:Connect(function()
		gorevPanel.Visible = false
	end)

	local gorevListe = makeScroll(gorevPanel, UDim2.fromOffset(14, 100), UDim2.new(1, -28, 1, -114))

	-- Sunucudan gelen son pano
	local gorevVerisi: { remaining: number, quests: { any } } = { remaining = 0, quests = {} }
	local gorevKalan = 0

	local function gorevSatiri(parent: Instance, quest: any, order: number)
		local bitti = quest.done == true
		-- Hedef doldu ama odul henuz alinmadi: satirda Collect dugmesi belirir
		local hazir = quest.ready == true
		local renk = quest.color or UI.Colors.accent

		local row = Instance.new("Frame")
		row.Name = quest.id
		-- Collect dugmesi cikacaksa satir uzar: dugme XP yazisinin ALTINA oturur
		row.Size = UDim2.new(1, -6, 0, if hazir then 100 else 84)
		row.BorderSizePixel = 0
		row.LayoutOrder = order
		row.Parent = parent
		UI.corner(row, 12)
		-- Odulun renginde kart; hazir gorev altin, biten yesil kalin cerceve alir
		local kontur = UI.renkliKart(row, renk)
		if hazir then
			kontur.Color = UI.Colors.gold
			kontur.Thickness = 3
		elseif bitti then
			kontur.Color = UI.Colors.good
			kontur.Thickness = 3
		end

		UI.text({
			text = quest.text,
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			-- Odul yazisiyla arasinda nefes payi kalsin diye dar tutuldu
			frameSize = UDim2.new(1, -190, 0, 24),
			position = UDim2.fromOffset(14, 10),
			parent = row,
		})

		-- Odul her zaman brainrot; rengi odulun kademesinden gelir
		UI.text({
			text = quest.reward,
			size = UI.Sizes.small,
			font = UI.Fonts.bold,
			color = renk,
			align = Enum.TextXAlignment.Right,
			frameSize = UDim2.new(0, 160, 0, 24),
			position = UDim2.new(1, -174, 0, 10),
			parent = row,
		})

		-- Odulun XP'si, brainrot yazisinin hemen altinda
		if type(quest.xp) == "number" and quest.xp > 0 then
			UI.text({
				text = `+{quest.xp} XP`,
				size = UI.Sizes.small,
				font = UI.Fonts.bold,
				color = UI.Colors.gold,
				align = Enum.TextXAlignment.Right,
				frameSize = UDim2.new(0, 160, 0, 20),
				position = UDim2.new(1, -174, 0, 36),
				parent = row,
			})
		end

		UI.text({
			text = if bitti then "COLLECTED" else `{quest.progress} / {quest.target}`,
			size = UI.Sizes.small,
			font = UI.Fonts.bold,
			color = if bitti then UI.Colors.good else UI.Colors.textDim,
			frameSize = UDim2.new(1, -28, 0, 20),
			position = UDim2.fromOffset(14, 36),
			parent = row,
		})

		local oluk = Instance.new("Frame")
		oluk.Name = "Cubuk"
		oluk.Position = UDim2.fromOffset(14, 62)
		-- Collect dugmesi cikacaksa cubuk kisalir, dugmenin altina girmesin
		oluk.Size = if hazir then UDim2.new(1, -132, 0, 12) else UDim2.new(1, -28, 0, 12)
		oluk.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
		oluk.BorderSizePixel = 0
		oluk.Parent = row
		UI.corner(oluk, 6)
		UI.stroke(oluk, Color3.fromRGB(0, 0, 0), 2)

		local oran = if quest.target > 0 then math.clamp(quest.progress / quest.target, 0, 1) else 0
		if oran > 0 then
			local dolgu = Instance.new("Frame")
			dolgu.Name = "Dolgu"
			dolgu.Size = UDim2.fromScale(oran, 1)
			dolgu.BackgroundColor3 = if bitti then UI.Colors.good else renk
			dolgu.BorderSizePixel = 0
			dolgu.Parent = oluk
			UI.corner(dolgu, 6)
			UI.cubukCilasi(dolgu)
		end

		--[[
			COLLECT

			Odul kendiliginden verilmiyor: hedef dolunca satirda bu dugme cikar.
			Cubugun sagindaki bosluga oturur, yazilarla ic ice girmez.

			Basilinca panel kapanir; patlama sunucudan gelir, boylece efekt
			arayuzun arkasinda kalmaz.
		]]
		if hazir then
			local topla = UI.dugme3B(row, "Collect", UDim2.fromOffset(106, 36), UI.Colors.gold)
			topla.AnchorPoint = Vector2.new(1, 0)
			--[[
				Cubugun sagi, XP yazisinin (36..56) ALTI: 58..94. Eskiden 44'te
				basliyordu ve "+10 XP" yazisinin ustune biniyordu.
			]]
			topla.Position = UDim2.new(1, -12, 0, 58)

			topla.MouseButton1Click:Connect(function()
				GorevAl:FireServer(quest.id)
				gorevPanel.Visible = false
			end)

		end
	end

	local function gorevleriCiz()
		clearRows(gorevListe)

		if #gorevVerisi.quests == 0 then
			UI.text({
				text = "Loading Quests...",
				size = UI.Sizes.small,
				color = UI.Colors.textDim,
				frameSize = UDim2.new(1, -6, 0, 40),
				parent = gorevListe,
			})
			return
		end

		for index, quest in gorevVerisi.quests do
			gorevSatiri(gorevListe, quest, index)
		end
	end

	local function gorevSayaciYaz()
		gorevSayacYazi.Text = `New Quests In {sureMetni(gorevKalan)}`
	end

	--[[
		Hedefi dolmus ama odulu alinmamis gorev var mi. Panelin acilmasini
		beklemez: nokta oyuncuyu panele cagiran sey.
	]]
	local function gorevHazirMi(): boolean
		for _, quest in gorevVerisi.quests do
			if quest.ready == true then
				return true
			end
		end
		return false
	end

	GorevDurum.OnClientEvent:Connect(function(veri)
		if type(veri) ~= "table" then
			return
		end

		gorevVerisi = veri
		gorevKalan = math.max(0, tonumber(veri.remaining) or 0)
		gorevSayaciYaz()
		Bildirim.ayarla("quests", gorevHazirMi())

		-- Panel kapaliyken cizmeye gerek yok; acilirken zaten cizilecek
		if gorevPanel.Visible then
			gorevleriCiz()
		end
	end)

	function gorevPaneliniAc()
		gorevPanel.Visible = not gorevPanel.Visible

		if gorevPanel.Visible then
			GorevAc:FireServer()
			gorevleriCiz()
			gorevSayaciYaz()
		end
	end

	task.spawn(function()
		while true do
			task.wait(1)

			if gorevKalan > 0 then
				gorevKalan -= 1
				if gorevPanel.Visible then
					gorevSayaciYaz()
				end
			elseif gorevPanel.Visible then
				-- Sure doldu: yeni panoyu iste (sunucu da kendiliginden yollar)
				GorevAc:FireServer()
			end
		end
	end)

	-- Output'ta bu satir gorunuyorsa butun menu ve paneller kuruldu
	print("[Menuler] arayuz kuruldu")
end


-- ISINLAYICI + HIZ PANELLERI: yerelleri kendi blogunda (Luau ust seviyede en fazla 200 yerel kabul ediyor)
do
	local Config = require(Shared:WaitForChild("OyunConfig"))
	local Passler = require(Shared:WaitForChild("Passler"))
	local Hiz = require(Shared:WaitForChild("Hiz"))
	local PassSatinAl = Net.event("PassSatinAl")
	local IsinlayiciGit = Net.event("IsinlayiciGit")
	local HizAl = Net.event("HizAl")
	local HizRebirth = Net.event("HizRebirth")
	-- Para birimi sarisi (Shared > Bases.RotColor ile ayni)
	local ROT_SARI = Color3.fromRGB(255, 214, 41)

	------------------------------------------------------------------
	-- ISINLAYICI  (sagdaki Teleporter butonu)
	--
	-- Acilmis butun adalar tek tusla. Teleporter gecisi (Robux) gerekir;
	-- gecis yoksa panelin ustunde satin alma dugmesi durur ve ada
	-- dugmeleri de satin alma penceresini acar. Adalar kaptandan acilir;
	-- burada yalnizca acik olanlara gidilir.
	------------------------------------------------------------------
	local TP_MOR = Color3.fromRGB(150, 120, 255)

	local tpPanel = UI.panel(screen, UDim2.fromOffset(480, 470), "Isinlayici")

	UI.text({
		text = "Teleporter",
		size = UI.Sizes.title,
		font = UI.Fonts.bold,
		color = TP_MOR,
		frameSize = UDim2.new(1, -80, 0, 34),
		position = UDim2.fromOffset(18, 14),
		parent = tpPanel,
	})

	UI.closeButton(tpPanel).MouseButton1Click:Connect(function()
		tpPanel.Visible = false
	end)

	local tpAciklama = UI.text({
		text = "",
		size = UI.Sizes.small,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -36, 0, 40),
		position = UDim2.fromOffset(18, 50),
		parent = tpPanel,
		wrapped = true,
	})

	local tpListe = makeScroll(tpPanel, UDim2.fromOffset(14, 96), UDim2.new(1, -28, 1, -110))

	local function tpSahip(): boolean
		return Passler.sahip(player, "Teleporter")
	end

	local function tpCiz()
		local pass = Passler.get("Teleporter")
		local sahip = tpSahip()
		local acik = tonumber(inventory.islands) or 1

		tpAciklama.Text = if sahip
			then "Teleport to any island you have unlocked."
			else `Get the Teleporter pass ({if pass then pass.fiyat else 0} R$) to travel to your unlocked islands from anywhere.`

		clearRows(tpListe)

		local sira = 0

		-- Gecis yoksa en ustte satin alma satiri
		if not sahip then
			sira += 1
			local satir = Instance.new("Frame")
			satir.Name = "SatinAl"
			satir.Size = UDim2.new(1, -6, 0, 60)
			satir.BackgroundColor3 = UI.Colors.panelLight
			satir.BorderSizePixel = 0
			satir.LayoutOrder = sira
			satir.Parent = tpListe
			UI.corner(satir, 10)
			UI.stroke(satir, UI.Colors.gold, 2)

			UI.text({
				text = "Teleporter Pass",
				size = UI.Sizes.body,
				font = UI.Fonts.bold,
				color = UI.Colors.gold,
				frameSize = UDim2.new(1, -170, 1, 0),
				position = UDim2.fromOffset(14, 0),
				parent = satir,
			})

			local al = UI.button(satir, `BUY  {if pass then pass.fiyat else 0} R$`, UDim2.fromOffset(140, 42), UI.Colors.good)
			al.AnchorPoint = Vector2.new(1, 0.5)
			al.Position = UDim2.new(1, -10, 0.5, 0)
			UI.stroke(al, Color3.fromRGB(0, 0, 0), 2)
			al.MouseButton1Click:Connect(function()
				PassSatinAl:FireServer("Teleporter")
			end)
		end

		for index, ada in Config.Islands do
			if ada.comingSoon then
				continue
			end

			sira += 1
			local acildi = index <= acik

			local satir = Instance.new("Frame")
			satir.Name = ada.name
			satir.Size = UDim2.new(1, -6, 0, 64)
			satir.BackgroundColor3 = UI.Colors.panelLight
			satir.BorderSizePixel = 0
			satir.LayoutOrder = sira
			satir.Parent = tpListe
			UI.corner(satir, 10)
			UI.stroke(satir, if acildi then ada.color else UI.Colors.panel, 1)

			UI.text({
				text = if acildi then ada.name else "???",
				size = UI.Sizes.body,
				font = UI.Fonts.bold,
				color = if acildi then ada.color else UI.Colors.textDim,
				frameSize = UDim2.new(1, -170, 0, 24),
				position = UDim2.fromOffset(14, 8),
				parent = satir,
			})

			UI.text({
				text = if acildi then ada.desc else "Unlock it at a Teleporter first.",
				size = UI.Sizes.tiny,
				color = UI.Colors.textDim,
				frameSize = UDim2.new(1, -170, 0, 26),
				position = UDim2.fromOffset(14, 32),
				parent = satir,
				wrapped = true,
			})

			local renk = if acildi and sahip then UI.Colors.good elseif acildi then UI.Colors.gold else UI.Colors.panel
			local yazi = if not acildi then "LOCKED" elseif sahip then "TELEPORT" else "NEED PASS"
			local buton = UI.button(satir, yazi, UDim2.fromOffset(140, 42), renk)
			buton.AnchorPoint = Vector2.new(1, 0.5)
			buton.Position = UDim2.new(1, -10, 0.5, 0)
			UI.stroke(buton, Color3.fromRGB(0, 0, 0), 2)

			if acildi then
				buton.MouseButton1Click:Connect(function()
					if tpSahip() then
						IsinlayiciGit:FireServer(index)
						tpPanel.Visible = false
					else
						PassSatinAl:FireServer("Teleporter")
					end
				end)
			end
		end
	end

	function ekMenu.isinlayiciAc()
		tpPanel.Visible = not tpPanel.Visible
		if tpPanel.Visible then
			tpCiz()
		end
	end

	--[[
		BUTON GECIS ALINANA KADAR GRI

		Yuzun ustune gri bir ortu konur (ikonun altinda); ikon da grilesir.
		Yuzun kendi rengine dokunulmuyor: fare efekti o rengi hafizada
		tutuyor, degistirilse alindiktan sonra gri geri donerdi.
	]]
	local tpButon = sagSutun:FindFirstChild("Teleporter")
	local tpYuz = tpButon and tpButon:FindFirstChild("Yuz")
	local tpOrtu: Frame? = nil
	if tpYuz and tpYuz:IsA("Frame") then
		local ortu = Instance.new("Frame")
		ortu.Name = "GriOrtu"
		ortu.Size = UDim2.fromScale(1, 1)
		ortu.BackgroundColor3 = Color3.fromRGB(125, 128, 135)
		ortu.BorderSizePixel = 0
		ortu.ZIndex = 4
		ortu.Parent = tpYuz
		UI.corner(ortu, 10)
		tpOrtu = ortu
	end

	local function tpButonCiz()
		local sahip = tpSahip()
		if tpOrtu then
			tpOrtu.Visible = not sahip
		end
		if tpButon and tpButon:IsA("GuiObject") then
			tpButon.BackgroundColor3 = if sahip
				then MenuRenk.teleporter:Lerp(Color3.new(0, 0, 0), 0.32)
				else Color3.fromRGB(80, 82, 88)
		end
		if tpYuz then
			for _, d in tpYuz:GetChildren() do
				if d:IsA("ImageLabel") then
					d.ImageColor3 = if sahip then Color3.new(1, 1, 1) else Color3.fromRGB(175, 175, 175)
				elseif d:IsA("TextLabel") then
					d.TextColor3 = if sahip then Color3.new(1, 1, 1) else Color3.fromRGB(175, 175, 175)
				end
			end
		end
	end
	tpButonCiz()

	-- Gecis alininca buton renklenir, acik panel tazelenir
	do
		local pass = Passler.get("Teleporter")
		if pass then
			player:GetAttributeChangedSignal(pass.nitelik):Connect(function()
				tpButonCiz()
				if tpPanel.Visible then
					tpCiz()
				end
			end)
		end
	end

	EnvanterGuncelle.OnClientEvent:Connect(function(data)
		if type(data) == "table" and tpPanel.Visible then
			-- Menuler'in kendi dinleyicisi 'inventory'yi ayni karede guncelliyor
			task.defer(tpCiz)
		end
	end)
end


--[[
	HIZ PANELI: kendi blogunda. Isinlayiciyla ayni bloktayken ikisinin
	yerelleri toplanip 200 yerel sinirini asiyordu (bkz. tools/check.luau).
]]
do
	local Hiz = require(Shared:WaitForChild("Hiz"))
	local HizAl = Net.event("HizAl")
	local HizRebirth = Net.event("HizRebirth")
	-- Para birimi sarisi (Shared > Bases.RotColor ile ayni)
	local ROT_SARI = Color3.fromRGB(255, 214, 41)

	------------------------------------------------------------------
	-- HIZ  (soldaki ayakkabi butonu)
	--
	-- 100 yukseltme; her biri Rot ister ve fiyati katlanarak artar
	-- (bkz. Shared > Hiz). Seviye sunucudan oyuncu niteligiyle gelir.
	------------------------------------------------------------------
	local hzPanel = UI.panel(screen, UDim2.fromOffset(440, 460), "Hiz")

	UI.baslikCubugu(hzPanel, "Speed", Color3.fromRGB(110, 230, 255), Color3.fromRGB(60, 120, 255), "speed")

	UI.closeButton(hzPanel).MouseButton1Click:Connect(function()
		hzPanel.Visible = false
	end)

	local hzSeviye = UI.text({
		text = "",
		size = UI.Sizes.huge,
		font = UI.Fonts.bold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -36, 0, 50),
		position = UDim2.fromOffset(18, 72),
		parent = hzPanel,
	})

	local hzCarpan = UI.text({
		text = "",
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -36, 0, 24),
		position = UDim2.fromOffset(18, 124),
		parent = hzPanel,
	})

	-- Ilerleme cubugu: alinan / 100
	local hzOluk = Instance.new("Frame")
	hzOluk.Name = "Cubuk"
	hzOluk.Position = UDim2.fromOffset(18, 160)
	hzOluk.Size = UDim2.new(1, -36, 0, 16)
	hzOluk.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
	hzOluk.BorderSizePixel = 0
	hzOluk.Parent = hzPanel
	UI.corner(hzOluk, 8)
	UI.stroke(hzOluk, Color3.fromRGB(0, 0, 0), 2)

	local hzDolgu = Instance.new("Frame")
	hzDolgu.Name = "Dolgu"
	hzDolgu.Size = UDim2.fromScale(0, 1)
	hzDolgu.BorderSizePixel = 0
	hzDolgu.Parent = hzOluk
	UI.corner(hzDolgu, 8)
	UI.cubukCilasi(hzDolgu)

	local hzSayac = UI.text({
		text = "",
		size = UI.Sizes.small,
		color = UI.Colors.textDim,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -36, 0, 20),
		position = UDim2.fromOffset(18, 180),
		parent = hzPanel,
	})

	local hzBakiye = UI.text({
		text = "",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = ROT_SARI,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -36, 0, 20),
		position = UDim2.fromOffset(18, 206),
		parent = hzPanel,
	})

	--[[
		Iki dugme: +1 ve +10. Para yetiyorsa yesil, yetmiyorsa gri 3B dugme
		(UI.dugme3BRenk; fare etkisi her seferinde guncel rengi okur).
	]]
	local HZ_YESIL = Color3.fromRGB(70, 205, 85)

	local function hzDugmesi(x: number, adet: number)
		local dugme, yuz = UI.dugme3B(hzPanel, nil, UDim2.new(0.5, -24, 0, 72), UI.KapaliRenk)
		dugme.Name = `Al{adet}`
		dugme.Position = UDim2.new(x, if x == 0 then 18 else 6, 0, 240)

		local ust = UI.text({
			text = `+{adet} SPEED`,
			size = UI.Sizes.label,
			font = UI.Fonts.bold,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.new(1, 0, 0, 30),
			position = UDim2.fromOffset(0, 4),
			parent = yuz,
			zIndex = 5,
		})

		local alt = UI.text({
			text = "",
			size = UI.Sizes.small,
			font = UI.Fonts.bold,
			color = ROT_SARI,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.new(1, 0, 0, 22),
			position = UDim2.fromOffset(0, 34),
			parent = yuz,
			zIndex = 5,
		})

		dugme.MouseButton1Click:Connect(function()
			HizAl:FireServer(adet)
		end)

		return function(alinan: number, rot: number)
			local kalan = math.min(adet, Hiz.Max - alinan)
			if kalan <= 0 then
				ust.Text = "MAXED"
				alt.Text = ""
				UI.dugme3BRenk(dugme, UI.KapaliRenk)
			else
				local fiyat = Hiz.topluFiyat(alinan, kalan)
				ust.Text = `+{kalan} SPEED`
				alt.Text = `{Format.short(fiyat)} Rot`
				UI.dugme3BRenk(dugme, if rot >= fiyat then HZ_YESIL else UI.KapaliRenk)
			end
		end
	end

	local hzBir = hzDugmesi(0, 1)
	local hzOn = hzDugmesi(0.5, 10)

	--[[
		REBIRTH: Speed 101'de acilir. Hiz basa doner, arkadaki iz uzar ve
		bir sonraki hiz rengine gecer (Shared > Hiz). Kirmizidan sonra biter.
	]]
	local hzRebirth, hzRebirthYuz = UI.dugme3B(hzPanel, nil, UDim2.new(1, -36, 0, 58), UI.KapaliRenk)
	hzRebirth.Name = "Rebirth"
	hzRebirth.Position = UDim2.fromOffset(18, 322)

	local hzRebirthYazi = UI.text({
		text = "",
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = hzRebirthYuz,
		zIndex = 5,
	})

	hzRebirth.MouseButton1Click:Connect(function()
		local alinan = tonumber(player:GetAttribute(Hiz.Nitelik)) or 0
		local rebirth = tonumber(player:GetAttribute(Hiz.RebirthNitelik)) or 0
		if Hiz.rebirthAtilabilir(alinan, rebirth) then
			HizRebirth:FireServer()
		end
	end)

	local hzRebirthBilgi = UI.text({
		text = "",
		size = UI.Sizes.tiny,
		color = UI.Colors.textDim,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, -36, 0, 20),
		position = UDim2.fromOffset(18, 388),
		parent = hzPanel,
	})

	local function hzCiz()
		local alinan = tonumber(player:GetAttribute(Hiz.Nitelik)) or 0
		local seviye = alinan + 1
		local rot = tonumber(inventory.rot) or 0
		local renk = Hiz.renk(seviye)

		hzSeviye.Text = `Speed {seviye}`
		hzSeviye.TextColor3 = renk
		if alinan >= Hiz.Max then
			hzCarpan.Text = `x{string.format("%.2f", Hiz.carpan(alinan))} walk speed (MAX)`
		else
			hzCarpan.Text = `x{string.format("%.2f", Hiz.carpan(alinan))}  ->  x{string.format("%.2f", Hiz.carpan(alinan + 1))} walk speed`
		end
		hzDolgu.Size = UDim2.fromScale(alinan / Hiz.Max, 1)
		hzDolgu.BackgroundColor3 = renk
		hzSayac.Text = `{alinan} / {Hiz.Max} upgrades`
		hzBakiye.Text = `You have {Format.short(rot)} Rot`

		hzBir(alinan, rot)
		hzOn(alinan, rot)

		local rebirth = tonumber(player:GetAttribute(Hiz.RebirthNitelik)) or 0
		if rebirth >= Hiz.MaxRebirth then
			hzRebirthYazi.Text = "ALL REBIRTHS DONE"
			UI.dugme3BRenk(hzRebirth, UI.KapaliRenk)
			hzRebirthYazi.TextColor3 = Hiz.rebirthRengi(rebirth) or UI.Colors.text
		elseif alinan >= Hiz.Max then
			hzRebirthYazi.Text = `REBIRTH  ({rebirth + 1}/{Hiz.MaxRebirth})`
			-- Rebirth hazir: gozden kacmasin diye mor
			UI.dugme3BRenk(hzRebirth, Color3.fromRGB(190, 90, 255))
			hzRebirthYazi.TextColor3 = Color3.new(1, 1, 1)
		else
			hzRebirthYazi.Text = `Rebirth at Speed {Hiz.Max + 1}  ({rebirth}/{Hiz.MaxRebirth})`
			UI.dugme3BRenk(hzRebirth, UI.KapaliRenk)
			hzRebirthYazi.TextColor3 = Color3.fromRGB(225, 228, 236)
		end
		hzRebirthBilgi.Text = if rebirth >= Hiz.MaxRebirth
			then "Your trail is at its longest."
			else "Rebirth resets your speed and gives you a longer, new-colored trail."
	end

	function ekMenu.hizAc()
		hzPanel.Visible = not hzPanel.Visible
		if hzPanel.Visible then
			hzCiz()
		end
	end

	for _, nitelik in { Hiz.Nitelik, Hiz.RebirthNitelik } do
		player:GetAttributeChangedSignal(nitelik):Connect(function()
			if hzPanel.Visible then
				hzCiz()
			end
		end)
	end

	EnvanterGuncelle.OnClientEvent:Connect(function(data)
		if type(data) == "table" and hzPanel.Visible then
			task.defer(hzCiz)
		end
	end)
end


-- DETECTIVE TAKIP: yerelleri kendi blogunda (Luau ust seviyede en fazla 200 yerel kabul ediyor)
do
	------------------------------------------------------------------
	-- DETECTIVE TAKIBI  (sol menudeki 8. buton)
	--
	-- Yalnizca IZLEME: buradan brainrot verilmez, alinmaz. Detective'e
	-- birakilan brainrotlarin kalan suresi ve is bitince hangi
	-- brainrotlarin ciktigi gorulur. Teslim almak icin Detective'e gidilir.
	--
	-- BUTONUN KENDISI BAR: is surerken yuzu alttan yukari yesile dolar;
	-- is bitince parlar (kontur altin renkte nabiz atar).
	------------------------------------------------------------------
	local DetectiveTakip = Net.event("DetectiveTakip")
	local DetectiveDurumOlayi = Net.event("DetectiveDurum")

	local TAKIP_SARI = Color3.fromRGB(255, 236, 180)
	local DOLUM_YESIL = Color3.fromRGB(70, 215, 95)

	local takipIs: any = nil
	local takipBitis = 0

	local takipPanel = UI.panel(screen, UDim2.fromOffset(560, 540), "DetektifTakip")

	UI.baslikCubugu(takipPanel, "Detective", Color3.fromRGB(150, 110, 255), Color3.fromRGB(50, 170, 230), "detective")

	UI.closeButton(takipPanel).MouseButton1Click:Connect(function()
		takipPanel.Visible = false
	end)

	local takipDurum = UI.text({
		text = "",
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		frameSize = UDim2.new(1, -36, 0, 24),
		position = UDim2.fromOffset(18, 72),
		parent = takipPanel,
		wrapped = true,
	})

	local takipOluk = Instance.new("Frame")
	takipOluk.Position = UDim2.fromOffset(18, 104)
	takipOluk.Size = UDim2.new(1, -36, 0, 26)
	takipOluk.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
	takipOluk.BorderSizePixel = 0
	takipOluk.Parent = takipPanel
	UI.corner(takipOluk, 13)
	UI.stroke(takipOluk, Color3.fromRGB(0, 0, 0), 2)

	local takipDolgu = Instance.new("Frame")
	takipDolgu.Size = UDim2.fromScale(0, 1)
	takipDolgu.BackgroundColor3 = DOLUM_YESIL
	takipDolgu.BorderSizePixel = 0
	takipDolgu.Parent = takipOluk
	UI.corner(takipDolgu, 13)
	UI.cubukCilasi(takipDolgu)

	local takipBarYazi = UI.text({
		text = "",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = takipOluk,
	})
	takipBarYazi.ZIndex = 3

	local takipListe = makeScroll(takipPanel, UDim2.fromOffset(14, 142), UDim2.new(1, -28, 1, -156))
	local takipPencere = BrainrotOnizleme.pencere(takipListe, takipPanel)

	local function takipKalan(): number
		if not takipIs or takipIs.bitti then
			return 0
		end
		return math.max(0, takipBitis - os.clock())
	end

	local function takipOran(): number
		if not takipIs then
			return 0
		end
		if takipIs.bitti then
			return 1
		end
		local toplam = math.max(1, tonumber(takipIs.toplam) or 1)
		return math.clamp(1 - takipKalan() / toplam, 0, 1)
	end

	-- Liste yalnizca durum degisince yeniden kurulur
	local function takipListeCiz()
		takipPencere.temizle()
		clearRows(takipListe)

		if not takipIs then
			UI.text({
				text = "Take your unidentified brainrots to the Detective. You can follow the progress here.",
				size = UI.Sizes.small,
				color = UI.Colors.textDim,
				align = Enum.TextXAlignment.Center,
				frameSize = UDim2.new(1, -10, 0, 44),
				parent = takipListe,
				wrapped = true,
			})
			return
		end

		if not takipIs.bitti then
			UI.text({
				text = `The Detective is identifying {takipIs.adet or 0} brainrot(s). Results will show up here.`,
				size = UI.Sizes.small,
				color = UI.Colors.textDim,
				align = Enum.TextXAlignment.Center,
				frameSize = UDim2.new(1, -10, 0, 44),
				parent = takipListe,
				wrapped = true,
			})
			return
		end

		local sonuclar = if type(takipIs.sonuclar) == "table" then takipIs.sonuclar else {}
		table.sort(sonuclar, function(a, b)
			return (tonumber(a.income) or 0) > (tonumber(b.income) or 0)
		end)
		for sira, sonuc in sonuclar do
			brainrotRow(takipListe, {
				uid = sonuc.uid,
				name = sonuc.name,
				rarity = sonuc.rarity,
				condition = sonuc.condition,
				mutation = sonuc.mutation,
				revealed = true,
			}, sira, takipPencere)
		end
	end

	local function takipYaziCiz()
		local oran = takipOran()
		takipDolgu.Size = UDim2.fromScale(oran, 1)

		if not takipIs then
			takipDurum.Text = "No brainrots at the Detective."
			takipDurum.TextColor3 = UI.Colors.textDim
			takipBarYazi.Text = ""
		elseif takipIs.bitti then
			takipDurum.Text = `Done! Go to the Detective to collect {takipIs.adet or 0} brainrot(s).`
			takipDurum.TextColor3 = DOLUM_YESIL
			takipBarYazi.Text = "READY"
		else
			local t = math.ceil(takipKalan())
			takipDurum.Text = `Identifying {takipIs.adet or 0} brainrot(s)...`
			takipDurum.TextColor3 = TAKIP_SARI
			takipBarYazi.Text = string.format("%d:%02d left", t // 60, t % 60)
		end
	end

	function ekMenu.detektifAc()
		takipPanel.Visible = not takipPanel.Visible
		if takipPanel.Visible then
			takipListeCiz()
			takipYaziCiz()
			DetectiveTakip:FireServer()
		end
	end

	------------------------------------------------------------------
	-- BUTON: dolum + parlama
	------------------------------------------------------------------
	local takipButon = solSutun:FindFirstChild("Detective")
	local takipYuz = takipButon and takipButon:FindFirstChild("Yuz")
	local butonDolum: Frame? = nil
	local butonKontur: UIStroke? = nil
	if takipYuz and takipYuz:IsA("Frame") then
		local dolum = Instance.new("Frame")
		dolum.Name = "Dolum"
		dolum.AnchorPoint = Vector2.new(0, 1)
		dolum.Position = UDim2.fromScale(0, 1)
		dolum.Size = UDim2.fromScale(1, 0)
		dolum.BackgroundColor3 = DOLUM_YESIL
		dolum.BorderSizePixel = 0
		-- Parlama bandinin (3) altinda, ikonun (5) altinda
		dolum.ZIndex = 2
		dolum.Parent = takipYuz
		-- Butonun yuzuyle ayni kose yuvarlakligi
		UI.corner(dolum, 10)
		butonDolum = dolum
	end
	if takipButon then
		butonKontur = takipButon:FindFirstChildOfClass("UIStroke")
	end

	local function butonCiz()
		local dolum = butonDolum
		if dolum then
			dolum.Visible = takipIs ~= nil
			dolum.Size = UDim2.fromScale(1, takipOran())
		end

		local kontur = butonKontur
		if kontur then
			if takipIs and takipIs.bitti then
				-- Is bitti: altin kontur nabiz atar
				local nabiz = (math.sin(os.clock() * 5) + 1) / 2
				kontur.Color = Color3.fromRGB(255, 215, 40):Lerp(Color3.new(1, 1, 1), nabiz * 0.6)
				kontur.Thickness = 2 + nabiz * 2.5
			else
				kontur.Color = Color3.fromRGB(0, 0, 0)
				kontur.Thickness = 2
			end
		end
	end

	DetectiveDurumOlayi.OnClientEvent:Connect(function(ozet)
		local oncekiBitti = takipIs ~= nil and takipIs.bitti == true
		takipIs = if type(ozet) == "table" then ozet else nil
		takipBitis = os.clock() + (if takipIs then tonumber(takipIs.kalan) or 0 else 0)

		local simdiBitti = takipIs ~= nil and takipIs.bitti == true
		if takipPanel.Visible then
			takipListeCiz()
			takipYaziCiz()
		elseif simdiBitti ~= oncekiBitti then
			takipListeCiz()
		end
		butonCiz()
	end)

	-- Dolum ve nabiz her karede, yazilar yarim saniyede bir
	local sonYazi = 0
	game:GetService("RunService").RenderStepped:Connect(function()
		if not takipIs then
			return
		end
		butonCiz()
		local simdi = os.clock()
		if takipPanel.Visible and simdi - sonYazi > 0.5 then
			sonYazi = simdi
			takipYaziCiz()
		end
	end)

	takipListeCiz()
	takipYaziCiz()
	butonCiz()
	DetectiveTakip:FireServer()
end
