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

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarity = require(Shared:WaitForChild("Rarity"))
local Condition = require(Shared:WaitForChild("Condition"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Shovels = require(Shared:WaitForChild("Shovels"))
local Detectors = require(Shared:WaitForChild("Detectors"))
local Skins = require(Shared:WaitForChild("Skins"))
local Format = require(Shared:WaitForChild("Format"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Net = require(Shared:WaitForChild("Net"))
local Icons = require(Shared:WaitForChild("Icons"))
local Rewards = require(Shared:WaitForChild("Rewards"))

local UI = require(script.Parent:WaitForChild("UI"))
-- Iki asamali rulet (Rot Slots + Lucky Block ayni mekanigi kullanir)
local Rulet = require(script.Parent:WaitForChild("Rulet"))

local EnvanterGuncelle = Net.event("EnvanterGuncelle")
local DetectiveAc = Net.event("DetectiveAc")
local DetectiveTeslim = Net.event("DetectiveTeslim")
local DetectiveSonuc = Net.event("DetectiveSonuc")
local BaseGuncelle = Net.event("BaseGuncelle")
local SlottanAl = Net.event("SlottanAl")
local EtkinlikSayaci = Net.event("EtkinlikSayaci")
local LuckyBlockSonuc = Net.event("LuckyBlockSonuc")
local OdulAc = Net.event("OdulAc")
local OdulCevir = Net.event("OdulCevir")
local OdulDurum = Net.event("OdulDurum")
local OdulSonuc = Net.event("OdulSonuc")
local SlotMakinesiAc = Net.event("SlotMakinesiAc")
local SlotMakinesiCevir = Net.event("SlotMakinesiCevir")
local SlotMakinesiSonuc = Net.event("SlotMakinesiSonuc")
local SkinTak = Net.event("SkinTak")
local SkinDongu = Net.event("SkinDongu")
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
	skins = {},
	equipped = {},
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
local function brainrotRow(parent: Instance, item: any, order: number): TextButton
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

	-- Simsiyah brainrot: kare tamamen siyah, sadece rarity belli
	local icon = Instance.new("Frame")
	icon.Size = UDim2.fromOffset(42, 42)
	icon.Position = UDim2.fromOffset(10, 10)
	icon.BackgroundColor3 = if revealed then rarityInfo.color else Color3.fromRGB(10, 10, 12)
	icon.BorderSizePixel = 0
	icon.Parent = row
	UI.corner(icon, 8)
	UI.stroke(icon, rarityInfo.color, 1)

	if not revealed then
		UI.text({
			text = "?",
			size = UI.Sizes.heading,
			font = UI.Fonts.bold,
			color = rarityInfo.color,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.fromScale(1, 1),
			parent = icon,
		})
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
			frameSize = UDim2.new(1, -180, 0, 22),
			position = UDim2.fromOffset(62, 9),
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
		frameSize = UDim2.new(1, -180, 0, 20),
		position = UDim2.fromOffset(62, 32),
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

-- Brainrot sayilarinin altinda Rot Coin bakiyesi
local envanterCoin = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = UI.Colors.gold,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 68),
	parent = envanter,
})

UI.closeButton(envanter).MouseButton1Click:Connect(function()
	envanter.Visible = false
end)

local envanterListe = makeScroll(envanter, UDim2.fromOffset(14, 96), UDim2.new(1, -28, 1, -110))

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

	-- Fuse coinleri de burada gorunsun; bozdurucuya gitmeden once bilsin
	local fuseCoins = #(inventory.coins or {})
	envanterCoin.Text = if fuseCoins > 0
		then `{inventory.rotCoins or 0} Rot Coin  -  {fuseCoins} Fuse Coin`
		else `{inventory.rotCoins or 0} Rot Coin`

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
		local row = brainrotRow(envanterListe, item, 100 + index)

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
-- Tek satir (Rot); yazi 3 katina cikarildigi icin kutu da buyudu
rotKutu.Size = UDim2.fromOffset(460, 96)
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
		frameSize = UDim2.fromScale(1, 1),
		parent = rotKutu,
	})

	-- Kalinlik yazi boyundan bagimsiz sabit: 60px rakamda 3px kontur
	-- (Fonts.applyOutline kalinligi TextSize ile buyutur, burada istenmiyor)
	UI.stroke(yazi, Color3.fromRGB(0, 0, 0), 3)

	return yazi
