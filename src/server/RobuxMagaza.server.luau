--!strict
--[[
	RobuxMagaza  (Script)
	Yeri: ServerScriptService > RobuxMagaza

	Sag ustteki STORE magazasinin sunucu tarafi. Urunler ve fiyatlar
	Shared > RobuxMagaza'da; Game Pass'ler Passler scriptinde satilir.

	SATIN ALMA AKISI
	  1. Istemci RobuxUrunAl ile urunun ANAHTARINI yollar
	  2. Burasi Roblox'un satin alma penceresini acar
	  3. Oyuncu odeyince Roblox ProcessReceipt'i cagirir; urun burada verilir

	ProcessReceipt OYUNDA TEK YERDE atanabilir (sonra atanan oncekini
	ezer). Baska bir Developer Product eklenirse o da buradan verilmeli.

	AYNI FIS IKI KEZ VERILMEZ
	Roblox fisi, PurchaseGranted donene kadar tekrar tekrar yollar (sunucu
	degisse bile). Bu yuzden fis kimligi urunle AYNI ANDA oyuncunun kaydina
	yazilir ve kayit DataStore'a ulasmadan PurchaseGranted donulmez.
	Kayit basarisizsa NotProcessedYet donulur: Roblox sonra tekrar dener,
	fis zaten kayitli oldugu icin urun ikinci kez verilmez.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local RobuxMagaza = require(Shared:WaitForChild("RobuxMagaza"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))

local Bildirim = Net.event("Bildirim")
local RobuxUrunAl = Net.event("RobuxUrunAl")
-- Sans takviyesi alininca Rot'un ustundeki iksir yazisi guncellensin
local SansDurum = Net.event("RotCoinMagazaDurum")

local YESIL = Color3.fromRGB(140, 230, 160)
local SARI = Color3.fromRGB(255, 200, 90)

-- Ayni oyuncu dugmeye ust uste basarsa pencere tekrar tekrar acilmasin
local PENCERE_ARASI = 1
local sonPencere: { [Player]: number } = {}

local function sansDurumuGonder(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local carpan = PlayerData.luckBonus(player)
	SansDurum:FireClient(player, {
		carpan = carpan,
		kalan = if carpan > 1 then math.max(0, data.luckUntil - os.time()) else 0,
	})
end

--[[
	Sans takviyesi. Parasi odendigi icin HICBIR durumda reddedilmez:
	  - ayni ya da daha guclu takviye aktifse: sure uzar
	  - daha zayif takviye (Rot Coin iksiri) aktifse: yerini alir
]]
local function sansVer(player: Player, data: any, carpan: number, saniye: number)
	local aktif = PlayerData.luckBonus(player)
	if aktif >= carpan - 0.001 then
		data.luckUntil += saniye
	else
		PlayerData.grantLuck(player, carpan, saniye)
	end
end

--[[
	DEDEKTIF KAPILARI

	Inceleme suresini atlama urunu burada odeniyor ama isi Detective
	betigi yapiyor. Iki BindableFunction'la konusuluyor (bkz.
	ServerScriptService > Detective > SUREYI ATLAMA).

	Tembel aliniyor: betikler ayni anda yukleniyor, ust seviyede
	WaitForChild ile beklemek bu betigi kilitleyebilirdi.
]]
local function dedektifKapisi(ad: string): BindableFunction?
	local betik = script.Parent:FindFirstChild("Detective")
	local kapi = betik and betik:FindFirstChild(ad)
	return if kapi and kapi:IsA("BindableFunction") then kapi else nil
end

local function dedektifAtla(player: Player): boolean
	local kapi = dedektifKapisi("DedektifAtla")
	return kapi ~= nil and kapi:Invoke(player) == true
end

local function dedektifBekliyor(player: Player): boolean
	local kapi = dedektifKapisi("DedektifBekliyorMu")
	return kapi ~= nil and kapi:Invoke(player) == true
end

-- Urunu verir. Yalnizca kayittaki veriyi degistirir; bekleme yapmaz.
local function urunVer(player: Player, data: any, urun: RobuxMagaza.Urun)
	if urun.tur == "luckyblock" and urun.tier then
		PlayerData.addLuckyBlocks(player, urun.tier, urun.adet or 1)
	elseif urun.tur == "luck" then
		sansVer(player, data, urun.carpan or 2, urun.saniye or 0)
	elseif urun.tur == "rotcoin" then
		PlayerData.addRotCoins(player, urun.rotCoin or 0)
	elseif urun.tur == "detectiveSkip" then
		--[[
			Dedektifin suresini siler. Isi Detective betigi yapiyor; burasi
			yalnizca odemeyi isleyen yer (ProcessReceipt oyunda TEK yerde
			olabiliyor, bkz. dosya basi).

			Bekleyen is yoksa false doner. Fis yine de kabul ediliyor --
			ProcessReceipt'ten para iadesi yok; onun yerine pencere
			ACILMADAN once bekleyen is var mi diye bakiliyor (asagida).
		]]
		if not dedektifAtla(player) then
			Bildirim:FireClient(
				player,
				"The Detective had already finished -- nothing to skip.",
				Color3.fromRGB(255, 200, 90)
			)
		end
	else
		error(`bilinmeyen urun turu: {urun.tur}`)
	end
end

-- Urun verildikten sonra ekrandakiler (canta, bakiye, iksir yazisi) tazelenir
local function ekraniTazele(player: Player, urun: RobuxMagaza.Urun)
	if urun.tur == "luckyblock" then
		Envanter.syncLuckyBlocks(player)
	elseif urun.tur == "luck" then
		sansDurumuGonder(player)
	end
	Envanter.push(player)
end

local function fisIsle(fis: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(fis.PlayerId)
	if not player then
		-- Oyuncu cikmis: bir sonraki girisinde (hangi sunucu olursa) verilir
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = PlayerData.get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local fisId = tostring(fis.PurchaseId)

	-- Daha once verilmis: yalnizca kaydin DataStore'a ulastigindan emin ol
	if data.purchases[fisId] then
		return if PlayerData.save(player)
			then Enum.ProductPurchaseDecision.PurchaseGranted
			else Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local urun = RobuxMagaza.idIle(fis.ProductId)
	if not urun then
		warn(`[RobuxMagaza] tanimsiz urun ID'si {fis.ProductId} ({player.Name}); Shared > RobuxMagaza'ya ekle`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Fis ve urun ayni anda yazilir (arada bekleme yok)
	data.purchases[fisId] = os.time()
	local ok, hata = pcall(urunVer, player, data, urun)
	if not ok then
		-- Hicbir sey verilmediyse fis geri alinir, Roblox tekrar dener
		data.purchases[fisId] = nil
		warn(`[RobuxMagaza] {urun.anahtar} verilemedi ({player.Name}): {hata}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Ekran hatasi satin almayi bozmasin
	pcall(ekraniTazele, player, urun)
	Bildirim:FireClient(player, `Thank you! You got {urun.ad}!`, YESIL)

	if not PlayerData.save(player) then
		-- Urun ve fis bellekte; kayit sonra (otomatik ya da cikista) gider
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.ProcessReceipt = function(fis)
	local ok, sonuc = pcall(fisIsle, fis)
	if ok then
		return sonuc
	end
	warn(`[RobuxMagaza] fis islenemedi: {sonuc}`)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

RobuxUrunAl.OnServerEvent:Connect(function(player, anahtar)
	if type(anahtar) ~= "string" then
		return
	end

	local urun = RobuxMagaza.get(anahtar)
	if not urun then
		return
	end

	local simdi = os.clock()
	if simdi - (sonPencere[player] or -math.huge) < PENCERE_ARASI then
		return
	end
	sonPencere[player] = simdi

	--[[
		ATLANACAK BIR SEY YOKSA PENCERE ACILMAZ

		ProcessReceipt'ten para iadesi yok: pencere acilip oyuncu oderse
		odeme gecer. Bu yuzden denetim odemeden ONCE burada yapiliyor.
	]]
	if urun.tur == "detectiveSkip" and not dedektifBekliyor(player) then
		Bildirim:FireClient(player, "The Detective is not working on anything.", SARI)
		return
	end

	if not RobuxMagaza.satista(urun) then
		Bildirim:FireClient(player, `{urun.ad} is coming soon!`, SARI)
		return
	end

	local ok, hata = pcall(function()
		MarketplaceService:PromptProductPurchase(player, urun.id)
	end)
	if not ok then
		warn(`[RobuxMagaza] satin alma penceresi acilamadi ({anahtar}): {hata}`)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	sonPencere[player] = nil
end)
