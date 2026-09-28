--!strict
--[[
	AfkSans  (Script)
	Yeri: ServerScriptService > AfkSans

	Yonca alanlari + sans puani + Leprechaun alan yukseltmesi.
	Butun mantik Modules > AfkSans icinde; burasi yalnizca baslatir.
]]

local Modules = script.Parent:WaitForChild("Modules")
local AfkSans = require(Modules:WaitForChild("AfkSans"))

AfkSans.baslat()
