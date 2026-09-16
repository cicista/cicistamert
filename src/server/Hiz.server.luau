--!strict
--[[
	Hiz  (Script)
	Yeri: ServerScriptService > Hiz

	Hiz yukseltmesi (Shared > Hiz):
	  - HizAl ile gelen istegi dogrular, Rot'u duser, seviyeyi arttirir
	  - oyuncunun yurume hizini uygular (her dogusta da)
	  - seviyeyi oyuncunun ustune "SpeedLevel" niteligi olarak yazar;
	    istemci paneli ve bas ustu yazisi buradan okur

	FLYBOARD
	Flyboard binerken taban hizi Humanoid'in "FlyboardTabanHiz"
	niteliginde tutuyor ve her karede bonusu onun ustune ekliyor. Oyuncu
	tahtadayken hiz alirsa WalkSpeed degil o nitelik guncellenir; tahta
	yeni hizi kendisi uygular, inince de o hizda kalinir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Hiz = require(Shared:WaitForChild("Hiz"))
local Format = require(Shared:WaitForChild("Format"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))
local Seviye = require(Modules:WaitForChild("Seviye"))

local Bildirim = Net.event("Bildirim")
local HizAl = Net.event("HizAl")

-- Admin paneli seviyeyi degistirince hizi yeniden uygulatir
local hizYenile = Instance.new("BindableEvent")
hizYenile.Name = "HizYenile"
hizYenile.Parent = script

local FLYBOARD_TABAN = "FlyboardTabanHiz"
-- Tek istekte en fazla kac yukseltme alinabilir (panelde x1 ve x10 var)
local TOPLU_EN_FAZLA = 10

local function hiziUygula(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	player:SetAttribute(Hiz.Nitelik, data.speedLevel)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local hiz = Hiz.hiz(data.speedLevel)
	if humanoid:GetAttribute(FLYBOARD_TABAN) ~= nil then
		humanoid:SetAttribute(FLYBOARD_TABAN, hiz)
	else
		humanoid.WalkSpeed = hiz
	end
end

local function oyuncuHazirla(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		hiziUygula(player)
		Seviye.etiketGuncelle(player)
	end)

	-- Veri yuklenene kadar bekle
	task.spawn(function()
		while player.Parent and not PlayerData.get(player) do
			task.wait(0.25)
		end
		if player.Parent then
			hiziUygula(player)
			Seviye.etiketGuncelle(player)
		end
	end)
end

hizYenile.Event:Connect(function(player: Player)
	hiziUygula(player)
	Seviye.etiketGuncelle(player)
end)

Players.PlayerAdded:Connect(oyuncuHazirla)
for _, player in Players:GetPlayers() do
	oyuncuHazirla(player)
end

HizAl.OnServerEvent:Connect(function(player, adet)
	local data = PlayerData.get(player)
	if not data or type(adet) ~= "number" then
		return
	end

	adet = math.clamp(math.floor(adet), 1, TOPLU_EN_FAZLA)
	adet = math.min(adet, Hiz.Max - data.speedLevel)
	if adet <= 0 then
		Bildirim:FireClient(player, "Your speed is already maxed!", Color3.fromRGB(255, 200, 90))
		return
	end

	local fiyat = Hiz.topluFiyat(data.speedLevel, adet)
	if data.rot < fiyat then
		Bildirim:FireClient(
			player,
			`Not enough Rot! You need {Format.short(fiyat)} Rot.`,
			Color3.fromRGB(255, 90, 90)
		)
		return
	end

	PlayerData.addRot(player, -fiyat)
	data.speedLevel += adet
	hiziUygula(player)
	Seviye.etiketGuncelle(player)
	Envanter.push(player)

	Bildirim:FireClient(
		player,
		`Speed {data.speedLevel + 1}!  (x{string.format("%.2f", Hiz.carpan(data.speedLevel))} walk speed)`,
		Hiz.renk(data.speedLevel + 1)
	)
end)
