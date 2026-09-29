--!strict

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

export type Tur = "klavye" | "dokunmatik" | "gamepad"

local Girdi = {}

local dinleyiciler: { (Tur) -> () } = {}

local function tercihOf(): Tur?
	local ok, sonuc = pcall(function(): Tur?
		local tercih = (UserInputService :: any).PreferredInput
		local liste = (Enum :: any).PreferredInput
		if tercih == liste.Gamepad then
			return "gamepad"
		elseif tercih == liste.Touch then
			return "dokunmatik"
		elseif tercih == liste.KeyboardAndMouse then
			return "klavye"
		end
		return nil
	end)
	return if ok then sonuc else nil
end

local function sonGirdiOf(tip: Enum.UserInputType): Tur?
	if string.sub(tip.Name, 1, 7) == "Gamepad" then
		return "gamepad"
	elseif tip == Enum.UserInputType.Touch then
		return "dokunmatik"
	elseif
		tip == Enum.UserInputType.Keyboard
		or tip == Enum.UserInputType.MouseMovement
		or tip == Enum.UserInputType.MouseButton1
		or tip == Enum.UserInputType.MouseButton2
		or tip == Enum.UserInputType.MouseWheel
	then
		return "klavye"
	end
	return nil
end

local function hesapla(): Tur
	local tercih = tercihOf()
	if tercih then
		return tercih
	end
	local son = sonGirdiOf(UserInputService:GetLastInputType())
	if son then
		return son
	end
	if GuiService:IsTenFootInterface() then
		return "gamepad"
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "dokunmatik"
	end
	if UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
		return "gamepad"
	end
	return "klavye"
end

local mevcut: Tur = hesapla()

local function tazele(yeni: Tur?)
	local tur = yeni or hesapla()
	if tur == mevcut then
		return
	end
	mevcut = tur
	for _, dinleyici in dinleyiciler do
		task.spawn(dinleyici, tur)
	end
end

UserInputService.LastInputTypeChanged:Connect(function(tip)
	if tercihOf() then
		return
	end
	local son = sonGirdiOf(tip)
	if son then
		tazele(son)
	end
end)

pcall(function()
	UserInputService:GetPropertyChangedSignal("PreferredInput" :: any):Connect(function()
		tazele()
	end)
end)

function Girdi.tur(): Tur
	return mevcut
end

function Girdi.dokunmatik(): boolean
	return mevcut == "dokunmatik"
end

function Girdi.gamepad(): boolean
	return mevcut == "gamepad"
end

function Girdi.degisince(dinleyici: (Tur) -> ())
	table.insert(dinleyiciler, dinleyici)
end

function Girdi.izle(dinleyici: (Tur) -> ())
	table.insert(dinleyiciler, dinleyici)
	task.spawn(dinleyici, mevcut)
end

function Girdi.sec<T>(klavye: T, dokunmatik: T, gamepad: T): T
	if mevcut == "dokunmatik" then
		return dokunmatik
	elseif mevcut == "gamepad" then
		return gamepad
	end
	return klavye
end

function Girdi.yaziBagla(yazi: TextLabel | TextButton, klavye: string, dokunmatik: string, gamepad: string)
	local function ciz()
		if yazi.Parent then
			yazi.Text = Girdi.sec(klavye, dokunmatik, gamepad)
		end
	end
	ciz()
	Girdi.degisince(ciz)
end

local ISIMLER: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.ButtonA] = "A",
	[Enum.KeyCode.ButtonB] = "B",
	[Enum.KeyCode.ButtonX] = "X",
	[Enum.KeyCode.ButtonY] = "Y",
	[Enum.KeyCode.ButtonL1] = "LB",
	[Enum.KeyCode.ButtonR1] = "RB",
	[Enum.KeyCode.ButtonL2] = "LT",
	[Enum.KeyCode.ButtonR2] = "RT",
	[Enum.KeyCode.ButtonSelect] = "SELECT",
	[Enum.KeyCode.ButtonStart] = "START",
	[Enum.KeyCode.DPadUp] = "D-PAD",
	[Enum.KeyCode.Thumbstick1] = "L-STICK",
	[Enum.KeyCode.Thumbstick2] = "R-STICK",
}

function Girdi.tusAdi(tus: Enum.KeyCode): string
	local ad = ISIMLER[tus]
	if ad then
		return ad
	end
	local ok, sonuc = pcall(function()
		return UserInputService:GetStringForKeyCode(tus)
	end)
	if ok and type(sonuc) == "string" and sonuc ~= "" then
		return string.upper(sonuc)
	end
	return string.upper(tus.Name)
end

function Girdi.tusResmi(tus: Enum.KeyCode): string?
	local ok, sonuc = pcall(function()
		return UserInputService:GetImageForKeyCode(tus)
	end)
	if ok and type(sonuc) == "string" and sonuc ~= "" then
		return sonuc
	end
	return nil
end

return Girdi
