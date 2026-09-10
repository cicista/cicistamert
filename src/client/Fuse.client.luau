--[[
	Fuse  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Fuse

	Uc ekran:

	1. MAKINE PANELI  (alt orta)
	   Makineye yaklasinca kendiliginden gorunur. Oyuncu ne yapmasi
	   gerektigini buradan okur:

	       Same Rarity Brainrot   3/5
	       Rare  ->  EPIC COIN
	       %60 Tiny   %20 Large   %20 Huge
	       %20 Gold   %10 Diamond
	       E ile koy   |   F ile geri al   |   18sn

	   Kademe, boyut ve mutasyon sanslari her esya konuldugunda tazelenir.
	   Ekranda yazan oran cekilisin GERCEK orani: arayuz de sunucu da
	   Shared > Fuse icindeki ayni fonksiyonlari kullaniyor.

	2. BIRLESME GOSTERISI  (tam ekran)
	   5. esya konuldugunda oynar: iceri konan esyalarin renginde ruhlar
	   donerek merkeze kapanir, beyaz bir patlamada birlesir, yeni kademenin
	   renginde yildizlar dagilir ve coinin adi okunur. Coin cantaya ancak
	   gosteri bitince duser.

	3. COIN BOZDURUCU  (orta panel)
	   Coin listesi; birine tiklayinca tek asamali cark doner ve o kademeden
	   cikan brainrot aciga cikar. Coinin boyutu neyse brainrot da o boyutta
	   gelir, o yuzden cark yalnizca ISMI merak ettirir.
]]

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Condition = require(Shared:WaitForChild("Condition"))
local Format = require(Shared:WaitForChild("Format"))
local Fuse = require(Shared:WaitForChild("Fuse"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))
local Rulet = require(script.Parent:WaitForChild("Rulet"))

local FuseDurum = Net.event("FuseDurum")
local FuseGeriAl = Net.event("FuseGeriAl")
local FuseSonuc = Net.event("FuseSonuc")
local CoinAc = Net.event("CoinAc")
local CoinBozdur = Net.event("CoinBozdur")
local CoinSonuc = Net.event("CoinSonuc")
local FuseSecim = Net.event("FuseSecim")
local FuseEkle = Net.event("FuseEkle")

local TAKE_BACK = "FuseGeriAlEylemi"

local screen = Instance.new("ScreenGui")
screen.Name = "FuseEkrani"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

------------------------------------------------------------------
-- 1. MAKINE DURUM PANELI
--
-- Bu panel ARTIK EKRANDA TEK BASINA DURMUYOR: makine penceresinin SAG
-- SUTUNU olarak asagida yeniden konumlaniyor (bkz. MAKINE PENCERESI).
-- Yani makineye yaklasmak hicbir sey acmiyor; pencere ancak E ile
-- girilince cikiyor ve koydugun esyalar ile olasiliklari orada gorursun.
------------------------------------------------------------------
local machinePanel = Instance.new("Frame")
machinePanel.Name = "MakinePaneli"
machinePanel.AnchorPoint = Vector2.new(0.5, 1)
machinePanel.Position = UDim2.new(0.5, 0, 1, -150)
machinePanel.Size = UDim2.fromOffset(460, 172)
machinePanel.BackgroundColor3 = UI.Colors.panel
machinePanel.BackgroundTransparency = 0.1
machinePanel.BorderSizePixel = 0
machinePanel.Visible = false
machinePanel.Parent = screen
UI.corner(machinePanel, 12)

local machineStroke = UI.stroke(machinePanel, UI.Colors.accent, 2)

UI.text({
	text = "FUSE MACHINE",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = UI.Colors.accent,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 20),
	position = UDim2.fromOffset(10, 8),
	parent = machinePanel,
})

-- "Same Rarity Brainrot  3/5"
local headline = UI.text({
	text = "",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 30),
	position = UDim2.fromOffset(10, 42),
	parent = machinePanel,
})

-- "Rare  ->  EPIC COIN"
local resultLine = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 48),
	position = UDim2.fromOffset(10, 80),
	parent = machinePanel,
})

-- "%60 Tiny   %20 Large   %20 Huge"
local sizeLine = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 22),
	position = UDim2.fromOffset(10, 140),
	parent = machinePanel,
})

-- "%20 Gold   %10 Diamond" -- iceride mutasyonlu esya varsa
local mutationLine = UI.text({
	text = "",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 22),
	position = UDim2.fromOffset(10, 168),
	parent = machinePanel,
})

