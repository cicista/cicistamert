--!strict
--[[
	Place dosyasindaki onemli nesnelerin KONUMLARINI yazar.
	Kullanim: lune run tools/konum.luau <place.rbxl>

	Harita bozuldugunda "eskiden neredeydi" sorusunu tahminle degil
	olcumle cevaplamak icin. Iki dosyanin ciktisini karsilastirirsan
	neyin kaydigini gorursun.

	Bakilan yerler:
	    Workspace > Bases > Base1..N   -- base'ler ve slotlari
	    Spawn_* adli parcalar          -- ada isinlanma noktalari
	    NPC'ler ve Fuse nesneleri
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local placePath = process.args[1]
if not placePath or not fs.isFile(placePath) then
	print("HATA: place dosyasi ver")
	print("  lune run tools/konum.luau guncel.rbxl")
	process.exit(1)
end

local game = roblox.deserializePlace(fs.readFile(placePath))
local workspace = game:GetService("Workspace")

--[[
	Bir parcanin konumu.

	Position dogrudan okunmuyor: place dosyasinda konum CFrame olarak
	saklaniyor ve Lune varsayilan degeri olmayan ozelliklerde hata veriyor.
	CFrame uzerinden gidiyoruz, o da yoksa parcayi atliyoruz.
]]
local function partPosition(part: any): Vector3?
	local ok, cf = pcall(function()
		return part.CFrame
	end)
	return if ok and cf then cf.Position else nil
end

-- Konumu olan ilk parcayi bulur (Model ise icindekine bakar)
local function positionOf(node: any): Vector3?
	if node:IsA("BasePart") then
		return partPosition(node)
	end

	if node:IsA("Model") then
		local primary = node.PrimaryPart
		if primary then
			local position = partPosition(primary)
			if position then
				return position
			end
		end

		for _, child in node:GetDescendants() do
			if child:IsA("BasePart") then
				local position = partPosition(child)
				if position then
					return position
				end
			end
		end
	end

	return nil
end

local function show(label: string, node: any)
	local position = positionOf(node)
	if position then
		print(string.format("  %-24s %8.1f  %8.1f  %8.1f", label, position.X, position.Y, position.Z))
	else
		print(string.format("  %-24s (parca yok)", label))
	end
end

print(`DOSYA: {placePath}`)
print("")

------------------------------------------------------------------
-- BASE'LER
------------------------------------------------------------------
print("=== BASE'LER ===")
print(string.format("  %-24s %8s  %8s  %8s", "AD", "X", "Y", "Z"))
print(string.rep("-", 56))

local bases = workspace:FindFirstChild("Bases")
if not bases then
	print("  Workspace > Bases bulunamadi")
else
	for _, base in bases:GetChildren() do
		show(base.Name, base)

		-- Slotlar da onemli: base tasinip slotlar kalmis olabilir
		local slots = 0
		for _, node in base:GetDescendants() do
			if node.Name:match("^Slot%d+$") then
				slots += 1
			end
		end
		print(string.format("  %-24s %d slot", "", slots))
	end
end

------------------------------------------------------------------
-- ADA ISINLANMA NOKTALARI
------------------------------------------------------------------
print("")
print("=== SPAWN NOKTALARI ===")
print(string.rep("-", 56))

local found = 0
for _, node in workspace:GetDescendants() do
	if node.Name:match("^Spawn_") then
		show(node.Name, node)
		found += 1
	end
end

if found == 0 then
	print("  Spawn_ ile baslayan parca yok")
end

------------------------------------------------------------------
-- NPC VE FUSE NESNELERI
------------------------------------------------------------------
print("")
print("=== NPC / NESNELER ===")
print(string.rep("-", 56))

local WANTED = {
	"Kaptan",
	"Captain",
	"BrainrotDetective",
	"BrainrotSaticisi",
	"RotBuyer",
	"SlotMakinesi",
	"Shopkeeper",
	"Shop",
	"FuseMakinesi",
	"FuseMachine",
	"CoinBozdurucu",
	"CoinTrader",
	"FuseVFX",
}

for _, name in WANTED do
	local node = workspace:FindFirstChild(name, true)
	if node then
		show(name, node)
	end
end
