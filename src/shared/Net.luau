--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

Net.Events = {
	"AdaMenusuAc",
	"AdayaGit",
	"Bildirim",

	"GPSGuncelle",
	"SuzmeKaz",
	"MinigameBasla",
	"MinigameSonuc",
	"KaziBitti",

	"EnvanterGuncelle",
	"EnvanterAc",
	"CantaYukselt",

	"DetectiveAc",
	"DetectiveTeslim",
	"DetectiveSonuc",
	"DetectiveDurum",
	"DetectiveTakip",

	"BaseGuncelle",
	"ParaSac",
	"SlotaKoy",
	"SlottanAl",

	"LuckyBlockAc",
	"LuckyBlockSonuc",
	"LuckyBlockBasladi",

	"OdulDurum",
	"OdulAc",
	"OdulAl",
	"OdulSonuc",

	"ArkadasDurum",
	"ArkadasAc",

	"RotCoinMagazaAc",
	"RotCoinMagazaAl",
	"RotCoinMagazaDurum",

	"SeviyeDurum",
	"SeviyeAtladi",
	"SeviyeAc",

	"EkOdulAc",
	"EkOdulAl",
	"EkOdulDurum",
	"KodKullan",
	"KodSonuc",

	"MagazaAc",
	"KurekAl",
	"GPSAl",

	"SaticiDurum",
	"BrainrotSat",
	"TumunuSat",

	"FuseDurum",
	"FuseGeriAl",
	"FuseSonuc",
	"FuseSecim",
	"FuseEkle",
	"FuseCikar",
	"FuseBaslat",

	"FlyboardAc",
	"FlyboardAl",
	"FlyboardYukseklik",

	"RodAc",
	"RodAl",

	"AdaKurekAc",
	"AdaKurekAl",
	"KazmaAc",
	"KazmaAl",
	"MadenTakas",

	"GorevDurum",
	"GorevAc",
	"GorevAl",

	"AyarDurum",
	"AyarKaydet",

	"IndexAc",
	"IndexDurum",

	"PassSatinAl",
	"RobuxUrunAl",

	"BaseyeIsinlan",
	"IsinlayiciGit",

	"HizAl",
	"HizRebirth",
	"HizAyarla",

	"YoncaListesi",
	"YoncaIste",
	"AfkAlan",
	"YoncaTopla",
	"YoncaSonuc",
	"LeprechaunAc",
	"AfkAlanAl",
	"AfkYenidenBaglan",

	"GachaAc",
	"KacanYumurtaTeklif",
	"Duyuru",
	"UnvanDurum",
	"UnvanAc",
	"UnvanKusan",
	"TakasIslem",
	"TakasDurum",
	"GachaSonuc",
	"GachaDene",

	"AdminPanelAc",
	"AdminKomut",

	"ScrollSonuc",

	"OgreticiDurum",
	"OgreticiIste",

	"KapismaBasla",
	"KapismaDurum",
	"KapismaTik",
	"KapismaBitti",
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

function Net.init()
	assert(RunService:IsServer(), "Net.init must only be called on the server")

	local remotes = folder()
	for _, name in Net.Events do
		if not remotes:FindFirstChild(name) then
			local event = Instance.new("RemoteEvent")
			event.Name = name
			event.Parent = remotes
		end
	end
end

function Net.event(name: string): RemoteEvent
	local remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	return remotes:WaitForChild(name) :: RemoteEvent
end

return Net
