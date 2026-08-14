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

### T5 — GERÇEK Windows kiosk (`--win-kiosk`) — makine gelince
> ⚠️ Bu adım gerçekten kilitler (tam ekran + taskbar gizli + klavye kilidi + ses kapalı).
> **Güvenlik ağları:** (1) panik **Ctrl+Alt+Shift+Q**, (2) **Ctrl+Alt+Del** her zaman → Görev
> Yöneticisi → python.exe sonlandır, (3) **reboot serbest bırakır** (autostart Registry'ye HENÜZ
> yazılmıyor — W6-3 adım 4). Yani makine kalıcı kilitlenemez.
```
python client.py --win-kiosk
```
**Beklenen:** tam ekran kilit ekranı, taskbar yok, Win/Alt+Tab/Alt+F4 engelli, ses kapalı, pencere
hep üstte. **Enroll + mobilden aç/kapat testi** — önce sırrı yaz, sonra kiosk'u aç:
```
python client.py --set-enroll-secret <SIR>     # Readme.txt içeriği; config'e ENC: yazar
python client.py --win-kiosk                    # tahtayı panelden/mobilden tanıt → aç/kapat dene
```
**DURUM: ⏳ makine bekliyor (kod hazır, commit e2457c1).**

> Not: `python client.py` (bayraksız) Windows'ta HÂLÂ güvenli önizleme — kilitleme YOK.
> Gerçek kilit **sadece `--win-kiosk`** ile. `python client.py --help` tüm bayrakları listeler.

---

## 4. Durum tablosu (W6)

| Aşama | İçerik | Durum |
|---|---|---|
| **W6-0** | Fizibilite — UI Windows'ta render | ✅ kanıtlandı |
| **W6-1** | Platform katmanı (`platform_layer.py`: arayüz + Linux + Windows) | ✅ |
| **W6-2** | Zorlama primitifleri: taskbar/uyku/ses/kill | ✅ kanıtlandı |
| **W6-2B** | Klavye kilidi (low-level hook, panik+auto-release) | ✅ kanıtlandı |
| **W6-3.1** | Gerçek Windows kilit akışı (`--win-kiosk`) + `force_on_top` + enroll helper | ✅ kod (makine testi ⏳) |
| **W6-3.2+** | Autostart + uninstall + Task Mgr + token + paketleme (aşağıda) | ⏳ sıradaki |

---

## 5. W6-3 — kalan işler (sıradaki, entegrasyon ağırlıklı)

1. **✅ Gerçek Windows kilit akışı — BİTTİ (kod, commit e2457c1).** `--win-kiosk` bayrağı: `init_ui`
   tam ekran/çerçevesiz/topmost, `main()` `lock_system` çağırır → `hide_taskbar` + `disable_shortcuts`
   (klavye kilidi) + `disable_sleep` + `mute` + `kill_all_browsers`. Bayraksız = güvenli önizleme (değişmedi).
   Enroll helper: `--set-enroll-secret <SIR>` (Windows'ta setup.sh yerine config'e ENC: yazar).
   **Makine testi bekliyor (T5).**
2. **✅ `force_on_top` — BİTTİ.** `platform_layer.force_window_on_top(hwnd)` → Windows `SetWindowPos(HWND_TOPMOST)`
   (x64 prototipli), Linux no-op (client._force_on_top xdotool kullanmaya devam). `_force_on_top` Windows dalı bunu çağırır.
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

---

## 9. SÜRÜM DAĞITIMI & SERTLEŞTİRME — Pardus + Windows üretim çıkışı (13 Ağu 2026 planı)

> **Amaç (kullanıcı):** Hem Pardus hem Windows'u sahaya çıkarmak. Tek şifreli zip kurulum (şifre
> telefonla). Zamanlı/okul-bazlı güncelleme. Sunucuya sızma yolu SIFIR. Öğrenci tahtayı kural dışı
> açamasın, programı kaldıramasın, dosyalar gizli + her dağıtımdan önce tersine-mühendisliğe karşı
> obfuscate. Aşağıdaki "AÇIK" maddeleri **iki bağımsız denetimden** (güncelleme + güvenlik) çıktı.
> **HİÇBİRİ HENÜZ UYGULANMADI — kullanıcı "başla" deyince sıraya girer.**

