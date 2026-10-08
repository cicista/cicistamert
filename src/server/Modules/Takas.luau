--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("Takas"))
local Canta = require(Shared:WaitForChild("Canta"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Net = require(Shared:WaitForChild("Net"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))
local Unvan = require(script.Parent:WaitForChild("Unvan"))

local Bildirim = Net.event("Bildirim")
local TakasIslem = Net.event("TakasIslem")
local TakasDurum = Net.event("TakasDurum")

local SARI = Color3.fromRGB(255, 200, 90)
local KIRMIZI = Color3.fromRGB(255, 110, 110)

type Teklif = { esyalar: { [string]: boolean }, bloklar: { [string]: number } }

type Oturum = {
	a: Player,
	b: Player,
	teklif: { [Player]: Teklif },
	kabul: { [Player]: boolean },
	surum: number,
	geriSayimBitis: number?,
	bitti: boolean,
}

local Takas = {}

local istekler: { [Player]: { hedef: Player, zaman: number } } = {}
local oturumlar: { [Player]: Oturum } = {}
local sonIstek: { [Player]: number } = {}
local sonIslem: { [Player]: number } = {}

local function seviyeYeterli(player: Player): boolean
	local data = PlayerData.get(player)
	return data ~= nil and (data.level or 0) >= Ayar.GerekenSeviye
end

local function karsi(oturum: Oturum, player: Player): Player
	return if oturum.a == player then oturum.b else oturum.a
end

local function esyaBilgisi(item: any): { [string]: any }
	return {
		uid = item.uid,
		name = if item.revealed then item.name else nil,
		rarity = item.rarity,
		condition = item.condition,
		mutation = item.mutation,
		revealed = item.revealed == true,
	}
end

local function teklifBilgisi(player: Player, teklif: Teklif): { [string]: any }
	local esyalar = {}
	for uid in teklif.esyalar do
		local item = PlayerData.findItem(player, uid)
		if item and not item.slot then
			table.insert(esyalar, esyaBilgisi(item))
		end
	end
	return { esyalar = esyalar, bloklar = teklif.bloklar }
end

local function esyaSayisi(teklif: Teklif): number
	local sayi = 0
	for _ in teklif.esyalar do
		sayi += 1
	end
	for _ in teklif.bloklar do
		sayi += 1
	end
	return sayi
end

local function durumGonder(oturum: Oturum)
	local kalan = if oturum.geriSayimBitis then math.max(0, oturum.geriSayimBitis - os.clock()) else nil

	for _, oyuncu in { oturum.a, oturum.b } do
		local diger = karsi(oturum, oyuncu)
		local data = PlayerData.get(oyuncu)
		if not data then
			continue
		end

		local envanter = {}
		local teklifim = oturum.teklif[oyuncu]
		for _, item in data.inventory do
			if not item.slot and not teklifim.esyalar[item.uid] then
				table.insert(envanter, esyaBilgisi(item))
			end
		end

		local bloklarim = {}
		for tierId, adet in data.luckyBlocks do
			local kalanAdet = adet - (teklifim.bloklar[tierId] or 0)
			if kalanAdet > 0 then
				bloklarim[tierId] = kalanAdet
			end
		end

		TakasDurum:FireClient(oyuncu, {
			tur = "oturum",
			karsi = { id = diger.UserId, ad = diger.DisplayName },
			benim = teklifBilgisi(oyuncu, teklifim),
			onun = teklifBilgisi(diger, oturum.teklif[diger]),
			benimKabul = oturum.kabul[oyuncu] == true,
			onunKabul = oturum.kabul[diger] == true,
			geriSayim = kalan,
			envanter = envanter,
			bloklarim = bloklarim,
		})
	end
end

local function bitir(oturum: Oturum, basarili: boolean, mesaj: string?)
	if oturum.bitti then
		return
	end
	oturum.bitti = true
	oturum.geriSayimBitis = nil

	for _, oyuncu in { oturum.a, oturum.b } do
		if oturumlar[oyuncu] == oturum then
			oturumlar[oyuncu] = nil
		end
		if oyuncu.Parent then
			TakasDurum:FireClient(oyuncu, {
				tur = "bitti",
				basarili = basarili,
				mesaj = mesaj,
			})
		end
	end
end

local function degisti(oturum: Oturum)
	oturum.surum += 1
	oturum.kabul[oturum.a] = false
	oturum.kabul[oturum.b] = false
	oturum.geriSayimBitis = nil
	durumGonder(oturum)
end

local function dogrula(oturum: Oturum): string?
	for _, oyuncu in { oturum.a, oturum.b } do
		if not oyuncu.Parent then
			return "The other player left."
		end
		local data = PlayerData.get(oyuncu)
		if not data then
			return "Player data is not ready."
		end

		local teklif = oturum.teklif[oyuncu]
		for uid in teklif.esyalar do
			local item = PlayerData.findItem(oyuncu, uid)
			if not item or item.slot then
				return `{oyuncu.DisplayName}'s offer changed (an item is gone or placed on the base).`
			end
		end
		for tierId, adet in teklif.bloklar do
			if not LuckyBlock.exists(tierId) or adet < 1 or PlayerData.luckyBlockCount(oyuncu, tierId) < adet then
				return `{oyuncu.DisplayName} does not have those Lucky Blocks anymore.`
			end
		end
	end

	for _, oyuncu in { oturum.a, oturum.b } do
		local diger = karsi(oturum, oyuncu)
		local data = PlayerData.get(oyuncu) :: any
		local gelen = 0
		for _ in oturum.teklif[diger].esyalar do
			gelen += 1
		end
		local giden = 0
		for _ in oturum.teklif[oyuncu].esyalar do
			giden += 1
		end
		if PlayerData.cantaSayisi(oyuncu) - giden + gelen > Canta.duzelt(data.inventoryMax) then
			return `{oyuncu.DisplayName}'s backpack would be too full.`
		end
	end

	return nil
end

local function yeniUid(alici: any): string
	local mevcut: { [string]: boolean } = {}
	for _, item in alici.inventory do
		mevcut[item.uid] = true
	end
	local uid = PlayerData.newUid()
	while mevcut[uid] do
		uid = PlayerData.newUid()
	end
	return uid
end

local function tamamla(oturum: Oturum)
	if oturum.bitti then
		return
	end

	local hata = dogrula(oturum)
	if hata then
		bitir(oturum, false, hata)
		return
	end

	local dataA = PlayerData.get(oturum.a) :: any
	local dataB = PlayerData.get(oturum.b) :: any

	local tasinan: { [Player]: { any } } = { [oturum.a] = {}, [oturum.b] = {} }
	for _, oyuncu in { oturum.a, oturum.b } do
		for uid in oturum.teklif[oyuncu].esyalar do
			local item = PlayerData.removeItem(oyuncu, uid)
			if item then
				table.insert(tasinan[oyuncu], item)
			end
		end
	end

	for _, oyuncu in { oturum.a, oturum.b } do
		local diger = karsi(oturum, oyuncu)
		local aliciData = if diger == oturum.a then dataA else dataB
		for _, item in tasinan[oyuncu] do
			item.uid = yeniUid(aliciData)
			item.slot = nil
			table.insert(aliciData.inventory, item)
			if item.revealed and item.name then
				PlayerData.discover(diger, item.name)
				PlayerData.discoverMutation(diger, item.name, item.mutation)
			end
		end
		for tierId, adet in oturum.teklif[oyuncu].bloklar do
			PlayerData.addLuckyBlocks(oyuncu, tierId, -adet)
			PlayerData.addLuckyBlocks(diger, tierId, adet)
		end
	end

	PlayerData.hemenKaydet(oturum.a)
	PlayerData.hemenKaydet(oturum.b)

	print(
		`[Takas] {oturum.a.Name} <-> {oturum.b.Name}: {#tasinan[oturum.a]} item(s) + blocks / {#tasinan[oturum.b]} item(s) + blocks`
	)

	bitir(oturum, true, nil)

	for _, oyuncu in { oturum.a, oturum.b } do
		task.spawn(function()
			Envanter.syncBrainrots(oyuncu)
			Envanter.syncLuckyBlocks(oyuncu)
			Envanter.push(oyuncu)
			Envanter.indexGonder(oyuncu)
			Unvan.ilerlet(oyuncu, "trade", 1)
		end)
	end
end

local function kabulKontrol(oturum: Oturum)
	oturum.surum += 1

	if not (oturum.kabul[oturum.a] and oturum.kabul[oturum.b]) then
		oturum.geriSayimBitis = nil
		durumGonder(oturum)
		return
	end

	if esyaSayisi(oturum.teklif[oturum.a]) + esyaSayisi(oturum.teklif[oturum.b]) == 0 then
		oturum.kabul[oturum.a] = false
		oturum.kabul[oturum.b] = false
		durumGonder(oturum)
		return
	end

	oturum.geriSayimBitis = os.clock() + Ayar.GeriSayim
	local surum = oturum.surum
	durumGonder(oturum)

	task.delay(Ayar.GeriSayim, function()
		if oturum.bitti or oturum.surum ~= surum then
			return
		end
		if oturum.kabul[oturum.a] and oturum.kabul[oturum.b] then
			tamamla(oturum)
		end
	end)
end

local function istekGonder(player: Player, hedef: Player)
	if hedef == player or not hedef.Parent then
		return
	end

	local simdi = os.clock()
	if simdi - (sonIstek[player] or -math.huge) < Ayar.IstekAraligi then
		Bildirim:FireClient(player, "Wait a moment before sending another request.", SARI)
		return
	end
	sonIstek[player] = simdi

	if not seviyeYeterli(player) then
		Bildirim:FireClient(player, `Trading unlocks at Level {Ayar.GerekenSeviye}!`, SARI)
		return
	end
	if not seviyeYeterli(hedef) then
		Bildirim:FireClient(player, `{hedef.DisplayName} must be Level {Ayar.GerekenSeviye} to trade.`, SARI)
		return
	end
	if oturumlar[player] or oturumlar[hedef] then
		Bildirim:FireClient(player, `{hedef.DisplayName} is already trading.`, SARI)
		return
	end

	istekler[player] = { hedef = hedef, zaman = simdi }
	TakasDurum:FireClient(hedef, {
		tur = "istek",
		gonderen = player.UserId,
		ad = player.DisplayName,
		sure = Ayar.IstekSuresi,
	})
	TakasDurum:FireClient(player, { tur = "gonderildi", hedef = hedef.UserId })
	Bildirim:FireClient(player, `Trade request sent to {hedef.DisplayName}.`, Color3.fromRGB(150, 220, 255))
end

local function istegeYanit(player: Player, gonderen: Player, kabul: boolean)
	local istek = istekler[gonderen]
	if not istek or istek.hedef ~= player or os.clock() - istek.zaman > Ayar.IstekSuresi then
		if kabul then
			Bildirim:FireClient(player, "That trade request has expired.", SARI)
		end
		return
	end
	istekler[gonderen] = nil

	if not kabul then
		Bildirim:FireClient(gonderen, `{player.DisplayName} declined your trade request.`, KIRMIZI)
		return
	end

	if not gonderen.Parent or oturumlar[player] or oturumlar[gonderen] then
		Bildirim:FireClient(player, "The trade could not start.", SARI)
		return
	end
	if not seviyeYeterli(player) or not seviyeYeterli(gonderen) then
		Bildirim:FireClient(player, `Both players must be Level {Ayar.GerekenSeviye} to trade.`, SARI)
		return
	end

	local oturum: Oturum = {
		a = gonderen,
		b = player,
		teklif = {
			[gonderen] = { esyalar = {}, bloklar = {} },
			[player] = { esyalar = {}, bloklar = {} },
		},
		kabul = { [gonderen] = false, [player] = false },
		surum = 0,
		geriSayimBitis = nil,
		bitti = false,
	}
	oturumlar[gonderen] = oturum
	oturumlar[player] = oturum
	durumGonder(oturum)
end

local function esyaEkle(player: Player, oturum: Oturum, uid: string)
	local teklif = oturum.teklif[player]
	if teklif.esyalar[uid] then
		return
	end
	if esyaSayisi(teklif) >= Ayar.EnFazlaEsya then
		Bildirim:FireClient(player, `You can offer up to {Ayar.EnFazlaEsya} things.`, SARI)
		return
	end
	local item = PlayerData.findItem(player, uid)
	if not item or item.slot then
		Bildirim:FireClient(player, "Take it off your base first.", SARI)
		return
	end
	teklif.esyalar[uid] = true
	degisti(oturum)
end

local function blokEkle(player: Player, oturum: Oturum, tierId: string, adet: number)
	if not LuckyBlock.exists(tierId) then
		return
	end
	local teklif = oturum.teklif[player]
	local mevcut = teklif.bloklar[tierId] or 0
	local yeni = math.clamp(mevcut + adet, 0, PlayerData.luckyBlockCount(player, tierId))
	if yeni == mevcut then
		return
	end
	if mevcut == 0 and yeni > 0 and esyaSayisi(teklif) >= Ayar.EnFazlaEsya then
		Bildirim:FireClient(player, `You can offer up to {Ayar.EnFazlaEsya} things.`, SARI)
		return
	end
	teklif.bloklar[tierId] = if yeni > 0 then yeni else nil
	degisti(oturum)
end

TakasIslem.OnServerEvent:Connect(function(player: Player, veri: any)
	if type(veri) ~= "table" or type(veri.tur) ~= "string" then
		return
	end

	local simdi = os.clock()
	if simdi - (sonIslem[player] or -math.huge) < Ayar.IslemAraligi then
		return
	end
	sonIslem[player] = simdi

	local tur = veri.tur

	if tur == "gonder" then
		local hedef = if type(veri.hedef) == "number" then Players:GetPlayerByUserId(veri.hedef) else nil
		if hedef then
			istekGonder(player, hedef)
		end
		return
	elseif tur == "yanit" then
		local gonderen = if type(veri.gonderen) == "number" then Players:GetPlayerByUserId(veri.gonderen) else nil
		if gonderen then
			istegeYanit(player, gonderen, veri.kabul == true)
		end
		return
	end

	local oturum = oturumlar[player]
	if not oturum or oturum.bitti then
		return
	end

	if tur == "ekle" and type(veri.uid) == "string" and #veri.uid <= 64 then
		esyaEkle(player, oturum, veri.uid)
	elseif tur == "cikar" and type(veri.uid) == "string" then
		if oturum.teklif[player].esyalar[veri.uid] then
			oturum.teklif[player].esyalar[veri.uid] = nil
			degisti(oturum)
		end
	elseif tur == "blok" and type(veri.tier) == "string" and type(veri.adet) == "number" then
		local adet = math.clamp(math.floor(veri.adet), -1000, 1000)
		if adet ~= 0 then
			blokEkle(player, oturum, veri.tier, adet)
		end
	elseif tur == "kabul" then
		oturum.kabul[player] = veri.deger == true
		kabulKontrol(oturum)
	elseif tur == "iptal" then
		bitir(oturum, false, `{player.DisplayName} cancelled the trade.`)
	elseif tur == "durum" then
		durumGonder(oturum)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local oturum = oturumlar[player]
	if oturum then
		bitir(oturum, false, `{player.DisplayName} left the game.`)
	end
	istekler[player] = nil
	for gonderen, istek in istekler do
		if istek.hedef == player then
			istekler[gonderen] = nil
		end
	end
	sonIstek[player] = nil
	sonIslem[player] = nil
end)

function Takas.mesgulMu(player: Player): boolean
	return oturumlar[player] ~= nil
end

return Takas
