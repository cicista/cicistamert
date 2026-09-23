--!strict
--[[
	IKI ASAMALI RULET  --  ortak cizim modulu

	Lucky Block carki bunu kullanir; iki asamali cark mekanigi tek yerde duruyor.

	AKIS
	  1. ASAMA  Bolmelerde yalnizca "?" ve KADEME RENGI vardir. Ne cikacagi
	            belli degildir; rulet durunca sadece kademe ortaya cikar
	            (orn. kirmizi bolmede durdu -> Mythic).
	  2. ASAMA  Serit yeniden kurulur; bu kez bolmelerde SADECE o kademeden
	            cikabilecek adaylar (brainrot ya da skin) ADIYLA yazar.
	            Rulet durunca odul aciga cikar.

	Kazanan bolmenin nerede duracagi CAGIRAN TARAFTAN gelir -- yani sunucunun
	sectigi sonuctan. Rulet hicbir sey secmez, sadece gosterir.

	GORUNUM (cocuklara hitap eden, canli)
	  - Bolmeler kademe renginde parlak kartlar (ustu acik, alti koyu + cila)
	  - Ortada ust ve altta elmas isaretciler, ince parlayan cizgi
	  - Seridin iki ucunda karanliga solma: bolmeler ortaya dogru belirir
	  - Kazanan bolmede Rulet.kutla: genisleyen halka + etrafa yildizlar
	  - DEGERLI BOLMELER KENDINI BELLI EDER (bkz. KademeEfekti modulu):
	    kademe yukseldikce cerceve nabiz atar, isik doner, aura parlar,
	    en ustte gokkusagi ve kivilcimlar. Nadir bir bolme onunden gecerken
	    oyuncu heyecanlansin.

	KULLANIM
	    local reel = Rulet.new(panel, { position = ..., width = 408, height = 96 })
	    Rulet.run(reel, {
	        rarityCells = { "Epic", "Mythic", ... },   -- 1. asama
	        rarityWinner = 36,
	        rarityTime = 4,
	        pause = 0.7,
	        cells = { { text = "Tralalero", color = ... }, ... },  -- 2. asama
	        winner = 24,
	        time = 4,
	        onRarity = function(rarityId) ... end,   -- 1. cark durunca
	        onFinish = function() ... end,           -- 2. cark durunca
	    })
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarity = require(Shared:WaitForChild("Rarity"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))

local UI = require(script.Parent:WaitForChild("UI"))
-- 2. asama bolmelerinde brainrot resmi (bkz. BrainrotOnizleme.seritPencere)
local BrainrotOnizleme = require(script.Parent:WaitForChild("BrainrotOnizleme"))
-- Degerli bolmelerin canli cercevesi (Index de ayni modulu kullanir)
local KademeEfekti = require(script.Parent:WaitForChild("KademeEfekti"))
-- 1. cark durunca calan patlama sesi
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

--[[
	1. CARK DURUNCA calan ses. Kademe belli oldugu an bir "patlama" gelsin
	diye: ikinci cark donmeye baslamadan once vurgu. Ikinci carkin sonundaki
	FuseExplosion'i sunucu caliyor (bkz. Modules > Patlama).
]]
local DURUS_SESI = "FuseExplosion"
-- 1. cark durunca calan patlama sesi
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

--[[
	1. CARK DURUNCA calan ses. Kademe belli oldugu an bir "patlama" gelsin
	diye: ikinci cark donmeye baslamadan once vurgu. Ikinci carkin sonundaki
	FuseExplosion'i sunucu caliyor (bkz. Modules > Patlama).
]]
local DURUS_SESI = "FuseExplosion"
-- 1. cark durunca calan patlama sesi
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

--[[
	1. CARK DURUNCA calan ses. Kademe belli oldugu an bir "patlama" gelsin
	diye: ikinci cark donmeye baslamadan once vurgu. Ikinci carkin sonundaki
	FuseExplosion'i sunucu caliyor (bkz. Modules > Patlama).
]]
local DURUS_SESI = "FuseExplosion"
-- 1. cark durunca calan patlama sesi
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

--[[
	1. CARK DURUNCA calan ses. Kademe belli oldugu an bir "patlama" gelsin
	diye: ikinci cark donmeye baslamadan once vurgu. Ikinci carkin sonundaki
	FuseExplosion'i sunucu caliyor (bkz. Modules > Patlama).
]]
local DURUS_SESI = "FuseExplosion"
-- 1. cark durunca calan patlama sesi
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

--[[
	1. CARK DURUNCA calan ses. Kademe belli oldugu an bir "patlama" gelsin
	diye: ikinci cark donmeye baslamadan once vurgu. Ikinci carkin sonundaki
	FuseExplosion'i sunucu caliyor (bkz. Modules > Patlama).
]]
local DURUS_SESI = "FuseExplosion"
-- 1. cark durunca calan patlama sesi
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

--[[
	1. CARK DURUNCA calan ses. Kademe belli oldugu an bir "patlama" gelsin
	diye: ikinci cark donmeye baslamadan once vurgu. Ikinci carkin sonundaki
	FuseExplosion'i sunucu caliyor (bkz. Modules > Patlama).
]]
local DURUS_SESI = "FuseExplosion"
-- 1. cark durunca calan patlama sesi
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

--[[
	1. CARK DURUNCA calan ses. Kademe belli oldugu an bir "patlama" gelsin
	diye: ikinci cark donmeye baslamadan once vurgu. Ikinci carkin sonundaki
	FuseExplosion'i sunucu caliyor (bkz. Modules > Patlama).
]]
local DURUS_SESI = "FuseExplosion"
-- 1. cark durunca calan patlama sesi
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

--[[
	1. CARK DURUNCA calan ses. Kademe belli oldugu an bir "patlama" gelsin
	diye: ikinci cark donmeye baslamadan once vurgu. Ikinci carkin sonundaki
	FuseExplosion'i sunucu caliyor (bkz. Modules > Patlama).
]]
local DURUS_SESI = "FuseExplosion"
-- 1. cark durunca calan patlama sesi
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

--[[
	1. CARK DURUNCA calan ses. Kademe belli oldugu an bir "patlama" gelsin
	diye: ikinci cark donmeye baslamadan once vurgu. Ikinci carkin sonundaki
	FuseExplosion'i sunucu caliyor (bkz. Modules > Patlama).
]]
local DURUS_SESI = "FuseExplosion"
-- 1. cark durunca calan patlama sesi
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

--[[
	1. CARK DURUNCA calan ses. Kademe belli oldugu an bir "patlama" gelsin
	diye: ikinci cark donmeye baslamadan once vurgu. Ikinci carkin sonundaki
	FuseExplosion'i sunucu caliyor (bkz. Modules > Patlama).
]]
local DURUS_SESI = "FuseExplosion"
-- 1. cark durunca calan patlama sesi
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

--[[
	1. CARK DURUNCA calan ses. Kademe belli oldugu an bir "patlama" gelsin
	diye: ikinci cark donmeye baslamadan once vurgu. Ikinci carkin sonundaki
	FuseExplosion'i sunucu caliyor (bkz. Modules > Patlama).
]]
local DURUS_SESI = "FuseExplosion"
-- 1. cark durunca calan patlama sesi
local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

--[[
	1. CARK DURUNCA calan ses. Kademe belli oldugu an bir "patlama" gelsin
	diye: ikinci cark donmeye baslamadan once vurgu. Ikinci carkin sonundaki
	FuseExplosion'i sunucu caliyor (bkz. Modules > Patlama).
]]
local DURUS_SESI = "FuseExplosion"

local Rulet = {}

-- 1. asama bolmeleri dar (icinde sadece "?" var), 2. asama genis (isim yazar)
local RARITY_CELL_WIDTH = 84
local NAME_CELL_WIDTH = 132
local CELL_GAP = 6

export type Cell = {
	text: string,
	color: Color3,
	--[[
		Verilirse 2. asama bolmesinde brainrotun 3B resmi ustte, adi altta
		durur. Verilmezse bolme eskisi gibi yalnizca yazi (skin, coin...).
		1. asamada ("?" bolmeleri) hic kullanilmaz: kademe gizli kalmali.
	]]
	brainrot: { name: string, mutation: string? }?,
	-- Bolmenin kademesi: cercevedeki canli efekt buna gore secilir
	rarity: string?,
}

export type Reel = {
	frame: Frame,
	strip: Frame,
	marker: Frame,
	-- Ust ve alttaki elmas isaretciler (tint ile boyanir)
	oklar: { Frame },
	stroke: UIStroke,
	width: number,
	height: number,
	-- Serit su an hangi bolme genisligiyle kurulu
	cellWidth: number,
	busy: boolean,
	-- Seritteki brainrot resimleri; yalnizca cercevenin icinden gecenlere kurulur
	onizleme: BrainrotOnizleme.Pencere,
}

--[[
	rarityCells nil ise 1. ASAMA ATLANIR ve dogrudan odul serdi doner.

	Kademesi onceden belli olan bir cark icin: kademeyi bir kez daha
	cevirmek oyuncuyu bildigi bir seyi beklemeye zorlardi.
]]
export type Plan = {
	rarityCells: { string }?,
	rarityWinner: number?,
	rarityTime: number?,
	pause: number?,
	cells: { Cell },
	winner: number,
	time: number,
	-- Yalnizca iki asamali cevirimde cagrilir
	onRarity: ((rarityId: string) -> ())?,
	-- 2. cark donmeye baslarken (ses tekrarlamak icin)
	onSecondSpin: (() -> ())?,
	onFinish: (() -> ())?,
}

export type Options = {
	position: UDim2?,
	width: number?,
	height: number?,
	color: Color3?,
	name: string?,
}

------------------------------------------------------------------
-- KURULUM
------------------------------------------------------------------
function Rulet.new(parent: Instance, options: Options?): Reel
	local o = options or {}
	local width = o.width or 408
	local height = o.height or 96
	local color = o.color or UI.Colors.gold

	local frame = Instance.new("Frame")
	frame.Name = o.name or "Rulet"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = o.position or UDim2.new(0.5, 0, 0, 70)
	frame.Size = UDim2.fromOffset(width, height)
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = parent
	UI.corner(frame, 12)

	-- Zemin: ortasi hafif aydinlik, ust ve alt kenari koyu (derinlik)
	local zemin = Instance.new("UIGradient")
	zemin.Rotation = 90
	zemin.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 16, 26)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(38, 42, 64)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 16, 26)),
	})
	zemin.Parent = frame

	local stroke = UI.stroke(frame, color, 3)

	--[[
		KENARLARDA SOLMA

		Seridin iki ucu karanliga eriyor: bolmeler kenardan kesik kesik
		girmek yerine ortaya dogru belirip kayboluyor.
	]]
	for taraf = 0, 1 do
		local solma = Instance.new("Frame")
		solma.Name = if taraf == 0 then "SolSolma" else "SagSolma"
		solma.AnchorPoint = Vector2.new(taraf, 0)
		solma.Position = UDim2.fromScale(taraf, 0)
		solma.Size = UDim2.new(0, 70, 1, 0)
		solma.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
		solma.BorderSizePixel = 0
		solma.ZIndex = 5
		solma.Parent = frame

		local gecis = Instance.new("UIGradient")
		gecis.Transparency = if taraf == 0
			then NumberSequence.new(0, 1)
			else NumberSequence.new(1, 0)
		gecis.Parent = solma
	end

	-- Kayan serit: konumu her zaman sol kenardan olculur
	local strip = Instance.new("Frame")
	strip.Name = "Serit"
	strip.AnchorPoint = Vector2.new(0, 0.5)
	strip.Position = UDim2.new(0, 0, 0.5, 0)
	strip.Size = UDim2.new(0, 0, 1, -14)
	strip.BackgroundTransparency = 1
	strip.Parent = frame

	-- Ortadaki isaretci: bolmeler bunun hizasinda durur
	local marker = Instance.new("Frame")
	marker.Name = "Isaretci"
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Position = UDim2.fromScale(0.5, 0.5)
	marker.Size = UDim2.new(0, 4, 1, 0)
	marker.BackgroundColor3 = color
	marker.BackgroundTransparency = 0.15
	marker.BorderSizePixel = 0
	marker.ZIndex = 6
	marker.Parent = frame

	--[[
		ELMAS ISARETCILER

		Ust ve alt kenarin ortasinda 45 derece dondurulmus kareler. Donmus
		nesne ClipsDescendants ile kirpilmadigi icin cercevenin disina da
		tasiyor -- burada istenen tam olarak bu: kenara oturmus bir mucevher.
		Bu yuzden rulet cercevesinin UST nesnesine konuyorlar (cercevenin
		icinde kalsalar yine gorunurler ama kenar cizgisinin altinda kalirlar).
	]]
	local oklar: { Frame } = {}
	for yon = 0, 1 do
		local ok = Instance.new("Frame")
		ok.Name = if yon == 0 then "UstIsaretci" else "AltIsaretci"
		ok.AnchorPoint = Vector2.new(0.5, 0.5)
		ok.Size = UDim2.fromOffset(20, 20)
		ok.Rotation = 45
		ok.BackgroundColor3 = color
		ok.BorderSizePixel = 0
		ok.ZIndex = 8
		ok.Parent = parent
		UI.corner(ok, 4)
		UI.stroke(ok, Color3.fromRGB(0, 0, 0), 2)

		-- Cerceveyle birlikte konumlanir (cerceve AnchorPoint 0.5, 0)
		local function yerlestir()
			local p = frame.Position
			ok.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + (if yon == 0 then 0 else height))
		end
		yerlestir()
		frame:GetPropertyChangedSignal("Position"):Connect(yerlestir)

		table.insert(oklar, ok)
	end

	return {
		frame = frame,
		strip = strip,
		marker = marker,
		oklar = oklar,
		stroke = stroke,
		width = width,
		height = height,
		cellWidth = NAME_CELL_WIDTH,
		busy = false,
		onizleme = BrainrotOnizleme.seritPencere(frame),
	}
