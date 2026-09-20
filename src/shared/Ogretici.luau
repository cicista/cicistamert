--!strict
--[[
	OGRETICI  --  yeni oyuncunun ilk turu

	Oyuna ilk giren oyuncuyu oyunun dongusunde bir kez elinden tutup
	gezdirir: kaz -> kimligini ac -> base'e koy -> parayi topla -> uc tane
	ayni kademe kaz -> birlestir.

	BURASI YALNIZCA TANIM. Adimlarin sirasi, oyuncuya gosterilen yazi ve
	hangi hedefin isaretlenecegi burada; ilerletme sunucuda
	(ServerScriptService > Modules > Ogretici), isaretleme ve oklar
	istemcide (StarterPlayerScripts > Ogretici).

	NEDEN ORTAK MODUL
	Sunucu "kacinci adimdayiz"i, istemci "bu adimda neyi isaretleyecegim"i
	bilmek zorunda. Ikisi ayni listeden okursa bir adim eklemek tek yerde
	kaliyor.

	YENI ADIM EKLEMEK
	Listeye bir satir yaz ve `olay` alanina sunucunun hangi olayda
	ilerleyecegini koy. Sunucudaki Ogretici.olay(player, "<olay>") cagrisi
	o adimi bitirir; hangi kancadan cagrilacagi o sistemin kendi dosyasinda.
]]

local Ogretici = {}

--[[
	ISARETLENECEK HEDEF TURU

	Istemci bunu Workspace'te arar:
	  kum       -> oyuncuya en yakin kum zemini (Config.Sand'e gore)
	  dedektif  -> Config.Detective.name adli model
	  base      -> oyuncunun kendi base'i (Bases.CollectMarkerName'li pad)
	  fuse      -> Config.Fuse.machineName adli model
]]
export type Hedef = "kum" | "dedektif" | "base" | "fuse"

export type Adim = {
	-- Kayitta ve kancalarda kullanilan kimlik
	id: string,
	-- Sunucuyu bu adimdan sonraki adima gecirecek olayin adi
	olay: string,
	hedef: Hedef,
	-- Oyuncunun ekraninda duran yonerge
	yazi: string,
	--[[
		Adimin altinda duran kucuk aciklama. Oyuncu "neden" bunu yaptigini
		bilsin diye; bos birakilirsa yalnizca yonerge gosterilir.
	]]
	alt: string?,
}

--[[
	ADIMLAR  --  sirayla

	UC TANE AYNI KADEME (ucKazi) kullanicinin envanterinden sayiliyor, tek
	tek kazilardan degil: oyuncu arada baska kademe kazsa da, elinde ayni
	kademeden uc tane biriktigi an adim biter.
]]
-- Tip, tablonun sonundaki `:: { Adim }` ile veriliyor: Luau alan
-- bildiriminde `Ad.alan: Tip =` sozdizimini kabul etmiyor.
Ogretici.Adimlar = {
	{
		id = "ilkKazi",
		olay = "kazdi",
		hedef = "kum",
		yazi = "Dig in the sand!",
		alt = "Beams are buried under the sand.",
	},
	{
		id = "ilkCollect",
		olay = "collectledi",
		hedef = "dedektif",
		yazi = "Take it to the Detective!",
		alt = "He reveals what you dug up.",
	},
	{
		id = "slot",
		olay = "slotladi",
		hedef = "base",
		yazi = "Place it in a base slot!",
		alt = "Brainrots earn cash while placed.",
	},
	{
		id = "para",
		olay = "parayiAldi",
		hedef = "base",
		yazi = "Collect your cash!",
		alt = "Step on the pad at your base.",
	},
	{
		id = "ucKazi",
		olay = "ucKazdi",
		hedef = "kum",
		yazi = "Dig 3 beams of the same rarity!",
		alt = "Same rarity, any island.",
	},
	{
		id = "ucCollect",
		olay = "ucCollectledi",
		hedef = "dedektif",
		yazi = "Reveal all 3 at the Detective!",
		alt = "The Fuse Machine only takes revealed ones.",
	},
	{
		id = "fuse",
		olay = "fuseYapti",
		hedef = "fuse",
		yazi = "Fuse them at the Fuse Machine!",
		alt = "3 of a kind can become something better.",
	},
} :: { Adim }

-- Her adim bitince verilen odul
Ogretici.RotCoinOdulu = 1

--[[
	Adim bitis patlamasinin rengi.

	Kademe renklerinden biri DEGIL: odul kademeye bagli olmadigi icin
	beyaz kaliyor, oyuncu "bu ogretici odulu" diye ayirt ediyor.
]]
Ogretici.PatlamaRengi = Color3.fromRGB(255, 255, 255)

--[[
	Patlamanin buyuklugu icin kullanilan kademe. Patlama.oynat olcegi
	kademeden okuyor; renk zaten ustte eziliyor, buradaki tek is boyut.
]]
Ogretici.PatlamaOlcegi = "Epic"

-- Isaretlenen hedefin etrafindaki parlama ve oklarin rengi
Ogretici.IsaretRengi = Color3.fromRGB(255, 215, 60)

function Ogretici.adimSayisi(): number
	return #Ogretici.Adimlar
end

-- 1'den baslayan sira numarasiyla adim; sira disindaysa nil
function Ogretici.adim(sira: number): Adim?
	return Ogretici.Adimlar[sira]
end

-- Bir olay hangi siradaki adimi bitiriyor; eslesmezse nil
function Ogretici.siraOf(olay: string): number?
	for sira, adim in Ogretici.Adimlar do
		if adim.olay == olay then
			return sira
		end
	end
	return nil
end

return Ogretici
