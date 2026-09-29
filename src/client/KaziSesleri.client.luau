local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

local HARFLER = {
	["\u{FC}"] = "u", ["\u{DC}"] = "u",
	["\u{131}"] = "i", ["\u{130}"] = "i",
	["\u{15F}"] = "s", ["\u{15E}"] = "s",
	["\u{E7}"] = "c", ["\u{C7}"] = "c",
	["\u{F6}"] = "o", ["\u{D6}"] = "o",
	["\u{11F}"] = "g", ["\u{11E}"] = "g",
}

local function sade(ad: string): string
	local s = ad
	for harf, yerine in HARFLER do
		s = string.gsub(s, harf, yerine)
	end
	s = string.lower(s)
	return (string.gsub(s, "[%s_%-]", ""))
end

type SesKaydi = { anahtar: string, ses: Sound?, uyarildi: boolean, sonArama: number }

local function sesKaydi(anahtar: string): SesKaydi
	return { anahtar = anahtar, ses = nil, uyarildi = false, sonArama = -math.huge }
end

local function bul(anahtar: string): Sound?
	for _, kok in { SoundService :: Instance, Workspace, ReplicatedStorage } do
		for _, d in kok:GetDescendants() do
			if d:IsA("Sound") and string.find(sade(d.Name), anahtar, 1, true) then
				return d
			end
		end
	end
	return nil
end

local function cal(kayit: SesKaydi)
	local ses = kayit.ses
	if not ses or not ses.Parent then
		local simdi = os.clock()
		if simdi - kayit.sonArama < 5 then
			return
		end
		kayit.sonArama = simdi
		ses = bul(kayit.anahtar)
		kayit.ses = ses
	end

	if not ses then
		if not kayit.uyarildi then
			kayit.uyarildi = true
			warn(`[KaziSesleri] No Sound with "{kayit.anahtar}" in its name was found (SoundService / Workspace / ReplicatedStorage)`)
		end
		return
	end

	SoundService:PlayLocalSound(ses)
end

local suzmeSesi = sesKaydi("suzme")
local kaziSesi = sesKaydi("kazi")
local kaziDongusu = sesKaydi("dirtdigging")

task.spawn(function()
	local klasor = Workspace:WaitForChild("IsikSuzmeleri")
	local gorulen: { [string]: boolean } = {}

	for _, model in klasor:GetChildren() do
		local id = model:GetAttribute("BeamId")
		if type(id) == "string" then
			gorulen[id] = true
		end
	end

	klasor.ChildAdded:Connect(function(model)
		local id = model:GetAttribute("BeamId")
		if type(id) ~= "string" or gorulen[id] then
			return
		end
		gorulen[id] = true

		if model:GetAttribute("Owner") == localPlayer.UserId then
			cal(suzmeSesi)
		end
	end)
end)

local donguSesi: Sound? = nil

local DONGU_ARALIGI = 0.4

local function donguyuDurdur()
	local ses = donguSesi
	donguSesi = nil
	if ses then
		ses:Stop()
		ses:Destroy()
	end
end

local function donguyuBaslat()
	donguyuDurdur()

	local kaynak = kaziDongusu.ses
	if not kaynak or not kaynak.Parent then
		kaynak = bul(kaziDongusu.anahtar)
		kaziDongusu.ses = kaynak
	end
	if not kaynak then
		if not kaziDongusu.uyarildi then
			kaziDongusu.uyarildi = true
			warn('[KaziSesleri] No Sound with "Dirt Digging" in its name was found (SoundService / Workspace / ReplicatedStorage)')
		end
		return
	end

	local kopya = kaynak:Clone()
	kopya.Name = "KaziDongusu"
	kopya.Looped = false
	kopya.Parent = SoundService
	donguSesi = kopya

	task.spawn(function()
		while donguSesi == kopya and kopya.Parent do
			kopya.TimePosition = 0
			kopya:Play()
			task.wait(DONGU_ARALIGI)
		end
	end)
end

local function karakterBagla(karakter: Model)
	donguyuDurdur()

	karakter:GetAttributeChangedSignal("Kaziyor"):Connect(function()
		if karakter:GetAttribute("Kaziyor") == true then
			cal(kaziSesi)
			donguyuBaslat()
		else
			donguyuDurdur()
		end
	end)

	karakter.Destroying:Connect(donguyuDurdur)
end

if localPlayer.Character then
	karakterBagla(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(karakterBagla)
