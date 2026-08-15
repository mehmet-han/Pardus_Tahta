#!/bin/bash
# ============================================================================
# MEBRE AKILLI TAHTA — UZAKTAN GUNCELLEME UYGULAYICI (root, §9.2)
# ============================================================================
# Cagiran: client.bin (etapadmin) -> `sudo -n /usr/local/bin/fatih-update`
# Sudoers YALNIZCA ARGUMANSIZ cagriya izin verir (fatih-uninstall deseni); staging
# yolu bu betikte SABIT (arguman ile disaridan yonlendirilemez).
#
# Ne yapar: ~etapadmin/.mebre_upd/app icindeki YENI surumu /opt/fatih-client'a
# kopyalar (config.ini KORUNUR = cihaz kimligi), eskiyi .eski olarak yedekler
# (rollback), servisi yeniden baslatir (yeni client.bin).
#
# GUVENLIK: client paketi ZATEN indirmeden once SHA-256 dogruladi. Bu betik
# sadece dosya-sistemi islemini yapar; etapadmin /opt'a yazamadigi icin bu dar
# yetki gerekli (kaldirma yetkisiyle ayni seviye — zaten mevcut risk).
# ----------------------------------------------------------------------------
set -e

HEDEF="/opt/fatih-client"
# Staging SABIT: sudoers argumansiz izin verdigi icin disaridan degistirilemez.
YENI="$(getent passwd etapadmin | cut -d: -f6)/.mebre_upd/app"

[ -d "$YENI" ]            || { echo "HATA: yeni surum klasoru yok: $YENI"; exit 1; }
[ -x "$YENI/client.bin" ] || { echo "HATA: $YENI/client.bin yok"; exit 2; }
[ -d "$HEDEF" ]           || { echo "HATA: kurulum yok: $HEDEF"; exit 3; }

echo "[fatih-update] eski surum yedekleniyor (.eski)..."
rm -rf "${HEDEF}.eski" 2>/dev/null || true
cp -a "$HEDEF" "${HEDEF}.eski" 2>/dev/null || true

echo "[fatih-update] yeni surum kopyalaniyor (config.ini korunuyor)..."
if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete --exclude 'config.ini' "$YENI"/ "$HEDEF"/
else
    # rsync yoksa: config.ini haric her seyi sil, yeniyi kopyala.
    find "$HEDEF" -mindepth 1 -maxdepth 1 ! -name 'config.ini' -exec rm -rf {} + 2>/dev/null || true
    cp -a "$YENI"/. "$HEDEF"/
fi

# Izinler: yalniz root + etapadmin (ogrenci/ogretmen okuyamaz).
chown -R root:etapadmin "$HEDEF"
chmod -R 750 "$HEDEF"
[ -f "$HEDEF/config.ini" ] && chmod 600 "$HEDEF/config.ini"

# Staging'i temizle.
rm -rf "$(dirname "$YENI")" 2>/dev/null || true

echo "[fatih-update] servis yeniden baslatiliyor..."
# Kopyalama BITTI; restart bu sureci (cagiran client) oldurse bile yeni dosyalar
# yerinde ve systemd yeni client.bin'i baslatir (Restart=always guvencesi).
systemctl restart fatih-client-app.service 2>/dev/null || true
echo "[fatih-update] guncelleme uygulandi."
