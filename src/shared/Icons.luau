--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Ores = require(script.Parent:WaitForChild("Ores"))

local Icons = {}

local ASSET_KATEGORI = "Assets"
Icons.AssetKlasoru = "Icons"

Icons.PackName = "Simulator Icon Pack"

export type IconEntry = { any }

local Map: { [string]: IconEntry } = {
	rot = { "Cash", "CashIcon" },
	rotPara = {
		{ "AssetsTam", "Rot" },
		{ "AssetsTam", "Money" },
		{ "AssetsTam", "Cash" },
		{ "Cash", "CashStack" },
		{ "Cash", "Cash" },
		{ "Cash", "CashIcon" },
	},
	rotCoin = {
		{ "*", "LowPolyCoin" },
		{ "Id", "rbxassetid://17368060122" },
	},

	inventory = {
		{ "Menus", "Backpack" },
		{ "Menus", "Bag" },
		{ "Misc", "Backpack" },
		{ "Menus", "Crate" },
		{ "Menus", "Chest" },
		{ "Menus", "Inventory" },
	},
	shop = { "Menus", "Shop" },
	store = {
		{ "*", "Store" },
		{ "*", "Shop" },
	},
	teleporter = {
		{ "AssetsTam", "Teleporter" },
		{ "Menus", "Teleport" },
	},
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
	detective = {
		{ "AssetsTam", "Detective" },
		{ "Misc", "Question" },
	},
	luckyBlock = {
		{ "AssetsTam", "LuckyBlock" },
		{ "*", "LuckyBlock" },
		{ "RNG", "? Box" },
	},
	autoClicker = {
		{ "AssetsTam", "AutoClicker" },
		{ "*", "AutoClick" },
		{ "*", "Click" },
		{ "*", "Cursor" },
		{ "*", "Mouse" },
		{ "*", "Hand" },
	},
	upgrade = { "Arrows", "GoldUpgrade" },
	lockClosed = { "Misc", "LockClosed" },
	lockOpen = { "Misc", "LockOpen" },
	gps = { "Misc", "Locate" },
	shovel = { "Stats", "Power" },

	ogreticiHedef = {
		{ "Misc", "Locate" },
		{ "*", "Locate" },
	},
	ogreticiOk = {
		{ "Arrows", "Up" },
		{ "*", "Up" },
	},

	luck1 = { "Luck", "NormalLuck" },
	luck2 = { "Luck", "SuperLuck" },
	luck3 = { "Luck", "UltraLuck" },

	pets = { "Menus", "Pets" },
	index = { "Menus", "Index" },
	trade = { "Arrows", "Trade" },
	quests = { "Menus", "Quests" },
	rewards = {
		{ "*", "PurpleGift" },
		{ "Menus", "Rewards" },
	},
	vip = { "Menus", "VIP" },
	friends = { "Menus", "Friends" },
	playtime = { "Stats", "Playtime" },
	trophies = { "Stats", "Trophies/Wins" },
}

for id in Ores.Info do
	Map[`ore_{id}`] = { ASSET_KATEGORI, id }
end

Icons.Map = Map

local packFolder: Instance? = nil
local cache: { [string]: string } = {}

local function findPack(): Instance?
	if packFolder and packFolder.Parent then
		return packFolder
	end

	local roots: { Instance } = { ReplicatedStorage, Workspace }

	for _, root in roots do
		local direct = root:FindFirstChild(Icons.PackName)
			or root:FindFirstChild(Icons.PackName, true)
		if direct then
			packFolder = direct
			return direct
		end
	end

	for _, root in roots do
		for _, node in root:GetDescendants() do
			local assetIkonlari = node.Name == Icons.AssetKlasoru and node.Parent ~= nil and node.Parent.Name == "Assets"
			if node:IsA("Folder") and not assetIkonlari and string.find(string.lower(node.Name), "icon", 1, true) then
				packFolder = node
				return node
			end
		end
	end

	return nil
end

function Icons.get(category: string, name: string): string?
	if category == ASSET_KATEGORI then
		return Icons.asset(name)
	end

	if category == "AssetsTam" then
		return Icons.assetTam(name)
	end

	if category == "Id" then
		return name
	end

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

function Icons.of(id: string): string?
	local entry = Icons.Map[id]
	if not entry then
		return nil
	end

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

function Icons.apply(target: ImageLabel | ImageButton, id: string): boolean
	local image = Icons.of(id)
	if not image then
		return false
	end
	target.Image = image
	return true
end

function Icons.bind(target: ImageLabel | ImageButton, id: string, onResult: ((ok: boolean) -> ())?)
	if target:GetAttribute("IkonKimligi") == id and target.Image ~= "" then
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

local assetCache: { [string]: string } = {}

local function assetKlasoru(klasorAdi: string?): Instance?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	return assets and assets:FindFirstChild(klasorAdi or Icons.AssetKlasoru)
end

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

local function goruntu(node: Instance): string?
	if node:IsA("Decal") then
		return if node.Texture ~= "" then node.Texture else nil
	elseif node:IsA("ImageLabel") then
		return if node.Image ~= "" then node.Image else nil
	elseif node:IsA("ImageButton") then
		return if node.Image ~= "" then node.Image else nil
	elseif node:IsA("StringValue") then
		return if node.Value ~= "" then node.Value else nil
	elseif node:IsA("MeshPart") then
		return if node.TextureID ~= "" then node.TextureID else nil
	end

	for _, cocuk in node:GetDescendants() do
		if
			cocuk:IsA("Decal")
			or cocuk:IsA("ImageLabel")
			or cocuk:IsA("ImageButton")
			or cocuk:IsA("MeshPart")
		then
			local bulunan = goruntu(cocuk)
			if bulunan then
				return bulunan
			end
		end
	end

	return nil
end

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

function Icons.assetKlasorden(klasorAdi: string, ad: string): string?
	local anahtar = `{klasorAdi}/{ad}`
	local cached = assetCache[anahtar]
	if cached then
		return cached
	end

	local klasor = assetKlasoru(klasorAdi)
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
				assetCache[anahtar] = bulunan
				return bulunan
			end
		elseif not icerenden and string.find(kok, aranan, 1, true) then
			icerenden = goruntu(node)
		end
	end

	if icerenden then
		assetCache[anahtar] = icerenden
	end
	return icerenden
end

function Icons.asset(ad: string): string?
	return Icons.assetKlasorden(Icons.AssetKlasoru, ad)
end

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
