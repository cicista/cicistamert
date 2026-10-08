--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Passler = require(Shared:WaitForChild("Passler"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))

local Bildirim = Net.event("Bildirim")
local PassSatinAl = Net.event("PassSatinAl")

local PassYenile = Instance.new("BindableEvent")
PassYenile.Name = "PassYenile"
PassYenile.Parent = script

local TEKRAR_BEKLEME = 10
local DENEME_SAYISI = 3

local function sahiplikYaz(player: Player, ad: string, sahip: boolean)
	local info = Passler.get(ad)
	if not info or not player.Parent then
		return
	end

	player:SetAttribute("PassKalici_" .. ad, sahip)

	if sahip then
		player:SetAttribute(info.nitelik, true)
	elseif player:GetAttribute("PassSure_" .. ad) == nil then
		player:SetAttribute(info.nitelik, false)
	end
end

local function kontrol(player: Player, ad: string)
	local info = Passler.get(ad)
	if not info then
		return
	end

	if Passler.TEST_STUDIO and RunService:IsStudio() then
		sahiplikYaz(player, ad, true)
		return
	end

	local data = PlayerData.bekle(player)
	if data and data.giftedPasses[ad] == true then
		sahiplikYaz(player, ad, true)
		return
	end

	if info.id <= 0 then
		sahiplikYaz(player, ad, false)
		return
	end

	for deneme = 1, DENEME_SAYISI do
		local ok, sonuc = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, info.id)
		end)

		if ok then
			if player:GetAttribute(info.nitelik) ~= true then
				sahiplikYaz(player, ad, sonuc == true)
			end
			return
		end

		warn(`[Passler] {player.Name} / {ad} query failed ({deneme}/{DENEME_SAYISI}): {sonuc}`)
		if not player.Parent then
			return
		end
		task.wait(TEKRAR_BEKLEME)
	end
end

local function oyuncuGeldi(player: Player)
	for ad in Passler.Info do
		task.spawn(kontrol, player, ad)
	end
end

PassYenile.Event:Connect(function(player: Player, ad: string)
	local info = Passler.get(ad)
	if not info or not player.Parent then
		return
	end

	player:SetAttribute("PassKalici_" .. ad, false)
	if player:GetAttribute("PassSure_" .. ad) == nil then
		player:SetAttribute(info.nitelik, false)
	end
	task.spawn(kontrol, player, ad)
end)

Players.PlayerAdded:Connect(oyuncuGeldi)
for _, player in Players:GetPlayers() do
	oyuncuGeldi(player)
end

PassSatinAl.OnServerEvent:Connect(function(player, ad)
	if type(ad) ~= "string" then
		return
	end

	local info = Passler.get(ad)
	if not info then
		return
	end

	if Passler.sahip(player, ad) then
		return
	end

	if info.id <= 0 then
		Bildirim:FireClient(player, `{info.ad} is coming soon!`, Color3.fromRGB(255, 200, 90))
		return
	end

	local ok, hata = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, info.id)
	end)
	if not ok then
		warn(`[Passler] purchase prompt could not be opened ({ad}): {hata}`)
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
	local ad = Passler.adiniBul(gamePassId)
	if not ad or not purchased then
		return
	end

	sahiplikYaz(player, ad, true)
	local info = Passler.get(ad)
	if info then
		Bildirim:FireClient(player, `{info.ad} unlocked!`, Color3.fromRGB(140, 230, 160))
	end
end)
