--!strict
--[[
	GUNLUK ODUL  --  7 gunluk takvim

	Her 24 saatte bir o gunun odulu alinir; alinan her odul takvimi bir
	sonraki gune gecirir. 7. gunden sonra takvim 1. gune doner.

	    Gun 1   150K Rot                            + 1 Rot Coin
	    Gun 2   3M Rot                              + 1 Rot Coin
	    Gun 3   1 gunluk Detective Pass             + 1 Rot Coin
	    Gun 4   1 x en ucuz Lucky Block             + 1 Rot Coin
	    Gun 5   2 x en ucuz Lucky Block + 12s Telep + 2 Rot Coin
	    Gun 6   3 x en ucuz Lucky Block             + 1 Rot Coin
	    Gun 7   1 x en pahali Lucky Block           + 1 Rot Coin

	EN UCUZ / EN PAHALI Lucky Block adla yazilmiyor; LuckyBlock.Tiers
	icindeki SIRADAN (order) bulunuyor. Yeni bir tur eklenirse 7. gun
	kendiliginden en ustteki tur olur.

	SERI BOZULMASI
	Bir odul alindiktan sonra streakReset saniye (48 saat) icinde siradaki
	alinmazsa seri bozulur ve takvim 1. gune doner. Yani oyuncunun her gun
	ugramak icin tam bir gunluk payi var.

	Sure sunucu saatiyle (os.time) tutulur; oyundan cikmak sayaci sifirlamaz.

	(Onceki surum her 24 saatte bir hediye carkiydi; bu takvim onun yerini aldi.)
]]

local LuckyBlock = require(script.Parent.LuckyBlock)
local Format = require(script.Parent.Format)
-- Gecis odullerinin adi icin (Detective Pass, Teleporter)
local Passler = require(script.Parent.Passler)

local Rewards = {}

-- Iki odul arasi bekleme (saniye). 86400 = 24 saat
Rewards.cooldown = 86400

--[[
	OYUNA GIRINCE BEKLEME

	Oyuncu oyuna girdikten sonra gunluk odulu alabilmek icin bu kadar
	saniye oynamak zorunda (her giriste). 24 saat dolmus olsa bile once bu
	sure dolar; sayac panelde kalan sure olarak gorunur.
]]
Rewards.MinSessionSeconds = 15 * 60

-- Son odulden bu kadar saniye gecerse seri bozulur, 1. gune donulur (48 saat)
Rewards.streakReset = 172800

-- LuckyBlock.Tiers icinde sirasi en dusuk / en yuksek tur
local function uctakiTur(enPahali: boolean): string
	local secilen = LuckyBlock.Tiers[1]
	for _, tur in LuckyBlock.Tiers do
		if (enPahali and tur.order > secilen.order) or (not enPahali and tur.order < secilen.order) then
			secilen = tur
		end
	end
	return secilen.id
end

local EN_UCUZ = uctakiTur(false)
local EN_PAHALI = uctakiTur(true)

export type Day = {
	day: number,
	-- "rot", "luckyblock" ya da "pass"
	kind: string,
	amount: number,
	-- Yalnizca luckyblock odullerinde: hangi tur
	tier: string?,
	-- Ana odulun YANINDA verilen Rot Coin (yoksa nil)
	rotCoins: number?,
	--[[
		SURELI GECIS. kind == "pass" ise ANA odul budur; diger gunlerde ana
		odulun yanina eklenir. passSeconds bitince gecis kendiliginden kapanir
		(bkz. ServerScriptService > Modules > SureliGecis).
	]]
	pass: string?,
	passSeconds: number?,
}

--[[
	TAKVIM. Odulleri degistirmek icin yalnizca bu tabloyu duzenle; kartlar,
	bildirim ve sunucu hepsini buradan okuyor.
]]
Rewards.Days = {
	{ day = 1, kind = "rot", amount = 150000, rotCoins = 1 },
	{ day = 2, kind = "rot", amount = 3000000, rotCoins = 1 },
	-- 3. gun: 1 gunluk Detective Pass (kazilan brainrotlar kimlikli gelir)
	{ day = 3, kind = "pass", amount = 0, pass = "DetectivePass", passSeconds = 86400, rotCoins = 1 },
	{ day = 4, kind = "luckyblock", amount = 1, tier = EN_UCUZ, rotCoins = 1 },
	-- 5. gun: onceden verilen 1 Rot Coin + her gunun ekstra 1'i
	-- 5. gun: 12 saatlik Teleporter + onceki odul
	{ day = 5, kind = "luckyblock", amount = 2, tier = EN_UCUZ, rotCoins = 2, pass = "Teleporter", passSeconds = 43200 },
	{ day = 6, kind = "luckyblock", amount = 3, tier = EN_UCUZ, rotCoins = 1 },
	{ day = 7, kind = "luckyblock", amount = 1, tier = EN_PAHALI, rotCoins = 1 },
} :: { Day }

