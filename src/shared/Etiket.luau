--!strict
--[[
	BRAINROT ETIKETI  --  uc satirlik dunya yazisi

	    Tralalero Tralala        <- isim, kademe renginde
	    Huge (3x)  Gold (8x)     <- boyut ve mutasyon carpanlari
	    1.5M/sn                  <- saniyelik gelir, para renginde

	IKI YERDE KULLANILIR
	  1. Base slotuna yerlestirilen brainrot  (ServerScriptService > BaseSistemi)
	  2. ELDE TASINAN brainrot                (Modules > Tools)

	Ikisi ayri ayri kurulsaydi zamanla birbirinden ayrisirdi: birinde
	mutasyon yazar digerinde yazmaz, biri parlar digeri parlamaz olurdu.
	Tek yerden uretiliyor ki elde tasirken gorunen sey base'te gorunenle
	birebir ayni olsun.

	RENK KURALLARI (oyunun her yerinde ayni)
	  - Isim HER ZAMAN kademe renginde. Epic ve ustunde parilti gradyani,
	    Divine'da sari <-> beyaz parildama (istemci cizer, bkz. Shared > Divine).
	  - Boyut satiri HER ZAMAN boyut renginde; mutasyon o rengi ele geciremez,
	    yalnizca kendi adiyla yazar.
	  - Gelir satiri para renginde (sari).
]]

local Bases = require(script.Parent.Bases)
local Brainrots = require(script.Parent.Brainrots)
local Condition = require(script.Parent.Condition)
local Divine = require(script.Parent.Divine)
local Fonts = require(script.Parent.Fonts)
local Format = require(script.Parent.Format)
local Mutations = require(script.Parent.Mutations)
local Rarity = require(script.Parent.Rarity)

local Etiket = {}

Etiket.Name = "Etiket"

--[[
	Satir yerlesimi. Yazi boyutlarini buradan degistirirsen iki yerde
	birden degisir.
]]
Etiket.Layout = {
	width = 190,
	height = 82,

	-- Kademe satiri (DIVINE, SECRET, ABYSSAL...) en ustte, efekt onun uzerinde
	raritySize = 15,
	nameSize = 18,
	statSize = 14,
	incomeSize = 16,

	rarityY = 2,
	nameY = 20,
	statY = 42,
	incomeY = 60,

	-- Kac studdan uzakta gorunmez olsun
	maxDistance = 120,
}

local function line(
	billboard: BillboardGui,
	name: string,
	text: string,
	color: Color3,
	size: number,
	y: number
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, size + 2)
	label.Position = UDim2.fromOffset(0, y)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextSize = size
	label.TextScaled = false
	Fonts.apply(label)
	label.Parent = billboard
	return label
end

