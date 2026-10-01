local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OyunConfig")) :: any

local DONME_MESAFESI = Config.Performans.baseDonmeMesafesi

type Entry = {
	model: Model,
	home: CFrame,
	pivot: CFrame,
	spin: boolean,
	spinSpeed: number,
	bobHeight: number,
	bobSpeed: number,
	time: number,
	rainbow: Highlight?,
}

local entries: { [Model]: Entry } = {}

local function track(model: Model)
	if entries[model] then
		return
	end

	local home = model:GetAttribute("SpinHome")
	local pivot = model:GetAttribute("SpinPivot")

	if typeof(home) ~= "CFrame" or typeof(pivot) ~= "CFrame" then
		return
	end

	entries[model] = {
		model = model,
		home = home,
		pivot = pivot,
		spin = model:GetAttribute("SpinEnabled") ~= false,
		spinSpeed = (model:GetAttribute("SpinSpeed") :: number?) or 0.8,
		bobHeight = (model:GetAttribute("BobHeight") :: number?) or 0,
		bobSpeed = (model:GetAttribute("BobSpeed") :: number?) or 1.6,
		time = math.random() * 10,
		rainbow = nil,
	}

	if model:GetAttribute("Mutation") == "Rainbow" then
		local highlight = Instance.new("Highlight")
		highlight.Name = "RainbowEfekt"
		highlight.FillTransparency = 0.88
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Adornee = model
		highlight.Parent = model

		entries[model].rainbow = highlight
	end
end

local function untrack(model: Model)
	entries[model] = nil
end

local function watch(instance: Instance)
	if not instance:IsA("Model") then
		return
	end

	if instance:GetAttribute("SpinDisplay") then
		track(instance)
	end

	instance:GetAttributeChangedSignal("SpinDisplay"):Connect(function()
		if instance:GetAttribute("SpinDisplay") then
			track(instance)
		else
			untrack(instance)
		end
	end)

	instance:GetAttributeChangedSignal("SpinHome"):Connect(function()
		untrack(instance)
		if instance:GetAttribute("SpinDisplay") then
			track(instance)
		end
	end)
end

for _, instance in Workspace:GetDescendants() do
	watch(instance)
end

Workspace.DescendantAdded:Connect(watch)

Workspace.DescendantRemoving:Connect(function(instance)
	if instance:IsA("Model") then
		untrack(instance)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	local kamera = Workspace.CurrentCamera
	local goz = if kamera then kamera.CFrame.Position else nil

	for model, entry in entries do
		if not model.Parent then
			entries[model] = nil
			continue
		end

		entry.time += dt

		if goz and (entry.pivot.Position - goz).Magnitude > DONME_MESAFESI then
			continue
		end

		local lift = if entry.bobHeight > 0
			then (math.sin(entry.time * entry.bobSpeed) * 0.5 + 0.5) * entry.bobHeight
			else 0

		local angle = if entry.spin then entry.time * entry.spinSpeed else 0

		local offset = CFrame.new(entry.pivot.Position + Vector3.new(0, lift, 0))
			* CFrame.Angles(0, angle, 0)
			* CFrame.new(-entry.pivot.Position)

		model:PivotTo(offset * entry.home)

		if entry.rainbow then
			entry.rainbow.FillColor = Color3.fromHSV((entry.time * 0.2) % 1, 0.85, 1)
			entry.rainbow.OutlineColor = Color3.fromHSV((entry.time * 0.2 + 0.5) % 1, 0.9, 1)
		end
	end
end)
