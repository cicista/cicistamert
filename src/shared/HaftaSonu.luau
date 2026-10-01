--!strict

local HaftaSonu = {}

HaftaSonu.SansCarpani = 2

HaftaSonu.VfxCarpani = 2

HaftaSonu.Sure = 48 * 3600

HaftaSonu.SaatDilimi = 0

HaftaSonu.Nitelik = "HaftaSonuBitis"

HaftaSonu.KuleYolu = { "MainIsland", "updatetower" }

HaftaSonu.YaziParcasi = "TEXT"

HaftaSonu.RenkA = Color3.fromRGB(20, 90, 255)
HaftaSonu.RenkB = Color3.fromRGB(215, 235, 255)

function HaftaSonu.dogalBitis(simdi: number): number
	local kayma = HaftaSonu.SaatDilimi * 3600
	local yerel = math.floor(simdi + kayma)
	local t = os.date("!*t", yerel) :: any
	local gunBasi = yerel - (t.hour * 3600 + t.min * 60 + t.sec)

	local baslangic: number
	if t.wday == 7 then
		baslangic = gunBasi
	elseif t.wday == 1 then
		baslangic = gunBasi - 86400
	else
		return 0
	end

	return baslangic + HaftaSonu.Sure - kayma
end

function HaftaSonu.sureYazisi(kalan: number): string
	local s = math.max(0, math.floor(kalan))
	return string.format("%02d:%02d:%02d", s // 3600, (s % 3600) // 60, s % 60)
end

return HaftaSonu
