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

local EnvanterGuncelle = Net.event("EnvanterGuncelle")
local DetectiveAc = Net.event("DetectiveAc")
local DetectiveTeslim = Net.event("DetectiveTeslim")
local DetectiveSonuc = Net.event("DetectiveSonuc")
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
	row.Size = UDim2.new(1, -6, 0, 62)
	row.BackgroundColor3 = UI.Colors.panelLight
	row.BorderSizePixel = 0
	-- Fare etkisi tiklanabilir satirlarda ayrica veriliyor (UI.hover)
	row.AutoButtonColor = false
	row.Text = ""
	row.LayoutOrder = order
	row.Parent = parent
	UI.corner(row, 10)
	UI.stroke(row, rarityInfo.color, 1)

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
	badge.Size = UDim2.fromOffset(56, 26)
	badge.Position = UDim2.new(1, -68, 0.5, -13)
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

	if item.slot then
		UI.text({
			text = `Slot {item.slot}`,
			size = UI.Sizes.tiny,
			color = UI.Colors.accent,
			align = Enum.TextXAlignment.Right,
			frameSize = UDim2.fromOffset(90, 16),
			position = UDim2.new(1, -170, 0, 8),
			parent = row,
		})
	end

	return row
end

------------------------------------------------------------------
-- ENVANTER
------------------------------------------------------------------
local envanter = UI.panel(screen, UDim2.fromOffset(520, 480), "Envanter")

UI.text({
	text = "Inventory",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	frameSize = UDim2.new(1, -80, 0, 36),
	position = UDim2.fromOffset(18, 14),
	parent = envanter,
})

local envanterOzet = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 48),
	parent = envanter,
})


UI.closeButton(envanter).MouseButton1Click:Connect(function()
	envanter.Visible = false
end)

local envanterListe = makeScroll(envanter, UDim2.fromOffset(14, 96), UDim2.new(1, -28, 1, -110))

-- Yalnizca ekrandaki satirlara brainrot resmi kurulur (bkz. BrainrotOnizleme)
local envanterPencere = BrainrotOnizleme.pencere(envanterListe, envanter)

