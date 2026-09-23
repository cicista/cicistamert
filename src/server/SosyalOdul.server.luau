--[[
	SosyalOdul  (Script)
	Yeri: ServerScriptService > SosyalOdul

	Rewards panelinin Playtime ve Social Rewards sekmelerinin sunucu tarafi.
	Ayarlar Shared > SosyalOdul'da; KODLAR yalnizca burada (istemci goremez).

	Her istek sunucuda dogrulanir:
	  grup     -- gruba uye mi (Roblox'a sorulur), daha once alinmis mi
	  like     -- daha once alinmis mi (begeni Roblox'ta dogrulanamiyor)
	  playtime -- oturum suresi yetiyor mu, bu oturumda alinmis mi
	  kod      -- gecerli mi, bu hesap daha once kullanmis mi
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local SosyalOdul = require(Shared:WaitForChild("SosyalOdul"))
local Passler = require(Shared:WaitForChild("Passler"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))
local SureliGecis = require(Modules:WaitForChild("SureliGecis"))

local Bildirim = Net.event("Bildirim")
local EkOdulAc = Net.event("EkOdulAc")
local EkOdulAl = Net.event("EkOdulAl")
local EkOdulDurum = Net.event("EkOdulDurum")
local KodKullan = Net.event("KodKullan")
local KodSonuc = Net.event("KodSonuc")

local SARI = Color3.fromRGB(255, 215, 40)
local KIRMIZI = Color3.fromRGB(255, 120, 120)

--[[
	KODLAR  --  yeni kod eklemek icin buraya bir satir yaz.

	Anahtar BUYUK HARFLE yazilir; oyuncunun yazdigi kod buyuk/kucuk harf ve
	bosluk gozetmeden karsilastirilir ("release" = "RELEASE").
	Her kod hesap basina bir kez kullanilir.
]]
local KODLAR: { [string]: { rotCoins: number } } = {
	RELEASE = { rotCoins = 5 },
}

--[[
	PLAYTIME SAYACI  --  oturumun degil GUNUN sayaci

	Eskiden sure her giriste sifirdan sayiliyor, alinan basamaklar da yalniz
	bu tabloda duruyordu: oyuncu cikip girince hepsi yenileniyordu. Artik
	toplam sure ve alinan basamaklar KAYITTA (bkz. PlayerData.playtime*) ve
	gun degisince sifirlaniyor.

	Burada tutulan tek sey `son`: kayda en son ne zaman sure islendigi.
	Aradaki fark, durum her sorulduğunda kayda ekleniyor.
]]
local oturum: { [Player]: { son: number } } = {}

-- Ust uste gelen istekler ayni odulu iki kez vermesin
local mesgul: { [Player]: boolean } = {}
local sonKod: { [Player]: number } = {}

--[[
	Son islemeden bu yana gecen sureyi kayda ekler ve o gunun TOPLAM
	suresini dondurur. Veri henuz yuklenmediyse sayac baslamaz -- yukleme
	beklerken gecen sure odule saydirilmaz.
]]
local function playtimeTazele(player: Player): number
	local simdi = os.clock()
	local o = oturum[player]
	if not o then
		o = { son = simdi }
		oturum[player] = o
	end

	local gecen = simdi - o.son
	o.son = simdi

	if not PlayerData.get(player) then
		return 0
	end
	return PlayerData.playtimeEkle(player, gecen)
end

local function grupta(player: Player): boolean
	if SosyalOdul.GroupId == 0 then
		return false
	end
	local ok, sonuc = pcall(function()
		return (player :: any):IsInGroupAsync(SosyalOdul.GroupId)
	end)
	if not ok then
		ok, sonuc = pcall(function()
			return player:IsInGroup(SosyalOdul.GroupId)
		end)
	end
	return ok and sonuc == true
end

local function durumGonder(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	local gecen = playtimeTazele(player)

	local basamaklar = {}
	for i, odul in SosyalOdul.Playtime do
		table.insert(basamaklar, {
			claimed = PlayerData.playtimeAlindi(player, i),
			ready = gecen >= odul.minutes * 60,
		})
	end

	EkOdulDurum:FireClient(player, {
		elapsed = gecen,
		playtime = basamaklar,
		group = {
			id = SosyalOdul.GroupId,
			claimed = data.socialClaimed.group == true,
		},
		like = {
			claimed = data.socialClaimed.like == true,
		},
	})
end

--[[
	Odulu verir; ekrana ne kazanildigini yazar.

	SURELI GECIS odulunde (kind = "pass") sure saniye cinsinden gelir ve
	kalici sahibi olan oyuncuya verilmez -- onun yerine bildirimde sebebi
	yazar, odul de harcanmis sayilmaz.
]]
local function ver(player: Player, kind: string, amount: number, pass: string?, seconds: number?)
	if kind == "rotcoin" then
		PlayerData.addRotCoins(player, amount)
		Bildirim:FireClient(player, `+{amount} Rot Coin!`, SARI)
	elseif kind == "rot" then
		PlayerData.addRot(player, amount)
		Bildirim:FireClient(player, `+{amount} Rot!`, SARI)
	elseif kind == "luckyblock" then
		PlayerData.addLuckyBlocks(player, SosyalOdul.enUcuzLuckyBlock(), amount)
		Envanter.syncLuckyBlocks(player)
		Bildirim:FireClient(player, `+{amount} Lucky Block!`, SARI)
	elseif kind == "pass" and pass and seconds then
		local info = Passler.get(pass)
		local ad = if info then info.ad else pass
		if SureliGecis.ver(player, pass, seconds) then
			Bildirim:FireClient(player, `{ad} unlocked for {SosyalOdul.sure(seconds)}!`, SARI)
		else
			Bildirim:FireClient(player, `You already own {ad}.`, SARI)
		end
	end
	Envanter.push(player)
end

local function al(player: Player, tur: string, index: any)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	if tur == "group" then
		if data.socialClaimed.group then
			return
		end
		if SosyalOdul.GroupId == 0 then
			Bildirim:FireClient(player, "Group reward is coming soon!", SARI)
			return
		end
		if not grupta(player) then
			Bildirim:FireClient(player, "Join the group first, then claim!", KIRMIZI)
			return
		end
		data.socialClaimed.group = true
		ver(player, "rotcoin", SosyalOdul.GroupReward)
	elseif tur == "like" then
		if data.socialClaimed.like then
			return
		end
		data.socialClaimed.like = true
		ver(player, "rotcoin", SosyalOdul.LikeReward)
	elseif tur == "playtime" then
		local i = tonumber(index)
		local odul = if i then SosyalOdul.Playtime[i] else nil
		if not i or not odul then
			return
		end
		if playtimeTazele(player) < odul.minutes * 60 then
			return
		end
		-- Isaretleme ile odul ayni adimda: iki istek ayni basamagi alamaz
		if not PlayerData.playtimeAl(player, i) then
			return
		end
		ver(player, odul.kind, odul.amount or 0, odul.pass, odul.seconds)
	end
end

EkOdulAl.OnServerEvent:Connect(function(player, tur, index)
	if type(tur) ~= "string" or mesgul[player] then
		return
	end
	mesgul[player] = true
	local ok, hata = pcall(al, player, tur, index)
	if not ok then
		warn(`[SosyalOdul] {player.Name} {tur} odulu verilemedi: {tostring(hata)}`)
	end
	mesgul[player] = nil
	durumGonder(player)
end)

KodKullan.OnServerEvent:Connect(function(player, kod)
	if type(kod) ~= "string" or #kod > 40 then
		return
	end

	-- Kod denemesi saniyede bir: tahminle kod aranmasin
	local simdi = os.clock()
	if sonKod[player] and simdi - sonKod[player] < 1 then
		return
	end
	sonKod[player] = simdi

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local anahtar = string.upper((string.gsub(kod, "%s", "")))
	local odul = KODLAR[anahtar]

	if not odul then
		KodSonuc:FireClient(player, { ok = false, message = "Invalid code" })
		return
	end
	if data.redeemedCodes[anahtar] then
		KodSonuc:FireClient(player, { ok = false, message = "Code already redeemed" })
		return
	end

	data.redeemedCodes[anahtar] = true
	ver(player, "rotcoin", odul.rotCoins)
	KodSonuc:FireClient(player, { ok = true, message = `Redeemed! +{odul.rotCoins} Rot Coin` })
end)

EkOdulAc.OnServerEvent:Connect(function(player)
	durumGonder(player)
end)

Players.PlayerAdded:Connect(function(player)
	oturum[player] = { son = os.clock() }
end)
for _, player in Players:GetPlayers() do
	oturum[player] = { son = os.clock() }
end

--[[
	PANEL ACILMASA DA SURE ISLENSIN

	playtimeTazele yalnizca durum sorulunca calisiyor. Oyuncu Rewards'i hic
	acmadan cikarsa o oturumun tamami kayda gecmezdi; dakikada bir isleyip
	bu bosluğu kapatiyoruz. Ayrica gece yarisini oyunun icinde geciren
	oyuncunun sayaci da burada sifirlaniyor.
]]
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in Players:GetPlayers() do
			playtimeTazele(player)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	-- Kayit alinmadan once son dilimi de isle
	playtimeTazele(player)
	oturum[player] = nil
	mesgul[player] = nil
	sonKod[player] = nil
end)
