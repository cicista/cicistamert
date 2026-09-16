--[[
	HataIletici  (Script)  --  YALNIZCA STUDIO
	Yeri: ServerScriptService > HataIletici

	Sunucudaki hata ve uyarilari oyunculara yollar; istemcideki HataEkrani
	onlari ekranin sag altinda gosterir (Output acmadan gorulsun diye).
	Gecmis mesajlar da oyuncu girince bir kez yollanir.

	Yayinlanan oyunda (Studio disinda) hicbir sey yapmaz.
]]

local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--[[
	KAPALI: ekip hata kutusunu Studio'da da gormek istemiyor. Hatalar yine
	Output penceresinde. Tekrar acmak icin ACIK = true yap (HataEkrani ve
	HataIletici ikisinde de).
]]
local ACIK = false
if not ACIK then
	return
end

if not RunService:IsStudio() then
	return
end

local olay = Instance.new("RemoteEvent")
olay.Name = "HataIletici"
olay.Parent = ReplicatedStorage

local function onemli(tur: Enum.MessageType): boolean
	return tur == Enum.MessageType.MessageError or tur == Enum.MessageType.MessageWarning
end

LogService.MessageOut:Connect(function(mesaj, tur)
	if onemli(tur) then
		olay:FireAllClients(mesaj, tur.Name)
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.delay(3, function()
		if not player.Parent then
			return
		end
		for _, kayit in LogService:GetLogHistory() do
			if onemli(kayit.messageType) then
				olay:FireClient(player, kayit.message, kayit.messageType.Name)
			end
		end
	end)
end)
