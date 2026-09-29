--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local ArayuzSesi = {}

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
				warn('[ArayuzSesi] No Sound with "Cartoon Bubble" in its name was found (SoundService / Workspace / ReplicatedStorage)')
			end
			return
		end
	end

	SoundService:PlayLocalSound(mevcut :: Sound)
end

return ArayuzSesi
