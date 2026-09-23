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
		Seridin solunda duran ANLATICI resmi (bkz. Ogretici.Anlaticilar).
		Bos birakilirsa "tesvik" kullanilir.
	]]
	resim: string?,
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
		resim = "hosgeldin",
		yazi = "Dig the glowing beam!",
		alt = "It is right next to you -- click it, then click fast!",
	},
	{
		id = "ilkCollect",
		olay = "collectledi",
		hedef = "dedektif",
		resim = "dusunce",
		yazi = "Take it to the Detective!",
		alt = "He reveals what you dug up.",
	},
	{
		id = "slot",
		olay = "slotladi",
		hedef = "base",
		resim = "tesvik",
		yazi = "Place it in a base slot!",
		alt = "Brainrots earn cash while placed.",
	},
	{
		id = "para",
		olay = "parayiAldi",
		hedef = "base",
		resim = "dans",
		yazi = "Collect your cash!",
		alt = "Step on the pad at your base.",
	},
	{
		id = "ucKazi",
		olay = "ucKazdi",
		hedef = "kum",
		resim = "tesvik",
		yazi = "Dig the 3 beams!",
		alt = "They are lined up next to you.",
	},
	{
		id = "ucCollect",
		olay = "ucCollectledi",
		hedef = "dedektif",
		resim = "dusunce",
		yazi = "Reveal all 3 at the Detective!",
		alt = "Hand in all three, then collect them.",
	},
	{
		id = "fuse",
		olay = "fuseYapti",
		hedef = "fuse",
		resim = "dans",
		yazi = "Fuse them at the Fuse Machine!",
		alt = "3 of a kind can become something better.",
	},
} :: { Adim }

--[[
	ILK KAZI  --  yeni oyuncu sansa birakilmaz

	Ogreticinin ILK adiminda (ilkKazi) oyuncunun yaninda GARANTI bir
	suzme dogar; kademesi hep ayni (IlkKademe), yani ilk kazi her zaman
	en kolay olani. Cekilis yok, bekleme yok: adimi attigi anda yanindadir
	(bkz. ServerScriptService > KaziSistemi).

	Minioyunda da KAYBETMEZ: imlec dibe inerse sifirlanmak yerine az bir
	degerde tutulur (bkz. StarterPlayerScripts > Minigame). Oyuncu geri
	gitmeyi gorur, ogrenir; ama ilk denemesinde brainrotu kacirmaz.
]]
--[[
	ANLATICI RESIMLERI

	Solda, adimin havasina uyan bir karakter resmi duruyor. Resimler
	Studio'ya elle konuyor: ReplicatedStorage > Assets > Icons icine
	asagidaki adlardan BIRIYLE (Decal, ImageLabel ya da StringValue).
	Buyuk/kucuk harf, bosluk ve alt cizgi farki onemsiz; Turkce karakterli
	ad da kabul ediliyor ("dusunce" ya da "düşünce").

	Hicbiri bulunamazsa serit resimsiz gorunur ve Output'a hangi adlarin
	arandigi bir kez yazilir.
]]
Ogretici.Anlaticilar = {
	hosgeldin = { "hosgeldin", "hoşgeldin", "welcome" },
	dusunce = { "dusunce", "düşünce", "thinking" },
	tesvik = { "tesvik", "teşvik", "encourage" },
	dans = { "dans", "dance" },
} :: { [string]: { string } }

--[[
	ADA IPUCU  --  ogreticiden SONRAKI tek yonlendirme

	Oyuncunun parasi ikinci adaya (Candy Island) yetince ekranda bir serit
	belirir ve Teleporter isaretlenir; isinlayici menusunde o adanin satiri
	KIRMIZI yanar. Oyuncu adayi acip oraya gidince "burada daha guclu
	brainrotlar var" denir ve ipucu bir daha gorunmez.

	Gereken para Config.Islands[ada].price'tan okunur; burada yazili degil.
]]
Ogretici.AdaIpucu = {
	-- Kacinci ada (Config.Islands sirasi)
	ada = 2,
	-- Oyuncu niteligi: istemciler bu ipucunun acik olup olmadigini buradan okur
	nitelik = "IpucuAda",
	yazi = "You can afford a new island!",
	alt = "Open the Teleporter and pick the red island.",
	resim = "tesvik",
	-- Adaya varinca gosterilen bildirim
	varis = "Stronger brainrots live here -- dig this sand for better rot!",
	renk = Color3.fromRGB(255, 60, 60),
}

