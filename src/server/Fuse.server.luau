--[[
	Fuse  (Script)
	Yeri: ServerScriptService > Fuse

	ILK ADADAKI FUSE MAKINESI  (Config.Fuse.machineName)

	   3 AYNI brainrot (ayni isim) konur, oyuncu FUSE'a basar:
	     %Fuse.SuccessChance  -> bir ust kademeden acilmis brainrot
	     kalani               -> hicbir sey, konan 3 brainrot gider

	   Kurallar ve oranlar Shared > Fuse'ta. Hepsi SUNUCUDA dogrulanir:
	   istemci yalnizca "su uid'yi koy / su uid'yi geri al / baslat" der.

	   Konan brainrotlar envanterden CIKAR, makinede bekler. Oyuncu
	   Fuse.Timeout saniye islem yapmazsa, oyundan cikarsa ya da "Return"a
	   basarsa geri verilir -- hicbir yolda kaybolmaz.

	ARAYUZ (bkz. StarterPlayerScripts > Fuse)
	  Makinede E'ye basinca pencere acilir: 3 slot, "+" ile brainrot secimi,
	  slotlarda Return, altta FUSE dugmesi.

	(Coin sistemi ve Coin Trader oyundan kaldirildi.)
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
local Seviye = require(Modules:WaitForChild("Seviye"))
local Patlama = require(Modules:WaitForChild("Patlama"))

local Bildirim = Net.event("Bildirim")
local FuseDurum = Net.event("FuseDurum")
local FuseGeriAl = Net.event("FuseGeriAl")
local FuseSecim = Net.event("FuseSecim")
local FuseEkle = Net.event("FuseEkle")
local FuseCikar = Net.event("FuseCikar")
local FuseBaslat = Net.event("FuseBaslat")
local FuseSonuc = Net.event("FuseSonuc")

local F = Config.Fuse
local rng = Random.new()

local UYARI = Color3.fromRGB(255, 200, 90)
local RED = Color3.fromRGB(255, 120, 120)

--[[
	Makinenin icindekiler -- oyuncu basina ayri.

	name    : makinedeki brainrotlarin ortak adi (ilk konan belirler)
	rarity  : o brainrotun kademesi
	entries : { { condition, mutation, item } } -- item veriden cikarilmis kayit
]]
type Pending = {
	name: string,
	rarity: string,
	entries: { any },
	lastAt: number,
}

local pending: { [Player]: Pending } = {}

-- Birlestirme gosterisi suruyor: bu sirada yeni esya konmasin / baslatilmasin
local fusing: { [Player]: boolean } = {}

------------------------------------------------------------------
-- NPC KURULUMU
------------------------------------------------------------------

-- Haritada model yoksa o noktaya basit bir tezgah kurar
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

	local sign = Instance.new("BillboardGui")
	sign.Name = "Tabela"
	sign.Size = UDim2.fromOffset(230, 44)
	sign.StudsOffset = Vector3.new(0, 5, 0)
	sign.MaxDistance = 120
	sign.Parent = body

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = label
	text.TextColor3 = color
	text.TextSize = 22
	Fonts.apply(text)
	text.Parent = sign

	model.Parent = Workspace
	return model
end

--[[
	NPC ARAMA: butun Workspace taranir, ad karsilastirmasi buyuk/kucuk harf
	ve bosluk gozetmez ("FuseMachine" = "Fuse Machine").
]]
local function adEsit(a: string, b: string): boolean
	return string.lower((string.gsub(a, "%s", ""))) == string.lower((string.gsub(b, "%s", "")))
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

-- Modelin tutunma parcasi (derin arama: parcalar alt modellerde olabilir)
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

local machine: Model = bulunanMakine
	or buildStand(F.machineName, F.machineSpawnPosition, "FUSE MACHINE", Color3.fromRGB(120, 200, 255))

if not bulunanMakine then
	warn(`[Fuse] "{F.machineName}" / "{F.machineAltName}" bulunamadi -- yedek tezgah kuruldu`)
end

------------------------------------------------------------------
-- DURUM YAYINI
------------------------------------------------------------------

local function inMachineRange(player: Player): boolean
	local anchor = if machine and machine.Parent then anchorOf(machine) else nil
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if not anchor or not root or not root:IsA("BasePart") then
		return false
	end

	return (root.Position - anchor.Position).Magnitude <= F.machineRange
end

--[[
	Bir brainrot makineye KONABILIR MI? Konamazsa sebebi doner.
	Hem liste (eligibleItems) hem koyma (insertItem) ayni kurali kullanir;
	listede gorunen her sey gercekten konabilir.
]]
local function uygunsuzluk(player: Player, item: any): string?
	if item.slot then
		return "A brainrot on your base cannot be fused."
	end
	if not item.revealed or type(item.name) ~= "string" then
		return "Unidentified brainrots cannot be fused. Take it to the Detective first."
	end

	local next = Fuse.nextRarity(item.rarity)
	if not next then
		return `{Rarity.displayName(item.rarity)} cannot be fused, it is the top tier.`
	end

	if not Brainrots.availableOn(next, PlayerData.reachedIsland(player)) then
		return `{Rarity.displayName(next)} brainrots unlock on a later island.`
	end

	local slot = pending[player]
	if slot and slot.name ~= item.name then
		return `The machine holds {slot.name}, add the same brainrot.`
	end

	return nil
end

--[[
	MAKINEYE KONABILECEK BRAINROTLAR (secim listesi)

	Makinede bir brainrot varsa yalnizca AYNI ISIMDEKILER listelenir.
	Ayni isimden toplam kac tane oldugu da gider: oyuncu 3'e yetip
	yetmeyecegini listeden gorsun.
]]
local function eligibleItems(player: Player): { any }
	local data = PlayerData.get(player)
	if not data then
		return {}
	end

	local out = {}
	local sayac: { [string]: number } = {}

	for _, item in data.inventory do
		if uygunsuzluk(player, item) then
			continue
		end
		sayac[item.name] = (sayac[item.name] or 0) + 1
		table.insert(out, {
			uid = item.uid,
			name = item.name,
			rarity = item.rarity,
			condition = item.condition,
			mutation = item.mutation,
		})
	end

	for _, entry in out do
		entry.owned = sayac[entry.name] or 0
	end

	-- Once cok olan (3'e yetenler ustte), sonra ada gore
	table.sort(out, function(a, b)
		if a.owned ~= b.owned then
			return a.owned > b.owned
		end
		return a.name < b.name
	end)

	return out
end

local function pushStatus(player: Player)
	local slot = pending[player]
	local slots = {}

	if slot then
		for _, entry in slot.entries do
			table.insert(slots, {
				uid = entry.item.uid,
				name = entry.item.name,
				rarity = entry.item.rarity,
				condition = entry.condition,
				mutation = entry.mutation,
			})
		end
	end

	FuseDurum:FireClient(player, {
		near = true,
		fusing = fusing[player] == true,
		name = if slot then slot.name else nil,
		rarity = if slot then slot.rarity else nil,
		nextRarity = if slot then Fuse.nextRarity(slot.rarity) else nil,
		required = Fuse.Required,
		chance = Fuse.SuccessChance,
		slots = slots,
		mutations = if slot then Fuse.mutationChances(slot.entries) else {},
		timeout = if slot then math.max(0, Fuse.Timeout - (os.clock() - slot.lastAt)) else 0,
		items = eligibleItems(player),
	})
end

local function closeStatus(player: Player)
	FuseDurum:FireClient(player, { near = false })
end

------------------------------------------------------------------
-- IADE
------------------------------------------------------------------

-- Makinedeki BUTUN brainrotlari sahibine geri verir (her cikis yolu buradan)
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
		table.insert(data.inventory, entry.item)
	end

	Envanter.syncBrainrots(player)
	Envanter.push(player)

	if count > 0 and reason then
		Bildirim:FireClient(player, `{count} brainrot(s) returned from the machine ({reason})`, UYARI)
	end
end

-- Tek slotu geri verir ("Return" dugmesi)
local function returnOne(player: Player, uid: string)
	local slot = pending[player]
	if not slot or fusing[player] then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	for index, entry in slot.entries do
		if entry.item.uid == uid then
			table.remove(slot.entries, index)
			table.insert(data.inventory, entry.item)
			break
		end
	end

	if #slot.entries == 0 then
		pending[player] = nil
	else
		slot.lastAt = os.clock()
	end

	Envanter.syncBrainrots(player)
	Envanter.push(player)
	pushStatus(player)
end

------------------------------------------------------------------
-- KOYMA
------------------------------------------------------------------
local function insertItem(player: Player, uid: string)
	if fusing[player] then
		return
	end

	local item = PlayerData.findItem(player, uid)
	if not item then
		Bildirim:FireClient(player, "That brainrot is no longer in your inventory.", UYARI)
		return
	end

	local sebep = uygunsuzluk(player, item)
	if sebep then
		Bildirim:FireClient(player, sebep, RED)
		return
	end

	local slot = pending[player]
	if slot and #slot.entries >= Fuse.Required then
		Bildirim:FireClient(player, `The machine is full ({Fuse.Required}/{Fuse.Required}). Press FUSE!`, UYARI)
		return
	end

	local taken = PlayerData.removeItem(player, uid)
	if not taken then
		return
	end

	if not slot then
		slot = { name = taken.name, rarity = taken.rarity, entries = {}, lastAt = os.clock() }
		pending[player] = slot
	end

	local active = slot :: Pending
	table.insert(active.entries, {
		condition = taken.condition,
		mutation = taken.mutation,
		item = taken,
	})
	active.lastAt = os.clock()

	Envanter.syncBrainrots(player)
	Envanter.push(player)
	pushStatus(player)
end

------------------------------------------------------------------
-- BIRLESTIRME
------------------------------------------------------------------
local function bodyOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function playFuseSound(player: Player, names: { string }): Sound?
	local body = bodyOf(player)
	return if body then Assets.playSoundAt(names, body) else nil
end

local function completeFuse(player: Player)
	local slot = pending[player]
	if not slot or fusing[player] then
		return
	end

	if #slot.entries < Fuse.Required then
		Bildirim:FireClient(player, `You need {Fuse.Required} of the same brainrot to fuse.`, UYARI)
		return
	end

	local nextRarity = Fuse.nextRarity(slot.rarity)
	local ada = PlayerData.reachedIsland(player)

	if not nextRarity or not Brainrots.availableOn(nextRarity, ada) then
		-- Koyarken engelleniyor; yine de brainrotlar kaybolmasin
		returnItems(player, "cannot fuse this brainrot")
		pushStatus(player)
		return
	end

	local basari = Fuse.rollSuccess(rng)

	--[[
		ODUL ONCE veriye yazilir, makine ANCAK ondan sonra bosaltilir. Brainrot
		uretilemezse (veri yuklenmemis olsa mesela) konanlar iade edilir.
	]]
	local kazanilan: any = nil
	local condition = Fuse.rollSize(slot.entries, rng)
	local mutation = Fuse.rollMutation(slot.entries, rng)

	if basari then
		local info = Brainrots.rollIsland(nextRarity :: any, ada, rng)
		kazanilan = PlayerData.addBrainrot(player, nextRarity, condition, mutation, ada)
		if not kazanilan then
			returnItems(player, "try again")
			pushStatus(player)
			return
		end

		-- Makineden cikan brainrot ACIK gelir: Detective'e gitmeye gerek yok
		kazanilan.name = info.name
		kazanilan.revealed = true
		GorevTakip.ilerlet(player, "collect", 1, nextRarity)
	end

	-- Gorev panosu: makinede bir birlestirme yapildi (tutsa da tutmasa da)
	GorevTakip.ilerlet(player, "fuse", 1, nextRarity)
	-- Level: her deneme XP verir; tutarsa cikan kademenin XP'si de eklenir
	Seviye.xpVer(player, Seviye.XP.fuse + (if basari then Seviye.rarityXp(nextRarity) else 0))

	local fromName = slot.name
	local fromRarity = slot.rarity
	local souls = #slot.entries

	pending[player] = nil
	fusing[player] = true
	pushStatus(player)

	FuseSonuc:FireClient(player, {
		success = basari,
		fromName = fromName,
		fromRarity = fromRarity,
		toRarity = nextRarity,
		name = if kazanilan then kazanilan.name else nil,
		condition = condition,
		mutation = mutation,
		income = if kazanilan then Brainrots.income(kazanilan.name, condition :: any, mutation :: any) else 0,
		souls = souls,
	})

	local charge = playFuseSound(player, Fuse.VFX.charge)

	task.delay(Fuse.burstDelay(), function()
		if charge and charge.Parent then
			charge:Stop()
			charge:Destroy()
		end
		-- Patlama yalnizca basarida; basarisizlikta gosteri sessizce soner
		if basari and player.Parent then
			Patlama.oynat(player, nextRarity :: string)
		end
	end)

	task.delay(Fuse.mergeTime(), function()
		fusing[player] = nil
		if not player.Parent then
			return
		end

		Envanter.syncBrainrots(player)
		Envanter.push(player)

		if kazanilan then
			local tam = Mutations.get(mutation).prefix .. kazanilan.name
			Bildirim:FireClient(
				player,
				`FUSE SUCCESS! {tam} {Condition.get(condition).shortName} ({Format.perSecond(Brainrots.income(kazanilan.name, condition :: any, mutation :: any))})`,
				Rarity.color(nextRarity :: string)
			)
		else
			Bildirim:FireClient(player, `Fuse failed... your {souls} {fromName} were lost.`, RED)
		end

		pushStatus(player)
	end)
end

------------------------------------------------------------------
-- PROMPT
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

	-- Prompt pencereyi acar; brainrotlar orada secilir
	prompt.Triggered:Connect(function(player: Player)
		pushStatus(player)
		FuseSecim:FireClient(player)
	end)

	print(`[Fuse] Makine promptu kuruldu: {anchor:GetFullName()}`)
end

task.spawn(attachMachinePrompt)

------------------------------------------------------------------
-- REMOTE BAGLANTILARI
------------------------------------------------------------------
FuseEkle.OnServerEvent:Connect(function(player, uid)
	if type(uid) == "string" then
		insertItem(player, uid)
	end
end)

FuseCikar.OnServerEvent:Connect(function(player, uid)
	if type(uid) == "string" then
		returnOne(player, uid)
	end
end)

FuseBaslat.OnServerEvent:Connect(function(player)
	completeFuse(player)
end)

FuseGeriAl.OnServerEvent:Connect(function(player)
	if fusing[player] then
		return
	end
	returnItems(player, "taken back")
	pushStatus(player)
end)

------------------------------------------------------------------
-- DONGULER
------------------------------------------------------------------
local nearby: { [Player]: boolean } = {}

-- Menzildekine durum yayini; menzilden cikanin penceresi kapanir
task.spawn(function()
	while true do
		task.wait(0.4)

		for _, player in Players:GetPlayers() do
			if inMachineRange(player) then
				nearby[player] = true
				pushStatus(player)
			elseif nearby[player] then
				nearby[player] = nil
				closeStatus(player)
			end
		end
	end
end)

-- Zaman asimi: unutulan brainrotlar sahibine doner
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
				returnItems(player, `no action for {Fuse.Timeout}s`)
				if nearby[player] then
					pushStatus(player)
				end
			end
		end
	end
end)

--[[
	Oyuncu ayrilirken makinedeki brainrotlar verisine GERI YAZILIR.
	PlayerData'nin ayrilma oncesi kancasi cache hala doluyken calisir.
]]
PlayerData.onBeforeRelease(function(player: Player)
	returnItems(player, nil)
end)

Players.PlayerRemoving:Connect(function(player)
	pending[player] = nil
	nearby[player] = nil
	fusing[player] = nil
end)
