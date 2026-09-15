--[[
	KaziSistemi  (Script)
	Yeri: ServerScriptService > KaziSistemi

	Kazi akisi:
	  1. GPS her zaman cantadadir. Oyuncu onu ELINE ALIR.
	  2. GPS elde + ayak kumdayken etrafta ISIK SUZMELERI dogar.
	     GPS elde degilken YENI suzme cikmaz, ama var olanlar yerinde kalir
	     -- kazmak icin kuregi eline almak gerekiyor.
	  3. Suzmenin rengi icinden cikacak brainrot'un rarity'sini gosterir.
	  4. Oyuncu KUREGI ELINE ALIP suzmeye yaklasir ve kazar -> minigame acilir.
	  5. Kazanilirsa brainrot SIMSIYAH bir Tool olarak cantaya girer;
	     hangi brainrot oldugu Brainrot Detective acana kadar gizlidir.

	Kum artik dogrudan kazilmaz -- yalnizca suzmeler kazilir.
	Binde bir cikan sari-siyah suzmeden Rot Coin cikar.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Condition = require(Shared:WaitForChild("Condition"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Detectors = require(Shared:WaitForChild("Detectors"))
local Rods = require(Shared:WaitForChild("Rods"))
local DigMinigame = require(Shared:WaitForChild("DigMinigame"))
local KaziMinigame = require(Shared:WaitForChild("KaziMinigame"))
local Net = require(Shared:WaitForChild("Net"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Sand = require(Modules:WaitForChild("Sand"))
local Tools = require(Modules:WaitForChild("Tools"))
local Olta = require(Modules:WaitForChild("Olta"))
local Beams = require(Modules:WaitForChild("Beams"))
local LuckyBlockOdul = require(Modules:WaitForChild("LuckyBlockOdul"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Ores = require(Shared:WaitForChild("Ores"))
local Envanter = require(Modules:WaitForChild("Envanter"))
local GorevTakip = require(Modules:WaitForChild("GorevTakip"))
local Patlama = require(Modules:WaitForChild("Patlama"))
local Arkadaslar = require(Modules:WaitForChild("Arkadaslar"))
local Seviye = require(Modules:WaitForChild("Seviye"))

local Bildirim = Net.event("Bildirim")
local GPSGuncelle = Net.event("GPSGuncelle")
local SuzmeKaz = Net.event("SuzmeKaz")
local MinigameBasla = Net.event("MinigameBasla")
local MinigameSonuc = Net.event("MinigameSonuc")
local KaziBitti = Net.event("KaziBitti")

local D = Config.Dig

--[[
	KESIF NITELIGI

	Oyuncu su an "kesifte" mi: kumda GPS ile ya da denizde olta ile arama
	yapiyor mu. Sunucu karar verir, ISTEMCI de okur (bkz.
	StarterPlayerScripts > KesifKisiti) -- boylece yasak esya bir kare bile
	gorunmeden geri gonderilir.
]]
local KESIF_NITELIGI = "KesifKisiti"
local G = Config.GPS

local rng = Random.new()

-- Suren kazilar: [player] = { beamId, startedAt, gearId, rarityId, startPos, sea }
local digging: { [Player]: any } = {}
local lastDig: { [Player]: number } = {}

--[[
	GIRDAP HIZI

	Iki girdap dogumu arasinda en az bu kadar saniye gecer: hepsi bir anda
	dolmasin, oyuncu gezdikce yenisi cikmis gibi olsun.
]]
local GIRDAP_ARASI = 4
local lastWhirl: { [Player]: number } = {}

-- Teshis yazisi bir kez cikar (ilk basarili girdaptan sonra susar)
local girdapBildirildi = false

--[[
	Toplam sans carpani = ZEMIN bonusu * dedektor seviyesi.

	Zemin bonusu ada konumuna degil, ustunde DURULAN parcanin adina bakar
	(Config.Sand.luckByName). Ornegin "VolkanKum" adli zemin x3 verir.
	Boylece bonus adanin neresinde durdugunla degil, gercekten o kumun
	uzerinde olup olmadiginla belirlenir.

	Ust kademeler bu carpandan ustel olarak etkilenir (bkz. Rarity.rollBeam),
	yani Lv5 dedektor + volkan kumu Secret'i gercekten bulunabilir kilar.
]]
local function luckFor(player: Player): number
	local ground = Sand.luckUnder(player)

	local data = PlayerData.get(player)
	local detector = if data then Detectors.get(data.detector :: any) else Detectors.get(Detectors.Default)

	--[[
		Gecici sans carpani ve ARKADAS BUFFI da hesaba katilir: ayni sunucuda
		Roblox arkadasi varsa x1.15 (bkz. Modules > Arkadaslar).
	]]
	-- Level bonusu da kalici carpan olarak eklenir (her level +%1, bkz. Shared > Seviye)
	return ground * detector.luck * PlayerData.luckBonus(player) * Arkadaslar.carpan(player) * Seviye.carpan(player)
end

-- Oyuncunun dedektorune gore tarama ayarlari
local function detectorFor(player: Player): Detectors.DetectorInfo
	local data = PlayerData.get(player)
	local id = if data then data.detector else Detectors.Default
	return Detectors.get(id :: any)
end

-- Oyuncunun kusandigi olta; yoksa nil (denizde girdap dogmaz)
local function rodFor(player: Player): Rods.RodInfo?
	local data = PlayerData.get(player)
	return if data then Rods.get(data.rod) else nil
end

------------------------------------------------------------------
-- OTOMATIK EKIPMAN
--
-- Kurek ve GPS artik CANTAYA HIC GIRMIYOR. Elde ne olmasi gerektigine
-- burasi karar veriyor ve tek yerden uyguluyor:
--
--     kaziyorsa                 -> kurek
--     elinde brainrot/coin var  -> karisilmaz (esyasini tasiyor)
--     ayagi kumdaysa            -> GPS, ve orada KALIR
--     digeri                    -> ikisi de kalkar
--
-- "Kum" tanimi Config.Sand'dan geliyor: adinda "kum" ya da "sand" gecen
-- her parca sayilir. Yani KarKum, SekerKum, GizliKum, BuzKum... hepsi
-- kendiliginden kapsama girer, buraya isim yazmaya gerek yok.
------------------------------------------------------------------

--[[
	Oyuncunun EN SON kumda gorundugu an.

	GPS bu yuzden kumdan cikar cikmaz inmiyor: ziplamak, kenardan bir an
	tasmak ya da egimde havada kalmak Humanoid'in zemin bildirmemesine yol
	aciyor ve oyuncu bir kare boyunca "kumda degil" sayiliyor. Cikistan
	Config.Dig.autoUnequipDelay saniye gecmeden GPS elden alinmaz.
]]
local lastOnSand: { [Player]: number } = {}

local function otoEkipman(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return
	end

	--[[
		Kazi suruyorsa kurek elde kalir, baska hicbir sey karismaz.

		DENIZ ISTISNASI: girdap kaziliyorsa oyuncu flyboardda ve elinde OLTA
		var; kurege gecmek tahtadaki gorunumu bozardi, olta elde kalir.
	]]
	local oturum = digging[player]
	if oturum then
		-- Kazi sirasinda da elde baska bir sey duramaz
		player:SetAttribute(KESIF_NITELIGI, true)
		if oturum.pickaxeId then
			-- Maden kazisi: elde kazma durur
			Envanter.equipPickaxe(player, oturum.pickaxeId)
		elseif not oturum.sea then
			Envanter.equipShovel(player)
		end
		return
	end

	--[[
		Tahtadayken elde olta durur; kum kurallari denize karismaz.

		Kesif kisiti DENIZDE DE gecerli: olta elindeyken cantadan brainrot
		ya da lucky block kusanilamaz.
	]]
	if Olta.has(player) then
		player:SetAttribute(KESIF_NITELIGI, true)
		return
	end

	local now = os.clock()

	--[[
		KUMDA HER ZAMAN GPS

		Elinde brainrot, coin ya da lucky block olsa bile kuma basildigi
		anda GPS ele gecer. Onceden tasidigin esyaya oncelik veriliyordu;
		istenen davranis bu degil -- kumun uzeri arama alani, orada elde
		baska bir sey durmuyor.

		Tool degistirmeyi asil engelleyen sey toolEngelle; burasi yalnizca
		GPS'in elde olmasini garantiler.
	]]
	if Sand.isOnSand(player) then
		lastOnSand[player] = now
		player:SetAttribute(KESIF_NITELIGI, true)
		Envanter.equipGPS(player)
		return
	end

	--[[
		Kumdan cikti ama sure dolmadi: GPS elde kalmaya devam eder.
		Boylece zipladiginda ya da kumun kenarindan bir adim tastiginda
		esya elinden dusmez. Kisit da bu sure boyunca surer.
	]]
	local left = lastOnSand[player]
	if left and now - left < D.autoUnequipDelay then
		return
	end

	lastOnSand[player] = nil
	player:SetAttribute(KESIF_NITELIGI, false)
	Envanter.unequipTools(player)
end

------------------------------------------------------------------
-- KAZIDA KARAKTER SABIT
--
-- Kumda kurekle, madende kazmayla ve denizde oltayla kazi boyunca oyuncu
-- yerinden kipirdayamaz: kok parcasi (HumanoidRootPart) sabitlenir, kazi
-- bitince birakilir. Kumda ve madende karakter once kazilan noktaya doner.
-- Sabitlemeyi sunucu yapar; animasyonlar sabit kokte de oynar.
------------------------------------------------------------------
local sabitlenen: { [Player]: BasePart } = {}

local function sabitle(player: Player, root: BasePart, hedef: Vector3?)
	if sabitlenen[player] then
		return
	end

	if hedef then
		local bakis = Vector3.new(hedef.X, root.Position.Y, hedef.Z)
		if (bakis - root.Position).Magnitude > 0.5 then
			root.CFrame = CFrame.lookAt(root.Position, bakis)
		end
	end

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.Anchored = true
	sabitlenen[player] = root
end

local function serbestBirak(player: Player)
	local root = sabitlenen[player]
	sabitlenen[player] = nil
	if root and root.Parent then
		root.Anchored = false
	end
end

------------------------------------------------------------------
-- KAZI
------------------------------------------------------------------
local function finishDig(player: Player, won: boolean)
	local session = digging[player]
	if not session then
		return
	end
	digging[player] = nil
	lastDig[player] = os.clock()

	-- Karakter yeniden hareket edebilir
	serbestBirak(player)

	-- Atilan misina toplanir (girdap kazisiysa zaten vardir)
	local karakter = player.Character
	if karakter then
		Olta.reel(karakter)
		-- Kazma hareketi durur
		karakter:SetAttribute("Kaziyor", nil)
		karakter:SetAttribute("KaziHedef", nil)
	end

	local beam = Beams.get(session.beamId)
	KaziBitti:FireClient(player)

	-- Kurek isini bitirdi: kumdaysa GPS hemen geri gelsin, dongu beklemesin
	otoEkipman(player)

	if not beam then
		return
	end

	Beams.remove(session.beamId, if won then "kazi kazanildi" else "kazi kaybedildi")

	--[[
		KUMDA KAZANINCA PATLAMA

		Gorev odulundeki (Quests > Collect) efektin AYNISI: Workspace'teki
		FuseVFX, kazilan brainrotun kademe renginde. Denizde yok -- orada
		zaten misina/girdap gosterisi var.

		Efekt kaybetmede oynamaz; sonuc bildirimlerinden once cagriliyor ki
		gorsel ile yazi ayni ana denk gelsin.
	]]
	local maden = Ores.get(beam.kind)

	if won and not session.sea and not maden then
		Patlama.oynat(player, beam.kind)
	end

	if not won then
		local kayip = if maden then `The {maden.displayName} crumbled!` else "The brainrot got away!"
		Bildirim:FireClient(player, kayip, Color3.fromRGB(255, 120, 120))
		return
	end

	-- Oyuncunun ulastigi ada: Lucky Block / odul / Fuse havuzlari buna bakar
	PlayerData.reachIsland(player, beam.island)

	-- Maden: hesaba eklenir, brainrot akisina girmez
	if maden then
		local adet = PlayerData.addOre(player, maden.id, Ores.MineAmount)
		Seviye.xpVer(player, Seviye.XP.ore)
		Envanter.push(player)
		Bildirim:FireClient(player, `+{Ores.MineAmount} {maden.displayName} (x{adet})`, maden.color)
		return
	end

	-- Lucky Block suzmesi: siyah yumurta degil, acilmayi bekleyen bir blok
	if beam.kind == "LuckyBlock" then
		-- Hangi turun ciktigi burada belirlenir (Normal / Altin / Elmas)
		local tierId = LuckyBlock.rollTier(rng)
		local tier = LuckyBlock.get(tierId)

		PlayerData.addLuckyBlocks(player, tierId, 1)
		Envanter.syncLuckyBlocks(player)
		Envanter.push(player)
		LuckyBlockOdul.showDrop(beam.position, tierId)

		Bildirim:FireClient(
			player,
			`{string.upper(tier.displayName)} found! (x{PlayerData.luckyBlockCount(player, tierId)})`,
			tier.color
		)
		return
	end

	-- Brainrot: simsiyah bir Tool olarak cantaya girer
	local condition = Condition.roll(rng)
	-- Mutasyon da burada belirlenir ama Detective acana kadar gizli kalir
	local mutation = Mutations.roll(rng)
	-- Ada esyayla birlikte tasiniyor: ismi Detective SECERKEN kullanilacak
	local item = PlayerData.addBrainrot(player, beam.kind, condition, mutation, beam.island)
	if not item then
		return
	end

	Envanter.syncBrainrots(player)
	Envanter.push(player)

	-- Gorev panosu: hem "kaz" hem de kademe gorevleri bu kazidan sayar
	GorevTakip.ilerlet(player, "dig", 1)
	GorevTakip.ilerlet(player, "collect", 1, beam.kind)
	-- Level: kazilan brainrotun kademesine gore XP
	Seviye.xpVer(player, Seviye.rarityXp(beam.kind))
end

local function startDig(player: Player, beamId: string)
	if digging[player] then
		return
	end

	local now = os.clock()
	if lastDig[player] and now - lastDig[player] < D.cooldown then
		return
	end

	local beam = Beams.get(beamId)
	if not beam or beam.owner ~= player or beam.claimed then
		return
	end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	--[[
		Girdaba olta UZAKTAN atilir, suzmeye ise sokulmak gerekir.
		Ikisinin payi ayri (bkz. OyunConfig > GPS).
	]]
	local erisim = if beam.sea then G.seaDigDistance else G.digDistance

	if (beam.position - root.Position).Magnitude > erisim then
		local uyari = if beam.sea then "Get closer to the whirlpool!" else "Get closer to the beam!"
		Bildirim:FireClient(player, uyari, Color3.fromRGB(255, 160, 60))
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	--[[
		MADEN, ADANIN KAZMASI YA DA DAHA ILERI BIR ADANIN KAZMASIYLA KAZILIR

		Ust kademe kazma alt adalarin madenlerini de kirar: madenin adasindan
		son adaya kadar (Ores.IslandOrder) oyuncunun sahip oldugu EN ILERI
		kazma secilir ve ele o verilir. Maden zorlugu kazmadan degil madenin
		sabit hizindan gelir (bkz. KaziMinigame), yani iyi kazma zorlugu bozmaz.

		Uygun kazmasi yoksa maden yerinde kalir (claimed olmaz), oyuncuya
		hangi kazmayi alacagi yazilir.
	]]
	local maden = Ores.get(beam.kind)
	local pickaxeId: string? = nil
	if maden then
		local gerekenSira = table.find(Ores.IslandOrder, maden.island)
		local gerekenAda = Ores.island(maden.island)

		if gerekenSira then
			for i = #Ores.IslandOrder, gerekenSira, -1 do
				local ada = Ores.island(Ores.IslandOrder[i])
				local aday = if ada then ada.pickaxe else nil
				if aday and PlayerData.hasPickaxe(player, aday) then
					pickaxeId = aday
					break
				end
			end
		end

		if not pickaxeId then
			local gereken = if gerekenAda then Ores.Pickaxes[gerekenAda.pickaxe] else nil
			local kazmaAdi = if gereken then gereken.displayName else "the right pickaxe"
			Bildirim:FireClient(player, `You need the {kazmaAdi} (or a better one) to mine {maden.displayName}!`, maden.color)
			return
		end
	end

	beam.claimed = true

	-- Kazi boyunca karakter yerinde sabit (denizde de); kumda ve madende kazilan noktaya doner
	sabitle(player, root :: BasePart, if beam.sea then nil else beam.position)

	--[[
		Kurek oyuncunun elinde DEGILDIR -- cantada da durmuyor. Suzmeye
		tiklamak zaten "kazmak istiyorum" demek oldugu icin kuregi burada
		eline veriyoruz; GPS onun yerini birakir, kazi bitince geri gelir.

		GIRDAPTA DEGISMEZ: oyuncu tahtada ve elinde olta var, minigame
		zorlugunu yine kurek belirliyor ama elindeki olta kaliyor.
	]]
	if beam.sea then
		-- Olta savrulur: misina animasyonun ortasinda birakilip girdaba duser
		if char then
			Olta.cast(char, beam.position)
		end
	elseif pickaxeId then
		Envanter.equipPickaxe(player, pickaxeId)
	else
		Envanter.equipShovel(player)
	end

	--[[
		MINIGAME'I ELDEKI EKIPMAN BELIRLER

		Kumda KUREK, denizde OLTA. Denizde kuregin seviyesi hic isin icine
		girmez: girdabi yakalama kolayligi tamamen olta kademesinden gelir
		(bkz. Shared > DigMinigame > gear).
	]]
	-- Madende kazma: zorluk madenin sabit hizindan gelir (bkz. KaziMinigame)
	local gearId = if beam.sea then (data.rod or Rods.Order[1]) elseif pickaxeId then pickaxeId else data.shovel
	local gear = DigMinigame.gear(gearId)

	--[[
		PENCERE NE ZAMAN ACILIR

		Kumda kurek belirler: iyi kurek daha cabuk kazmaya baslar.
		DENIZDE savurma animasyonu belirler -- pencere, olta savrulup misina
		suya dustukten sonra acilmali. Bu yuzden sure sabit (Rods.CastTime)
		ve olta kademesi onu degistirmez; yoksa iyi oltada pencere
		animasyonun ortasinda acilirdi.
	]]
	--[[
		KARADA BEKLEME YOK: alet ele gelir gelmez kazi animasyonu baslar.
		Eskiden burada yarim saniye bekleniyordu ve karakter o sure boyunca
		kuregi animasyonsuz, duz tutuyordu.
	]]
	local prepare = if beam.sea then Rods.CastTime else 0
	local _ = gear

	digging[player] = {
		beamId = beamId,
		startedAt = now,
		-- Deniz girdabi mi: ekipman kurallari buna gore degisiyor
		sea = beam.sea == true,
		gearId = gearId,
		rarityId = beam.kind,
		startPos = root.Position,
		-- Maden kazisinda elde tutulacak kazma (otomatik ekipman buna bakar)
		pickaxeId = pickaxeId,
	}

	--[[
		KAZMA HAREKETI: karakter "Kaziyor" niteligini tasidigi surece istemciler
		kolu kaldirip kuregi yere vurduruyor (bkz. StarterPlayerScripts >
		KaziHareketi). Denizde olta savruluyor, orada yazilmaz.
	]]
	if not beam.sea and player.Character then
		player.Character:SetAttribute("Kaziyor", true)
		-- Kazilan nokta: karakter kazi boyunca buraya donuk durur
		player.Character:SetAttribute("KaziHedef", beam.position)
	end

	task.wait(prepare)

	local session = digging[player]
	if not session or session.beamId ~= beamId then
		return
	end

	-- Lucky Block icin minigame yok, dogrudan kazanilir
	if beam.kind == "LuckyBlock" then
		finishDig(player, true)
		return
	end

	local seed = rng:NextInteger(1, 2 ^ 30)
	session.seed = seed
	-- Mod istemciye ACIKCA gonderiliyor: kumda tiklama oyunu, denizde bar oyunu
	MinigameBasla:FireClient(player, gearId, beam.kind, seed, if beam.sea then "sea" else "sand")

	-- Client sonuc gondermezse (cokme, kacis, kapatma) oturum takili kalmasin;
	-- yoksa oyuncu bir daha hic kazamaz.
	task.delay(D.minigameTimeout, function()
		local stuck = digging[player]
		if stuck and stuck.beamId == beamId then
			finishDig(player, false)
		end
	end)
end

------------------------------------------------------------------
-- REMOTE BAGLANTILARI
------------------------------------------------------------------
SuzmeKaz.OnServerEvent:Connect(function(player, beamId)
	if type(beamId) ~= "string" then
		return
	end
	task.spawn(startDig, player, beamId)
end)

MinigameSonuc.OnServerEvent:Connect(function(player, won)
	local session = digging[player]
	if not session then
		return
	end

	local elapsed = os.clock() - session.startedAt
	if elapsed > D.minigameTimeout then
		finishDig(player, false)
		return
	end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local pay = if session.sea then D.seaMoveDistance else D.maxMoveDistance
	if not root or (root.Position - session.startPos).Magnitude > pay then
		finishDig(player, false)
		return
	end

	--[[
		MACRO / EXPLOIT KONTROLU  --  yalnizca kumda

		Kumdaki minioyun tiklama tabanli ve istemci "kazandim" diyor. Iki sey
		bagimsiz olarak dogrulaniyor:

		  1. ERISILEBILIRLIK. Kurek kademeye yetmiyorsa imlec matematiksel
		     olarak dolamaz (bkz. Shared > KaziMinigame). Boyle bir zaferin
		     dogru olma ihtimali yok.

		  2. SURE. Insan elinin ustu sayilan MAX_CPS ile bile minioyun belli
		     bir sureden once bitirilemez. %15 pay birakildi: ilk tiklamalar
		     kovadaki hazir jetonlari harcadigi icin gercek sure teorik alt
		     sinirin biraz altina inebiliyor.

		Denizde bu kontrol yok -- orasi basili tutma oyunu.
	]]
	if not session.sea and won == true then
		local enHizli = KaziMinigame.minDuration(session.gearId, session.rarityId)

		if enHizli == math.huge then
			warn(
				`[Kazi] {player.Name} erisilemez bir kademeyi kazandi dedi `
					.. `({session.gearId} ile {session.rarityId}), reddedildi`
			)
			finishDig(player, false)
			return
		end

		local altSinir = enHizli * 0.85
		if elapsed < altSinir then
			warn(
				`[Kazi] {player.Name} minioyunu imkansiz surede bitirdi `
					.. `({string.format("%.2f", elapsed)}s < {string.format("%.2f", altSinir)}s), reddedildi`
			)
			finishDig(player, false)
			return
		end
	end

	finishDig(player, won == true)
end)

------------------------------------------------------------------
-- OTOMATIK EKIPMAN DONGUSU
--
-- Tarama dongusunden AYRI ve ondan cok daha sik calisir: oyuncu kuma
-- adim attiginda GPS'in elinde belirmesi aninda olmali, 1.5 saniye
-- sonra degil.
------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(D.autoEquipInterval)

		for _, player in Players:GetPlayers() do
			-- Bir oyuncudaki hata digerlerini durdurmasin
			local ok, err = pcall(otoEkipman, player)
			if not ok then
				warn(`[Kazi] {player.Name}: otomatik ekipman hata verdi -- {tostring(err)}`)
			end
		end
	end
end)

------------------------------------------------------------------
-- GPS TARAMA DONGUSU
--
-- YENI suzme yalnizca GPS ELDEYKEN ve ayak kumdayken dogar.
-- Bir kez dogan suzme, GPS elden inse bile yerinde kalir -- cunku kazmak
-- icin kuregi eline almak gerekiyor ve o an GPS zorunlu olarak iniyor.
-- Suzmeler kendi omurleri (Config.GPS.beamLifetime) dolunca sonuyor.
------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(G.scanInterval)

		Beams.cleanup()

		for _, player in Players:GetPlayers() do
			local gpsInHand = Tools.equipped(player, Tools.GPSName) ~= nil
			-- Denizde tahtadaysa balikcilik acik (bkz. Flyboard.server)
			local rodInHand = player:GetAttribute("Flyboarding") == true
			local rod = rodFor(player)

			if gpsInHand and not digging[player] and Sand.isOnSand(player) then
				local detector = detectorFor(player)

				-- Suzme sansi ve limiti dedektor seviyesinden gelir
				if rng:NextNumber() * 100 <= detector.spawnChance then
					Beams.trySpawn(player, luckFor(player), rng, detector.maxBeams)
				end
			end

			--[[
				DENIZ: GIRDAPLAR

				Kumdaki kurallarin aynisi, iki fark var: olta elde olacak
				(flyboardla denizdeyken kendiliginden veriliyor) ve sans ile
				limit DEDEKTORDEN degil OLTADAN geliyor.
			]]
			if rodInHand and rod and not digging[player] then
				--[[
					GIRDAPLAR TEKER TEKER GELIR

					Iki dogum arasinda en az GIRDAP_ARASI saniye var: kumdaki
					suzmeler gibi hepsi bir anda dolmasin, oyuncu gezdikce
					yenisi cikmis gibi olsun.
				]]
				local simdi = os.clock()
				local sonGirdap = lastWhirl[player] or 0

				if simdi - sonGirdap >= GIRDAP_ARASI and rng:NextNumber() * 100 <= rod.spawnChance then
					if Beams.trySpawnSea(player, rod.luck * (G.seaLuck or 1), rng, rod.maxWhirls, rod.scanRadius) then
						lastWhirl[player] = simdi
						girdapBildirildi = true
					elseif not girdapBildirildi then
						--[[
							TESHIS

							Olta elde ve sira geldi ama girdap dogmadi: cevrede su
							bulunamadi demektir. Bir kez yazilir; ilk basarili
							dogumdan sonra bir daha cikmaz.
						]]
						girdapBildirildi = true
						warn(
							"[Girdap] Su bulunamadi: deniz parcalarinin adinda "
								.. "deniz/sea/ocean/water/su geciyor mu, isin onlara carpiyor mu?"
						)
					end
				end
			end

			--[[
				Mevcut suzmeler her durumda gonderilir; kurek eldeyken de
				kazilabilmeleri icin client listesinin dolu kalmasi sart.

				Tarama yaricapi elde ne varsa ondan gelir: olta varsa oltanin,
				yoksa dedektorun.
			]]
			local yaricap = if rodInHand and rod then rod.scanRadius else detectorFor(player).scanRadius
			GPSGuncelle:FireClient(player, Beams.snapshotFor(player, yaricap))
		end
	end
end)

------------------------------------------------------------------
-- OYUNCU BAGLANTILARI
------------------------------------------------------------------
--[[
	KESIF SIRASINDA ELDE BASKA SEY DURMAZ

	Kumda GPS, denizde olta elde kalir. Oyuncu cantadan brainrot, coin ya
	da lucky block kusanirsa esya ELINE HIC GECMEDEN geri gonderilir ve
	sebebi yazilir.

	Eskiden bunu yalnizca tarama dongusu yapiyordu (1.5 saniyede bir):
	esya bir sure elde kaliyor, sonra kendiliginden geri gidiyordu --
	oyuncu neden oldugunu anlamiyordu. Ve kural DENIZDE hic yoktu.

	Burasi ChildAdded ile ANINDA tepki verir. Istemci tarafinda da ayni
	kontrol var (bkz. StarterPlayerScripts > KesifKisiti): oradaki tepki
	ag gecikmesini beklemedigi icin esya bir kare bile gorunmez.

	IZINLI ESYALAR nitelikten taniniyor: kurek ShovelId, GPS DetectorId
	tasiyor. Ada adlari gibi isimle karsilastirmak kirilgan olurdu.
]]
local UYARI_ARASI = 2
local sonUyari: { [Player]: number } = {}

local function kesifAraciMi(tool: Tool): boolean
	return tool:GetAttribute("ShovelId") ~= nil
		or tool:GetAttribute("DetectorId") ~= nil
		or tool:GetAttribute("PickaxeId") ~= nil
end

local function toolEngelle(player: Player, tool: Tool)
	if not player:GetAttribute(KESIF_NITELIGI) or kesifAraciMi(tool) then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:UnequipTools()
	end

	--[[
		Kumda GPS elden dusmus olur (Roblox yeni tool kusanilinca eskisini
		birakir); hemen geri veriliyor ki oyuncunun eli bir an bos kalmasin.
		Denizde olta bir Tool DEGIL, ele kaynakli bir model -- o zaten
		dusmuyor.
	]]
	if Sand.isOnSand(player) then
		Envanter.equipGPS(player)
	end

	local now = os.clock()
	if now - (sonUyari[player] or 0) < UYARI_ARASI then
		return
	end
	sonUyari[player] = now

	Bildirim:FireClient(player, "You can't hold that while searching!", Color3.fromRGB(255, 160, 60))
end

------------------------------------------------------------------
-- OYUNCU BAGLANTILARI
------------------------------------------------------------------
local function onCharacterAdded(player: Player)
	local character = player.Character
	if character then
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				toolEngelle(player, child)
			end
		end)
	end

	task.wait(0.5)
	Envanter.refresh(player)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.spawn(onCharacterAdded, player)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	digging[player] = nil
	sabitlenen[player] = nil
	lastDig[player] = nil
	lastOnSand[player] = nil
end)

-- Magaza kuregi degistirdiginde bunu tetikler; eski kurek silinip yenisi verilir
local refreshEvent = Instance.new("BindableEvent")
refreshEvent.Name = "KurekYenile"
refreshEvent.Parent = script
refreshEvent.Event:Connect(function(player: Player)
	Envanter.giveShovel(player)
end)
