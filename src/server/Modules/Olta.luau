--!strict
--[[
	OLTA PARCALARI

	Denizde flyboardla gezerken elde duran olta ve girdaba atilan misina.

	NEDEN TOOL DEGIL
	Olta hotbarda yer kaplamasin, secilemesin ve elden birakilamasin diye
	Tool kullanilmiyor: parcalar dogrudan SAG ELE kaynaklanan bir Model.
	Denize girince gelir, cikinca gider; oyuncunun yapabilecegi bir sey yok.

	  Olta.build(rodId)             -- modeli uretir
	  Olta.attach(character, model) -- ele kaynaklar
	  Olta.has(player)              -- elinde olta var mi
	  Olta.remove(character)        -- oltayi ve misinayi kaldirir
	  Olta.cast(character, hedef)   -- misinayi girdabin ortasina atar
	  Olta.reel(character)          -- misinayi toplar
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rods = require(Shared:WaitForChild("Rods"))

local Olta = {}

--[[
	Oltanin gorunumu KODDA uretiliyor: sap, ince kamis, makara ve misinanin
	ucunda kademe renginde bir samandira. Makara ile samandira kademenin
	renginde, boylece elindeki oltanin seviyesi bir bakista anlasilir.
]]
function Olta.build(rodId: string?): Model
	local info = Rods.get(rodId) or Rods.Info[Rods.Order[1]]

	local model = Instance.new("Model")
	model.Name = Rods.ToolName

	local function parca(name: string, size: Vector3, color: Color3, material: Enum.Material): Part
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = color
		part.Material = material
		part.Anchored = false
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = model
		return part
	end

	-- Sap: elde tutulan kisim, modelin ana parcasi
	local sap = parca("Sap", Vector3.new(0.22, 1.1, 0.22), Color3.fromRGB(60, 44, 32), Enum.Material.Wood)
	model.PrimaryPart = sap

	local kamis = parca("Kamis", Vector3.new(0.12, 4.2, 0.12), Color3.fromRGB(38, 40, 46), Enum.Material.Metal)
	kamis.CFrame = sap.CFrame * CFrame.new(0, 2.6, 0)

	local makara = parca("Makara", Vector3.new(0.5, 0.5, 0.24), info.color, Enum.Material.Metal)
	makara.CFrame = sap.CFrame * CFrame.new(0.16, 0.72, 0)

	local samandira = parca("Samandira", Vector3.new(0.42, 0.42, 0.42), info.color, Enum.Material.Neon)
	samandira.Shape = Enum.PartType.Ball
	samandira.CFrame = sap.CFrame * CFrame.new(0, 4.6, 0)

	-- Misinanin cikis noktasi: atilan cizgi buraya baglanir
	local uc = Instance.new("Attachment")
	uc.Name = Rods.TipName
	uc.Parent = samandira

	return model
end

--[[
	Oltayi sag ele kaynaklar. R15'te RightHand, R6'da Right Arm; ikisi de
	yoksa false doner ve cagiran taraf modeli atar.
]]
function Olta.attach(character: Model, model: Model): boolean
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local sap = model.PrimaryPart

	if not hand or not hand:IsA("BasePart") or not sap then
		return false
	end

	model:PivotTo(hand.CFrame * CFrame.new(0, -0.4, -0.4) * CFrame.Angles(math.rad(-20), 0, 0))
	model.Parent = character

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hand
			weld.Part1 = part
			weld.Parent = part
		end
	end

	return true
end

function Olta.has(player: Player): boolean
	local character = player.Character
	return character ~= nil and character:FindFirstChild(Rods.ToolName) ~= nil
end

-- Atilan misinayi toplar
function Olta.reel(character: Model)
	local old = character:FindFirstChild(Rods.LineName)
	if old then
		old:Destroy()
	end
end

function Olta.remove(character: Model?)
	if not character then
		return
	end

	Olta.reel(character)

	local rod = character:FindFirstChild(Rods.ToolName)
	if rod then
		rod:Destroy()
	end
end

--[[
	MISINAYI GIRDABA ATAR

	Oltanin ucundan hedefe ince bir cizgi gerilir, ucunda samandira suya
	duser. Cizgi bir Beam oldugu icin oyuncu hareket ettikce kendiliginden
	gerilir; minigame bitince Olta.reel ile toplanir.
]]
function Olta.cast(character: Model, target: Vector3): BasePart?
	Olta.reel(character)

	local rod = character:FindFirstChild(Rods.ToolName)
	local tip = rod and rod:FindFirstChild(Rods.TipName, true)
	if not rod or not tip or not tip:IsA("Attachment") then
		return nil
	end

	-- Hedefteki sabit uc: girdabin tam ortasi
	local kanca = Instance.new("Part")
	kanca.Name = Rods.LineName
	kanca.Size = Vector3.one
	kanca.Transparency = 1
	kanca.Anchored = true
	kanca.CanCollide = false
	kanca.CanQuery = false
	kanca.CanTouch = false
	kanca.CFrame = CFrame.new(target)
	kanca.Parent = character

	local hedefNokta = Instance.new("Attachment")
	hedefNokta.Name = "Hedef"
	hedefNokta.Parent = kanca

	local misina = Instance.new("Beam")
	misina.Name = "Misina"
	misina.Attachment0 = tip
	misina.Attachment1 = hedefNokta
	misina.Width0 = 0.06
	misina.Width1 = 0.06
	misina.FaceCamera = true
	misina.LightInfluence = 0
	misina.Color = ColorSequence.new(Color3.fromRGB(240, 245, 250))
	misina.Transparency = NumberSequence.new(0.15)
	-- Eksi egrilik ipe hafif bir sarkma verir
	misina.CurveSize0 = -6
	misina.CurveSize1 = -2
	misina.Parent = kanca

	local samandira = Instance.new("Part")
	samandira.Name = "Samandira"
	samandira.Shape = Enum.PartType.Ball
	samandira.Size = Vector3.new(0.6, 0.6, 0.6)
	samandira.Color = Color3.fromRGB(255, 80, 80)
	samandira.Material = Enum.Material.SmoothPlastic
	samandira.Anchored = true
	samandira.CanCollide = false
	samandira.CanQuery = false
	samandira.CanTouch = false
	samandira.CFrame = CFrame.new(target)
	samandira.Parent = kanca

	return kanca
end

return Olta