--[[
	ILK KUREK IPUCU  --  ogreticiden sonraki ikinci yonlendirme

	Baslangic kuregi yavas; oyunun asil hizi ikinci kurekle geliyor. Oyuncu
	onun parasina ulasinca ekranda serit belirir ve KUREK MAGAZASI
	isaretlenir. Kuregi alinca ipucu kapanir ve bir daha gosterilmez.

	Fiyat burada YAZILI DEGIL: Shovels.Info[kurek].price'tan okunuyor, yani
	kuregin fiyatini degistirmek yeter.
]]
Ogretici.KurekIpucu = {
	-- Hangi kurek (bkz. Shared > Shovels)
	kurek = "Iron",
	-- Oyuncu niteligi: istemci ipucunun acik olup olmadigini buradan okur
	nitelik = "IpucuKurek",
	yazi = "You can afford your first shovel!",
	alt = "Open the Shovel Shop and buy it -- digging gets much faster.",
	resim = "tesvik",
	-- Kurek alininca cikan bildirim
	varis = "Nice shovel! Beams come out way faster now.",
	renk = Color3.fromRGB(255, 200, 60),
	--[[
		Isaretlenecek modelin Workspace'teki adlari. Magaza betigi de ayni
		listeyi kullaniyor (bkz. ServerScriptService > Magaza > MAGAZA_ADLARI).
	]]
	modeller = { "Shop", "Shopkeeper", "ShovelShop", "Magaza", "KurekMagazasi" },
}

--[[
	ILK KUREK IPUCU  --  ogreticiden sonraki ikinci yonlendirme

	Baslangic kuregi yavas; oyunun asil hizi ikinci kurekle geliyor. Oyuncu
	onun parasina ulasinca ekranda serit belirir ve KUREK MAGAZASI
	isaretlenir. Kuregi alinca ipucu kapanir ve bir daha gosterilmez.

	Fiyat burada YAZILI DEGIL: Shovels.Info[kurek].price'tan okunuyor, yani
	kuregin fiyatini degistirmek yeter.
]]
Ogretici.KurekIpucu = {
	-- Hangi kurek (bkz. Shared > Shovels)
	kurek = "Iron",
	-- Oyuncu niteligi: istemci ipucunun acik olup olmadigini buradan okur
	nitelik = "IpucuKurek",
	yazi = "You can afford your first shovel!",
	alt = "Open the Shovel Shop and buy it -- digging gets much faster.",
	resim = "tesvik",
	-- Kurek alininca cikan bildirim
	varis = "Nice shovel! Beams come out way faster now.",
	renk = Color3.fromRGB(255, 200, 60),
	--[[
		Isaretlenecek modelin Workspace'teki adlari. Magaza betigi de ayni
		listeyi kullaniyor (bkz. ServerScriptService > Magaza > MAGAZA_ADLARI).
	]]
	modeller = { "Shop", "Shopkeeper", "ShovelShop", "Magaza", "KurekMagazasi" },
}

--[[
	ILK KUREK IPUCU  --  ogreticiden sonraki ikinci yonlendirme

	Baslangic kuregi yavas; oyunun asil hizi ikinci kurekle geliyor. Oyuncu
	onun parasina ulasinca ekranda serit belirir ve KUREK MAGAZASI
	isaretlenir. Kuregi alinca ipucu kapanir ve bir daha gosterilmez.

	Fiyat burada YAZILI DEGIL: Shovels.Info[kurek].price'tan okunuyor, yani
	kuregin fiyatini degistirmek yeter.
]]
Ogretici.KurekIpucu = {
	-- Hangi kurek (bkz. Shared > Shovels)
	kurek = "Iron",
	-- Oyuncu niteligi: istemci ipucunun acik olup olmadigini buradan okur
	nitelik = "IpucuKurek",
	yazi = "You can afford your first shovel!",
	alt = "Open the Shovel Shop and buy it -- digging gets much faster.",
	resim = "tesvik",
	-- Kurek alininca cikan bildirim
	varis = "Nice shovel! Beams come out way faster now.",
	renk = Color3.fromRGB(255, 200, 60),
	--[[
		Isaretlenecek modelin Workspace'teki adlari. Magaza betigi de ayni
		listeyi kullaniyor (bkz. ServerScriptService > Magaza > MAGAZA_ADLARI).
	]]
	modeller = { "Shop", "Shopkeeper", "ShovelShop", "Magaza", "KurekMagazasi" },
}