end

-- 60px: eski olcunun (20) 3 kati
local rotYazi = paraSatiri(UI.Sizes.label * 3)

-- Rot Coin bakiyesi HUD.tan kaldirildi; yalnizca ana para (Rot) gorunuyor
local function refreshRot(rot: number?)
	rotYazi.Text = `{Format.short(rot or 0)} Rot`
end

refreshRot(inventory.rot)

--[[
	Ayri bir baglanti: gelen veriyi DOGRUDAN okuyor, yukaridaki envanter
	baglantisinin once calismasina guvenmiyor. Roblox ayni sinyaldeki
	baglantilarin sirasini garanti etmez.
]]
EnvanterGuncelle.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end
	refreshRot(data.rot)
end)

------------------------------------------------------------------
-- SKIN DONGUSU (Z)
-- Elde tutulan tool'un gorunumunu sirayla degistirir:
--   varsayilan -> sahip olunan 1. skin -> 2. skin -> ... -> varsayilan
-- Seviye parlamasi degismez; sadece govde gorunumu doner.
------------------------------------------------------------------
ContextActionService:BindAction("SkinDongusu", function(_, state)
	if state == Enum.UserInputState.Begin then
		SkinDongu:FireServer()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.Z)

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

DetectiveAc.OnClientEvent:Connect(function(pending)
	clearRows(detectiveListe)

	for index, item in pending do
		local rarityInfo = Rarity.get(item.rarity)
		local row = brainrotRow(detectiveListe, {
			uid = item.uid,
			rarity = item.rarity,
			condition = item.condition,
			mutation = item.mutation,
			revealed = false,
		}, index)

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
-- SLOT MAKINESI  --  IKI ASAMALI RULET
--
-- 1. ASAMA  Bolmelerde yalnizca "?" ve KADEME RENGI doner. Rulet durunca
--           hangi kademenin ciktigi belli olur, hangi skin oldugu degil.
-- 2. ASAMA  Serit yeniden kurulur; bu kez SADECE o kademeden cikabilecek
--           skinler adiyla doner ve odul aciga cikar.
--
-- Sunucu yalnizca kazanan skini gonderir; seridi burasi kurar (Skins
-- katalogu paylasimli). Sureler Skins.Wheel'den geldigi icin sunucunun
-- odulu verdigi an ile ruletin durdugu an her zaman ayni kalir.
------------------------------------------------------------------
local slotPanel = UI.panel(screen, UDim2.fromOffset(470, 400), "SlotMakinesi")

UI.text({
	text = "Rot Slots",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = UI.Colors.gold,
	frameSize = UDim2.new(1, -80, 0, 36),
	position = UDim2.fromOffset(18, 14),
	parent = slotPanel,
})

local slotCoinLabel = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 48),
	parent = slotPanel,
})

UI.closeButton(slotPanel).MouseButton1Click:Connect(function()
	slotPanel.Visible = false
end)

local slotReel = Rulet.new(slotPanel, {
	position = UDim2.new(0.5, 0, 0, 86),
	width = 408,
	height = 96,
	color = UI.Colors.gold,
	name = "Rulet",
})

local slotRng = Random.new()

--[[
	1. ASAMA bolmeleri: katalogdan cekilmis rastgele skinlerin KADEMELERI.

	Cekilis gercek agirliklarla yapiliyor (Skins.roll), boylece serit oyunun
	gercek dagilimina benzer gorunur: cok Common, arada bir Legendary.
	winnerRarity verilirse kazanan bolmeye o konur; verilmezse serit yalnizca
	bekleme halindedir.
]]
local function slotRarityCells(winnerRarity: string?): { string }
	local W = Skins.Wheel
	local cells: { string } = {}

	for index = 1, W.cellCount do
		if winnerRarity and index == W.winnerIndex then
			table.insert(cells, winnerRarity)
		else
			table.insert(cells, Skins.roll(slotRng).rarity)
		end
	end

	return cells
end

