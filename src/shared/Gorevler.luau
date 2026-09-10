--!strict
--[[
	GOREVLER  (Quests)

	Bes gorevlik bir pano; YARIM SAATTE BIR yenilenir. Pano herkeste aynidir:
	gorevler saat dilimine gore uretilir (cycle = os.time() / 1800), oyuncuya
	ozel olan yalnizca ILERLEME. Boylece iki oyuncu ayni gorevleri konusabilir
	ve sunucunun oyuncu basina gorev "uydurmasi" gerekmez.

	NEDEN "kac Rot kazan" GOREVI YOK

	Rot geliri oyun ilerledikce katlaniyor: yeni oyuncu icin imkansiz olan bir
	sayi, base'i dolmus oyuncu icin bir dakikalik is. Bu yuzden gorevler
	yalnizca EYLEM SAYIYOR (kaz, topla, sat, yerlestir, ac, birlestir) --
	bunlar oyunun her asamasinda asagi yukari ayni emegi ister.

	ZORLUK DENGESI

	Isik suzmesi sanslari: Common %62, Rare %25, Epic %9, Legendary %3.
	Yani "10 Rare topla" ortalama 40 kazi demek -- yarim saatlik pano icin
	normal zorluk. Hedefler bu tabloya gore secildi.

	ODULLER TAMAMEN COIN
	  easy   -> 1 Rare Coin
	  normal -> 1 Epic Coin
	  hard   -> 1 Legendary Coin
	Coin, Coin Trader'da ayni kademeden bir brainrota donusur.
]]

local Rarity = require(script.Parent.Rarity)

local Gorevler = {}

Gorevler.CYCLE_SECONDS = 1800
Gorevler.COUNT = 5

--[[
	Pano her yenilendiginde kac gorev hangi zorluktan gelir.
	Toplam bes: iki kolay, bir normal, bir zor, bir cok zor.
]]
Gorevler.Plan = { easy = 2, normal = 1, hard = 1, extreme = 1 }

export type QuestKind = "dig" | "collect" | "sell" | "place" | "lucky" | "fuse"
export type Difficulty = "easy" | "normal" | "hard" | "extreme"

export type QuestDef = {
	id: string,
	kind: QuestKind,
	-- Sayilacak kademe. "collect" gorevinde toplanan brainrotun, "fuse"
	-- gorevinde uretilen coinin kademesi. Bos birakilirsa hepsi sayar.
	rarity: string?,
	target: number,
	difficulty: Difficulty,
	-- Ilerleme bildiriminde kullanilan kisa ad: "Rare Brainrots  3/10"
	short: string,
	-- Panelde gorunen tam metin
	text: string,
	--[[
		Zorlugun standart odulunun yerine gecer.

		Fuse gorevleri icin var: "Mythic coin uret" diyen gorev odul olarak
		yine Mythic vermez -- oyuncu zaten o coini elinde tutuyor. Istenen
		fuse'in BIR ALTI verilir.
	]]
	reward: Reward?,
}

export type Reward = { rarity: string, count: number }

--[[
	ODUL KADEMESI = EMEK KADEMESI

	Bir gorev Legendary coin veriyorsa EN AZ Epic isteyecek (Epic suzme kazmak
	ya da Legendary coin uretmek); Mythic coin veriyorsa Legendary isteyecek.
	Yoksa Common kazarak Mythic kazanilirdi ve kademelerin anlami kalmazdi.

	  easy    -> Rare Coin       (Common seviyesi is)
	  normal  -> Epic Coin       (Rare seviyesi is)
	  hard    -> Legendary Coin  (Epic seviyesi is)
	  extreme -> Mythic Coin     (Legendary seviyesi is)
]]
local Rewards: { [Difficulty]: Reward } = {
	easy = { rarity = "Rare", count = 1 },
	normal = { rarity = "Epic", count = 1 },
	hard = { rarity = "Legendary", count = 1 },
	extreme = { rarity = "Mythic", count = 1 },
}

