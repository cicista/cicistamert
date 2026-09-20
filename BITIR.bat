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
rem
rem CIKTISI SUSTURULUYOR: push reddedildiginde git ekrana kirmizi "error"
rem ve "hint" satirlari basiyor. Bu normal bir durum (arkadas senden once
rem gondermis) ve asagisi onu kendisi cozuyor; kirmizi yazilari gormek
rem bosuna korkutuyordu. Gercekten cozulemeyen bir hata olursa sebebi
rem :PUSHHATA bolumunde acikca gosteriliyor.
echo GitHub'a gonderiliyor...
git push >nul 2>&1
if not errorlevel 1 goto TAMAM

rem ------------------------------------------------------------------
rem  PUSH OLMADI  --  sebebi ne?
rem
rem  Uzakta senden sonra gelmis bir commit varsa is basit: birlestirilir.
rem  Yoksa sorun baska (internet, yetki) ve o zaman gercek hatayi
rem  gostermek gerekiyor.
rem ------------------------------------------------------------------
git fetch origin >nul 2>&1

set "GERIDE="
for /f "delims=" %%A in ('git log HEAD..origin/main --oneline 2^>nul') do set "GERIDE=1"
if not defined GERIDE goto PUSHHATA

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
echo     basina cozemiyor. SENIN ISIN DURUYOR, kaybolmadi.
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
echo     Commit'lerin duruyor, kaybolmadi. Gonderme neden olmadi:
echo.
git push
echo.
echo     Cogu zaman internet ya da GitHub erisimidir; biraz sonra
echo     BITIR.bat'i tekrar calistir.
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
