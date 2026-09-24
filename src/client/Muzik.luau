--!strict
--[[
	ARKA PLAN MUZIGI  (ModuleScript, istemci)
	Yeri: StarterPlayer > StarterPlayerScripts > Muzik

	CALMA LISTESI

	Workspace > Musics klasorundeki butun sarkilar bir liste olusturuyor.
	Oyuncu girince liste KARISTIRILIYOR ve bastan calmaya basliyor; bir
	sarki bitince siradaki geliyor, liste bitince yeniden karistirilip
	basa donuyor.

	Yani her oyuncu baska bir sarkiyla giriyor ve tek bir parca surekli
	tekrar etmiyor. Tek sarki varsa o dongude calar (eski davranis).

	YENI SARKI EKLEMEK
	Klasore atmak yeterli; burada hicbir sey yazilmiyor.

	NASIL CALAR
	  Calan sarkinin bir KOPYASI bu oyuncunun SoundService'ine konuyor;
	  klasordeki asil sesler bu oyuncuda susturuluyor. Boylece:
	    - sunucuda da caliyorsa iki kez duyulmaz
	    - bir parcanin icindeyse (konumlu ses) her yerden ayni duyulur
	    - ses ayari yalnizca bu oyuncuyu etkiler

	AYAR  (Ayarlar panelinden, kayitli; bkz. Menuler > AYARLAR)
	    Muzik.ayarla(yuzde, kapali)   -- yuzde 0..100, kapali true/false
	Sarkinin kendi Volume degeri %100 sayilir.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Muzik = {}

--[[
	Sarkilarin durdugu klasorun adi. Buyuk/kucuk harf ve bosluk farki
	onemsiz ("musics", "Musics", "MUSIC" hepsi olur).
]]
Muzik.KlasorAdi = "Musics"

--[[
	Klasor bulunamazsa aranacak TEK sarki. Eski kurulumlarda sarki
	klasorsuz, tek basina duruyordu; o kurulumlar da calismaya devam etsin.
]]
Muzik.SesAdi = "Happy Shoppers"

local KOPYA_ADI = "ArkaPlanMuzigi"

--[[
	Bir sarki bittikten sonra digerine gecerken birakilan sessizlik.
	Sifir olsaydi parcalar birbirine yapisik duyuluyordu.
]]
local ARA = 1.5

local yuzde = 100
local kapali = false
local calan: Sound? = nil
-- Calan sarkinin KENDI seviyesi (%100 karsiligi)
local tabanSes = 0.5

local function sadeAd(ad: string): string
	return string.lower((string.gsub(ad, "[%s_%-]", "")))
end

------------------------------------------------------------------
-- SARKILARI BUL
------------------------------------------------------------------
--[[
	Once Musics klasoru, yoksa tek sarki.

	Klasor Workspace'te aranir ama SoundService ve ReplicatedStorage'a da
	bakilir: nereye konulursa konulsun bulunsun.
]]
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
					--[[
						Klasordeki sira Studio'daki sira; karistirma
						asagida yapiliyor ama once ADA gore siralaniyor ki
						her oyuncuda ayni listeden baslansin.
					]]
					table.sort(liste, function(a, b)
						return a.Name < b.Name
					end)
					return liste
				end
			end
		end
	end

	-- Klasor yok: eski davranis, tek sarki adiyla aranir
	for _, kok in koklar do
		for _, node in kok:GetDescendants() do
			if node:IsA("Sound") and node.Name == Muzik.SesAdi then
				return { node }
			end
		end
	end

	return {}
end

------------------------------------------------------------------
-- SES SEVIYESI
------------------------------------------------------------------
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

-- Su an calan sarkinin adi (arayuz gostermek isterse diye)
function Muzik.simdikiSarki(): string?
	return if calan then calan:GetAttribute("SarkiAdi") :: string? else nil
end

------------------------------------------------------------------
-- CALMA LISTESI
------------------------------------------------------------------
--[[
	Listeyi karistirir (Fisher-Yates).

	`sonAd` verilirse karistirmadan sonra listenin BASINA o sarki
	gelmiyor: liste basa dondugunde ayni parca ust uste iki kez calmasin.
]]
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

--[[
	Bir sarkiyi calar ve BITENE KADAR bekler.

	Ended olayi tek basina yeterli degil: ses yuklenemezse ya da baska bir
	sebeple hic calmaya baslamazsa o olay hic gelmiyor ve muzik orada
	oluyordu. Bu yuzden sarkinin uzunlugu kadar bir ust sinir da var;
	uzunluk bilinmiyorsa kisa bir bekleyisle gecilip siradakine geciliyor.
]]
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

	-- Uzunluk yuklenmemis olabilir: kisa bir sure beklenir
	if kopya.TimeLength <= 0 then
		local bitis = os.clock() + 5
		while kopya.TimeLength <= 0 and os.clock() < bitis and kopya.Parent do
			task.wait(0.2)
		end
	end

	if kopya.TimeLength > 0 then
		--[[
			Ended'i bekleyen bir iplik ve zaman asimi yaris halinde:
			hangisi once gelirse sarki bitmis sayiliyor. Ust sinir birkac
			saniye fazla, cunku Ended cogu zaman tam zamaninda geliyor.
		]]
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
		-- Uzunluk hic gelmedi: sarki bozuk olabilir, siradakine gec
		warn(`[Muzik] "{kaynak.Name}" yuklenemedi, siradaki sarkiya geciliyor`)
		task.wait(1)
	end

	if calan == kopya then
		calan = nil
	end
	kopya:Destroy()
end

------------------------------------------------------------------
-- BASLAT
------------------------------------------------------------------
task.spawn(function()
	-- Sesler Studio'ya gec yuklenebilir: bir dakika boyunca aranir
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

	--[[
		KLASORDEKI ASIL SESLER SUSAR

		Biri Studio'da "Playing" birakilmissa ya da sunucu calistiriyorsa
		kopyayla ust uste binerdi. Bu yalnizca BU oyuncuyu etkiliyor.
	]]
	for _, ses in sarkilar do
		ses.Volume = 0
		ses.Playing = false
	end

	print(`[Muzik] {#sarkilar} sarki bulundu, calma listesi karistirildi`)

	local sonAd: string? = nil

	while true do
		--[[
			HER TURDA YENIDEN KARISTIRILIYOR: liste hep ayni sirada
			calsaydi ikinci turda oyuncu sirayi ezberlerdi. Ilk tur da
			karisik, yani her oyuncu baska bir sarkiyla basliyor.
		]]
		for _, kaynak in karistir(sarkilar, sonAd) do
			if kaynak.Parent then
				cal(kaynak)
				sonAd = kaynak.Name
				task.wait(ARA)
			end
		end

		-- Tek sarki varsa liste bitmez gibi davranir; yine de nefes payi
		if #sarkilar == 1 then
			task.wait(ARA)
		end
	end
end)

return Muzik
