--!strict
--[[
	GelirYazisi  (LocalScript)
	Yeri: StarterPlayer > StarterPlayerScripts > GelirYazisi

	Oyuncunun base'i her saniye ne kazandiriyorsa, o rakam TOPLA butonunun
	uzerinde bir yerden firlayip kayboluyor. Para birikiyormus hissi veren
	tek sey buydu: eskiden birikim yalnizca butona basinca gorunuyordu,
	arada base olu duruyordu.

	AKIS  (her saniye bir tane)
	    dogar  : butonun uzerinde RASTGELE bir noktada, kucuk ve saydam
	    pop    : hizlica normalin biraz ustune buyur, sonra oturur
	    bekle  : 0.5 saniye oldugu yerde durur
	    soner  : yukari suzulurken yavasca kaybolur

	Her yazi kendi acisiyla duruyor (saga ya da sola 30 dereceye kadar):
	ust uste gelen iki yazi birbirinin kopyasi gibi gorunmesin.

	NEREDEN BILIYOR
	Sunucu butona iki nitelik yaziyor (bkz. ServerScriptService >
	BaseSistemi > updateCollectButton):
	    SahipId         -- base kimin
	    SaniyelikGelir  -- saniyede kac rot

	Yalnizca KENDI base'inin yazilari cikiyor: herkesinki cizilseydi
	kalabalik bir haritada ekran yaziyla dolardi.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Bases = require(Shared:WaitForChild("Bases"))
local Format = require(Shared:WaitForChild("Format"))

local UI = require(script.Parent:WaitForChild("UI"))

------------------------------------------------------------------
-- AYARLAR
------------------------------------------------------------------
-- Iki yazi arasi sure. 1 = saniyede bir (gelir de saniyelik)
local ARALIK = 1

-- Yazinin dogdugu kutu: butonun ustunde bu kadar stud'luk bir alan
local DAGILIM_X = 2.6
local DAGILIM_Z = 1.6
local EN_ALCAK = 2.2
local EN_YUKSEK = 3.6

-- Egim: saga ya da sola en cok bu kadar derece
local EN_COK_ACI = 30

-- Buyume, bekleme ve sonme sureleri (saniye)
local POP_SURESI = 0.18
local BEKLEME = 0.5
local SONME_SURESI = 0.9

-- Sonerken bu kadar stud yukari suzulur
local YUKSELME = 2.4

--[[
	Ayni anda ekranda durabilecek en cok yazi. Oyuncu uzun sure bakmadan
	dursa bile birikip ekrani doldurmasin (sunucu takilirsa arka arkaya
	birkac tane dogabilir).
]]
local EN_COK_YAZI = 8

------------------------------------------------------------------
-- BUTONU BUL
------------------------------------------------------------------
--[[
	Oyuncunun kendi base'inin TOPLA butonu. Base'ler oyun sirasinda
	el degistirdigi (oyuncu girer/cikar) icin her seferinde bakiliyor;
	bulunan buton bir sonraki cagriya kadar saklaniyor.
]]
local sonPad: BasePart? = nil

local function benimButonum(): BasePart?
	local var = sonPad
	if var and var.Parent and var:GetAttribute("SahipId") == player.UserId then
		return var
	end

	local kok = Workspace:FindFirstChild(Bases.FolderName) or Workspace
	for _, node in kok:GetDescendants() do
		if
			node:IsA("BasePart")
			and node.Name == "ToplaButonu"
			and node:GetAttribute("SahipId") == player.UserId
		then
			sonPad = node
			return node
		end
	end

	sonPad = nil
	return nil
end

------------------------------------------------------------------
-- YAZI
------------------------------------------------------------------
local acikYazi = 0

local function yaziCikar(pad: BasePart, gelir: number)
	if acikYazi >= EN_COK_YAZI then
		return
	end
	acikYazi += 1

	local rastgele = Random.new()

	local tabela = Instance.new("BillboardGui")
	tabela.Name = "GelirYazisi"
	tabela.Adornee = pad
	tabela.Size = UDim2.fromOffset(190, 54)
	tabela.AlwaysOnTop = true
	--[[
		Uzaktan gorunmesin: baska adadaki base'in yazilari ekranin kenarinda
		birikiyordu. Buton zaten yakindayken anlamli.
	]]
	tabela.MaxDistance = 140
	tabela.StudsOffset = Vector3.new(
		rastgele:NextNumber(-DAGILIM_X, DAGILIM_X),
		rastgele:NextNumber(EN_ALCAK, EN_YUKSEK),
		rastgele:NextNumber(-DAGILIM_Z, DAGILIM_Z)
	)
	tabela.Parent = playerGui

	local yazi = UI.text({
		text = `+{Format.short(gelir)}`,
		size = UI.Sizes.heading,
		font = UI.Fonts.bold,
		color = Bases.RotColor,
		align = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromScale(1, 1),
		parent = tabela,
	})
	-- Kalin siyah kontur: zemin ne renk olursa olsun okunur
	local kontur = UI.stroke(yazi, Color3.fromRGB(0, 0, 0), 3)

	--[[
		EGIM: sifirdan EN_COK_ACI dereceye, yonu de rastgele. Sifira yakin
		degerler de cikiyor -- hepsi egik olsaydi duzen yapay gorunurdu.
	]]
	yazi.Rotation = rastgele:NextNumber(0, EN_COK_ACI) * (if rastgele:NextNumber() < 0.5 then -1 else 1)

	--[[
		POP: kucuk ve biraz iri arasinda gidip oturuyor. Back easing
		sonunda hafif bir geri tepme veriyor, "firlamis" hissi ondan.
	]]
	local olcek = Instance.new("UIScale")
	olcek.Scale = 0.35
	olcek.Parent = yazi

	TweenService
		:Create(
			olcek,
			TweenInfo.new(POP_SURESI, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		)
		:Play()

	task.delay(POP_SURESI + BEKLEME, function()
		if not tabela.Parent then
			return
		end

		local bilgi = TweenInfo.new(SONME_SURESI, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		TweenService:Create(yazi, bilgi, { TextTransparency = 1 }):Play()
		TweenService:Create(kontur, bilgi, { Transparency = 1 }):Play()
		-- Sonerken yukari suzulur ve hafifce kuculur
		TweenService
			:Create(tabela, bilgi, { StudsOffset = tabela.StudsOffset + Vector3.new(0, YUKSELME, 0) })
			:Play()
		TweenService:Create(olcek, bilgi, { Scale = 0.8 }):Play()

		task.delay(SONME_SURESI, function()
			tabela:Destroy()
			acikYazi -= 1
		end)
	end)
end

------------------------------------------------------------------
-- DONGU
------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(ARALIK)

		local pad = benimButonum()
		if pad then
			local gelir = pad:GetAttribute("SaniyelikGelir")
			if type(gelir) == "number" and gelir > 0 then
				yaziCikar(pad, gelir)
			end
		end
	end
end)
