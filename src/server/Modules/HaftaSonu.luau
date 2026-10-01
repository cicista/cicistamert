--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("HaftaSonu"))

local HaftaSonu = {}

local testBitis = 0

function HaftaSonu.bitis(): number
	local simdi = os.time()
	local bitis = Ayar.dogalBitis(simdi)
	if testBitis > simdi then
		bitis = math.max(bitis, testBitis)
	end
	return if bitis > simdi then bitis else 0
end

function HaftaSonu.aktif(): boolean
	return HaftaSonu.bitis() > 0
end

function HaftaSonu.carpan(): number
	return if HaftaSonu.aktif() then Ayar.SansCarpani else 1
end

local function yayinla()
	Workspace:SetAttribute(Ayar.Nitelik, HaftaSonu.bitis())
end

function HaftaSonu.testBaslat()
	testBitis = os.time() + Ayar.Sure
	yayinla()
end

function HaftaSonu.testDurdur()
	testBitis = 0
	yayinla()
end

yayinla()
task.spawn(function()
	while true do
		task.wait(1)
		yayinla()
	end
end)

return HaftaSonu
