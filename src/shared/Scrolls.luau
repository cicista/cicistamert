--!strict
--[[
	SCROLL'LAR  --  base'deki brainrota mutasyon basma

	Rot Coin magazasindan alinir, cantaya bir Tool olarak girer. Oyuncu
	scroll'u ELINDE TUTARKEN base'indeki bir slota E'ye basinca oradaki
	brainrota mutasyon denemesi yapilir.

	Deneme SANSA bagli ve scroll her durumda harcanir -- tutarsa mutasyon
	gelir, tutmazsa yalnizca bildirim. Bu yuzden fiyat dusuk tutuldu.

	MODEL
	Tool'un kendisi Studio'da hazir duruyor:
	ReplicatedStorage > Assets > Scrolls > <modelAdi>
	Oradan klonlaniyor, yani tutusu ve gorunumu tamamen Studio'daki
	Tool'un ayarlarindan geliyor (Grip degerlerine dokunulmuyor).
]]

local Mutations = require(script.Parent.Mutations)

local Scrolls = {}

export type ScrollInfo = {
	id: string,
	ad: string,
	aciklama: string,
	-- Assets > Scrolls altindaki Tool'un adi
	modelAdi: string,
	-- Basarili olursa verilecek mutasyon (bkz. Shared > Mutations)
	mutasyon: string,
	-- Tutma olasiligi, 0..1
	sans: number,
	-- Rot Coin fiyati
	fiyat: number,
	renk: Color3,
}

Scrolls.Info = {
	HackerMutation = {
		id = "HackerMutation",
		ad = "Hacker Mutation Scroll",
		aciklama = "40% chance to give a placed brainrot the Hacker mutation",
		modelAdi = "HackerMutationScroll",
		mutasyon = "Hacker",
		sans = 0.4,
		fiyat = 25,
		renk = Mutations.get("Hacker").color,
	},
} :: { [string]: ScrollInfo }

-- Listeleme icin sabit sira (magaza ve canta ayni sirayi kullansin)
Scrolls.Order = { "HackerMutation" } :: { string }

function Scrolls.get(id: string?): ScrollInfo?
	return if type(id) == "string" then Scrolls.Info[id] else nil
end

-- Cantadaki Tool'a konan nitelik: hangi scroll oldugu buradan okunuyor
Scrolls.Nitelik = "ScrollId"

-- Hotbarda yazan ad: "Hacker Mutation Scroll x3"
function Scrolls.etiket(id: string, adet: number): string
	local info = Scrolls.get(id)
	local ad = if info then info.ad else id
	return if adet > 1 then `{ad} x{adet}` else ad
end

return Scrolls
