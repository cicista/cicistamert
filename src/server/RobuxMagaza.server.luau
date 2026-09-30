--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local RobuxMagaza = require(Shared:WaitForChild("RobuxMagaza"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))
local Gacha = require(Modules:WaitForChild("Gacha"))
local AfkSans = require(Modules:WaitForChild("AfkSans"))
local KacanYumurta = require(Modules:WaitForChild("KacanYumurta"))
local Canta = require(Shared:WaitForChild("Canta"))

local Bildirim = Net.event("Bildirim")
local RobuxUrunAl = Net.event("RobuxUrunAl")
local SansDurum = Net.event("RotCoinMagazaDurum")

local YESIL = Color3.fromRGB(140, 230, 160)
local SARI = Color3.fromRGB(255, 200, 90)

local PENCERE_ARASI = 1
local sonPencere: { [Player]: number } = {}

local function sansDurumuGonder(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local carpan = PlayerData.luckBonus(player)
	SansDurum:FireClient(player, {
		carpan = carpan,
		kalan = if carpan > 1 then math.max(0, data.luckUntil - os.time()) else 0,
	})
end

local function sansVer(player: Player, data: any, carpan: number, saniye: number)
	local aktif = PlayerData.luckBonus(player)
	if aktif >= carpan - 0.001 then
		data.luckUntil += saniye
	else
		PlayerData.grantLuck(player, carpan, saniye)
	end
end

local function dedektifKapisi(ad: string): BindableFunction?
	local betik = script.Parent:FindFirstChild("Detective")
	local kapi = betik and betik:FindFirstChild(ad)
	return if kapi and kapi:IsA("BindableFunction") then kapi else nil
end

local function dedektifAtla(player: Player): boolean
	local kapi = dedektifKapisi("DedektifAtla")
	return kapi ~= nil and kapi:Invoke(player) == true
end

local function dedektifBekliyor(player: Player): boolean
	local kapi = dedektifKapisi("DedektifBekliyorMu")
	return kapi ~= nil and kapi:Invoke(player) == true
end

local function urunVer(player: Player, data: any, urun: RobuxMagaza.Urun)
	if urun.tur == "luckyblock" and urun.tier then
		PlayerData.addLuckyBlocks(player, urun.tier, urun.adet or 1)
	elseif urun.tur == "luck" then
		sansVer(player, data, urun.carpan or 2, urun.saniye or 0)
	elseif urun.tur == "rotcoin" then
		PlayerData.addRotCoins(player, urun.rotCoin or 0)
	elseif urun.tur == "detectiveSkip" then
		if not dedektifAtla(player) then
			Bildirim:FireClient(
				player,
				"The Detective had already finished -- nothing to skip.",
				Color3.fromRGB(255, 200, 90)
			)
		end
	elseif urun.tur == "afkAlan" and urun.alan then
		AfkSans.robuxlaAc(player, urun.alan)
	elseif urun.tur == "gacha" then
		Gacha.ver(player)
	elseif urun.tur == "kacanYumurta" then
		KacanYumurta.ver(player)
	else
		error(`unknown product type: {urun.tur}`)
	end
end

local function ekraniTazele(player: Player, urun: RobuxMagaza.Urun)
	if urun.tur == "gacha" or urun.tur == "kacanYumurta" then
		return
	end
	if urun.tur == "luckyblock" then
		Envanter.syncLuckyBlocks(player)
	elseif urun.tur == "luck" then
		sansDurumuGonder(player)
	end
	Envanter.push(player)
end

local function fisIsle(fis: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(fis.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = PlayerData.bekle(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local fisId = tostring(fis.PurchaseId)

	if data.purchases[fisId] then
		return if PlayerData.fisKaydedildi(player, fisId)
			then Enum.ProductPurchaseDecision.PurchaseGranted
			else Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local urun = RobuxMagaza.idIle(fis.ProductId)
	if not urun then
		warn(`[RobuxMagaza] unknown product ID {fis.ProductId} ({player.Name}); add it to Shared > RobuxMagaza`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	data.purchases[fisId] = os.time()
	local ok, hata = pcall(urunVer, player, data, urun)
	if not ok then
		data.purchases[fisId] = nil
		warn(`[RobuxMagaza] {urun.anahtar} could not be granted ({player.Name}): {hata}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	pcall(ekraniTazele, player, urun)
	Bildirim:FireClient(
		player,
		if urun.tur == "gacha" then "Thank you! Premium Spin is spinning..." else `Thank you! You got {urun.ad}!`,
		YESIL
	)

	if not PlayerData.fisKaydedildi(player, fisId) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.ProcessReceipt = function(fis)
	local ok, sonuc = pcall(fisIsle, fis)
	if ok then
		return sonuc
	end
	warn(`[RobuxMagaza] receipt could not be processed: {sonuc}`)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

RobuxUrunAl.OnServerEvent:Connect(function(player, anahtar)
	if type(anahtar) ~= "string" then
		return
	end

	local urun = RobuxMagaza.get(anahtar)
	if not urun then
		return
	end

	local simdi = os.clock()
	if simdi - (sonPencere[player] or -math.huge) < PENCERE_ARASI then
		return
	end
	sonPencere[player] = simdi

	if urun.tur == "detectiveSkip" and not dedektifBekliyor(player) then
		Bildirim:FireClient(player, "The Detective is not working on anything.", SARI)
		return
	end

	if urun.tur == "gacha" then
		local data = PlayerData.get(player)
		if data and PlayerData.cantaSayisi(player) >= Canta.duzelt(data.inventoryMax) then
			Bildirim:FireClient(player, "Your backpack is full! Make room before using the Premium Spin.", SARI)
			return
		end
	end

	if urun.tur == "afkAlan" and urun.alan and AfkSans.robuxAlaniAcik(player, urun.alan) then
		Bildirim:FireClient(player, `{urun.ad} is already unlocked.`, Color3.fromRGB(180, 200, 220))
		return
	end

	if not RobuxMagaza.satista(urun) then
		Bildirim:FireClient(player, `{urun.ad} is coming soon!`, SARI)
		return
	end

	if urun.tur == "kacanYumurta" and not KacanYumurta.satinAlmaBasla(player) then
		return
	end

	local ok, hata = pcall(function()
		MarketplaceService:PromptProductPurchase(player, urun.id)
	end)
	if not ok then
		warn(`[RobuxMagaza] purchase prompt could not be opened ({anahtar}): {hata}`)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	sonPencere[player] = nil
end)
