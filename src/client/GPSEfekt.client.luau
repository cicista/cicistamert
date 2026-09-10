--[[
	GPSEfekt  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > GPSEfekt

	ARAMA SINYALI

	Dedektor elde tutulurken antenin ucundaki topun etrafinda yesil bir
	halka acilir: kucucuk baslar, buyur, solar ve kaybolur. Ancak tamamen
	kaybolduktan sonra kisa bir sessizligin ardindan yenisi baslar --
	ekranda ayni anda hicbir zaman iki halka olmaz.

	Zeminde halka YOK; ayak dibindeki daireler kaldirildi.

	NEDEN ISTEMCIDE
	Tamamen gorsel; sunucuda uretilse saniyede ~20 kez replike edilir ve
	titrer. Divine parildamasi (IlahiRenk) ve base donmesi (BaseGorsel) ile
	ayni cozum.

	Halka YEREL uretilir ama HERKES bu script'i calistirdigi icin herkes
	birbirinin arama sinyalini gorur.

	Renk, hiz, sessizlik ve kalinlik: Shared > GPSEfekt
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GPSEfekt = require(Shared:WaitForChild("GPSEfekt"))

local A = GPSEfekt.Antenna

type Entry = {
	character: Model,
	tool: Tool,
	billboard: BillboardGui,
	frame: Frame,
	stroke: UIStroke,
}

-- [character] = efekt
local entries: { [Model]: Entry } = {}

------------------------------------------------------------------
-- PARCALAR
------------------------------------------------------------------

--[[
	Antenin ucundaki halka.

	Topa bagli bir BillboardGui: hangi acidan bakilirsa bakilsin halka
	kameraya donuk kalir. Billboard topun kendi altinda durdugu icin tool
	silindiginde onunla birlikte gider -- ayrica temizlemek gerekmez.

	Dolgu yok (BackgroundTransparency = 1); gorunen sey yalnizca UIStroke.
	UICorner yaricapi %100 oldugu icin kare cerceve tam daireye doner.
]]
local function makeSignal(ball: BasePart): (BillboardGui, Frame, UIStroke)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "GPSSinyali"
	billboard.Adornee = ball
	billboard.Size = UDim2.fromOffset(A.size, A.size)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = A.maxDistance
	billboard.LightInfluence = 0
	billboard.Parent = ball

	local frame = Instance.new("Frame")
	frame.Name = "Halka"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	-- En kucuk boyutta ve gorunmez baslar; ilk dongu de kucukten acilir
	frame.Size = UDim2.fromScale(A.minScale, A.minScale)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = GPSEfekt.color
	stroke.Thickness = A.thickness
	stroke.Transparency = 1
	stroke.Parent = frame

	return billboard, frame, stroke
end

------------------------------------------------------------------
-- TAKIP
------------------------------------------------------------------

-- Karakterin ELINDE dedektor var mi
local function heldDetector(character: Model): Tool?
	for _, item in character:GetChildren() do
		if item:IsA("Tool") and item:GetAttribute("DetectorId") then
			return item
		end
	end
	return nil
end

local function stop(character: Model)
	local entry = entries[character]
	if not entry then
		return
	end
	entries[character] = nil

	if entry.billboard.Parent then
		entry.billboard:Destroy()
	end
end

local function start(character: Model, tool: Tool)
	if entries[character] then
		return
	end

	--[[
		Anten topu bulunamayabilir: oyuncu Assets > Detectors icine kendi
		modelini koyduysa o modelde boyle bir parca olmayabilir. O zaman
		sinyal hic cizilmez, oyun normal calisir.
	]]
	local ball = tool:FindFirstChild(GPSEfekt.BallName)
	if not ball or not ball:IsA("BasePart") then
		return
	end

	local billboard, frame, stroke = makeSignal(ball)

	entries[character] = {
		character = character,
		tool = tool,
		billboard = billboard,
		frame = frame,
		stroke = stroke,
	}
end

--[[
	Kimde dedektor var, kimde yok -- her karede degil, saniyede birkac kez
	kontrol edilir. Tool kusanma/birakma o kadar hizli olmuyor.
]]
task.spawn(function()
	while true do
		task.wait(0.2)

		local alive: { [Model]: boolean } = {}

		for _, player in Players:GetPlayers() do
			local character = player.Character
			if not character then
				continue
			end

			local tool = heldDetector(character)
			if not tool then
				continue
			end

			alive[character] = true

			-- Tool degistiyse (seviye/skin yenilendi) sinyal yeniden kurulur
			local entry = entries[character]
			if entry and entry.tool ~= tool then
				stop(character)
				entry = nil
			end

			if not entry then
				start(character, tool)
			end
		end

		-- Dedektoru elinden birakanlarin ve ayrilanlarin sinyalini kaldir
		for character in entries do
			if not alive[character] then
				stop(character)
			end
		end
	end
end)

------------------------------------------------------------------
-- CIZIM
------------------------------------------------------------------

local function lerp(from: number, to: number, alpha: number): number
	return from + (to - from) * alpha
end

local elapsed = 0

RunService.RenderStepped:Connect(function(dt)
	elapsed += dt

	--[[
		Evre butun oyuncularda ORTAK hesaplaniyor; her karakterin kendi
		sayaci olsaydi ekranda birbirine karisan ritimler olurdu. Halka
		zaten tek oldugu icin ortak ritim daha duzenli gorunuyor.
	]]
	local phase = GPSEfekt.phase(elapsed)

	for character, entry in entries do
		--[[
			Karakter ya da tool gittiyse sinyal de gitsin. Tarama dongusu
			0.2 saniyede bir bakiyor; elden dusen bir GPS'in halkasi o kadar
			sure ortada kalmasin diye burada da kontrol ediliyor.
		]]
		if not character.Parent or entry.tool.Parent ~= character then
			stop(character)
			continue
		end

		if not phase then
			--[[
				Sessizlik ani: halka gorunmez.

				Boyut da EN KUCUGE cekiliyor. Yalnizca saydamlik
				ayarlansaydi halka gorunmezken son (en buyuk) boyutunda
				kalir ve yeni dongunun ilk karesinde bir an kocaman
				parlardi -- "once en buyuk cikiyor, sonra kuculuyor"
				denen sey buydu.
			]]
			entry.frame.Size = UDim2.fromScale(A.minScale, A.minScale)
			entry.stroke.Transparency = 1
			continue
		end

		-- Her dongu EN KUCUKTEN baslar, EN BUYUKTE solarak biter
		local scale = lerp(A.minScale, 1, phase)
		entry.frame.Size = UDim2.fromScale(scale, scale)
		entry.stroke.Transparency = lerp(A.fadeFrom, A.fadeTo, phase)
	end
end)
