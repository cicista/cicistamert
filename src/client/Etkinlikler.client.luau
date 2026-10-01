--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local GizemAyar = require(Shared:WaitForChild("SunucuIsini"))
local HavaAyar = require(Shared:WaitForChild("Hava"))

local UI = require(script.Parent:WaitForChild("UI"))
local SayacKarti = require(script.Parent:WaitForChild("SayacKarti"))

local BEYAZ = Color3.new(1, 1, 1)
local SIYAH = Color3.new(0, 0, 0)
local KIRMIZI = Color3.fromRGB(255, 80, 80)

local YAKIN = 60
local KENAR = 12
local KART_EN = 250
local KART_BOY = 76

local N = GizemAyar.Nitelik
local HN = HavaAyar.Nitelik

local screen = Instance.new("ScreenGui")
screen.Name = "Etkinlikler"
screen.DisplayOrder = 1
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local kap = Instance.new("Frame")
kap.Name = "Kap"
kap.AnchorPoint = Vector2.new(1, 0)
kap.Position = UDim2.new(1, -KENAR, 0, 120)
kap.Size = UDim2.fromOffset(KART_EN, 0)
kap.AutomaticSize = Enum.AutomaticSize.Y
kap.BackgroundTransparency = 1
kap.Parent = screen

local duzen = Instance.new("UIListLayout")
duzen.FillDirection = Enum.FillDirection.Vertical
duzen.Padding = UDim.new(0, 8)
duzen.SortOrder = Enum.SortOrder.LayoutOrder
duzen.HorizontalAlignment = Enum.HorizontalAlignment.Right
duzen.Parent = kap

type Kart = {
	cerceve: Frame,
	kontur: UIStroke,
	olcek: UIScale,
	rozet: TextLabel,
	rozetZemin: Frame,
	baslik: TextLabel,
	buyuk: TextLabel,
	alt: TextLabel,
}

local function kartKur(sira: number, renk: Color3): Kart
	local cerceve = Instance.new("Frame")
	cerceve.Name = `Kart{sira}`
	cerceve.Size = UDim2.fromOffset(KART_EN, KART_BOY)
	cerceve.BackgroundColor3 = BEYAZ
	cerceve.BorderSizePixel = 0
	cerceve.LayoutOrder = sira
	cerceve.Visible = false
	cerceve.Parent = kap
	UI.corner(cerceve, 14)
	local kontur = UI.stroke(cerceve, SIYAH, 3)
	kontur.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local zemin = Instance.new("UIGradient")
	zemin.Rotation = 90
	zemin.Color = ColorSequence.new(renk:Lerp(SIYAH, 0.55), renk:Lerp(SIYAH, 0.82))
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
	UI.pariltilar(ic, renk:Lerp(BEYAZ, 0.3), 8, 2)

	local rozetZemin = Instance.new("Frame")
	rozetZemin.Name = "Rozet"
	rozetZemin.AnchorPoint = Vector2.new(0.5, 0.5)
	rozetZemin.Position = UDim2.fromOffset(38, KART_BOY / 2)
	rozetZemin.Size = UDim2.fromOffset(56, 56)
	rozetZemin.BackgroundColor3 = renk:Lerp(SIYAH, 0.25)
	rozetZemin.BorderSizePixel = 0
	rozetZemin.ZIndex = 3
	rozetZemin.Parent = cerceve
	UI.corner(rozetZemin, 28)
	UI.stroke(rozetZemin, renk:Lerp(BEYAZ, 0.35), 2)

	local rozet = UI.text({
		text = "?",
		size = 30,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = rozetZemin,
		zIndex = 4,
	})

	local baslik = UI.text({
		text = "",
		size = UI.Sizes.small,
		font = UI.Fonts.bold,
		color = BEYAZ,
		glow = renk,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(170, 20),
		position = UDim2.fromOffset(74, 6),
		parent = cerceve,
		zIndex = 5,
	})

	local buyuk = UI.text({
		text = "",
		size = 26,
		font = UI.Fonts.bold,
		color = BEYAZ,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(170, 30),
		position = UDim2.fromOffset(74, 25),
		parent = cerceve,
		zIndex = 5,
	})

	local alt = UI.text({
		text = "",
		size = UI.Sizes.tiny,
		font = UI.Fonts.bold,
		color = renk:Lerp(BEYAZ, 0.4),
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(170, 18),
		position = UDim2.fromOffset(74, 54),
		parent = cerceve,
		zIndex = 5,
	})

	return {
		cerceve = cerceve,
		kontur = kontur,
		olcek = olcek,
		rozet = rozet,
		rozetZemin = rozetZemin,
		baslik = baslik,
		buyuk = buyuk,
		alt = alt,
	}
end

local gizemKarti = kartKur(1, GizemAyar.Renk)
gizemKarti.baslik.Text = GizemAyar.Ad

