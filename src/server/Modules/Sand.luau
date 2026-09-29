--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OyunConfig"))

local Sand = {}

local S = Config.Sand

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

function Sand.isSandMaterial(material: Enum.Material?): boolean
	return material ~= nil and S.materials[material] == true
end

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
	part: BasePart?,
	material: Enum.Material,
	luck: number,
}

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

function Sand.isOnSand(player: Player, ignore: { Instance }?): boolean
	if Sand.isSandMaterial(Sand.floorMaterial(player)) then
		return true
	end

	local ground = Sand.underPlayer(player, ignore)
	return ground ~= nil and ground.isSand
end

function Sand.luckUnder(player: Player): number
	local ground = Sand.underPlayer(player)
	if not ground or not ground.isSand then
		return 1
	end
	return ground.luck
end

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

		local p = ground.part
		if p then
			table.insert(
				lines,
				string.format(
					"  Boyu / konumu                  : (%.0f, %.1f, %.0f)  @ (%.0f, %.1f, %.0f)",
					p.Size.X, p.Size.Y, p.Size.Z, p.Position.X, p.Position.Y, p.Position.Z
				)
			)
			table.insert(
				lines,
				string.format(
					"  Saydamlik / CanCollide / sinif : %.2f / %s / %s",
					p.Transparency, tostring(p.CanCollide), p.ClassName
				)
			)
		end
		table.insert(
			lines,
			`  Addan kum sayildi mi           : {ground.part ~= nil and Sand.isSandName(ground.part.Name)}`
		)
		table.insert(lines, `  Zemin sans carpani             : x{ground.luck}`)
	else
		table.insert(lines, `  Isin hicbir zemine carpmadi ({S.rayDepth} stud asagi bakildi)`)
	end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }

		local bulunan = 0
		table.insert(lines, "")
		table.insert(lines, "  Yakindaki kum parcalari (80 stud):")

		for _, part in Workspace:GetPartBoundsInRadius(root.Position, 80, params) do
			if Sand.isSandMaterial(part.Material) or Sand.isSandName(part.Name) then
				bulunan += 1
				if bulunan <= 12 then
					local isaret = if part.Transparency >= 0.9 then "   <-- GORUNMEZ" else ""
					table.insert(
						lines,
						string.format(
							"    %s  boy=(%.0f, %.1f, %.0f)  saydam=%.2f%s",
							part:GetFullName(), part.Size.X, part.Size.Y, part.Size.Z, part.Transparency, isaret
						)
					)
				end
			end
		end

		if bulunan == 0 then
			table.insert(lines, "    (yok)")
		elseif bulunan > 12 then
			table.insert(lines, `    ... ve {bulunan - 12} parca daha`)
		end
	end

	table.insert(lines, "")
	table.insert(lines, `  SONUC -- kumda mi              : {onSand}`)

	return onSand, lines
end

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

function Sand.randomSpot(rng: Random, attempts: number?): Vector3?
	local parts, weights, total = sandParts(nil)
	return spotFrom(parts, weights, total, rng, attempts)
end

function Sand.randomSpotNamed(names: { string }, rng: Random, attempts: number?): Vector3?
	local parts, weights, total = sandParts(names)
	return spotFrom(parts, weights, total, rng, attempts)
end

return Sand
