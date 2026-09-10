--[[
	Minigame  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Minigame

	Stardew Valley balik minioyununun kazi hali.

	Dusey bir cubukta:
	  - Yesil bar oyuncunun kontrolunde: tusa/ekrana BASILI TUTUNCA yukari cikar,
	    birakinca yercekimiyle duser
	  - Brainrot ikonu kacar; rarity yukseldikce daha sik ve daha sert sicrar
	  - Ikon barin icindeyken sagdaki ilerleme dolar, disindayken geriler
	  - Ilerleme dolarsa brainrot yakalanir, sifirlanirsa kacar

	Kurek leveli barin boyunu ve tepkiselligini artirir, gerilemeyi yavaslatir;
	yani yuksek level kurek yuksek rarity brainrotlari tutulabilir kilar.
	Butun bu dengeler Shared > Shovels ve Shared > Rarity icinde ayarlanir.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DigMinigame = require(Shared:WaitForChild("DigMinigame"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Shovels = require(Shared:WaitForChild("Shovels"))
local Net = require(Shared:WaitForChild("Net"))

local UI = require(script.Parent:WaitForChild("UI"))

local MinigameBasla = Net.event("MinigameBasla")
local MinigameSonuc = Net.event("MinigameSonuc")
local KaziBitti = Net.event("KaziBitti")

local ACTION_NAME = "KaziMinigameTut"

------------------------------------------------------------------
-- ARAYUZ
------------------------------------------------------------------
local screen = Instance.new("ScreenGui")
screen.Name = "KaziMinigame"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Enabled = false
screen.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(300, 580)
root.BackgroundColor3 = UI.Colors.panel
root.BackgroundTransparency = 0.08
root.BorderSizePixel = 0
root.Parent = screen
UI.corner(root, 16)

local rootStroke = UI.stroke(root, UI.Colors.accent, 2)

local header = UI.text({
	text = "",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -24, 0, 32),
	position = UDim2.fromOffset(12, 14),
	parent = root,
	name = "Baslik",
})

local subHeader = UI.text({
	text = "Hold the key and keep the brainrot inside the bar",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -24, 0, 20),
	position = UDim2.fromOffset(12, 48),
	parent = root,
	name = "AltBaslik",
})

-- Dusey kacis cubugu
local track = Instance.new("Frame")
track.Name = "Track"
track.AnchorPoint = Vector2.new(0.5, 0)
track.Position = UDim2.new(0.42, 0, 0, 84)
track.Size = UDim2.fromOffset(84, 460)
track.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
track.BorderSizePixel = 0
track.ClipsDescendants = true
track.Parent = root
UI.corner(track, 12)

-- Oyuncunun kontrol ettigi yesil bar
local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.AnchorPoint = Vector2.new(0.5, 0.5)
bar.Size = UDim2.new(1, -12, 0, 60)
bar.Position = UDim2.fromScale(0.5, 0.5)
bar.BackgroundColor3 = Color3.fromRGB(86, 206, 122)
bar.BackgroundTransparency = 0.25
bar.BorderSizePixel = 0
bar.Parent = track
UI.corner(bar, 8)

-- Kacan brainrot ikonu: yazisiz, sabit kirmizi-turuncu blok
local TARGET_COLOR = Color3.fromRGB(255, 108, 40)

local target = Instance.new("Frame")
target.Name = "Target"
target.AnchorPoint = Vector2.new(0.5, 0.5)
target.Size = UDim2.fromOffset(44, 44)
target.Position = UDim2.fromScale(0.5, 0.5)
target.BackgroundColor3 = TARGET_COLOR
target.BorderSizePixel = 0
target.Parent = track
UI.corner(target, 10)

UI.stroke(target, Color3.fromRGB(255, 168, 90), 2)

-- Ilerleme cubugu (sagda)
local progressTrack = Instance.new("Frame")
progressTrack.Name = "ProgressTrack"
progressTrack.AnchorPoint = Vector2.new(0.5, 0)
progressTrack.Position = UDim2.new(0.82, 0, 0, 84)
progressTrack.Size = UDim2.fromOffset(26, 460)
progressTrack.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
progressTrack.BorderSizePixel = 0
progressTrack.ClipsDescendants = true
progressTrack.Parent = root
UI.corner(progressTrack, 10)

local progressFill = Instance.new("Frame")
progressFill.Name = "Fill"
progressFill.AnchorPoint = Vector2.new(0.5, 1)
progressFill.Position = UDim2.fromScale(0.5, 1)
progressFill.Size = UDim2.new(1, 0, 0.35, 0)
progressFill.BackgroundColor3 = UI.Colors.good
progressFill.BorderSizePixel = 0
progressFill.Parent = progressTrack
UI.corner(progressFill, 10)

local hint = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -24, 0, 20),
	position = UDim2.new(0, 12, 1, -30),
	parent = root,
	name = "Ipucu",
})

------------------------------------------------------------------
-- OYUN DONGUSU
------------------------------------------------------------------
local active: DigMinigame.Minigame? = nil
local holding = false
local connection: RBXScriptConnection? = nil

--[[
	KAZMA ANIMASYONU

	Kurek Tool'unun uzerine sunucuda yazilan "DigAnimation" niteligini okur
	ve minigame SURESINCE dongu halinde oynatir; minigame biter bitmez durur.

	Id tek bir yerden geliyor: Shared > Assets > Animations > shovelDig.
	Orasi bos birakildigi surece nitelik hic yazilmaz ve burasi sessizce
	atlanir -- yani animasyon hazir olmadan da oyun calisir.

	Oncelik tutma animasyonundan (Action) bir kademe YUKSEK: kazarken kazma
	pozu tutma pozunu ezmeli.
]]
local digTrack: AnimationTrack? = nil

