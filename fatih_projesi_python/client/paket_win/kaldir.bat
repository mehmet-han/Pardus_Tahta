@echo off
chcp 65001 >nul
REM MEBRE AKILLI TAHTA — elle kaldirma (normalde panelden uzaktan kaldirilir)
schtasks /Delete /TN "MebreTahtaBekci" /F >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v MebreTahta /f >nul 2>&1
taskkill /IM client.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul
attrib -h -s "C:\pf" >nul 2>&1
rmdir /S /Q "C:\pf\Tahta"
REM Eski konumdan (varsa) da temizle
rmdir /S /Q "C:\MebreTahta" >nul 2>&1
echo Kaldirildi.
pause
