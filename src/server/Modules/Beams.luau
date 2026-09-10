--!strict
--[[
	Isik suzmeleri.

	Kum uzerinde gezen her oyuncunun etrafinda periyodik olarak isik suzmeleri
	dogar. Suzmenin RENGI icinden cikacak brainrot'un rarity'sini ele verir --
	oyuncu kazip kazmayacagina buna bakarak karar verir.

	Kum artik dogrudan kazilmaz; SADECE suzmeler kazilir.

	Bir suzme tek bir oyuncuya aittir (baskasi kazamaz), boylece 6 kisilik
	sunucuda oyuncular birbirinin suzmesini calamaz.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Config = require(Shared:WaitForChild("OyunConfig"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Divine = require(Shared:WaitForChild("Divine"))

local Sand = require(script.Parent:WaitForChild("Sand"))

local Beams = {}

local G = Config.GPS
local V = Config.BeamVFX

export type Beam = {
	id: string,
	owner: Player,
	kind: string,        -- RarityId, "RotCoin" ya da "LuckyBlock"
	position: Vector3,
	model: Model,
	bornAt: number,
	claimed: boolean,    -- kazi basladiysa tekrar kazilamaz
}

local active: { [string]: Beam } = {}
local beamCounter = 0

local folder = Workspace:FindFirstChild("IsikSuzmeleri")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "IsikSuzmeleri"
	folder.Parent = Workspace
end

------------------------------------------------------------------
-- GORSEL
------------------------------------------------------------------
-- YEDEK GORUNUM: VFX yoksa kullanilan basit isik sutunu
local function buildFallbackModel(kind: string, position: Vector3): Model
	--[[
		Ozel suzme turlerinin (Rot Coin, Lucky Block) kendi iki renkli gecisi
		var; kademe suzmeleri tek renk.
	]]
	local special = if kind == "RotCoin"
		then Rarity.RotCoin
		elseif kind == "LuckyBlock" then Rarity.LuckyBlock
		else nil

	local colorA = if special then special.colorA else Rarity.color(kind)
	local colorB = if special then special.colorB else colorA

	local model = Instance.new("Model")
	model.Name = `Suzme_{kind}`

	-- Yerden yukselen isik sutunu
	local column = Instance.new("Part")
	column.Name = "Column"
	column.Size = Vector3.new(2.6, 26, 2.6)
	column.CFrame = CFrame.new(position + Vector3.new(0, 13, 0))
	column.Anchored = true
	column.CanCollide = false
	column.CanQuery = false
	column.CanTouch = false
	column.CastShadow = false
	column.Material = Enum.Material.Neon
	column.Color = colorA
	column.Transparency = 0.55
	column.Parent = model
	model.PrimaryPart = column

	-- Ozel suzmeler (Rot Coin, Lucky Block) iki renk arasinda gidip gelir;
	-- kademe suzmeleri sabit renk kalir
	if special then
		task.spawn(function()
			local toBlack = TweenService:Create(column, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Color = colorB })
			local toGold = TweenService:Create(column, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Color = colorA })
			while column.Parent do
				toBlack:Play()
				toBlack.Completed:Wait()
				if not column.Parent then break end
				toGold:Play()
				toGold.Completed:Wait()
			end
		end)
	end

	-- Zemindeki halka
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 6, 6)
	ring.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = colorA
	ring.Transparency = 0.3
	ring.Parent = model

	-- Yukari yukselen parcaciklar
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, -12, 0)
	attachment.Parent = column

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorA),
		ColorSequenceKeypoint.new(1, colorB),
	})
	particles.Lifetime = NumberRange.new(1.2, 2)
	particles.Rate = 22
	particles.Speed = NumberRange.new(6, 10)
	particles.SpreadAngle = Vector2.new(8, 8)
	particles.Size = NumberSequence.new(0.8)
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.LightEmission = 1
	particles.Parent = attachment

	local light = Instance.new("PointLight")
	light.Color = colorA
	light.Range = 22
	light.Brightness = 3
	light.Parent = column

	--[[
		Divine suzmesi tek renk degil: sari ile beyaz arasinda parildar.
		Sunucu yalnizca etiketler, rengi her oyuncunun makinesi cizer
		(bkz. StarterPlayerScripts > IlahiRenk).
	]]
	if kind == "Secret" then
		Divine.tag(column)
		Divine.tag(ring)
		Divine.tag(light)
		Divine.tag(particles)
	end

	return model
