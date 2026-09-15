--[[
	SirtAksesuari  (Script)
	Yeri: ServerScriptService > SirtAksesuari

	Oyuncularin SIRT aksesuarlarini (kanat, pelerin, sirt cantasi, kilic
	kini...) karakterden kaldirir. Diger aksesuarlar -- sapka, sac, yuz,
	omuz, bel -- oldugu gibi kalir.

	NEDEN: elde tutulan kurek, kazma ve olta tutma animasyonlarinda sirttaki
	buyuk aksesuarlar araclarin ve efektlerin icine giriyordu.

	NASIL TANINIR
	  1. Aksesuarin turu (Accessory.AccessoryType) Back ise.
	  2. Turu bilinmeyen eski aksesuarlarda: tutunma noktasi
	     "BodyBackAttachment" ise (Roblox'un sirt noktasi).

	Aksesuarlar karaktere gecikmeli yuklenebildigi icin yalnizca dogumda
	degil, karaktere SONRADAN eklenen aksesuarlarda da kontrol yapilir.
]]

local Players = game:GetService("Players")

local SIRT_NOKTASI = "BodyBackAttachment"

local function sirtAksesuariMi(aksesuar: Accessory): boolean
	if aksesuar.AccessoryType == Enum.AccessoryType.Back then
		return true
	end

	-- Turu isaretlenmemis eski aksesuarlar: hangi noktaya takildigina bak
	local handle = aksesuar:FindFirstChild("Handle")
	local nokta = handle and handle:FindFirstChildOfClass("Attachment")
	return nokta ~= nil and nokta.Name == SIRT_NOKTASI
end

local function denetle(node: Instance)
	if node:IsA("Accessory") and sirtAksesuariMi(node) then
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
