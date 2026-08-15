@echo off
REM ============================================================================
REM MEBRE AKILLI TAHTA — SELF-HEAL + WATCHDOG  (C# ConfigServices/checkSystmFolder karsiligi)
REM ============================================================================
REM Zamanlanmis gorev bunu DAKIKADA BIR calistirir. C#'ta SYSTEM servisi neyi
REM yapiyorsa (dosya silinse yeniden olustur + surec oldurulse yeniden baslat)
REM onu yapar. BU BETIK ANA KLASORDE DEGIL, AYRI GIZLI YEDEK KONUMDA durur
REM (C:\ProgramData\MebreSvc) -> ana klasor silinse bile healer hayatta kalir.
REM ----------------------------------------------------------------------------
set MAIN=C:\pf\Tahta
set YEDEK=C:\ProgramData\MebreSvc\app

REM 1) SELF-HEAL: ana dosyalar silinmis/yeniden adlandirilmissa YEDEKTEN geri koy.
if not exist "%MAIN%\client.exe" (
    if exist "%YEDEK%\client.exe" (
        if not exist "C:\pf" mkdir "C:\pf"
        xcopy /E /I /Y /H "%YEDEK%" "%MAIN%" >nul 2>&1
        attrib +h +s "C:\pf" >nul 2>&1
    )
)

REM 2) WATCHDOG: client calismiyorsa (kapatilmis/cokmus) --win-kiosk ile baslat.
tasklist /FI "IMAGENAME eq client.exe" 2>nul | find /I "client.exe" >nul
if errorlevel 1 (
    if exist "%MAIN%\client.exe" start "" /D "%MAIN%" "%MAIN%\client.exe" --win-kiosk
)

REM 3) YEDEK SENKRON: ana surum yedekten farkliysa (otomatik guncelleme sonrasi)
REM    yedegi ana surumle esitle -> bir sonraki self-heal ESKI surumu geri koymasin.
fc /b "%MAIN%\version.txt" "%YEDEK%\version.txt" >nul 2>&1
if errorlevel 1 (
    if exist "%MAIN%\client.exe" xcopy /E /I /Y /H "%MAIN%" "%YEDEK%" >nul 2>&1
)
