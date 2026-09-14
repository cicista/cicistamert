--!strict
--[[
	GUNLUK ODUL  --  sunucu tarafi (7 gunluk takvim)

	Takvim, oduller ve kurallar Shared > Rewards'ta. Burasi yalnizca:
	  - oyuncunun durumunu hesaplayip istemciye gonderir (OdulDurum)
	  - "al" istegini DOGRULAYIP o gunun odulunu verir (OdulAl)

	Hangi gunun alinacagi ve alinabilir olup olmadigi SUNUCUDA hesaplanir.
	Istemci yalnizca "almak istiyorum" der; hangi odulu alacagini o
	belirleyemez.

	Sure os.time ile tutulur: oyundan cikip girmek sayaci sifirlamaz.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Net = require(Shared:WaitForChild("Net"))
local Rewards = require(Shared:WaitForChild("Rewards"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))

local Bildirim = Net.event("Bildirim")
local OdulAc = Net.event("OdulAc")
local OdulAl = Net.event("OdulAl")
local OdulDurum = Net.event("OdulDurum")
local OdulSonuc = Net.event("OdulSonuc")

local Odul = {}

-- Ust uste gelen iki "al" istegi ayni odulu iki kez vermesin
local aliyor: { [Player]: boolean } = {}

local function durum(player: Player): Rewards.State?
	local data = PlayerData.get(player)
	if not data then
		return nil
	end
	return Rewards.state(data.lastReward or 0, data.rewardDay or 1, os.time())
end

function Odul.push(player: Player)
	local d = durum(player)
	if not d then
		return
	end

	OdulDurum:FireClient(player, {
		day = d.day,
		ready = d.ready,
		remaining = d.remaining,
		cooldown = Rewards.cooldown,
	})
end

-- O gunun odulunu verir ve oyuncuya ne kazandigini yazar
local function ver(player: Player, day: number)
	local odul = Rewards.get(day)

	if odul.kind == "rot" then
		PlayerData.addRot(player, odul.amount)
	elseif odul.kind == "luckyblock" then
		PlayerData.addLuckyBlocks(player, odul.tier or LuckyBlock.Default, odul.amount)
		Envanter.syncLuckyBlocks(player)
	end

	-- Bazi gunlerde ana odulun yaninda Rot Coin de var
	local coin = odul.rotCoins or 0
	if coin > 0 then
		PlayerData.addRotCoins(player, coin)
	end

	-- Ekrandaki Rot/Rot Coin gostergesi ve envanter bayat kalmasin
	Envanter.push(player)

	local yazi = Rewards.label(day)
	if coin > 0 then
		yazi ..= ` + {coin} Rot Coin`
	end
	Bildirim:FireClient(player, `Day {day} reward: {yazi}!`, Rewards.color(day))
end

local function al(player: Player)
	if aliyor[player] then
		return
	end

	local data = PlayerData.get(player)
	local d = durum(player)
	if not data or not d then
		return
	end

	if not d.ready then
		Bildirim:FireClient(
			player,
			`Daily reward is not ready ({Rewards.formatRemaining(d.remaining)} left)`,
			Color3.fromRGB(255, 200, 90)
		)
		Odul.push(player)
		return
	end

	aliyor[player] = true

	--[[
		ONCE KAYIT ILERLER, SONRA ODUL VERILIR.
		Odul verilirken bir hata cikarsa takvim yine de ilerlemis olur;
		boylece ayni gunun odulu tekrar tekrar alinamaz. Hata Output'a yazilir.
	]]
	data.lastReward = os.time()
	data.rewardDay = Rewards.nextDay(d.day)

	local ok, hata = pcall(ver, player, d.day)
	if not ok then
		warn(`[Odul] {player.Name} icin {d.day}. gun odulu verilemedi: {tostring(hata)}`)
	end

	OdulSonuc:FireClient(player, { day = d.day })
	Odul.push(player)

	aliyor[player] = nil
end

------------------------------------------------------------------
-- BAGLANTILAR
------------------------------------------------------------------
OdulAc.OnServerEvent:Connect(function(player)
	Odul.push(player)
end)

OdulAl.OnServerEvent:Connect(function(player)
	al(player)
end)

Players.PlayerRemoving:Connect(function(player)
	aliyor[player] = nil
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
