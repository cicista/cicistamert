--!strict
--[[
	Backdoor tarayici.
	Kullanim: lune run tools/scan.luau harita.rbxl

	Toolbox modelleriyle gelen arka kapilari arar. Iki tur kontrol var:

	1. KAYNAK KODU  -- scriptin icindeki tehlikeli desenler
	2. YAPI         -- scriptin ADI ve DURDUGU YER
	                   (kod tertemiz gorunse de yeri ele verir)

	--------------------------------------------------------------
	NEDEN YAPI KONTROLU DE VAR

	12 Eylul 2026'da bu haritada 72 arka kapi bulundu ve tarayicinin eski
	surumu UCUNU DE kacirmisti. Kullandiklari numaralar:

	  a) Sahte isim.  "Package" gibi gorunen ad -- icindeki a ve e aslinda
	     KIRIL harfi. Studio'da goz ayirt etmez, arayinca bulunmaz.
	     70 kopyasi vardi.

	  b) Dolayli require.  Asset id kodda yazmaz; NumberPose gibi kimsenin
	     bakmadigi bir nesnenin Value'sunda durur:
	         require(script:WaitForChild("Sync", 4).Value)

	  c) Studio'da uyuma.  IsStudio() / InStudioMode() ile Studio'da hic
	     calismaz, yalnizca CANLI sunucuda uyanir. Gelistirici hic gormez.

	  d) Id'yi calisma aninda insa etme.  Id hicbir yerde yazmaz:
	     MarketplaceService:GetProductInfo(x).Description okunur, harfleri
	     sayiya cevrilir, sonra global `script` sahte bir tabloyla
	     degistirilip require edilir.

	  e) Sacma yere saklanma.  Scriptler Configuration klasorunun, animasyon
	     kayitlarinin (AnimSaves > Keyframe > Pose) ve hatta bir IntValue'nun
	     altina konmustu. Oralarda kimse script aramaz.

	Asagidaki kontroller bu bes numarayi da hedefler.
	--------------------------------------------------------------

	Agirliklar:  3 = neredeyse kesin arka kapi,  2 = bak,  1 = genelde zararsiz
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local placePath = process.args[1] or "game.rbxl"
if not fs.isFile(placePath) then
	print(`HATA: {placePath} bulunamadi`)
	process.exit(1)
end

local game = roblox.deserializePlace(fs.readFile(placePath))

local SCRIPT_CLASSES = {
	Script = true,
	LocalScript = true,
	ModuleScript = true,
}

------------------------------------------------------------------
-- 1. KAYNAK KODU DESENLERI
------------------------------------------------------------------
local PATTERNS = {
	-- Uzaktan kod calistirma
	{ "require%s*%(%s*%d%d%d+", "require(<sayi>) -- uzaktan modul", 3 },
	{ "require%s*%([^)]-%.Value", "require(<nesne>.Value) -- gizlenmis uzaktan modul", 3 },
	{ "loadstring", "loadstring -- dinamik kod", 3 },
	{ "GetObjects%s*%(", "GetObjects -- uzaktan asset yukleme", 3 },

	-- Global `script` degiskenini ezmek: mesru kodda pratikte hic olmaz.
	-- Amaci require(script.X) cagrisini masum gostermek.
	{ "script%s*=%s*{", "global `script` sahte tabloyla degistiriliyor", 3 },

	-- Asset aciklamasindan id cekme
	{ "GetProductInfo", "GetProductInfo -- id'yi asset aciklamasindan cekme", 3 },

	-- Disari veri
	{ "HttpGet", "HttpGet -- disari istek", 3 },
	{ "PostAsync%s*%(", "HttpService PostAsync -- veri sizdirma", 3 },

	-- Studio'da uyuma
	{ "IsStudio%s*%(", "IsStudio() -- Studio'da uyuyup canli sunucuda uyanma", 2 },
	{ "InStudioMode%s*%(", "InStudioMode() -- Studio'da uyuyup canli sunucuda uyanma", 2 },
	{ "UserSettings%s*%(%s*%)", "UserSettings() -- genelde InStudioMode icin", 2 },
	{ "JobId", "JobId -- yalnizca canli sunucuda calisma kontrolu", 2 },

	-- Gizlenmis metin / id insasi
	{ "getfenv", "getfenv -- ortam kurcalama", 2 },
	{ "string%.char%s*%(", "string.char -- gizlenmis metin", 2 },
	{ ":byte%s*%(", ":byte() -- harflerden sayi/id insasi", 2 },
	{ "\\%d%d%d", "escape'li string -- gizlenmis metin", 2 },

	-- Genelde zararsiz
	{ "GetAsync%s*%(", "GetAsync (DataStore ise normaldir)", 1 },
	{ "rbxassetid://%d+", "rbxassetid referansi", 1 },
}

