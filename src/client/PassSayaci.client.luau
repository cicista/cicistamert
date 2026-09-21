--!strict
--[[
	PassSayaci  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > PassSayaci

	Odulden cikan SURELI gecislerin kalan suresini ekranin sag ustunde
	gosterir: gecisin ikonu ve yanindaki geri sayim.

	    [kilic] 14:52      (Auto Clicker, 15 dakikalik)
	    [ok]    11:59:03   (Teleporter, 12 saatlik)

	SURE NITELIKTEN OKUNUYOR. Sunucu sureli hakki verirken bitis anini
	oyuncunun ustune yaziyor (bkz. Modules > SureliGecis):

	    player:GetAttribute("PassSure_AutoClicker")  -- os.time cinsinden

	Yani burasi sunucuya hic soru sormuyor; nitelik degisince satir cikiyor,
	sure bitince kendiliginden kayboluyor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Icons = require(Shared:WaitForChild("Icons"))
local Passler = require(Shared:WaitForChild("Passler"))

local UI = require(script.Parent:WaitForChild("UI"))

-- Sunucudaki onadla ayni (bkz. Modules > SureliGecis)
local SURE_ONADI = "PassSure_"

--[[
	Hangi gecis hangi ikonla gorunsun. Auto Clicker kazi minigame'inde
	calistigi icin kurek/kilic ikonu, Teleporter da kendi ikonuyla.
]]
local IKONLAR: { [string]: string } = {
	AutoClicker = "shovel",
	Teleporter = "teleporter",
}

local ekran = Instance.new("ScreenGui")
ekran.Name = "PassSayaci"
-- HUD katmani: menu butonlarinin ve panellerin altinda
ekran.DisplayOrder = 2
ekran.ResetOnSpawn = false
ekran.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ekran.Parent = playerGui

local liste = Instance.new("Frame")
liste.Name = "Sayaclar"
liste.AnchorPoint = Vector2.new(1, 0)
-- Sag ust: Store butonunun altinda kalacak kadar asagida
liste.Position = UDim2.new(1, -16, 0, 150)
liste.Size = UDim2.fromOffset(190, 0)
liste.AutomaticSize = Enum.AutomaticSize.Y
liste.BackgroundTransparency = 1
liste.Parent = ekran

local dizilim = Instance.new("UIListLayout")
dizilim.FillDirection = Enum.FillDirection.Vertical
dizilim.HorizontalAlignment = Enum.HorizontalAlignment.Right
dizilim.Padding = UDim.new(0, 6)
dizilim.SortOrder = Enum.SortOrder.LayoutOrder
dizilim.Parent = liste

-- Kalan sure: "14:52" ya da "11:59:03"
local function sureYazisi(saniye: number): string
	local t = math.max(0, math.floor(saniye))
	if t >= 3600 then
		return string.format("%d:%02d:%02d", t // 3600, (t % 3600) // 60, t % 60)
	end
	return string.format("%d:%02d", t // 60, t % 60)
end

type Satir = { kap: Frame, yazi: TextLabel }
local satirlar: { [string]: Satir } = {}

local function satirKur(gecisAdi: string, siraNo: number): Satir
	local info = Passler.get(gecisAdi)

	local kap = Instance.new("Frame")
	kap.Name = gecisAdi
	kap.Size = UDim2.fromOffset(150, 38)
	kap.BackgroundColor3 = Color3.fromRGB(26, 24, 36)
	kap.BorderSizePixel = 0
	kap.LayoutOrder = siraNo
	kap.Parent = liste
	UI.corner(kap, 10)
	UI.stroke(kap, Color3.fromRGB(255, 215, 60), 2)

	local ikon = Instance.new("ImageLabel")
	ikon.Name = "Ikon"
	ikon.AnchorPoint = Vector2.new(0, 0.5)
	ikon.Position = UDim2.new(0, 8, 0.5, 0)
	ikon.Size = UDim2.fromOffset(24, 24)
	ikon.BackgroundTransparency = 1
	ikon.ScaleType = Enum.ScaleType.Fit
	ikon.ZIndex = 5
	ikon.Parent = kap
	Icons.bind(ikon, IKONLAR[gecisAdi] or "shovel")

	local yazi = UI.text({
		text = "",
		size = UI.Sizes.body,
		font = UI.Fonts.bold,
		color = Color3.fromRGB(255, 225, 140),
		align = Enum.TextXAlignment.Left,
		frameSize = UDim2.new(1, -44, 1, 0),
		position = UDim2.fromOffset(40, 0),
		parent = kap,
		zIndex = 5,
	})
	yazi.Name = "Sure"

	if info then
		--[[
			Gecisin adi kutuya sigmiyor; uzerine gelince gorunsun diye
			ipucu olarak duruyor.
		]]
		kap.Name = info.ad
	end

	return { kap = kap, yazi = yazi }
end

local function tazele()
	local simdi = os.time()
	local sira = 0

	for gecisAdi in Passler.Info do
		sira += 1

		local bitis = player:GetAttribute(SURE_ONADI .. gecisAdi)
		local kalan = if type(bitis) == "number" then bitis - simdi else 0

		if kalan <= 0 then
			local satir = satirlar[gecisAdi]
			if satir then
				satir.kap:Destroy()
				satirlar[gecisAdi] = nil
			end
			continue
		end

		local satir = satirlar[gecisAdi]
		if not satir then
			satir = satirKur(gecisAdi, sira)
			satirlar[gecisAdi] = satir
		end
		satir.yazi.Text = sureYazisi(kalan)
	end
end

tazele()

task.spawn(function()
	while true do
		task.wait(1)
		tazele()
	end
end)
