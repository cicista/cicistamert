--!strict
--[[
	OGRETICI  --  sunucu tarafi

	Yeni oyuncunun ilk turunu takip eder: hangi adimda oldugunu tutar,
	adimi bitiren olay geldiginde odulu verir ve siradakine gecer.
	Adimlarin kendisi Shared > Ogretici'de (ikisi de ayni listeden okur).

	NASIL ILERLIYOR
	Ogretici KENDI BASINA bir sey dinlemiyor. Oyunun sistemleri isleri
	bitince buraya haber veriyor:

	    Ogretici.olay(player, "kazdi")

	Gelen olay SIRADAKI adimin bekledigi olaysa adim biter; degilse sessizce
	yok sayilir. Boylece oyuncu adimlari atlayamiyor ve her sistem yalnizca
	tek satirla bagli kaliyor -- ogretici olmasa da calismaya devam ederler.

	KANCALARIN YERI
	    kazdi         KaziSistemi   (beam kazilip envantere girince)
	    collectledi   Detective     (kimlik acilinca)
	    slotladi      BaseSistemi   (brainrot slota konunca)
	    parayiAldi    BaseSistemi   (toplama padinde para alinca)
	    ucKazdi       KaziSistemi   (ayni kademeden ucu birikince)
	    ucCollectledi Detective     (ayni kademeden uc ACIK olunca)
	    fuseYapti     Fuse          (birlestirme bitince)

	ODUL
	Her adim 1 Rot Coin veriyor, yaninda BEYAZ FuseVFX patlamasi ve
	FuseExplosion sesi (bkz. Modules > Patlama). Beyaz, cunku odul bir
	kademeye bagli degil: oyuncu bunun ogretici odulu oldugunu renginden
	ayirt ediyor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Adimlar = require(Shared:WaitForChild("Ogretici"))

local PlayerData = require(script.Parent.PlayerData)
local Patlama = require(script.Parent.Patlama)

--[[
	REMOTE'LAR TEMBEL ALINIYOR.

	Modul seviyesinde Net.event cagirmak, remote henuz olusmamissa (Net.init
	baska bir scriptte calisiyor) require'i O SATIRDA bekletir -- ve bu
	modulu require eden butun sistemler onunla birlikte durur. 20 Eylul
	2026'da kazi sistemi boyle kilitlendi: GPS bile cantaya girmiyordu.

	Burada remote ilk KULLANIMDA aliniyor, yuklenirken degil.
]]
local remoteler: { [string]: RemoteEvent } = {}

local function remote(ad: string): RemoteEvent
	local mevcut = remoteler[ad]
	if not mevcut then
		mevcut = Net.event(ad)
		remoteler[ad] = mevcut
	end
	return mevcut
end

local Ogretici = {}

--[[
	ADIM KIMLIGI OYUNCU NITELIGINDE

	Istemcideki baska scriptler (ornegin minioyun) "su an ogreticinin hangi
	adimindayiz" bilgisine ihtiyac duyuyor ama OgreticiDurum remote'unu
	dinlemek zorunda kalmasinlar: nitelik kendiliginden replike oluyor ve
	her yerden tek satirla okunuyor.

	    player:GetAttribute("OgreticiAdim") == "ilkKazi"

	Ogretici bitince nitelik silinir (nil).
]]
Ogretici.Nitelik = "OgreticiAdim"

--[[
	ADIMIN ISARETLEYECEGI KONUM (istege bagli)

	Ilk kazida isaret KUMUN kendisi degil, oyuncu icin dogurulan garanti
	suzme olmali. KaziSistemi suzmeyi dogurunca buraya yaziyor; istemci
	oku hep o noktaya cekiyor. Suzme kazilinca / kaybolunca nil yazilir.
]]
local hedefKonum: { [Player]: Vector3 } = {}

function Ogretici.hedefKonumAyarla(player: Player, konum: Vector3?)
	if hedefKonum[player] == konum then
		return
	end
	hedefKonum[player] = konum
	Ogretici.gonder(player)
end

--[[
	GERI DUSME  --  ogretici elde olmayan bir seyi bekletmesin

	"Dedektife goturt" ve "slota koy" adimlarinin anlamli olmasi icin
	oyuncunun elinde bir brainrot olmali. Oyuncu onu sattiysa, birlestirdiyse
	ya da kaydi baska bir sebeple bos kaldiysa ogretici dedektifi isaret edip
	sonsuza kadar bekler -- oyuncu da ne istendigini anlamaz.

	Boyle bir durumda adim KAZI adimina geri aliniyor: isaret kuma doner,
	oyuncu kazar ve akis kaldigi yerden devam eder.

	Dedektife TESLIM EDILMIS esyalar da "elde" sayiliyor: oyuncu isi
	birakmis degil, sirasini bekliyor.
]]
local function elindeBrainrotVar(data: any): boolean
	if type(data.inventory) == "table" and #data.inventory > 0 then
		return true
	end

	local is = data.detectiveJob
	return is ~= nil and type(is.items) == "table" and #is.items > 0
end

local function geriDus(data: any)
	if data.tutorial.bitti then
		return
	end

	local adim = Adimlar.adim(data.tutorial.adim)
	if not adim then
		return
	end

	-- Bu iki adim da elde bir brainrot olmasini gerektiriyor
	if (adim.id == "ilkCollect" or adim.id == "slot") and not elindeBrainrotVar(data) then
		data.tutorial.adim = 1
	end
end

--[[
	Istemciye o anki durumu yollar.

	Veri henuz yuklenmemisse hicbir sey yollanmaz: istemci zaten hazir
	olunca OgreticiIste ile kendisi soruyor, o istek yuklemeden sonraya
	denk geliyor.
]]
function Ogretici.gonder(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	-- Elde olmayan bir seyi bekletiyorsak kazi adimina don
	geriDus(data)

	local adim = Adimlar.adim(data.tutorial.adim)
	player:SetAttribute(Ogretici.Nitelik, if data.tutorial.bitti or not adim then nil else adim.id)

	remote("OgreticiDurum"):FireClient(player, {
		adim = data.tutorial.adim,
		bitti = data.tutorial.bitti,
		toplam = Adimlar.adimSayisi(),
		-- Varsa isaret bu noktaya gider (ilk kazidaki garanti suzme)
		konum = hedefKonum[player],
	})
end

--[[
	UC KAZI ADIMI  --  SAYIM UIDLERLE

	"Uc tane ayni kademe" adimi eskiden envanterdeki ayni kademeden esyalari
	sayiyordu; base'e konmus ILK brainrot da sayildigi icin oyuncu IKI kazi
	yapinca adim bitiyordu. Artik yalnizca BU ADIMDA kazilan brainrotlarin
	uid'leri sayiliyor: ucunu kazmadan adim bitmez.

	Ayni liste bir sonraki adimda (hepsini dedektife goster) da kullanilir:
	adim, listedeki UC uid'in de kimligi acilinca biter.
]]
local function kazilanListesi(data: any): { string }
	local t = data.tutorial
	if type(t.kazilan) ~= "table" then
		t.kazilan = {}
	end
	return t.kazilan
end

-- Kac tane (Shared > Ogretici ile ayni sayi)
Ogretici.UcAdet = Adimlar.UcAdet or 3

-- Bu adimda kazilan bir brainrotu kaydeder; ucu tamamlaninca adimi bitirir
function Ogretici.kaziKaydet(player: Player, uid: string?)
	local data = PlayerData.get(player)
	if not data or type(uid) ~= "string" then
		return
	end
	if Ogretici.bekleyen(player) ~= "ucKazdi" then
		return
	end

	local liste = kazilanListesi(data)
	for _, mevcut in liste do
		if mevcut == uid then
			return
		end
	end

	table.insert(liste, uid)
	if #liste >= Ogretici.UcAdet then
		Ogretici.olay(player, "ucKazdi")
	end
end

-- Kayitli uid'lerin hepsi acildi mi (dedektiften geri geldi mi)
local function hepsiAcildi(data: any): boolean
	local liste = kazilanListesi(data)
	if #liste < Ogretici.UcAdet then
		return false
	end

	local acik: { [string]: boolean } = {}
	for _, item in data.inventory do
		if item.revealed and item.name then
			acik[item.uid] = true
		end
	end

	for _, uid in liste do
		if not acik[uid] then
			return false
		end
	end
	return true
end

-- Oyuncunun su anki adiminin kimligi (ornek: "ilkKazi"); bitmisse nil
function Ogretici.adimId(player: Player): string?
	local data = PlayerData.get(player)
	if not data or data.tutorial.bitti then
		return nil
	end
	local adim = Adimlar.adim(data.tutorial.adim)
	return if adim then adim.id else nil
end

-- Adim bitti kutlamasi: Rot Coin + beyaz patlama + ses
local function odullendir(player: Player, adim: Adimlar.Adim, sira: number)
	PlayerData.addRotCoins(player, Adimlar.RotCoinOdulu)
	Patlama.oynat(player, Adimlar.PatlamaOlcegi, true, Adimlar.PatlamaRengi)

	local son = sira >= Adimlar.adimSayisi()
	local yazi = if son
		then `Tutorial complete!  +{Adimlar.RotCoinOdulu} Rot Coin`
		else `{adim.yazi}  done!  +{Adimlar.RotCoinOdulu} Rot Coin`
	remote("Bildirim"):FireClient(player, yazi, Adimlar.IsaretRengi)
end

--[[
	Bir sistem "su oldu" diyor.

	Yalnizca SIRADAKI adimin bekledigi olay ilerletir. Oyuncu ileri bir
	adimin isini erken yaparsa (ornegin ogretici daha kazmayi soylemeden
	fuse yaparsa) o is sayilmaz, sirasi gelince yine yapmasi gerekir --
	adimlar birbirinin uzerine kuruluyor.
]]
function Ogretici.olay(player: Player, olay: string)
	local data = PlayerData.get(player)
	if not data or data.tutorial.bitti then
		return
	end

	local sira = data.tutorial.adim
	local adim = Adimlar.adim(sira)
	if not adim or adim.olay ~= olay then
		return
	end

	odullendir(player, adim, sira)

	-- Biten adimin isaret noktasi bir sonrakine tasinmasin
	hedefKonum[player] = nil

	-- "Hepsini dedektife goster" adimi bitince kazilan listesi de temizlenir
	if adim.id == "ucCollect" then
		data.tutorial.kazilan = {}
	end

	if sira >= Adimlar.adimSayisi() then
		data.tutorial.bitti = true
	else
		data.tutorial.adim = sira + 1
	end

	Ogretici.gonder(player)
end

--[[
	Ogreticinin SU AN bekledigi olay; ogretici bittiyse nil.

	Kancalarin ucuz cikis yolu: pahali bir sayim yapmadan once "bu olayi
	bekliyor muyuz" diye bakabilsinler.
]]
function Ogretici.bekleyen(player: Player): string?
	local data = PlayerData.get(player)
	if not data or data.tutorial.bitti then
		return nil
	end
	local adim = Adimlar.adim(data.tutorial.adim)
	return if adim then adim.olay else nil
end

--[[
	Envanterde AYNI kademeden `adet` tane var mi.

	yalnizcaAcik = true ise kimligi acilmis (revealed) olanlar sayilir;
	Fuse makinesi yalnizca onlari kabul ettigi icin "uc tanesini de
	dedektife goster" adimi bunu kullaniyor.

	Slota konmus esyalar da sayiliyor: oyuncu ilk brainrotunu base'e koydu,
	onu geri almak zorunda kalmasin.
]]
function Ogretici.ayniKademeVar(player: Player, adet: number, yalnizcaAcik: boolean?): boolean
	local data = PlayerData.get(player)
	if not data then
		return false
	end

	local sayac: { [string]: number } = {}
	for _, item in data.inventory do
		if yalnizcaAcik and not item.revealed then
			continue
		end
		local yeni = (sayac[item.rarity] or 0) + 1
		if yeni >= adet then
			return true
		end
		sayac[item.rarity] = yeni
	end

	return false
end

--[[
	"Uc tane ayni kademe" adimlarinin ortak kancasi: sart saglandiysa
	ilerletir. Kazi ve dedektif tarafindan cagriliyor.
]]
function Ogretici.ucKontrol(player: Player)
	local bekleyen = Ogretici.bekleyen(player)
	if bekleyen ~= "ucCollectledi" then
		return
	end

	local data = PlayerData.get(player)
	if not data then
		return
	end

	--[[
		Bu adimda kazilan UC brainrotun ucunun de kimligi acildiysa biter.
		Kayit yoksa (eski kayit, admin ile adim atlatildi) eski kurala
		dusulur: envanterde ayni kademeden uc ACIK esya.
	]]
	local bitti = if #kazilanListesi(data) >= Ogretici.UcAdet
		then hepsiAcildi(data)
		else Ogretici.ayniKademeVar(player, Ogretici.UcAdet, true)

	if bitti then
		Ogretici.olay(player, "ucCollectledi")
	end
end

--[[
	Istemci hazir olunca durumu istiyor.

	BAGLANTI task.spawn ICINDE: Net.event remote'u beklerken bu modulun
	yuklenmesi durmasin (yukaridaki tembel alma notuyla ayni sebep).
]]
--[[
	ADA IPUCU  (bkz. Shared > Ogretici > AdaIpucu)

	Ogretici bittikten sonra tek yonlendirme: parasi ikinci adaya yetince
	ipucu acilir, ada acilinca kapanir ve bir daha gosterilmez. Durum
	oyuncu niteliginde tutuluyor; istemciler (isinlayici menusu ve ogretici
	seridi) onu okuyor.
]]
local Config = require(Shared:WaitForChild("OyunConfig"))
local Shovels = require(Shared:WaitForChild("Shovels"))

local IP = Adimlar.AdaIpucu
-- Ilk kurek ipucu (asagida); IP'yi okuyan fonksiyonlar da bunu gordugu
-- icin ikisi de burada tanimli
local KI = Adimlar.KurekIpucu

local function ipucuFiyati(): number
	local ada = Config.Islands[IP.ada]
	return if ada then tonumber(ada.price) or math.huge else math.huge
end

local function ipucuKontrol(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	--[[
		Ogretici bitmeden ipucu cikmaz: yeni oyuncunun ekraninda iki
		yonlendirme birden durmasin.
	]]
	--[[
		SERIT TEK YONERGELIK: kurek ipucu aciksa ada ipucu bekler. Kurek
		oyunun sirasinda once geliyor (750K, ada 650M), yani normalde ikisi
		hic carsismaz -- ama kurek hic alinmadan adaya para yetisirse
		oyuncuyu once kurege yonlendiriyoruz.
	]]
	local uygun = data.tutorial.bitti
		and not data.tutorial.adaIpucu
		and data.islands < IP.ada
		and data.rot >= ipucuFiyati()
		and player:GetAttribute(KI.nitelik) ~= true

	if uygun then
		if player:GetAttribute(IP.nitelik) ~= true then
			player:SetAttribute(IP.nitelik, true)
		end
		return
	end

	-- Ada acildiysa ipucu biter ve bir daha gosterilmez
	if data.islands >= IP.ada and not data.tutorial.adaIpucu then
		data.tutorial.adaIpucu = true
		if player:GetAttribute(IP.nitelik) == true then
			-- Ipucu acikken ada alindi: varis mesaji
			remote("Bildirim"):FireClient(player, IP.varis, IP.renk)
		end
	end

	if player:GetAttribute(IP.nitelik) ~= nil then
		player:SetAttribute(IP.nitelik, nil)
	end
end

--[[
	ILK KUREK IPUCU  (bkz. Shared > Ogretici > KurekIpucu)

	Ada ipucuyla ayni kalipta: parasi ikinci kurege yetince nitelik acilir,
	kurek alininca kapanir ve bir daha gosterilmez. Fiyat Shovels'tan
	okunuyor, burada yazili degil.

	IKI IPUCU AYNI ANDA CIKMAZ: serit tek yonergelik, o yuzden kurek ipucu
	aciksa ada ipucu bekler (bkz. ipucuKontrol).
]]
local function kurekAlindi(data: PlayerData.Data): boolean
	local hedef = Shovels.Info[KI.kurek]
	local sahip = Shovels.Info[data.shovelMax]
	return hedef ~= nil and sahip ~= nil and sahip.level >= hedef.level
end

local function kurekIpucuKontrol(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	local hedef = Shovels.Info[KI.kurek]
	local fiyat = if hedef then hedef.price else math.huge

	-- Kurek alindiysa ipucu biter ve bir daha gosterilmez
	if kurekAlindi(data) then
		if not data.tutorial.kurekIpucu then
			data.tutorial.kurekIpucu = true
			if player:GetAttribute(KI.nitelik) == true then
				remote("Bildirim"):FireClient(player, KI.varis, KI.renk)
			end
		end
		if player:GetAttribute(KI.nitelik) ~= nil then
			player:SetAttribute(KI.nitelik, nil)
		end
		return
	end

	local uygun = data.tutorial.bitti and not data.tutorial.kurekIpucu and data.rot >= fiyat

	if uygun then
		if player:GetAttribute(KI.nitelik) ~= true then
			player:SetAttribute(KI.nitelik, true)
		end
	elseif player:GetAttribute(KI.nitelik) ~= nil then
		player:SetAttribute(KI.nitelik, nil)
	end
end

task.spawn(function()
	while true do
		task.wait(2)
		for _, player in game:GetService("Players"):GetPlayers() do
			pcall(ipucuKontrol, player)
			pcall(kurekIpucuKontrol, player)
		end
	end
end)

task.spawn(function()
	remote("OgreticiIste").OnServerEvent:Connect(function(player)
		Ogretici.gonder(player)
	end)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	hedefKonum[player] = nil
end)

return Ogretici
