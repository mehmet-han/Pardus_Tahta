# Akıllı Tahta (Pardus v6) — Bağımsız İnceleme Notu

**Tarih:** 3 Ağustos 2026
**Durum:** İlk saha kurulumu YAPILMADI. Yarın ilk tahtaya kurulacak.
**Sürüm:** V6.00.34 · tahta deposu `Pardus_Tahta` dal `v6` · sunucu `v5` dal `main`

---

## Neden bu inceleme isteniyor

70 okulda tahta kurulu. Sahada tahtayı yeniden kurmak veya elle güncellemek
**hem çok maliyetli hem pratikte imkânsız** — okula gitmek gerekiyor, tahtalar
sınıflarda, ders saatleri dolu. Bu yüzden ilk kurulumdan önce hatanın **sıfıra**
yakın olması gerekiyor. Yayına çıktıktan sonra "küçük bir düzeltme" diye bir şey yok.

İstenen: sistemin tamamının bağımsız gözle, baştan sona okunması ve
**kurulumdan sonra düzeltilmesi zor olacak** hataların bulunması.

---

## Sistem ne yapıyor

Pardus işletim sistemli akıllı tahtalara kurulan bir **kiosk/kilit** uygulaması.

- Tahta ders dışında **kilitli** durur; tam ekran bir pencere ekranı kaplar,
  klavye `evdev` ile exclusive grab edilir, görev çubuğu gizlenir.
- Öğretmen tahtayı MebreCep'ten (mobil), yönetim panelinden veya tahtadaki
  admin şifresiyle açar. Ders çıkış saatinde otomatik kilitlenir.
- Kilit ekranında üç pano: **aferin (ilk 5)**, **doğum günü**, **bugün gelmeyenler**;
  ayrıca **duyuru slider'ı** ve sınav saatinde **sınav oturma düzeni**.
- Sunucu tarafı: `v5` (Node.js/Express + MySQL), cihaz uçları
  `/client/akilli_tahta_cihaz/*`.

### Bileşenler

| Dosya | Ne yapar | Satır |
|---|---|---|
| `fatih_projesi_python/client/client.py` | Tahta istemcisi (PyQt5). Kilit, paneller, sunucu iletişimi, şifre doğrulama | ~7100 |
| `setup.sh` | Kurulum: derleme (Cython), kopyalama, sudoers, autostart, hesap kilitleri | ~340 |
| `uninstall.sh` | Kaldırma; şifre veya uzaktan kaldırma kanıtı ister | ~150 |
| `doktor.sh` | Saha teşhis aracı | ~125 |
| v5 `src/apps/akilliTahtaCihaz/*` | Cihaz uçları: enroll, boards, poll, ack, schedule, display, sinav_oturma | — |
| v5 `src/routes|services|repositories/client/tahta_duyuru/*` | Tahta duyuruları | — |

---

## Güvenlik modeli (incelemede en çok önemsenen)

1. **Cihaz kimliği:** her tahta `enroll` ile bir **cihaz token'ı** alır. Sunucu
   yalnızca `sha256(token)`'ı saklar. Sonraki her istek `Authorization: Bearer <token>`
   + `X-Timestamp` (±300 sn replay penceresi) ile gider. Kimlik (kurum_kodu, tahta_no)
   **token'dan** çözülür, gövdeden asla okunmaz.

2. **Kurulum sırrı:** `enroll`/`boards` uçları paylaşılan bir sırla korunur
   (`DEVICE_ENROLL_SECRET`). Sır kurulum medyasında `Readme.txt` içinde gömülüdür
   (dosyadaki ilk 64 haneli hex). Tanıtım biter bitmez tahtadan **silinir**.
   Tanıtılmış tahta, sır olmadan mevcut token'ıyla yeniden tanıtılabilir —
   ama **yalnızca kendi okulu** için.

3. **Çevrimdışı açma:** tahta-özel TOTP (HMAC-SHA256, device_token türevli, 60 sn adım).
   Eski `Y·d·m·85` formülü öğrenciler tarafından kırılmıştı, kaldırıldı.

