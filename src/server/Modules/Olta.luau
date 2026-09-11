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
	  Olta.cast(character, hedef)   -- misinayi girdaba savurur (animasyonlu)
	  Olta.reel(character)          -- misinayi toplar
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
	MISINAYI GIRDABA SAVURUR

	Misina girdabin ortasinda ANINDA belirmez -- oltanin ucundan cikar,
	havada kavis cizer ve suya duser:

	  CastRelease kadar bekle   (savurma animasyonunun geri cekme kismi;
	                             misina henuz gorunmez)
	  CastFlight boyunca ucur   (oltanin ucundan girdabin ortasina, kavisli)
	  hedefte sabitlen          (ip hafif sarkar, minigame boyunca durur)

	Zamanlama Shared > Rods icinde; savurma animasyonunu degistirirsen
	orayi guncelle.

	Cagiran tarafi BEKLETMEZ: ucus kendi thread'inde doner, fonksiyon
	hemen doner. Minigame'in ne zaman acilacagini KaziSistemi ayri
	bekliyor (Rods.CastTime).
]]
function Olta.cast(character: Model, target: Vector3): BasePart?
	Olta.reel(character)

	local rod = character:FindFirstChild(Rods.ToolName)
	local tip = rod and rod:FindFirstChild(Rods.TipName, true)
	if not rod or not tip or not tip:IsA("Attachment") then
		return nil
	end

	--[[
		Samandira hem misinanin ucu hem de suya dusen sasi. Once oltanin
		ucunda, gorunmez halde durur; birakilinca gorunur ve ucar.
	]]
	local samandira = Instance.new("Part")
	samandira.Name = Rods.LineName
	samandira.Shape = Enum.PartType.Ball
	samandira.Size = Vector3.new(0.6, 0.6, 0.6)
	samandira.Color = Color3.fromRGB(255, 80, 80)
	samandira.Material = Enum.Material.SmoothPlastic
	samandira.Transparency = 1
	samandira.Anchored = true
	samandira.CanCollide = false
	samandira.CanQuery = false
	samandira.CanTouch = false
	samandira.CFrame = CFrame.new(tip.WorldPosition)
	samandira.Parent = character

	local hedefNokta = Instance.new("Attachment")
	hedefNokta.Name = "Hedef"
	hedefNokta.Parent = samandira

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
	-- Ucarken ip gergin; sarkma suya dustukten sonra geliyor
	misina.CurveSize0 = 0
	misina.CurveSize1 = 0
	misina.Enabled = false
	misina.Parent = samandira

	task.spawn(function()
		-- Savurma animasyonunun geri cekme kismi: ip henuz cikmadi
		task.wait(Rods.CastRelease)
		if samandira.Parent == nil then
			return
		end

		--[[
			Baslangic noktasi BURADA okunuyor, fonksiyonun basinda degil:
			oyuncu bekleme boyunca kipirdadiysa ip yine de oltanin
			ucundan cikmali.
		]]
		local basla = tip.WorldPosition
		local mesafe = (target - basla).Magnitude

		-- Kavis yuksekligi mesafeyle buyur ama asiri firlamasin
		local kavis = math.clamp(mesafe * 0.14, 3, 14)

		samandira.Transparency = 0
		misina.Enabled = true

		local baslangicZamani = os.clock()
		while true do
			local oran = (os.clock() - baslangicZamani) / Rods.CastFlight
			if oran >= 1 then
				break
			end

			-- Duz gidis + sin egrisiyle yukari kavis
			local nokta = basla:Lerp(target, oran)
				+ Vector3.new(0, math.sin(oran * math.pi) * kavis, 0)
			samandira.CFrame = CFrame.new(nokta)

			RunService.Heartbeat:Wait()
			if samandira.Parent == nil then
				-- Minigame bitti ya da oyuncu tahtadan indi: ipi topla
				return
			end
		end

		samandira.CFrame = CFrame.new(target)
		-- Suya dustu: ip artik hafif sarksin
		misina.CurveSize0 = -6
		misina.CurveSize1 = -2
	end)

	return samandira
end

return Olta
