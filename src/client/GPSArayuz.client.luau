--[[
	GPSArayuz  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > GPSArayuz

	Brainrot GPS'in ekran tarafi.

	Kumlu alandayken server periyodik olarak yakindaki isik suzmelerini gonderir.
	Bu script:
	  - Her suzmenin uzerine rarity'sini yazan bir dunya etiketi koyar
	  - Ekranin kenarinda suzmeleri mesafeye gore siralayan bir liste gosterir
	  - En yakin suzme kazi mesafesindeyse "E ile kaz" ipucu verir

	Oyuncu suzmenin rengine bakip kazip kazmayacagina kendisi karar verir;
	kum artik dogrudan kazilmaz.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Icons = require(Shared:WaitForChild("Icons"))
local Net = require(Shared:WaitForChild("Net"))

local UI = require(script.Parent:WaitForChild("UI"))

local GPSGuncelle = Net.event("GPSGuncelle")
local SuzmeKaz = Net.event("SuzmeKaz")

local DIG_ACTION = "SuzmeKazEylemi"
local G = Config.GPS

------------------------------------------------------------------
-- ARAYUZ
------------------------------------------------------------------
local screen = Instance.new("ScreenGui")
screen.Name = "BrainrotGPS"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Enabled = true
screen.Parent = playerGui

-- Ekran altindaki kazi ipucu
local hint = Instance.new("Frame")
hint.Name = "KaziIpucu"
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -110)
-- Madende solda ikon duruyor; yazi sigsin diye 280'den genisletildi
hint.Size = UDim2.fromOffset(310, 44)
hint.BackgroundColor3 = UI.Colors.panel
hint.BackgroundTransparency = 0.1
hint.BorderSizePixel = 0
hint.Visible = false
hint.Parent = screen
UI.corner(hint, 12)

local hintStroke = UI.stroke(hint, UI.Colors.good, 2)

local hintLabel = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = hint,
})

-- Maden suzmesinde ipucunun solunda madenin ikonu (Assets > Icons)
local hintIkon = Instance.new("ImageLabel")
hintIkon.Name = "MadenIkonu"
hintIkon.AnchorPoint = Vector2.new(0, 0.5)
hintIkon.Position = UDim2.new(0, 10, 0.5, 0)
hintIkon.Size = UDim2.fromOffset(28, 28)
hintIkon.BackgroundTransparency = 1
hintIkon.ScaleType = Enum.ScaleType.Fit
hintIkon.Visible = false
hintIkon.Parent = hint

------------------------------------------------------------------
-- DUNYA ETIKETLERI
------------------------------------------------------------------
local labelFolder = Instance.new("Folder")
labelFolder.Name = "GPSEtiketleri"
labelFolder.Parent = playerGui

-- [beamId] = BillboardGui
local labels: { [string]: BillboardGui } = {}
-- Server'dan gelen son liste
local beams: { { id: string, kind: string, position: Vector3 } } = {}
local nearest: { id: string, distance: number }? = nil

--[[
	Suzme turu kademe OLMAYABILIR (maden, "LuckyBlock").

	Onceden burada Rarity.get cagriliyordu; o bilinmeyen kimlikte assert
	atiyor ve hata bu fonksiyondan cagiran GPSGuncelle isleyicisine kadar
	firliyordu. Sonuc: bir Lucky Block suzmesi dogar dogmaz GPS arayuzunun
	tamami olu kaliyor, hicbir suzme kazilamiyordu. Artik uc turu de guvenle
	karsilayan paylasimli yardimcilar kullaniliyor.
]]
local function kindColor(kind: string): Color3
	return Rarity.beamColor(kind)
end

local function kindName(kind: string): string
	return string.upper(Rarity.beamName(kind))
end

local function makeLabel(beam: { id: string, kind: string, position: Vector3 }): BillboardGui
	-- Etiketin tutunacagi gorunmez bir nokta
	local anchor = Instance.new("Part")
	anchor.Name = `GPSAnchor_{beam.id}`
	anchor.Size = Vector3.one
	anchor.Position = beam.position + Vector3.new(0, 16, 0)
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Parent = Workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Name = `GPSLabel_{beam.id}`
	billboard.Adornee = anchor
	billboard.Size = UDim2.fromOffset(200, 56)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = G.scanRadius + 20
	billboard.Parent = labelFolder

	-- Anchor etiketle birlikte silinsin
	billboard.Destroying:Connect(function()
		if anchor.Parent then
			anchor:Destroy()
		end
	end)

	local color = kindColor(beam.kind)

	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
	card.BackgroundTransparency = 0.25
	card.BorderSizePixel = 0
	card.Parent = billboard
	UI.corner(card, 10)
	UI.stroke(card, color, 2)

	local kindLabel = UI.text({
		text = kindName(beam.kind),
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = color,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 24),
		position = UDim2.fromOffset(0, 5),
		parent = card,
		name = "Kind",
	})

	--[[
		Kademe suzmelerinde yazi kademesine gore biciimlenir: Epic ve ustu
		parlar, Divine sari <-> beyaz parildar. Rot Coin ve Lucky Block
		kademe olmadigi icin disarida kalir.
	]]
	if Rarity.Info[beam.kind] then
		UI.rarityStyle(kindLabel, beam.kind)
	end

	UI.text({
		text = "",
		size = UI.Sizes.small,
		color = UI.Colors.textDim,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.new(1, 0, 0, 20),
		position = UDim2.fromOffset(0, 29),
		parent = card,
		name = "Mesafe",
	})

	return billboard
