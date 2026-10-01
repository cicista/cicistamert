--!strict

local Ogretici = {}

export type Hedef = "kum" | "dedektif" | "base" | "fuse"

export type Adim = {
	id: string,
	olay: string,
	hedef: Hedef,
	yazi: string,
	resim: string?,
	alt: string?,
}

Ogretici.Adimlar = {
	{
		id = "ilkKazi",
		olay = "kazdi",
		hedef = "kum",
		resim = "hosgeldin",
		yazi = "Dig the glowing beam!",
		alt = "It is right next to you -- dig it, then hit it fast!",
	},
	{
		id = "ilkCollect",
		olay = "collectledi",
		hedef = "dedektif",
		resim = "dusunce",
		yazi = "Take it to the Detective!",
		alt = "He reveals what you dug up.",
	},
	{
		id = "slot",
		olay = "slotladi",
		hedef = "base",
		resim = "tesvik",
		yazi = "Place it in a base slot!",
		alt = "Pets earn cash while placed.",
	},
	{
		id = "para",
		olay = "parayiAldi",
		hedef = "base",
		resim = "dans",
		yazi = "Collect your cash!",
		alt = "Step on the pad at your base.",
	},
	{
		id = "ucKazi",
		olay = "ucKazdi",
		hedef = "kum",
		resim = "tesvik",
		yazi = "Dig the 3 beams!",
		alt = "They are lined up next to you.",
	},
	{
		id = "ucCollect",
		olay = "ucCollectledi",
		hedef = "dedektif",
		resim = "dusunce",
		yazi = "Reveal all 3 at the Detective!",
		alt = "Hand in all three, then collect them.",
	},
	{
		id = "fuse",
		olay = "fuseYapti",
		hedef = "fuse",
		resim = "dans",
		yazi = "Fuse them at the Fuse Machine!",
		alt = "3 of a kind can become something better.",
	},
} :: { Adim }

Ogretici.Anlaticilar = {
	hosgeldin = { "hosgeldin", "hoşgeldin", "welcome" },
	dusunce = { "dusunce", "düşünce", "thinking" },
	tesvik = { "tesvik", "teşvik", "encourage" },
	dans = { "dans", "dance" },
} :: { [string]: { string } }

Ogretici.AdaIpucu = {
	ada = 2,
	nitelik = "IpucuAda",
	yazi = "You can afford a new island!",
	alt = "Open the Teleporter and pick the red island.",
	resim = "tesvik",
	varis = "Stronger pets live here -- dig this sand for better rot!",
	renk = Color3.fromRGB(255, 60, 60),
}

Ogretici.KurekIpucu = {
	kurek = "Iron",
	nitelik = "IpucuKurek",
	yazi = "You can afford your first shovel!",
	alt = "Open the Shovel Shop and buy it -- digging gets much faster.",
	resim = "tesvik",
	varis = "Nice shovel! Beams come out way faster now.",
	renk = Color3.fromRGB(255, 200, 60),
	modeller = { "Shop", "Shopkeeper", "ShovelShop", "Magaza", "KurekMagazasi" },
}

Ogretici.IlkKademe = "Common"

Ogretici.UcAdet = 3

Ogretici.RotCoinOdulu = 1

Ogretici.BitisOdulu = { luckyBlock = "Normal", adet = 1 }

Ogretici.PatlamaRengi = Color3.fromRGB(255, 255, 255)

Ogretici.PatlamaOlcegi = "Epic"

Ogretici.IsaretRengi = Color3.fromRGB(255, 215, 60)

function Ogretici.adimSayisi(): number
	return #Ogretici.Adimlar
end

function Ogretici.adim(sira: number): Adim?
	return Ogretici.Adimlar[sira]
end

function Ogretici.siraOf(olay: string): number?
	for sira, adim in Ogretici.Adimlar do
		if adim.olay == olay then
			return sira
		end
	end
	return nil
end

return Ogretici
