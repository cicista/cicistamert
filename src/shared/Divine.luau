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
--[[
	DIVINE'IN PARILDAMA ARALIGI

	0.04 saniyede bir renk degistiriyordu -- saniyede 25 gecis, goz yoruyordu.
	Artik en YAVAS parildayan kademe Divine; ust kademeler sirayla
	hizlaniyor (bkz. Flashes): 0.7 / 0.6 / 0.5 / 0.4 / 0.3.
]]
Divine.interval = 0.5

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

--[[
	Butun parildama etiketlerini soker.

	Eskiden yalnizca Divine etiketini kaldiriyordu; artik dort kademe daha
	parildadigi icin tek tek sokmek gerekiyor. Yeniden kullanilan bir yazi
	(ornegin envanter satiri) eski paletiyle parildamaya devam ederdi.
]]
function Divine.untag(instance: Instance)
	for _, parilti in Divine.Flashes do
		CollectionService:RemoveTag(instance, parilti.tag)
	end
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
--[[
	sweep: parlama bandinin yazinin uzerinden bir gecisi kac saniye surer.
	band:  bandin YARI genisligi (0..1). Kucuk olan daha keskin, daha sert.

	Ikisi de kademe yukseldikce sertlesir: Abyssal en hizli ve en keskin,
	Divine en yumusak.
]]
export type Parilti = {
	tag: string,
	colorA: Color3,
	colorB: Color3,
	interval: number,
	sweep: number,
	band: number,
}

Divine.Flashes = {
	-- Divine (kimligi Secret): sari <-> beyaz
	Secret = {
		tag = Divine.Tag,
		colorA = Divine.colorA,
		colorB = Divine.colorB,
		interval = Divine.interval,
		sweep = 1.30,
		band = 0.14,
	},

	-- Cosmic: parlak koyu mor <-> beyaz
	Cosmic = {
		tag = "KozmikRenk",
		colorA = Color3.fromRGB(138, 43, 226),
		colorB = Color3.fromRGB(255, 255, 255),
		interval = 0.42,
		sweep = 1.00,
		band = 0.11,
	},

	-- Secret (kimligi Gizli): siyah <-> beyaz
	Gizli = {
		tag = "GizliRenk",
		--[[
			UCLAR TERS: colorA BEYAZ.

			Gecis zamanin cogunu colorA da geciriyor; siyah basta olunca yazi
			koyu zeminde okunmuyordu. Boylece tema ayni (siyah-beyaz) ama
			yazi cogunlukla beyaz, arada siyaha dusuyor.
		]]
		colorA = Color3.fromRGB(245, 245, 250),
		colorB = Color3.fromRGB(14, 14, 16),
		interval = 0.34,
		sweep = 0.78,
		band = 0.085,
	},

	-- Infernal: volkan turuncusu <-> beyaz
	Infernal = {
		tag = "InfernalRenk",
		colorA = Color3.fromRGB(255, 92, 12),
		colorB = Color3.fromRGB(255, 255, 255),
		interval = 0.26,
		sweep = 0.58,
		band = 0.065,
	},

	-- Abyssal: derin deniz mavisi <-> beyaz
	Abyssal = {
		tag = "AbyssalRenk",
		colorA = Color3.fromRGB(8, 52, 130),
		colorB = Color3.fromRGB(255, 255, 255),
		interval = 0.18,
		sweep = 0.40,
		band = 0.045,
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