--[[
	ILK KUREK IPUCU  --  ogreticiden sonraki ikinci yonlendirme

	Baslangic kuregi yavas; oyunun asil hizi ikinci kurekle geliyor. Oyuncu
	onun parasina ulasinca ekranda serit belirir ve KUREK MAGAZASI
	isaretlenir. Kuregi alinca ipucu kapanir ve bir daha gosterilmez.

	Fiyat burada YAZILI DEGIL: Shovels.Info[kurek].price'tan okunuyor, yani
	kuregin fiyatini degistirmek yeter.
]]
Ogretici.KurekIpucu = {
	-- Hangi kurek (bkz. Shared > Shovels)
	kurek = "Iron",
	-- Oyuncu niteligi: istemci ipucunun acik olup olmadigini buradan okur
	nitelik = "IpucuKurek",
	yazi = "You can afford your first shovel!",
	alt = "Open the Shovel Shop and buy it -- digging gets much faster.",
	resim = "tesvik",
	-- Kurek alininca cikan bildirim
	varis = "Nice shovel! Beams come out way faster now.",
	renk = Color3.fromRGB(255, 200, 60),
	--[[
		Isaretlenecek modelin Workspace'teki adlari. Magaza betigi de ayni
		listeyi kullaniyor (bkz. ServerScriptService > Magaza > MAGAZA_ADLARI).
	]]
	modeller = { "Shop", "Shopkeeper", "ShovelShop", "Magaza", "KurekMagazasi" },
}

--[[
	ILK KUREK IPUCU  --  ogreticiden sonraki ikinci yonlendirme

	Baslangic kuregi yavas; oyunun asil hizi ikinci kurekle geliyor. Oyuncu
	onun parasina ulasinca ekranda serit belirir ve KUREK MAGAZASI
	isaretlenir. Kuregi alinca ipucu kapanir ve bir daha gosterilmez.

	Fiyat burada YAZILI DEGIL: Shovels.Info[kurek].price'tan okunuyor, yani
	kuregin fiyatini degistirmek yeter.
]]
Ogretici.KurekIpucu = {
	-- Hangi kurek (bkz. Shared > Shovels)
	kurek = "Iron",
	-- Oyuncu niteligi: istemci ipucunun acik olup olmadigini buradan okur
	nitelik = "IpucuKurek",
	yazi = "You can afford your first shovel!",
	alt = "Open the Shovel Shop and buy it -- digging gets much faster.",
	resim = "tesvik",
	-- Kurek alininca cikan bildirim
	varis = "Nice shovel! Beams come out way faster now.",
	renk = Color3.fromRGB(255, 200, 60),
	--[[
		Isaretlenecek modelin Workspace'teki adlari. Magaza betigi de ayni
		listeyi kullaniyor (bkz. ServerScriptService > Magaza > MAGAZA_ADLARI).
	]]
	modeller = { "Shop", "Shopkeeper", "ShovelShop", "Magaza", "KurekMagazasi" },
}

--[[
	ILK KUREK IPUCU  --  ogreticiden sonraki ikinci yonlendirme

	Baslangic kuregi yavas; oyunun asil hizi ikinci kurekle geliyor. Oyuncu
	onun parasina ulasinca ekranda serit belirir ve KUREK MAGAZASI
	isaretlenir. Kuregi alinca ipucu kapanir ve bir daha gosterilmez.

	Fiyat burada YAZILI DEGIL: Shovels.Info[kurek].price'tan okunuyor, yani
	kuregin fiyatini degistirmek yeter.
]]
Ogretici.KurekIpucu = {
	-- Hangi kurek (bkz. Shared > Shovels)
	kurek = "Iron",
	-- Oyuncu niteligi: istemci ipucunun acik olup olmadigini buradan okur
	nitelik = "IpucuKurek",
	yazi = "You can afford your first shovel!",
	alt = "Open the Shovel Shop and buy it -- digging gets much faster.",
	resim = "tesvik",
	-- Kurek alininca cikan bildirim
	varis = "Nice shovel! Beams come out way faster now.",
	renk = Color3.fromRGB(255, 200, 60),
	--[[
		Isaretlenecek modelin Workspace'teki adlari. Magaza betigi de ayni
		listeyi kullaniyor (bkz. ServerScriptService > Magaza > MAGAZA_ADLARI).
	]]
	modeller = { "Shop", "Shopkeeper", "ShovelShop", "Magaza", "KurekMagazasi" },
}

