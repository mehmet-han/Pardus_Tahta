# PHP (v4) Bağımlılığını Bitirme — Yol Haritası

> Hazırlanma: 9 Ağustos 2026 · Ölçümler bu tarihte canlı veritabanından alındı.
> İlgili dosyalar: `Pardus_Tahta/pardusv6_project_rules.md`,
> `mebre_web/project_rules.md`

---

## 🔴 Önce gerçekler: v4 bu ay kapatılamaz

**Ölçüm (`smart_boadr_logs`, son 14 gün):**

| Gün | Aktif tahta | İşlem |
|---|---|---|
| 08-08 | 5 | 17 |
| 08-07 | 12 | 43 |
| 08-06 | 13 | 81 |
| 08-05 | 13 | 75 |
| **08-04** | **71** | **433** |
| 07-28 | 31 | 126 |
| 07-27 | 30 | 267 |

Okullar kapalıyken, yaz tatilinin ortasında bile her gün onlarca tahta işlem
görüyor. `securtyphp_logs` kayıtları doğrudan `/v4/s_brt.php` diyor — cihazlar
**hâlâ v4'e konuşuyor**.

**Neden bu ay bitmez:**
- Sahadaki tahtalarda **V1.00.93** kurulu, o sürüm v4'e bağlı
- V6 hâlâ deneme aşamasında, sahaya dağıtılmadı
- Windows istemcisi için Faz 3 (Pardus kodundan yeniden yazım) **hiç başlamadı**
- **Eylül'de saha 3.547 tahtaya çıkıyor** — dağıtım için en kötü zaman

Gerçekçi bitiş: Faz 3 + saha geçişi sonrası, **kışa doğru** (Kasım–Aralık veya
yarıyıl tatili).

---

## Bu ay (Ağustos, sessiz pencere) bitirilebilecekler

### [x] 1. `/ynt/` ve `/yonetim/` panellerini kapat ✅ **9 Ağu 2026 — YAPILDI**

Kullanıcı teyidi: tamamen ölü, kimse kullanmıyor.

- `/ynt/` → **444 dosya, 50.6 MB** eski PHP paneli (ynt4). İçinde `login.php`
  ve veritabanı bağlantısı vardı.
- `/yonetim/` → 1 dosya, canlıda 200 dönüyordu.

**Yapılan:** DirectAdmin File Manager'dan yeniden adlandırıldı (**silinmedi**):
`ynt → _ynt_KAPALI_20260809`, `yonetim → _yonetim_KAPALI_20260809`.

**Doğrulama (canlı):** `/ynt/` **404** · `/yonetim/` **404** ·
`/api/v4/s_brt.php` **401** (tahtalar etkilenmedi) · `/exe/*` 200 · `/` 200

**Bağımlılık kontrolü:** Tüm PHP kaynağında `ynt/` klasörüne tek referans
`cron6.php` → `ynt/Compodent/numaralar.txt`. `cron6.php` crontab'ta olmadığı
için (ölü kod) sorun yok.

- [ ] **23 Ağustos 2026'dan sonra:** şikâyet gelmediyse tamamen sil.
- [ ] **Aynı gün:** `ynt.mebre.com.tr` **DNS kaydını da temizle.** Klasör silinse
      bile alt alan adı ayakta kalır ve 404 döner — dışarıya "burada bir panel
      vardı" sinyali verir. Cloudflare → DNS → kaydı sil.

> Neden yeniden adlandırma: 50 MB'ı geri yüklemek yarım saat, adı geri
> değiştirmek beş saniye.

**Yan etki (aynı gün çözüldü):** New Relic'te `backend v4 - prod - PHP` adlı bir
Synthetic monitör `https://ynt.mebre.com.tr/lo…` adresini 60 saniyede bir
yokluyormuş. Klasör kapanınca 404 dönmeye başladı, monitör %0 başarıya düştü ve
alarm gönderdi. **Monitör silindi** (9 Ağu 2026). `backend v5 - prod` monitörüne
dokunulmadı — o çalışmaya devam ediyor, %100 başarıda.

> ⚠️ Ders: bir uç kapatılırken onu **dışarıdan izleyen** sistemler de gözden
> geçirilmeli. Alarm sahada bir arıza olduğu için değil, izleyici güncellenmediği
> için geldi.

---

### [~] 2. Cron'ları taşı — **kod hazır, PASİF bekliyor**

