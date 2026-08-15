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
echo ============================================================
echo  KURULUM TAMAM. Simdi TANITIM ekrani aciliyor (onizleme).
echo ------------------------------------------------------------
echo  1) Kilit ekraninda bos yere SAG TIKLAYIN.
echo  2) "Sifre Degistir" ile varsayilan sifreyi degistirin.
echo  3) Tekrar sag tik - "Tahta Yapilandirmasi":
echo     Kurum Kodu + 12 haneli Kurulum Kodu + Sifre girin.
echo  4) "Tahtalari Getir" - sinifi secin - "Onayla".
echo  5) Tanitim bitince bu pencereyi KAPATIN (sag ustteki X).
echo     -> Tahta hemen TAM EKRAN kilitlenecektir.
echo ============================================================
echo.
REM Onizleme: operator tanitim yapar. Pencereyi KAPATINCA (X) buraya doner.
start /wait "" /D "%HEDEF%" "%HEDEF%\client.exe"

REM Tanitim bitti (pencere kapandi) -> GERCEK tam-ekran kilit modunu baslat.
REM Bir sonraki acilista da HKCU\Run kaydi ayni sekilde --win-kiosk baslatir.
echo Tam ekran kilit modu baslatiliyor...
start "" /D "%HEDEF%" "%HEDEF%\client.exe" --win-kiosk
