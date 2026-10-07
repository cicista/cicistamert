--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig")) :: any

local YAZI_FONTU = Font.new("rbxasset://fonts/families/Bangers.json", Enum.FontWeight.Bold)

local klasor: Folder = Instance.new("Folder")
klasor.Name = "DunyaEtiketleri"
klasor.Parent = playerGui

local kurulan: { [any]: BillboardGui } = {}

local function bul(yol: { string }): Instance?
	local node: Instance? = Workspace
	for _, ad in yol do
		node = if node then node:FindFirstChild(ad) else nil
	end
	return node
end

local function yazi(ebeveyn: Instance, metin: string, renk: Color3, boyut: UDim2, konum: UDim2)
	local etiket = Instance.new("TextLabel")
	etiket.BackgroundTransparency = 1
	etiket.Size = boyut
	etiket.Position = konum
	etiket.FontFace = YAZI_FONTU
	etiket.Text = metin
	etiket.TextColor3 = renk
	etiket.TextScaled = true
	etiket.Parent = ebeveyn

	local kontur = Instance.new("UIStroke")
	kontur.Color = Color3.new(0, 0, 0)
	kontur.Thickness = 3
	kontur.Parent = etiket
end

local function kur(tanim: any, hedef: Instance)
	local adornee: BasePart? = nil
	local ofset = Vector3.new(0, tanim.yukseklik, 0)

	if tanim.kafa then
		local kafa = hedef:FindFirstChild("Head", true)
		if kafa and kafa:IsA("BasePart") then
			adornee = kafa
		end
	end

	if not adornee and tanim.parca then
		local parca = hedef:FindFirstChild(tanim.parca, true)
		if parca and parca:IsA("BasePart") then
			adornee = parca
			local yuzey = parca:FindFirstChildOfClass("SurfaceGui")
			local on = parca.CFrame:VectorToWorldSpace(Vector3.FromNormalId(if yuzey then yuzey.Face else Enum.NormalId.Front))
			ofset = Vector3.new(0, parca.Size.Y / 2 + tanim.yukseklik, 0) + on * (tanim.ileri or 0)
		end
	end

	if not adornee and hedef:IsA("Model") then
		local cf, boy = hedef:GetBoundingBox()
		local parca = hedef.PrimaryPart or hedef:FindFirstChildWhichIsA("BasePart", true)
		if parca then
			adornee = parca
			ofset = Vector3.new(cf.Position.X, cf.Position.Y + boy.Y / 2 + tanim.yukseklik, cf.Position.Z) - parca.Position
		end
	elseif not adornee and hedef:IsA("BasePart") then
		adornee = hedef
	end

	if not adornee then
		return
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = tanim.metin
	gui.Adornee = adornee
	gui.Size = UDim2.fromScale(tanim.boyut.X, tanim.boyut.Y)
	if tanim.kafa then
		gui.StudsOffset = ofset
	else
		gui.StudsOffsetWorldSpace = ofset
	end
	gui.MaxDistance = tanim.mesafe
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.ResetOnSpawn = false
	gui.Parent = klasor

	if tanim.alt then
		yazi(gui, tanim.metin, tanim.renk, UDim2.fromScale(1, 0.66), UDim2.new())
		yazi(gui, tanim.alt, Color3.new(1, 1, 1), UDim2.fromScale(1, 0.34), UDim2.fromScale(0, 0.66))
	else
		yazi(gui, tanim.metin, tanim.renk, UDim2.fromScale(1, 0.9), UDim2.new())
	end

	kurulan[tanim] = gui
end

local function tara()
	if not klasor.Parent then
		klasor = Instance.new("Folder")
		klasor.Name = "DunyaEtiketleri"
		klasor.Parent = playerGui
	end

	for _, tanim in Config.DunyaEtiketleri do
		local var = kurulan[tanim]
		if var and var.Parent == klasor and var.Adornee and var.Adornee:IsDescendantOf(Workspace) then
			continue
		end
		if var then
			var:Destroy()
			kurulan[tanim] = nil
		end

		local hedef = bul(tanim.yol)
		if hedef then
			kur(tanim, hedef)
		end
	end
end

task.spawn(function()
	while true do
		tara()
		task.wait(3)
	end
end)
