--[[
	Kesif Kisiti  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > KesifKisiti

	KESIF SIRASINDA ELDE BASKA SEY DURMAZ

	Kumda GPS, denizde olta elde kalir. Oyuncu cantadan brainrot, coin ya
	da lucky block kusanmaya calisirsa esya HEMEN geri gonderilir.

	NEDEN ISTEMCIDE DE VAR
	Asil kural sunucuda (bkz. ServerScriptService > KaziSistemi): yetki
	orada, uyari yazisini da o gonderiyor. Ama sunucunun haberi olmasi bir
	gidis-donus suruyor ve esya o sure boyunca elde gorunuyordu -- "bir an
	geliyor, sonra geri gidiyor" sikayeti buydu.

	Burasi ayni kontrolu YEREL yapar: tool karaktere girer girmez, ag
	beklemeden birakilir. Gorunen sure bir kareye iner.

	Sunucu yine de kendi kontrolunu yapiyor; buradaki yalnizca gorsel bir
	hizlandirma, guvenlik siniri degil.

	IZINLI ESYALAR nitelikten taniniyor: kurek ShovelId, GPS DetectorId
	tasiyor (bkz. Modules > Tools). Isimle karsilastirmak kirilgan olurdu.
]]

local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Sunucu bu nitelikle "su an kesiftesin" diyor
local KESIF_NITELIGI = "KesifKisiti"

local function kesifAraciMi(tool: Tool): boolean
	return tool:GetAttribute("ShovelId") ~= nil or tool:GetAttribute("DetectorId") ~= nil
end

local function denetle(character: Model, child: Instance)
	if not child:IsA("Tool") then
		return
	end

	if not player:GetAttribute(KESIF_NITELIGI) then
		return
	end

	if kesifAraciMi(child :: Tool) then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:UnequipTools()
	end
end

local function karakteriBagla(character: Model)
	character.ChildAdded:Connect(function(child)
		denetle(character, child)
	end)

	--[[
		Karakter dogdugunda elinde yasak bir esya kalmis olabilir (olum
		aninda elde duran sey yeniden kusanilabiliyor); bir kez bastan
		taraniyor.
	]]
	for _, child in character:GetChildren() do
		denetle(character, child)
	end
end

player.CharacterAdded:Connect(karakteriBagla)

if player.Character then
	karakteriBagla(player.Character)
end