end

------------------------------------------------------------------
-- SERIT
------------------------------------------------------------------

--[[
	Bir bolmenin serit icindeki hedef konumu.
	Bolmenin MERKEZI isaretcinin (pencerenin ortasi) hizasina gelmeli.
]]
local function offsetFor(reel: Reel, index: number): number
	local center = (index - 1) * reel.cellWidth + reel.cellWidth / 2
	return -(center - reel.width / 2)
end

local function clearStrip(reel: Reel)
	-- Resimler bolmelerle birlikte silinmesin: havuza donsunlar
	reel.onizleme.temizle()

	for _, child in reel.strip:GetChildren() do
		child:Destroy()
	end
end

-- Degerli bolmelerin canli cercevesi (bkz. KademeEfekti)
local function efektTak(strip: Frame, cell: Frame, color: Color3, rarityId: string?)
	local cizgi = cell:FindFirstChildOfClass("UIStroke")
	if cizgi then
		KademeEfekti.tak(cell, cizgi, color, rarityId, { aura = "dis", auraKap = strip })
	end
end

--[[
	Seridi verilen bolmelerle kurar.

	showText false ise bolmede yalnizca buyuk bir "?" durur ve renk disinda
	hicbir ipucu verilmez -- 1. asama boyle cizilir.
]]
local function buildStrip(reel: Reel, cells: { Cell }, cellWidth: number, showText: boolean)
	clearStrip(reel)

	reel.cellWidth = cellWidth
	reel.strip.Size = UDim2.new(0, cellWidth * #cells, 1, -14)
	reel.strip.Position = UDim2.new(0, 0, 0.5, 0)

	for index, entry in cells do
		local cell = Instance.new("Frame")
		cell.Name = `Bolme{index}`
		cell.AnchorPoint = Vector2.new(0, 0.5)
		-- Y olcegi 0.5: kutucuk seridin dikey ortasina oturur
		cell.Position = UDim2.new(0, (index - 1) * cellWidth + CELL_GAP, 0.5, 0)
		cell.Size = UDim2.fromOffset(cellWidth - CELL_GAP * 2, reel.height - 22)
		cell.BorderSizePixel = 0
		cell.Parent = reel.strip
		UI.corner(cell, 10)

		--[[
			PARLAK KART: kademe renginde; ustu acik, alti koyu, ustte cam
			parlakligi. Kontur rengin acik tonu -- koyu zeminde kart
			kenarindan parliyormus gibi durur.
		]]
		cell.BackgroundColor3 = entry.color
		local kartGecis = Instance.new("UIGradient")
		kartGecis.Rotation = 90
		kartGecis.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(200, 200, 200)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 120, 120)),
		})
		kartGecis.Parent = cell
		UI.stroke(cell, entry.color:Lerp(Color3.new(1, 1, 1), 0.45), 2)

		local parlak = UI.gloss(cell, 0.78)
		parlak.Size = UDim2.new(1, 0, 0.42, 0)
		UI.corner(parlak, 10)

		-- Degerli bolme cercevesiyle kendini belli eder
		efektTak(reel.strip, cell, entry.color, entry.rarity)

		local resim = if showText then entry.brainrot else nil

		if resim then
			--[[
				BRAINROT BOLMESI: ustte resmi, altta adi.

				Resim cercevesi bolmeye ORANLA bagli: kazanan bolme vurgulanip
				buyurken resim de onunla buyuyor.
			]]
			local yuva = Instance.new("Frame")
			yuva.Name = "Resim"
			yuva.BackgroundTransparency = 1
			yuva.Position = UDim2.fromOffset(4, 2)
			yuva.Size = UDim2.new(1, -8, 1, -24)
			yuva.Parent = cell

			reel.onizleme.ekle(yuva, { name = resim.name, mutation = resim.mutation, revealed = true })

			-- Isim beyaz + siyah kontur: renkli kartin ustunde okunur
			local ad = UI.text({
				text = entry.text,
				size = UI.Sizes.tiny,
				font = UI.Fonts.bold,
				color = Color3.new(1, 1, 1),
				align = Enum.TextXAlignment.Center,
				frameSize = UDim2.new(1, -6, 0, 18),
				position = UDim2.new(0, 3, 1, -20),
				parent = cell,
				name = "Isaret",
				zIndex = 5,
			})
			-- Uzun adlar tek satirda kalsin, bolmeden tasmasin
			ad.TextTruncate = Enum.TextTruncate.AtEnd
		else
			-- "?" kocaman ve beyaz: kartin rengi kademeyi zaten soyluyor
			UI.text({
				text = if showText then entry.text else "?",
				size = if showText then UI.Sizes.small else UI.Sizes.huge + 8,
				font = UI.Fonts.bold,
				color = Color3.new(1, 1, 1),
				align = Enum.TextXAlignment.Center,
				frameSize = UDim2.new(1, -8, 1, -8),
				position = UDim2.fromOffset(4, 4),
				parent = cell,
				wrapped = showText,
				name = "Isaret",
				zIndex = 5,
			})
		end
	end
