--!strict

local DigMinigame = require(script.Parent.DigMinigame)
local Rarity = require(script.Parent.Rarity)
local Shovels = require(script.Parent.Shovels)

local SunucuIsini = {}

SunucuIsini.Kind = Rarity.Mystery.id
SunucuIsini.Ad = "MYSTERY BEAM"
SunucuIsini.Renk = Rarity.Mystery.color

SunucuIsini.Omur = 300

SunucuIsini.Adalar = { "kum", "sekerkum", "snowkum", "alevkum" }
SunucuIsini.OdulAdasi = "deniz"

SunucuIsini.OdulSanslari = {
	{ kademe = "Legendary", sans = 22 },
	{ kademe = "Mythic", sans = 18 },
	{ kademe = "Secret", sans = 15 },
	{ kademe = "Cosmic", sans = 13 },
	{ kademe = "Gizli", sans = 11.5 },
	{ kademe = "Infernal", sans = 10.5 },
	{ kademe = "Abyssal", sans = 10 },
}

SunucuIsini.Nitelik = {
	sonraki = "GizemSonraki",
	konum = "GizemKonum",
	bitis = "GizemBitis",
	kazan = "GizemKazan",
	ada = "GizemAda",
}

local function guc(gearId: string): number
	local gear = DigMinigame.gear(gearId)
	return if Shovels.Info[gearId :: Shovels.ShovelId] then Shovels.power(gear.level) else gear.level
end

function SunucuIsini.zorluk(gearId: string): string
	local sira = math.clamp(math.floor(guc(gearId)) + 1, 1, #Rarity.Order)
	return Rarity.Order[sira]
end

function SunucuIsini.odulKademesi(rng: Random): string
	local toplam = 0
	for _, satir in SunucuIsini.OdulSanslari do
		toplam += satir.sans
	end

	local zar = rng:NextNumber() * toplam
	for _, satir in SunucuIsini.OdulSanslari do
		zar -= satir.sans
		if zar <= 0 then
			return satir.kademe
		end
	end
	return SunucuIsini.OdulSanslari[1].kademe
end

return SunucuIsini