--[[
	Etiketi kurar ve adornee'ye baglar.

	item   -- envanter kaydi (name, rarity, condition, mutation)
	adornee -- etiketin tutunacagi parca
	lift   -- kac stud YUKARIDA dursun (dunya uzayinda; parca donse de
	          yazi hep yukarida kalir)

	Ayni adornee'de eskiden bir etiket varsa once o silinir, boylece
	tekrar cagirmak guvenlidir.
]]
function Etiket.build(item: any, adornee: Instance, lift: number?): BillboardGui
	--[[
		KADEMEYE GORE BUYUME

		Adaya bagli ust kademeler (Cosmic, Secret, Infernal, Abyssal)
		etikette daha iri gorunur; carpan Divine'a kadar 1 oldugu icin
		mevcut kademelerin gorunumu hic degismez (bkz. Rarity.labelScale).

		Carpan HEM yazi boyutlarina HEM cercevenin olcusune uygulaniyor --
		yalnizca yaziyi buyutseydik satirlar cerceveye sigmazdi.
	]]
	local buyutme = Rarity.labelScale(item.rarity)

	local L = {
		width = Etiket.Layout.width * buyutme,
		height = Etiket.Layout.height * buyutme,

		raritySize = math.round(Etiket.Layout.raritySize * buyutme),
		nameSize = math.round(Etiket.Layout.nameSize * buyutme),
		statSize = math.round(Etiket.Layout.statSize * buyutme),
		incomeSize = math.round(Etiket.Layout.incomeSize * buyutme),

		rarityY = Etiket.Layout.rarityY * buyutme,
		nameY = Etiket.Layout.nameY * buyutme,
		statY = Etiket.Layout.statY * buyutme,
		incomeY = Etiket.Layout.incomeY * buyutme,

		maxDistance = Etiket.Layout.maxDistance,
	}

	local rarityInfo = Rarity.get(item.rarity)
	local conditionInfo = Condition.get(item.condition)
	local mutationInfo = Mutations.get(item.mutation)
	local special = Mutations.isSpecial(item.mutation)

	local old = adornee:FindFirstChild(Etiket.Name)
	if old then
		old:Destroy()
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = Etiket.Name
	billboard.Size = UDim2.fromOffset(L.width, L.height)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = L.maxDistance
	--[[
		StudsOffsetWorldSpace: parca donerken yazi savrulmasin diye DUNYA
		ekseninde yukari kayar. Normal StudsOffset parcanin eksenine bagli
		oldugu icin donen modelde yazi da donerdi.
	]]
	billboard.StudsOffsetWorldSpace = Vector3.new(0, lift or 0, 0)
	--[[
		ISIKTAN ETKILENMESIN

		Mutasyonlu modellerin kendi renkli isiklari var (Galaxy mor, Gold sari).
		Isik etkisi acikken yazi o rengi aliyordu: Legendary bir brainrot Galaxy
		olunca adi sari yerine MOR gorunuyordu. Sifirlaninca yazi her isikta
		kendi renginde kalir.
	]]
	billboard.LightInfluence = 0
	billboard.Parent = adornee

	------------------------------------------------------------------
	-- KADEME SATIRI
	--
	-- Brainrotun uzerinde kademesi de yaziyor: MYTHIC, DIVINE, ABYSSAL...
	-- Butun gorsel efekt (parlak gradyan + suzulen parlama bandi) ARTIK
	-- BURADA. Isim sade kalinca ikisi birbiriyle yarismiyor ve etiket
	-- uzaktan da okunuyor.
	------------------------------------------------------------------
	local rarityLabel = line(
		billboard,
		"Kademe",
		Rarity.labelText(item.rarity),
		rarityInfo.color,
		L.raritySize,
		L.rarityY
	)

	if Rarity.isDivine(item.rarity) then
		--[[
			Mythic ile ayni parlak gradyan, ustune parildama etiketi.
			tagIf: Cosmic mor, Secret siyah, Infernal kirmizi, Abyssal mavi.
		]]
		Fonts.applyGlow(rarityLabel, rarityInfo.color)
		Divine.tagIf(rarityLabel, item.rarity)
	elseif Rarity.isGlowing(item.rarity) then
		Fonts.applyGlow(rarityLabel, rarityInfo.color)
	end

	------------------------------------------------------------------
	-- ISIM
	--
	-- TEK RENK: kademenin rengi. Efekt kademe satirinda oldugu icin isim
	-- sade duruyor -- iki satir birden parlarsa hicbiri okunmuyor.
	------------------------------------------------------------------
	local nameLabel = line(billboard, "Isim", item.name or "???", rarityInfo.color, L.nameSize, L.nameY)

	------------------------------------------------------------------
	-- BOYUT (+ mutasyon)
	------------------------------------------------------------------
	--[[
		BOYUT VE MUTASYON AYRI YAZI, AYRI RENK

		Tek satirda tek renk oldugunda "Galaxy (8x)" de boyutun renginde
		yaziliyordu. Simdi iki ayri TextLabel yan yana duruyor ve her biri
		kendi rengini tasiyor.

		Ayri olmalarinin ikinci sebebi: Galaxy ve Hacker mutasyonlarinin
		rengi SABIT DEGIL, iki renk arasinda gidip geliyor. Canlandirmayi
		yapan istemci scripti bir NESNEYI boyuyor, yazinin bir parcasini
		degil -- RichText ile bu mumkun olmazdi.
	]]
	local statRow = Instance.new("Frame")
	statRow.Name = "Stat"
	statRow.BackgroundTransparency = 1
	statRow.Size = UDim2.new(1, 0, 0, L.statSize + 2)
	statRow.Position = UDim2.fromOffset(0, L.statY)
	statRow.Parent = billboard

	local statLayout = Instance.new("UIListLayout")
	statLayout.FillDirection = Enum.FillDirection.Horizontal
	statLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	statLayout.Padding = UDim.new(0, 8)
	statLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statLayout.Parent = statRow

	local function statParca(name: string, text: string, color: Color3, order: number): TextLabel
		local label = Instance.new("TextLabel")
		label.Name = name
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.new(0, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = color
		label.TextSize = L.statSize
		label.TextScaled = false
		label.LayoutOrder = order
		Fonts.apply(label)
		label.Parent = statRow
		return label
	end

	statParca(
		"Boyut",
		`{conditionInfo.shortName} ({conditionInfo.multiplier}x)`,
		conditionInfo.color,
		1
	)

	if special then
		local mutasyon = statParca(
			"Mutasyon",
			`{mutationInfo.displayName} ({mutationInfo.multiplier}x)`,
			mutationInfo.color,
			2
		)
		-- Galaxy ve Hacker: rengi istemci her karede degistirir
		Mutations.tagIf(mutasyon, item.mutation)
	end

	------------------------------------------------------------------
	-- GELIR
	------------------------------------------------------------------
	local income = if item.name then Brainrots.income(item.name, item.condition, item.mutation) else 0
	line(billboard, "Gelir", Format.perSecond(income), Bases.RotColor, L.incomeSize, L.incomeY)

	return billboard
end

return Etiket