local hintLine = UI.text({
	text = "",
	size = UI.Sizes.tiny,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 20),
	position = UDim2.fromOffset(10, 202),
	parent = machinePanel,
})

local nearMachine = false

-- Birlesme gosterisi oynuyor mu. Alt panel gosteri sirasinda gizlenir;
-- FuseDurum isleyicisi bunu okudugu icin burada, ondan ONCE bildirilir.
local merging = false

------------------------------------------------------------------
-- MAKINE PENCERESI  (esya secimi)
--
-- Esyayi ELDE TUTMAK yok: E'ye basinca bu pencere acilir ve makineye
-- konabilecek her sey listelenir. Tiklanan esya makineye girer.
--
-- Liste sunucudan geliyor (FuseDurum.items) ve her eklemeden sonra
-- tazeleniyor; makinede bir kademe varsa sunucu zaten yalnizca O kademeyi
-- yolluyor, yani kabul edilmeyecek satir listede gorunmez.
------------------------------------------------------------------
local konabilir: { any } = {}

local secimPenceresi = UI.panel(screen, UDim2.fromOffset(880, 470), "MakineSecimi")

UI.text({
	text = "Fuse Machine",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	frameSize = UDim2.new(1, -80, 0, 36),
	position = UDim2.fromOffset(18, 14),
	parent = secimPenceresi,
})

local secimOzet = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 50),
	parent = secimPenceresi,
})

UI.closeButton(secimPenceresi).MouseButton1Click:Connect(function()
	secimPenceresi.Visible = false
end)

local secimListe = Instance.new("ScrollingFrame")
secimListe.Name = "Liste"
-- SOL SUTUN: makineye konabilecek esyalar
secimListe.Position = UDim2.fromOffset(14, 82)
secimListe.Size = UDim2.new(0.5, -20, 1, -96)
secimListe.BackgroundTransparency = 1
secimListe.BorderSizePixel = 0
secimListe.ScrollBarThickness = 5
secimListe.ScrollBarImageColor3 = UI.Colors.panelLight
secimListe.CanvasSize = UDim2.new()
secimListe.AutomaticCanvasSize = Enum.AutomaticSize.Y
secimListe.Parent = secimPenceresi

local secimDizilim = Instance.new("UIListLayout")
secimDizilim.Padding = UDim.new(0, 8)
secimDizilim.SortOrder = Enum.SortOrder.LayoutOrder
secimDizilim.Parent = secimListe

--[[
	SAG SUTUN: MAKINENIN DURUMU

	Bu panel eskiden makineye yaklasinca ekranin ALTINDA kendiliginden
	beliriyordu. Artik ayri bir pencere degil: ayni pencerenin sag yarisi.
	Yani makineye girmeden hicbir sey acilmiyor, girince de koydugun
	esyalari ve olasiliklari solda secim yaparken yaninda goruyorsun.
]]
machinePanel.AnchorPoint = Vector2.new(0, 0)
machinePanel.Position = UDim2.new(0.5, 6, 0, 82)
machinePanel.Size = UDim2.new(0.5, -20, 1, -96)
machinePanel.BackgroundTransparency = 0
machinePanel.BackgroundColor3 = UI.Colors.panelLight
machinePanel.Visible = true
machinePanel.Parent = secimPenceresi

-- Makinedekileri envantere geri al (F tusunun dugme karsiligi)
local geriAlButon = UI.button(machinePanel, "Take Back", UDim2.new(1, -24, 0, 38), UI.Colors.panel)
geriAlButon.AnchorPoint = Vector2.new(0.5, 1)
geriAlButon.Position = UDim2.new(0.5, 0, 1, -12)
UI.stroke(geriAlButon, Color3.fromRGB(0, 0, 0), 2)

geriAlButon.MouseButton1Click:Connect(function()
	FuseGeriAl:FireServer()
end)

UI.hover(geriAlButon)

