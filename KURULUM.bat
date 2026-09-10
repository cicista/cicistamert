@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   KURULUM - Rojo ve Lune'u kurar
echo   Bir kez calistirmak yeterli.
echo ============================================
echo.

rem Zaten kurulu mu
set "ROJO="
where rojo >nul 2>&1 && set "ROJO=rojo"
if not defined ROJO if exist "%LOCALAPPDATA%\Rojo\bin\rojo.exe" set "ROJO=%LOCALAPPDATA%\Rojo\bin\rojo.exe"

if defined ROJO (
    echo Rojo zaten kurulu:
    "%ROJO%" --version
    echo.
    echo Yine de guncellemek istersen bu pencereyi kapatip
    echo asagidaki adimi atlamadan devam edebilirsin.
    echo.
)

echo Rojo indiriliyor (GitHub - rojo-rbx/rojo)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$bin=\"$env:LOCALAPPDATA\Rojo\bin\";" ^
  "New-Item -ItemType Directory -Force $bin | Out-Null;" ^
  "$zip=\"$env:TEMP\rojo.zip\";" ^
  "Invoke-WebRequest 'https://github.com/rojo-rbx/rojo/releases/download/v7.7.0/rojo-7.7.0-windows-x86_64.zip' -OutFile $zip;" ^
  "Expand-Archive $zip -DestinationPath $bin -Force;" ^
  "Remove-Item $zip -Force"

if errorlevel 1 (
    echo.
    echo !!! Rojo indirilemedi. Internet baglantisini kontrol et.
    pause
    exit /b 1
)

echo Lune indiriliyor (yardimci araclar icin)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$bin=\"$env:LOCALAPPDATA\Rojo\bin\";" ^
  "$zip=\"$env:TEMP\lune.zip\";" ^
  "Invoke-WebRequest 'https://github.com/lune-org/lune/releases/download/v0.10.5/lune-0.10.5-windows-x86_64.zip' -OutFile $zip;" ^
  "Expand-Archive $zip -DestinationPath $bin -Force;" ^
  "Remove-Item $zip -Force"

echo.
echo Studio eklentisi indiriliyor...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$p=\"$env:LOCALAPPDATA\Roblox\Plugins\";" ^
  "New-Item -ItemType Directory -Force $p | Out-Null;" ^
  "Invoke-WebRequest 'https://github.com/rojo-rbx/rojo/releases/download/v7.7.0/Rojo.rbxm' -OutFile \"$p\Rojo.rbxm\""

echo.
echo ============================================
"%LOCALAPPDATA%\Rojo\bin\rojo.exe" --version
echo   KURULUM TAMAM
echo.
echo   Studio aciksa KAPAT ve tekrar ac
echo   (eklentinin yuklenmesi icin gerekli).
echo.
echo   Sonra BASLA.bat calistir.
echo ============================================
echo.
pause
