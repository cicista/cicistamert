local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DigMinigame = require(Shared:WaitForChild("DigMinigame"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local KaziMinigame = require(Shared:WaitForChild("KaziMinigame"))
local OtoTiklayici = require(Shared:WaitForChild("OtoTiklayici"))
local Assets = require(Shared:WaitForChild("Assets"))

task.spawn(function()
	local liste = {}
	for _, ham in { Assets.Animations.shovelDig, Assets.Animations.pickaxeDig } do
		local gercek = Assets.id(ham)
		if gercek then
			local animasyon = Instance.new("Animation")
			animasyon.AnimationId = gercek
			table.insert(liste, animasyon)
		end
	end
	if #liste > 0 then
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync(liste)
		end)
	end
end)
local Ores = require(Shared:WaitForChild("Ores"))
local Icons = require(Shared:WaitForChild("Icons"))
local Net = require(Shared:WaitForChild("Net"))

local UI = require(script.Parent:WaitForChild("UI"))

local MinigameBasla = Net.event("MinigameBasla")
local MinigameSonuc = Net.event("MinigameSonuc")
local KaziBitti = Net.event("KaziBitti")
local Passler = require(Shared:WaitForChild("Passler"))
local PassSatinAl = Net.event("PassSatinAl")

local ACTION_NAME = "KaziMinigameTut"

local BalikPaneli = require(script.Parent:WaitForChild("BalikPaneli"))

local KUREK_IKONU = "rbxassetid://82895822894928"

local IKON_BOY = 96

local IKON_ACI = 90

local KAZMA_IKON_ADI = "pickaxe_icon"
local KAZMA_ACI = 0

local ikonAci = IKON_ACI
local kazmaUyarisiVerildi = false

local OTO_X = 0.72
local OTO_Y = 0.8

local OTO_BOY = 92

local KAZI_ARA = 14

local KAZI_BOY = 360

local TEHLIKE_ORANI = 0.16

local kaziEkran = Instance.new("ScreenGui")
kaziEkran.Name = "KaziBar"
kaziEkran.ResetOnSpawn = false
kaziEkran.IgnoreGuiInset = true
kaziEkran.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
kaziEkran.Enabled = false
kaziEkran.Parent = playerGui

local kaziCerceve = Instance.new("Frame")
kaziCerceve.Name = "Cerceve"
kaziCerceve.AnchorPoint = Vector2.new(0.5, 1)
kaziCerceve.Position = UDim2.new(OTO_X, 0, OTO_Y, -(OTO_BOY / 2 + KAZI_ARA))
kaziCerceve.Size = UDim2.fromOffset(74, KAZI_BOY)
kaziCerceve.BackgroundColor3 = Color3.fromRGB(74, 55, 36)
kaziCerceve.BorderSizePixel = 0
kaziCerceve.ClipsDescendants = true
kaziCerceve.Parent = kaziEkran
UI.corner(kaziCerceve, 6)
UI.stroke(kaziCerceve, Color3.fromRGB(0, 0, 0), 4)

local function dokuKat(parent: Instance, renk: Color3, saydam: number, aci: number, sikilik: number)
	local kat = Instance.new("Frame")
	kat.Name = "Doku"
	kat.Size = UDim2.fromScale(1, 1)
	kat.BackgroundColor3 = renk
	kat.BackgroundTransparency = saydam
	kat.BorderSizePixel = 0
	kat.ZIndex = 2
	kat.Parent = parent

	local stops = {}
	for i = 0, sikilik do
		local t = i / sikilik
		local acikMi = i % 2 == 0
		table.insert(stops, NumberSequenceKeypoint.new(t, if acikMi then 0 else 1))
	end

	local gecis = Instance.new("UIGradient")
	gecis.Rotation = aci
	gecis.Transparency = NumberSequence.new(stops)
	gecis.Parent = kat

	return kat
end

dokuKat(kaziCerceve, Color3.fromRGB(38, 27, 16), 0.55, 28, 17)
dokuKat(kaziCerceve, Color3.fromRGB(214, 184, 132), 0.82, -14, 11)

local kaziDolgu = Instance.new("Frame")
kaziDolgu.Name = "Dolgu"
kaziDolgu.AnchorPoint = Vector2.new(0.5, 1)
kaziDolgu.Position = UDim2.fromScale(0.5, 1)
kaziDolgu.Size = UDim2.fromScale(1, 0)
kaziDolgu.BackgroundColor3 = UI.Colors.good
kaziDolgu.BorderSizePixel = 0
kaziDolgu.ZIndex = 3
kaziDolgu.Parent = kaziCerceve

dokuKat(kaziDolgu, Color3.fromRGB(0, 0, 0), 0.7, 28, 17).ZIndex = 4
dokuKat(kaziDolgu, Color3.fromRGB(255, 255, 255), 0.86, -14, 11).ZIndex = 4

local kaziTehlike = Instance.new("Frame")
kaziTehlike.Name = "Tehlike"
kaziTehlike.AnchorPoint = Vector2.new(0.5, 1)
kaziTehlike.Position = UDim2.fromScale(0.5, 1)
kaziTehlike.Size = UDim2.fromScale(1, TEHLIKE_ORANI)
kaziTehlike.BackgroundColor3 = Color3.fromRGB(10, 8, 6)
kaziTehlike.BackgroundTransparency = 0.15
kaziTehlike.BorderSizePixel = 0
kaziTehlike.ZIndex = 6
kaziTehlike.Parent = kaziCerceve

local kaziKatman = Instance.new("Frame")
kaziKatman.Name = "IkonKatmani"
kaziKatman.AnchorPoint = kaziCerceve.AnchorPoint
kaziKatman.Position = kaziCerceve.Position
kaziKatman.Size = kaziCerceve.Size
kaziKatman.BackgroundTransparency = 1
kaziKatman.ZIndex = 8
kaziKatman.Parent = kaziEkran

local kaziIkon = Instance.new("ImageLabel")
kaziIkon.Name = "Kurek"
kaziIkon.AnchorPoint = Vector2.new(0.5, 0.5)
kaziIkon.Size = UDim2.fromOffset(IKON_BOY, IKON_BOY)
kaziIkon.BackgroundTransparency = 1
kaziIkon.Image = KUREK_IKONU
kaziIkon.Rotation = IKON_ACI
kaziIkon.ZIndex = 8
kaziIkon.Parent = kaziKatman

local otoKutu = Instance.new("Frame")
otoKutu.Name = "OtoTiklayici"
otoKutu.AnchorPoint = Vector2.new(0.5, 0.5)
otoKutu.Position = UDim2.fromScale(OTO_X, OTO_Y)
otoKutu.Size = UDim2.fromOffset(176, OTO_BOY)
otoKutu.BackgroundTransparency = 1
otoKutu.Visible = true
otoKutu.ZIndex = 8
otoKutu.Parent = kaziEkran

UI.text({
	text = "AUTO CLICKER",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 22),
	position = UDim2.fromOffset(0, 0),
	parent = otoKutu,
	name = "Baslik",
})

