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
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Config = require(Shared:WaitForChild("OyunConfig"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Flyboard = require(Shared:WaitForChild("Flyboard"))
local Divine = require(Shared:WaitForChild("Divine"))

local Sand = require(script.Parent:WaitForChild("Sand"))

local Beams = {}

local G = Config.GPS
local V = Config.BeamVFX
local W = Config.WhirlVFX

export type Beam = {
	id: string,
	owner: Player,
	kind: string,        -- RarityId, "RotCoin" ya da "LuckyBlock"
	position: Vector3,
	model: Model,
	bornAt: number,
	claimed: boolean,    -- kazi basladiysa tekrar kazilamaz
	-- Denizde dogan GIRDAP mi (olta sistemi), yoksa kumdaki suzme mi
	sea: boolean?,
	--[[
		Dogdugu adanin kum parcasinin ADI (kum, sekerkum, snowkum,
		gizlikum, deniz). Kazidan cikan brainrotun ismi bu adaya gore
		seciliyor -- ayni kademe her adada farkli brainrotlar veriyor.
	]]
	island: string?,
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
local function buildVFXModel(cfg, kind: string, position: Vector3): Model?
	local template = Assets.vfxTemplate(cfg.name)
	if not template then
		return nil
	end

	local color = Rarity.beamColor(kind)

	--[[
		ISTENMEYEN NESNELERI SIL
		Config.BeamVFX.hide icinde adi gecenler efektten kaldirilir.
	]]
	step("hide", function()
		for _, name in cfg.hide do
			local doomed = template:FindFirstChild(name, true)
			while doomed do
				doomed:Destroy()
				doomed = template:FindFirstChild(name, true)
			end
		end
	end)

	--[[
		PAKETIN KENDI SCRIPTLERINI SIL

		Toolbox efektlerinin icinde kendi dondurme/animasyon scriptleri
		oluyor. Girdabin donusunu oyunun kendisi yonetiyor (bkz. spin);
		paketin scripti ayni modeli ayri bir eksende cevirince efekt yan
		yatmis gibi donuyordu. Ayrica efekt paketinin script CALISTIRMASI
		icin bir sebep yok -- olmayan script arka kapi da olamaz.
	]]
	if cfg.stripScripts then
		step("script temizligi", function()
			Assets.stripScripts(template)
		end)
	end

	--[[
		EFEKT BORUSU  --  sira onemli

		  1. SIYAH KATMANI SIL   Renklendirme parlakligi korudugu icin siyah
		     her kademede siyah kalir; temizlenmezse koyu duman one gecer.
		  2. KADEMEYE BOYA       Mor tonlar suzmenin rengine doner.
		  3. BEYAZI YUMUSAT      Renklendirme beyaza dokunamaz, o yuzden en
		     sona birakildi; boyamadan sonra calisir ki ezilmesin.
	]]
	if cfg.removeDark then
		step("siyah katman", function()
			Assets.removeDarkEffects(template, cfg.darkThreshold, cfg.keepColor)
		end)
	end

	step("renklendirme", function()
		Assets.tintEffects(template, color, cfg.preserveShading, cfg.keepColor, cfg.vividness)
	end)

	--[[
		YUZEY RENKLENDIRME

		Bazi paketler efekti parcaciklarla degil DOKULU PARCALARLA kuruyor
		(donen bir disk, uzerine yapistirilmis bir Decal...). Onlarin rengi
		parcanin kendisinde durur ve tintEffects oraya bakmaz. tintParts
		acikken parcalar, decal'lar ve dokular da kademeye boyanir.

		Girdap icin acik: VortexVFX dokulu parcalardan kurulu ve kapaliyken
		kademe ne olursa olsun hep ayni mavi kaliyordu.
	]]
	if cfg.tintParts then
		step("yuzey renklendirme", function()
			Assets.tintSurfaces(template, color, cfg.preserveShading, cfg.keepColor, cfg.vividness)
		end)
	end

	--[[
		PARCACIK GECISI  --  beyaz patlamaya karsi

		Duz tek renkte parcaciklar ekranda beyaza patliyordu. Sebep renk
		degil LightEmission: yuksek oldugunda parcacik eklemeli cizilir ve
		rengi ne olursa olsun merkez bembeyaz olur.

		Acikken parcaciklar kademe renginin ACIK -> KOYU gecisine cevrilir
		ve parlama tavana cekilir. Flyboard tahtalarinda da ayni yol
		kullaniliyor.

		Bu adim renklendirmeden SONRA gelir: parcaciklarda son soz onun.
	]]
	if cfg.ramp then
		step("parcacik gecisi", function()
			Assets.rampEffects(template, color, cfg.ramp, cfg.keepColor)
		end)
	end

	if cfg.softenWhite then
		step("beyaz yumusatma", function()
			Assets.softenWhites(template, color, {
				saturation = cfg.whiteSaturation,
				value = cfg.whiteValue,
				grey = cfg.whiteGrey,
				saturationRef = cfg.whiteSaturationRef,
				maxValue = cfg.whiteMaxValue,
				highlight = cfg.whiteHighlight,
				highlightValue = cfg.whiteHighlightValue,
				glow = cfg.whiteGlow,
			}, cfg.keepColor)
		end)
	end

	--[[
		YERLESTIRME KAYMASI

		Efektin sinirlarina (min/max) bakip onu suzmenin noktasina tasiyacak
		oteleme. Hem asil yerlestirmede hem taslarin Common yerini
		hesaplarken AYNI formul kullaniliyor -- ikisi ayri yazilsaydi biri
		degistiginde taslar yine kayardi.
	]]
	local function yerlestirmeKaymasi(min: Vector3, max: Vector3): Vector3
		local tabanY = cfg.fixedY or position.Y
		local targetY = tabanY + cfg.height
		local shiftY = if cfg.alignToGround
			then targetY - min.Y
			else targetY - (min.Y + max.Y) / 2

		return Vector3.new(
			position.X - (min.X + max.X) / 2,
			shiftY,
			position.Z - (min.Z + max.Z) / 2
		)
	end

	--[[
		ZEMIN PARCALARI (Rocks) COMMON YERINDE KALIR

		Kademe olcegi efektin TAMAMINI buyutuyor ve sonra alt ucu zemine
		oturtuluyordu. Isik sutunu tasin altina da uzandigi icin buyuyen
		modelde taslar sutunla birlikte YUKARI kayiyor, nadir suzmelerde
		havada asili duruyordu.

		Olceklemeden ONCE taslarin Common'da (olcek 1) nereye oturacagi ve
		boyu kaydediliyor; yerlestirmeden sonra taslar oraya geri konuyor.
		Efektin geri kalani oldugu gibi buyuyup yerlesiyor.
	]]
	type ZeminParcasi = {
		part: BasePart,
		cframe: CFrame,
		size: Vector3,
		meshes: { [SpecialMesh]: Vector3 },
	}
	local zeminParcalari: { ZeminParcasi } = {}
	local kademeOlcegi = (cfg.baseScale or 1) * (cfg.scaleByRarity[kind] or 1)

	if cfg.groundParts and #cfg.groundParts > 0 and kademeOlcegi ~= 1 and template:IsA("Model") then
		step("zemin parcalari", function()
			local min, max = Assets.worldBounds(template :: Model)
			if not min or not max then
				return
			end

			local commonKaymasi = yerlestirmeKaymasi(min, max)

			local function zeminde(node: Instance): boolean
				local cursor: Instance? = node
				while cursor and cursor ~= template do
					for _, ad in cfg.groundParts do
						if cursor.Name == ad then
							return true
						end
					end
					cursor = cursor.Parent
				end
				return false
			end

			for _, node in template:GetDescendants() do
				if node:IsA("BasePart") and zeminde(node) then
					local meshes = {}
					for _, child in node:GetChildren() do
						if child:IsA("SpecialMesh") then
							meshes[child] = child.Scale
						end
					end

					table.insert(zeminParcalari, {
						part = node,
						cframe = node.CFrame + commonKaymasi,
						size = node.Size,
						meshes = meshes,
					})
				end
			end
		end)
	end

	--[[
		BUYUKLUK

		Parcacik boyu/hizi, isik menzili ve efektin kendi geometrisi birlikte
		olceklenir; yoksa cap degil yalnizca hiz artar.

		Kademe carpani paketin KENDI taban olcegiyle carpilir. baseScale
		sonradan eklendi: girdap paketinin boyu oyuna gore cok kucuktu ve
		carpani 1 olan Common/Rare girdaplar ekranda tek bir parcacik gibi
		duruyordu. Kumda taban 1 -- o paket zaten dogru boyda kurulmus.
	]]
	local scale = (cfg.baseScale or 1) * (cfg.scaleByRarity[kind] or 1)
	if scale ~= 1 then
		step("olcekleme", function()
			Assets.scaleEffects(template, scale)

			if template:IsA("Model") then
				local asModel = template :: Model
				asModel:ScaleTo(asModel:GetScale() * scale)
			elseif template:IsA("BasePart") then
				-- Tek parcalik paket: Model olmadigi icin ScaleTo yok
				template.Size *= scale
			end
		end)
	end

	local model = Instance.new("Model")
	model.Name = `{cfg.label}_{kind}`

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
			`{cfg.label} vfx sinifi: {cfg.name}`,
			`[{cfg.label}] "{cfg.name}" bir {template.ClassName}; icindekiler tasindi.`
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

		--[[
			DIKEY YER

			Normalde noktanin kendi Y'si kullanilir. cfg.fixedY verilmisse
			onun yerine o sabit yukseklik gecerlidir.

			Deniz icin sabit: isin dalganin tepesine ya da cukuruna denk
			gelebiliyor ve girdap bazen suyun biraz altinda/ustunde
			kaliyordu. Kumda fixedY yok -- zemin her yerde ayni yukseklikte
			degil, orada isinin buldugu nokta dogru olan.
		]]
		local shift = yerlestirmeKaymasi(min, max)

		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.CFrame = part.CFrame + shift
			end
		end
	end)

	--[[
		TASLAR COMMON YERINE DONER

		Efektin geri kalani buyuyup yerlesti; zemin parcalari olceklenmeden
		once kaydedilen boy ve konumlarina geri aliniyor. Boyut ONCE
		yaziliyor, sonra CFrame -- tersi olsaydi boy degisimi merkezi
		kaydirabilirdi.
	]]
	if #zeminParcalari > 0 then
		step("zemin parcalari geri", function()
			for _, kayit in zeminParcalari do
				if kayit.part.Parent then
					kayit.part.Size = kayit.size
					kayit.part.CFrame = kayit.cframe
					for mesh, olcek in kayit.meshes do
						mesh.Scale = olcek
					end
				end
			end
		end)
	end

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
--[[
	GIRDAP  --  denizdeki suzmenin karsiligi

	Kumdaki isik sutununun yerine su yuzeyinde donen bir HUNI durur:
	  - alttaki dar uc ile ustteki genis agiz arasinda konik bir govde
	  - kademenin renginde donen bir halka
	  - yukari savrulan su parcaciklari

	Kademe rengi disinda karadaki suzmeyle ayni kurallara tabi: ayni
	kimlikle kaydedilir, ayni sekilde kazilir, ayni sekilde temizlenir.
]]
local function buildFallbackWhirl(kind: string, position: Vector3): Model
	-- Ozel turlerin iki renkli gecisi var; kademe girdaplari tek renk
	local special = if kind == "RotCoin"
		then Rarity.RotCoin
		elseif kind == "LuckyBlock" then Rarity.LuckyBlock
		else nil

	local colorA = if special then special.colorA else Rarity.color(kind)
	local colorB = if special then special.colorB else colorA

	local model = Instance.new("Model")
	model.Name = `Girdap_{kind}`

	--[[
		HUNI

		Roblox'ta koni parcasi yok; iki ucu farkli genislikte bir Beam
		kullaniliyor (Flyboard isik konisiyle ayni yol). FaceCamera ile her
		acidan huni gibi gorunur.
	]]
	local core = Instance.new("Part")
	core.Name = "Govde"
	core.Size = Vector3.new(1, 6, 1)
	core.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	core.Transparency = 1
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.CanTouch = false
	core.Parent = model

	local dip = Instance.new("Attachment")
	dip.Name = "Dip"
	dip.Position = Vector3.new(0, -3, 0)
	dip.Parent = core

	local agiz = Instance.new("Attachment")
	agiz.Name = "Agiz"
	agiz.Position = Vector3.new(0, 3, 0)
	agiz.Parent = core

	local huni = Instance.new("Beam")
	huni.Name = "Huni"
	huni.Attachment0 = dip
	huni.Attachment1 = agiz
	huni.Width0 = 0.5
	huni.Width1 = 5
	huni.FaceCamera = true
	huni.LightEmission = 0.3
	huni.LightInfluence = 0
	huni.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorB),
		ColorSequenceKeypoint.new(1, colorA),
	})
	huni.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 0.55),
	})
	huni.Parent = core

	-- Su yuzeyinde donen halka
	local halka = Instance.new("Part")
	halka.Name = "Halka"
	halka.Shape = Enum.PartType.Cylinder
	halka.Size = Vector3.new(0.2, 5, 5)
	halka.CFrame = CFrame.new(position + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	halka.Anchored = true
	halka.CanCollide = false
	halka.CanQuery = false
	halka.CanTouch = false
	halka.CastShadow = false
	halka.Material = Enum.Material.Neon
	halka.Color = colorA
	halka.Transparency = 0.35
	halka.Parent = model

	-- Yukari savrulan su
	local serpinti = Instance.new("ParticleEmitter")
	serpinti.Name = "Serpinti"
	serpinti.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorA),
		ColorSequenceKeypoint.new(1, colorB),
	})
	serpinti.Lifetime = NumberRange.new(0.6, 1.1)
	serpinti.Rate = 26
	serpinti.Speed = NumberRange.new(5, 9)
	serpinti.SpreadAngle = Vector2.new(14, 14)
	serpinti.Size = NumberSequence.new(0.7)
	serpinti.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	serpinti.LightEmission = 0.4
	serpinti.Parent = dip

	local isik = Instance.new("PointLight")
	isik.Color = colorA
	isik.Range = 18
	isik.Brightness = 2
	isik.Parent = core

	model.PrimaryPart = core
	return model
