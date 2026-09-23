--[[
	Satis  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > Satis

	Brainrot saticisinin ekran tarafi.

	NPC'ye E ile basinca SATIS PENCERESI acilir:
	    - envanterdeki satilabilir her brainrot fiyatiyla listelenir,
	      tiklayinca o brainrot satilir
	    - altta "Sell All" dugmesi hepsini birden satar

	ONAY: satis hemen yapilmaz; "Sell X for Y Rot?" sorusu cikar (Yes / No).
	"Don't ask again for 5 minutes" isaretlenirse o sure boyunca soru
	sorulmadan satilir.

	Brainrotu ELDE TUTMAK yok; eskiden ekranin altinda "E ile elindekini
	sat / F ile hepsini sat" seridi vardi, o kalkti. Fiyatlar oyuncuya ozel
	oldugu icin liste sunucudan geliyor ve her satistan sonra tazeleniyor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarity = require(Shared:WaitForChild("Rarity"))
local Format = require(Shared:WaitForChild("Format"))
local Net = require(Shared:WaitForChild("Net"))

local UI = require(script.Parent:WaitForChild("UI"))

local SaticiDurum = Net.event("SaticiDurum")
local BrainrotSat = Net.event("BrainrotSat")
local TumunuSat = Net.event("TumunuSat")

local screen = Instance.new("ScreenGui")
screen.Name = "SatisEkrani"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

------------------------------------------------------------------
-- PENCERE
------------------------------------------------------------------
local satilabilir: { any } = {}

local pencere = UI.panel(screen, UDim2.fromOffset(480, 470), "SaticiPenceresi")

UI.text({
	text = "Sell Brainrots",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	frameSize = UDim2.new(1, -80, 0, 36),
	position = UDim2.fromOffset(18, 14),
	parent = pencere,
})

local ozet = UI.text({
	text = "",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -80, 0, 20),
	position = UDim2.fromOffset(18, 50),
	parent = pencere,
})

UI.closeButton(pencere).MouseButton1Click:Connect(function()
	pencere.Visible = false
end)

-- Liste ile "Sell All" dugmesi arasinda pay birakilir
local liste = Instance.new("ScrollingFrame")
liste.Name = "Liste"
liste.Position = UDim2.fromOffset(14, 82)
liste.Size = UDim2.new(1, -28, 1, -158)
liste.BackgroundTransparency = 1
liste.BorderSizePixel = 0
liste.ScrollBarThickness = 5
liste.ScrollBarImageColor3 = UI.Colors.panelLight
liste.CanvasSize = UDim2.new()
liste.AutomaticCanvasSize = Enum.AutomaticSize.Y
liste.Parent = pencere
-- Satir konturlari sol kenarda kirpilmasin (bkz. UI.listePayi)
UI.listePayi(liste)

local listeDizilim = Instance.new("UIListLayout")
listeDizilim.Padding = UDim.new(0, 8)
listeDizilim.SortOrder = Enum.SortOrder.LayoutOrder
listeDizilim.Parent = liste

local hepsiButon = UI.button(pencere, "Sell All", UDim2.new(1, -36, 0, 48), UI.Colors.good)
hepsiButon.AnchorPoint = Vector2.new(0.5, 1)
hepsiButon.Position = UDim2.new(0.5, 0, 1, -18)
local hepsiYazi = hepsiButon:FindFirstChild("Label") :: TextLabel

------------------------------------------------------------------
-- ONAY PENCERESI
------------------------------------------------------------------
-- "Bir daha sorma" isaretlenince bu kadar saniye soru sorulmaz
local SORMA_SURESI = 5 * 60
local sormaBitis = 0

local onay = Instance.new("Frame")
onay.Name = "Onay"
onay.Size = UDim2.fromScale(1, 1)
onay.BackgroundColor3 = Color3.new(0, 0, 0)
onay.BackgroundTransparency = 0.35
onay.BorderSizePixel = 0
-- Arkadaki satirlara tiklanmasin
onay.Active = true
onay.Visible = false
onay.ZIndex = 20
onay.Parent = pencere
UI.corner(onay, 14)

local onayKutu = Instance.new("Frame")
onayKutu.AnchorPoint = Vector2.new(0.5, 0.5)
onayKutu.Position = UDim2.fromScale(0.5, 0.5)
onayKutu.Size = UDim2.fromOffset(400, 230)
onayKutu.BackgroundColor3 = UI.Colors.panel
onayKutu.BorderSizePixel = 0
onayKutu.ZIndex = 21
onayKutu.Parent = onay
UI.corner(onayKutu, 12)
UI.stroke(onayKutu, UI.Colors.gold, 2)

local onayBaslik = UI.text({
	text = "Are you sure?",
	size = UI.Sizes.heading,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -24, 0, 30),
	position = UDim2.fromOffset(12, 14),
	parent = onayKutu,
})
onayBaslik.ZIndex = 22

