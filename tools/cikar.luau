--!strict
--[[
	Place dosyasindan NESNE CIKARIR ve .rbxm olarak kaydeder.
	Kullanim: lune run tools/cikar.luau <place.rbxl> <cikti.rbxm> <ad> [ad2 ...]

	Ornek:
	    lune run tools/cikar.luau guncel.rbxl baseler.rbxm Bases

	Cikan dosyayi Studio'da Workspace'e sag tik -> Insert from File ile
	geri koyarsin; nesneler KAYITLI KONUMLARIYLA gelir.

	NE ISE YARAR
	  Haritada bir sey yanlislikla tasindiginda ya da silindiginde, eski
	  bir place kopyasindan yalnizca o parcayi geri almak icin. Butun
	  dosyayi yayinlamak gerekmez -- digerinin calismasini ezmezsin.

	DIKKAT
	  Geri koymadan ONCE hedefteki eski kopyayi sil, yoksa ayni isimde iki
	  nesne olur ve kod hangisini bulacagini sasirir.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local placePath = process.args[1]
local outputPath = process.args[2]

if not placePath or not fs.isFile(placePath) or not outputPath then
	print("HATA: eksik arguman")
	print("  lune run tools/cikar.luau <place.rbxl> <cikti.rbxm> <ad> [ad2 ...]")
	print("")
	print("  ornek: lune run tools/cikar.luau guncel.rbxl baseler.rbxm Bases")
	process.exit(1)
end

--[[
	Adlarin arasina "offset=x,y,z" yazilabilir.

	Cikarilan her parca o kadar KAYDIRILIR. Harita tasindiginda eski bir
	kopyadan alinan nesneleri yeni yerine oturtmak icin: Studio'da alti
	modeli elle surukleyip tutturmaya calismak yerine dosya zaten dogru
	konumda gelir.
]]
-- Vector3 Lune'da global degil, roblox kutuphanesinden gelir
local Vector3 = roblox.Vector3

local names = {}
local offset = Vector3.new(0, 0, 0)
local hasOffset = false

for index = 3, #process.args do
	local arg = process.args[index]
	local x, y, z = string.match(arg, "^offset=(-?[%d%.]+),(-?[%d%.]+),(-?[%d%.]+)$")

	if x then
		offset = Vector3.new(tonumber(x) :: number, tonumber(y) :: number, tonumber(z) :: number)
		hasOffset = true
	else
		table.insert(names, arg)
	end
end

if #names == 0 then
	print("HATA: cikarilacak nesne adi verilmedi")
	process.exit(1)
end

local game = roblox.deserializePlace(fs.readFile(placePath))
local workspace = game:GetService("Workspace")

--[[
	Bir alt agacin butun parcalarini kaydirir.

	Konum CFrame uzerinden okunuyor: place dosyasinda Position ayri bir
	ozellik olarak saklanmiyor ve Lune varsayilani olmayan alanlarda hata
	veriyor.
]]
local function shift(root: any, delta: Vector3)
	local function move(part: any)
		local ok, cf = pcall(function()
			return part.CFrame
		end)
		if ok and cf then
			part.CFrame = cf + delta
		end
	end

	if root:IsA("BasePart") then
		move(root)
	end

	for _, node in root:GetDescendants() do
		if node:IsA("BasePart") then
			move(node)
		end
	end
end

local picked = {}

for _, name in names do
	-- Once Workspace'in dogrudan altinda, yoksa her yerde ara
	local node = workspace:FindFirstChild(name) or workspace:FindFirstChild(name, true)

	if node then
		--[[
			Klon aliniyor: serializeModel nesneyi agactan koparmasin.
			Kaynak dosya zaten diskte, ama bellekte bozmanin da alemi yok.
		]]
		table.insert(picked, node:Clone())

		local kids = #node:GetChildren()
		print(`  BULUNDU  {name}  ({node.ClassName}, {kids} cocuk)`)
	else
		print(`  YOK      {name}`)
	end
end

if #picked == 0 then
	print("")
	print("Hicbir nesne bulunamadi, dosya yazilmadi.")
	process.exit(1)
end

if hasOffset then
	for _, node in picked do
		shift(node, offset)
	end
	print("")
	print(string.format("  KAYDIRILDI  %.1f, %.1f, %.1f", offset.X, offset.Y, offset.Z))
end

fs.writeFile(outputPath, roblox.serializeModel(picked))

print("")
print(`TAMAM -- {#picked} nesne yazildi`)
print(`Cikti: {outputPath}`)
print("")
print("Studio'da: Workspace'e sag tik -> Insert from File -> bu dosya")
print("Once hedefteki ESKI kopyayi sil, yoksa ayni isimde iki nesne olur.")
