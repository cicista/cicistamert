local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Divine = require(Shared:WaitForChild("Divine"))
local Mutations = require(Shared:WaitForChild("Mutations"))

local function bandliGecis(color: Color3, parlak: Color3, yer: number, yari: number): ColorSequence
	local duraklar = {}
	local sol = math.clamp(yer - yari, 0, 1)
	local sag = math.clamp(yer + yari, 0, 1)

	table.insert(duraklar, ColorSequenceKeypoint.new(0, if sol <= 0 then parlak else color))

	if sol > 0 then
		table.insert(duraklar, ColorSequenceKeypoint.new(sol, color))
	end

	if yer > 0 and yer < 1 then
		table.insert(duraklar, ColorSequenceKeypoint.new(yer, parlak))
	end

	if sag < 1 then
		table.insert(duraklar, ColorSequenceKeypoint.new(sag, color))
	end

	table.insert(duraklar, ColorSequenceKeypoint.new(1, if sag >= 1 then parlak else color))

	return ColorSequence.new(duraklar)
end

local function paint(instance: Instance, color: Color3, yer: number?, yari: number?)
	if instance:IsA("TextLabel") or instance:IsA("TextButton") then
		local gradient = instance:FindFirstChild("Parilti")

		if gradient and gradient:IsA("UIGradient") then
			local parlak = color:Lerp(Color3.new(1, 1, 1), 0.55)
			gradient.Offset = Vector2.zero
			gradient.Color = bandliGecis(color, parlak, yer or 0.5, yari or 0.12)
			instance.TextColor3 = Color3.new(1, 1, 1)
		else
			instance.TextColor3 = color
		end
	elseif instance:IsA("BasePart") then
		instance.Color = color
	elseif instance:IsA("UIStroke") then
		instance.Color = color
	elseif instance:IsA("Light") then
		instance.Color = color
	elseif instance:IsA("ParticleEmitter") then
		instance.Color = ColorSequence.new(color)
	elseif instance:IsA("Highlight") then
		instance.OutlineColor = color
	elseif instance:IsA("UIGradient") then
		instance.Color = ColorSequence.new(color)
	elseif instance:IsA("Frame") then
		instance.BackgroundColor3 = color
	elseif instance:IsA("GuiObject") then
		instance.BackgroundColor3 = color
	end
end

type Palet = {
	colorA: Color3,
	colorB: Color3,
	interval: number,
	sweep: number,
	band: number,
	tracked: { [Instance]: boolean },
}

local paletler: { Palet } = {}

local function paletEkle(tag: string, colorA: Color3, colorB: Color3, interval: number, sweep: number?, band: number?)
	local palet: Palet = {
		colorA = colorA,
		colorB = colorB,
		interval = interval,
		sweep = sweep or 1.6,
		band = band or 0.12,
		tracked = {},
	}

	for _, instance in CollectionService:GetTagged(tag) do
		palet.tracked[instance] = true
	end

	CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		palet.tracked[instance] = true
	end)

	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
		palet.tracked[instance] = nil
	end)

	table.insert(paletler, palet)
end

for _, flash in Divine.Flashes do
	paletEkle(flash.tag, flash.colorA, flash.colorB, flash.interval, flash.sweep, flash.band)
end

for _, flash in Mutations.Flash do
	paletEkle(flash.tag, flash.colorA, flash.colorB, flash.interval, flash.sweep, flash.band)
end

local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
	elapsed += dt

	for _, palet in paletler do
		local faz = elapsed / math.max(palet.interval, 1 / 240) * math.pi
		local dalga = (math.sin(faz) + 1) / 2
		local oran = dalga ^ 4 * 0.85
		local color = palet.colorA:Lerp(palet.colorB, oran)

		local tur = (elapsed / palet.sweep) % 1
		local yer = -palet.band + tur * (1 + palet.band * 2)

		for instance in palet.tracked do
			if not instance.Parent then
				palet.tracked[instance] = nil
				continue
			end

			paint(instance, color, yer, palet.band)
		end
	end
end)
