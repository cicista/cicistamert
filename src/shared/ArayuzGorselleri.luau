--!strict

local ArayuzGorselleri = {}

export type Dilim = {
	id: string,
	kesit: Rect,
	olcek: number,
	tasma: number,
	kose: number,
}

export type UcParca = {
	id: string,
	en: number,
	boy: number,
	sol: number,
	sag: number,
}

ArayuzGorselleri.Panel = {
	id = "rbxassetid://124822291576460",
	kesit = Rect.new(170, 170, 690, 695),
	olcek = 0.2,
	tasma = 88,
	kose = 14,
} :: Dilim

ArayuzGorselleri.Ipucu = {
	id = "rbxassetid://113272227747903",
	kesit = Rect.new(170, 170, 690, 695),
	olcek = 0.1,
	tasma = 88,
	kose = 8,
} :: Dilim

ArayuzGorselleri.Doku = {
	id = "rbxassetid://82102098179496",
	boy = 220,
	saydamlik = 0.88,
}

ArayuzGorselleri.Kapat = {
	id = "rbxassetid://78041932541361",
	boy = 40,
}

ArayuzGorselleri.Dugme = {
	en = 932,
	boy = 412,
	kapak = 215,
	yuzUst = 0.03,
	yuzBoy = 0.8,
	basmaKaymasi = 0.04,
	normalTon = 0.92,
	basiliTon = 0.78,
	griEnAz = 0.55,
	renkler = {
		yesil = "rbxassetid://138355576465455",
		mavi = "rbxassetid://139511945270106",
		kirmizi = "rbxassetid://112196397557907",
		altin = "rbxassetid://103778107771990",
		mor = "rbxassetid://102662351932311",
		gri = "rbxassetid://128560492595838",
	} :: { [string]: string },
}

ArayuzGorselleri.Kurdele = {
	id = "rbxassetid://109541274425315",
	en = 966,
	boy = 205,
	sol = 170,
	sag = 170,
	govdeSol = 96,
	govdeUst = 2,
	govdeBoy = 165,
}

ArayuzGorselleri.ParaKutusu = {
	id = "rbxassetid://85113115827816",
	en = 987,
	boy = 266,
	sol = 262,
	sag = 47,
	yuvaMerkezX = 128,
}

ArayuzGorselleri.Slot = { id = "rbxassetid://126565713725039", kesit = Rect.new(180, 180, 692, 692) }
ArayuzGorselleri.Sekme = { id = "rbxassetid://89614504346486", gri = "rbxassetid://70437239003906", kapali = "rbxassetid://84080255824088" }
ArayuzGorselleri.Cubuk = {
	cerceve = "rbxassetid://120047387291829",
	dolgu = "rbxassetid://75259884600656",
	serit = "rbxassetid://104680980931491",
}

return ArayuzGorselleri