local onayYazi = UI.text({
	text = "",
	size = UI.Sizes.body,
	font = UI.Fonts.bold,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.new(1, -24, 0, 50),
	position = UDim2.fromOffset(12, 48),
	parent = onayKutu,
	wrapped = true,
})
onayYazi.ZIndex = 22
onayYazi.RichText = true

-- Isaret kutusu: "5 dakika sorma"
local isaret = Instance.new("TextButton")
isaret.Name = "Sorma"
isaret.Position = UDim2.fromOffset(24, 108)
isaret.Size = UDim2.new(1, -48, 0, 30)
isaret.BackgroundTransparency = 1
isaret.Text = ""
isaret.ZIndex = 22
isaret.Parent = onayKutu

local isaretKare = Instance.new("Frame")
isaretKare.Position = UDim2.fromOffset(0, 3)
isaretKare.Size = UDim2.fromOffset(24, 24)
isaretKare.BackgroundColor3 = UI.Colors.panelLight
isaretKare.BorderSizePixel = 0
isaretKare.ZIndex = 22
isaretKare.Parent = isaret
UI.corner(isaretKare, 6)
UI.stroke(isaretKare, Color3.fromRGB(0, 0, 0), 2)

local isaretTik = UI.text({
	text = "\u{2713}",
	size = UI.Sizes.label,
	font = UI.Fonts.bold,
	color = UI.Colors.good,
	align = Enum.TextXAlignment.Center,
	frameSize = UDim2.fromScale(1, 1),
	parent = isaretKare,
})
isaretTik.ZIndex = 23

local isaretYazi = UI.text({
	text = "Don't ask again for 5 minutes",
	size = UI.Sizes.small,
	color = UI.Colors.textDim,
	frameSize = UDim2.new(1, -34, 1, 0),
	position = UDim2.fromOffset(34, 0),
	parent = isaret,
})
isaretYazi.ZIndex = 22

local isaretli = false
local function isaretCiz()
	isaretTik.Visible = isaretli
end
isaretCiz()

isaret.MouseButton1Click:Connect(function()
	isaretli = not isaretli
	isaretCiz()
end)

