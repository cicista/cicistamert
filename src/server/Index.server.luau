--!strict
--[[
	Index  (Script)
	Yeri: ServerScriptService > Index

	Brainrot kesif defterinin sunucu tarafi. Tek isi var: istemci defteri
	acinca kesfedilen adlarin listesini gondermek.

	--------------------------------------------------------------
	KESIF NEREDE KAYDEDILIYOR

	Burada DEGIL. Kayit, envanter her senkronlandiginda
	Envanter.push icinde yapiliyor -- brainrotun kimligi acilan butun
	yollarin ortak bogazi orasi (bkz. Modules > Envanter).

	Bu script yalnizca OKUYUCU: yazma yolu tek yerde kalsin diye.

	--------------------------------------------------------------
	NEDEN KATALOG GONDERILMIYOR

	Istemci brainrot katalogunu (Shared > Brainrots) zaten okuyabiliyor,
	cunku o modul ReplicatedStorage'da. Buradan yalnizca oyuncuya OZEL
	olan sey gidiyor: hangilerini bulmus. Katalogu de gondermek ayni
	veriyi iki kez tasimak olurdu.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local Modules = script.Parent:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))

local IndexAc = Net.event("IndexAc")
local IndexDurum = Net.event("IndexDurum")

--[[
	ISTEK SINIRI

	Panel her acilista bir istek atiyor; oyuncu dugmeye hizli hizli basarsa
	istek yagmuru olur. Kisa bir bekleme bunu kesiyor -- veri kuculuk
	oldugu icin cevap zaten aninda geliyor, oyuncu yavasligi fark etmez.
]]
local BEKLEME = 0.25
local sonIstek: { [Player]: number } = {}

local function gonder(player: Player)
	IndexDurum:FireClient(player, PlayerData.discovered(player))
end

IndexAc.OnServerEvent:Connect(function(player)
	local simdi = os.clock()
	if (sonIstek[player] or 0) + BEKLEME > simdi then
		return
	end
	sonIstek[player] = simdi

	--[[
		Veri henuz yuklenmemis olabilir (oyuncu girer girmez dugmeye
		bastiysa). PlayerData.discovered bos tablo donuyor, panel de
		"hicbiri bulunmadi" cizerek aciliyor; bir sonraki acilista dogru
		veriyle gelir. Bos beklemekten iyidir.
	]]
	gonder(player)
end)

Players.PlayerRemoving:Connect(function(player)
	sonIstek[player] = nil
end)
