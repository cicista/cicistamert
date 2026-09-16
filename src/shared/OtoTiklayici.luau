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

	KUREGE GORE NE KIRAR  (simulasyonla olculdu, sunucu kontroluyle)

	    kurek        Common Rare Epic Legend Mythic Divine
	    Wooden  L1     +     +    -     -      -      -
	    Iron    L2     +     +    +     -      -      -
	    Golden  L3     +     +    +     +      -      -
	    Diamond L4     +     +    +     +      +      -
	    Celest. L5     +     +    +     +      +      +

	Yetmeyen kademede tiklayici DURMAZ, vurmaya devam eder; ama imlec
	geri tepmeye yetisemez, minioyun kaybedilir ve brainrot kacar.
	Oyuncuya ayrica bir uyari gosterilmez.
]]

local KaziMinigame = require(script.Parent.KaziMinigame)

local OtoTiklayici = {}

--[[
	SATIN ALMA VE SAHIPLIK Shared > Passler'da ("AutoClicker").

	Dugme HERKESTE gorunur. Gecisi olmayan oyuncuda "BUY" yazar ve
	basinca satin alma penceresi acilir (ID girilmediyse "Coming soon!").
	Eskiden Studio test kapisi yuzunden herkeste bedava acik geliyordu.
]]

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

return OtoTiklayici
