--!strict

local Fonts = {}

local FACE = Font.fromEnum(Enum.Font.FredokaOne)

Fonts.bold = FACE
Fonts.medium = FACE
Fonts.regular = FACE

Fonts.Outline = {
	color = Color3.fromRGB(0, 0, 0),
	ratio = 0.1,
	min = 1.2,
	max = 4,
}

function Fonts.strokeThickness(textSize: number): number
	local o = Fonts.Outline
	return math.clamp(textSize * o.ratio, o.min, o.max)
end

function Fonts.applyOutline(label: TextLabel, thickness: number?): UIStroke
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Name = "Kontur"
	end

	local outline = stroke :: UIStroke
	outline.Color = Fonts.Outline.color
	outline.Thickness = thickness or Fonts.strokeThickness(label.TextSize)
	outline.Transparency = 0
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	outline.LineJoinMode = Enum.LineJoinMode.Round
	outline.Parent = label

	label.TextStrokeTransparency = 1

	return outline
end

function Fonts.applyGlow(label: TextLabel, color: Color3): UIGradient
	local existing = label:FindFirstChild("Parilti")
	if existing then
		existing:Destroy()
	end

	local bright = color:Lerp(Color3.new(1, 1, 1), 0.65)

	local gradient = Instance.new("UIGradient")
	gradient.Name = "Parilti"
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, bright),
		ColorSequenceKeypoint.new(0.5, color),
		ColorSequenceKeypoint.new(1, bright),
	})
	gradient.Parent = label

	label.TextColor3 = Color3.new(1, 1, 1)

	return gradient
end

function Fonts.clearGlow(label: TextLabel, color: Color3)
	local existing = label:FindFirstChild("Parilti")
	if existing then
		existing:Destroy()
	end
	label.TextColor3 = color
end

function Fonts.apply(label: TextLabel, thickness: number?): TextLabel
	label.FontFace = FACE
	Fonts.applyOutline(label, thickness)
	return label
end

return Fonts