4. **Kriz kodu:** sunucu tamamen çökerse tahtayı açar.
   `HMAC-SHA256(ANA_ANAHTAR, "<kurum_kodu>-<YYYYMMDD>")` → 8 hane. Tamamen çevrimdışı
   doğrulanır, okula ve güne özeldir, girildiğinde tahta **24 saat kilitlenmez**.

5. **Kaba kuvvet:** 5 hatalı denemede ekran kilitlenir.

6. **Denetim:** sunucudan komut almadan yapılan her açılış `smart_boadr_logs`'a
   "Yerel açılış" olarak düşer ve sebebi (admin şifresi / çevrimdışı şifre / kriz kodu)
   yazılır. ynt5'te "Şüpheli Açılışlar" ekranı bunu gösterir.

---

## Bugün bulunan ve düzeltilen hatalar (doğrulama için)

Bu maddeler **zaten düzeltildi**; incelemede aynı hataların başka yerde tekrarlanıp
tekrarlanmadığına bakılması faydalı olur.

1. **Kriz penceresi etkisizdi.** Poll başarısız olunca çalışan "internet kesildi, kilitle"
   dalı kriz penceresini kontrol etmiyordu. Kriz kodu tam da internet/sunucu yokken
   giriliyor; ilk başarısız poll tahtayı yeniden kilitliyordu. `check_schedule` ve
   başlangıç kilidi kontrol ediyordu, yalnız bu dal atlanmıştı. → **V6.00.33**

2. **Açılış sebebi her zaman kayboluyordu.** Şifre doğrulanınca önce *sebepsiz*
   `acknowledge_command("tahtaLock","0")` gidiyor, ardından `unlock_system` sebepli
   ack'i atıyordu. Sunucu "yerel açılış" kaydını `open_close` 1→0 geçişinde yazdığı
   için sebep hep boş kalıyordu. → **V6.00.33**

3. **`sudo fatih-uninstall --force` şifreyi atlıyordu.** sudoers kuralı argüman
   kısıtlamıyordu; tahtada terminale erişen herkes kilit sistemini tek komutla
   kaldırabiliyordu. → **V6.00.34** (sudoers argümansız + stdin kanıtı)

4. **Duyuru metni HTML olarak işleniyordu.** QLabel varsayılanı `Qt.AutoText`;
   `<img src="http://...">` gibi içerik tahtada çalışıyordu. → **V6.00.31**

5. **Sunucuda `DEVICE_ENROLL_SECRET` hiç tanımlı değildi** — V6.00.02'den beri hiçbir
   yeni tahta kurulamıyordu, kimse denemediği için fark edilmemişti. → düzeltildi.

---

## AÇIK MADDELER — özellikle bunlara bakılması isteniyor

Aşağıdakiler **bilinçli olarak** çözülmedi; ya karar gerektiriyor ya da kurulumdan
bir gün önce denenmemiş değişiklik riski taşıyor. İnceleyenin görüşü isteniyor.

### A. `etapadmin` hesabının şifresi yok
`setup.sh` `passwd -d etapadmin` yapıyor (boş şifre). Debian/Pardus PAM'i genelde
`nullok` taşıdığı için bu, **TTY'den boş şifreyle giriş** anlamına gelebilir.
`ogretmen`/`ogrenci` hesapları `passwd -l` ile kilitlendi ama `etapadmin`'e
dokunulmadı: lightdm otomatik girişi o hesapla yapılıyor ve kilitlemek tahtayı
açılamaz hale getirebilir.
**Soru:** otomatik girişi bozmadan bu hesabı nasıl kapatmalı?

### B. Konsol (VT) geçişi engellenmiyor
Kilitliyken `evdev` grab'i `Ctrl+Alt+F2`'yi de engelliyor (sahada dizüstü klavyesiyle
doğrulandı). Ancak grab **yalnızca başlangıçta bulunan cihazlara** uygulanıyor:
kilitliyken **sonradan takılan USB klavye** grab'li değil. Ayrıca `DontVTSwitch` yok,
tty2-6 maskelenmedi.
**Not:** VT'yi tamamen kapatmak, uygulama çökerse tahtaya girecek yol bırakmıyor —
70 tahtalık filoda bu risk kabul edilmedi.