local havaKarti = SayacKarti.kur(kap, HavaAyar.BeklemeRengi)
havaKarti.cerceve.LayoutOrder = 0
local havaSlaytlari: { [string]: number } = {}
for _, tur in HavaAyar.Turler do
	havaSlaytlari[tur.id] = SayacKarti.modelSlayti(
		havaKarti,
		tur.renk,
		Assets.boyaliModel(HavaAyar.Model, tur.mutasyon),
		HavaAyar.ModelYakinligi,
		{ sekil = tur.sekil, renk = tur.parcacik }
	)
end
SayacKarti.dondur(havaKarti)

local function sure(saniye: number): string
	local s = math.max(0, math.floor(saniye))
	return string.format("%d:%02d", s // 60, s % 60)
end

local function sayi(ad: string): number
	local deger = Workspace:GetAttribute(ad)
	return if type(deger) == "number" then deger else 0
end

local function ekranAcik(ad: string): boolean
	local gui = playerGui:FindFirstChild(ad)
	return gui ~= nil and gui:IsA("ScreenGui") and gui.Enabled
end

local function yerlestir()
	local lucky = playerGui:FindFirstChild("LuckyYagmuru")
	local luckyKap = lucky and lucky:FindFirstChild("Kap")
	if luckyKap and luckyKap:IsA("GuiObject") and luckyKap.Visible and luckyKap.AbsoluteSize.Y > 0 then
		kap.Position = UDim2.fromOffset(
			luckyKap.AbsolutePosition.X + luckyKap.AbsoluteSize.X,
			luckyKap.AbsolutePosition.Y + luckyKap.AbsoluteSize.Y + 8 * UI.carpan()
		)
	else
		kap.Position = UDim2.new(1, -KENAR, 0, KENAR)
	end
end

local renkDuzeltme = Instance.new("ColorCorrectionEffect")
renkDuzeltme.Name = "HavaRengi"
renkDuzeltme.Enabled = false
renkDuzeltme.Parent = Lighting

local yagisParcasi = Instance.new("Part")
yagisParcasi.Name = "HavaYagisi"
yagisParcasi.Size = Vector3.new(140, 1, 140)
yagisParcasi.Transparency = 1
yagisParcasi.Anchored = true
yagisParcasi.CanCollide = false
yagisParcasi.CanQuery = false
yagisParcasi.CanTouch = false
yagisParcasi.CastShadow = false

local yagis = Instance.new("ParticleEmitter")
yagis.Name = "Yagis"
yagis.Texture = "rbxasset://textures/particles/sparkles_main.dds"
yagis.Rate = 0
yagis.Lifetime = NumberRange.new(3.5, 5.5)
yagis.Speed = NumberRange.new(10, 16)
yagis.EmissionDirection = Enum.NormalId.Bottom
yagis.SpreadAngle = Vector2.new(8, 8)
yagis.Rotation = NumberRange.new(0, 360)
yagis.RotSpeed = NumberRange.new(-90, 90)
yagis.LightEmission = 1
yagis.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.45),
	NumberSequenceKeypoint.new(1, 0.15),
})
yagis.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.1, 0.1),
	NumberSequenceKeypoint.new(0.85, 0.3),
	NumberSequenceKeypoint.new(1, 1),
})
yagis.Parent = yagisParcasi

local gosterilenHava = ""

local function havaGorunumu(tur: HavaAyar.HavaTuru?)
	local id = if tur then tur.id else ""
	if id == gosterilenHava then
		return
	end
	gosterilenHava = id

	local bilgi = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	if tur then
		renkDuzeltme.Enabled = true
		TweenService:Create(renkDuzeltme, bilgi, { TintColor = tur.gok, Saturation = 0.15, Brightness = 0.02 }):Play()
		yagis.Color = ColorSequence.new(tur.parcacik)
		yagis.Rate = 70
	else
		local donus = TweenService:Create(renkDuzeltme, bilgi, { TintColor = BEYAZ, Saturation = 0, Brightness = 0 })
		donus.Completed:Connect(function()
			if gosterilenHava == "" then
				renkDuzeltme.Enabled = false
			end
		end)
		donus:Play()
		yagis.Rate = 0
	end
end

local function nabiz(kart: Kart, t: number, hiz: number, guc: number)
	kart.olcek.Scale = 1 + math.sin(t * hiz) * guc
end