--[[
	2. ASAMA bolmeleri: SADECE kazanan kademedeki skinler, adiyla.

	O kademede tek skin varsa butun bolmeler ayni gorunur -- dogru davranis,
	cunku gercekten baska ihtimal yoktur.
]]
local function slotSkinCells(winnerRarity: string, winnerId: string): { Rulet.Cell }
	local W = Skins.Wheel
	local pool = Skins.byRarity(winnerRarity)
	local color = Rarity.color(winnerRarity)
	local winner = Skins.get(winnerId)

	local cells: { Rulet.Cell } = {}

	for index = 1, W.revealCellCount do
		local pick = if index == W.revealWinnerIndex
			then winner
			elseif #pool > 0 then pool[slotRng:NextInteger(1, #pool)]
			else nil

		table.insert(cells, {
			text = if pick then pick.displayName else "?",
			color = color,
		})
	end

	return cells
end

local reelName = UI.text({
	text = "Spin!",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 26),
	position = UDim2.new(0, 10, 0, 194),
	parent = slotPanel,
})

local reelDetail = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 22),
	position = UDim2.new(0, 10, 0, 222),
	parent = slotPanel,
})

local spinButton = UI.button(slotPanel, "SPIN (1 Rot Coin)", UDim2.new(1, -36, 0, 46), UI.Colors.gold)
spinButton.AnchorPoint = Vector2.new(0.5, 1)
spinButton.Position = UDim2.new(0.5, 0, 1, -18)
local spinLabel = spinButton:FindFirstChild("Label") :: TextLabel
spinLabel.TextColor3 = Color3.fromRGB(28, 24, 10)

spinButton.MouseButton1Click:Connect(function()
	SlotMakinesiCevir:FireServer()
end)

SlotMakinesiAc.OnClientEvent:Connect(function(data)
	slotCoinLabel.Text = `{data.rotCoins} Rot Coins  -  {data.cost} coin per spin`

	-- Panel ilk acildiginda serit bos durmasin: "?" bolmelerle beklesin
	Rulet.reset(slotReel, slotRarityCells(nil))

	slotPanel.Visible = true
end)

SlotMakinesiSonuc.OnClientEvent:Connect(function(result)
	if type(result) ~= "table" or type(result.id) ~= "string" then
		return
	end

	local W = Skins.Wheel

	local started = Rulet.run(slotReel, {
		rarityCells = slotRarityCells(result.rarity),
		rarityWinner = W.winnerIndex,
		rarityTime = W.spinTime,
		pause = W.pause,
		cells = slotSkinCells(result.rarity, result.id),
		winner = W.revealWinnerIndex,
		time = W.revealSpinTime,

		-- 1. cark durdu: yalnizca kademe aciklanir
		onRarity = function(rarityId: string)
			reelName.Text = string.upper(Rarity.displayName(rarityId))
			UI.rarityStyle(reelName, rarityId)
			reelDetail.Text = "Tier locked in, now which skin?"
			reelDetail.TextColor3 = UI.Colors.textDim
		end,

		-- 2. cark durdu: odul aciga cikar
		onFinish = function()
			spinButton.Active = true
			Rulet.shake(slotPanel)

			reelName.Text = result.displayName
			UI.rarityStyle(reelName, result.rarity)

			local rarityLabel = Rarity.displayName(result.rarity)
			local toolLabel = if result.tool == "Shovel" then "Shovel" else "GPS"
			reelDetail.Text = if result.duplicate
				then `{toolLabel} {rarityLabel} (already owned)`
				else `{toolLabel} {rarityLabel} (NEW!)`
			reelDetail.TextColor3 = if result.duplicate then UI.Colors.textDim else UI.Colors.good

			if not result.duplicate then
				SkinTak:FireServer(result.id)
			end
		end,
	})

	if not started then
		return
	end

	spinButton.Active = false
	reelName.Text = "..."
	UI.plainStyle(reelName, UI.Colors.text)
	reelDetail.Text = ""
	Rulet.tint(slotReel, UI.Colors.gold)
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
	local cells: { Rulet.Cell } = {}
	for _, entry in data.cells do
		table.insert(cells, { text = entry.name, color = Rarity.color(entry.rarity) })
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
-- Ekranin en ustune yakin: Roblox'un ust barinin ikonlari kenarlarda,
-- orta kisim bos oldugu icin cakisma olmuyor
sayacKutu.Position = UDim2.new(0.5, 0, 0, 6)
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
-- Ayarlar paneli de dosyanin sonunda kuruluyor; ayni sebeple once bildirilir
local ayarPaneliniAc: () -> ()
-- Gorev panosu da oyle
local gorevPaneliniAc: () -> ()

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

	solSutun.Position = UDim2.new(0, 16, 1, -(altBosluk + paraYuksekligi + SUTUN_BOSLUK))
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
	pets = Color3.fromRGB(120, 226, 150), -- yesil
	quests = Color3.fromRGB(255, 150, 70), -- turuncu
	rewards = Color3.fromRGB(255, 214, 41), -- altin
	index = Color3.fromRGB(186, 120, 255), -- mor
	friends = Color3.fromRGB(255, 120, 190), -- pembe
	settings = Color3.fromRGB(90, 220, 210), -- turkuaz
}

