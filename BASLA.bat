@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   BASLA
echo   1) Arkadasinin kodunu ceker
echo   2) Rojo'yu baslatir
echo ============================================
echo.

echo [1/2] Kod cekiliyor...
git pull
if errorlevel 1 (
    echo.
    echo !!! KOD CEKILEMEDI
    echo.
    echo     Muhtemel sebep: senin de kaydedilmemis degisikligin var.
    echo     Cozum: once BITIR.bat calistir, sonra tekrar dene.
    echo.
    pause
    exit /b 1
)

echo.
echo [2/2] Rojo baslatiliyor...

rem Onceki denemeden kalan Rojo varsa port dolu kalir; once onu kapat
tasklist /FI "IMAGENAME eq rojo.exe" 2>nul | find /I "rojo.exe" >nul
if not errorlevel 1 (
    echo     Eski Rojo penceresi bulundu, kapatiliyor...
    taskkill /IM rojo.exe /F >nul 2>&1
    timeout /t 2 /nobreak >nul
)

rem Rojo nerede kurulu olursa olsun bulunsun
set "ROJO="
where rojo >nul 2>&1 && set "ROJO=rojo"
if not defined ROJO if exist "%LOCALAPPDATA%\Rojo\bin\rojo.exe" set "ROJO=%LOCALAPPDATA%\Rojo\bin\rojo.exe"
if not defined ROJO if exist "%USERPROFILE%\.rokit\bin\rojo.exe" set "ROJO=%USERPROFILE%\.rokit\bin\rojo.exe"
if not defined ROJO if exist "%USERPROFILE%\.aftman\bin\rojo.exe" set "ROJO=%USERPROFILE%\.aftman\bin\rojo.exe"

if not defined ROJO (
    echo.
    echo !!! ROJO BULUNAMADI
    echo     Rojo kurulu degil ya da alisilmadik bir yerde.
    echo     Kurulumdan sonra bu dosyayi tekrar calistir.
    echo.
    pause
    exit /b 1
)

echo.
echo     Simdi Studio'da: Plugins - Rojo - Connect
echo.
echo     DIKKAT: Ayni anda arkadasin Connect ETMESIN.
echo     ############################################
echo     #  BU PENCEREYI KAPATMA                    #
echo     #  Rojo BU PENCEREDE calisiyor.            #
echo     #  Kapatirsan Studio baglantisi kopar.     #
echo     ############################################
echo.
echo     Isin bitince: once pencereyi kapat, sonra BITIR.bat calistir.
echo.

"%ROJO%" serve default.project.json
pause
