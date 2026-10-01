--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Fonts = require(Shared:WaitForChild("Fonts"))
local Net = require(Shared:WaitForChild("Net"))
local SeviyeAyar = require(Shared:WaitForChild("Seviye"))
local Hiz = require(Shared:WaitForChild("Hiz"))
local Unvanlar = require(Shared:WaitForChild("Unvanlar"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))

local Bildirim = Net.event("Bildirim")
local SeviyeDurum = Net.event("SeviyeDurum")
local SeviyeAtladi = Net.event("SeviyeAtladi")
local SeviyeAc = Net.event("SeviyeAc")

local ETIKET_ADI = "SeviyeEtiketi"

local Seviye = {}

Seviye.XP = SeviyeAyar.XP
Seviye.rarityXp = SeviyeAyar.rarityXp

local ETIKET_EN = 240
local UNVAN_BOY = 26
local ISIM_BOY = 24
local LEVEL_BOY = 26
local HIZ_BOY = 18

local function satirKur(parent: Instance, ad: string, sira: number, boy: number, yaziBoyu: number, kalinlik: number): TextLabel
	local yazi = Instance.new("TextLabel")
	yazi.Name = ad
	yazi.LayoutOrder = sira
	yazi.Size = UDim2.new(1, 0, 0, boy)
	yazi.BackgroundTransparency = 1
	yazi.TextColor3 = Color3.new(1, 1, 1)
	yazi.TextSize = yaziBoyu
	Fonts.apply(yazi)
	yazi.Parent = parent

	local kontur = yazi:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	kontur.Color = Color3.new(0, 0, 0)
	kontur.Thickness = kalinlik
	kontur.Parent = yazi
	return yazi
end

local function etiketGuncelle(player: Player)
	local data = PlayerData.get(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not data or not head then
		return
	end

	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	local etiket = head:FindFirstChild(ETIKET_ADI) :: BillboardGui?
	if not etiket then
		local yeni = Instance.new("BillboardGui")
		yeni.Name = ETIKET_ADI
		yeni.Size = UDim2.fromOffset(ETIKET_EN, UNVAN_BOY + ISIM_BOY + LEVEL_BOY + HIZ_BOY)
		yeni.StudsOffset = Vector3.new(0, 3.4, 0)
		yeni.MaxDistance = 90
		yeni.LightInfluence = 0
		yeni.Parent = head

		local dizilim = Instance.new("UIListLayout")
		dizilim.SortOrder = Enum.SortOrder.LayoutOrder
		dizilim.VerticalAlignment = Enum.VerticalAlignment.Bottom
		dizilim.HorizontalAlignment = Enum.HorizontalAlignment.Center
		dizilim.Padding = UDim.new(0, -3)
		dizilim.Parent = yeni

		satirKur(yeni, "Unvan", 1, UNVAN_BOY, 21, 2)
		satirKur(yeni, "Isim", 2, ISIM_BOY, 19, 2)
		satirKur(yeni, "Yazi", 3, LEVEL_BOY, 22, 2).TextColor3 = Color3.fromRGB(255, 215, 40)
		satirKur(yeni, "Hiz", 4, HIZ_BOY, 15, 1.5)

		etiket = yeni
	end

	local unvanYazi = (etiket :: BillboardGui):FindFirstChild("Unvan") :: TextLabel?
	if unvanYazi then
		local kusanilan = data.unvan.kusanilan
		local rozet = Unvanlar.get(kusanilan)
		unvanYazi.Visible = rozet ~= nil
		if unvanYazi:GetAttribute("UnvanId") ~= kusanilan then
			unvanYazi:SetAttribute("UnvanId", kusanilan)
			unvanYazi.Text = if rozet then rozet.unvan else ""
			Unvanlar.stilUygula(unvanYazi, kusanilan)
		end
	end

	local isim = (etiket :: BillboardGui):FindFirstChild("Isim") :: TextLabel?
	if isim then
		isim.Text = player.DisplayName
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

Seviye.etiketGuncelle = etiketGuncelle

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

function Seviye.carpan(player: Player): number
	local data = PlayerData.get(player)
	return if data then SeviyeAyar.sansCarpani(data.level) else 1
end

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
		Envanter.push(player)
		etiketGuncelle(player)

		SeviyeAtladi:FireClient(player, {
			level = data.level,
			rotCoins = coin,
			luck = SeviyeAyar.sansYuzdesi(data.level),
		})
		local coinYazi = if coin > 0 then `+{coin} Rot Coin, ` else ""
		Bildirim:FireClient(
			player,
			`LEVEL UP! Level {data.level}  ({coinYazi}+{SeviyeAyar.sansYuzdesi(data.level)}% Luck)`,
			Color3.fromRGB(255, 215, 40)
		)
	end

	Seviye.push(player, miktar)
end

local function oyuncuHazirla(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Head", 10)
		etiketGuncelle(player)
	end)
	if player.Character then
		task.spawn(etiketGuncelle, player)
	end

	task.spawn(function()
		task.wait(3)
		if PlayerData.bekle(player) then
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
