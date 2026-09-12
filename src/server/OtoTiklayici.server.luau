--!strict
--[[
	OtoTiklayici  (Script)
	Yeri: ServerScriptService > OtoTiklayici

	Otomatik tiklayici Pass'inin SAHIPLIK KAYNAGI.

	Tiklamanin kendisi istemcide olur (bkz. Minigame.client): bu script
	yalnizca "bu oyuncu passi almis mi" sorusunu cevaplar ve cevabi
	istemciye bildirir.

	--------------------------------------------------------------
	NEDEN DATASTORE YOK

	Pass sahipligi Roblox'un kendi kaydi. PlayerData'ya kopyalamak iki
	dogruluk kaynagi yaratir ve iade/geri alma durumunda ikisi ayrisir.
	Tek kaynak MarketplaceService.

	--------------------------------------------------------------
	NEDEN SUNUCU KONTROLU YETERLI

	Otomatik tiklayici oyuna yeni bir GUC katmiyor; zaten var olan
	tiklamayi oyuncu yerine yapiyor. Pass'i olmayan biri istemcisini
	kirip otomatik tiklatsa kazanabilecegi en fazla sey, eliyle hizli
	tiklayarak da kazanabilecegi seydir -- kazi tavani (MAX_CPS) ve
	KaziSistemi'ndeki sure/erisilebilirlik dogrulamasi yerinde durur.

	Bu yuzden burada agir bir dogrulama yok: sahiplik bilgisi arayuzun
	dugmeyi hangi halde cizecegini bilmesi icin gonderiliyor.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local OtoTiklayici = require(Shared:WaitForChild("OtoTiklayici"))

local OtoTiklayiciDurum = Net.event("OtoTiklayiciDurum")
local OtoTiklayiciSor = Net.event("OtoTiklayiciSor")

--[[
	Pass ID girilmediyse script tamamen susar: ne web cagrisi yapar ne
	istemciye bir sey soyler. Istemci de dugmeyi cizmez (bkz.
	OtoTiklayici.kurulu). Ozellik ID girilene kadar uyur.
]]
if not OtoTiklayici.kurulu() then
	if OtoTiklayici.gorunur() then
		-- Studio test kapisi acik: dugme cikar ama sahiplik sorulmaz
		print("[OtoTiklayici] GAMEPASS_ID yok -- Studio TEST kapisi acik, dugme calisir")
	else
		warn("[OtoTiklayici] GAMEPASS_ID girilmemis, ozellik kapali (Shared > OtoTiklayici)")
	end
	return
end

--[[
	Oyuncu basina cevap onbellegi.

	nil  = henuz bilinmiyor (ya da son deneme hata verdi)
	true/false = bilinen cevap

	Sahiplik oyun icinde yalnizca TEK yone degisebilir (almak), onu da
	PromptGamePassPurchaseFinished'den duyuyoruz. Yani true'ya dondukten
	sonra tekrar sormaya gerek yok.
]]
local sahip: { [Player]: boolean } = {}

-- Basarisiz denemeden sonra tekrar denemek icin en erken zaman
local sonraDene: { [Player]: number } = {}

-- Hata sonrasi bekleme: web cagrisi dusukse her karede tekrar denenmesin
local RETRY_BEKLEME = 10

local function bildir(player: Player)
	if player.Parent == nil then
		return
	end
	OtoTiklayiciDurum:FireClient(player, sahip[player] == true)
end

--[[
	Sahipligi ogren ve istemciye bildir.

	Cevap onbellekteyse web'e hic gitmez. Hata alirsa sahipligi false
	VARSAYMAZ, bilinmiyor olarak birakir: gecici bir kesintide passini
	alan oyuncunun dugmesi "satin al" haline donmesin.
]]
local function kontrol(player: Player)
	if sahip[player] ~= nil then
		bildir(player)
		return
	end

	local simdi = os.clock()
	if (sonraDene[player] or 0) > simdi then
		bildir(player)
		return
	end

	local ok, sonuc = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, OtoTiklayici.GAMEPASS_ID)
	end)

	if not ok then
		sonraDene[player] = simdi + RETRY_BEKLEME
		warn(`[OtoTiklayici] {player.Name} icin sahiplik sorgusu basarisiz: {sonuc}`)
		bildir(player)
		return
	end

	sahip[player] = sonuc == true
	bildir(player)
end

Players.PlayerAdded:Connect(kontrol)
for _, player in Players:GetPlayers() do
	task.spawn(kontrol, player)
end

Players.PlayerRemoving:Connect(function(player)
	sahip[player] = nil
	sonraDene[player] = nil
end)

-- Istemci arayuzu acildiginda durumunu ister
OtoTiklayiciSor.OnServerEvent:Connect(function(player)
	kontrol(player)
end)

--[[
	Satin alma bitti.

	Roblox bu olayi satin alma penceresi KAPANDIGINDA veriyor; kisi
	vazgectiyse purchased false gelir. Alindiysa onbellegi dogrudan
	guncelliyoruz -- web cagrisinin yeni durumu gormesi bazen gecikiyor.
]]
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
	if gamePassId ~= OtoTiklayici.GAMEPASS_ID then
		return
	end

	if purchased then
		sahip[player] = true
		sonraDene[player] = nil
	end

	bildir(player)
end)