-- Ayirici baslik satiri (BRAINROTLAR gibi)
local function sectionHeader(parent: Instance, text: string, order: number)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -6, 0, 24)
	holder.BackgroundTransparency = 1
	holder.LayoutOrder = order
	holder.Parent = parent

	UI.text({
		text = text,
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		frameSize = UDim2.fromScale(1, 1),
		parent = holder,
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
	local hidden, placed = 0, 0
	for _, item in items do
		if not item.revealed then
			hidden += 1
		end
		if item.slot then
			placed += 1
		end
	end

	envanterOzet.Text = `{#items} brainrots  -  {hidden} unidentified  -  {placed} on base`


	------------------------------------------------------------------
	-- BRAINROTLAR
	------------------------------------------------------------------
	sectionHeader(envanterListe, `BRAINROTS ({#items})`, 100)

	if #items == 0 then
		UI.text({
			text = "No brainrots yet. Hold your GPS and look for light beams in the sand.",
			size = UI.Sizes.small,
			color = UI.Colors.textDim,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.new(1, 0, 0, 36),
			parent = envanterListe,
			wrapped = true,
		}).LayoutOrder = 5
		return
	end

	-- Once acilmamislar, sonra rarity'ye gore
	local sorted = table.clone(items)
	--[[
		SIRALAMA: pahalidan ucuza.

		Once kimligi belirlenmemisler (islem bekleyenler ustte kalsin),
		sonra saniyelik getiriye gore buyukten kucuge. Getiri rarity,
		boyut ve mutasyonu birlikte hesaba kattigi icin "pahali" olan
		gercekten en cok kazandirandir.
	]]
	local function worth(item: any): number
		if item.revealed and item.name then
			return Brainrots.income(item.name, item.condition, item.mutation)
		end
		-- Acilmamis: rarity'nin en dusuk uyesi kadar sayilir
		return Brainrots.minIncome(item.rarity, item.condition)
	end

	table.sort(sorted, function(a, b)
		if a.revealed ~= b.revealed then
			return not a.revealed
		end
		return worth(a) > worth(b)
	end)

	for index, item in sorted do
		local row = brainrotRow(envanterListe, item, 100 + index, envanterPencere)

		-- Base'e konmus olanlar tiklaninca geri alinir
		if item.slot then
			row.MouseButton1Click:Connect(function()
				SlottanAl:FireServer(item.uid)
			end)

			UI.hover(row)
		end
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
local ROT_SATIR = 96
local COIN_SATIR = 44
rotKutu.Size = UDim2.fromOffset(460, ROT_SATIR + COIN_SATIR)
rotKutu.BackgroundTransparency = 1
rotKutu.BorderSizePixel = 0
rotKutu.Parent = screen

--[[
	Tek satir, yalnizca yazi: "12.4K Rot".

	Once solda bir para ikonu vardi; kaldirildi. Yazinin yuksekligi kutuyu
	dolduruyor, boylece dikey ortalama kutunun kendisinden geliyor.
]]
local function paraSatiri(yaziBoyu: number): TextLabel
	local yazi = UI.text({
		text = "",
		size = yaziBoyu,
		font = UI.Fonts.bold,
		-- Rakam beyaz; sari ton yalnizca panellerde kaldi
		color = Color3.fromRGB(255, 255, 255),
		align = Enum.TextXAlignment.Left,
		--[[
			Oyunun standart konturu kapali; yerine asagida sabit kalinlikta
			bir kontur var: applyOutline kalinligi yazi boyuyla buyudugu icin
			rakam 3 katina cikinca kontur de asiri kalinlasiyordu.
		]]
		outline = false,
		frameSize = UDim2.new(1, 0, 0, ROT_SATIR),
		parent = rotKutu,
	})

	-- Kalinlik yazi boyundan bagimsiz sabit: 60px rakamda 3px kontur
	-- (Fonts.applyOutline kalinligi TextSize ile buyutur, burada istenmiyor)
	UI.stroke(yazi, Color3.fromRGB(0, 0, 0), 3)

	return yazi
end

-- 60px: eski olcunun (20) 3 kati
local rotYazi = paraSatiri(UI.Sizes.label * 3)

-- ROT COIN  --  Rot'un hemen altinda, sade sari yazi: "1.2K Rot Coin"
local coinYazi = UI.text({
	text = "0 Rot Coin",
	size = math.floor(UI.Sizes.label * 1.6),
	font = UI.Fonts.bold,
	color = Color3.fromRGB(255, 215, 40),
	align = Enum.TextXAlignment.Left,
	outline = false,
	frameSize = UDim2.new(1, 0, 0, COIN_SATIR),
	position = UDim2.fromOffset(0, ROT_SATIR),
	parent = rotKutu,
	name = "RotCoinYazi",
})
UI.stroke(coinYazi, Color3.fromRGB(0, 0, 0), 2.5)

local function refreshRot(rot: number?, rotCoins: number?)
	rotYazi.Text = `{Format.short(rot or 0)} Rot`
	coinYazi.Text = `{Format.short(rotCoins or 0)} Rot Coin`
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
local detective = UI.panel(screen, UDim2.fromOffset(520, 440), "Detective")

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
	text = "Hand me a pitch-black brainrot and I will tell you who it is.",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 48),
	parent = detective,
})

UI.closeButton(detective).MouseButton1Click:Connect(function()
	detective.Visible = false
end)

local detectiveListe = makeScroll(detective, UDim2.fromOffset(14, 78), UDim2.new(1, -28, 1, -92))
local detectivePencere = BrainrotOnizleme.pencere(detectiveListe, detective)

DetectiveAc.OnClientEvent:Connect(function(pending)
	detectivePencere.temizle()
	clearRows(detectiveListe)

	for index, item in pending do
		local rarityInfo = Rarity.get(item.rarity)
		local row = brainrotRow(detectiveListe, {
			uid = item.uid,
			rarity = item.rarity,
			condition = item.condition,
			mutation = item.mutation,
			revealed = false,
		}, index, detectivePencere)

		row.MouseButton1Click:Connect(function()
			DetectiveTeslim:FireServer(item.uid)
			row.Visible = false
		end)

		UI.hover(row)

		UI.text({
			text = `{rarityInfo.revealTime}s`,
			size = UI.Sizes.tiny,
			color = UI.Colors.textDim,
			align = Enum.TextXAlignment.Right,
			frameSize = UDim2.fromOffset(90, 16),
			position = UDim2.new(1, -170, 1, -26),
			parent = row,
		})
	end

	detective.Visible = true
end)

DetectiveSonuc.OnClientEvent:Connect(function()
	if detective.Visible then
		detective.Visible = false
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
local magaza = UI.panel(screen, UDim2.fromOffset(520, 470), "Magaza")

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

local magazaListe = makeScroll(magaza, UDim2.fromOffset(14, 78), UDim2.new(1, -28, 1, -92))

--[[
	Magaza satiri.
	detail: o toola ozgu ikinci satir (kurekte bar/hiz, gpste sans/menzil)
	onBuy:  satin alma remote'unu tetikleyen fonksiyon
]]
local function shopRow(entry: any, detail: string, order: number, onBuy: () -> ())
	local color = Rarity.color(entry.rarity)

	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, -6, 0, 70)
	row.BackgroundColor3 = UI.Colors.panelLight
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	row.Text = ""
	row.LayoutOrder = order
	row.Parent = magazaListe
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
	})

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

