--!strict

local Shovels = require(script.Parent:WaitForChild("Shovels"))
local Rods = require(script.Parent:WaitForChild("Rods"))

local AfkSans = {}

local function kurekFiyati(level: number): number
	for _, info in Shovels.Info do
		if info.level == level then
			return info.price
		end
	end
	error(`AfkSans: Lv{level} shovel not found`)
end

local function oltaFiyati(level: number): number
	for _, info in Rods.Info do
		if info.level == level then
			return info.price
		end
	end
	error(`AfkSans: Lv{level} rod not found`)
end

export type Alan = {
	id: string,
	displayName: string,
	puanYonca: number,
	fiyat: number,
	kademe: string?,
	robux: string?,
}

local MYTHIC_PUAN = 500

local alanlar: { Alan } = {
	{ id = "Common", displayName = "Common Clover Field", puanYonca = 25, fiyat = 0 },
	{ id = "Rare", displayName = "Rare Clover Field", puanYonca = 60, fiyat = kurekFiyati(6) },
	{ id = "Epic", displayName = "Epic Clover Field", puanYonca = 135, fiyat = kurekFiyati(11) },
	{ id = "Legendary", displayName = "Legendary Clover Field", puanYonca = 270, fiyat = oltaFiyati(1) },
	{ id = "Mythic", displayName = "Mythic Clover Field", puanYonca = MYTHIC_PUAN, fiyat = oltaFiyati(5) },
	{
		id = "Secret",
		kademe = "Gizli",
		displayName = "Secret Clover Field",
		puanYonca = MYTHIC_PUAN * 2,
		fiyat = 0,
		robux = "AfkSecretAlan",
	},
}
AfkSans.Alanlar = alanlar

AfkSans.MaxPuan = 20_000_000
AfkSans.MaxCarpan = 20

AfkSans.YoncaSayisi = 10
AfkSans.MinAralik = 2
AfkSans.KenarPayi = 2
AfkSans.OlcekMin = 0.3
AfkSans.OlcekMax = 0.75
AfkSans.ToplamaSuresi = 3
AfkSans.Erisim = 3
AfkSans.TitremeSuresi = 1
AfkSans.YoncaXp = 1
AfkSans.ToplamaAnimasyonu = "rbxassetid://112929077414582"

AfkSans.OtoBaslamaBekleme = 1

AfkSans.YenidenBaglanSuresi = 18 * 60
AfkSans.DonusGecerlilik = 10 * 60
AfkSans.TeleportVeriAnahtari = "AfkDonus"

AfkSans.KlasorAdi = "CloverAreas"
AfkSans.NpcAdi = "Leprechaun"
AfkSans.PuanNiteligi = "AfkPuan"
AfkSans.SeviyeNiteligi = "AfkSeviye"
AfkSans.OzelNiteligi = "AfkOzelAlanlar"

function AfkSans.kademe(id: string): string
	local alan = AfkSans.get(id)
	return if alan and alan.kademe then alan.kademe else id
end

function AfkSans.siraliSayi(): number
	local sayi = 0
	for _, alan in AfkSans.Alanlar do
		if not alan.robux then
			sayi += 1
		end
	end
	return sayi
end

function AfkSans.sahip(sira: number, seviye: number, ozel: { [string]: boolean }): boolean
	local alan = AfkSans.Alanlar[sira]
	if not alan then
		return false
	end
	if alan.robux then
		return ozel[alan.id] == true
	end
	return sira <= seviye
end

function AfkSans.ozelCoz(yazi: any): { [string]: boolean }
	local ozel: { [string]: boolean } = {}
	if type(yazi) == "string" then
		for id in string.gmatch(yazi, "[^,]+") do
			ozel[id] = true
		end
	end
	return ozel
end

function AfkSans.sira(id: string): number?
	for i, alan in AfkSans.Alanlar do
		if alan.id == id then
			return i
		end
	end
	return nil
end

function AfkSans.get(id: string): Alan?
	local i = AfkSans.sira(id)
	return if i then AfkSans.Alanlar[i] else nil
end

function AfkSans.carpan(puan: number): number
	local oran = math.clamp(puan, 0, AfkSans.MaxPuan) / AfkSans.MaxPuan
	return 1 + (AfkSans.MaxCarpan - 1) * oran
end

function AfkSans.icinde(zemin: BasePart, nokta: Vector3): boolean
	local yerel = zemin.CFrame:PointToObjectSpace(nokta)
	local boy = zemin.Size
	return math.abs(yerel.X) <= boy.X / 2
		and math.abs(yerel.Z) <= boy.Z / 2
		and yerel.Y >= boy.Y / 2 - 1
		and yerel.Y <= boy.Y / 2 + 20
end

return AfkSans
