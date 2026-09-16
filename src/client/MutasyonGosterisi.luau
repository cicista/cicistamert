--!strict
--[[
	MUTASYON GOSTERISI  (ModuleScript, istemci)
	Yeri: StarterPlayer > StarterPlayerScripts > MutasyonGosterisi

	Bir brainrotun mutasyonu ortaya ciktiginda ekranin ortasinda BUYUK
	harflerle, etkileyici bir yazi cikar:

	        GOLD MUTATION!
	    Tralalero Tralala  -  8x income

	Yazi buyuyerek belirir, sallanir, arkasinda mutasyon renginde bir
	parlama nabiz atar; birkac saniye sonra soner. Ust uste gelen
	mutasyonlar SIRAYLA gosterilir (Detective ayni anda birkac tane acabilir).

	Cagiranlar: Detective sonucu, Lucky Block carki, Fuse makinesi.

	    MutasyonGosterisi.goster(mutationId, brainrotAdi)

	Mutasyonsuz (Normal) cagrilar sessizce yok sayilir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mutations = require(Shared:WaitForChild("Mutations"))

local UI = require(script.Parent:WaitForChild("UI"))

local MutasyonGosterisi = {}

-- Yazinin ekranda kalma suresi (saniye)
local EKRANDA = 2.6

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local ekran = Instance.new("ScreenGui")
ekran.Name = "MutasyonGosterisi"
ekran.ResetOnSpawn = false
ekran.IgnoreGuiInset = true
ekran.DisplayOrder = 50
ekran.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ekran.Parent = playerGui

local kutu = Instance.new("Frame")
kutu.Name = "Kutu"
kutu.AnchorPoint = Vector2.new(0.5, 0.5)
kutu.Position = UDim2.fromScale(0.5, 0.36)
kutu.Size = UDim2.fromOffset(760, 190)
kutu.BackgroundTransparency = 1
kutu.Visible = false
kutu.Parent = ekran

local olcek = Instance.new("UIScale")
olcek.Parent = kutu

-- Arkadaki parlama: mutasyon renginde, ortasi dolu kenarlari seffaf bir elips
local parlama = Instance.new("Frame")
parlama.Name = "Parlama"
parlama.AnchorPoint = Vector2.new(0.5, 0.5)
parlama.Position = UDim2.fromScale(0.5, 0.45)
parlama.Size = UDim2.fromScale(1.1, 1.3)
parlama.BackgroundColor3 = Color3.new(1, 1, 1)
parlama.BorderSizePixel = 0
parlama.ZIndex = 1
parlama.Parent = kutu
UI.corner(parlama, 400)

local parlamaGecis = Instance.new("UIGradient")
parlamaGecis.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.35),
	NumberSequenceKeypoint.new(1, 1),
})
parlamaGecis.Parent = parlama

local baslik = UI.text({
	text = "",
	size = 72,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	align = Enum.TextXAlignment.Center,
	outline = false,
	frameSize = UDim2.new(1, 0, 0, 96),
	position = UDim2.fromOffset(0, 10),
	parent = kutu,
	name = "Baslik",
})
baslik.ZIndex = 3
local baslikKontur = UI.stroke(baslik, Color3.fromRGB(0, 0, 0), 5)

local alt = UI.text({
	text = "",
	size = UI.Sizes.title,
	font = UI.Fonts.bold,
	color = Color3.new(1, 1, 1),
	align = Enum.TextXAlignment.Center,
	outline = false,
	frameSize = UDim2.new(1, 0, 0, 40),
	position = UDim2.fromOffset(0, 112),
	parent = kutu,
	name = "Alt",
})
alt.ZIndex = 3
local altKontur = UI.stroke(alt, Color3.fromRGB(0, 0, 0), 3)

type Oge = { id: string, ad: string? }
local sira: { Oge } = {}
local oynuyor = false

local function oynat(oge: Oge)
	local bilgi = Mutations.get(oge.id)

	Mutations.untag(baslik)
	baslik.Text = `{string.upper(bilgi.displayName)} MUTATION!`
	baslik.TextColor3 = bilgi.color
	-- Galaxy / Hacker gibi canli renkler her karede degisir
	Mutations.tagIf(baslik, oge.id)

	alt.Text = if oge.ad then `{oge.ad}  -  {bilgi.multiplier}x income` else `{bilgi.multiplier}x income`
	parlama.BackgroundColor3 = bilgi.color

	for _, yazi in { baslik, alt } do
		yazi.TextTransparency = 0
	end
	baslikKontur.Transparency = 0
	altKontur.Transparency = 0
	parlama.BackgroundTransparency = 0

	kutu.Visible = true
	olcek.Scale = 0.2
	baslik.Rotation = 0

	-- Buyuyerek belirme: once biraz fazla, sonra yerine otur
	local buyu = TweenService:Create(olcek, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.15 })
	buyu:Play()
	buyu.Completed:Wait()
	TweenService:Create(olcek, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Scale = 1 }):Play()

	-- Sallanma ve parlama nabzi
	local salla = TweenService:Create(
		baslik,
		TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 5, true),
		{ Rotation = 5 }
	)
	baslik.Rotation = -5
	salla:Play()
	local nabiz = TweenService:Create(
		parlama,
		TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Size = UDim2.fromScale(1.3, 1.6) }
	)
	nabiz:Play()

	task.wait(EKRANDA)

	salla:Cancel()
	baslik.Rotation = 0
	local sonus = TweenInfo.new(0.4)
	for _, yazi in { baslik, alt } do
		TweenService:Create(yazi, sonus, { TextTransparency = 1 }):Play()
	end
	TweenService:Create(baslikKontur, sonus, { Transparency = 1 }):Play()
	TweenService:Create(altKontur, sonus, { Transparency = 1 }):Play()
	local son = TweenService:Create(parlama, sonus, { BackgroundTransparency = 1 })
	son:Play()
	son.Completed:Wait()

	nabiz:Cancel()
	parlama.Size = UDim2.fromScale(1.1, 1.3)
	kutu.Visible = false
	Mutations.untag(baslik)
end

function MutasyonGosterisi.goster(mutationId: string?, brainrotAdi: string?)
	if not mutationId or not Mutations.isSpecial(mutationId) then
		return
	end

	table.insert(sira, { id = mutationId, ad = brainrotAdi })
	if oynuyor then
		return
	end

	oynuyor = true
	task.spawn(function()
		while #sira > 0 do
			local oge = table.remove(sira, 1) :: Oge
			local ok, hata = pcall(oynat, oge)
			if not ok then
				warn(`[MutasyonGosterisi] {tostring(hata)}`)
				kutu.Visible = false
			end
		end
		oynuyor = false
	end)
end

return MutasyonGosterisi
