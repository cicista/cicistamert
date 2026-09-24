--[[
	Detective  (Script)
	Yeri: ServerScriptService > Detective

	Brainrot Detective NPC'si.

	Kazidan cikan brainrot envantere SIMSIYAH gelir: oyuncu sadece rarity'sini
	ve kondisyonunu gorur, hangi brainrot oldugunu bilmez. Bu NPC'ye teslim
	edilince inceleme suresi sonunda brainrot'un kimligi ortaya cikar;
	oyuncu Detective'e donup brainrotlarini TESLIM ALIR.

	Acilan brainrot artik base slotuna konabilir ve saniyelik gelir uretir.

	TOPLU INCELEME
	  Oyuncu kimligi belirlenmemis BUTUN brainrotlarini tek seferde birakir.
	  Bekleme suresi hepsinin (Rarity.revealTime) TOPLAMIDIR. Is oyuncu
	  verisine yazilir (PlayerData.detectiveJob): oyuncu yanindan ayrilabilir,
	  oyundan cikip girse bile sure islemeye devam eder. Sure dolunca hepsi
	  birden acilir ama Detective'de bekler. Is surerken yeni teslim alinmaz.

	SECEREK INCELEME
	  Istemci DetectiveTeslim ile uid listesi yollarsa yalnizca o
	  brainrotlar birakilir (tek bir tane de olabilir); liste yoksa hepsi.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Condition = require(Shared:WaitForChild("Condition"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Fonts = require(Shared:WaitForChild("Fonts"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))
--[[
	OGRETICI ISTEGE BAGLI  --  modul yoksa bu sistem yine calisir.

	Sert bir WaitForChild ile baglanirsa ve modul Studio'ya henuz
	senkronize olmadiysa script o satirda SONSUZA KADAR bekler; sistemin
	tamami (GPS'i cantaya koyan kod dahil) hic kurulmaz. Ogretici oyunun
	yan islevi: yoksa oyun kendi bildigini okumali.

	Bes saniye beklenmesinin sebebi Rojo: dosyalar sirayla geliyor, modul
	scriptten birkac kare sonra dusebilir.
]]
local Ogretici = {
	olay = function(_player: Player, _olay: string) end,
	ucKontrol = function(_player: Player) end,
}
do
	local modul = Modules:WaitForChild("Ogretici", 5)
	if modul and modul:IsA("ModuleScript") then
		local ok, sonuc = pcall(require, modul)
		if ok then
			Ogretici = sonuc
		else
			warn(`[Ogretici] modul yuklenemedi: {tostring(sonuc)}`)
		end
	end
end

local Bildirim = Net.event("Bildirim")
local DetectiveAc = Net.event("DetectiveAc")
local DetectiveTeslim = Net.event("DetectiveTeslim")
local DetectiveSonuc = Net.event("DetectiveSonuc")
local DetectiveDurum = Net.event("DetectiveDurum")
-- Sol menudeki Detective takip paneli durumu ister
local DetectiveTakip = Net.event("DetectiveTakip")

local D = Config.Detective
local rng = Random.new()

-- Su an inceleme surecinde olan oyuncular
local busy: { [Player]: boolean } = {}

------------------------------------------------------------------
-- NPC KURULUMU
------------------------------------------------------------------

-- Workspace'te hazir NPC yoksa basit bir inceleme stanti kurar.
local function buildStand(): Model
	local model = Instance.new("Model")
	model.Name = D.name

	local base = Instance.new("Part")
	base.Name = "Masa"
	base.Size = Vector3.new(8, 4, 4)
	base.Position = D.spawnPosition
	base.Anchored = true
	base.Color = Color3.fromRGB(58, 44, 36)
	base.Material = Enum.Material.WoodPlanks
	base.Parent = model
	model.PrimaryPart = base

	local lamp = Instance.new("Part")
	lamp.Name = "Lamba"
	lamp.Size = Vector3.new(1, 1, 1)
	lamp.Position = D.spawnPosition + Vector3.new(0, 3.5, 0)
	lamp.Anchored = true
	lamp.CanCollide = false
	lamp.Shape = Enum.PartType.Ball
	lamp.Color = Color3.fromRGB(255, 236, 180)
	lamp.Material = Enum.Material.Neon
	lamp.Parent = model

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 236, 180)
	light.Range = 20
	light.Brightness = 2
	light.Parent = lamp

	local sign = Instance.new("BillboardGui")
	sign.Name = "Tabela"
	sign.Size = UDim2.new(0, 200, 0, 44)
	sign.StudsOffset = Vector3.new(0, 4, 0)
	sign.AlwaysOnTop = false
	sign.MaxDistance = 90
	sign.Parent = base

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Fonts.bold
	label.Text = "Brainrot Detective"
	label.TextColor3 = Color3.fromRGB(255, 236, 180)
	label.TextSize = 20
	label.TextScaled = false
	label.TextStrokeTransparency = 1
	label.Parent = sign

	model.Parent = Workspace
	return model
end

local function findNPC(): Model?
	local existing = Workspace:FindFirstChild(D.name, true)
	if existing and existing:IsA("Model") then
		return existing
	end
	return nil
end

-- Panel acma asagida tanimli (toplu inceleme bolumu); prompt ondan once kuruluyor
local panelAc: (player: Player) -> ()

local function attachPrompt(model: Model)
	local anchor: BasePart? = model.PrimaryPart
		or model:FindFirstChild("HumanoidRootPart") :: BasePart?
		or model:FindFirstChildWhichIsA("BasePart")

	if not anchor then
		warn("[Detective] NPC'de tutunulacak bir Part bulunamadi")
		return
	end

	local existing = anchor:FindFirstChildOfClass("ProximityPrompt")
	if existing then
		existing:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = D.promptText
	prompt.ObjectText = D.promptSubText
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = D.promptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor

	prompt.Triggered:Connect(function(player)
		panelAc(player)
	end)
end

------------------------------------------------------------------
-- TOPLU INCELEME
------------------------------------------------------------------
--[[
	AKIS

	1. TESLIM   Oyuncu brainrotlarini birakir. Brainrotlar envanterden
	            CIKAR ve isin icinde (detectiveJob.items) durur: hotbar'da
	            ve envanterde gorunmezler.
	2. SURE     Sure dolunca hepsinin kimligi acilir (bitti = true), ama
	            oyuncuya VERILMEZ. Sonuclar sol menudeki Detective
	            butonundan uzaktan gorulebilir.
	3. TESLIM ALMA
	            Oyuncu Detective'e gidip konusunca brainrotlar envantere
	            geri gelir.
]]
--[[
	Sure yazisi. Divine ustu kademeler saatlere ciktigi icin saat de
	yaziliyor: "60:00" yerine "1:00:00".
]]
local function sureYazisi(saniye: number): string
	local t = math.max(0, math.ceil(saniye))
	if t >= 3600 then
		return string.format("%d:%02d:%02d", t // 3600, (t % 3600) // 60, t % 60)
	end
	return string.format("%d:%02d", t // 60, t % 60)
end

-- Kimligi belirlenmemis brainrotlar (sure = kademesinin acilma suresi)
local function bekleyenler(data: any): { any }
	local out = {}
	for _, item in data.inventory do
		if not item.revealed then
			table.insert(out, {
				uid = item.uid,
				rarity = item.rarity,
				condition = item.condition,
				mutation = item.mutation,
				sure = Rarity.get(item.rarity :: any).revealTime,
			})
		end
	end
	return out
end

-- Bitmis isin sonuc satirlari (istemcide kart olarak cizilir)
local function sonucListesi(is: any): { any }
	local out = {}
	for _, item in is.items do
		table.insert(out, {
			uid = item.uid,
			name = item.name,
			rarity = item.rarity,
			condition = item.condition,
			mutation = item.mutation,
			income = if item.name
				then Brainrots.income(item.name, item.condition :: any, item.mutation :: any)
				else 0,
		})
	end
	return out
end

-- Istemciye giden is ozeti; is yoksa nil
local function isOzeti(data: any): any?
	local is = data.detectiveJob
	if not is then
		return nil
	end
	return {
		kalan = if is.bitti then 0 else math.max(0, is.bitis - os.time()),
		toplam = is.toplam,
		adet = #is.items,
		bitti = is.bitti == true,
		sonuclar = if is.bitti then sonucListesi(is) else nil,
	}
end

local function durumYolla(player: Player, data: any)
	DetectiveDurum:FireClient(player, isOzeti(data))
end

-- Bitmis isin brainrotlarini envantere geri verir
local function teslimAl(player: Player, data: any)
	local is = data.detectiveJob
	if not is or not is.bitti then
		return
	end
	data.detectiveJob = nil

	local sonuclar = sonucListesi(is)
	for _, item in is.items do
		table.insert(data.inventory, item)
	end

	Envanter.syncBrainrots(player)
	Envanter.push(player)
	DetectiveSonuc:FireClient(player, sonuclar)
	durumYolla(player, data)

	--[[
		OGRETICI: "collect" adimi esya DEDEKTIFTEN ALININCA biter, kimlik
		acildigi an degil -- oyuncunun bir sonraki adimda onu slota koymasi
		icin esyanin elinde olmasi gerekiyor. ucCollect adimi da burada
		kontrol ediliyor: uc tanesi de acildiysa o adim kapanir.
	]]
	Ogretici.olay(player, "collectledi")
	Ogretici.ucKontrol(player)

	if #sonuclar > 0 then
		-- En degerlisi bildirimde yazar
		local enIyi = sonuclar[1]
		for _, sonuc in sonuclar do
			if sonuc.income > enIyi.income then
				enIyi = sonuc
			end
		end
		local special = Mutations.isSpecial(enIyi.mutation)
		Bildirim:FireClient(
			player,
			`Collected {#sonuclar} brainrot(s) from the Detective! Best: {enIyi.name} ({Format.perSecond(enIyi.income)})`,
			if special then Mutations.color(enIyi.mutation) else Rarity.color(enIyi.rarity)
		)
	end
end

function panelAc(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

--[[
		BITMIS IS KENDILIGINDEN TESLIM EDILMEZ

		Eskiden panel acilir acilmaz brainrotlar cantaya giriyordu; oyuncu
		ne oldugunu anlamadan pencere kapaniyordu. Artik panelde COLLECT
		dugmesi cikiyor ve teslim ona BASINCA oluyor (istemci yine
		DetectiveTeslim yolluyor, asagidaki isleyici teslim ediyor).
	]]
	local is = data.detectiveJob

	local liste = bekleyenler(data)
	local ozet = isOzeti(data)
	if #liste == 0 and not ozet then
		Bildirim:FireClient(player, "You have no unidentified brainrots.", Color3.fromRGB(255, 200, 90))
		return
	end

	DetectiveAc:FireClient(player, { pending = liste, job = ozet })
end

-- Sure doldu: isteki butun brainrotlarin kimligi acilir (oyuncuya henuz verilmez)
local function isiBitir(player: Player, data: any)
	local is = data.detectiveJob
	if not is or is.bitti then
		return
	end

	for _, item in is.items do
		if item.revealed then
			continue
		end
		--[[
			Rarity sabit kalir; hangi brainrot oldugu simdi belli olur. Isim
			KAZILDIGI ADANIN listesinden seciliyor.
		]]
		local picked = Brainrots.rollIsland(item.rarity :: any, item.island, rng)
		item.name = picked.name
		item.revealed = true
	end

	is.bitti = true
	durumYolla(player, data)

	Bildirim:FireClient(
		player,
		`The Detective identified {#is.items} brainrot(s)! Go to the Detective to collect them.`,
		Color3.fromRGB(255, 236, 180)
	)
end

------------------------------------------------------------------
-- SUREYI ATLAMA  (Robux)
--
-- Odeme RobuxMagaza'da isleniyor (ProcessReceipt oyunda TEK yerde
-- olabiliyor). Oraya iki kapi aciliyor:
--
--   DedektifBekliyorMu  -- satin alma penceresi acilmadan once sorulur;
--                          bekleyen is yoksa pencere hic acilmaz, yani
--                          oyuncu bos yere odemez
--   DedektifAtla        -- odeme alininca cagrilir, sureyi siler
--
-- BindableFunction cunku ikisinin de CEVABI onemli.
------------------------------------------------------------------
local BekliyorMu = Instance.new("BindableFunction")
BekliyorMu.Name = "DedektifBekliyorMu"
BekliyorMu.Parent = script

BekliyorMu.OnInvoke = function(player: Player): boolean
	local data = PlayerData.get(player)
	local is = data and data.detectiveJob
	return is ~= nil and not is.bitti
end

local Atla = Instance.new("BindableFunction")
Atla.Name = "DedektifAtla"
Atla.Parent = script

Atla.OnInvoke = function(player: Player): boolean
	local data = PlayerData.get(player)
	local is = data and data.detectiveJob
	if not is or is.bitti then
		return false
	end

	-- Sure bitmis sayiliyor; is normal yolundan tamamlaniyor
	is.bitis = os.time()
	isiBitir(player, data)
	return true
end

DetectiveTeslim.OnServerEvent:Connect(function(player, secilen)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	--[[
		YALNIZCA TESLIM AL  --  panelin COLLECT dugmesi

		Istemci "collect" yollarsa bitmis is cantaya verilir ve DURULUR:
		bekleyen brainrotlar bu tiklamayla yeniden ise girmez, oyuncu
		istedigini secip IDENTIFY der.
	]]
	if secilen == "collect" then
		local bitmis = isOzeti(data)
		if bitmis and bitmis.bitti then
			teslimAl(player, data)
		end
		panelAc(player)
		return
	end

	local mevcut = isOzeti(data)
	if mevcut then
		if mevcut.bitti then
			teslimAl(player, data)
		else
			Bildirim:FireClient(
				player,
				`The Detective is still working ({sureYazisi(mevcut.kalan)} left).`,
				Color3.fromRGB(255, 200, 90)
			)
			durumYolla(player, data)
			return
		end
	end

	local liste = bekleyenler(data)

	-- Secim geldiyse yalnizca secilenler (istemciye guvenilmez: listede olmayan uid atlanir)
	if type(secilen) == "table" then
		local istenen: { [string]: boolean } = {}
		local sayi = 0
		for _, uid in secilen do
			if type(uid) == "string" and sayi < 500 then
				istenen[uid] = true
				sayi += 1
			end
		end

		local suzulen = {}
		for _, item in liste do
			if istenen[item.uid] then
				table.insert(suzulen, item)
			end
		end
		liste = suzulen
	end

	if #liste == 0 then
		Bildirim:FireClient(player, "You have no unidentified brainrots.", Color3.fromRGB(255, 200, 90))
		return
	end

	-- Brainrotlar envanterden cikip isin icine girer
	local toplam = 0
	local items = {}
	for _, bilgi in liste do
		local item = PlayerData.removeItem(player, bilgi.uid)
		if item then
			toplam += bilgi.sure
			table.insert(items, item)
		end
	end
	if #items == 0 then
		return
	end
	toplam = math.max(1, math.ceil(toplam))

	data.detectiveJob = { bitis = os.time() + toplam, toplam = toplam, items = items, bitti = false }
	Envanter.syncBrainrots(player)
	Envanter.push(player)
	durumYolla(player, data)
	Bildirim:FireClient(
		player,
		`Detective is identifying {#items} brainrot(s) ({sureYazisi(toplam)}). You can leave!`,
		Color3.fromRGB(255, 236, 180)
	)
end)

-- Suresi dolan isler (oyuncu nerede olursa olsun)
task.spawn(function()
	while true do
		task.wait(1)
		local simdi = os.time()
		for _, player in Players:GetPlayers() do
			local data = PlayerData.get(player)
			local is = data and data.detectiveJob
			if is and not is.bitti and simdi >= is.bitis then
				local ok, hata = pcall(isiBitir, player, data)
				if not ok then
					warn(`[Detective] {player.Name} isi bitirilemedi: {tostring(hata)}`)
				end
			end
		end
	end
end)

-- Oyuna donen oyuncu isini gorsun (sol menudeki Detective butonu)
local function girisDurumu(player: Player)
	task.spawn(function()
		for _ = 1, 3 do
			task.wait(2)
			local data = player.Parent and PlayerData.get(player)
			if data then
				durumYolla(player, data)
			end
		end
	end)
end

Players.PlayerAdded:Connect(girisDurumu)
for _, player in Players:GetPlayers() do
	girisDurumu(player)
end

-- Sol menudeki takip paneli acilinca guncel durumu ister
DetectiveTakip.OnServerEvent:Connect(function(player)
	local data = PlayerData.get(player)
	if data then
		durumYolla(player, data)
	end
end)

------------------------------------------------------------------
-- BASLAT
------------------------------------------------------------------
task.spawn(function()
	local npc = findNPC()
	if not npc then
		npc = buildStand()
	end
	attachPrompt(npc)
end)
