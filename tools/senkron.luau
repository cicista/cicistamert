--!strict
--[[
	Studio'daki kod ile diskteki kodu karsilastirir.
	Kullanim:
	    1. Studio: Dosya - Kopyasini indir  ->  guncel.rbxl
	    2. lune run tools/senkron.luau guncel.rbxl

	Her script icin diskteki dosyayla Studio'daki surumu karsilastirir ve
	FARKLI olanlari listeler. Boylece "hangi degisiklik inmemis" sorusu
	tahminle degil olcumle cevaplanir.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local placePath = process.args[1]
if not placePath or not fs.isFile(placePath) then
	print("HATA: place dosyasi ver")
	print("  Studio: Dosya - Kopyasini indir  ->  guncel.rbxl")
	print("  lune run tools/senkron.luau guncel.rbxl")
	process.exit(1)
end

local game = roblox.deserializePlace(fs.readFile(placePath))

-- Rojo project.json ile ayni eslesme
local ROUTES = {
	{ dir = "src/server", service = "ServerScriptService", sub = nil },
	{ dir = "src/shared", service = "ReplicatedStorage", sub = "Shared" },
	{ dir = "src/client", service = "StarterPlayer", sub = "StarterPlayerScripts" },
}

-- Dosya adindan Studio'daki instance adi ("Foo.server.luau" -> "Foo")
local function instanceName(fileName: string): string
	return (fileName:gsub("%.server%.luau$", ""):gsub("%.client%.luau$", ""):gsub("%.luau$", ""))
end

-- Karsilastirma icin bosluk farklarini yok say
local function normalize(source: string): string
	return (source:gsub("\r\n", "\n"):gsub("%s+$", ""))
end

local same, differ, missing = 0, 0, 0
local problems: { string } = {}

local function compare(folder: Instance?, dir: string, prefix: string)
	if not fs.isDir(dir) then
		return
	end

	for _, entry in fs.readDir(dir) do
		local path = `{dir}/{entry}`

		if fs.isDir(path) then
			local child = folder and folder:FindFirstChild(entry)
			if not child then
				missing += 1
				table.insert(problems, `EKSIK KLASOR  {prefix}{entry}`)
			else
				compare(child, path, `{prefix}{entry}.`)
			end
			continue
		end

		if not entry:match("%.luau$") then
			continue
		end

		local name = instanceName(entry)
		local instance = folder and folder:FindFirstChild(name)

		if not instance then
			missing += 1
			table.insert(problems, `STUDIO'DA YOK  {prefix}{name}`)
			continue
		end

		local diskSource = normalize(fs.readFile(path))
		local studioSource = normalize((instance :: any).Source or "")

		if diskSource == studioSource then
			same += 1
		else
			differ += 1
			local diskLines = select(2, diskSource:gsub("\n", "")) + 1
			local studioLines = select(2, studioSource:gsub("\n", "")) + 1
			table.insert(
				problems,
				`ESKI KALMIS   {prefix}{name}   (disk {diskLines} satir, Studio {studioLines} satir)`
			)
		end
	end
end

for _, route in ROUTES do
	local ok, service = pcall(function()
		return game:GetService(route.service)
	end)
	if not ok or not service then
		continue
	end

	local root: Instance? = service
	if route.sub then
		root = service:FindFirstChild(route.sub)
	end

	compare(root, route.dir, "")
end

print(`GUNCEL: {same}   ESKI: {differ}   EKSIK: {missing}`)
print("")

if #problems == 0 then
	print("Her sey senkron -- Studio diskle ayni.")
else
	for _, line in problems do
		print("  " .. line)
	end
	print("")
	print("Duzeltmek icin: YENILE.bat calistir, sonra Studio'da Disconnect + Connect")
end
