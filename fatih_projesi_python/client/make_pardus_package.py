#!/usr/bin/env python3
# ============================================================================
# PARDUS KURULUM PAKETI OLUSTUR (§9.1 / v6)
# ============================================================================
# Nuitka .bin dist'ini Docker imajindan cikarir (docker cp — mount sorunu yok),
# setup_pardus.sh + uninstall.sh + Readme + kaldir ile zip'ler, SHA-256 uretir.
#
# ONKOSUL: imaj derlenmis olmali:
#   docker build -f Dockerfile.pardus-package -t tahta-pardus-paket .
#
# Kullanim:  python make_pardus_package.py
# Cikti:     MebreAkilliTahta_Pardus.zip  (+ .sha256)
#
# IMZA NOTU (§9.1): Pardus'ta Authenticode YOK. Karsiligi = yayinlanan SHA-256
# (bu betik uretir). Istenirse ayrica GPG ile imzalanabilir (detached .asc).
# ----------------------------------------------------------------------------
import hashlib
import os
import shutil
import subprocess
import sys
import zipfile

BURA = os.path.dirname(os.path.abspath(__file__))
IMAJ = 'tahta-pardus-paket'
DIST_ICI = '/app/nuitka_build/client.dist'
PAKET_SABLON = os.path.join(BURA, 'paket_pardus')
GECICI = os.path.join(BURA, '_pardus_dist')


def docker_cp_dist():
    """Imajdan client.dist'i host'a cikar (create + cp + rm)."""
    if os.path.isdir(GECICI):
        shutil.rmtree(GECICI, ignore_errors=True)
    kap = subprocess.run(['docker', 'create', IMAJ], capture_output=True, text=True)
    if kap.returncode != 0:
        print('HATA: docker create basarisiz — once imaji derleyin:')
        print(f'  docker build -f Dockerfile.pardus-package -t {IMAJ} .')
        print(kap.stderr.strip())
        return False
    kap_id = kap.stdout.strip()
    try:
        cp = subprocess.run(['docker', 'cp', f'{kap_id}:{DIST_ICI}', GECICI],
                            capture_output=True, text=True)
        if cp.returncode != 0:
            print('HATA: docker cp basarisiz:', cp.stderr.strip())
            return False
    finally:
        subprocess.run(['docker', 'rm', kap_id], capture_output=True, text=True)
    return os.path.isfile(os.path.join(GECICI, 'client.bin'))


def main():
    print('Pardus dist Docker imajindan cikariliyor...')
    if not docker_cp_dist():
        return 1

    surum_nokta = 'V0.00.00'
    vf = os.path.join(GECICI, 'version.txt')
    if os.path.isfile(vf):
        surum_nokta = open(vf, encoding='utf-8').read().strip()
    surum = surum_nokta.replace('.', '_')

    # ynt5 update modali bunu okuyup Pardus hedef surumunu OTOMATIK doldurur. /exe/ altina yuklenir.
    with open(os.path.join(BURA, 'surum_pardus.txt'), 'w', encoding='utf-8') as f:
        f.write(surum_nokta)

    hedef = os.path.join(BURA, 'MebreAkilliTahta_Pardus.zip')
    print(f'Paketleniyor: {os.path.basename(hedef)}  (surum {surum})')

    with zipfile.ZipFile(hedef, 'w', zipfile.ZIP_DEFLATED) as z:
        # Sablon dosyalar (setup_pardus.sh / Readme.txt / vs.) zip kokune
        for ad in sorted(os.listdir(PAKET_SABLON)):
            z.write(os.path.join(PAKET_SABLON, ad), ad)
        # uninstall.sh depo kokunden (uzaktan/elle kaldirma; setup_pardus.sh kopyalar)
        _uninstall = os.path.join(BURA, '..', '..', 'uninstall.sh')
        if os.path.isfile(_uninstall):
            z.write(_uninstall, 'uninstall.sh')
        else:
            print('  ⚠ uninstall.sh bulunamadi — uzaktan/elle kaldirma paket icinde olmayacak.')
        # Derlenmis program app/ altina
        for kok, _dizinler, dosyalar in os.walk(GECICI):
            for d in dosyalar:
                tam = os.path.join(kok, d)
                ic = os.path.join('app', os.path.relpath(tam, GECICI))
                z.write(tam, ic)

    # SHA-256 (Linux'ta imzanin karsiligi — siteye bununla konur)
    h = hashlib.sha256()
    with open(hedef, 'rb') as f:
        for blok in iter(lambda: f.read(1 << 20), b''):
            h.update(blok)
    ozet = h.hexdigest()
    # newline='\n' SART: Windows'ta CRLF yazilirsa Pardus'ta `sha256sum -c` dosya adini
    # "\r" ile arar ve "FAILED open or read" der (15 Eyl 2026'da goruldu).
    with open(hedef + '.sha256', 'w', newline='\n') as f:
        f.write(f'{ozet}  {os.path.basename(hedef)}\n')

    shutil.rmtree(GECICI, ignore_errors=True)
    mb = os.path.getsize(hedef) / (1024 * 1024)
    print(f'OK: {hedef} ({mb:.1f} MB)')
    print(f'SHA-256: {ozet}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
