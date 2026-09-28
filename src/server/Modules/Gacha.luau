--!strict
--[[
	Gacha  (ModuleScript)
	Yeri: ServerScriptService > Modules > Gacha

	Yumurta gachasinin sunucu tarafi. Ayarlar Shared > Gacha'da.

	  Gacha.baslat()         ServerScriptService > Gacha cagirir (bir kez):
	                         NPC'ye prompt takar, admin denemesini dinler
	  Gacha.ver(player)      bir cevirme: kademeyi secer, yumurtayi cantaya
	                         yazar ve gosteriyi baslatir. BEKLEMEZ -- Robux
	                         fisi (ProcessReceipt) bunu cagiriyor.

	AKIS
	  1. NPC'nin promptu -> GachaAc (pencere acilir, admin ise deneme dugmesi)
	  2. Istemci RobuxUrunAl("Gacha") -> RobuxMagaza penceresi acar
	  3. Oyuncu oderse ProcessReceipt -> Gacha.ver
	  4. Yumurta HEMEN kayda yazilir (cark donerken oyuncu cikarsa kaybolmaz)
	     ama cantaya ve ekrana cark DURUNCA yansir; surpriz bozulmasin.
	  5. GachaSonuc ile istemci carki cevirir; sure dolunca burada
	     FuseExplosion + kademe renginde FuseVFX patlar (Modules > Patlama).

	CANTA DOLU OLSA DA VERILIR
	Para odenmis ve geri verilemiyor; yumurta kapasite siniri gozetilmeden
	eklenir. Pencere acilmadan once canta dolu mu diye ayrica bakiliyor
	(bkz. RobuxMagaza.server) -- oyuncu once yer acsin.

	UST USTE ALIM
	Cark donerken ikinci bir fis gelirse ikinci gosteri birincisi bitince
	baslar (sira). Yumurtalarin ikisi de fis aninda kayda yazilmistir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("Gacha"))
local Condition = require(Shared:WaitForChild("Condition"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Net = require(Shared:WaitForChild("Net"))
local OyunConfig = require(Shared:WaitForChild("OyunConfig"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))
local Patlama = require(script.Parent:WaitForChild("Patlama"))

local Gacha = {}

local rng = Random.new()

-- Oyuncunun sirada bekleyen gosterileri (bkz. UST USTE ALIM)
local mesgul: { [Player]: boolean } = {}

------------------------------------------------------------------
-- YETKI  (AdminPanel ile ayni kural: Shared > OyunConfig > Admin)
------------------------------------------------------------------
local function adminMi(player: Player): boolean
	local A = OyunConfig.Admin
	if A.allowInStudio and RunService:IsStudio() then
		return true
	end
	for _, id in A.userIds do
		if player.UserId == id then
			return true
		end
	end
	return false
end

------------------------------------------------------------------
-- GOSTERI
------------------------------------------------------------------
local function gosteri(player: Player, rarityId: string)
	-- Onceki cevirme bitene kadar sira bekle
	while mesgul[player] and player.Parent do
		task.wait(0.2)
	end
	if not player.Parent then
		return
	end
	mesgul[player] = true

	local ad = Ayar.yumurtaAdi(Rarity.displayName(rarityId))
	Net.event("GachaSonuc"):FireClient(player, { rarity = rarityId, ad = ad })

	-- Yumurtanin elde edildigi an: FuseExplosion + kademe renginde FuseVFX
	task.wait(Ayar.toplamSure())
	if player.Parent then
		Patlama.oynat(player, rarityId)

		Envanter.syncBrainrots(player)
		Envanter.push(player)
		Net.event("Bildirim"):FireClient(player, `You got a {ad}!`, Rarity.color(rarityId))
	end

	-- Sonuc ekranda biraz dursun; sonraki cevirme hemen ustune binmesin
	task.wait(Ayar.SonucSuresi)
	mesgul[player] = nil
end

--[[
	Bir cevirme. Yumurtayi kayda yazar ve gosteriyi arka planda baslatir.
	Hata verirse (veri yok) cagiran taraf bunu gorur: fis geri alinir.
]]
function Gacha.ver(player: Player)
	local data = PlayerData.get(player)
	if not data then
		error("oyuncu verisi yok")
	end

	local rarityId = Ayar.sec(rng)
	-- Kazidakiyle ayni: boyut ve mutasyon da cikar, mutasyon acilana kadar gizli
	local condition = Condition.roll(rng)
	local mutation = Mutations.roll(rng)

	-- Ada yok: isim acilinca o kademenin butun havuzundan secilir
	local item = PlayerData.addBrainrot(player, rarityId, condition, mutation, nil, true)
	if not item then
		error("yumurta cantaya eklenemedi")
	end

	task.spawn(gosteri, player, rarityId)
end

------------------------------------------------------------------
-- NPC
------------------------------------------------------------------
local npcParcalari: { [BasePart]: boolean } = {}

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

local function pencereyiAc(player: Player)
	Net.event("GachaAc"):FireClient(player, { admin = adminMi(player) })
end

-- Bu adla butun NPC'lere prompt takar; zaten takiliysa atlar. Kac tane bulundugunu dondurur
local function npcBagla(): number
	local hedef = string.lower(Ayar.NpcAdi)
	local sayi = 0

	for parca in npcParcalari do
		if not parca.Parent then
			npcParcalari[parca] = nil
		end
	end

	for _, node in Workspace:GetDescendants() do
		if string.lower(node.Name) ~= hedef or not (node:IsA("Model") or node:IsA("BasePart")) then
			continue
		end

		local parca = tutunmaParcasi(node)
		if not parca then
			continue
		end
		sayi += 1
		if npcParcalari[parca] and parca:FindFirstChild("GachaPrompt") then
			continue
		end

		npcParcalari[parca] = true
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "GachaPrompt"
		prompt.ActionText = "Open"
		prompt.ObjectText = "Egg Gacha"
		prompt.HoldDuration = 0.2
		prompt.MaxActivationDistance = Ayar.PromptMesafe
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = parca
		prompt.Triggered:Connect(pencereyiAc)

		print(`[Gacha] NPC baglandi: {parca:GetFullName()}`)
	end
	return sayi
end

------------------------------------------------------------------
-- BASLAT
------------------------------------------------------------------
local basladi = false

function Gacha.baslat()
	if basladi then
		return
	end
	basladi = true

	--[[
		ADMIN DENEMESI: pencerede yalnizca adminlere gorunen dugme.
		Ucretsiz bir cevirme; yetki burada, sunucuda denetleniyor.
	]]
	Net.event("GachaDene").OnServerEvent:Connect(function(player)
		if not adminMi(player) then
			return
		end
		if mesgul[player] then
			Net.event("Bildirim"):FireClient(player, "Wait for the current spin to finish.", Color3.fromRGB(255, 200, 90))
			return
		end
		local ok, hata = pcall(Gacha.ver, player)
		if not ok then
			warn(`[Gacha] admin denemesi basarisiz ({player.Name}): {hata}`)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		mesgul[player] = nil
	end)

	-- NPC sonradan gelebilir (akis, elle ekleme): eklenince yeniden baglanir
	if npcBagla() == 0 then
		warn(`[Gacha] '{Ayar.NpcAdi}' NPC'si haritada bulunamadi; eklenince baglanacak`)
	end
	Workspace.DescendantAdded:Connect(function(node)
		if string.lower(node.Name) == string.lower(Ayar.NpcAdi) then
			task.delay(0.5, npcBagla)
		end
	end)
end

return Gacha
