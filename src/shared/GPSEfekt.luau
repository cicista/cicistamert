--!strict
--[[
	GPS ARAMA SINYALI  --  ayarlar

	Dedektor elde tutulurken antenin ucundaki topun etrafinda yesil bir
	halka acilir: kucuk baslar, buyur, solar ve kaybolur.

	AYNI ANDA TEK HALKA VARDIR. Bir halka tamamen kaybolmadan digeri
	baslamaz; aralarinda ayrica kisa bir sessizlik (gap) durur. Boylece
	sinyal "surekli akan" degil, "arada bir yoklayan" gibi gorunur.

	Zeminde halka YOK -- ayak dibindeki daireler kaldirildi, sinyal
	yalnizca antenden cikiyor.

	NEDEN ISTEMCIDE
	Tamamen gorsel; sunucuda uretilse saniyede ~20 kez replike edilir ve
	titrer. Divine parildamasi (IlahiRenk) ve base donmesi (BaseGorsel) ile
	ayni cozum: sunucu hicbir sey yapmaz, her makine kendi cizer.

	Halkalar YEREL uretilir ama HERKES bu script'i calistirdigi icin herkes
	birbirinin arama sinyalini gorur.
]]

local GPSEfekt = {}

-- Antenin ucundaki topun adi; istemci sinyali ona baglar
GPSEfekt.BallName = "Anten"

--[[
	Sinyalin rengi. Dedektor seviyesi degisse de arama sinyali her zaman
	yesil kalir.
]]
GPSEfekt.color = Color3.fromRGB(60, 220, 90)

--[[
	Bir halkanin acilip tamamen kaybolmasi kac saniye surer.
	Buyutursen sinyal daha agir ve sakin akar.
]]
GPSEfekt.cycle = 1

--[[
	Iki halka ARASINDAKI sessizlik (saniye).

	Halka kaybolduktan sonra bu kadar hicbir sey gorunmez, sonra yenisi
	baslar. Sifir yaparsan halkalar pes pese gelir ama yine ust uste
	binmezler; buyutursen sinyal seyrekler.
]]
GPSEfekt.gap = 0.37

------------------------------------------------------------------
-- ANTEN HALKASI
------------------------------------------------------------------
GPSEfekt.Antenna = {
	-- Halkanin cizildigi kare alanin ekrandaki boyu (piksel)
	size = 195,
	-- Kac stud uzaktan sonra gorunmez olsun
	maxDistance = 90,
	-- Halka en kucukken capinin, en buyuk capa orani
	minScale = 0.18,
	-- Cizgi kalinligi (piksel). Ince olsun istendi.
	thickness = 2,
	-- Halka dogarken saydamligi
	fadeFrom = 0.1,
	-- Halka en buyukken saydamligi (1 = tamamen kaybolur)
	fadeTo = 1,
}

--[[
	Halkanin su anki evresi.

	Donen deger 0..1 arasindaysa halka gorunur ve o oranda acilmistir.
	nil donerse SESSIZLIK anindayiz: halka hic cizilmez.

	Tek halka oldugu icin "biri kaybolmadan digeri belirmesin" kurali
	kendiliginden saglanir.
]]
function GPSEfekt.phase(clock: number): number?
	local total = GPSEfekt.cycle + GPSEfekt.gap
	if total <= 0 then
		return nil
	end

	local t = clock % total
	if t > GPSEfekt.cycle then
		return nil
	end

	return t / GPSEfekt.cycle
end

return GPSEfekt
