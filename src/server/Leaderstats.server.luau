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

local Hiz = require(Shared:WaitForChild("Hiz"))

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
-- Arkadas buffi: oyuncular girerken arkadasliklari hemen olculsun
require(Modules:WaitForChild("Arkadaslar"))
-- Level sistemi: bas ustu yazisi ve XP bari baglantilari
require(Modules:WaitForChild("Seviye"))

local function setupStats(player: Player)
	local data = PlayerData.load(player)

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	-- Siralama icin sayisal olmali; Rot milyarlara ciktigi icin NumberValue
	local rot = Instance.new("NumberValue")
	rot.Name = "Rot"
	rot.Value = data.rot
	rot.Parent = stats

	-- Rot ilk sutun kalir (liste Rot'a gore siralanir)
	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = data.level
	level.Parent = stats

	--[[
		Speed: rebirth'ler dahil TOPLAM hiz seviyesi. Rebirth hizi Speed 1'e
		dondursede burada sifirlanmaz: her rebirth 100 sayilir.
		Ornek: 2 rebirth + Speed 50  ->  250
	]]
	local function toplamHiz(d: any): number
		return (d.speedRebirth or 0) * Hiz.Max + (d.speedLevel or 0) + 1
	end

	local speed = Instance.new("IntValue")
	speed.Name = "Speed"
	speed.Value = toplamHiz(data)
	speed.Parent = stats

	stats.Parent = player

	-- Veriden leaderstats'a surekli yansitma
	task.spawn(function()
		while player.Parent do
			local current = PlayerData.get(player)
			if current then
				rot.Value = current.rot
				level.Value = current.level
				speed.Value = toplamHiz(current)
			end
			task.wait(0.5)
		end
	end)
end

Players.PlayerAdded:Connect(setupStats)

for _, player in Players:GetPlayers() do
	task.spawn(setupStats, player)
end
