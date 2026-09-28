--!strict
--[[
	AFK SANS SISTEMI  --  ayarlar (sunucu + istemci)

	Workspace > CloverAreas icinde bes alan var:
	    Common > Rare > Epic > Legendary > Mythic

	Her alanin adi kademe adi; kendisi yoncalarin cikacagi ZEMIN parcasi.
	Icinde "<Kademe>Barricade" (alan kilitliyken girisi kapatir),
	"<Kademe>Border" ve "Fences" klasoru var. Common'da barikat yok, bedava.

	Oyuncu alanda yonca topladikca SANS PUANI kazanir. Puan kalici; kazi ve
	olta sans carpanina eklenir (bkz. KaziSistemi > luckFor):

	    carpan = 1 + (MaxCarpan - 1) * puan / MaxPuan

	20.000.000 puan = x20 sans (tavan). Puanin carpana cevrilmesi bilerek
	oyuncuya gosterilmiyor: yavas artan x1.0003 yerine buyuyen bir sayi
	gorsun diye.

	YONCA BASINA PUAN
	Her toplanan yonca alanin sabit puanini verir (puanYonca). Bir yonca
	ortalama ~4.5 sn surer (3 sn toplama + ~1.5 sn yuruyus). Mythic'te
	tavana 50 saatte ulasilacak sekilde ayarli:

	    50 saat = 180.000 sn / 4.5 = 40.000 yonca
	    20.000.000 / 40.000 = 500 puan/yonca

	Alt alanlar belirgin sekilde yavas:

	    Common      25/yonca  ~1000 saat
	    Rare        60/yonca  ~417 saat
	    Epic       135/yonca  ~185 saat
	    Legendary  270/yonca  ~93 saat
	    Mythic     500/yonca  ~50 saat

	Toplama suresi sunucuda sayildigi icin bir oyuncu en fazla her
	ToplamaSuresi saniyede bir yonca alabilir.
]]

local Shovels = require(script.Parent:WaitForChild("Shovels"))
local Rods = require(script.Parent:WaitForChild("Rods"))

local AfkSans = {}

--[[
	ALAN FIYATLARI kurek / olta fiyatlarina BAGLI: o esyanin fiyati
	degisirse alanin fiyati da kendiliginden degisir.

	    Rare       Lv6 kurek   (Lollipop Shovel)
	    Epic       Lv11 kurek  (Frost Shovel)
	    Legendary  Lv1 olta    (Bamboo Rod)
	    Mythic     Lv5 olta    (Leviathan Rod)
]]
local function kurekFiyati(level: number): number
	for _, info in Shovels.Info do
		if info.level == level then
			return info.price
		end
	end
	error(`AfkSans: Lv{level} kurek bulunamadi`)
end

local function oltaFiyati(level: number): number
	for _, info in Rods.Info do
		if info.level == level then
			return info.price
		end
	end
	error(`AfkSans: Lv{level} olta bulunamadi`)
end

export type Alan = {
	id: string,
	-- Leprechaun panelinde gorunen ad
	displayName: string,
	-- Toplanan her yoncanin verdigi sans puani
	puanYonca: number,
	-- Rot bedeli (Common bedava)
	fiyat: number,
}

local alanlar: { Alan } = {
	{ id = "Common", displayName = "Common Clover Field", puanYonca = 25, fiyat = 0 },
	{ id = "Rare", displayName = "Rare Clover Field", puanYonca = 60, fiyat = kurekFiyati(6) },
	{ id = "Epic", displayName = "Epic Clover Field", puanYonca = 135, fiyat = kurekFiyati(11) },
	{ id = "Legendary", displayName = "Legendary Clover Field", puanYonca = 270, fiyat = oltaFiyati(1) },
	{ id = "Mythic", displayName = "Mythic Clover Field", puanYonca = 500, fiyat = oltaFiyati(5) },
}
AfkSans.Alanlar = alanlar

-- Tavan: bu kadar puan MaxCarpan kadar sans verir, fazlasi birikmez
AfkSans.MaxPuan = 20_000_000
AfkSans.MaxCarpan = 20

-- Alanda ayni anda duran yonca sayisi (oyuncu basina)
AfkSans.YoncaSayisi = 10
-- Iki yonca arasi en az bosluk (kenardan kenara, stud)
AfkSans.MinAralik = 2
-- Zemin kenarindan birakilan pay (stud)
AfkSans.KenarPayi = 2
-- Rastgele boyut araligi
AfkSans.OlcekMin = 0.3
AfkSans.OlcekMax = 0.75
-- Bir yoncanin toplanma suresi (saniye)
AfkSans.ToplamaSuresi = 3
-- Toplamaya baslamak icin yoncaya en fazla bu kadar yaklasmak gerek (yonca yaricapina ek)
AfkSans.Erisim = 3
-- Bar titremesi son bu kadar saniyede baslar
AfkSans.TitremeSuresi = 1
-- Toplama animasyonu (ToplamaSuresi kadar surer; farkliysa hizi ayarlanir)
AfkSans.ToplamaAnimasyonu = "rbxassetid://112929077414582"

-- Isimler
AfkSans.KlasorAdi = "CloverAreas"
AfkSans.NpcAdi = "Leprechaun"
-- Oyuncu nitelikleri (sunucu yazar, istemci okur)
AfkSans.PuanNiteligi = "AfkPuan"
AfkSans.SeviyeNiteligi = "AfkSeviye"

function AfkSans.sira(id: string): number?
	for i, alan in AfkSans.Alanlar do
		if alan.id == id then
			return i
		end
	end
	return nil
end

function AfkSans.get(id: string): Alan?
	local i = AfkSans.sira(id)
	return if i then AfkSans.Alanlar[i] else nil
end

-- Sans puanini carpana cevirir (1 .. MaxCarpan)
function AfkSans.carpan(puan: number): number
	local oran = math.clamp(puan, 0, AfkSans.MaxPuan) / AfkSans.MaxPuan
	return 1 + (AfkSans.MaxCarpan - 1) * oran
end

--[[
	Nokta bu alanin ustunde mi. Zemin donuk olabilir, bu yuzden parcanin
	kendi eksenlerinde bakiliyor. Yukseklik payi: zeminin 1 stud altindan
	20 stud ustune kadar (ziplayan oyuncu alandan cikmis sayilmasin).
]]
function AfkSans.icinde(zemin: BasePart, nokta: Vector3): boolean
	local yerel = zemin.CFrame:PointToObjectSpace(nokta)
	local boy = zemin.Size
	return math.abs(yerel.X) <= boy.X / 2
		and math.abs(yerel.Z) <= boy.Z / 2
		and yerel.Y >= boy.Y / 2 - 1
		and yerel.Y <= boy.Y / 2 + 20
end

return AfkSans
