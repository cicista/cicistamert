local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))

local W = Config.WhirlVFX
local TAG = W.spinTag

type Kayit = { taban: CFrame, aci: number }
local kayitlar: { [Model]: Kayit } = {}

local function ekle(node: Instance)
	if not node:IsA("Model") then
		return
	end

	local model = node :: Model

	task.defer(function()
		if not model.Parent then
			return
		end

		local ok, pivot = pcall(function()
			return model:GetPivot()
		end)
		if not ok then
			return
		end

		kayitlar[model] = { taban = pivot, aci = 0 }
	end)
end

local function cikar(node: Instance)
	if node:IsA("Model") then
		kayitlar[node :: Model] = nil
	end
end

for _, node in CollectionService:GetTagged(TAG) do
	ekle(node)
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(ekle)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(cikar)

RunService.RenderStepped:Connect(function(dt)
	for model, kayit in kayitlar do
		if not model.Parent then
			kayitlar[model] = nil
			continue
		end

		local hiz = model:GetAttribute("DonusHizi") or W.spin
		kayit.aci = (kayit.aci + math.rad(hiz) * dt) % (math.pi * 2)

		model:PivotTo(kayit.taban * CFrame.Angles(0, kayit.aci, 0))
	end
end)
