--[[
	SirtEsyalari  (Script)
	Yeri: ServerScriptService > SirtEsyalari

	Oyuncunun SAHIP OLDUGU esyalar govdesinde gorunur -- diger oyunculara
	hangi kurekle gezdigini gostermek icin:

	    SIRTTA KUREK  -- kusandigi kurek, 45 derece capraz
	    BELDE GPS     -- kusandigi dedektor, 20 derece egik, 0.8 boyunda

	NE ZAMAN GIZLENIR
	    kurek -- ELDEYKEN (kazi sirasinda kurek ele gelir)
	    GPS   -- ELDEYKEN ya da oyuncu KESIFTEYKEN (kumun ustunde arama,
	             kazi, denizde olta). Yani kumdan cikinca bele geri doner.

	Modeller elde tutulan esyanin AYNISI (Tools.buildShovel / buildGPS);
	kurek yukseltilince ya da dedektor degisince govdedeki de yenilenir.

	Konum, aci ve boyut: Shared > Assets > BodyItems
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))
local Tools = require(Modules:WaitForChild("Tools"))

local AYAR = Assets.BodyItems

-- KaziSistemi'nin "su an kesifte" niteligi (kumda GPS, kazi, denizde olta)
local KESIF_NITELIGI = "KesifKisiti"

local KUREK_ADI = "SirtKuregi"
local GPS_ADI = "BelGPS"

type Esya = {
	model: Model?,
	-- Modelin kuruldugu esya kimligi; degisince yeniden kurulur
	id: string?,
	-- Kurulamayan kimlik: her turda tekrar denenip Output'u doldurmasin
	hataliId: string?,
}

type Durum = {
	character: Model,
	kurek: Esya,
	gps: Esya,
	baglantilar: { RBXScriptConnection },
}

local durumlar: { [Player]: Durum } = {}

------------------------------------------------------------------
-- MODEL
------------------------------------------------------------------
local function govdeParcasi(character: Model, adlar: { string }): BasePart?
	for _, ad in adlar do
		local parca = character:FindFirstChild(ad)
		if parca and parca:IsA("BasePart") then
			return parca
		end
	end
	return nil
end

--[[
	Elde tutulan Tool'u govdeye takilacak bir Model'e cevirir. Tool olarak
	kalsaydi Roblox onu ele almaya calisir, cantaya da girerdi.
	Handle (tutus noktasi) modelin ana parcasi olur.
]]
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

-- Modeli govde parcasina kaynaklar (ayar: Assets.BodyItems.shovel / gps)
local function govdeyeTak(model: Model, parca: BasePart, ayar: any)
	local olcek = ayar.scale or 1
	if olcek ~= 1 then
		pcall(function()
			model:ScaleTo(olcek)
		end)
	end

	-- R6'da tek govde parcasi var (Torso); konum ona gore ayri
	local konum = if parca.Name == "Torso" then (ayar.positionR6 or ayar.position) else ayar.position
	local r = ayar.rotation or Vector3.zero

	local weld = Instance.new("Weld")
	weld.Name = "GovdeBagi"
	weld.Part0 = parca
	weld.Part1 = model.PrimaryPart
	weld.C0 = CFrame.new(konum or Vector3.zero) * CFrame.Angles(math.rad(r.X), math.rad(r.Y), math.rad(r.Z))
	weld.Parent = model.PrimaryPart
end

local function esyayiSil(esya: Esya)
	if esya.model then
		esya.model:Destroy()
	end
	esya.model = nil
	esya.id = nil
end

--[[
	Esyanin modeli istenen kimlikle kurulu mu; degilse yeniden kurar.
	Parca (govde) henuz yoksa bir sonraki turda tekrar denenir.
]]
local function kur(esya: Esya, character: Model, id: string?, parcaAdlari: { string }, kurucu: (string) -> Tool, ad: string, ayar: any)
	if esya.id == id and (esya.model or not id) then
		return
	end
	if id and esya.hataliId == id then
		return
	end

	esyayiSil(esya)
	if not id then
		return
	end

	local parca = govdeParcasi(character, parcaAdlari)
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
	esya.hataliId = nil
end

-- Gorunmesi gerekiyorsa karaktere, gerekmiyorsa hicbir yere (model saklanir)
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

------------------------------------------------------------------
-- DURUM
------------------------------------------------------------------
-- Elde bu nitelige sahip bir Tool var mi (ShovelId / DetectorId)
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

	local yeni: Durum = {
		character = character,
		kurek = {},
		gps = {},
		baglantilar = {},
	}
	durumlar[player] = yeni

	-- Esya ele alinip birakilinca beklemeden tepki ver
	local function tetikle()
		task.defer(guncelle, player)
	end
	table.insert(yeni.baglantilar, character.ChildAdded:Connect(tetikle))
	table.insert(yeni.baglantilar, character.ChildRemoved:Connect(tetikle))
	table.insert(yeni.baglantilar, player:GetAttributeChangedSignal(KESIF_NITELIGI):Connect(tetikle))

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

	-- SIRTTA KUREK: elde degilse gorunur
	kur(durum.kurek, character, data.shovel, { "UpperTorso", "Torso" }, Tools.buildShovel, KUREK_ADI, AYAR.shovel)
	goster(durum.kurek, character, not eldeMi(character, "ShovelId"))

	-- BELDE GPS: elde degilse VE kesifte degilse gorunur
	kur(durum.gps, character, data.detector, { "LowerTorso", "Torso" }, Tools.buildGPS, GPS_ADI, AYAR.gps)
	local kesifte = player:GetAttribute(KESIF_NITELIGI) == true
	goster(durum.gps, character, not kesifte and not eldeMi(character, "DetectorId"))
end

------------------------------------------------------------------
-- DONGU
--
-- Anlik tepkiler karakter/nitelik sinyallerinden geliyor; bu dongu
-- yalnizca kurek yukseltme ve dedektor degisimi gibi veri degisikliklerini
-- yakalar.
------------------------------------------------------------------
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
