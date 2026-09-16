--[[
	DenizAnimasyonlari  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > DenizAnimasyonlari

	FLYBOARD USTUNDEKI ANIMASYONLAR  (Shared > Assets > Animations)

	    flyboardIdle  tahtadayken SUREKLI (dongu)
	    rodCast       olta girdaba atilinca BIR KEZ (1.733 sn)
	    fishing       balik tutma minigame'i boyunca (dongu)

	Oncelikler ustten alta: rodCast > fishing > flyboardIdle. Ustteki
	oynarken alttaki devam eder ama gorunmez; bitince alttaki kalir.

	NE ZAMAN
	  - Tahtaya binince / inince: oyuncunun "Flyboarding" niteligi
	  - Olta atilinca: sunucu karaktere "OltaAtis" niteligini yazar
	    (bkz. Modules > Olta.cast)
	  - Minigame: sunucu MinigameBasla'yi "sea" moduyla gonderir, kazi
	    bitince KaziBitti gelir

	Animasyonlar oyuncunun kendi karakterinde oynatildigi icin diger
	oyunculara da gorunur.

	DUSME ANIMASYONU KAPALI
	Tahta karakteri havada tuttugu icin Humanoid kendini "dusuyor" sayip
	Roblox'un fall / jump animasyonunu da oynatiyordu; flyboardIdle ile
	karisinca karakter kambur duruyordu. Tahtadayken Freefall / Jumping /
	FallingDown durumlari kapatilir ve bu animasyonlar her karede durdurulur.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Net = require(Shared:WaitForChild("Net"))

local MinigameBasla = Net.event("MinigameBasla")
local KaziBitti = Net.event("KaziBitti")

type Izler = {
	idle: AnimationTrack?,
	cast: AnimationTrack?,
	fishing: AnimationTrack?,
}

local izler: Izler = {}
local baglantilar: { RBXScriptConnection } = {}

local function yukle(animator: Animator, anahtar: string, oncelik: Enum.AnimationPriority, dongu: boolean): AnimationTrack?
	local id = Assets.id(Assets.Animations[anahtar])
	if not id then
		return nil
	end

	local animasyon = Instance.new("Animation")
	animasyon.AnimationId = id

	local ok, track = pcall(function()
		return animator:LoadAnimation(animasyon)
	end)
	animasyon:Destroy()

	if not ok or not track then
		return nil
	end

	track.Priority = oncelik
	track.Looped = dongu
	return track
end

local function denizde(): boolean
	return player:GetAttribute("Flyboarding") == true
end

-- Tahtadayken kapatilan Humanoid durumlari
local KAPALI_DURUMLAR = {
	Enum.HumanoidStateType.Freefall,
	Enum.HumanoidStateType.Jumping,
	Enum.HumanoidStateType.FallingDown,
}

-- Animate scriptinin tahtada karismamasi gereken animasyonlari (Animation adlari)
local KARISAN_ANIMASYONLAR = {
	FallAnim = true,
	JumpAnim = true,
	fall = true,
	jump = true,
	SwimAnim = true,
	SwimIdle = true,
	swim = true,
	swimidle = true,
	ClimbAnim = true,
}

local function durumlariAyarla(tahtada: boolean)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	for _, durum in KAPALI_DURUMLAR do
		humanoid:SetStateEnabled(durum, not tahtada)
	end
	if tahtada then
		local simdiki = humanoid:GetState()
		if table.find(KAPALI_DURUMLAR, simdiki) then
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end
end

local function hepsiniDurdur()
	for _, track in { izler.idle, izler.cast, izler.fishing } do
		if track and track.IsPlaying then
			track:Stop(0.2)
		end
	end
end

-- Tahta durumuna gore duris animasyonu
local function durusuGuncelle()
	durumlariAyarla(denizde())
	if denizde() then
		if izler.idle and not izler.idle.IsPlaying then
			izler.idle:Play(0.25)
		end
	else
		hepsiniDurdur()
	end
end

local function karakterGeldi(character: Model)
	for _, baglanti in baglantilar do
		baglanti:Disconnect()
	end
	table.clear(baglantilar)
	izler = {}

	local humanoid = character:WaitForChild("Humanoid", 10)
	local animator = humanoid and humanoid:WaitForChild("Animator", 10)
	if not animator or not animator:IsA("Animator") then
		return
	end

	izler.idle = yukle(animator, "flyboardIdle", Enum.AnimationPriority.Action, true)
	izler.fishing = yukle(animator, "fishing", Enum.AnimationPriority.Action2, true)
	izler.cast = yukle(animator, "rodCast", Enum.AnimationPriority.Action3, false)

	-- Olta atildi: savurma bir kez oynar
	table.insert(
		baglantilar,
		character:GetAttributeChangedSignal("OltaAtis"):Connect(function()
			if denizde() and izler.cast then
				izler.cast:Play(0.1)
			end
		end)
	)

	durusuGuncelle()
end

player:GetAttributeChangedSignal("Flyboarding"):Connect(durusuGuncelle)

-- Tahtadayken dusme / ziplama / yuzme animasyonu oynamasin
RunService.RenderStepped:Connect(function()
	if not denizde() then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	for _, track in animator:GetPlayingAnimationTracks() do
		local animasyon = track.Animation
		if animasyon and KARISAN_ANIMASYONLAR[animasyon.Name] then
			track:Stop(0)
		end
	end
end)

MinigameBasla.OnClientEvent:Connect(function(_gearId, _rarityId, _seed, mod)
	if mod == "sea" and denizde() and izler.fishing and not izler.fishing.IsPlaying then
		izler.fishing:Play(0.2)
	end
end)

KaziBitti.OnClientEvent:Connect(function()
	if izler.fishing and izler.fishing.IsPlaying then
		izler.fishing:Stop(0.2)
	end
end)

player.CharacterAdded:Connect(karakterGeldi)
if player.Character then
	task.spawn(karakterGeldi, player.Character)
end
