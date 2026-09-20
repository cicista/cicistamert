@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   KURTAR
echo   Takilmis git durumunu toparlar
echo ============================================
echo.
echo   Ne zaman kullanilir:
echo     - "you have unmerged files" yaziyorsa
echo     - "Exiting because of an unresolved conflict" yaziyorsa
echo     - BASLA.bat ya da BITIR.bat "YARIM KALMIS BIRLESTIRME" diyorsa
echo.

rem ------------------------------------------------------------------
rem  ADIM 1  --  YARIM KALMIS ISLEMI IPTAL ET
rem
rem  Rebase ya da merge ortada kalmissa once o temizlenir. Bu ADIM HICBIR
rem  SEYI SILMEZ: yalnizca yarim kalan birlestirmeyi geri alir, kendi
rem  commit'lerin oldugu gibi durur.
rem ------------------------------------------------------------------
echo [1/3] Yarim kalmis islem temizleniyor...

set "YARIM="
if exist ".git\rebase-merge" set "YARIM=1"
if exist ".git\rebase-apply" set "YARIM=1"
if defined YARIM (
    git rebase --abort >nul 2>&1
    echo     Yarim kalan birlestirme geri alindi.
)

if exist ".git\MERGE_HEAD" (
    git merge --abort >nul 2>&1
    echo     Yarim kalan birlesme geri alindi.
)

if not defined YARIM if not exist ".git\MERGE_HEAD" echo     Yarim kalan bir sey yoktu.

echo.
echo [2/3] Durum:
echo.
git status --short
echo.

set "ILERIDE="
for /f "delims=" %%A in ('git log origin/main..HEAD --oneline 2^>nul') do set "ILERIDE=1"
if defined ILERIDE (
    echo     Gonderilmemis commit'lerin:
    git log origin/main..HEAD --oneline
    echo.
)

echo [3/3] Simdi ne yapilacak?
echo.
echo   Cogu zaman buraya kadarki temizlik yetiyor:
echo     pencereyi kapat, BITIR.bat calistir.
echo.
echo   AMA ayni satirlari ikiniz birden degistirdiyseniz BITIR.bat yine
echo   takilir. O zaman asagidaki secenek isine yarar.
echo.
echo   ---------------------------------------------------------------
echo   SIFIRLA: kendi yerel degisikliklerini birakip GitHub'daki hale don
echo.
echo   Bu secenek kendi commit'lerini "yedek" adli bir dala tasir, sonra
echo   GitHub'daki surumu alir. Hicbir sey silinmez ama calisma kopyan
echo   tamamen GitHub'daki hale doner.
echo   ---------------------------------------------------------------
echo.

set "SIFIRLA="
set /p SIFIRLA="Sifirlayayim mi? (E/H): "
if /I not "%SIFIRLA%"=="E" goto BITTI

echo.
echo   Emin misin? Calisma kopyandaki kaydedilmemis degisiklikler gider.
set "EMIN="
set /p EMIN="Tekrar yaz (EVET): "
if /I not "%EMIN%"=="EVET" goto BITTI

echo.
echo   Yedek dal olusturuluyor...
for /f "tokens=2 delims==" %%A in ('wmic os get localdatetime /value 2^>nul') do set "ZAMAN=%%A"
set "DAL=yedek-%ZAMAN:~0,8%-%ZAMAN:~8,4%"
git branch "%DAL%" >nul 2>&1
echo     Commit'lerin "%DAL%" dalinda duruyor.

echo.
echo   GitHub'daki hale donuluyor...
git fetch origin
git reset --hard origin/main
echo.
echo   Tamam. Artik GitHub'daki surumdesin.

:BITTI
echo.
echo ============================================
echo   KURTAR bitti.
echo   Sirada: BASLA.bat
echo ============================================
echo.
pause
