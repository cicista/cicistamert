--!strict
--[[
	KADEME EFEKTI  --  her kademenin KENDINE OZGU cercevesi  (ModuleScript, istemci)
	Yeri: StarterPlayer > StarterPlayerScripts > KademeEfekti

	Lucky Block carkindaki bolmeler ve Index hucreleri ayni efekti kullanir.
	Her kademe ayri bir kimlik tasir; yukari ciktikca cerceve daha iddiali:

	  Common     gri, sade ince cerceve
	  Rare       mavi, yavasca kayan parlaklik
	  Epic       mor, nabiz atan cerceve + donen isik
	  Legendary  altin, donen beyaz isik + icte sicak isilti
	  Mythic     kirmizi, IKI isik bandi hizla doner + nabiz atan aura
	  Divine     kehribar <-> beyaz seritli cerceve + aura + altin kivilcimlar
	  Cosmic     mor <-> beyaz serit + aura + mor kivilcimlar
	  Secret     siyah <-> beyaz hizli serit + titreyen aura
	  Infernal   ates turuncusu <-> beyaz, daha hizli + kalin
	  Abyssal    derin mavi <-> beyaz, en hizli + en kalin

	Divine ve ustunun renk ciftleri Shared > Divine > Flashes'tan geliyor
	(dunyadaki etiketlerin parildamasiyla ayni renkler).

	KILITLI MOD (Index'te henuz bulunmamis brainrot)
	Cerceve BUTUN gosterisiyle calisir -- oyuncu neyi kacirdigini gorsun,
	heveslensin. Kapali oldugunu kilit rozeti ve gri onizleme soyluyor;
	burada yalnizca aura biraz daha sonuk.

	KULLANIM
	    local e = KademeEfekti.tak(kart, kartinKonturu, renk, rarityId, {
	        aura = "dis", auraKap = serit,        -- carkta: kartin arkasinda
	        -- ya da
	        aura = "ic", zemin = true,            -- Index'te: icte halka + renkli zemin
	        etkin = function() return panel.Visible end,  -- gorunmezken bosa calismasin
	    })
	    if e then
	        e.kilitli = true
	        KademeEfekti.yenile(e)
	    end

	Butun efektler TEK bir RenderStepped'te ilerliyor; kart silinince listeden
	kendiliginden dusuyor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarity = require(Shared:WaitForChild("Rarity"))
local Divine = require(Shared:WaitForChild("Divine"))

local UI = require(script.Parent:WaitForChild("UI"))

local KademeEfekti = {}

export type Secenek = {
	-- "dis": kartin arkasinda kardes cerceve (auraKap gerekli)
	-- "ic" : kartin icinde, kenara yakin parlayan halka
	aura: string?,
	auraKap: Instance?,
	-- Kartin zeminine alttan kademe rengi (Index hucresi gibi koyu kartlarda)
	zemin: boolean?,
	-- false donerse o karede efekt guncellenmez (panel kapali, ekran disi)
	etkin: (() -> boolean)?,
}

--[[
	Bir kademenin cerceve tarifi.
	  kalinlik : kontur kalinligi
	  isik     : konturda donen renk gecisi (nil = duz renk)
	  hiz      : isigin donus hizi (derece/sn)
	  nabiz    : kontur saydamligi nabiz atar mi
	  aura     : parlayan halka renkleri (nil = aura yok); iki renk arasinda gidip gelir
	  kivilcim : kosede parlayan kivilcim rengi (nil = yok)
	  zemin    : kart zeminine verilecek ton (nil = dokunma)
]]
type Tarif = {
	kalinlik: number,
	isik: ColorSequence?,
	hiz: number,
	nabiz: boolean,
	aura: { Color3 }?,
	kivilcim: Color3?,
	zemin: Color3?,
}

export type Efekt = {
	kart: GuiObject,
	seviye: number,
	faz: number,
	tarif: Tarif,
	cizgi: UIStroke,
	gecis: UIGradient?,
	aura: UIStroke?,
	kivilcimlar: { Frame },
	kilitli: boolean,
	etkin: (() -> boolean)?,
}

local BEYAZ = Color3.new(1, 1, 1)

local efektler: { Efekt } = {}

-- Tek renk + ortasinda dar beyaz isik bandi (adet kadar band)
local function isikBandi(renk: Color3, adet: number): ColorSequence
	local duraklar = { ColorSequenceKeypoint.new(0, renk) }
	for i = 1, adet do
		local orta = (i - 0.5) / adet
		table.insert(duraklar, ColorSequenceKeypoint.new(orta - 0.05, renk))
		table.insert(duraklar, ColorSequenceKeypoint.new(orta, BEYAZ))
		table.insert(duraklar, ColorSequenceKeypoint.new(orta + 0.05, renk))
	end
	table.insert(duraklar, ColorSequenceKeypoint.new(1, renk))
	return ColorSequence.new(duraklar)
end

-- Iki renk arasinda keskin seritler (Divine ve ustu)
local function seritler(a: Color3, b: Color3, adet: number): ColorSequence
	local duraklar = {}
	local adim = 1 / (adet * 2)
	for i = 0, adet * 2 - 1 do
		local renk = if i % 2 == 0 then a else b
		table.insert(duraklar, ColorSequenceKeypoint.new(i * adim, renk))
		table.insert(duraklar, ColorSequenceKeypoint.new(math.min(1, (i + 1) * adim - 0.004), renk))
	end
	-- ColorSequence son duragi 1 olmali
	duraklar[#duraklar] = ColorSequenceKeypoint.new(1, if (adet * 2 - 1) % 2 == 0 then a else b)
	return ColorSequence.new(duraklar)
end

-- Kademenin efekt seviyesi (Rarity.order; bilinmeyen kademe 0)
function KademeEfekti.seviye(rarityId: string?): number
	if not rarityId then
		return 0
	end
	local info = Rarity.Info[rarityId :: any]
	return if info then info.order else 0
end

local function tarifi(rarityId: string, renk: Color3): Tarif
	local seviye = KademeEfekti.seviye(rarityId)
	local parilti = Divine.Flashes[rarityId]

	-- Divine ve ustu: kendi renk cifti, seviye arttikca hizli ve kalin
	if parilti then
		local ust = seviye - 6 -- Divine 0 .. Abyssal 4
		return {
			kalinlik = 4 + ust * 0.5,
			-- ColorSequence en fazla 20 durak alir: serit cifti basina 4 -> en fazla 5 cift
			isik = seritler(parilti.colorA, parilti.colorB, math.min(3 + ust, 5)),
			hiz = 150 + ust * 45,
			nabiz = false,
			aura = { parilti.colorA, parilti.colorB },
			kivilcim = parilti.colorA:Lerp(BEYAZ, 0.35),
			zemin = parilti.colorA,
		}
	end

	if seviye >= 5 then
		-- Mythic
		return {
			kalinlik = 4,
			isik = isikBandi(renk, 2),
			hiz = 220,
			nabiz = false,
			aura = { renk, renk:Lerp(BEYAZ, 0.5) },
			kivilcim = nil,
			zemin = renk,
		}
	elseif seviye == 4 then
		-- Legendary
		return {
			kalinlik = 3.5,
			isik = isikBandi(renk, 1),
			hiz = 130,
			nabiz = false,
			aura = nil,
			kivilcim = nil,
			zemin = renk,
		}
	elseif seviye == 3 then
		-- Epic
		return {
			kalinlik = 3,
			isik = isikBandi(renk, 1),
			hiz = 80,
			nabiz = true,
			aura = nil,
			kivilcim = nil,
			zemin = nil,
		}
	elseif seviye == 2 then
		-- Rare: yavas kayan acik mavi parlaklik
		return {
			kalinlik = 2.5,
			isik = ColorSequence.new({
				ColorSequenceKeypoint.new(0, renk),
				ColorSequenceKeypoint.new(0.5, renk:Lerp(BEYAZ, 0.55)),
				ColorSequenceKeypoint.new(1, renk),
			}),
			hiz = 45,
			nabiz = false,
			aura = nil,
			kivilcim = nil,
			zemin = nil,
		}
	end

	-- Common: sade
	return {
		kalinlik = 2,
		isik = nil,
		hiz = 0,
		nabiz = false,
		aura = nil,
		kivilcim = nil,
		zemin = nil,
	}
end

-- Kilit durumuna gore sabit ozellikleri yazar (kalinlik, renk)
function KademeEfekti.yenile(e: Efekt)
	e.cizgi.Thickness = e.tarif.kalinlik
	e.cizgi.Transparency = 0
	if e.gecis then
		-- Gecis konturun rengiyle carpilir: taban beyaz olmali
		e.cizgi.Color = BEYAZ
	end
end

function KademeEfekti.tak(kart: GuiObject, cizgi: UIStroke, renk: Color3, rarityId: string?, secenek: Secenek?): Efekt?
	if not rarityId or KademeEfekti.seviye(rarityId) < 1 then
		return nil
	end
	local s = secenek or {}
	local tarif = tarifi(rarityId, renk)

	local e: Efekt = {
		kart = kart,
		seviye = KademeEfekti.seviye(rarityId),
		faz = math.random() * math.pi * 2,
		tarif = tarif,
		cizgi = cizgi,
		gecis = nil,
		aura = nil,
		kivilcimlar = {},
		kilitli = false,
		etkin = s.etkin,
	}

	cizgi.Color = renk

	-- Konturda donen isik / seritler
	if tarif.isik then
		local gecis = Instance.new("UIGradient")
		gecis.Name = "KademeIsigi"
		gecis.Color = tarif.isik
		gecis.Parent = cizgi
		e.gecis = gecis
	end

	-- Kart zemini: alttan kademe rengi yukselir (Index hucresi)
	if s.zemin and tarif.zemin then
		local zemin = Instance.new("UIGradient")
		zemin.Name = "KademeZemini"
		zemin.Rotation = 90
		zemin.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, UI.Colors.panelLight),
			ColorSequenceKeypoint.new(0.55, UI.Colors.panelLight:Lerp(tarif.zemin, 0.18)),
			ColorSequenceKeypoint.new(1, UI.Colors.panelLight:Lerp(tarif.zemin, 0.5)),
		})
		zemin.Parent = kart
		-- Gecis zemin rengiyle carpilir: taban beyaz
		kart.BackgroundColor3 = BEYAZ
	end

	-- Parlayan aura
	if tarif.aura and s.aura then
		local aura = Instance.new("Frame")
		aura.Name = "KademeAurasi"
		aura.BackgroundTransparency = 1
		aura.BorderSizePixel = 0

		if s.aura == "dis" and s.auraKap then
			--[[
				Kartin ARKASINDA kardes cerceve. Kartin cocugu olamazdi:
				cocuk her zaman ebeveyninin USTUNDE cizilir ve karti kapatirdi.
			]]
			aura.AnchorPoint = kart.AnchorPoint
			aura.Position = kart.Position - UDim2.fromOffset(5, 0)
			aura.Size = kart.Size + UDim2.fromOffset(10, 10)
			aura.ZIndex = 0
			aura.Parent = s.auraKap
			kart.Destroying:Connect(function()
				aura:Destroy()
			end)
		else
			--[[
				Kartin ICINDE, kenardan biraz iceride bir halka. Index hucresi
				kirpan bir kutunun icinde; distaki aura kesilirdi.
			]]
			aura.Position = UDim2.fromOffset(4, 4)
			aura.Size = UDim2.new(1, -8, 1, -8)
			aura.ZIndex = 6
			aura.Parent = kart
		end

		UI.corner(aura, 12)
		e.aura = UI.stroke(aura, tarif.aura[1], 6)
	end

	-- Kosede goz kirpan kivilcimlar
	local kivilcimRengi = tarif.kivilcim
	if kivilcimRengi then
		for i, kose in { Vector2.new(0.14, 0.1), Vector2.new(0.86, 0.16), Vector2.new(0.16, 0.58), Vector2.new(0.84, 0.5) } do
			local k = Instance.new("Frame")
			k.Name = `Kivilcim{i}`
			k.AnchorPoint = Vector2.new(0.5, 0.5)
			k.Position = UDim2.fromScale(kose.X, kose.Y)
			k.Size = UDim2.fromOffset(9, 9)
			k.Rotation = 45
			k.BackgroundColor3 = kivilcimRengi
			k.BorderSizePixel = 0
			k.ZIndex = 7
			k.Parent = kart
			UI.corner(k, 2)
			table.insert(e.kivilcimlar, k)
		end
	end

	KademeEfekti.yenile(e)
	table.insert(efektler, e)
	return e
end

local zaman = 0

RunService.RenderStepped:Connect(function(dt)
	if #efektler == 0 then
		return
	end
	zaman += dt
	local t = zaman

	for i = #efektler, 1, -1 do
		local e = efektler[i]
		if not e.kart.Parent then
			efektler[i] = efektler[#efektler]
			efektler[#efektler] = nil
			continue
		end

		local etkin = e.etkin
		if etkin and not etkin() then
			continue
		end

		local tarif = e.tarif
		local nabiz = (math.sin(t * 5 + e.faz) + 1) * 0.5

		if tarif.nabiz then
			e.cizgi.Transparency = nabiz * 0.5
		end

		local gecis = e.gecis
		if gecis and tarif.hiz > 0 then
			gecis.Rotation = (t * tarif.hiz + e.faz * 57) % 360
		end

		local aura = e.aura
		local auraRenk = tarif.aura
		if aura and auraRenk then
			-- Ust kademelerde aura daha hizli titrer
			local titreme = (math.sin(t * (5 + e.seviye) + e.faz) + 1) * 0.5
			local taban = if e.kilitli then 0.4 else 0.2
			aura.Transparency = taban + titreme * 0.55
			aura.Thickness = 4 + titreme * 5
			aura.Color = auraRenk[1]:Lerp(auraRenk[2], titreme)
		end

		for j, k in e.kivilcimlar do
			-- Her kivilcim kendi zamaninda parlayip soner, donerek
			local parilti = math.max(0, math.sin(t * 4 + e.faz + j * 1.7))
			k.BackgroundTransparency = 1 - parilti
			k.Rotation = 45 + t * 120
			local boy = 4 + parilti * 10
			k.Size = UDim2.fromOffset(boy, boy)
		end
	end
end)

return KademeEfekti