-- SOL: oyunun kendi sistemleri
menuButonu(solSutun, "inventory", "Inventory", MenuRenk.inventory, toggleEnvanter)
menuButonu(solSutun, "pets", "Pets", MenuRenk.pets)
menuButonu(solSutun, "quests", "Quests", MenuRenk.quests, function()
	gorevPaneliniAc()
end)
menuButonu(solSutun, "rewards", "Rewards", MenuRenk.rewards, function()
	odulPaneliniAc()
end)
menuButonu(solSutun, "index", "Index", MenuRenk.index)
menuButonu(solSutun, "friends", "Friends", MenuRenk.friends)

-- SAG: ekstra
menuButonu(sagSutun, "settings", "Settings", MenuRenk.settings, function()
	ayarPaneliniAc()
end)


------------------------------------------------------------------
-- GUNLUK ODUL PANELI
--
-- Cark yalnizca gosterim: kazanan bolmeyi sunucu belirliyor, istemci
-- gelen indekste durduruyor. Odul de cark durunca veriliyor.
------------------------------------------------------------------
local ODUL_CELL_W = 130
local ODUL_CELL_GAP = 6
local ODUL_REEL_W = 400
local ODUL_REEL_H = 92

local odulPanel = UI.panel(screen, UDim2.fromOffset(460, 330), "GunlukOdul")

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

local odulReel = Instance.new("Frame")
odulReel.Name = "Cark"
odulReel.AnchorPoint = Vector2.new(0.5, 0)
odulReel.Position = UDim2.new(0.5, 0, 0, 62)
odulReel.Size = UDim2.fromOffset(ODUL_REEL_W, ODUL_REEL_H)
odulReel.BackgroundColor3 = Color3.fromRGB(12, 14, 19)
odulReel.BorderSizePixel = 0
odulReel.ClipsDescendants = true
odulReel.Parent = odulPanel
UI.corner(odulReel, 12)
UI.stroke(odulReel, UI.Colors.gold, 2)

local odulSerit = Instance.new("Frame")
odulSerit.Name = "Serit"
odulSerit.AnchorPoint = Vector2.new(0, 0.5)
odulSerit.Position = UDim2.new(0, 0, 0.5, 0)
odulSerit.Size = UDim2.new(0, 0, 1, -14)
odulSerit.BackgroundTransparency = 1
odulSerit.Parent = odulReel

local odulIsaretci = Instance.new("Frame")
odulIsaretci.Name = "Isaretci"
odulIsaretci.AnchorPoint = Vector2.new(0.5, 0.5)
odulIsaretci.Position = UDim2.fromScale(0.5, 0.5)
odulIsaretci.Size = UDim2.new(0, 3, 1, 0)
odulIsaretci.BackgroundColor3 = UI.Colors.gold
odulIsaretci.BorderSizePixel = 0
odulIsaretci.ZIndex = 6
odulIsaretci.Parent = odulReel

local odulSonucYazi = UI.text({
	text = "",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 26),
	position = UDim2.fromOffset(10, 168),
	parent = odulPanel,
})

local odulDurumYazi = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 22),
	position = UDim2.fromOffset(10, 198),
	parent = odulPanel,
})

