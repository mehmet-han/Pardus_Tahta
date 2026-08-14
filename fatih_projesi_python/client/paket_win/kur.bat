@echo off
chcp 65001 >nul
REM ============================================================================
REM MEBRE AKILLI TAHTA — WINDOWS KURULUM (W6-3 / §9.1)
REM ============================================================================
REM Ne yapar:
REM   1) Program dosyalarini C:\MebreTahta klasorune kopyalar
REM   2) Oturum acilisinda OTOMATIK baslamayi kaydeder (kilit modu: --win-kiosk)
REM   3) Programi tanitim icin baslatir (Kurulum Kodu'nu panelden alip girin)
REM ----------------------------------------------------------------------------
set HEDEF=C:\MebreTahta

echo Mebre Akilli Tahta kuruluyor...
xcopy /E /I /Y "%~dp0app" "%HEDEF%" >nul
if errorlevel 1 (
    echo HATA: Dosyalar kopyalanamadi. Yonetici olarak calistirmayi deneyin.
    pause
    exit /b 1
)

REM Readme.txt paket kokunde doldurulduysa yanina tasi (kurulum kodu otomatik okunur)
if exist "%~dp0Readme.txt" copy /Y "%~dp0Readme.txt" "%HEDEF%\Readme.txt" >nul

REM Oturum acilisinda kilit modunda otomatik baslat
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v MebreTahta /t REG_SZ /d "\"%HEDEF%\client.exe\" --win-kiosk" /f >nul

echo.
echo Kurulum tamam. Simdi tanitim ekrani aciliyor...
echo Panelden uretilen 12 haneli KURULUM KODU'nu girip sinifi tanitin.
start "" /D "%HEDEF%" "%HEDEF%\client.exe"
