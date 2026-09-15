--!strict
--[[
	REWARDS PANELININ DIGER SEKMELERI  --  ayarlar

	Rewards butonu acilinca uc sekme var:
	    Playtime        -- oyunda kalinan sureye gore oduller (bu dosya)
	    Daily           -- 7 gunluk takvim (bkz. Shared > Rewards, degismedi)
	    Social Rewards  -- grup odulu, like+favorite odulu, kod kutusu

	SOCIAL REWARDS
	  - Grup odulu: GroupId'deki gruba uye olan oyuncu HESAP BASINA BIR KEZ
	    GroupReward kadar Rot Coin alir. Uyelik sunucuda dogrulanir.
	    GroupId 0 iken kart "Coming Soon" yazar.
	  - Like + Favorite: Roblox begeniyi dogrulamaya izin vermiyor; oyuncu
	    Claim'e basinca favori penceresi acilir ve odul HESAP BASINA BIR KEZ
	    verilir.
	  - Kodlar SUNUCUDA durur (bkz. ServerScriptService > SosyalOdul); burada
	    olsalar istemci okuyabilirdi.

	PLAYTIME
	  Sure HER GIRISTE sifirdan sayilir; her basamak o oturumda bir kez alinir.
]]

local Format = require(script.Parent.Format)
local LuckyBlock = require(script.Parent.LuckyBlock)

local SosyalOdul = {}

-- Roblox grup kimligi (grup linkindeki sayi). 0 = grup yok, kart "Coming Soon"
SosyalOdul.GroupId = 0
-- Kartta tirnak icinde yazan grup adi (bos birakilirsa "our Group" yazar)
SosyalOdul.GroupName = ""
SosyalOdul.GroupReward = 5

SosyalOdul.LikeReward = 3

export type PlaytimeOdul = {
	minutes: number,
	-- "rotcoin" | "rot" | "luckyblock"
	kind: string,
	amount: number,
}

SosyalOdul.Playtime = {
	{ minutes = 5, kind = "rotcoin", amount = 1 },
	{ minutes = 15, kind = "rot", amount = 5000 },
	{ minutes = 30, kind = "luckyblock", amount = 1 },
	{ minutes = 45, kind = "rotcoin", amount = 2 },
	{ minutes = 60, kind = "rotcoin", amount = 3 },
} :: { PlaytimeOdul }

-- En ucuz Lucky Block turu (playtime odulu bunu verir)
function SosyalOdul.enUcuzLuckyBlock(): string
	local secilen = LuckyBlock.Tiers[1]
	for _, tur in LuckyBlock.Tiers do
		if tur.order < secilen.order then
			secilen = tur
		end
	end
	return secilen.id
end

-- Kartta yazan odul: "+1 Rot Coin", "+5K Rot", "1x Lucky Block"
function SosyalOdul.etiket(odul: PlaytimeOdul): string
	if odul.kind == "rotcoin" then
		return `+{odul.amount} Rot Coin`
	elseif odul.kind == "rot" then
		return `+{Format.short(odul.amount)} Rot`
	end
	return `{odul.amount}x {LuckyBlock.get(SosyalOdul.enUcuzLuckyBlock()).displayName}`
end

-- Icons.Map kisa adi
function SosyalOdul.ikon(odul: PlaytimeOdul): string
	if odul.kind == "rotcoin" then
		return "rotCoin"
	elseif odul.kind == "rot" then
		return "rot"
	end
	return "luckyBlock"
end

-- "4:05", "1:02:30"
function SosyalOdul.sure(saniye: number): string
	local t = math.max(0, math.floor(saniye))
	if t >= 3600 then
		return string.format("%d:%02d:%02d", t // 3600, (t % 3600) // 60, t % 60)
	end
	return string.format("%d:%02d", t // 60, t % 60)
end

return SosyalOdul
