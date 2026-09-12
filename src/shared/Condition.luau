--!strict
--[[
	Brainrot BOYUTU -- rarity ve mutasyondan bagimsiz ikinci stat.

	Kucukten buyuge: Tiny -> Small -> Normal -> Large -> Huge

	Iki sey belirler:
	  scale      -> modelin kendi boyunun kac kati gorunecegi
	                (Tiny = ceyregi, Huge = iki kati)
	  multiplier -> saniyelik geliri kac katina cikardigi (1x .. 3x)

	Pasif gelir = rarity tabani * boyut carpani * mutasyon carpani

	Tanimadigi bir kimlik gelirse (bozuk ya da cok eski kayit) hataya
	donusmez, varsayilan boyuta duser.
]]

export type ConditionId = "Tiny" | "Small" | "Normal" | "Large" | "Huge"

export type ConditionInfo = {
	id: ConditionId,
	shortName: string,
	displayName: string,
	order: number,
	-- Modelin kendi boyuna gore olcek
	scale: number,
	-- Gelir carpani
	multiplier: number,
	-- Kazidan bu boyutun cikma sansi (yuzde, toplam 100)
	chance: number,
	color: Color3,
}

local Condition = {}

Condition.Order = { "Tiny", "Small", "Normal", "Large", "Huge" } :: { ConditionId }

Condition.Info = {
	Tiny = {
		id = "Tiny",
		shortName = "Tiny",
		displayName = "Tiny",
		order = 1,
		scale = 0.25,
		multiplier = 1,
		chance = 32,
		color = Color3.fromRGB(150, 92, 76),
	},

	Small = {
		id = "Small",
		shortName = "Small",
		displayName = "Small",
		order = 2,
		scale = 0.6,
		multiplier = 1.5,
		chance = 24,
		color = Color3.fromRGB(184, 148, 84),
	},

	Normal = {
		id = "Normal",
		shortName = "Regular",
		displayName = "Regular",
		order = 3,
		scale = 1,
		multiplier = 2,
		chance = 30,
		color = Color3.fromRGB(196, 196, 108),
	},

	Large = {
		id = "Large",
		shortName = "Large",
		displayName = "Large",
		order = 4,
		scale = 1.4,
		multiplier = 2.5,
		chance = 11,
		color = Color3.fromRGB(120, 200, 140),
	},

	Huge = {
		id = "Huge",
		shortName = "Huge",
		displayName = "Huge",
		order = 5,
		scale = 2,
		multiplier = 3,
		chance = 3,
		color = Color3.fromRGB(96, 208, 232),
	},
} :: { [ConditionId]: ConditionInfo }

Condition.Default = "Normal" :: ConditionId

--[[
	Kimligi cozer. Bilinmeyen deger hataya donusmez, varsayilana duser.
]]
function Condition.get(id: string?): ConditionInfo
	if id then
		local direct = Condition.Info[id :: ConditionId]
		if direct then
			return direct
		end
	end

	return Condition.Info[Condition.Default]
end

function Condition.scale(id: string?): number
	return Condition.get(id).scale
end

--[[
	KADEMEYE GORE BOYUT SINIFI OLCEGI

	Cosmic SONRASI kademelerde (Secret, Infernal, Abyssal) en kucuk sinif
	artik kucuk degil: Tiny, Regular ile AYNI boyda duruyor ve ustu oradan
	buyuyerek devam ediyor.

	    sinif      normal   Cosmic sonrasi
	    Tiny        0.25        1.0
	    Small       0.60        1.2
	    Regular     1.00        1.5
	    Large       1.40        1.8
	    Huge        2.00        2.2

	Sebep: o kademelerdeki bir brainrotun Tiny cikmasi onu degersiz
	gostermemeli; kademe zaten nadir, en kucugu bile heybetli dursun.

	Kademe verilmezse normal olcek doner -- eski cagrilar bozulmuyor.
]]
local USTUN_OLCEK: { [string]: number } = {
	Tiny = 1.0,
	Small = 1.2,
	Normal = 1.5,
	Large = 1.8,
	Huge = 2.2,
}

function Condition.scaleFor(id: string?, rarityOrder: number?): number
	if rarityOrder and rarityOrder >= 8 then
		return USTUN_OLCEK[Condition.get(id).id] or Condition.scale(id)
	end

	return Condition.scale(id)
end

function Condition.multiplier(id: string?): number
	return Condition.get(id).multiplier
end

function Condition.roll(rng: Random): ConditionId
	local roll = rng:NextNumber() * 100
	local cursor = 0

	for _, id in Condition.Order do
		cursor += Condition.Info[id].chance
		if roll <= cursor then
			return id
		end
	end

	return Condition.Default
end

return Condition
