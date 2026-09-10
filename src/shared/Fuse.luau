--!strict
--[[
	FUSE  --  brainrot birlestirme ve coin sistemi

	IKI NPC
	  1. FUSE MAKINESI    Ayni kademeden 5 esya alir, BIR UST kademede bir
	                      coin verir.
	  2. COIN BOZDURUCU   Coini alir, o kademeden bir brainrot cikarir.

	MAKINE KURALLARI
	  - Icine konan butun esyalar AYNI KADEMEDEN olmali. Farkli kademe
	    reddedilir.
	  - Brainrot da coin de konabilir; coin kendi kademesi ve boyutuyla
	    islenir. Yani 5 Epic coin -> 1 Legendary coin.
	  - Cikan coinin BOYUTU, iceri konan esyalarin boyutlarindan agirlikli
	    cekilir: 3 Tiny + 1 Large + 1 Huge -> %60 Tiny, %20 Large, %20 Huge.
	  - Cikan coinin MUTASYONU da iceridekilerden aktarilir: her mutasyonlu
	    esya %10 katar. 2 Gold + 1 Diamond -> %20 Gold, %10 Diamond,
	    %70 mutasyonsuz.
	  - En ust kademe (Divine) birlestirilemez; ustu yok.
	  - Makineye konan esyalar oyuncunun envanterinden CIKAR ama kaybolmaz:
	    Fuse.Timeout saniye boyunca yeni esya konmazsa hepsi geri verilir.

	COIN
	  Coinin uc bilgisi var: kademe, boyut ve mutasyon. Bozdurulunca o
	  kademeden rastgele bir brainrot cikar; BOYUT ve MUTASYON coinden
	  aynen gecer, yeniden cekilmez. Yani Huge/Gold bir coin her zaman
	  Huge/Gold bir brainrot verir.

	  Coinin adi kademe ve boyuttan turer ("Tiny Epic Coin"), rengi de
	  kademenin rengidir. Mutasyon isme EKLENMEZ -- ipucunda, bozdurucu
	  listesinde ve coinin isiginda gorunur.
]]

local Condition = require(script.Parent.Condition)
local Mutations = require(script.Parent.Mutations)
local Rarity = require(script.Parent.Rarity)

local Fuse = {}

-- Bir coin uretmek icin kac esya gerekir
Fuse.Required = 5

-- Makineye kac saniye yeni esya konmazsa icindekiler geri verilir
Fuse.Timeout = 30

--[[
	COIN CARKI

	Bozdurucunun ruleti tek asamalidir: kademe zaten coinin uzerinde yaziyor,
	merak edilen hangi brainrot oldugu. Bu yuzden dogrudan brainrot serdi
	dondurulur (bkz. StarterPlayerScripts > Rulet).
]]
Fuse.Wheel = {
	cellCount = 30,
	winnerIndex = 24,
	spinTime = 2.8,
	-- Cark durduktan sonra odulun cantaya girmesi icin beklenen ek sure
	settle = 0.4,
}

function Fuse.totalSpinTime(): number
	return Fuse.Wheel.spinTime + Fuse.Wheel.settle
end

--[[
	BIRLESME GOSTERISI

	5. esya konuldugu anda coin dogrudan envantere dusuyordu; o kadar hizli
	oluyordu ki oyuncu ne kazandigini gormuyordu. Artik once bir gosteri
	oynuyor:

	    gather -> iceri konan esyalarin renginde RUHLAR ekranda bir cember
	              olusturur, donerek merkeze dogru kapanir
	    flash  -> merkezde birlesip beyaza patlar
	    burst  -> yeni kademenin renginde bir sok dalgasi ve yildizlar dagilir,
	              coinin adi okunur
	    hold   -> okunacak kadar ekranda kalir

	Coin VERIYE hemen yazilir (gosteri sirasinda oyuncu cikarsa kaybolmasin)
	ama cantaya ve envanter ekranina ancak gosteri bitince yansitilir. Bu
	yuzden sureler burada: sunucu da istemci de ayni kaynagi okur.
]]
Fuse.Merge = {
	gatherTime = 1.4,
	flashTime = 0.35,
	burstTime = 1.1,
	holdTime = 0.9,

	-- Patlama anindaki ekran sarsintisi
	shakeTime = 0.65,
	-- Sarsintinin siddeti (stud). Buyutursen kamera daha cok savrulur.
	shakeStrength = 2.6,
}

function Fuse.mergeTime(): number
	local M = Fuse.Merge
	return M.gatherTime + M.flashTime + M.burstTime + M.holdTime
end

