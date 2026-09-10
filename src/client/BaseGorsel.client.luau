--[[
	BaseGorsel  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > BaseGorsel

	Base slotlarindaki brainrotlarin donme ve suzulme animasyonu.

	NEDEN ISTEMCIDE
	Bu animasyon once sunucuda yapiliyordu. Roblox sunucu tarafindaki
	hareketi istemciye saniyede yaklasik 20 kez replike eder; dongu ne
	kadar sik calisirsa calissin oyuncu takilmali bir donme gorur.
	Animasyonu her oyuncunun kendi makinesinde cizince hareket ekran
	tazeleme hizinda akar ve sunucuya hicbir yuk binmez.

	Sunucu modeli yerlestirir ve uzerine su ozellikleri yazar:
	    SpinDisplay  (bool)    -- bu model animasyonlu
	    SpinHome     (CFrame)  -- yerlesmis, hareketsiz durus
	    SpinPivot    (CFrame)  -- donusun etrafinda dondugu dikey eksen
	    SpinEnabled  (bool)    -- donsun mu
	    SpinSpeed    (number)  -- radyan/saniye
	    BobHeight    (number)  -- suzulme yuksekligi (0 = sabit)
	    BobSpeed     (number)

	Buradaki CFrame degisiklikleri yereldir; sunucuya geri gitmez.
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Animasyonlu modeller ve her birinin kendi zamani
type Entry = {
	model: Model,
	home: CFrame,
	pivot: CFrame,
	spin: boolean,
	spinSpeed: number,
	bobHeight: number,
	bobSpeed: number,
	time: number,
	-- Rainbow gibi renk dongusu isteyen mutasyonlar icin
	rainbow: Highlight?,
}

local entries: { [Model]: Entry } = {}

local function track(model: Model)
	if entries[model] then
		return
	end

	local home = model:GetAttribute("SpinHome")
	local pivot = model:GetAttribute("SpinPivot")

	-- Ozellikler sunucudan gecikmeli gelebilir; ikisi de yoksa atla
	if typeof(home) ~= "CFrame" or typeof(pivot) ~= "CFrame" then
		return
	end

	entries[model] = {
		model = model,
		home = home,
		pivot = pivot,
		spin = model:GetAttribute("SpinEnabled") ~= false,
		spinSpeed = (model:GetAttribute("SpinSpeed") :: number?) or 0.8,
		bobHeight = (model:GetAttribute("BobHeight") :: number?) or 0,
		bobSpeed = (model:GetAttribute("BobSpeed") :: number?) or 1.6,
		-- Baslangic zamani rastgele: butun brainrotlar ayni anda ayni
		-- yone bakmasin, base daha canli gorunsun
		time = math.random() * 10,
		rainbow = nil,
	}

	--[[
		RAINBOW

		Paketteki Rainbow modelleri rengi kendi icindeki bir script ile
		degistiriyor; o script sunucuda calismadigi icin model tek renk
		(acik yesil) kaliyordu. Renk dongusunu burada, istemcide ciziyoruz:
		modelin uzerine bir Highlight konup rengi surekli gokkusagi
		boyunca gezdiriliyor.
	]]
	if model:GetAttribute("Mutation") == "Rainbow" then
		local highlight = Instance.new("Highlight")
		highlight.Name = "RainbowEfekt"
		-- Dolgu neredeyse seffaf: modelin kendi dokusu ve detaylari gorunur
		-- kalsin, renk dongusu esas olarak konturda aksin
		highlight.FillTransparency = 0.88
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Adornee = model
		highlight.Parent = model

		entries[model].rainbow = highlight
	end
end

local function untrack(model: Model)
	entries[model] = nil
end

--[[
	Bir modelin animasyonlu olup olmadigini anlar.
	Ozellik sunucudan model olusturulduktan hemen sonra geldigi icin
	AttributeChanged de dinlenir.
]]
local function watch(instance: Instance)
	if not instance:IsA("Model") then
		return
	end

	if instance:GetAttribute("SpinDisplay") then
		track(instance)
	end

	instance:GetAttributeChangedSignal("SpinDisplay"):Connect(function()
		if instance:GetAttribute("SpinDisplay") then
			track(instance)
		else
			untrack(instance)
		end
	end)

	instance:GetAttributeChangedSignal("SpinHome"):Connect(function()
		untrack(instance)
		if instance:GetAttribute("SpinDisplay") then
			track(instance)
		end
	end)
end

-- Zaten var olanlar
for _, instance in Workspace:GetDescendants() do
	watch(instance)
end

Workspace.DescendantAdded:Connect(watch)

Workspace.DescendantRemoving:Connect(function(instance)
	if instance:IsA("Model") then
		untrack(instance)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	for model, entry in entries do
		if not model.Parent then
			entries[model] = nil
			continue
		end

		entry.time += dt

		--[[
			Suzulme yalnizca YUKARI dogru: dinlenme konumu en alt nokta,
			salinim oradan yukari cikar. Boylece model plakanin icine girmez.
		]]
		local lift = if entry.bobHeight > 0
			then (math.sin(entry.time * entry.bobSpeed) * 0.5 + 0.5) * entry.bobHeight
			else 0

		local angle = if entry.spin then entry.time * entry.spinSpeed else 0

		local offset = CFrame.new(entry.pivot.Position + Vector3.new(0, lift, 0))
			* CFrame.Angles(0, angle, 0)
			* CFrame.new(-entry.pivot.Position)

		model:PivotTo(offset * entry.home)

		-- Rainbow: renk tonu saniyede ~1/5 tur dolasir
		if entry.rainbow then
			entry.rainbow.FillColor = Color3.fromHSV((entry.time * 0.2) % 1, 0.85, 1)
			entry.rainbow.OutlineColor = Color3.fromHSV((entry.time * 0.2 + 0.5) % 1, 0.9, 1)
		end
	end
end)
