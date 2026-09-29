local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
