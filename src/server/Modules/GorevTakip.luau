--!strict
--[[
	GOREV TAKIBI

	Gorev panosunun sunucu tarafi: ilerlemeyi sayar, biten gorevin odulunu
	verir ve arayuze gonderir.

	ILERLEME NEREDEN GELIYOR
	Diger sistemler (kazi, satici, base, fuse, lucky block) tek bir cagri
	yapiyor:  GorevTakip.ilerlet(player, "dig", 1)
	Hangi gorevin bundan etkilenecegini burasi bulur; cagiran tarafin panoda
	ne oldugunu bilmesi gerekmez.

	YENILENME
	Pano yarim saatte bir kendiliginden degisir. Ayri bir "sifirla" isi yok:
	kaydin icindeki cycle numarasi o anki dilimle uyusmuyorsa ilerleme
	sifirdan baslar (bkz. tazele). Boylece sunucu kapaliyken gecen dilimler
	de dogru sayilir.

	ODUL
	Odul tamamen COIN: biten gorevin zorluguna gore bir coin cantaya girer
	(Normal boy, mutasyonsuz). Coin Trader'da ayni kademeden bir brainrota
	donusur.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Gorevler = require(Shared:WaitForChild("Gorevler"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Condition = require(Shared:WaitForChild("Condition"))
local Net = require(Shared:WaitForChild("Net"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))

local Bildirim = Net.event("Bildirim")
local GorevDurum = Net.event("GorevDurum")

local GorevTakip = {}

-- Bildirim renkleri
local ILERLEME_RENGI = Color3.fromRGB(190, 205, 225)
local BITTI_RENGI = Color3.fromRGB(140, 230, 160)

--[[
	Oyuncunun gorev durumu. Dilim degistiyse ilerleme burada sifirlanir.
	Veri henuz yuklenmediyse nil doner ve cagiran taraf sessizce vazgecer.
]]
local function tazele(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return nil
	end

	local durum = data.quests
	local cycle = Gorevler.cycle()

	if durum.cycle ~= cycle then
		durum.cycle = cycle
		durum.progress = {}
		durum.done = {}
	end

	return durum
end

-- Arayuze gidecek paket
local function paket(player: Player)
	local durum = tazele(player)
	if not durum then
		return nil
	end

	local liste = {}
	for _, def in Gorevler.forCycle(durum.cycle) do
		local reward = Gorevler.reward(def)
		local ilerleme = math.min(durum.progress[def.id] or 0, def.target)
		local alindi = durum.done[def.id] == true

		table.insert(liste, {
			id = def.id,
			text = def.text,
			target = def.target,
			progress = ilerleme,
			-- done: odul ALINDI. ready: hedef doldu ama odul bekliyor.
			done = alindi,
			ready = not alindi and ilerleme >= def.target,
			reward = Gorevler.rewardText(def),
			color = Rarity.color(reward.rarity),
		})
	end

	return {
		remaining = Gorevler.remaining(),
		quests = liste,
	}
end

-- Panoyu arayuze yollar. Veri henuz yuklenmediyse false doner.
function GorevTakip.gonder(player: Player): boolean
	local veri = paket(player)
	if not veri then
		return false
	end

	GorevDurum:FireClient(player, veri)
	return true
end

local function odulVer(player: Player, def: Gorevler.QuestDef)
	local reward = Gorevler.reward(def)

	for _ = 1, reward.count do
		PlayerData.addCoin(player, reward.rarity, Condition.Default, "Normal")
	end

	Envanter.syncCoins(player)
	Envanter.push(player)
end

--[[
	Bir eylemi panoya isler.

	kind    -- "dig" | "collect" | "sell" | "place" | "lucky" | "fuse"
	amount  -- kac tane (varsayilan 1)
	rarity  -- yalnizca "collect" icin: toplanan brainrotun kademesi

	Ayni eylem birden fazla gorevi ilerletebilir (ornegin "20 kaz" ve
	"90 kaz" ayni anda panodaysa ikisi de sayar).
]]
function GorevTakip.ilerlet(player: Player, kind: string, amount: number?, rarity: string?)
	local durum = tazele(player)
	if not durum then
		return
	end

	local adet = math.max(1, math.floor(amount or 1))
	local degisti = false

	for _, def in Gorevler.forCycle(durum.cycle) do
		if def.kind ~= kind or durum.done[def.id] then
			continue
		end
		-- Kademe gorevleri yalnizca kendi kademesini sayar
		if def.rarity and def.rarity ~= rarity then
			continue
		end

		local yeni = math.min((durum.progress[def.id] or 0) + adet, def.target)
		if yeni == durum.progress[def.id] then
			continue
		end

		durum.progress[def.id] = yeni
		degisti = true

		if yeni >= def.target then
			--[[
				ODUL BURADA VERILMEZ.

				Gorev "toplanmayi bekliyor" durumuna gecer; oyuncu odulunu
				Quests panelindeki Collect dugmesiyle alir (bkz. GorevTakip.al).
				Boylece odul gorunmeden cebe girmiyor, alirken gosterisi de oluyor.
			]]
			Bildirim:FireClient(
				player,
				`Quest Ready: {def.text}`,
				BITTI_RENGI
			)
		else
			Bildirim:FireClient(player, `{def.short}  {yeni} / {def.target}`, ILERLEME_RENGI)
		end
	end

	if degisti then
		GorevTakip.gonder(player)
	end
end

return GorevTakip
