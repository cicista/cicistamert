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

	remote("OgreticiDurum"):FireClient(player, {
		adim = data.tutorial.adim,
		bitti = data.tutorial.bitti,
		toplam = Adimlar.adimSayisi(),
	})
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
	if bekleyen == "ucKazdi" then
		if Ogretici.ayniKademeVar(player, 3, false) then
			Ogretici.olay(player, "ucKazdi")
		end
	elseif bekleyen == "ucCollectledi" then
		if Ogretici.ayniKademeVar(player, 3, true) then
			Ogretici.olay(player, "ucCollectledi")
		end
	end
end

--[[
	Istemci hazir olunca durumu istiyor.

	BAGLANTI task.spawn ICINDE: Net.event remote'u beklerken bu modulun
	yuklenmesi durmasin (yukaridaki tembel alma notuyla ayni sebep).
]]
task.spawn(function()
	remote("OgreticiIste").OnServerEvent:Connect(function(player)
		Ogretici.gonder(player)
	end)
end)

return Ogretici
