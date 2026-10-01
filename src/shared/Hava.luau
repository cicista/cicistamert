--!strict

export type HavaTuru = {
	id: string,
	ad: string,
	mutasyon: string,
	sans: number,
	agirlik: number,
	renk: Color3,
	gok: Color3,
	parcacik: Color3,
}

local Hava = {}

Hava.Aralik = 1800
Hava.Kayma = 900
Hava.Sure = 240
Hava.UyariSaniyeleri = { 60 }

Hava.Turler = {
	{
		id = "GoldRush",
		ad = "Gold Rush",
		mutasyon = "Gold",
		sans = 25,
		agirlik = 40,
		renk = Color3.fromRGB(255, 200, 60),
		gok = Color3.fromRGB(255, 232, 175),
		parcacik = Color3.fromRGB(255, 214, 90),
	},
	{
		id = "DiamondHail",
		ad = "Diamond Hail",
		mutasyon = "Diamond",
		sans = 15,
		agirlik = 30,
		renk = Color3.fromRGB(110, 230, 255),
		gok = Color3.fromRGB(200, 238, 255),
		parcacik = Color3.fromRGB(170, 240, 255),
	},
	{
		id = "GalaxyNight",
		ad = "Galaxy Night",
		mutasyon = "Galaxy",
		sans = 8,
		agirlik = 20,
		renk = Color3.fromRGB(170, 110, 255),
		gok = Color3.fromRGB(205, 175, 255),
		parcacik = Color3.fromRGB(215, 140, 255),
	},
	{
		id = "HackerStorm",
		ad = "Hacker Storm",
		mutasyon = "Hacker",
		sans = 5,
		agirlik = 10,
		renk = Color3.fromRGB(60, 255, 110),
		gok = Color3.fromRGB(175, 255, 195),
		parcacik = Color3.fromRGB(90, 255, 140),
	},
} :: { HavaTuru }

Hava.Nitelik = {
	tur = "HavaTur",
	bitis = "HavaBitis",
	sonraki = "HavaSonraki",
}

function Hava.get(id: string?): HavaTuru?
	for _, tur in Hava.Turler do
		if tur.id == id then
			return tur
		end
	end
	return nil
end

function Hava.sec(rng: Random): HavaTuru
	local toplam = 0
	for _, tur in Hava.Turler do
		toplam += tur.agirlik
	end

	local zar = rng:NextNumber() * toplam
	for _, tur in Hava.Turler do
		zar -= tur.agirlik
		if zar <= 0 then
			return tur
		end
	end
	return Hava.Turler[1]
end

function Hava.sonraki(simdi: number): number
	local a, k = Hava.Aralik, Hava.Kayma
	return (math.floor((simdi - k) / a) + 1) * a + k
end

function Hava.aciklama(tur: HavaTuru): string
	return `{tur.sans}% {tur.mutasyon} chance on everything you dig or fish!`
end

return Hava
