--!strict
--[[
	Gacha  (Script)
	Yeri: ServerScriptService > Gacha

	Yumurta gachasi: Gacha NPC'si, mor pencere, Robux ile cevirme.
	Butun mantik Modules > Gacha icinde; burasi yalnizca baslatir.
	Satin alma fisi RobuxMagaza'da isleniyor (ProcessReceipt tek yerde).
]]

local Modules = script.Parent:WaitForChild("Modules")
local Gacha = require(Modules:WaitForChild("Gacha"))

Gacha.baslat()
