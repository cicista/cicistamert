--!strict

local Gacha = {}

export type Yumurta = {
	rarity: string,
	sans: number,
}

Gacha.Yumurtalar = {
	{ rarity = "Secret", sans = 40 },
	{ rarity = "Cosmic", sans = 27 },
	{ rarity = "Gizli", sans = 18 },
	{ rarity = "Infernal", sans = 10 },
	{ rarity = "Abyssal", sans = 5 },
} :: { Yumurta }

Gacha.Fiyat = 499
Gacha.Ada = "deniz"
Gacha.UrunAnahtari = "Gacha"

Gacha.NpcAdi = "Gacha"
Gacha.PromptMesafe = 12

Gacha.BolmeSayisi = 46
Gacha.KazananSira = 40
Gacha.GirisSuresi = 0.8
Gacha.CevirmeSuresi = 6.5
Gacha.SonucSuresi = 3

Gacha.Artis = 0.5
Gacha.ArtanKademeler = { Infernal = true, Abyssal = true } :: { [string]: boolean }

local function tabanlar(): (number, number)
	local artan, diger = 0, 0
	for _, y in Gacha.Yumurtalar do
		if Gacha.ArtanKademeler[y.rarity] then
			artan += y.sans
		else
			diger += y.sans
		end
	end
	return artan, diger
end

function Gacha.maxIska(): number
	local _, diger = tabanlar()
	local sayi = 0
	for _ in Gacha.ArtanKademeler do
		sayi += 1
	end
	if sayi == 0 or Gacha.Artis <= 0 then
		return 0
	end
	return math.floor(diger / (Gacha.Artis * sayi) + 1e-6)
end

function Gacha.sanslar(iska: number?): { [string]: number }
	local n = math.clamp(math.floor(iska or 0), 0, Gacha.maxIska())
	local artis = Gacha.Artis * n
	local _, diger = tabanlar()

	local eklenen = 0
	local sonuc: { [string]: number } = {}
	for _, y in Gacha.Yumurtalar do
		if Gacha.ArtanKademeler[y.rarity] then
			sonuc[y.rarity] = y.sans + artis
			eklenen += artis
		end
	end
	local kalan = math.max(diger - eklenen, 0)
	for _, y in Gacha.Yumurtalar do
		if not Gacha.ArtanKademeler[y.rarity] then
			sonuc[y.rarity] = if diger > 0 then y.sans * kalan / diger else 0
		end
	end
	return sonuc
end

function Gacha.yuzde(deger: number): string
	local yuvarlak = math.floor(deger * 10 + 0.5) / 10
	if yuvarlak == math.floor(yuvarlak) then
		return `{math.floor(yuvarlak)}%`
	end
	return `{string.format("%.1f", yuvarlak)}%`
end

function Gacha.yumurtaAdi(displayName: string): string
	return `{displayName} Egg`
end

function Gacha.sans(rarity: string, iska: number?): number
	return Gacha.sanslar(iska)[rarity] or 0
end

function Gacha.sec(rng: Random, iska: number?): string
	local sanslar = Gacha.sanslar(iska)
	local toplam = 0
	for _, y in Gacha.Yumurtalar do
		toplam += sanslar[y.rarity] or 0
	end

	local zar = rng:NextNumber(0, toplam)
	local son = Gacha.Yumurtalar[1].rarity
	for _, y in Gacha.Yumurtalar do
		local agirlik = sanslar[y.rarity] or 0
		if agirlik <= 0 then
			continue
		end
		son = y.rarity
		zar -= agirlik
		if zar <= 0 then
			return y.rarity
		end
	end
	return son
end

function Gacha.toplamSure(): number
	return Gacha.GirisSuresi + Gacha.CevirmeSuresi
end

return Gacha
