--[[
	AdminPanel  (Script)
	Yeri: ServerScriptService > AdminPanel

	Test/yonetim paneli. Yetki Config.Admin.userIds listesinden gelir;
	Studio'da allowInStudio acikken herkese aciktir (canli sunucuda degil).

	YETKI SUNUCUDA DOGRULANIR: client'tan gelen her komut yeniden kontrol edilir,
	panel gorunmese bile yetkisiz bir oyuncu komut calistiramaz.

	Komutlar:
	  giveAllTools   -- butun kurek ve dedektor seviyelerinin en ustunu verir
	  giveRot        -- Config.Admin.rotGrant kadar Rot
	  revealAll      -- envanterdeki tum siyah brainrotlarin kimligini acar
	  giveLuckyBlock -- secilen turden BIR Lucky Block verir (arg: tur id'si)
	  luckyEvent     -- blok yagmuru etkinligini hemen baslatir
	  giveBrainrot   -- secilen rarity'de brainrot uretir
	                    (arg: rarity ya da { rarity = ..., mutation = ... })
	  setShovel      -- kurek seviyesi ayarlar (arg: shovelId)
	  setDetector    -- dedektor seviyesi ayarlar (arg: detectorId)
	  setFlyboard    -- flyboard kademesi verir (arg: flyboardId)
	  setRod         -- olta kademesi verir (arg: rodId)
	  clearInventory -- envanteri bosaltir (slottakiler dahil)
	  spawnBeam      -- istenen kademede isik suzmesi dogurur (arg: rarity)
	  haritaRaporu   -- adalarin, base lerin ve NPC lerin konumlarini Output a yazar
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
-- Ogretici adim tanimlari (admin komutlari icin)
local OgreticiAdimlar = require(Shared:WaitForChild("Ogretici"))
local Config = require(Shared:WaitForChild("OyunConfig"))
local Shovels = require(Shared:WaitForChild("Shovels"))
local Detectors = require(Shared:WaitForChild("Detectors"))
local Flyboard = require(Shared:WaitForChild("Flyboard"))
local Rods = require(Shared:WaitForChild("Rods"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Condition = require(Shared:WaitForChild("Condition"))
local Bases = require(Shared:WaitForChild("Bases"))
local Fuse = require(Shared:WaitForChild("Fuse"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Assets = require(Shared:WaitForChild("Assets"))
local Ores = require(Shared:WaitForChild("Ores"))
local Passler = require(Shared:WaitForChild("Passler"))
local Hiz = require(Shared:WaitForChild("Hiz"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))
local Tools = require(Modules:WaitForChild("Tools"))
local Beams = require(Modules:WaitForChild("Beams"))
local Sand = require(Modules:WaitForChild("Sand"))

-- BaseSistemi'nin slot modellerini envanterle esitleyen tetigi
local baseYenile = script.Parent:WaitForChild("BaseSistemi"):WaitForChild("BaseYenile") :: BindableEvent
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local LuckyBlockOdul = require(Modules:WaitForChild("LuckyBlockOdul"))

local Bildirim = Net.event("Bildirim")
local AdminPanelAc = Net.event("AdminPanelAc")
local AdminKomut = Net.event("AdminKomut")

local A = Config.Admin
local rng = Random.new()

------------------------------------------------------------------
-- YETKI
------------------------------------------------------------------
local function isAdmin(player: Player): boolean
	if A.allowInStudio and RunService:IsStudio() then
		return true
	end

	for _, id in A.userIds do
		if player.UserId == id then
			return true
		end
	end

	return false
end

------------------------------------------------------------------
-- KOMUTLAR
------------------------------------------------------------------
local commands: { [string]: (player: Player, data: any, arg: any) -> string? } = {}

function commands.giveAllTools(player, data)
	-- En ust kurek ve dedektor
	local topShovel = Shovels.Order[#Shovels.Order]
	local topDetector = Detectors.Order[#Detectors.Order]

	data.shovel = topShovel
	data.shovelMax = topShovel
	data.detector = topDetector
	data.detectorMax = topDetector

	Envanter.giveShovel(player)
	Envanter.giveGPS(player)

	return `{Shovels.get(topShovel).displayName} + {Detectors.get(topDetector).displayName} verildi`
end

function commands.giveRot(player, data)
	PlayerData.addRot(player, A.rotGrant)
	return `+{Format.short(A.rotGrant)} Rot`
end

-- Rot Coin: panelde +10 / +100 / +1000 dugmeleri (baska miktar kabul edilmez)
local ROT_COIN_MIKTARLARI = { [10] = true, [100] = true, [1000] = true }

function commands.giveRotCoins(player, data, arg)
	local miktar = tonumber(arg)
	if not miktar or not ROT_COIN_MIKTARLARI[miktar] then
		return nil
	end
	PlayerData.addRotCoins(player, miktar)
	return `+{miktar} Rot Coin  (toplam {data.rotCoins})`
end

--[[
	OGRETICIYI BASA SAR

	Ogretici bir kere bitince (ya da eski bir kayitta hic baslamayinca) bir
	daha gorunmuyor; test etmek icin her seferinde yeni hesap acmak gerekirdi.
	Bu komut oyuncuyu ilk adima dondurur ve istemciye yeni durumu yollar.
]]
function commands.ogreticiSifirla(player, data)
	data.tutorial = { adim = 1, bitti = false }

	local modul = script.Parent:FindFirstChild("Modules")
	local ogretici = modul and modul:FindFirstChild("Ogretici")
	if ogretici and ogretici:IsA("ModuleScript") then
		local ok, sonuc = pcall(require, ogretici)
		if ok then
			sonuc.gonder(player)
		end
	end

	return "Ogretici basa sarildi: 1. adim"
end

-- Ogretici modulunu bir kez cozer (yoksa nil)
local function ogreticiModulu(): any?
	local modul = script.Parent:FindFirstChild("Modules")
	local node = modul and modul:FindFirstChild("Ogretici")
	if node and node:IsA("ModuleScript") then
		local ok, sonuc = pcall(require, node)
		if ok then
			return sonuc
		end
	end
	return nil
end

--[[
	SIRADAKI ADIMA GEC

	Adimin isini yapmadan ilerletir: test ederken her seferinde kazi yapip
	dedektife kosmak gerekmesin.
]]
function commands.ogreticiAtla(player, data)
	if data.tutorial.bitti then
		return "Ogretici zaten bitmis"
	end

	local toplam = OgreticiAdimlar.adimSayisi()
	if data.tutorial.adim >= toplam then
		data.tutorial.bitti = true
	else
		data.tutorial.adim += 1
	end

	local ogretici = ogreticiModulu()
	if ogretici then
		ogretici.gonder(player)
	end

	return if data.tutorial.bitti
		then "Ogretici bitirildi"
		else `Ogretici {data.tutorial.adim}. adima gecti`
end

-- Butun ogreticiyi bitirir (yonergeler kaybolur)
function commands.ogreticiBitir(player, data)
	data.tutorial.bitti = true

	local ogretici = ogreticiModulu()
	if ogretici then
		ogretici.gonder(player)
	end

	return "Ogretici bitirildi"
end

--[[
	ADA IPUCUNU SIFIRLA

	"Parasi yetti, Teleporter'i goster" ipucunu yeniden gosterilebilir
	yapar (bkz. Shared > Ogretici > AdaIpucu).
]]
function commands.adaIpucuSifirla(player, data)
	data.tutorial.adaIpucu = nil
	player:SetAttribute(OgreticiAdimlar.AdaIpucu.nitelik, nil)
	return "Ada ipucu sifirlandi (parasi yetince yeniden cikar)"
end

-- Etkinligi beklemeden tetikler (normalde saatte bir)
function commands.luckyEvent(player, data)
	LuckyBlockOdul.runEvent()
	return `Etkinlik baslatildi ({LuckyBlock.Event.count} blok)`
end

-- Her tikta TEK blok verir; tur arg ile gelir
function commands.giveLuckyBlock(player, data, arg)
	local tierId = if type(arg) == "string" and LuckyBlock.exists(arg) then arg else LuckyBlock.Default
	local tier = LuckyBlock.get(tierId)

	PlayerData.addLuckyBlocks(player, tierId, 1)
	Envanter.syncLuckyBlocks(player)
	Envanter.push(player)

	return `+1 {tier.displayName}  (toplam {PlayerData.luckyBlockCount(player, tierId)})`
end

--[[
	arg iki bicimde gelebilir:
	    "Legendary"                                 -- eski panel
	    { rarity = "Legendary", mutation = "Hacker" }  -- mutasyon secili panel
	Mutasyon testi icin sart: Hacker binde bir cikiyor, elle uretilemezse
	yesil modellerin dogru calistigi dogrulanamaz.
]]
--[[
	Panelden brainrot verir.

	Mutasyon VARSAYILAN OLARAK RASTGELE cekilir -- oyunun her yerinde
	oldugu gibi Gold %7, Diamond %3, Galaxy %1. Panelde belirli bir
	mutasyon secilmisse onun yerine o kullanilir.
]]
function commands.giveBrainrot(player, data, arg)
	local rarityId = "Common"
	local mutationId: string? = nil

	if type(arg) == "string" then
		if Rarity.Info[arg] then
			rarityId = arg
		end
	elseif type(arg) == "table" then
		if type(arg.rarity) == "string" and Rarity.Info[arg.rarity] then
			rarityId = arg.rarity
		end
		-- "Random" ya da bos: rastgele cekilis
		if type(arg.mutation) == "string" and Mutations.Info[arg.mutation] then
			mutationId = arg.mutation
		end
	end

	if not mutationId then
		mutationId = Mutations.roll(rng)
	end

	local condition = Condition.roll(rng)

	local item = PlayerData.addBrainrot(player, rarityId, condition, mutationId)
	if not item then
		return nil
	end

	--[[
		Panelden verilen brainrot ACIK gelir.

		Normal akista brainrot simsiyah cikar ve kimligi -- mutasyonu dahil --
		Detective acana kadar gizlidir. Panel bir test araci oldugu icin
		burada bekletmenin anlami yok: mutasyonu ve ismi hemen gorunsun,
		yoksa "mutasyon hic gelmiyor" gibi gorunur.
	]]
	item.name = Brainrots.roll(rarityId :: any, rng).name
	item.revealed = true

	Envanter.syncBrainrots(player)

	local mutationInfo = Mutations.get(mutationId)
	local suffix = if Mutations.isSpecial(mutationId)
		then `  <-- {mutationInfo.displayName} {mutationInfo.multiplier}x`
		else ""

	return `{item.name}  ({Rarity.displayName(rarityId)}, {Condition.get(condition).shortName}, {mutationInfo.displayName}){suffix}`
end

--[[
	Envanterdeki TUM siyah brainrotlarin kimligini aciga cikarir.
	Detective'in yaptigi isin toplu ve beklemesiz hali: rarity sabit kalir,
	isim esyanin KAZILDIGI ADANIN (ve onceki adalarin) havuzundan secilir --
	Detective ile birebir ayni kural. Eskiden butun havuzdan seciyordu ve
	main island'da kazilanlara diger adalarin brainrotlari cikiyordu.
]]
function commands.revealAll(player, data)
	local count = 0

	for _, item in data.inventory do
		if not item.revealed then
			local picked = Brainrots.rollIsland(item.rarity :: any, item.island, rng)
			item.name = picked.name
			item.revealed = true
			count += 1
		end
	end

	if count == 0 then
		return "Acilacak siyah brainrot yok"
	end

	Envanter.syncBrainrots(player)
	return `{count} brainrot'un kimligi acildi`
end

--[[
	ELDEKI brainrotu secilen mutasyona cevirir.

	Panelde mutasyona basildiginda calisir: elde acilmis (kimligi belli)
	bir brainrot varsa o brainrot dogrudan mutasyonlu haline doner.
	Kapali (obtainable = false) mutasyonlar da buradan verilebilir --
	panelin amaci zaten test.
]]
function commands.setMutation(player, data, arg)
	if type(arg) ~= "string" or not Mutations.Info[arg] then
		return nil
	end

	local _, heldUid = Tools.equippedBrainrot(player)
	if not heldUid then
		return "Once bir brainrotu eline al"
	end

	local item = PlayerData.findItem(player, heldUid)
	if not item then
		return nil
	end

	if not item.revealed or not item.name then
		return "Bu brainrotun kimligi belli degil"
	end

	if item.mutation == arg then
		return `Zaten {Mutations.get(arg).displayName}`
	end

	item.mutation = arg

	-- Tool yeniden uretilir: model, isim ve efektler mutasyona gore degisir
	Envanter.syncBrainrots(player)

	local info = Mutations.get(arg)
	return `{item.name} -> {info.displayName} ({info.multiplier}x)`
end

--[[
	MUTASYON TESTI

	Mutasyon cekilisini 1000 kez calistirip dagilimi Output'a yazar.
	"Mutasyon hic gelmiyor" sikayetinin kaynagini kesinlestirir:
	burada dogru dagilim cikiyorsa cekilis calisiyor demektir, sorun
	baska yerdedir (ornegin brainrot siyah oldugu icin gorunmuyordur).
]]
function commands.testMutation(player, data)
	local counts: { [string]: number } = {}
	local rolls = 1000

	for _ = 1, rolls do
		local id = Mutations.roll(rng)
		counts[id] = (counts[id] or 0) + 1
	end

	print(`[ADMIN] {rolls} cekilis:`)
	for _, id in Mutations.Order do
		local n = counts[id] or 0
		print(string.format("  %-10s %4d  (%%%.1f)", id, n, n / rolls * 100))
	end

	local special = rolls - (counts.Normal or 0)
	return `{special}/{rolls} mutasyonlu -- ayrinti Output'ta`
end

--[[
	ISIK SUZMESI SPAWNLA

	Istenen kademede bir suzme dogurur: cekilis yok, sans yok, adet siniri
	yok. Amaci suzmelerin gorunumunu ve o kademedeki kazi zorlugunu istedigin
	an sinayabilmek -- yoksa Divine'i gormek icin saatlerce kazmak gerekirdi.

	arg: rarity kimligi ("Common".."Secret"), maden kimligi ya da "LuckyBlock"
]]
function commands.spawnBeam(player, data, arg)
	if type(arg) ~= "string" then
		return nil
	end

	local maden = Ores.get(arg)
	local valid = Rarity.Info[arg] ~= nil or arg == "LuckyBlock" or maden ~= nil
	if not valid then
		return nil
	end

	local beam = Beams.spawnKind(player, arg)
	if not beam then
		return "Suzme dogurulamadi -- karakterin yok mu?"
	end

	-- Maden: kaya dogar, adanin kazmasi gerekir
	if maden then
		local cfg = Ores.island(maden.island)
		local kazma = if cfg then Ores.Pickaxes[cfg.pickaxe] else nil
		return `{maden.displayName} kayasi dogdu -- {if kazma then kazma.displayName else "kazma"} gerekir`
	end

	local label = if Rarity.Info[arg] then Rarity.displayName(arg) else Rarity.LuckyBlock.displayName

	return `{label} suzmesi dogdu -- kuregi eline al ve kaz`
end

--[[
	HARITA RAPORU

	Oyunun haritada NE GORDUGUNU Output'a yazar: adalarin isinlanma
	noktalari, base'ler ve NPC'ler nerede duruyor, hangisi eksik.

	Harita Studio'da tasindiginda "kod eski konuma gonderiyor" mu yoksa
	"nesne hic bulunamiyor" mu -- bunu tahminle degil olcumle ayirmak icin.

	Kod nesneleri ISIMLE buluyor, koordinatla degil. Bu yuzden bir nesne
	tasindiginda kodda degistirilecek bir sey normalde YOKTUR; rapor da
	bunu dogrulamaya yariyor.
]]
local function vec(position: Vector3): string
	return string.format("%.1f, %.1f, %.1f", position.X, position.Y, position.Z)
end

local function anchorPosition(node: Instance?): Vector3?
	if not node then
		return nil
	end
	if node:IsA("BasePart") then
		return node.Position
	end
	if node:IsA("Model") then
		local part = node.PrimaryPart or node:FindFirstChildWhichIsA("BasePart", true)
		return if part then part.Position else nil
	end
	return nil
end

function commands.haritaRaporu(player, data)
	local eksik = 0

	print("========== HARITA RAPORU ==========")
	print("")
	print("ADALAR  (kod once spawn parcasina bakar, yoksa config konumuna duser)")

	for index, island in Config.Islands do
		local part = if island.spawnPartName
			then Workspace:FindFirstChild(island.spawnPartName, true)
			else nil
		local position = anchorPosition(part)

		if position then
			print(
				string.format(
					"  %d) %-14s %-16s BULUNDU   %s   (config: %s)",
					index,
					island.name,
					island.spawnPartName or "-",
					vec(position),
					vec(island.position)
				)
			)
		else
			eksik += 1
			print(
				string.format(
					"  %d) %-14s %-16s YOK!      config konumu kullanilacak: %s",
					index,
					island.name,
					island.spawnPartName or "-",
					vec(island.position)
				)
			)
		end
	end

	print("")
	print("BASE'LER  (isimle bulunur, konum kodda yazmaz)")

	--[[
		Arama BaseSistemi ile AYNI fonksiyondan geciyor (Bases.findFolder).
		Rapor baska turlu arasaydi oyunun gordugunden farkli bir sey
		soyleyebilirdi -- nitekim bir kez oyle oldu: rapor Workspace'in
		kokune bakiyordu, klasor ise adanin icindeydi.
	]]
	local bases = Bases.findFolder()

	if not bases then
		eksik += 1
		print(`  Workspace'in hicbir yerinde "{Bases.FolderName}" klasoru YOK!`)
	else
		print(`  Klasor yeri: {bases:GetFullName()}`)

		--[[
			Once klasorun ICINDE NE VAR onu yaz.

			BaseSistemi "Base1".."Base6" adlarini arar, bulamazsa klasordeki
			diger modelleri ada gore siralayip sirayla atar. Yani isimler
			farkli olsa da oyun calisabilir -- ama neyin ne oldugunu gormek
			icin once ham icerigi listelemek lazim.
		]]
		local children = bases:GetChildren()
		print(string.format("  Klasor icerigi: %d nesne", #children))

		for _, child in children do
			local position = anchorPosition(child)
			local slots = 0
			for _, node in child:GetDescendants() do
				if string.match(node.Name, "^Slot%d+$") then
					slots += 1
				end
			end

			print(
				string.format(
					"    %-16s %-12s %-24s %d slot",
					child.Name,
					child.ClassName,
					if position then vec(position) else "(parca yok)",
					slots
				)
			)
		end

		print("")
		print("  Beklenen adlar:")

		for index = 1, Bases.Count do
			local base = bases:FindFirstChild(`Base{index}`)
			if base then
				print(string.format("    Base%d  var", index))
			else
				eksik += 1
				print(string.format("    Base%d  YOK", index))
			end
		end
	end

	print("")
	print("NPC / NESNELER")

	local wanted = {
		Config.NPC.name,
		Config.NPC.altName,
		Config.Detective.name,
		Config.Seller.name,
		Config.Seller.altName,
		Config.Fuse.machineName,
		Config.Fuse.machineAltName,
		-- VFX ayari Shared > Fuse'da, Config.Fuse'da degil
		Fuse.VFX.name,
	}

	for _, name in wanted do
		if type(name) == "string" then
			local position = anchorPosition(Workspace:FindFirstChild(name, true))
			if position then
				print(string.format("  %-20s %s", name, vec(position)))
			end
		end
	end

	print("")
	print("===================================")

	return if eksik == 0
		then "Harita tamam -- ayrinti Output'ta"
		else `{eksik} nesne EKSIK -- ayrinti Output'ta`
end

--[[
	KUM RAPORU

	GPS kumun uzerinde kendiliginden ele geliyor; gelmiyorsa sebep ya
	zeminin malzemesi ya da adidir. Bu komut oyuncunun TAM O AN bastigi
	zemin hakkinda oyunun ne gordugunu Output'a yazar -- "algilamadi"
	sikayetini tahminden cikarip olcume cevirir.
]]
function commands.kumRaporu(player, data)
	local onSand, lines = Sand.report(player)

	print("========== KUM RAPORU ==========")
	for _, line in lines do
		print(line)
	end
	print("================================")

	return if onSand
		then "Kumdasin -- GPS elinde olmali"
		else "Kumda DEGILSIN -- sebep Output'ta"
end

--[[
	VFX RAPORU

	Suzme efektinin (Config.BeamVFX.name) icinde NE VAR, hepsini Output
	icine listeler: sinif, ad, renk ve HSV degerleri.

	Ne ise yarar: efektte gorunmesini istemedigin bir sey varsa -- ornegin
	ortadaki kucuk yesil nokta -- hangi nesne oldugunu buradan bulur,
	adini Config.BeamVFX.hide listesine yazip kaldirirsin.

	YESIL, cok parlak ve cok kucuk nesneler ayrica isaretlenir.
]]
local function hsvOf(color: Color3): string
	local h, s, v = color:ToHSV()
	return string.format("H=%.2f S=%.2f V=%.2f", h, s, v)
end

local function isGreenish(color: Color3): boolean
	local h, s, v = color:ToHSV()
	return h >= 0.22 and h <= 0.45 and s >= 0.35 and v >= 0.35
end

--[[
	GIZLI BRAINROT RAPORU

	Kimligi belirlenmemis brainrotlar duz kutu gorunuyorsa sebebi burada
	belli olur. Model Studio agacinda NEREDE olursa olsun bulunsun diye
	butun yaygin servisler taranir; ayrica Workspace'in dogrudan
	cocuklari da listelenir ki adin gercek yazilisi gozle gorulsun.
]]
function commands.gizliRaporu(player, data)
	local cfg = Assets.HiddenBrainrot

	print("========== GIZLI BRAINROT RAPORU ==========")
	print(`  Aranan ad : "{cfg.name}"`)
	print(`  Korunan   : "{cfg.keepPart}"`)
	print("")

	-- Adinda "hidden" gecen her sey, hangi serviste olursa olsun
	print("  Adinda \"hidden\" gecenler (tum servisler):")
	local seen = 0
	for _, root in Assets.searchRoots() do
		for _, node in root:GetDescendants() do
			if string.find(string.lower(node.Name), "hidden", 1, true) then
				seen += 1
				print(string.format("    %2d. %-14s %s", seen, node.ClassName, node:GetFullName()))
			end
		end
	end
	if seen == 0 then
		print("    (hicbiri)")
	end
	print("")

	--[[
		HER SATIR BENZERSIZ OLMALI

		Roblox Output ayni metinli satirlari tek satirda GRUPLAR ("(x5)"
		seklinde) ve gizler. Onceki raporda Water Block gibi tekrar eden
		nesneler bu yuzden hic gorunmedi. Bastaki sira numarasi her satiri
		benzersiz kildigi icin artik hicbiri gizlenmiyor.
	]]
	local kids = Workspace:GetChildren()
	print(`  Workspace'in dogrudan cocuklari ({#kids} adet):`)
	for index, node in kids do
		print(string.format("    %2d. %-14s %s", index, node.ClassName, node.Name))
	end
	print("")

	local model = Assets.hiddenBrainrotModel()

	if not model then
		print("  URETIM BASARISIZ -- yukaridaki listede modeli gor, adini")
		print("  Assets.HiddenBrainrot.name icine birebir yaz.")
		print("===========================================")
		return "Model uretilemedi -- ayrinti Output icinde"
	end

	local parts, keep = 0, 0
	for _, node in model:GetDescendants() do
		if node:IsA("BasePart") then
			parts += 1
			if node:GetAttribute(cfg.keepAttribute) then
				keep += 1
			end
		end
	end

	print("  URETIM BASARILI")
	print(`    BasePart sayisi        : {parts}`)
	print(`    Korunan ("{cfg.keepPart}") : {keep}`)

	if keep == 0 then
		print(`    UYARI: "{cfg.keepPart}" bulunamadi -- her sey kademe rengine boyanacak.`)
		print("    Modelin icindeki parca adlari:")
		for _, node in model:GetDescendants() do
			if node:IsA("BasePart") then
				print(`      {node.Name}`)
			end
		end
	end

	model:Destroy()
	print("===========================================")

	return `Model hazir ({parts} parca, {keep} korunan) -- ayrinti Output icinde`
end

function commands.vfxRaporu(player, data)
	local name = Config.BeamVFX.name
	local template = Assets.vfxTemplate(name)

	if not template then
		return `"{name}" bulunamadi -- Workspace ya da Assets > VFX icine koy`
	end

	print("========== VFX RAPORU ==========")
	print(`  Kok : {template.ClassName} "{template.Name}"`)
	print("")

	local flagged = 0
	local total = 0

	for _, node in template:GetDescendants() do
		total += 1

		local detail = ""
		local mark = ""

		if node:IsA("BasePart") then
			local size = node.Size
			detail = string.format(
				"renk=%d,%d,%d  %s  boyut=%.2f,%.2f,%.2f  %s",
				math.floor(node.Color.R * 255),
				math.floor(node.Color.G * 255),
				math.floor(node.Color.B * 255),
				hsvOf(node.Color),
				size.X,
				size.Y,
				size.Z,
				node.Material.Name
			)

			if isGreenish(node.Color) then
				mark = "   <-- YESIL"
				flagged += 1
			elseif math.max(size.X, size.Y, size.Z) <= 0.6 then
				mark = "   <-- cok kucuk"
				flagged += 1
			end
		elseif node:IsA("ParticleEmitter") or node:IsA("Trail") or node:IsA("Beam") then
			local first = node.Color.Keypoints[1].Value
			detail = string.format("ilk renk %s", hsvOf(first))

			if node:IsA("ParticleEmitter") then
				detail ..= string.format("  LightEmission=%.2f  Rate=%.1f", node.LightEmission, node.Rate)
			end

			if isGreenish(first) then
				mark = "   <-- YESIL"
				flagged += 1
			end
		elseif node:IsA("Light") then
			detail = string.format("%s  Brightness=%.1f  Range=%.1f", hsvOf(node.Color), node.Brightness, node.Range)
			if isGreenish(node.Color) then
				mark = "   <-- YESIL"
				flagged += 1
			end
		elseif node:IsA("Attachment") then
			detail = "(parcacik tutamagi -- kendisi gorunmez)"
		end

		print(string.format("  %-18s %-24s %s%s", node.ClassName, node.Name, detail, mark))
	end

	print("")
	print(`  Toplam {total} nesne, {flagged} tanesi isaretli`)
	print("  Kaldirmak icin adini Config.BeamVFX.hide listesine yaz.")
	print("================================")

	template:Destroy()

	return `{total} nesne listelendi, {flagged} isaretli -- ayrinti Output icinde`
end

-- Kazma verir: tek bir kazma id'si ya da "all"
function commands.givePickaxe(player, data, arg)
	if arg == "all" then
		for id in Ores.Pickaxes do
			data.pickaxes[id] = true
		end
		return "Butun kazmalar verildi"
	end

	if type(arg) ~= "string" or not Ores.Pickaxes[arg] then
		return nil
	end

	data.pickaxes[arg] = true
	return `{Ores.Pickaxes[arg].displayName} verildi`
end

--[[
	Maden verir (her tikta 10). arg bir maden id'si ise yalnizca o maden,
	bir ada id'si ise ("sekerkum") o adanin uc madeni birden.
]]
local MADEN_ADEDI = 10

function commands.giveOres(player, data, arg)
	if type(arg) ~= "string" then
		return nil
	end

	local cfg = Ores.island(arg)
	if cfg then
		for _, id in cfg.ores do
			PlayerData.addOre(player, id, MADEN_ADEDI)
		end
		return `{cfg.name}: her madenden +{MADEN_ADEDI}`
	end

	local maden = Ores.get(arg)
	if not maden then
		return nil
	end

	local adet = PlayerData.addOre(player, maden.id, MADEN_ADEDI)
	return `+{MADEN_ADEDI} {maden.displayName} (x{adet})`
end

function commands.setShovel(player, data, arg)
	if type(arg) ~= "string" or not Shovels.Info[arg] then
		return nil
	end

	data.shovel = arg
	-- Admin verdigi kademeyi kalici da yapar (satici listesinde gorunsun)
	if Shovels.get(arg :: any).level > Shovels.get(data.shovelMax :: any).level then
		data.shovelMax = arg
	end
	Envanter.giveShovel(player)
	return `Kurek: {Shovels.get(arg).displayName}`
end

function commands.setRod(player, data, arg)
	if type(arg) ~= "string" or not Rods.exists(arg) then
		return nil
	end

	data.rod = arg
	if Rods.level(arg) > Rods.level(data.rodMax) then
		data.rodMax = arg
	end

	-- Yalnizca flyboardla denizdeyse ele gelir; karada olta elde durmaz
	if player:GetAttribute("Flyboarding") == true then
		Envanter.removeRod(player)
		Envanter.equipRod(player)
	end

	local info = Rods.get(arg)
	return `Olta: {if info then info.displayName else arg}`
end

function commands.setFlyboard(player, data, arg)
	if type(arg) ~= "string" or not Flyboard.exists(arg) then
		return nil
	end

	data.flyboard = arg
	if Flyboard.level(arg) > Flyboard.level(data.flyboardMax) then
		data.flyboardMax = arg
	end
	local info = Flyboard.get(arg)
	return `Flyboard: {if info then info.displayName else arg}`
end

function commands.setDetector(player, data, arg)
	if type(arg) ~= "string" or not Detectors.Info[arg] then
		return nil
	end

	data.detector = arg
	if Detectors.get(arg :: any).level > Detectors.get(data.detectorMax :: any).level then
		data.detectorMax = arg
	end
	Envanter.giveGPS(player)
	return `Dedektor: {Detectors.get(arg).displayName}`
end

--[[
	SCRIPT RAPORU

	Bizim kodumuz yalnizca ServerScriptService, StarterPlayerScripts ve
	ReplicatedStorage > Shared icinde. Bunlarin DISINDAKI butun scriptler
	(haritaya ya da modellere gomulu olanlar) Output'a yazilir. Hazir
	modellerle gelen, hata veren ya da disaridan modul yukleyen (require)
	scriptleri bulup silmek icin.
]]
function commands.scriptRaporu(player, data)
	local ServerScriptService = game:GetService("ServerScriptService")
	local StarterPlayer = game:GetService("StarterPlayer")
	local bizim = {
		ServerScriptService,
		StarterPlayer:FindFirstChild("StarterPlayerScripts"),
		ReplicatedStorage:FindFirstChild("Shared"),
	}

	local function bizimMi(node: Instance): boolean
		for _, kok in bizim do
			if kok and node:IsDescendantOf(kok) then
				return true
			end
		end
		return false
	end

	local kokler = {
		Workspace,
		ReplicatedStorage,
		game:GetService("ServerStorage"),
		game:GetService("StarterGui"),
		game:GetService("StarterPack"),
		game:GetService("Lighting"),
		game:GetService("SoundService"),
		StarterPlayer,
	}

	local bulunan = {}
	for _, kok in kokler do
		for _, node in kok:GetDescendants() do
			if node:IsA("LuaSourceContainer") and not bizimMi(node) then
				table.insert(bulunan, `  {node.ClassName}  {node:GetFullName()}`)
			end
		end
	end

	print(`[Admin] Bizim klasorlerimiz disindaki scriptler ({#bulunan}):`)
	for _, satir in bulunan do
		print(satir)
	end
	return `{#bulunan} yabanci script -- liste Output'ta`
end

-- Robux gecisini bu oturum icin ver / geri al (kayda yazilmaz)
function commands.togglePass(player, data, arg)
	local info = if type(arg) == "string" then Passler.get(arg) else nil
	if not info then
		return nil
	end
	local yeni = not Passler.sahip(player, arg)
	player:SetAttribute(info.nitelik, yeni)
	return `{info.ad}: {if yeni then "VERILDI" else "ALINDI"} (bu oturum)`
end

--[[
	Hiz scriptine "yeniden uygula" der. Script bulunamazsa sorun degil:
	Hiz scripti yarim saniyede bir veriyi kontrol edip kendisi uygular.
	Yurume hizi burada da hemen yazilir ki fark aninda hissedilsin.
]]
local function hiziYenile(player: Player)
	local data = PlayerData.get(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if data and humanoid then
		local hiz = Hiz.hiz(data.speedLevel)
		if humanoid:GetAttribute("FlyboardTabanHiz") ~= nil then
			humanoid:SetAttribute("FlyboardTabanHiz", hiz)
		else
			humanoid.WalkSpeed = hiz
		end
	end

	local betik = script.Parent:FindFirstChild("Hiz")
	local olay = betik and betik:FindFirstChild("HizYenile")
	if olay and olay:IsA("BindableEvent") then
		olay:Fire(player)
	end
end

-- Hiz rebirth sayisini ayarla (0..Hiz.MaxRebirth)
function commands.setRebirth(player, data, arg)
	local adet = tonumber(arg)
	if not adet then
		return nil
	end
	data.speedRebirth = math.clamp(math.floor(adet), 0, Hiz.MaxRebirth)
	hiziYenile(player)
	return `Hiz rebirth: {data.speedRebirth}`
end

-- Hiz yukseltmesi sayisini ayarla (0..100)
function commands.setSpeed(player, data, arg)
	local adet = tonumber(arg)
	if not adet then
		return nil
	end
	data.speedLevel = math.clamp(math.floor(adet), 0, Hiz.Max)
	hiziYenile(player)
	return `Hiz: Speed {data.speedLevel + 1} (x{string.format("%.1f", Hiz.carpan(data.speedLevel))})`
end

function commands.clearInventory(player, data)
	local count = #data.inventory
	table.clear(data.inventory)

	Envanter.syncBrainrots(player)
	-- Base'e yerlestirilmis olanlarin sahnedeki modelleri de kaldirilir
	baseYenile:Fire(player)

	return `{count} brainrot silindi`
end

------------------------------------------------------------------
-- BAGLANTILAR
------------------------------------------------------------------
AdminKomut.OnServerEvent:Connect(function(player, command, arg)
	-- Panel gorunmese bile yetki burada tekrar dogrulanir
	if not isAdmin(player) then
		return
	end

	if type(command) ~= "string" then
		return
	end

	local handler = commands[command]
	if not handler then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	--[[
		Komut hatasi SESSIZCE yutulmasin.

		Bir komut calisirken hata verdiginde eskiden butun olay isleyicisi
		duruyordu: panelde tiklarsin, hicbir sey olmaz, Output icinde de
		yalnizca ham bir yigin izi belirirdi. Artik hata yakalanip
		ekranda kirmizi bir bildirim olarak gosteriliyor -- "calismiyor"
		ile "hata veriyor" birbirinden ayrilabiliyor.
	]]
	local ok, message = pcall(handler, player, data, arg)

	if not ok then
		warn(`[ADMIN] "{command}" hata verdi -- {tostring(message)}`)
		Bildirim:FireClient(player, `[ADMIN] {command} HATA: {tostring(message)}`, Color3.fromRGB(255, 90, 90))
		return
	end

	Envanter.push(player)

	if message then
		Bildirim:FireClient(player, `[ADMIN] {message}`, Color3.fromRGB(255, 214, 41))
	end
end)

-- Oyuncuya yetkisini bildirir; client paneli buna gore acar
local function announce(player: Player)
	task.wait(1)
	if not player.Parent then
		return
	end

	AdminPanelAc:FireClient(player, {
		allowed = isAdmin(player),
		rotGrant = A.rotGrant,
		shovels = Shovels.Order,
		detectors = Detectors.Order,
		flyboards = Flyboard.Order,
		rods = Rods.Order,
		rarities = Rarity.Order,
	})
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(announce, player)
end)

for _, player in Players:GetPlayers() do
	task.spawn(announce, player)
end
