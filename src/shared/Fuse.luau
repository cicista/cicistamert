--!strict
--[[
	FUSE  --  brainrot birlestirme

	FUSE MAKINESI
	  AYNI KADEMEDEN 3 brainrot alir (isimleri farkli olabilir, kimligi
	  acilmis). Ayni isimler sansi artirir (bkz. Fuse.Chances). Oyuncu
	  "FUSE"a basinca birlestirme yapilir:

	    sans ihtimalle            -> BIR UST kademeden acilmis bir brainrot
	    kalan ihtimalle           -> HICBIR SEY; konan 3 brainrot gider

	MAKINE KURALLARI
	  - Icine konan butun brainrotlar AYNI KADEMEDE olmali; isimler farkli
	    olabilir, ayni isim sayisi arttikca sans artar.
	  - Kimligi acilmamis (siyah) brainrot konamaz: adi bilinmiyor.
	  - Base slotundaki brainrot konamaz.
	  - Makine Abyssal'i HIC GORMEZ: Abyssal konamaz ve uretilemez. Bu
	    yuzden Infernal da birlestirilemez (ustu Abyssal). Divine, Cosmic,
	    Secret birlestirilebilir (bkz. Fuse.Excluded).
	  - Ust kademede oyuncunun ulastigi adada hic brainrot yoksa konamaz
	    (yoksa sonraki adalarin brainrotu erken alinirdi).
	  - Kazanilan brainrotun BOYUTU konanlardan birinin boyutudur (rastgele),
	    MUTASYONU da konanlardan aktarilabilir (bkz. Fuse.Mutation).
	  - Konan brainrotlar envanterden CIKAR ama kaybolmaz: FUSE'a basilmadan
	    Fuse.Timeout saniye islem yapilmazsa hepsi geri verilir. Her slotun
	    "Return" dugmesi de tek tek geri alir.

	(Coin sistemi ve Coin Trader oyundan kaldirildi.)
]]

local Condition = require(script.Parent.Condition)
local Mutations = require(script.Parent.Mutations)
local Rarity = require(script.Parent.Rarity)

local Fuse = {}

-- Makineye kac ayni brainrot konur
Fuse.Required = 3

--[[
	BASARI SANSI (yuzde)  --  makineye konan brainrotlarin ISIMLERINE gore

	Ayni kademeden FARKLI isimli brainrotlar da konabilir; ayni isim ne kadar
	coksa sans o kadar yuksek:
	    3'u ayni isim   -> same3
	    2'si ayni isim  -> same2
	    hepsi farkli    -> mixed
	Tutmazsa hicbir sey cikmaz.
]]
Fuse.Chances = {
	same3 = 25,
	same2 = 20,
	mixed = 15,
}

-- En yuksek sans (arayuzde "en fazla" olarak yazar)
Fuse.SuccessChance = Fuse.Chances.same3

-- Makinede kac saniye islem yapilmazsa icindekiler geri verilir
Fuse.Timeout = 60

--[[
	BIRLESME GOSTERISI

	    gather -> konan brainrotlarin renginde RUHLAR ekranda bir cember
	              olusturur, donerek merkeze dogru kapanir
	    flash  -> merkezde birlesip parlar
	    burst  -> BASARIDA yeni kademenin renginde sok dalgasi ve yildizlar;
	              BASARISIZLIKTA cekirdek sonup kaybolur
	    hold   -> sonuc okunacak kadar ekranda kalir

	Brainrot VERIYE hemen yazilir (gosteri sirasinda oyuncu cikarsa
	kaybolmasin) ama cantaya ancak gosteri bitince yansitilir. Sureler
	burada: sunucu da istemci de ayni kaynagi okur.
]]
Fuse.Merge = {
	gatherTime = 1.4,
	flashTime = 0.35,
	burstTime = 1.1,
	holdTime = 1.1,

	-- Patlama anindaki ekran sarsintisi
	shakeTime = 0.65,
	-- Sarsintinin siddeti (stud). Buyutursen kamera daha cok savrulur.
	shakeStrength = 2.6,
}

function Fuse.mergeTime(): number
	local M = Fuse.Merge
	return M.gatherTime + M.flashTime + M.burstTime + M.holdTime
end

-- Patlama ani: gosteri baslangicindan kac saniye sonra (VFX ve sarsinti buna kilitli)
function Fuse.burstDelay(): number
	return Fuse.Merge.gatherTime + Fuse.Merge.flashTime
