@echo off
REM ============================================================================
REM WINDOWS — client.py'yi Nuitka ile DERLE (obfuscation §9.4 + paket §9.1 / W6-3)
REM ============================================================================
REM Cikti: nuitka_build_win\client.dist\client.exe (+ yaninda Qt/kutuphaneler)
REM Gereksinim: VS Build Tools 2022 (MSVC) + pip: nuitka, pyqt5, requests
REM
REM SIRA (project_rules §9.1 — imza EN SON kod adimi):
REM   1) bu betik (derleme)  2) --test dogrulama  3) SECTIGO IMZA (signtool, kullanici)
REM   4) make_windows_package.py (zip)  5) mebre.com.tr/exe/ yukleme
REM ----------------------------------------------------------------------------
cd /d "%~dp0"

python -m nuitka ^
    --standalone ^
    --msvc=latest ^
    --enable-plugin=pyqt5 ^
    --assume-yes-for-downloads ^
    --windows-console-mode=disable ^
    --include-data-dir=resources=resources ^
    --include-data-files=version.txt=version.txt ^
    --output-dir=nuitka_build_win ^
    --remove-output ^
    client.py

if errorlevel 1 (
    echo HATA: Nuitka derleme basarisiz.
    exit /b 1
)

echo.
echo OK: nuitka_build_win\client.dist\client.exe uretildi.
echo Dogrulama: client.exe --test  (pencere yok, kilit yok)
echo Kanit (§9.4): strings ciktisinda sabit anahtar DUZ METIN gorunmemeli.