local function gizemGuncelle(simdi: number, t: number)
	local kart = gizemKarti
	local konum = Workspace:GetAttribute(N.konum)
	local bitis = sayi(N.bitis)
	local sonraki = sayi(N.sonraki)
	local kazan = Workspace:GetAttribute(N.kazan)

	local aktif = typeof(konum) == "Vector3" and bitis > simdi
	local bekleme = sonraki - simdi
	local yakin = not aktif and sonraki > 0 and bekleme <= YAKIN

	kart.cerceve.Visible = aktif or yakin
	if not kart.cerceve.Visible then
		return
	end

	local renk = Color3.fromHSV((t * 0.25) % 1, 0.55, 1)
	kart.rozetZemin.Rotation = math.sin(t * 3) * 10

	if aktif then
		local mesafe = "?"
		local karakter = player.Character
		local kok = karakter and karakter:FindFirstChild("HumanoidRootPart")
		if kok and kok:IsA("BasePart") then
			mesafe = `{math.floor(((konum :: Vector3) - kok.Position).Magnitude)}m`
		end

		if type(kazan) == "string" and kazan ~= "" then
			local kapisma = string.find(kazan, " VS ", 1, true) ~= nil
			kart.buyuk.Text = `{string.upper(kazan)}`
			kart.buyuk.TextColor3 = KIRMIZI
			kart.buyuk.TextScaled = kapisma
			kart.alt.Text = if kapisma then "CLASH IN PROGRESS!" else "IS DIGGING IT!"
		else
			kart.buyuk.TextScaled = false
			kart.buyuk.Text = `{mesafe}  {sure(bitis - simdi)}`
			kart.buyuk.TextColor3 = renk
			kart.alt.Text = "FIRST TO DIG WINS!"
		end
		kart.kontur.Color = renk
		kart.kontur.Thickness = 4
		nabiz(kart, t, 6, 0.03)
	else
		local yanip = math.sin(t * 10) > 0
		kart.buyuk.Text = `IN {sure(bekleme)}`
		kart.buyuk.TextColor3 = if yanip then GizemAyar.Renk else BEYAZ
		kart.alt.Text = `LANDS ON {string.upper(GizemAyar.AdaAdi)}`
		kart.kontur.Color = if yanip then GizemAyar.Renk else SIYAH
		kart.kontur.Thickness = 3
		nabiz(kart, t, 8, 0.04)
	end
end

local havaZemini: Color3? = nil
local havaSaniyesi = -1

local function havaGuncelle(simdi: number, t: number)
	local turId = Workspace:GetAttribute(HN.tur)
	local bitis = sayi(HN.bitis)
	local sonraki = sayi(HN.sonraki)

	local tur = if type(turId) == "string" and bitis > simdi then HavaAyar.get(turId) else nil
	havaGorunumu(tur)

	local siradakiId = Workspace:GetAttribute(HN.siradaki)
	local siradaki = if type(siradakiId) == "string" then HavaAyar.get(siradakiId) else nil

	local kart = havaKarti
	local gosterilen = tur or siradaki
	local zeminRengi = if gosterilen then gosterilen.renk else HavaAyar.BeklemeRengi
	if havaZemini ~= zeminRengi then
		havaZemini = zeminRengi
		SayacKarti.zeminRengi(kart, zeminRengi)
	end

	if tur then
		SayacKarti.sabitle(kart, havaSlaytlari[tur.id])
		kart.sayac.Text = SayacKarti.sure(bitis - simdi)
		SayacKarti.boya(kart, "aktif", t, tur.renk, tur.renk:Lerp(BEYAZ, 0.3))
		return
	end

	SayacKarti.sabitle(kart, if siradaki then havaSlaytlari[siradaki.id] else nil)
	local bekleme = math.max(0, sonraki - simdi)
	if sonraki > 0 and bekleme <= YAKIN then
		kart.sayac.Text = SayacKarti.sure(bekleme)
		SayacKarti.boya(kart, "yakin", t, HavaAyar.BeklemeRengi)
		local saniye = math.ceil(bekleme)
		if saniye ~= havaSaniyesi then
			havaSaniyesi = saniye
			SayacKarti.vurus(kart, if saniye <= 10 then 1.5 else 1.25)
		end
	else
		kart.sayac.Text = if sonraki > 0 then SayacKarti.sure(bekleme) else "--:--"
		SayacKarti.boya(kart, "bekle", t, HavaAyar.BeklemeRengi)
	end
end

RunService.Heartbeat:Connect(function()
	local kamera = Workspace.CurrentCamera
	if kamera and gosterilenHava ~= "" then
		if yagisParcasi.Parent ~= kamera then
			yagisParcasi.Parent = kamera
		end
		yagisParcasi.CFrame = CFrame.new(kamera.CFrame.Position + Vector3.new(0, 35, 0))
	end

	local simdi = Workspace:GetServerTimeNow()
	local t = os.clock()

	havaGuncelle(simdi, t)
	gizemGuncelle(simdi, t)

	kap.Visible = not (ekranAcik("KaziBar") or ekranAcik("KaziMinigame"))
	if kap.Visible then
		yerlestir()
	end
end)
