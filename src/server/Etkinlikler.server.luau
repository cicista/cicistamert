--!strict

local Modules = script.Parent:WaitForChild("Modules")
local SunucuIsini = require(Modules:WaitForChild("SunucuIsini"))
local Hava = require(Modules:WaitForChild("Hava"))

SunucuIsini.calistir()
Hava.calistir()
