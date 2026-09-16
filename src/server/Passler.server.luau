--!strict
--[[
	Passler  (Script)
	Yeri: ServerScriptService > Passler

	Robux gecislerinin (Shared > Passler) SAHIPLIK KAYNAGI.

	Her oyuncu icin her gecisin sahipligi MarketplaceService'ten ogrenilir
	ve oyuncunun ustune nitelik olarak yazilir:
	    player:SetAttribute("Pass_Teleporter", true)
	Nitelik istemciye kendiliginden gider; arayuz ve diger sunucu
	scriptleri yalnizca onu okur.

	NEDEN DATASTORE YOK
	Gecis sahipligi Roblox'un kendi kaydi. PlayerData'ya kopyalamak iki
	dogruluk kaynagi yaratir ve iade durumunda ikisi ayrisir.

	SATIN ALMA
	Istemci PassSatinAl ile gecisin adini yollar. ID girilmisse satin alma
	penceresi acilir; girilmemisse "Coming soon!" bildirimi gider.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Passler = require(Shared:WaitForChild("Passler"))

local Bildirim = Net.event("Bildirim")
local PassSatinAl = Net.event("PassSatinAl")

-- Web cagrisi dusukse tekrar denemeden once beklenen sure
local TEKRAR_BEKLEME = 10
local DENEME_SAYISI = 3

local function sahiplikYaz(player: Player, ad: string, sahip: boolean)
	local info = Passler.get(ad)
	if info and player.Parent then
		player:SetAttribute(info.nitelik, sahip)
	end
end

--[[
	Bir gecisin sahipligini ogrenir. Sorgu hata verirse sahiplik false
	VARSAYILMAZ; birkac kez daha denenir. Hic ogrenilemezse nitelik
	yazilmaz (arayuz "satin al" gosterir, gercek sahip bir sonraki girisinde
	gecisine kavusur).
]]
local function kontrol(player: Player, ad: string)
	local info = Passler.get(ad)
	if not info then
		return
	end

	if Passler.TEST_STUDIO and RunService:IsStudio() then
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
			-- Oturum icinde satin alinmissa (ya da adminden verilmisse) geri alinmaz
			if player:GetAttribute(info.nitelik) ~= true then
				sahiplikYaz(player, ad, sonuc == true)
			end
			return
		end

		warn(`[Passler] {player.Name} / {ad} sorgusu basarisiz ({deneme}/{DENEME_SAYISI}): {sonuc}`)
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
		warn(`[Passler] satin alma penceresi acilamadi ({ad}): {hata}`)
	end
end)

--[[
	Satin alma bitti. Web cagrisinin yeni durumu gormesi bazen gecikiyor;
	bu yuzden nitelik dogrudan yazilir.
]]
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