local otoDugme = Instance.new("TextButton")
otoDugme.Name = "Dugme"
otoDugme.Position = UDim2.fromOffset(0, 30)
otoDugme.Size = UDim2.new(1, 0, 0, 58)
otoDugme.BackgroundColor3 = UI.Colors.bad
otoDugme.BorderSizePixel = 0
otoDugme.AutoButtonColor = false
otoDugme.Text = ""
otoDugme.ZIndex = 8
otoDugme.Parent = otoKutu
UI.corner(otoDugme, 10)
UI.stroke(otoDugme, Color3.fromRGB(0, 0, 0), 3)

local otoYazi = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = otoDugme,
	name = "Label",
	zIndex = 9,
})

local otoRenk = UI.Colors.bad

otoDugme.MouseEnter:Connect(function()
	otoDugme.BackgroundColor3 = UI.shade(otoRenk, UI.HoverLift)
end)

otoDugme.MouseLeave:Connect(function()
	otoDugme.BackgroundColor3 = otoRenk
end)

local otoSahip = Passler.sahip(player, "AutoClicker")

local otoAcik = true

local function otoCalisiyorMu(): boolean
	return otoSahip and otoAcik
end

local otoFiyat: Frame? = nil

local function otoDugmeyiCiz()
	otoKutu.Visible = true

	if not otoSahip then
		local pass = Passler.get("AutoClicker")

		if not otoFiyat then
			otoFiyat = UI.robuxFiyati(otoDugme, if pass then pass.fiyat else 0, UI.Sizes.label, 10)
		end
		local kutu = otoFiyat
		if kutu then
			kutu.Visible = true
		end

		otoYazi.Text = ""
		otoRenk = UI.Colors.gold
		otoDugme.BackgroundColor3 = otoRenk
		return
	end

	local kutu = otoFiyat
	if kutu then
		kutu.Visible = false
	end

	otoYazi.Text = if otoAcik then "ON" else "OFF"
	otoRenk = if otoAcik then UI.Colors.good else UI.Colors.bad
	otoDugme.BackgroundColor3 = otoRenk
