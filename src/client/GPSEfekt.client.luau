local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GPSEfekt = require(Shared:WaitForChild("GPSEfekt"))

local A = GPSEfekt.Antenna

type Entry = {
	character: Model,
	tool: Tool,
	billboard: BillboardGui,
	frame: Frame,
	stroke: UIStroke,
}

local entries: { [Model]: Entry } = {}

local function makeSignal(ball: BasePart): (BillboardGui, Frame, UIStroke)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "GPSSinyali"
	billboard.Adornee = ball
	billboard.Size = UDim2.fromOffset(A.size, A.size)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = A.maxDistance
	billboard.LightInfluence = 0
	billboard.Parent = ball

	local frame = Instance.new("Frame")
	frame.Name = "Halka"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(A.minScale, A.minScale)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = GPSEfekt.color
	stroke.Thickness = A.thickness
	stroke.Transparency = 1
	stroke.Parent = frame

	return billboard, frame, stroke
end

local function heldDetector(character: Model): Tool?
	for _, item in character:GetChildren() do
		if item:IsA("Tool") and item:GetAttribute("DetectorId") then
			return item
		end
	end
	return nil
end

local function stop(character: Model)
	local entry = entries[character]
	if not entry then
		return
	end
	entries[character] = nil

	if entry.billboard.Parent then
		entry.billboard:Destroy()
	end
end

local function start(character: Model, tool: Tool)
	if entries[character] then
		return
	end

	local ball = tool:FindFirstChild(GPSEfekt.BallName)
	if not ball or not ball:IsA("BasePart") then
		return
	end

	local billboard, frame, stroke = makeSignal(ball)

	entries[character] = {
		character = character,
		tool = tool,
		billboard = billboard,
		frame = frame,
		stroke = stroke,
	}
end

task.spawn(function()
	while true do
		task.wait(0.2)

		local alive: { [Model]: boolean } = {}

		for _, player in Players:GetPlayers() do
			local character = player.Character
			if not character then
				continue
			end

			local tool = heldDetector(character)
			if not tool then
				continue
			end

			alive[character] = true

			local entry = entries[character]
			if entry and entry.tool ~= tool then
				stop(character)
				entry = nil
			end

			if not entry then
				start(character, tool)
			end
		end

		for character in entries do
			if not alive[character] then
				stop(character)
			end
		end
	end
end)

local function lerp(from: number, to: number, alpha: number): number
	return from + (to - from) * alpha
end

local elapsed = 0

RunService.RenderStepped:Connect(function(dt)
	elapsed += dt

	local phase = GPSEfekt.phase(elapsed)

	for character, entry in entries do
		if not character.Parent or entry.tool.Parent ~= character then
			stop(character)
			continue
		end

		if not phase then
			entry.frame.Size = UDim2.fromScale(A.minScale, A.minScale)
			entry.stroke.Transparency = 1
			continue
		end

		local scale = lerp(A.minScale, 1, phase)
		entry.frame.Size = UDim2.fromScale(scale, scale)
		entry.stroke.Transparency = lerp(A.fadeFrom, A.fadeTo, phase)
	end
end)
