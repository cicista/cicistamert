--!strict

export type MutationId = "Normal" | "Gold" | "Lava" | "Diamond" | "Galaxy" | "Rainbow" | "Hacker"

export type MutationInfo = {
	id: MutationId,
	displayName: string,
	order: number,
	prefix: string,
	multiplier: number,
	chance: number,
	obtainable: boolean,
	color: Color3,
}

local CollectionService = game:GetService("CollectionService")

local Mutations = {}

Mutations.Order = { "Normal", "Gold", "Lava", "Diamond", "Galaxy", "Rainbow", "Hacker" } :: { MutationId }

Mutations.IndexOrder = { "Gold", "Diamond", "Galaxy", "Hacker" } :: { MutationId }

Mutations.Info = {
	Normal = {
		id = "Normal",
		displayName = "Normal",
		order = 1,
		prefix = "",
		multiplier = 1,
		chance = 89,
		obtainable = true,
		color = Color3.fromRGB(220, 220, 225),
	},

	Gold = {
		id = "Gold",
		displayName = "Gold",
		order = 2,
		prefix = "Gold ",
		multiplier = 3,
		chance = 7,
		obtainable = true,
		color = Color3.fromRGB(255, 200, 60),
	},

	Lava = {
		id = "Lava",
		displayName = "Lava",
		order = 3,
		prefix = "Lava ",
		multiplier = 6,
		chance = 0,
		obtainable = false,
		color = Color3.fromRGB(255, 95, 40),
	},

	Diamond = {
		id = "Diamond",
		displayName = "Diamond",
		order = 4,
		prefix = "Diamond ",
		multiplier = 5,
		chance = 3,
		obtainable = true,
		color = Color3.fromRGB(110, 230, 255),
	},

	Galaxy = {
		id = "Galaxy",
		displayName = "Galaxy",
		order = 5,
		prefix = "Galaxy ",
		multiplier = 8,
		chance = 1,
		obtainable = true,
		color = Color3.fromRGB(170, 110, 255),
	},

	Rainbow = {
		id = "Rainbow",
		displayName = "Rainbow",
		order = 6,
		prefix = "Rainbow ",
		multiplier = 10,
		chance = 0,
		obtainable = false,
		color = Color3.fromRGB(255, 120, 200),
	},

	Hacker = {
		id = "Hacker",
		displayName = "Hacker",
		order = 7,
		prefix = "Hacker ",
		multiplier = 12,
		chance = 0,
		obtainable = false,
		color = Color3.fromRGB(60, 255, 110),
	},
} :: { [MutationId]: MutationInfo }

export type Flash = {
	tag: string,
	colorA: Color3,
	colorB: Color3,
	interval: number,
}

local Flash: { [string]: Flash } = {
	Galaxy = {
		tag = "GalaksiRenk",
		colorA = Color3.fromRGB(170, 110, 255),
		colorB = Color3.fromRGB(255, 70, 210),
		interval = 0.06,
	},
	Hacker = {
		tag = "HackerRenk",
		colorA = Color3.fromRGB(60, 255, 110),
		colorB = Color3.fromRGB(255, 255, 255),
		interval = 0.06,
	},
}

Mutations.Flash = Flash

Mutations.Default = "Normal" :: MutationId

function Mutations.get(id: string?): MutationInfo
	local info = Mutations.Info[(id or Mutations.Default) :: MutationId]
	return info or Mutations.Info.Normal
end

function Mutations.color(id: string?): Color3
	return Mutations.get(id).color
end

function Mutations.multiplier(id: string?): number
	return Mutations.get(id).multiplier
end

function Mutations.isSpecial(id: string?): boolean
	return Mutations.get(id).id ~= "Normal"
end

function Mutations.roll(rng: Random): MutationId
	local roll = rng:NextNumber() * 100
	local cursor = 0

	for _, id in Mutations.Order do
		local info = Mutations.Info[id]
		if info.obtainable then
			cursor += info.chance
			if roll <= cursor then
				return id
			end
		end
	end

	return Mutations.Default
end

function Mutations.flash(id: string?): Flash?
	return if id then Flash[id] else nil
end

function Mutations.flashColorAt(flash: Flash, clock: number): Color3
	local step = math.floor(clock / math.max(flash.interval, 1 / 240))
	return if step % 2 == 0 then flash.colorA else flash.colorB
end

function Mutations.tagIf(instance: Instance, id: string?)
	local flash = Mutations.flash(id)
	if flash and not CollectionService:HasTag(instance, flash.tag) then
		CollectionService:AddTag(instance, flash.tag)
	end
end

function Mutations.untag(instance: Instance)
	for _, flash in Flash do
		CollectionService:RemoveTag(instance, flash.tag)
	end
end

return Mutations