local function secimListesiniCiz()
	for _, child in secimListe:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	if #konabilir == 0 then
		UI.text({
			text = "Nothing you can fuse right now.",
			size = UI.Sizes.small,
			color = UI.Colors.textDim,
			frameSize = UDim2.new(1, -6, 0, 40),
			parent = secimListe,
		})
		return
	end

	for index, item in konabilir do
		local renk = Rarity.color(item.rarity)
		local ad = item.name or `Unidentified {Rarity.displayName(item.rarity)}`
		local altYazi = `{Rarity.displayName(item.rarity)}  --  {Condition.get(item.condition).shortName}`

		if Mutations.isSpecial(item.mutation) then
			altYazi ..= `  --  {Mutations.get(item.mutation).displayName}`
		end

		local row = Instance.new("TextButton")
		row.Name = item.uid
		row.Text = ""
		row.AutoButtonColor = false
		row.Size = UDim2.new(1, -6, 0, 52)
		row.BackgroundColor3 = UI.Colors.panelLight
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = secimListe
		UI.corner(row, 10)
		UI.stroke(row, renk, 1)

		UI.text({
			text = ad,
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = renk,
			frameSize = UDim2.new(1, -110, 0, 22),
			position = UDim2.fromOffset(14, 6),
			parent = row,
		})

		UI.text({
			text = altYazi,
			size = UI.Sizes.tiny,
			color = UI.Colors.textDim,
			frameSize = UDim2.new(1, -110, 0, 18),
			position = UDim2.fromOffset(14, 28),
			parent = row,
		})

		-- Coin mi brainrot mu: makineye ikisi de girer, ayrimi yazi soyler
		UI.text({
			text = if item.kind == "coin" then "COIN" else "BRAINROT",
			size = UI.Sizes.tiny,
			font = UI.Fonts.bold,
			color = UI.Colors.textDim,
			align = Enum.TextXAlignment.Right,
			frameSize = UDim2.new(0, 96, 0, 52),
			position = UDim2.new(1, -110, 0, 0),
			parent = row,
		})

		row.MouseButton1Click:Connect(function()
			FuseEkle:FireServer(item.uid)
		end)

		UI.hover(row)
	end
end

FuseSecim.OnClientEvent:Connect(function()
	secimPenceresi.Visible = true
	secimListesiniCiz()
end)


local function bindTakeBack()
	ContextActionService:BindAction(TAKE_BACK, function(_, state)
		if state == Enum.UserInputState.Begin then
			FuseGeriAl:FireServer()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.F)
end

local function unbindTakeBack()
	ContextActionService:UnbindAction(TAKE_BACK)
end

--[[
	Boyut sansi satiri: "%60 Tiny   %20 Large   %20 Huge"

	Yalnizca ICERIDE BULUNAN boyutlar yazilir; hic esya yoksa satir bos
	kalir, cunku heniz cekilecek bir sey yok.
]]
local function sizeText(sizes: { any }?): string
	if type(sizes) ~= "table" or #sizes == 0 then
		return ""
	end

	local parts = {}
	for _, entry in sizes do
		local info = Condition.get(entry.id)
		table.insert(parts, `{math.floor(entry.chance + 0.5)}% {info.shortName}`)
	end

	return table.concat(parts, "   ")
end

--[[
	Mutasyon aktarim satiri: "%20 Gold   %10 Diamond"

	Makineye konan her mutasyonlu esya kendi mutasyonunu gecirme sansi
	katiyor. Iceride hic mutasyonlu esya yoksa satir bos kalir -- bos bir
	"%0" yazmak yerine hic gostermemek daha temiz.
]]
local function mutationText(mutations: { any }?): string
	if type(mutations) ~= "table" or #mutations == 0 then
		return ""
	end

	local parts = {}
	for _, entry in mutations do
		local info = Mutations.get(entry.id)
		table.insert(parts, `{math.floor(entry.chance + 0.5)}% {info.displayName}`)
	end

	return table.concat(parts, "   ")
end

