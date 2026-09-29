--!strict
--[[
	Olta minioyunu zorluk simulasyonu (olta x kademe).
	Kullanim: lune run tools/zorluk.luau

	Shared > DigMinigame Roblox API'si (Random, Color3) kullandigi icin Lune'da
	dogrudan require edilemez; asagidaki model oradaki Stardew modelinin
	aynisidir. DigMinigame.Baliklar ya da Rods minigame degerleri degisirse
	burayi da guncelle.

	Her olta x kademe icin uc bot oynar ve kazanma yuzdesi yazilir:

	  SABIT  -- bari sutunun ortasinda tutar, baliga hic bakmaz. Eski
	            modeldeki acik buydu; yeni modelde kazanamamali.
	  ORTA   -- baligi 0.25 sn gecikmeyle gorur, kaba tahminle kovalar
	            (siradan bir oyuncu)
	  USTA   -- 0.15 sn gecikme, iyi tahmin (cok iyi bir oyuncu)
]]

local OYUN = 300

-- DigMinigame.Baliklar ile ayni (Rarity.order sirasiyla)
local BALIKLAR = {
	{ ad = "Common", zorluk = 15, hareket = "mixed" },
	{ ad = "Rare", zorluk = 30, hareket = "smooth" },
	{ ad = "Epic", zorluk = 45, hareket = "mixed" },
	{ ad = "Legendary", zorluk = 55, hareket = "floater" },
	{ ad = "Mythic", zorluk = 65, hareket = "mixed" },
	{ ad = "Divine", zorluk = 75, hareket = "sinker" },
	{ ad = "Cosmic", zorluk = 82, hareket = "dart" },
	{ ad = "Secret", zorluk = 90, hareket = "mixed" },
	{ ad = "Infernal", zorluk = 100, hareket = "mixed" },
	{ ad = "Abyssal", zorluk = 110, hareket = "mixed" },
}

-- Rods minigame degerleri ile ayni
local OLTALAR = {
	{ ad = "Bamboo", bar = 0.17, ivme = 1, artis = 0.12, gerileme = 0.18 },
	{ ad = "Steel", bar = 0.2, ivme = 1, artis = 0.125, gerileme = 0.17 },
	{ ad = "Carbon", bar = 0.23, ivme = 1.05, artis = 0.13, gerileme = 0.16 },
	{ ad = "Abyssal", bar = 0.27, ivme = 1.05, artis = 0.135, gerileme = 0.15 },
	{ ad = "Leviathan", bar = 0.31, ivme = 1.1, artis = 0.14, gerileme = 0.14 },
}

local TIK = 1 / 60
local SUTUN = 568
local ZAMAN_ASIMI = 120

local function sonraki(a: number, b: number): number
	a = math.floor(a)
	b = math.floor(b)
	if b - 1 <= a then
		return a
	end
	return math.random(a, b - 1)
end

type Bot = (gecmis: { number }, barMerkez: number, barHiz: number, boy: number) -> boolean

