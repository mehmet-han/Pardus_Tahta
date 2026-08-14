#!/usr/bin/env bash
# ============================================================================
# PARDUS / DEBIAN — client.py'yi Nuitka ile DERLE (obfuscation, §9.4)
# ============================================================================
# Amac: duz Python client.py -> makine koduna derlenmis, icini okunamayan
# calistirilabilir (standalone). Sahadaki Pardus tahtalarina bu gider.
#
# Gerçek Pardus makinede ya da Debian 12 tabanli bir ortamda calistirin:
#     bash build_pardus_nuitka.sh
#
# Cikti: ./nuitka_build/client.dist/client.bin  (+ yaninda Qt/kutuphaneler)
# ----------------------------------------------------------------------------
set -euo pipefail

BURA="$(cd "$(dirname "$0")" && pwd)"
cd "$BURA"

echo "== 1) Bagimliliklar (gcc + python3-dev + PyQt5 + patchelf) =="
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y python3 python3-pip python3-dev python3-pyqt5 gcc patchelf ccache
fi
# requests/urllib3 derleme aninda kurulu olmali ki Nuitka standalone'a gomsun.
python3 -m pip install --user --upgrade nuitka ordered-set requests urllib3

echo "== 2) Nuitka derleme (standalone + PyQt5 plugin) =="
# --standalone : tum bagimliliklari yanina koyar (tahtada python kurulu olmasa da calisir)
# --enable-plugin=pyqt5 : Qt'yi dogru gomer
# --assume-yes-for-downloads : gerekli parcalari sormadan indir
python3 -m nuitka \
    --standalone \
    --enable-plugin=pyqt5 \
    --assume-yes-for-downloads \
    --output-dir=nuitka_build \
    --remove-output \
    client.py

echo "== 3) Derlenen ikiliyi --test ile dogrula (pencere yok, kilit yok) =="
BIN="nuitka_build/client.dist/client.bin"
if [ -x "$BIN" ]; then
    "$BIN" --test || true
    echo ""
    echo "OK: $BIN uretildi."
    echo "Kanit: 'strings $BIN' ciktisinda sabit anahtar/sir DUZ METIN gorunmemeli (§9.4)."
else
    echo "HATA: $BIN uretilemedi — yukaridaki Nuitka ciktisina bak."
    exit 1
fi
