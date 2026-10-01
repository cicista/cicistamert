--!strict

local DigMinigame = require(script.Parent.DigMinigame)
local KaziMinigame = require(script.Parent.KaziMinigame)
local Rarity = require(script.Parent.Rarity)
local Shovels = require(script.Parent.Shovels)

local SunucuIsini = {}

SunucuIsini.Kind = Rarity.Mystery.id
SunucuIsini.Ad = "MYSTERY BEAM"
SunucuIsini.Renk = Rarity.Mystery.color

SunucuIsini.Aralik = 1200
SunucuIsini.Kayma = 600
SunucuIsini.Omur = 300
SunucuIsini.UyariSaniyeleri = { 60 }

SunucuIsini.Kumlar = { "kum" }
SunucuIsini.Ada = "kum"
SunucuIsini.AdaAdi = "Main Island"
SunucuIsini.OdulAdasi = "deniz"

SunucuIsini.OdulArtislari = {
	{ artis = 1, sans = 70 },
	{ artis = 2, sans = 25 },
	{ artis = 3, sans = 5 },
}

SunucuIsini.Nitelik = {
	sonraki = "GizemSonraki",
	konum = "GizemKonum",
	bitis = "GizemBitis",
	kazan = "GizemKazan",
}

function SunucuIsini.sonraki(simdi: number): number
	local a, k = SunucuIsini.Aralik, SunucuIsini.Kayma
	return (math.floor((simdi - k) / a) + 1) * a + k
end

local function guc(gearId: string): number
	local gear = DigMinigame.gear(gearId)
	return if Shovels.Info[gearId :: Shovels.ShovelId] then Shovels.power(gear.level) else gear.level
end

function SunucuIsini.zorluk(gearId: string): string
	local sira = math.clamp(math.floor(guc(gearId)) + 1, 1, #Rarity.Order)
	return Rarity.Order[sira]
end

function SunucuIsini.odulKademesi(rng: Random, gearId: string): string
	local enIyi = KaziMinigame.enYuksekKademe(gearId) or Rarity.Order[1]
	local info = Rarity.Info[enIyi :: Rarity.RarityId]
	local sira = if info then info.order else 1

	local toplam = 0
	for _, satir in SunucuIsini.OdulArtislari do
		toplam += satir.sans
	end

	local zar = rng:NextNumber() * toplam
	local artis = SunucuIsini.OdulArtislari[1].artis
	for _, satir in SunucuIsini.OdulArtislari do
		zar -= satir.sans
		if zar <= 0 then
			artis = satir.artis
			break
		end
	end

	return Rarity.Order[math.clamp(sira + artis, 1, #Rarity.Order)]
end

return SunucuIsini
