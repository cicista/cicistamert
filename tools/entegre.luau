--!strict
--[[
	Place dosyasina GUNCEL KODU gomer.
	Kullanim: lune run tools/entegre.luau <girdi.rbxl> [cikti.rbxl]

	extract.luau'nun tersi: oradaki place'ten koda gider, burasi koddan
	place'e gider.

	NE YAPAR
	  Diskteki src/ klasorunu okur ve place dosyasindaki su uc yeri
	  BASTAN YAZAR -- Rojo'nun Connect edince yaptiginin aynisi:

	      src/server/  ->  ServerScriptService
	      src/shared/  ->  ReplicatedStorage > Shared
	      src/client/  ->  StarterPlayer > StarterPlayerScripts

	NE YAPMAZ
	  Baska HICBIR yere dokunmaz. Ozellikle:
	      Workspace                    -- harita, NPC'ler, FuseVFX, sesler
	      ReplicatedStorage > Assets   -- brainrot modelleri, LuckyBlocks
	  Bunlar place dosyasinda oldugu gibi kalir.

	NEDEN VAR
	  Kod git'te, harita place dosyasinda yasiyor. Ikisini birlestirmenin
	  normal yolu Studio'da Rojo Connect etmek. Ama place'i baskasina
	  gonderecekken ya da baskasinin Team Create'ine yayinlatacakken elde
	  TEK bir guncel dosya olmasi gerekiyor -- bu arac onu uretiyor.

	DOSYA ADI KURALLARI (Rojo ile ayni)
	      Foo.server.luau  ->  Script
	      Foo.client.luau  ->  LocalScript
	      Foo.luau         ->  ModuleScript
	      klasor/          ->  Folder
	      klasor/init.luau ->  klasorun kendisi ModuleScript olur
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Instance = roblox.Instance

------------------------------------------------------------------
-- GIRDI
------------------------------------------------------------------
local inputPath = process.args[1]
if not inputPath or not fs.isFile(inputPath) then
	print("HATA: place dosyasi verilmedi ya da bulunamadi")
	print("  lune run tools/entegre.luau guncel.rbxl [cikti.rbxl]")
	process.exit(1)
end

local outputPath = process.args[2] or "oyun-hazir.rbxl"

for _, dir in { "src/server", "src/shared", "src/client" } do
	if not fs.isDir(dir) then
		print(`HATA: {dir} bulunamadi -- bu araci depo klasorunden calistir`)
		process.exit(1)
	end
end

print(`Okunuyor: {inputPath}`)
local game = roblox.deserializePlace(fs.readFile(inputPath))

------------------------------------------------------------------
-- KOD -> INSTANCE
------------------------------------------------------------------

-- Dosya adindan sinif ve instance adi
local function classOf(fileName: string): (string?, string?)
	local name = fileName:match("^(.+)%.server%.luau$")
	if name then
		return "Script", name
	end

	name = fileName:match("^(.+)%.client%.luau$")
	if name then
		return "LocalScript", name
	end

	name = fileName:match("^(.+)%.luau$")
	if name then
		return "ModuleScript", name
	end

	return nil, nil
end

local created = 0

--[[
	Bir klasoru hedef instance'in altina kurar.

	Klasorun icinde init.luau / init.server.luau / init.client.luau varsa
	klasorun KENDISI o script olur (Rojo kurali); yoksa Folder olur.
]]
local function build(dir: string, parent: any)
	for _, entry in fs.readDir(dir) do
		local path = `{dir}/{entry}`

		if fs.isDir(path) then
			-- Klasorun kendisi script mi olacak?
			local holder: any = nil

			for _, initName in { "init.server.luau", "init.client.luau", "init.luau" } do
				local initPath = `{path}/{initName}`
				if fs.isFile(initPath) then
					local class = classOf(initName)
					holder = Instance.new(class :: any)
					holder.Source = fs.readFile(initPath)
					break
				end
			end

			if not holder then
				holder = Instance.new("Folder")
			end

			holder.Name = entry
			holder.Parent = parent
			created += 1

			build(path, holder)
			continue
		end

		local class, name = classOf(entry)
		if not class or not name then
			continue
		end

		-- init dosyalari yukarida klasore donusturuldu, tekrar eklenmesin
		if name == "init" then
			continue
		end

		local script = Instance.new(class :: any)
		script.Name = name
		script.Source = fs.readFile(path)
		script.Parent = parent
		created += 1
	end
end

--[[
	Hedefin altini bosaltir ve silinenleri yazar.

	Rojo Connect ederken de aynisini yapiyor: yonettigi yerin icerigi
	tamamen diskten gelir. Silinenleri yazdiriyoruz ki oraya elle konmus
	bir sey varsa sessizce kaybolmasin.
]]
local function clear(target: any, label: string)
	local removed = {}

	for _, child in target:GetChildren() do
		table.insert(removed, `{child.ClassName} "{child.Name}"`)
		child:Destroy()
	end

	if #removed > 0 then
		print(`  {label}: {#removed} eski nesne silindi`)
		for _, text in removed do
			print(`      - {text}`)
		end
	end
end

------------------------------------------------------------------
-- YERLESTIRME
------------------------------------------------------------------

-- Servisi bulur; ara klasor gerekiyorsa (Shared, StarterPlayerScripts) kurar
local function target(serviceName: string, childName: string?, childClass: string?): any
	local service = game:GetService(serviceName :: any)

	if not childName then
		return service
	end

	local child = service:FindFirstChild(childName)
	if not child then
		child = Instance.new((childClass or "Folder") :: any)
		child.Name = childName
		child.Parent = service
		print(`  {serviceName} > {childName} yoktu, olusturuldu`)
	end

	return child
end

print("")
print("Kod gomuluyor...")

local routes = {
	{ dir = "src/server", node = target("ServerScriptService"), label = "ServerScriptService" },
	{ dir = "src/shared", node = target("ReplicatedStorage", "Shared"), label = "ReplicatedStorage > Shared" },
	{
		dir = "src/client",
		node = target("StarterPlayer", "StarterPlayerScripts", "StarterPlayerScripts"),
		label = "StarterPlayerScripts",
	},
}

for _, route in routes do
	clear(route.node, route.label)
	build(route.dir, route.node)
end

------------------------------------------------------------------
-- YAZ
------------------------------------------------------------------
fs.writeFile(outputPath, roblox.serializePlace(game))

print("")
print(`TAMAM -- {created} script/klasor gomuldu`)
print(`Cikti: {outputPath}`)
print("")
print("Workspace ve ReplicatedStorage > Assets'e DOKUNULMADI;")
print("haritan, NPC'lerin ve modellerin oldugu gibi duruyor.")
