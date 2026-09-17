--!strict
--[[
	Hiz  (Script)
	Yeri: ServerScriptService > Hiz

	Hiz yukseltmesi (Shared > Hiz):
	  - HizAl ile gelen istegi dogrular, Rot'u duser, seviyeyi arttirir
	  - oyuncunun yurume hizini uygular (her dogusta da)
	  - seviyeyi oyuncunun ustune "SpeedLevel" niteligi olarak yazar;
	    istemci paneli ve bas ustu yazisi buradan okur

	REBIRTH
	HizRebirth: Speed 101'deki oyuncunun seviyesi sifirlanir, rebirth sayisi
	artar ve karakterin arkasina iz (Trail) takilir. Iz her dogusta yeniden
	kurulur; boyu ve rengi rebirth sayisindan gelir (Shared > Hiz).

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
local HizRebirth = Net.event("HizRebirth")

local IZ_ADI = "HizIzi"

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

-- Karakterin arkasindaki rebirth izi
local function iziKur(player: Player)
	local data = PlayerData.get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not root then
		return
	end

	player:SetAttribute(Hiz.RebirthNitelik, data.speedRebirth)

	local eski = root:FindFirstChild(IZ_ADI)
	if eski then
		eski:Destroy()
	end
	for _, ad in { "HizIziUst", "HizIziAlt" } do
		local a = root:FindFirstChild(ad)
		if a then
			a:Destroy()
		end
	end

	local renk = Hiz.rebirthRengi(data.speedRebirth)
	if not renk then
		return
	end

	-- Govde boyunca dik bir serit: omuzdan kalcaya
	local ust = Instance.new("Attachment")
	ust.Name = "HizIziUst"
	ust.Position = Vector3.new(0, 0.9, 0.4)
	ust.Parent = root

	local alt = Instance.new("Attachment")
	alt.Name = "HizIziAlt"
	alt.Position = Vector3.new(0, -1, 0.4)
	alt.Parent = root

	local iz = Instance.new("Trail")
	iz.Name = IZ_ADI
	iz.Attachment0 = ust
	iz.Attachment1 = alt
	iz.Color = ColorSequence.new(renk)
	iz.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	iz.Lifetime = Hiz.izOmru(data.speedRebirth)
	iz.MinLength = 0.1
	iz.LightEmission = 0.7
	iz.FaceCamera = false
	iz.Parent = root
end

local function oyuncuHazirla(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		character:WaitForChild("HumanoidRootPart", 10)
		hiziUygula(player)
		iziKur(player)
		Seviye.etiketGuncelle(player)
	end)

	-- Veri yuklenene kadar bekle
	task.spawn(function()
		while player.Parent and not PlayerData.get(player) do
			task.wait(0.25)
		end
		if player.Parent then
			hiziUygula(player)
			iziKur(player)
			Seviye.etiketGuncelle(player)
		end
	end)
end

hizYenile.Event:Connect(function(player: Player)
	hiziUygula(player)
	iziKur(player)
	Seviye.etiketGuncelle(player)
end)

HizRebirth.OnServerEvent:Connect(function(player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	if data.speedRebirth >= Hiz.MaxRebirth then
		Bildirim:FireClient(player, "You reached the final rebirth!", Color3.fromRGB(255, 200, 90))
		return
	end
	if data.speedLevel < Hiz.Max then
		Bildirim:FireClient(player, `Reach Speed {Hiz.Max + 1} to rebirth!`, Color3.fromRGB(255, 200, 90))
		return
	end

	data.speedRebirth += 1
	data.speedLevel = 0
	hiziUygula(player)
	iziKur(player)
	Seviye.etiketGuncelle(player)
	Envanter.push(player)

	Bildirim:FireClient(
		player,
		`SPEED REBIRTH {data.speedRebirth}! Your trail got longer.`,
		Hiz.rebirthRengi(data.speedRebirth) or Color3.new(1, 1, 1)
	)
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
			`Not enough Rot! You need {Format.short(fiyat - data.rot)} more Rot for Speed +{adet}.`,
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
