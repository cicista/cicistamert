--!strict
--[[
	DIVINE RENGI  --  sari <-> beyaz canlandirmasi

	Divine (eski adiyla Secret) kademesi tek renk degildir: sari ile beyaz
	arasinda cok hizli gidip gelir. Boylece en ust kademe hem Legendary'nin
	kehribar sarisindan ayrilir hem de "ilahi" bir parlama hissi verir.

	NEDEN ISTEMCIDE CIZILIYOR
	Sunucudaki renk degisimi istemciye saniyede ~20 kez replike edilir;
	0.01 saniyelik bir donusum oradan cizilirse titreme kaba ve kesik
	gorunur. Bu yuzden sunucu yalnizca "bu nesne Divine" diye ETIKETLER,
	rengi her oyuncunun kendi makinesi her karede hesaplar.
	(bkz. StarterPlayerScripts > IlahiRenk)

	KULLANIM
	    Divine.tag(part)      -- sunucu ya da istemci, fark etmez
	    Divine.untag(part)

	Etiketli nesnenin sinifina gore dogru ozellik boyanir:
	    BasePart        -> Color
	    TextLabel       -> TextColor3
	    UIStroke        -> Color
	    Frame / GuiObject -> BackgroundColor3
	    PointLight vb.  -> Color
	    ParticleEmitter -> Color (ColorSequence)
]]

local CollectionService = game:GetService("CollectionService")

local Divine = {}

-- Etiketli nesneleri istemci bu adla buluyor
Divine.Tag = "IlahiRenk"

--[[
	Iki uc renk ve gecis hizi.

	interval: kac saniyede bir renk degisir. 0.04 = saniyede ~25 gecis;
	belirgin ama goz yormayan bir parildama. Kucultursen sertlesir.
]]
Divine.colorA = Color3.fromRGB(255, 232, 90)
Divine.colorB = Color3.fromRGB(255, 255, 255)
Divine.interval = 0.04

--[[
	Ruletlerde ve panellerde kullanilan ZEMIN tonu.

	Bolme arka plani her karede degisirse serit okunamaz hale geliyor;
	orada sabit ama Legendary'den acik bir "ilahi sari" kullaniyoruz.
]]
Divine.panelColor = Color3.fromRGB(255, 240, 150)

-- Verilen ana gore su anki renk
function Divine.colorAt(clock: number): Color3
	local step = math.floor(clock / math.max(Divine.interval, 1 / 240))
	return if step % 2 == 0 then Divine.colorA else Divine.colorB
end

function Divine.tag(instance: Instance)
	if not CollectionService:HasTag(instance, Divine.Tag) then
		CollectionService:AddTag(instance, Divine.Tag)
	end
end

function Divine.untag(instance: Instance)
	CollectionService:RemoveTag(instance, Divine.Tag)
end

--[[
	ADAYA BAGLI UST KADEMELERIN PARILTILARI

	Divine'in sari<->beyaz parildamasinin aynisi, her kademe icin ayri iki
	uc renkle. Her birinin KENDI etiketi var; istemci hepsini ayri palet
	olarak kaydediyor (bkz. StarterPlayerScripts > IlahiRenk).

	Divine'in kendisi de burada: boylece "hangi kademe parildar" sorusunun
	tek bir cevabi oluyor ve tagIf her yerde ayni sekilde calisiyor.

	interval kucukse parildama sertlesir. Ust kademeler biraz daha hizli
	parildiyor -- "her yeni ada oncekinden daha gosterisli" istegi.
]]
export type Parilti = {
	tag: string,
	colorA: Color3,
	colorB: Color3,
	interval: number,
}

Divine.Flashes = {
	-- Divine (kimligi Secret): sari <-> beyaz
	Secret = {
		tag = Divine.Tag,
		colorA = Divine.colorA,
		colorB = Divine.colorB,
		interval = Divine.interval,
	},

	-- Cosmic: parlak koyu mor <-> beyaz
	Cosmic = {
		tag = "KozmikRenk",
		colorA = Color3.fromRGB(138, 43, 226),
		colorB = Color3.fromRGB(255, 255, 255),
		interval = 0.038,
	},

	-- Secret (kimligi Gizli): siyah <-> beyaz
	Gizli = {
		tag = "GizliRenk",
		colorA = Color3.fromRGB(14, 14, 16),
		colorB = Color3.fromRGB(255, 255, 255),
		interval = 0.034,
	},

	-- Infernal: kan kirmizisi <-> beyaz
	Infernal = {
		tag = "InfernalRenk",
		colorA = Color3.fromRGB(140, 6, 14),
		colorB = Color3.fromRGB(255, 255, 255),
		interval = 0.03,
	},

	-- Abyssal: derin deniz mavisi <-> beyaz
	Abyssal = {
		tag = "AbyssalRenk",
		colorA = Color3.fromRGB(8, 52, 130),
		colorB = Color3.fromRGB(255, 255, 255),
		interval = 0.026,
	},
} :: { [string]: Parilti }

--[[
	Kademesi parildayan bir kademeyse ETIKETLER, degilse dokunmaz.
	Cagiran taraflarin her yerde ayni "if" i yazmamasi icin.

	Eskiden yalnizca Divine'i biliyordu; artik adaya bagli dort ust kademe
	de ayni kapidan geciyor.
]]
function Divine.tagIf(instance: Instance, rarityId: string?)
	local parilti = if rarityId then Divine.Flashes[rarityId] else nil
	if not parilti then
		return
	end

	if not CollectionService:HasTag(instance, parilti.tag) then
		CollectionService:AddTag(instance, parilti.tag)
	end
end

return Divine