------------------------------------------------------------------
-- 2. YAPI KONTROLLERI
------------------------------------------------------------------

--[[
	Bir scriptin EBEVEYNI bunlardan biriyse durum ciddi: kimse bir
	Configuration klasorunun ya da bir IntValue'nun altinda script aramaz.
]]
local SUPHELI_EBEVEYN = {
	Configuration = true,
	Pose = true,
	NumberPose = true,
	Keyframe = true,
	KeyframeSequence = true,
	IntValue = true,
	NumberValue = true,
	StringValue = true,
	ObjectValue = true,
	BoolValue = true,
	CFrameValue = true,
	Vector3Value = true,
	Color3Value = true,
	BrickColorValue = true,
}

-- Asset id tasiyabilen deger nesneleri
local DEGER_CLASSLARI = {
	NumberPose = true,
	NumberValue = true,
	IntValue = true,
	StringValue = true,
	IntConstrainedValue = true,
	DoubleConstrainedValue = true,
}

------------------------------------------------------------------
type Finding = { path: string, class: string, note: string, weight: number, line: string }
local findings: { Finding } = {}

local function ekle(path: string, class: string, note: string, weight: number, line: string?)
	table.insert(findings, {
		path = path,
		class = class,
		note = note,
		weight = weight,
		line = line or "",
	})
end

-- Adin ham bayt gorunumu: Kiril harfleri boyle ortaya cikar
local function baytGorunumu(s: string): string
	local out = {}
	for i = 1, #s do
		local b = string.byte(s, i)
		table.insert(out, if b < 32 or b > 126 then string.format("<%02X>", b) else string.char(b))
	end
	return table.concat(out)
end

local function kaynakTara(child: any, childPath: string)
	local ok, source = pcall(function()
		return child.Source
	end)
	if not ok or type(source) ~= "string" then
		return
	end

	for _, entry in PATTERNS do
		local pattern, note, weight = entry[1], entry[2], entry[3]
		if source:match(pattern) then
			--[[
				Eslesen satiri bul. Desen satira yayilmissa (ornegin require
				acilip alt satirda kapaniyorsa) bos kalir -- bulgu yine de
				raporlanir, yalnizca ornek satir gosterilmez.
			]]
			local lineText = ""
			for line in source:gmatch("[^\r\n]+") do
				if line:match(pattern) then
					lineText = line:gsub("^%s+", "")
					if #lineText > 110 then
						lineText = lineText:sub(1, 110) .. " ..."
					end
					break
				end
			end
			ekle(childPath, child.ClassName, note, weight, lineText)
		end
	end
end

local function yapiTara(child: any, childPath: string, ebeveyn: any)
	local ad = child.Name

	--[[
		ASCII DISI SCRIPT ADI

		Mesru bir script adinda Kiril/Yunan harfi olmaz. utf8.len harf
		sayisini, # bayt sayisini verir; ikisi tutmuyorsa ad ASCII disidir.
	]]
	if utf8.len(ad) ~= #ad then
		ekle(childPath, child.ClassName, `ASCII disi script adi -- baytlar: {baytGorunumu(ad)}`, 3)
	end

	if ebeveyn and SUPHELI_EBEVEYN[ebeveyn.ClassName] then
		ekle(childPath, child.ClassName, `bir [{ebeveyn.ClassName}] altinda duruyor -- script icin olagan bir yer degil`, 3)
	end

	if string.find(childPath, "AnimSaves", 1, true) then
		ekle(childPath, child.ClassName, "animasyon kayitlarinin (AnimSaves) icine saklanmis", 3)
	end
