--!strict
-- Lune ile calisir: lune run tools/check.luau
-- src/ altindaki butun .luau dosyalarini derleyerek sozdizimi hatasi arar.
-- (Calistirmaz -- sadece parse/compile eder.)

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local failures = 0
local checked = 0

--[[
	200 YEREL SINIRI

	Luau bir fonksiyonda ayni anda en fazla 200 yerel tutar. Asilirsa
	script Studio'da "Out of local registers" verip HIC calismaz (18 Eylul
	2026'da Menuler boyle kirildi, butun arayuz kayboldu). luau.compile
	bunu yakalamadigi icin burada kaba bir sayim yapiliyor:

	  ust seviye yereller (girintisiz "local ...")
	  + o an icinde bulunulan ust seviye do-blogunun yerelleri (1 girinti)

	Fonksiyon govdeleri kendi sinirini tasidigi icin sayilmaz.
]]
local YEREL_SINIR = 198
local YEREL_UYARI = 185

local function adSayisi(satir: string): number
	if satir:match("^%s*local%s+function%s") then
		return 1
	end
	local adlar = satir:match("^%s*local%s+([^=]+)")
	if not adlar then
		return 0
	end
	local _, virgul = adlar:gsub(",", "")
	return virgul + 1
end

local function yerelSay(source: string): (number, number)
	local ust = 0
	local blokta = false
	local blok = 0
	local tepe, tepeSatir = 0, 0
	local no = 0

	for satir in (source .. "\n"):gmatch("([^\n]*)\n") do
		no += 1
		if satir:match("^do%s*$") or satir:match("^do%s+%-%-") then
			blokta = true
			blok = 0
		elseif blokta and satir:match("^end") then
			blokta = false
			blok = 0
		elseif satir:match("^local%s") then
			ust += adSayisi(satir)
		elseif blokta and satir:match("^\tlocal%s") then
			blok += adSayisi(satir)
		end

		if ust + blok > tepe then
			tepe = ust + blok
			tepeSatir = no
		end
	end

	return tepe, tepeSatir
end

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

			-- luau.compile 200 yerel sinirini denetlemiyor; ayrica sayilir
			local tepe, satir = yerelSay(source)
			if tepe > YEREL_SINIR then
				failures += 1
				print(`FAIL  {path}`)
				print(`      ust seviyede {tepe} yerel (satir {satir}); Luau siniri 200 -- script Studio'da HIC calismaz`)
			elseif tepe > YEREL_UYARI then
				print(`UYARI {path}: ust seviyede {tepe} yerel (sinir 200). Yeni yerelleri do-blogu ya da tabloya koy.`)
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
