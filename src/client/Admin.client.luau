--[[
	Admin  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Admin

	Test paneli. Yalnizca sunucu "yetkilisin" derse acilir
	(Config.Admin.userIds, ya da Studio'da allowInStudio).

	Panel sadece bir arayuz: butun komutlar sunucuda yeniden dogrulanir,
	yani bu script kurcalansa bile yetkisiz komut calismaz.

	Acilis tusu: Config.Admin.keyCode (varsayilan F2)
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))
local Shovels = require(Shared:WaitForChild("Shovels"))
local Detectors = require(Shared:WaitForChild("Detectors"))
local Flyboard = require(Shared:WaitForChild("Flyboard"))
local Rods = require(Shared:WaitForChild("Rods"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Ores = require(Shared:WaitForChild("Ores"))
local Passler = require(Shared:WaitForChild("Passler"))
local Hiz = require(Shared:WaitForChild("Hiz"))

local UI = require(script.Parent:WaitForChild("UI"))

local AdminPanelAc = Net.event("AdminPanelAc")
local AdminKomut = Net.event("AdminKomut")

local allowed = false

local screen = Instance.new("ScreenGui")
screen.Name = "AdminPanel"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local panel = UI.panel(screen, UDim2.fromOffset(560, 520), "Panel")

UI.text({
	text = "Admin Paneli",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = UI.Colors.gold,
	frameSize = UDim2.new(1, -80, 0, 36),
	position = UDim2.fromOffset(18, 14),
	parent = panel,
})

local subtitle = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 48),
	parent = panel,
})

UI.closeButton(panel).MouseButton1Click:Connect(function()
	panel.Visible = false
end)

local list = Instance.new("ScrollingFrame")
list.Name = "Liste"
list.Position = UDim2.fromOffset(14, 78)
list.Size = UDim2.new(1, -28, 1, -92)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.ScrollBarImageColor3 = UI.Colors.panelLight
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local order = 0

local function section(title: string)
	order += 1

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -6, 0, 24)
	holder.BackgroundTransparency = 1
	holder.LayoutOrder = order
	holder.Parent = list

	UI.text({
		text = title,
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = UI.Colors.textDim,
		frameSize = UDim2.fromScale(1, 1),
		parent = holder,
	})
end

local function actionButton(label: string, command: string, arg: any?, color: Color3?)
	order += 1

	local button = UI.button(list, label, UDim2.new(1, -6, 0, 40), color)
	button.LayoutOrder = order

	button.MouseButton1Click:Connect(function()
		AdminKomut:FireServer(command, arg)
	end)
end

--[[
	Yan yana dizilen kucuk butonlar (kurek/dedektor/rarity/mutasyon secimi).

	entry.command + entry.arg -> tiklaninca komutu gonderir
	entry.getArg              -> arg'i TIKLAMA aninda hesaplar (secili mutasyon)
	entry.onClick             -> komut gondermez, sadece cagrilir (secim yapar)

	Uretilen butonlari dondurur ki secili olan isaretlenebilsin.
]]
type ChipEntry = {
	label: string,
	command: string?,
	arg: any,
	getArg: (() -> any)?,
	onClick: ((index: number) -> ())?,
	color: Color3?,
}

local function chipRow(entries: { ChipEntry }): { TextButton }
	order += 1

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, 36)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = list

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.Padding = UDim.new(0, 6)
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Parent = row

	local width = 1 / #entries
	local chips: { TextButton } = {}

	for index, entry in entries do
		local chip = Instance.new("TextButton")
		chip.Size = UDim2.new(width, -6, 1, 0)
		chip.BackgroundColor3 = UI.Colors.panelLight
		chip.BorderSizePixel = 0
		chip.AutoButtonColor = true
		chip.Text = ""
		chip.LayoutOrder = index
		chip.Parent = row
		UI.corner(chip, 8)
		UI.stroke(chip, entry.color or UI.Colors.accent, 1)

		UI.text({
			text = entry.label,
			size = UI.Sizes.tiny,
			font = UI.Fonts.bold,
			color = entry.color or UI.Colors.text,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.fromScale(1, 1),
			parent = chip,
		})

		table.insert(chips, chip)

		chip.MouseButton1Click:Connect(function()
			if entry.onClick then
				entry.onClick(index)
				return
			end
			AdminKomut:FireServer(entry.command, if entry.getArg then entry.getArg() else entry.arg)
		end)
	end

	return chips
