--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("Kapisma"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local Basla = Net.event("KapismaBasla")
local Durum = Net.event("KapismaDurum")
local Tik = Net.event("KapismaTik")
local Bitti = Net.event("KapismaBitti")
local Bildirim = Net.event("Bildirim")
local Duyuru = Net.event("Duyuru")

export type Duello = {
	a: Player,
	b: Player,
	kind: string,
	p: number,
	durum: string,
	bitis: number,
	jeton: { [Player]: number },
	sonDolum: { [Player]: number },
	bitince: (kazanan: Player, kaybeden: Player) -> (),
}

local Kapisma = {}

local duellolar: { [Player]: Duello } = {}

function Kapisma.icinde(player: Player): boolean
	return duellolar[player] ~= nil
end

local function kademeAdi(kind: string): string
	return string.upper(Rarity.beamName(kind))
end

local function bitir(d: Duello, kazanan: Player)
	if d.durum == "bitti" then
		return
	end
	d.durum = "bitti"

	local kaybeden = if kazanan == d.a then d.b else d.a
	duellolar[d.a] = nil
	duellolar[d.b] = nil

	for _, oyuncu in { d.a, d.b } do
		if oyuncu.Parent then
			Bitti:FireClient(oyuncu, { kazandin = oyuncu == kazanan, kazanan = kazanan.DisplayName })
		end
	end

	local savunma = kazanan == d.a
	Duyuru:FireAllClients({
		tur = "sunucu",
		kademe = d.kind,
		renk = Rarity.beamColor(d.kind),
		ust = `{string.upper(kazanan.DisplayName)} BEAT {string.upper(kaybeden.DisplayName)} IN A CLASH!`,
		buyuk = if savunma then `{kademeAdi(d.kind)} DEFENDED!` else `{kademeAdi(d.kind)} STOLEN!`,
	})

	local ok, hata = pcall(d.bitince, kazanan, kaybeden)
	if not ok then
		warn(`[Kapisma] finish callback failed -- {tostring(hata)}`)
	end
end

function Kapisma.basla(a: Player, b: Player, kind: string, bitince: (kazanan: Player, kaybeden: Player) -> ())
	local d: Duello = {
		a = a,
		b = b,
		kind = kind,
		p = 0.5,
		durum = "sayim",
		bitis = 0,
		jeton = { [a] = Ayar.Patlama, [b] = Ayar.Patlama },
		sonDolum = { [a] = os.clock(), [b] = os.clock() },
		bitince = bitince,
	}
	duellolar[a] = d
	duellolar[b] = d

	local ortak = { kind = kind, sayim = Ayar.GeriSayim, sure = Ayar.Sure }
	Basla:FireClient(a, { rakip = b.DisplayName, taraf = 1, kind = ortak.kind, sayim = ortak.sayim, sure = ortak.sure })
	Basla:FireClient(b, { rakip = a.DisplayName, taraf = -1, kind = ortak.kind, sayim = ortak.sayim, sure = ortak.sure })

	for _, diger in Players:GetPlayers() do
		if diger ~= a and diger ~= b then
			Bildirim:FireClient(
				diger,
				`CLASH! {b.DisplayName} is fighting {a.DisplayName} for a {Rarity.beamName(kind)}!`,
				Ayar.Renk
			)
		end
	end

	task.spawn(function()
		task.wait(Ayar.GeriSayim)
		if d.durum ~= "sayim" then
			return
		end
		d.durum = "yaris"
		d.bitis = os.clock() + Ayar.Sure
		d.sonDolum[a] = os.clock()
		d.sonDolum[b] = os.clock()

		while d.durum == "yaris" do
			local kalan = d.bitis - os.clock()
			for _, oyuncu in { a, b } do
				if oyuncu.Parent then
					Durum:FireClient(oyuncu, d.p, math.max(0, kalan))
				end
			end

			if kalan <= 0 then
				bitir(d, if d.p >= 0.5 then a else b)
				break
			end
			task.wait(Ayar.GuncellemeAraligi)
		end
	end)
end

Tik.OnServerEvent:Connect(function(player)
	local d = duellolar[player]
	if not d or d.durum ~= "yaris" then
		return
	end

	local simdi = os.clock()
	local jeton = math.min(Ayar.Patlama, d.jeton[player] + (simdi - d.sonDolum[player]) * Ayar.MaxCps)
	d.sonDolum[player] = simdi
	if jeton < 1 then
		d.jeton[player] = jeton
		return
	end
	d.jeton[player] = jeton - 1

	local yon = if player == d.a then 1 else -1
	d.p = math.clamp(d.p + Ayar.Adim * yon, 0, 1)

	if d.p >= 1 then
		bitir(d, d.a)
	elseif d.p <= 0 then
		bitir(d, d.b)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local d = duellolar[player]
	if d then
		bitir(d, if player == d.a then d.b else d.a)
	end
end)

return Kapisma