--[[
	ILK KUREK IPUCU  --  ogreticiden sonraki ikinci yonlendirme

	Baslangic kuregi yavas; oyunun asil hizi ikinci kurekle geliyor. Oyuncu
	onun parasina ulasinca ekranda serit belirir ve KUREK MAGAZASI
	isaretlenir. Kuregi alinca ipucu kapanir ve bir daha gosterilmez.

	Fiyat burada YAZILI DEGIL: Shovels.Info[kurek].price'tan okunuyor, yani
	kuregin fiyatini degistirmek yeter.
]]
Ogretici.KurekIpucu = {
	-- Hangi kurek (bkz. Shared > Shovels)
	kurek = "Iron",
	-- Oyuncu niteligi: istemci ipucunun acik olup olmadigini buradan okur
	nitelik = "IpucuKurek",
	yazi = "You can afford your first shovel!",
	alt = "Open the Shovel Shop and buy it -- digging gets much faster.",
	resim = "tesvik",
	-- Kurek alininca cikan bildirim
	varis = "Nice shovel! Beams come out way faster now.",
	renk = Color3.fromRGB(255, 200, 60),
	--[[
		Isaretlenecek modelin Workspace'teki adlari. Magaza betigi de ayni
		listeyi kullaniyor (bkz. ServerScriptService > Magaza > MAGAZA_ADLARI).
	]]
	modeller = { "Shop", "Shopkeeper", "ShovelShop", "Magaza", "KurekMagazasi" },
}

--[[
	ILK KUREK IPUCU  --  ogreticiden sonraki ikinci yonlendirme

	Baslangic kuregi yavas; oyunun asil hizi ikinci kurekle geliyor. Oyuncu
	onun parasina ulasinca ekranda serit belirir ve KUREK MAGAZASI
	isaretlenir. Kuregi alinca ipucu kapanir ve bir daha gosterilmez.

	Fiyat burada YAZILI DEGIL: Shovels.Info[kurek].price'tan okunuyor, yani
	kuregin fiyatini degistirmek yeter.
]]
Ogretici.KurekIpucu = {
	-- Hangi kurek (bkz. Shared > Shovels)
	kurek = "Iron",
	-- Oyuncu niteligi: istemci ipucunun acik olup olmadigini buradan okur
	nitelik = "IpucuKurek",
	yazi = "You can afford your first shovel!",
	alt = "Open the Shovel Shop and buy it -- digging gets much faster.",
	resim = "tesvik",
	-- Kurek alininca cikan bildirim
	varis = "Nice shovel! Beams come out way faster now.",
	renk = Color3.fromRGB(255, 200, 60),
	--[[
		Isaretlenecek modelin Workspace'teki adlari. Magaza betigi de ayni
		listeyi kullaniyor (bkz. ServerScriptService > Magaza > MAGAZA_ADLARI).
	]]
	modeller = { "Shop", "Shopkeeper", "ShovelShop", "Magaza", "KurekMagazasi" },
}

--[[
	ILK KUREK IPUCU  --  ogreticiden sonraki ikinci yonlendirme

	Baslangic kuregi yavas; oyunun asil hizi ikinci kurekle geliyor. Oyuncu
	onun parasina ulasinca ekranda serit belirir ve KUREK MAGAZASI
	isaretlenir. Kuregi alinca ipucu kapanir ve bir daha gosterilmez.

	Fiyat burada YAZILI DEGIL: Shovels.Info[kurek].price'tan okunuyor, yani
	kuregin fiyatini degistirmek yeter.
]]
Ogretici.KurekIpucu = {
	-- Hangi kurek (bkz. Shared > Shovels)
	kurek = "Iron",
	-- Oyuncu niteligi: istemci ipucunun acik olup olmadigini buradan okur
	nitelik = "IpucuKurek",
	yazi = "You can afford your first shovel!",
	alt = "Open the Shovel Shop and buy it -- digging gets much faster.",
	resim = "tesvik",
	-- Kurek alininca cikan bildirim
	varis = "Nice shovel! Beams come out way faster now.",
	renk = Color3.fromRGB(255, 200, 60),
	--[[
		Isaretlenecek modelin Workspace'teki adlari. Magaza betigi de ayni
		listeyi kullaniyor (bkz. ServerScriptService > Magaza > MAGAZA_ADLARI).
	]]
	modeller = { "Shop", "Shopkeeper", "ShovelShop", "Magaza", "KurekMagazasi" },
}