local odulButon = UI.button(odulPanel, "SPIN", UDim2.new(1, -40, 0, 48), UI.Colors.gold)
odulButon.AnchorPoint = Vector2.new(0.5, 1)
odulButon.Position = UDim2.new(0.5, 0, 1, -18)

local odulButonYazi = odulButon:FindFirstChild("Label", true) :: TextLabel?
if odulButonYazi then
	odulButonYazi.TextColor3 = Color3.fromRGB(30, 26, 8)
end

local function odulOffsetFor(index: number): number
	local center = (index - 1) * ODUL_CELL_W + ODUL_CELL_W / 2
	return -(center - ODUL_REEL_W / 2)
end

local function odulSeritKur(cells: { any })
	for _, child in odulSerit:GetChildren() do
		child:Destroy()
	end

	odulSerit.Size = UDim2.new(0, ODUL_CELL_W * #cells, 1, -14)

	for index, entry in cells do
		local hucre = Instance.new("Frame")
		hucre.Name = `Bolme{index}`
		hucre.AnchorPoint = Vector2.new(0, 0.5)
		hucre.Position = UDim2.fromOffset((index - 1) * ODUL_CELL_W + ODUL_CELL_GAP, 0)
		hucre.Size = UDim2.fromOffset(ODUL_CELL_W - ODUL_CELL_GAP * 2, 70)
		hucre.BackgroundColor3 = entry.color
		hucre.BackgroundTransparency = 0.78
		hucre.BorderSizePixel = 0
		hucre.Parent = odulSerit
		UI.corner(hucre, 8)
		UI.stroke(hucre, entry.color, 2)

		UI.text({
			text = entry.label,
			size = UI.Sizes.tiny,
			font = UI.Fonts.bold,
			color = entry.color,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.new(1, -8, 1, -8),
			position = UDim2.fromOffset(4, 4),
			parent = hucre,
			wrapped = true,
		})
	end
end

local odulKalan = 0
local odulHazir = false
local odulDonuyor = false

local function odulButonTazele()
	if odulDonuyor then
		odulButon.Visible = false
		return
	end

	odulButon.Visible = true
	if odulButonYazi then
		odulButonYazi.Text = if odulHazir then "SPIN" else Rewards.formatRemaining(odulKalan)
	end
end

OdulDurum.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end

	odulKalan = tonumber(data.remaining) or 0
	odulHazir = data.ready == true

	odulDurumYazi.Text = if odulHazir
		then "Wheel is ready!"
		else `Next reward in {Rewards.formatRemaining(odulKalan)}`

	odulButonTazele()
end)

-- Sayac istemcide de ilerlesin; sunucu her cevirmede tazeliyor
task.spawn(function()
	while true do
		task.wait(1)
		if not odulHazir and odulKalan > 0 then
			odulKalan -= 1
			if odulKalan <= 0 then
				odulHazir = true
				odulDurumYazi.Text = "Wheel is ready!"
			elseif odulPanel.Visible then
				odulDurumYazi.Text = `Next reward in {Rewards.formatRemaining(odulKalan)}`
			end
			odulButonTazele()
		end
	end
end)

odulButon.MouseButton1Click:Connect(function()
	if odulDonuyor or not odulHazir then
		return
	end
	OdulCevir:FireServer()
end)

OdulSonuc.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" or type(data.cells) ~= "table" then
		return
	end

	odulDonuyor = true
	odulSonucYazi.Text = "..."
	odulButonTazele()

	odulSeritKur(data.cells)
	odulSerit.Position = UDim2.new(0, 0, 0.5, 0)
	odulPanel.Visible = true

	local tween = TweenService:Create(
		odulSerit,
		TweenInfo.new(data.spinTime or 3.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, odulOffsetFor(data.winnerIndex), 0.5, 0) }
	)

	tween.Completed:Connect(function()
		odulDonuyor = false
		odulButonTazele()

		local winner = data.winner
		if type(winner) == "table" then
			odulSonucYazi.Text = winner.label
			odulSonucYazi.TextColor3 = winner.color
		end
	end)

	tween:Play()
end)

function odulPaneliniAc()
	odulPanel.Visible = not odulPanel.Visible
	if odulPanel.Visible then
		OdulAc:FireServer()
	end
end


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

	-- Odul her zaman coin; rengi coinin kademesinden gelir
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
