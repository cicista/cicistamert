--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ayar = require(Shared:WaitForChild("Gacha"))
local Condition = require(Shared:WaitForChild("Condition"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Net = require(Shared:WaitForChild("Net"))
local Rarity = require(Shared:WaitForChild("Rarity"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Envanter = require(script.Parent:WaitForChild("Envanter"))
local Patlama = require(script.Parent:WaitForChild("Patlama"))
local Yetki = require(script.Parent:WaitForChild("Yetki"))

local Gacha = {}

local rng = Random.new()

local mesgul: { [Player]: boolean } = {}

local function adminMi(player: Player): boolean
	return Yetki.admin(player)
end

local function gosteri(player: Player, rarityId: string, onceki: number, yeni: number)
	while mesgul[player] and player.Parent do
		task.wait(0.2)
	end
	if not player.Parent then
		return
	end
	mesgul[player] = true

	local ad = Ayar.yumurtaAdi(Rarity.displayName(rarityId))
	Net.event("GachaSonuc"):FireClient(player, { rarity = rarityId, ad = ad, onceki = onceki, iska = yeni })

	task.wait(Ayar.toplamSure())
	if player.Parent then
		Patlama.oynat(player, rarityId)

		Envanter.syncBrainrots(player)
		Envanter.push(player)
		Net.event("Bildirim"):FireClient(player, `You got a {ad}!`, Rarity.color(rarityId))
	end

	task.wait(Ayar.SonucSuresi)
	mesgul[player] = nil
end

function Gacha.ver(player: Player)
	local data = PlayerData.get(player)
	if not data then
		error("no player data")
	end

	local onceki = data.gachaIska
	local rarityId = Ayar.sec(rng, onceki)
	local condition = Condition.roll(rng)
	local mutation = Mutations.roll(rng)

	local item = PlayerData.addBrainrot(player, rarityId, condition, mutation, Ayar.Ada, true)
	if not item then
		error("egg could not be added to the backpack")
	end

	data.gachaIska = if Ayar.ArtanKademeler[rarityId] then 0 else math.min(onceki + 1, Ayar.maxIska())

	task.spawn(gosteri, player, rarityId, onceki, data.gachaIska)
end

local npcParcalari: { [BasePart]: boolean } = {}

local function tutunmaParcasi(node: Instance): BasePart?
	if node:IsA("BasePart") then
		return node
	end
	if node:IsA("Model") then
		if node.PrimaryPart then
			return node.PrimaryPart
		end
		local root = node:FindFirstChild("HumanoidRootPart", true)
		if root and root:IsA("BasePart") then
			return root
		end
	end
	return node:FindFirstChildWhichIsA("BasePart", true)
end

local function pencereyiAc(player: Player)
	local data = PlayerData.get(player)
	Net.event("GachaAc"):FireClient(player, {
		admin = adminMi(player),
		iska = if data then data.gachaIska else 0,
	})
end

local function npcBagla(): number
	local hedef = string.lower(Ayar.NpcAdi)
	local sayi = 0

	for parca in npcParcalari do
		if not parca.Parent then
			npcParcalari[parca] = nil
		end
	end

	for _, node in Workspace:GetDescendants() do
		if string.lower(node.Name) ~= hedef or not (node:IsA("Model") or node:IsA("BasePart")) then
			continue
		end

		local parca = tutunmaParcasi(node)
		if not parca then
			continue
		end
		sayi += 1
		if npcParcalari[parca] and parca:FindFirstChild("GachaPrompt") then
			continue
		end

		npcParcalari[parca] = true
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "GachaPrompt"
		prompt.ActionText = "Open"
		prompt.ObjectText = "Premium Spin"
		prompt.HoldDuration = 0.2
		prompt.MaxActivationDistance = Ayar.PromptMesafe
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = parca
		prompt.Triggered:Connect(pencereyiAc)

		print(`[Gacha] NPC baglandi: {parca:GetFullName()}`)
	end
	return sayi
end

local basladi = false

function Gacha.baslat()
	if basladi then
		return
	end
	basladi = true

	Net.event("GachaDene").OnServerEvent:Connect(function(player)
		if not adminMi(player) then
			return
		end
		if mesgul[player] then
			Net.event("Bildirim"):FireClient(player, "Wait for the current spin to finish.", Color3.fromRGB(255, 200, 90))
			return
		end
		local ok, hata = pcall(Gacha.ver, player)
		if not ok then
			warn(`[Gacha] admin test failed ({player.Name}): {hata}`)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		mesgul[player] = nil
	end)

	if npcBagla() == 0 then
		warn(`[Gacha] NPC '{Ayar.NpcAdi}' not found in the map; will connect once added`)
	end
	Workspace.DescendantAdded:Connect(function(node)
		if string.lower(node.Name) == string.lower(Ayar.NpcAdi) then
			task.delay(0.5, npcBagla)
		end
	end)
end

return Gacha
