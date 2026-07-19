#!/usr/bin/env python3
"""
provision_board.py — Pardus tahtası INTERAKTİF kurulum + cihaz token'ı üretim aracı. FAZ 2 / Seçenek A.

⛔ Bu araç DAĞITILAN İSTEMCİYE GİRMEZ. `fatih_projesi_python/client/` dışında durur; paket_olustur.py
   yalnızca `client/` klasörünü paketler. Enroll sırrı (DEVICE_ENROLL_SECRET) çalışma anında tutulur;
   config.ini'ye VEYA istemci binary'sine ASLA yazılmaz.

Akış (teknisyen tahtayı kurarken çalıştırır):
  1) Kurum kodu + enroll sırrı alınır.
  2) POST /boards  → o kurumun tahta listesi; teknisyen doğru tahtayı seçer.
  3) POST /enroll  → cihaz token'ı üretilir (dönen token yalnızca bir kez).
  4) config.ini'ye yazılır: corporate_code, board_id, board_name (düz), device_token (ENC:base64).
  5) POST /poll    → token'la doğrulanır (200 + status:true beklenir).

Kullanım:
  python3 provision_board.py
  DEVICE_ENROLL_SECRET=... python3 provision_board.py --kurum 353535
  python3 provision_board.py --secret ... --kurum 353535 --url https://apiv5.mebre.com.tr

Sır önceliği: --secret > DEVICE_ENROLL_SECRET env > interaktif sorma. Hiçbir durumda saklanmaz.
"""

import argparse
import base64
import configparser
import getpass
import os
import sys
import time

try:
    import requests
except ImportError:
    print("HATA: 'requests' modülü gerekli (istemci ortamında kurulu olmalı).", file=sys.stderr)
    sys.exit(2)


# Karar: PROD backend (client XOR'u da apiv5.mebre.com.tr'ye bakıyor).
DEFAULT_BASE_URL = "https://apiv5.mebre.com.tr"
DEVICE_PATH = "/client/akilli_tahta_cihaz"

# client.py ile AYNI config yolları (kiosk kullanıcısı sistem/kiosk kopyasından okur).
APP_NAME = "fatih-client"
USER_CONFIG_PATH = os.path.expanduser(f"~/.config/{APP_NAME}/config.ini")
SYSTEM_CONFIG_PATH = "/opt/fatih-client/config.ini"
KIOSK_CONFIG_PATH = "/home/fatih-kiosk/.config/fatih-client/config.ini"


def enc(value: str) -> str:
    """client.py `_deo` ile uyumlu obfuscation: 'ENC:' + base64."""
    return "ENC:" + base64.b64encode(value.encode("utf-8")).decode("ascii")


def get_secret(cli_secret: str) -> str:
    if cli_secret:
        return cli_secret
    env = os.environ.get("DEVICE_ENROLL_SECRET")
    if env:
        return env
    return getpass.getpass("Enroll sırrı (DEVICE_ENROLL_SECRET): ").strip()


def api(base, path, *, secret=None, token=None, body=None, verify=True, timeout=30):
    """v5 cihaz API çağrısı. secret -> X-Enroll-Secret; token -> Bearer + X-Timestamp."""
    headers = {"Content-Type": "application/json"}
    if secret:
        headers["X-Enroll-Secret"] = secret
    if token:
        headers["Authorization"] = f"Bearer {token}"
        headers["X-Timestamp"] = str(int(time.time()))
    r = requests.post(f"{base}{DEVICE_PATH}{path}", headers=headers, json=(body or {}), timeout=timeout, verify=verify)
    return r


def list_boards(base, secret, kurum, verify):
    try:
        r = api(base, "/boards", secret=secret, body={"corporateCode": kurum}, verify=verify)
    except requests.RequestException as e:
        sys.exit(f"HATA: /boards isteği başarısız: {e}")
    if r.status_code != 200:
        sys.exit(f"HATA: /boards {r.status_code}: {r.text[:300]}")
    try:
        return r.json()["result"]["boards"]
    except (ValueError, KeyError):
        sys.exit(f"HATA: /boards yanıtı beklenmedik: {r.text[:300]}")


def enroll(base, secret, kurum, board_id, board_name, verify):
    try:
        r = api(base, "/enroll", secret=secret,
                body={"corporateCode": kurum, "boardId": board_id, "boardName": board_name}, verify=verify)
    except requests.RequestException as e:
        sys.exit(f"HATA: /enroll isteği başarısız: {e}")
    if r.status_code != 200:
        sys.exit(f"HATA: /enroll {r.status_code}: {r.text[:300]}")
    try:
        token = r.json()["result"]["token"]
    except (ValueError, KeyError):
        sys.exit(f"HATA: /enroll yanıtı beklenmedik: {r.text[:300]}")
    if not token:
        sys.exit("HATA: token boş döndü.")
    return token


