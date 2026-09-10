--!strict
--[[
	Slot makinesinden cikan tool skinleri.

	Skinler tool turune gore ayrilir ("Shovel" / "GPS") ama slot makinesi
	cekilisinde HEPSI tek havuzda yarisir -- yani kurege de gps'e de skin cikabilir.
	Cikan skin hangi toola aitse orada gorunur.

	Bir skin sadece gorseldir; oyun dengesine etkisi yoktur.
]]

export type SkinTool = "Shovel" | "GPS"

export type SkinInfo = {
	id: string,
	displayName: string,
	tool: SkinTool,
	rarity: string,
	-- Cekilis agirligi (buyuk sayi = daha sik cikar)
	weight: number,
	color: Color3,
	material: Enum.Material,
	-- Metalik/parlak skinler icin
	reflectance: number?,
	-- Skinin uzerine binen isik rengi (nil = isik yok)
	glowColor: Color3?,
}

local Skins = {}

Skins.List = {
	-- Common
	{ id = "shovel_rust", displayName = "Rusted", tool = "Shovel", rarity = "Common", weight = 100,
		color = Color3.fromRGB(122, 84, 58), material = Enum.Material.CorrodedMetal },
	{ id = "gps_army", displayName = "Army Green", tool = "GPS", rarity = "Common", weight = 100,
		color = Color3.fromRGB(86, 102, 62), material = Enum.Material.SmoothPlastic },
	{ id = "shovel_beach", displayName = "Beach Day", tool = "Shovel", rarity = "Common", weight = 90,
		color = Color3.fromRGB(240, 214, 160), material = Enum.Material.SmoothPlastic },
	{ id = "gps_carbon", displayName = "Carbon", tool = "GPS", rarity = "Common", weight = 90,
		color = Color3.fromRGB(42, 44, 48), material = Enum.Material.Metal, reflectance = 0.1 },

	-- Rare
	{ id = "shovel_ocean", displayName = "Ocean Drift", tool = "Shovel", rarity = "Rare", weight = 40,
		color = Color3.fromRGB(58, 148, 196), material = Enum.Material.Glass, reflectance = 0.25 },
	{ id = "gps_neon", displayName = "Neon Pulse", tool = "GPS", rarity = "Rare", weight = 40,
		color = Color3.fromRGB(64, 224, 208), material = Enum.Material.Neon,
		glowColor = Color3.fromRGB(64, 224, 208) },
	{ id = "shovel_crimson", displayName = "Crimson", tool = "Shovel", rarity = "Rare", weight = 35,
		color = Color3.fromRGB(178, 44, 52), material = Enum.Material.Metal, reflectance = 0.2 },

	-- Epic
	{ id = "shovel_obsidian", displayName = "Obsidian", tool = "Shovel", rarity = "Epic", weight = 14,
		color = Color3.fromRGB(24, 22, 32), material = Enum.Material.Glass, reflectance = 0.5 },
	{ id = "gps_hologram", displayName = "Hologram", tool = "GPS", rarity = "Epic", weight = 14,
		color = Color3.fromRGB(150, 210, 255), material = Enum.Material.ForceField,
		glowColor = Color3.fromRGB(120, 190, 255) },
	{ id = "shovel_venom", displayName = "Venom", tool = "Shovel", rarity = "Epic", weight = 12,
		color = Color3.fromRGB(126, 224, 72), material = Enum.Material.Neon,
		glowColor = Color3.fromRGB(126, 224, 72) },

	-- Legendary
	{ id = "shovel_gold", displayName = "Solid Gold", tool = "Shovel", rarity = "Legendary", weight = 4,
		color = Color3.fromRGB(255, 200, 62), material = Enum.Material.Metal, reflectance = 0.6 },
	{ id = "gps_prism", displayName = "Prism", tool = "GPS", rarity = "Legendary", weight = 4,
		color = Color3.fromRGB(232, 160, 255), material = Enum.Material.Glass, reflectance = 0.7,
		glowColor = Color3.fromRGB(232, 160, 255) },

	-- Mythic
	{ id = "shovel_void", displayName = "Void Rift", tool = "Shovel", rarity = "Mythic", weight = 1,
		color = Color3.fromRGB(88, 32, 168), material = Enum.Material.Neon,
		glowColor = Color3.fromRGB(148, 72, 255) },
	{ id = "gps_singularity", displayName = "Singularity", tool = "GPS", rarity = "Mythic", weight = 1,
		color = Color3.fromRGB(18, 18, 26), material = Enum.Material.Neon,
		glowColor = Color3.fromRGB(255, 70, 90) },

	-- Secret
	{ id = "shovel_rotgod", displayName = "Rot God", tool = "Shovel", rarity = "Secret", weight = 0.2,
		color = Color3.fromRGB(40, 255, 190), material = Enum.Material.Neon,
		glowColor = Color3.fromRGB(40, 255, 190) },
} :: { SkinInfo }

