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

	-- Base
	"BaseGuncelle",     -- server -> client: base durumu + toplam gelir
	"SlotaKoy",         -- client -> server: brainrotu slota yerlestir
	"SlottanAl",        -- client -> server: brainrotu slottan al

	-- Lucky Block
	"EtkinlikSayaci",   -- server -> client: sonraki blok yagmuruna kalan saniye
	"LuckyBlockAc",     -- client -> server: bir blok acmak istiyorum
	"LuckyBlockSonuc",  -- server -> client: cark verisi + kazanan

	-- Gunluk odul
	"OdulDurum",        -- server -> client: kalan sure / cevrilebilir mi
	"OdulAc",           -- client -> server: durumu istiyorum
	"OdulCevir",        -- client -> server: carki cevir
	"OdulSonuc",        -- server -> client: cark verisi + kazanilan odul

	-- Slot makinesi
	"SlotMakinesiAc",   -- server -> client: makine arayuzu
	"SlotMakinesiCevir",-- client -> server: cevir
	"SlotMakinesiSonuc",-- server -> client: cikan skin

	-- Skin / magaza
	"SkinTak",          -- client -> server: bu skini tak
	"SkinDongu",        -- client -> server: Z -- elindeki toolun skinini degistir
	"MagazaAc",         -- server -> client: kurek + gps magazasi
	"KurekAl",          -- client -> server: kurek satin al
	"GPSAl",            -- client -> server: dedektor satin al

	-- Satici NPC
	"SaticiDurum",      -- server -> client: yakinlik + fiyatlar
	"BrainrotSat",      -- client -> server: elindekini sat (E)
	"TumunuSat",        -- client -> server: envanteri sat (F)

	-- Fuse makinesi
	"FuseDurum",        -- server -> client: makine paneli (kademe, adet, boyut sanslari)
	"FuseGeriAl",       -- client -> server: makinedeki esyalari envantere geri al
	"FuseSonuc",        -- server -> client: birlesme gosterisi (ruhlar + cikan coin)
	"FuseSecim",        -- server -> client: makine secim penceresini ac
	"FuseEkle",         -- client -> server: bu esyayi makineye koy (uid)

	-- Coin bozdurucu
	"CoinAc",           -- server -> client: bozdurulabilir coin listesi
	"CoinBozdur",       -- client -> server: bu coini bozdur
	"CoinSonuc",        -- server -> client: cark verisi + kazanan brainrot

	-- Flyboard
	"FlyboardAc",       -- server -> client: satici paneli (kademeler + fiyatlar)
	"FlyboardAl",       -- client -> server: bu kademeyi satin al
	"FlyboardYukseklik",-- client -> server: Space / Shift ile yukseklik degisimi

	-- Olta (RodSeller)
	"RodAc",            -- server -> client: olta saticisi paneli
	"RodAl",            -- client -> server: bu kademeyi al ya da kusan

	-- Gorevler (Quests paneli)
	"GorevDurum",       -- server -> client: pano + ilerleme + kalan sure
	"GorevAc",          -- client -> server: panoyu istiyorum
	"GorevAl",          -- client -> server: biten gorevin odulunu topla (id)

	-- Ayarlar (Settings paneli)
	"AyarDurum",       -- server -> client: kayitli ayarlar (arayuz olcegi)
	"AyarKaydet",      -- client -> server: ayari kaydet

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
