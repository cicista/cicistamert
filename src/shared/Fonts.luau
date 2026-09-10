--!strict
--[[
	Oyunun YAZI KIMLIGI -- tek kaynak.

	Hedeflenen gorunum: yuvarlak, kalin, siyah konturlu cizgi film yazisi
	(Steal a Brainrot / Pet Simulator tarzi). Roblox'ta bunun karsiligi
	FredokaOne + kalin bir UIStroke.

	Kontur TextStrokeTransparency ile DEGIL UIStroke ile yapilir: eski
	TextStroke kenarlari bulaniklastiriyor, UIStroke keskin kaliyor.

	Kalinlik yazi boyutuyla orantili: 14px yazida ince, 51px baslikta kalin.
	Kucuk yazilarda sabit kalin kontur harfleri birbirine yapistiriyordu.

	FONTU DEGISTIRMEK
	Asagidaki FAMILY satirini degistir, butun oyun birden degisir. Roblox'un
	hazir aileleri: FredokaOne, LuckiestGuy, Bangers, DenkOne, Montserrat...
]]

local Fonts = {}

-- Oyunun ana fontu
local FACE = Font.fromEnum(Enum.Font.FredokaOne)

Fonts.bold = FACE
Fonts.medium = FACE
Fonts.regular = FACE

Fonts.Outline = {
	color = Color3.fromRGB(0, 0, 0),
	-- Kontur kalinligi = yazi boyutu * ratio, min/max arasina sikistirilir
	ratio = 0.1,
	min = 1.2,
	max = 4,
}

function Fonts.strokeThickness(textSize: number): number
	local o = Fonts.Outline
	return math.clamp(textSize * o.ratio, o.min, o.max)
end

--[[
	Bir TextLabel'a oyunun standart konturunu ekler.
	Zaten kontur varsa yenisini uretmez, mevcut olani gunceller.
]]
function Fonts.applyOutline(label: TextLabel, thickness: number?): UIStroke
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Name = "Kontur"
	end

	local outline = stroke :: UIStroke
	outline.Color = Fonts.Outline.color
	outline.Thickness = thickness or Fonts.strokeThickness(label.TextSize)
	outline.Transparency = 0
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	outline.LineJoinMode = Enum.LineJoinMode.Round
	outline.Parent = label

	-- Eski bulanik kontur kapali kalsin
	label.TextStrokeTransparency = 1

	return outline
end

--[[
	PARLAK YAZI  --  mavinin (Rare) ustundeki kademeler

	Epic, Legendary, Mythic ve Divine brainrotlarin ISMI daha degerli
	gorunsun diye yaziya dikey bir parilti gradyani konur: ortasi kendi
	kademe renginde, uclari beyaza dogru acilir. Icinden isik geliyormus
	gibi durur.

	MODELLERE HICBIR EFEKT EKLENMEZ -- istek yalnizca yazilar icindi.

	NOT: UIGradient yazinin rengiyle CARPILIR. Bu yuzden TextColor3 beyaza
	cekilir ve rengi gradyan tasir; yoksa renk kendisiyle carpilip
	kararirdi. Bu fonksiyondan sonra TextColor3'u elle degistirirsen
	pariltiyi bozarsin -- rengi degistirmen gerekiyorsa yeniden cagir.
]]
function Fonts.applyGlow(label: TextLabel, color: Color3): UIGradient
	local existing = label:FindFirstChild("Parilti")
	if existing then
		existing:Destroy()
	end

	local bright = color:Lerp(Color3.new(1, 1, 1), 0.65)

	local gradient = Instance.new("UIGradient")
	gradient.Name = "Parilti"
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, bright),
		ColorSequenceKeypoint.new(0.5, color),
		ColorSequenceKeypoint.new(1, bright),
	})
	gradient.Parent = label

	label.TextColor3 = Color3.new(1, 1, 1)

	return gradient
end

-- Pariltiyi kaldirir; yazi duz kademe rengine doner.
function Fonts.clearGlow(label: TextLabel, color: Color3)
	local existing = label:FindFirstChild("Parilti")
	if existing then
		existing:Destroy()
	end
	label.TextColor3 = color
end

--[[
	Yaziyi tek adimda oyunun kimligine sokar: font + kontur.
	Sunucunun urettigi dunya etiketleri (hologram, tabela, slot) bunu kullanir.
]]
function Fonts.apply(label: TextLabel, thickness: number?): TextLabel
	label.FontFace = FACE
	Fonts.applyOutline(label, thickness)
	return label
end

return Fonts
