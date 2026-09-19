--!strict
--[[
	IKONLAR  --  Simulator Icon Pack koprusu

	Paket oyunun icinde duruyor (ReplicatedStorage altinda bir yerde). Her ikon
	su yapida: <Kategori> > <Ikon adi> (Part) > Decal

	Asset id'leri KODA YAZILMIYOR; calisma aninda Decal'den okunuyor. Boylece
	paketi degistirirsen ya da baska bir pakete gecersen kodda hicbir sey
	degismiyor.

	KULLANIM
	    Icons.get("Menus", "Inventory")   -- kategori + isim
	    Icons.of("rot")                   -- oyuna ozel kisa ad (asagidaki Map)

	Ikon bulunamazsa nil doner ve cagiran taraf ikonsuz devam eder; hicbir
	yerde hata olusmaz.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Maden ikonlari katalogdaki her maden icin otomatik tanimlaniyor (asagida)
local Ores = require(script.Parent:WaitForChild("Ores"))

local Icons = {}

--[[
	OYUNUN KENDI IKONLARI  --  ReplicatedStorage > Assets > Icons

	Paketten ayri: buraya elle konan ikonlar (su an maden ikonlari).
	Haritada kategori olarak "Assets" yazilan girisler paketten degil bu
	klasorden okunur, orn. { "Assets", "Ruby" }.

	ISIM ESLESMESI ESNEK: buyuk/kucuk harf, bosluk, alt cizgi ve basta/sonda
	"icon" kelimesi yok sayilir. "Ruby", "ruby_icon", "RubyIcon", "icon ruby"
	hepsi "Ruby" aramasina denk gelir. Tam eslesme yoksa adinda aranan
	kelimeyi IcERen ilk ikon kullanilir.

	ICERIK TURU ESNEK: Decal/Texture (Texture), ImageLabel/ImageButton
	(Image), StringValue (Value) ya da bunlardan birini icinde tasiyan
	herhangi bir nesne (paketteki gibi Part > Decal).

	Hangi ikonlarin eslestigini gormek icin: Icons.assetRaporu()
]]
local ASSET_KATEGORI = "Assets"
Icons.AssetKlasoru = "Icons"

-- Paketin adi (Explorer'da gorunen klasor adi)
Icons.PackName = "Simulator Icon Pack"

--[[
	OYUNA OZEL IKON HARITASI

	Solda kodun kullandigi kisa ad, sagda pakette karsiligi.
	Bir ikonu degistirmek istersen yalnizca buradaki satiri degistir.

	Su an oyunda karsiligi olan sistemler ve ILERIDE eklenecekler burada;
	oyunla ilgisi olmayan kategoriler (Potions, Cursors, Kills, Health,
	Energy, Stars, Gifts...) bilerek disarida birakildi.
]]
--[[
	Bir kisa adin karsisi ya TEK cift ({kategori, isim}) ya da SIRAYLA
	denenecek ciftler listesidir. Liste hali, pakette adi kesin bilinmeyen
	ikonlar icin: ilk bulunan kullanilir.
]]
export type IconEntry = { any }

local Map: { [string]: IconEntry } = {
	-- Para birimleri
	rot = { "Cash", "CashIcon" },
	--[[
		Sol alttaki buyuk Rot gostergesinin para destesi ikonu. Kendi
		ikonunu Assets > Icons icine "Rot" (ya da "Money" / "Cash") adiyla
		koyarsan o kullanilir; yoksa paketteki para ikonlari denenir.
	]]
	rotPara = {
		{ "AssetsTam", "Rot" },
		{ "AssetsTam", "Money" },
		{ "AssetsTam", "Cash" },
		{ "Cash", "CashStack" },
		{ "Cash", "Cash" },
		{ "Cash", "CashIcon" },
	},
	--[[
		Rot Coin: paketteki LowPolyCoin (hangi kategoride durdugu fark etmez,
		"*" butun paketi arar). Paket istemciye hic gelmezse eski altin coin
		resmi (dogrudan kimlik) kullanilir.
	]]
	rotCoin = {
		{ "*", "LowPolyCoin" },
		{ "Id", "rbxassetid://17368060122" },
	},

	-- Mevcut sistemler
	--[[
		Paketteki "Menus > Inventory" kahverengi bir sirt cantasi ve cirkin
		duruyordu. Once daha temiz alternatifler deneniyor; hicbiri pakette
		yoksa eski ikona dusuyor -- yani en kotu ihtimalle eskisi gibi.
	]]
	inventory = {
		{ "Menus", "Backpack" },
		{ "Menus", "Bag" },
		{ "Misc", "Backpack" },
		{ "Menus", "Crate" },
		{ "Menus", "Chest" },
		{ "Menus", "Inventory" },
	},
	shop = { "Menus", "Shop" },
	-- STORE butonunun yanindaki ikon: paketteki "Store" (yoksa "Shop")
	store = {
		{ "*", "Store" },
		{ "*", "Shop" },
	},
	--[[
		Sagdaki Teleporter butonu. Once Assets > Icons icindeki "Teleporter"
		(adi birebir), yoksa paketteki Menus > Teleport. Buton bir kez ikon
		aldiktan sonra bir daha degismez (bkz. Menuler > menuButonu).
	]]
	teleporter = {
		{ "AssetsTam", "Teleporter" },
		{ "Menus", "Teleport" },
	},
	--[[
		Sagdaki base'e don butonu ve soldaki hiz butonu. Pakette adi kesin
		bilinmiyor; sirayla denenir. Hicbiri yoksa butonda emoji gorunur.
		Kendi ikonunu Assets > Icons icine "Home" / "Speed" adiyla koyarsan
		o kullanilir.
	]]
	home = {
		{ "Assets", "Home" },
		{ "Menus", "Home" },
		{ "Menus", "House" },
		{ "Misc", "Home" },
		{ "Misc", "House" },
	},
	speed = {
		{ "Assets", "Speed" },
		{ "Assets", "Shoe" },
		{ "Stats", "Speed" },
		{ "Stats", "WalkSpeed" },
		{ "Misc", "Shoe" },
		{ "Misc", "Boot" },
		{ "Menus", "Speed" },
	},
	settings = { "Menus", "Settings" },
	seller = { "Cash", "CashBag" },
	-- Soldaki Detective butonu: Assets > Icons > "detective"
	detective = {
		{ "AssetsTam", "Detective" },
		{ "Misc", "Question" },
	},
	luckyBlock = { "RNG", "? Box" },
	upgrade = { "Arrows", "GoldUpgrade" },
	lockClosed = { "Misc", "LockClosed" },
	lockOpen = { "Misc", "LockOpen" },
	gps = { "Misc", "Locate" },
	shovel = { "Stats", "Power" },

	-- Dedektor sans kademeleri
	luck1 = { "Luck", "NormalLuck" },
	luck2 = { "Luck", "SuperLuck" },
	luck3 = { "Luck", "UltraLuck" },

	-- ILERIDE EKLENECEK SISTEMLER (ikonlari simdiden hazir)
	pets = { "Menus", "Pets" },
	-- Pakette "Index" yoksa yazi yedegi ("IND") gorunur; o zaman
	-- buradaki ismi pakettekiyle degistir (ornek: { "Menus", "Collection" })
	index = { "Menus", "Index" },
	trade = { "Arrows", "Trade" },
	quests = { "Menus", "Quests" },
	-- Gunluk odul butonu: paketteki PurpleGift (yoksa eski Rewards ikonu)
	rewards = {
		{ "*", "PurpleGift" },
		{ "Menus", "Rewards" },
	},
	vip = { "Menus", "VIP" },
	friends = { "Menus", "Friends" },
	playtime = { "Stats", "Playtime" },
	trophies = { "Stats", "Trophies/Wins" },
}

--[[
	MADEN IKONLARI  --  kisa ad: "ore_<maden kimligi>"  (orn. "ore_Ruby")

	Katalogdaki (Shared > Ores) her maden icin kendiliginden tanimlaniyor;
	yeni maden eklenince burada bir sey degistirmek gerekmiyor. Ikonun
	Assets > Icons icinde madenin adini tasimasi yeterli (bkz. ustteki
	ISIM ESLESMESI).
]]
for id in Ores.Info do
	Map[`ore_{id}`] = { ASSET_KATEGORI, id }
end

Icons.Map = Map

local packFolder: Instance? = nil
local cache: { [string]: string } = {}

--[[
	Paketi bulur. Adi tam eslesmezse "icon" gecen bir klasor de kabul edilir,
	boylece paketi yeniden adlandirsan da calisir.
]]
local function findPack(): Instance?
	if packFolder and packFolder.Parent then
		return packFolder
	end

	--[[
		Paket ReplicatedStorage'da da olabilir Workspace'te de -- ikisi de
		istemciye replike edilir, yani Decal'in Texture'i her iki durumda da
		okunabilir. Once ReplicatedStorage'a bakiliyor.
	]]
	local roots: { Instance } = { ReplicatedStorage, Workspace }

	for _, root in roots do
		local direct = root:FindFirstChild(Icons.PackName)
			or root:FindFirstChild(Icons.PackName, true)
		if direct then
			packFolder = direct
			return direct
		end
	end

	-- Adi degistirilmisse: icinde "icon" gecen ve alt klasoru olan bir klasor
	for _, root in roots do
		for _, node in root:GetDescendants() do
			-- Assets > Icons oyunun kendi ikon klasoru, paket DEGIL: adinda "icon" gecse de atlanir
			local assetIkonlari = node.Name == Icons.AssetKlasoru and node.Parent ~= nil and node.Parent.Name == "Assets"
			if node:IsA("Folder") and not assetIkonlari and string.find(string.lower(node.Name), "icon", 1, true) then
				packFolder = node
				return node
			end
		end
	end

	return nil
end

--[[
	Kategori + isimden asset id.
	Sonuc onbellege alinir; ayni ikon her istendiginde agac taranmaz.
]]
function Icons.get(category: string, name: string): string?
	-- Oyunun kendi ikonlari paketten degil Assets > Icons klasorunden okunur
	if category == ASSET_KATEGORI then
		return Icons.asset(name)
	end

	--[[
		"AssetsTam": Assets > Icons icinde ADI BIREBIR (buyuk/kucuk harf ve
		bosluk farki gozetmeden) tutan ikon. "Assets" kategorisi ada yakin
		isimleri de kabul ediyor ("Teleport" -> "TeleportKumanda"); menu
		butonlarinda yanlis ikon gelmesin diye bu kullaniliyor.
	]]
	if category == "AssetsTam" then
		return Icons.assetTam(name)
	end

	--[[
		"Id" kategorisi: isim DOGRUDAN resim kimligidir ("rbxassetid://...").
		Paket Workspace'te duruyor ve StreamingEnabled acikken istemciye hic
		gelmeyebiliyor; mutlaka gorunmesi gereken ikonlar bu yolla verilir.
	]]
	if category == "Id" then
		return name
	end

	--[[
		"*" kategorisi: ikon paketin HANGI klasorunde olursa olsun adiyla
		bulunur (buyuk/kucuk harf farki yok). Kategorisi bilinmeyen ikonlar
		icin: LowPolyCoin, PurpleGift, Store gibi.
	]]
	if category == "*" then
		local anahtar = `*/{name}`
		local bulunan = cache[anahtar]
		if bulunan then
			return bulunan
		end

		local paket = findPack()
		if not paket then
			return nil
		end

		local hedef = string.lower(name)
		for _, node in paket:GetDescendants() do
			if string.lower(node.Name) == hedef then
				local decal = if node:IsA("Decal") then node else node:FindFirstChildOfClass("Decal")
				if decal and decal.Texture ~= "" then
					cache[anahtar] = decal.Texture
					return decal.Texture
				end
			end
		end
		return nil
	end

	local key = `{category}/{name}`

	local cached = cache[key]
	if cached then
		return cached
	end

	--[[
		BULUNAMADI SONUCU ONBELLEGE ALINMAZ.

		Istemci acilirken paket henuz replike edilmemis olabiliyor. Olumsuz
		sonuc saklandiginda ikon sonradan gelse bile bir daha aranmiyor ve
		arayuz kalici olarak yazi yedegine dusuyordu.
	]]

	local pack = findPack()
	local folder = pack and pack:FindFirstChild(category)
	local holder = folder and folder:FindFirstChild(name)
	local decal = holder and holder:FindFirstChildOfClass("Decal")

	if decal and decal.Texture ~= "" then
		cache[key] = decal.Texture
		return decal.Texture
	end

	return nil
end

--[[
	Kisa adla ikon (Icons.Map uzerinden).

	Bir kisa adin karsisinda TEK cift ({kategori, isim}) ya da SIRAYLA
	DENENECEK ciftler listesi olabilir. Liste hali paketten pakete degisen
	isimler icin: ilk bulunan kullanilir, hicbiri yoksa nil doner.
]]
function Icons.of(id: string): string?
	local entry = Icons.Map[id]
	if not entry then
		return nil
	end

	-- Ilk eleman da tabloysa bu bir alternatifler listesi
	if type(entry[1]) == "table" then
		for _, secenek in (entry :: any) :: { { string } } do
			local image = Icons.get(secenek[1], secenek[2])
			if image then
				return image
			end
		end
		return nil
	end

	local tek = (entry :: any) :: { string }
	return Icons.get(tek[1], tek[2])
end

--[[
	Bir ImageLabel/ImageButton'a ikon koyar.
	Ikon yoksa nesneye dokunmaz ve false doner.
]]
function Icons.apply(target: ImageLabel | ImageButton, id: string): boolean
	local image = Icons.of(id)
	if not image then
		return false
	end
	target.Image = image
	return true
end

--[[
	IKONU BEKLEYEREK BAGLAR

	Paket istemciye gec replike olabilir. Ikon simdi varsa hemen konur;
	yoksa arka planda birkac saniye aranmaya devam edilir. Sonuc belli
	oldugunda onResult(true/false) cagrilir -- cagiran taraf buna gore yazi
	yedegini gosterir ya da gizler.
]]
function Icons.bind(target: ImageLabel | ImageButton, id: string, onResult: ((ok: boolean) -> ())?)
	--[[
		HANGI IKONUN BAGLI OLDUGU NESNENIN USTUNDE TUTULUYOR

		Ayni yaziya ard arda FARKLI ikon baglanabiliyor (maden sayaci ada
		degisince, GPS ipucu suzme degisince). Eskiden ilk baglamanin
		yeniden deneme dongusu sonradan ikon bulup YENI ikonun ustune eski
		resmi basabiliyordu. Artik dongu her adimda "hala ben mi bagliyim"
		diye bakiyor; degilse sessizce cekiliyor.
	]]
	if target:GetAttribute("IkonKimligi") == id and target.Image ~= "" then
		-- Zaten bu ikon takili: sik cagrilarda (GPS ipucu) bosuna is yapilmasin
		if onResult then
			onResult(true)
		end
		return
	end
	target:SetAttribute("IkonKimligi", id)

	if Icons.apply(target, id) then
		if onResult then
			onResult(true)
		end
		return
	end

	-- Yeni ikon henuz yok: onceki ikon ekranda yanlis bilgi olarak kalmasin
	target.Image = ""

	task.spawn(function()
		for _ = 1, 20 do
			task.wait(0.5)
			if not target.Parent or target:GetAttribute("IkonKimligi") ~= id then
				return
			end
			if Icons.apply(target, id) then
				if onResult then
					onResult(true)
				end
				return
			end
		end

		if onResult and target:GetAttribute("IkonKimligi") == id then
			onResult(false)
		end
	end)
end

------------------------------------------------------------------
-- ASSETS > ICONS OKUYUCU
------------------------------------------------------------------
local assetCache: { [string]: string } = {}

local function assetKlasoru(): Instance?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	return assets and assets:FindFirstChild(Icons.AssetKlasoru)
end

-- Isim eslesmesi icin sadelestirme (bkz. OYUNUN KENDI IKONLARI)
local function sadelestir(ad: string): string
	local s = (string.gsub(string.lower(ad), "[^%w]", ""))
	if #s > 4 and string.sub(s, -4) == "icon" then
		s = string.sub(s, 1, -5)
	end
	if #s > 4 and string.sub(s, 1, 4) == "icon" then
		s = string.sub(s, 5)
	end
	return s
end

-- Bir nesneden resim kimligini cikarir; icinde tasiyorsa oradan
local function goruntu(node: Instance): string?
	if node:IsA("Decal") then
		-- Texture sinifi da Decal'den turuyor, ikisi birden burada
		return if node.Texture ~= "" then node.Texture else nil
	elseif node:IsA("ImageLabel") then
		return if node.Image ~= "" then node.Image else nil
	elseif node:IsA("ImageButton") then
		return if node.Image ~= "" then node.Image else nil
	elseif node:IsA("StringValue") then
		return if node.Value ~= "" then node.Value else nil
	end

	for _, cocuk in node:GetDescendants() do
		if cocuk:IsA("Decal") or cocuk:IsA("ImageLabel") or cocuk:IsA("ImageButton") then
			local bulunan = goruntu(cocuk)
			if bulunan then
				return bulunan
			end
		end
	end

	return nil
end

--[[
	Assets > Icons icinden adla resim.

	Bulunan onbellege alinir; BULUNAMAYAN alinmaz (Icons.get ile ayni
	sebep: istemci acilirken klasor henuz replike edilmemis olabilir).
]]
function Icons.assetTam(ad: string): string?
	local klasor = assetKlasoru()
	if not klasor then
		return nil
	end
	local aranan = sadelestir(ad)
	for _, node in klasor:GetDescendants() do
		if sadelestir(node.Name) == aranan then
			local bulunan = goruntu(node)
			if bulunan then
				return bulunan
			end
		end
	end
	return nil
end

function Icons.asset(ad: string): string?
	local cached = assetCache[ad]
	if cached then
		return cached
	end

	local klasor = assetKlasoru()
	if not klasor then
		return nil
	end

	local aranan = sadelestir(ad)
	if aranan == "" then
		return nil
	end

	local icerenden: string? = nil
	for _, node in klasor:GetDescendants() do
		local kok = sadelestir(node.Name)
		if kok == aranan then
			local bulunan = goruntu(node)
			if bulunan then
				assetCache[ad] = bulunan
				return bulunan
			end
		elseif not icerenden and string.find(kok, aranan, 1, true) then
			icerenden = goruntu(node)
		end
	end

	if icerenden then
		assetCache[ad] = icerenden
	end
	return icerenden
end

--[[
	Assets > Icons eslesme raporu (Output).

	Klasorun icerigi koddan gorunmuyor; isim tutmayan bir ikon oldugunda
	hangisi oldugu ve klasorde neler bulundugu tek satirda yaziliyor.
]]
function Icons.assetRaporu()
	local klasor = assetKlasoru()
	if not klasor then
		warn(
			"[Icons] ReplicatedStorage > Assets > Icons bulunamadi; "
				.. "maden ikonlari cikmaz."
		)
		return
	end

	local eksik: { string } = {}
	for id in Ores.Info do
		if not Icons.asset(id) then
			table.insert(eksik, id)
		end
	end

	if #eksik == 0 then
		print("[Icons] Assets > Icons: butun maden ikonlari bulundu.")
		return
	end

	local adlar: { string } = {}
	for _, cocuk in klasor:GetChildren() do
		table.insert(adlar, `{cocuk.Name} ({cocuk.ClassName})`)
	end
	table.sort(eksik)
	warn(
		`[Icons] Assets > Icons icinde karsiligi bulunamayan: {table.concat(eksik, ", ")}. `
			.. `Klasorde olanlar: {table.concat(adlar, ", ")}`
	)
end

--[[
	Hangi ikonlarin bulundugunu Output'a yazar.
	Paket yanlis yerdeyse ya da bir isim tutmuyorsa buradan gorulur.
]]
function Icons.report()
	local pack = findPack()
	if not pack then
		warn(
			`[Icons] '{Icons.PackName}' bulunamadi. Paketi ReplicatedStorage `
				.. "ya da Workspace icine koy."
		)
		return
	end

	local found, lost = 0, {}
	for id in Icons.Map do
		if Icons.of(id) then
			found += 1
		else
			table.insert(lost, id)
		end
	end

	table.sort(lost)
	if #lost == 0 then
		print(`[Icons] {pack:GetFullName()} -- {found} ikon hazir`)
	else
		warn(`[Icons] {found} ikon hazir, BULUNAMAYAN: {table.concat(lost, ", ")}`)
	end
end


--[[
	PAKETTE NE VAR?

	Kodda bir ikonun adini tahmin etmek yerine listeyi gormek icin. Studio'da
	komut cubuguna:

	    require(game.ReplicatedStorage.Shared.Icons).katalog("Menus")

	Kategori verilmezse butun kategorileri ve icindeki ikon adlarini yazar.
]]
function Icons.katalog(category: string?)
	local pack = findPack()
	if not pack then
		warn(`[Icons] '{Icons.PackName}' bulunamadi.`)
		return
	end

	for _, folder in pack:GetChildren() do
		if category and folder.Name ~= category then
			continue
		end

		local names = {}
		for _, node in folder:GetChildren() do
			table.insert(names, node.Name)
		end
		table.sort(names)

		print(`[Icons] {folder.Name} ({#names}): {table.concat(names, ", ")}`)
	end
end

return Icons
