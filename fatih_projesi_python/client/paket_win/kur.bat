@echo off
chcp 65001 >nul
REM ============================================================================
REM MEBRE AKILLI TAHTA — WINDOWS KURULUM (W6-3 / §9.1 / §9.2)
REM ============================================================================
REM Ne yapar:
REM   1) Program dosyalarini C:\pf\Tahta'ya kopyalar (C# 'C:\pf' konvansiyonu) + GIZLER.
REM   2) AYNI dosyalarin YEDEGINI C:\ProgramData\MebreSvc\app'e koyar (self-heal kaynagi).
REM      -> ana klasor silinse watchdog yedekten geri koyar.
REM   3) Dakikada bir "client.exe --watchdog" calistiran gorev (KONSOLSUZ GUI -> pencere ACMAZ).
REM   4) Programi DOGRUDAN KILIT EKRANI (--win-kiosk) baslatir; operator SAG TIK ile tanitir.
REM ----------------------------------------------------------------------------
set KOK=C:\pf
set HEDEF=C:\pf\Tahta
set SVC=C:\ProgramData\MebreSvc

echo Mebre Akilli Tahta kuruluyor...
if not exist "%KOK%" mkdir "%KOK%"
xcopy /E /I /Y "%~dp0app" "%HEDEF%" >nul
if errorlevel 1 (
    echo HATA: Dosyalar kopyalanamadi. Yonetici olarak calistirmayi deneyin.
    pause
    exit /b 1
)

REM Readme.txt paket kokunde doldurulduysa yanina tasi (kurulum kodu otomatik okunur)
if exist "%~dp0Readme.txt" copy /Y "%~dp0Readme.txt" "%HEDEF%\Readme.txt" >nul

REM YEDEK (ayri gizli konum -> ana klasor silinse watchdog buradan geri koyar).
if not exist "%SVC%" mkdir "%SVC%"
xcopy /E /I /Y "%~dp0app" "%SVC%\app" >nul
attrib +h +s "%SVC%" >nul 2>&1

REM Ana klasoru de GIZLE (ogrenci Explorer'da gormesin).
attrib +h +s "%KOK%" >nul 2>&1

REM Oturum acilisinda kilit modunda otomatik baslat
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v MebreTahta /t REG_SZ /d "\"%HEDEF%\client.exe\" --win-kiosk" /f >nul

REM WATCHDOG + SELF-HEAL: dakikada bir YEDEKTEKI client.exe --watchdog. client.exe KONSOLSUZ
REM GUI oldugu icin HIC PENCERE ACMAZ (eski healer.bat/VBS console-flash sorunu bitti). Ana
REM client'i baslatir + ana klasor silinse yedekten geri koyar. /RL LIMITED = yonetici gerekmez.
schtasks /Create /TN "MebreTahtaBekci" /TR "\"%SVC%\app\client.exe\" --watchdog" /SC MINUTE /MO 1 /RL LIMITED /F >nul 2>&1

echo.
echo ============================================================
echo  KURULUM TAMAM. Kilit ekrani aciliyor.
echo ------------------------------------------------------------
echo  Kilit ekraninda tanitim icin:
echo   1) Bos yere SAG TIKLAYIN.
echo   2) "Sifre Degistir" ile varsayilan sifreyi degistirin.
echo   3) Tekrar sag tik - "Tahta Yapilandirmasi":
echo      Kurum Kodu + 12 haneli Kurulum Kodu + Sifre girin.
echo   4) "Tahtalari Getir" - sinifi secin - "Onayla".
echo  (Acil cikis gerekirse: Ctrl+Alt+Shift+Q)
echo ============================================================
echo.
REM DOGRUDAN kilit ekrani (--win-kiosk): tam ekran, X yok, taskbar gizli.
start "" /D "%HEDEF%" "%HEDEF%\client.exe" --win-kiosk