end

otoDugmeyiCiz()

otoDugme.Activated:Connect(function()
	if not otoSahip then
		PassSatinAl:FireServer("AutoClicker")
		return
	end

	otoAcik = not otoAcik
	otoDugmeyiCiz()
end)

do
	local pass = Passler.get("AutoClicker")
	if pass then
		player:GetAttributeChangedSignal(pass.nitelik):Connect(function()
			otoSahip = Passler.sahip(player, "AutoClicker")
			otoDugmeyiCiz()
		end)
	end
end

local SARSINTI_ADI = "KaziSarsinti"

local SONUM = 7

local TIK_GUCU = 1.1
local TIK_TAVAN = 2.6

local ZAFER_GUCU = 7

local sarsintiGucu = 0
local vurusGucu = 0

local vurusYon = 1
local sarsintiBagli = false
local rng = Random.new()

local function sarsintiKapali(): boolean
	return game:GetService("Players").LocalPlayer:GetAttribute("SarsintiKapali") == true
end

local function sarsintiyiBagla()
	if sarsintiBagli then
		return
	end
	sarsintiBagli = true

	RunService:BindToRenderStep(SARSINTI_ADI, Enum.RenderPriority.Camera.Value + 1, function(dt)
		sarsintiGucu = math.max(0, sarsintiGucu - dt * SONUM)
		vurusGucu = math.max(0, vurusGucu - dt * SONUM)

		local v = math.min(vurusGucu, 1)
		kaziIkon.Size = UDim2.fromOffset(IKON_BOY + v * 45, IKON_BOY + v * 45)
		kaziIkon.Rotation = ikonAci + vurusYon * v * 27

		if sarsintiGucu <= 0 or sarsintiKapali() then
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		local g = sarsintiGucu
		camera.CFrame = camera.CFrame
			* CFrame.new(rng:NextNumber(-g, g) * 0.5, rng:NextNumber(-g, g) * 0.5, 0)
			* CFrame.Angles(0, 0, math.rad(rng:NextNumber(-g, g) * 2.2))
	end)
end

local function sarsintiyiCoz()
	if not sarsintiBagli then
		return
	end
	sarsintiBagli = false
	RunService:UnbindFromRenderStep(SARSINTI_ADI)

	sarsintiGucu = 0
	vurusGucu = 0
	kaziIkon.Size = UDim2.fromOffset(IKON_BOY, IKON_BOY)
	kaziIkon.Rotation = ikonAci
end
local kaziRenk = UI.Colors.good

local OGRETICI_NITELIK = "OgreticiAdim"
local OGRETICI_ADIM = "ilkKazi"
local OGRETICI_TABAN = 0.06

local function ogreticiKazisi(): boolean
	return player:GetAttribute(OGRETICI_NITELIK) == OGRETICI_ADIM
end

local tiklaYazilari: { TextLabel } = {}

for i, x in { 0.5 - 0.26, 0.5 + 0.26 } do
	local yazi = UI.text({
		text = "CLICK!",
		size = UI.Sizes.huge,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(255, 240, 120),
		align = Enum.TextXAlignment.Center,
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(x, 0.5),
		frameSize = UDim2.fromOffset(220, 60),
		parent = kaziEkran,
		name = `Tikla{i}`,
	})
	yazi.Visible = false
	yazi.ZIndex = 20
	table.insert(tiklaYazilari, yazi)
end

local tiklaZaman = 0

local function tiklaYazisiCiz(dt: number, acik: boolean)
	if not acik then
		for _, yazi in tiklaYazilari do
			yazi.Visible = false
		end
		return
	end

	tiklaZaman += dt
	for i, yazi in tiklaYazilari do
		yazi.Visible = true
		local nabiz = (math.sin(tiklaZaman * 7 + (i - 1) * math.pi) + 1) * 0.5
		yazi.TextSize = math.floor(UI.Sizes.huge * (0.85 + nabiz * 0.4))
		yazi.TextTransparency = 0.15 - nabiz * 0.15
		yazi.Rotation = (if i == 1 then -8 else 8) * (0.5 + nabiz)
	end
