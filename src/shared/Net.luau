--!strict
--[[
	Butun RemoteEvent / RemoteFunction'lari tek yerden tanimlar.

	Server tarafi Net.init() cagirir (Leaderstats en erken calisan script),
	client tarafi Net.event("Ad") ile bekleyerek alir. Boylece
	"WaitForChild sirasi" sorunu olmaz.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

-- RemoteEvent isimleri
Net.Events = {
	-- Mevcut sistem
	"AdaMenusuAc",
	"AdayaGit",
	"Bildirim",

	-- GPS + kazi
	"GPSGuncelle",      -- server -> client: yakindaki suzmelerin listesi
	"SuzmeKaz",         -- client -> server: su suzmeyi kazmak istiyorum
	"MinigameBasla",    -- server -> client: gearId (kurek ya da olta), rarityId, seed
	"MinigameSonuc",    -- client -> server: kazandim / kaybettim
	"KaziBitti",        -- server -> client: minigame kapat

	-- Envanter
	"EnvanterGuncelle", -- server -> client: tam envanter
	"EnvanterAc",       -- client -> server: envanteri istiyorum

	-- Brainrot Detective
	"DetectiveAc",      -- server -> client: teslim edilebilir siyah brainrotlar
	"DetectiveTeslim",  -- client -> server: bu brainrotu temizle
	"DetectiveSonuc",   -- server -> client: acilan brainrot bilgisi
	"DetectiveDurum",   -- server -> client: toplu inceleme isi (kalan, toplam, adet) ya da nil

	-- Base
	"BaseGuncelle",     -- server -> client: base durumu + toplam gelir
	"ParaSac",          -- server -> client: toplama efekti (toplayan, padin ust yuzu, miktar)
	"SlotaKoy",         -- client -> server: brainrotu slota yerlestir
	"SlottanAl",        -- client -> server: brainrotu slottan al

	-- Lucky Block
	"EtkinlikSayaci",   -- server -> client: sonraki blok yagmuruna kalan saniye
	"LuckyBlockAc",     -- client -> server: bir blok acmak istiyorum
	"LuckyBlockSonuc",  -- server -> client: cark verisi + kazanan

	-- Gunluk odul
	"OdulDurum",        -- server -> client: takvimde hangi gun, alinabilir mi, kalan sure
	"OdulAc",           -- client -> server: durumu istiyorum
	"OdulAl",           -- client -> server: bugunun odulunu al
	"OdulSonuc",        -- server -> client: odulu alinan gun (kart kutlamasi icin)

	-- Arkadaslar (Friends sekmesi + arkadas buffi)
	"ArkadasDurum",     -- server -> client: sunucudaki arkadaslar + buff yuzdesi
	"ArkadasAc",        -- client -> server: durumumu soyle

	-- Rot Coin magazasi
	"RotCoinMagazaAc",    -- client -> server: iksir durumumu soyle
	"RotCoinMagazaAl",    -- client -> server: bu urunu al (id)
	"RotCoinMagazaDurum", -- server -> client: aktif sans iksiri (carpan, kalan sure)

	-- Level sistemi
	"SeviyeDurum",      -- server -> client: level, xp, gereken xp, kazanilan xp
	"SeviyeAtladi",     -- server -> client: level atlandi (yeni level, oduller)
	"SeviyeAc",         -- client -> server: durumumu soyle

	-- Rewards paneli: Playtime + Social Rewards sekmeleri
	"EkOdulAc",         -- client -> server: playtime/social durumumu soyle
	"EkOdulAl",         -- client -> server: odulu al ("group" | "like" | "playtime", index)
	"EkOdulDurum",      -- server -> client: oturum suresi, alinanlar
	"KodKullan",        -- client -> server: kodu kullan (metin)
	"KodSonuc",         -- server -> client: kod sonucu (ok, message)

	-- Magaza
	"MagazaAc",         -- server -> client: kurek + gps magazasi
	"KurekAl",          -- client -> server: kurek satin al
	"GPSAl",            -- client -> server: dedektor satin al

	-- Satici NPC
	"SaticiDurum",      -- server -> client: yakinlik + fiyatlar
	"BrainrotSat",      -- client -> server: elindekini sat (E)
	"TumunuSat",        -- client -> server: envanteri sat (F)

	-- Fuse makinesi
	"FuseDurum",        -- server -> client: makine penceresi (slotlar, secilebilirler, sans)
	"FuseGeriAl",       -- client -> server: makinedeki butun brainrotlari geri al
	"FuseSonuc",        -- server -> client: birlesme gosterisi (basari + kazanilan brainrot)
	"FuseSecim",        -- server -> client: makine penceresini ac
	"FuseEkle",         -- client -> server: bu brainrotu makineye koy (uid)
	"FuseCikar",        -- client -> server: bu slottaki brainrotu geri al (uid)
	"FuseBaslat",       -- client -> server: FUSE dugmesi, birlestirmeyi baslat

	-- Flyboard
	"FlyboardAc",       -- server -> client: satici paneli (kademeler + fiyatlar)
	"FlyboardAl",       -- client -> server: bu kademeyi satin al
	"FlyboardYukseklik",-- client -> server: Space / Shift ile yukseklik degisimi

	-- Olta (RodSeller)
	"RodAc",            -- server -> client: olta saticisi paneli
	"RodAl",            -- client -> server: bu kademeyi al ya da kusan

	-- Ada saticilari (kurek + kazma + maden takasi)
	"AdaKurekAc",       -- server -> client: adanin kurek saticisi paneli
	"AdaKurekAl",       -- client -> server: ada kuregini al ya da kusan
	"KazmaAc",          -- server -> client: kazma saticisi paneli (kazma + takas)
	"KazmaAl",          -- client -> server: adanin kazmasini satin al
	"MadenTakas",       -- client -> server: diger iki madenden birer tane ver, bunu al

	-- Gorevler (Quests paneli)
	"GorevDurum",       -- server -> client: pano + ilerleme + kalan sure
	"GorevAc",          -- client -> server: panoyu istiyorum
	"GorevAl",          -- client -> server: biten gorevin odulunu topla (id)

	-- Ayarlar (Settings paneli)
	"AyarDurum",       -- server -> client: kayitli ayarlar (arayuz olcegi)
	"AyarKaydet",      -- client -> server: ayari kaydet

	-- Index (brainrot kesif defteri)
	"IndexAc",          -- client -> server: defteri istiyorum
	"IndexDurum",       -- server -> client: kesfedilen brainrot adlari

	-- Robux gecisleri (bkz. Shared > Passler); sahiplik oyuncu niteligiyle gelir
	"PassSatinAl",       -- client -> server: bu gecisin satin alma penceresini ac (ad)

	-- Sagdaki butonlar
	"BaseyeIsinlan",     -- client -> server: beni base'imin onune isinla
	"IsinlayiciGit",     -- client -> server: acik adaya isinla (ada indeksi, Teleporter gecisi)

	-- Hiz yukseltmesi (bkz. Shared > Hiz); seviye oyuncu niteliginde (SpeedLevel)
	"HizAl",             -- client -> server: kac yukseltme alinacak

	-- Admin
	"AdminPanelAc",     -- server -> client: panel + yetki
	"AdminKomut",       -- client -> server: komut calistir
}

local function folder(): Folder
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing and existing:IsA("Folder") then
		return existing
	end

	local created = Instance.new("Folder")
	created.Name = "Remotes"
	created.Parent = ReplicatedStorage
	return created
end

-- Server: butun remote'lari olusturur. Birden fazla cagirmak zararsizdir.
function Net.init()
	assert(RunService:IsServer(), "Net.init sadece server tarafinda cagrilir")

	local remotes = folder()
	for _, name in Net.Events do
		if not remotes:FindFirstChild(name) then
			local event = Instance.new("RemoteEvent")
			event.Name = name
			event.Parent = remotes
		end
	end
end

-- Her iki taraf: adiyla remote alir. Client tarafinda hazir olana kadar bekler.
function Net.event(name: string): RemoteEvent
	local remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	return remotes:WaitForChild(name) :: RemoteEvent
end

return Net
