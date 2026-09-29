--!strict

local CollectionService = game:GetService("CollectionService")

local Divine = {}

Divine.Tag = "IlahiRenk"

Divine.colorA = Color3.fromRGB(255, 232, 90)
Divine.colorB = Color3.fromRGB(255, 255, 255)
Divine.interval = 0.5

Divine.panelColor = Color3.fromRGB(255, 240, 150)

function Divine.colorAt(clock: number): Color3
	local step = math.floor(clock / math.max(Divine.interval, 1 / 240))
	return if step % 2 == 0 then Divine.colorA else Divine.colorB
end

function Divine.tag(instance: Instance)
	if not CollectionService:HasTag(instance, Divine.Tag) then
		CollectionService:AddTag(instance, Divine.Tag)
	end
end

function Divine.untag(instance: Instance)
	for _, parilti in Divine.Flashes do
		CollectionService:RemoveTag(instance, parilti.tag)
	end
end

export type Parilti = {
	tag: string,
	colorA: Color3,
	colorB: Color3,
	interval: number,
	sweep: number,
	band: number,
}

Divine.Flashes = {
	Secret = {
		tag = Divine.Tag,
		colorA = Divine.colorA,
		colorB = Divine.colorB,
		interval = Divine.interval,
		sweep = 1.30,
		band = 0.14,
	},

	Cosmic = {
		tag = "KozmikRenk",
		colorA = Color3.fromRGB(138, 43, 226),
		colorB = Color3.fromRGB(255, 255, 255),
		interval = 0.42,
		sweep = 1.00,
		band = 0.11,
	},

	Gizli = {
		tag = "GizliRenk",
		colorA = Color3.fromRGB(245, 245, 250),
		colorB = Color3.fromRGB(14, 14, 16),
		interval = 0.34,
		sweep = 0.78,
		band = 0.085,
	},

	Infernal = {
		tag = "InfernalRenk",
		colorA = Color3.fromRGB(255, 92, 12),
		colorB = Color3.fromRGB(255, 255, 255),
		interval = 0.26,
		sweep = 0.58,
		band = 0.065,
	},

	Abyssal = {
		tag = "AbyssalRenk",
		colorA = Color3.fromRGB(8, 52, 130),
		colorB = Color3.fromRGB(255, 255, 255),
		interval = 0.18,
		sweep = 0.40,
		band = 0.045,
	},
} :: { [string]: Parilti }

function Divine.tagIf(instance: Instance, rarityId: string?)
	local parilti = if rarityId then Divine.Flashes[rarityId] else nil
	if not parilti then
		return
	end

	if not CollectionService:HasTag(instance, parilti.tag) then
		CollectionService:AddTag(instance, parilti.tag)
	end
end

return Divine
