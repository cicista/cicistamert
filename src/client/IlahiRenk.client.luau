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

	YAZILARDA KESKIN PARLAMA BANDI
	Onceki hal yumusak bir uc-durakli gradyandi (parlak -> renk -> parlak)
	ve Offset ile kaydiriliyordu; sonuc "soft" duruyordu, sertligi yoktu.

	Artik gradyan her karede YENIDEN kuruluyor: yazinin cogu kademenin duz
	rengi, uzerinden DAR ve PARLAK bir bant geciyor. Metal yazilardaki
	isik silme efekti gibi -- keskin ve okunabilir.

	Bandin genisligi ve gecis hizi kademeye gore degisiyor (bkz. Divine >
	Flashes): Abyssal en dar ve en hizli, Divine en genis ve en yavas.
]]
local function bandliGecis(color: Color3, parlak: Color3, yer: number, yari: number): ColorSequence
	--[[
		Duraklar sirali OLMAK ZORUNDA ve 0 ile 1'i icermeli; bant kenara
		tasarsa kirpiliyor, boylece bant ekrandan girip cikiyormus gibi olur.
	]]
	local duraklar = {}
	local sol = math.clamp(yer - yari, 0, 1)
	local sag = math.clamp(yer + yari, 0, 1)

	table.insert(duraklar, ColorSequenceKeypoint.new(0, if sol <= 0 then parlak else color))

	if sol > 0 then
		table.insert(duraklar, ColorSequenceKeypoint.new(sol, color))
	end

	if yer > 0 and yer < 1 then
		table.insert(duraklar, ColorSequenceKeypoint.new(yer, parlak))
	end

	if sag < 1 then
		table.insert(duraklar, ColorSequenceKeypoint.new(sag, color))
	end

	table.insert(duraklar, ColorSequenceKeypoint.new(1, if sag >= 1 then parlak else color))

	return ColorSequence.new(duraklar)
end

local function paint(instance: Instance, color: Color3, yer: number?, yari: number?)
	if instance:IsA("TextLabel") or instance:IsA("TextButton") then
		local gradient = instance:FindFirstChild("Parilti")

		if gradient and gradient:IsA("UIGradient") then
			-- Bant BEYAZA yakin ama tam beyaz degil: renk hep okunuyor
			local parlak = color:Lerp(Color3.new(1, 1, 1), 0.55)
			gradient.Offset = Vector2.zero
			gradient.Color = bandliGecis(color, parlak, yer or 0.5, yari or 0.12)
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
	-- Parlama bandinin bir gecisi kac saniye surer
	sweep: number,
	-- Bandin yari genisligi: kucuk olan daha keskin
	band: number,
	tracked: { [Instance]: boolean },
}

local paletler: { Palet } = {}

local function paletEkle(tag: string, colorA: Color3, colorB: Color3, interval: number, sweep: number?, band: number?)
	local palet: Palet = {
		colorA = colorA,
		colorB = colorB,
		interval = interval,
		sweep = sweep or 1.6,
		band = band or 0.12,
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
	paletEkle(flash.tag, flash.colorA, flash.colorB, flash.interval, flash.sweep, flash.band)
end

for _, flash in Mutations.Flash do
	paletEkle(flash.tag, flash.colorA, flash.colorB, flash.interval, flash.sweep, flash.band)
end

local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
	elapsed += dt

	for _, palet in paletler do
		--[[
			RENK GECISI  --  renk esas, beyaz misafir

			Duz sinus kullaninca sure iki renk arasinda ESIT paylasiliyordu
			ve ikinci uc beyaz oldugu icin yazi zamanin yarisini solgun
			geciriyordu. Sinus 4. kuvvete alinip 0.85 ile olcekleniyor:
			zamanin cogu kademenin KENDI RENGINDE, arada kisa bir parlama.
		]]
		local faz = elapsed / math.max(palet.interval, 1 / 240) * math.pi
		local dalga = (math.sin(faz) + 1) / 2
		local oran = dalga ^ 4 * 0.85
		local color = palet.colorA:Lerp(palet.colorB, oran)

		--[[
			PARLAMA BANDININ YERI

			Bant -yari'dan 1+yari'ya kadar gidiyor, yani yazinin disindan
			girip disindan cikiyor: parlama beliriverip kaybolmuyor,
			uzerinden GECIYOR.

			Hiz kademeye gore: Abyssal en hizli (0.7 sn), Divine en yavas.
		]]
		local tur = (elapsed / palet.sweep) % 1
		local yer = -palet.band + tur * (1 + palet.band * 2)

		for instance in palet.tracked do
			-- Silinen nesneler listeden kendiliginden dusmez; burada temizlenir
			if not instance.Parent then
				palet.tracked[instance] = nil
				continue
			end

			paint(instance, color, yer, palet.band)
		end
	end
end)
