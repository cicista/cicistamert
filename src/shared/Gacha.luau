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

-- Yumurtanin ekranda gorunen adi: "Divine Egg"
function Gacha.yumurtaAdi(displayName: string): string
	return `{displayName} Egg`
end

function Gacha.sans(rarity: string): number
	for _, y in Gacha.Yumurtalar do
		if y.rarity == rarity then
			return y.sans
		end
	end
	return 0
end

-- Agirliga gore bir kademe secer
function Gacha.sec(rng: Random): string
	local toplam = 0
	for _, y in Gacha.Yumurtalar do
		toplam += y.sans
	end

	local zar = rng:NextNumber(0, toplam)
	for _, y in Gacha.Yumurtalar do
		zar -= y.sans
		if zar <= 0 then
			return y.rarity
		end
	end
	return Gacha.Yumurtalar[1].rarity
end

-- Istemcide bekleme toplami: sunucu patlamayi bu kadar sonra oynatir
function Gacha.toplamSure(): number
	return Gacha.GirisSuresi + Gacha.CevirmeSuresi
end

return Gacha
