--[[
	KaziSesleri  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > KaziSesleri

	Iki kisiye ozel ses (yalnizca bu oyuncu duyar, SoundService:PlayLocalSound):

	    SUZME SESI  -- BU OYUNCUNUN suzmesi dogunca (baskasinin suzmesinde calmaz)
	    KAZI SESI   -- bu oyuncu kaziya basladigi AN (kumda / madende; denizde olta
	                   atarken calmaz)
	    KAZI DONGUSU -- "Dirt Digging": kazi SURDUGU SURECE dongude calar,
	                   kazi bitince susar

	Sesler Studio'ya elle konan Sound'lar; ADIYLA bulunur. Turkce harfler,
	buyuk/kucuk harf, bosluk, _ ve - yok sayilir:
	    "süzmeses", "Süzme Ses", "SuzmeSes"  -> suzme sesi
	    "kazı", "Kazi Sesi", "KAZI"          -> kazi sesi
	SoundService, Workspace ya da ReplicatedStorage icinde olabilir.

	Suzme sesi oyuna girildiginde ZATEN VAR OLAN suzmeler icin calmaz; her
	suzme icin yalnizca bir kez calar.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

------------------------------------------------------------------
-- SES BULMA
------------------------------------------------------------------
local HARFLER = {
	["\u{FC}"] = "u", ["\u{DC}"] = "u", -- u noktali
	["\u{131}"] = "i", ["\u{130}"] = "i", -- noktasiz i / noktali buyuk I
	["\u{15F}"] = "s", ["\u{15E}"] = "s", -- s cengelli
	["\u{E7}"] = "c", ["\u{C7}"] = "c", -- c cengelli
	["\u{F6}"] = "o", ["\u{D6}"] = "o", -- o noktali
	["\u{11F}"] = "g", ["\u{11E}"] = "g", -- yumusak g
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
		-- Bulunamadiysa en fazla 5 saniyede bir aranir
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
			warn(`[KaziSesleri] Adinda "{kayit.anahtar}" gecen bir Sound bulunamadi (SoundService / Workspace / ReplicatedStorage)`)
		end
		return
	end

	SoundService:PlayLocalSound(ses)
end

local suzmeSesi = sesKaydi("suzme")
local kaziSesi = sesKaydi("kazi")
-- Kazi SURDUKCE dongude calan ses ("Dirt Digging")
local kaziDongusu = sesKaydi("dirtdigging")

------------------------------------------------------------------
-- SUZME DOGUNCA
------------------------------------------------------------------
task.spawn(function()
	local klasor = Workspace:WaitForChild("IsikSuzmeleri")
	local gorulen: { [string]: boolean } = {}

	-- Girildiginde zaten olanlar sessizce isaretlenir
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

------------------------------------------------------------------
-- KAZI BASLAYINCA
--
-- Sunucu kazi BASLAR BASLAMAZ (hazirlik beklemesinden once) karaktere
-- "Kaziyor" niteligini yazar; yalnizca kumda ve madende, denizde yazmaz
-- (bkz. ServerScriptService > KaziSistemi). Ses tam o an calar.
------------------------------------------------------------------
--[[
	KAZI DONGUSU: kazi basladiginda "Dirt Digging" sesinin bir KOPYASI bu
	oyuncunun SoundService'ine konup dongude calar (yalnizca bu oyuncu duyar);
	kazi bitince (nitelik kalkinca) ya da karakter degisince durup silinir.
]]
local donguSesi: Sound? = nil

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
			warn('[KaziSesleri] Adinda "Dirt Digging" gecen bir Sound bulunamadi (SoundService / Workspace / ReplicatedStorage)')
		end
		return
	end

	local kopya = kaynak:Clone()
	kopya.Name = "KaziDongusu"
	kopya.Looped = true
	kopya.Parent = SoundService
	kopya:Play()
	donguSesi = kopya
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
