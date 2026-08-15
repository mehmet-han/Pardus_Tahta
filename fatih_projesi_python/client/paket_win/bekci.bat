@echo off
REM ============================================================================
REM MEBRE AKILLI TAHTA — WINDOWS BEKCI (watchdog)  (C# SmartBoardServiceSystm karsiligi)
REM ============================================================================
REM Zamanlanmis gorev bunu DAKIKADA BIR calistirir. client.exe calismiyorsa
REM (biri kapatti/coktu) --win-kiosk ile YENIDEN baslatir. Pardus'taki systemd
REM Restart=always'in Windows karsiligi. Tek-ornek kilidi sayesinde client zaten
REM calisiyorken bu yeni baslatma sessizce cikar (dublicate olmaz).
REM ----------------------------------------------------------------------------
tasklist /FI "IMAGENAME eq client.exe" 2>nul | find /I "client.exe" >nul
if errorlevel 1 (
    start "" /D "C:\pf\Tahta" "C:\pf\Tahta\client.exe" --win-kiosk
)
