--!strict
--[[
	Envanter senkronizasyonu.

	PlayerData.inventory tek dogruluk kaynagidir; bu modul Backpack'i ona
	gore esitler. Her brainrot FIZIKSEL bir Tool olarak cantada durur:

	  - slota yerlestirilmemis her brainrot -> cantada bir Tool
	  - slota konulan brainrot          -> Tool silinir, base'te model belirir
	  - Detective bir brainrotu acinca  -> Tool yeniden uretilir (siyah -> normal)

	Kurek ve GPS de burada garanti altina alinir:
	  - Kurek her zaman tek tanedir
	  - GPS her zaman cantadadir (kumda otomatik ELE GELMEZ, oyuncu kendi kusanir)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))

local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Tools = require(script.Parent:WaitForChild("Tools"))
local Olta = require(script.Parent:WaitForChild("Olta"))

local EnvanterGuncelle = Net.event("EnvanterGuncelle")

local Envanter = {}

-- Envanter durumunu client'a yollar (HUD + envanter ekrani bunu kullanir)
function Envanter.push(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	--[[
		INDEX KAYDI BURADA TUTULUYOR

		Brainrotun kimligi BES ayri yerde aciliyor (Detective, Fuse, Lucky
		Block, gunluk odul, admin paneli). Bes cagri yerine tek bir yere
		yazmanin sebebi: her acilis sonunda envanter istemciye
		senkronlanmak ZORUNDA -- oyuncu esyanin adini baska turlu
		ogrenemez. Yani burasi butun acilis yollarinin ortak bogazi ve
		ileride altinci bir yol eklenirse onu da kendiliginden yakalar.

		Yan fayda: guncellemeden once oynayanlarin elindeki acilmis
		brainrotlar ilk senkronda Index'e islenir, eski oyuncular sifir
		Index'le baslamaz.
	]]
	for _, item in data.inventory do
		if item.revealed and item.name then
			PlayerData.discover(player, item.name)
		end
	end

	EnvanterGuncelle:FireClient(player, {
		rot = data.rot,
		rotCoins = data.rotCoins,
		luckyBlocks = data.luckyBlocks,
		shovel = data.shovel,
		-- Envanter ekrani dedektor satirini bundan ciziyor; eksik olursa
		-- oyuncu Divine tasisa bile ekranda Basic gorunur
		detector = data.detector,
		inventory = data.inventory,
		-- Madenler ve kazmalar (ada saticilari ve ileride envanter ekrani)
		ores = data.ores,
		pickaxes = data.pickaxes,
		-- Envanter ekrani base bolumunu 1..acik slot sayisi kadar ciziyor
		baseSlots = data.baseSlots,
		-- Isinlayici menusu acik adalari bundan ciziyor
		islands = data.islands,
	})
end

------------------------------------------------------------------
-- KUREK VE GPS  --  CANTAYA HIC GIRMEZLER
--
-- Ikisi de artik envanterde durmuyor; duruma gore DOGRUDAN ELE
-- veriliyor ve isi bitince siliniyor:
--
--     kumun uzerine bas   -> GPS elde belirir ve orada kalir
--     suzmeye tikla       -> yerini kurek alir, kazi biter, GPS geri gelir
--     kumdan cik          -> ikisi de kaybolur
--
-- Kimin ne zaman elinde olacagina KaziSistemi karar veriyor; burasi
-- yalnizca "su an sunu tut" emrini uyguluyor.
--
-- Tool'u dogrudan Character'a parent etmek Roblox'ta KUSANMAK demektir;
-- Humanoid:EquipTool cantada olmayi sart kostugu icin bu yol secildi.
------------------------------------------------------------------

--[[
	Tool SU AN ELDE MI?
	Cantayi saymaz -- zaten oraya hic konmuyorlar.
]]
local function held(player: Player, toolName: string): Tool?
	return Tools.equipped(player, toolName)
end

--[[
	Elde ne varsa indirir.

	Oyuncu brainrot tasirken bir suzmeye tiklarsa kurek onun yerine gecmeli;
	iki tool ayni anda kusanilamaz. Humanoid:UnequipTools brainrotu cantaya
	geri koyar -- yeri zaten orasi.
]]
local function clearHands(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:UnequipTools()
	end
end

-- Adi verilen tool'u hem elden hem cantadan siler
function Envanter.unequip(player: Player, toolName: string)
	Tools.remove(player, toolName)
end

-- Kurek ve GPS'in ikisini birden kaldirir (kumdan cikinca)
function Envanter.unequipTools(player: Player)
	Tools.remove(player, Tools.ShovelName)
	Tools.remove(player, Tools.GPSName)
	Tools.remove(player, Tools.PickaxeName)
end

--[[
	Kuregi ELINE verir; GPS varsa onun yerini alir.
	Zaten eldeyse hicbir sey yapmaz -- yoksa her cagride tool yeniden
	uretilir ve tutma animasyonu bastan baslardi.
]]
function Envanter.equipShovel(player: Player)
	local data = PlayerData.get(player)
	local character = player.Character
	if not data or not character then
		return
	end

	if held(player, Tools.ShovelName) then
		return
	end

	clearHands(player)
	Tools.remove(player, Tools.GPSName)
	Tools.remove(player, Tools.ShovelName)
	Tools.remove(player, Tools.PickaxeName)
	Tools.buildShovel(data.shovel).Parent = character
end

--[[
	KAZMAYI ELINE verir (maden kazisi). Kurekle ayni kural: zaten eldeyse
	yeniden uretilmez.
]]
function Envanter.equipPickaxe(player: Player, pickaxeId: string)
	local character = player.Character
	if not character then
		return
	end

	local eldeki = held(player, Tools.PickaxeName)
	if eldeki and eldeki:GetAttribute("PickaxeId") == pickaxeId then
		return
	end

	clearHands(player)
	Tools.remove(player, Tools.GPSName)
	Tools.remove(player, Tools.ShovelName)
	Tools.remove(player, Tools.PickaxeName)
	Tools.buildPickaxe(pickaxeId).Parent = character
end

--[[
	GPS'i ELINE verir; kurek varsa onun yerini alir.

	Oyuncu tool'u indirmeye calisirsa Roblox onu cantaya atar; bu durumda
	elde bulunamaz ve buraya tekrar gelinir -- yani GPS kumdayken elde
	kalmaya devam eder.
]]
function Envanter.equipGPS(player: Player)
	local data = PlayerData.get(player)
	local character = player.Character
	if not data or not character then
		return
	end

	if held(player, Tools.GPSName) then
		return
	end

	clearHands(player)
	Tools.remove(player, Tools.ShovelName)
	Tools.remove(player, Tools.GPSName)
	Tools.remove(player, Tools.PickaxeName)
	Tools.buildGPS(data.detector).Parent = character
end

--[[
	OLTAYI ELE VERIR  (flyboardla denize girince)

	Olta bir Tool DEGIL: hotbarda yer kaplamasin ve elden birakilamasin
	diye dogrudan sag ele kaynaklanir (bkz. Modules > Olta). Kurek ve GPS
	yine de elden birakilir ki denizde tek sey dursun.

	Oltasi olmayan oyuncuda hicbir sey olmaz.
]]
function Envanter.equipRod(player: Player)
	local data = PlayerData.get(player)
	local character = player.Character
	if not data or not character or not data.rod then
		return
	end

	if Olta.has(player) then
		return
	end

	clearHands(player)
	Tools.remove(player, Tools.ShovelName)
	Tools.remove(player, Tools.GPSName)
	Tools.remove(player, Tools.PickaxeName)

	local model = Olta.build(data.rod)
	if not Olta.attach(character, model) then
		-- Karakter hazir degilse (el parcasi yok) sessizce vazgec
		model:Destroy()
	end
end

-- Oltayi ve atilmis misinayi tamamen kaldirir (flyboarddan inince)
function Envanter.removeRod(player: Player)
	Olta.remove(player.Character)
end

--[[
	ELDEKI kuregi tazeler (seviye ya da skin degistiginde).

	Elde kurek yoksa hicbir sey yapmaz: tool zaten yokken uretmenin
	anlami yok, bir dahaki kaziya girdiginde yenisi kurulur.
]]
function Envanter.giveShovel(player: Player)
	if not held(player, Tools.ShovelName) then
		return
	end

	Tools.remove(player, Tools.ShovelName)
	Envanter.equipShovel(player)
end

-- ELDEKI GPS'i tazeler (seviye ya da skin degistiginde)
function Envanter.giveGPS(player: Player)
	if not held(player, Tools.GPSName) then
		return
	end

	Tools.remove(player, Tools.GPSName)
	Envanter.equipGPS(player)
end

--[[
	Lucky Block: elde kac tane varsa tek bir Tool olarak durur, adinda adedi
	yazar. Hic kalmayinca Tool silinir.
]]
function Envanter.syncLuckyBlocks(player: Player)
	local data = PlayerData.get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then
		return
	end

	--[[
		Her TUR icin ayri bir Tool. Mevcut Tool'lar aranirken ISIM kullanilamaz
		(adinda adet yaziyor, her acilista degisiyor); tur niteligine bakiliyor.
	]]
	local existing: { [string]: Tool } = {}

	for _, place in { backpack :: Instance, player.Character } do
		if place then
			for _, item in place:GetChildren() do
				if item:IsA("Tool") and item:GetAttribute("LuckyBlock") then
					local tierId = item:GetAttribute("LuckyTier")
					-- Tursuz (eski surumden kalma) ya da tekrar eden Tool'lar silinir
					if type(tierId) ~= "string" or existing[tierId] then
						item:Destroy()
					else
						existing[tierId] = item
					end
				end
			end
		end
	end

	for _, tier in LuckyBlock.Tiers do
		local count = data.luckyBlocks[tier.id] or 0
		local tool = existing[tier.id]

		if count <= 0 then
			if tool then
				tool:Destroy()
			end
			continue
		end

		--[[
			Tool zaten varsa YENIDEN URETILMEZ, sadece adi guncellenir.
			Yeniden uretilseydi oyuncu blogu elinde tutarken her acilista Tool
			elinden duser, her blok icin tekrar kusanmasi gerekirdi.
		]]
		if tool then
			tool.Name = Tools.luckyBlockLabel(tier.id, count)
		else
			Tools.buildLuckyBlock(tier.id, count).Parent = backpack
		end
	end
end

--[[
	Cantayi envanter verisiyle esitler.
	Slotta olmayan her brainrot icin bir Tool bulunur; fazlaliklar silinir.
]]
--[[
	Sirt cantasini (hotbar) siralar: once KIMLIGI ACILMIS brainrotlar
	PAHALIDAN UCUZA, sonra acilmamislar.

	NEDEN IKI ADIM
	Roblox'un canta arayuzu Tool'lari eklenme sirasina gore dizer. Onceki
	surum her Tool'u ayni karede cikarip hemen geri koyuyordu; bu ya hic
	istemciye gitmiyor ya da Tool bosalttigi kendi yerine geri oturuyordu --
	sira hic degismiyordu. Artik:
	    1. siralanacak Tool'lar gorunmez bir BEKLEME klasorune alinir
	       (oyuncunun altinda "CantaSirasi"; syncBrainrots onu da tarar,
	       yoksa Tool'lari kayip sanip kopyasini uretirdi)
	    2. kisa bir bekleme sonra istenen sirayla cantaya geri konur
	Zaten siraliysa hicbir seye dokunulmaz (her senkronda titremesin).
	ELDE TUTULAN tool'a dokunulmaz (o Character'in altindadir).
]]
local PARK_ADI = "CantaSirasi"
local siralaniyor: { [Player]: boolean } = {}

local function parkKlasoru(player: Player): Folder
	local var = player:FindFirstChild(PARK_ADI)
	if var and var:IsA("Folder") then
		return var
	end
	local yeni = Instance.new("Folder")
	yeni.Name = PARK_ADI
	yeni.Parent = player
	return yeni
end

local function reorderBackpack(player: Player, backpack: Instance)
	if siralaniyor[player] then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	-- uid -> (acilmis mi, saniyelik getiri)
	local acik: { [string]: boolean } = {}
	local worth: { [string]: number } = {}
	for _, entry in data.inventory do
		if entry.revealed and entry.name then
			acik[entry.uid] = true
			worth[entry.uid] = Brainrots.income(entry.name, entry.condition, entry.mutation)
		else
			worth[entry.uid] = Brainrots.minIncome(entry.rarity, entry.condition)
		end
	end

	local mevcut: { Tool } = {}
	for _, tool in backpack:GetChildren() do
		if tool:IsA("Tool") and tool:GetAttribute("BrainrotUid") then
			table.insert(mevcut, tool)
		end
	end
	if #mevcut < 2 then
		return
	end

	local istenen = table.clone(mevcut)
	table.sort(istenen, function(a, b)
		local ua = a:GetAttribute("BrainrotUid") :: string
		local ub = b:GetAttribute("BrainrotUid") :: string
		if (acik[ua] == true) ~= (acik[ub] == true) then
			return acik[ua] == true
		end
		return (worth[ua] or 0) > (worth[ub] or 0)
	end)

	local ayni = true
	for i, tool in istenen do
		if mevcut[i] ~= tool then
			ayni = false
			break
		end
	end
	if ayni then
		return
	end

	siralaniyor[player] = true
	local park = parkKlasoru(player)
	for _, tool in istenen do
		tool.Parent = park
	end

	task.spawn(function()
		task.wait(0.15)
		for _, tool in istenen do
			if tool.Parent == park and backpack.Parent then
				tool.Parent = backpack
			end
		end
		siralaniyor[player] = nil
	end)
end

function Envanter.syncBrainrots(player: Player)
	local data = PlayerData.get(player)
	if not data then
		warn(`[Envanter] {player.Name}: veri yuklenmemis, brainrot esitlenemedi`)
		return
	end

	-- Karakter yeni oluyorsa Backpack bir an gecikebilir; kisa sure bekle
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		backpack = player:WaitForChild("Backpack", 5) :: Backpack?
	end
	if not backpack then
		warn(`[Envanter] {player.Name}: Backpack bulunamadi, brainrot esitlenemedi`)
		return
	end

	-- Cantada/elde bulunan brainrot tool'lari
	local present: { [string]: Tool } = {}
	-- Siralama sirasinda bekleme klasorundeki Tool'lar da sayilir (bkz. reorderBackpack)
	local places = { backpack :: Instance, player.Character, player:FindFirstChild(PARK_ADI) }

	for _, place in places do
		if place then
			for _, item in place:GetChildren() do
				if item:IsA("Tool") then
					local uid = item:GetAttribute("BrainrotUid")
					if type(uid) == "string" then
						present[uid] = item
					end
				end
			end
		end
	end

	-- Envanterde olup cantada olmayanlari uret, durumu degisenleri yenile
	local expected: { [string]: boolean } = {}

	-- Tek bir brainrot'un uretimi patlarsa digerleri etkilenmesin
	--[[
		Tek bir brainrot'un uretimi patlarsa digerleri etkilenmesin.

		DIKKAT: pcall hatayi yutar; brainrot envanter VERISINDE kalir ama
		cantada gorunmez. "Envantere geliyor ama cantaya gelmiyor" seklindeki
		her sikayette once Output'taki bu uyariya bakilmali -- brainrot'un
		adi ve gercek hata mesaji orada yaziyor.
	]]
	local function spawnTool(entry: any)
		local ok, err = pcall(function()
			Tools.buildBrainrot(entry).Parent = backpack
		end)
		if not ok then
			warn(
				`[Envanter] {player.Name}: "{entry.name or "???"}" ({entry.rarity}) brainrot tool'u `
					.. `uretilemedi -- {tostring(err)}`
			)
		end
	end

	for _, entry in data.inventory do
		if entry.slot then
			continue -- base'te duruyor, cantada olmamali
		end

		expected[entry.uid] = true
		local existing = present[entry.uid]

		if existing then
			-- Siyahtan normale gectiyse tool'u yeniden uret
			local wasRevealed = existing:GetAttribute("Revealed") == true
			if wasRevealed ~= (entry.revealed == true) then
				existing:Destroy()
				spawnTool(entry)
			end
		else
			spawnTool(entry)
		end
	end

	-- Envanterde olmayan (satilmis / slota konmus) tool'lari temizle
	for uid, tool in present do
		if not expected[uid] then
			tool:Destroy()
		end
	end

	-- Canta pahalidan ucuza dizilir
	reorderBackpack(player, backpack)
end

--[[
	Karakter dogdugunda / veri degistiginde cagrilir.

	Kurek ve GPS BURADA VERILMEZ: ikisi de cantaya girmiyor, duruma gore
	dogrudan ele veriliyor (bkz. KaziSistemi > otomatik ekipman dongusu).
	Burasi yalnizca cantada durmasi gereken seylerle ilgilenir.
]]
function Envanter.refresh(player: Player)
	Envanter.syncBrainrots(player)
	Envanter.syncLuckyBlocks(player)
	Envanter.push(player)
end

return Envanter
