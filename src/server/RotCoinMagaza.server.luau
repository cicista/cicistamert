local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local RotCoinMagaza = require(Shared:WaitForChild("RotCoinMagaza"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))
local Iksir = require(Modules:WaitForChild("Iksir"))

local Bildirim = Net.event("Bildirim")
local MagazaAc = Net.event("RotCoinMagazaAc")
local MagazaAl = Net.event("RotCoinMagazaAl")

local SARI = Color3.fromRGB(255, 215, 40)
local KIRMIZI = Color3.fromRGB(255, 120, 120)

local aliyor: { [Player]: boolean } = {}

local durumGonder = Iksir.durumGonder

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
		ok, sebep = Iksir.ver(player, urun.multiplier or 1, urun.seconds or 0)
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