FuseDurum.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" or not data.near then
		if nearMachine then
			nearMachine = false
			unbindTakeBack()
			-- Makineden uzaklasinca secim penceresi de kapanir
			secimPenceresi.Visible = false
		end
		return
	end

	if not nearMachine then
		nearMachine = true
		bindTakeBack()
	end

	-- Birlesme gosterisi oynarken pencere kapali kalir
	if merging then
		secimPenceresi.Visible = false
	end

	local count = tonumber(data.count) or 0
	local rarityId = if type(data.rarity) == "string" then data.rarity else nil

	------------------------------------------------------------------
	-- Baslik: makine bosken ne yapmasi gerektigini soyler.
	-- Metin Shared > Fuse'dan geliyor; sunucu ve istemci ayni cumleyi kurar.
	------------------------------------------------------------------
	headline.Text = Fuse.headline(rarityId, count)

	if rarityId then
		UI.rarityStyle(headline, rarityId)
		machineStroke.Color = Rarity.color(rarityId)
	else
		UI.plainStyle(headline, UI.Colors.text)
		machineStroke.Color = UI.Colors.accent
	end

	------------------------------------------------------------------
	-- Ne cikacak
	------------------------------------------------------------------
	if rarityId and type(data.nextRarity) == "string" then
		resultLine.Text = `{Rarity.displayName(rarityId)}  ->  {string.upper(Rarity.displayName(data.nextRarity))} COIN`
		UI.rarityStyle(resultLine, data.nextRarity)
	else
		resultLine.Text = "Add 5 items of the same tier to get a coin one tier higher"
		UI.plainStyle(resultLine, UI.Colors.textDim)
	end

	------------------------------------------------------------------
	-- Boyut ve mutasyon sanslari
	------------------------------------------------------------------
	sizeLine.Text = sizeText(data.sizes)
	mutationLine.Text = mutationText(data.mutations)

	------------------------------------------------------------------
	-- Ipucu + iade sayaci
	------------------------------------------------------------------
	local timeout = math.floor(tonumber(data.timeout) or 0)
	hintLine.Text = if count > 0
		then `Auto-return in {timeout}s`
		else "Pick items on the left to fill the machine"

	--[[
		SECIM LISTESI

		Her pakette tazelenir; pencere aciksa yeniden cizilir, boylece
		makineye konan esya listeden hemen duser.
	]]
	konabilir = if type(data.items) == "table" then data.items else {}
	secimOzet.Text = if rarityId
		then `Machine holds {Rarity.displayName(rarityId)}  --  {count}/{data.required or 5}`
		else `{#konabilir} items you can fuse`

	if secimPenceresi.Visible then
		secimListesiniCiz()
	end
end)

------------------------------------------------------------------
-- 2. BIRLESME GOSTERISI
--
-- 5. esya konuldugunda coin aninda envantere dusuyordu; oyuncu ne
-- kazandigini goremeden bitiyordu. Artik once bir gosteri oynuyor:
--
--   1) Iceri konan esyalarin renginde RUHLAR ekranda bir cember olusturur
--   2) Donerek merkeze kapanirlar ve beyaz bir patlamada birlesirler
--   3) Yeni kademenin renginde sok dalgasi ve yildizlar dagilir
--   4) Coinin adi okunur, sonra ekran soner
--
-- Sureler Shared > Fuse > Merge icinde; sunucu odulu tam bu sure sonunda
-- cantaya yaziyor, yani coin gosteri bitmeden envanterde belirmiyor.
------------------------------------------------------------------
local M = Fuse.Merge

-- Ruhlarin baslangicta durdugu cemberin yaricapi (piksel)
local SOUL_RADIUS = 130
local SOUL_SIZE = 34

local mergeRoot = Instance.new("Frame")
mergeRoot.Name = "BirlesmeGosterisi"
--[[
	GOSTERI EKRANIN ORTASINDA DURMALI

	Arayuz olcegi her ust duzey nesneye bir UIScale koyuyor ve UIScale
	nesneyi ANCHORPOINT'INDEN buyutuyor. Bu kare ekran kadar buyuk oldugu
	icin (0,0) ankoruyla %125 olcekte sag alta dogru kayiyordu -- ruhlar da
	onunla birlikte kosede doniyordu.

	Merkezden ankorlaninca olcek her yone esit acilir, sahne ortada kalir.
]]
mergeRoot.AnchorPoint = Vector2.new(0.5, 0.5)
mergeRoot.Position = UDim2.fromScale(0.5, 0.5)
mergeRoot.Size = UDim2.fromScale(1, 1)
mergeRoot.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mergeRoot.BackgroundTransparency = 1
mergeRoot.BorderSizePixel = 0
mergeRoot.Visible = false
-- Tiklamalari yutmasin: gosteri sirasinda oyuncu hareket edebilmeli
mergeRoot.Active = false
mergeRoot.Parent = screen

-- Ruhlarin ve parcaciklarin icinde yasadigi kare alan
local stage = Instance.new("Frame")
stage.Name = "Sahne"
stage.AnchorPoint = Vector2.new(0.5, 0.5)
stage.Position = UDim2.fromScale(0.5, 0.45)
stage.Size = UDim2.fromOffset(400, 400)
stage.BackgroundTransparency = 1
stage.Parent = mergeRoot

local mergeTitle = UI.text({
	text = "FUSING",
	size = UI.Sizes.small,
	font = UI.Fonts.bold,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 22),
	position = UDim2.new(0, 0, 0.5, -190),
	parent = mergeRoot,
})