end


------------------------------------------------------------------
-- KAZMA
------------------------------------------------------------------
local function digNearest()
	if not nearest then
		return
	end
	SuzmeKaz:FireServer(nearest.id)
end

--[[
	SOL TIK ile kazilir. Gamepad'de X yedek olarak duruyor.

	E TUSU KALDIRILDI: kazi hem kumda hem denizde yalnizca tiklamayla
	baslar. Kum minioyunu zaten tiklama tabanli oldugu icin ayni tus hem
	kaziyi baslatiyor hem ilk vurusu vuruyor -- arada tus degistirmek
	akisi boluyordu.

	Kurek oyuncunun elinde DEGILDIR -- kumda GPS tasiniyor. Suzmenin
	menziline girip sol tiklamak "kazmak istiyorum" demek: sunucu kuregi
	eline verir, kazi biter bitmez GPS geri gelir.

	Menzilde suzme yoksa digNearest hicbir sey yapmaz, yani bos tiklamalar
	zararsizdir. Eylem Pass donduruyor: tiklama yutulmuyor, tool ve arayuz
	kendi islerini gormeye devam ediyor.
]]
ContextActionService:BindAction(DIG_ACTION, function(_, state)
	if state == Enum.UserInputState.Begin then
		digNearest()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.KeyCode.ButtonX)

hint.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		digNearest()
	end
end)

------------------------------------------------------------------
-- GUNCELLEME
------------------------------------------------------------------
GPSGuncelle.OnClientEvent:Connect(function(list)
	beams = list or {}


	-- Artik olmayan etiketleri sil
	local alive: { [string]: boolean } = {}
	for _, beam in beams do
		alive[beam.id] = true
		if not labels[beam.id] then
			labels[beam.id] = makeLabel(beam)
		end
	end

	for id, billboard in labels do
		if not alive[id] then
			billboard:Destroy()
			labels[id] = nil
		end
	end

end)

-- Mesafeleri her karede degil, saniyede birkac kez guncelle
task.spawn(function()
	while true do
		task.wait(0.15)

		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			nearest = nil
			hint.Visible = false
			continue
		end

		local best: { id: string, distance: number, kind: string, sea: boolean }? = nil

		for _, beam in beams do
			local distance = (beam.position - root.Position).Magnitude

			local billboard = labels[beam.id]
			if billboard then
				local card = billboard:FindFirstChildWhichIsA("Frame")
				local distanceLabel = card and card:FindFirstChild("Mesafe")
				if distanceLabel and distanceLabel:IsA("TextLabel") then
					distanceLabel.Text = `{math.floor(distance)} studs`
				end
			end

			if not best or distance < best.distance then
				best = { id = beam.id, distance = distance, kind = beam.kind, sea = beam.sea == true }
			end
		end

		-- Girdaba olta uzaktan atilir; suzmeye ise sokulmak gerekir
		local erisim = if best and best.sea then G.seaDigDistance else G.digDistance

		if best and best.distance <= erisim then
			nearest = { id = best.id, distance = best.distance }

			--[[
				IPUCU HER KADEMEDE CIKAR

				Bir ara Epic ve ustunde gizleniyordu; ama ekranin altindaki
				bu yazi ayni zamanda "menzile girdin" demek oluyor. Gizli
				oldugunda oyuncu -- ozellikle denizde, girdap 30 stud oteden
				atildigi icin -- ne zaman tiklayabilecegini kestiremiyordu.
			]]
			local color = kindColor(best.kind)
			hintStroke.Color = color
			hintLabel.TextColor3 = color

			-- Madense ikon solda; yazi ona yer acmak icin biraz saga kayar
			local madenAnahtari = `ore_{best.kind}`
			local madenMi = Icons.Map[madenAnahtari] ~= nil
			if madenMi then
				Icons.bind(hintIkon, madenAnahtari)
			end
			hintIkon.Visible = madenMi
			hintLabel.Position = UDim2.fromOffset(if madenMi then 16 else 0, 0)

			-- Denizdeki girdapta "dig" degil "fish" yazar
			local eylem = if best.sea then "fish" else "dig"
			hintLabel.Text = if UserInputService.TouchEnabled
				then `{kindName(best.kind)} - tap to {eylem}`
				else `{kindName(best.kind)} - click to {eylem}`
			hint.Visible = true
		else
			nearest = nil
			hint.Visible = false
		end
	end
end)

Players.LocalPlayer.CharacterRemoving:Connect(function()
	hint.Visible = false
end)