end

------------------------------------------------------------------
-- HAREKET
------------------------------------------------------------------

-- Seridi kazanan bolmeye kaydirir ve durana kadar bekler.
local function slideTo(reel: Reel, index: number, duration: number)
	local tween = TweenService:Create(
		reel.strip,
		TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, offsetFor(reel, index), 0.5, 0) }
	)
	tween:Play()
	tween.Completed:Wait()
end

--[[
	Kazanan bolmeyi vurgular: kisa bir buyume-kuculme ve kalin kontur.
	mark verilirse bolmedeki yazi da onunla degistirilir.
]]
local function highlight(reel: Reel, index: number, color: Color3, mark: string?)
	local cell = reel.strip:FindFirstChild(`Bolme{index}`)
	if not cell or not cell:IsA("Frame") then
		return
	end

	local label = cell:FindFirstChild("Isaret")
	if mark and label and label:IsA("TextLabel") then
		label.Text = mark
		label.TextColor3 = color
	end

	local stroke = cell:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Thickness = 5
		stroke.Transparency = 0
		-- Donen isigi olan cercevede taban beyaz kalmali (gecis carpar)
		stroke.Color = if stroke:FindFirstChildOfClass("UIGradient")
			then Color3.new(1, 1, 1)
			else color:Lerp(Color3.new(1, 1, 1), 0.6)
	end

	local home = cell.Size
	local pop = TweenService:Create(
		cell,
		TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(home.X.Offset + 20, home.Y.Offset + 20) }
	)
	pop:Play()
	pop.Completed:Once(function()
		TweenService:Create(cell, TweenInfo.new(0.18), { Size = home }):Play()
	end)
