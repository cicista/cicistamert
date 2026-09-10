--[[
	IlahiRenk  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > IlahiRenk

	Divine (eski adiyla Secret) kademesinin sari <-> beyaz parildamasini cizer.

	Sunucu ya da arayuz kodu bir nesneyi Shared > Divine ile ETIKETLER;
	burasi her karede etiketli nesneleri bulup rengini gunceller. Boylece
	renk degisimi replikasyona takilmaz, her oyuncunun ekraninda akici olur.

	Etiketli nesnenin sinifina gore dogru ozellik boyanir; ayni etiket hem
	dunyadaki isik suzmesinde hem arayuzdeki yazida calisir.

	Hiz ve renkler Shared > Divine icinde ayarlanir.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Divine = require(Shared:WaitForChild("Divine"))

--[[
	Bir nesneye o anki rengi uygular.

	Sinif kontrolleri en sik gorulenden basliyor: her karede butun etiketli
	nesneler icin calisiyor, gereksiz IsA cagrisi yapmayalim.
]]
local function paint(instance: Instance, color: Color3)
	if instance:IsA("TextLabel") or instance:IsA("TextButton") then
		instance.TextColor3 = color
	elseif instance:IsA("BasePart") then
		instance.Color = color
	elseif instance:IsA("UIStroke") then
		instance.Color = color
	elseif instance:IsA("Light") then
		-- PointLight / SpotLight / SurfaceLight
		instance.Color = color
	elseif instance:IsA("ParticleEmitter") then
		instance.Color = ColorSequence.new(color)
	elseif instance:IsA("Highlight") then
		-- Siyah brainrotun kademe konturu
		instance.OutlineColor = color
	elseif instance:IsA("Frame") then
		instance.BackgroundColor3 = color
	elseif instance:IsA("GuiObject") then
		instance.BackgroundColor3 = color
	end
end

--[[
	Etiketli nesneler her karede yeniden sorulmaz; CollectionService'in
	sinyalleriyle yerel bir liste tutulur. GetTagged her karede cagrilsaydi
	her seferinde yeni bir tablo ayrilirdi.
]]
local tracked: { [Instance]: boolean } = {}

for _, instance in CollectionService:GetTagged(Divine.Tag) do
	tracked[instance] = true
end

CollectionService:GetInstanceAddedSignal(Divine.Tag):Connect(function(instance)
	tracked[instance] = true
end)

CollectionService:GetInstanceRemovedSignal(Divine.Tag):Connect(function(instance)
	tracked[instance] = nil
end)

local elapsed = 0

RunService.RenderStepped:Connect(function(dt)
	elapsed += dt

	local color = Divine.colorAt(elapsed)

	for instance in tracked do
		-- Silinen nesneler listeden kendiliginden dusmez; burada temizlenir
		if not instance.Parent then
			tracked[instance] = nil
			continue
		end

		paint(instance, color)
	end
end)
