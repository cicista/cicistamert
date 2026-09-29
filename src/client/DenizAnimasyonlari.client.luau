local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Net = require(Shared:WaitForChild("Net"))

local MinigameBasla = Net.event("MinigameBasla")
local KaziBitti = Net.event("KaziBitti")

local YerelSes = require(script.Parent:WaitForChild("YerelSes"))

local RODCAST_GECIKME = 0.5
local atisNo = 0
local atisBitti = true
local balikSesi: Sound? = nil

local function balikSesiniDurdur()
	YerelSes.durdur(balikSesi)
	balikSesi = nil
end

local function oltaSesleri()
	atisNo += 1
	local no = atisNo
	atisBitti = false
	balikSesiniDurdur()

	task.delay(RODCAST_GECIKME, function()
		if no ~= atisNo or atisBitti then
			return
		end
		local ses, sure = YerelSes.cal("RodCast")
		if not ses then
			return
		end
		if sure > 0 then
			task.wait(sure)
		elseif ses.Parent then
			ses.Ended:Wait()
		end
		if no ~= atisNo or atisBitti then
			return
		end
		balikSesi = YerelSes.cal("Fishing", true)
	end)
end

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

local function hepsiniDurdur()
	for _, track in { izler.idle, izler.cast, izler.fishing } do
		if track and track.IsPlaying then
			track:Stop(0.2)
		end
	end
end

local function durusuGuncelle()
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

	table.insert(
		baglantilar,
		character:GetAttributeChangedSignal("OltaAtis"):Connect(function()
			if denizde() and izler.cast then
				izler.cast:Play(0.1)
			end
			if denizde() then
				oltaSesleri()
			end
		end)
	)

	durusuGuncelle()
end

player:GetAttributeChangedSignal("Flyboarding"):Connect(durusuGuncelle)

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
	atisBitti = true
	balikSesiniDurdur()
end)

player:GetAttributeChangedSignal("Flyboarding"):Connect(function()
	if not denizde() then
		atisBitti = true
		balikSesiniDurdur()
	end
end)

player.CharacterAdded:Connect(karakterGeldi)
if player.Character then
	task.spawn(karakterGeldi, player.Character)
end
