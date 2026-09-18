--!strict
--[[
	Brainrot mutasyonlari -- rarity ve kondisyondan bagimsiz UCUNCU stat.

	BrainrotPack her brainrot'un 7 ayri surumunu iceriyor. Mutasyon hem MODELI
	hem GELIRI degistirir:

	    model  -> Assets > Brainrots > ... > "Gold Tralalero Tralala"
	    gelir  -> rarity tabani * condition carpani * mutasyon carpani

	SU AN CIKABILENLER:
	    Gold %7  |  Diamond %3  |  Galaxy %1  |  kalani Normal

	Lava, Rainbow ve Hacker kapali (obtainable = false). Oyunda hicbir
	yoldan cikmazlar -- yalnizca admin panelinden verilebilirler.

	Gelir carpanlari: Gold 3x, Diamond 5x, Galaxy 8x, Rainbow 10x, Hacker 12x.

	prefix -> paketteki model adinin onune gelen ek. Normal'de bos, cunku
	Normal klasorundeki modeller duz isimli.

	YENI MUTASYON EKLEMEK
	Asagiya bir satir ekle, Order listesine de id'sini yaz. chance degerlerinin
	toplami 100 olmali. Modelleri "<prefix><brainrot adi>" seklinde adlandir.
]]

export type MutationId = "Normal" | "Gold" | "Lava" | "Diamond" | "Galaxy" | "Rainbow" | "Hacker"

export type MutationInfo = {
	id: MutationId,
	displayName: string,
	order: number,
	-- Paketteki model adinin on eki
	prefix: string,
	-- Geliri kac katina cikarir
	multiplier: number,
	-- Kazidan bu mutasyonun cikma sansi (yuzde, toplam 100)
	chance: number,
	-- false ise oyunda hic cikmaz; yalnizca admin panelinden verilebilir
	obtainable: boolean,
	color: Color3,
}

local CollectionService = game:GetService("CollectionService")

local Mutations = {}

Mutations.Order = { "Normal", "Gold", "Lava", "Diamond", "Galaxy", "Rainbow", "Hacker" } :: { MutationId }

--[[
	Index'te ayri alt kategori olarak gosterilen mutasyonlar (bu sirayla).
	Oyuncunun bu mutasyonlarla buldugu brainrotlar ayrica kaydedilir
	(PlayerData.discoveredMut). Listeye ekleme yapmak yeterli.
]]
Mutations.IndexOrder = { "Gold", "Diamond", "Galaxy" } :: { MutationId }

Mutations.Info = {
	Normal = {
		id = "Normal",
		displayName = "Normal",
		order = 1,
		prefix = "",
		multiplier = 1,
		chance = 89,
		obtainable = true,
		color = Color3.fromRGB(220, 220, 225),
	},

	Gold = {
		id = "Gold",
		displayName = "Gold",
		order = 2,
		prefix = "Gold ",
		multiplier = 3,
		chance = 7,
		obtainable = true,
		color = Color3.fromRGB(255, 200, 60),
	},

	Lava = {
		id = "Lava",
		displayName = "Lava",
		order = 3,
		prefix = "Lava ",
		multiplier = 6,
		chance = 0,
		obtainable = false,
		color = Color3.fromRGB(255, 95, 40),
	},

	Diamond = {
		id = "Diamond",
		displayName = "Diamond",
		order = 4,
		prefix = "Diamond ",
		multiplier = 5,
		chance = 3,
		obtainable = true,
		color = Color3.fromRGB(110, 230, 255),
	},

	--[[
		Galaxy, Rainbow'un yerini aldi.

		Paketteki Rainbow modelleri duz renk export edilmis, gokkusagi
		gorunmuyordu. Galaxy ayni sansla (%1) oyuna girdi; Rainbow ise
		tamamen kapatildi ve yalnizca admin panelinden verilebilir.
	]]
	Galaxy = {
		id = "Galaxy",
		displayName = "Galaxy",
		order = 5,
		prefix = "Galaxy ",
		multiplier = 8,
		chance = 1,
		obtainable = true,
		color = Color3.fromRGB(170, 110, 255),
	},

	Rainbow = {
		id = "Rainbow",
		displayName = "Rainbow",
		order = 6,
		prefix = "Rainbow ",
		multiplier = 10,
		chance = 0,
		obtainable = false,
		color = Color3.fromRGB(255, 120, 200),
	},

	-- Paketteki yesil "hacker" surumleri
	Hacker = {
		id = "Hacker",
		displayName = "Hacker",
		order = 7,
		prefix = "Hacker ",
		multiplier = 12,
		chance = 0,
		obtainable = false,
		color = Color3.fromRGB(60, 255, 110),
	},
} :: { [MutationId]: MutationInfo }

