--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Adimlar = require(Shared:WaitForChild("Ogretici"))

local PlayerData = require(script.Parent.PlayerData)
local Patlama = require(script.Parent.Patlama)

local remoteler: { [string]: RemoteEvent } = {}

local function remote(ad: string): RemoteEvent
	local mevcut = remoteler[ad]
	if not mevcut then
		mevcut = Net.event(ad)
		remoteler[ad] = mevcut
	end
	return mevcut
end

local Ogretici = {}

Ogretici.Nitelik = "OgreticiAdim"

local hedefKonum: { [Player]: Vector3 } = {}

function Ogretici.hedefKonumAyarla(player: Player, konum: Vector3?)
	if hedefKonum[player] == konum then
		return
	end
	hedefKonum[player] = konum
	Ogretici.gonder(player)
end

local function elindeBrainrotVar(data: any): boolean
	if type(data.inventory) == "table" and #data.inventory > 0 then
		return true
	end

	local is = data.detectiveJob
	return is ~= nil and type(is.items) == "table" and #is.items > 0
end

local function geriDus(data: any)
	if data.tutorial.bitti then
		return
	end

	local adim = Adimlar.adim(data.tutorial.adim)
	if not adim then
		return
	end

	if (adim.id == "ilkCollect" or adim.id == "slot") and not elindeBrainrotVar(data) then
		data.tutorial.adim = 1
	end
end

