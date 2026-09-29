--!strict

local Hiz = {}

Hiz.Max = 100
Hiz.TabanHiz = 16
Hiz.MaxCarpan = 10

Hiz.IlkFiyat = 2_500
Hiz.SonFiyat = 5_000_000_000_000

Hiz.Oran = (Hiz.SonFiyat / Hiz.IlkFiyat) ^ (1 / (Hiz.Max - 1))

Hiz.Nitelik = "SpeedLevel"

local function yuvarla(x: number): number
	local basamak = 10 ^ math.max(0, math.floor(math.log10(x)) - 2)
	return math.floor(x / basamak + 0.5) * basamak
end

function Hiz.fiyat(alinan: number): number?
	if alinan >= Hiz.Max then
		return nil
	end
	if alinan >= Hiz.Max - 1 then
		return Hiz.SonFiyat
	end
	return yuvarla(Hiz.IlkFiyat * Hiz.Oran ^ math.max(0, alinan))
end

function Hiz.topluFiyat(alinan: number, adet: number): number
	local toplam = 0
	for i = 0, adet - 1 do
		local f = Hiz.fiyat(alinan + i)
		if not f then
			break
		end
		toplam += f
	end
	return toplam
end

function Hiz.hiz(alinan: number): number
	local oran = math.clamp(alinan, 0, Hiz.Max) / Hiz.Max
	return Hiz.TabanHiz * (1 + (Hiz.MaxCarpan - 1) * oran)
end

function Hiz.carpan(alinan: number): number
	return Hiz.hiz(alinan) / Hiz.TabanHiz
end

local Renkler = {
	{ en = 10, renk = Color3.fromRGB(235, 235, 235) },
	{ en = 25, renk = Color3.fromRGB(110, 230, 120) },
	{ en = 45, renk = Color3.fromRGB(90, 180, 255) },
	{ en = 65, renk = Color3.fromRGB(190, 110, 255) },
	{ en = 85, renk = Color3.fromRGB(255, 150, 50) },
	{ en = math.huge, renk = Color3.fromRGB(255, 50, 50) },
}

Hiz.MaxRebirth = #Renkler
Hiz.RebirthNitelik = "SpeedRebirth"

Hiz.IzIlkOmur = 0.35
Hiz.IzOmurArtisi = 0.15

function Hiz.rebirthRengi(rebirth: number): Color3?
	local r = Renkler[math.clamp(rebirth, 0, #Renkler)]
	return if rebirth >= 1 and r then r.renk else nil
end

function Hiz.izOmru(rebirth: number): number
	return Hiz.IzIlkOmur + Hiz.IzOmurArtisi * math.max(0, rebirth - 1)
end

function Hiz.rebirthAtilabilir(alinan: number, rebirth: number): boolean
	return alinan >= Hiz.Max and rebirth < Hiz.MaxRebirth
end

function Hiz.renk(seviye: number): Color3
	for _, r in Renkler do
		if seviye <= r.en then
			return r.renk
		end
	end
	return Renkler[#Renkler].renk
end

return Hiz