end

-- Ruletin cercevesini ve isaretcisini bir renge boyar
function Rulet.tint(reel: Reel, color: Color3)
	reel.stroke.Color = color
	reel.marker.BackgroundColor3 = color
	for _, ok in reel.oklar do
		ok.BackgroundColor3 = color
	end
end

--[[
	KUTLAMA  --  kazanan aciga cikinca

	Rulet cercevesinin ortasindan:
	  - kademe renginde bir halka genisleyip solar
	  - etrafa donerek yildizlar sacilir
	Hepsi cercevenin UST nesnesinde (panel): cerceve kirptigi icin
	icinde olsalar kenardan kesilirlerdi.
]]
function Rulet.kutla(reel: Reel, color: Color3)
	local panel = reel.frame.Parent
	if not panel then
		return
	end

	local p = reel.frame.Position
	local merkez = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + reel.height / 2)
	local parlak = color:Lerp(Color3.new(1, 1, 1), 0.35)

	-- Genisleyen halka
	local halka = Instance.new("Frame")
	halka.Name = "KutlamaHalkasi"
	halka.AnchorPoint = Vector2.new(0.5, 0.5)
	halka.Position = merkez
	halka.Size = UDim2.fromOffset(60, 60)
	halka.BackgroundTransparency = 1
	halka.ZIndex = 9
	halka.Parent = panel
	UI.corner(halka, 999)
	local halkaCizgi = UI.stroke(halka, parlak, 8)

	local sure = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	TweenService:Create(halka, sure, { Size = UDim2.fromOffset(reel.width + 80, reel.width + 80) }):Play()
	local solma = TweenService:Create(halkaCizgi, sure, { Transparency = 1, Thickness = 1 })
	solma.Completed:Once(function()
		halka:Destroy()
	end)
	solma:Play()

	-- Yildizlar: donmus kareler, dairesel olarak disa ucar ve solar
	local adet = 16
	for i = 1, adet do
		local aci = (i / adet) * math.pi * 2 + math.random() * 0.3
		local uzaklik = math.random(110, 210)
		local boy = math.random(10, 18)

		local yildiz = Instance.new("Frame")
		yildiz.Name = "KutlamaYildizi"
		yildiz.AnchorPoint = Vector2.new(0.5, 0.5)
		yildiz.Position = merkez
		yildiz.Size = UDim2.fromOffset(boy, boy)
		yildiz.Rotation = 45
		yildiz.BackgroundColor3 = if i % 3 == 0 then Color3.fromRGB(255, 240, 140) else parlak
		yildiz.BorderSizePixel = 0
		yildiz.ZIndex = 9
		yildiz.Parent = panel
		UI.corner(yildiz, 3)

		local hedef = merkez + UDim2.fromOffset(math.cos(aci) * uzaklik, math.sin(aci) * uzaklik * 0.7)
		local ucus = TweenInfo.new(0.55 + math.random() * 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(yildiz, ucus, {
			Position = hedef,
			Rotation = 45 + math.random(-180, 180),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(boy * 0.4, boy * 0.4),
		}):Play()
		task.delay(0.9, function()
			yildiz:Destroy()
		end)
	end
end

--[[
	Ruleti BEKLEME haline alir: verilen kademelerden "?" bolmeler kurulur ve
	serit hareketsiz durur. Panel ilk acildiginda seridin bos gorunmemesi
	icin. Rulet donuyorsa hicbir sey yapmaz.
]]
function Rulet.reset(reel: Reel, rarities: { string })
	if reel.busy then
		return
	end

	local cells: { Cell } = {}
	for _, id in rarities do
		table.insert(cells, { text = "?", color = Rarity.color(id), rarity = id })
	end

	buildStrip(reel, cells, RARITY_CELL_WIDTH, false)
end

-- Paneli kisaca titretir (kazanma hissi)
-- Settings > Screen Shake kapaliysa sarsinti yok (nitelik Ayarlar'dan gelir)
local function sarsintiKapali(): boolean
	return game:GetService("Players").LocalPlayer:GetAttribute("SarsintiKapali") == true
end

function Rulet.shake(frame: GuiObject)
	if sarsintiKapali() then
		return
	end
	local home = frame.Position
	task.spawn(function()
		for _ = 1, 6 do
			frame.Position = home + UDim2.fromOffset(math.random(-4, 4), math.random(-4, 4))
			task.wait(0.03)
		end
		frame.Position = home
	end)
end

------------------------------------------------------------------
-- IKI ASAMALI CEVIRIM
------------------------------------------------------------------

--[[
	Ruleti bastan sona oynatir.

	Cagiran taraf hicbir zamanlama yapmaz: burada beklenir, asama bitince
	onRarity / onFinish cagrilir. Kendi thread'inde calisir, cagirani
	bloklamaz.

	Rulet zaten donuyorsa false doner ve hicbir sey yapmaz. Cagiran taraf
	buna bakip arayuzunu kilitlemeli: yoksa baslamayan bir cevirim yuzunden
	buton sonsuza dek kapali kalabilir.
]]
--[[
	CARK SESI (bkz. LuckyBlock.Wheel.spinSounds)
	Bulunan ses saklanir; bulunamazsa her cevirmede yeniden aranir
	(ses Studio'ya sonradan konmus olabilir).
]]
local carkSesi: Sound? = nil

local function carkSesiBul(): Sound?
	if carkSesi and carkSesi.Parent then
		return carkSesi
	end

	local sesler: { Sound } = {}
	for _, kok in { SoundService :: Instance, Workspace, ReplicatedStorage } do
		for _, d in kok:GetDescendants() do
			if d:IsA("Sound") then
				table.insert(sesler, d)
			end
		end
	end

	for _, ad in LuckyBlock.Wheel.spinSounds or {} do
		for _, s in sesler do
			if s.Name == ad then
				carkSesi = s
				return s
			end
		end
	end

	for _, s in sesler do
		local kucuk = string.lower(s.Name)
		if string.find(kucuk, "spin", 1, true) or string.find(kucuk, "wheel", 1, true) then
			carkSesi = s
			return s
		end
	end

	return nil
end

local function carkSesiCal()
	local ses = carkSesiBul()
	if ses then
		SoundService:PlayLocalSound(ses)
	end
end

function Rulet.run(reel: Reel, plan: Plan): boolean
	if reel.busy then
		return false
	end
	reel.busy = true

	task.spawn(function()
		local fallbackColor = UI.Colors.text

		------------------------------------------------------------------
		-- 1. ASAMA: kademe -- yalnizca "?" ve renk
		-- (rarityCells verilmemisse bu asama tamamen atlanir)
		------------------------------------------------------------------
		local stageOne = plan.rarityCells

		if stageOne then
			local rarityCells: { Cell } = {}
			for _, id in stageOne do
				table.insert(rarityCells, { text = "?", color = Rarity.color(id), rarity = id })
			end

			local winnerIndex = plan.rarityWinner or 1

			buildStrip(reel, rarityCells, RARITY_CELL_WIDTH, false)
			carkSesiCal()
			slideTo(reel, winnerIndex, plan.rarityTime or 2.5)

			local winnerRarity = stageOne[winnerIndex] or "Common"
			fallbackColor = Rarity.color(winnerRarity)

			Rulet.tint(reel, fallbackColor)
			highlight(reel, winnerIndex, fallbackColor)
			YerelSes.cal(DURUS_SESI)

			if plan.onRarity then
				plan.onRarity(winnerRarity)
			end

			task.wait(plan.pause or 0.7)
		end

		------------------------------------------------------------------
		-- 2. ASAMA: o kademeden cikabilecekler, adiyla
		------------------------------------------------------------------
		buildStrip(reel, plan.cells, NAME_CELL_WIDTH, true)
		carkSesiCal()
		if plan.onSecondSpin then
			plan.onSecondSpin()
		end
		slideTo(reel, plan.winner, plan.time)

		local winnerCell = plan.cells[plan.winner]
		highlight(reel, plan.winner, if winnerCell then winnerCell.color else fallbackColor)

		reel.busy = false

		if plan.onFinish then
			plan.onFinish()
		end
	end)

	return true
end

return Rulet
