--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("Hava"))
local Net = require(Shared:WaitForChild("Net"))

local Bildirim = Net.event("Bildirim")
local Duyuru = Net.event("Duyuru")

local Hava = {}

local rng = Random.new()

local aktif: Ayar.HavaTuru? = nil
local bitis = 0
local siradaki: Ayar.HavaTuru = Ayar.sec(rng)

local function yayinla()
	Workspace:SetAttribute(Ayar.Nitelik.tur, if aktif then aktif.id else "")
	Workspace:SetAttribute(Ayar.Nitelik.bitis, if aktif then bitis else 0)
	Workspace:SetAttribute(Ayar.Nitelik.siradaki, siradaki.id)
end

function Hava.aktif(): Ayar.HavaTuru?
	if aktif and os.time() < bitis then
		return aktif
	end
	return nil
end

function Hava.mutasyon(zar: Random): string?
	local tur = Hava.aktif()
	if tur and zar:NextNumber() * 100 < tur.sans then
		return tur.mutasyon
	end
	return nil
end

function Hava.baslat(id: string?, sure: number?): Ayar.HavaTuru
	local tur = Ayar.get(id)
	if not tur then
		tur = siradaki
		siradaki = Ayar.sec(rng)
	end
	aktif = tur
	bitis = os.time() + (sure or tur.sure or Ayar.Sure)
	yayinla()

	Duyuru:FireAllClients({
		tur = "sunucu",
		renk = tur.renk,
		ust = "WEATHER EVENT",
		buyuk = `{string.upper(tur.ad)}!`,
	})
	Bildirim:FireAllClients(`{string.upper(tur.ad)}! {Ayar.aciklama(tur)}`, tur.renk)

	return tur
end

function Hava.durdur(): boolean
	local tur = aktif
	if not tur then
		return false
	end
	aktif = nil
	bitis = 0
	yayinla()
	Bildirim:FireAllClients(`The {tur.ad} is over.`, tur.renk)
	return true
end

local calisti = false

function Hava.calistir()
	if calisti then
		return
	end
	calisti = true

	yayinla()

	task.spawn(function()
		local sonraki = Ayar.sonraki(os.time())
		local uyarilan: { [number]: boolean } = {}

		while true do
			local simdi = os.time()
			Workspace:SetAttribute(Ayar.Nitelik.sonraki, sonraki)

			if aktif and simdi >= bitis then
				Hava.durdur()
			end

			local kalan = sonraki - simdi
			for _, esik in Ayar.UyariSaniyeleri do
				if kalan <= esik and kalan > esik - 5 and not uyarilan[esik] then
					uyarilan[esik] = true
					Bildirim:FireAllClients("A weather event starts in 1 minute! Get ready to dig!", Color3.fromRGB(150, 220, 255))
				end
			end

			if simdi >= sonraki then
				sonraki = Ayar.sonraki(simdi)
				table.clear(uyarilan)
				if not Hava.aktif() then
					Hava.baslat()
				end
			end

			task.wait(1)
		end
	end)
end

return Hava
