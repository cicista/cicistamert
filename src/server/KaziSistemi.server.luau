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
local Shovels = require(Shared:WaitForChild("Shovels"))
local Detectors = require(Shared:WaitForChild("Detectors"))
local Net = require(Shared:WaitForChild("Net"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Sand = require(Modules:WaitForChild("Sand"))
local Tools = require(Modules:WaitForChild("Tools"))
local Beams = require(Modules:WaitForChild("Beams"))
local LuckyBlockOdul = require(Modules:WaitForChild("LuckyBlockOdul"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Envanter = require(Modules:WaitForChild("Envanter"))
local GorevTakip = require(Modules:WaitForChild("GorevTakip"))

local Bildirim = Net.event("Bildirim")
local GPSGuncelle = Net.event("GPSGuncelle")
local SuzmeKaz = Net.event("SuzmeKaz")
local MinigameBasla = Net.event("MinigameBasla")
local MinigameSonuc = Net.event("MinigameSonuc")
local KaziBitti = Net.event("KaziBitti")

local D = Config.Dig
local G = Config.GPS

local rng = Random.new()

-- Suren kazilar: [player] = { beamId, startedAt, shovelId, rarityId, startPos }
local digging: { [Player]: any } = {}
local lastDig: { [Player]: number } = {}

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

	-- Gunluk odulden gelen gecici carpan da hesaba katilir
	return ground * detector.luck * PlayerData.luckBonus(player)
end

-- Oyuncunun dedektorune gore tarama ayarlari
local function detectorFor(player: Player): Detectors.DetectorInfo
	local data = PlayerData.get(player)
	local id = if data then data.detector else Detectors.Default
	return Detectors.get(id :: any)
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

	-- Kazi suruyorsa kurek elde kalir, baska hicbir sey karismaz
	if digging[player] then
		Envanter.equipShovel(player)
		return
	end

	local now = os.clock()

	--[[
		KUMDA HER ZAMAN GPS

		Elinde brainrot, coin ya da lucky block olsa bile kuma basildigi
		anda GPS ele gecer. Onceden tasidigin esyaya oncelik veriliyordu;
		istenen davranis bu degil -- kumun uzeri arama alani, orada elde
		baska bir sey durmuyor.

		Ayni kural "tool degistirilemez" isini de goruyor: oyuncu cantadan
		baska bir sey kusansa bile bir sonraki kontrolde GPS geri gelir,
		yani kumun ustunde baska toola gecilemez.
	]]
	if Sand.isOnSand(player) then
		lastOnSand[player] = now
		Envanter.equipGPS(player)
		return
	end

	--[[
		Kumdan cikti ama sure dolmadi: GPS elde kalmaya devam eder.
		Boylece zipladiginda ya da kumun kenarindan bir adim tastiginda
		esya elinden dusmez.
	]]
	local left = lastOnSand[player]
	if left and now - left < D.autoUnequipDelay then
		return
	end

	lastOnSand[player] = nil
	Envanter.unequipTools(player)
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

	local beam = Beams.get(session.beamId)
	KaziBitti:FireClient(player)

	-- Kurek isini bitirdi: kumdaysa GPS hemen geri gelsin, dongu beklemesin
	otoEkipman(player)

	if not beam then
		return
	end

	Beams.remove(session.beamId, if won then "kazi kazanildi" else "kazi kaybedildi")

	if not won then
		Bildirim:FireClient(player, "The brainrot got away!", Color3.fromRGB(255, 120, 120))
		return
	end

	-- Rot Coin suzmesi
	if beam.kind == "RotCoin" then
		local amount = rng:NextInteger(Rarity.RotCoin.amountMin, Rarity.RotCoin.amountMax)
		PlayerData.addRotCoins(player, amount)
		Envanter.push(player)
		Bildirim:FireClient(player, `+{amount} Rot Coin!`, Rarity.RotCoin.colorA)
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
			`{string.upper(tier.displayName)} found! (x{PlayerData.luckyBlockCount(player, tierId)}) -- take it from your backpack and click`,
			tier.color
		)
		return
	end

	-- Brainrot: simsiyah bir Tool olarak cantaya girer
	local condition = Condition.roll(rng)
	-- Mutasyon da burada belirlenir ama Detective acana kadar gizli kalir
	local mutation = Mutations.roll(rng)
	local item = PlayerData.addBrainrot(player, beam.kind, condition, mutation)
	if not item then
		return
	end

	Envanter.syncBrainrots(player)
	Envanter.push(player)

	-- Gorev panosu: hem "kaz" hem de kademe gorevleri bu kazidan sayar
	GorevTakip.ilerlet(player, "dig", 1)
	GorevTakip.ilerlet(player, "collect", 1, beam.kind)
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

	if (beam.position - root.Position).Magnitude > G.digDistance then
		Bildirim:FireClient(player, "Get closer to the beam!", Color3.fromRGB(255, 160, 60))
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	beam.claimed = true

	--[[
		Kurek oyuncunun elinde DEGILDIR -- cantada da durmuyor. Suzmeye
		tiklamak zaten "kazmak istiyorum" demek oldugu icin kuregi burada
		eline veriyoruz; GPS onun yerini birakir, kazi bitince geri gelir.
	]]
	Envanter.equipShovel(player)

	local shovel = Shovels.get(data.shovel)
	local prepare = D.prepareTime * shovel.digSpeed

	digging[player] = {
		beamId = beamId,
		startedAt = now,
		shovelId = data.shovel,
		rarityId = beam.kind,
		startPos = root.Position,
	}

	task.wait(prepare)

	local session = digging[player]
	if not session or session.beamId ~= beamId then
		return
	end

	-- Rot Coin ve Lucky Block icin minigame yok, dogrudan kazanilir
	if beam.kind == "RotCoin" or beam.kind == "LuckyBlock" then
		finishDig(player, true)
		return
	end

	local seed = rng:NextInteger(1, 2 ^ 30)
	session.seed = seed
	MinigameBasla:FireClient(player, data.shovel, beam.kind, seed)

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
	if not root or (root.Position - session.startPos).Magnitude > D.maxMoveDistance then
		finishDig(player, false)
		return
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

			if gpsInHand and not digging[player] and Sand.isOnSand(player) then
				local detector = detectorFor(player)

				-- Suzme sansi ve limiti dedektor seviyesinden gelir
				if rng:NextNumber() * 100 <= detector.spawnChance then
					Beams.trySpawn(player, luckFor(player), rng, detector.maxBeams)
				end
			end

			-- Mevcut suzmeler her durumda gonderilir; kurek eldeyken de
			-- kazilabilmeleri icin client listesinin dolu kalmasi sart.
			GPSGuncelle:FireClient(player, Beams.snapshotFor(player, detectorFor(player).scanRadius))
		end
	end
end)

------------------------------------------------------------------
-- OYUNCU BAGLANTILARI
------------------------------------------------------------------
local function onCharacterAdded(player: Player)
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