function Rewards.get(day: number): Day
	return Rewards.Days[math.clamp(math.floor(day), 1, #Rewards.Days)]
end

-- Takvimde siradaki gun (7'den sonra 1)
function Rewards.nextDay(day: number): number
	return day % #Rewards.Days + 1
end

--[[
	Sureli gecis odulunun yanindaki sure: "1 Day", "12h", "15 min".
	Tam bolunuyorsa o birimde yaziliyor.
]]
function Rewards.passSuresi(saniye: number): string
	local t = math.max(0, math.floor(saniye))
	if t >= 86400 and t % 86400 == 0 then
		local gun = t // 86400
		return if gun == 1 then "1 Day" else `{gun} Days`
	end
	if t >= 3600 then
		return `{t // 3600}h`
	end
	return `{t // 60} min`
end

-- Kartta ve bildirimde yazan odul adi
function Rewards.label(day: number): string
	local odul = Rewards.get(day)
	if odul.kind == "rot" then
		return `+{Format.short(odul.amount)} Rot`
	elseif odul.kind == "pass" then
		local bilgi = Passler.get(odul.pass or "")
		local ad = if bilgi then bilgi.ad else (odul.pass or "Pass")
		return `{ad} ({Rewards.passSuresi(odul.passSeconds or 0)})`
	end

	local tur = LuckyBlock.get(odul.tier)
	return if odul.amount > 1 then `{odul.amount}x {tur.displayName}` else tur.displayName
end

-- Odulun rengi: Rot sari, gecis moru, Lucky Block kendi turunun renginde
function Rewards.color(day: number): Color3
	local odul = Rewards.get(day)
	if odul.kind == "rot" then
		return Color3.fromRGB(255, 214, 41)
	elseif odul.kind == "pass" then
		return Color3.fromRGB(170, 120, 255)
	end
	return LuckyBlock.get(odul.tier).color
end

export type State = {
	-- Takvimde alinacak gun
	day: number,
	ready: boolean,
	-- Alinabilir olmasina kalan saniye (hazirsa 0)
	remaining: number,
}

--[[
	OYUNCUNUN DURUMU

	lastReward : son odulun alindigi an (0 = hic alinmamis)
	rewardDay  : takvimde siradaki gun
]]
function Rewards.state(lastReward: number, rewardDay: number, now: number): State
	local day = math.clamp(math.floor(rewardDay), 1, #Rewards.Days)

	if lastReward <= 0 then
		return { day = day, ready = true, remaining = 0 }
	end

	local elapsed = now - lastReward

	if elapsed >= Rewards.streakReset then
		-- Seri bozuldu: takvim basa doner
		return { day = 1, ready = true, remaining = 0 }
	end

	if elapsed >= Rewards.cooldown then
		return { day = day, ready = true, remaining = 0 }
	end

	return { day = day, ready = false, remaining = Rewards.cooldown - elapsed }
end

-- Kalan sureyi "5h 12m" gibi okunur yaziya cevirir (bildirimlerde)
function Rewards.formatRemaining(seconds: number): string
	local total = math.max(0, math.floor(seconds))
	local hours = math.floor(total / 3600)
	local minutes = math.floor((total % 3600) / 60)
	local secs = total % 60

	if hours > 0 then
		return `{hours}h {minutes}m`
	end
	if minutes > 0 then
		return `{minutes}m {secs}s`
	end
	return `{secs}s`
end

-- Kartin dugmesindeki geri sayim: "23:59:07"
function Rewards.formatClock(seconds: number): string
	local t = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d:%02d", t // 3600, (t % 3600) // 60, t % 60)
end

return Rewards
