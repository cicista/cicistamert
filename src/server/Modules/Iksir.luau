--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local RotCoinMagaza = require(Shared:WaitForChild("RotCoinMagaza"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Iksir = {}

function Iksir.durumGonder(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	local carpan = PlayerData.luckBonus(player)
	Net.event("RotCoinMagazaDurum"):FireClient(player, {
		carpan = carpan,
		kalan = if carpan > 1 then math.max(0, data.luckUntil - os.time()) else 0,
	})
end

function Iksir.ver(player: Player, carpan: number, sure: number): (boolean, string?)
	local data = PlayerData.get(player)
	if not data then
		return false, "Purchase failed."
	end

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

return Iksir
