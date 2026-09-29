local Players = game:GetService("Players")

local KALDIRILACAK_TURLER = {
	[Enum.AccessoryType.Back] = true,
	[Enum.AccessoryType.Shoulder] = true,
	[Enum.AccessoryType.Waist] = true,
	[Enum.AccessoryType.Front] = true,
}

local KALDIRILACAK_NOKTALAR = {
	BodyBackAttachment = true,
	BodyFrontAttachment = true,
	LeftShoulderAttachment = true,
	RightShoulderAttachment = true,
	LeftCollarAttachment = true,
	RightCollarAttachment = true,
	WaistBackAttachment = true,
	WaistFrontAttachment = true,
	WaistCenterAttachment = true,
}

local function kaldirilacakMi(aksesuar: Accessory): boolean
	if KALDIRILACAK_TURLER[aksesuar.AccessoryType] then
		return true
	end

	local handle = aksesuar:FindFirstChild("Handle")
	if not handle then
		return false
	end

	for _, child in handle:GetChildren() do
		if child:IsA("Attachment") and KALDIRILACAK_NOKTALAR[child.Name] then
			return true
		end
	end

	return false
end

local function denetle(node: Instance)
	if node:IsA("Accessory") and kaldirilacakMi(node) then
		task.defer(function()
			if node.Parent then
				node:Destroy()
			end
		end)
	end
end

local function karakterGeldi(character: Model)
	character.ChildAdded:Connect(denetle)

	for _, child in character:GetChildren() do
		denetle(child)
	end
end

local function oyuncuGeldi(player: Player)
	player.CharacterAdded:Connect(karakterGeldi)

	player.CharacterAppearanceLoaded:Connect(function(character)
		for _, child in character:GetChildren() do
			denetle(child)
		end
	end)

	if player.Character then
		karakterGeldi(player.Character)
	end
end

Players.PlayerAdded:Connect(oyuncuGeldi)

for _, player in Players:GetPlayers() do
	oyuncuGeldi(player)
end
