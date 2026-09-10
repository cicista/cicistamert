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
	height = 62,

	nameSize = 18,
	statSize = 14,
	incomeSize = 16,

	nameY = 2,
	statY = 22,
	incomeY = 40,

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
	local L = Etiket.Layout

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
	billboard.Parent = adornee

	------------------------------------------------------------------
	-- ISIM
	------------------------------------------------------------------
	local nameLabel = line(billboard, "Isim", item.name or "???", rarityInfo.color, L.nameSize, L.nameY)

	if Rarity.isDivine(item.rarity) then
		Divine.tag(nameLabel)
	elseif Rarity.isGlowing(item.rarity) then
		Fonts.applyGlow(nameLabel, rarityInfo.color)
	end

	------------------------------------------------------------------
	-- BOYUT (+ mutasyon)
	------------------------------------------------------------------
	local stat = if special
		then `{conditionInfo.shortName} ({conditionInfo.multiplier}x)  {mutationInfo.displayName} ({mutationInfo.multiplier}x)`
		else `{conditionInfo.shortName} ({conditionInfo.multiplier}x)`

	line(billboard, "Stat", stat, conditionInfo.color, L.statSize, L.statY)

	------------------------------------------------------------------
	-- GELIR
	------------------------------------------------------------------
	local income = if item.name then Brainrots.income(item.name, item.condition, item.mutation) else 0
	line(billboard, "Gelir", Format.perSecond(income), Bases.RotColor, L.incomeSize, L.incomeY)

	return billboard
end

return Etiket
