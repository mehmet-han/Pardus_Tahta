@echo off
chcp 65001 >nul
REM ============================================================================
REM MEBRE AKILLI TAHTA — WINDOWS KURULUM (W6-3 / §9.1)
REM ============================================================================
REM Ne yapar:
REM   1) Program dosyalarini C:\pf\Tahta klasorune kopyalar (C# masaustu programiyla
REM      AYNI konvansiyon: C:\pf sistem-benzeri, taninmayan klasor) + klasoru GIZLER
REM      (ogrenci gormesin/silmesin; tahta kilitliyken zaten Explorer'a erisilemez).
REM   2) Oturum acilisinda OTOMATIK baslamayi kaydeder (kilit modu: --win-kiosk)
REM   3) Programi DOGRUDAN KILIT EKRANI (--win-kiosk) olarak baslatir; operator
REM      kilit ekraninda SAG TIK ile tanitimi yapar. Onizleme/X'li pencere YOK.
REM ----------------------------------------------------------------------------
set KOK=C:\pf
set HEDEF=C:\pf\Tahta

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

REM Klasoru GIZLE + sistem (ogrenci Explorer'da gormesin). Icindeki calisma etkilenmez.
attrib +h +s "%KOK%" >nul 2>&1

REM Oturum acilisinda kilit modunda otomatik baslat
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v MebreTahta /t REG_SZ /d "\"%HEDEF%\client.exe\" --win-kiosk" /f >nul

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
REM Operator kilit ekraninda SAG TIK ile tanitir. Bir sonraki acilista da
REM HKCU\Run kaydi ayni sekilde --win-kiosk baslatir.
start "" /D "%HEDEF%" "%HEDEF%\client.exe" --win-kiosk
