@echo off
chcp 65001 >nul
REM MEBRE AKILLI TAHTA — elle kaldirma (normalde panelden uzaktan kaldirilir)
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v MebreTahta /f >nul 2>&1
taskkill /IM client.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul
rmdir /S /Q "C:\MebreTahta"
echo Kaldirildi.
pause
