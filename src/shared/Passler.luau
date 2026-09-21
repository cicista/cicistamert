--!strict
--[[
	ROBUX GECISLERI (Game Pass)  --  tek yerden

	Her gecisin sahipligi SUNUCUDA ogrenilir ve oyuncunun ustune nitelik
	olarak yazilir (orn. player:GetAttribute("Pass_Teleporter")). Istemci
	ve diger sunucu scriptleri yalnizca bu niteligi okur.

	--------------------------------------------------------------
	GECISI BAGLAMAK  (her gecis icin bir kez)

	  1. create.roblox.com > deneyim > Monetization > Passes > Create
	  2. Fiyatini asagidaki 'fiyat' ile ayni yap (yalnizca arayuzde yazar)
	  3. Adres cubugundaki .../passes/<ID>/... sayisini 'id'ye yaz

	id = 0 iken gecis SATILMAZ: dugme gorunur, basinca "Coming soon!"
	der. Kimseye bedava verilmez.

	--------------------------------------------------------------
	TEST

	Studio'da denemek icin Admin paneli > PASSES bolumundeki dugmeler
	gecisi o oturum icin verir/geri alir (kayda yazilmaz).

	TEST_STUDIO = true yapilirsa Studio'da herkes butun gecislere sahip
	sayilir. Yayindaki oyunu hicbir durumda etkilemez.
]]

local Passler = {}

export type PassInfo = {
	id: number,
	-- Arayuzde yazan Robux fiyati
	fiyat: number,
	ad: string,
	aciklama: string,
	nitelik: string,
}

Passler.Info = {
	AutoClicker = {
		id = 0,
		fiyat = 500,
		ad = "Auto Clicker",
		aciklama = "Your shovel digs by itself during the dig minigame.",
		nitelik = "Pass_AutoClicker",
	},
	Teleporter = {
		id = 0,
		fiyat = 250,
		ad = "Teleporter",
		aciklama = "Teleport to any island you have unlocked, from anywhere.",
		nitelik = "Pass_Teleporter",
	},
	--[[
		DETECTIVE PASS

		Kazidan ve oltadan cikan brainrotlar dedektife ugramadan kimligi
		ACIK gelir. Dedektifin kendisi yine duruyor: pass'siz oyuncular ve
		mutasyon acma isi ona kaliyor.
	]]
	DetectivePass = {
		id = 0,
		fiyat = 350,
		ad = "Detective Pass",
		aciklama = "Everything you dig or fish comes already identified.",
		nitelik = "Pass_DetectivePass",
	},
} :: { [string]: PassInfo }

Passler.TEST_STUDIO = false

function Passler.get(ad: string): PassInfo?
	return Passler.Info[ad]
end

-- Gecis satisa acik mi (ID girilmis mi)
function Passler.satista(ad: string): boolean
	local info = Passler.Info[ad]
	return info ~= nil and info.id > 0
end

-- Oyuncu bu gecise sahip mi (iki tarafta da calisir)
function Passler.sahip(player: Player, ad: string): boolean
	local info = Passler.Info[ad]
	return info ~= nil and player:GetAttribute(info.nitelik) == true
end

-- Bir gecis kimligine karsilik gelen ad
function Passler.adiniBul(id: number): string?
	for ad, info in Passler.Info do
		if info.id > 0 and info.id == id then
			return ad
		end
	end
	return nil
end

return Passler
