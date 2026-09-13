--!strict
--[[
	Tool seviyesi parlamasi.

	Kurek ve dedektor seviyeleri artik farkli GOVDE RENGI ile degil,
	sabit bir PARLAMA ile ayirt edilir:

	    Lv.1  yesil
	    Lv.2  mavi
	    Lv.3  mor
	    Lv.4  sari
	    Lv.5  kirmizi

	Parlama SKINDEN BAGIMSIZDIR: skin degistiginde govde gorunumu degisir,
	parlama rengi ayni kalir. Boylece uzaktan bakinca kimin kacinci seviye
	tool tasidigi her zaman belli olur.
]]

local LevelGlow = {}

LevelGlow.Colors = {
	[1] = Color3.fromRGB(80, 235, 120),
	[2] = Color3.fromRGB(70, 160, 255),
	[3] = Color3.fromRGB(180, 100, 255),
	[4] = Color3.fromRGB(255, 214, 60),
	[5] = Color3.fromRGB(255, 80, 80),
}

function LevelGlow.color(level: number): Color3
	-- Ada kurekleri adanin renginde parlar: Candy pembe, Snow buz mavisi, Volcano turuncu
	if level > 15 then
		return Color3.fromRGB(255, 140, 40)
	elseif level > 10 then
		return Color3.fromRGB(130, 215, 255)
	elseif level > 5 then
		return Color3.fromRGB(255, 120, 200)
	end
	return LevelGlow.Colors[math.clamp(level, 1, 5)] or LevelGlow.Colors[1]
end

--[[
	Tool'a seviye parlamasini uygular.
	Handle'a bir PointLight ve tool'un tamamina rengi veren bir Highlight
	konur. Ikisi de sabit isimlidir, boylece skin degisiminde yeniden
	uretilebilir ve ust uste birikmez.
]]
function LevelGlow.apply(tool: Tool, level: number)
	local handle = tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return
	end

	local color = LevelGlow.color(level)

	local oldLight = handle:FindFirstChild("LevelGlow")
	if oldLight then
		oldLight:Destroy()
	end

	local light = Instance.new("PointLight")
	light.Name = "LevelGlow"
	light.Color = color
	light.Range = 10
	light.Brightness = 2
	light.Parent = handle

	local oldHighlight = tool:FindFirstChild("LevelHighlight")
	if oldHighlight then
		oldHighlight:Destroy()
	end

	-- Kontur (border) YOK: eski hali duvar arkasindan gorunen bir cerceve
	-- ciziyordu. Artik yalnizca tool.un kendisi parlama renginde parliyor
	-- ve arkasinda kalan yuzeyler onu gizliyor (Occluded).
	local highlight = Instance.new("Highlight")
	highlight.Name = "LevelHighlight"
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = color
	highlight.FillTransparency = 0.55
	highlight.OutlineTransparency = 1
	highlight.Adornee = handle
	highlight.Parent = tool

	-- Client'in da bilmesi icin (envanter ekrani, skin dongusu)
	tool:SetAttribute("LevelGlow", color)
	tool:SetAttribute("Level", level)
end

return LevelGlow
