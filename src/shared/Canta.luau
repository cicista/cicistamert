--!strict
--[[
	CANTA KAPASITESI  (ModuleScript)
	Yeri: ReplicatedStorage > Shared > Canta

	Oyuncunun cantasinda (base slotlarina KONMAMIS) en fazla kac brainrot
	durabilecegi ve bunun Rot ile nasil buyutuldugu.

	    20 ile baslar  ->  5'er 5'er artar  ->  100'de durur

	NEDEN SINIR VAR
	Sinirsiz canta iki seyi bozuyordu: oyuncu yuzlerce brainrotu satmadan
	biriktirip envanteri okunmaz hale getiriyordu, ve Fuse'a girecek
	malzemeyi sonsuza kadar stoklayabiliyordu. Sinir, oyuncuyu ya satmaya
	ya da base'ine koymaya itiyor.

	BASE SLOTLARI BU SINIRA GIRMEZ
	Slota konan brainrot base'de duruyor, cantada degil. Onlarin sayisi
	ayri bir yukseltmeyle artiyor (bkz. Shared > Bases > Upgrade).

	FIYAT
	Onalti yukseltme var (20->25 ... 95->100). Ilki IlkFiyat, sonuncusu
	SonFiyat; aradakiler ussel olarak dagiliyor. Yani iki uc degeri
	degistirmek butun egriyi yeniden dagitiyor, arada elle sayi yazmak
	gerekmiyor.

	    10M   24M   57M   138M  331M  794M  1.9B  4.6B
	    11B   26B   63B   151B  362B  869B  2.1T  5T      (toplam ~8.6T)

	Her adim bir oncekinin 2.4 kati: ne basta duvar var ne sonda ucurum.
	Ilki ucuz, oyuncu sinirin varligini ogrenirken takilip kalmasin.
]]

local Canta = {}

-- Oyuna yeni baslayan oyuncunun canta kapasitesi
Canta.Baslangic = 20

--[[
	Her yukseltmede kac slot eklenir.

	5, 10 DEGIL. Sebebi fiyat egrisi: 20-100 arasi 10'ar gidince sekiz
	yukseltme oluyor ve 10M ile 5T arasini sekize bolmek adim basina
	6.5 kat demek -- son adim tek basina 767B'den 5T'ye zipliyordu.
	5'er gidince onalti adim oluyor ve her adim 2.4 kat: basi da sonu da
	yumusak.

	10 yapilirsa ucurum geri gelir' o zaman ya IlkFiyat'i yukseltmek ya da
	SonFiyat'i dusurmek gerekir.
]]
Canta.Adim = 5

-- Kapasitenin ulasabilecegi en yuksek deger
Canta.EnCok = 100

-- Ilk yukseltmenin (20 -> 30) bedeli
Canta.IlkFiyat = 10_000_000

-- Son yukseltmenin (90 -> 100) bedeli
Canta.SonFiyat = 5_000_000_000_000

-- Toplam kac yukseltme var
function Canta.yukseltmeSayisi(): number
	return math.max(0, (Canta.EnCok - Canta.Baslangic) // Canta.Adim)
end

--[[
	Kapasiteyi gecerli bir degere oturtur: baslangicin altina inmez,
	en cogu asmaz ve her zaman Adim'in katinda kalir.

	Kayittan gelen bozuk bir sayi (elle duzenleme, eski surum) burada
	toparlaniyor; cagiran taraflarin ayrica denetlemesi gerekmiyor.
]]
function Canta.duzelt(deger: number?): number
	local sayi = tonumber(deger) or Canta.Baslangic
	sayi = math.clamp(math.floor(sayi), Canta.Baslangic, Canta.EnCok)

	-- Adim'in katina yuvarla (asagi): 35 -> 30
	local fazla = (sayi - Canta.Baslangic) % Canta.Adim
	return sayi - fazla
end

--[[
	Kapasite su an `mevcut` iken SIRADAKI yukseltmenin bedeli.
	Kapasite dolmussa nil doner.
]]
function Canta.fiyat(mevcut: number): number?
	local kapasite = Canta.duzelt(mevcut)
	if kapasite >= Canta.EnCok then
		return nil
	end

	local adet = Canta.yukseltmeSayisi()
	if adet <= 1 then
		return Canta.IlkFiyat
	end

	-- Kacinci yukseltme (0 = ilki)
	local sira = (kapasite - Canta.Baslangic) // Canta.Adim
	local oran = (Canta.SonFiyat / Canta.IlkFiyat) ^ (1 / (adet - 1))
	local ham = Canta.IlkFiyat * oran ^ sira

	--[[
		Ilk uc basamaga yuvarlaniyor: 1.72B yerine 1.72B, kusuratli
		sayilar arayuzde cirkin duruyor ve oyuncu "neden 1,718,000,000"
		diye sormasin.
	]]
	local basamak = 10 ^ math.max(0, math.floor(math.log10(ham)) - 2)
	return math.floor(ham / basamak + 0.5) * basamak
end

-- Kapasite en yuksek degerde mi
function Canta.dolu(mevcut: number): boolean
	return Canta.duzelt(mevcut) >= Canta.EnCok
end

return Canta