local byId: { [string]: SkinInfo } = {}
local totalWeight = 0

for _, skin in Skins.List do
	byId[skin.id] = skin
	totalWeight += skin.weight
end

Skins.ById = byId

-- Slot makinesi bir cevirim icin kac Rot Coin ister
Skins.SpinCost = 1

--[[
	RULET  --  IKI ASAMA  (Lucky Block carkiyla ayni mantik)

	1. ASAMA (kademe):  bolmelerde yalnizca "?" ve kademe rengi vardir.
	   Rulet durunca hangi KADEMENIN ciktigi belli olur, hangi skin oldugu degil.

	2. ASAMA (skin): serit yeniden kurulur; bu kez SADECE o kademeden
	   cikabilecek skinler doner ve odul aciga cikar.

	Sureler burada; sunucu odulu bu surenin sonunda veriyor, istemci de ayni
	degerlerle ciziyor.
]]
Skins.Wheel = {
	-- 1. asama: kademe ruleti
	cellCount = 40,
	winnerIndex = 32,
	spinTime = 2.6,

	-- Iki rulet arasindaki bekleme
	pause = 0.7,

	-- 2. asama: o kademedeki skinlerin ruleti
	revealCellCount = 28,
	revealWinnerIndex = 22,
	revealSpinTime = 2.2,

	-- Rulet durduktan sonra odulun verilmesi icin beklenen ek sure
	settle = 0.4,
}

function Skins.totalSpinTime(): number
	local W = Skins.Wheel
	return W.spinTime + W.pause + W.revealSpinTime + W.settle
end

function Skins.get(id: string): SkinInfo?
	return byId[id]
end

-- Slot makinesi cekilisi: butun skinler tek havuzda, tool ayrimi yok.
function Skins.roll(rng: Random): SkinInfo
	local roll = rng:NextNumber() * totalWeight
	local cursor = 0
	for _, skin in Skins.List do
		cursor += skin.weight
		if roll <= cursor then
			return skin
		end
	end
	return Skins.List[1]
end

-- Bir toola ait skinleri dondurur (envanter ekraninda gruplama icin).
function Skins.forTool(tool: SkinTool): { SkinInfo }
	local out = {}
	for _, skin in Skins.List do
		if skin.tool == tool then
			table.insert(out, skin)
		end
	end
	return out
end

--[[
	Bir kademedeki butun skinler.
	Ruletin 2. asamasi bunu kullanir: kademe belli olduktan sonra yalnizca
	o kademeden cikabilecekler doner.
]]
function Skins.byRarity(rarity: string): { SkinInfo }
	local out = {}
	for _, skin in Skins.List do
		if skin.rarity == rarity then
			table.insert(out, skin)
		end
	end
	return out
end

--[[
	Bir skini tool'un parcalarina uygular.
	tool: Tool instance
	skinId: uygulanacak skin (nil ise varsayilan gorunum korunur)
]]
function Skins.apply(tool: Tool, skinId: string?)
	if not skinId then
		return
	end

	local skin = byId[skinId]
	if not skin then
		return
	end

	for _, part in tool:GetDescendants() do
		if part:IsA("BasePart") then
			part.Color = skin.color
			part.Material = skin.material
			part.Reflectance = skin.reflectance or 0
		end
	end

	-- Parlamaya DOKUNULMAZ. Seviye parlamasi (Shared > LevelGlow) skinden
	-- bagimsizdir; skin degisse de Lv rengi ayni kalir.
end

--[[
	Z tusu skin dongusu.

	Bir tool icin gecilebilecek gorunumlerin sirasi:
	    1. varsayilan gorunum  (DEFAULT)
	    2. sahip olunan skinler, katalog sirasiyla

	Lua tablosunda nil saklanamadigi icin varsayilan gorunum DEFAULT
	sabitiyle temsil edilir; disariya nil olarak cikar.
]]
Skins.DEFAULT = "__default__"

function Skins.ownedCycle(tool: SkinTool, owned: { [string]: boolean }): { string }
	local cycle = { Skins.DEFAULT }

	for _, skin in Skins.List do
		if skin.tool == tool and owned[skin.id] then
			table.insert(cycle, skin.id)
		end
	end

	return cycle
end

--[[
	Siradaki gorunumu verir; sondaysa basa (varsayilana) doner.
	current / donen deger: skin id ya da nil (varsayilan gorunum)
]]
function Skins.nextInCycle(tool: SkinTool, owned: { [string]: boolean }, current: string?): string?
	local cycle = Skins.ownedCycle(tool, owned)

	local position = 1
	local key = current or Skins.DEFAULT
	for index, id in cycle do
		if id == key then
			position = index
			break
		end
	end

	local nextId = cycle[position % #cycle + 1]
	return if nextId == Skins.DEFAULT then nil else nextId
end

return Skins
