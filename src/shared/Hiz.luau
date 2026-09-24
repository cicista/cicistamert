--!strict
--[[
	HIZ YUKSELTMESI  (sol menudeki ayakkabi butonu)

	Oyuncu Rot ile 100 kez hiz yukseltmesi alabilir.

	    alinan  = kac yukseltme alindi (0..100), kayitta speedLevel
	    seviye  = alinan + 1  ->  karakterin altinda "Speed 57"

	HIZ
	Yurume hizi alinan yukseltmeyle DOGRUSAL artar; 100. yukseltmede
	taban hizin 10 katina ulasir (16 -> 160).

	REBIRTH
	Speed 101'e (100 yukseltme) ulasan oyuncu rebirth atabilir: hiz Speed 1'e
	doner, karakterin arkasinda bir iz (trail) belirir. Her rebirth'te iz
	biraz uzar ve rengi bir sonraki hiz rengine gecer:
	    1 beyaz, 2 yesil, 3 mavi, 4 mor, 5 turuncu, 6 kirmizi
	Kirmizidan (6. rebirth) sonra rebirth atilamaz.

	FIYAT
	Katlanarak artar. Ilk yukseltme IlkFiyat, 100. yukseltme SonFiyat --
	en pahali oltayla (Leviathan Rod) ayni. Aradaki her adim ayni oranda
	pahalilasir (~%22).
]]

local Hiz = {}

Hiz.Max = 100
Hiz.TabanHiz = 16
Hiz.MaxCarpan = 10

Hiz.IlkFiyat = 2_500
--[[
	Son kademe 5T: oyundaki en pahali tek satin alma. Bir ust basamak
	Coming Soon adasiyla (5T) ayni; en pahali olta ve flyboard 3T.
]]
Hiz.SonFiyat = 5_000_000_000_000

-- Her adimin fiyat carpani: IlkFiyat * oran^(Max-1) = SonFiyat
Hiz.Oran = (Hiz.SonFiyat / Hiz.IlkFiyat) ^ (1 / (Hiz.Max - 1))

-- Karakterdeki nitelik: istemci ve bas ustu yazisi buradan okur
Hiz.Nitelik = "SpeedLevel"

local function yuvarla(x: number): number
	-- Ilk 3 basamak: 2.5K, 3.11K ... 5T
	local basamak = 10 ^ math.max(0, math.floor(math.log10(x)) - 2)
	return math.floor(x / basamak + 0.5) * basamak
end

-- 'alinan' yukseltme varken SIRADAKININ fiyati; hepsi alindiysa nil
function Hiz.fiyat(alinan: number): number?
	if alinan >= Hiz.Max then
		return nil
	end
	if alinan >= Hiz.Max - 1 then
		return Hiz.SonFiyat
	end
	return yuvarla(Hiz.IlkFiyat * Hiz.Oran ^ math.max(0, alinan))
end

-- 'alinan' yukseltmeden sonraki 'adet' yukseltmenin toplam fiyati
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

-- Yurume hizi
function Hiz.hiz(alinan: number): number
	local oran = math.clamp(alinan, 0, Hiz.Max) / Hiz.Max
	return Hiz.TabanHiz * (1 + (Hiz.MaxCarpan - 1) * oran)
end

-- Taban hizin kac kati (arayuz icin): 1.0 .. 10.0
function Hiz.carpan(alinan: number): number
	return Hiz.hiz(alinan) / Hiz.TabanHiz
end

--[[
	YAZI RENGI  --  seviye yukseldikce isinir

	    Speed 1-10     beyaz
	    Speed 11-25    yesil
	    Speed 26-45    mavi
	    Speed 46-65    mor
	    Speed 66-85    turuncu
	    Speed 86-101   kirmizi
]]
local Renkler = {
	{ en = 10, renk = Color3.fromRGB(235, 235, 235) },
	{ en = 25, renk = Color3.fromRGB(110, 230, 120) },
	{ en = 45, renk = Color3.fromRGB(90, 180, 255) },
	{ en = 65, renk = Color3.fromRGB(190, 110, 255) },
	{ en = 85, renk = Color3.fromRGB(255, 150, 50) },
	{ en = math.huge, renk = Color3.fromRGB(255, 50, 50) },
}

-- En fazla rebirth: renk sayisi kadar (kirmizida biter)
Hiz.MaxRebirth = #Renkler
Hiz.RebirthNitelik = "SpeedRebirth"

-- Izin (trail) omru: ilk rebirth'te 0.35 sn, her rebirth'te +0.15 sn
Hiz.IzIlkOmur = 0.35
Hiz.IzOmurArtisi = 0.15

-- 'rebirth' kez rebirth atilmis oyuncunun iz rengi (0 ise iz yok)
function Hiz.rebirthRengi(rebirth: number): Color3?
	local r = Renkler[math.clamp(rebirth, 0, #Renkler)]
	return if rebirth >= 1 and r then r.renk else nil
end

function Hiz.izOmru(rebirth: number): number
	return Hiz.IzIlkOmur + Hiz.IzOmurArtisi * math.max(0, rebirth - 1)
end

-- Rebirth atilabilir mi
function Hiz.rebirthAtilabilir(alinan: number, rebirth: number): boolean
	return alinan >= Hiz.Max and rebirth < Hiz.MaxRebirth
end

-- 'seviye' = alinan + 1
function Hiz.renk(seviye: number): Color3
	for _, r in Renkler do
		if seviye <= r.en then
			return r.renk
		end
	end
	return Renkler[#Renkler].renk
end

return Hiz
