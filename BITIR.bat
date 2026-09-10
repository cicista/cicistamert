@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   BITIR - degisiklikleri kaydet ve gonder
echo ============================================
echo.

git diff --quiet && git diff --cached --quiet
if not errorlevel 1 (
    echo Degisiklik yok, gonderilecek bir sey bulunamadi.
    echo.
    pause
    exit /b 0
)

echo Degisen dosyalar:
git status --short
echo.

set /p MESAJ="Ne degistirdin? (kisa yaz): "
if "%MESAJ%"=="" set MESAJ=guncelleme

git add -A
git commit -m "%MESAJ%"
if errorlevel 1 (
    echo.
    echo !!! commit BASARISIZ.
    pause
    exit /b 1
)

echo.
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
