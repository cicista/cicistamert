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
--[[
	ETIKETLI NESNEYI BOYAR

	TEXT ICIN GRADYAN KORUNUR
	Mythic gibi kademelerde yazinin uzerinde bir UIGradient var (Fonts
	"Parilti"): parlak -> renk -> parlak, yaziya hacim veriyor. Parildayan
	kademelerde bu gradyan SILINIYORDU ve geriye duz tek renk kaliyordu --
	ust kademeler alt kademelerden daha ucuz gorunuyordu.

	Artik gradyan duruyor ve PARILDAYAN SEY GRADYANIN KENDISI. Yazinin
	TextColor3'u beyaz kalir ki gradyan kendi rengini bozulmadan gostersin.

	sweep: gradyanin kaydirma miktari. Isik yazinin uzerinden gecer gibi
	suzulur -- asil "pahali" duran sey bu.
]]
local function paint(instance: Instance, color: Color3, sweep: number?)
	if instance:IsA("TextLabel") or instance:IsA("TextButton") then
		local gradient = instance:FindFirstChild("Parilti")

		if gradient and gradient:IsA("UIGradient") then
			-- Ucu az beyaz: 0.7 iken yazi rengini kaybedip solgun gorunuyordu
			local bright = color:Lerp(Color3.new(1, 1, 1), 0.32)
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, bright),
				ColorSequenceKeypoint.new(0.5, color),
				ColorSequenceKeypoint.new(1, bright),
			})
			if sweep then
				gradient.Offset = Vector2.new(0, sweep)
			end
			instance.TextColor3 = Color3.new(1, 1, 1)
		else
			instance.TextColor3 = color
		end
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
	elseif instance:IsA("UIGradient") then
		instance.Color = ColorSequence.new(color)
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

--[[
	Divine ve adaya bagli dort ust kademe (Cosmic, Secret, Infernal,
	Abyssal) ayni yerden geliyor: Shared > Divine > Flashes. Divine'in
	kendisi de o tabloda oldugu icin ayrica eklemeye gerek yok.
]]
for _, flash in Divine.Flashes do
	paletEkle(flash.tag, flash.colorA, flash.colorB, flash.interval)
end

for _, flash in Mutations.Flash do
	paletEkle(flash.tag, flash.colorA, flash.colorB, flash.interval)
end

local elapsed = 0

--[[
	Isik suzulmesinin bir turu kac saniye surer. Renk gecisinden bagimsiz:
	yavas parildayan bir kademede bile parlama akmaya devam etsin.
]]
local SUZULME = 1.6

RunService.RenderStepped:Connect(function(dt)
	elapsed += dt

	--[[
		Isik yazinin uzerinden asagidan yukari suzulur. -1..1 araligi
		gradyani tam disaridan tam disariya tasir, yani parlama girip cikar.
	]]
	local sweep = (elapsed / SUZULME) % 2 - 1

	for _, palet in paletler do
		--[[
			RENK GECISI  --  renk esas, beyaz misafir

			Iki sorun vardi:

			1. Gecis ANIYDI (step % 2): yazi strobe gibi kirpisiyordu.
			2. Duz sinus kullaninca sure iki renk arasinda ESIT paylasiliyor
			   ve ikinci uc BEYAZ oldugu icin yazi zamanin yarisini solgun
			   geciriyordu -- "renkten cok beyaz gorunuyor" sikayeti buydu.

			Cozum sinusu KUVVETE almak: egri zamanin cogunu 0'a yakin, yani
			KADEMENIN KENDI RENGINDE geciriyor, arada kisa bir beyaz parlama
			gelip gidiyor. Ust sinir da 1 degil: tam beyaza hic varmiyor,
			en parlak anda bile rengin izi kaliyor.
		]]
		local faz = elapsed / math.max(palet.interval, 1 / 240) * math.pi
		local dalga = (math.sin(faz) + 1) / 2
		local oran = dalga ^ 4 * 0.85
		local color = palet.colorA:Lerp(palet.colorB, oran)

		for instance in palet.tracked do
			-- Silinen nesneler listeden kendiliginden dusmez; burada temizlenir
			if not instance.Parent then
				palet.tracked[instance] = nil
				continue
			end

			paint(instance, color, sweep)
		end
	end
end)
