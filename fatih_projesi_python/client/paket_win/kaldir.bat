@echo off
chcp 65001 >nul
REM MEBRE AKILLI TAHTA — elle kaldirma (normalde panelden uzaktan kaldirilir)
REM ONEMLI: once watchdog gorevini durdur, yoksa healer dosyalari geri koyar.
schtasks /Delete /TN "MebreTahtaBekci" /F >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v MebreTahta /f >nul 2>&1
REM Dokunmatik kabuk hareketleri ilkelerini geri al (kur.bat / client kilitte yaziyor)
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\EdgeUI" /v AllowEdgeSwipe /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Windows\EdgeUI" /v AllowEdgeSwipe /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Wisp\Touch" /v TouchGestureSetting /f >nul 2>&1
taskkill /IM client.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul
attrib -h -s "C:\pf" >nul 2>&1
attrib -h -s "C:\ProgramData\MebreSvc" >nul 2>&1
rmdir /S /Q "C:\pf\Tahta" >nul 2>&1
rmdir /S /Q "C:\ProgramData\MebreSvc" >nul 2>&1
REM Eski konumdan (varsa) da temizle
rmdir /S /Q "C:\MebreTahta" >nul 2>&1
echo Kaldirildi.
pause
