--!strict
--[[
	Kum algilama.
	GPS yalnizca kum uzerindeyken calisir ve isik suzmeleri sadece kumda dogar.

	IKI OLCUT VAR, sirasiyla:

	  1. ZEMIN MALZEMESI  (birincil)
	     Humanoid.FloorMaterial -- Roblox'un fizik motorunun hesapladigi
	     "su an neyin ustunde duruyorum" degeri. Hem Terrain hem normal
	     Part icin dogru sonuc verir, isin gondermeye gerek kalmaz ve
	     oyuncu egimde, parcanin kenarinda ya da yuruyusun ortasinda olsa
	     da tutar. Kabul edilen malzemeler: Config.Sand.materials.

	  2. PARCA ADI  (yedek)
	     Malzemesi kum OLMAYAN ama adinda "kum"/"sand" gecen ozel zeminler
	     icin (SekerKum, GizliKum...). Bunlar icin asagi isin gonderilir.

	Ikisinden biri tutuyorsa oyuncu kumdadir.

	"GPS neden acilmiyor?" sorusu icin Sand.report -- admin panelindeki
	"Kum raporu" butonu onu Output'a yazdirir.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OyunConfig"))

local Sand = {}

local S = Config.Sand

--[[
	Zemine ozel sans carpani.
	Parca adi Config.Sand.luckByName icinde aranir (kucuk harf, tam eslesme).
	Ornek: "VolkanKum" adli zemin -> x3
]]
function Sand.luckOf(name: string): number
	return S.luckByName[string.lower(name)] or 1
end

function Sand.isSandName(name: string): boolean
	local lower = string.lower(name)
	for _, keyword in S.nameKeywords do
		if string.find(lower, keyword, 1, true) then
			return true
		end
	end
	return false
end

-- Bu malzeme kum sayiliyor mu (Config.Sand.materials)
function Sand.isSandMaterial(material: Enum.Material?): boolean
	return material ~= nil and S.materials[material] == true
end

--[[
	OYUNCUNUN BASTIGI ZEMININ MALZEMESI

	Havadayken Roblox Air dondurur; biz nil veriyoruz ki cagiran taraf
	"zemin yok" ile "zemin var ama kum degil" arasindaki farki gorebilsin.
]]
function Sand.floorMaterial(player: Player): Enum.Material?
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	local material = humanoid.FloorMaterial
	if material == Enum.Material.Air then
		return nil
	end

	return material
end

export type GroundInfo = {
	position: Vector3,
	normal: Vector3,
	isSand: boolean,
	-- Uzerinde durulan parca ve o zemine ozel sans carpani
	part: BasePart?,
	-- Isinin carptigi yuzeyin malzemesi (kum kontrolu ve teshis icin)
	material: Enum.Material,
	luck: number,
}

-- Verilen konumdan asagi isin gonderip zemini inceler.
function Sand.probe(origin: Vector3, ignore: { Instance }?): GroundInfo?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore or {}

	local result = Workspace:Raycast(origin, Vector3.new(0, -S.rayDepth, 0), params)
	if not result then
		return nil
	end

	local sand = false
	if Sand.isSandMaterial(result.Material) then
		sand = true
	elseif result.Instance and result.Instance:IsA("BasePart") and Sand.isSandName(result.Instance.Name) then
		sand = true
	end

	local part = if result.Instance and result.Instance:IsA("BasePart") then result.Instance else nil

	return {
		position = result.Position,
		normal = result.Normal,
		isSand = sand,
		part = part,
		material = result.Material,
		luck = if part then Sand.luckOf(part.Name) else 1,
	}
end

-- Oyuncunun ayaginin altindaki zemin
function Sand.underPlayer(player: Player, ignore: { Instance }?): GroundInfo?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end

	local filter = { char :: Instance }
	if ignore then
		for _, item in ignore do
			table.insert(filter, item)
		end
	end

	return Sand.probe(root.Position, filter)
end

--[[
	Oyuncu kumun uzerinde mi?

	Once zemin MALZEMESI: Terrain de olsa normal Part da olsa, ustunde
	durulan seyin malzemesi Sand ise cevap dogrudan evettir. Isin
	gonderilmez -- FloorMaterial zaten fizik motorunun bildigi deger.

	Malzeme kum degilse, adinda "kum"/"sand" gecen ozel zeminler icin
	asagi bir isin gonderilir.
]]
function Sand.isOnSand(player: Player, ignore: { Instance }?): boolean
	if Sand.isSandMaterial(Sand.floorMaterial(player)) then
		return true
	end

	local ground = Sand.underPlayer(player, ignore)
	return ground ~= nil and ground.isSand
end

--[[
	Oyuncunun UZERINDE DURDUGU zeminin sans carpani.
	Kum degilse ya da ozel bir zemin degilse 1 doner.
]]
function Sand.luckUnder(player: Player): number
	local ground = Sand.underPlayer(player)
	if not ground or not ground.isSand then
		return 1
	end
	return ground.luck
end

--[[
	TESHIS

	"GPS neden acilmiyor?" sorusunu tahminle degil olcumle cevaplar:
	oyuncunun bastigi zeminin malzemesi ne, isin neye carpti, hangi
	olcutten kum sayildi ya da sayilmadi.

	Donen: kumda mi (bool) ve Output'a yazilacak satirlar.
]]
function Sand.report(player: Player): (boolean, { string })
	local lines: { string } = {}

	local material = Sand.floorMaterial(player)
	local ground = Sand.underPlayer(player)
	local onSand = Sand.isOnSand(player)

	local accepted: { string } = {}
	for item in S.materials do
		table.insert(accepted, item.Name)
	end

	table.insert(lines, `  Bastigin zemin (FloorMaterial) : {if material then material.Name else "YOK -- havadasin"}`)
	table.insert(lines, `  Kabul edilen malzemeler        : {table.concat(accepted, ", ")}`)
	table.insert(lines, `  Malzemeden kum sayildi mi      : {Sand.isSandMaterial(material)}`)
	table.insert(lines, "")

	if ground then
		table.insert(
			lines,
			`  Isinin buldugu parca           : {if ground.part then ground.part:GetFullName() else "Terrain"}`
		)
		table.insert(lines, `  O parcanin malzemesi           : {ground.material.Name}`)
		table.insert(
			lines,
			`  Addan kum sayildi mi           : {ground.part ~= nil and Sand.isSandName(ground.part.Name)}`
		)
		table.insert(lines, `  Zemin sans carpani             : x{ground.luck}`)
	else
		table.insert(lines, `  Isin hicbir zemine carpmadi ({S.rayDepth} stud asagi bakildi)`)
	end

	table.insert(lines, "")
	table.insert(lines, `  SONUC -- kumda mi              : {onSand}`)

	return onSand, lines
end

--[[
	HARITADA RASTGELE BIR KUM NOKTASI

	Lucky Block etkinligi bunu kullaniyor: bloklar oyunculardan bagimsiz
	olarak kumlarin uzerinde beliriyor.

	Kum sayilan parcalar toplanir ve YUZ ALANINA GORE agirlikli secilir --
	yoksa 5x5'lik kucuk bir kum parcasi kocaman bir plajla ayni sansa sahip
	olurdu. Secilen parcanin ustunde rastgele bir noktadan asagi isin
	gonderilip gercekten kum mu diye dogrulanir.

	Bulamazsa nil doner (harita kumsuzsa).
]]
--[[
	Kum sayilan parcalari toplar. Ad suzgeci verilirse yalnizca ADI TAM
	TUTAN parcalar alinir (kucuk/buyuk harf onemsiz) -- Lucky Block etkinligi
	her adanin kendi kumunu boyle buluyor.
]]
local function sandParts(names: { string }?): ({ BasePart }, { number }, number)
	local istenen: { [string]: boolean }? = nil
	if names then
		istenen = {}
		for _, name in names do
			(istenen :: { [string]: boolean })[string.lower(name)] = true
		end
	end

	local parts: { BasePart } = {}
	local weights: { number } = {}
	local total = 0

	for _, node in Workspace:GetDescendants() do
		if node:IsA("BasePart") then
			local kum = if istenen
				then istenen[string.lower(node.Name)] == true
				else Sand.isSandMaterial(node.Material) or Sand.isSandName(node.Name)

			if kum then
				local area = node.Size.X * node.Size.Z
				table.insert(parts, node)
				table.insert(weights, area)
				total += area
			end
		end
	end

	return parts, weights, total
end

--[[
	Verilen parca listesinden rastgele bir UST YUZ noktasi.
	Secim YUZ ALANINA GORE agirlikli: yoksa 5x5'lik kucuk bir kum parcasi
	kocaman bir plajla ayni sansa sahip olurdu.
]]
local function spotFrom(
	parts: { BasePart },
	weights: { number },
	total: number,
	rng: Random,
	attempts: number?
): Vector3?
	if #parts == 0 or total <= 0 then
		return nil
	end

	for _ = 1, attempts or 12 do
		local roll = rng:NextNumber() * total
		local cursor = 0
		local chosen = parts[1]
		for index, part in parts do
			cursor += weights[index]
			if roll <= cursor then
				chosen = part
				break
			end
		end

		-- Parcanin UST yuzunde rastgele bir nokta (parca donmus olsa da dogru)
		local half = chosen.Size / 2
		local point = chosen.CFrame * Vector3.new(
			rng:NextNumber(-half.X, half.X),
			half.Y,
			rng:NextNumber(-half.Z, half.Z)
		)

		local ground = Sand.probe(point + Vector3.new(0, 6, 0))
		if ground and ground.isSand then
			return ground.position
		end
	end

	return nil
end

--[[
	HARITADA RASTGELE BIR KUM NOKTASI

	Kum sayilan butun parcalar aday: hem malzemesi kum olanlar hem adinda
	"kum"/"sand" gecenler. Bulamazsa nil doner (harita kumsuzsa).
]]
function Sand.randomSpot(rng: Random, attempts: number?): Vector3?
	local parts, weights, total = sandParts(nil)
	return spotFrom(parts, weights, total, rng, attempts)
end

--[[
	BELIRLI ADLI KUMDA rastgele bir nokta.

	Lucky Block yagmuru her adaya bir blok birakiyor; ada ile kum adi
	eslesmesi Shared > LuckyBlock > Event.islandSands icinde.
	O adda parca yoksa nil doner ve o ada atlanir.
]]
function Sand.randomSpotNamed(names: { string }, rng: Random, attempts: number?): Vector3?
	local parts, weights, total = sandParts(names)
	return spotFrom(parts, weights, total, rng, attempts)
end

return Sand
