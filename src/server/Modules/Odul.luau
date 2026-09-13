--!strict
--[[
	GUNLUK ODUL  --  sunucu tarafi

	Her 24 saatte bir hediye carki. Kazanan SUNUCUDA belirlenir; istemciye
	yalnizca "cark su bolmede dursun" bilgisi gider, yani cark manipule
	edilemez. Odul, cark durduktan sonra veriliyor -- surpriz bozulmasin.

	Sure os.time ile tutulur: oyundan cikip girmek sayaci sifirlamaz.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Condition = require(Shared:WaitForChild("Condition"))
local Format = require(Shared:WaitForChild("Format"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Rewards = require(Shared:WaitForChild("Rewards"))
local Skins = require(Shared:WaitForChild("Skins"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))
local GorevTakip = require(script.Parent:WaitForChild("GorevTakip"))

local Bildirim = Net.event("Bildirim")
local OdulAc = Net.event("OdulAc")
local OdulCevir = Net.event("OdulCevir")
local OdulDurum = Net.event("OdulDurum")
local OdulSonuc = Net.event("OdulSonuc")

local Odul = {}

local rng = Random.new()

-- Ayni anda iki cark donmesin
local spinning: { [Player]: boolean } = {}

------------------------------------------------------------------
-- DURUM
------------------------------------------------------------------

-- Bir sonraki odule kalan saniye (0 = simdi cevrilebilir)
local function remaining(player: Player): number
	local data = PlayerData.get(player)
	if not data then
		return Rewards.cooldown
	end

	local elapsed = os.time() - (data.lastReward or 0)
	return math.max(0, Rewards.cooldown - elapsed)
end

function Odul.push(player: Player)
	local left = remaining(player)

	OdulDurum:FireClient(player, {
		remaining = left,
		ready = left <= 0,
		cooldown = Rewards.cooldown,
		luckLeft = math.max(0, (PlayerData.get(player) and PlayerData.get(player).luckUntil or 0) - os.time()),
	})
end

------------------------------------------------------------------
-- ODUL DAGITIMI
------------------------------------------------------------------

--[[
	Kazanilan odulu verir ve oyuncuya ne kazandigini yazar.
	Cark DURDUKTAN sonra cagrilir.
]]
--[[
	GUNLUK ODUL BRAINROTU CARK DONMEDEN SECILIR

	Once brainrot, cark DURDUKTAN sonra grant icinde seciliyordu; carkta
	yalnizca "BRAINROT" yaziyordu. Artik bolmelerde brainrot resimleri var ve
	isaretcinin durdugu resim ile gercekten verilen brainrot AYNI olmali.
	Bu yuzden secim cevirme aninda yapiliyor, cark verisiyle istemciye
	gidiyor ve cark durunca TAM O brainrot veriliyor.

	Oyuncunun ulastigi adaya gore sinirlama aynen korunuyor.
]]
type BrainrotSecimi = { rarityId: string, info: any, condition: any, mutation: any }

local function brainrotSec(player: Player): BrainrotSecimi
	-- Oyuncunun ulastigi adaya kadar: sonraki adalarin brainrotu cikmaz
	local ada = PlayerData.reachedIsland(player)
	local rarityId = Brainrots.clampRarity(Rewards.rollBrainrotRarity(rng), ada)
	return {
		rarityId = rarityId,
		info = Brainrots.rollIsland(rarityId :: any, ada, rng),
		condition = Condition.roll(rng),
		mutation = Mutations.roll(rng),
	}
end

local function grant(player: Player, prizeId: string, secim: BrainrotSecimi?)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	if prizeId == "luck" then
		local boost = Rewards.luckBoost
		PlayerData.grantLuck(player, boost.multiplier, boost.duration)

		Bildirim:FireClient(
			player,
			`Luck x{boost.multiplier} for {boost.duration // 60} minutes!`,
			Color3.fromRGB(120, 226, 150)
		)
		return
	end

	if prizeId == "luckyblock" then
		local tierId = LuckyBlock.rollTier(rng)
		local tier = LuckyBlock.get(tierId)

		PlayerData.addLuckyBlocks(player, tierId, 1)
		Envanter.syncLuckyBlocks(player)

		Bildirim:FireClient(player, `You won a {tier.displayName}!`, tier.color)
		return
	end

	if prizeId == "brainrot" then
		-- Cark donmeden secilmis olan (bkz. spin); yoksa simdi secilir
		local sec = secim or brainrotSec(player)
		local rarityId = sec.rarityId
		local info = sec.info
		local condition = sec.condition
		local mutation = sec.mutation

		local item = PlayerData.addBrainrot(player, rarityId, condition, mutation)
		if not item then
			return
		end

		-- Odul brainrotu ACIK gelir: Detective'e gitmeye gerek yok
		item.name = info.name
		item.revealed = true

		-- Gorev panosu: gunluk odulden gelen brainrot da kademe gorevine sayilir
		GorevTakip.ilerlet(player, "collect", 1, rarityId)
		Envanter.syncBrainrots(player)

		local income = Brainrots.income(info.name, condition, mutation :: any)
		Bildirim:FireClient(
			player,
			--[[
				Mutations.fullName diye bir fonksiyon YOK (adi bir ara degisti).
				Bu satir hata veriyordu: brainrot envantere eklenmis oluyor ama
				bildirim, envanter gonderimi ve odul sayaci tazelemesi hic
				calismiyordu. Tam ad prefix VERI alanindan kuruluyor.
			]]
			`You got {Mutations.get(mutation).prefix .. info.name} ({Format.perSecond(income)})`,
			if Mutations.isSpecial(mutation) then Mutations.color(mutation) else Rarity.color(rarityId)
		)
		return
	end

	if prizeId == "skin" then
		--[[
			Sahip olunmayan skinler arasindan secilir. Hepsi doluysa skin
			yerine Lucky Block verilir -- oyuncu bos elle kalmasin.
		]]
		local kalanlar = {}
		for _, skin in Skins.List do
			if not data.skins[skin.id] then
				table.insert(kalanlar, skin)
			end
		end

		if #kalanlar == 0 then
			local tierId = Rewards.skinFallbackTier
			PlayerData.addLuckyBlocks(player, tierId, 1)
			Envanter.syncLuckyBlocks(player)

			Bildirim:FireClient(
				player,
				`You own every skin! You got a {LuckyBlock.get(tierId).displayName} instead.`,
				Color3.fromRGB(255, 236, 90)
			)
			return
		end

		local skin = kalanlar[rng:NextInteger(1, #kalanlar)]
		data.skins[skin.id] = true

		Bildirim:FireClient(player, `{skin.displayName} skin unlocked!`, Rarity.color(skin.rarity))
		return
	end
end

------------------------------------------------------------------
-- CARK
------------------------------------------------------------------

--[[
	Carkin bolmelerini doldurur. Bolmeler yalnizca gosterim; kazanan bolme
	disindakilerin oyuna etkisi yok.
]]
local function buildCells(player: Player, winnerIndex: number, winnerId: string, kazanan: BrainrotSecimi?): { any }
	local cells = {}

	for index = 1, Rewards.Wheel.cellCount do
		local prize = if index == winnerIndex then Rewards.get(winnerId) else Rewards.roll(rng)
		if prize then
			local cell: any = { id = prize.id, label = prize.label, color = prize.color }

			--[[
				Brainrot bolmesine gosterilecek brainrot. Kazanan bolmede
				GERCEKTEN verilecek olan (mutasyonuyla); digerlerinde oyuncunun
				adasinda cikabilecek rastgele bir brainrot, yalnizca gosterim.
			]]
			if prize.id == "brainrot" then
				local sec = if index == winnerIndex and kazanan then kazanan else brainrotSec(player)
				cell.brainrot = {
					name = sec.info.name,
					rarity = sec.rarityId,
					mutation = if index == winnerIndex then sec.mutation else nil,
				}
			end

			table.insert(cells, cell)
		end
	end

	return cells
end

local function spin(player: Player)
	if spinning[player] then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local left = remaining(player)
	if left > 0 then
		Bildirim:FireClient(
			player,
			`Daily reward is not ready ({Rewards.formatRemaining(left)} left)`,
			Color3.fromRGB(255, 200, 90)
		)
		Odul.push(player)
		return
	end

	spinning[player] = true

	-- Sayac HEMEN baslar: cark donerken tekrar cevrilemesin
	data.lastReward = os.time()
	Odul.push(player)

	local prize = Rewards.roll(rng)

	-- Brainrot cikacaksa HANGISI oldugu simdi seciliyor (bkz. brainrotSec)
	local secim = if prize.id == "brainrot" then brainrotSec(player) else nil

	OdulSonuc:FireClient(player, {
		cells = buildCells(player, Rewards.Wheel.winnerIndex, prize.id, secim),
		winnerIndex = Rewards.Wheel.winnerIndex,
		spinTime = Rewards.Wheel.spinTime,
		winner = {
			id = prize.id,
			label = prize.label,
			color = prize.color,
			brainrot = if secim
				then { name = secim.info.name, rarity = secim.rarityId, mutation = secim.mutation }
				else nil,
		},
	})

	-- Odul cark durunca verilir
	task.delay(Rewards.totalSpinTime(), function()
		spinning[player] = nil
		if not player.Parent then
			return
		end

		-- Carkta gosterilen brainrotun TA KENDISI veriliyor
		grant(player, prize.id, secim)
		Envanter.push(player)
		Odul.push(player)
	end)
end

------------------------------------------------------------------
-- BAGLANTILAR
------------------------------------------------------------------
OdulAc.OnServerEvent:Connect(function(player)
	Odul.push(player)
end)

OdulCevir.OnServerEvent:Connect(function(player)
	spin(player)
end)

Players.PlayerRemoving:Connect(function(player)
	spinning[player] = nil
end)

--[[
	Oyuncu girince durumu bir kez gonderir; menu butonu odul hazirsa
	isaret gosterebilsin.
]]
Players.PlayerAdded:Connect(function(player)
	task.delay(3, function()
		if player.Parent then
			Odul.push(player)
		end
	end)
end)

return Odul
