--!strict
--[[
	Backdoor tarayici.
	Kullanim: lune run tools/scan.luau game.rbxl

	Toolbox modellerine gizlenen arka kapilarin tipik izlerini arar:
	  GetObjects / rbxassetid  -> uzaktan asset indirip calistirma
	  require(<sayi>)          -> uzaktan modul cagirma (en yaygin backdoor)
	  loadstring / getfenv     -> dinamik kod calistirma
	  HttpGet / GetAsync       -> disari veri gonderme, uzaktan kod cekme
	  Players.PlayerAdded + Instance.new("RemoteEvent") -> gizli komut kanali

	Bulduklarini scripti tam yoluyla listeler.
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

-- { desen, aciklama, agirlik }  agirlik 3 = neredeyse kesin arka kapi
local PATTERNS = {
	{ "GetObjects%s*%(", "GetObjects -- uzaktan asset yukleme", 3 },
	{ "rbxassetid://%d+", "rbxassetid referansi", 1 },
	{ "require%s*%(%s*%d%d%d+", "require(<sayi>) -- uzaktan modul", 3 },
	{ "loadstring", "loadstring -- dinamik kod", 3 },
	{ "getfenv", "getfenv -- ortam kurcalama", 2 },
	{ "HttpGet", "HttpGet -- disari istek", 3 },
	{ "GetAsync%s*%(", "HttpService GetAsync", 2 },
	{ "PostAsync%s*%(", "HttpService PostAsync -- veri sizdirma", 3 },
	{ "\\%d%d%d", "escape'li string -- gizlenmis metin", 2 },
	{ "string%.char%s*%(", "string.char -- gizlenmis metin", 2 },
}

local findings: { { path: string, class: string, note: string, weight: number, line: string } } = {}

local function scan(instance: any, path: string)
	for _, child in instance:GetChildren() do
		local childPath = `{path}.{child.Name}`

		if SCRIPT_CLASSES[child.ClassName] then
			local source = child.Source or ""

			for _, entry in PATTERNS do
				local pattern, note, weight = entry[1], entry[2], entry[3]
				local hit = source:match(pattern)
				if hit then
					-- Eslesen satiri bul
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

					table.insert(findings, {
						path = childPath,
						class = child.ClassName,
						note = note,
						weight = weight,
						line = lineText,
					})
				end
			end
		end

		scan(child, childPath)
	end
end

for _, service in game:GetChildren() do
	scan(service, service.Name)
end

table.sort(findings, function(a, b)
	return a.weight > b.weight
end)

if #findings == 0 then
	print("TEMIZ -- bilinen arka kapi izi bulunamadi")
	return
end

print(`{#findings} supheli iz bulundu:\n`)

local lastWeight = -1
for _, f in findings do
	if f.weight ~= lastWeight then
		lastWeight = f.weight
		local label = if f.weight >= 3 then "=== YUKSEK RISK ==="
			elseif f.weight == 2 then "=== ORTA RISK ==="
			else "=== DUSUK RISK (genelde zararsiz) ==="
		print(`\n{label}`)
	end

	print(`  [{f.class}] {f.path}`)
	print(`      {f.note}`)
	if f.line ~= "" then
		print(`      > {f.line}`)
	end
end
