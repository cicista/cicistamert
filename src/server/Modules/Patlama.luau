--!strict
--[[
	PATLAMA  --  Workspace'teki FuseVFX + FuseExplosion

	Studio'ya elle konulmus efekt ve ses, oyuncunun uzerinde oynatilir.
	Iki yerden kullaniliyor:

	  - Fuse makinesi   : 5 esya birlesip coin cikardiginda
	  - Gorev odulu     : Quests panelinde Collect'e basildiginda

	Efekt karakterin govdesine KAYNAKLANIR, sabit bir noktaya konmaz:
	oyuncu patlama sirasinda yururse efekt uzerinde kalir. Sunucu urettigi
	icin haritadaki herkes gorur.

	Efekt ya da ses bulunamazsa sessizce atlanir; oyun calismaya devam eder.
]]

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Assets"))
local Fuse = require(Shared:WaitForChild("Fuse"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local Patlama = {}

-- Oyuncunun govdesi: sesler ve efekt buraya baglanir
local function bodyOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

--[[
	Kademeye gore renklenen patlama.

	rarityId  -- efektin BUYUKLUGU bundan gelir; renk de verilmezse rengi de
	sesli     -- false verilirse yalnizca gorsel oynar (ses baska yerde
	             calindiysa iki kez duyulmasin diye)
	renk      -- verilirse kademe rengini EZER. Ogretici odulu gibi bir
	             kademeye bagli OLMAYAN kutlamalar icin (beyaz patlama).
]]
function Patlama.oynat(player: Player, rarityId: string, sesli: boolean?, renk: Color3?)
	local cfg = Fuse.VFX

	local root = bodyOf(player)
	if not root then
		return
	end

	-- Patlama sesi efektle AYNI KAREDE ve ayni yerde
	if sesli ~= false then
		Assets.playSoundAt(cfg.explosion, root)
	end

	local template = Assets.vfxTemplate(cfg.name)
	if not template then
		return
	end

	-- Sablonla karismasin diye ayri ad: arama bir daha ona takilmasin
	template.Name = `{cfg.name}_Patlama`

	Assets.tintEffects(template, renk or Rarity.color(rarityId), cfg.preserveShading)
	Assets.scaleEffects(template, cfg.scaleByRarity[rarityId] or 1)

	local origin = root.CFrame * CFrame.new(0, cfg.height, 0)

	--[[
		Govdeye kaynak. Anchored KAPALI olmali: sabitlenmis bir parca
		kaynaklanamaz, oldugu yerde kalir.
	]]
	local function weldToBody(part: BasePart)
		part.Anchored = false
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
	end

	--[[
		SIRA ONEMLI: once DUNYAYA KON, sonra yerlestir, en son kaynakla.

		WeldConstraint yalnizca iki parca da DataModel icindeyken baglanir.
		Once kaynaklayip sonra parent edilirse kaynak tutmuyor; parca da
		sabitlenmemis oldugu icin ilk fizik adiminda dusup gozden kayboluyor
		ve efekt hic gorunmuyordu.
	]]
	template.Parent = Workspace

	if template:IsA("BasePart") then
		template.CFrame = origin
		weldToBody(template)
	elseif template:IsA("Model") then
		template:PivotTo(origin)
		for _, part in template:GetDescendants() do
			if part:IsA("BasePart") then
				weldToBody(part)
			end
		end
	end

	-- Tek seferlik yumak: sablonun kendi yayicilari ayni anda patlar
	Assets.playBurst(template, cfg.burst)

	-- Isiklar sonerek biter; aniden kapanmalari patlamayi kesik gosteriyor
	for _, node in template:GetDescendants() do
		if node:IsA("Light") then
			TweenService:Create(node, TweenInfo.new(cfg.stopAfter), { Brightness = 0 }):Play()
		end
	end

	-- Rate'i sifir olmayan yayicilar kuyruk birakmasin diye susturulur
	task.delay(cfg.stopAfter, function()
		if template.Parent then
			Assets.stopEmitters(template)
		end
	end)

	Debris:AddItem(template, cfg.lifetime)
end

return Patlama
