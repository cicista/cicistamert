--!strict
--[[
	ARAYUZ TIKLAMA SESI  (ModuleScript, istemci)
	Yeri: StarterPlayer > StarterPlayerScripts > ArayuzSesi

	Sol menudeki (ve sagdaki Settings) butonlara tiklaninca calan ses.
	Studio'ya elle konan Sound ADIYLA bulunur: adinda (bosluk, _ ve - yok
	sayilarak) "cartoonbubble" gecen, yoksa "bubble" gecen ilk Sound.
	SoundService, Workspace ya da ReplicatedStorage icinde olabilir.

	SoundService:PlayLocalSound ile calar: yalnizca tiklayan oyuncu duyar.

	    ArayuzSesi.tikla()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local ArayuzSesi = {}

-- Aranacak ad parcalari; ilk eslesen kullanilir
local ADAYLAR = { "cartoonbubble", "bubble" }

local ses: Sound? = nil
local uyarildi = false
local sonArama = -math.huge

local function sade(ad: string): string
	return string.lower((string.gsub(ad, "[%s_%-]", "")))
end

local function bul(): Sound?
	local sesler: { Sound } = {}
	for _, kok in { SoundService :: Instance, Workspace, ReplicatedStorage } do
		for _, d in kok:GetDescendants() do
			if d:IsA("Sound") then
				table.insert(sesler, d)
			end
		end
	end

	for _, aday in ADAYLAR do
		for _, s in sesler do
			if string.find(sade(s.Name), aday, 1, true) then
				return s
			end
		end
	end
	return nil
end

function ArayuzSesi.tikla()
	local mevcut = ses
	if not mevcut or not mevcut.Parent then
		-- Bulunamadiysa her tiklamada degil, en fazla 5 saniyede bir aranir
		local simdi = os.clock()
		if simdi - sonArama < 5 then
			return
		end
		sonArama = simdi

		mevcut = bul()
		ses = mevcut
		if not mevcut then
			if not uyarildi then
				uyarildi = true
				warn('[ArayuzSesi] Adinda "Cartoon Bubble" gecen bir Sound bulunamadi (SoundService / Workspace / ReplicatedStorage)')
			end
			return
		end
	end

	SoundService:PlayLocalSound(mevcut :: Sound)
end

return ArayuzSesi
