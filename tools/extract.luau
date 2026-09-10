--!strict
-- Lune ile calisir: lune run tools/extract.luau game.rbxl
-- Place icindeki tum scriptleri Rojo duzenine uygun sekilde src/ altina yazar.
--
-- Eslesme:
--   ServerScriptService.*            -> src/server/...
--   ReplicatedStorage.*              -> src/shared/...
--   StarterPlayer.StarterPlayerScripts.* -> src/client/...
--   StarterGui.*                     -> src/gui/...
--   digerleri                        -> src/_other/<Servis>/...

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local placePath = process.args[1] or "game.rbxl"
if not fs.isFile(placePath) then
	print(`HATA: {placePath} bulunamadi`)
	process.exit(1)
end

local game = roblox.deserializePlace(fs.readFile(placePath))

local EXT = {
	Script = ".server.luau",
	LocalScript = ".client.luau",
	ModuleScript = ".luau",
}

local written = 0

local function sanitize(name: string): string
	return (name:gsub("[^%w%-_ ]", "_"))
end

local function ensureDir(dir: string)
	if not fs.isDir(dir) then
		fs.writeDir(dir)
	end
end

-- Bir instance alt agacini verilen klasore yazar.
-- Script olan instance'lar dosya, cocugu olan scriptler init.* olarak klasore doner.
local function dump(instance: any, dir: string)
	for _, child in instance:GetChildren() do
		local ext = EXT[child.ClassName]
		local name = sanitize(child.Name)
		local hasKids = #child:GetChildren() > 0

		if ext then
			local source = child.Source or ""
			if hasKids then
				local sub = `{dir}/{name}`
				ensureDir(sub)
				fs.writeFile(`{sub}/init{ext}`, source)
				written += 1
				dump(child, sub)
			else
				ensureDir(dir)
				fs.writeFile(`{dir}/{name}{ext}`, source)
				written += 1
			end
		elseif hasKids then
			dump(child, `{dir}/{name}`)
		end
	end
end

local ROUTES: { { service: string, sub: string?, dir: string } } = {
	{ service = "ServerScriptService", dir = "src/server" },
	{ service = "ServerStorage", dir = "src/serverstorage" },
	{ service = "ReplicatedStorage", dir = "src/shared" },
	{ service = "ReplicatedFirst", dir = "src/replicatedfirst" },
	{ service = "StarterPlayer", sub = "StarterPlayerScripts", dir = "src/client" },
	{ service = "StarterPlayer", sub = "StarterCharacterScripts", dir = "src/character" },
	{ service = "StarterGui", dir = "src/gui" },
	{ service = "StarterPack", dir = "src/starterpack" },
}

ensureDir("src")

for _, route in ROUTES do
	local ok, service = pcall(function()
		return game:GetService(route.service)
	end)
	if not ok or not service then
		continue
	end

	local target = service
	if route.sub then
		target = service:FindFirstChild(route.sub)
		if not target then
			continue
		end
	end

	dump(target, route.dir)
end

print(`{written} script yazildi.`)
