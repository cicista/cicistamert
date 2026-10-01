--!strict

local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("UI"))
local LuckyOnizleme = require(script.Parent:WaitForChild("LuckyOnizleme"))

local SayacKarti = {}

SayacKarti.EN = 160
SayacKarti.BOY = 64

local BEYAZ = Color3.new(1, 1, 1)
local SIYAH = Color3.new(0, 0, 0)

local MODEL = 58
local SLAYT_SURESI = 2.4
local KAYMA_SURESI = 0.45

export type Slayt = { kutu: Frame, renk: Color3 }

export type Kart = {
	cerceve: Frame,
	kontur: UIStroke,
	olcek: UIScale,
	zemin: UIGradient,
	modelAlani: Frame,
	kaydirici: Frame,
	huzmeler: Frame,
	hale: Frame,
	sayac: TextLabel,
	sayacOlcek: UIScale,
	slaytlar: { Slayt },
	simdiki: number,
	sabit: boolean,
}

function SayacKarti.sure(saniye: number): string
	local s = math.max(0, math.floor(saniye))
	if s >= 3600 then
		return string.format("%d:%02d:%02d", s // 3600, (s % 3600) // 60, s % 60)
	end
	return string.format("%02d:%02d", s // 60, s % 60)
end

function SayacKarti.zeminRengi(kart: Kart, renk: Color3)
	kart.zemin.Color = ColorSequence.new(renk:Lerp(SIYAH, 0.45), renk:Lerp(SIYAH, 0.8))
end

local function efektRengi(kart: Kart, renk: Color3)
	for _, kap in { kart.huzmeler, kart.hale } do
		for _, parca in kap:GetDescendants() do
			if parca:IsA("Frame") then
				TweenService:Create(parca, TweenInfo.new(KAYMA_SURESI), { BackgroundColor3 = renk }):Play()
			end
		end
	end
end

function SayacKarti.kur(parent: GuiObject, renk: Color3, rakam: boolean?): Kart
	local cerceve = Instance.new("Frame")
	cerceve.Name = "Kart"
	cerceve.Size = UDim2.fromOffset(SayacKarti.EN, SayacKarti.BOY)
	cerceve.BackgroundColor3 = BEYAZ
	cerceve.BorderSizePixel = 0
	cerceve.Parent = parent
	UI.corner(cerceve, 14)
	local kontur = UI.stroke(cerceve, SIYAH, 3)
	kontur.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local zemin = Instance.new("UIGradient")
	zemin.Rotation = 90
	zemin.Parent = cerceve

	local olcek = Instance.new("UIScale")
	olcek.Parent = cerceve

	local ic = Instance.new("Frame")
	ic.Name = "Ic"
	ic.Size = UDim2.fromScale(1, 1)
	ic.BackgroundTransparency = 1
	ic.ClipsDescendants = true
	ic.Parent = cerceve
	UI.corner(ic, 14)
	UI.caprazDesen(ic, BEYAZ, 6)
	UI.pariltilar(ic, renk:Lerp(BEYAZ, 0.3), 6, 2, rakam)

	local modelAlani = Instance.new("Frame")
	modelAlani.Name = "Model"
	modelAlani.AnchorPoint = Vector2.new(0.5, 0.5)
	modelAlani.Position = UDim2.fromOffset(36, SayacKarti.BOY / 2)
	modelAlani.Size = UDim2.fromOffset(MODEL, MODEL)
	modelAlani.BackgroundTransparency = 1
	modelAlani.ZIndex = 4
	modelAlani.Parent = cerceve

	local huzmeler = UI.isikHuzmeleri(modelAlani, renk, {
		sayi = 10,
		uzunluk = 54,
		kalinlik = 12,
		tur = 10,
		parlaklik = 0.3,
		zIndex = 3,
	})
	huzmeler.Position = UDim2.fromScale(0.5, 0.5)
	local hale = UI.parlama(modelAlani, renk, 66, 3)

	local kaydirici = Instance.new("Frame")
	kaydirici.Name = "Kaydirici"
	kaydirici.AnchorPoint = Vector2.new(0.5, 0.5)
	kaydirici.Position = UDim2.fromScale(0.5, 0.5)
	kaydirici.Size = UDim2.fromScale(1, 1)
	kaydirici.BackgroundTransparency = 1
	kaydirici.ClipsDescendants = true
	kaydirici.ZIndex = 5
	kaydirici.Parent = modelAlani

	local sayac = UI.text({
		text = "--:--",
		size = 30,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(SayacKarti.EN - 72, SayacKarti.BOY),
		position = UDim2.fromOffset(68, 0),
		parent = cerceve,
		zIndex = 7,
	})
	local sayacOlcek = Instance.new("UIScale")
	sayacOlcek.Parent = sayac

	local kart: Kart = {
		cerceve = cerceve,
		kontur = kontur,
		olcek = olcek,
		zemin = zemin,
		modelAlani = modelAlani,
		kaydirici = kaydirici,
		huzmeler = huzmeler,
		hale = hale,
		sayac = sayac,
		sayacOlcek = sayacOlcek,
		slaytlar = {},
		simdiki = 1,
		sabit = false,
	}
	SayacKarti.zeminRengi(kart, renk)
	return kart
end

function SayacKarti.slaytEkle(kart: Kart, renk: Color3, doldur: (Frame) -> ()): number
	local sira = #kart.slaytlar + 1
	local kutu = Instance.new("Frame")
	kutu.Name = `Slayt{sira}`
	kutu.AnchorPoint = Vector2.new(0.5, 0.5)
	kutu.Position = UDim2.fromScale(if sira == 1 then 0.5 else 1.5, 0.5)
	kutu.Size = UDim2.fromScale(1, 1)
	kutu.BackgroundTransparency = 1
	kutu.ZIndex = 5
	kutu.Parent = kart.kaydirici
	doldur(kutu)
	table.insert(kart.slaytlar, { kutu = kutu, renk = renk })
	if sira == 1 then
		efektRengi(kart, renk)
	end
	return sira
end

function SayacKarti.modelSlayti(kart: Kart, renk: Color3, model: Model?): number
	return SayacKarti.slaytEkle(kart, renk, function(kutu)
		if not model or not LuckyOnizleme.modelEkle(kutu, model, 6) then
			local top = Instance.new("Frame")
			top.AnchorPoint = Vector2.new(0.5, 0.5)
			top.Position = UDim2.fromScale(0.5, 0.5)
			top.Size = UDim2.fromScale(0.6, 0.6)
			top.BackgroundColor3 = renk
			top.BorderSizePixel = 0
			top.ZIndex = 6
			top.Parent = kutu
			UI.corner(top, 100)
			UI.stroke(top, BEYAZ, 2)
		end
	end)
end

local function gec(kart: Kart, hedef: number, animasyon: boolean)
	if hedef == kart.simdiki or not kart.slaytlar[hedef] then
		return
	end
	local eski = kart.slaytlar[kart.simdiki]
	local yeni = kart.slaytlar[hedef]
	kart.simdiki = hedef

	if not animasyon then
		eski.kutu.Position = UDim2.fromScale(1.5, 0.5)
		yeni.kutu.Position = UDim2.fromScale(0.5, 0.5)
		efektRengi(kart, yeni.renk)
		return
	end

	yeni.kutu.Position = UDim2.fromScale(1.5, 0.5)
	local bilgi = TweenInfo.new(KAYMA_SURESI, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(eski.kutu, bilgi, { Position = UDim2.fromScale(-0.5, 0.5) }):Play()
	TweenService:Create(yeni.kutu, bilgi, { Position = UDim2.fromScale(0.5, 0.5) }):Play()
	efektRengi(kart, yeni.renk)
end

function SayacKarti.sabitle(kart: Kart, sira: number?)
	kart.sabit = sira ~= nil
	if sira then
		gec(kart, sira, true)
	end
end

function SayacKarti.dondur(kart: Kart)
	task.spawn(function()
		while kart.cerceve.Parent do
			task.wait(SLAYT_SURESI)
			if not kart.sabit and #kart.slaytlar > 1 then
				gec(kart, kart.simdiki % #kart.slaytlar + 1, true)
			end
		end
	end)
end

function SayacKarti.vurus(kart: Kart, guc: number)
	kart.sayacOlcek.Scale = guc
	TweenService:Create(
		kart.sayacOlcek,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()
end

export type Durum = "aktif" | "yakin" | "bekle"

function SayacKarti.boya(kart: Kart, durum: Durum, t: number, renk: Color3, aktifRenk: Color3?)
	kart.huzmeler.Rotation = (t * (if durum == "bekle" then 25 else 90)) % 360

	if durum == "aktif" then
		local parlak = aktifRenk or Color3.fromHSV((t * 0.3) % 1, 0.6, 1)
		kart.sayac.TextColor3 = parlak
		kart.sayac.Rotation = 0
		kart.kontur.Color = parlak
		kart.kontur.Thickness = 4
		kart.olcek.Scale = 1 + math.sin(t * 6) * 0.03
	elseif durum == "yakin" then
		local yanip = math.sin(t * 10) > 0
		kart.sayac.TextColor3 = if yanip then Color3.fromRGB(255, 70, 70) else renk
		kart.sayac.Rotation = math.sin(t * 30) * 3
		kart.kontur.Color = if yanip then Color3.fromRGB(255, 70, 70) else renk
		kart.kontur.Thickness = 4
		kart.olcek.Scale = 1 + math.sin(t * 8) * 0.04
	else
		kart.sayac.TextColor3 = BEYAZ
		kart.sayac.Rotation = 0
		kart.kontur.Color = SIYAH
		kart.kontur.Thickness = 3
		kart.olcek.Scale = 1
	end
end

return SayacKarti
