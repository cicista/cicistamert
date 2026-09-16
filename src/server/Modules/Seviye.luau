--!strict
--[[
	LEVEL SISTEMI  --  sunucu tarafi

	Ayarlar (XP miktarlari, gereken XP, oduller) Shared > Seviye'de.

	KULLANIM
	  Seviye.xpVer(player, Seviye.XP.ore)
	  Seviye.xpVer(player, Seviye.XP.beam)
	  Seviye.carpan(player)   -- kazi sansina carpilan kalici level bonusu

	XP yalnizca sunucuda verilir; istemci sadece gosterir (SeviyeDurum,
	SeviyeAtladi). Leaderstats'taki Level sutunu da veriden okunur.

	Leaderstats bu modulu Net.init()'ten SONRA require eder: karakter
	gelince bas ustu yazisini kuran baglantilar ancak o zaman kurulur.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Fonts = require(Shared:WaitForChild("Fonts"))
local Net = require(Shared:WaitForChild("Net"))
local SeviyeAyar = require(Shared:WaitForChild("Seviye"))
local Hiz = require(Shared:WaitForChild("Hiz"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))

local Bildirim = Net.event("Bildirim")
local SeviyeDurum = Net.event("SeviyeDurum")
local SeviyeAtladi = Net.event("SeviyeAtladi")
local SeviyeAc = Net.event("SeviyeAc")

local ETIKET_ADI = "SeviyeEtiketi"

local Seviye = {}

-- Diger scriptler ayarlara ayrica require yazmadan ulassin
Seviye.XP = SeviyeAyar.XP

------------------------------------------------------------------
-- BAS USTU YAZISI  ("Lv. 12", altinda daha kucuk "Speed 57")
------------------------------------------------------------------
local ETIKET_EN = 140
local LEVEL_BOY = 30
local HIZ_BOY = 20

local function etiketGuncelle(player: Player)
	local data = PlayerData.get(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not data or not head then
		return
	end

	local etiket = head:FindFirstChild(ETIKET_ADI) :: BillboardGui?
	if not etiket then
		local yeni = Instance.new("BillboardGui")
		yeni.Name = ETIKET_ADI
		yeni.Size = UDim2.fromOffset(ETIKET_EN, LEVEL_BOY + HIZ_BOY)
		-- Roblox'un kendi isim yazisinin biraz ustunde; hiz satiri eklenince
		-- kutu asagi uzadigi icin merkez biraz yukari alindi
		yeni.StudsOffset = Vector3.new(0, 2.8, 0)
		yeni.MaxDistance = 90
		yeni.LightInfluence = 0
		yeni.Parent = head

		local yazi = Instance.new("TextLabel")
		yazi.Name = "Yazi"
		yazi.Size = UDim2.new(1, 0, 0, LEVEL_BOY)
		yazi.BackgroundTransparency = 1
		yazi.TextColor3 = Color3.fromRGB(255, 215, 40)
		yazi.TextSize = 22
		Fonts.apply(yazi)
		yazi.Parent = yeni

		local kontur = Instance.new("UIStroke")
		kontur.Color = Color3.new(0, 0, 0)
		kontur.Thickness = 2
		kontur.Parent = yazi

		-- Hiz seviyesi: levelin altinda, ondan kucuk; rengi seviyeyle isinir
		local hizYazi = Instance.new("TextLabel")
		hizYazi.Name = "Hiz"
		hizYazi.Position = UDim2.fromOffset(0, LEVEL_BOY - 2)
		hizYazi.Size = UDim2.new(1, 0, 0, HIZ_BOY)
		hizYazi.BackgroundTransparency = 1
		hizYazi.TextSize = 15
		Fonts.apply(hizYazi)
		hizYazi.Parent = yeni

		local hizKontur = Instance.new("UIStroke")
		hizKontur.Color = Color3.new(0, 0, 0)
		hizKontur.Thickness = 1.5
		hizKontur.Parent = hizYazi

		etiket = yeni
	end

	local yazi = (etiket :: BillboardGui):FindFirstChild("Yazi") :: TextLabel?
	if yazi then
		yazi.Text = `Lv. {data.level}`
	end

	local hizYazi = (etiket :: BillboardGui):FindFirstChild("Hiz") :: TextLabel?
	if hizYazi then
		local hizSeviyesi = (data.speedLevel or 0) + 1
		hizYazi.Text = `Speed {hizSeviyesi}`
		hizYazi.TextColor3 = Hiz.renk(hizSeviyesi)
	end
end

-- Hiz yukseltmesi de bas ustu yazisini tazeler (bkz. ServerScriptService > Hiz)
Seviye.etiketGuncelle = etiketGuncelle

------------------------------------------------------------------
-- DURUM
------------------------------------------------------------------
function Seviye.push(player: Player, gained: number?)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	SeviyeDurum:FireClient(player, {
		level = data.level,
		xp = data.xp,
		need = SeviyeAyar.gerekenXp(data.level),
		max = SeviyeAyar.Max,
		gained = gained or 0,
	})
end

-- Kazi sansina carpilan kalici level bonusu
function Seviye.carpan(player: Player): number
	local data = PlayerData.get(player)
	return if data then SeviyeAyar.sansCarpani(data.level) else 1
end

--[[
	XP verir; yetiyorsa (birden fazla da olabilir) level atlatir ve odulleri
	verir. Max levelde XP birikmez.
]]
function Seviye.xpVer(player: Player, amount: number)
	local data = PlayerData.get(player)
	local miktar = math.floor(amount or 0)
	if not data or miktar <= 0 or data.level >= SeviyeAyar.Max then
		return
	end

	data.xp += miktar

	local atlanan = 0
	local coin = 0
	while data.level < SeviyeAyar.Max and data.xp >= SeviyeAyar.gerekenXp(data.level) do
		data.xp -= SeviyeAyar.gerekenXp(data.level)
		data.level += 1
		atlanan += 1
		coin += SeviyeAyar.rotCoinOdulu(data.level)
	end

	if data.level >= SeviyeAyar.Max then
		data.xp = 0
	end

	if atlanan > 0 then
		PlayerData.addRotCoins(player, coin)
		-- Ekrandaki Rot Coin bakiyesi bayat kalmasin
		Envanter.push(player)
		etiketGuncelle(player)

		SeviyeAtladi:FireClient(player, {
			level = data.level,
			rotCoins = coin,
			luck = SeviyeAyar.sansYuzdesi(data.level),
		})
		Bildirim:FireClient(
			player,
			`LEVEL UP! Level {data.level}  (+{coin} Rot Coin, +{SeviyeAyar.sansYuzdesi(data.level)}% Luck)`,
			Color3.fromRGB(255, 215, 40)
		)
	end

	Seviye.push(player, miktar)
end

------------------------------------------------------------------
-- BAGLANTILAR
------------------------------------------------------------------
local function oyuncuHazirla(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Head", 10)
		etiketGuncelle(player)
	end)
	if player.Character then
		task.spawn(etiketGuncelle, player)
	end

	-- Veri yuklenince bar ve bas ustu yazisi gorunsun
	task.delay(3, function()
		if player.Parent then
			etiketGuncelle(player)
			Seviye.push(player)
		end
	end)
end

Players.PlayerAdded:Connect(oyuncuHazirla)
for _, player in Players:GetPlayers() do
	task.spawn(oyuncuHazirla, player)
end

SeviyeAc.OnServerEvent:Connect(function(player)
	Seviye.push(player)
end)

return Seviye
