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
	SansX2 = {
		id = 0,
		fiyat = 399,
		ad = "2x Luck",
		aciklama = "Permanently doubles your luck when digging and fishing.",
		nitelik = "Pass_SansX2",
	},
	RotX15 = {
		id = 0,
		fiyat = 249,
		ad = "1.5x Rot",
		aciklama = "Your base earns 50% more Rot, forever.",
		nitelik = "Pass_RotX15",
	},
} :: { [string]: PassInfo }

Passler.SansCarpani = 2

Passler.RotCarpani = 1.5

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

function Passler.sansCarpani(player: Player): number
	return if Passler.sahip(player, "SansX2") then Passler.SansCarpani else 1
end

function Passler.rotCarpani(player: Player): number
	return if Passler.sahip(player, "RotX15") then Passler.RotCarpani else 1
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