### 9.1 Kurulum paketi (her iki OS, şifreli zip) + KOD İMZALAMA (Sectigo)
- **Mevcut:** `paket_olustur.py` "KORUMALI" paket = yalnız **sabit-şifreli AES ZIP** (şifre kaynakta:
  `ZIP_SIFRE = env("FATIH_ZIP_SIFRE","803417")`). İçindeki `client.py` DÜZ kaynak. Enroll sırrı pakette
  `Readme.txt`'te dolaşıyor. Eski C# masaüstü **Sectigo kod-imzalama sertifikasıyla imzalanıp** siteye konuyor.
- **Hedef:** İki OS için tek kurulum mantığı; zip şifresi kaynağa gömülü DEĞİL, indirene telefonla verilir.
  İçerik gerçek obfuscate (9.4). Enroll sırrı okul-özel+süreli (9.3).
- **KOD İMZALAMA (kullanıcı isteği — masaüstündeki akışın aynısı):**
  - **Windows:** PyInstaller `.exe` üretilir → **Sectigo sertifikasıyla `signtool` (Authenticode)** imzalanır
    (SmartScreen/AV uyarısını kaldırır, "doğrulanmış yayıncı" gösterir) → siteye/kuruluma konur. Masaüstünde
    yapılan işlemin birebir aynısı. Zaman damgası (RFC 3161) ile imzala (sertifika bitse de imza geçerli kalır).
  - **Pardus/Linux:** Authenticode YOK. Karşılığı: paketi **GPG ile imzala** (ya da imzalı apt deposu) veya en
    azından şifreli zip + yayınlanan SHA-256 sağlaması. `.exe` imzası Linux'ta işe yaramaz.
  - Her dağıtımdan önceki sıra: **derle/obfuscate (9.4) → imzala → (şifreli) paketle → yayınla.**
- **DAĞITIM / indirme sayfası (mebre.com.tr — kullanıcı düzenliyor):** Paketler `https://mebre.com.tr/exe/`
  altında **sürümlü adlarla** yayınlanır (ör. Windows `Fatih_Client_Kurulum_V1_00_93.zip`, Pardus
  `MebreAkilliTahta.zip`). İndirme alanında **3 program** gösterilecek (bilgisayar+telefon görselinin
  üzerinde): **(1) MebreOkul · (2) Windows için Akıllı Tahta Kilit · (3) Pardus için Akıllı Tahta Kilit.**
  Website'i kullanıcı düzenler; biz paketleri bu yola koyarız (her şey bitince).
- **apply_update BAĞLANTISI:** Otomatik güncelleme (9.2) tam bu `/exe/` URL'lerinden indirir → imza/SHA-256
  doğrular → uygular. `guncelle_hedef` (hedef sürüm) → indirilecek paket adı türetilir (ör.
  `Fatih_Client_Kurulum_V1_00_XX.zip`). URL şeması client'ta config alanı olur.

### 9.2 Zamanlı / okul-bazlı güncelleme (YENİ sistem — asıl acı nokta)
- **Mevcut:** Uzaktan güncelleme kanalı YOK. Güncelleme %100 elle (`git pull` + `setup.sh`/dosya kopyala,
  SSH/menü). `/version`+`check_version` sadece "⬆ Güncelleme mevcut" ETİKETİ (indirme/uygulama yok;
  sürüm global, okul bazlı değil). Poll komutları yalnız `openClose/message/shutdown/system_Remove/log_istek`.
  Windows'ta hiçbir güncelleme yolu yok.
- **İskelet (hazır model):** `system_Remove` akışı = komut→ACK→çalıştır→denetim kaydı (`tahta_kaldirma_kayit`).
  Client-side `/schedule` = zaman-penceresi örneği. Başarısızlık raporu = **yeni hata denetimi kanalı** (9.6).
