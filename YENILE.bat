@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   YENILE
echo   Rojo'yu tazeler (git pull YAPMAZ)
echo ============================================
echo.
echo   Ne zaman kullanilir:
echo     - Kodda degisiklik yapildi ama Studio'ya inmedi
echo     - Rojo bagli gorunuyor ama patch gelmiyor
echo.

tasklist /FI "IMAGENAME eq rojo.exe" 2>nul | find /I "rojo.exe" >nul
if not errorlevel 1 (
    echo Eski Rojo kapatiliyor...
    taskkill /IM rojo.exe /F >nul 2>&1
    timeout /t 2 /nobreak >nul
)

set "ROJO="
where rojo >nul 2>&1 && set "ROJO=rojo"
if not defined ROJO if exist "%LOCALAPPDATA%\Rojo\bin\rojo.exe" set "ROJO=%LOCALAPPDATA%\Rojo\bin\rojo.exe"
if not defined ROJO if exist "%USERPROFILE%\.rokit\bin\rojo.exe" set "ROJO=%USERPROFILE%\.rokit\bin\rojo.exe"
if not defined ROJO if exist "%USERPROFILE%\.aftman\bin\rojo.exe" set "ROJO=%USERPROFILE%\.aftman\bin\rojo.exe"

if not defined ROJO (
    echo.
    echo !!! ROJO BULUNAMADI -- once KURULUM.bat calistir.
    echo.
    pause
    exit /b 1
)

echo.
echo   Rojo yeniden basladi.
echo.
echo   SIMDI STUDIO'DA:  Plugins - Rojo - Disconnect, sonra Connect
echo   (Rojo her yeniden basladiginda eski oturum gecersiz olur,
echo    Studio kendiliginden yeniden baglanmaz.)
echo.
echo   ############################################
echo   #  BU PENCEREYI KAPATMA                    #
echo   #  Rojo BU PENCEREDE calisiyor.            #
echo   #  Kapatirsan sunucu durur ve Studio       #
echo   #  "Couldn't connect" hatasi verir.        #
echo   #  Calismayi bitirince kapatabilirsin.     #
echo   ############################################
echo.

"%ROJO%" serve default.project.json
pause
