--[[
	RotCoinMagaza  (Script)
	Yeri: ServerScriptService > RotCoinMagaza

	Rot Coin magazasinin sunucu tarafi. Urunler ve fiyatlar Shared >
	RotCoinMagaza'da. Burasi:
	  - satin almayi DOGRULAR (bakiye, iksir kurallari) ve urunu verir
	  - aktif sans iksirinin durumunu istemciye yollar (Rot'un ustundeki yazi)

	Istemci yalnizca urun id'si yollar; fiyati ve ne verilecegini o belirleyemez.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local RotCoinMagaza = require(Shared:WaitForChild("RotCoinMagaza"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))

local Bildirim = Net.event("Bildirim")
local MagazaAc = Net.event("RotCoinMagazaAc")
local MagazaAl = Net.event("RotCoinMagazaAl")
local MagazaDurum = Net.event("RotCoinMagazaDurum")

local SARI = Color3.fromRGB(255, 215, 40)
local KIRMIZI = Color3.fromRGB(255, 120, 120)

-- Ust uste gelen iki istek ayni Rot Coin'i iki kez harcamasin
local aliyor: { [Player]: boolean } = {}

local function durumGonder(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	-- luckBonus suresi dolmussa kaydi da temizler
	local carpan = PlayerData.luckBonus(player)
	MagazaDurum:FireClient(player, {
		carpan = carpan,
		kalan = if carpan > 1 then math.max(0, data.luckUntil - os.time()) else 0,
	})
end

--[[
	Sans iksiri. Verilemiyorsa (false, sebep) doner; o zaman Rot Coin dusmez.
]]
local function iksirVer(player: Player, data: any, urun: RotCoinMagaza.Urun): (boolean, string?)
	local carpan = urun.multiplier or 1
	local sure = urun.seconds or 0
	local aktif = PlayerData.luckBonus(player)

	if aktif > 1 then
		if math.abs(aktif - carpan) < 0.001 then
			-- Ayni iksir: sure uzar
			local kalan = data.luckUntil - os.time()
			if kalan + sure > RotCoinMagaza.MaxPotionSeconds then
				return false, `You can stack at most {RotCoinMagaza.sureYazisi(RotCoinMagaza.MaxPotionSeconds)} of this potion.`
			end
			data.luckUntil += sure
			return true, nil
		elseif carpan < aktif then
			return false, "A stronger luck potion is already active."
		end
	end

	-- Iksir yok ya da daha gucluye geciliyor
	PlayerData.grantLuck(player, carpan, sure)
	return true, nil
end

local function satinAl(player: Player, id: string)
	if aliyor[player] then
		return
	end

	local urun = RotCoinMagaza.get(id)
	local data = PlayerData.get(player)
	if not urun or not data then
		return
	end

	if data.rotCoins < urun.price then
		Bildirim:FireClient(player, `Not enough Rot Coin! {urun.name} costs {urun.price} Rot Coin.`, KIRMIZI)
		return
	end

	aliyor[player] = true

	local ok, sebep = true, nil
	if urun.kind == "potion" then
		ok, sebep = iksirVer(player, data, urun)
	elseif urun.kind == "luckyblock" and urun.tier then
		PlayerData.addLuckyBlocks(player, urun.tier, urun.amount or 1)
		Envanter.syncLuckyBlocks(player)
	else
		ok, sebep = false, "This item cannot be bought."
	end

	if ok then
		PlayerData.addRotCoins(player, -urun.price)
		Bildirim:FireClient(player, `Bought {urun.name} for {urun.price} Rot Coin!`, SARI)
	else
		Bildirim:FireClient(player, sebep or "Purchase failed.", KIRMIZI)
	end

	-- Ekrandaki Rot Coin bakiyesi ve iksir yazisi bayat kalmasin
	Envanter.push(player)
	durumGonder(player)

	aliyor[player] = nil
end

MagazaAl.OnServerEvent:Connect(function(player, id)
	if type(id) == "string" then
		satinAl(player, id)
	end
end)

MagazaAc.OnServerEvent:Connect(function(player)
	durumGonder(player)
end)

-- Girince aktif iksir (oyundan cikmadan once alinmis) Rot'un ustunde gorunsun
Players.PlayerAdded:Connect(function(player)
	task.delay(3, function()
		if player.Parent then
			durumGonder(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	aliyor[player] = nil
end)
