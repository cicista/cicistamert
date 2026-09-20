@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   BITIR - degisiklikleri kaydet ve gonder
echo ============================================
echo.

rem Kaydedilmemis degisiklik var mi?
rem git status --porcelain kullaniliyor: git diff'in aksine YENI dosyalari
rem da gorur. Eskiden yeni bir dosya eklenince "degisiklik yok" deniyordu.
set "DEGISIKLIK="
for /f "delims=" %%A in ('git status --porcelain') do set "DEGISIKLIK=1"

if not defined DEGISIKLIK goto GONDER

echo Degisen dosyalar:
git status --short
echo.

set "MESAJ="
set /p MESAJ="Ne degistirdin? (kisa yaz): "
if not defined MESAJ set "MESAJ=guncelleme"

git add -A
git commit -m "%MESAJ%"
if errorlevel 1 (
    echo.
    echo !!! commit BASARISIZ.
    pause
    exit /b 1
)
echo.

:GONDER
rem PUSH HER ZAMAN DENENIR.
rem Eski surum yalnizca kaydedilmemis degisiklige bakip "Degisiklik yok"
rem deyip cikiyordu. Kaydedilmis ama HENUZ GONDERILMEMIS commit varsa
rem (ornegin baska bir arac commit ettiyse) bunlar GitHub'a hic gitmiyordu.
rem git push gonderecek bir sey yoksa zaten "Everything up-to-date" der.
echo GitHub'a gonderiliyor...
git push
if not errorlevel 1 goto TAMAM

rem ------------------------------------------------------------------
rem  PUSH REDDEDILDI  --  arkadasin senden sonra bir sey gondermis.
rem
rem  Eskiden burada "elle su komutu yaz" deniyordu ve is oyuncuda kaliyordu.
rem  Artik birlestirme KENDILIGINDEN deneniyor: rebase, senin commitlerini
rem  onunkilerin USTUNE tasir, kimsenin isi kaybolmaz.
rem ------------------------------------------------------------------
echo.
echo     Arkadasin senden sonra bir sey gondermis.
echo     Onun isiyle birlestirilip tekrar denenecek...
echo.

git pull --rebase
if errorlevel 1 goto CAKISMA

echo.
echo     Birlestirildi, tekrar gonderiliyor...
git push
if errorlevel 1 goto PUSHHATA
goto TAMAM

:CAKISMA
echo.
echo !!! BIRLESTIRME TAKILDI
echo.
echo     Ayni satirlari ikiniz birden degistirmissiniz; bunu git tek
echo     basina cozemiyor.
echo.
echo     Geri almak icin:   git rebase --abort
echo     Sonra arkadasinla konusun, kim neyi degistirdi bakin.
echo.
pause
exit /b 1

:PUSHHATA
echo.
echo !!! GONDERILEMEDI
echo.
echo     Birlestirme tamam ama gonderme yine olmadi. Internet baglantisi
echo     ya da GitHub erisimi olabilir. Biraz sonra tekrar dene.
echo.
pause
exit /b 1

:TAMAM
echo.
echo ============================================
echo   TAMAM. Kod GitHub'a kaydedildi.
echo   Artik arkadasin BASLA.bat ile cekebilir.
echo ============================================
echo.
pause
