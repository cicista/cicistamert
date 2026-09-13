--!strict
--[[
	IKI ASAMALI RULET  --  ortak cizim modulu

	Hem Lucky Block carki hem Rot Slots ruleti bunu kullanir; ikisi de ayni
	sekilde davransin diye mekanik tek yerde duruyor.

	AKIS
	  1. ASAMA  Bolmelerde yalnizca "?" ve KADEME RENGI vardir. Ne cikacagi
	            belli degildir; rulet durunca sadece kademe ortaya cikar
	            (orn. kirmizi bolmede durdu -> Mythic).
	  2. ASAMA  Serit yeniden kurulur; bu kez bolmelerde SADECE o kademeden
	            cikabilecek adaylar (brainrot ya da skin) ADIYLA yazar.
	            Rulet durunca odul aciga cikar.

	Kazanan bolmenin nerede duracagi CAGIRAN TARAFTAN gelir -- yani sunucunun
	sectigi sonuctan. Rulet hicbir sey secmez, sadece gosterir.

	KULLANIM
	    local reel = Rulet.new(panel, { position = ..., width = 408, height = 96 })
	    Rulet.run(reel, {
	        rarityCells = { "Epic", "Mythic", ... },   -- 1. asama
	        rarityWinner = 36,
	        rarityTime = 3,
	        pause = 0.7,
	        cells = { { text = "Tralalero", color = ... }, ... },  -- 2. asama
	        winner = 24,
	        time = 2.6,
	        onRarity = function(rarityId) ... end,   -- 1. cark durunca
	        onFinish = function() ... end,           -- 2. cark durunca
	    })
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))
-- 2. asama bolmelerinde brainrot resmi (bkz. BrainrotOnizleme.seritPencere)
local BrainrotOnizleme = require(script.Parent:WaitForChild("BrainrotOnizleme"))

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
}

export type Reel = {
	frame: Frame,
	strip: Frame,
	marker: Frame,
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

	Fuse coini boyle calisir: kademe coinin uzerinde zaten yaziyor, merak
	edilen tek sey hangi brainrot oldugu. Kademeyi bir kez daha cevirmek
	oyuncuyu bildigi bir seyi beklemeye zorlardi.
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
	frame.BackgroundColor3 = Color3.fromRGB(12, 14, 19)
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = parent
	UI.corner(frame, 12)

	local stroke = UI.stroke(frame, color, 2)

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
	marker.Size = UDim2.new(0, 3, 1, 0)
	marker.BackgroundColor3 = color
	marker.BorderSizePixel = 0
	marker.ZIndex = 6
	marker.Parent = frame

	return {
		frame = frame,
		strip = strip,
		marker = marker,
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
		cell.BackgroundColor3 = entry.color
		cell.BackgroundTransparency = 0.78
		cell.BorderSizePixel = 0
		cell.Parent = reel.strip
		UI.corner(cell, 8)
		UI.stroke(cell, entry.color, 2)

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

			local ad = UI.text({
				text = entry.text,
				size = UI.Sizes.tiny,
				font = UI.Fonts.bold,
				color = entry.color,
				align = Enum.TextXAlignment.Center,
				frameSize = UDim2.new(1, -6, 0, 18),
				position = UDim2.new(0, 3, 1, -20),
				parent = cell,
				name = "Isaret",
			})
			-- Uzun adlar tek satirda kalsin, bolmeden tasmasin
			ad.TextTruncate = Enum.TextTruncate.AtEnd
		else
			UI.text({
				text = if showText then entry.text else "?",
				size = if showText then UI.Sizes.tiny else UI.Sizes.title,
				font = UI.Fonts.bold,
				color = entry.color,
				align = Enum.TextXAlignment.Center,
				frameSize = UDim2.new(1, -8, 1, -8),
				position = UDim2.fromOffset(4, 4),
				parent = cell,
				wrapped = showText,
				name = "Isaret",
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
		stroke.Thickness = 4
		stroke.Color = color
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
		table.insert(cells, { text = "?", color = Rarity.color(id) })
	end

	buildStrip(reel, cells, RARITY_CELL_WIDTH, false)
end

-- Paneli kisaca titretir (kazanma hissi)
function Rulet.shake(frame: GuiObject)
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
				table.insert(rarityCells, { text = "?", color = Rarity.color(id) })
			end

			local winnerIndex = plan.rarityWinner or 1

			buildStrip(reel, rarityCells, RARITY_CELL_WIDTH, false)
			slideTo(reel, winnerIndex, plan.rarityTime or 2.5)

			local winnerRarity = stageOne[winnerIndex] or "Common"
			fallbackColor = Rarity.color(winnerRarity)

			Rulet.tint(reel, fallbackColor)
			highlight(reel, winnerIndex, fallbackColor)

			if plan.onRarity then
				plan.onRarity(winnerRarity)
			end

			task.wait(plan.pause or 0.7)
		end

		------------------------------------------------------------------
		-- 2. ASAMA: o kademeden cikabilecekler, adiyla
		------------------------------------------------------------------
		buildStrip(reel, plan.cells, NAME_CELL_WIDTH, true)
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