local evet = UI.button(onayKutu, "Yes, Sell", UDim2.fromOffset(170, 50), UI.Colors.good)
evet.Position = UDim2.new(0.5, -178, 1, -66)
evet.ZIndex = 22
local hayir = UI.button(onayKutu, "No", UDim2.fromOffset(170, 50), Color3.fromRGB(200, 70, 80))
hayir.Position = UDim2.new(0.5, 8, 1, -66)
hayir.ZIndex = 22
for _, dugme in { evet, hayir } do
	UI.stroke(dugme, Color3.fromRGB(0, 0, 0), 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local etiket = dugme:FindFirstChild("Label")
	if etiket and etiket:IsA("TextLabel") then
		etiket.ZIndex = 23
	end
end

local bekleyenIs: (() -> ())? = nil

-- RichText icine giden adlar: & < > isaretleri yaziyi bozmasin
local function kacis(metin: string): string
	return (metin:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function onayKapat()
	onay.Visible = false
	bekleyenIs = nil
end

evet.MouseButton1Click:Connect(function()
	local is = bekleyenIs
	if isaretli then
		sormaBitis = os.clock() + SORMA_SURESI
	end
	onayKapat()
	if is then
		is()
	end
end)

hayir.MouseButton1Click:Connect(onayKapat)

-- Satistan once sorar; 5 dakikalik izin varsa dogrudan yapar
local function onayla(metin: string, is: () -> ())
	if os.clock() < sormaBitis then
		is()
		return
	end
	bekleyenIs = is
	onayYazi.Text = metin
	isaretli = false
	isaretCiz()
	onay.Visible = true
end

pencere:GetPropertyChangedSignal("Visible"):Connect(function()
	if not pencere.Visible then
		onayKapat()
	end
end)

local sonToplam = 0

hepsiButon.MouseButton1Click:Connect(function()
	if #satilabilir == 0 then
		return
	end
	onayla(
		`Sell <b>all {#satilabilir} brainrots</b> for <font color="#FFD629">{Format.short(sonToplam)} Rot</font>?`,
		function()
			TumunuSat:FireServer()
		end
	)
end)

local function listeyiCiz()
	for _, child in liste:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	if #satilabilir == 0 then
		UI.text({
			text = "Nothing to sell. Dig up some brainrots first.",
			size = UI.Sizes.small,
			color = UI.Colors.textDim,
			frameSize = UDim2.new(1, -6, 0, 40),
			parent = liste,
		})
		return
	end

	for index, item in satilabilir do
		local renk = Rarity.color(item.rarity)
		-- Kimligi belirlenmemis brainrotun adi yok, yalnizca kademesi bilinir
		local ad = item.name or `Unidentified {Rarity.displayName(item.rarity)}`

		local row = Instance.new("TextButton")
		row.Name = item.uid
		row.Text = ""
		row.AutoButtonColor = false
		row.Size = UDim2.new(1, -6, 0, 52)
		row.BackgroundColor3 = UI.Colors.panelLight
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = liste
		UI.corner(row, 10)
		UI.stroke(row, renk, 1)

		UI.text({
			text = ad,
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = renk,
			frameSize = UDim2.new(1, -150, 0, 22),
			position = UDim2.fromOffset(14, 6),
			parent = row,
		})

		UI.text({
			text = Rarity.displayName(item.rarity),
			size = UI.Sizes.tiny,
			color = UI.Colors.textDim,
			frameSize = UDim2.new(1, -150, 0, 18),
			position = UDim2.fromOffset(14, 28),
			parent = row,
		})

		UI.text({
			text = `+{Format.short(item.value)} Rot`,
			size = UI.Sizes.body,
			font = UI.Fonts.bold,
			color = UI.Colors.gold,
			align = Enum.TextXAlignment.Right,
			frameSize = UDim2.new(0, 130, 0, 52),
			position = UDim2.new(1, -144, 0, 0),
			parent = row,
		})

		row.MouseButton1Click:Connect(function()
			-- Sunucu satisi yapar ve listeyi tazeler; satilan satir bir
			-- sonraki pakette kendiliginden kaybolur
			onayla(
				`Sell <b>{kacis(ad)}</b> for <font color="#FFD629">{Format.short(item.value)} Rot</font>?`,
				function()
					BrainrotSat:FireServer(item.uid)
				end
			)
		end)

		UI.hover(row)
	end
end

------------------------------------------------------------------
-- SUNUCU PAKETI
------------------------------------------------------------------
SaticiDurum.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" or not data.near then
		-- Saticidan uzaklasinca pencere kapanir
		pencere.Visible = false
		return
	end

	satilabilir = if type(data.items) == "table" then data.items else {}

	local toplam = tonumber(data.totalValue) or 0
	sonToplam = toplam
	ozet.Text = `{#satilabilir} brainrots  --  {Format.short(toplam)} Rot total`

	if hepsiYazi then
		hepsiYazi.Text = if #satilabilir > 0
			then `Sell All  ({Format.short(toplam)} Rot)`
			else "Nothing To Sell"
	end
	hepsiButon.Active = #satilabilir > 0

	-- Prompt tetiklendiginde acilir; sonraki tazelemeler pencereyi acmaz
	if data.open then
		pencere.Visible = true
	end

	if pencere.Visible then
		listeyiCiz()
	end
end)
