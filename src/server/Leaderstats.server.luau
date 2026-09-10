--[[
	Leaderstats  (Script)
	Yeri: ServerScriptService > Leaderstats

	Oyunun acilis scripti:
	  - Assets klasorlerini olusturur (model atmak icin)
	  - butun remote'lari olusturur (diger scriptler bunlari bekler)
	  - oyuncu verisini yukler
	  - leaderstats'i veriyle senkron tutar

	SIRALAMA
	Roblox'un kendi oyuncu listesi leaderstats'taki ILK sayisal degere gore
	buyukten kucuge siralar. Bu yuzden "Rot" bir NumberValue: boylece butun
	oyuncular Rot'a gore siralanir. Kisa gosterim (1.5M gibi) ekranin sag
	ustundeki kendi HUD'umuzda var.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Assets = require(Shared:WaitForChild("Assets"))
local Icons = require(Shared:WaitForChild("Icons"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))

-- Model klasorleri ve remote'lar herkesten once hazir olmali
Assets.ensureFolders()
Net.init()

-- Hangi Lucky Block modeli kacinci sirada, Output'tan gorulebilsin
Assets.listLuckyBlocks()

-- Ikon paketi bulundu mu, hangileri eksik
Icons.report()

--[[
	Gunluk odul sistemi. Require edilince remote baglantilarini kurar.

	MUTLAKA Net.init()'TEN SONRA: Odul modulu yuklenirken Net.event() ile
	remote'lari aliyor, Net.event ise WaitForChild kullaniyor. Remote'lar
	henuz olusturulmadan require edilirse modul sonsuza kadar bekler ve bu
	acilis scripti hic bitmez -- leaderstats, base ve NPC'ler dahil hicbir
	sey kurulmaz.
]]
require(Modules:WaitForChild("Odul"))

local function setupStats(player: Player)
	local data = PlayerData.load(player)

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	-- Siralama icin sayisal olmali; Rot milyarlara ciktigi icin NumberValue
	local rot = Instance.new("NumberValue")
	rot.Name = "Rot"
	rot.Value = data.rot
	rot.Parent = stats

	local coins = Instance.new("IntValue")
	coins.Name = "Rot Coin"
	coins.Value = data.rotCoins
	coins.Parent = stats

	local brainrot = Instance.new("IntValue")
	brainrot.Name = "Brainrot"
	brainrot.Value = #data.inventory
	brainrot.Parent = stats

	stats.Parent = player

	-- Veriden leaderstats'a surekli yansitma
	task.spawn(function()
		while player.Parent do
			local current = PlayerData.get(player)
			if current then
				rot.Value = current.rot
				coins.Value = current.rotCoins
				brainrot.Value = #current.inventory
			end
			task.wait(0.5)
		end
	end)
end

Players.PlayerAdded:Connect(setupStats)

for _, player in Players:GetPlayers() do
	task.spawn(setupStats, player)
end