end

local function degerTara(child: any, childPath: string, ebeveyn: any)
	if not DEGER_CLASSLARI[child.ClassName] then
		return
	end

	local ok, deger = pcall(function()
		return child.Value
	end)
	if not ok then
		return
	end

	--[[
		Asset id boyutunda sayi tutan deger nesnesi. Tek basina masum
		olabilir; ama EBEVEYNI bir scriptse o script onu require ediyordur.
	]]
	if string.match(tostring(deger), "^%d%d%d%d%d%d%d%d+$") then
		local scriptAltinda = ebeveyn ~= nil and SCRIPT_CLASSES[ebeveyn.ClassName] == true
		ekle(
			childPath,
			child.ClassName,
			if scriptAltinda
				then `asset id BIR SCRIPTIN ALTINDA saklaniyor: {deger}`
				else `deger nesnesinde asset id: {deger}`,
			if scriptAltinda then 3 else 2
		)
	end
end

local function scan(instance: any, path: string)
	local ok, kids = pcall(function()
		return instance:GetChildren()
	end)
	if not ok then
		return
	end

	for _, child in kids do
		local childPath = `{path}.{child.Name}`

		if SCRIPT_CLASSES[child.ClassName] then
			kaynakTara(child, childPath)
			yapiTara(child, childPath, instance)
		end

		degerTara(child, childPath, instance)

		scan(child, childPath)
	end
end

for _, service in game:GetChildren() do
	scan(service, service.Name)
end

------------------------------------------------------------------
-- RAPOR
------------------------------------------------------------------
table.sort(findings, function(a, b)
	if a.weight ~= b.weight then
		return a.weight > b.weight
	end
	return a.path < b.path
end)

if #findings == 0 then
	print("TEMIZ -- bilinen arka kapi izi bulunamadi")
	return
end

--[[
	Ayni arka kapinin 70 kopyasi ekrani doldurmasin: ayni ad + ayni bulgu
	tek satirda "[70 kopya]" diye ozetlenir, ornek yol da yazilir.
]]
type Grup = { ornek: Finding, adet: number }
local gruplar: { Grup } = {}
local index: { [string]: Grup } = {}

for _, f in findings do
	local ad = string.match(f.path, "[^%.]+$") or f.path
	local key = `{ad}|{f.note}|{f.class}`
	local g = index[key]
	if g then
		g.adet += 1
	else
		g = { ornek = f, adet = 1 }
		index[key] = g
		table.insert(gruplar, g)
	end
end

local yuksek = 0
for _, f in findings do
	if f.weight >= 3 then
		yuksek += 1
	end
end

print(`{#findings} supheli iz ({#gruplar} farkli tur)`)
if yuksek > 0 then
	print(`YUKSEK RISK: {yuksek} -- bunlara mutlaka bak`)
end

local lastWeight = -1
for _, g in gruplar do
	local f = g.ornek
	if f.weight ~= lastWeight then
		lastWeight = f.weight
		local label = if f.weight >= 3
			then "=== YUKSEK RISK ==="
			elseif f.weight == 2 then "=== ORTA RISK ==="
			else "=== DUSUK RISK (genelde zararsiz) ==="
		print(`\n{label}`)
	end

	local adet = if g.adet > 1 then `   [{g.adet} kopya]` else ""
	print(`  [{f.class}] {f.path}{adet}`)
	print(`      {f.note}`)
	if f.line ~= "" then
		print(`      > {f.line}`)
	end
end
