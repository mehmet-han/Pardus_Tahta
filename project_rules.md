# Windows Portu (W6) — Kurallar ve Test Playbook'u

> **Amaç:** Sahadaki yüzlerce eski **C# v2 (V2.13, v4/PHP bağımlı)** Windows tahtayı, okullar
> açılmadan **aynı Python `client.py` ile** değiştirmek → v4/PHP bağımlılığını tamamen bitirmek.
> **Windows tam parite şart.** Bu belge, yeni bir Windows makinede her parçayı **tek tek, güvenle**
> test etmek için hazırlandı (Pardus'u denediğimiz gibi).
>
> **Branch:** Tüm Windows işi `windows` branch'inde (`git checkout windows`). Pardus canlı hattı
> (`v6`/`main`, V6.00.48) ETKİLENMEZ. **Tek kod tabanı:** Pardus + Windows aynı `client.py`'yi
> paylaşır; fark sadece `platform_layer.py` içindeki zorlama katmanında.
>
> Son güncelleme: 2026-07-20. İlgili: `pardusv6_project_rules.md` (Pardus kuralları),
> `faz3_csharp_gecis_playbook.md` (ARTIK GEÇERSİZ — Faz 3 iptal, çünkü client.py zaten v5 konuşuyor).

---

## 0. Karar ve mimari (neden Python)

- **Karar:** C#'ı v5'e taşıyıp tüm özellikleri (offline şifre, aferin/doğum günü/yoklama panelleri,
  uzaktan kaldırma, duyuru...) yeniden yazmak yerine → **AYNI Python istemcisini Windows'ta çalıştır.**
  Böylece tek kod tabanı; her yeni özellik bir kez yazılır. C# ayrı repo (`Fatih_Client_CSharp`) sadece
  referans/arşiv kalır.
- **`client.py` iki katman:**
  1. **TAŞINIR (~%70):** NetworkClient (v5 cihaz sözleşmesi), tüm `/display` panelleri, offline TOTP
     şifre, kilit ekranı UI (PyQt5). Cross-platform — Windows'ta çalıştığı KANITLANDI.
  2. **OS-özel zorlama:** taskbar/ses/kısayol/uyku/ön-uygulama/klavye kilidi/USB/autostart/kurulum.
     `platform_layer.py` arkasına alındı: `LinuxBackend` (Pardus) + `WindowsBackend` (yeni).
