--!strict
--[[
	ScrollEfekti  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > ScrollEfekti

	Mutasyon scroll'u base'deki bir brainrota basildiginda ekrana cikan
	gosteri. Sunucu ScrollSonuc ile sonucu yolluyor (bkz. BaseSistemi >
	scrollKullan); sesi ve bildirimi de sunucu veriyor, burasi yalnizca
	GORSELI oynatiyor.

	Tuttugunda dedektiften cikan mutasyon gosterisinin aynisi calisiyor --
	mutasyonun kendi rengiyle, yani Hacker'da yesil. Tutmadiginda ekranda
	bir sey cikmiyor: sunucunun bildirimi ve FuseFail sesi yeterli.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local ScrollSonuc = Net.event("ScrollSonuc")

--[[
	Gosteri modulu ISTEGE BAGLI: yoksa bu script sessizce durur, oyunun
	geri kalani etkilenmez (ayni desen Fuse.client'ta da var).
]]
local MutasyonGosterisi = (function()
	local modul = script.Parent:WaitForChild("MutasyonGosterisi", 5)
	if modul then
		local ok, sonuc = pcall(require, modul)
		if ok then
			return sonuc
		end
	end
	warn("[ScrollEfekti] MutasyonGosterisi yuklenemedi; gosteri oynatilmayacak")
	return nil
end)()

ScrollSonuc.OnClientEvent:Connect(function(veri)
	if type(veri) ~= "table" or veri.ok ~= true then
		return
	end
	if not MutasyonGosterisi then
		return
	end

	MutasyonGosterisi.goster(veri.mutation, veri.name)
end)
