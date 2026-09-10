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

local Icons = {}

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
	rotCoin = { "Coins", "CoinIcon" },

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
	teleport = { "Menus", "Teleport" },
	settings = { "Menus", "Settings" },
	seller = { "Cash", "CashBag" },
	detective = { "Misc", "Question" },
	slotMachine = { "RNG", "Wheel" },
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
	rewards = { "Menus", "Rewards" },
	vip = { "Menus", "VIP" },
	friends = { "Menus", "Friends" },
	playtime = { "Stats", "Playtime" },
	trophies = { "Stats", "Trophies/Wins" },
}

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
			if node:IsA("Folder") and string.find(string.lower(node.Name), "icon", 1, true) then
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
	if Icons.apply(target, id) then
		if onResult then
			onResult(true)
		end
		return
	end

	task.spawn(function()
		for _ = 1, 20 do
			task.wait(0.5)
			if not target.Parent then
				return
			end
			if Icons.apply(target, id) then
				if onResult then
					onResult(true)
				end
				return
			end
		end

		if onResult then
			onResult(false)
		end
	end)
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
