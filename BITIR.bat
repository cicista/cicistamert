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
rem (ornegin baska bir araç commit ettiyse) bunlar GitHub'a hic gitmiyordu.
rem git push gonderecek bir sey yoksa zaten "Everything up-to-date" der.
echo GitHub'a gonderiliyor...
git push
if errorlevel 1 (
    echo.
    echo !!! push BASARISIZ.
    echo     Arkadasin senden sonra bir sey gonderdiyse once soyle dene:
    echo         git pull --rebase
    echo     sonra bu dosyayi tekrar calistir.
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   TAMAM. Kod GitHub'a kaydedildi.
echo   Artik arkadasin BASLA.bat ile cekebilir.
echo ============================================
echo.
pause
