--!strict

local Mutations = require(script.Parent.Mutations)

local Scrolls = {}

export type ScrollInfo = {
	id: string,
	ad: string,
	aciklama: string,
	modelAdi: string,
	mutasyon: string,
	sans: number,
	fiyat: number,
	renk: Color3,
}

Scrolls.Info = {
	HackerMutation = {
		id = "HackerMutation",
		ad = "Hacker Mutation Scroll",
		aciklama = "40% chance to give a placed brainrot the Hacker mutation",
		modelAdi = "HackerMutationScroll",
		mutasyon = "Hacker",
		sans = 0.4,
		fiyat = 30,
		renk = Mutations.get("Hacker").color,
	},
} :: { [string]: ScrollInfo }

Scrolls.Order = { "HackerMutation" } :: { string }

function Scrolls.get(id: string?): ScrollInfo?
	return if type(id) == "string" then Scrolls.Info[id] else nil
end

Scrolls.Nitelik = "ScrollId"

function Scrolls.etiket(id: string, adet: number): string
	local info = Scrolls.get(id)
	local ad = if info then info.ad else id
	return if adet > 1 then `{ad} x{adet}` else ad
end

function Scrolls.model(id: string): Instance?
	local info = Scrolls.get(id)
	if not info then
		return nil
	end

	local assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
	local klasor = assets and assets:FindFirstChild("Scrolls")
	local sablon = klasor and klasor:FindFirstChild(info.modelAdi, true)
	return if sablon then sablon:Clone() else nil
end

return Scrolls
