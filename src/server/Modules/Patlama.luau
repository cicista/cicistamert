--!strict

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Fuse = require(Shared:WaitForChild("Fuse"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local Patlama = {}

local function bodyOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

function Patlama.oynat(player: Player, rarityId: string, sesli: boolean?, renk: Color3?)
	local cfg = Fuse.VFX

	local root = bodyOf(player)
	if not root then
		return
	end

	if sesli ~= false then
		Assets.playSoundAt(cfg.explosion, root)
	end

	local template = Assets.vfxTemplate(cfg.name)
	if not template then
		return
	end

	template.Name = `{cfg.name}_Patlama`

	Assets.tintEffects(template, renk or Rarity.color(rarityId), cfg.preserveShading)
	Assets.scaleEffects(template, cfg.scaleByRarity[rarityId] or 1)

	local origin = root.CFrame * CFrame.new(0, cfg.height, 0)

	local function weldToBody(part: BasePart)
		part.Anchored = false
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
	end

	template.Parent = Workspace

	if template:IsA("BasePart") then
		template.CFrame = origin
		weldToBody(template)
	elseif template:IsA("Model") then
		template:PivotTo(origin)
		for _, part in template:GetDescendants() do
			if part:IsA("BasePart") then
				weldToBody(part)
			end
		end
	end

	Assets.playBurst(template, cfg.burst)

	for _, node in template:GetDescendants() do
		if node:IsA("Light") then
			TweenService:Create(node, TweenInfo.new(cfg.stopAfter), { Brightness = 0 }):Play()
		end
	end

	task.delay(cfg.stopAfter, function()
		if template.Parent then
			Assets.stopEmitters(template)
		end
	end)

	Debris:AddItem(template, cfg.lifetime)
end

return Patlama