end

local mod: string = "sea"
local active: DigMinigame.Minigame? = nil
local kazi: KaziMinigame.Game? = nil
local holding = false
local connection: RBXScriptConnection? = nil

local throttleUntil = 0

local function calisiyor(): boolean
	return active ~= nil or kazi ~= nil
end

local digTrack: AnimationTrack? = nil

local donusHumanoid: Humanoid? = nil
local donusEski: boolean? = nil

local function stopDigAnimation()
	if digTrack then
		digTrack:Stop(0.15)
		digTrack:Destroy()
		digTrack = nil
	end

	if donusHumanoid and donusEski ~= nil and donusHumanoid.Parent then
		donusHumanoid.AutoRotate = donusEski
	end
	donusHumanoid = nil
	donusEski = nil
end

local function startDigAnimation()
	stopDigAnimation()

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not character or not animator then
		return
	end

	local id: string? = nil
	for deneme = 1, 10 do
		for _, item in character:GetChildren() do
			if item:IsA("Tool") then
				if item:GetAttribute("PickaxeId") then
					id = Assets.id(Assets.Animations.pickaxeDig)
					break
				elseif item:GetAttribute("ShovelId") then
					id = Assets.id(Assets.Animations.shovelDig)
					break
				end
			end
		end
		if id or deneme == 10 then
			break
		end
		task.wait(0.05)
		if not calisiyor() then
			return
		end
	end

	if not id or id == "" then
		return
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = id

	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	animation:Destroy()

	if not ok or not track then
		return
	end

	track.Priority = Enum.AnimationPriority.Action2
	track.Looped = true
	track:Play(0.1)
	digTrack = track

	local humanoidDon = character:FindFirstChildOfClass("Humanoid")
	local kok = character:FindFirstChild("HumanoidRootPart")
	local hedef = character:GetAttribute("KaziHedef")
	if humanoidDon and kok and kok:IsA("BasePart") and typeof(hedef) == "Vector3" then
		donusHumanoid = humanoidDon
		donusEski = humanoidDon.AutoRotate
		humanoidDon.AutoRotate = false
		local bakis = Vector3.new(hedef.X, kok.Position.Y, hedef.Z)
		if (bakis - kok.Position).Magnitude > 0.5 then
			kok.CFrame = CFrame.lookAt(kok.Position, bakis)
		end
	end
end

local function setHolding(value: boolean)
	holding = value
end

local function tikla()
	local oyun = kazi
	if not oyun then
		return
	end

	if not oyun:click() then
		throttleUntil = os.clock() + 0.4
		return
	end

	sarsintiGucu = math.min(TIK_TAVAN, sarsintiGucu + TIK_GUCU)
	vurusGucu = math.min(TIK_TAVAN, vurusGucu + TIK_GUCU)

	vurusYon = -vurusYon
end

local function bindInput()
	if mod == "sand" then
		ContextActionService:BindAction(ACTION_NAME, function(_, state)
			if state == Enum.UserInputState.Begin then
				tikla()
			end
			return Enum.ContextActionResult.Sink
		end, true, Enum.KeyCode.Space, Enum.KeyCode.ButtonA, Enum.UserInputType.MouseButton1)

		ContextActionService:SetTitle(ACTION_NAME, "KAZ")
		return
	end

	ContextActionService:BindAction(ACTION_NAME, function(_, state)
		if state == Enum.UserInputState.Begin then
			setHolding(true)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			setHolding(false)
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.Space, Enum.KeyCode.ButtonA, Enum.UserInputType.MouseButton1)

	ContextActionService:SetTitle(ACTION_NAME, "TUT")
end

local function unbindInput()
	ContextActionService:UnbindAction(ACTION_NAME)
	setHolding(false)
end

local function stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	active = nil
	kazi = nil
	unbindInput()
	stopDigAnimation()
	BalikPaneli.gizle()
	kaziEkran.Enabled = false
	sarsintiyiCoz()
end

local function finish(won: boolean)
	if not calisiyor() then
		return
	end

	local kumdu = mod == "sand"
	active = nil
	kazi = nil

	if connection then
		connection:Disconnect()
		connection = nil
	end
	unbindInput()
	stopDigAnimation()

	if kumdu then
		if won then
			sarsintiGucu = ZAFER_GUCU
			vurusGucu = TIK_TAVAN
		end

		kaziEkran.Enabled = false
		task.delay(0.8, sarsintiyiCoz)

		MinigameSonuc:FireServer(won)
		return
	end

	BalikPaneli.bitir(won)

	MinigameSonuc:FireServer(won)

	task.delay(1.2, function()
		if not calisiyor() then
			BalikPaneli.gizle()
		end
	end)