### C. Autostart kullanıcı seviyesinden iptal edilebilir
Otomatik başlatma `/etc/xdg/autostart/` (root, 644). Kullanıcı kendi
`~/.config/autostart/` altına aynı isimde `Hidden=true` dosya koyarsa program hiç
başlamaz. Root'a ait bir gözcü servis (systemd) düşünüldü, kurulumdan önce
denenmemiş değişiklik riski nedeniyle yapılmadı.

### D. Paylaşılan kurulum sırrı geniş dağılıyor
Tahtaları yalnızca Mebre kurmuyor — diğer firmalar ve öğretmenler de kuruyor.
Sır bu yüzden çok elde. Dosya adı `secret.txt` → `Readme.txt` yapıldı ve içerik
gerçek bir kurulum kılavuzuna gömüldü, ama bu **gizleme**, şifreleme değil.
Sunucuda `/enroll` ve `/boards` uçlarına 5 dk/30 istek sınırı kondu.
Kalıcı çözüm (ynt5'ten okula özel süreli kod) sahada uygulanamaz bulundu:
"gece 2'de de tahta kuruyorlar, her kuruluma kod veremeyiz".

### E. Kriz kodu ana anahtarı tahtada gömülü
`client.py` içinde XOR+hex ile gizlenmiş. Root erişimi olan biri teorik olarak
çıkarabilir; çıkarsa **tüm okullar** etkilenir. Azaltma: sürümle döndürülebilir olması
ve her kullanımın denetim kaydına düşmesi.

### F. Ders programı tazeliği
Öğretmen duyurusu, okulun masaüstünden gönderdiği `mobiledata.data_ogretmen`
blob'undan doğrulanıyor. Okul programı değiştirip senkron etmezse öğretmen haklıyken
reddediliyor. Hata mesajı sebebi açık söylüyor ama sahada şikâyet gelmesi bekleniyor.

---

## İnceleme yaparken özellikle bakılması istenenler

1. **Tahtanın kilitli kalmama ihtimali olan HER yol.** Fail-safe kapalı olmalı:
   şüphe varsa kilitli kalsın. `unlock_system` çağıran tüm yerler, `manual_override`
   davranışı, poll hatası, saat kayması, sunucu 401'i.
2. **Tahtanın açılamaz hale gelme ihtimali.** Kilit ekranındaki bir çizim hatası
   (panel/duyuru/sınav) uygulamayı çökertirse tahta ne olur? İstisna yakalama yeterli mi?
3. **Yarım kurulum durumları.** `setup.sh` ortada kesilirse tahta hangi durumda kalır?
4. **Saat/zaman dilimi.** Sunucu UTC, tahta yerel; NTP senkronu var. Kilit saatleri,
   sınav saatleri, kriz kodunun gün sınırı, duyuru `hedef_tarih` — tutarlı mı?
5. **Yeniden tanıtma yolu** (V6.00.30) — token'la kendi okulu dışına çıkılabiliyor mu?
6. **Kaldırma yetkisi** (V6.00.34) — stdin kanıtı atlatılabilir mi?
7. **Sunucu tarafı:** `ack` kolon beyaz listesi, `deviceAuth` replay penceresi,
   `/display` ve `/sinav_oturma` null güvenliği, duyuru metin temizliği.

## Bakılmasına gerek olmayanlar

- ynt5 paneli (iç yönetim, ayrı depo) — tahtanın çalışmasını etkilemiyor
- MebreCep mobil uygulaması — ayrı ekip, ayrı depo
- Masaüstü MebreOkul (C#) — ayrı ekip

---

## Doğrulama komutları

```bash
# Tahta istemcisi derleniyor mu / statik analiz
python -m py_compile fatih_projesi_python/client/client.py
python -m pyflakes  fatih_projesi_python/client/client.py

# Kabuk betikleri
bash -n setup.sh && bash -n uninstall.sh && bash -n doktor.sh

# Sunucu tarafı
cd ../v5 && for f in $(git ls-files 'src/**/*.js'); do node --check "$f" || echo "HATA: $f"; done
```

**Not:** Bu depoda `Readme.txt` / `secret.txt` **yoktur** (`.gitignore`). Kurulum
kodunu taşıyan dosya yalnızca kurulum USB'sindedir.
