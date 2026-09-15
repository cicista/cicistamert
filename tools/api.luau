--!strict
--[[
	API tutarlilik denetcisi.
	Kullanim: lune run tools/api.luau

	"Modul.fonksiyon()" seklindeki her cagriyi, o modulun GERCEKTEN
	tanimladigi alanlarla karsilastirir ve karsiligi olmayanlari listeler.

	Ne ise yarar: bir fonksiyonu yeniden adlandirdiginda ya da sildiginde
	geride kalan cagriyi bulur. Sozdizimi denetcisi (check.luau) bunu
	yakalayamaz -- kod gayet gecerlidir, yalnizca calisma aninda
	"attempt to call a nil value" diye patlar. Bu tur hatalar pcall icinde
	yutuldugunda (ornegin Envanter'in tool uretimi) hic gorunmez bile.

	Kaba bir metin taramasidir; amaci kesinlik degil, gozden kacani
	yakalamak. Yanlis alarmlari IGNORE listesine ekleyebilirsin.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

-- Denetlenecek moduller: dosya yolu -> kod icinde kullanilan degisken adi
local MODULES: { [string]: string } = {
	["src/shared/Assets.luau"] = "Assets",
	["src/shared/Bases.luau"] = "Bases",
	["src/shared/Brainrots.luau"] = "Brainrots",
	["src/shared/Condition.luau"] = "Condition",
	["src/shared/Divine.luau"] = "Divine",
	["src/shared/DigMinigame.luau"] = "DigMinigame",
	["src/shared/Detectors.luau"] = "Detectors",
	["src/shared/Fonts.luau"] = "Fonts",
	["src/shared/Format.luau"] = "Format",
	["src/shared/Fuse.luau"] = "Fuse",
	["src/shared/LevelGlow.luau"] = "LevelGlow",
	["src/shared/LuckyBlock.luau"] = "LuckyBlock",
	["src/shared/Mutations.luau"] = "Mutations",
	["src/shared/Net.luau"] = "Net",
	["src/shared/Rarity.luau"] = "Rarity",
	["src/shared/Shovels.luau"] = "Shovels",
	["src/server/Modules/PlayerData.luau"] = "PlayerData",
	["src/server/Modules/Envanter.luau"] = "Envanter",
	["src/server/Modules/Tools.luau"] = "Tools",
	["src/server/Modules/Beams.luau"] = "Beams",
	["src/server/Modules/Sand.luau"] = "Sand",
	["src/server/Modules/LuckyBlockOdul.luau"] = "LuckyBlockOdul",
	["src/client/UI.luau"] = "UI",
	["src/client/Rulet.luau"] = "Rulet",
}

-- Yanlis alarmlar (yerel degiskenler, Roblox API'si vb.)
local IGNORE: { [string]: boolean } = {
	["Net.Events"] = true,
}

--[[
	Bir modulun disariya actigi alanlar.

	Yakalanan bicimler:
	    function Modul.ad(     -- fonksiyon
	    Modul.ad = ...         -- alan atamasi
	    export type Ad         -- tip (Modul.Ad seklinde kullanilir)

	Tablo icindeki serbest "ad = deger" satirlari BILEREK toplanmiyor:
	onlar yerel degiskenleri de yakalayip her seyi "tanimli" gosteriyor ve
	denetimi ise yaramaz hale getiriyordu.
]]
local function exportsOf(source: string, alias: string): { [string]: boolean }
	local out: { [string]: boolean } = {}

	for name in source:gmatch(`function%s+{alias}%.([%w_]+)`) do
		out[name] = true
	end
	for name in source:gmatch(`{alias}%.([%w_]+)%s*=[^=]`) do
		out[name] = true
	end
	-- Disa acilan tipler: "Modul.Tip" seklinde referans veriliyor
	for name in source:gmatch("export%s+type%s+([%w_]+)") do
		out[name] = true
	end

	return out
end

--[[
	Kaynaktaki blok yorumlarini ve satir yorumlarini bosluga cevirir.
	Yorumlardaki "Modul.alan" anlatimlari yanlis alarm uretiyordu.
]]
local function stripComments(source: string): string
	-- Blok yorumlari: satir sayisi bozulmasin diye satir sonlari korunur
	source = source:gsub("%-%-%[%[.-%]%]", function(block)
		return (block:gsub("[^\n]", " "))
	end)
	-- Satir yorumlari
	source = source:gsub("%-%-[^\n]*", "")
	return source
end

local function walk(dir: string, out: { string })
	for _, entry in fs.readDir(dir) do
		local path = `{dir}/{entry}`
		if fs.isDir(path) then
			walk(path, out)
		elseif entry:match("%.luau$") then
			table.insert(out, path)
		end
	end
	return out
end

------------------------------------------------------------------
-- 1. Her modulun actigi alanlari topla
------------------------------------------------------------------
local exports: { [string]: { [string]: boolean } } = {}

for path, alias in MODULES do
	if not fs.isFile(path) then
		print(`UYARI: {path} bulunamadi`)
		continue
	end
	exports[alias] = exportsOf(fs.readFile(path), alias)
end

------------------------------------------------------------------
-- 2. Butun kaynaklarda kullanimlari tara
------------------------------------------------------------------
local files = walk("src", {})
table.sort(files)

type Problem = { file: string, line: number, text: string, ref: string }
local problems: { Problem } = {}

for _, path in files do
	local source = stripComments(fs.readFile(path))
	local lineNumber = 0

	for line in source:gmatch("[^\n]*") do
		lineNumber += 1

		local trimmed = line:gsub("^%s+", "")

		for alias, name in line:gmatch("([%u][%w_]*)%.([%w_]+)") do
			local known = exports[alias]
			if not known then
				continue
			end

			local ref = `{alias}.{name}`
			if not known[name] and not IGNORE[ref] then
				table.insert(problems, {
					file = path,
					line = lineNumber,
					text = trimmed,
					ref = ref,
				})
			end
		end
	end
end

------------------------------------------------------------------
-- 3. Rapor
------------------------------------------------------------------
print("")
if #problems == 0 then
	print(`OK -- {#files} dosya, tanimsiz modul alani yok`)
	return
end

print(`{#problems} supheli referans:\n`)

for _, p in problems do
	print(`  {p.ref}`)
	print(`      {p.file}:{p.line}`)
	print(`      {p.text}`)
end

print("")
print("Yanlis alarm varsa tools/api.luau icindeki IGNORE listesine ekle.")
process.exit(1)