local mergeName = UI.text({
	text = "",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 36),
	position = UDim2.new(0, 0, 0.5, 130),
	parent = mergeRoot,
})

local mergeSub = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 22),
	position = UDim2.new(0, 0, 0.5, 170),
	parent = mergeRoot,
})

-- Yuvarlak parlayan kure: hem ruhlar hem birlesme cekirdegi bundan
local function makeOrb(color: Color3, size: number): Frame
	local orb = Instance.new("Frame")
	orb.AnchorPoint = Vector2.new(0.5, 0.5)
	orb.Position = UDim2.fromScale(0.5, 0.5)
	orb.Size = UDim2.fromOffset(size, size)
	orb.BackgroundColor3 = color
	orb.BorderSizePixel = 0
	orb.Parent = stage

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = orb

	local halo = Instance.new("UIStroke")
	halo.Color = color:Lerp(Color3.new(1, 1, 1), 0.6)
	halo.Thickness = 3
	halo.Transparency = 0.2
	halo.Parent = orb

	return orb
end

local function clearStage()
	for _, child in stage:GetChildren() do
		child:Destroy()
	end
end

--[[
	Dagilan yildizlar.

	Kucuk kareler 45 derece dondurulunce elmas gibi duruyor; disari
	firlarken kuculup soluyorlar. Hazir bir gorsel gerekmiyor.
]]
local function burstStars(color: Color3, count: number)
	for index = 1, count do
		local angle = (index - 1) / count * math.pi * 2 + math.random() * 0.4
		local distance = 90 + math.random() * 90
		local size = 10 + math.random() * 10

		local star = Instance.new("Frame")
		star.AnchorPoint = Vector2.new(0.5, 0.5)
		star.Position = UDim2.fromScale(0.5, 0.5)
		star.Size = UDim2.fromOffset(size, size)
		star.Rotation = 45
		star.BackgroundColor3 = if index % 2 == 0 then color else Color3.new(1, 1, 1)
		star.BorderSizePixel = 0
		star.Parent = stage

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 3)
		corner.Parent = star

		TweenService:Create(star, TweenInfo.new(M.burstTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(angle) * distance, 0.5, math.sin(angle) * distance),
			Size = UDim2.fromOffset(0, 0),
			Rotation = 45 + 180,
			BackgroundTransparency = 1,
		}):Play()
	end
end

-- Merkezden disari acilan halka
local function shockwave(color: Color3)
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromOffset(40, 40)
	ring.BackgroundTransparency = 1
	ring.BorderSizePixel = 0
	ring.Parent = stage

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring

	local edge = Instance.new("UIStroke")
	edge.Color = color
	edge.Thickness = 6
	edge.Parent = ring

	local info = TweenInfo.new(M.burstTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, { Size = UDim2.fromOffset(340, 340) }):Play()
	TweenService:Create(edge, info, { Transparency = 1, Thickness = 0 }):Play()
end

--[[
	EKRAN SARSINTISI

	Kamerayi kisa sure boyunca rastgele oynatir; siddet sonuna dogru
	sonerek biter.

	RenderStep'e Camera onceliginden SONRA baglaniyor: Roblox kendi kamera
	guncellemesini yaptiktan sonra uzerine sapma ekliyoruz. Once baglansa
	varsayilan kamera her karede bizim degisikligimizi ezerdi.
]]
local SHAKE_NAME = "FuseSarsinti"
local shaking = false

local function shakeCamera(duration: number, strength: number)
	if shaking then
		return
	end
	shaking = true

	local elapsed = 0

	RunService:BindToRenderStep(SHAKE_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt)
		elapsed += dt

		local alpha = elapsed / duration
		if alpha >= 1 then
			RunService:UnbindFromRenderStep(SHAKE_NAME)
			shaking = false
			return
		end

		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end

		-- Kare (1-alpha)^2 ile soner: bas sert, son yumusak
		local power = strength * (1 - alpha) ^ 2

		camera.CFrame = camera.CFrame
			* CFrame.new((math.random() - 0.5) * power, (math.random() - 0.5) * power, 0)
			* CFrame.Angles(0, 0, (math.random() - 0.5) * power * 0.03)
	end)
end

-- Ayni anda iki gosteri oynamasin

