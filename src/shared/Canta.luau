--!strict

local Canta = {}

Canta.Baslangic = 20

Canta.Adim = 5

Canta.EnCok = 100

Canta.IlkFiyat = 10_000_000

Canta.SonFiyat = 5_000_000_000_000

function Canta.yukseltmeSayisi(): number
	return math.max(0, (Canta.EnCok - Canta.Baslangic) // Canta.Adim)
end

function Canta.duzelt(deger: number?): number
	local sayi = tonumber(deger) or Canta.Baslangic
	sayi = math.clamp(math.floor(sayi), Canta.Baslangic, Canta.EnCok)

	local fazla = (sayi - Canta.Baslangic) % Canta.Adim
	return sayi - fazla
end

function Canta.fiyat(mevcut: number): number?
	local kapasite = Canta.duzelt(mevcut)
	if kapasite >= Canta.EnCok then
		return nil
	end

	local adet = Canta.yukseltmeSayisi()
	if adet <= 1 then
		return Canta.IlkFiyat
	end

	local sira = (kapasite - Canta.Baslangic) // Canta.Adim
	local oran = (Canta.SonFiyat / Canta.IlkFiyat) ^ (1 / (adet - 1))
	local ham = Canta.IlkFiyat * oran ^ sira

	local basamak = 10 ^ math.max(0, math.floor(math.log10(ham)) - 2)
	return math.floor(ham / basamak + 0.5) * basamak
end

function Canta.dolu(mevcut: number): boolean
	return Canta.duzelt(mevcut) >= Canta.EnCok
end

return Canta