--[[
	ILK KUREK IPUCU  --  ogreticiden sonraki ikinci yonlendirme

	Baslangic kuregi yavas; oyunun asil hizi ikinci kurekle geliyor. Oyuncu
	onun parasina ulasinca ekranda serit belirir ve KUREK MAGAZASI
	isaretlenir. Kuregi alinca ipucu kapanir ve bir daha gosterilmez.

	Fiyat burada YAZILI DEGIL: Shovels.Info[kurek].price'tan okunuyor, yani
	kuregin fiyatini degistirmek yeter.
]]
Ogretici.KurekIpucu = {
	-- Hangi kurek (bkz. Shared > Shovels)
	kurek = "Iron",
	-- Oyuncu niteligi: istemci ipucunun acik olup olmadigini buradan okur
	nitelik = "IpucuKurek",
	yazi = "You can afford your first shovel!",
	alt = "Open the Shovel Shop and buy it -- digging gets much faster.",
	resim = "tesvik",
	-- Kurek alininca cikan bildirim
	varis = "Nice shovel! Beams come out way faster now.",
	renk = Color3.fromRGB(255, 200, 60),
	--[[
		Isaretlenecek modelin Workspace'teki adlari. Magaza betigi de ayni
		listeyi kullaniyor (bkz. ServerScriptService > Magaza > MAGAZA_ADLARI).
	]]
	modeller = { "Shop", "Shopkeeper", "ShovelShop", "Magaza", "KurekMagazasi" },
}

--[[
	ILK KUREK IPUCU  --  ogreticiden sonraki ikinci yonlendirme

	Baslangic kuregi yavas; oyunun asil hizi ikinci kurekle geliyor. Oyuncu
	onun parasina ulasinca ekranda serit belirir ve KUREK MAGAZASI
	isaretlenir. Kuregi alinca ipucu kapanir ve bir daha gosterilmez.

	Fiyat burada YAZILI DEGIL: Shovels.Info[kurek].price'tan okunuyor, yani
	kuregin fiyatini degistirmek yeter.
]]
Ogretici.KurekIpucu = {
	-- Hangi kurek (bkz. Shared > Shovels)
	kurek = "Iron",
	-- Oyuncu niteligi: istemci ipucunun acik olup olmadigini buradan okur
	nitelik = "IpucuKurek",
	yazi = "You can afford your first shovel!",
	alt = "Open the Shovel Shop and buy it -- digging gets much faster.",
	resim = "tesvik",
	-- Kurek alininca cikan bildirim
	varis = "Nice shovel! Beams come out way faster now.",
	renk = Color3.fromRGB(255, 200, 60),
	--[[
		Isaretlenecek modelin Workspace'teki adlari. Magaza betigi de ayni
		listeyi kullaniyor (bkz. ServerScriptService > Magaza > MAGAZA_ADLARI).
	]]
	modeller = { "Shop", "Shopkeeper", "ShovelShop", "Magaza", "KurekMagazasi" },
}

--[[
	ILK KUREK IPUCU  --  ogreticiden sonraki ikinci yonlendirme

	Baslangic kuregi yavas; oyunun asil hizi ikinci kurekle geliyor. Oyuncu
	onun parasina ulasinca ekranda serit belirir ve KUREK MAGAZASI
	isaretlenir. Kuregi alinca ipucu kapanir ve bir daha gosterilmez.

	Fiyat burada YAZILI DEGIL: Shovels.Info[kurek].price'tan okunuyor, yani
	kuregin fiyatini degistirmek yeter.
]]
Ogretici.KurekIpucu = {
	-- Hangi kurek (bkz. Shared > Shovels)
	kurek = "Iron",
	-- Oyuncu niteligi: istemci ipucunun acik olup olmadigini buradan okur
	nitelik = "IpucuKurek",
	yazi = "You can afford your first shovel!",
	alt = "Open the Shovel Shop and buy it -- digging gets much faster.",
	resim = "tesvik",
	-- Kurek alininca cikan bildirim
	varis = "Nice shovel! Beams come out way faster now.",
	renk = Color3.fromRGB(255, 200, 60),
	--[[
		Isaretlenecek modelin Workspace'teki adlari. Magaza betigi de ayni
		listeyi kullaniyor (bkz. ServerScriptService > Magaza > MAGAZA_ADLARI).
	]]
	modeller = { "Shop", "Shopkeeper", "ShovelShop", "Magaza", "KurekMagazasi" },
}

Ogretici.IlkKademe = "Common"

--[[
	"Uc tane kaz" adiminda kac suzme dogar ve kac tanesi istenir. Suzmeler
	yan yana dizilir ve hepsi IlkKademe'dendir; oyuncu sansa birakilmadan
	ucunu de toplar (bkz. KaziSistemi > ogreticiSuzmesi).
]]
Ogretici.UcAdet = 3

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
