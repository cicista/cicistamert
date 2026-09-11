--[[
	Fuse  (Script)
	Yeri: ServerScriptService > Fuse

	ILK ADADAKI IKI NPC.

	1. FUSE MAKINESI  (Config.Fuse.machineName)
	   Ayni kademeden 5 esya alir, BIR UST kademede bir coin verir.

	   Esyayi ELINE ALIP makinede E'ye BASILI TUT: esya envanterden cikar,
	   makinenin icinde birikir. Makinede farkli kademeden esya bulunamaz.
	   Coin de konabilir -- kendi kademesi ve boyutuyla islenir, yani
	   5 Epic coin -> 1 Legendary coin.

	   Cikan coinin BOYUTU ve MUTASYONU iceri konanlardan cekilir:
	   3 Tiny + 1 Large + 1 Huge -> %60 Tiny, %20 Large, %20 Huge.
	   2 Gold + 1 Diamond       -> %20 Gold, %10 Diamond, %70 mutasyonsuz.

	   Makineye Fuse.Timeout saniye boyunca yeni esya konmazsa icindekiler
	   sahibine geri verilir -- kimse esyasini makinede unutup kaybetmesin.

	2. COIN BOZDURUCU  (Config.Fuse.openerName)
	   Coini alir, coinin kademesinden rastgele bir brainrot verir. Cikan
	   brainrot'un boyutu COININ BOYUTUDUR; yani Huge coin her zaman Huge
	   brainrot verir. Cark yalnizca gosterim, sonuc once belirlenir.

	ARAYUZ
	  Makinenin paneli yaklasinca kendiliginden gorunur (prompt beklemez):
	  oyuncu ne yapmasi gerektigini -- "Same Rarity Brainrot 0/5" -- ve
	  koydukca degisen kademe/boyut sanslarini oradan okur.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Assets = require(Shared:WaitForChild("Assets"))
local Condition = require(Shared:WaitForChild("Condition"))
local Fonts = require(Shared:WaitForChild("Fonts"))
local Format = require(Shared:WaitForChild("Format"))
local Fuse = require(Shared:WaitForChild("Fuse"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))
local GorevTakip = require(Modules:WaitForChild("GorevTakip"))
local Patlama = require(Modules:WaitForChild("Patlama"))

local Bildirim = Net.event("Bildirim")
local FuseDurum = Net.event("FuseDurum")
local FuseGeriAl = Net.event("FuseGeriAl")
local FuseSecim = Net.event("FuseSecim")
local FuseEkle = Net.event("FuseEkle")
local FuseSonuc = Net.event("FuseSonuc")
local CoinAc = Net.event("CoinAc")
local CoinBozdur = Net.event("CoinBozdur")
local CoinSonuc = Net.event("CoinSonuc")

local F = Config.Fuse
local rng = Random.new()

--[[
	Makinenin icindekiler -- oyuncu basina ayri.

	entries: { { kind = "brainrot" | "coin", item = <veri kopyasi> } }
	Esyalar PlayerData'dan CIKARILIP buraya alinir; iade edilince geri konur.
	Boylece "hem envanterde hem makinede" gibi bir ara durum olusmaz.
]]
type Pending = {
	rarity: string,
	-- { kind, condition, item } -- condition disariya duzlestirilmis hali
	entries: { any },
	lastAt: number,
}

local pending: { [Player]: Pending } = {}

-- Bozdurma carki donerken ikinci bir coin acilmasin
local opening: { [Player]: boolean } = {}

------------------------------------------------------------------
-- NPC KURULUMU
------------------------------------------------------------------

--[[
	Haritada model yoksa o noktaya basit bir tezgah kurar.
	Diger NPC'lerdeki (Detective, Satici, SlotMakinesi) mantigin aynisi:
	oyun model olmadan da calisir, model eklenince kod degismez.
]]
local function buildStand(name: string, position: Vector3, label: string, color: Color3): Model
	local model = Instance.new("Model")
	model.Name = name

	local body = Instance.new("Part")
	body.Name = "Govde"
	body.Size = Vector3.new(7, 7, 5)
	body.Position = position
	body.Anchored = true
	body.Color = Color3.fromRGB(52, 58, 72)
	body.Material = Enum.Material.Metal
	body.Parent = model
	model.PrimaryPart = body

	local panel = Instance.new("Part")
	panel.Name = "Ekran"
	panel.Size = Vector3.new(5, 2.2, 0.3)
	panel.Position = position + Vector3.new(0, 2, -2.5)
	panel.Anchored = true
	panel.CanCollide = false
	panel.Color = color
	panel.Material = Enum.Material.Neon
	panel.Parent = model

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 18
	light.Brightness = 2
	light.Parent = panel

	local sign = Instance.new("BillboardGui")
	sign.Name = "Tabela"
	sign.Size = UDim2.fromOffset(230, 44)
	sign.StudsOffset = Vector3.new(0, 5, 0)
	sign.AlwaysOnTop = false
	sign.MaxDistance = 120
	sign.Parent = body

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = label
	text.TextColor3 = color
	text.TextSize = 22
	text.TextScaled = false
	Fonts.apply(text)
	text.Parent = sign

	model.Parent = Workspace
	return model
end

-- Adiyla (ya da yedek adiyla) haritada arar
--[[
	NPC ARAMA

	Modeller MAIN ISLAND gibi baska bir modelin icinde durabiliyor, o yuzden
	butun Workspace taranir. Ad karsilastirmasi BUYUK/KUCUK HARF ve bosluk
	gozetmez: "FuseMachine", "Fuse Machine" ve "FUSEMACHINE" ayni sayilir.

	Bulunamazsa yedek tezgah kurulur; Output'taki uyaridan anlasilir.
]]
local function adEsit(a: string, b: string): boolean
	return string.lower(string.gsub(a, "%s", "")) == string.lower(string.gsub(b, "%s", ""))
end

local function findNPC(name: string, altName: string?): Model?
	for _, candidate in { name, altName } do
		if not candidate then
			continue
		end

		for _, node in Workspace:GetDescendants() do
			if node:IsA("Model") and adEsit(node.Name, candidate) then
				return node
			end
		end
	end

	return nil
end

--[[
	Modelin tutunma parcasi. Parcalar alt modellerin icinde olabilir, bu
	yuzden arama DERIN: yalnizca dogrudan cocuklara bakan surum bazi
	NPC'lerde bos donuyordu.
]]
local function anchorOf(model: Model): BasePart?
	local primary = model.PrimaryPart
	if primary then
		return primary
	end

	local root = model:FindFirstChild("HumanoidRootPart", true)
	if root and root:IsA("BasePart") then
		return root
	end

	return model:FindFirstChildWhichIsA("BasePart", true)
end

local bulunanMakine = findNPC(F.machineName, F.machineAltName)
local bulunanBozdurucu = findNPC(F.openerName, F.openerAltName)

local machine: Model = bulunanMakine
	or buildStand(F.machineName, F.machineSpawnPosition, "FUSE MACHINE", Color3.fromRGB(120, 200, 255))

local opener: Model = bulunanBozdurucu
	or buildStand(F.openerName, F.openerSpawnPosition, "COIN TRADER", Color3.fromRGB(255, 200, 90))

-- Hangisinin haritadan geldigi, hangisinin yedek oldugu Output'tan gorulsun
if not bulunanMakine then
	warn(`[Fuse] "{F.machineName}" / "{F.machineAltName}" bulunamadi -- yedek tezgah kuruldu`)
end
if not bulunanBozdurucu then
	warn(`[Fuse] "{F.openerName}" / "{F.openerAltName}" bulunamadi -- yedek tezgah kuruldu`)
end

------------------------------------------------------------------
-- DURUM YAYINI
------------------------------------------------------------------

local function machinePosition(): Vector3?
	if not machine or not machine.Parent then
		return nil
	end
	local anchor = anchorOf(machine)
	return if anchor then anchor.Position else nil
end

local function inMachineRange(player: Player): boolean
	local position = machinePosition()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if not position or not root or not root:IsA("BasePart") then
		return false
	end

	return (root.Position - position).Magnitude <= F.machineRange
end

--[[
	Makine panelini tazeler.

	Makine bosken bile gonderilir: oyuncu yaklasinca ne yapmasi gerektigini
	("Same Rarity Brainrot 0/5") gormeli.
]]
--[[
	MAKINEYE KONABILECEK ESYALAR

	Oyuncu artik esyayi elinde tutmuyor, makine penceresinden seciyor.
	Listeye giren: base slotunda OLMAYAN brainrotlar ve butun coinler --
	yalnizca ust kademesi olanlar (en ust kademe birlestirilemez).

	Makinede zaten bir kademe varsa yalnizca O kademe listelenir; oyuncu
	kabul edilmeyecek bir esyaya tiklamak zorunda kalmasin.
]]
local function eligibleItems(player: Player): { any }
	local data = PlayerData.get(player)
	if not data then
		return {}
	end

	local slot = pending[player]
	local istenen = if slot then slot.rarity else nil

	local out = {}

	for _, item in data.inventory do
		if item.slot or not Fuse.nextRarity(item.rarity) then
			continue
		end
		if istenen and item.rarity ~= istenen then
			continue
		end

		table.insert(out, {
			uid = item.uid,
			kind = "brainrot",
			rarity = item.rarity,
			condition = item.condition,
			mutation = item.mutation,
			name = if item.revealed and item.name then item.name else nil,
		})
	end

	for _, coin in data.coins do
		if not Fuse.nextRarity(coin.rarity) then
			continue
		end
		if istenen and coin.rarity ~= istenen then
			continue
		end

		table.insert(out, {
			uid = coin.uid,
			kind = "coin",
			rarity = coin.rarity,
			condition = coin.condition,
			mutation = coin.mutation,
			name = Fuse.coinName(coin.rarity, coin.condition, coin.mutation),
		})
	end

	return out
end

local function pushStatus(player: Player)
	local slot = pending[player]
	local entries = if slot then slot.entries else {}
	local rarityId = if slot then slot.rarity else nil

	FuseDurum:FireClient(player, {
		near = true,
		rarity = rarityId,
		count = #entries,
		required = Fuse.Required,
		nextRarity = if rarityId then Fuse.nextRarity(rarityId) else nil,
		sizes = Fuse.sizeChances(entries),
		mutations = Fuse.mutationChances(entries),
		-- Iadeye kalan sure (makine bosken anlamsiz)
		timeout = if slot then math.max(0, Fuse.Timeout - (os.clock() - slot.lastAt)) else 0,
		-- Makine penceresinde listelenecek esyalar
		items = eligibleItems(player),
	})
end

local function closeStatus(player: Player)
	FuseDurum:FireClient(player, { near = false })
end

------------------------------------------------------------------
-- IADE
------------------------------------------------------------------

--[[
	Makinedeki esyalari sahibine geri verir.

	Esyalar veriden cikarilmis oldugu icin buraya dokunmadan birakilirsa
	gercekten kaybolurlar; her cikis yolu (zaman asimi, oyuncunun ayrilmasi,
	elle geri alma) bu fonksiyondan gecer.
]]
local function returnItems(player: Player, reason: string?)
	local slot = pending[player]
	if not slot then
		return
	end
	pending[player] = nil

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local count = #slot.entries
	for _, entry in slot.entries do
		if entry.kind == "coin" then
			table.insert(data.coins, entry.item)
		else
			table.insert(data.inventory, entry.item)
		end
	end

	Envanter.syncBrainrots(player)
	Envanter.syncCoins(player)
	Envanter.push(player)

	if count > 0 and reason then
		Bildirim:FireClient(player, `{count} item(s) returned from the machine ({reason})`, Color3.fromRGB(255, 200, 90))
	end
end

------------------------------------------------------------------
-- PATLAMA EFEKTI
------------------------------------------------------------------

--[[
	Birlesme patlamasini BIRLESTIREN OYUNCUNUN UZERINDE oynatir.

	Efektin rengi CIKAN COININ kademesine cevrilir: 5 mavi brainrot birlesip
	sari bir coin verdiyse patlama da sari olur. Renklendirme parcaciklarin
	kendi parlaklik yapisini korur (bkz. Assets.tintEffects). Ust kademelerde
	patlamanin capi da buyur (Fuse.VFX.scaleByRarity).

	Efekt karakterin govdesine KAYNAKLANIR, sabit bir noktaya konmaz: oyuncu
	patlama sirasinda yururse efekt uzerinde kalir. Sunucu urettigi icin
	haritadaki herkes gorur, yalnizca birlestiren degil.
]]
-- Oyuncunun govdesi: sesler ve efekt buraya baglanir
local function bodyOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

--[[
	Fuse sesini oyuncunun uzerinde calar.
	3B oldugu icin yakindaki herkes duyar, kaynagi da dogru yerde olur.
]]
local function playFuseSound(player: Player, names: { string }): Sound?
	local body = bodyOf(player)
	if not body then
		return nil
	end
	return Assets.playSoundAt(names, body)
end

--[[
	Patlama Modules > Patlama icinde: gorev odulu (Quests > Collect) da tam
	ayni efekti kullaniyor, kod iki yerde durmasin.
]]
local function playBurstVFX(player: Player, rarityId: string)
	Patlama.oynat(player, rarityId)
end

------------------------------------------------------------------
-- BIRLESTIRME
------------------------------------------------------------------

--[[
	5'e ulasildiginda: icerideki esyalar yok olur, bir ust kademede
	coin uretilir. Coinin boyutu iceridekilerden cekilir.
]]
local function completeFuse(player: Player)
	local slot = pending[player]
	if not slot then
		return
	end

	local nextRarity = Fuse.nextRarity(slot.rarity)
	if not nextRarity then
		-- Buraya gelinmemeli (koyarken engelleniyor) ama esya kaybolmasin
		returnItems(player, "bu kademenin ustu yok")
		return
	end

	--[[
		Boyut ve mutasyon iceridekilerden cekilir; ikisi de panelde yazan
		oranin aynisi (arayuz de cekilis de Shared > Fuse'daki ayni
		fonksiyonlari kullaniyor).
	]]
	local condition = Fuse.rollSize(slot.entries, rng)
	local mutation = Fuse.rollMutation(slot.entries, rng)

	--[[
		Coin ONCE uretilir, makine ANCAK ondan sonra bosaltilir.
		Ters sirada olsaydi ve coin uretilemeseydi (veri yuklenmemis olsa
		mesela) icerideki 5 esya hicbir sey vermeden yok olurdu.
	]]
	local coin = PlayerData.addCoin(player, nextRarity, condition, mutation)
	if not coin then
		return
	end

	-- Gorev panosu: makinede coin uretildi
	GorevTakip.ilerlet(player, "fuse", 1, nextRarity)

	-- Gosteride kac ruh donecek: iceri konan esya sayisi
	local fromRarity = slot.rarity
	local souls = #slot.entries

	pending[player] = nil
	pushStatus(player)

	FuseSonuc:FireClient(player, {
		fromRarity = fromRarity,
		toRarity = nextRarity,
		condition = condition,
		mutation = mutation,
		coinName = Fuse.coinName(nextRarity, condition, mutation),
		souls = souls,
	})

	-- Ruhlar toplanmaya baslarken yukleniyor sesi
	local charge = playFuseSound(player, Fuse.VFX.charge)

	--[[
		Oyuncunun uzerindeki patlama efekti, gosterinin PATLAMA anina
		kilitlenir: ruhlar merkeze kapanip beyaz parlamada birlestigi an.
		Sure Fuse.burstDelay()'den geliyor, istemcideki gosteri de ayni
		degeri okuyor -- ekran sarsintisi ile efekt ayni karede oluyor.
	]]
	task.delay(Fuse.burstDelay(), function()
		--[[
			Yukleniyor sesi patlamayla birlikte kesilir. Uzun bir ses
			kullanilirsa patlamadan sonra kuyruk birakip gerilimi
			bozuyordu; burada bitmesi gerekiyor.
		]]
		if charge and charge.Parent then
			charge:Stop()
			charge:Destroy()
		end

		playBurstVFX(player, nextRarity)
	end)

	--[[
		Coin VERIYE yukarida hemen yazildi -- gosteri oynarken oyuncu
		cikarsa kaybolmasin. Ama CANTAYA ve envanter ekranina gosteri
		bitince yansitiliyor: yoksa coin daha ruhlar birlesmeden envanterde
		beliriyor ve surpriz kaliyor.
	]]
	task.delay(Fuse.mergeTime(), function()
		if not player.Parent then
			return
		end

		Envanter.syncCoins(player)
		Envanter.push(player)

		Bildirim:FireClient(
			player,
			`{Fuse.coinName(nextRarity, condition, mutation)} created! Take it to the Coin Trader.`,
			Rarity.color(nextRarity)
		)
	end)
end

--[[
	Elde tutulan esyayi makineye koyar.

	Kabul edilenler: brainrot (acilmis ya da acilmamis) ve coin. Ikisinde de
	kademe ve boyut bellidir, makinenin ihtiyaci olan tek sey bu.
]]
local function insertItem(player: Player, uid: string)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	--[[
		UID ILE GELIR, ELDE TUTMA YOK.

		Oyuncu makine penceresinde envanterindeki esyayi seciyor. Ayni uid
		hem coin hem brainrot olamaz; once coinlere, sonra brainrotlara
		bakiliyor.
	]]
	local heldCoinUid: string? = if PlayerData.findCoin(player, uid) then uid else nil
	local heldBrainrotUid: string? = if not heldCoinUid and PlayerData.findItem(player, uid) then uid else nil

	if not heldCoinUid and not heldBrainrotUid then
		Bildirim:FireClient(player, "That item is no longer in your inventory.", Color3.fromRGB(255, 200, 90))
		return
	end

	------------------------------------------------------------------
	-- Esyayi coz: kademe, boyut ve veri kaydi
	------------------------------------------------------------------
	local kind: string
	local record: any

	if heldCoinUid then
		kind = "coin"
		record = PlayerData.findCoin(player, heldCoinUid)
	else
		kind = "brainrot"
		record = PlayerData.findItem(player, heldBrainrotUid :: string)
	end

	if not record then
		return
	end

	if kind == "brainrot" and record.slot then
		Bildirim:FireClient(player, "A brainrot on your base cannot be fused.", Color3.fromRGB(255, 200, 90))
		return
	end

	------------------------------------------------------------------
	-- Kurallar
	------------------------------------------------------------------
	if not Fuse.nextRarity(record.rarity) then
		Bildirim:FireClient(
			player,
			`{Rarity.displayName(record.rarity)} cannot be fused, it is the top tier.`,
			Color3.fromRGB(255, 120, 120)
		)
		return
	end

	local slot = pending[player]

	if slot and slot.rarity ~= record.rarity then
		Bildirim:FireClient(
			player,
			`The machine holds {Rarity.displayName(slot.rarity)}, add the same tier.`,
			Color3.fromRGB(255, 120, 120)
		)
		return
	end

	------------------------------------------------------------------
	-- Esyayi veriden al, makineye koy
	------------------------------------------------------------------
	local taken = if kind == "coin"
		then PlayerData.removeCoin(player, heldCoinUid :: string)
		else PlayerData.removeItem(player, heldBrainrotUid :: string)

	if not taken then
		return
	end

	if not slot then
		slot = { rarity = record.rarity, entries = {}, lastAt = os.clock() }
		pending[player] = slot
	end

	--[[
		condition esyanin ICINDEN cikarilip girdinin uzerine yaziliyor.
		Fuse.sizeChances ve Fuse.rollSize girdinin dogrudan .condition
		alanini okuyor; ic ice item.condition'a bakmak zorunda kalmasinlar
		diye burada duzlestiriliyor.
	]]
	local active = slot :: Pending
	table.insert(active.entries, {
		kind = kind,
		condition = taken.condition,
		mutation = taken.mutation,
		item = taken,
	})
	active.lastAt = os.clock()

	Envanter.syncBrainrots(player)
	Envanter.syncCoins(player)
	Envanter.push(player)

	if #active.entries >= Fuse.Required then
		completeFuse(player)
	else
		pushStatus(player)
	end
end

------------------------------------------------------------------
-- COIN BOZDURMA
------------------------------------------------------------------

--[[
	Carkin bolmeleri: hepsi coinin kademesinden, biri gercek odul.
	Kademe zaten belli oldugu icin tek asamali doner (bkz. Rulet).
]]
local function buildCells(rarityId: string, winnerIndex: number, winnerName: string): { { name: string, rarity: string } }
	local cells = {}

	for index = 1, Fuse.Wheel.cellCount do
		if index == winnerIndex then
			table.insert(cells, { name = winnerName, rarity = rarityId })
		else
			table.insert(cells, { name = Brainrots.roll(rarityId :: any, rng).name, rarity = rarityId })
		end
	end

	return cells
end

local function openCoin(player: Player, uid: string)
	if opening[player] then
		return
	end

	local coin = PlayerData.findCoin(player, uid)
	if not coin then
		return
	end

	opening[player] = true

	--[[
		Odul burada belirlenir; cark yalnizca gosterim.

		BOYUT ve MUTASYON coinden AYNEN gecer -- yeniden cekilmez. Huge bir
		coin her zaman Huge, Gold bir coin her zaman Gold brainrot verir.
		Cekilis zaten makinede yapildi; burada tekrar cekmek oyuncunun
		makinede gordugu orani anlamsiz kilardi.
	]]
	local info = Brainrots.roll(coin.rarity :: any, rng)
	local condition = Condition.get(coin.condition).id
	local mutation = Mutations.get(coin.mutation).id

	PlayerData.removeCoin(player, uid)
	Envanter.syncCoins(player)

	local item = PlayerData.addBrainrot(player, coin.rarity, condition, mutation)
	if not item then
		opening[player] = nil
		return
	end

	-- Coinden cikan brainrot da kademe gorevlerine sayilir
	GorevTakip.ilerlet(player, "collect", 1, coin.rarity)

	-- Coinden cikan brainrot ACIK gelir: Detective'e gitmeye gerek yok
	item.name = info.name
	item.revealed = true

	local income = Brainrots.income(info.name, condition :: any, mutation :: any)

	CoinSonuc:FireClient(player, {
		cells = buildCells(coin.rarity, Fuse.Wheel.winnerIndex, info.name),
		winnerIndex = Fuse.Wheel.winnerIndex,
		spinTime = Fuse.Wheel.spinTime,
		coinName = Fuse.coinName(coin.rarity, coin.condition, coin.mutation),
		winner = {
			name = info.name,
			rarity = coin.rarity,
			condition = condition,
			mutation = mutation,
			income = income,
		},
	})

	-- Cark durunca odul cantaya girer ve bildirim cikar
	task.delay(Fuse.totalSpinTime(), function()
		opening[player] = nil
		if not player.Parent then
			return
		end

		Envanter.syncBrainrots(player)
		Envanter.push(player)

		Bildirim:FireClient(
			player,
			`{info.name} {Condition.get(condition).shortName} ({Format.perSecond(income)})`,
			Rarity.color(coin.rarity)
		)
	end)
end

-- Bozdurucunun ekranina gonderilen coin listesi
local function pushCoins(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	local list = {}
	for _, coin in data.coins do
		table.insert(list, {
			uid = coin.uid,
			rarity = coin.rarity,
			condition = coin.condition,
			mutation = coin.mutation,
		})
	end

	CoinAc:FireClient(player, list)
end

------------------------------------------------------------------
-- PROMPTLAR
------------------------------------------------------------------
local function attachMachinePrompt()
	local anchor = anchorOf(machine)
	if not anchor then
		warn("[Fuse] Makinede tutunulacak bir Part bulunamadi")
		return
	end

	local existing = anchor:FindFirstChild("FusePrompt")
	if existing then
		existing:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "FusePrompt"
	prompt.ActionText = F.machinePromptText
	prompt.ObjectText = F.machinePromptSubText
	prompt.HoldDuration = F.machineHoldDuration
	prompt.MaxActivationDistance = F.machinePromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = anchor

	--[[
		Prompt artik esya KOYMUYOR, PENCEREYI ACIYOR.
		Oyuncu envanterinden hangisini koyacagini orada seciyor.
	]]
	prompt.Triggered:Connect(function(player: Player)
		pushStatus(player)
		FuseSecim:FireClient(player)
	end)

	print(`[Fuse] Makine promptu kuruldu: {anchor:GetFullName()}`)
end

local function attachOpenerPrompt()
	local anchor = anchorOf(opener)
	if not anchor then
		warn("[Fuse] Bozdurucuda tutunulacak bir Part bulunamadi")
		return
	end

	local existing = anchor:FindFirstChild("CoinPrompt")
	if existing then
		existing:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CoinPrompt"
	prompt.ActionText = F.openerPromptText
	prompt.ObjectText = F.openerPromptSubText
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = F.openerPromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor

	prompt.Triggered:Connect(pushCoins)

	print(`[Fuse] Bozdurucu promptu kuruldu: {anchor:GetFullName()}`)
end

task.spawn(attachMachinePrompt)
task.spawn(attachOpenerPrompt)

------------------------------------------------------------------
-- REMOTE BAGLANTILARI
------------------------------------------------------------------
FuseEkle.OnServerEvent:Connect(function(player, uid)
	if type(uid) ~= "string" then
		return
	end
	insertItem(player, uid)
end)

FuseGeriAl.OnServerEvent:Connect(function(player)
	returnItems(player, "geri aldin")
	pushStatus(player)
end)

CoinBozdur.OnServerEvent:Connect(function(player, uid)
	if type(uid) ~= "string" then
		return
	end
	openCoin(player, uid)
end)

------------------------------------------------------------------
-- DONGULER
------------------------------------------------------------------

--[[
	Makine paneli ve zaman asimi.

	Panel PROMPT BEKLEMEDEN gorunur: oyuncu makineye yaklasinca ne yapmasi
	gerektigini okumali. Menzilden cikanin paneli kapanir.
]]
local nearby: { [Player]: boolean } = {}

task.spawn(function()
	while true do
		task.wait(0.4)

		for _, player in Players:GetPlayers() do
			local near = inMachineRange(player)

			if near then
				nearby[player] = true
				pushStatus(player)
			elseif nearby[player] then
				nearby[player] = nil
				closeStatus(player)
			end
		end
	end
end)

-- Zaman asimi: unutulan esyalar sahibine doner
task.spawn(function()
	while true do
		task.wait(1)

		local now = os.clock()
		for player, slot in pending do
			if not player.Parent then
				pending[player] = nil
				continue
			end

			if now - slot.lastAt >= Fuse.Timeout then
				returnItems(player, `{Fuse.Timeout} saniye yeni esya konmadi`)
				if nearby[player] then
					pushStatus(player)
				end
			end
		end
	end
end)

--[[
	Oyuncu ayrilirken makinedeki esyalar verisine GERI YAZILIR.

	Bunu PlayerRemoving'e baglamiyoruz: PlayerData da ayni sinyale bagli ve
	Roblox baglanti sirasini garanti etmiyor -- once o calisirsa cache
	silinir, makinedeki esyalar kaydedilmeden yok olurdu. PlayerData'nin
	ayrilma oncesi kancasi ise cache HALA DOLUYKEN calisiyor, yani iade her
	zaman kayda giriyor.
]]
PlayerData.onBeforeRelease(function(player: Player)
	returnItems(player, nil)
end)

Players.PlayerRemoving:Connect(function(player)
	pending[player] = nil
	opening[player] = nil
	nearby[player] = nil
end)
