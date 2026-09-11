--[[
	IlahiRenk  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > IlahiRenk

	CANLI RENKLERI CIZER.

	Uc yerde kullaniliyor:
	  Divine kademesi  -> sari <-> beyaz   (Shared > Divine)
	  Galaxy mutasyonu -> mor <-> pembe    (Shared > Mutations > Flash)
	  Hacker mutasyonu -> yesil <-> beyaz  (ayni yer)

	Sunucu ya da arayuz kodu bir nesneyi ETIKETLER; burasi her karede
	etiketli nesneleri bulup rengini gunceller. Renk degisimi boylece
	replikasyona takilmaz, her oyuncunun ekraninda akici olur -- sunucudan
	saniyede 20 kez renk gondermek titrek ve kesik gorunurdu.

	Etiketli nesnenin sinifina gore dogru ozellik boyanir; ayni etiket hem
	dunyadaki isik suzmesinde hem arayuzdeki yazida calisir.

	Hizlar ve renkler Shared > Divine ve Shared > Mutations icinde ayarlanir.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Divine = require(Shared:WaitForChild("Divine"))
local Mutations = require(Shared:WaitForChild("Mutations"))

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
	Her palet bir CollectionService etiketi ve iki uc renktir.

	Etiketli nesneler her karede yeniden sorulmaz; CollectionService'in
	sinyalleriyle yerel bir liste tutulur. GetTagged her karede cagrilsaydi
	her seferinde yeni bir tablo ayrilirdi.
]]
type Palet = {
	colorA: Color3,
	colorB: Color3,
	interval: number,
	tracked: { [Instance]: boolean },
}

local paletler: { Palet } = {}

local function paletEkle(tag: string, colorA: Color3, colorB: Color3, interval: number)
	local palet: Palet = {
		colorA = colorA,
		colorB = colorB,
		interval = interval,
		tracked = {},
	}

	for _, instance in CollectionService:GetTagged(tag) do
		palet.tracked[instance] = true
	end

	CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		palet.tracked[instance] = true
	end)

	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
		palet.tracked[instance] = nil
	end)

	table.insert(paletler, palet)
end

paletEkle(Divine.Tag, Divine.colorA, Divine.colorB, Divine.interval)

for _, flash in Mutations.Flash do
	paletEkle(flash.tag, flash.colorA, flash.colorB, flash.interval)
end

local elapsed = 0

RunService.RenderStepped:Connect(function(dt)
	elapsed += dt

	for _, palet in paletler do
		local step = math.floor(elapsed / math.max(palet.interval, 1 / 240))
		local color = if step % 2 == 0 then palet.colorA else palet.colorB

		for instance in palet.tracked do
			-- Silinen nesneler listeden kendiliginden dusmez; burada temizlenir
			if not instance.Parent then
				palet.tracked[instance] = nil
				continue
			end

			paint(instance, color)
		end
	end
end)
