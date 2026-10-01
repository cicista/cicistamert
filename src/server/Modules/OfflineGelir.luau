--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Bases = require(Shared:WaitForChild("Bases"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))
local Gelir = require(script.Parent:WaitForChild("Gelir"))

local Duyuru = Net.event("Duyuru")

local A = Bases.Offline

local OfflineGelir = {}

local hesaplandi: { [Player]: boolean } = {}

local function sureYazisi(saniye: number): string
	local dakika = math.floor(saniye / 60)
	local saat = dakika // 60
	if saat > 0 then
		return `{saat}h {dakika % 60}m`
	end
	return `{dakika}m`
end

function OfflineGelir.hesapla(saniyelik: number, saniye: number): number
	if saniye < A.enAzSaniye or saniyelik <= 0 then
		return 0
	end
	local sayilan = math.min(saniye, A.enFazlaSaat * 3600)
	return math.floor(saniyelik * sayilan * A.oran)
end

local function oyuncuGeldi(player: Player)
	local data = PlayerData.bekle(player)
	if not data or not player.Parent then
		return
	end

	local simdi = os.time()
	local son = data.sonGorulme
	data.sonGorulme = simdi
	hesaplandi[player] = true
	if son <= 0 then
		return
	end

	local saniye = simdi - son
	local miktar = OfflineGelir.hesapla(Gelir.saniyelik(player), saniye)
	if miktar < 1 then
		return
	end

	PlayerData.addRot(player, miktar)
	Envanter.push(player)

	Duyuru:FireClient(player, {
		tur = "odul",
		baslik = "WELCOME BACK!",
		yazi = `+{Format.short(miktar)} Rot`,
		alt = `Your pets kept working while you were away ({sureYazisi(math.min(saniye, A.enFazlaSaat * 3600))})`,
		ikon = "rot",
	})
end

Players.PlayerAdded:Connect(oyuncuGeldi)
for _, player in Players:GetPlayers() do
	task.spawn(oyuncuGeldi, player)
end

Players.PlayerRemoving:Connect(function(player)
	local data = PlayerData.get(player)
	if data and hesaplandi[player] then
		data.sonGorulme = os.time()
	end
	hesaplandi[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(A.kayitAraligi)
		local simdi = os.time()
		for _, player in Players:GetPlayers() do
			local data = PlayerData.get(player)
			if data and hesaplandi[player] then
				data.sonGorulme = simdi
			end
		end
	end
end)

return OfflineGelir
