--!strict
--[[
	GUNLUK ODUL

	Her 24 saatte bir hediye carki cevrilir. Carkta dort odul var:

	  luck        30 dakikalik sans carpani (kazida daha iyi suzme cikar)
	  brainrot    dogrudan envantere giren ACILMIS brainrot
	  luckyblock  bir Lucky Block (istedigin zaman acarsin)
	  skin        sahip olmadigin bir kurek/GPS skini

	Sure sunucu saatiyle (os.time) tutulur, oyundan cikmak sayaci sifirlamaz.
]]

local LuckyBlock = require(script.Parent.LuckyBlock)

local Rewards = {}

-- Iki odul arasi bekleme (saniye). 86400 = 24 saat
Rewards.cooldown = 86400

--[[
	Sans odulu: verilen sure boyunca kazidaki sans carpanini yukseltir.
	Zemin ve dedektor carpanlariyla CARPILIR, yani en iyi kurulumda etkisi
	daha da buyuk olur.
]]
Rewards.luckBoost = {
	multiplier = 2,
	-- Saniye (1800 = 30 dakika)
	duration = 1800,
}

-- Skin odulunde oyuncunun sahip olmadigi bir skin verilir; hepsi doluysa
-- bunun yerine asagidaki tur Lucky Block verilir.
Rewards.skinFallbackTier = "Normal"

--[[
	Carkin odulleri. weight = agirlik (toplamlarinin 100 olmasi gerekmez).
	Bir odulu kaldirmak istersen agirligini 0 yap.
]]
export type Prize = {
	id: string,
	label: string,
	weight: number,
	color: Color3,
}

Rewards.Prizes = {
	{
		id = "brainrot",
		label = "BRAINROT",
		weight = 34,
		color = Color3.fromRGB(180, 100, 255),
	},
	{
		id = "luck",
		label = "30 MIN LUCK",
		weight = 30,
		color = Color3.fromRGB(120, 226, 150),
	},
	{
		id = "luckyblock",
		label = "LUCKY BLOCK",
		weight = 24,
		color = Color3.fromRGB(255, 236, 90),
	},
	{
		id = "skin",
		label = "SKIN",
		weight = 12,
		color = Color3.fromRGB(90, 180, 255),
	},
} :: { Prize }

-- Cark gorunumu (Lucky Block carkiyla ayni mantik)
Rewards.Wheel = {
	cellCount = 40,
	winnerIndex = 33,
	spinTime = 3.2,
	-- Cark durduktan sonra odulun verilmesi icin beklenen ek sure
	settle = 0.4,
}

function Rewards.totalSpinTime(): number
	return Rewards.Wheel.spinTime + Rewards.Wheel.settle
end

local byId: { [string]: Prize } = {}
for _, prize in Rewards.Prizes do
	byId[prize.id] = prize
end

function Rewards.get(id: string): Prize?
	return byId[id]
end

-- Carkin duracagi odulu secer
function Rewards.roll(rng: Random): Prize
	local total = 0
	for _, prize in Rewards.Prizes do
		total += math.max(0, prize.weight)
	end

	if total <= 0 then
		return Rewards.Prizes[1]
	end

	local roll = rng:NextNumber() * total
	local cursor = 0
	for _, prize in Rewards.Prizes do
		cursor += math.max(0, prize.weight)
		if roll <= cursor then
			return prize
		end
	end

	return Rewards.Prizes[#Rewards.Prizes]
end

--[[
	Brainrot odulunde hangi kademe cikacagi.
	Lucky Block'un Normal tur tablosu kullaniliyor: Common yok, cogu Epic.
]]
function Rewards.rollBrainrotRarity(rng: Random): string
	return LuckyBlock.rollRarity("Normal", rng)
end

-- Kalan sureyi "5s 12dk" gibi okunur yaziya cevirir
function Rewards.formatRemaining(seconds: number): string
	local total = math.max(0, math.floor(seconds))
	local hours = math.floor(total / 3600)
	local minutes = math.floor((total % 3600) / 60)
	local secs = total % 60

	if hours > 0 then
		return `{hours}h {minutes}m`
	end
	if minutes > 0 then
		return `{minutes}m {secs}s`
	end
	return `{secs}s`
end

return Rewards