end

--[[
	VFX varsa onu, yoksa kodla cizilen yedek gorunumu kurar.

	VFX kurulumu HICBIR ZAMAN suzmeyi engellememeli: paket degistiginde,
	bir ayar bozuk kaldiginda ya da renklendirme sirasinda hata ciktiginda
	eskiden suzme hic olusmuyor ve oyuncu "kazacak bir sey yok" durumunda
	kaliyordu. Artik hata yakalanir, sebep Output icine bir kez yazilir ve
	yedek gorunume dusulur -- suzme her zaman dogar.
]]
local function buildWithVFX(
	cfg: any,
	kind: string,
	position: Vector3,
	fallback: (string, Vector3) -> Model
): Model
	local ok, result = pcall(buildVFXModel, cfg, kind, position)

	if ok and result then
		return result
	end

	if not ok then
		Assets.warnOnce(
			`{cfg.label} vfx hatasi`,
			`[{cfg.label}] VFX kurulamadi, yedek gorunume dusuldu -- {tostring(result)}`
		)
	end

	return fallback(kind, position)
end

-- Kumdaki isik sutunu: DigLightVFX
local function buildBeamModel(kind: string, position: Vector3): Model
	return buildWithVFX(V, kind, position, buildFallbackModel)
end

-- Denizdeki girdap: VortexVFX
local function buildWhirlModel(kind: string, position: Vector3): Model
	return buildWithVFX(W, kind, position, buildFallbackWhirl)