end

--[[
	Bir hazirlik adimini GUVENLE calistirir.

	Adimlarin her biri (renklendirme, olcekleme, yerlestirme...) paketin
	icerigine bagli ve hepsi hata verebiliyor. Eskiden tek bir adim
	patlayinca butun VFX cope gidiyor ve suzme eski basit sutuna dusuyordu
	-- ekranda "VFX hic yok" gibi gorunuyordu.

	Artik her adim kendi icinde korunuyor: biri patlarsa YALNIZCA o adim
	atlanir, efektin geri kalani calismaya devam eder. Hangi adimin
	patladigi Output icine bir kez yazilir, boylece sebep gorunur kalir.
]]
local function step(label: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then
		Assets.warnOnce(
			`suzme adimi: {label}`,
			`[Suzme] "{label}" adimi hata verdi, atlandi -- {tostring(err)}`
		)
	end
end

--[[
	VFX'ten suzme kurar.

	Sablon bir Part de olabilir bir Model de; ikisi de tek bir Model'in
	icine sarilip dondurulur, boylece cagiran taraf ne geldigini bilmek
	zorunda kalmaz.

	Bulunamazsa nil doner ve yedek gorunume dusulur.
]]
local function buildVFXModel(kind: string, position: Vector3): Model?
	local template = Assets.vfxTemplate(V.name)
	if not template then
		return nil
	end

	local color = Rarity.beamColor(kind)

	--[[
		ISTENMEYEN NESNELERI SIL
		Config.BeamVFX.hide icinde adi gecenler efektten kaldirilir.
	]]
	step("hide", function()
		for _, name in V.hide do
			local doomed = template:FindFirstChild(name, true)
			while doomed do
				doomed:Destroy()
				doomed = template:FindFirstChild(name, true)
			end
		end
	end)

	--[[
		EFEKT BORUSU  --  sira onemli

		  1. SIYAH KATMANI SIL   Renklendirme parlakligi korudugu icin siyah
		     her kademede siyah kalir; temizlenmezse koyu duman one gecer.
		  2. KADEMEYE BOYA       Mor tonlar suzmenin rengine doner.
		  3. BEYAZI YUMUSAT      Renklendirme beyaza dokunamaz, o yuzden en
		     sona birakildi; boyamadan sonra calisir ki ezilmesin.
	]]
	if V.removeDark then
		step("siyah katman", function()
			Assets.removeDarkEffects(template, V.darkThreshold, V.keepColor)
		end)
	end

	step("renklendirme", function()
		Assets.tintEffects(template, color, V.preserveShading, V.keepColor, V.vividness)
	end)

	if V.softenWhite then
		step("beyaz yumusatma", function()
			Assets.softenWhites(template, color, {
				saturation = V.whiteSaturation,
				value = V.whiteValue,
				grey = V.whiteGrey,
				saturationRef = V.whiteSaturationRef,
				maxValue = V.whiteMaxValue,
				highlight = V.whiteHighlight,
				highlightValue = V.whiteHighlightValue,
				glow = V.whiteGlow,
			}, V.keepColor)
		end)
	end

	--[[
		BUYUKLUK: parcacik boyu/hizi ve isik menzili ile efektin kendi
		geometrisi birlikte olceklenir, yoksa cap degil yalnizca hiz artar.
	]]
	local scale = V.scaleByRarity[kind] or 1
	if scale ~= 1 then
		step("olcekleme", function()
			Assets.scaleEffects(template, scale)

			if template:IsA("Model") then
				local asModel = template :: Model
				asModel:ScaleTo(asModel:GetScale() * scale)
			end
		end)
	end

	local model = Instance.new("Model")
	model.Name = `Suzme_{kind}`

	--[[
		SABLON OLDUGU GIBI ALINIR

		Efekt Studio'da nasil kurulduysa oyle kalmali: taslar (Rocks) isik
		sutununa gore hangi noktadaysa orada durmali. Bu yuzden parcalar tek
		tek yerlestirilmiyor; sablon OLDUGU GIBI iceri alinip TAMAMI ayni
		vektorle oteleniyor.
	]]
	if template:IsA("Model") or template:IsA("BasePart") then
		template.Parent = model
	else
		--[[
			Folder gibi beklenmedik bir kok geldi. Icindekileri tasiyip
			devam ediyoruz -- eskiden burada vazgecilip basit sutuna
			dusuluyordu ve efekt hic gorunmuyordu.
		]]
		for _, child in template:GetChildren() do
			child.Parent = model
		end
		template:Destroy()

		Assets.warnOnce(
			`suzme vfx sinifi: {V.name}`,
			`[Suzme] "{V.name}" bir {template.ClassName}; icindekiler tasindi.`
		)
	end

	--[[
		Parcalar sabitlenir ve isin/dokunma disina alinir. Sabitlenmezse
		efekt yere duser; isina gorunur kalirsa kum aramasi ona carpar.
	]]
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end

	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end

	--[[
		YERINE TASI

		Efektin tamami TEK bir vektorle otelenir: yatayda suzmenin noktasina
		ortalanir, dikeyde alt ucu zemine oturur (alignToGround). Oteleme her
		parcaya ayni miktarda uygulandigi icin taslarin isik sutununa gore
		konumu aynen korunur.
	]]
	step("yerlestirme", function()
		local min, max = Assets.worldBounds(model)
		if not min or not max then
			return
		end

		local targetY = position.Y + V.height
		local shiftY = if V.alignToGround
			then targetY - min.Y
			else targetY - (min.Y + max.Y) / 2

		local shift = Vector3.new(
			position.X - (min.X + max.X) / 2,
			shiftY,
			position.Z - (min.Z + max.Z) / 2
		)

		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.CFrame = part.CFrame + shift
			end
		end
	end)

	--[[
		Divine suzmesi tek renk degil: isiklari sari <-> beyaz parildar.
		Yalnizca ISIKLAR etiketlenir; parcaciklarin kendi gecisi korunur.
	]]
	if kind == "Secret" then
		for _, node in model:GetDescendants() do
			if node:IsA("Light") then
				Divine.tag(node)
			end
		end
	end

	return model
end

--[[
	VFX varsa onu, yoksa eski sutunu kurar.

	VFX kurulumu HICBIR ZAMAN suzmeyi engellememeli: paket degistiginde,
	bir ayar bozuk kaldiginda ya da renklendirme sirasinda hata ciktiginda
	eskiden suzme hic olusmuyor ve oyuncu "kazacak bir sey yok" durumunda
	kaliyordu. Artik hata yakalanir, sebep Output icine bir kez yazilir ve
	basit isik sutununa dusulur -- suzme her zaman dogar.
]]
local function buildBeamModel(kind: string, position: Vector3): Model
	local ok, result = pcall(buildVFXModel, kind, position)

	if ok and result then
		return result
	end

	if not ok then
		Assets.warnOnce(
			"suzme vfx hatasi",
			`[Suzme] VFX kurulamadi, basit sutuna dusuldu -- {tostring(result)}`
		)
	end

	return buildFallbackModel(kind, position)
end

------------------------------------------------------------------
-- SUZME OLUSTURMA
------------------------------------------------------------------

-- Oyuncunun etrafinda kumlu bir nokta arar.
local function findSandSpot(player: Player): Vector3?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end

	local origin = root.Position

	for _ = 1, 12 do
		local angle = math.random() * math.pi * 2
		local distance = math.random() * (G.maxSpawnDistance - G.minSpawnDistance) + G.minSpawnDistance
		local candidate = origin + Vector3.new(math.cos(angle) * distance, 6, math.sin(angle) * distance)

		local ground = Sand.probe(candidate, { char, folder })
		if ground and ground.isSand then
			return ground.position
		end
	end

	return nil
end

function Beams.countFor(player: Player): number
	local count = 0
	for _, beam in active do
		if beam.owner == player then
			count += 1
		end
	end
	return count
end

-- Suzmeyi fiilen kuran ortak adim; kimin, ne turde ve nerede oldugu belli.
local function createBeam(player: Player, kind: string, spot: Vector3): Beam
	beamCounter += 1
	local id = `beam_{beamCounter}`

	local model = buildBeamModel(kind, spot)
	model:SetAttribute("BeamId", id)
	model:SetAttribute("Owner", player.UserId)
	model.Parent = folder

	local beam: Beam = {
		id = id,
		owner = player,
		kind = kind,
		position = spot,
		model = model,
		bornAt = os.clock(),
		claimed = false,
	}
	active[id] = beam

	if Beams.Debug then
		print(`[Suzme] DOGDU {id} ({kind}) sahip={player.Name} toplam={Beams.countFor(player)}`)
	end

	return beam
end

--[[
	Oyuncu icin bir suzme dogurmayi dener.
	luck: bulundugu adanin sans carpani
	Donen: olusan Beam ya da nil
]]
function Beams.trySpawn(player: Player, luck: number, rng: Random, maxBeams: number?): Beam?
	if Beams.countFor(player) >= (maxBeams or G.maxBeamsPerPlayer) then
		return nil
	end

	local spot = findSandSpot(player)
	if not spot then
		return nil
	end

	return createBeam(player, Rarity.rollBeam(rng, luck), spot)
end

--[[
	ISTENEN TURDE suzme dogurur -- cekilis yok, sans yok, adet siniri yok.

	Yalnizca admin paneli kullanir: belirli bir kademenin suzmesini ve kazi
	zorlugunu sinamak icin. Kum bulunamazsa oyuncunun ayaginin dibine konur,
	boylece kumsuz bir yerde de test edilebilir.
]]
function Beams.spawnKind(player: Player, kind: string): Beam?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end

	local spot = findSandSpot(player)

	if not spot then
		-- Kum yoksa: oyuncunun onunde, ayak hizasinda
		local ground = Sand.probe(root.Position + root.CFrame.LookVector * 12, { char, folder })
		spot = if ground then ground.position else root.Position - Vector3.new(0, 3, 0)
	end

	return createBeam(player, kind, spot :: Vector3)
end

function Beams.get(id: string): Beam?
	return active[id]
end

--[[
	Teshis anahtari.
	Acikken her suzme dogumu/silinmesi sebebiyle birlikte Output'a yazilir.
	"Suzme neden kayboldu?" sorusunu cevaplamak icin gecici olarak ac;
	canlida kapali dursun, yoksa Output surekli akar.
]]
Beams.Debug = false

function Beams.remove(id: string, reason: string?)
	local beam = active[id]
	if not beam then
		return
	end

	if Beams.Debug then
		print(`[Suzme] SILINDI {id} ({beam.kind}) sahip={beam.owner.Name} sebep={reason or "belirtilmemis"}`)
	end

	if beam.model.Parent then
		--[[
			Once yayicilar ve isiklar susturulur, SONRA model silinir.

			Dogrudan Destroy edilince paketin uzun omurlu parcaciklari bir
			sure daha havada asili kaliyor ve kazilmis suzme yerinde
			duruyormus gibi gorunuyordu. Clear havadakileri de siler.
		]]
		for _, node in beam.model:GetDescendants() do
			if node:IsA("ParticleEmitter") then
				node.Enabled = false
				node:Clear()
			elseif node:IsA("Light") then
				node.Enabled = false
			end
		end

		beam.model:Destroy()
	end
	active[id] = nil
end

-- Bir oyuncunun butun suzmelerini siler (yalnizca oyuncu sunucudan cikinca)
function Beams.clearFor(player: Player, reason: string?)
	for id, beam in active do
		if beam.owner == player then
			Beams.remove(id, reason or "clearFor")
		end
	end
end

-- Oyuncunun gorebilecegi suzmelerin client'a gonderilecek ozeti
function Beams.snapshotFor(player: Player, scanRadius: number?): { { id: string, kind: string, position: Vector3 } }
	local out = {}
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return out
	end

	for id, beam in active do
		if beam.owner == player and not beam.claimed then
			local distance = (beam.position - root.Position).Magnitude
			if distance <= (scanRadius or G.scanRadius) then
				table.insert(out, {
					id = id,
					kind = beam.kind,
					position = beam.position,
				})
			end
		end
	end

	return out
end

--[[
	Suresi dolan suzmeleri temizler.

	Kazilmaya baslanmis (claimed) bir suzme normal omrunu asabilir; ama
	minigame yarida kalirsa sonsuza dek bellekte kalmasin diye onlara da
	daha uzun bir ust sinir uygulanir.
]]
function Beams.cleanup()
	local now = os.clock()
	local claimedLimit = G.beamLifetime + 120

	for id, beam in active do
		local age = now - beam.bornAt
		local ownerGone = beam.owner.Parent == nil
		local expired = if beam.claimed then age > claimedLimit else age > G.beamLifetime

		if expired or ownerGone then
			Beams.remove(id, if ownerGone then "sahip cikti" else `omur doldu ({math.floor(age)}sn)`)
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	Beams.clearFor(player, "oyuncu ayrildi")
end)

return Beams
