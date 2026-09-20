@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   BASLA
echo   1) Gonderilmemis isin var mi diye bakar
echo   2) Arkadasinin kodunu ceker
echo   3) Rojo'yu baslatir
echo ============================================
echo.

rem ------------------------------------------------------------------
rem  ADIM 1  --  GONDERILMEMIS IS KONTROLU
rem
rem  En sik yasanan kaza buydu: kendi degisikligini gondermeden calismaya
rem  devam ediyorsun, arkadasin BASLA.bat ile ESKI kodu cekip Connect
rem  ediyor ve Team Create'teki Studio'ya onun kopyasi basiliyor. Senin
rem  isin gitmis gibi gorunuyor -- aslinda hic gonderilmemisti.
rem
rem  Bu yuzden artik en basta uyariliyor.
rem ------------------------------------------------------------------
echo [1/3] Gonderilmemis is kontrolu...

set "DEGISIKLIK="
for /f "delims=" %%A in ('git status --porcelain') do set "DEGISIKLIK=1"
if defined DEGISIKLIK goto UYARI

rem Commit edilmis ama push edilmemis is de ayni tehlikeyi tasir
set "ILERIDE="
for /f "delims=" %%A in ('git log origin/main..HEAD --oneline 2^>nul') do set "ILERIDE=1"
if defined ILERIDE goto UYARI

echo     Temiz.
goto CEK

:UYARI
echo.
echo     ###########################################################
echo     #  DIKKAT: GITHUB'A GONDERILMEMIS ISIN VAR                #
echo     ###########################################################
echo.
git status --short
for /f "delims=" %%A in ('git log origin/main..HEAD --oneline 2^>nul') do echo     gonderilmemis commit: %%A
echo.
echo     Bunlar GitHub'da YOK. Arkadasin BASLA.bat calistirip Connect
echo     ederse Studio'ya KENDI kopyasini basar ve bu is kaybolur.
echo.
echo     Yapilacak: bu pencereyi kapat, BITIR.bat calistir, sonra
echo     buraya geri don.
echo.

set "DEVAM="
set /p DEVAM="Yine de devam edeyim mi? (E/H): "
if /I not "%DEVAM%"=="E" exit /b 1
echo.

:CEK
echo.
echo [2/3] Kod cekiliyor...
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
echo [3/3] Rojo baslatiliyor...

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
echo     Iki kisi birden baglanirsa SON baglanan otekinin kodunu ezer.
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