end

------------------------------------------------------------------
-- SUZME OLUSTURMA
------------------------------------------------------------------

-- Oyuncunun etrafinda kumlu bir nokta arar.
local function findSandSpot(player: Player): (Vector3?, string?)
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
			-- Ada adi da doner: brainrot ismi buna gore secilecek
			return ground.position, if ground.part then string.lower(ground.part.Name) else nil
		end
	end

	return nil
end

--[[
	Oyuncunun acik suzme sayisi.

	sea verilirse yalnizca O TUR sayilir: kumdaki suzmeler ile denizdeki
	girdaplarin limitleri AYRI. Onceden ikisi tek havuzdan sayiliyordu ve
	kumda birkac suzme birakan oyuncu denizde hic girdap goremiyordu.
]]
function Beams.countFor(player: Player, sea: boolean?): number
	local count = 0
	for _, beam in active do
		--[[
			KAZILMAYA BASLANMIS OLANLAR SAYILMAZ.

			claimed bir suzme artik kazilamaz, yalnizca temizlenmeyi bekler.
			Limite dahil edilince bir hata yuzunden yarida kalan iki kazi bile
			limiti sonsuza dek dolduruyor ve yeni suzme/girdap hic dogmuyordu.
		]]
		if beam.owner == player and not beam.claimed then
			if sea == nil or (beam.sea == true) == sea then
				count += 1
			end
		end
	end
	return count