--[[
	PATLAMA ANI  --  gosteri baslangicindan kac saniye sonra.

	Ruhlar merkeze kapanir (gather), beyaz parlamada birlesir (flash) ve
	ISTE O AN patlar. Dunyadaki VFX ile ekran sarsintisi tam bu ana
	kilitlenir; sunucu da istemci de ayni degeri okur.
]]
function Fuse.burstDelay(): number
	return Fuse.Merge.gatherTime + Fuse.Merge.flashTime
end

--[[
	PATLAMA EFEKTI (VFX)

	Workspace'te -- ya da duzenli yeri olan ReplicatedStorage > Assets > VFX
	icinde -- bu isimde bir Part aranir. Icindeki butun ParticleEmitter,
	PointLight, Beam ve Trail'lerin RENGI cikan coinin kademesine cevrilir.

	Patlama BIRLESTIREN OYUNCUNUN KARAKTERINDE olur ve ona kaynaklanir --
	yani oyuncu yururse efekt uzerinde kalir. Sunucu urettigi icin
	haritadaki herkes gorur, yalnizca birlestiren degil.

	Efekt bulunamazsa gosteri sessizce VFX'siz oynar; oyun calismaya devam
	eder, Output'a bir kez uyari duser.
]]
Fuse.VFX = {
	name = "FuseVFX",
	-- Patlama karakterin govde hizasindan kac stud YUKARIDA olussun
	height = 3,
	-- Efekt kac saniye sonra temizlenir (parcaciklarin omru bitsin diye)
	lifetime = 3,
	-- Tek seferlik patlamada her yayicinin attigi parcacik sayisi
	burst = 60,
	-- Akmaya devam eden yayicilar kac saniye sonra susturulur
	stopAfter = 0.6,
	--[[
		KADEMEYE GORE PATLAMA BUYUKLUGU

		Parcacik boyu, hizi ve isik menzili bu carpanla olceklenir; yani
		patlamanin CAPI buyur. Yazilmayan kademe 1 (normal) sayilir.

		Divine'in kimligi hala "Secret" -- gorunen adi degisti, veri
		uyumlulugu icin kimlik korundu (bkz. Shared > Rarity).
	]]
	scaleByRarity = {
		Secret = 1.6,
	},

	--[[
		SESLER

		Studio'ya elle konulmus Sound nesnelerinin adlari. Efektle ayni
		yerlerde aranir: Workspace ya da ReplicatedStorage > Assets > Sounds.

		Her alan bir ADAY LISTESI; ilk bulunan calinir. Boylece Studio'da
		ad yanlis yazilmis olsa da tutar (NPC'lerdeki altName mantiginin
		aynisi). Hicbiri bulunamazsa gosteri sessizce sessiz oynar.

		charge    -> ruhlar toplanmaya baslarken
		explosion -> tam patlama aninda, efektle ayni karede
	]]
	charge = { "FuseCharge", "FuseCarge" },
	explosion = { "FuseExplosion" },
	--[[
		Renklendirme bicimi.

		true  : parcaciklarin KENDI parlaklik ve doygunluk yapisi korunur,
		        yalnizca renk TONU degisir. Beyaz cekirdek beyaz kalir,
		        renkli uclar hedef renge doner -- paketin tasarimi bozulmaz.
		false : her sey duz tek renk olur.
	]]
	preserveShading = true,
}

--[[
	Bir kademenin BIR USTU. En ust kademede nil doner.
	Makine buna gore hangi coini verecegini bulur.
]]
function Fuse.nextRarity(rarityId: string): string?
	local info = Rarity.Info[rarityId :: Rarity.RarityId]
	if not info then
		return nil
	end

	for _, id in Rarity.Order do
		if Rarity.Info[id].order == info.order + 1 then
			return id
		end
	end

	return nil
end

--[[
	Ekranda gorunen coin adi.

	    (Epic, Tiny, Normal)  ->  "Tiny Epic Coin"
	    (Epic, Tiny, Gold)    ->  "Gold Tiny Epic Coin"

	Coinde mutasyon ISME yazilir -- brainrotlardan farkli olarak. Sebep:
	brainrotun mutasyonu zaten altindaki carpan satirinda gorunuyor, coinde
	ise coinin tamami bu uc bilgiden ibaret; isim disinda yazacak yer yok.
]]
function Fuse.coinName(rarityId: string, conditionId: string, mutationId: string?): string
	local base = `{Condition.get(conditionId).shortName} {Rarity.displayName(rarityId)} Coin`

	if Mutations.isSpecial(mutationId) then
		return `{Mutations.get(mutationId).displayName} {base}`
	end

	return base
end

-- Coinin rengi kademesinin rengidir
function Fuse.coinColor(rarityId: string): Color3
	return Rarity.color(rarityId)