MagazaAc.OnClientEvent:Connect(function(payload)
	clearRows(magazaListe)

	if type(payload) ~= "table" then
		return
	end

	local order = 0

	------------------------------------------------------------------
	-- KUREKLER: minigame kolayligi
	------------------------------------------------------------------
	order += 1
	sectionHeader(magazaListe, "SHOVELS  --  easier minigame", order)

	for _, entry in payload.shovels or {} do
		order += 1
		shopRow(
			entry,
			`Bar {math.floor(entry.barSize * 100)}%  -  Dig speed {string.format("%.2f", 1 / entry.digSpeed)}x`,
			order,
			function()
				KurekAl:FireServer(entry.id)
			end
		)
	end

	------------------------------------------------------------------
	-- DEDEKTORLER: yuksek rarity sansi
	------------------------------------------------------------------
	order += 1
	sectionHeader(magazaListe, "DETECTORS  --  better rarity odds", order)

	for _, entry in payload.detectors or {} do
		order += 1
		shopRow(
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
local luckyPanel = UI.panel(screen, UDim2.fromOffset(470, 300), "LuckyBlock")

UI.text({
	text = "LUCKY BLOCK",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = Rarity.LuckyBlock.colorA,
	frameSize = UDim2.new(1, -80, 0, 36),
	position = UDim2.fromOffset(18, 14),
	parent = luckyPanel,
})

-- Hangi turden blok acildi (Lucky Block / Altin / Elmas)
local luckyTier = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 50),
	parent = luckyPanel,
})

UI.closeButton(luckyPanel).MouseButton1Click:Connect(function()
	luckyPanel.Visible = false
end)

local luckyReel = Rulet.new(luckyPanel, {
	position = UDim2.new(0.5, 0, 0, 78),
	width = 408,
	height = 96,
	color = Rarity.LuckyBlock.colorA,
	name = "Cark",
})

local luckyResult = UI.text({
	text = "",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 26),
	position = UDim2.fromOffset(10, 186),
	parent = luckyPanel,
})

local luckyDetail = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 22),
	position = UDim2.fromOffset(10, 214),
	parent = luckyPanel,
})

LuckyBlockSonuc.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" or type(data.rarityCells) ~= "table" or type(data.cells) ~= "table" then
		return
	end

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

	local cells: { Rulet.Cell } = {}
	for index, entry in data.cells do
		table.insert(cells, {
			text = entry.name,
			color = Rarity.color(entry.rarity),
			brainrot = if type(entry.name) == "string"
				then {
					name = entry.name,
					mutation = if index == kazananSira and kazanan then kazanan.mutation else nil,
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

		-- 1. cark durdu: yalnizca kademe aciklanir, brainrot hala gizli
		onRarity = function(rarityId: string)
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
		end,
	})

	if not started then
		return
	end

	luckyTier.Text = if type(data.tierName) == "string" then string.upper(data.tierName) else ""
	luckyTier.TextColor3 = if typeof(data.tierColor) == "Color3" then data.tierColor else UI.Colors.textDim

	luckyResult.Text = "..."
	UI.plainStyle(luckyResult, UI.Colors.text)
	luckyDetail.Text = ""
	Rulet.tint(luckyReel, Rarity.LuckyBlock.colorA)

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

local function menuButonu(sutun: Frame, iconId: string, isim: string, renk: Color3, onClick: (() -> ())?)
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
		text = string.upper(string.sub(isim, 1, 3)),
		size = UI.Sizes.small,
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
		buton.MouseButton1Click:Connect(onClick)

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
}

-- SOL: oyunun kendi sistemleri
menuButonu(solSutun, "inventory", "Inventory", MenuRenk.inventory, toggleEnvanter)
-- Pet sistemi iptal edildi; yerinde Rot Coin magazasi
menuButonu(solSutun, "rotCoin", "Rot Coin Shop", MenuRenk.rotcoin, function()
	rotCoinMagazaAc()
end)
menuButonu(solSutun, "quests", "Quests", MenuRenk.quests, function()
	gorevPaneliniAc()
end)
menuButonu(solSutun, "rewards", "Rewards", MenuRenk.rewards, function()
	odulPaneliniAc()
end)
menuButonu(solSutun, "index", "Index", MenuRenk.index, function()
	Index.ac()
end)
menuButonu(solSutun, "friends", "Friends", MenuRenk.friends, function()
	arkadasPaneliniAc()
end)

