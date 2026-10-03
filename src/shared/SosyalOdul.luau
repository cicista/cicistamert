--!strict

local Format = require(script.Parent.Format)
local LuckyBlock = require(script.Parent.LuckyBlock)
local Passler = require(script.Parent.Passler)

local SosyalOdul = {}

SosyalOdul.GroupId = 283943894
SosyalOdul.GroupName = "BEAMFORGE"
SosyalOdul.GroupReward = 5

export type PlaytimeOdul = {
	minutes: number,
	kind: string,
	amount: number?,
	pass: string?,
	seconds: number?,
}

SosyalOdul.Playtime = {
	{ minutes = 15, kind = "rotcoin", amount = 1 },
	{ minutes = 30, kind = "pass", pass = "AutoClicker", seconds = 900 },
	{ minutes = 60, kind = "luckyblock", amount = 1 },
	{ minutes = 120, kind = "rotcoin", amount = 2 },
	{ minutes = 180, kind = "rotcoin", amount = 3 },
} :: { PlaytimeOdul }

function SosyalOdul.enUcuzLuckyBlock(): string
	local secilen = LuckyBlock.Tiers[1]
	for _, tur in LuckyBlock.Tiers do
		if tur.order < secilen.order then
			secilen = tur
		end
	end
	return secilen.id
end

function SosyalOdul.etiket(odul: PlaytimeOdul): string
	if odul.kind == "rotcoin" then
		return `+{odul.amount} Rot Coin`
	elseif odul.kind == "rot" then
		return `+{Format.short(odul.amount)} Rot`
	elseif odul.kind == "pass" then
		local bilgi = Passler.get(odul.pass or "")
		local ad = if bilgi then bilgi.ad else (odul.pass or "Pass")
		local dakika = math.floor((odul.seconds or 0) / 60)
		return if dakika > 0 then `{ad} {dakika} min` else ad
	end
	return `{odul.amount or 1}x {LuckyBlock.get(SosyalOdul.enUcuzLuckyBlock()).displayName}`
end

local PASS_IKON: { [string]: string } = {
	AutoClicker = "autoClicker",
	Teleporter = "teleporter",
	DetectivePass = "detective",
}

function SosyalOdul.ikon(odul: PlaytimeOdul): string
	if odul.kind == "rotcoin" then
		return "rotCoin"
	elseif odul.kind == "rot" then
		return "rot"
	elseif odul.kind == "pass" then
		return PASS_IKON[odul.pass or ""] or "rewards"
	end
	return "luckyBlock"
end

function SosyalOdul.sure(saniye: number): string
	local t = math.max(0, math.floor(saniye))
	if t >= 3600 then
		return string.format("%d:%02d:%02d", t // 3600, (t % 3600) // 60, t % 60)
	end
	return string.format("%d:%02d", t // 60, t % 60)
end

return SosyalOdul
