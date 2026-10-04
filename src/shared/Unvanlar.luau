--!strict

local CollectionService = game:GetService("CollectionService")

local Brainrots = require(script.Parent.Brainrots)
local Format = require(script.Parent.Format)
local Rarity = require(script.Parent.Rarity)
local SeviyeAyar = require(script.Parent.Seviye)

local Unvanlar = {}

export type Stil = {
	tur: string,
	renk: Color3?,
	renkA: Color3?,
	renkB: Color3?,
	etiket: string?,
	nabiz: boolean?,
}

export type Rozet = {
	id: string,
	ad: string,
	unvan: string,
	tur: string,
	hedef: number,
	seviye: number,
	stil: Stil,
	robloxId: number,
	aciklama: string?,
}

Unvanlar.GokkusagiEtiketi = "UnvanGokkusagi"
Unvanlar.NabizEtiketi = "UnvanNabiz"

Unvanlar.SeviyeRenkleri = {
	Color3.fromRGB(170, 175, 190),
	Color3.fromRGB(90, 200, 255),
	Color3.fromRGB(190, 110, 255),
	Color3.fromRGB(255, 200, 40),
	Color3.fromRGB(255, 90, 60),
	Color3.fromRGB(255, 255, 255),
} :: { Color3 }

Unvanlar.SeviyeAdlari = { "COMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC", "ULTIMATE" } :: { string }

local function kademeSirasi(id: string): number
	local info = Rarity.Info[id :: Rarity.RarityId]
	return if info then info.order else 0
end