- **Sürümleme:** `V6.00.xx` (eski V2.13 şeması biter). `version.txt` = tek doğruluk kaynağı
  (config.ini bump'ı kaçırabilir; runtime version.txt kazanır). Windows dağıtımı `v6.00.01`'den başlar.

---

## 1. Windows makine hazırlığı

1. **Python 3.11+** kur (python.org). Kurulumda "Add to PATH" işaretle.
2. Depoyu al: `windows` branch. (D: yedeğinden ya da mevcut kopyadan.)
   ```
   git checkout windows
   ```
3. Bağımlılıklar:
   ```
   pip install PyQt5 requests urllib3
   pip install pycaw comtypes        # ses için (opsiyonel — yoksa ses no-op)
   ```
   > evdev / pyudev KURULMAZ (Linux'a özel; kodda guard'lı, Windows'ta no-op).

---

## 2. ⚠️ GÜVENLİK — önce oku (test makineni kilitlemez)

Hiçbir test adımı makineyi **kalıcı kilitlemez**. Kanıtlı sebepler:

- **Format/silme kodu YOK.** `remove_system` bile Linux yolları siler (`/opt/fatih-client`), Windows'ta
  çalışmaz ve zaten sadece sunucu "kaldır" komutuyla tetiklenir, açılışta değil.
- **Güvenli önizleme (main):** Windows'ta `client.py` çalışınca kiosk zorlaması (`lock_system`) HİÇ
  çağrılmaz; pencere **normal, çerçeveli (X butonlu), hep-üstte DEĞİL** açılır.
- **Klavye kilidi testinde 3 güvenlik ağı:**
  1. **PANİK:** `Ctrl+Alt+Shift+Q` → hook'u anında bırakır.
  2. **Otomatik:** test 15sn sonra kendini bırakır (+ bağımsız 20sn sert-timer).
  3. **`Ctrl+Alt+Del` HER ZAMAN çalışır** (Windows kernel SAS — kullanıcı-modu hook engelleyemez).
     Nihai kaçış: Ctrl+Alt+Del → Görev Yöneticisi → python.exe sonlandır.
- **Reboot'ta geri gelmez:** Windows'ta autostart Registry'ye yazılmıyor (W6-3'te gelecek). Kapattın mı biter.

---

## 3. Test adımları (tek tek, sıralı)

Hepsini `fatih_projesi_python\client` klasöründen çalıştır:
```
cd C:\Github\Pardus_Tahta_v6\fatih_projesi_python\client
```

### T1 — Import + config (sıfır risk, pencere yok)
```
python client.py --test
```
**Beklenen:** `✅ Configuration loaded successfully` + admin şifresi. Pencere açılmaz.
**Kanıtlar:** import (evdev/pyudev guard'ları), config okuma, XOR çözme Windows'ta çalışıyor.
**DURUM: ✅ geçti.**

### T2 — UI önizleme (kilit ekranı, normal pencere)
```
python client.py
```
**Beklenen:** ~1280×800 **normal, X butonlu** pencerede kilit ekranı (arka plan, "Tahtayı Açın"
butonu, saat, sürüm, MEBRE logosu). Paneller (aferin/yoklama) BOŞ olabilir — normal (config'te
device_token yok, `/display`'e kimlik doğrulayamıyor). Önemli olan pencerenin çizilmesi.
**Kapatma:** X butonu / Alt+F4.
**DURUM: ✅ geçti (kilit ekranı render oldu).**

### T3 — Zorlama primitifleri öz-testi (auto-revert)
```
python platform_layer.py
```
**Beklenen (her biri denenir + HEMEN geri alınır):**
1. Uyku engeli açılır.
2. Ses kapanır (2sn) → açılır (pycaw kuruluysa; yoksa atlanır).
3. **Görev çubuğu 3sn kaybolur → geri gelir.** ← asıl kanıt.
`kill_foreground_apps` bu testte YOK (tarayıcılarını kapatmasın diye).
**DURUM: ✅ geçti (taskbar gizlenip geldi).**

### T4 — Klavye kilidi (15sn, güvenli)
```
python platform_layer.py --test-keylock
```
**Beklenen:** "Klavye kilidi AKTİF..." log'u + 15sn geri sayım. Kilit aktifken DENE:
- **Win tuşu** → Başlat açılmamalı
- **Alt+Tab** → pencere değişmemeli
- **Alt+F4** → kapanmamalı
- **Ctrl+Esc / Alt+Esc** → engelli
**Bırakma:** 15sn bekle (otomatik) / `Ctrl+Alt+Shift+Q` (panik) / son çare `Ctrl+Alt+Del`.
Bırakılınca Alt+Tab/Win **tekrar çalışmalı.**
**DURUM: ✅ geçti (hepsi engellendi, otomatik bırakıldı).**
> Sorun çıkarsa: "SetWindowsHookExW başarısız (GetLastError=...)" log'unu paylaş.

---

## 4. Durum tablosu (W6)

| Aşama | İçerik | Durum |
|---|---|---|
| **W6-0** | Fizibilite — UI Windows'ta render | ✅ kanıtlandı |
| **W6-1** | Platform katmanı (`platform_layer.py`: arayüz + Linux + Windows) | ✅ |
| **W6-2** | Zorlama primitifleri: taskbar/uyku/ses/kill | ✅ kanıtlandı |
| **W6-2B** | Klavye kilidi (low-level hook, panik+auto-release) | ✅ kanıtlandı |
| **W6-3** | Entegrasyon + paketleme + kurulum (aşağıda) | ⏳ sıradaki |

---

## 5. W6-3 — kalan işler (sıradaki, entegrasyon ağırlıklı)

1. **Gerçek Windows kilit akışı:** Şu an `main()` Windows'ta `lock_system`'i ATLIYOR (güvenli önizleme).
   Windows'a özel bir kilit path'i: primitifleri (`platform_layer`) bağla — tam ekran topmost kilit ekranı +
   `hide_taskbar` + `disable_shortcuts` (klavye kilidi) + `disable_sleep` + `mute`. Açılışta kilitli gelsin.
2. **`force_on_top`:** Pencereyi üstte tutma → Windows `SetWindowPos(HWND_TOPMOST)` (Linux'ta xdotool).
   Platform arayüzüne ekle.
3. **Task Manager sertleştirme:** `DisableTaskMgr` policy (Registry) + gerekiyorsa kill. (Ctrl+Alt+Del
   engellenemez ama Görev Yöneticisi'ni zorlaştır.)
4. **Autostart:** Registry `Run` anahtarı veya Task Scheduler (Linux'ta systemd/.desktop yerine).
5. **Uninstall (uzaktan kaldırma):** Windows karşılığı — autostart sil + kurulum dizinini sil (sudo YOK;
   Windows'ta admin/servis kapsamı). `remove_system`'i platform'a yönlendir.
6. **Token saklama:** Registry + DPAPI (Linux'ta config.ini + XOR yerine). Enroll akışı aynı v5 uçları.
7. **Paketleme:** PyInstaller ile tek `.exe` (+ obfuscation, Pardus KORUMALI muadili). Inno Setup ile
   kurulum (C# `Yükleyici` yerine). Sürüm `v6.00.01`.
8. **Saha:** v2 tahtaları tespit et → yeni programla değiştir → v4 trafiğini kes.

---

## 6. Kritik kurallar / tuzaklar (unutma)

- **x64 ctypes tuzağı (W6-2B'de yaşandı):** Win32 fonksiyonlarına `argtypes`/`restype` tanımlamazsan
  64-bit pointer'lar (modül handle, callback, hook handle, LRESULT) 32-bit'e KIRPILIR ve API sessizce
  başarısız olur (hook kurulmaz). Her Win32 çağrısında imzayı tanımla.
- **Ctrl+Alt+Del engellenemez:** Windows kernel-seviyesi Secure Attention Sequence. Kusur değil,
  güvenlik ağı (makine asla tam kilitlenmez). Gerçek kiosk'ta Görev Yöneticisi'ni policy ile zorlaştır.
- **`IS_WINDOWS` guard:** Linux-özel importlar (evdev/pyudev) ve Windows-özel ctypes kodu platform
  guard'ı arkasında — biri diğerinin import'unu bozmamalı.
- **Tek kod tabanı korunacak:** Pardus'a eklenen her özellik `windows` branch'ine MERGE edilir; kod
  ayrı repoya taşınmaz (yoksa iki kopya senkron kâbusu geri gelir).
- **v4 dokunulmaz:** Geçiş paralel; eski v2 tahtalar hâlâ v4'e vurur, kesim en sonda.
- **Sır yasağı:** enroll sırrı (dosya adı artık `Readme.txt`), admin şifresi, token düz metin yazılmaz.

---

## 7. Yedekleme

Yerel git + **harici disk (D:) ayna** (internet YOK). Bu repo `windows` branch'i her commit'te
`yedek` remote'una (`D:\MebreYedek\Pardus_Tahta_v6.git`) push'lanabilir. Merkezi notlar +
tek-tık yedek: `C:\Github\mebre-tahta-v6\` (`yedekle-hepsi.bat`).

---

## 8. Referanslar (C# Windows karşılıkları — W6-3'te işe yarar)

`platform_layer.py`'deki zorlama, C#'tan port edildi; C#'ta Windows implementasyonları HAZIR:
- `PanelManager` ↔ C# `TastbarWindows.cs` (taskbar gizle/göster)
- `VolumeControl` ↔ C# `SendMessageW` APPCOMMAND_VOLUME_MUTE/UP
- `ShortcutManager` ↔ C# `CtrlAltDel` engelleme
- Kilit/kiosk ↔ C# `Form1.cs` `LockSystm`
Kaynak: `C:\Github\Fatih_Client_CSharp` (arşiv/referans).
