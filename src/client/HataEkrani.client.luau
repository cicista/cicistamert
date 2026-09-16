--[[
	HataEkrani  (LocalScript)  --  YALNIZCA STUDIO
	Yeri: StarterPlayer > StarterPlayerScripts > HataEkrani

	Hata ve uyarilari oyun ekraninin sag altinda gosterir; Output penceresini
	acmadan hangi scriptin nerede bozuldugu gorulsun diye.

	    - istemcideki hata / uyarilar (script baslamadan onceki gecmis dahil)
	    - sunucudaki hata / uyarilar (ServerScriptService > HataIletici yollar)

	GURULTU GOSTERILMEZ: bizim kodumuzla ilgisi olmayan bilinen mesajlar
	(Studio'da DataStore kapali, ikon paketinde olmayan ikon) ayiklanir.
	Kutu X ile kapanir; yeni hata gelmezse 20 saniye sonra kendiliginden
	gizlenir, yeni hata gelince tekrar acilir.

	Hicbir modul kullanmaz: diger scriptler bozuk olsa da calisir.
	Yayinlanan oyunda (Studio disinda) hicbir sey yapmaz.
]]

local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--[[
	KAPALI: ekip hata kutusunu Studio'da da gormek istemiyor. Hatalar yine
	Output penceresinde. Tekrar acmak icin ACIK = true yap (HataEkrani ve
	HataIletici ikisinde de).
]]
local ACIK = false
if not ACIK then
	return
end

if not RunService:IsStudio() then
	return
end

local EN_FAZLA = 14
local KENDILIGINDEN_KAPANMA = 20

-- Gosterilmeyecek bilinen mesajlar (duz metin parcasi)
local YOKSAY = {
	"StudioAccessToApisNotAllowed", -- Studio'da DataStore izni kapali (Oyun Ayarlari > Guvenlik)
	"ikon hazir, BULUNAMAYAN", -- ikon paketinde olmayan ikon; kullanilmiyor
	"HataEkrani",
}

local ekran = Instance.new("ScreenGui")
ekran.Name = "HataEkrani"
ekran.ResetOnSpawn = false
ekran.DisplayOrder = 100
ekran.IgnoreGuiInset = true
ekran.Enabled = false
ekran.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local kutu = Instance.new("TextLabel")
kutu.AnchorPoint = Vector2.new(1, 1)
kutu.Position = UDim2.new(1, -10, 1, -10)
kutu.Size = UDim2.new(0.45, 0, 0.3, 0)
kutu.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
kutu.BackgroundTransparency = 0.15
kutu.TextColor3 = Color3.fromRGB(255, 255, 255)
kutu.Font = Enum.Font.Code
kutu.TextSize = 13
kutu.TextWrapped = true
kutu.TextXAlignment = Enum.TextXAlignment.Left
kutu.TextYAlignment = Enum.TextYAlignment.Top
kutu.Parent = ekran

local kapat = Instance.new("TextButton")
kapat.AnchorPoint = Vector2.new(1, 0)
kapat.Position = UDim2.new(1, -4, 0, 4)
kapat.Size = UDim2.fromOffset(28, 28)
kapat.BackgroundColor3 = Color3.fromRGB(190, 50, 60)
kapat.Text = "X"
kapat.TextColor3 = Color3.new(1, 1, 1)
kapat.Font = Enum.Font.GothamBold
kapat.TextSize = 16
kapat.Parent = kutu

local satirlar: { string } = {}
local sonHata = 0

kapat.MouseButton1Click:Connect(function()
	ekran.Enabled = false
end)

local function yoksay(mesaj: string): boolean
	for _, parca in YOKSAY do
		if string.find(mesaj, parca, 1, true) then
			return true
		end
	end
	return false
end

local function ekle(kaynak: string, mesaj: string, tur: Enum.MessageType)
	if tur ~= Enum.MessageType.MessageError and tur ~= Enum.MessageType.MessageWarning then
		return
	end
	if yoksay(mesaj) then
		return
	end
	local etiket = if tur == Enum.MessageType.MessageError then "HATA" else "uyari"
	local satir = `[{kaynak} {etiket}] {mesaj}`
	-- Ayni mesaj tekrar gelince listeyi sisirmesin
	if table.find(satirlar, satir) then
		return
	end
	table.insert(satirlar, satir)
	while #satirlar > EN_FAZLA do
		table.remove(satirlar, 1)
	end
	kutu.Text = "HATA EKRANI (yalnizca Studio)\n\n" .. table.concat(satirlar, "\n")
	ekran.Enabled = true

	sonHata = os.clock()
	local bu = sonHata
	task.delay(KENDILIGINDEN_KAPANMA, function()
		if sonHata == bu then
			ekran.Enabled = false
		end
	end)
end

for _, kayit in LogService:GetLogHistory() do
	ekle("istemci", kayit.message, kayit.messageType)
end

LogService.MessageOut:Connect(function(mesaj, tur)
	ekle("istemci", mesaj, tur)
end)

task.spawn(function()
	local olay = ReplicatedStorage:WaitForChild("HataIletici", 30)
	if olay and olay:IsA("RemoteEvent") then
		olay.OnClientEvent:Connect(function(mesaj, turAdi)
			local tur = if turAdi == "MessageError" then Enum.MessageType.MessageError else Enum.MessageType.MessageWarning
			ekle("SUNUCU", tostring(mesaj), tur)
		end)
	end
end)