local function playMerge(data: any)
	if merging then
		return
	end
	merging = true

	--[[
		Gosteri baslarken makine arayuzu kapanir: ruhlar donerken altta
		panel, ustte secim penceresi durmasi gosterinin onune geciyordu.
		Panel gosteri bitince FuseDurum ile kendiliginden geri gelir.
	]]
	secimPenceresi.Visible = false

	local fromColor = Rarity.color(data.fromRarity)
	local toColor = Rarity.color(data.toRarity)
	local soulCount = math.clamp(tonumber(data.souls) or Fuse.Required, 2, 12)

	clearStage()
	mergeName.Text = ""
	mergeSub.Text = ""
	UI.plainStyle(mergeName, UI.Colors.text)

	-- Gosteriyi gorev odulu de kullaniyor; baslik pakette gelirse o yazilir
	mergeTitle.Text = data.title or `FUSING {string.upper(Rarity.displayName(data.fromRarity))}`
	mergeTitle.TextColor3 = fromColor

	mergeRoot.Visible = true
	TweenService:Create(mergeRoot, TweenInfo.new(0.25), { BackgroundTransparency = 0.55 }):Play()

	------------------------------------------------------------------
	-- 1. ASAMA: ruhlar donerek merkeze kapanir
	------------------------------------------------------------------
	local souls: { Frame } = {}
	for index = 1, soulCount do
		souls[index] = makeOrb(fromColor, SOUL_SIZE)
	end

	local elapsed = 0
	local spin: RBXScriptConnection

	spin = RunService.RenderStepped:Connect(function(dt)
		elapsed += dt

		local alpha = math.min(elapsed / M.gatherTime, 1)
		-- Yumusak giris ve cikis: basta yavas, ortada hizli, sonda yavas
		local eased = alpha * alpha * (3 - 2 * alpha)

		local radius = SOUL_RADIUS * (1 - eased)
		local turn = eased * math.pi * 3

		for index, soul in souls do
			if not soul.Parent then
				continue
			end

			local angle = (index - 1) / soulCount * math.pi * 2 + turn
			soul.Position =
				UDim2.new(0.5, math.cos(angle) * radius, 0.5, math.sin(angle) * radius)

			-- Merkeze yaklastikca kuculurler
			local size = SOUL_SIZE * (1 - eased * 0.5)
			soul.Size = UDim2.fromOffset(size, size)
		end

		if alpha >= 1 then
			spin:Disconnect()
		end
	end)

	task.wait(M.gatherTime)

	------------------------------------------------------------------
	-- 2. ASAMA: beyaz patlama, ruhlar tek cekirdege doner
	------------------------------------------------------------------
	if spin.Connected then
		spin:Disconnect()
	end

	for _, soul in souls do
		soul:Destroy()
	end

	local core = makeOrb(Color3.new(1, 1, 1), 24)
	TweenService:Create(core, TweenInfo.new(M.flashTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(120, 120),
		BackgroundColor3 = toColor,
	}):Play()

	task.wait(M.flashTime)

	------------------------------------------------------------------
	-- 3. ASAMA: PATLAMA -- sok dalgasi, yildizlar, sarsinti ve sonuc
	--
	-- Bu an Fuse.burstDelay()'e denk gelir; sunucu dunyadaki FuseVFX
	-- patlamasini tam da simdi oynatiyor, yani ekran sarsintisi ile
	-- efekt ayni karede.
	------------------------------------------------------------------
	shakeCamera(M.shakeTime, M.shakeStrength)
	shockwave(toColor)
	burstStars(toColor, 16)

	-- Cekirdek coin haline gelir: kucuk bir madeni para gibi kalir
	TweenService:Create(core, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		Size = UDim2.fromOffset(76, 76),
	}):Play()

	mergeTitle.Text = data.endTitle or "FUSED"
	mergeTitle.TextColor3 = toColor

	mergeName.Text = data.coinName or ""
	UI.rarityStyle(mergeName, data.toRarity)

	--[[
		Alt satir: mutasyon aktarildiysa ONU yazar (satirin konusu odur,
		rengi de mutasyonun rengi olur). Aktarilmadiysa boyut rengiyle
		sade bir onay yazisi kalir.
	]]
	local mutationInfo = Mutations.get(data.mutation)

	if Mutations.isSpecial(data.mutation) then
		mergeSub.Text = `{mutationInfo.displayName} ({mutationInfo.multiplier}x)  --  added to your inventory`
		mergeSub.TextColor3 = mutationInfo.color
	else
		mergeSub.Text = "added to your inventory"
		mergeSub.TextColor3 = Condition.get(data.condition).color
	end

	task.wait(M.burstTime + M.holdTime)

	------------------------------------------------------------------
	-- Kapanis
	------------------------------------------------------------------
	local fade = TweenService:Create(mergeRoot, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
	fade:Play()
	fade.Completed:Wait()

	clearStage()
	mergeRoot.Visible = false
	merging = false

end

FuseSonuc.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" or type(data.toRarity) ~= "string" then
		return
	end
	task.spawn(playMerge, data)
end)

