--[[
	SirtAksesuari  (Script)
	Yeri: ServerScriptService > SirtAksesuari

	Oyuncularin GOVDEYE takilan buyuk aksesuarlarini karakterden kaldirir:

	    SIRT  -- kanat, pelerin, sirt cantasi, kilic kini
	    OMUZ  -- omuz peti, omuzda duran hayvan, aura
	    BEL   -- kuyruk, bel kemeri, bel aurasi
	    ON    -- gogus aurasi, on susler

	Kalanlar: sapka, sac, yuz, boyun ve katmanli kiyafetler (ceket, tisort...).

	NEDEN: elde tutulan kurek, kazma ve olta ile tutma animasyonlarinda bu
	aksesuarlar araclarin ve efektlerin icine giriyordu.

	NASIL TANINIR
	  1. Aksesuarin turu (Accessory.AccessoryType) KALDIRILACAK_TURLER icinde.
	  2. Turu bilinmeyen eski aksesuarlarda: tutunma noktasinin adi
	     KALDIRILACAK_NOKTALAR icinde (Roblox'un govde noktalari).

	Aksesuarlar karaktere gecikmeli yuklenebildigi icin yalnizca dogumda
	degil, karaktere SONRADAN eklenen aksesuarlarda da kontrol yapilir.
]]

local Players = game:GetService("Players")

local KALDIRILACAK_TURLER = {
	[Enum.AccessoryType.Back] = true,
	[Enum.AccessoryType.Shoulder] = true,
	[Enum.AccessoryType.Waist] = true,
	[Enum.AccessoryType.Front] = true,
}

local KALDIRILACAK_NOKTALAR = {
	BodyBackAttachment = true,
	BodyFrontAttachment = true,
	LeftShoulderAttachment = true,
	RightShoulderAttachment = true,
	LeftCollarAttachment = true,
	RightCollarAttachment = true,
	WaistBackAttachment = true,
	WaistFrontAttachment = true,
	WaistCenterAttachment = true,
}

local function kaldirilacakMi(aksesuar: Accessory): boolean
	if KALDIRILACAK_TURLER[aksesuar.AccessoryType] then
		return true
	end

	-- Turu isaretlenmemis eski aksesuarlar: hangi noktaya takildigina bak
	local handle = aksesuar:FindFirstChild("Handle")
	if not handle then
		return false
	end

	for _, child in handle:GetChildren() do
		if child:IsA("Attachment") and KALDIRILACAK_NOKTALAR[child.Name] then
			return true
		end
	end

	return false
end

local function denetle(node: Instance)
	if node:IsA("Accessory") and kaldirilacakMi(node) then
		-- Bir kare bekle: Roblox aksesuari takarken silinirse uyari verebiliyor
		task.defer(function()
			if node.Parent then
				node:Destroy()
			end
		end)
	end
end

local function karakterGeldi(character: Model)
	character.ChildAdded:Connect(denetle)

	for _, child in character:GetChildren() do
		denetle(child)
	end
end

local function oyuncuGeldi(player: Player)
	player.CharacterAdded:Connect(karakterGeldi)

	-- Gorunus tamamen yuklendiginde bir tur daha: gec gelen aksesuarlar kalmasin
	player.CharacterAppearanceLoaded:Connect(function(character)
		for _, child in character:GetChildren() do
			denetle(child)
		end
	end)

	if player.Character then
		karakterGeldi(player.Character)
	end
end

Players.PlayerAdded:Connect(oyuncuGeldi)

for _, player in Players:GetPlayers() do
	oyuncuGeldi(player)
end
