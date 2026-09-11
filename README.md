# cicistamert

Roblox oyunu. Depo yalnizca KODU tutar (`src/`); harita ve Workspace
Team Create'te yasar, Rojo onlara dokunmaz.

## Ilk kurulum (herkes bir kez)

1. `KURULUM.bat` -- Rojo, Lune ve Studio eklentisini kurar.
2. Studio aciksa kapat, tekrar ac (eklenti yuklensin).

## Her calisma

1. `BASLA.bat` -- once arkadasinin kodunu ceker, sonra Rojo'yu baslatir.
2. Studio'da: Plugins > Rojo > Connect.
3. Pencereyi KAPATMA; Rojo o pencerede calisiyor.
4. Isin bitince pencereyi kapat, `BITIR.bat` calistir -- kodu GitHub'a gonderir.

`YENILE.bat`: Rojo calisirken arkadasinin son kodunu cekmek icin.

## ONEMLI: Rojo'ya AYNI ANDA TEK KISI baglanir

Ikiniz birden Connect ederseniz son baglanan digerinin kodunu ezer.
Once "ben basliyorum" deyip oyle baglan.

## Klasorler

| Klasor | Studio'daki yeri |
|---|---|
| `src/server` | ServerScriptService |
| `src/client` | StarterPlayer > StarterPlayerScripts |
| `src/shared` | ReplicatedStorage > Shared |

## Sozdizimi kontrolu

    lune run tools/check.luau

`src/` altindaki butun `.luau` dosyalarini derleyip hata arar (calistirmaz).
Rojo ve Lune `%LOCALAPPDATA%\Rojo\bin` altindadir; PATH'te degilse tam yol gerekir.

## Backdoor taramasi

    lune run tools/scan.luau harita.rbxl

Toolbox modelleriyle gelen arka kapilari arar. Haritayi once Studio'dan
`File > Save As` ile bir `.rbxl` olarak kaydet, sonra o dosyayi tara.

**Yeni bir toolbox modeli ekledikten sonra HER SEFERINDE calistir.**

Cikti uc kademeli. Bakman gereken tek sayi **YUKSEK RISK**:

- `YUKSEK RISK: 0` yoksa harita temiz demektir.
- ORTA ve DUSUK RISK'te kendi kodumuz da cikar (AdminPanel'in `allowInStudio`
  kontrolu, PlayerData'nin DataStore korumasi, ses/animasyon asset id'leri).
  Bunlar normaldir.

Tarayici hem kaynak koduna hem de scriptin ADINA ve DURDUGU YERE bakar --
12 Eylul 2026'da bulunan 72 arka kapinin ucu de kodu tertemiz gorunuyordu,
ele veren sey nerede durduklariydi. Ayrintilar `tools/scan.luau` basindaki
aciklamada.