def write_config(config_path, kurum, board_id, board_name, token) -> bool:
    """config.ini'ye kimlik (düz) + device_token (ENC) yazar. Dosya yoksa/erişilemezse False."""
    if not os.path.exists(config_path):
        return False
    try:
        cfg = configparser.ConfigParser()
        cfg.read(config_path)
        if "settings" not in cfg:
            cfg.add_section("settings")
        cfg.set("settings", "corporate_code", str(kurum))
        cfg.set("settings", "board_id", str(board_id))
        cfg.set("settings", "board_name", board_name)
        cfg.set("settings", "device_token", enc(token))
        with open(config_path, "w") as f:
            cfg.write(f)
        return True
    except PermissionError:
        print(f"  ⚠ yazma izni yok (sudo gerekebilir): {config_path}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"  ⚠ yazılamadı {config_path}: {e}", file=sys.stderr)
        return False


def main():
    ap = argparse.ArgumentParser(description="Pardus tahtası interaktif kurulum + provisioning (Faz 2, Seçenek A).")
    ap.add_argument("--config", default=USER_CONFIG_PATH, help="Ana config.ini yolu")
    ap.add_argument("--url", default=DEFAULT_BASE_URL, help="v5 taban URL (varsayılan PROD apiv5.mebre.com.tr)")
    ap.add_argument("--secret", default="", help="Enroll sırrı (verilmezse env/prompt; SAKLANMAZ)")
    ap.add_argument("--kurum", default="", help="Kurum kodu (verilmezse sorulur)")
    ap.add_argument("--no-verify-tls", action="store_true", help="TLS doğrulamasını kapat (SADECE test)")
    args = ap.parse_args()

    base = args.url.rstrip("/")
    verify = not args.no_verify_tls
    secret = get_secret(args.secret)
    if not secret:
        sys.exit("HATA: enroll sırrı boş.")

    kurum = (args.kurum or input("Kurum kodu: ").strip())
    if not kurum:
        sys.exit("HATA: kurum kodu boş.")

    # 1) Tahta listesi
    boards = list_boards(base, secret, kurum, verify)
    if not boards:
        sys.exit(f"Bu kurum ({kurum}) için tahta bulunamadı. Önce masaüstü/panelden tahta tanımlanmalı.")

    print(f"\n{kurum} kurumunun tahtaları:")
    for i, b in enumerate(boards, 1):
        aktif = "" if b.get("aktif", 1) else "  (pasif)"
        print(f"  [{i}] board_id={b['boardId']}  {b['name']}{aktif}")

    # 2) Seçim
    sel = input("\nBu tahta hangisi? (numara): ").strip()
    try:
        chosen = boards[int(sel) - 1]
    except (ValueError, IndexError):
        sys.exit("HATA: geçersiz seçim.")
    board_id = int(chosen["boardId"])
    board_name = chosen["name"]

    onay = input(f"\nSeçim: board_id={board_id} ({board_name}). Enroll edilsin mi? [e/H]: ").strip().lower()
    if onay not in ("e", "evet", "y", "yes"):
        sys.exit("İptal edildi.")

    # 3) Enroll
    token = enroll(base, secret, kurum, board_id, board_name, verify)
    secret = None  # sırrı RAM'den düşür

    # 4) Config'lere yaz (var olan tüm kopyalar)
    targets = [args.config]
    for p in (SYSTEM_CONFIG_PATH, KIOSK_CONFIG_PATH):
        if p != args.config and os.path.exists(p):
            targets.append(p)
    written = [p for p in targets if write_config(p, kurum, board_id, board_name, token)]
    if not written:
        sys.exit("HATA: config hiçbir yere yazılamadı (izin? sudo ile dene).")
    print("\nConfig yazıldı:")
    for p in written:
        print(f"  ✅ {p}")

    # 5) Doğrulama
    try:
        v = api(base, "/poll", token=token, verify=verify)
        if v.status_code == 200 and v.json().get("status") is True:
            print(f"✅ Doğrulama başarılı — /poll: {v.json().get('result')}")
        else:
            print(f"⚠ Doğrulama beklenmedik: {v.status_code} {v.text[:200]}", file=sys.stderr)
    except requests.RequestException as e:
        print(f"⚠ Doğrulama isteği başarısız (token yazıldı ama poll denenemedi): {e}", file=sys.stderr)

    token = None
    print("\nKurulum tamam. İstemci yeniden başlatılınca tahta v5'e bağlanacak.")


if __name__ == "__main__":
    main()
