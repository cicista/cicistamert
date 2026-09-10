--!strict
-- Lune ile calisir: lune run tools/check.luau
-- src/ altindaki butun .luau dosyalarini derleyerek sozdizimi hatasi arar.
-- (Calistirmaz -- sadece parse/compile eder.)

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local failures = 0
local checked = 0

local function walk(dir: string)
	for _, entry in fs.readDir(dir) do
		local path = `{dir}/{entry}`
		if fs.isDir(path) then
			walk(path)
		elseif entry:match("%.luau$") then
			checked += 1
			local source = fs.readFile(path)
			local ok, err = pcall(function()
				luau.compile(source)
			end)
			if not ok then
				failures += 1
				print(`FAIL  {path}`)
				print(`      {tostring(err)}`)
			end
		end
	end
end

walk("src")

print("")
if failures == 0 then
	print(`OK -- {checked} dosya, sozdizimi hatasi yok`)
else
	print(`{failures}/{checked} dosyada sozdizimi hatasi var`)
	process.exit(1)
end
