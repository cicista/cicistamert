--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("SunucuIsini"))
local Condition = require(Shared:WaitForChild("Condition"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local Beams = require(script.Parent:WaitForChild("Beams"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))
local GorevTakip = require(script.Parent:WaitForChild("GorevTakip"))
local Hava = require(script.Parent:WaitForChild("Hava"))
local Patlama = require(script.Parent:WaitForChild("Patlama"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Sand = require(script.Parent:WaitForChild("Sand"))
local Seviye = require(script.Parent:WaitForChild("Seviye"))
local Unvan = require(script.Parent:WaitForChild("Unvan"))

local Bildirim = Net.event("Bildirim")
local Duyuru = Net.event("Duyuru")

local N = Ayar.Nitelik

local SunucuIsini = {}

local rng = Random.new()

local aktifId: string? = nil
local bitis = 0

local function temizle()
	aktifId = nil
	bitis = 0
	Workspace:SetAttribute(N.konum, nil)
	Workspace:SetAttribute(N.bitis, 0)
	Workspace:SetAttribute(N.kazan, "")
end

function SunucuIsini.aktif(): Beams.Beam?
	local id = aktifId
	return if id then Beams.get(id) else nil
end

function SunucuIsini.dogur(): (boolean, string)
	if SunucuIsini.aktif() then
		return false, "A Mystery Beam is already active"
	end

	local spot = Sand.randomSpotNamed(Ayar.Kumlar, rng)
	if not spot then
		warn(`[SunucuIsini] no sand spot found on {table.concat(Ayar.Kumlar, ", ")}`)
		return false, "No sand spot found"
	end

	local beam = Beams.spawnPublic(Ayar.Kind, spot, Ayar.Ada, Ayar.Omur)
	aktifId = beam.id
	bitis = os.time() + Ayar.Omur

	Workspace:SetAttribute(N.konum, spot)
	Workspace:SetAttribute(N.bitis, bitis)
	Workspace:SetAttribute(N.kazan, "")

	Duyuru:FireAllClients({
		tur = "sunucu",
		renk = Ayar.Renk,
		ust = `A MYSTERY BEAM LANDED ON {string.upper(Ayar.AdaAdi)}`,
		buyuk = "FIRST TO DIG WINS!",
	})
	Bildirim:FireAllClients(
		`A MYSTERY BEAM landed on {Ayar.AdaAdi}! First to dig it wins a pet above your best rarity!`,
		Ayar.Renk
	)

	return true, `Mystery Beam dropped at {math.floor(spot.X)}, {math.floor(spot.Z)}`
end

function SunucuIsini.basladi(player: Player, beam: Beams.Beam)
	beam.kazan = player
	Workspace:SetAttribute(N.kazan, player.DisplayName)

	for _, diger in Players:GetPlayers() do
		if diger ~= player then
			Bildirim:FireClient(diger, `{player.DisplayName} is digging the Mystery Beam!`, Ayar.Renk)
		end
	end
end

function SunucuIsini.kaybetti(player: Player, beam: Beams.Beam)
	beam.claimed = false
	beam.kazan = nil
	Workspace:SetAttribute(N.kazan, "")

	Bildirim:FireAllClients(`{player.DisplayName} failed! The Mystery Beam is still up for grabs!`, Ayar.Renk)
end

function SunucuIsini.kazandi(player: Player, beam: Beams.Beam)
	Beams.remove(beam.id, "mystery beam won")
	temizle()

	local data = PlayerData.get(player)
	if not data then
		return
	end

	local odul = Ayar.odulKademesi(rng, data.shovel)
	local condition = Condition.roll(rng)
	local mutation = Hava.mutasyon(rng) or Mutations.roll(rng)

	local item = PlayerData.addBrainrot(player, odul, condition, mutation, Ayar.OdulAdasi, true)
	if not item then
		return
	end

	Envanter.syncBrainrots(player)
	Envanter.push(player)
	Patlama.oynat(player, odul)

	GorevTakip.ilerlet(player, "dig", 1)
	Unvan.ilerlet(player, "kazi", 1)
	GorevTakip.ilerlet(player, "collect", 1, odul)
	Seviye.xpVer(player, Seviye.rarityXp(odul))

	Duyuru:FireAllClients({
		tur = "sunucu",
		kademe = odul,
		ust = `{string.upper(player.DisplayName)} WON THE MYSTERY BEAM!`,
		buyuk = `{string.upper(Rarity.displayName(odul))} EGG!`,
	})
	Bildirim:FireClient(player, `You won the Mystery Beam! A {Rarity.displayName(odul)} egg is in your backpack.`, Rarity.color(odul))
end

local calisti = false

function SunucuIsini.calistir()
	if calisti then
		return
	end
	calisti = true

	temizle()

	Players.PlayerRemoving:Connect(function(player)
		local beam = SunucuIsini.aktif()
		if beam and beam.kazan == player then
			SunucuIsini.kaybetti(player, beam)
		end
	end)

	task.spawn(function()
		local sonraki = Ayar.sonraki(os.time())
		local uyarilan: { [number]: boolean } = {}

		while true do
			local simdi = os.time()
			Workspace:SetAttribute(N.sonraki, sonraki)

			if aktifId and not SunucuIsini.aktif() then
				temizle()
				Bildirim:FireAllClients("Nobody dug the Mystery Beam in time... it faded away.", Ayar.Renk)
			end

			local kalan = sonraki - simdi
			for _, esik in Ayar.UyariSaniyeleri do
				if kalan <= esik and kalan > esik - 5 and not uyarilan[esik] then
					uyarilan[esik] = true
					Bildirim:FireAllClients(
						`A MYSTERY BEAM lands on {Ayar.AdaAdi} in 1 minute! Get ready to race!`,
						Ayar.Renk
					)
				end
			end

			if simdi >= sonraki then
				sonraki = Ayar.sonraki(simdi)
				table.clear(uyarilan)
				SunucuIsini.dogur()
			end

			task.wait(1)
		end
	end)
end

return SunucuIsini