end

-- Suzmeyi fiilen kuran ortak adim; kimin, ne turde ve nerede oldugu belli.
local function createBeam(player: Player, kind: string, spot: Vector3, sea: boolean?, island: string?): Beam
	beamCounter += 1
	local id = `beam_{beamCounter}`

	local model = if sea then buildWhirlModel(kind, spot) else buildBeamModel(kind, spot)
	model:SetAttribute("BeamId", id)
	model:SetAttribute("Owner", player.UserId)
	model.Parent = folder

	--[[
		GIRDAP YATAYDA DONER

		Donusu ISTEMCI yapiyor: model etiketleniyor, her oyuncu kendi
		ekraninda ceviriyor. Sunucuda cevirmek her karede CFrame
		replikasyonu demek olurdu -- gorsel bir detay icin gereksiz trafik.

		Tek eksen: dunya Y'si. Paketin kendi dondurme scriptleri silindigi
		icin (stripScripts) baska bir eksende ceviren kimse kalmiyor;
		girdap eskiden onlar yuzunden yan yatmis gibi donuyordu.
	]]
	if sea and W.spin and W.spin ~= 0 then
		model:SetAttribute("DonusHizi", W.spin)
		CollectionService:AddTag(model, W.spinTag)
	end

	local beam: Beam = {
		id = id,
		owner = player,
		kind = kind,
		position = spot,
		model = model,
		bornAt = os.clock(),
		claimed = false,
		sea = sea,
		-- Denizde sabit; kumda kum parcasinin adi
		island = if sea then "deniz" else island,
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
--[[
	DENIZDE GIRDAP NOKTASI

	Kumdaki findSandSpot'un deniz karsiligi: oyuncunun etrafinda rastgele
	bir noktaya asagi isin gonderilir, su yuzeyine carparsa orasi girdabin
	yeri olur. Terrain su da isim verilmis deniz parcalari da kabul edilir
	(bkz. Shared > Flyboard > SeaNames).
]]
local function findSeaSpot(player: Player, maxDistance: number?): Vector3?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, folder }

	local origin = root.Position

	--[[
		GIRDAPLAR BIRBIRINE YAPISMAZ

		Ayni oyuncunun iki girdabi arasinda en az seaSeparation stud olur.
		Deniz genis; kumun dar sayilari burada girdaplari birbirinin dibine
		yigiyordu.
	]]
	local function uygun(nokta: Vector3): boolean
		for _, beam in active do
			if beam.owner == player and (beam.position - nokta).Magnitude < G.seaSeparation then
				return false
			end
		end
		return true
	end

	--[[
		DOGUM YARICAPI OLTADAN GELIR

		Cok onemli: istemciye yalnizca oltanin scanRadius'u icindeki
		girdaplar gonderiliyor (bkz. snapshotFor). Yaricapin disinda dogan
		girdap oyuncuya hic ulasmaz -- gorunmez olur ve tiklanamaz. Bu yuzden
		ust sinir sabit bir sayi DEGIL, dogrudan oltanin menzili.

		Kenarda dogan girdap oyuncu azicik kipirdayinca menzilden cikip
		titremesin diye biraz icerden kesiliyor.
	]]
	local enUzak = math.max((maxDistance or G.seaMaxSpawnDistance) * 0.9, G.seaMinSpawnDistance + 10)
	local yaricap = enUzak - G.seaMinSpawnDistance

	--[[
		Ayrik durma sarti sikiysa cogu deneme bosa gider; deniz taramasinda
		kumdan FAZLA deneme yapiliyor. Yine de yer bulunamazsa girdap bu tur
		dogmaz -- oyuncu gezdikce yer acilir, zaten istenen de bu.
	]]
	for _ = 1, 30 do
		local angle = math.random() * math.pi * 2
		local distance = math.random() * yaricap + G.seaMinSpawnDistance
		local candidate = origin + Vector3.new(math.cos(angle) * distance, 12, math.sin(angle) * distance)

		local hit = Workspace:Raycast(candidate, Vector3.new(0, -80, 0), params)
		if hit then
			-- Terrain su ya da adi (veya ust modelinin adi) deniz olan bir parca
			local suMu = hit.Material == Enum.Material.Water or Flyboard.isSeaInstance(hit.Instance)

			if suMu and uygun(hit.Position) then
				return hit.Position
			end
		end
	end

	return nil
end

--[[
	Denizde girdap dogurmayi dener. Kumdaki trySpawn ile ayni kurallar;
	fark yalnizca noktanin suda aranmasi ve gorunumun huni olmasi.
]]
function Beams.trySpawnSea(player: Player, luck: number, rng: Random, maxWhirls: number?, scanRadius: number?): Beam?
	if Beams.countFor(player, true) >= (maxWhirls or G.maxBeamsPerPlayer) then
		return nil
	end

	local spot = findSeaSpot(player, scanRadius)
	if not spot then
		return nil
	end

	return createBeam(player, Rarity.rollBeam(rng, luck), spot, true)
end

function Beams.trySpawn(player: Player, luck: number, rng: Random, maxBeams: number?): Beam?
	if Beams.countFor(player, false) >= (maxBeams or G.maxBeamsPerPlayer) then
		return nil
	end

	local spot, ada = findSandSpot(player)
	if not spot then
		return nil
	end

	return createBeam(player, Rarity.rollBeam(rng, luck), spot, false, ada)
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

	local spot, ada = findSandSpot(player)

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
					sea = beam.sea == true,
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
-- MARKER_152426