local Pool: { QuestDef } = {
	-- KOLAY  --  birkac dakika
	{
		id = "dig20",
		kind = "dig",
		target = 20,
		difficulty = "easy",
		short = "Beams Dug",
		text = "Dig Up 20 Light Beams",
	},
	{
		id = "common15",
		kind = "collect",
		rarity = "Common",
		target = 15,
		difficulty = "easy",
		short = "Common Brainrots",
		text = "Collect 15 Common Brainrots",
	},
	{
		id = "sell10",
		kind = "sell",
		target = 10,
		difficulty = "easy",
		short = "Brainrots Sold",
		text = "Sell 10 Brainrots",
	},
	{
		id = "place5",
		kind = "place",
		target = 5,
		difficulty = "easy",
		short = "Brainrots Placed",
		text = "Place 5 Brainrots On Your Base",
	},

	-- NORMAL  --  yarim saatin buyuk kismi
	{
		id = "rare10",
		kind = "collect",
		rarity = "Rare",
		target = 10,
		difficulty = "normal",
		short = "Rare Brainrots",
		text = "Collect 10 Rare Brainrots",
	},
	{
		id = "dig45",
		kind = "dig",
		target = 45,
		difficulty = "normal",
		short = "Beams Dug",
		text = "Dig Up 45 Light Beams",
	},
	{
		id = "sell25",
		kind = "sell",
		target = 25,
		difficulty = "normal",
		short = "Brainrots Sold",
		text = "Sell 25 Brainrots",
	},
	{
		--[[
			Lucky block nadir bir esya: "3 tane ac" gorevi cogu panoda
			bitirilemezdi. Tek blok isteniyor, odul yine Epic coin.
		]]
		id = "lucky1",
		kind = "lucky",
		target = 1,
		difficulty = "normal",
		short = "Lucky Blocks Opened",
		text = "Open A Lucky Block",
	},
	{
		id = "rare25",
		kind = "collect",
		rarity = "Rare",
		target = 25,
		difficulty = "normal",
		short = "Rare Brainrots",
		text = "Collect 25 Rare Brainrots",
	},

	-- ZOR  --  Epic seviyesi is, Legendary coin verir
	{
		id = "epic3",
		kind = "collect",
		rarity = "Epic",
		target = 3,
		difficulty = "hard",
		short = "Epic Brainrots",
		text = "Collect 3 Epic Brainrots",
	},
	{
		id = "fuseLegendary",
		kind = "fuse",
		rarity = "Legendary",
		target = 1,
		difficulty = "hard",
		-- Istenen fuse'in bir alti: Legendary uret, Epic coin al
		reward = { rarity = "Epic", count = 1 },
		short = "Legendary Coins Made",
		text = "Create A Legendary Coin At The Fuse Machine",
	},

	-- COK ZOR  --  Legendary seviyesi is, Mythic coin verir
	{
		id = "legendary2",
		kind = "collect",
		rarity = "Legendary",
		target = 2,
		difficulty = "extreme",
		short = "Legendary Brainrots",
		text = "Collect 2 Legendary Brainrots",
	},
	{
		id = "fuseMythic",
		kind = "fuse",
		rarity = "Mythic",
		target = 1,
		difficulty = "extreme",
		-- Istenen fuse'in bir alti: Mythic uret, Legendary coin al
		reward = { rarity = "Legendary", count = 1 },
		short = "Mythic Coins Made",
		text = "Create A Mythic Coin At The Fuse Machine",
	},
}

Gorevler.Rewards = Rewards
Gorevler.Pool = Pool

local byId: { [string]: QuestDef } = {}
local byDifficulty: { [string]: { QuestDef } } = { easy = {}, normal = {}, hard = {}, extreme = {} }

for _, def in Pool do
	byId[def.id] = def
	table.insert(byDifficulty[def.difficulty], def)
end

function Gorevler.get(id: string): QuestDef?
	return byId[id]
end

function Gorevler.reward(def: QuestDef): Reward
	return def.reward or Rewards[def.difficulty]
end

--[[
	Odulun yazisi: "Epic Coin".

	TEK adette sayi YAZILMAZ -- "1 Epic Coin" hem gereksiz hem de rakam
	kelimeye yapisik duruyordu. Birden fazlaysa "2x Epic Coin".
]]
function Gorevler.rewardText(def: QuestDef): string
	local reward = Gorevler.reward(def)
	local ad = `{Rarity.displayName(reward.rarity)} Coin`
	return if reward.count > 1 then `{reward.count}x {ad}` else ad
end

-- Kacinci yarim saatlik dilimdeyiz
function Gorevler.cycle(now: number?): number
	return math.floor((now or os.time()) / Gorevler.CYCLE_SECONDS)
end

-- Panonun yenilenmesine kalan saniye
function Gorevler.remaining(now: number?): number
	local zaman = now or os.time()
	return Gorevler.CYCLE_SECONDS - (zaman % Gorevler.CYCLE_SECONDS)
end

local function karistir(list: { QuestDef }, rng: Random): { QuestDef }
	local copy = table.clone(list)
	for i = #copy, 2, -1 do
		local j = rng:NextInteger(1, i)
		copy[i], copy[j] = copy[j], copy[i]
	end
	return copy
end

local cache: { [number]: { QuestDef } } = {}

--[[
	Bir dilimin gorevleri. Ayni cycle her zaman ayni bes gorevi verir:
	rastgeleligin tohumu dilim numarasi.

	Ayni TURDEN iki gorev secilmemeye calisilir (iki tane "kaz" gorevi ayni
	anda ilerler, pano tekrar ediyormus gibi durur). Havuz yetmezse tekrara
	izin verilir, yoksa pano bes gorevden az kalir.
]]
function Gorevler.forCycle(cycle: number): { QuestDef }
	local hazir = cache[cycle]
	if hazir then
		return hazir
	end

	local rng = Random.new(cycle)
	local secilen: { QuestDef } = {}
	local kullanilanTur: { [string]: boolean } = {}

	for _, zorluk in { "easy", "normal", "hard", "extreme" } do
		local havuz = karistir(byDifficulty[zorluk], rng)
		local kalan = Gorevler.Plan[zorluk :: Difficulty]

		for _, def in havuz do
			if kalan <= 0 then
				break
			end
			if not kullanilanTur[def.kind] then
				table.insert(secilen, def)
				kullanilanTur[def.kind] = true
				kalan -= 1
			end
		end

		for _, def in havuz do
			if kalan <= 0 then
				break
			end
			if not table.find(secilen, def) then
				table.insert(secilen, def)
				kalan -= 1
			end
		end
	end

	cache[cycle] = secilen
	return secilen
end

return Gorevler