local function stopDigAnimation()
	if digTrack then
		digTrack:Stop(0.15)
		digTrack:Destroy()
		digTrack = nil
	end
end

local function startDigAnimation()
	stopDigAnimation()

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not character or not animator then
		return
	end

	-- Elde kurek var mi, uzerinde kazma animasyonu tanimli mi
	local id: string? = nil
	for _, item in character:GetChildren() do
		if item:IsA("Tool") and item:GetAttribute("ShovelId") then
			id = item:GetAttribute("DigAnimation") :: string?
			break
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
end

local function setHolding(value: boolean)
	holding = value
	bar.BackgroundTransparency = if value then 0.1 else 0.3
end

local function bindInput()
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
	unbindInput()
	stopDigAnimation()
	screen.Enabled = false
end

--[[
	PERFECT rozeti.
	Hedef bastan sona hic yesil barin disina cikmadiysa gosterilir:
	0.5 saniye ekranda kalir ve panel hafifce titrer.
]]
local perfectLabel = UI.text({
	text = "PERFECT!",
	size = UI.Sizes.huge,
	font = UI.Fonts.bold,
	color = Color3.fromRGB(255, 226, 90),
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, 0, 0, 48),
	position = UDim2.new(0, 0, 0.5, -24),
	parent = screen,
	name = "Perfect",
	outline = true,
	zIndex = 20,
})
perfectLabel.Visible = false

-- Hedef bu turda barin disina hic cikti mi
local everLeft = false

local function shakeScreen()
	local origin = root.Position

	task.spawn(function()
		local rng = Random.new()
		for _ = 1, 10 do
			root.Position = origin + UDim2.fromOffset(rng:NextInteger(-5, 5), rng:NextInteger(-5, 5))
			task.wait(0.03)
		end
		root.Position = origin
	end)
end

local function showPerfect()
	perfectLabel.Visible = true
	shakeScreen()

	task.delay(0.5, function()
		perfectLabel.Visible = false
	end)
end

local function finish(won: boolean)
	if not active then
		return
	end
	active = nil

	if connection then
		connection:Disconnect()
		connection = nil
	end
	unbindInput()
	stopDigAnimation()

	-- Sonuc gorseli kisa sure ekranda kalir
	rootStroke.Color = if won then UI.Colors.good else UI.Colors.bad
	header.Text = if won then "CAUGHT IT!" else "IT GOT AWAY!"
	-- Kademe gorunumu (parilti / parildama) kalkmali, yoksa rengi ezer
	UI.plainStyle(header, if won then UI.Colors.good else UI.Colors.bad)

	if won and not everLeft then
		showPerfect()
	end

	MinigameSonuc:FireServer(won)

	task.delay(0.7, function()
		-- Bu arada yeni bir kazi baslamadiysa kapat
		if not active then
			screen.Enabled = false
		end
	end)
end

local function render(state: DigMinigame.State)
	-- Cubuk 0..1 -> ekranda ust 0, alt 1 olacak sekilde ters cevrilir
	local barHeight = state.barSize
	bar.Size = UDim2.new(1, -12, barHeight, 0)
	bar.Position = UDim2.fromScale(0.5, 1 - state.barPosition)

	target.Position = UDim2.fromScale(0.5, 1 - state.targetPosition)

	progressFill.Size = UDim2.new(1, 0, state.progress, 0)

	local inside = math.abs(state.targetPosition - state.barPosition) <= state.barSize * 0.5
	if not inside then
		everLeft = true
	end

	progressFill.BackgroundColor3 = if inside then UI.Colors.good else UI.Colors.warn
end

MinigameBasla.OnClientEvent:Connect(function(shovelId, rarityId, seed)
	if active then
		return
	end

	local rarityInfo = Rarity.get(rarityId)
	local shovelInfo = Shovels.get(shovelId)

	header.Text = `{rarityInfo.displayName} BRAINROT`
	-- Epic+ parlak, Divine parildar; cerceve kademe renginde kalir
	UI.rarityStyle(header, rarityId)
	rootStroke.Color = rarityInfo.color

	subHeader.Text = `{shovelInfo.displayName}  |  Lv.{shovelInfo.level}`
	hint.Text = if UserInputService.TouchEnabled
		then "Touch and hold the screen"
		else "Hold SPACE or left click"

	-- Hedef her rarityde ayni kirmizi-turuncu; rarity rengi baslikta ve cercevede
	target.BackgroundColor3 = TARGET_COLOR

	everLeft = false
	perfectLabel.Visible = false
	active = DigMinigame.new(shovelId, rarityId, seed)
	screen.Enabled = true
	bindInput()
	startDigAnimation()

	render((active :: any).state)

	connection = RunService.RenderStepped:Connect(function(dt)
		local game_ = active
		if not game_ then
			return
		end

		-- Cok buyuk dt sicramalarini kirp (kare dususu oyunu bozmasin)
		local step = math.min(dt, 1 / 20)
		local state = game_:step(step, holding)
		render(state)

		if state.finished then
			finish(state.won)
		end
	end)
end)

-- Server kaziyi iptal ederse (uzaklasma, olum vs.)
KaziBitti.OnClientEvent:Connect(function()
	if active then
		stop()
	end
end)

-- Karakter olurse minigame kapansin
player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		if active then
			MinigameSonuc:FireServer(false)
			stop()
		end
	end)
end)
