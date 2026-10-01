--!strict

local Modules = script.Parent:WaitForChild("Modules")
local SunucuIsini = require(Modules:WaitForChild("SunucuIsini"))
local Hava = require(Modules:WaitForChild("Hava"))
local LuckyBlockOdul = require(Modules:WaitForChild("LuckyBlockOdul"))

SunucuIsini.calistir()
Hava.calistir()

LuckyBlockOdul.YagmurBitti.Event:Connect(function()
	SunucuIsini.dogur()
end)