**crontab (DirectAdmin, kullanıcı `mebrecomtr`) — 10 kayıt:**

| Dakika | Saat | Script | Durum |
|---|---|---|---|
| 7, 15, 25, 30, 40, 45, 50, 55 | 0 | **`workAll.php` — 8 KEZ** | ✅ ynt5'e yazıldı (pasif) |
| 3 | 0 | `tableOnarim.php` | ⚠️ **artık gereksiz** — madde 3 yapıldı, MyISAM kalmadı |
| 10 | 3 | `cronBackupCtrl.php` | ❌ **ÖLÜ** — sadece silinecek |

`cron6.php` ve `cronJop.php` crontab'ta **yok** → ölü, taşınmayacak.

**`cronBackupCtrl.php` neden ölü:** FTP hedefi `78.135.107.187`, yani kapatılan
eski sunucu. Yıllardır başarısız oluyor olmalı. Taşınmayacak, crontab'tan
silinecek. *(Ayrı soru: yedekleme şimdi nerede yapılıyor, eskiler temizleniyor mu?)*

**Yapılan (9 Ağu):** `workAll.php` → **ynt5**'e taşındı
(`ynt5/src/jobs/geceBakim.ts`, commit `0fd2705`). v5 değil ynt5 seçildi çünkü
ynt5 tek kopya çalışıyor (fork mode) — v5 cluster'da iki kopya olduğu için
dağıtık kilit gerektirirdi.

Panelde görünür: **ynt5 → sol menü → Zamanlanmış İşler** (commit `e79d49b`).

> 🔴 **`workAll.php`'nin 8 kez çalışması bilinçli bir tasarımdır.** Script
> `shutdown=1` yazıp **15 saniye** bekliyor, sonra `shutdown=0`'a çekiyor. Tahta
> 5 saniyede bir yokladığı için o dar pencereyi yakalamalı; o an kapalıysa
> kaçırıyor. Sekiz tekrar = sekiz şans.
> **Tek sefere indirilirse gece kapalı tahtalar kilit komutunu hiç almaz ve
> sabah kilitsiz açılır.** Kod bu davranışı birebir koruyor.

**Aktifleştirme sırası (henüz yapılmadı):**
- [ ] ynt5'i deploy et, `.env` → `GECE_BAKIM_MOD=kuru` → bir gece logları izle
      (hiçbir şey yazmaz, tamamen güvenli)
- [ ] Loglar doğruysa: DirectAdmin'den **8 adet `workAll.php` kaydını sil**
- [ ] **Aynı gün** `GECE_BAKIM_MOD=aktif` yap
      *(arada boşluk kalırsa ya iki cron birden çalışır ya da hiçbiri çalışmaz)*
- [ ] Ertesi sabah doğrula: tahtalar kilitli açıldı mı, `smart_board_post` güncel mi
- [ ] `cronBackupCtrl.php` kaydını sil (ölü)

---

### [x] 3. MyISAM tablolarını InnoDB'ye çevir ✅ **9 Ağu 2026 — YAPILDI**

**Sonuç:** Dev ve prod'da **9 aktif tablo** InnoDB'ye çevrildi. FULLTEXT indeksi
olmadığı için sorunsuz geçti. Satır sayıları dönüşüm öncesi/sonrası birebir
aynı — **842 satır**, veri kaybı yok:

| Tablo | Satır (önce = sonra) |
|---|---|
| `okul_lisans_gecmisi` | 504 |
| `hesap_tahsilatlar` | 207 |
| `hesap_bolge_iller` | 79 |
| `hesap_islemler` | 45 |
| `hesap_urunler` / `hesap_bolgeler` / `hesap_ayarlar` | 4 / 2 / 1 |
| `sms_kara_liste` / `All_Message_s` | 0 / 0 |

Prod'da geriye yalnızca iki tarihli yedek tablosu MyISAM kaldı (bilerek).

**Kazanç:** `hesap_tahsilatlar` gibi para tutan tablolarda artık tablo kilidi
yerine satır kilidi var, transaction destekleniyor ve çökmede bozulma riski
ortadan kalktı.

- [ ] **Kalan karar:** iki yedek tablosu (`mobil_token_s_yedek_20260731` 14.3 MB,
      `mbl_Login_val_izin_yedek_20260802`) hâlâ gerekli mi? Silinirse veritabanında
      hiç MyISAM kalmaz → `tableOnarim.php` tamamen gereksizleşir, taşınmaz.

