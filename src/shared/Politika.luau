--!strict

local Politika = {}

Politika.RastgeleNiteligi = "PolitikaRastgeleYasak"
Politika.TakasNiteligi = "PolitikaTakasYasak"

Politika.RastgeleTurler = {
	luckyblock = true,
	baslangic = true,
	gacha = true,
	kacanYumurta = true,
	rotcoin = true,
} :: { [string]: boolean }

Politika.RastgeleMesaji = "This item isn't available in your region."
Politika.TakasMesaji = "Trading isn't available in your region."
Politika.KarsiTakasMesaji = "Trading with this player isn't available in their region."

function Politika.rastgeleMi(tur: string): boolean
	return Politika.RastgeleTurler[tur] == true
end

return Politika
