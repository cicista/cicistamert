--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Detectors = require(Shared:WaitForChild("Detectors"))
local Flyboard = require(Shared:WaitForChild("Flyboard"))
local OyunConfig = require(Shared:WaitForChild("OyunConfig"))
local Passler = require(Shared:WaitForChild("Passler"))
local Rewards = require(Shared:WaitForChild("Rewards"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Sand = require(script.Parent:WaitForChild("Sand"))
local Arkadaslar = require(script.Parent:WaitForChild("Arkadaslar"))
local Seviye = require(script.Parent:WaitForChild("Seviye"))
local AfkSans = require(script.Parent:WaitForChild("AfkSans"))
local HaftaSonu = require(script.Parent:WaitForChild("HaftaSonu"))

export type Parca = { ad: string, carpan: number, gizli: boolean? }

local Sans = {}

Sans.Nitelik = "SansCarpani"
Sans.AyrintiNiteligi = "SansAyrinti"
Sans.GeciciNiteligi = "SansGeciciBitis"
Sans.Deniz = "deniz"

local ARALIK = 0.5

local bolgeler: { [Player]: string } = {}

local function suda(player: Player, ground: Sand.GroundInfo?): boolean
	if player:GetAttribute("Flyboarding") == true then
		return true
	end

	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if humanoid:GetState() == Enum.HumanoidStateType.Swimming or humanoid.FloorMaterial == Enum.Material.Water then
			return true
		end
	end

	return ground ~= nil
		and not ground.isSand
		and (ground.material == Enum.Material.Water or Flyboard.isSeaInstance(ground.part))
end

function Sans.bolge(player: Player): string
	local ground = Sand.underPlayer(player)
	if player:GetAttribute("Flyboarding") ~= true and ground and ground.isSand then
		bolgeler[player] = Brainrots.islandOf(ground.part)
	elseif suda(player, ground) then
		bolgeler[player] = Sans.Deniz
	end
	return bolgeler[player] or Brainrots.IslandOrder[1]
end

function Sans.adaSansi(ada: string): number
	if ada == Sans.Deniz then
		return OyunConfig.GPS.seaLuck or 0
	end
	return Sand.adaSansi(ada)
end

local function kisiselParcalar(player: Player): { Parca }
	local data = PlayerData.get(player)
	local dedektor = Detectors.get((if data then data.detector else Detectors.Default) :: any)
	local seri = if data then Rewards.seriGecerli(data.streak, data.lastReward, os.time()) else 0

	return {
		{ ad = "Daily Streak", carpan = Rewards.seriCarpani(seri) },
		{ ad = "Detector", carpan = dedektor.luck },
		{ ad = "Clovers", carpan = AfkSans.carpan(player), gizli = true },
		{ ad = "Level", carpan = Seviye.carpan(player) },
		{ ad = "Potion", carpan = PlayerData.luckBonus(player) },
		{ ad = "Friends", carpan = Arkadaslar.carpan(player) },
		{ ad = "Weekend", carpan = HaftaSonu.carpan() },
		{ ad = "2x Luck Pass", carpan = Passler.sansCarpani(player) },
	}
end

local function carp(parcalar: { Parca }, gizliDahil: boolean): number
	local toplam = 1
	for _, parca in parcalar do
		if gizliDahil or not parca.gizli then
			toplam *= parca.carpan
		end
	end
	return toplam
end

function Sans.kazi(player: Player): number
	local ada = Sans.bolge(player)
	if ada == Sans.Deniz then
		ada = Brainrots.IslandOrder[1]
	end
	return Sans.adaSansi(ada) + carp(kisiselParcalar(player), true)
end

function Sans.deniz(player: Player): number
	return Sans.adaSansi(Sans.Deniz) + carp(kisiselParcalar(player), true)
end

local function yuvarla(deger: number): number
	if deger >= 100 then
		return math.floor(deger + 0.5)
	end
	return math.floor(deger * 100 + 0.5) / 100
end

local function yayinla(player: Player)
	if not PlayerData.get(player) then
		return
	end

	local ada = Sans.bolge(player)
	local adaSansi = Sans.adaSansi(ada)
	local parcalar = kisiselParcalar(player)

	local satirlar: { string } = {}
	if adaSansi > 0 then
		table.insert(satirlar, `{(Brainrots.IslandNames :: { [string]: string })[ada] or ada} +{yuvarla(adaSansi)}`)
	end
	for _, parca in parcalar do
		if not parca.gizli and math.abs(parca.carpan - 1) > 1e-3 then
			table.insert(satirlar, `{parca.ad} x{yuvarla(parca.carpan)}`)
		end
	end

	local deger = yuvarla(adaSansi + carp(parcalar, false))
	if player:GetAttribute(Sans.Nitelik) ~= deger then
		player:SetAttribute(Sans.Nitelik, deger)
	end

	local ayrinti = table.concat(satirlar, "|")
	if player:GetAttribute(Sans.AyrintiNiteligi) ~= ayrinti then
		player:SetAttribute(Sans.AyrintiNiteligi, ayrinti)
	end

	local data = PlayerData.get(player)
	local bitis = if data and data.luckUntil > os.time() then data.luckUntil else 0
	if player:GetAttribute(Sans.GeciciNiteligi) ~= bitis then
		player:SetAttribute(Sans.GeciciNiteligi, bitis)
	end
end

local calisti = false

function Sans.calistir()
	if calisti then
		return
	end
	calisti = true

	Players.PlayerRemoving:Connect(function(player)
		bolgeler[player] = nil
	end)

	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				local ok, hata = pcall(yayinla, player)
				if not ok then
					warn(`[Sans] {player.Name}: luck update failed -- {tostring(hata)}`)
				end
			end
			task.wait(ARALIK)
		end
	end)
end

return Sans