<details>
<summary>Yapılan işin ayrıntısı</summary>

### (arşiv) MyISAM → InnoDB dönüşümü

**Ölçüm:** 118 InnoDB, **11 MyISAM**. MyISAM olanların çoğu **ynt5'in kendi yeni
tabloları** — muhtemelen sunucunun varsayılan motoru MyISAM olduğu için farkında
olmadan öyle oluşmuşlar.

| Tablo | Satır | Not |
|---|---|---|
| `mobil_token_s_yedek_20260731` | 77.402 (14.3 MB) | 📦 tarihli yedek — silinebilir |
| `mbl_Login_val_izin_yedek_20260802` | 4.329 | 📦 tarihli yedek — silinebilir |
| `okul_lisans_gecmisi` | 504 | ✅ aktif |
| `hesap_tahsilatlar` | 207 | ✅ aktif — **para tutuyor** |
| `hesap_bolge_iller` | 79 | ✅ aktif |
| `hesap_islemler` | 45 | ✅ aktif |
| `hesap_urunler` / `hesap_bolgeler` / `hesap_ayarlar` | 4 / 2 / 1 | ✅ aktif |
| `All_Message_s` | 0 | ✅ aktif — iletişim formu |
| `sms_kara_liste` | 0 | ✅ aktif |

**Neden önemli:** MyISAM'da transaction yok ve yazma sırasında **tüm tablo
kilitleniyor**. `hesap_tahsilatlar` gibi para tutan bir tablo için uygun değil.
Ayrıca çökmede bozulabildikleri için `tableOnarim.php` cron'u var — bu dönüşüm
o cron'u da gereksiz kılar.