Unvanlar.Liste = {
	{ id = "ilkKazi", ad = "First Dig", unvan = "Rookie Digger", tur = "kazi", hedef = 1, seviye = 1, stil = { tur = "duz", renk = Color3.fromRGB(215, 220, 230) }, robloxId = 583380109494572 },
	{ id = "evSahibi", ad = "Home Sweet Home", unvan = "Base Builder", tur = "place", hedef = 5, seviye = 1, stil = { tur = "duz", renk = Color3.fromRGB(150, 220, 255) }, robloxId = 4284590385141970 },
	{ id = "ilkSans", ad = "Feeling Lucky", unvan = "Lucky Charm", tur = "lucky", hedef = 1, seviye = 1, stil = { tur = "duz", renk = Color3.fromRGB(255, 236, 120) }, robloxId = 2329542200823661 },

	{ id = "kurekUstasi", ad = "Shovel Master", unvan = "Shovel Master", tur = "kazi", hedef = 100, seviye = 2, stil = { tur = "parlak", renk = Color3.fromRGB(255, 160, 60) }, robloxId = 3959914139508390 },
	{ id = "denizci", ad = "Sea Legs", unvan = "Sea Angler", tur = "balik", hedef = 25, seviye = 2, stil = { tur = "parlak", renk = Color3.fromRGB(80, 210, 255) }, robloxId = 3194941449934881 },
	{ id = "fuzyoncu", ad = "Fusion Apprentice", unvan = "Fusion Apprentice", tur = "fuse", hedef = 10, seviye = 2, stil = { tur = "parlak", renk = Color3.fromRGB(200, 120, 255) }, robloxId = 814585550309545 },
	{ id = "yildiz", ad = "Rising Star", unvan = "Rising Star", tur = "level", hedef = 10, seviye = 2, stil = { tur = "parlak", renk = Color3.fromRGB(255, 215, 60) }, robloxId = 4019541214069236 },
	{ id = "tuccar", ad = "Deal Maker", unvan = "Deal Maker", tur = "trade", hedef = 5, seviye = 2, stil = { tur = "parlak", renk = Color3.fromRGB(110, 235, 130) }, robloxId = 3385749699296839 },

	{ id = "yerYaran", ad = "Ground Breaker", unvan = "Ground Breaker", tur = "kazi", hedef = 1000, seviye = 3, stil = { tur = "gecis", renkA = Color3.fromRGB(255, 200, 60), renkB = Color3.fromRGB(255, 70, 40) }, robloxId = 3408693571661145 },
	{ id = "servetAvcisi", ad = "Fortune Hunter", unvan = "Fortune Hunter", tur = "lucky", hedef = 50, seviye = 3, stil = { tur = "gecis", renkA = Color3.fromRGB(255, 240, 90), renkB = Color3.fromRGB(80, 230, 110) }, robloxId = 1092148184467403 },
	{ id = "mitik", ad = "Mythic Seeker", unvan = "Mythic Seeker", tur = "kademe", hedef = kademeSirasi("Mythic"), seviye = 3, stil = { tur = "gecis", renkA = Color3.fromRGB(255, 80, 120), renkB = Color3.fromRGB(255, 160, 220) }, robloxId = 0 },
	{ id = "alim", ad = "Pet Scholar", unvan = "Pet Scholar", tur = "index", hedef = 50, seviye = 3, stil = { tur = "gecis", renkA = Color3.fromRGB(90, 160, 255), renkB = Color3.fromRGB(190, 110, 255) }, robloxId = 0 },
	{ id = "denizKurdu", ad = "Old Sea Dog", unvan = "Captain of the Sea", tur = "balik", hedef = 500, seviye = 3, stil = { tur = "gecis", renkA = Color3.fromRGB(40, 220, 255), renkB = Color3.fromRGB(30, 90, 255) }, robloxId = 0 },

	{ id = "ilahi", ad = "Divine Touch", unvan = "Divine Touched", tur = "kademe", hedef = kademeSirasi("Secret"), seviye = 4, stil = { tur = "flas", etiket = "IlahiRenk" }, robloxId = 0 },
	{ id = "emektar", ad = "Veteran", unvan = "Veteran", tur = "level", hedef = 30, seviye = 4, stil = { tur = "flas", etiket = "GizliRenk" }, robloxId = 0 },
	{ id = "ustaTuccar", ad = "Master Trader", unvan = "Master Trader", tur = "trade", hedef = 25, seviye = 4, stil = { tur = "flas", etiket = "HackerRenk" }, robloxId = 0 },
	{ id = "zengin", ad = "Rot Tycoon", unvan = "Rot Tycoon", tur = "rot", hedef = 1e9, seviye = 4, stil = { tur = "flas", etiket = "IlahiRenk", nabiz = true }, robloxId = 0 },

	{ id = "kozmik", ad = "Cosmic Voyager", unvan = "Cosmic Voyager", tur = "kademe", hedef = kademeSirasi("Cosmic"), seviye = 5, stil = { tur = "flas", etiket = "KozmikRenk", nabiz = true }, robloxId = 0 },
	{ id = "gizli", ad = "Secret Keeper", unvan = "Keeper of Secrets", tur = "kademe", hedef = kademeSirasi("Gizli"), seviye = 5, stil = { tur = "flas", etiket = "GizliRenk", nabiz = true }, robloxId = 0 },
	{ id = "cehennem", ad = "Hellfire Hunter", unvan = "Hellfire Hunter", tur = "kademe", hedef = kademeSirasi("Infernal"), seviye = 5, stil = { tur = "flas", etiket = "InfernalRenk", nabiz = true }, robloxId = 0 },
	{ id = "hizSeytani", ad = "Speed Demon", unvan = "Speed Demon", tur = "rebirth", hedef = 3, seviye = 5, stil = { tur = "flas", etiket = "GalaksiRenk", nabiz = true }, robloxId = 0 },

	{ id = "ucurum", ad = "Abyss Walker", unvan = "Abyss Walker", tur = "kademe", hedef = kademeSirasi("Abyssal"), seviye = 6, stil = { tur = "flas", etiket = "AbyssalRenk", nabiz = true }, robloxId = 0 },
	{ id = "efsane", ad = "Pet Legend", unvan = "Pet Legend", tur = "index", hedef = #Brainrots.List, seviye = 6, stil = { tur = "gokkusagi", nabiz = true }, robloxId = 0 },
	{ id = "gizemUstasi", ad = "Mystery Master", unvan = "Mystery Master", tur = "level", hedef = SeviyeAyar.Max, seviye = 6, stil = { tur = "gokkusagi", nabiz = true }, robloxId = 0 },
} :: { Rozet }

local byId: { [string]: Rozet } = {}
for _, rozet in Unvanlar.Liste do
	byId[rozet.id] = rozet
end

function Unvanlar.get(id: string?): Rozet?
	return if id then byId[id] else nil
end

function Unvanlar.gereksinim(rozet: Rozet): string
	local h = rozet.hedef
	local tur = rozet.tur
	if tur == "kazi" then
		return if h == 1 then "Dig up your first beam" else `Dig up {Format.short(h)} beams`
	elseif tur == "balik" then
		return `Fish up {Format.short(h)} pets at sea`
	elseif tur == "place" then
		return `Place {h} pets on your base`
	elseif tur == "lucky" then
		return if h == 1 then "Open a Lucky Block" else `Open {Format.short(h)} Lucky Blocks`
	elseif tur == "fuse" then
		return `Fuse pets {h} times`
	elseif tur == "trade" then
		return `Complete {h} trades`
	elseif tur == "rot" then
		return `Collect {Format.short(h)} Rot from your base`
	elseif tur == "level" then
		return `Reach Level {h}`
	elseif tur == "index" then
		return if h >= #Brainrots.List then "Discover every pet in the Index" else `Discover {h} pets in the Index`
	elseif tur == "rebirth" then
		return `Speed Rebirth {h} times`
	elseif tur == "kademe" then
		for _, id in Rarity.Order do
			local info = Rarity.Info[id]
			if info and info.order == h then
				local ad = Rarity.displayName(id)
				local harf = string.upper(string.sub(ad, 1, 1))
				local tanim = if string.find("AEIOU", harf, 1, true) then "an" else "a"
				return `Find {tanim} {ad} pet`
			end
		end
	end
	return rozet.aciklama or ""
end

local STIL_NITELIGI = "UnvanStili"
local STIL_ETIKETLERI = {
	"IlahiRenk",
	"KozmikRenk",
	"GizliRenk",
	"InfernalRenk",
	"AbyssalRenk",
	"GalaksiRenk",
	"HackerRenk",
	Unvanlar.GokkusagiEtiketi,
	Unvanlar.NabizEtiketi,
}

function Unvanlar.stilUygula(label: TextLabel, id: string?)
	for _, cocuk in label:GetChildren() do
		if cocuk:GetAttribute(STIL_NITELIGI) then
			cocuk:Destroy()
		end
	end
	for _, etiket in STIL_ETIKETLERI do
		if CollectionService:HasTag(label, etiket) then
			CollectionService:RemoveTag(label, etiket)
		end
	end

	local kontur = label:FindFirstChildOfClass("UIStroke")
	if not kontur then
		kontur = Instance.new("UIStroke")
		kontur.Thickness = 2
		kontur.Parent = label
	end
	local cizgi = kontur :: UIStroke
	cizgi.Color = Color3.new(0, 0, 0)
	cizgi.Transparency = 0

	label.TextColor3 = Color3.new(1, 1, 1)

	local rozet = Unvanlar.get(id)
	if not rozet then
		return
	end
	local stil = rozet.stil

	local function gecis(ad: string): UIGradient
		local g = Instance.new("UIGradient")
		g.Name = ad
		g:SetAttribute(STIL_NITELIGI, true)
		g.Parent = label
		return g
	end

	if stil.tur == "duz" then
		label.TextColor3 = stil.renk or label.TextColor3
	elseif stil.tur == "parlak" then
		local renk = stil.renk or Color3.new(1, 1, 1)
		label.TextColor3 = renk
		cizgi.Color = renk:Lerp(Color3.new(0, 0, 0), 0.55)
		cizgi.Thickness = math.max(cizgi.Thickness, 2.5)
	elseif stil.tur == "gecis" then
		local g = gecis("UnvanGecisi")
		g.Rotation = 90
		g.Color = ColorSequence.new(stil.renkA or Color3.new(1, 1, 1), stil.renkB or Color3.new(1, 1, 1))
	elseif stil.tur == "flas" and stil.etiket then
		gecis("Parilti")
		CollectionService:AddTag(label, stil.etiket)
	elseif stil.tur == "gokkusagi" then
		gecis("Gokkusagi")
		CollectionService:AddTag(label, Unvanlar.GokkusagiEtiketi)
	end

	if stil.nabiz then
		CollectionService:AddTag(label, Unvanlar.NabizEtiketi)
	end
end

return Unvanlar
