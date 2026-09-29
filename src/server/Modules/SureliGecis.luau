--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Passler = require(Shared:WaitForChild("Passler"))

local PlayerData = require(script.Parent.PlayerData)

local SureliGecis = {}

SureliGecis.SureNiteligi = "PassSure_"

local function sureAdi(gecisAdi: string): string
	return SureliGecis.SureNiteligi .. gecisAdi
end

local function uygula(player: Player, gecisAdi: string)
	local data = PlayerData.get(player)
	local info = Passler.get(gecisAdi)
	if not data or not info then
		return
	end

	local bitis = data.tempPasses[gecisAdi]
	local kalan = if bitis then bitis - os.time() else 0

	if kalan <= 0 then
		data.tempPasses[gecisAdi] = nil
		player:SetAttribute(sureAdi(gecisAdi), nil)
		if player:GetAttribute("PassKalici_" .. gecisAdi) ~= true then
			player:SetAttribute(info.nitelik, nil)
		end
		return
	end

	player:SetAttribute(info.nitelik, true)
	player:SetAttribute(sureAdi(gecisAdi), bitis)

	task.delay(kalan + 1, function()
		if player.Parent then
			uygula(player, gecisAdi)
		end
	end)
end

function SureliGecis.ver(player: Player, gecisAdi: string, saniye: number): boolean
	local data = PlayerData.get(player)
	local info = Passler.get(gecisAdi)
	if not data or not info or saniye <= 0 then
		return false
	end

	if player:GetAttribute("PassKalici_" .. gecisAdi) == true then
		return false
	end

	local simdi = os.time()
	local mevcut = data.tempPasses[gecisAdi]
	local taban = if mevcut and mevcut > simdi then mevcut else simdi
	data.tempPasses[gecisAdi] = taban + math.floor(saniye)

	uygula(player, gecisAdi)
	return true
end

function SureliGecis.kalan(player: Player, gecisAdi: string): number
	local data = PlayerData.get(player)
	if not data then
		return 0
	end
	local bitis = data.tempPasses[gecisAdi]
	return if bitis then math.max(0, bitis - os.time()) else 0
end

function SureliGecis.kur(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	for gecisAdi in data.tempPasses do
		uygula(player, gecisAdi)
	end
end

return SureliGecis
