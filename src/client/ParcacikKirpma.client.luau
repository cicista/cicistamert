--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig")) :: any

local P = Config.Performans
local NITELIK = "UzaktaKapali"

type Kayit = { mesafe: number, rate: number, yari: boolean }

local yayicilar: { [ParticleEmitter]: Kayit } = {}
local baglananKokler: { [Instance]: boolean } = {}

local function ekle(node: Instance, mesafe: number)
	if node:IsA("ParticleEmitter") and not yayicilar[node] then
		yayicilar[node] = { mesafe = mesafe, rate = node.Rate, yari = false }
	end
end

local function kokBul(yol: { string }): Instance?
	local node: Instance? = Workspace
	for _, ad in yol do
		node = if node then node:FindFirstChild(ad) else nil
	end
	return node
end

local function kokleriBagla()
	for _, tanim in P.parcacikKokleri do
		local kok = kokBul(tanim.yol)
		if kok and not baglananKokler[kok] then
			baglananKokler[kok] = true
			for _, node in kok:GetDescendants() do
				ekle(node, tanim.mesafe)
			end
			kok.DescendantAdded:Connect(function(node)
				ekle(node, tanim.mesafe)
			end)
			kok.Destroying:Connect(function()
				baglananKokler[kok] = nil
			end)
		end
	end
end

local function konumu(yayici: ParticleEmitter): Vector3?
	local ebeveyn = yayici.Parent
	if ebeveyn and ebeveyn:IsA("BasePart") then
		return ebeveyn.Position
	elseif ebeveyn and ebeveyn:IsA("Attachment") then
		return ebeveyn.WorldPosition
	end
	return nil
end

local function kirp()
	local kamera = Workspace.CurrentCamera
	if not kamera then
		return
	end
	local goz = kamera.CFrame.Position

	for yayici, kayit in yayicilar do
		if not yayici.Parent then
			yayicilar[yayici] = nil
			continue
		end

		local konum = konumu(yayici)
		if not konum then
			continue
		end

		local mesafe = (konum - goz).Magnitude
		local uzak = mesafe > kayit.mesafe

		local yari = not uzak and mesafe > kayit.mesafe * P.parcacikYariOran
		if yari ~= kayit.yari then
			kayit.yari = yari
			yayici.Rate = if yari then kayit.rate * 0.5 else kayit.rate
		end

		if uzak then
			if yayici.Enabled then
				yayici.Enabled = false
				yayici:SetAttribute(NITELIK, true)
			end
		elseif yayici:GetAttribute(NITELIK) then
			yayici:SetAttribute(NITELIK, nil)
			yayici.Enabled = true
		end
	end
end

kokleriBagla()

task.spawn(function()
	local sonArama = os.clock()
	while true do
		task.wait(P.parcacikAraligi)
		if os.clock() - sonArama >= P.kokAramaAraligi then
			sonArama = os.clock()
			kokleriBagla()
		end
		kirp()
	end
end)