-- SAG: ekstra
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
local ODUL_UST = 64
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
	text = "DAILY REWARD",
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
	kart.Parent = odulPanel
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

	-- Odulun ikonu: Rot icin para, Lucky Block icin blok (ikon paketi)
	local ikon = Instance.new("ImageLabel")
	ikon.Name = "Ikon"
	ikon.AnchorPoint = Vector2.new(0.5, 0.5)
	-- Rot Coin yazisi olan kartta ikon biraz kucuk ve asagida: yaziyla cakismasin
	local ikonBoy = if buyuk then 120 elseif coinVar then 48 else 62
	ikon.Position = UDim2.new(0.5, 0, 0.5, if coinVar then 0 else -10)
	ikon.Size = UDim2.fromOffset(ikonBoy, ikonBoy)
	ikon.BackgroundTransparency = 1
	ikon.ScaleType = Enum.ScaleType.Fit
	ikon.Parent = kart
	Icons.bind(ikon, if odul.kind == "rot" then "rot" else "luckyBlock")

	-- Lucky Block ikonu turun renginde hafifce boyanir: en pahali blok ucuzundan ayrilsin
	if odul.kind == "luckyblock" then
		ikon.ImageColor3 = Color3.new(1, 1, 1):Lerp(Rewards.color(gun), 0.35)
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

function odulPaneliniAc()
	odulPanel.Visible = not odulPanel.Visible
	if odulPanel.Visible then
		OdulAc:FireServer()
	end
end


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


------------------------------------------------------------------
-- ROTCOIN MAGAZASI  (sol menude eski Pets butonunun yeri)
--
-- Urunler ve fiyatlar Shared > RotCoinMagaza'da; satin alma sunucuda
-- dogrulanir. Panel yalnizca listeyi cizer ve id yollar.
------------------------------------------------------------------
local RC_SARI = Color3.fromRGB(255, 215, 40)

local rcPanel = UI.panel(screen, UDim2.fromOffset(500, 500), "RotCoinMagaza")

UI.text({
	text = "Rot Coin Shop",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = RC_SARI,
	frameSize = UDim2.new(1, -80, 0, 34),
	position = UDim2.fromOffset(18, 14),
	parent = rcPanel,
})

UI.closeButton(rcPanel).MouseButton1Click:Connect(function()
	rcPanel.Visible = false
end)

local rcBakiyeYazi = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	color = RC_SARI,
	frameSize = UDim2.new(1, -36, 0, 24),
	position = UDim2.fromOffset(18, 50),
	parent = rcPanel,
})

local rcIksirYazi = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -36, 0, 20),
	position = UDim2.fromOffset(18, 76),
	parent = rcPanel,
})

local rcListe = makeScroll(rcPanel, UDim2.fromOffset(14, 104), UDim2.new(1, -28, 1, -118))

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
		iksirBuff.Text = `Luck Potion: {yazi}`
		rcIksirYazi.Text = `Active potion: {yazi}`
		rcIksirYazi.TextColor3 = Color3.fromRGB(90, 220, 255)
	else
		rcIksirYazi.Text = "No luck potion active"
		rcIksirYazi.TextColor3 = UI.Colors.textDim
	end

	if iksirBuff.Visible ~= aktif then
		iksirBuff.Visible = aktif
		solSutunuYerlestir()
	end
end

local function rcCiz()
	rcBakiyeYazi.Text = `You have {Format.short(rcBakiye)} Rot Coin`
	iksirYazilariniGuncelle()

	clearRows(rcListe)

	for sira, urun in RotCoinMagaza.Urunler do
		local yeter = rcBakiye >= urun.price

		local satir = Instance.new("Frame")
		satir.Name = urun.id
		satir.Size = UDim2.new(1, -6, 0, 72)
		satir.BackgroundColor3 = UI.Colors.panelLight
		satir.BorderSizePixel = 0
		satir.LayoutOrder = sira
		satir.Parent = rcListe
		UI.corner(satir, 10)
		UI.stroke(satir, urun.color, 1)

		local ikon = Instance.new("ImageLabel")
		ikon.Name = "Ikon"
		ikon.Position = UDim2.fromOffset(8, 8)
		ikon.Size = UDim2.fromOffset(56, 56)
		ikon.BackgroundTransparency = 1
		ikon.ScaleType = Enum.ScaleType.Fit
		ikon.Parent = satir
		Icons.bind(ikon, urun.icon)
		if urun.tint then
			ikon.ImageColor3 = Color3.new(1, 1, 1):Lerp(urun.color, 0.35)
		end

		UI.text({
			text = urun.name,
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = urun.color,
			frameSize = UDim2.new(1, -214, 0, 24),
			position = UDim2.fromOffset(74, 10),
			parent = satir,
		})

		UI.text({
			text = urun.desc,
			size = UI.Sizes.tiny,
			color = UI.Colors.textDim,
			frameSize = UDim2.new(1, -214, 0, 30),
			position = UDim2.fromOffset(74, 34),
			parent = satir,
			wrapped = true,
		})

		local buton = UI.button(
			satir,
			`{urun.price} Rot Coin`,
			UDim2.fromOffset(124, 44),
			if yeter then UI.Colors.good else UI.Colors.panel
		)
		buton.AnchorPoint = Vector2.new(1, 0.5)
		buton.Position = UDim2.new(1, -10, 0.5, 0)
		UI.stroke(buton, Color3.fromRGB(0, 0, 0), 2)
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

