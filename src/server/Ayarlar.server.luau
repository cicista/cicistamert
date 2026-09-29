local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))

local AyarDurum = Net.event("AyarDurum")
local AyarKaydet = Net.event("AyarKaydet")

local OLCEK_MIN = 50
local OLCEK_MAX = 150

local function ayarlariYolla(player: Player)
	local data = PlayerData.bekle(player)
	if not data then
		return
	end
	player:SetAttribute("SarsintiKapali", data.shakeOff == true)
	AyarDurum:FireClient(player, {
		uiScale = data.uiScale or 100,
		musicVolume = data.musicVolume or 100,
		musicMuted = data.musicMuted == true,
		sfxVolume = data.sfxVolume or 100,
		sfxMuted = data.sfxMuted == true,
		shakeOff = data.shakeOff == true,
	})
end

AyarKaydet.OnServerEvent:Connect(function(player: Player, payload: any)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	if type(payload) == "table" then
		local yuzde = tonumber(payload.uiScale)
		if yuzde then
			data.uiScale = math.clamp(math.round(yuzde), OLCEK_MIN, OLCEK_MAX)
		end

		local ses = tonumber(payload.musicVolume)
		if ses then
			data.musicVolume = math.clamp(math.round(ses), 0, 100)
		end
		if type(payload.musicMuted) == "boolean" then
			data.musicMuted = payload.musicMuted
		end

		local efekt = tonumber(payload.sfxVolume)
		if efekt then
			data.sfxVolume = math.clamp(math.round(efekt), 0, 100)
		end
		if type(payload.sfxMuted) == "boolean" then
			data.sfxMuted = payload.sfxMuted
		end
		if type(payload.shakeOff) == "boolean" then
			data.shakeOff = payload.shakeOff
		end
	end

	ayarlariYolla(player)
end)

local function playerAdded(player: Player)
	task.spawn(function()
		for _ = 1, 5 do
			if not player.Parent then
				return
			end
			ayarlariYolla(player)
			task.wait(1)
		end
	end)
end

Players.PlayerAdded:Connect(playerAdded)

for _, player in Players:GetPlayers() do
	playerAdded(player)
end
