local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Seviye = require(Modules:WaitForChild("Seviye"))

local AyarDurum = Net.event("AyarDurum")
local AyarKaydet = Net.event("AyarKaydet")

local OLCEK_MIN = 50
local OLCEK_MAX = 150

local ACIK_KAPALI = {
	shakeOff = "SarsintiKapali",
	hintsOff = "RehberKapali",
	beamSoundOff = "SuzmeSesiKapali",
	fuseAnimOff = "FuseAnimasyonKapali",
	hideTitle = "UnvanGizli",
	hideName = "IsimGizli",
	hideLevel = "LevelGizli",
	hideSpeed = "HizGizli",
	hideOthers = "HerkesEtiketGizli",
}

local function ayarlariYolla(player: Player)
	local data = PlayerData.bekle(player)
	if not data then
		return
	end
	for alan, nitelik in ACIK_KAPALI do
		player:SetAttribute(nitelik, (data :: any)[alan] == true)
	end
	AyarDurum:FireClient(player, {
		uiScale = data.uiScale or 100,
		uiScaleMobile = data.uiScaleMobile or OLCEK_MIN,
		musicVolume = data.musicVolume or 100,
		musicMuted = data.musicMuted == true,
		sfxVolume = data.sfxVolume or 100,
		sfxMuted = data.sfxMuted == true,
		shakeOff = data.shakeOff == true,
		hintsOff = data.hintsOff == true,
	})
end

local function sonluSayi(deger: any): number?
	local sayi = tonumber(deger)
	if not sayi or sayi ~= sayi or math.abs(sayi) == math.huge then
		return nil
	end
	return sayi
end

AyarKaydet.OnServerEvent:Connect(function(player: Player, payload: any)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	if type(payload) == "table" then
		local yuzde = sonluSayi(payload.uiScale)
		if yuzde then
			data.uiScale = math.clamp(math.round(yuzde), OLCEK_MIN, OLCEK_MAX)
		end
		local mobil = sonluSayi(payload.uiScaleMobile)
		if mobil then
			data.uiScaleMobile = math.clamp(math.round(mobil), OLCEK_MIN, OLCEK_MAX)
		end

		local ses = sonluSayi(payload.musicVolume)
		if ses then
			data.musicVolume = math.clamp(math.round(ses), 0, 100)
		end
		if type(payload.musicMuted) == "boolean" then
			data.musicMuted = payload.musicMuted
		end

		local efekt = sonluSayi(payload.sfxVolume)
		if efekt then
			data.sfxVolume = math.clamp(math.round(efekt), 0, 100)
		end
		if type(payload.sfxMuted) == "boolean" then
			data.sfxMuted = payload.sfxMuted
		end
		local etiketDegisti = false
		for alan in ACIK_KAPALI do
			local deger = payload[alan]
			if type(deger) == "boolean" then
				if (data :: any)[alan] ~= deger and string.sub(alan, 1, 4) == "hide" then
					etiketDegisti = true
				end
				(data :: any)[alan] = deger
			end
		end
		if etiketDegisti then
			Seviye.etiketGuncelle(player)
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
