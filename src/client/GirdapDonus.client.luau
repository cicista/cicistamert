--[[
	Girdap Donusu  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > GirdapDonus

	Denizdeki girdaplari YATAYDA cevirir.

	NEDEN ISTEMCIDE
	Donus tamamen gorsel. Sunucuda cevirseydik her karede modelin CFrame'i
	butun oyunculara replike olurdu -- birkac girdap icin ciddi trafik.
	Burada her oyuncu kendi ekranindaki kopyayi ceviriyor; parcalar zaten
	Anchored oldugu icin sunucuyla cakismiyor.

	NEDEN TEK EKSEN
	Paketin kendi dondurme scriptleri modeli kendi yerel eksenlerinde
	ceviriyordu ve girdap yan yatmis gibi donuyordu. O scriptler efekt
	kurulurken siliniyor (bkz. Assets.stripScripts); burada yalnizca
	DUNYA Y ekseni etrafinda cevriliyor, yani girdap her zaman su
	yuzeyine paralel doner.

	Hiz sunucudan geliyor (DonusHizi niteligi, derece/saniye).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("OyunConfig"))

local W = Config.WhirlVFX
local TAG = W.spinTag

--[[
	Her model icin BASLANGIC durusu ve o ana kadarki aci saklanir.

	Baslangic durusu bir kez okunuyor: her karede GetPivot ile okuyup
	uzerine eklemek kayan hatalari biriktirir ve model yavasca suruklenir.
	Sabit bir tabana aci eklemek bu sorunu tamamen ortadan kaldirir.
]]
type Kayit = { taban: CFrame, aci: number }
local kayitlar: { [Model]: Kayit } = {}

local function ekle(node: Instance)
	if not node:IsA("Model") then
		return
	end

	local model = node :: Model

	--[[
		Modelin parcalari efekt kurulurken tek tek yerlestiriliyor; etiket
		eklendigi an pivot henuz son yerinde olmayabilir. Bir kare beklemek
		tabanin dogru okunmasini garantiler.
	]]
	task.defer(function()
		if not model.Parent then
			return
		end

		local ok, pivot = pcall(function()
			return model:GetPivot()
		end)
		if not ok then
			return
		end

		kayitlar[model] = { taban = pivot, aci = 0 }
	end)
end

local function cikar(node: Instance)
	if node:IsA("Model") then
		kayitlar[node :: Model] = nil
	end
end

for _, node in CollectionService:GetTagged(TAG) do
	ekle(node)
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(ekle)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(cikar)

RunService.RenderStepped:Connect(function(dt)
	for model, kayit in kayitlar do
		-- Sunucu girdabi sildiyse kaydi da birak
		if not model.Parent then
			kayitlar[model] = nil
			continue
		end

		local hiz = model:GetAttribute("DonusHizi") or W.spin
		kayit.aci = (kayit.aci + math.rad(hiz) * dt) % (math.pi * 2)

		-- Yalnizca Y: girdap su yuzeyine paralel doner, yan yatmaz
		model:PivotTo(kayit.taban * CFrame.Angles(0, kayit.aci, 0))
	end
end)
