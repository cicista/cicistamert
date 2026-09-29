--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Net = require(Shared:WaitForChild("Net"))
local Rewards = require(Shared:WaitForChild("Rewards"))
local Format = require(Shared:WaitForChild("Format"))

local PASS_YERINE_ROT = 1_000_000
local Passler = require(Shared:WaitForChild("Passler"))
local SosyalOdul = require(Shared:WaitForChild("SosyalOdul"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))

local Bildirim = Net.event("Bildirim")
local OdulAc = Net.event("OdulAc")
local OdulAl = Net.event("OdulAl")
local OdulDurum = Net.event("OdulDurum")
local OdulSonuc = Net.event("OdulSonuc")

local Odul = {}

local aliyor: { [Player]: boolean } = {}

local girisZamani: { [Player]: number } = {}

local function durum(player: Player): Rewards.State?
	local data = PlayerData.get(player)
	if not data then
		return nil
	end
	local d = Rewards.state(data.lastReward or 0, data.rewardDay or 1, os.time())

	local oynanan = os.clock() - (girisZamani[player] or os.clock())
	local kalanOyun = Rewards.MinSessionSeconds - oynanan
	if kalanOyun > 0 and (d.ready or d.remaining < kalanOyun) then
		return { day = d.day, ready = false, remaining = math.ceil(kalanOyun) }
	end
	return d
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

local function ver(player: Player, day: number)
	local odul = Rewards.get(day)

	if odul.kind == "rot" then
		PlayerData.addRot(player, odul.amount)
	elseif odul.kind == "luckyblock" then
		PlayerData.addLuckyBlocks(player, odul.tier or LuckyBlock.Default, odul.amount)
		Envanter.syncLuckyBlocks(player)
	end

	local passYazisi = ""
	if odul.pass and odul.passSeconds then
		local info = Passler.get(odul.pass)
		local ad = if info then info.ad else odul.pass

		if SureliGecis.ver(player, odul.pass, odul.passSeconds) then
			if odul.kind ~= "pass" then
				passYazisi = ` + {ad} ({SosyalOdul.sure(odul.passSeconds)})`
			end
		elseif odul.kind == "pass" then
			local yerine = PASS_YERINE_ROT
			PlayerData.addRot(player, yerine)
			passYazisi = ` -- already owned, +{Format.short(yerine)} Rot instead`
		end
	end

	local coin = odul.rotCoins or 0
	if coin > 0 then
		PlayerData.addRotCoins(player, coin)
	end

	Envanter.push(player)

	local yazi = Rewards.label(day)
	if coin > 0 then
		yazi ..= ` + {coin} Rot Coin`
	end
	yazi ..= passYazisi
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

OdulAc.OnServerEvent:Connect(function(player)
	Odul.push(player)
end)

OdulAl.OnServerEvent:Connect(function(player)
	al(player)
end)

Players.PlayerRemoving:Connect(function(player)
	aliyor[player] = nil
	girisZamani[player] = nil
end)

for _, player in Players:GetPlayers() do
	girisZamani[player] = os.clock()
end

Players.PlayerAdded:Connect(function(player)
	girisZamani[player] = os.clock()
	task.spawn(function()
		task.wait(3)
		if PlayerData.bekle(player) then
			Odul.push(player)
		end
	end)
end)

return Odul