local function oyna(olta: any, balik: any, bot: Bot, gecikme: number): (boolean, number)
	local boy = math.floor(olta.bar * SUTUN + 0.5)
	local barUst = SUTUN - boy
	local barHiz = 0
	local b = 508
	local bHiz = 0
	local hedef = -1
	local suzulme = 0
	local iceride = true
	local ilerleme = 0.3
	local d = balik.zorluk
	local tip = balik.hareket
	local smooth = tip == "smooth"
	local gecmis: { number } = {}

	local tik = 0
	while tik * TIK < ZAMAN_ASIMI do
		tik += 1

		-- Balik
		if math.random() < d * (if smooth then 20 else 1) / 4000 and (not smooth or hedef == -1) then
			local asagi = 548 - b
			local oran = math.min(99, d + sonraki(10, 45)) / 100
			hedef = b + sonraki(math.min(-b, asagi), asagi) * oran
		end
		if tip == "floater" then
			suzulme = math.max(suzulme - 0.01, -1.5)
		elseif tip == "sinker" then
			suzulme = math.min(suzulme + 0.01, 1.5)
		end
		if math.abs(b - hedef) > 3 and hedef ~= -1 then
			local ivme = (hedef - b) / (sonraki(10, 30) + (100 - math.min(100, d)))
			bHiz += (ivme - bHiz) / 5
		elseif not smooth and math.random() < d / 2000 then
			hedef = b + (if math.random() < 0.5 then sonraki(-100, -51) else sonraki(50, 101))
		else
			hedef = -1
		end
		if tip == "dart" and math.random() < d / 1000 then
			hedef = b + (if math.random() < 0.5 then sonraki(-100 - d * 2, -51) else sonraki(50, 101 + d * 2))
		end
		hedef = math.clamp(hedef, -1, 548)
		b = math.clamp(b + bHiz + suzulme, 0, 532)

		-- Oyuncu baligin gecikmeli halini gorur (ekrandaki ortasi: b + 30)
		table.insert(gecmis, b + 30)
		local gorulen = gecmis[math.max(1, #gecmis - gecikme)]
		local basili = bot({ gorulen, gecmis[math.max(1, #gecmis - gecikme - 6)] }, barUst + boy / 2, barHiz, boy)

		-- Bar
		local ivme = if basili then -0.25 * olta.ivme else 0.25
		if basili and (barUst == 0 or barUst == SUTUN - boy) then
			barHiz = 0
		end
		if iceride then
			ivme *= 0.6
		end
		barHiz += ivme
		barUst += barHiz
		if barUst + boy > SUTUN then
			barUst = SUTUN - boy
			barHiz = -barHiz * 2 / 3
		elseif barUst < 0 then
			barUst = 0
			barHiz = -barHiz * 2 / 3
		end
		iceride = b + 12 <= barUst - 32 + boy and b - 16 >= barUst - 32
		if b >= 548 - boy and barUst >= SUTUN - boy - 4 then
			iceride = true
		end

		if iceride then
			ilerleme += olta.artis * TIK
		else
			ilerleme -= olta.gerileme * TIK
		end
		if ilerleme >= 1 then
			return true, tik * TIK
		elseif ilerleme <= 0 then
			return false, tik * TIK
		end
	end
	return false, ZAMAN_ASIMI
end

-- Bari ortada tutar: baliga bakmaz
local sabit: Bot = function(_, barMerkez, barHiz)
	return barMerkez + barHiz * 6 > SUTUN / 2
end

-- Tahminli kovalama: baligin hizini da kestirip bari oraya surer
local function kovalayan(ongoru: number, hata: number): Bot
	return function(g, barMerkez, barHiz)
		local simdi, once = g[1], g[2]
		local tahmin = simdi + (simdi - once) / 6 * ongoru
		local hedef = tahmin + (math.random() * 2 - 1) * hata
		return barMerkez + barHiz * 8 > hedef
	end
end

local orta = kovalayan(4, 22)
local usta = kovalayan(10, 8)

local function yuzde(olta: any, balik: any, bot: Bot, gecikme: number): (number, number)
	local kazanc, sure = 0, 0
	for _ = 1, OYUN do
		local ok, s = oyna(olta, balik, bot, gecikme)
		if ok then
			kazanc += 1
			sure += s
		end
	end
	return math.floor(kazanc / OYUN * 100 + 0.5), if kazanc > 0 then sure / kazanc else 0
end

math.randomseed(12345)

print(`Kazanma yuzdesi (her hucre {OYUN} oyun)  SABIT / ORTA / USTA  [ustanin ort. suresi]`)
local baslik = string.format("%-10s", "")
for _, olta in OLTALAR do
	baslik ..= string.format("%-24s", olta.ad)
end
print(baslik)

for _, balik in BALIKLAR do
	local satir = string.format("%-10s", balik.ad)
	for _, olta in OLTALAR do
		local s = yuzde(olta, balik, sabit, 0)
		local o = yuzde(olta, balik, orta, 15)
		local u, us = yuzde(olta, balik, usta, 9)
		satir ..= string.format("%-24s", string.format("%3d/%3d/%3d [%4.1fs]", s, o, u, us))
	end
	print(satir)
end
