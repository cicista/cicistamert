--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local ArkadasDurum = Net.event("ArkadasDurum")
local ArkadasAc = Net.event("ArkadasAc")

local Arkadaslar = {}

Arkadaslar.BONUS = 0.15

Arkadaslar.TEST_STUDIO = true

local iliski: { [number]: { [number]: boolean } } = {}

local function kaydet(a: number, b: number, arkadas: boolean)
	local ilkinin = iliski[a]
	if not ilkinin then
		ilkinin = {}
		iliski[a] = ilkinin
	end
	local ikincinin = iliski[b]
	if not ikincinin then
		ikincinin = {}
		iliski[b] = ikincinin
	end
	ilkinin[b] = arkadas
	ikincinin[a] = arkadas
end

function Arkadaslar.liste(player: Player): { Player }
	local sonuc: { Player } = {}
	local benim = iliski[player.UserId]
	if not benim then
		return sonuc
	end

	for _, diger in Players:GetPlayers() do
		if diger ~= player and benim[diger.UserId] then
			table.insert(sonuc, diger)
		end
	end
	return sonuc
end

function Arkadaslar.carpan(player: Player): number
	return if #Arkadaslar.liste(player) > 0 then 1 + Arkadaslar.BONUS else 1
end

function Arkadaslar.push(player: Player)
	if not player.Parent then
		return
	end

	local arkadaslar = {}
	for _, arkadas in Arkadaslar.liste(player) do
		table.insert(arkadaslar, {
			userId = arkadas.UserId,
			name = arkadas.Name,
			displayName = arkadas.DisplayName,
		})
	end

	ArkadasDurum:FireClient(player, {
		sayi = #arkadaslar,
		yuzde = math.floor(Arkadaslar.BONUS * 100 + 0.5),
		arkadaslar = arkadaslar,
	})
end

local function eslestir(yeni: Player)
	for _, diger in Players:GetPlayers() do
		if diger == yeni then
			continue
		end

		local arkadas = false
		if Arkadaslar.TEST_STUDIO and RunService:IsStudio() then
			arkadas = true
		else
			local ok, sonuc = pcall(function()
				return yeni:IsFriendsWith(diger.UserId)
			end)
			arkadas = ok and sonuc == true
		end

		kaydet(yeni.UserId, diger.UserId, arkadas)

		if arkadas then
			Arkadaslar.push(diger)
		end
	end

	Arkadaslar.push(yeni)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(eslestir, player)

	task.delay(4, Arkadaslar.push, player)
end)

for _, player in Players:GetPlayers() do
	task.spawn(eslestir, player)
end

Players.PlayerRemoving:Connect(function(player)
	local benim = iliski[player.UserId]
	iliski[player.UserId] = nil
	if not benim then
		return
	end

	for userId, arkadas in benim do
		local karsi = iliski[userId]
		if karsi then
			karsi[player.UserId] = nil
		end

		if arkadas then
			local kalan = Players:GetPlayerByUserId(userId)
			if kalan then
				task.defer(Arkadaslar.push, kalan)
			end
		end
	end
end)

ArkadasAc.OnServerEvent:Connect(function(player)
	Arkadaslar.push(player)
end)

return Arkadaslar