function Ogretici.gonder(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	geriDus(data)

	local adim = Adimlar.adim(data.tutorial.adim)
	player:SetAttribute(Ogretici.Nitelik, if data.tutorial.bitti or not adim then nil else adim.id)

	remote("OgreticiDurum"):FireClient(player, {
		adim = data.tutorial.adim,
		bitti = data.tutorial.bitti,
		toplam = Adimlar.adimSayisi(),
		konum = hedefKonum[player],
	})
end

local function kazilanListesi(data: any): { string }
	local t = data.tutorial
	if type(t.kazilan) ~= "table" then
		t.kazilan = {}
	end
	return t.kazilan
end

Ogretici.UcAdet = Adimlar.UcAdet or 3

function Ogretici.kaziKaydet(player: Player, uid: string?)
	local data = PlayerData.get(player)
	if not data or type(uid) ~= "string" then
		return
	end
	if Ogretici.bekleyen(player) ~= "ucKazdi" then
		return
	end

	local liste = kazilanListesi(data)
	for _, mevcut in liste do
		if mevcut == uid then
			return
		end
	end

	table.insert(liste, uid)
	if #liste >= Ogretici.UcAdet then
		Ogretici.olay(player, "ucKazdi")
	end
end

local function hepsiAcildi(data: any): boolean
	local liste = kazilanListesi(data)
	if #liste < Ogretici.UcAdet then
		return false
	end

	local acik: { [string]: boolean } = {}
	for _, item in data.inventory do
		if item.revealed and item.name then
			acik[item.uid] = true
		end
	end

	for _, uid in liste do
		if not acik[uid] then
			return false
		end
	end
	return true
end

function Ogretici.adimId(player: Player): string?
	local data = PlayerData.get(player)
	if not data or data.tutorial.bitti then
		return nil
	end
	local adim = Adimlar.adim(data.tutorial.adim)
	return if adim then adim.id else nil
end

local function odullendir(player: Player, adim: Adimlar.Adim, sira: number)
	PlayerData.addRotCoins(player, Adimlar.RotCoinOdulu)
	Patlama.oynat(player, Adimlar.PatlamaOlcegi, true, Adimlar.PatlamaRengi)

	local son = sira >= Adimlar.adimSayisi()
	local yazi = if son
		then `Tutorial complete!  +{Adimlar.RotCoinOdulu} Rot Coin`
		else `{adim.yazi}  done!  +{Adimlar.RotCoinOdulu} Rot Coin`
	remote("Bildirim"):FireClient(player, yazi, Adimlar.IsaretRengi)
end

function Ogretici.olay(player: Player, olay: string)
	local data = PlayerData.get(player)
	if not data or data.tutorial.bitti then
		return
	end

	local sira = data.tutorial.adim
	local adim = Adimlar.adim(sira)
	if not adim or adim.olay ~= olay then
		return
	end

	odullendir(player, adim, sira)

	hedefKonum[player] = nil

	if adim.id == "ucCollect" then
		data.tutorial.kazilan = {}
	end

	if sira >= Adimlar.adimSayisi() then
		data.tutorial.bitti = true
	else
		data.tutorial.adim = sira + 1
	end

	Ogretici.gonder(player)
end

function Ogretici.bekleyen(player: Player): string?
	local data = PlayerData.get(player)
	if not data or data.tutorial.bitti then
		return nil
	end
	local adim = Adimlar.adim(data.tutorial.adim)
	return if adim then adim.olay else nil
end

function Ogretici.ayniKademeVar(player: Player, adet: number, yalnizcaAcik: boolean?): boolean
	local data = PlayerData.get(player)
	if not data then
		return false
	end

	local sayac: { [string]: number } = {}
	for _, item in data.inventory do
		if yalnizcaAcik and not item.revealed then
			continue
		end
		local yeni = (sayac[item.rarity] or 0) + 1
		if yeni >= adet then
			return true
		end
		sayac[item.rarity] = yeni
	end

	return false
end

function Ogretici.ucKontrol(player: Player)
	local bekleyen = Ogretici.bekleyen(player)
	if bekleyen ~= "ucCollectledi" then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local bitti = if #kazilanListesi(data) >= Ogretici.UcAdet
		then hepsiAcildi(data)
		else Ogretici.ayniKademeVar(player, Ogretici.UcAdet, true)

	if bitti then
		Ogretici.olay(player, "ucCollectledi")
	end
end

local Config = require(Shared:WaitForChild("OyunConfig"))
local Shovels = require(Shared:WaitForChild("Shovels"))

local IP = Adimlar.AdaIpucu
local KI = Adimlar.KurekIpucu

local function ipucuFiyati(): number
	local ada = Config.Islands[IP.ada]
	return if ada then tonumber(ada.price) or math.huge else math.huge
end

local function ipucuKontrol(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	local uygun = data.tutorial.bitti
		and not data.tutorial.adaIpucu
		and data.islands < IP.ada
		and data.rot >= ipucuFiyati()
		and player:GetAttribute(KI.nitelik) ~= true

	if uygun then
		if player:GetAttribute(IP.nitelik) ~= true then
			player:SetAttribute(IP.nitelik, true)
		end
		return
	end

	if data.islands >= IP.ada and not data.tutorial.adaIpucu then
		data.tutorial.adaIpucu = true
		if player:GetAttribute(IP.nitelik) == true then
			remote("Bildirim"):FireClient(player, IP.varis, IP.renk)
		end
	end

	if player:GetAttribute(IP.nitelik) ~= nil then
		player:SetAttribute(IP.nitelik, nil)
	end
end

local function kurekAlindi(data: PlayerData.Data): boolean
	local hedef = Shovels.Info[KI.kurek]
	local sahip = Shovels.Info[data.shovelMax]
	return hedef ~= nil and sahip ~= nil and sahip.level >= hedef.level
end

local function kurekIpucuKontrol(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	local hedef = Shovels.Info[KI.kurek]
	local fiyat = if hedef then hedef.price else math.huge

	if kurekAlindi(data) then
		if not data.tutorial.kurekIpucu then
			data.tutorial.kurekIpucu = true
			if player:GetAttribute(KI.nitelik) == true then
				remote("Bildirim"):FireClient(player, KI.varis, KI.renk)
			end
		end
		if player:GetAttribute(KI.nitelik) ~= nil then
			player:SetAttribute(KI.nitelik, nil)
		end
		return
	end

	local uygun = data.tutorial.bitti and not data.tutorial.kurekIpucu and data.rot >= fiyat

	if uygun then
		if player:GetAttribute(KI.nitelik) ~= true then
			player:SetAttribute(KI.nitelik, true)
		end
	elseif player:GetAttribute(KI.nitelik) ~= nil then
		player:SetAttribute(KI.nitelik, nil)
	end
end

task.spawn(function()
	while true do
		task.wait(2)
		for _, player in game:GetService("Players"):GetPlayers() do
			pcall(ipucuKontrol, player)
			pcall(kurekIpucuKontrol, player)
		end
	end
end)

task.spawn(function()
	remote("OgreticiIste").OnServerEvent:Connect(function(player)
		Ogretici.gonder(player)
	end)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	hedefKonum[player] = nil
end)

return Ogretici