**Neden kısa:** Aktif tabloların hepsi minik (en büyüğü 504 satır, dokuzunun
toplamı 1 MB'ın altında). `ALTER TABLE` saniyeler sürer.

- [ ] FULLTEXT kontrolü (varsa dönüşüm takılabilir):
      `SELECT DISTINCT TABLE_NAME, INDEX_TYPE FROM information_schema.STATISTICS
       WHERE TABLE_SCHEMA='mebrecomtr_mbrdata' AND INDEX_TYPE='FULLTEXT';`
- [ ] İki tarihli yedek tablosunu sil (~14 MB) — içerikleri hâlâ gerekli mi teyit et
- [ ] Kalan 9 tabloyu dönüştür: `ALTER TABLE <ad> ENGINE=InnoDB;`
- [ ] **Önce dev** (`mebrecomtr_mbrdata_dev`), sonra prod — kural gereği
- [ ] Doğrula: `ENGINE` sütunu, ynt5 paneli çalışıyor mu, iletişim formu yazıyor mu
- [ ] Sonuç: `tableOnarim.php` gereksizleşir → crontab'tan silinir, taşınmaz

</details>

---

### [ ] 4. Kalan statik sayfaları taşı

`iletisim.html`, `mebrecep.html`, `privacy-policy.html`, `komut1.html`,
`sozlesme.pdf`, `hata.html`, `block.html`

- [ ] `mebre_web/public/` altına kopyala
- [ ] Cloudflare Worker route'una ekle (**dar desen**, `/*` değil)
- [ ] Eski sunucudan kaldır

---

## Faz 3 hazırlığı (Ağustos–Eylül, kod yazma)

### [ ] 5. Windows istemcisi — karar uygulanmalı

**Karar (5 Ağu 2026): C# istemcisini taşımak yerine Pardus/Python kodu Windows'ta
çalıştırılacak.** Tek kod tabanı, iki istemci arasında davranış farkı kalmaz.

- [ ] `faz3_csharp_gecis_playbook.md`'yi yeniden yaz — artık "C# metod eşlemesi"
      değil, **"Windows'a özgü davranış envanteri"**: kiosk kilidi,
      servis/oturum yönetimi, DPAPI karşılığı, paketleme/imzalama
- [ ] PyQt'nin Windows'ta kiosk davranışını doğrula
- [ ] Kurulum paketi + kod imzalama akışı (mevcut sertifika: `CN=Hasan Hatunoğlu`)

### [ ] 6. Zaman damgası toleransı — v5'te karşılığı var mı?

**Somut vaka (4 Ağu 2026):** Kurum `99975059`, tahta `15` (`8A`),
IP `46.221.12.118` — tahtanın saati **34 dakika ileri**, istek saniyede bir
tekrarlanıyor, tek günde **1.049 hata kaydı**.

v4 bunu şöyle çözüyor: `workAll.php`, iki günden uzun süre hata üreten IP'leri
`Access_IpAdres_s`'e ekliyor ve zaman damgası kontrolü o IP için atlanıyor.

- [ ] v5'in cihaz auth'unda bu mekanizmanın karşılığı var mı, kontrol et
- [ ] Yoksa: saati şaşmış tahtalar v5'e **hiç bağlanamaz** — çözüm tasarlanmalı
      (tolerans penceresi, sunucu saatiyle senkron, veya IP muafiyeti)

---

## Saha geçişi (Kasım–Aralık veya yarıyıl tatili)

### [ ] 7. Dalga dalga dağıtım

- [ ] **Eylül–Ekim'de BAŞLATMA** — saha zirvede (3.547 tahta)
- [ ] Okul okul, uzaktan güncelleme
- [x] Her dalgadan sonra ölç: v4'e hâlâ vuran tahta kaldı mı
      ✅ **Artık otomatik.** ynt5 → **Zamanlanmış İşler → v4 Nabzı** her sabah
      06:15'te ölçüyor (`src/jobs/v4Nabiz.ts`, commit `7714776`). 14 günlük tablo:
      v4 olay/tahta, v5 olay/tahta, v4 güvenlik kaydı, "v4 son görülme".
      Ayrım `smart_boadr_logs.school_id` ile: v4 gerçek okul id yazıyor, v5 device
      ucu sabit `0`. Tamamen okuma, hiçbir tabloya yazmıyor.
      ⚠️ İki sınır panelde de yazılı: v5'in **panel** tarafı da gerçek id ile
      yazdığı için "v4" sütununa elle yapılan işlemler karışır (sayı tek haneye
      inince sıfır bekleme); `securtyphp_logs` yalnızca hata kaydı tuttuğu için
      sıfır olması "v4 kullanılmıyor" demek değildir.
- [ ] Geri dönüş yolu her zaman açık kalsın (v4 ayakta)

### [ ] 8. v4'ü emekliye ayır

- [ ] v4 trafiği sıfırlandığında `s_brt.php` kapatılır
- [ ] ⛔ **Makine KAPATILMAZ** — veritabanı orada, ayrıca `api`, `da` alt alan
      adlarını da barındırıyor
- [ ] Kriz kodu ve çevrimdışı şifre her aşamada çalışır kalmalı

---

## Yan işler (acil değil ama unutulmasın)

- [ ] **`Updater1.exe` `www` adresine bağımlı:** binary'de
      `https://www.mebre.com.tr/exe/FatihProjesi1.exe` gömülü. 9 Ağu'da
      www → apex 301 yönlendirmesi kuruldu; .NET standart sınıfları 301'i takip
      eder ama `AllowAutoRedirect=false` ihtimali var. **Sahadan "güncelleme
      hatası" gelirse ilk bakılacak yer.** Kalıcı çözüm: yeni sürümde gömülü
      adresi apex'e çekmek.
- [ ] **`FatihProjesi1.exe` 7 Eylül 2022 tarihli** — updater kanalı fiilen terk
      edilmiş. Silinmedi (riskli olabilir), duruyor.
- [ ] **`Ana_index` klasörü commitsiz ve remote'suz** — eski PHP kaynağının,
      cron script'lerinin ve silinen dosyaların tek kopyası burada.
      Şifreli arşiv olarak buluta/USB'ye alınmalı.
- [ ] **`v4/s_brt.php` case 5566 SQL enjeksiyonu** açık (kolon adı filtresiz).
      v5'te whitelist ile kapatıldı; v4'te Faz 8'e kadar duruyor.
- [ ] **`v4/s_brt.php:602` (case 5572) bozuk SQL** — tırnak kapanmamış, UPDATE
      sessizce hiç çalışmıyor. v5'te doğru yapılıyor.
- [ ] **ynt5 cluster'a alınırsa:** `geceBakim` işi iki kez çalışır. O durumda
      v5'teki `jobs/dersNotuOzet.js` gibi Redis kilidi eklenmeli.
