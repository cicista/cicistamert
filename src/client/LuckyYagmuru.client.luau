--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LuckyBlock = require(Shared:WaitForChild("LuckyBlock"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local UI = require(script.Parent:WaitForChild("UI"))
local LuckyOnizleme = require(script.Parent:WaitForChild("LuckyOnizleme"))
local SayacKarti = require(script.Parent:WaitForChild("SayacKarti"))
local Ipucu = require(script.Parent:WaitForChild("Ipucu"))

local E = LuckyBlock.Event

local ALTIN = Rarity.LuckyBlock.colorA
local SON_DAKIKA = 60

if not E.enabled then
	return
end

local screen = Instance.new("ScreenGui")
screen.Name = "LuckyYagmuru"
screen.DisplayOrder = 1
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local KENAR = 12

local kap = Instance.new("Frame")
kap.Name = "Kap"
kap.AnchorPoint = Vector2.new(1, 0)
kap.Position = UDim2.new(1, -KENAR, 0, KENAR)
kap.Size = UDim2.fromOffset(SayacKarti.EN, SayacKarti.BOY)
kap.BackgroundTransparency = 1
kap.Parent = screen

local kart = SayacKarti.kur(kap, Color3.fromRGB(110, 60, 180))
for _, tier in LuckyBlock.Tiers do
	SayacKarti.slaytEkle(kart, tier.color, function(kutu)
		LuckyOnizleme.ekle(kutu, tier, 6)
	end)
end
SayacKarti.dondur(kart)

local function nitelik(ad: string): number
	local deger = Workspace:GetAttribute(ad)
	return if type(deger) == "number" then deger else 0
end

local sonSaniye = -1

Ipucu.bagla(kart.cerceve, function()
	local simdi = Workspace:GetServerTimeNow()
	local bitis = nitelik(E.nitelikBitis)
	local kalan = nitelik(E.nitelikKalan)
	local sonraki = nitelik(E.nitelikSonraki)

	local satirlar: { string } = {}
	if kalan > 0 and bitis > simdi then
		table.insert(satirlar, `It's raining Lucky Blocks! {math.floor(kalan)} left on the islands.`)
		table.insert(satirlar, `Hop on your flyboard and grab one before they vanish ({SayacKarti.sure(bitis - simdi)} left).`)
	else
		table.insert(satirlar, "Every hour, Lucky Blocks drop on the islands.")
		if sonraki > 0 then
			table.insert(satirlar, `Next rain in {SayacKarti.sure(sonraki - simdi)}.`)
		end
	end
	table.insert(
		satirlar,
		`Each player can take {E.oyuncuBasiLimit} per rain. Open it from your backpack to win a random brainrot.`
	)
	table.insert(satirlar, "When the rain ends, a Mystery Beam drops on a random island!")

	return { baslik = "LUCKY BLOCK RAIN", renk = ALTIN, satirlar = satirlar }
end)

local function ekranAcik(ad: string): boolean
	local gui = playerGui:FindFirstChild(ad)
	return gui ~= nil and gui:IsA("ScreenGui") and gui.Enabled
end

local function yerlestir()
	if not UI.Girdi.dokunmatik() then
		kap.AnchorPoint = Vector2.new(1, 0)
		kap.Position = UDim2.new(1, -KENAR, 0, KENAR)
		return
	end

	local menuler = playerGui:FindFirstChild("OyunMenuleri")
	local sag = menuler and menuler:FindFirstChild("SagMenu")
	local magaza = playerGui:FindFirstChild("RobuxMagazasi")
	local store = magaza and magaza:FindFirstChild("StoreButonu")
	if not (sag and sag:IsA("GuiObject")) then
		kap.AnchorPoint = Vector2.new(1, 0)
		kap.Position = UDim2.new(1, -KENAR, 0, KENAR)
		return
	end

	local alt = sag.AbsolutePosition.Y + sag.AbsoluteSize.Y
	if store and store:IsA("GuiObject") and store.Visible then
		alt = math.max(alt, store.AbsolutePosition.Y + store.AbsoluteSize.Y)
	end
	kap.AnchorPoint = Vector2.new(1, 0)
	kap.Position = UDim2.fromOffset(sag.AbsolutePosition.X + sag.AbsoluteSize.X, alt + 8 * UI.carpan())
end

RunService.Heartbeat:Connect(function()
	kap.Visible = not (ekranAcik("KaziBar") or ekranAcik("KaziMinigame"))
	if not kap.Visible then
		return
	end

	local simdi = Workspace:GetServerTimeNow()
	local t = os.clock()

	local sonraki = nitelik(E.nitelikSonraki)
	local bitis = nitelik(E.nitelikBitis)
	local kalan = nitelik(E.nitelikKalan)

	local aktif = kalan > 0 and bitis > simdi
	local bekleme = math.max(0, sonraki - simdi)
	local yakin = not aktif and sonraki > 0 and bekleme <= SON_DAKIKA

	if aktif then
		kart.sayac.Text = SayacKarti.sure(bitis - simdi)
		SayacKarti.boya(kart, "aktif", t, ALTIN)
	elseif yakin then
		kart.sayac.Text = SayacKarti.sure(bekleme)
		SayacKarti.boya(kart, "yakin", t, ALTIN)
		local saniye = math.ceil(bekleme)
		if saniye ~= sonSaniye then
			sonSaniye = saniye
			SayacKarti.vurus(kart, if saniye <= 10 then 1.5 else 1.25)
		end
	else
		kart.sayac.Text = if sonraki > 0 then SayacKarti.sure(bekleme) else "--:--"
		SayacKarti.boya(kart, "bekle", t, ALTIN)
	end
end)

yerlestir()
UI.Girdi.degisince(yerlestir)
UI.onScaleChanged(yerlestir)
task.spawn(function()
	local menuler = playerGui:WaitForChild("OyunMenuleri", 30)
	local sag = menuler and menuler:WaitForChild("SagMenu", 10)
	local magaza = playerGui:WaitForChild("RobuxMagazasi", 30)
	local store = magaza and magaza:WaitForChild("StoreButonu", 10)
	for _, nesne in { sag, store } do
		if nesne and nesne:IsA("GuiObject") then
			nesne:GetPropertyChangedSignal("AbsolutePosition"):Connect(yerlestir)
			nesne:GetPropertyChangedSignal("AbsoluteSize"):Connect(yerlestir)
		end
	end
	yerlestir()
end)
