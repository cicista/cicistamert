local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Icons = require(Shared:WaitForChild("Icons"))
local Net = require(Shared:WaitForChild("Net"))

local UI = require(script.Parent:WaitForChild("UI"))

local GPSGuncelle = Net.event("GPSGuncelle")
local SuzmeKaz = Net.event("SuzmeKaz")

local DIG_ACTION = "SuzmeKazEylemi"
local G = Config.GPS

local screen = Instance.new("ScreenGui")
screen.Name = "BrainrotGPS"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Enabled = true
screen.Parent = playerGui

local hint = Instance.new("Frame")
hint.Name = "KaziIpucu"
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -110)
hint.Size = UDim2.fromOffset(310, 44)
hint.BackgroundColor3 = UI.Colors.panel
hint.BackgroundTransparency = 0.1
hint.BorderSizePixel = 0
hint.Visible = false
hint.Parent = screen
UI.corner(hint, 12)

local hintStroke = UI.stroke(hint, UI.Colors.good, 2)

local hintLabel = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = hint,
})

local hintIkon = Instance.new("ImageLabel")
hintIkon.Name = "MadenIkonu"
hintIkon.AnchorPoint = Vector2.new(0, 0.5)
hintIkon.Position = UDim2.new(0, 10, 0.5, 0)
hintIkon.Size = UDim2.fromOffset(28, 28)
hintIkon.BackgroundTransparency = 1
hintIkon.ScaleType = Enum.ScaleType.Fit
hintIkon.Visible = false
hintIkon.Parent = hint

local labelFolder = Instance.new("Folder")
labelFolder.Name = "GPSEtiketleri"
labelFolder.Parent = playerGui

local labels: { [string]: BillboardGui } = {}
local beams: { { id: string, kind: string, position: Vector3 } } = {}
local nearest: { id: string, distance: number }? = nil

local function kindColor(kind: string): Color3
	return Rarity.beamColor(kind)
end

local function kindName(kind: string): string
	return string.upper(Rarity.beamName(kind))
end

local function makeLabel(beam: { id: string, kind: string, position: Vector3 }): BillboardGui
	local anchor = Instance.new("Part")
	anchor.Name = `GPSAnchor_{beam.id}`
	anchor.Size = Vector3.one
	anchor.Position = beam.position + Vector3.new(0, 16, 0)
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Parent = Workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Name = `GPSLabel_{beam.id}`
	billboard.Adornee = anchor
	billboard.Size = UDim2.fromOffset(130, 34)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = G.scanRadius + 20
	billboard.Parent = labelFolder

	billboard.Destroying:Connect(function()
		if anchor.Parent then
			anchor:Destroy()
		end
	end)

	local color = kindColor(beam.kind)

	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
	card.BackgroundTransparency = 0.25
	card.BorderSizePixel = 0
	card.Parent = billboard
	UI.corner(card, 10)
	UI.stroke(card, color, 2)

	local kindLabel = UI.text({
		text = kindName(beam.kind),
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = color,
		align = Enum.TextXAlignment.Center,
		alignY = Enum.TextYAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = card,
		name = "Kind",
	})

	if Rarity.Info[beam.kind] then
		UI.rarityStyle(kindLabel, beam.kind)
	end

	return billboard
end

local function digNearest()
	if not nearest then
		return
	end
	SuzmeKaz:FireServer(nearest.id)
end

ContextActionService:BindAction(DIG_ACTION, function(_, state)
	if state == Enum.UserInputState.Begin then
		digNearest()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.KeyCode.ButtonX)

hint.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		digNearest()
	end
end)

GPSGuncelle.OnClientEvent:Connect(function(list)
	beams = list or {}

	local alive: { [string]: boolean } = {}
	for _, beam in beams do
		alive[beam.id] = false
	end

	for id, billboard in labels do
		if not alive[id] then
			billboard:Destroy()
			labels[id] = nil
		end
	end

end)

task.spawn(function()
	while true do
		task.wait(0.15)

		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			nearest = nil
			hint.Visible = false
			continue
		end

		local best: { id: string, distance: number, kind: string, sea: boolean }? = nil

		for _, beam in beams do
			local distance = (beam.position - root.Position).Magnitude

			if not best or distance < best.distance then
				best = { id = beam.id, distance = distance, kind = beam.kind, sea = beam.sea == true }
			end
		end

		local erisim = if best and best.sea then G.seaDigDistance else G.digDistance

		if best and best.distance <= erisim then
			nearest = { id = best.id, distance = best.distance }

			local color = kindColor(best.kind)
			hintStroke.Color = color
			hintLabel.TextColor3 = color

			local madenAnahtari = `ore_{best.kind}`
			local madenMi = Icons.Map[madenAnahtari] ~= nil
			if madenMi then
				Icons.bind(hintIkon, madenAnahtari)
			end
			hintIkon.Visible = madenMi
			hintLabel.Position = UDim2.fromOffset(if madenMi then 16 else 0, 0)

			local eylem = if best.sea then "fish" else "dig"
			hintLabel.Text = if UserInputService.TouchEnabled
				then `{kindName(best.kind)} - tap to {eylem}`
				else `{kindName(best.kind)} - click to {eylem}`
			hint.Visible = true
		else
			nearest = nil
			hint.Visible = false
		end
	end
end)

Players.LocalPlayer.CharacterRemoving:Connect(function()
	hint.Visible = false
end)
