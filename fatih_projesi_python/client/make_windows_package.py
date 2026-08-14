#!/usr/bin/env python3
# ============================================================================
# WINDOWS KURULUM PAKETI OLUSTUR (§9.1 / W6-3)
# ============================================================================
# SIRA (project_rules §9.1 — imza EN SON kod adimi, zip imzadan SONRA):
#   1) build_windows_nuitka.bat      (derleme)
#   2) client.exe --test             (dogrulama)
#   3) SECTIGO IMZA (kullanici):
#      signtool sign /fd SHA256 /tr http://timestamp.sectigo.com /td SHA256 ^
#          nuitka_build_win\client.dist\client.exe
#   4) python make_windows_package.py   (bu betik — zip'i uretir)
#   5) mebre.com.tr/exe/ altina yukle
#
# Cikti: Fatih_Client_Kurulum_Win_V<surum>.zip
#   kur.bat / kaldir.bat / Readme.txt (kod alani BOS — sir yok!) / app\ (client.dist)
# ----------------------------------------------------------------------------
import os
import sys
import zipfile

BURA = os.path.dirname(os.path.abspath(__file__))
DIST = os.path.join(BURA, 'nuitka_build_win', 'client.dist')
PAKET_SABLON = os.path.join(BURA, 'paket_win')


def main():
    exe = os.path.join(DIST, 'client.exe')
    if not os.path.isfile(exe):
        print('HATA: client.exe yok — once build_windows_nuitka.bat calistirin.')
        return 1

    surum = 'V0_00_00'
    vf = os.path.join(BURA, 'version.txt')
    if os.path.isfile(vf):
        surum = open(vf, encoding='utf-8').read().strip().replace('.', '_')

    hedef = os.path.join(BURA, f'Fatih_Client_Kurulum_Win_{surum}.zip')
    print(f'Paketleniyor: {os.path.basename(hedef)}')
    print('NOT: client.exe IMZALANDI MI? Imza zip\'ten ONCE atilmali (§9.1).')

    with zipfile.ZipFile(hedef, 'w', zipfile.ZIP_DEFLATED) as z:
        # Sablon dosyalar (kur/kaldir/Readme) zip kokune
        for ad in os.listdir(PAKET_SABLON):
            z.write(os.path.join(PAKET_SABLON, ad), ad)
        # Derlenmis uygulama app\ altina
        for kok, _dizinler, dosyalar in os.walk(DIST):
            for d in dosyalar:
                tam = os.path.join(kok, d)
                ic = os.path.join('app', os.path.relpath(tam, DIST))
                z.write(tam, ic)

    mb = os.path.getsize(hedef) / (1024 * 1024)
    print(f'OK: {hedef} ({mb:.1f} MB)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