end

--[[
	PATLAMA EFEKTI (VFX)

	Workspace'te -- ya da ReplicatedStorage > Assets > VFX icinde -- bu
	isimde bir Part aranir. Rengi kazanilan brainrotun kademesine cevrilir,
	patlama birlestiren oyuncunun karakterinde olur. Yalnizca BASARIDA oynar.

	Efekt bulunamazsa gosteri VFX'siz oynar; Output'a bir kez uyari duser.
]]
Fuse.VFX = {
	name = "FuseVFX",
	height = 3,
	lifetime = 3,
	burst = 60,
	stopAfter = 0.6,
	-- Kademeye gore patlama capi; yazilmayan kademe 1 sayilir
	scaleByRarity = {
		Secret = 1.6,
	},

	--[[
		SESLER (Workspace ya da Assets > Sounds icindeki Sound adlari)
		charge    -> ruhlar toplanmaya baslarken
		explosion -> basari patlamasi aninda
	]]
	charge = { "FuseCharge", "FuseCarge" },
	explosion = { "FuseExplosion" },
	-- true: parcaciklarin parlaklik yapisi korunur, yalnizca renk tonu degisir
	preserveShading = true,
}

--[[
	MAKINENIN GORMEDIGI KADEMELER

	Bunlar makineye konamaz, makineden de cikamaz; secim listesinde de hic
	gorunmez. Abyssal yalnizca denizden gelir.
]]
Fuse.Excluded = {
	Abyssal = true,
} :: { [string]: boolean }

-- Makine bu kademeyi gorur mu (listede cikar mi)
function Fuse.sees(rarityId: string?): boolean
	return type(rarityId) == "string" and Rarity.Info[rarityId :: Rarity.RarityId] ~= nil and not Fuse.Excluded[rarityId]
end

-- Bir kademenin BIR USTU. En ust kademede ya da ustu makinenin gormedigi bir kademeyse nil.
function Fuse.nextRarity(rarityId: string): string?
	local info = Rarity.Info[rarityId :: Rarity.RarityId]
	if not info then
		return nil
	end

	for _, id in Rarity.Order do
		if Rarity.Info[id].order == info.order + 1 then
			if Fuse.Excluded[id] then
				return nil
			end
			return id
		end
	end

	return nil
end

export type SizeChance = {
	id: string,
	count: number,
	chance: number,
}

-- Konanlarin BOYUT DAGILIMI (Condition.Order sirasinda, yalnizca bulunanlar)
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
			table.insert(out, { id = id, count = count, chance = count / total * 100 })
		end
	end

	return out
end

--[[
	MUTASYON AKTARIMI

	Konan HER mutasyonlu brainrot, kendi mutasyonunu kazanilan brainrota
	gecirme sansi tasir (esya basina chancePerItem). Ayni mutasyondan birden
	fazla varsa TOPLANIR. Cekilis tek seferdir.
]]
Fuse.Mutation = {
	chancePerItem = 10,
}

export type MutationChance = {
	id: string,
	count: number,
	chance: number,
}

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
			table.insert(out, { id = id, count = count, chance = count * Fuse.Mutation.chancePerItem })
		end
	end

	return out
end

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

-- Kazanilan brainrotun boyutu: konanlardan rastgele birinin boyutu
function Fuse.rollSize(entries: { any }, rng: Random): string
	if #entries == 0 then
		return Condition.Default
	end

	local picked = entries[rng:NextInteger(1, #entries)]
	return Condition.get(picked.condition).id
end

-- Makinedekilerin sansi: en cok tekrar eden isim sayisina gore (bkz. Fuse.Chances)
function Fuse.chanceFor(entries: { any }): number
	local sayac: { [string]: number } = {}
	local enCok = 0
	for _, entry in entries do
		local ad = entry.name or (entry.item and entry.item.name)
		if type(ad) == "string" then
			sayac[ad] = (sayac[ad] or 0) + 1
			enCok = math.max(enCok, sayac[ad])
		end
	end

	if enCok >= 3 then
		return Fuse.Chances.same3
	elseif enCok == 2 then
		return Fuse.Chances.same2
	end
	return Fuse.Chances.mixed
end

-- Birlestirme tuttu mu (sans verilmezse en yuksek sans)
function Fuse.rollSuccess(rng: Random, chance: number?): boolean
	return rng:NextNumber() * 100 < (chance or Fuse.SuccessChance)
end

return Fuse
