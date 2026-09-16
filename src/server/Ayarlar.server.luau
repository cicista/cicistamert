--[[
	Ayarlar  (Script)
	Yeri: ServerScriptService > Ayarlar

	Oyuncunun kisisel ayarlarini saklar ve geri verir:

	  uiScale      -- arayuz olcegi yuzdesi (%50..%150, varsayilan %100)
	  musicVolume  -- arka plan muzigi ses yuzdesi (%0..%100, varsayilan %100)
	  musicMuted   -- muzik kapali mi (varsayilan acik)
	  sfxVolume    -- ses efektleri yuzdesi (%0..%100, varsayilan %100)
	  sfxMuted     -- ses efektleri kapali mi (varsayilan acik)
	  shakeOff     -- ekran sarsintisi kapali mi (varsayilan acik); oyuncunun
	                  "SarsintiKapali" niteligine de yazilir, sarsinti yapan
	                  istemci kodlari onu okur

	NEDEN SUNUCUDA
	Roblox'ta istemcinin kalici deposu yok; ayarin oturumlar arasinda
	kalmasi icin oyuncu verisiyle (PlayerData) birlikte DataStore'a
	yazilmasi gerekiyor.

	AKIS
	  1. Oyuncu girer  -> server AyarDurum ile kayitli ayari yollar
	  2. Client gec yuklendiyse AyarKaydet'i degersiz cagirir (nil),
	     server yine mevcut ayari yollar. Boylece "istemci hazir olmadan
	     gonderdim" sorunu olmaz.
	  3. Oyuncu paneli oynatir -> client AyarKaydet ile yeni degeri yollar
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))

local AyarDurum = Net.event("AyarDurum")
local AyarKaydet = Net.event("AyarKaydet")

-- Panelin sinirlariyla ayni; istemciye guvenilmez, deger burada da kirpilir
local OLCEK_MIN = 50
local OLCEK_MAX = 150

local function ayarlariYolla(player: Player)
	local data = PlayerData.get(player) or PlayerData.load(player)
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

--[[
	Client'tan gelen ayar. Deger sayi degilse ya da sinirlarin disindaysa
	yalnizca mevcut ayar geri yollanir -- istemci ne gonderirse gondersin
	veri bozulmaz.
]]
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

--[[
	Giriste ayari yollar. Client scripti henuz baglanmamis olabilir; bu
	yuzden birkac kere tekrarlanir. Client kendi hazir oldugunda zaten
	AyarKaydet ile durum istiyor, iki yol da ayni sonuca cikiyor.
]]
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