end

export type SizeChance = {
	id: string,
	count: number,
	chance: number,
}

--[[
	Iceri konan esyalarin BOYUT DAGILIMI.

	entries: { { condition = "Tiny" }, ... }
	Donen: Condition.Order sirasinda, yalnizca iceride BULUNAN boyutlar.

	Arayuz bunu oldugu gibi yaziyor ("%60 Tiny  %20 Large  %20 Huge"), cekilis
	de ayni tabloyu kullaniyor -- yani oyuncunun gordugu oran gercek oran.
]]
function Fuse.sizeChances(entries: { any }): { SizeChance }
	local total = #entries
	if total == 0 then
		return {}
	end

	local counts: { [string]: number } = {}
	for _, entry in entries do
		local id = Condition.get(entry.condition).id
		counts[id] = (counts[id] or 0) + 1
	end

	local out: { SizeChance } = {}
	for _, id in Condition.Order do
		local count = counts[id]
		if count then
			table.insert(out, {
				id = id,
				count = count,
				chance = count / total * 100,
			})
		end
	end

	return out
end

--[[
	MUTASYON AKTARIMI

	Makineye konan HER esya, kendi mutasyonunu cikan coine gecirme sansi
	tasir. Sans esya basina chancePerItem kadardir ve ayni mutasyondan
	birden fazla esya varsa TOPLANIR:

	    2 Gold + 1 Diamond + 2 mutasyonsuz
	        ->  %20 Gold,  %10 Diamond,  %70 mutasyonsuz

	Mutasyonsuz esyalar hicbir sey katmaz. En fazla Fuse.Required esya
	konabildigi icin toplam sans %50'yi gecemez.

	Coin de mutasyon tasir: Gold bir coin makineye konursa o da Gold katar.

	Cekilis TEK SEFERDIR -- coin ya bir mutasyon alir ya da hic almaz,
	ikisi birden olmaz.
]]
Fuse.Mutation = {
	chancePerItem = 10,
}

export type MutationChance = {
	id: string,
	count: number,
	chance: number,
}

--[[
	Iceri konanlarin MUTASYON DAGILIMI.

	entries: { { mutation = "Gold" }, ... }
	Donen: Mutations.Order sirasinda, yalnizca iceride BULUNAN mutasyonlar.

	Arayuz bunu oldugu gibi yaziyor, cekilis de ayni tabloyu kullaniyor --
	yani oyuncunun gordugu oran gercek oran.
]]
function Fuse.mutationChances(entries: { any }): { MutationChance }
	local counts: { [string]: number } = {}

	for _, entry in entries do
		local info = Mutations.get(entry.mutation)
		if info.id ~= Mutations.Default then
			counts[info.id] = (counts[info.id] or 0) + 1
		end
	end

	local out: { MutationChance } = {}
	for _, id in Mutations.Order do
		local count = counts[id]
		if count then
			table.insert(out, {
				id = id,
				count = count,
				chance = count * Fuse.Mutation.chancePerItem,
			})
		end
	end

	return out
end

--[[
	Cikacak coinin mutasyonu.

	Siralanan sanslar toplanir; cekilen sayi hangi araliga duserse o
	mutasyon kazanir. Hicbirine dusmezse coin mutasyonsuz cikar.
]]
function Fuse.rollMutation(entries: { any }, rng: Random): string
	local roll = rng:NextNumber() * 100
	local cursor = 0

	for _, entry in Fuse.mutationChances(entries) do
		cursor += entry.chance
		if roll <= cursor then
			return entry.id
		end
	end

	return Mutations.Default
end

--[[
	Cikacak coinin boyutunu ceker.

	Cekilis dogrudan esya listesinden yapiliyor: rastgele bir esya secilip
	onun boyutu aliniyor. Bu, sizeChances'in verdigi oranin tam karsiligi --
	iki yer ayri ayri hesaplasaydi ekranda yazan oranla gercek oran zamanla
	ayrisabilirdi.
]]
function Fuse.rollSize(entries: { any }, rng: Random): string
	if #entries == 0 then
		return Condition.Default
	end

	local picked = entries[rng:NextInteger(1, #entries)]
	return Condition.get(picked.condition).id
end

--[[
	Makinenin onunde yazan yonerge.
	Oyuncu ne yapmasi gerektigini panele bakarak anlasin diye.
]]
function Fuse.headline(rarityId: string?, count: number): string
	if not rarityId then
		return `Same Rarity Brainrot  {count}/{Fuse.Required}`
	end
	return `{Rarity.displayName(rarityId)} Brainrot  {count}/{Fuse.Required}`
end

return Fuse
