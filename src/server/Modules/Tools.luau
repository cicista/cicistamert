--!strict
--[[
	Kurek, Brainrot GPS ve brainrot toollarini olusturur.

	Kurek: oyuncuda her zaman TEK tane bulunur; yeni kurek alininca eskisi silinir.
	GPS:   her zaman cantada durur, oyuncu kendi eline alir.
	Brainrot: fiziksel esya; acilmamisken simsiyah, acildiktan sonra gercek modeli.

	MODEL / ANIMASYON EKLEME
	Butun asset id'leri ve model klasorleri Shared > Assets icinde tanimlidir.
	Model bulunamazsa burada uretilen basit gorunum kullanilir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Shovels = require(Shared:WaitForChild("Shovels"))
local Detectors = require(Shared:WaitForChild("Detectors"))
local Rods = require(Shared:WaitForChild("Rods"))
local Skins = require(Shared:WaitForChild("Skins"))
local Rarity = require(Shared:WaitForChild("Rarity"))
local Condition = require(Shared:WaitForChild("Condition"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Assets = require(Shared:WaitForChild("Assets"))
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local LevelGlow = require(Shared:WaitForChild("LevelGlow"))
local Divine = require(Shared:WaitForChild("Divine"))
local Fuse = require(Shared:WaitForChild("Fuse"))
local Etiket = require(Shared:WaitForChild("Etiket"))
local GPSEfekt = require(Shared:WaitForChild("GPSEfekt"))
local Fonts = require(Shared:WaitForChild("Fonts"))

local Tools = {}

Tools.ShovelName = "Shovel"
Tools.GPSName = "Brainrot GPS"
Tools.LuckyBlockName = "Lucky Block"

--[[
	Lucky Block cantadan kullanilinca cagrilir.

	Acma mantigi LuckyBlockOdul icinde; burada sadece bir kanca tutuluyor.
	Tools -> LuckyBlockOdul seklinde bir require olsaydi dairesel bagimlilik
	olusurdu (LuckyBlockOdul -> Envanter -> Tools).
]]
Tools.onLuckyBlockUsed = nil :: ((player: Player, tierId: string) -> ())?

------------------------------------------------------------------
-- ORTAK
------------------------------------------------------------------

--[[
	Bir Model'i tutulabilir Tool govdesine cevirir.
	PrimaryPart "Handle" olur, kalan parcalar ona kaynaklanir.
	Ic ice modellerde de Handle'in Tool'un DOGRUDAN cocugu olmasi garantidir.
]]
local function attachModel(tool: Tool, model: Model): BasePart?
	local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not primary then
		model:Destroy()
		return nil
	end

	primary.Name = "Handle"
	primary.Parent = tool

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = primary
			weld.Part1 = part
			weld.Parent = primary
		end
	end

	for _, child in model:GetChildren() do
		child.Parent = tool
	end
	model:Destroy()

	for _, part in tool:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
		end
	end

	return primary
end

--[[
	Tool'a tutma animasyonu bagi ekler.
	Animasyonu client oynatir (Animator sadece client'ta guvenilir calisir);
	burada yalnizca id'yi tool'a yaziyoruz.
]]
local function setHoldAnimation(tool: Tool, animationId: string?)
	local id = Assets.id(animationId)
	if not id then
		return
	end
	tool:SetAttribute("HoldAnimation", id)
end

--[[
	Mutasyonsuz brainrotlardan gorsel efektleri kaldirir.

	BrainrotPack modellerinin bazilarinda parcacik, iz ve isik efektleri
	gomulu geliyor. Bunlar mutasyonu belli etmek icin anlamli; duz (Normal)
	brainrotta ise gereksiz gorsel gurultu yapiyor.
]]
local EFFECT_CLASSES = {
	"ParticleEmitter",
	"Trail",
	"Beam",
	"Highlight",
	"PointLight",
	"SpotLight",
	"SurfaceLight",
	"Sparkles",
	"Fire",
	"Smoke",
}

-- Adinda bunlardan biri gecen parcalar da suslemedir (paket modellerinde
-- kristal, hale, yildiz gibi dekoratif Part'lar bu adlarla geliyor)
local EFFECT_NAMES = { "vfx", "effect", "efekt", "aura", "glow", "sparkle", "particle", "halo", "ring", "orb" }

local function isEffectPart(part: BasePart): boolean
	local lower = string.lower(part.Name)
	for _, word in EFFECT_NAMES do
		if string.find(lower, word, 1, true) then
			return true
		end
	end
	return false
end

function Tools.stripEffects(model: Instance)
	local doomed: { Instance } = {}

	for _, item in model:GetDescendants() do
		for _, class in EFFECT_CLASSES do
			if item:IsA(class) then
				table.insert(doomed, item)
				break
			end
		end

		-- Adiyla belli olan susleme parcalari (modelin govdesi degil)
		if item:IsA("BasePart") and isEffectPart(item) then
			table.insert(doomed, item)
		end
	end

	for _, item in doomed do
		if item.Parent then
			item:Destroy()
		end
	end
end

------------------------------------------------------------------
-- KUREK
------------------------------------------------------------------
function Tools.buildShovel(shovelId: string, skinId: string?): Tool
	local info = Shovels.get(shovelId :: any)

	local tool = Instance.new("Tool")
	tool.RequiresHandle = true

	-- Assets > Shovels icinde model varsa o kullanilir
	local model = Assets.shovelModel(info.id, skinId)
	local handle = if model then attachModel(tool, model) else nil

	if not handle then
		local body = Instance.new("Part")
		body.Name = "Handle"
		body.Size = Vector3.new(0.4, 3.2, 0.4)
		body.Color = Color3.fromRGB(120, 80, 45)
		body.Material = Enum.Material.Wood
		body.Parent = tool

		local blade = Instance.new("Part")
		blade.Name = "Blade"
		blade.Size = Vector3.new(1.2, 1.2, 0.2)
		blade.Color = Color3.fromRGB(178, 182, 190)
		blade.Material = Enum.Material.Metal
		blade.CanCollide = false
		blade.Massless = true
		blade.CFrame = body.CFrame * CFrame.new(0, -1.8, 0)
		blade.Parent = tool

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = blade
		weld.Parent = body
	end

	tool.Name = Tools.ShovelName
	tool.CanBeDropped = false
	tool.ToolTip = `{info.displayName}  |  Lv.{info.level}`
	tool:SetAttribute("ShovelId", info.id)

	-- Model kendi gorunumunu getirmisse skin rengini zorlamayiz
	if skinId and not model then
		Skins.apply(tool, skinId)
	end

	setHoldAnimation(tool, Assets.Animations.shovelHold)

	-- Seviye parlamasi skinden bagimsizdir; en sonda uygulanir
	LevelGlow.apply(tool, info.level)

	return tool
end

------------------------------------------------------------------
-- BRAINROT GPS (DEDEKTOR)
------------------------------------------------------------------
function Tools.buildGPS(detectorId: string, skinId: string?): Tool
	local info = Detectors.get(detectorId :: any)

	local tool = Instance.new("Tool")
	tool.RequiresHandle = true

	local model = Assets.detectorModel(info.id, skinId)
	local handle = if model then attachModel(tool, model) else nil

	--[[
		ANTEN GORUNUMU

		Eski gorunum bir telefondu (govde + ekran + kucuk anten). Yenisi
		ince bir CUBUK ve ucunda bir TOP: klasik dedektor anteni.

		Topun adi GPSEfekt.BallName -- istemci "baglanmaya calisiyor"
		dalgalarini ona bakarak buluyor. Adi degistirirsen dalgalar kaybolur.
	]]
	if not handle then
		local rod = Instance.new("Part")
		rod.Name = "Handle"
		rod.Size = Vector3.new(0.14, 2.4, 0.14)
		rod.Color = Color3.fromRGB(48, 52, 60)
		rod.Material = Enum.Material.Metal
		rod.TopSurface = Enum.SurfaceType.Smooth
		rod.BottomSurface = Enum.SurfaceType.Smooth
		rod.Parent = tool

		local ball = Instance.new("Part")
		ball.Name = GPSEfekt.BallName
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(0.55, 0.55, 0.55)
		-- Top dedektorun kendi renginde yanar; seviye ilerledikce degisir
		ball.Color = info.color
		ball.Material = Enum.Material.Neon
		ball.CanCollide = false
		ball.Massless = true
		-- Cubugun tam ucunda
		ball.CFrame = rod.CFrame * CFrame.new(0, rod.Size.Y / 2, 0)
		ball.Parent = tool

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rod
		weld.Part1 = ball
		weld.Parent = rod

		handle = rod
	end

	tool.Name = Tools.GPSName
	tool.CanBeDropped = false
	tool.ToolTip = `{info.displayName}  |  Lv.{info.level}  |  Luck x{info.luck}`
	tool:SetAttribute("DetectorId", info.id)

	if skinId and not model then
		Skins.apply(tool, skinId)
	end

	--[[
		TOP HER ZAMAN YANAR

		Skins.apply butun parcalarin malzemesini skinin malzemesiyle
		degistiriyor; topa dokunulsaydi anten ucu sonuk kalirdi. Skinin
		RENGI korunur (istenen zaten sadece renk degisikligiydi), yalnizca
		malzeme Neon'a geri alinir.
	]]
	local ball = tool:FindFirstChild(GPSEfekt.BallName)
	if ball and ball:IsA("BasePart") then
		ball.Material = Enum.Material.Neon
		ball.Reflectance = 0
	end

	--[[
		Anten elin neresinden tutuluyor gorunecek: Shared > Assets > GPSGrip.
		Model paketten geliyorsa ona dokunmayiz -- kendi tutus noktasi vardir.
	]]
	if not model then
		local grip = Assets.GPSGrip
		tool.Grip = CFrame.new(grip.position)
			* CFrame.Angles(
				math.rad(grip.rotation.X),
				math.rad(grip.rotation.Y),
				math.rad(grip.rotation.Z)
			)
	end

	setHoldAnimation(tool, Assets.Animations.gpsHold)

	LevelGlow.apply(tool, info.level)

	return tool
end

------------------------------------------------------------------
-- BRAINROT (fiziksel esya)
------------------------------------------------------------------

--[[
	BRAINROT'U KAFAYA TASIT

	Roblox bir Tool kusanildiginda Handle'i SAG ELE baglayan "RightGrip"
	baglantisini kendisi kurar. Kafada tasimak icin o baglanti kaldirilip
	yerine KAFAYA giden kendi kaynagimiz konur.

	Boylece brainrot animasyondaki el konumundan bagimsiz olarak hep tam
	kafanin ortasinda durur -- animasyon sadece kollari poz verir.

	Yukseklik modelin GORSEL MERKEZINE gore olculur (MerkezKaymasi
	niteligi): paket modellerinde Handle govdenin ortasinda olmayabiliyor,
	merkez hesabi olmasa kimi brainrot havada kimi kafanin icinde kalirdi.
]]
local HEAD_WELD = "KafaKaynagi"

local function holdOnHead(tool: Tool)
	local character = tool.Parent
	if not character or not character:IsA("Model") then
		return
	end

	local head = character:FindFirstChild("Head")
	local handle = tool:FindFirstChild("Handle")
	if not head or not head:IsA("BasePart") or not handle or not handle:IsA("BasePart") then
		return
	end

	local cfg = Assets.BrainrotHold

	-- Handle ile modelin gorsel merkezi arasindaki fark
	local shift = (tool:GetAttribute("MerkezKaymasi") :: Vector3?) or Vector3.zero
	-- Modelin kendi yari yuksekligi: her boyut kafaya dogru otursun
	local half = (tool:GetAttribute("YariYukseklik") :: number?) or 1

	local old = handle:FindFirstChild(HEAD_WELD)
	if old then
		old:Destroy()
	end

	--[[
		KENDI TUTUS AYARI OLAN TOOLLAR

		Kimligi belirlenmemis brainrot duz bir kup; gercek brainrot
		modelleriyle ayni yerde durunca elin uzerinde asili kaliyor.
		Bu yuzden o tool'a kendi kayma ve donus degerleri yaziliyor
		(bkz. Assets.HiddenBrainrot). Nitelik yoksa herkes icin gecerli
		olan genel ayar kullanilir.
	]]
	local offset = (tool:GetAttribute("TutusKaymasi") :: Vector3?) or cfg.headOffset
	local spin = (tool:GetAttribute("TutusDonusu") :: Vector3?) or cfg.headRotation

	--[[
		Yukseklik = kafanin yarisi + brainrot'un yarisi + bosluk.
		Boylece Tiny de Huge de kafanin tepesine ayni sekilde oturur.
	]]
	local lift = head.Size.Y / 2 + half + cfg.headGap

	--[[
		Once konum, sonra donus, en son merkez duzeltmesi: model KENDI
		merkezi etrafinda doner ve merkezi hedef noktaya oturur.
	]]
	local weld = Instance.new("Weld")
	weld.Name = HEAD_WELD
	weld.Part0 = head
	weld.Part1 = handle
	weld.C0 = CFrame.new(offset + Vector3.new(0, lift, 0))
		* CFrame.Angles(
			math.rad(spin.X),
			math.rad(spin.Y),
			math.rad(spin.Z)
		)
		* CFrame.new(-shift)
	weld.Parent = handle

	--[[
		Ele takan baglanti kaynak KURULDUKTAN SONRA kaldirilir. Ters sirada
		olsaydi handle bir an bagsiz kalir ve dusebilirdi.
	]]
	local grip = character:FindFirstChild("RightGrip", true)
	if grip then
		grip:Destroy()
	end
end

local function releaseHead(tool: Tool)
	local handle = tool:FindFirstChild("Handle")
	local weld = handle and handle:FindFirstChild(HEAD_WELD)
	if weld then
		weld:Destroy()
	end
end

--[[
	Envanterdeki bir brainrot'u tutulabilir Tool'a cevirir.

	Acilmamis (siyah) hal: butun parcalar simsiyah, isim "??? (Rarity)"
	Acilmis hal:           Assets > Brainrots icindeki model, gercek adiyla
	                       (mutasyonluysa "Gold ..." surumu ve mutasyon rengi)
]]
function Tools.buildBrainrot(item: any): Tool
	local rarityInfo = Rarity.get(item.rarity)
	local conditionInfo = Condition.get(item.condition)
	local mutationInfo = Mutations.get(item.mutation)
	local revealed = item.revealed and item.name

	local tool = Instance.new("Tool")
	-- Mutasyonlu brainrot adiyla birlikte tasinir: "Gold Tralalero Tralala"
	tool.Name = if revealed
		then item.name
		else `??? ({rarityInfo.displayName})`
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("BrainrotUid", item.uid)
	tool:SetAttribute("Rarity", item.rarity)
	tool:SetAttribute("Condition", item.condition)
	tool:SetAttribute("Mutation", item.mutation)
	tool:SetAttribute("Revealed", revealed == true)

	--[[
		Gizli modelin KENDI tutus ayari (bkz. Assets.HiddenBrainrot).
		holdOnHead bu nitelikleri gorurse genel ayar yerine bunlari
		kullanir; acilmis brainrotlarda nitelik hic yazilmaz ve eski
		yerlesim aynen korunur.
	]]
	if not revealed then
		tool:SetAttribute("TutusKaymasi", Assets.HiddenBrainrot.offset)
		tool:SetAttribute("TutusDonusu", Assets.HiddenBrainrot.rotation)
	end

	--[[
		HANGI MODEL KULLANILIR

		acilmis   -> brainrotun kendi modeli (mutasyonluysa "Gold ..." surumu)
		acilmamis -> Studio'daki hazir gizli model (Assets.HiddenBrainrot).
		             Beyaz hazirlanmistir; asagida kademe rengine boyanir.

		Ikisi de bulunamazsa duz kutu gorunumune dusulur.
		Acilmis model boyut sinifina gore olceklenir ve mutasyonu yoksa
		ustundeki efektler temizlenir.
	]]
	local model = if revealed
		then Assets.brainrotModel(item.name, item.mutation)
		else Assets.hiddenBrainrotModel()
	local handle: BasePart? = nil

	if model then
		--[[
			MODEL HAZIRLIGI HICBIR ZAMAN ESYAYI YOK ETMEMELI

			Once ortak tabana indirilir, sonra boyut carpani uygulanir;
			dogrudan olceklenirse pakette buyuk export edilmis modeller elde
			tasinamayacak kadar devlesiyor.

			Ama bu adimlarin (olcekleme, efekt temizligi, govdeye baglama)
			HERHANGI BIRI patlarsa hata Envanter'in tool uretimindeki
			pcall'una kadar firliyor ve brainrot cantada HIC OLUSMUYORDU:
			veri duruyor, esya yok. Kozmetik bir sorun esyayi yok ediyordu.

			Artik hata burada yakalanip modelden vazgeciliyor -- tool duz
			kutu gorunumuyle de olsa mutlaka uretiliyor.
		]]
		local prepared = model :: Model

		local ok, err = pcall(function()
			--[[
				BOYUT

				Acilmis brainrot boyut sinifina gore olceklenir
				(Tiny ceyrek .. Huge iki kat).

				Kimligi belirlenmemis olan ise HER ZAMAN AYNI boyda:
				kutunun buyuklugu icindekini ele vermesin, hepsi tek tip
				gorunsun. Bu yuzden carpan 1 sabit.
			]]
			local sizeScale = if revealed then Condition.scale(item.condition) else 1
			Assets.fitModel(prepared, Assets.BrainrotSize.toolSize, sizeScale)

			--[[
				Gizli modelin KENDI VFX'i tasarimin parcasi -- temizlenmez.
				Efekt temizligi yalnizca acilmis, mutasyonsuz brainrotlar
				icin: paket modellerindeki gomulu parcaciklar orada gurultu.
			]]
			if revealed and not Mutations.isSpecial(item.mutation) then
				Tools.stripEffects(prepared)
			end

			--[[
				Handle ile modelin GORSEL MERKEZI arasindaki fark, model
				parcalanmadan ONCE olculur. Kafada tasima bunu kullaniyor:
				paket modellerinde Handle govdenin ortasinda olmayabiliyor.
			]]
			local min, max = Assets.worldBounds(prepared)
			local primary = prepared.PrimaryPart
			if min and max and primary then
				tool:SetAttribute("MerkezKaymasi", (min + max) / 2 - primary.Position)
				tool:SetAttribute("YariYukseklik", (max.Y - min.Y) / 2)
			end

			handle = attachModel(tool, prepared)
		end)

		if not ok then
			Assets.warnOnce(
				`tool modeli: {item.name}`,
				`[Tools] "{item.name}" tool modeli hazirlanamadi, duz gorunume dusuldu -- {tostring(err)}`
			)

			-- Yarim kalmis parcalar tool'da kalmasin
			for _, child in tool:GetChildren() do
				if child:IsA("BasePart") then
					child:Destroy()
				end
			end
			pcall(function()
				prepared:Destroy()
			end)

			model = nil
			handle = nil
		end
	end

	if not handle then
		local body = Instance.new("Part")
		body.Name = "Handle"
		-- Model bulunamayinca kurulan yedek kutu da golge dusurmesin
		body.CastShadow = false
		body.Size = Vector3.new(2, 2, 2)
		body.TopSurface = Enum.SurfaceType.Smooth
		body.BottomSurface = Enum.SurfaceType.Smooth
		body.Parent = tool
		handle = body

		--[[
			Yedek kutunun olcusu de yazilir: model bulunamadiginda da
			kafada dogru yukseklikte dursun. Kutunun merkezi zaten
			Handle'in merkezi, o yuzden kayma sifir.
		]]
		tool:SetAttribute("MerkezKaymasi", Vector3.zero)
		tool:SetAttribute("YariYukseklik", body.Size.Y / 2)
	end

	for _, part in tool:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.Massless = true
			part.CanCollide = false

			if revealed then
				if not model then
					-- Model yoksa mutasyon rengiyle parlayan kutu
					part.Color = if Mutations.isSpecial(item.mutation) then mutationInfo.color else rarityInfo.color
					part.Material = Enum.Material.Neon
				end
			elseif not part:GetAttribute(Assets.HiddenBrainrot.keepAttribute) then
				--[[
					KIMLIGI BELIRLENMEMIS: KADEME RENGINE BOYA

					Gizli model BEYAZ hazirlanmistir; butun parcalari suzmenin
					kademe rengine cevriliyor. Tek istisna keepPart (Cube):
					o nitelikle isaretli oldugu icin buraya hic girmez ve
					modelin kendi gorunumunde kalir.

					MALZEMEYE DOKUNULMAZ -- modelin dokusu tasarimin parcasi.
					Yalnizca model HIC bulunamadiysa (duz yedek kutu) mat
					plastige cevrilir, yoksa kutu cig gorunur.
				]]
				part.Color = rarityInfo.color

				if not model then
					part.Material = Enum.Material.Plastic
					part.Reflectance = 0
				end

				-- Divine sabit renk degil: sari <-> beyaz parildar
				Divine.tagIf(part, item.rarity)
			end
		end
	end

	-- Kademeyi uzaktan belli eden kontur (Adornee sart: Toola cizilmez)
	if not revealed and handle then
		local highlight = Instance.new("Highlight")
		highlight.Name = "RarityHighlight"
		highlight.FillTransparency = 1
		highlight.OutlineColor = rarityInfo.color
		highlight.OutlineTransparency = 0
		highlight.Adornee = handle
		highlight.Parent = handle

		-- Divine konturu sabit degil: sari <-> beyaz parildar
		Divine.tagIf(highlight, item.rarity)
	end

	local mutationTip = if Mutations.isSpecial(item.mutation)
		then `  |  {mutationInfo.displayName} ({mutationInfo.multiplier}x)`
		else ""

	tool.ToolTip = if revealed
		then `{rarityInfo.displayName}  |  {conditionInfo.shortName} ({conditionInfo.multiplier}x){mutationTip}`
		else `Unidentified  |  {rarityInfo.displayName}  |  {conditionInfo.shortName}`

	--[[
		NEREDE TASINIYOR

		"head" -> kusanildiginda kafaya kaynaklanir (Assets.BrainrotHold)
		"hand" -> normal Roblox tutusu; yeri Assets.BrainrotGrip'ten ayarlanir
	]]
	if Assets.BrainrotHold.mode == "head" then
		tool.Equipped:Connect(function()
			holdOnHead(tool)
		end)
		tool.Unequipped:Connect(function()
			releaseHead(tool)
		end)
	else
		local grip = Assets.BrainrotGrip
		tool.Grip = CFrame.new(grip.position)
			* CFrame.Angles(
				math.rad(grip.rotation.X),
				math.rad(grip.rotation.Y),
				math.rad(grip.rotation.Z)
			)
	end

	--[[
		ELDE TASIRKEN DE ETIKET

		Base slotundakiyle AYNI modulden geliyor (Shared > Etiket), yani
		isim, carpanlar ve gelir birebir ayni gorunuyor. Brainrot cantada
		dururken Handle sahnede olmadigi icin yazi gorunmez; yalnizca
		kusanildiginda cikar ve yakindaki HERKES gorur.

		Yukseklik modelin gercek tepesinden hesaplanir: Handle ile gorsel
		merkez arasindaki fark (MerkezKaymasi) + yari yukseklik. Sabit bir
		deger verilseydi Tiny'de yazi tepede asili, Huge'da modelin icinde
		kalirdi.
	]]
	if revealed and handle then
		local shift = (tool:GetAttribute("MerkezKaymasi") :: Vector3?) or Vector3.zero
		local half = (tool:GetAttribute("YariYukseklik") :: number?) or 1

		Etiket.build(item, handle, shift.Y + half + Assets.BrainrotHold.headGap + 0.6)
	end

	setHoldAnimation(tool, Assets.Animations.brainrotHold)

	return tool
end

------------------------------------------------------------------
-- FUSE COIN
------------------------------------------------------------------

--[[
	Fuse makinesinden cikan coin.

	Brainrot gibi cantada fiziksel bir Tool olarak durur: eline alip Fuse
	makinesine koyabilir ya da bozdurucuya goturebilirsin.

	Gorunumu tamamen koddan uretiliyor -- model paketine bagli degil:
	kademe renginde parlayan yassi bir madeni para, uzerinde boyut kisaltmasi.
]]
function Tools.buildCoin(coin: any): Tool
	local rarityInfo = Rarity.get(coin.rarity)
	local conditionInfo = Condition.get(coin.condition)

	local mutationInfo = Mutations.get(coin.mutation)
	local special = Mutations.isSpecial(coin.mutation)

	--[[
		Coinin adi uc bilgiyi de tasir: "Gold Tiny Epic Coin".
		Ipucunda yalnizca CARPANLAR var -- ne ise yaradigini anlatan bir
		cumleye gerek yok, adi zaten her seyi soyluyor.
	]]
	local mutationTip = if special then `  |  {mutationInfo.displayName} {mutationInfo.multiplier}x` else ""

	local tool = Instance.new("Tool")
	tool.Name = Fuse.coinName(coin.rarity, coin.condition, coin.mutation)
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = `{conditionInfo.shortName} {conditionInfo.multiplier}x{mutationTip}`
	tool:SetAttribute("CoinUid", coin.uid)
	tool:SetAttribute("Rarity", coin.rarity)
	tool:SetAttribute("Condition", coin.condition)
	tool:SetAttribute("Mutation", coin.mutation)

	local body = Instance.new("Part")
	body.Name = "Handle"
	body.Shape = Enum.PartType.Cylinder
	-- Yassi disk: X kalinlik, Y/Z cap
	body.Size = Vector3.new(0.28, 2.2, 2.2)
	body.Color = Fuse.coinColor(coin.rarity)
	body.Material = Enum.Material.Neon
	body.CanCollide = false
	body.Massless = true
	body.Parent = tool

	--[[
		Govde kademe renginde kalir (coinin kimligi odur), ISIK ise mutasyon
		renginde yanar. Boylece Gold bir coin elde tasinirken uzaktan da
		ayirt edilir, ama kademe rengi bozulmaz.
	]]
	local glow = Instance.new("PointLight")
	glow.Name = "Parilti"
	glow.Color = if special then mutationInfo.color else rarityInfo.color
	glow.Range = 8
	glow.Brightness = 2
	glow.Parent = body

	-- Divine coin sabit renk degil: sari <-> beyaz parildar
	Divine.tagIf(body, coin.rarity)
	Divine.tagIf(glow, coin.rarity)

	return tool
end

------------------------------------------------------------------
-- LUCKY BLOCK
------------------------------------------------------------------

-- Tool'un cantada gorunen adi: "Golden Lucky Block (3)"
function Tools.luckyBlockLabel(tierId: string, count: number): string
	local tier = LuckyBlock.get(tierId)
	return if count > 1 then `{tier.displayName} ({count})` else tier.displayName
end

--[[
	Cantadaki Lucky Block.

	Tek bir Tool butun stogu temsil eder; adinda kac tane oldugu yazar.
	Eline alip TIKLAYINCA bir tanesi acilir ve cark doner.

	Model: ReplicatedStorage > Assets > LuckyBlocks icindeki ILK model.
	Yoksa sari parlayan bir kup uretilir.
]]
function Tools.buildLuckyBlock(tierId: string, count: number): Tool
	local tier = LuckyBlock.get(tierId)

	local tool = Instance.new("Tool")
	tool.Name = Tools.luckyBlockLabel(tierId, count)
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = `{tier.displayName} -- click to spin the wheel`
	tool:SetAttribute("LuckyBlock", true)
	tool:SetAttribute("LuckyTier", tier.id)

	local model = Assets.luckyBlockModel(tier.modelName, tier.order)
	local handle = if model then attachModel(tool, model) else nil

	-- Paketin kendi animasyonu elde tutulurken de donsun
	if handle then
		Assets.playAnimations(tool)
	end

	if not handle then
		local body = Instance.new("Part")
		body.Name = "Handle"
		body.Size = Vector3.new(1.8, 1.8, 1.8)
		body.Color = tier.color
		body.Material = Enum.Material.Neon
		body.TopSurface = Enum.SurfaceType.Smooth
		body.BottomSurface = Enum.SurfaceType.Smooth
		body.CanCollide = false
		body.Massless = true
		body.Parent = tool
		handle = body
	end

	if handle then
		local glow = Instance.new("PointLight")
		glow.Name = "Parilti"
		glow.Color = tier.color
		glow.Range = 10
		glow.Brightness = 2
		glow.Parent = handle
	end

	tool.Activated:Connect(function()
		local player = Players:GetPlayerFromCharacter(tool.Parent)
		local handler = Tools.onLuckyBlockUsed
		if player and handler then
			handler(player, tier.id)
		end
	end)

	return tool
end

------------------------------------------------------------------
-- YARDIMCILAR
------------------------------------------------------------------

-- Oyuncunun uzerindeki ve cantasindaki ayni isimli toollari siler.
function Tools.remove(player: Player, toolName: string)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, item in backpack:GetChildren() do
			if item:IsA("Tool") and item.Name == toolName then
				item:Destroy()
			end
		end
	end

	local char = player.Character
	if char then
		for _, item in char:GetChildren() do
			if item:IsA("Tool") and item.Name == toolName then
				item:Destroy()
			end
		end
	end
end

function Tools.has(player: Player, toolName: string): boolean
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and backpack:FindFirstChild(toolName) then
		return true
	end
	local char = player.Character
	return char ~= nil and char:FindFirstChild(toolName) ~= nil
end

--[[
	Tool SU AN ELDE MI?
	Tools.has cantadakini de sayar; bu ise yalnizca kusanilmis olani dogrular.
	Kazi ve GPS taramasi buna bakar.
]]
function Tools.equipped(player: Player, toolName: string): Tool?
	local char = player.Character
	if not char then
		return nil
	end
	local tool = char:FindFirstChild(toolName)
	return if tool and tool:IsA("Tool") then tool else nil
end

-- Elde tutulan brainrot Tool'u (varsa) ve uid'si
function Tools.equippedBrainrot(player: Player): (Tool?, string?)
	local char = player.Character
	if not char then
		return nil, nil
	end

	for _, item in char:GetChildren() do
		if item:IsA("Tool") and item:GetAttribute("BrainrotUid") then
			return item, item:GetAttribute("BrainrotUid") :: string
		end
	end

	return nil, nil
end

-- Belirli bir uid'ye ait brainrot Tool'unu bulur (canta veya el)
function Tools.findBrainrot(player: Player, uid: string): Tool?
	local backpack = player:FindFirstChildOfClass("Backpack")
	local places = { backpack, player.Character }

	for _, place in places do
		if place then
			for _, item in place:GetChildren() do
				if item:IsA("Tool") and item:GetAttribute("BrainrotUid") == uid then
					return item
				end
			end
		end
	end

	return nil
end

return Tools
