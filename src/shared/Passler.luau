--!strict

local Passler = {}

export type PassInfo = {
	id: number,
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

function Passler.satista(ad: string): boolean
	local info = Passler.Info[ad]
	return info ~= nil and info.id > 0
end

function Passler.sahip(player: Player, ad: string): boolean
	local info = Passler.Info[ad]
	return info ~= nil and player:GetAttribute(info.nitelik) == true
end

function Passler.adiniBul(id: number): string?
	for ad, info in Passler.Info do
		if info.id > 0 and info.id == id then
			return ad
		end
	end
	return nil
end

return Passler
