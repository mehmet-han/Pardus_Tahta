@echo off
chcp 65001 >nul
REM ============================================================================
REM MEBRE AKILLI TAHTA — WINDOWS KURULUM (W6-3 / §9.1 / §9.2)
REM ============================================================================
REM Ne yapar:
REM   0) YONETICI degilse kendini yukseltir (C:\pf + otomatik giris icin gerekli).
REM   1) Program dosyalarini C:\pf\Tahta'ya kopyalar (C# 'C:\pf' konvansiyonu) + GIZLER.
REM   2) Yedegi C:\ProgramData\MebreSvc\app'e koyar (self-heal kaynagi).
REM   3) Dakikada bir "client.exe --watchdog" gorevi (KONSOLSUZ -> pencere ACMAZ).
REM   4) OTOMATIK GIRIS: boot'ta parola SORULMADAN masaustu -> kilit (C# gibi).
REM   5) Programi DOGRUDAN KILIT EKRANI (--win-kiosk) baslatir; operator SAG TIK ile tanitir.
REM ----------------------------------------------------------------------------

REM --- [0] Yonetici yukseltmesi (self-elevate) ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Yonetici izni gerekiyor, yukseltiliyor...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set KOK=C:\pf
set HEDEF=C:\pf\Tahta
set SVC=C:\ProgramData\MebreSvc

REM --- [0.5] ESKI SURUM TEMIZLIGI (C# FatihProjesi + eski Python denemeleri) ---
REM Eski C# programi Winlogon Userinit'ini C:\pf\Systm\FatihProjesi.exe YAPIYORDU.
REM !! SIRA KRITIK: ONCE Userinit varsayilana dondurulur, SONRA dosyalar silinir.
REM    (Once silinirse makine OTURUM ACAMAZ hale gelir.) Sonundaki virgul Windows standardi.
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Userinit /t REG_SZ /d "C:\Windows\system32\userinit.exe," /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoRestartShell /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v FatihProjesi /f >nul 2>&1
taskkill /IM FatihProjesi.exe /F >nul 2>&1
taskkill /IM ConfigServices.exe /F >nul 2>&1
taskkill /IM usp.exe /F >nul 2>&1
rmdir /S /Q "C:\pf\Systm" >nul 2>&1
rmdir /S /Q "C:\Windws" >nul 2>&1
rmdir /S /Q "C:\Configure" >nul 2>&1
del /F /Q "C:\Systm.sys" >nul 2>&1
del /F /Q "%ProgramFiles%\Systm.sys" >nul 2>&1
rmdir /S /Q "C:\MebreTahta" >nul 2>&1
REM Gorev Yoneticisi kilidi (C# mirasi) tahtada BILINCLI KORUNUR/SETLENIR (kiosk sertlestirme,
REM project_rules 6). Kaldirma betigi bunu 0'a geri alir - yanlis kurulumda iz kalmaz.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /t REG_DWORD /d 1 /f >nul 2>&1
REM DOKUNMATIK KABUK HAREKETLERI KAPALI (19 Eyl 2026, saha videosu): ogrenci sol kenardan
REM kaydirip Windows 11 Gorev Gorunumu'nu acti, yeni sanal masaustune gecti -> kilit ekrani
REM gorunmez. Klavye hook'u dokunmatik hareketleri yutamaz. Kenar kaydirma ilkesi HKLM+HKCU,
REM 3-4 parmak hareketleri HKCU. Client kilitte HKCU'yu her seferinde yeniden yazar.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\EdgeUI" /v AllowEdgeSwipe /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\EdgeUI" /v AllowEdgeSwipe /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Wisp\Touch" /v TouchGestureSetting /t REG_DWORD /d 0 /f >nul 2>&1

echo Mebre Akilli Tahta kuruluyor...
REM Onceki V6 kurulumunun uzerine TEMIZ kurulum (9 Eyl): calisan client durdurulur
REM (dosyalar kilitliyken xcopy yarim kalabiliyordu) + hedefler SIFIRLANIR ki eski
REM surumden artik dosya kalmasin. Kimlik/config AppData'dadir, SILINMEZ ->
REM yeniden tanitim GEREKMEZ.
schtasks /End /TN "MebreTahtaBekci" >nul 2>&1
taskkill /IM client.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul
rmdir /S /Q "%HEDEF%" >nul 2>&1
rmdir /S /Q "%SVC%\app" >nul 2>&1
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

REM UZAKTAN KALDIRMA GOREVI (9 Eyl fix): client SINIRLI kullanici oldugu icin admin-olusturulan
REM watchdog gorevini + C:\pf'i SILEMIYORDU -> uzaktan kaldirma "uygulandi" der ama watchdog geri
REM getiriyordu. Bu gorev SYSTEM/HIGHEST calisir; client `schtasks /Run` ile tetikler, SYSTEM her
REM seyi siler. /SC ONCE + gecmis /ST -> KENDILIGINDEN CALISMAZ, yalniz /Run ile tetiklenir.
schtasks /Create /TN "MebreTahtaKaldir" /TR "\"%HEDEF%\client.exe\" --kaldir" /SC ONCE /ST 00:00 /RU SYSTEM /RL HIGHEST /F >nul 2>&1

REM OTOMATIK GIRIS (C# karsiligi): boot'ta parola SORULMASIN -> dogrudan masaustu -> kilit.
REM Hesap parolasi bosaltilir (kiosk kilidi zaten guvenlik; C# de boyle yapiyordu) + AutoAdminLogon.
net user "%USERNAME%" "" >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LimitBlankPasswordUse /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d "%USERNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d "" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultDomainName /t REG_SZ /d "%COMPUTERNAME%" /f >nul 2>&1

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
