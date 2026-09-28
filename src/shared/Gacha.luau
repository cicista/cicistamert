--!strict
--[[
	YUMURTA GACHASI  --  ayarlar (sunucu + istemci)

	Haritadaki "Gacha" adli NPC'ye yaklasip E'ye basinca mor pencere acilir.
	Pencerede cikabilecek yumurtalar ve sanslari yazar; ortadaki dugme
	Robux ile bir cevirme satin alir. Cevirme Lucky Block carkinin aynisi,
	tek asamali: yalnizca yumurtalar doner.

	Cikan sey KIMLIKSIZ brainrot (yumurta): cantaya kapali girer, adini
	Detective acar. Kademe sirasi dusukten yuksege:

	    Divine > Cosmic > Secret > Infernal > Abyssal

	DIKKAT -- KIMLIK ADI, EKRANDAKI AD DEGIL (bkz. Shared > Rarity):
	    kimlik "Secret"  ->  ekranda "Divine"
	    kimlik "Gizli"   ->  ekranda "Secret"

	Robux urunu Shared > RobuxMagaza > GizliUrunler'de ("Gacha"). ID'si
	orada girilir; 0 iken dugme "coming soon" der.
]]

local Gacha = {}

export type Yumurta = {
	-- Rarity kimligi (ekrandaki ad degil)
	rarity: string,
	-- Agirlik; toplam 100 oldugu icin dogrudan yuzde
	sans: number,
}

--[[
	SANSLAR  --  toplam 100
	Abyssal %5; asagi dogru her kademe artarak ilerliyor.
]]
Gacha.Yumurtalar = {
	{ rarity = "Secret", sans = 40 }, -- Divine
	{ rarity = "Cosmic", sans = 27 },
	{ rarity = "Gizli", sans = 18 }, -- Secret
	{ rarity = "Infernal", sans = 10 },
	{ rarity = "Abyssal", sans = 5 },
} :: { Yumurta }

-- Robux fiyati (arayuzde yazar; asil tutari Developer Product belirler)
Gacha.Fiyat = 500
-- Shared > RobuxMagaza'daki urunun anahtari
Gacha.UrunAnahtari = "Gacha"

-- Haritadaki NPC'nin adi (buyuk/kucuk harf farki yok sayilir)
Gacha.NpcAdi = "Gacha"
-- ProximityPrompt menzili ve sunucunun kabul ettigi uzaklik
Gacha.PromptMesafe = 12

--[[
	CARK
	Sonucu sunucu secer; istemci seridi doldurur ve kazanani KazananSira'da
	durdurur. Sunucu da ayni surelerle bekleyip yumurtanin elde edildigi
	an FuseExplosion + FuseVFX oynatir.
]]
Gacha.BolmeSayisi = 46
Gacha.KazananSira = 40
-- Pencere acildiktan sonra cark baslamadan once (saniye)
Gacha.GirisSuresi = 0.8
-- Carkin donme suresi (saniye)
Gacha.CevirmeSuresi = 6.5
-- Sonuc gorundukten sonra pencere bu kadar acik kalir, sonra kapanabilir
Gacha.SonucSuresi = 3

--[[
	SANS ARTISI (pity)

	Infernal ya da Abyssal CIKMAYAN her cevirmede ikisinin de sansi Artis
	kadar (yuzde puani) artar; biri cikinca artis sifirlanir. Sayac oyuncu
	kaydinda: PlayerData > gachaIska.

	Eklenen pay diger yumurtalardan (Divine, Cosmic, Secret) KENDI
	oranlarinda dusulur; toplam hep 100. Diger yumurtalarin payi bitince
	artis durur (maxIska): o cevirmede Infernal ya da Abyssal kesin cikar.

	    iska  Infernal  Abyssal
	      0     10%       5%
	     10     15%      10%
	     40     30%      25%
	     85    52.5%    47.5%   (kesin)
]]
Gacha.Artis = 0.5
Gacha.ArtanKademeler = { Infernal = true, Abyssal = true } :: { [string]: boolean }

local function tabanlar(): (number, number)
	local artan, diger = 0, 0
	for _, y in Gacha.Yumurtalar do
		if Gacha.ArtanKademeler[y.rarity] then
			artan += y.sans
		else
			diger += y.sans
		end
	end
	return artan, diger
end

-- Artisin durdugu iska sayisi: diger yumurtalarin payi burada biter
function Gacha.maxIska(): number
	local _, diger = tabanlar()
	local sayi = 0
	for _ in Gacha.ArtanKademeler do
		sayi += 1
	end
	if sayi == 0 or Gacha.Artis <= 0 then
		return 0
	end
	return math.floor(diger / (Gacha.Artis * sayi) + 1e-6)
end

-- Iska sayisina gore her yumurtanin sansi (yuzde, toplam 100)
function Gacha.sanslar(iska: number?): { [string]: number }
	local n = math.clamp(math.floor(iska or 0), 0, Gacha.maxIska())
	local artis = Gacha.Artis * n
	local _, diger = tabanlar()

	local eklenen = 0
	local sonuc: { [string]: number } = {}
	for _, y in Gacha.Yumurtalar do
		if Gacha.ArtanKademeler[y.rarity] then
			sonuc[y.rarity] = y.sans + artis
			eklenen += artis
		end
	end
	-- Diger yumurtalar eklenen kadar, kendi oranlarinda kuculur
	local kalan = math.max(diger - eklenen, 0)
	for _, y in Gacha.Yumurtalar do
		if not Gacha.ArtanKademeler[y.rarity] then
			sonuc[y.rarity] = if diger > 0 then y.sans * kalan / diger else 0
		end
	end
	return sonuc
end

-- Ekranda yazan yuzde: tam sayiysa "5%", degilse "7.5%"
function Gacha.yuzde(deger: number): string
	local yuvarlak = math.floor(deger * 10 + 0.5) / 10
	if yuvarlak == math.floor(yuvarlak) then
		return `{math.floor(yuvarlak)}%`
	end
	return `{string.format("%.1f", yuvarlak)}%`
end

-- Yumurtanin ekranda gorunen adi: "Divine Egg"
function Gacha.yumurtaAdi(displayName: string): string
	return `{displayName} Egg`
end

-- Bir yumurtanin sansi (iska verilirse artisla birlikte)
function Gacha.sans(rarity: string, iska: number?): number
	return Gacha.sanslar(iska)[rarity] or 0
end

-- Agirliga gore bir kademe secer (iska verilirse artisla birlikte)
function Gacha.sec(rng: Random, iska: number?): string
	local sanslar = Gacha.sanslar(iska)
	local toplam = 0
	for _, y in Gacha.Yumurtalar do
		toplam += sanslar[y.rarity] or 0
	end

	local zar = rng:NextNumber(0, toplam)
	local son = Gacha.Yumurtalar[1].rarity
	for _, y in Gacha.Yumurtalar do
		local agirlik = sanslar[y.rarity] or 0
		-- Payi bitmis yumurta (kesin cevirmede Divine) hic secilmez
		if agirlik <= 0 then
			continue
		end
		son = y.rarity
		zar -= agirlik
		if zar <= 0 then
			return y.rarity
		end
	end
	return son
end

-- Istemcide bekleme toplami: sunucu patlamayi bu kadar sonra oynatir
function Gacha.toplamSure(): number
	return Gacha.GirisSuresi + Gacha.CevirmeSuresi
end

return Gacha