- **MODEL (kullanıcı kararı 13 Ağu): OTOMATİK + KADEMELİ (insan başında ŞART DEĞİL).**
  - ynt5'ten bir okul (ya da tek tahta) "**açılır açılmaz güncelle**" diye işaretlenir.
  - O okulun tahtaları bir sonraki açılışta/poll'da güncellemeyi **kimse başında olmadan otomatik alır**.
  - Güncelleme **takılır/başarısız olursa tahta bize RAPOR eder** (hata denetimi, `tip='guncelleme'`) →
    düzeltiriz. Başarılıysa yeni sürümü bildirir (client_surum zaten poll'da gidiyor → panelde görülür).
  - Okullar **sırayla, elle tetiklenir** (A okulu tamam → B okulu işaretle...). Toplu "hepsi birden" YOK;
    kademeli yayılım = bir hata çıkarsa tek okulda kalır.
  - **Opsiyonel zaman penceresi:** istenirse "şu saat aralığında" da işaretlenebilir (ör. mesai dışı);
    varsayılan "açılışta". Ders ortasında kesmemek için tahta, güncellemeyi kilitliyken/açılışta uygular.
- **Gereken parçalar:**
  1. **Sunucu kaydı (okul/tahta bazlı):** `guncelle` bayrağı + `hedef_surum` + tetik tipi (`acilista` |
     `pencere`) + (varsa) pencere başlangıç/bitiş + son durum (`beklemede/indiriliyor/uygulandi/basarisiz`).
  2. **Poll'da alan:** `guncelle=1, hedefSurum, tetik/pencere`. ACK whitelist'e güncelleme kolonu.
  3. **Panel (ynt5):** okul/tahta seç → "açılışta güncelle" işaretle/kaldır + durum sütunu (kaç tahta aldı,
     kaç başarısız). Kademeli: okul okul.
  4. **Tahtada `apply_update` uygulayıcısı:** komutla tetiklenir → imzalı/şifreli paketi indir → doğrula
     (imza/sağlama) → kur → restart. **Windows'ta ayrı** (exe değişimi + Registry). Başarısızlıkta rollback +
     rapor. `remove_system()` bunun yakın modeli.
  5. **Başarısızlık/durdu raporu:** her adım hata denetimine yazılır (`kaynak='tahta', tip='guncelleme:...'`)
     → HataGunlugu'nda görülür, düzeltilir. Bu geri-bildirim döngüsü kullanıcının açık isteği.
  6. **Denetim kaydı:** kim işaretledi (ynt5 kullanıcı), hangi okul/tahta, sonuç.

### 9.3 Sunucuya sızma önleme (güvenlik denetimi)
- **İYİ (korunacak):** token→tek okul kapsamı + çapraz-okul reddi (`deviceAuth`, `controller.js:68`);
  ACK kolon whitelist (SQLi kapalı); token sunucuda yalnız sha256 hash; enroll sonrası sır silme.
- **AÇIK 1 — tek paylaşılan enroll sırrı:** `DEVICE_ENROLL_SECRET` tüm okullar için TEK sabit; `/boards`+
  `/enroll` ile ele geçiren biri **çapraz-okul token basar + gerçek tahtayı ezer**. Pakette dolaşıyor.
  → **Hedef:** okul-özel + süreli provisioning token (ynt5'ten üret — [[provisioning-token-ynt5]]).
- **AÇIK 2 — config'te zayıf sır saklama:** `device_token`/`enroll_secret` config.ini'de yalnız `ENC:`
  = base64 (şifreleme değil); dosya dünya-okunur → token hırsızlığı → öğrenci PII (`/display`,`/sinav_oturma`).
  → **Hedef:** gerçek şifreleme (Linux keyring / Windows DPAPI) + izin 600 + gizleme.

### 9.4 Obfuscation / tersine mühendislik (EN KRİTİK — şu an TAMAMEN YOK)
- **Mevcut:** `client.py` sahaya DÜZ Python (7465 satır) gidiyor. "compiled into .so" yorumları GERÇEK DEĞİL;
  pyarmor lisanssız başarısız; Cython/PyInstaller uygulanmıyor. Kaynaktan çıkan filo-geneli sabit sırlar:
  XOR anahtarı `pardus2026!`, USB açma/kaldırma şifreleri, **KRİZ ana anahtarı**, URL/UA.
- **Hedef (HER dağıtımdan ÖNCE):**
  1. Gerçek derleme/obfuscation: Windows → PyInstaller `.exe` + pyarmor(lisans) ya da **Nuitka**; Pardus →
     Nuitka/Cython `.so`. Düz `client.py` sahaya çıkmaz.
  2. **Filo-geneli sabit sırları KALDIR → tahta-özel türet** (TOTP zaten tahta-özel; USB/kriz de olmalı).
  3. XOR "gizleme" yerine derlenmiş binary + tahta-özel anahtar.

### 9.5 Öğrenci sertleştirme (güvenlik denetimi)
- **AÇIK — sudoers fazla açık:** `ALL ALL NOPASSWD: reboot/shutdown` (HERKES → öğrenci tahtayı kapatır, DoS);
  `autologin-switch.sh` argümansız + `/opt/fatih-client` sahibi fatih-kiosk → **root yükseltme yolu**.
  → **Hedef:** sudoers'ı daralt (gerekli komut+argüman kısıtı; /opt sahibi root, 700).
- **AÇIK — kırık offline formül:** eski `Year*Day*Minute*85` şifresi tanıtılmamış tahtalarda HÂLÂ aktif
  (öğrenciler çözmüş). → **Hedef:** tamamen kaldır, yalnız tahta-özel TOTP.
- **AÇIK — kilit atlatma yolları:** `Ctrl+Alt+F2` tty geçişi engellenmiyor (Xorg `DontVTSwitch` yok);
  kilit aktifken sonradan takılan USB klavye grab dışı; **Windows'ta klavye kilidi kiosk akışına bağlı
  değil**; `Ctrl+Alt+Shift+Q` panik çıkışı kiosk'ta bile açık. → **Hedef:** Xorg `DontVTSwitch`+VT lock;
  klavye hot-plug izleme (pyudev var); Windows low-level hook'u (W6-2B yazıldı) kiosk akışına bağla;
  **panik çıkışı sahada kapat/gizle** (sadece test build'inde).
- **AÇIK — dosya gizli değil:** `/opt/fatih-client` 755 dünya-okunur; config `~/.config` umask 644.
  → **Hedef:** 700/root + gizleme + config 600.

### 9.6 Hata denetimi — DOĞRULANDI ✅ (iki OS)
Tek kod tabanı, **platform-kapısı YOK**: `_hata_bildir`/excepthook/`report_error`/poll-platform hepsi
Pardus+Windows'ta birebir. Yalnız **güncel client.py** çalışan tahtalarda devreye girer → 9.2 (güncelleme
dağıtımı) çözülmeden sahadaki eski tahtalardan geri dönüş gelmez.

### 9.8 SÜRELİ UYUTMA (tarih aralığı — sınav/tatil) [YENİ istek 14 Ağu]
- **İhtiyaç:** Okulda sınav (ör. 2 gün) ya da uzun tatil (**8 aya kadar**) olunca kilit programı DEVRE DIŞI
  kalmalı; tahta normal açılıp kapanmalı. Elle "aç" yetmez (kalıcı + unutulur); tarih bitince OTOMATİK
  normale dönmeli.
- **Model:** ynt5'ten okul/tahta için **uyku başlangıç + bitiş tarihi** girilir. Poll tahtaya iletir.
  Tahta: `uyku_bas ≤ now ≤ uyku_bit` ise **uykuda** = kilit YOK, tam normal masaüstü. Aralık dışında
  normal kilit davranışı KENDİLİĞİNDEN döner (elle müdahale yok).
- **Çevrimdışı dayanıklılık:** uyku aralığı config'e yazılır → sunucuya ulaşılamasa bile pencere içinde
  uykuda kalır (sınav günü internet kesilse bile tahta kilitlenmez).
- **Gereken parçalar:** (1) sunucu kaydı `uyku_bas/uyku_bit` (smart_board_post ya da akilli_tahtalar),
  (2) poll'da bu alanlar, (3) panelde tarih aralığı seç (okul/tahta) + net "şu tarihe kadar AÇIK" uyarısı,
  (4) client: uyku penceresinde `lock_system` atla + aralık bitince normale dön, (5) denetim (kim, hangi
  aralık). **guncelle_hedef ile AYNI kanal (poll) — küçük ek**, güncelleme mekanizmasıyla birlikte gelir.
- **Güvenlik notu:** Uyku sırasında tahta tamamen açık → öğrenci erişimi mümkün; bu KASITLI (sınav modu).
  Aralık sınırlı olduğu için risk bounded; panelde "açık" durumu net gösterilir.

### 9.7 Sıra önerisi (başla denince)
1. **Obfuscation + sabit-sır temizliği (9.4)** — diğer her şeyin ön koşulu; sırlar açıkken diğer sertleştirme
   yarım kalır. 2. **Zamanlı güncelleme (9.2)** — asıl acı nokta + hata denetimini sahaya taşır.
3. **Öğrenci sertleştirme (9.5)** + **config/enroll sır (9.3)**. 4. **Şifreli zip + telefon şifresi (9.1)**.
