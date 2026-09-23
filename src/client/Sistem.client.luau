--[[
	Sistem  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Sistem

	Uc is yapar:

	1. CORE GUI
	   Roblox'un kendi oyuncu listesini (Rot siralamasi) ve sirt cantasini acar.

	2. TOOL TUTMA ANIMASYONLARI
	   Tool'a sunucuda yazilan "HoldAnimation" ozelligini okur ve tool elde
	   tutulurken oynatir. Animasyon id'leri Shared > Assets icinde tanimlanir;
	   bos birakilan animasyon sessizce atlanir.

	3. DEDEKTOR BIP SESI
	   GPS elde tutulurken bip calar. En yakin isik suzmesi yaklastikca bip
	   araligi kisalir (metal dedektor hissi). Ses id'si ve araliklari
	   Shared > Assets > Sounds icinde.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Net = require(Shared:WaitForChild("Net"))

local GPSGuncelle = Net.event("GPSGuncelle")

------------------------------------------------------------------
-- 1. CORE GUI
------------------------------------------------------------------
local function setCoreGui()
	-- Oyun ilk karelerde CoreGui cagrilarini reddedebilir; basarana kadar dene
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
			--[[
				ROBLOX'UN HOTBAR'I KAPALI: yerini kendi cubugumuz aliyor
				(bkz. StarterPlayerScripts > Hotbar). Sebebi: Roblox'un
				cubugu bir Tool'un ya ikonunu ya adini gosteriyor, ikisini
				birden degil -- parsomenin adedi bu yuzden hic gorunmuyordu.
			]]
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		if ok then
			return
		end
		task.wait(0.25)
	end
end

task.spawn(setCoreGui)

------------------------------------------------------------------
-- 2. TOOL TUTMA ANIMASYONLARI
------------------------------------------------------------------
local tracks: { [Tool]: AnimationTrack } = {}

--[[
	URETILEN HER IZ burada da tutulur.

	tracks yalnizca "su an hangi tool'un izi caliyor" sorusunu cevapliyor ve
	stopTrack cagrilinca kayit oradan siliniyor. Iz gercekten durmadiysa
	(asagidaki gecis sorunu) artik kimse onu bilmiyor ve supurge de goremiyor
	oluyordu -- karakterin uzerinde asili kalan poz buydu.

	Bu liste bagimsiz: bizim urettigimiz hicbir iz gozden kacmaz.
]]
local uretilen: { AnimationTrack } = {}

--[[
	IZI DURDURUR

	Stop'tan HEMEN SONRA Destroy cagrilmiyor. Stop bir gecis suresi aliyor
	ve iz o sure boyunca hala karisima katkida bulunuyor; ortasinda yok
	edilirse gecis tamamlanmiyor ve SON POZ uzerinde kaliyor. Yurume
	animasyonunun takili kalmasinin sebebi buydu.

	Once durduruluyor, yok etme gecis bitince yapiliyor.
]]
local GECIS = 0.15

local function stopTrack(tool: Tool)
	local track = tracks[tool]
	if not track then
		return
	end

	tracks[tool] = nil

	pcall(function()
		track:Stop(GECIS)
	end)

	task.delay(GECIS + 0.05, function()
		pcall(function()
			track:Destroy()
		end)
	end)
end

-- Butun tutma animasyonlarini durdurur (olum, yeniden dogus)
local function stopAllTracks()
	for tool in tracks do
		stopTrack(tool)
	end
end

local function playHoldAnimation(tool: Tool)
	local id = Assets.id(tool:GetAttribute("HoldAnimation") :: string?)
	if not id then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not character or not animator then
		return
	end

	--[[
		TOOL HALA ELDE MI?

		Buraya kisa bir beklemenin ardindan geliniyor (asagidaki ChildAdded).
		Kurek ve GPS artik otomatik kusanilip birakildigi icin tool o bekleme
		icinde elden cikmis olabilir. Kontrol edilmezse animasyon TOOL
		GITTIKTEN SONRA basliyor ve onu durduracak sinyal coktan gecmis
		oluyordu -- karakterin kollari havada asili kaliyordu.
	]]
	if tool.Parent ~= character then
		stopTrack(tool)
		return
	end

	stopTrack(tool)

	local animation = Instance.new("Animation")
	animation.AnimationId = id

	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	animation:Destroy()

	if not ok or not track then
		return
	end

	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true
	track:Play(0.15)
	tracks[tool] = track
	table.insert(uretilen, track)
end

-- Tool karaktere eklendiginde elde tutuluyor demektir
local function watchCharacter(character: Model)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			task.wait(0.1)
			playHoldAnimation(child)
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			stopTrack(child)
		end
	end)

	-- Karakter dogdugunda zaten elde olan tool varsa
	for _, child in character:GetChildren() do
		if child:IsA("Tool") then
			task.spawn(playHoldAnimation, child)
		end
	end
end

if player.Character then
	watchCharacter(player.Character)
end

player.CharacterAdded:Connect(function(character)
	-- Eski bedenin animasyonlari yeni Animator'a tasinmasin
	stopAllTracks()
	watchCharacter(character)

	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.Died:Connect(stopAllTracks)
	end
end)

--[[
	GUVENLIK SUPURGESI

	Iki is yapar:

	1. Elde olmayan bir tool'un izi hala kayitliysa durdurur. Kurek ve GPS
	   saniyede birkac kez el degistirebildigi icin sinyallerin sirasi her
	   zaman ayni olmuyor, arada bir kacak kalabiliyor.

	2. BIZIM URETTIGIMIZ ama artik kimseye ait olmayan izleri durdurur.
	   tracks yalnizca "su an caliyor olmasi gereken" izi tutuyor; oradan
	   silinmis bir iz gercekten durmadiysa eskiden kimse fark etmiyordu.
	   Artik uretilen listesi uzerinden bulunup susturuluyor.

	Saniyede iki kez, birkac karsilastirma.
]]
task.spawn(function()
	while true do
		task.wait(0.5)

		local character = player.Character

		for tool in tracks do
			if tool.Parent ~= character then
				stopTrack(tool)
			end
		end

		-- Su an calmasi gereken iz (varsa) disinda ne kaldiysa sustur
		local izinli: { [AnimationTrack]: boolean } = {}
		for _, track in tracks do
			izinli[track] = true
		end

		for i = #uretilen, 1, -1 do
			local track = uretilen[i]
			local ok, caliyor = pcall(function()
				return track.IsPlaying
			end)

			if not ok then
				-- Yok edilmis iz: listeden dus
				table.remove(uretilen, i)
			elseif not caliyor then
				table.remove(uretilen, i)
			elseif not izinli[track] then
				pcall(function()
					track:Stop(0)
				end)
				table.remove(uretilen, i)
			end
		end
	end
end)

------------------------------------------------------------------
-- 3. DEDEKTOR BIP SESI
------------------------------------------------------------------
local S = Assets.Sounds

local beepSound: Sound? = nil

local function ensureBeep(): Sound?
	local id = Assets.id(S.detectorBeep)
	if not id then
		return nil
	end

	if beepSound and beepSound.Parent then
		return beepSound
	end

	local sound = Instance.new("Sound")
	sound.Name = "DedektorBip"
	sound.SoundId = id
	sound.Volume = S.detectorBeepVolume
	sound.Parent = SoundService
	beepSound = sound

	return sound
end

-- Server'dan gelen suzmeler; en yakini bip hizini belirler
local beams: { { id: string, kind: string, position: Vector3 } } = {}

GPSGuncelle.OnClientEvent:Connect(function(list)
	beams = list or {}
end)

local function nearestBeamDistance(): number?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or #beams == 0 then
		return nil
	end

	local best = math.huge
	for _, beam in beams do
		local distance = (beam.position - root.Position).Magnitude
		if distance < best then
			best = distance
		end
	end

	return if best < math.huge then best else nil
end

-- GPS elde mi
local function gpsInHand(): boolean
	local character = player.Character
	if not character then
		return false
	end

	for _, child in character:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("DetectorId") then
			return true
		end
	end

	return false
end

task.spawn(function()
	while true do
		local sound = ensureBeep()

		if not sound or not gpsInHand() then
			task.wait(0.3)
			continue
		end

		local distance = nearestBeamDistance()
		local interval = S.detectorBeepSlowest

		if distance then
			-- Yakinlik 0..1 -> bip araligi hizlidan yavasa
			local alpha = math.clamp(distance / S.detectorBeepRange, 0, 1)
			interval = S.detectorBeepFastest + (S.detectorBeepSlowest - S.detectorBeepFastest) * alpha
			-- Yakinken biraz daha yuksek sesli
			sound.Volume = S.detectorBeepVolume * (1.4 - alpha * 0.5)
		else
			sound.Volume = S.detectorBeepVolume * 0.7
		end

		sound:Play()
		task.wait(interval)
	end
end)
