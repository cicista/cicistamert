--!strict

local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("Hatirlatma"))
local Rewards = require(Shared:WaitForChild("Rewards"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local HatirlatmaServisi = {}

local harita = MemoryStoreService:GetSortedMap(Ayar.HaritaAdi)

local hataYazildi = false

local veriler: { [Player]: any } = {}

local function aktif(): boolean
	return Ayar.MesajId ~= ""
end

local function uyar(mesaj: string)
	if hataYazildi then
		return
	end
	hataYazildi = true
	warn(`[Hatirlatma] {mesaj}`)
end

local function gonder(userId: number, kayit: any)
	local gun = if type(kayit) == "table" then tonumber(kayit.gun) or 1 else 1
	local seri = if type(kayit) == "table" then tonumber(kayit.seri) or 0 else 0

	local govde = {
		source = { universe = `universes/{game.GameId}` },
		payload = {
			message_id = Ayar.MesajId,
			type = "MOMENT",
			parameters = {
				day = { string_value = tostring(gun) },
				reward = { string_value = Rewards.label(gun) },
				streak = { string_value = tostring(seri) },
			},
		},
		join_experience = { launch_data = Ayar.GirisVerisi },
		analytics_data = { category = Ayar.Kategori },
	}

	local ok, sonuc = pcall(function()
		return HttpService:RequestAsync({
			Url = `https://apis.roblox.com/cloud/v2/users/{userId}/notifications`,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["x-api-key"] = HttpService:GetSecret(Ayar.SirAdi),
			},
			Body = HttpService:JSONEncode(govde),
		})
	end)

	if not ok then
		uyar(`notification request failed: {tostring(sonuc)}`)
	elseif not sonuc.Success then
		uyar(`notification rejected ({sonuc.StatusCode}): {string.sub(sonuc.Body, 1, 200)}`)
	end
end

function HatirlatmaServisi.aktifMi(): boolean
	return aktif()
end

function HatirlatmaServisi.planla(player: Player, zaman: number, gun: number, seri: number)
	if not aktif() then
		return
	end
	local ok, hata = pcall(function()
		harita:SetAsync(tostring(player.UserId), { gun = gun, seri = seri }, Ayar.Omur, zaman)
	end)
	if not ok then
		uyar(`reminder could not be scheduled: {tostring(hata)}`)
	end
end

function HatirlatmaServisi.iptal(player: Player)
	if not aktif() then
		return
	end
	pcall(function()
		harita:RemoveAsync(tostring(player.UserId))
	end)
end

local function ayrilirkenPlanla(player: Player)
	local data = veriler[player] or PlayerData.get(player)
	veriler[player] = nil
	if not data or data.lastReward <= 0 then
		return
	end
	local simdi = os.time()
	if simdi - data.lastReward >= Rewards.streakReset then
		return
	end
	local hazir = data.lastReward + Rewards.cooldown
	local zaman = if hazir > simdi then hazir else simdi + Ayar.HazirGecikmesi
	local durum = Rewards.state(data.lastReward, data.rewardDay, simdi)
	HatirlatmaServisi.planla(player, zaman, durum.day, Rewards.seriGecerli(data.streak, data.lastReward, simdi))
end

local function tara()
	local ok, ogeler = pcall(function()
		return harita:GetRangeAsync(Enum.SortDirection.Ascending, Ayar.Toplu, nil, { sortKey = os.time() })
	end)
	if not ok then
		uyar(`reminder queue could not be read: {tostring(ogeler)}`)
		return
	end
	if type(ogeler) ~= "table" then
		return
	end

	for _, oge in ogeler do
		local anahtar = oge.key
		local silindi = pcall(function()
			harita:RemoveAsync(anahtar)
		end)
		local userId = tonumber(anahtar)
		if silindi and userId and not Players:GetPlayerByUserId(userId) then
			gonder(userId, oge.value)
		end
	end
end

local basladi = false

function HatirlatmaServisi.baslat()
	if basladi then
		return
	end
	basladi = true

	Workspace:SetAttribute(Ayar.AktifNiteligi, aktif())
	if not aktif() then
		return
	end

	local function girdi(player: Player)
		HatirlatmaServisi.iptal(player)
		local data = PlayerData.bekle(player)
		if data and player.Parent then
			veriler[player] = data
		end
	end

	Players.PlayerAdded:Connect(girdi)
	for _, player in Players:GetPlayers() do
		task.spawn(girdi, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		pcall(ayrilirkenPlanla, player)
	end)

	task.spawn(function()
		while true do
			task.wait(Ayar.KontrolAraligi)
			tara()
		end
	end)
end

return HatirlatmaServisi