------------------------------------------------------------------
-- 3. COIN BOZDURUCU
------------------------------------------------------------------
local coinPanel = UI.panel(screen, UDim2.fromOffset(470, 440), "CoinBozdurucu")

UI.text({
	text = "Coin Trader",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = UI.Colors.gold,
	frameSize = UDim2.new(1, -80, 0, 36),
	position = UDim2.fromOffset(18, 14),
	parent = coinPanel,
})

local coinSubtitle = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 48),
	parent = coinPanel,
})

UI.closeButton(coinPanel).MouseButton1Click:Connect(function()
	coinPanel.Visible = false
end)

--[[
	Coin listesi ile cark AYNI PANELDE, ust uste durur.
	Cark donerken liste gizlenir; bitince geri gelir.
]]
local coinList = Instance.new("ScrollingFrame")
coinList.Name = "Liste"
coinList.Position = UDim2.fromOffset(14, 78)
coinList.Size = UDim2.new(1, -28, 1, -92)
coinList.BackgroundTransparency = 1
coinList.BorderSizePixel = 0
coinList.ScrollBarThickness = 5
coinList.ScrollBarImageColor3 = UI.Colors.panelLight
coinList.CanvasSize = UDim2.new()
coinList.AutomaticCanvasSize = Enum.AutomaticSize.Y
coinList.Parent = coinPanel

local coinLayout = Instance.new("UIListLayout")
coinLayout.Padding = UDim.new(0, 8)
coinLayout.SortOrder = Enum.SortOrder.LayoutOrder
coinLayout.Parent = coinList

local spinArea = Instance.new("Frame")
spinArea.Name = "CarkAlani"
spinArea.Position = UDim2.fromOffset(14, 78)
spinArea.Size = UDim2.new(1, -28, 1, -92)
spinArea.BackgroundTransparency = 1
spinArea.Visible = false
spinArea.Parent = coinPanel

local coinReel = Rulet.new(spinArea, {
	position = UDim2.new(0.5, 0, 0, 40),
	width = 408,
	height = 96,
	color = UI.Colors.gold,
	name = "Cark",
})

local coinResult = UI.text({
	text = "",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 26),
	position = UDim2.fromOffset(10, 150),
	parent = spinArea,
})

local coinDetail = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -20, 0, 22),
	position = UDim2.fromOffset(10, 178),
	parent = spinArea,
})

-- Coin satiri: renk kademeden, boyut solda rozet olarak
local function coinRow(coin: any, order: number): TextButton
	local rarityColor = Rarity.color(coin.rarity)
	local conditionInfo = Condition.get(coin.condition)

	--[[
		Satirda aciklama yok: coinin adi ("Gold Tiny Epic Coin") zaten
		kademeyi, boyutu ve mutasyonu soyluyor. Sagda yalnizca CARPANLAR
		duruyor -- ad onlari tasimiyor.
	]]
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, -6, 0, 48)
	row.BackgroundColor3 = UI.Colors.panelLight
	row.BorderSizePixel = 0
	-- Fare etkisi tiklanabilir satirda veriliyor (UI.hover)
	row.AutoButtonColor = false
	row.Text = ""
	row.LayoutOrder = order
	row.Parent = coinList
	UI.corner(row, 10)
	UI.stroke(row, rarityColor, 1)

	-- Madeni para ikonu
	local icon = Instance.new("Frame")
	icon.Size = UDim2.fromOffset(32, 32)
	icon.Position = UDim2.fromOffset(10, 8)
	icon.BackgroundColor3 = rarityColor
	icon.BorderSizePixel = 0
	icon.Parent = row
	UI.corner(icon, 16)

	UI.rarityStyle(
		UI.text({
			text = Fuse.coinName(coin.rarity, coin.condition, coin.mutation),
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = rarityColor,
			frameSize = UDim2.new(1, -170, 0, 24),
			position = UDim2.fromOffset(52, 12),
			parent = row,
		}),
		coin.rarity
	)

	-- Carpanlar: boyut her zaman, mutasyon varsa yaninda kendi renginde
	local mutationInfo = Mutations.get(coin.mutation)
	local special = Mutations.isSpecial(coin.mutation)

	UI.text({
		text = if special
			then `{conditionInfo.multiplier}x  {mutationInfo.multiplier}x`
			else `{conditionInfo.multiplier}x`,
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		-- Boyut carpani her zaman boyut renginde; mutasyon rengini ele gecirmez
		color = if special then mutationInfo.color else conditionInfo.color,
		align = Enum.TextXAlignment.Right,
		frameSize = UDim2.fromOffset(100, 24),
		position = UDim2.new(1, -112, 0, 12),
		parent = row,
	})

	return row