end

------------------------------------------------------------------
-- PANEL ICERIGI
------------------------------------------------------------------
local built = false

local function buildPanel(info: any)
	if built then
		return
	end
	built = true

	subtitle.Text = `{Config.Admin.keyCode.Name} ile ac/kapat  --  butun komutlar sunucuda dogrulanir`

	section("HIZLI")
	actionButton("Butun toollari ver (en ust seviye)", "giveAllTools", nil, UI.Colors.good)
	actionButton(`Rot ver  (+{Format.short(info.rotGrant or 0)})`, "giveRot", nil, UI.Colors.gold)
	-- Rot Coin (Rot Coin Shop parasi)
	for _, miktar in { 10, 100, 1000 } do
		actionButton(`Rot Coin ver  (+{miktar})`, "giveRotCoins", miktar, Color3.fromRGB(120, 226, 150))
	end
	actionButton(
		`Blok yagmuru baslat  ({LuckyBlock.Event.count} blok)`,
		"luckyEvent",
		nil,
		UI.Colors.warn
	)

	-- Her tur icin ayri buton; her tik tek blok verir
	for _, tier in LuckyBlock.Tiers do
		actionButton(`{tier.displayName} ver  (+1)`, "giveLuckyBlock", tier.id, tier.color)
	end
	actionButton("Envanterdeki brainrotlarin kimligini ac", "revealAll", nil, UI.Colors.accent)
	-- Ogreticiyi basa sarar: test icin her seferinde yeni hesap gerekmesin
	actionButton("Ogreticiyi basa sar (1. adim)", "ogreticiSifirla", nil, Color3.fromRGB(255, 215, 60))
	actionButton("Ogretici: siradaki adima gec", "ogreticiAtla", nil, Color3.fromRGB(255, 190, 90))
	actionButton("Ogreticiyi bitir", "ogreticiBitir", nil, Color3.fromRGB(200, 170, 110))
	actionButton("Ada ipucunu sifirla (650M > Candy)", "adaIpucuSifirla", nil, Color3.fromRGB(255, 120, 120))
	actionButton("Mutasyon cekilisini test et (1000 kez, Output'a yazar)", "testMutation", nil, UI.Colors.textDim)
	actionButton("Harita raporu (ada/base/NPC konumlari, Output'a yazar)", "haritaRaporu", nil, UI.Colors.textDim)
	actionButton("Kum raporu (bastigin zemin, Output'a yazar)", "kumRaporu", nil, UI.Colors.textDim)
	actionButton("VFX raporu (suzme efektinin icerigi)", "vfxRaporu", nil, UI.Colors.textDim)
	actionButton("Gizli brainrot raporu (HiddenPart modeli)", "gizliRaporu", nil, UI.Colors.textDim)
	actionButton("Yabanci script raporu (haritadaki scriptler, Output'a yazar)", "scriptRaporu", nil, UI.Colors.warn)

	--[[
		KUREK SEVIYESI: 20 seviye tek satira sigmiyor; her ada ayri satir
		(Main 1-5, Candy 6-10, Snow 11-15, Volcano 16-20).
	]]
	section("KUREK SEVIYESI  --  Main / Candy / Snow / Volcano")
	-- "main" yalnizca isaret: tabloda nil tutulamiyor (dongu onu atlardi)
	for _, ada in { "main", "sekerkum", "snowkum", "alevkum" } do
		local shovelChips = {}
		for _, shovel in Shovels.forIsland(if ada == "main" then nil else ada) do
			table.insert(shovelChips, {
				label = `Lv{shovel.level}`,
				command = "setShovel",
				arg = shovel.id,
				color = if shovel.island then shovel.color else Rarity.color(shovel.rarity),
			})
		end
		if #shovelChips > 0 then
			chipRow(shovelChips)
		end
	end

	section("HIZ  --  alinan yukseltme sayisi (Speed = sayi + 1)")
	local hizChips = {}
	for _, adet in { 0, 10, 25, 50, 75, 99, 100 } do
		table.insert(hizChips, {
			label = tostring(adet),
			command = "setSpeed",
			arg = adet,
			color = Hiz.renk(adet + 1),
		})
	end
	chipRow(hizChips)

	section("HIZ REBIRTH  --  iz rengi ve boyu")
	local rebirthChips = {}
	for adet = 0, Hiz.MaxRebirth do
		table.insert(rebirthChips, {
			label = `R{adet}`,
			command = "setRebirth",
			arg = adet,
			color = Hiz.rebirthRengi(adet) or UI.Colors.textDim,
		})
	end
	chipRow(rebirthChips)

	section("ROBUX GECISLERI  --  bu oturum icin ver / al")
	local passChips = {}
	for ad, pass in Passler.Info do
		table.insert(passChips, {
			label = pass.ad,
			command = "togglePass",
			arg = ad,
			color = UI.Colors.gold,
		})
	end
	chipRow(passChips)

	section("DEDEKTOR SEVIYESI")
	local detectorChips = {}
	for _, id in Detectors.Order do
		local detector = Detectors.get(id)
		table.insert(detectorChips, {
			label = `Lv{detector.level}`,
			command = "setDetector",
			arg = id,
			color = Rarity.color(detector.rarity),
		})
	end
	chipRow(detectorChips)

	section("FLYBOARD KADEMESI")
	local flyboardChips = {}
	for _, id in Flyboard.Order do
		local board = Flyboard.Info[id]
		table.insert(flyboardChips, {
			label = `Lv{board.level}`,
			command = "setFlyboard",
			arg = id,
			color = board.color,
		})
	end
	chipRow(flyboardChips)

	section("OLTA KADEMESI")
	local rodChips = {}
	for _, id in Rods.Order do
		local rod = Rods.Info[id]
		table.insert(rodChips, {
			label = `Lv{rod.level}`,
			command = "setRod",
			arg = id,
			color = rod.color,
		})
	end
	chipRow(rodChips)

	------------------------------------------------------------------
	-- KAZMA + MADEN
	------------------------------------------------------------------
	section("KAZMA VER")
	local pickaxeChips: { any } = {}
	for _, ada in Ores.IslandOrder do
		local kazma = Ores.Pickaxes[Ores.Islands[ada].pickaxe]
		table.insert(pickaxeChips, {
			label = string.gsub(kazma.displayName, " Pickaxe", ""),
			command = "givePickaxe",
			arg = kazma.id,
			color = kazma.color,
		})
	end
	table.insert(pickaxeChips, {
		label = "Hepsi",
		command = "givePickaxe",
		arg = "all",
		color = UI.Colors.good,
	})
	chipRow(pickaxeChips)

	-- Her ada bir satir: once "uc maden birden", sonra tek tek
	section("MADEN VER  (+10)")
	for _, ada in Ores.IslandOrder do
		local cfg = Ores.Islands[ada]
		local oreChips: { any } = {
			{
				label = `{string.gsub(cfg.name, " Island", "")} x3`,
				command = "giveOres",
				arg = ada,
				color = cfg.color,
			},
		}
		for _, id in cfg.ores do
			table.insert(oreChips, {
				label = id,
				command = "giveOres",
				arg = id,
				color = cfg.color,
			})
		end
		chipRow(oreChips)
	end

	-- Maden kayasini dogurur (kazmak icin adanin kazmasi gerekir)
	section("MADEN SPAWNLA  --  kazma ile kaz")
	for _, ada in Ores.IslandOrder do
		local cfg = Ores.Islands[ada]
		local spawnChips: { any } = {}
		for _, id in cfg.ores do
			table.insert(spawnChips, {
				label = id,
				command = "spawnBeam",
				arg = id,
				color = cfg.color,
			})
		end
		chipRow(spawnChips)
	end

	--[[
		MUTASYON butonlari iki is birden yapar:

		1. ELINDE acilmis bir brainrot varsa, o brainrot dogrudan secilen
		   mutasyonlu haline doner (setMutation).
		2. Ayni tikla secim de yapilir; asagidaki "BRAINROT VER" ile
		   uretilen yeni brainrot bu mutasyonla gelir.

		Secili olan kalin konturla belli olur.
	]]
	section("MUTASYON  --  ELINDEKI brainrotu cevirir")

	--[[
		Mutasyon butonlari YALNIZCA ELDEKI brainrotu cevirir.

		Onceden bu butonlar ayni zamanda bir "secim" yapiyordu ve secim
		yapiskan kaliyordu: bir kez Hacker'a basan oyuncunun sonraki her
		brainrotu Hacker geliyordu. Artik secim yok -- asagidaki
		"BRAINROT VER" her zaman rastgele mutasyon cekiyor.
	]]
	local mutationChips: { TextButton }
	local mutationEntries: { any } = {}

	for _, id in Mutations.Order do
		local info = Mutations.get(id)
		table.insert(mutationEntries, {
			label = string.sub(info.displayName, 1, 4),
			color = info.color,
			onClick = function(index: number)
				-- Elde acilmis brainrot varsa onu bu mutasyona cevir
				AdminKomut:FireServer("setMutation", id)

				-- Kisa bir vurgu: hangi butona basildigi gorunsun
				local chip = mutationChips[index]
				local stroke = chip and chip:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Thickness = 3
					task.delay(0.35, function()
						if stroke.Parent then
							stroke.Thickness = 1
						end
					end)
				end
			end,
		})
	end

	mutationChips = chipRow(mutationEntries)


	--[[
		ISIK SUZMESI SPAWNLA

		Istenen kademede bir suzme dogurur. Cekilis, sans ve adet siniri
		yoktur: suzmenin gorunumunu ve o kademedeki kazi zorlugunu istedigin
		an sinamak icin. Kum yoksa oyuncunun onune konur.
	]]
	section("SUZME SPAWNLA  --  kaziyi ve zorlugu test et")

	local beamChips: { any } = {}
	for _, id in Rarity.Order do
		table.insert(beamChips, {
			label = string.sub(Rarity.get(id).displayName, 1, 4),
			command = "spawnBeam",
			arg = id,
			color = Rarity.color(id),
		})
	end
	chipRow(beamChips)

	-- Kademe disi suzme turleri
	chipRow({
		{
			label = "Lucky",
			command = "spawnBeam",
			arg = "LuckyBlock",
			color = Rarity.LuckyBlock.colorA,
		},
	})

	--[[
		GIRDAP SPAWNLA

		Suzmenin deniz karsiligi. Normalde olta + flyboard + sans gerekiyor;
		buradan dogrudan doguyor. Yakinda su yoksa karaya konur ve sunucu
		bunu mesajda soyler.
	]]
	section("GIRDAP SPAWNLA  --  denizdeki karsiligi")

	local girdapChips: { any } = {}
	for _, id in Rarity.Order do
		table.insert(girdapChips, {
			label = string.sub(Rarity.get(id).displayName, 1, 4),
			command = "spawnGirdap",
			arg = id,
			color = Rarity.color(id),
		})
	end
	chipRow(girdapChips)

	section("BRAINROT VER  --  mutasyon rastgele")
	local rarityChips: { any } = {}
	for _, id in Rarity.Order do
		table.insert(rarityChips, {
			label = string.sub(Rarity.get(id).displayName, 1, 4),
			command = "giveBrainrot",
			-- Arg tiklama aninda hesaplanir: o an secili mutasyon kullanilir
			-- Mutasyon her zaman rastgele cekilir (sunucu tarafinda)
			arg = id,
			color = Rarity.color(id),
		})
	end
	chipRow(rarityChips)

	--[[
		KIMLIKSIZ BRAINROT

		Siyah (acilmamis) halde geliyor: kademesinin yumurtasi olarak
		cantaya giriyor, kimligi Detective'te aciliyor. Yumurta boylarini
		ve Divine ustu efektleri sinamak icin.
	]]
	section("KIMLIKSIZ BRAINROT VER  --  Detective'te acilir")
	local gizliChips: { any } = {}
	for _, id in Rarity.Order do
		table.insert(gizliChips, {
			label = string.sub(Rarity.get(id).displayName, 1, 4),
			command = "giveGizliBrainrot",
			arg = id,
			color = Rarity.color(id),
		})
	end
	chipRow(gizliChips)

	section("TEHLIKELI")
	actionButton("Envanteri temizle", "clearInventory", nil, UI.Colors.bad)
end

------------------------------------------------------------------
-- YETKI
------------------------------------------------------------------
AdminPanelAc.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" or not info.allowed then
		allowed = false
		panel.Visible = false
		return
	end

	allowed = true
	buildPanel(info)
end)

ContextActionService:BindAction("AdminPanelAc", function(_, state)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	if not allowed then
		return Enum.ContextActionResult.Pass
	end

	panel.Visible = not panel.Visible
	return Enum.ContextActionResult.Sink
end, false, Config.Admin.keyCode)
