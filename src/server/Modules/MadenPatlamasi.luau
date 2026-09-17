--!strict
--[[
	MADEN PATLAMASI  --  sunucu tarafi

	Maden damari kirilinca madenin renginde (Shared > Ores > GemColors)
	kucuk taslar etrafa sacilir ve Workspace'teki "FuseExplosion" sesi
	calar. Taslar birkac saniye sonra kendiliginden silinir.

	    MadenPatlamasi.oynat(konum, renk)
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))

local MadenPatlamasi = {}

local TAS_SAYISI = 16
local TAS_OMRU = 2.5
local SES_ADLARI = { "FuseExplosion" }

local rng = Random.new()

function MadenPatlamasi.oynat(konum: Vector3, renk: Color3)
	local merkez = konum + Vector3.new(0, 1.5, 0)

	-- Sesin calacagi gorunmez tutamak
	local tutamak = Instance.new("Part")
	tutamak.Name = "MadenPatlamaSesi"
	tutamak.Anchored = true
	tutamak.CanCollide = false
	tutamak.CanQuery = false
	tutamak.CanTouch = false
	tutamak.Transparency = 1
	tutamak.Size = Vector3.new(0.2, 0.2, 0.2)
	tutamak.CFrame = CFrame.new(merkez)
	tutamak.Parent = Workspace
	Debris:AddItem(tutamak, 6)
	Assets.playSoundAt(SES_ADLARI, tutamak, 6)

	for _ = 1, TAS_SAYISI do
		local boy = rng:NextNumber(0.3, 0.75)
		local tas = Instance.new("Part")
		tas.Name = "MadenTasi"
		tas.Size = Vector3.new(boy, boy * rng:NextNumber(0.6, 1), boy * rng:NextNumber(0.7, 1.1))
		-- Tonu biraz oynat: hepsi birebir ayni renk olmasin
		tas.Color = renk:Lerp(Color3.new(1, 1, 1), rng:NextNumber(0, 0.25))
		tas.Material = if rng:NextNumber() < 0.5 then Enum.Material.Slate else Enum.Material.Glass
		tas.CFrame = CFrame.new(merkez + Vector3.new(rng:NextNumber(-0.6, 0.6), 0, rng:NextNumber(-0.6, 0.6)))
			* CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28))
		tas.CanCollide = true
		tas.CanQuery = false
		tas.CanTouch = false
		tas.Massless = true
		tas.CastShadow = false
		-- Oyunculari itmesin diye cok hafif
		tas.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0.4, 0.3)
		tas.Parent = Workspace

		local yon = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0.8, 1.6), rng:NextNumber(-1, 1)).Unit
		tas.AssemblyLinearVelocity = yon * rng:NextNumber(18, 32)
		tas.AssemblyAngularVelocity = Vector3.new(rng:NextNumber(-10, 10), rng:NextNumber(-10, 10), rng:NextNumber(-10, 10))
		pcall(function()
			tas:SetNetworkOwner(nil)
		end)

		Debris:AddItem(tas, TAS_OMRU + rng:NextNumber(0, 0.6))
	end
end

return MadenPatlamasi
