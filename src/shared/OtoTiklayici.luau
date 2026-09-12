--!strict
--[[
	OTOMATIK TIKLAYICI  --  Robux'la alinan kalici gecis

	Kumdaki kazi minioyunu tiklama tabanlidir. Bu gecisi alan oyuncu
	barin yanindaki dugmeyle otomatik tiklamayi acar; minioyun boyunca
	kurek kendi kendine vurur.

	--------------------------------------------------------------
	NEDEN TAVANIN USTUNE CIKMIYOR

	KaziMinigame kasten makro korumalidir: saniyede en fazla MAX_CPS
	tiklama SAYILIR, fazlasi yok sayilir (jeton kovasi). Zorluk
	merdiveninin butun basamaklari bu tavana gore hesaplanmistir.

	Bu yuzden otomatik tiklayici tavani ASMAYA CALISMAZ -- tavanin tam
	kendisinde, sabit araliklarla tiklar. Sebepleri:

	  1. Daha hizli tiklamanin FAYDASI YOK. Kova fazlasini zaten yok
	     sayar; 50 cps ile 12 cps ayni hizda ilerler.

	  2. Daha hizli tiklamanin ZARARI VAR. Kova basta BURST kadar hazir
	     jeton tutuyor; hepsi ilk karede harcanirsa minioyun sunucunun
	     bekledigi alt sinirdan once biter ve zafer REDDEDILIR
	     (bkz. KaziSistemi > MACRO / EXPLOIT KONTROLU).

	Sabit aralikla tiklamak kovayi dengede tutar: saniyede CPS jeton
	dolar, saniyede CPS jeton harcanir, kova hep dolu kalir.

	--------------------------------------------------------------
	DENGEYE ETKISI  --  bilerek kabul edilen takas

	Erisilebilen en zor basamak 5.5 cps ister, tavan 12 cps. Yani bu
	gecis, KURENIN YETTIGI her kademeyi garanti kazandirir; kazidaki
	beceri unsuru o oyuncu icin biter.

	Erisilemez kademeler (fark >= IMKANSIZ_FARK) yine alinamaz: oradaki
	geri tepme tavanin 2.5 katini ister. Yani kurek-kademe merdiveninin
	SINIRLARI korunur, kaybolan sey basamak icindeki efordur.
]]

local RunService = game:GetService("RunService")

local KaziMinigame = require(script.Parent.KaziMinigame)

local OtoTiklayici = {}

--[[
	Creator Dashboard'da olusturulan Pass'in ID'si.

	0 = henuz baglanmadi. Bu haldeyken dugme hic gorunmez, kimseye
	satin alma penceresi acilmaz -- yani ID girilmeden oyuna zarar
	vermez, ozellik sadece uyur.

	Nasil alinir:
	  create.roblox.com > deneyim > Associated Items > Passes > Create
	  Pass'i olusturduktan sonra fiyatini FIYAT ile ayni yap (500).
	  Adres cubugundaki .../passes/<ID>/... sayisini buraya yaz.
]]
OtoTiklayici.GAMEPASS_ID = 0

-- Magazada/dugmede yazan fiyat. Robux fiyatini Roblox tarafinda ayarlarsin;
-- bu sayi yalnizca arayuzde gosterilir.
OtoTiklayici.FIYAT = 500

--[[
	Saniyedeki otomatik tiklama sayisi.

	Makro tavaninin TAM KENDISI -- ustu degil. Yukaridaki "NEDEN TAVANIN
	USTUNE CIKMIYOR" bolumu bunun sebebini anlatiyor. Elle degistirmeden
	once orayi oku: buyutmek faydasiz ve zararli, kucultmek gecisi
	zayiflatir.
]]
OtoTiklayici.CPS = KaziMinigame.MAX_CPS

-- Iki otomatik tiklama arasindaki sure (saniye)
OtoTiklayici.ARALIK = 1 / OtoTiklayici.CPS

--[[
	Pass baglandi mi?

	ID girilmediyse ozellik tamamen sessiz kalir: dugme cizilmez,
	sunucu sorgu yapmaz. Yarim kurulmus bir satin alma akisinin
	oyuncuya gorunmesi, hic gorunmemesinden kotudur.
]]
function OtoTiklayici.kurulu(): boolean
	return OtoTiklayici.GAMEPASS_ID > 0
end

--[[
	STUDIO TEST KAPISI

	Pass olusturulmadan ozelligi denemek icin. ACIKKEN, yalnizca
	STUDIO'DA, pass alinmis gibi davranilir: dugme cikar, tiklayinca
	acilir/kapanir, kurek kendi kendine vurur. Satin alma penceresi
	acilmaz (acilacak bir pass yok).

	YAYINDAKI OYUNU ETKILEMEZ: RunService:IsStudio() yalnizca Studio
	icinde true. Sunucuda calisan gercek oyunda bu kapi kapalidir, yani
	burayi true birakip yayina cikmak kimseye bedava pass vermez.

	Pass ID girildikten sonra bu kapinin islevi kalmaz: kurulu() true
	olur ve sahiplik normal yoldan, MarketplaceService'ten okunur.
]]
OtoTiklayici.TEST_STUDIO = true

--[[
	Dugme cizilsin mi?

	Ya pass baglanmistir, ya da Studio'da test kapisi aciktir.
]]
function OtoTiklayici.gorunur(): boolean
	if OtoTiklayici.kurulu() then
		return true
	end
	return OtoTiklayici.TEST_STUDIO and RunService:IsStudio()
end

--[[
	Sahiplik SORULMADAN dogru sayilsin mi?

	Yalnizca test kapisi halinde. Pass baglandiysa burasi false doner ve
	cevap sunucudan gelir -- test kapisi gercek sahipligin onune gecmez.
]]
function OtoTiklayici.testSahipligi(): boolean
	return not OtoTiklayici.kurulu() and OtoTiklayici.TEST_STUDIO and RunService:IsStudio()
end

return OtoTiklayici
