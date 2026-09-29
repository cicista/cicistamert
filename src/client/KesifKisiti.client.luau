local Players = game:GetService("Players")

local player = Players.LocalPlayer

local KESIF_NITELIGI = "KesifKisiti"

local function kesifAraciMi(tool: Tool): boolean
	return tool:GetAttribute("ShovelId") ~= nil
		or tool:GetAttribute("DetectorId") ~= nil
		or tool:GetAttribute("PickaxeId") ~= nil
		or tool:GetAttribute("RodId") ~= nil
end

local function denetle(character: Model, child: Instance)
	if not child:IsA("Tool") then
		return
	end

	if not player:GetAttribute(KESIF_NITELIGI) then
		return
	end

	if kesifAraciMi(child :: Tool) then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:UnequipTools()
	end
end

local function karakteriBagla(character: Model)
	character.ChildAdded:Connect(function(child)
		denetle(character, child)
	end)

	for _, child in character:GetChildren() do
		denetle(character, child)
	end
end

player.CharacterAdded:Connect(karakteriBagla)

if player.Character then
	karakteriBagla(player.Character)
end
