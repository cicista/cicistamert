--!strict
-- Lune ile calisir: lune run tools/inspect.luau game.rbxl
-- Place dosyasinin agac yapisini ve icindeki tum scriptleri listeler.

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

local scripts: { { path: string, class: string, lines: number, bytes: number } } = {}

local function walk(instance: any, path: string, depth: number, out: { string })
	for _, child in instance:GetChildren() do
		local childPath = `{path}.{child.Name}`
		local class = child.ClassName

		if depth <= 2 then
			table.insert(out, `{string.rep("  ", depth)}{child.Name} [{class}]`)
		end

		if SCRIPT_CLASSES[class] then
			local source = child.Source or ""
			table.insert(scripts, {
				path = childPath,
				class = class,
				lines = select(2, source:gsub("\n", "")) + 1,
				bytes = #source,
			})
		end

		walk(child, childPath, depth + 1, out)
	end
end

local tree: { string } = {}
for _, service in game:GetChildren() do
	local kids = #service:GetChildren()
	if kids > 0 then
		table.insert(tree, `{service.Name} [{service.ClassName}]  ({kids} cocuk)`)
		walk(service, service.Name, 1, tree)
	end
end

print("=== AGAC (2 seviye) ===")
print(table.concat(tree, "\n"))

print("")
print(`=== SCRIPTLER ({#scripts} adet) ===`)
table.sort(scripts, function(a, b)
	return a.bytes > b.bytes
end)

local total = 0
for _, s in scripts do
	total += s.bytes
	print(`{s.bytes}b  {s.lines} satir  [{s.class}]  {s.path}`)
end
print(`\nTOPLAM kaynak: {total} byte`)