------------------------------------------------------------------
-- AYARLAR PANELI  (Settings)
--
-- Panelin butun metinleri INGILIZCE -- oyuncunun gordugu her yer oyle.
--
-- Tek ayar var: ARAYUZ OLCEGI. Olcegi UI modulu uyguluyor (UI.setScale
-- butun ScreenGui'lere UIScale koyar); burasi yalnizca paneli cizer ve
-- secilen degeri sunucuya kaydeder.
--
-- Deger sunucuda PlayerData icinde durur (uiScale), boylece oyuncu
-- cikip girince ayari yerinde kalir.
------------------------------------------------------------------
local ayarPanel = UI.panel(screen, UDim2.fromOffset(430, 286), "Ayarlar")

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
		AyarKaydet:FireServer({ uiScale = UI.getScale() })
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
end)

olcekYazisiTazele(UI.getScale())

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
local gorevPanel = UI.panel(screen, UDim2.fromOffset(520, 470), "Gorevler")

UI.text({
	text = "Quests",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	frameSize = UDim2.new(1, -80, 0, 36),
	position = UDim2.fromOffset(18, 14),
	parent = gorevPanel,
})

local gorevSayacYazi = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 50),
	parent = gorevPanel,
})

UI.closeButton(gorevPanel).MouseButton1Click:Connect(function()
	gorevPanel.Visible = false
end)

local gorevListe = makeScroll(gorevPanel, UDim2.fromOffset(14, 82), UDim2.new(1, -28, 1, -96))

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
	row.Size = UDim2.new(1, -6, 0, 84)
	row.BackgroundColor3 = UI.Colors.panelLight
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.Parent = parent
	UI.corner(row, 10)
	-- Biten gorev kendi odulunun renginde cerceve alir
	UI.stroke(
		row,
		if hazir then UI.Colors.gold elseif bitti then UI.Colors.good else UI.Colors.panel,
		if hazir or bitti then 2 else 1
	)

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

	local oran = if quest.target > 0 then math.clamp(quest.progress / quest.target, 0, 1) else 0
	if oran > 0 then
		local dolgu = Instance.new("Frame")
		dolgu.Name = "Dolgu"
		dolgu.Size = UDim2.fromScale(oran, 1)
		dolgu.BackgroundColor3 = if bitti then UI.Colors.good else renk
		dolgu.BorderSizePixel = 0
		dolgu.Parent = oluk
		UI.corner(dolgu, 6)
	end

	--[[
		COLLECT

		Odul kendiliginden verilmiyor: hedef dolunca satirda bu dugme cikar.
		Cubugun sagindaki bosluga oturur, yazilarla ic ice girmez.

		Basilinca panel kapanir; patlama sunucudan gelir, boylece efekt
		arayuzun arkasinda kalmaz.
	]]
	if hazir then
		local topla = UI.button(row, "Collect", UDim2.fromOffset(100, 26), UI.Colors.gold)
		topla.AnchorPoint = Vector2.new(1, 0)
		-- Cubukla ayni hizada: cubuk 62..74, dugme 55..81
		topla.Position = UDim2.new(1, -14, 0, 55)
		-- Menu butonlariyla ayni imza: kalin siyah kontur
		UI.stroke(topla, Color3.fromRGB(0, 0, 0), 2)

		topla.MouseButton1Click:Connect(function()
			GorevAl:FireServer(quest.id)
			gorevPanel.Visible = false
		end)

		UI.hover(topla)
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

GorevDurum.OnClientEvent:Connect(function(veri)
	if type(veri) ~= "table" then
		return
	end

	gorevVerisi = veri
	gorevKalan = math.max(0, tonumber(veri.remaining) or 0)
	gorevSayaciYaz()

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