end

CoinAc.OnClientEvent:Connect(function(coins)
	if type(coins) ~= "table" then
		return
	end

	for _, child in coinList:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	coinSubtitle.Text = `{#coins} coins  -  click the one you want to trade`

	if #coins == 0 then
		UI.text({
			text = "You have no coins. Put 5 brainrots of the same tier into the Fuse Machine.",
			size = UI.Sizes.small,
			color = UI.Colors.textDim,
			align = Enum.TextXAlignment.Center,
			frameSize = UDim2.new(1, 0, 0, 40),
			parent = coinList,
			wrapped = true,
		})
	else
		for index, coin in coins do
			local row = coinRow(coin, index)
			row.MouseButton1Click:Connect(function()
				CoinBozdur:FireServer(coin.uid)
			end)

			UI.hover(row)
		end
	end

	spinArea.Visible = false
	coinList.Visible = true
	coinPanel.Visible = true
end)

CoinSonuc.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" or type(data.cells) ~= "table" then
		return
	end

	--[[
		Bolmeler: hepsi coinin kademesinden. Kademe zaten belli oldugu icin
		rarityCells verilmiyor -- Rulet tek asamali doner.

		COININ MUTASYONU SERIDE YANSIR: coin Gold ise hangi brainrot cikarsa
		ciksin Gold olacak, bu yuzden butun serit Gold renginde doner. Isme
		"Gold" yazmiyoruz -- 30 bolmede tekrarlanmasi gurultu olurdu; renk
		ayni bilgiyi tek bakista veriyor.
	]]
	local coinMutation = if type(data.winner) == "table" then data.winner.mutation else nil
	local wheelMutated = Mutations.isSpecial(coinMutation)
	local wheelColor = Mutations.get(coinMutation).color

	local cells: { Rulet.Cell } = {}
	for _, entry in data.cells do
		table.insert(cells, {
			text = entry.name,
			color = if wheelMutated then wheelColor else Rarity.color(entry.rarity),
		})
	end

	local started = Rulet.run(coinReel, {
		cells = cells,
		winner = tonumber(data.winnerIndex) or Fuse.Wheel.winnerIndex,
		time = tonumber(data.spinTime) or Fuse.Wheel.spinTime,

		onFinish = function()
			local winner = data.winner
			if type(winner) ~= "table" then
				return
			end

			Rulet.shake(coinPanel)

			local mutationInfo = Mutations.get(winner.mutation)
			local special = Mutations.isSpecial(winner.mutation)
			local conditionInfo = Condition.get(winner.condition)

			-- Isim kademe renginde; Epic+ parlar, Divine parildar
			coinResult.Text = winner.name
			UI.rarityStyle(coinResult, winner.rarity)

			-- Boyut satiri her zaman boyut renginde
			local tag = if special then `  {mutationInfo.displayName} ({mutationInfo.multiplier}x)` else ""
			coinDetail.Text =
				`{Rarity.displayName(winner.rarity)}  -  {conditionInfo.shortName}{tag}  -  {Format.perSecond(winner.income or 0)}`
			coinDetail.TextColor3 = conditionInfo.color
		end,
	})

	if not started then
		return
	end

	coinList.Visible = false
	spinArea.Visible = true
	coinPanel.Visible = true

	coinSubtitle.Text = if type(data.coinName) == "string" then data.coinName else ""
	coinResult.Text = "..."
	UI.plainStyle(coinResult, UI.Colors.text)
	coinDetail.Text = ""

	-- Cerceve de mutasyonun renginde: mutasyonlu coin ilk bakista belli olsun
	Rulet.tint(coinReel, if wheelMutated then wheelColor else UI.Colors.gold)
end)