--[[
	CANLI RENKLER  (Divine'daki gibi)

	Bu iki mutasyon tek renk degil: iki renk arasinda hizla gidip gelir.
	Yol Divine ile ayni -- sunucu ya da arayuz nesneyi ETIKETLER, rengi her
	oyuncunun makinesi her karede hesaplar. Renk degisimi replikasyona
	takilmaz, herkesin ekraninda akici olur.
	(bkz. StarterPlayerScripts > IlahiRenk)

	  Galaxy -> mor <-> cirtlak pembe
	  Hacker -> yesil <-> beyaz

	interval: kac saniyede bir renk degisir.
]]
export type Flash = {
	tag: string,
	colorA: Color3,
	colorB: Color3,
	interval: number,
}

local Flash: { [string]: Flash } = {
	Galaxy = {
		tag = "GalaksiRenk",
		colorA = Color3.fromRGB(170, 110, 255),
		colorB = Color3.fromRGB(255, 70, 210),
		interval = 0.06,
	},
	Hacker = {
		tag = "HackerRenk",
		colorA = Color3.fromRGB(60, 255, 110),
		colorB = Color3.fromRGB(255, 255, 255),
		interval = 0.06,
	},
}

Mutations.Flash = Flash

Mutations.Default = "Normal" :: MutationId

function Mutations.get(id: string?): MutationInfo
	local info = Mutations.Info[(id or Mutations.Default) :: MutationId]
	-- Bilinmeyen/eski kayitlar Normal sayilir; veri kaybi hataya donusmesin
	return info or Mutations.Info.Normal
end

function Mutations.color(id: string?): Color3
	return Mutations.get(id).color
end

function Mutations.multiplier(id: string?): number
	return Mutations.get(id).multiplier
end

-- Normal disindaki her sey "ozel": arayuzde ismi mutasyon rengiyle yazilir.
function Mutations.isSpecial(id: string?): boolean
	return Mutations.get(id).id ~= "Normal"
end

--[[
	MODEL ADI HAKKINDA

	Paketteki mutasyonlu modeller "<prefix><brainrot adi>" seklinde
	adlandirilmistir:  "Gold Tralalero Tralala"

	Bunu kuran bir yardimci fonksiyon BILEREK YOK. Adi Assets icinde
	dogrudan prefix'ten kuruluyor, cunku iki modul Studio'ya ayri ayri
	senkronlaniyor: aradaki bag bir fonksiyon adi olursa, ad degistiginde
	ve karsi modul eski surumde kalirsa cagri nil'e duser ve brainrot
	tool'u hic uretilemez. Bir kez yasandi, tekrarlamasin.

	Brainrot'un EKRANDA gorunen adi her zaman kendi duz adidir; mutasyon
	zaten altindaki carpan satirinda yaziyor.
]]

--[[
	Mutasyon cekilisi.

	Yalnizca obtainable = true olanlar cikar; kapali olanlarin chance'i 0
	oldugu icin zaten secilemezler, kontrol ek guvenlik.

	Cekilis rarity'den TAMAMEN bagimsizdir: Common da Secret de ayni
	sansla mutasyon alir.
]]
function Mutations.roll(rng: Random): MutationId
	local roll = rng:NextNumber() * 100
	local cursor = 0

	for _, id in Mutations.Order do
		local info = Mutations.Info[id]
		if info.obtainable then
			cursor += info.chance
			if roll <= cursor then
				return id
			end
		end
	end

	return Mutations.Default
end

--[[
	Mutasyonun canli renk tanimi; sabit renkli mutasyonlarda nil doner.
]]
function Mutations.flash(id: string?): Flash?
	return if id then Flash[id] else nil
end

-- Verilen ana gore iki uc renkten hangisi gosterilecek
function Mutations.flashColorAt(flash: Flash, clock: number): Color3
	local step = math.floor(clock / math.max(flash.interval, 1 / 240))
	return if step % 2 == 0 then flash.colorA else flash.colorB
end

--[[
	Mutasyonun canli rengi varsa nesneyi etiketler, yoksa dokunmaz.
	Cagiran taraflarin her yerde ayni "if" i yazmamasi icin.
]]
function Mutations.tagIf(instance: Instance, id: string?)
	local flash = Mutations.flash(id)
	if flash and not CollectionService:HasTag(instance, flash.tag) then
		CollectionService:AddTag(instance, flash.tag)
	end
end

--[[
	Bir nesnenin butun canli renk etiketlerini kaldirir.

	Tekrar kullanilan yazilarda gerekli: onceki mutasyonun etiketi kalirsa
	yeni mutasyon sabit renkli olsa bile yanip sonmeye devam ederdi.
]]
function Mutations.untag(instance: Instance)
	for _, flash in Flash do
		CollectionService:RemoveTag(instance, flash.tag)
	end
end

return Mutations
