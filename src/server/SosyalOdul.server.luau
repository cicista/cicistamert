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

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Envanter = require(Modules:WaitForChild("Envanter"))

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

-- Oturum: giris ani ve bu oturumda alinan playtime basamaklari
local oturum: { [Player]: { basla: number, alinan: { [number]: boolean } } } = {}

-- Ust uste gelen istekler ayni odulu iki kez vermesin
local mesgul: { [Player]: boolean } = {}
local sonKod: { [Player]: number } = {}

local function oturumOf(player: Player)
	local o = oturum[player]
	if not o then
		o = { basla = os.clock(), alinan = {} }
		oturum[player] = o
	end
	return o
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

	local o = oturumOf(player)
	local gecen = os.clock() - o.basla

	local basamaklar = {}
	for i, odul in SosyalOdul.Playtime do
		table.insert(basamaklar, {
			claimed = o.alinan[i] == true,
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

-- Odulu verir; ekrana ne kazanildigini yazar
local function ver(player: Player, kind: string, amount: number)
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
		local o = oturumOf(player)
		if o.alinan[i] or os.clock() - o.basla < odul.minutes * 60 then
			return
		end
		o.alinan[i] = true
		ver(player, odul.kind, odul.amount)
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
	oturumOf(player)
end)
for _, player in Players:GetPlayers() do
	oturumOf(player)
end

Players.PlayerRemoving:Connect(function(player)
	oturum[player] = nil
	mesgul[player] = nil
	sonKod[player] = nil
end)
