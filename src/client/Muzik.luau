--!strict
--[[
	ARKA PLAN MUZIGI  (ModuleScript, istemci)
	Yeri: StarterPlayer > StarterPlayerScripts > Muzik

	Studio'ya elle konan "Happy Shoppers" Sound'unu adiyla bulur ve oyun
	boyunca DONGUDE calar. Ses; SoundService, Workspace ya da
	ReplicatedStorage icinde herhangi bir yerde olabilir.

	NASIL CALAR
	  Bulunan sesin bir KOPYASI bu oyuncunun SoundService'ine konup calinir;
	  asil ses bu oyuncuda susturulur. Boylece:
	    - sunucuda da caliyorsa iki kez duyulmaz
	    - bir parcanin icindeyse (konumlu ses) her yerden ayni duyulur
	    - ses ayari yalnizca bu oyuncuyu etkiler

	AYAR  (Ayarlar panelinden, kayitli; bkz. Menuler > AYARLAR)
	    Muzik.ayarla(yuzde, kapali)   -- yuzde 0..100, kapali true/false
	Sesin kendi Volume degeri %100 sayilir.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Muzik = {}

-- Studio'daki Sound'un adi
Muzik.SesAdi = "Happy Shoppers"

local KOPYA_ADI = "ArkaPlanMuzigi"

local yuzde = 100
local kapali = false
local calan: Sound? = nil
-- Asil sesin kendi seviyesi (%100 karsiligi)
local tabanSes = 0.5

local function bul(): Sound?
	for _, kok in { SoundService :: Instance, Workspace, ReplicatedStorage } do
		for _, d in kok:GetDescendants() do
			if d:IsA("Sound") and d.Name == Muzik.SesAdi then
				return d
			end
		end
	end
	return nil
end

local function uygula()
	local ses = calan
	if ses then
		ses.Volume = if kapali then 0 else tabanSes * yuzde / 100
	end
end

function Muzik.ayarla(yeniYuzde: number?, yeniKapali: boolean?)
	if yeniYuzde then
		yuzde = math.clamp(math.round(yeniYuzde), 0, 100)
	end
	if yeniKapali ~= nil then
		kapali = yeniKapali
	end
	uygula()
end

function Muzik.yuzde(): number
	return yuzde
end

function Muzik.kapali(): boolean
	return kapali
end

-- Ses Studio'ya gec yuklenebilir: bir dakika boyunca aranir
task.spawn(function()
	for _ = 1, 60 do
		local kaynak = bul()
		if kaynak then
			tabanSes = if kaynak.Volume > 0 then kaynak.Volume else 0.5

			local kopya = kaynak:Clone()
			kopya.Name = KOPYA_ADI
			kopya.Looped = true
			kopya.Parent = SoundService

			-- Asil ses bu oyuncuda susar (kopya calacak)
			kaynak.Volume = 0
			kaynak.Playing = false

			calan = kopya
			uygula()
			kopya:Play()
			return
		end
		task.wait(1)
	end
	warn(`[Muzik] "{Muzik.SesAdi}" adli Sound bulunamadi (SoundService / Workspace / ReplicatedStorage)`)
end)

return Muzik
