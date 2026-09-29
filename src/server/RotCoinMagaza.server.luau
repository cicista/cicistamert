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

local aliyor: { [Player]: boolean } = {}

local function durumGonder(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	local carpan = PlayerData.luckBonus(player)
	MagazaDurum:FireClient(player, {
		carpan = carpan,
		kalan = if carpan > 1 then math.max(0, data.luckUntil - os.time()) else 0,
	})
end

local function iksirVer(player: Player, data: any, urun: RotCoinMagaza.Urun): (boolean, string?)
	local carpan = urun.multiplier or 1
	local sure = urun.seconds or 0
	local aktif = PlayerData.luckBonus(player)

	if aktif > 1 then
		if math.abs(aktif - carpan) < 0.001 then
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
		Bildirim:FireClient(player, `Not enough Rot Coin! You need {urun.price - data.rotCoins} more Rot Coin for {urun.name}.`, KIRMIZI)
		return
	end

	aliyor[player] = true

	local ok, sebep = true, nil
	if urun.kind == "potion" then
		ok, sebep = iksirVer(player, data, urun)
	elseif urun.kind == "luckyblock" and urun.tier then
		PlayerData.addLuckyBlocks(player, urun.tier, urun.amount or 1)
		Envanter.syncLuckyBlocks(player)
	elseif urun.kind == "scroll" and urun.scroll then
		PlayerData.addScroll(player, urun.scroll, urun.amount or 1)
		Envanter.syncScrolls(player)
	else
		ok, sebep = false, "This item cannot be bought."
	end

	if ok then
		PlayerData.addRotCoins(player, -urun.price)
		Bildirim:FireClient(player, `Bought {urun.name} for {urun.price} Rot Coin!`, SARI)
	else
		Bildirim:FireClient(player, sebep or "Purchase failed.", KIRMIZI)
	end

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

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		task.wait(3)
		if PlayerData.bekle(player) then
			durumGonder(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	aliyor[player] = nil
end)
