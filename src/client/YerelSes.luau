--!strict
--[[
	YEREL SES  (ModuleScript, istemci)
	Yeri: StarterPlayer > StarterPlayerScripts > YerelSes

	Studio'ya elle konmus bir Sound'u ADIYLA bulup yalnizca bu oyuncuya
	calar. Ses SoundService, Workspace ya da ReplicatedStorage icinde
	olabilir. Bir KOPYASI calinir: asil ses yerinde kalir, kopya bitince
	silinir. Ses efektleri ayari (Settings) kopyaya da uygulanir.

	    local ses, sure = YerelSes.cal("Catch")          -- bir kez
	    local ses = YerelSes.cal("Fishing", true)        -- dongude
	    YerelSes.durdur(ses)

	'sure' sesin uzunlugu (saniye); ses yuklenmediyse en fazla 2 saniye
	beklenir, yine bilinmiyorsa 0 doner. Bulunamazsa (nil, 0).
]]

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local YerelSes = {}

local onbellek: { [string]: Sound } = {}
local uyarilan: { [string]: boolean } = {}

function YerelSes.bul(ad: string): Sound?
	local var = onbellek[ad]
	if var and var.Parent then
		return var
	end

	-- Ayni adli baska nesneler olabilir (LuckyBlock modelleri gibi): yalnizca Sound sayilir
	for _, kok in { Workspace :: Instance, SoundService, ReplicatedStorage } do
		for _, d in kok:GetDescendants() do
			if d:IsA("Sound") and d.Name == ad then
				onbellek[ad] = d
				return d
			end
		end
	end

	if not uyarilan[ad] then
		uyarilan[ad] = true
		warn(`[YerelSes] "{ad}" adli Sound bulunamadi (Workspace / SoundService / ReplicatedStorage)`)
	end
	return nil
end

function YerelSes.cal(ad: string, dongu: boolean?): (Sound?, number)
	local kaynak = YerelSes.bul(ad)
	if not kaynak then
		return nil, 0
	end

	if not kaynak.IsLoaded then
		pcall(function()
			ContentProvider:PreloadAsync({ kaynak })
		end)
	end

	local kopya = kaynak:Clone()
	kopya.Name = `Yerel_{ad}`
	kopya.Looped = dongu == true
	kopya.PlaybackRegion = kaynak.PlaybackRegion
	kopya.Parent = SoundService
	kopya:Play()

	if not kopya.Looped then
		kopya.Ended:Once(function()
			kopya:Destroy()
		end)
		task.delay(30, function()
			if kopya.Parent then
				kopya:Destroy()
			end
		end)
	end

	local sure = kaynak.TimeLength
	if sure <= 0 then
		local basla = os.clock()
		while kopya.TimeLength <= 0 and os.clock() - basla < 2 do
			task.wait()
		end
		sure = kopya.TimeLength
	end

	return kopya, sure / math.max(0.01, kaynak.PlaybackSpeed)
end

function YerelSes.durdur(ses: Sound?)
	if ses and ses.Parent then
		ses:Stop()
		ses:Destroy()
	end
end

return YerelSes
