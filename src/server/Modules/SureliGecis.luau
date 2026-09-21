--!strict
--[[
	SURELI GECISLER  --  odullerden cikan gecici Auto Clicker / Teleporter

	Oyuncu bir sure boyunca gecise SAHIPMIS GIBI davranir: gecisin kendi
	niteligi (orn. Pass_AutoClicker) aciliyor, yani Passler.sahip'i okuyan
	butun sistemler hicbir degisiklik olmadan calisiyor.

	SURE MUTLAK ZAMANLA tutuluyor (os.time): sunucu yeniden baslasa da
	oyuncu cikip girse de kalan sure dogru. Kayit PlayerData.tempPasses'te.

	ARAYUZ ICIN AYRI BIR NITELIK var: Pass_AutoClicker yalnizca "var/yok"
	der, ne zaman bitecegini soylemez. Sayacin geri sayabilmesi icin bitis
	ani da yaziliyor:

	    player:GetAttribute("PassSure_AutoClicker")  -- os.time cinsinden

	Kalici gecisi olan oyuncuya sureli verilmez: bakiyeyi bosa harcamasin.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Passler = require(Shared:WaitForChild("Passler"))

local PlayerData = require(script.Parent.PlayerData)

local SureliGecis = {}

-- Arayuzun okudugu bitis-ani niteliginin onadi
SureliGecis.SureNiteligi = "PassSure_"

local function sureAdi(gecisAdi: string): string
	return SureliGecis.SureNiteligi .. gecisAdi
end

--[[
	Niteligi ve sayaci gecerli duruma getirir.

	Sure dolmussa kayittan silinir; gecisin kendi niteligi yalnizca SURELI
	haktan geliyorsa kapatilir. Kalici sahipligi olanin niteligine
	dokunulmaz (onu Passler kendi dogruluyor).
]]
local function uygula(player: Player, gecisAdi: string)
	local data = PlayerData.get(player)
	local info = Passler.get(gecisAdi)
	if not data or not info then
		return
	end

	local bitis = data.tempPasses[gecisAdi]
	local kalan = if bitis then bitis - os.time() else 0

	if kalan <= 0 then
		data.tempPasses[gecisAdi] = nil
		player:SetAttribute(sureAdi(gecisAdi), nil)
		--[[
			Niteligi yalnizca SURELI hak actiysa kapatiyoruz. Kalici
			sahiplik varsa Passler zaten onu tekrar aciyor; burada
			kapatmak oyuncunun satin aldigi gecisi elinden alirdi.
		]]
		if player:GetAttribute("PassKalici_" .. gecisAdi) ~= true then
			player:SetAttribute(info.nitelik, nil)
		end
		return
	end

	player:SetAttribute(info.nitelik, true)
	player:SetAttribute(sureAdi(gecisAdi), bitis)

	-- Sure dolunca kendiliginden kapansin
	task.delay(kalan + 1, function()
		if player.Parent then
			uygula(player, gecisAdi)
		end
	end)
end

--[[
	Sureli hak verir. Ayni gecis tekrar verilirse sure UZAR, ustune biner.
	Kalici sahipligi olana verilmez (bakiyesi bosa gitmesin).
]]
function SureliGecis.ver(player: Player, gecisAdi: string, saniye: number): boolean
	local data = PlayerData.get(player)
	local info = Passler.get(gecisAdi)
	if not data or not info or saniye <= 0 then
		return false
	end

	if player:GetAttribute("PassKalici_" .. gecisAdi) == true then
		return false
	end

	local simdi = os.time()
	local mevcut = data.tempPasses[gecisAdi]
	local taban = if mevcut and mevcut > simdi then mevcut else simdi
	data.tempPasses[gecisAdi] = taban + math.floor(saniye)

	uygula(player, gecisAdi)
	return true
end

-- Kalan sure (saniye); hak yoksa 0
function SureliGecis.kalan(player: Player, gecisAdi: string): number
	local data = PlayerData.get(player)
	if not data then
		return 0
	end
	local bitis = data.tempPasses[gecisAdi]
	return if bitis then math.max(0, bitis - os.time()) else 0
end

--[[
	Oyuncu girince kayittaki butun sureli haklari yeniden kurar.
	PlayerData yuklendikten SONRA cagrilmali.
]]
function SureliGecis.kur(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	for gecisAdi in data.tempPasses do
		uygula(player, gecisAdi)
	end
end

return SureliGecis