end

local function renderKazi(state: KaziMinigame.State)
	kaziDolgu.Size = UDim2.fromScale(1, state.progress)

	kaziIkon.Position = UDim2.fromScale(0.5, 1 - state.progress)

	local kisildi = os.clock() < throttleUntil
	kaziDolgu.BackgroundColor3 = if kisildi then UI.Colors.warn else kaziRenk

	local tehlikede = state.progress <= TEHLIKE_ORANI
	kaziTehlike.BackgroundTransparency = if tehlikede then 0 else 0.15
	kaziTehlike.BackgroundColor3 = if tehlikede
		then Color3.fromRGB(90, 12, 12)
		else Color3.fromRGB(10, 8, 6)
end

local function modKur(yeniMod: string, rarityId: string)
	mod = yeniMod
	local kumdu = yeniMod == "sand"

	if kumdu then
		BalikPaneli.gizle()
	end
	kaziEkran.Enabled = kumdu

	if kumdu then
		local maden = Ores.get(rarityId)
		kaziRenk = if maden then maden.islandColor else Rarity.beamColor(rarityId)

		local kazmaResmi = if maden then Icons.asset(KAZMA_IKON_ADI) else nil
		if maden and not kazmaResmi and not kazmaUyarisiVerildi then
			kazmaUyarisiVerildi = true
			warn(
				`[Minigame] Kazma ikonu bulunamadi: ReplicatedStorage > Assets > Icons `
					.. `icine "{KAZMA_IKON_ADI}" adli bir Decal ya da ImageLabel koy. Simdilik kurek gorunuyor.`
			)
		end
		kaziIkon.Image = kazmaResmi or KUREK_IKONU
		ikonAci = if kazmaResmi then KAZMA_ACI else IKON_ACI
		kaziIkon.Rotation = ikonAci
		kaziDolgu.BackgroundColor3 = kaziRenk
		kaziDolgu.Size = UDim2.fromScale(1, KaziMinigame.START)
		sarsintiyiBagla()
	else
		sarsintiyiCoz()
	end
end

MinigameBasla.OnClientEvent:Connect(function(gearId, rarityId, seed, gelenMod)
	if calisiyor() then
		return
	end

	local gearInfo = DigMinigame.gear(gearId)

	modKur(if gelenMod == "sand" then "sand" else "sea", rarityId)

	throttleUntil = 0
	task.spawn(startDigAnimation)

	if mod == "sand" then
		local oyun = KaziMinigame.new(gearId, rarityId)
		kazi = oyun

		bindInput()
		renderKazi(oyun.state)

		local otoBirikim = 0

		connection = RunService.RenderStepped:Connect(function(dt)
			local g = kazi
			if not g then
				return
			end

			local step = math.min(dt, 1 / 20)
			local state = g:step(step)

			local ogreticide = ogreticiKazisi()
			if ogreticide and state.finished and not state.won then
				state.finished = false
				state.won = false
				state.progress = OGRETICI_TABAN
			end

			tiklaYazisiCiz(step, ogreticide and not state.finished)

			if otoCalisiyorMu() then
				otoBirikim += step
				while otoBirikim >= OtoTiklayici.ARALIK do
					otoBirikim -= OtoTiklayici.ARALIK
					tikla()
				end
			end

			renderKazi(state)

			if state.finished then
				tiklaYazisiCiz(step, false)
				finish(state.won)
			end
		end)
		return
	end

	BalikPaneli.basla(gearInfo, rarityId)

	local oyun = DigMinigame.new(gearId, rarityId, seed)
	active = oyun
	bindInput()
	BalikPaneli.ciz(oyun.state, holding)

	connection = RunService.RenderStepped:Connect(function(dt)
		local g = active
		if not g then
			return
		end

		local step = math.min(dt, 1 / 20)
		local state = g:step(step, holding)
		BalikPaneli.ciz(state, holding)

		if state.finished then
			finish(state.won)
		end
	end)
end)

KaziBitti.OnClientEvent:Connect(function()
	if calisiyor() then
		stop()
	end
end)

player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		if calisiyor() then
			MinigameSonuc:FireServer(false)
			stop()
		end
	end)
end)
