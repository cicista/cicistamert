--!strict
--[[
	AfkSans  (ModuleScript)
	Yeri: ServerScriptService > Modules > AfkSans

	AFK sans sistemi: yonca alanlari, yonca toplama, sans puani ve
	Leprechaun'daki alan yukseltmesi. Ayarlar Shared > AfkSans'ta.

	  AfkSans.baslat()        ServerScriptService > AfkSans cagirir (bir kez)
	  AfkSans.carpan(player)  sans puaninin carpani; KaziSistemi > luckFor
	                          ve deniz sansi bununla carpilir

	YONCALAR OYUNCUYA OZEL
	Her oyuncunun her alanda kendi YoncaSayisi yoncasi var. Konumlari
	sunucu seciyor ve istemciye yolluyor; modelleri istemci ciziyor. Ayni
	alanda duran iki oyuncu birbirinin yoncasini kapmaz.

	TOPLAMA
	  1. istemci yoncaya yaklasinca YoncaTopla(id) yollar
	  2. sunucu oyuncunun alanda ve yoncanin yaninda oldugunu dogrular
	  3. ToplamaSuresi sonra yine yanindaysa puan verilir, yonca silinip
	     yerine yenisi dogar ve YoncaSonuc ile istemciye bildirilir

	Her yonca alanin sabit puanini verir (Shared > AfkSans > puanYonca).
	Toplama suresi sunucuda sayildigi icin en fazla ToplamaSuresi'nde bir
	yonca alinabilir.

	Sunucudaki karakter konumu istemcininkinin biraz gerisinden gelir;
	kosarak yaklasan oyuncu sunucuda henuz uzakta gorunur. Mesafe kontrolu
	bu yuzden ERISIM_PAYI kadar genis tutuluyor, yoksa istek reddedilir ve
	istemci baska yoncaya kosup durur.

	LEPRECHAUN
	Haritada bu adla birden fazla NPC olabilir; hepsine prompt takilir,
	satin alma herhangi birinin yaninda yapilabilir.

	BARIKATLAR
	Sunucuda barikat hep kati. Alani acan oyuncunun istemcisi barikati
	kendi tarafinda gecilebilir yapiyor (karakter fizigi istemcide). Kilitli
	alana bir sekilde giren oyuncuya yonca verilmez.

	AFK YENIDEN BAGLANMA
	Roblox 20 dk girdisiz kalan oyuncuyu atiyor. Alandaki oyuncunun
	istemcisi YenidenBaglanSuresi dolunca AfkYenidenBaglan yollar; sunucu
	oyuncuyu AYNI sunucuya teleport eder (olmazsa herhangi bir sunucuya).
	Ayrilan her oyuncunun alan konumu DonusGecerlilik boyunca hatirlanir:
	ayni sunucuya donen oyuncu (bu yolla ya da atilip kendisi girerek)
	ayni noktaya isinlanir ve istemci toplamaya kendiliginden baslar.
	Baska sunucuya dusen oyuncu teleport verisindeki alanin ortasina
	konur. Alan kilitliyse hicbir sey yapilmaz.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("AfkSans"))
local Assets = require(Shared:WaitForChild("Assets"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))
-- Her yonca oyuncu XP'si de verir (Level sistemi)
local Seviye = require(script.Parent:WaitForChild("Seviye"))

local AfkSans = {}

type Yonca = {
	id: number,
	pos: Vector3,
	olcek: number,
	aci: number,
	yaricap: number,
}

type Toplama = {
	id: number,
	alan: string,
}

type Durum = {
	-- Ustunde durulan ACIK alan (kilitli alan nil sayilir)
	alan: string?,
	yoncalar: { [string]: { [number]: Yonca } },
	sayac: number,
	toplama: Toplama?,
}

local durumlar: { [Player]: Durum } = {}
local rng = Random.new()

-- Leprechaun'larin tutunma parcalari; satin alma herhangi birinin yaninda yapilir
local npcParcalari: { [BasePart]: boolean } = {}
local PROMPT_MESAFE = 12
local ISTEK_MESAFE = 24
-- Alan kontrol araligi (saniye)
local TARAMA = 0.4
-- Sunucu dogrulamasinda gecikme payi (stud); bkz. ust aciklama
local ERISIM_PAYI = 6

local HATA = Color3.fromRGB(255, 90, 90)
local UYARI = Color3.fromRGB(255, 200, 90)

------------------------------------------------------------------
-- CARPAN
------------------------------------------------------------------
function AfkSans.carpan(player: Player): number
	local data = PlayerData.get(player)
	return if data then Ayar.carpan(data.afkPuan) else 1
end

-- Oyuncu bu siradaki alana sahip mi (Rot sirasi ya da Robux)
local function sahipMi(data: any, sira: number): boolean
	return Ayar.sahip(sira, data.afkSeviye, data.afkOzel)
end

local function nitelikleriYaz(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	player:SetAttribute(Ayar.PuanNiteligi, math.floor(data.afkPuan))
	player:SetAttribute(Ayar.SeviyeNiteligi, data.afkSeviye)
	-- Robux alanlari: istemci barikati buna gore acar
	local ozel = {}
	for id in data.afkOzel do
		table.insert(ozel, id)
	end
	table.sort(ozel)
	player:SetAttribute(Ayar.OzelNiteligi, table.concat(ozel, ","))
end

------------------------------------------------------------------
-- ALANLAR
------------------------------------------------------------------
local function zemin(id: string): BasePart?
	local klasor = Workspace:FindFirstChild(Ayar.KlasorAdi)
	local node = klasor and klasor:FindFirstChild(id)
	return if node and node:IsA("BasePart") then node else nil
end

local function kok(player: Player): BasePart?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Oyuncunun ustunde durdugu alan ve o alanin acik olup olmadigi
local function alanBul(player: Player): (string?, boolean)
	local root = kok(player)
	local data = PlayerData.get(player)
	if not root or not data then
		return nil, false
	end

	for i, alan in Ayar.Alanlar do
		local z = zemin(alan.id)
		if z and Ayar.icinde(z, root.Position) then
			return alan.id, sahipMi(data, i)
		end
	end
	return nil, false
end

--[[
	Yonca modelinin yaricapi (olcek 1'de). Yoncalar arasi bosluk ve toplama
	mesafesi buna gore hesaplaniyor. Model yoksa istemcinin yedek yoncasinin
	boyu (1 stud).
]]
local yaricaplar: { [string]: number } = {}

local function tabanYaricap(id: string): number
	local r = yaricaplar[id]
	if r then
		return r
	end

	r = 1
	local model = Assets.cloverModel(id)
	if model then
		local _, boy = model:GetBoundingBox()
		r = math.max(math.max(boy.X, boy.Z) / 2, 0.5)
		model:Destroy()
	end

	yaricaplar[id] = r
	return r :: number
end

--[[
	Yoncanin cikamayacagi yerler: zeminin altindaki parcalar (Fences vb.).
	Border ve Barricade HARIC: ikisi de butun alani iceren buyuk kutular;
	engel sayilsalar hicbir yonca cikamazdi. Barikat acilan oyuncuda zaten
	gorunmez ve gecilebilir.
]]
local function engelDegil(node: Instance): boolean
	local ad = string.lower(node.Name)
	return string.find(ad, "border", 1, true) ~= nil or string.find(ad, "barricade", 1, true) ~= nil
end

local function engeller(z: BasePart): { Instance }
	local liste = {}
	for _, node in z:GetDescendants() do
		if not node:IsA("BasePart") then
			continue
		end

		-- Barikat Model olabilir: parcasinin adi degil, atasinin adi tutar
		local atla = false
		local ata: Instance? = node
		while ata and ata ~= z do
			if engelDegil(ata) then
				atla = true
				break
			end
			ata = ata.Parent
		end

		if not atla then
			table.insert(liste, node)
		end
	end
	return liste
end

local function yeniYonca(durum: Durum, alanId: string, z: BasePart): Yonca?
	local mevcut = durum.yoncalar[alanId]
	local tabanR = tabanYaricap(alanId)
	local boy = z.Size

	local liste = engeller(z)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = liste

	for deneme = 1, 40 do
		local olcek = rng:NextNumber(Ayar.OlcekMin, Ayar.OlcekMax)
		local r = tabanR * olcek
		local pay = Ayar.KenarPayi + r
		local yariX = math.max(boy.X / 2 - pay, 0)
		local yariZ = math.max(boy.Z / 2 - pay, 0)

		local nokta = z.CFrame * CFrame.new(rng:NextNumber(-yariX, yariX), boy.Y / 2, rng:NextNumber(-yariZ, yariZ))
		local pos = nokta.Position

		-- Son denemelerde bosluk sarti gevsiyor: alan kalabaliksa yine de dolsun
		local aralik = if deneme > 30 then 0 else Ayar.MinAralik
		local uygun = true
		for _, diger in mevcut do
			local fark = (diger.pos - pos) * Vector3.new(1, 0, 1)
			if fark.Magnitude < r + diger.yaricap + aralik then
				uygun = false
				break
			end
		end

		if uygun and #liste > 0 then
			local carpisan = Workspace:GetPartBoundsInRadius(pos + z.CFrame.UpVector * 1.5, r + 0.5, params)
			uygun = #carpisan == 0
		end

		if uygun then
			durum.sayac += 1
			local yonca: Yonca = {
				id = durum.sayac,
				pos = pos,
				olcek = olcek,
				aci = rng:NextNumber(0, math.pi * 2),
				yaricap = r,
			}
			mevcut[yonca.id] = yonca
			return yonca
		end
	end

	return nil
end

local function doldur(durum: Durum, alanId: string)
	local z = zemin(alanId)
	if not z then
		return
	end

	durum.yoncalar[alanId] = durum.yoncalar[alanId] or {}
	local sayi = 0
	for _ in durum.yoncalar[alanId] do
		sayi += 1
	end

	for _ = sayi + 1, Ayar.YoncaSayisi do
		if not yeniYonca(durum, alanId, z) then
			break
		end
	end
end

local function paket(alanId: string, yonca: Yonca)
	return {
		id = yonca.id,
		alan = alanId,
		pos = yonca.pos,
		olcek = yonca.olcek,
		aci = yonca.aci,
		yaricap = yonca.yaricap,
	}
end

--[[
	BUTUN ALANLARIN YONCALARI HEP GORUNUR

	Oyuncu hazir olunca her alan doldurulur ve hepsinin listesi yollanir;
	kilitli alanlarin yoncalari da gorunur (oyuncuyu acmaya ozendirir).
	Toplama yalnizca ustunde durulan ACIK alanda yapilir.
]]
local function hepsiniYolla(player: Player, durum: Durum)
	local YoncaListesi = Net.event("YoncaListesi")
	for _, alan in Ayar.Alanlar do
		doldur(durum, alan.id)
		local liste = {}
		for _, yonca in durum.yoncalar[alan.id] or {} do
			table.insert(liste, paket(alan.id, yonca))
		end
		YoncaListesi:FireClient(player, alan.id, liste)
	end
	Net.event("AfkAlan"):FireClient(player, durum.alan)
end

local function tara()
	for player, durum in durumlar do
		local alanId, acik = alanBul(player)
		local yeni = if acik then alanId else nil

		if yeni ~= durum.alan then
			durum.alan = yeni
			durum.toplama = nil
			Net.event("AfkAlan"):FireClient(player, yeni)
		end
	end
end

------------------------------------------------------------------
-- TOPLAMA
------------------------------------------------------------------
local function yaninda(player: Player, yonca: Yonca, pay: number): boolean
	local root = kok(player)
	if not root then
		return false
	end
	local fark = (root.Position - yonca.pos) * Vector3.new(1, 0, 1)
	return fark.Magnitude <= yonca.yaricap + Ayar.Erisim + pay
end

local function bitir(player: Player, durum: Durum, is: Toplama)
	if durum.toplama ~= is then
		return
	end
	durum.toplama = nil

	local YoncaSonuc = Net.event("YoncaSonuc")
	local yoncalar = durum.yoncalar[is.alan]
	local yonca = yoncalar and yoncalar[is.id]
	local data = PlayerData.get(player)
	local alan = Ayar.get(is.alan)

	if not yonca or not data or not alan or durum.alan ~= is.alan or not yaninda(player, yonca, ERISIM_PAYI + 2) then
		YoncaSonuc:FireClient(player, is.id, false)
		return
	end

	local once = data.afkPuan
	data.afkPuan = math.min(Ayar.MaxPuan, data.afkPuan + alan.puanYonca)
	local kazanc = data.afkPuan - once
	nitelikleriYaz(player)
	-- Her yonca oyuncu XP'si de verir (Level sistemi)
	Seviye.xpVer(player, Ayar.YoncaXp)

	yoncalar[is.id] = nil
	local z = zemin(is.alan)
	-- Yeni yonca kurulurken hata olsa bile istemci cevapsiz kalmasin (bar takili kalirdi)
	local yeni: Yonca? = nil
	if z then
		local ok, sonuc = pcall(yeniYonca, durum, is.alan, z)
		if ok then
			yeni = sonuc
		else
			warn(`[AfkSans] yeni yonca kurulamadi: {sonuc}`)
		end
	end

	YoncaSonuc:FireClient(player, is.id, true, math.floor(kazanc), if yeni then paket(is.alan, yeni) else nil)
end

local function toplaIstegi(player: Player, id: any)
	local durum = durumlar[player]
	if not durum then
		return
	end

	-- nil: oyuncu yoncadan uzaklasti, toplama birakiliyor
	if id == nil then
		durum.toplama = nil
		return
	end

	if type(id) ~= "number" then
		return
	end

	local alanId = durum.alan
	local yoncalar = alanId and durum.yoncalar[alanId]
	local yonca = yoncalar and yoncalar[id]
	if not alanId or not yonca or not yaninda(player, yonca, ERISIM_PAYI) then
		-- Yonca sunucuda hic yoksa (5. deger true) istemci onu sahneden de siler
		local yok = true
		for _, liste in durum.yoncalar do
			if liste[id] then
				yok = false
				break
			end
		end
		Net.event("YoncaSonuc"):FireClient(player, id, false, 0, nil, yok)
		return
	end

	local mevcut = durum.toplama
	if mevcut and mevcut.id == id then
		return
	end

	local is: Toplama = { id = id, alan = alanId }
	durum.toplama = is
	task.delay(Ayar.ToplamaSuresi, bitir, player, durum, is)
end

------------------------------------------------------------------
-- LEPRECHAUN (alan yukseltmesi)
------------------------------------------------------------------
local function panelVerisi(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return nil
	end

	local alanlar = {}
	for i, alan in Ayar.Alanlar do
		table.insert(alanlar, {
			id = alan.id,
			displayName = alan.displayName,
			puanYonca = alan.puanYonca,
			fiyat = alan.fiyat,
			owned = sahipMi(data, i),
			-- Robux alani sirayi beklemez; Rot alani yalnizca siradaki
			buyable = if alan.robux then not sahipMi(data, i) else i == data.afkSeviye + 1,
			-- Doluysa dugme Robux ile satin alir (Shared > RobuxMagaza anahtari)
			robux = alan.robux,
			kademe = Ayar.kademe(alan.id),
		})
	end

	return {
		puan = math.floor(data.afkPuan),
		rot = data.rot,
		alanlar = alanlar,
	}
end

local function npcYaninda(player: Player): boolean
	local root = kok(player)
	if not root then
		return false
	end
	for parca in npcParcalari do
		if parca.Parent and (root.Position - parca.Position).Magnitude <= ISTEK_MESAFE then
			return true
		end
	end
	return false
end

local function satinAl(player: Player, alanId: any)
	if type(alanId) ~= "string" or not npcYaninda(player) then
		return
	end

	local sira = Ayar.sira(alanId)
	local data = PlayerData.get(player)
	if not sira or not data then
		return
	end

	local alan = Ayar.Alanlar[sira]
	local Bildirim = Net.event("Bildirim")

	-- Robux alani Rot ile alinamaz: istemci RobuxUrunAl yollar (bkz. AfkSans.robuxlaAc)
	if alan.robux then
		return
	end

	if sira <= data.afkSeviye then
		Bildirim:FireClient(player, `{alan.displayName} is already unlocked.`, Color3.fromRGB(180, 200, 220))
		return
	end

	if sira ~= data.afkSeviye + 1 then
		Bildirim:FireClient(player, "Unlock the previous clover field first.", UYARI)
		return
	end

	if data.rot < alan.fiyat then
		Bildirim:FireClient(player, `Not enough Rot! You need {Format.short(alan.fiyat - data.rot)} more Rot.`, HATA)
		return
	end

	PlayerData.addRot(player, -alan.fiyat)
	data.afkSeviye = sira
	nitelikleriYaz(player)

	Envanter.push(player)
	Net.event("LeprechaunAc"):FireClient(player, panelVerisi(player))
	Bildirim:FireClient(player, `{alan.displayName} unlocked! The barricade is gone.`, Rarity.color(Ayar.kademe(alan.id)))
end

--[[
	ROBUX ALANI  --  RobuxMagaza'nin ProcessReceipt'i cagirir (bkz.
	RobuxMagaza.server > urunVer). BEKLEMEZ, yalnizca kaydi degistirir.
	Zaten acik alana ikinci fis gelirse bir sey yapmaz (pencere acilmadan
	once RobuxMagaza bunu ayrica denetliyor).
]]
function AfkSans.robuxlaAc(player: Player, alanId: string)
	local alan = Ayar.get(alanId)
	local data = PlayerData.get(player)
	if not alan or not alan.robux then
		error(`robux alani degil: {alanId}`)
	end
	if not data then
		error("oyuncu verisi yok")
	end

	data.afkOzel[alanId] = true
	nitelikleriYaz(player)

	-- Leprechaun paneli aciksa tazelensin
	local veri = panelVerisi(player)
	if veri then
		Net.event("LeprechaunAc"):FireClient(player, veri)
	end
	Net.event("Bildirim"):FireClient(
		player,
		`{alan.displayName} unlocked! The barricade is gone.`,
		Rarity.color(Ayar.kademe(alan.id))
	)
end

-- Bu Robux alani zaten acik mi (satin alma penceresi acilmadan once)
function AfkSans.robuxAlaniAcik(player: Player, alanId: string): boolean
	local data = PlayerData.get(player)
	return data ~= nil and data.afkOzel[alanId] == true
end

local function tutunmaParcasi(node: Instance): BasePart?
	if node:IsA("BasePart") then
		return node
	end
	if node:IsA("Model") then
		if node.PrimaryPart then
			return node.PrimaryPart
		end
		local root = node:FindFirstChild("HumanoidRootPart", true)
		if root and root:IsA("BasePart") then
			return root
		end
	end
	return node:FindFirstChildWhichIsA("BasePart", true)
end

-- Bu adla butun NPC'lere prompt takar; zaten takiliysa atlar. Kac tane bagli oldugunu dondurur
local function npcBagla(): number
	local hedef = string.lower(Ayar.NpcAdi)
	local sayi = 0

	-- Silinmis NPC'ler listeden cikar
	for parca in npcParcalari do
		if not parca.Parent then
			npcParcalari[parca] = nil
		end
	end

	for _, node in Workspace:GetDescendants() do
		if string.lower(node.Name) ~= hedef then
			continue
		end

		local parca = tutunmaParcasi(node)
		if not parca then
			continue
		end
		sayi += 1
		if npcParcalari[parca] and parca:FindFirstChild("LeprechaunPrompt") then
			continue
		end

		npcParcalari[parca] = true
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "LeprechaunPrompt"
		prompt.ActionText = "Open"
		prompt.ObjectText = "Clover Fields"
		prompt.HoldDuration = 0.2
		prompt.MaxActivationDistance = PROMPT_MESAFE
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = parca
		prompt.Triggered:Connect(function(player)
			local veri = panelVerisi(player)
			if veri then
				Net.event("LeprechaunAc"):FireClient(player, veri)
			end
		end)

		print(`[AfkSans] Leprechaun baglandi: {parca:GetFullName()}`)
	end
	return sayi
end

------------------------------------------------------------------
-- AFK YENIDEN BAGLANMA (bkz. ust aciklama)
------------------------------------------------------------------
type Donus = { alan: string, pos: Vector3?, zaman: number }

-- UserId -> ayrildigi andaki alan ve konum (yalnizca bu sunucuda)
local donusler: { [number]: Donus } = {}
-- Teleportu baslatilmis oyuncular (ikinci istek yok sayilir)
local baglananlar: { [Player]: boolean } = {}

local function donusuHatirla(player: Player)
	local durum = durumlar[player]
	if not durum or not durum.alan then
		return
	end
	local root = kok(player)
	donusler[player.UserId] = {
		alan = durum.alan,
		pos = if root then root.Position else nil,
		zaman = os.clock(),
	}
end

local function teleportEt(player: Player, ayniSunucu: boolean): boolean
	local secenek = Instance.new("TeleportOptions")
	if ayniSunucu then
		secenek.ServerInstanceId = game.JobId
	end
	-- Yalnizca alan adi gidiyor; konumu donulen sunucu kendisi seciyor
	local durum = durumlar[player]
	local alan = donusler[player.UserId] and donusler[player.UserId].alan or (durum and durum.alan)
	secenek:SetTeleportData({ [Ayar.TeleportVeriAnahtari] = alan or true })

	local ok, hata = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player }, secenek)
	end)
	if not ok then
		warn(`[AfkSans] {player.Name} yeniden baglanamadi (ayni sunucu: {ayniSunucu}): {hata}`)
	end
	return ok
end

local function yenidenBaglan(player: Player)
	local durum = durumlar[player]
	-- Yalnizca acik bir alanda duran oyuncu; istemcinin "AFK'yim" demesi yeterli
	-- cunku bu istek yalnizca oyuncunun KENDISINI teleport ediyor
	if not durum or not durum.alan or baglananlar[player] then
		return
	end
	baglananlar[player] = true
	donusuHatirla(player)

	if not teleportEt(player, true) and not teleportEt(player, false) then
		baglananlar[player] = nil
	end
end

-- Teleport baslayip sonra patlarsa (sunucu dolu vb.) herhangi bir sunucuya
local function teleportPatladi(player: Player, _sonuc: Enum.TeleportResult, mesaj: string, _yer: number, secenek: TeleportOptions?)
	if not baglananlar[player] or not player.Parent then
		return
	end
	warn(`[AfkSans] {player.Name} teleportu basarisiz: {mesaj}`)
	if secenek and secenek.ServerInstanceId ~= "" and teleportEt(player, false) then
		return
	end
	baglananlar[player] = nil
end

-- Donulecek alan ve konum: once bu sunucunun hafizasi, yoksa teleport verisi
local function donusBul(player: Player): (string?, Vector3?)
	local kayit = donusler[player.UserId]
	donusler[player.UserId] = nil
	if kayit and os.clock() - kayit.zaman <= Ayar.DonusGecerlilik then
		return kayit.alan, kayit.pos
	end

	local ok, katilim = pcall(function()
		return player:GetJoinData()
	end)
	local veri = if ok and type(katilim) == "table" then katilim.TeleportData else nil
	if type(veri) == "table" and katilim.SourcePlaceId == game.PlaceId then
		local alan = veri[Ayar.TeleportVeriAnahtari]
		if type(alan) == "string" then
			return alan, nil
		end
	end
	return nil, nil
end

local function afkSpotunaDon(player: Player)
	local alanId, pos = donusBul(player)
	if not alanId then
		return
	end

	local sira = Ayar.sira(alanId)
	local data = PlayerData.get(player)
	local z = zemin(alanId)
	-- Kilitli (ya da artik olmayan) alana isinlanilmaz
	if not sira or not data or not sahipMi(data, sira) or not z then
		return
	end

	local sinir = os.clock() + 20
	while player.Parent and not kok(player) and os.clock() < sinir do
		task.wait(0.2)
	end
	local char = player.Character
	if not player.Parent or not char or not kok(player) then
		return
	end

	-- Kayitli konum HumanoidRootPart'inki; alanin disinda kaldiysa zeminin ortasi
	local hedef = if pos and Ayar.icinde(z, pos)
		then pos + Vector3.new(0, 0.5, 0)
		else (z.CFrame * CFrame.new(0, z.Size.Y / 2 + 3.5, 0)).Position
	char:PivotTo(CFrame.new(hedef))
end

------------------------------------------------------------------
-- BASLAT
------------------------------------------------------------------
local function oyuncuHazirla(player: Player)
	if not PlayerData.bekle(player) or not player.Parent then
		return
	end

	nitelikleriYaz(player)
	local durum: Durum = {
		alan = nil,
		yoncalar = {},
		sayac = 0,
		toplama = nil,
	}
	durumlar[player] = durum
	hepsiniYolla(player, durum)
	afkSpotunaDon(player)
end

-- Istemci script'i sonradan baslarsa (ya da yeniden yuklenirse) listeleri yeniden ister
local sonIstek: { [Player]: number } = {}
local ISTEK_ARALIGI = 2

local function listeIstegi(player: Player)
	local simdi = os.clock()
	if simdi - (sonIstek[player] or 0) < ISTEK_ARALIGI then
		return
	end
	sonIstek[player] = simdi

	local durum = durumlar[player]
	if durum then
		hepsiniYolla(player, durum)
	end
end

local basladi = false

function AfkSans.baslat()
	if basladi then
		return
	end
	basladi = true

	local klasor = Workspace:FindFirstChild(Ayar.KlasorAdi)
	if not klasor then
		warn(`[AfkSans] Workspace > {Ayar.KlasorAdi} bulunamadi; yonca alanlari calismaz`)
	else
		for _, alan in Ayar.Alanlar do
			if not zemin(alan.id) then
				warn(`[AfkSans] {Ayar.KlasorAdi} > {alan.id} bir Part degil ya da yok`)
			end
		end

		--[[
			CITLER GECILEBILIR: Fences icindeki her parca carpismaz yapilir
			(sunucuda, herkes icin). Sonradan eklenen cit parcalari da.
			Yoncalar yine citlerin ustunde cikmaz (bkz. engeller).
		]]
		local function citMi(node: Instance): boolean
			local ata: Instance? = node
			while ata and ata ~= klasor do
				if string.find(string.lower(ata.Name), "fence", 1, true) then
					return true
				end
				ata = ata.Parent
			end
			return false
		end
		local function citiAc(node: Instance)
			if node:IsA("BasePart") and citMi(node) then
				node.CanCollide = false
			end
		end
		for _, node in klasor:GetDescendants() do
			citiAc(node)
		end
		klasor.DescendantAdded:Connect(citiAc)
	end

	Net.event("YoncaTopla").OnServerEvent:Connect(toplaIstegi)
	Net.event("AfkAlanAl").OnServerEvent:Connect(satinAl)
	Net.event("YoncaIste").OnServerEvent:Connect(listeIstegi)
	Net.event("AfkYenidenBaglan").OnServerEvent:Connect(yenidenBaglan)
	TeleportService.TeleportInitFailed:Connect(teleportPatladi)

	Players.PlayerAdded:Connect(oyuncuHazirla)
	for _, player in Players:GetPlayers() do
		task.spawn(oyuncuHazirla, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		-- Atilan ya da cikan oyuncu ayni sunucuya donerse ayni noktaya konur
		donusuHatirla(player)
		durumlar[player] = nil
		sonIstek[player] = nil
		baglananlar[player] = nil
	end)

	-- Eski donus kayitlari birikmesin
	task.spawn(function()
		while true do
			task.wait(60)
			local simdi = os.clock()
			for userId, kayit in donusler do
				if simdi - kayit.zaman > Ayar.DonusGecerlilik then
					donusler[userId] = nil
				end
			end
		end
	end)

	-- NPC sonradan gelebilir (Rojo, akis, elle ekleme): eklenince yeniden baglanir
	if npcBagla() == 0 then
		warn(`[AfkSans] '{Ayar.NpcAdi}' haritada bulunamadi; eklenince baglanacak`)
	end
	Workspace.DescendantAdded:Connect(function(node)
		if string.lower(node.Name) == string.lower(Ayar.NpcAdi) then
			task.delay(0.5, npcBagla)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(TARAMA)
			tara()
		end
	end)
end

return AfkSans
