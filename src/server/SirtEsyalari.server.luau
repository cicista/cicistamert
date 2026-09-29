local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Ores = require(Shared:WaitForChild("Ores"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Tools = require(Modules:WaitForChild("Tools"))

local AYAR = Assets.BodyItems

local KESIF_NITELIGI = "KesifKisiti"

local FLYBOARD_NITELIGI = "Flyboarding"

local KUREK_ADI = "SirtKuregi"
local GPS_ADI = "BelGPS"
local KAZMA_ADI = "SirtKazmasi"

type Esya = {
	model: Model?,
	id: string?,
	hataliId: string?,
	parcaBoyu: Vector3?,
}

type Durum = {
	character: Model,
	kurek: Esya,
	kazma: Esya,
	gps: Esya,
	baglantilar: { RBXScriptConnection },
}

local durumlar: { [Player]: Durum } = {}

local function govdeParcasi(character: Model, adlar: { string }): BasePart?
	for _, ad in adlar do
		local parca = character:FindFirstChild(ad)
		if parca and parca:IsA("BasePart") then
			return parca
		end
	end
	return nil
end

local function toolModele(tool: Tool, ad: string): Model?
	local handle = tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		tool:Destroy()
		return nil
	end

	local model = Instance.new("Model")
	model.Name = ad
	for _, child in tool:GetChildren() do
		child.Parent = model
	end
	tool:Destroy()

	model.PrimaryPart = handle
	Assets.stripScripts(model)

	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		end
	end

	return model
end

local EFEKT_SINIFLARI = { "Light", "Highlight", "ParticleEmitter", "Beam", "Trail", "Sparkles", "Fire", "Smoke" }

local function efektleriKaldir(model: Model)
	for _, d in model:GetDescendants() do
		for _, sinif in EFEKT_SINIFLARI do
			if d:IsA(sinif) then
				d:Destroy()
				break
			end
		end
	end
end

local function govdeyeTak(model: Model, parca: BasePart, ayar: any)
	if ayar.lights == false then
		efektleriKaldir(model)
	end

	local referans = if AYAR.reference then AYAR.reference[parca.Name] else nil
	local boyOrani = Vector3.one
	if typeof(referans) == "Vector3" and referans.X > 0 and referans.Y > 0 and referans.Z > 0 then
		boyOrani = parca.Size / referans
	end

	local olcek = (ayar.scale or 1) * ((boyOrani.X + boyOrani.Y + boyOrani.Z) / 3)
	if math.abs(olcek - 1) > 1e-3 then
		pcall(function()
			model:ScaleTo(olcek)
		end)
	end

	local konum = if parca.Name == "Torso" then (ayar.positionR6 or ayar.position) else ayar.position
	konum = (konum or Vector3.zero) * boyOrani
	local r = ayar.rotation or Vector3.zero

	local weld = Instance.new("Weld")
	weld.Name = "GovdeBagi"
	weld.Part0 = parca
	weld.Part1 = model.PrimaryPart
	weld.C0 = CFrame.new(konum or Vector3.zero) * CFrame.Angles(math.rad(r.X), math.rad(r.Y), math.rad(r.Z))

	if ayar.anchor == "center" then
		local kutu = model:GetBoundingBox()
		local ofset = model.PrimaryPart.CFrame:PointToObjectSpace(kutu.Position)
		weld.C1 = CFrame.new(ofset)
	end

	if ayar.spin then
		weld.C1 = weld.C1 * CFrame.Angles(0, math.rad(ayar.spin), 0)
	end
	weld.Parent = model.PrimaryPart
end

local function esyayiSil(esya: Esya)
	if esya.model then
		esya.model:Destroy()
	end
	esya.model = nil
	esya.id = nil
end

local function kur(esya: Esya, character: Model, id: string?, parcaAdlari: { string }, kurucu: (string) -> Tool, ad: string, ayar: any)
	local parca = govdeParcasi(character, parcaAdlari)
	local boyAyni = parca == nil or esya.parcaBoyu == nil or (esya.parcaBoyu - parca.Size).Magnitude < 0.01

	if esya.id == id and (esya.model or not id) and boyAyni then
		return
	end
	if id and esya.hataliId == id then
		return
	end

	esyayiSil(esya)
	if not id then
		return
	end

	if not parca then
		return
	end

	local ok, sonuc = pcall(kurucu, id)
	local model = if ok and sonuc then toolModele(sonuc, ad) else nil

	if not model then
		esya.hataliId = id
		warn(`[SirtEsyalari] {ad} kurulamadi ({id}): {if ok then "Handle yok" else tostring(sonuc)}`)
		return
	end

	govdeyeTak(model, parca, ayar)
	esya.model = model
	esya.id = id
	esya.parcaBoyu = parca.Size
	esya.hataliId = nil
end

local function goster(esya: Esya, character: Model, gorunur: boolean)
	local model = esya.model
	if not model then
		return
	end
	local hedef = if gorunur then character else nil
	if model.Parent ~= hedef then
		model.Parent = hedef
	end
end

local function enIyiKazma(data: any): string?
	local sahip = data.pickaxes
	if type(sahip) ~= "table" then
		return nil
	end
	for i = #Ores.IslandOrder, 1, -1 do
		local ada = Ores.Islands[Ores.IslandOrder[i]]
		local id = ada and ada.pickaxe
		if id and sahip[id] == true then
			return id
		end
	end
	return nil
end

local function eldeMi(character: Model, nitelik: string): boolean
	for _, child in character:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute(nitelik) ~= nil then
			return true
		end
	end
	return false
end

local function temizle(player: Player)
	local durum = durumlar[player]
	if not durum then
		return
	end
	for _, baglanti in durum.baglantilar do
		baglanti:Disconnect()
	end
	esyayiSil(durum.kurek)
	esyayiSil(durum.kazma)
	esyayiSil(durum.gps)
	durumlar[player] = nil
end

local guncelle: (player: Player) -> ()

local function durumAl(player: Player, character: Model): Durum
	local durum = durumlar[player]
	if durum and durum.character == character then
		return durum
	end

	temizle(player)

	if not AYAR.reference then
		task.delay(3, function()
			if not character.Parent then
				return
			end
			print(`[SirtEsyalari] {player.Name} govde boylari -- Assets.BodyItems.reference icin:`)
			print("	reference = {")
			for _, ad in { "UpperTorso", "LowerTorso", "Torso" } do
				local p = character:FindFirstChild(ad)
				if p and p:IsA("BasePart") then
					print(string.format("		%s = Vector3.new(%.3f, %.3f, %.3f),", ad, p.Size.X, p.Size.Y, p.Size.Z))
				end
			end
			print("	},")
		end)
	end

	local yeni: Durum = {
		character = character,
		kurek = {},
		kazma = {},
		gps = {},
		baglantilar = {},
	}
	durumlar[player] = yeni

	local function tetikle()
		task.defer(guncelle, player)
	end
	table.insert(yeni.baglantilar, character.ChildAdded:Connect(tetikle))
	table.insert(yeni.baglantilar, character.ChildRemoved:Connect(tetikle))
	table.insert(yeni.baglantilar, player:GetAttributeChangedSignal(KESIF_NITELIGI):Connect(tetikle))
	table.insert(yeni.baglantilar, player:GetAttributeChangedSignal(FLYBOARD_NITELIGI):Connect(tetikle))

	return yeni
end

function guncelle(player: Player)
	local character = player.Character
	local data = PlayerData.get(player)
	if not character or not data or not character.Parent then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local durum = durumAl(player, character)

	local denizde = player:GetAttribute(FLYBOARD_NITELIGI) == true

	kur(durum.kurek, character, data.shovel, { "UpperTorso", "Torso" }, Tools.buildShovel, KUREK_ADI, AYAR.shovel)
	goster(durum.kurek, character, not denizde and not eldeMi(character, "ShovelId"))

	kur(durum.kazma, character, enIyiKazma(data), { "UpperTorso", "Torso" }, Tools.buildPickaxe, KAZMA_ADI, AYAR.pickaxe)
	goster(durum.kazma, character, not denizde and not eldeMi(character, "PickaxeId"))

	kur(durum.gps, character, data.detector, { "LowerTorso", "Torso" }, Tools.buildGPS, GPS_ADI, AYAR.gps)
	local kesifte = player:GetAttribute(KESIF_NITELIGI) == true
	goster(durum.gps, character, not denizde and not kesifte and not eldeMi(character, "DetectorId"))
end

task.spawn(function()
	while true do
		task.wait(0.5)
		for _, player in Players:GetPlayers() do
			local ok, hata = pcall(guncelle, player)
			if not ok then
				warn(`[SirtEsyalari] {player.Name}: {tostring(hata)}`)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(temizle)
