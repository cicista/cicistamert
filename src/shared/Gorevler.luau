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

	ZORLUK DENGESI  (yarim saatte ~60 kazi)

	Isik suzmesi sanslari ana adada: Common %62, Rare %25, Epic %9,
	Legendary %3. "8 Rare topla" ~30 kazi, "3 Epic topla" ~35 kazi demek.
	Legendary tahta kurekle kazilamiyor; o gorev yalnizca en zor dilimde.

	ODUL
	  XP     : easy 500, normal 1500, hard 3000, extreme 5000
	  Brainrot: KADEME GOREVI (collect) istedigi kademeden verir -- ustunden
	            DEGIL. "3 Epic topla" -> 1 Epic brainrot.
	            Kademesiz gorevler (kaz, sat, yerlestir, ac, fuse) zorluga
	            gore: easy Common, normal Rare, hard Epic, extreme Legendary.

	Coin sistemi kaldirildi; "Fuse ile X coin uret" gorevleri de kalkti.
	Fuse gorevi artik yalnizca makineyi calistirmayi sayar.
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
	-- Yalnizca "collect": sayilacak (ve odul olarak verilecek) kademe
	rarity: string?,
	target: number,
	difficulty: Difficulty,
	-- Ilerleme bildiriminde kullanilan kisa ad: "Rare Brainrots  3/10"
	short: string,
	-- Panelde gorunen tam metin
	text: string,
}

export type Reward = { rarity: string, count: number }

-- Zorluga gore XP
Gorevler.XP = {
	easy = 500,
	normal = 1500,
	hard = 3000,
	extreme = 5000,
} :: { [Difficulty]: number }

-- Kademesiz gorevlerin brainrot odulu
local Rewards: { [Difficulty]: Reward } = {
	easy = { rarity = "Common", count = 1 },
	normal = { rarity = "Rare", count = 1 },
	hard = { rarity = "Epic", count = 1 },
	extreme = { rarity = "Legendary", count = 1 },
}

local Pool: { QuestDef } = {
	-- KOLAY  --  birkac dakika
	{
		id = "dig15",
		kind = "dig",
		target = 15,
		difficulty = "easy",
		short = "Beams Dug",
		text = "Dig Up 15 Light Beams",
	},
	{
		id = "common10",
		kind = "collect",
		rarity = "Common",
		target = 10,
		difficulty = "easy",
		short = "Common Brainrots",
		text = "Collect 10 Common Brainrots",
	},
	{
		id = "sell8",
		kind = "sell",
		target = 8,
		difficulty = "easy",
		short = "Brainrots Sold",
		text = "Sell 8 Brainrots",
	},
	{
		id = "place3",
		kind = "place",
		target = 3,
		difficulty = "easy",
		short = "Brainrots Placed",
		text = "Place 3 Brainrots On Your Base",
	},

	-- NORMAL  --  yarim saatin bir kismi
	{
		id = "dig35",
		kind = "dig",
		target = 35,
		difficulty = "normal",
		short = "Beams Dug",
		text = "Dig Up 35 Light Beams",
	},
	{
		id = "rare8",
		kind = "collect",
		rarity = "Rare",
		target = 8,
		difficulty = "normal",
		short = "Rare Brainrots",
		text = "Collect 8 Rare Brainrots",
	},
	{
		id = "sell20",
		kind = "sell",
		target = 20,
		difficulty = "normal",
		short = "Brainrots Sold",
		text = "Sell 20 Brainrots",
	},
	{
		id = "place8",
		kind = "place",
		target = 8,
		difficulty = "normal",
		short = "Brainrots Placed",
		text = "Place 8 Brainrots On Your Base",
	},

	-- ZOR  --  yarim saatin cogu
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
		id = "dig60",
		kind = "dig",
		target = 60,
		difficulty = "hard",
		short = "Beams Dug",
		text = "Dig Up 60 Light Beams",
	},
	{
		--[[
			Lucky block nadir bir esya: tek blok isteniyor. Blogu olmayan
			oyuncu icin zor sayilir.
		]]
		id = "lucky1",
		kind = "lucky",
		target = 1,
		difficulty = "hard",
		short = "Lucky Blocks Opened",
		text = "Open A Lucky Block",
	},
	{
		id = "fuse1",
		kind = "fuse",
		target = 1,
		difficulty = "hard",
		short = "Fuses Done",
		text = "Use The Fuse Machine Once",
	},

	-- COK ZOR  --  tam yarim saatlik is
	{
		id = "legendary1",
		kind = "collect",
		rarity = "Legendary",
		target = 1,
		difficulty = "extreme",
		short = "Legendary Brainrots",
		text = "Collect A Legendary Brainrot",
	},
	{
		id = "epic6",
		kind = "collect",
		rarity = "Epic",
		target = 6,
		difficulty = "extreme",
		short = "Epic Brainrots",
		text = "Collect 6 Epic Brainrots",
	},
	{
		id = "rare20",
		kind = "collect",
		rarity = "Rare",
		target = 20,
		difficulty = "extreme",
		short = "Rare Brainrots",
		text = "Collect 20 Rare Brainrots",
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

-- Kademe gorevi kendi kademesini, digerleri zorluk odulunu verir
function Gorevler.reward(def: QuestDef): Reward
	if def.kind == "collect" and def.rarity then
		return { rarity = def.rarity, count = 1 }
	end
	return Rewards[def.difficulty]
end

function Gorevler.xp(def: QuestDef): number
	return Gorevler.XP[def.difficulty] or 0
end

--[[
	Odulun yazisi: "Epic Brainrot".

	TEK adette sayi YAZILMAZ; birden fazlaysa "2x Epic Brainrot".
]]
function Gorevler.rewardText(def: QuestDef): string
	local reward = Gorevler.reward(def)
	local ad = `{Rarity.displayName(reward.rarity)} Brainrot`
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
