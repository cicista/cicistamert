--!strict
--[[
	Rojo'nun urettigi place icindeki GERCEK fiyatlari okur.
	Kullanim: lune run tools/fiyat.luau <place.rbxl>

	Boylece "diskte ne yaziyor" ile "Studio'ya ne gidiyor" ayrimi yapilir:
	  - rojo build ciktisini verirsen  -> Rojo'nun gonderdigi surum
	  - Studio'dan indirdigin place    -> Studio'da fiilen duran surum
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local placePath = process.args[1]
if not placePath or not fs.isFile(placePath) then
	print("HATA: place dosyasi ver -- lune run tools/fiyat.luau <dosya.rbxl>")
	process.exit(1)
end

local game = roblox.deserializePlace(fs.readFile(placePath))

-- Modulun kaynagindan displayName/price ciftlerini ayikla
local function dump(label: string, moduleName: string)
	local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
	local module = shared and shared:FindFirstChild(moduleName)

	if not module then
		print(`{label}: modul bulunamadi (ReplicatedStorage.Shared.{moduleName})`)
		return
	end

	local source = (module :: any).Source or ""
	print(`\n=== {label} ===`)

	local pendingName: string? = nil
	for line in source:gmatch("[^\r\n]+") do
		local name = line:match('displayName%s*=%s*"([^"]+)"')
		if name then
			pendingName = name
		end

		local price = line:match("price%s*=%s*([%d_]+)")
		if price and pendingName then
			print(string.format("  %-18s %s", pendingName, (price:gsub("_", ""))))
			pendingName = nil
		end
	end
end

dump("KUREKLER", "Shovels")
dump("DEDEKTORLER", "Detectors")
