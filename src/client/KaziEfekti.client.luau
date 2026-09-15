--[[
	KaziEfekti  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > KaziEfekti

	KAZI ANIMASYONLARINA GRI PARCACIK

	    kurek animasyonu  -> 0.25. saniyede kuregin ucundan KUM fiskirir
	    kazma animasyonu  -> 0.15. saniyede kazmanin ucunda TAS kirilir

	Animasyonlar dongude oynadigi icin parcacik HER TURDA o anda cikar.

	NASIL
	Her karede butun karakterlerin oynayan animasyonlarina bakilir; kazi
	animasyonu (Shared > Assets > Animations: shovelDig / pickaxeDig) varsa
	zamaninin ayarlanan saniyeyi GECTIGI kare yakalanir ve aletin ucunda
	parcacik patlatilir. Diger oyuncularin animasyonlari da her istemciye
	geldigi icin herkes herkesin efektini gorur.

	Aletin ucu: Handle'a EN UZAK parca (kurek bicaginin / kazma kafasinin
	ucu). Zaman ve parcacik ayarlari: Shared > Assets > DigEffects
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))

local E = Assets.DigEffects

local NOKTA_ADI = "KaziEfektNoktasi"

-- "rbxassetid://123" -> "123": id karsilastirmasi yazim farkindan etkilenmesin
local function idNumarasi(id: string?): string?
	if type(id) ~= "string" then
		return nil
	end
	return string.match(id, "%d+")
end

-- animasyon numarasi -> efekt ayari (E.shovel / E.pickaxe)
local ayarlar: { [string]: any } = {}
for _, tur in { "shovel", "pickaxe" } do
	local cfg = E[tur]
	local numara = if cfg then idNumarasi(Assets.Animations[cfg.animation]) else nil
	if numara then
		ayarlar[numara] = cfg
	end
end

-- Her animasyonun bir onceki karedeki zamani (zayif tablo: biten iz kendiliginden silinir)
local sonZaman: { [AnimationTrack]: number } = setmetatable({}, { __mode = "k" }) :: any

local function eldekiArac(character: Model): Tool?
	for _, child in character:GetChildren() do
		if child:IsA("Tool") and (child:GetAttribute("ShovelId") or child:GetAttribute("PickaxeId")) then
			return child
		end
	end
	return nil
end

-- Aletin ucu: Handle'a en uzak parcanin merkezi
local function ucNoktasi(arac: Tool): Vector3?
	local handle = arac:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return nil
	end

	local enUzak = -1
	local nokta: Vector3? = nil
	for _, d in arac:GetDescendants() do
		if d:IsA("BasePart") and d ~= handle then
			local mesafe = (d.Position - handle.Position).Magnitude
			if mesafe > enUzak then
				enUzak = mesafe
				nokta = d.Position
			end
		end
	end

	return nokta
end

-- Kapali bir yayici kurar; yalnizca Emit ile patlar
local function yayiciKur(
	ad: string,
	parent: Instance,
	renk1: Color3,
	renk2: Color3,
	boy: number,
	omurMin: number,
	omurMax: number,
	isik: number,
	yercekimi: number
): ParticleEmitter
	local pe = Instance.new("ParticleEmitter")
	pe.Name = ad
	pe.Enabled = false
	pe.Rate = 0
	pe.Color = ColorSequence.new(renk1, renk2)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, boy),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime = NumberRange.new(omurMin, omurMax)
	pe.Acceleration = Vector3.new(0, -yercekimi, 0)
	pe.Drag = 2
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-200, 200)
	pe.LightEmission = isik
	-- Isik etkisi dusuk: golgede de gorunsun (kivilcim hic etkilenmez)
	pe.LightInfluence = if isik > 0 then 0 else 0.3
	-- Zeminin/aletin icinde kaybolmasin
	pe.ZOffset = 1
	-- Parcaciklar alete yapismaz, cikti yerde kalir
	pe.LockedToPart = false
	pe.Parent = parent
	return pe
end

-- Aletin Handle'inda bir kez kurulan nokta + iki yayici: toz ve kivilcim
local function yayici(arac: Tool): (Attachment?, ParticleEmitter?, ParticleEmitter?)
	local handle = arac:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return nil, nil, nil
	end

	local nokta = handle:FindFirstChild(NOKTA_ADI)
	if not nokta then
		local yeni = Instance.new("Attachment")
		yeni.Name = NOKTA_ADI
		yeni.Parent = handle
		yayiciKur("KaziParcacik", yeni, E.color1, E.color2, E.size, E.lifetimeMin, E.lifetimeMax, 0, E.gravity)
		yayiciKur(
			"KaziKivilcim",
			yeni,
			E.sparkColor,
			E.sparkColor,
			E.sparkSize,
			E.sparkLifetimeMin,
			E.sparkLifetimeMax,
			1,
			E.gravity * 0.5
		)
		nokta = yeni
	end

	if not nokta:IsA("Attachment") then
		return nil, nil, nil
	end

	local toz = nokta:FindFirstChild("KaziParcacik")
	local kivilcim = nokta:FindFirstChild("KaziKivilcim")
	return nokta,
		if toz and toz:IsA("ParticleEmitter") then toz else nil,
		if kivilcim and kivilcim:IsA("ParticleEmitter") then kivilcim else nil
end

local function patlat(character: Model, cfg: any)
	local arac = eldekiArac(character)
	local uc = if arac then ucNoktasi(arac) else nil
	if not arac or not uc then
		return
	end

	local nokta, toz, kivilcim = yayici(arac)
	if not nokta then
		return
	end

	-- Dunya eksenleriyle: yayilma yonu (Top) her zaman YUKARI
	nokta.WorldCFrame = CFrame.new(uc)

	if toz then
		toz.SpreadAngle = Vector2.new(cfg.spread, cfg.spread)
		toz.Speed = NumberRange.new(cfg.speedMin, cfg.speedMax)
		toz:Emit(cfg.count)
	end

	if kivilcim and (cfg.sparkCount or 0) > 0 then
		kivilcim.SpreadAngle = Vector2.new(cfg.spread, cfg.spread)
		kivilcim.Speed = NumberRange.new(cfg.sparkSpeedMin, cfg.sparkSpeedMax)
		kivilcim:Emit(cfg.sparkCount)
	end
end

RunService.RenderStepped:Connect(function()
	for _, oyuncu in Players:GetPlayers() do
		local character = oyuncu.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if not character or not animator then
			continue
		end

		for _, track in animator:GetPlayingAnimationTracks() do
			local animasyon = track.Animation
			local cfg = if animasyon then ayarlar[idNumarasi(animasyon.AnimationId) or ""] else nil
			if not cfg then
				continue
			end

			local simdi = track.TimePosition
			local once = sonZaman[track]
			sonZaman[track] = simdi

			if once then
				local an = cfg.particleTime
				--[[
					O ani bu karede GECTI MI. Animasyon dongude: zaman basa
					sardiysa (simdi < once) turun sonu ya da yeni turun basi
					arasinda gecmis olabilir.
				]]
				local gecti = if simdi >= once then (once < an and simdi >= an) else (once < an or simdi >= an)
				if gecti then
					patlat(character, cfg)
				end
			end
		end
	end
end)
