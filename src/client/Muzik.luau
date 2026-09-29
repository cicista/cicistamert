--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Muzik = {}

Muzik.KlasorAdi = "Musics"

Muzik.SesAdi = "Happy Shoppers"

local KOPYA_ADI = "ArkaPlanMuzigi"

local ARA = 1.5

local yuzde = 100
local kapali = false
local calan: Sound? = nil
local tabanSes = 0.5

local function sadeAd(ad: string): string
	return string.lower((string.gsub(ad, "[%s_%-]", "")))
end

local function sarkilariBul(): { Sound }
	local koklar = { Workspace :: Instance, SoundService, ReplicatedStorage }
	local hedef = sadeAd(Muzik.KlasorAdi)

	for _, kok in koklar do
		for _, node in kok:GetDescendants() do
			if
				(node:IsA("Folder") or node:IsA("Model") or node:IsA("Configuration"))
				and sadeAd(node.Name) == hedef
			then
				local liste: { Sound } = {}
				for _, cocuk in node:GetDescendants() do
					if cocuk:IsA("Sound") then
						table.insert(liste, cocuk)
					end
				end
				if #liste > 0 then
					table.sort(liste, function(a, b)
						return a.Name < b.Name
					end)
					return liste
				end
			end
		end
	end

	for _, kok in koklar do
		for _, node in kok:GetDescendants() do
			if node:IsA("Sound") and node.Name == Muzik.SesAdi then
				return { node }
			end
		end
	end

	return {}
end

local function uygula()
	local ses = calan
	if ses and ses.Parent then
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

function Muzik.simdikiSarki(): string?
	return if calan then calan:GetAttribute("SarkiAdi") :: string? else nil
end

local function karistir(liste: { Sound }, sonAd: string?): { Sound }
	local sira = table.clone(liste)
	local rng = Random.new()

	for i = #sira, 2, -1 do
		local j = rng:NextInteger(1, i)
		sira[i], sira[j] = sira[j], sira[i]
	end

	if sonAd and #sira > 1 and sira[1].Name == sonAd then
		sira[1], sira[2] = sira[2], sira[1]
	end

	return sira
end

local function cal(kaynak: Sound)
	local kopya = kaynak:Clone()
	kopya.Name = KOPYA_ADI
	kopya.Looped = false
	kopya:SetAttribute("SarkiAdi", kaynak.Name)
	kopya.Parent = SoundService

	tabanSes = if kaynak.Volume > 0 then kaynak.Volume else 0.5
	calan = kopya
	uygula()

	kopya:Play()

	if kopya.TimeLength <= 0 then
		local bitis = os.clock() + 5
		while kopya.TimeLength <= 0 and os.clock() < bitis and kopya.Parent do
			task.wait(0.2)
		end
	end

	if kopya.TimeLength > 0 then
		local bitti = false
		local bag: RBXScriptConnection? = nil
		bag = kopya.Ended:Connect(function()
			bitti = true
		end)

		local sinir = os.clock() + kopya.TimeLength + 3
		while not bitti and os.clock() < sinir and kopya.Parent do
			task.wait(0.25)
		end

		if bag then
			bag:Disconnect()
		end
	else
		warn(`[Muzik] "{kaynak.Name}" yuklenemedi, siradaki sarkiya geciliyor`)
		task.wait(1)
	end

	if calan == kopya then
		calan = nil
	end
	kopya:Destroy()
end

task.spawn(function()
	local sarkilar: { Sound } = {}
	for _ = 1, 60 do
		sarkilar = sarkilariBul()
		if #sarkilar > 0 then
			break
		end
		task.wait(1)
	end

	if #sarkilar == 0 then
		warn(
			`[Muzik] Sarki bulunamadi. Workspace > {Muzik.KlasorAdi} klasorune `
				.. `Sound nesneleri koy (ya da "{Muzik.SesAdi}" adli tek bir Sound).`
		)
		return
	end

	for _, ses in sarkilar do
		ses.Volume = 0
		ses.Playing = false
	end

	print(`[Muzik] {#sarkilar} sarki bulundu, calma listesi karistirildi`)

	local sonAd: string? = nil

	while true do
		for _, kaynak in karistir(sarkilar, sonAd) do
			if kaynak.Parent then
				cal(kaynak)
				sonAd = kaynak.Name
				task.wait(ARA)
			end
		end

		if #sarkilar == 1 then
			task.wait(ARA)
		end
	end
end)

return Muzik
