---
description: Pardus Akıllı Tahta v6 — Proje Bağlamı, Mimari Tespitler ve Geliştirme Kuralları
son_guncelleme: 2026-07-14
---

# Pardus Akıllı Tahta v6 — Proje Kuralları ve Bağlam Dosyası

> Bu dosya **v6 geliştirmesine özeldir**. Depodaki `.agents/workflows/project_rules.md` (şifreleme,
> UI/odak, paketleme, şifre invariant'ı) **aynen yürürlüktedir ve bu dosya onu ezmez**. Burada yazanlar
> onun üstüne eklenen v6 bağlamıdır.
>
> İsim çakışması notu: `C:\Github\v5` deposunun kökünde de bir `project_rules.md` vardır. O **backend**
> projesine aittir, bu dosyayla karıştırılmamalıdır.

---

## 1. Neredeyiz? (Sürüm ve Dal Durumu)

| Ne | Değer |
|---|---|
| Sahaya dağıtılan sürüm | **V1.00.93** (`Fatih_Client_Kurulum_V1_00_93.zip`) — şu an okullarda kuruluyor |
| Dondurulmuş referans | `v1.00.93` git tag'i → commit `82c095e` |
| v1 çalışma kopyası | `C:\Github\Pardus_Tahta` — branch `main` (**hotfix'ler buradan**) |
| v6 çalışma kopyası | `C:\Github\Pardus_Tahta_v6` — branch `v6` (git worktree) |

**Kural:** v6 geliştirmesi yalnızca `v6` branch'inde ve `Pardus_Tahta_v6` klasöründe yapılır.
`main` yalnızca sahadaki V1.00.93'e acil düzeltme gerekirse dokunulur. İki klasör tek git geçmişini
paylaşır; kopyala-yapıştır ile ikinci bir kaynak ağacı **oluşturulmaz**.

Not: v6 worktree'sinde `.venv` yoktur (git'te takipli değil). Orada Python çalıştırılacaksa ayrı bir
sanal ortam kurulmalıdır.

---

## 2. Ekosistem Haritası (Hangi Depo Ne İşe Yarar)

| Depo / Klasör | İçerik | v6'daki rolü |
|---|---|---|
| `C:\Github\Pardus_Tahta` | Pardus (Linux) tahta istemcisi — Python/PyQt, Cython ile derlenir | Geliştirdiğimiz asıl ürün |
| `C:\Github\Fatih_Client_CSharp` | **Windows** tahta istemcisi (C#) | ⚠️ Aynı backend'i kullanır — kırılmamalı |
| `C:\Github\v4` | Eski backend — **PHP** (`s_brt.php`, `security.php`) | Sahadaki TÜM tahtalar (Pardus + Windows) buraya bağlı |
| `C:\Github\v5` | Yeni backend — **Node.js/Express** (mobil + masaüstü + tahta) | v6'nın hedef backend'i. GitHub: `mehmet-han/v5` |

### Sunucu Adresleri (ÖNEMLİ: PHP ve Node.js AYRI SUNUCULAR)

| Backend | Host | Örnek |
|---|---|---|
| v4 (PHP) | `api.mebre.com.tr` | `https://api.mebre.com.tr/v4/s_brt.php` |
| v5 (Node.js) | **`apiv5.mebre.com.tr`** | `https://apiv5.mebre.com.tr/client/...` |

İki backend **farklı sunucularda** çalışır ama **aynı MySQL veritabanını** paylaşır (bkz. §4.3).
Paralel geçişi mümkün kılan şey budur: v5'e yazılan komut, v4'ten okuyan eski tahtaya da ulaşır.

**En kritik kısıt:** Akıllı tahtalarda sadece Pardus değil, **Windows da kurulu**. Windows istemcisi
(C#) de `v4/s_brt.php`'yi çağırır. Üstelik **C# projesi asıl/ana projedir** — Pardus istemcisi ondan
türetilmiştir. Bu yüzden:

> ⛔ **v4 BACKEND'E DOKUNULMAZ.** Ne endpoint silinir, ne davranışı değiştirilir, ne kapatılır.
> Sahadaki hiçbir tahta (Pardus veya Windows) bozulmayacak. v5'e geçiş **paralel** yürür;
> önce Pardus/Python v6 taşınır, sonra C# aynı sözleşmeye göre taşınır.

---

## 3. Tahta ↔ Sunucu Kimlik Doğrulama Sözleşmesi (v4'te nasıl çalışıyor)

`client.py` → `_make_request()` tek geçiş noktasıdır. Tüm sunucu çağrıları buradan geçer.

1. **HTTP Basic Auth** — `wb_user` / `wb_pass` (config.ini'de XOR/ENC ile gizli, RAM'de anlık çözülür).
2. **`User-Key` header** — `generate_user_key()`; PHP tarafında `CheckAccesptKey()` doğrular.
3. **`UserCore` header** — `cFnc_original(fnc)` ile şifrelenmiş `fnc?zaman_damgası` çifti.
   - `security.php` bunu `_cFnc()` ile çözer, **gerçek `fnc`'yi buradan alır** ve `$_POST['fnc']`'yi ezer.
   - Zaman damgası eskiyse (~25 dk, tolerans 1sa+10dk) istek reddedilir → **replay koruması**.
4. **Gövdedeki `fnc: "3480"` bir YEM'dir.** `s_brt.php`'de 3480 diye bir `case` yoktur; sunucu bu
   değeri kullanmaz, header'dan gelenle değiştirir. Kodu okurken buna aldanma.
5. `verify=True` zorunlu (MITM koruması), istek biter bitmez `_url/_usr/_pwd` RAM'den silinir.

**Cihaz kimliği yoktur.** Tahta yalnızca `corporate_code` + `t_n` (board_id) ile tanınır. JWT yoktur.
v5'in mevcut `middlewares.auth` JWT'si tahtada **kullanılamaz** — bu, v6'nın çözmesi gereken ana
mimari problemdir.

---

## 4. `s_brt.php` Fonksiyon Envanteri ve v5 Karşılıkları

### 4.1 Panel tarafı (öğretmen/müdür uygulaması) — **v5'e TAŞINMIŞ ✅**

v5 modülü: `src/apps/akilliTahtaYonetim/` — hepsi `middlewares.auth` (admin/öğretmen JWT) korumalı.

| PHP `fnc` | v5 endpoint | İş |
|---|---|---|
| 1155 | `POST /client/akilli_tahta_yonetim/tahta_kilitle_ac` | Tek tahtayı kilitle/aç, mesaj gönder |
| 1175 | `POST /client/akilli_tahta_yonetim/tahta_tumunu_kapat` | Okulun tüm tahtalarını kapat |
| 1156 | `POST /client/akilli_tahta_yonetim/tahta_detay` | Tahta log kayıtları (son 100) |
| 5572 | `POST /client/akilli_tahta_yonetim/tahta_get_password` | Günlük geçici tahta şifresi üret + kaydı sıfırla |

### 4.2 Cihaz tarafı (`client.py`'nin çağırdıkları) — **v5'e TAŞINMAMIŞ ❌ (v6'nın işi)**

| PHP `fnc` | `client.py` fonksiyonu | İş | Sıklık |
|---|---|---|---|
| **5567** | `ctrl_post()` | Komut yoklama: `open_close, message, shutdown, system_Remove, log_istek` (virgüllü düz metin döner) | **5 sn'de bir** |
| **5566** | `set_value(column, value)` | Komut ACK'i — belirtilen kolonu günceller | Komut sonrası |
| **5563** | `get_values()` | Tahta çalışma saatleri (`mobiledata.akilli_tahtasss`, JSON) | Periyodik |
| **5571** | `save_log(log_name, vog)` | Hata/olay logu (`sbort_log`) | Olay bazlı |
| **5574** | `log_request()` | `log_istek` bayrağını sıfırla | Log sonrası |
| **5570** | `check_version()` | Sunucudaki güncel istemci sürümü (`vercion_s`, `id_=2`) | Periyodik |
| ~~5573~~ | `get_inspc()` | **ÖLÜ KOD** — PHP fonksiyonunun ilk satırı `echo "ok"; exit();`. **v5'e taşınmayacak.** | — |

### 4.3 Ortak Veritabanı (v4 ve v5 AYNI DB'ye yazar — paralel çalışmanın temeli)

| Tablo | Kullanım |
|---|---|
| `smart_board_post` | Tahta durum/komut kaydı: `t_id, kurum_kodu, open_close, message, shutdown, system_Remove, log_istek, p_tarihi` |
| `smart_boadr_logs` | Aç/kapat işlem logu: `school_id, kurum_koduss, log_adi, t_no, log_tarih` |
| `sbort_log` | Tahta hata logu: `_kurum_kodu, tahta_no, _n_log, _v_name, ip_no, _hataSayis_i` |
| `mobiledata` | `akilli_tahtasss` kolonu → çalışma saatleri JSON'u |
| `vercion_s` | `id_=2` satırı → güncel istemci sürümü |
| `_okullar` | Lisans/durum kontrolü: `kurumkodu`, `_mail_adrs`, `_status` |

---

## 5. v6 Hedef Mimarisi (Onaylanan Yön)

1. **v4 dokunulmaz.** Sahadaki Pardus + Windows tahtalar oradan beslenmeye devam eder.
2. **v5'e yeni bir cihaz modülü yazılır** (`akilliTahtaYonetim`'in yanına, ör. `src/apps/akilliTahtaCihaz`).
   Kapsam: 5567, 5566, 5563, 5571, 5574, 5570. (5573 hariç — ölü kod.)
   Aynı tablolara yazar → panel komutları tahtaya ulaşmaya devam eder.
3. **`client.py`'de değişiklik tek noktada toplanır: `_make_request()`.** Üstteki `ctrl_post`,
   `set_value`, `save_log` vb. fonksiyonların imzası korunur.
4. **`fnc`-in-`UserCore` numarası v5'te KULLANILMAZ.** O numara her şeyin tek bir `s_brt.php`'ye
   gitmesinden doğmuştu; v5'te her endpoint'in kendi yolu var. Korunacak olan, `UserCore`'un gerçek
   işlevi olan **zaman damgası / replay korumasıdır** (ayrı bir header olarak).
5. **Cihaz auth'u kademeli sertleştirilir:** Önce mevcut şema (Basic + User-Key + zaman damgası) v5'e
   taşınır ve çalıştığı doğrulanır. Her tahtaya özel **cihaz token'ı** v6 oturduktan SONRA, ayrı bir
   adımda eklenir. Sahada binlerce tahta varken provisioning akışını aynı anda değiştirmek riski katlar.

### 5.1 `client.py`'de host'a bağımlı DEĞİŞECEK yerler

v5 ayrı bir sunucuda (`apiv5.mebre.com.tr`) olduğu için sadece endpoint yolu değil **host da** değişir.
Bu, `client.py` içinde **üç ayrı yeri** etkiler — biri unutulursa istemci sessizce v4'e konuşmaya
devam eder veya ağ kontrolünde takılır:

1. `_make_request()` → XOR ile gömülü `_url` (`_dx("1815...")`) — asıl API adresi.
2. `check_network()` → XOR ile gömülü ayrı bir `_url` — ağ var mı testi.
3. `check_network()` → **düz metin fallback**: `socket.create_connection(("api.mebre.com.tr", 443))`.
   Burada host **sabit yazılmış**; XOR'lu adres değişse bile bu satır v4'e bakmaya devam eder.

**Kural:** Yeni host için XOR hex string'leri yeniden üretilecek, plaintext host bırakılmayacak
(bkz. `.agents/workflows/project_rules.md` §1). Yeni sunucunun geçerli TLS sertifikası olmalıdır —
`verify=True` zorunlu olduğu için sertifika hatası tüm istemciyi çalışamaz hale getirir.

---

## 4A. SAHA ÖLÇÜMLERİ (14 Temmuz 2026 — GERÇEK VERİ)

> ⚠️ Bu bölüm **tahmin değil, ölçümdür**. Faz 1'in kapasite tasarımı buna dayanır.
> Ölçüm yaz tatilinde yapıldığı için ham trafik yanıltıcıdır; **okul dönemi zirvesine göre** planlanır.

### 4A.1 Altyapı

| | v4 (PHP) | v5 (Node.js) |
|---|---|---|
| Host | `da.mebre.com.tr` / `185.40.84.183` | `apiv5.mebre.com.tr` / `188.132.200.30` |
| SSH | port 22 (⚠️ root+parola açık, son girişten beri **2852 başarısız deneme**) | port 22480 |
| OS | CentOS 8 (**EOL 2021**) | *(ölçülecek)* |
| Donanım | 12 vCPU, 15 GB RAM, 122 GB disk (%37) | *(ölçülecek)* |
| Yük | load avg **0.08** (yazın, neredeyse boşta) | *(ölçülecek)* |
| Web | Apache 2.4.48 + OpenLiteSpeed, DirectAdmin | *(ölçülecek)* |
| PHP | 7.4.33 (**EOL 2022**) | — |

**🔴 KRİTİK: MySQL (MariaDB 10.4.20) v4 SUNUCUSUNDA yerel çalışıyor** (`mysqld`, 5.8 GB RAM = toplamın %36'sı).
Veritabanı adı: **`mebrecomtr_mbrdata`**. v5 Node sunucusu bu DB'ye **ağ üzerinden uzaktan** bağlanır.

> ⛔ **Faz 5'te v4 endpoint'i kapatılsa bile 185.40.84.183 makinesi KAPATILAMAZ** — veritabanı orada.
> Ayrıca bu makine `api`, `ynt`, `yonetim` alt alan adlarını da barındırıyor.

**Log durumu:** Apache logları günlük döner, **arşiv tutulmuyor, AWStats yok**. Yani geçmiş trafik verisi
kalıcı olarak kayıp. Tarihsel ölçüm ancak DB üzerinden yapılabilir (aşağıdaki gibi).

### 4A.2 Tahta Envanteri (`smart_board_post`)

- **4.292 kayıtlı tahta**, **189 okul**.

### 4A.3 Aya Göre Aktif Tahta (`smart_boadr_logs`)

| Ay | İşlem | Aktif Tahta | Aktif Okul |
|---|---|---|---|
| 2025-09 | 186.958 | **3.547** ← ZİRVE | 140 |
| 2025-10 | 226.449 | 3.341 | 137 |
| 2025-11 | 154.825 | 3.049 | 127 |
| 2025-12 | 243.535 | 3.279 | 127 |
| 2026-01 | 81.501 | 2.981 | 125 |
| 2026-02 | 241.121 | 3.090 | 136 |
| 2026-03 | 164.965 | 2.879 | 131 |
| 2026-04 | 102.722 | 2.458 | 120 |
| 2026-05 | 72.392 | 1.889 | 102 |
| 2026-06 | 43.735 | 1.698 | 96 |
| 2026-07 | 1.301 | **121** ← yaz tatili | 22 |

Not: Bu tablo yalnızca **kilit/aç işlemi loglanmış** tahtaları sayar (yoklama trafiğini saymaz).
Yine de aktiflik için en güvenilir tarihsel göstergedir.

### 4A.3b Veritabanı Şeması — Tablolar, İndeksler, Boyutlar (`mebrecomtr_mbrdata`)

| Tablo | Satır | Veri | İndeks | Ne işe yarar |
|---|---|---|---|---|
| `akilli_tahtalar` | **3.149** (138 okul) | <1 MB | `PRIMARY(id)`, `(kurum_kodu, tahta_no)` | **TAHTA KÜTÜĞÜ** — asıl kayıt |
| `smart_board_post` | 4.176 | <1 MB | `PRIMARY(id)`, **`(kurum_kodu, t_id)`** ✅, `(kurum_kodu)` | Durum/komut tablosu (yoklama buradan okur) |
| `smart_boadr_logs` | **2.957.965** | **253 MB** | `PRIMARY(id)`, `(kurum_koduss, school_id, t_no, id)`, `(kurum_koduss, school_id, t_no)` — **`log_tarih` İNDEKSİ YOK** ❌ | Kilit/aç işlem logu |
| `sbort_log` | 18.507 | 8 MB | `PRIMARY(id)`, `(_kurum_kodu, tahta_no)` | Tahta hata logu |

**`akilli_tahtalar` kolonları:** `id, kurum_kodu(varchar10), tahta_no(int), tahta_tanimi(varchar50 — sınıf adı:
"5/AA"), sinif_kodu, aktif(tinyint), created_from/at, updated_from/at` *(zaman damgaları **unix int**)*.

> ⚠️ **KÜTÜK `akilli_tahtalar`'dır, `smart_board_post` DEĞİL.** Kütükte 3.149 tahta / 138 okul var;
> `smart_board_post`'ta 4.176 satır / 189 okul — aradaki fark **ölü/artık kayıtlardır**. Rapor ve tahta
> sayımı **daima `akilli_tahtalar`** üzerinden yapılır, yoksa gerçekte olmayan 1.000+ tahta sayılır.

**✅ Yoklama sorgusu indeksli.** `SELECT ... FROM smart_board_post WHERE kurum_kodu=? AND t_id=?`
→ `idx_board_post_kurum_tid` kullanır, tablo <1 MB (tamamen buffer pool'da). Saniyede 700 yoklama
DB tarafında **ucuz**. Faz 1'de korkulan tam-tablo-taraması yok.

### 4A.3c DB Bakımı — 14 Temmuz 2026'da YAPILDI ✅

Yaz tatili penceresinde (okullar kapalı, 121 aktif tahta) prod DB'de şu bakım yapıldı:

| İşlem | Sonuç |
|---|---|
| `smart_boadr_logs`'a `idx_boardlogs_tarih (log_tarih)` indeksi eklendi | 74 sn sürdü |
| `smart_boadr_logs` **MyISAM → InnoDB**'ye çevrildi | Artık satır kilidi + çökme dayanıklılığı var |
| Gereksiz `kurum_koduss` indeksi düşürüldü | `idx_boardlogs_lookup` onu zaten kapsıyordu |
| `tahta_istatistik_gunluk` özet tablosu oluşturuldu + geçmiş dolduruldu | — |

**Kazanç (ölçüldü):** Aylık rapor sorgusu **7,7 sn → 0,30 sn** (26 kat).
**Artık 4 tablo da InnoDB.** (Öncesinde `smart_boadr_logs` MyISAM'di → tablo bazlı kilit, transaction yok.)

> 💡 **Ders:** Bu tür DDL bakımları **yaz tatilinde** yapılır. Eylül'de `smart_boadr_logs`'u InnoDB'ye
> çevirmek dakikalarca tablo kilidi demekti; Temmuz'da etkisi sıfır oldu.

> ℹ️ InnoDB'de `information_schema.TABLE_ROWS` artık **tahminidir** (MyISAM'de kesindi).
> Kesin satır sayısı için `COUNT(*)` kullanılmalı — raporlama sorgularında buna dikkat.

**Kod tabanında `FORCE INDEX`/`USE INDEX` ipucu YOK** (v4, v5, ynt5 tarandı) → indeks değişiklikleri
uygulama kodunu bozmaz, optimizer serbest seçer.

### 4A.4 🔴 YÜK HESABI — Faz 1'in EN ÖNEMLİ TASARIM GİRDİSİ

**Model, sahada doğrulandı:**
- Temmuz: 121 aktif tahta × 12 istek/dk (5 sn yoklama) = **24 req/s** (hesap)
- Apache logunda ölçülen: **25 req/s** (1.803.270 istek / 20 saat) ✅ **Model tutuyor.**

**Bu modeli okul dönemi zirvesine uygulayınca:**

| Senaryo | Tahta | Hesaplanan Yük |
|---|---|---|
| Yaz tatili (bugün) | 121 | 25 req/s |
| **Okul dönemi zirvesi (Eylül 2025)** | **3.547** | **≈ 710 req/s** |
| Tüm kayıtlı tahtalar açılırsa | 4.292 | ≈ 860 req/s |
| **Tasarım hedefi (büyüme payıyla)** | — | **~1.000 req/s** |

> ⚠️ **TUZAK:** Ölçümü yazın yaptık. Bugünkü 25 req/s'ye bakıp "Node rahat kaldırır" demek
> **28 kat hata** yapmaktır. Eylül'de okullar açıldığında yük ~710 req/s'ye fırlar.

**Sonuçları (Faz 1 bunlara göre tasarlanacak):**
1. Mevcut PHP mimarisi **her yoklamada DB'ye gidiyor**. Aynısını Node'a kopyalarsak MariaDB'yi
   saniyede ~700 sorguyla döveriz. **Yoklama yanıtı için cache katmanı (Redis/bellek) şart.**
2. **Rate-limit IP'ye bağlanamaz.** Okullar NAT arkasında — 46 benzersiz IP'ye karşılık ~130 tahta
   görüldü, yani bir okulun tüm tahtaları tek IP'den çıkıyor. Limit **`corporate_code` + `board_id`**
   çiftine bağlanmalı, yoksa bir okulun tahtaları birbirini boğar.
3. **Yoklama israfı:** Günde ~2,2 milyon isteğin neredeyse tamamı "değişiklik var mı?" → "yok".
   v6'da iyileştirme seçenekleri: yanıt değişmediyse hafif/`304` benzeri dönüş, gece saatlerinde
   aralığı açma, uzun-yoklama (long-polling) veya push. **En azından aynı israfı olduğu gibi
   kopyalamayalım.**
4. Tahtalar **7/24 yokluyor** (saatlik dağılım gece de düz: 15:00→106k, 19:00→94k istek).

---

## 5A. YOL HARİTASI (Fazlar)

> Sıra bilinçlidir: Pardus/Python istemcisi "pilot"tur. Riski küçük kitlede görürüz, sözleşme
> oturduktan sonra asıl proje olan C#'ı aynı sözleşmeye taşırız.

### Faz 1 — v5 Cihaz Backend'i (Node.js)
- `src/apps/akilliTahtaCihaz` modülü: 5567, 5566, 5563, 5571, 5574, 5570 karşılıkları.
- Cihaz auth middleware'i (Basic + `User-Key` + zaman damgası/replay koruması).
- `5566` için **kolon whitelist'i** (SQL enjeksiyonu kapatılır).
- Aynı DB tablolarına yazar → v4'teki tahtalarla tam uyum korunur.
- **Kapasite hedefi: ~1.000 req/s** (bkz. §4A.4). Bu, tasarımı doğrudan belirler:
  - Yoklama (5567) yanıtı **cache'den** servis edilir; her istekte DB'ye gidilmez.
  - Rate-limit **`corporate_code` + `board_id`** bazlı (IP bazlı DEĞİL — okullar NAT arkasında).
  - Yoklama israfını azaltacak mekanizma (değişmediyse hafif dönüş / uzun-yoklama) değerlendirilir.

### Faz 2 — Pardus/Python v6 İstemcisi
- `_make_request()` v5'e yönlendirilir; üst seviye fonksiyon imzaları (`ctrl_post`, `set_value`, …) korunur.
- Host'a bağımlı 3 nokta (§5.1) güncellenir, XOR string'leri yeniden üretilir.
- Sürüm `V6.xx.xx` şemasına geçer; paketleme yine `paket_olustur.py` ile.
- Pilot okullarda saha testi. v4 hâlâ ayakta → sorun çıkarsa geri dönüş kolay.

### Faz 3 — C# (Windows) İstemcisinin v6'ya Taşınması  ← **asıl proje**
- Depo: `C:\Github\Fatih_Client_CSharp`.
- Faz 1'de tanımlanan **aynı** cihaz sözleşmesi kullanılır (yeni endpoint tasarlanmaz).
- Windows tahtalar da v4'ten kurtarılır.

### Faz 4 — Güvenlik Sertleştirmesi
- Her tahtaya özel **cihaz token'ı** + provisioning akışı (paylaşılan tek `wb_pass` kalkar).
- **Çevrimdışı şifre formülünün yenilenmesi** (bkz. §5C — öğrenciler çözmüş). Mobil + Pardus + C#
  koordineli. Saat-tabanlı OTP + tahta-özel sır.
- Hem Pardus hem Windows istemcisinde uygulanır.

### Faz 5 — v4 `s_brt.php`'nin Emekliye Ayrılması
- Sahadaki tüm tahtalar (Pardus + Windows) v5'e geçtikten SONRA.
- Önce trafik izlenir (v4'e hâlâ vuran tahta var mı?), sıfırlanınca endpoint kapatılır.

---

## 5B. VERİ KALİTESİ TESPİTLERİ (14 Temmuz 2026 — smart_boadr_logs analizi)

Raporun "aktif tahta" sayısını doğru göstermesi için keşfedilen kritik gerçekler:

### 5B.1 v4 `t_no` loglama hatası → tahta sayısı ŞİŞİK
- Son 1 yılın loglarının **%16,4'ünde** (~248 bin) `t_no`, `akilli_tahtalar` kütüğüyle eşleşmiyor.
- **Kök neden:** `s_brt.php` fnc 1175 ("tümünü kapat") logu yazarken tahta no yerine
  **`smart_board_post.id` (satır id'si)** geçiyor (`BordAcmaKapatmaBilgisiYaz(..., $row['id'], ...)`).
  Tekil kilitleme (fnc 1155) ise doğru `t_n`'i yazıyor. → Aynı tahta iki farklı `t_no` ile görünüyor.
- **v5 bunu DOĞRU yapıyor** (`insertBoardLog(..., boardRecord.t_id, ...)`) → v6 geçişinde kendiliğinden düzelir.
- Karşılıksız logların dağılımı (2025-09'dan beri, 248.501 kayıt):
  | Kategori | Log | Okul | Yorum |
  |---|---|---|---|
  | post.id çevrimiyle çözülebilen | 51.080 | — | fnc 1175 artığı, `smart_board_post.id → t_id` ile kurtarılır |
  | Okul kütükte **hiç yok** | 177.212 | 44 | Bırakan/düşen okullar + default-kod tahtalar (bkz. 5B.2) |
  | Okul var, bu tahta no yok | 17.868 | 11 | Çözülemeyen fnc 1175 artığı |
  | Büyük no (>100) | 2.099 | 7 | Çözülemeyen artık |
  | Geçersiz (`t_no <= 0`, ör. -1) | 242 | 31 | Bozuk kayıt |

### 5B.2 Default / okula-atanmamış tahtalar
- Program kurulur ama okul henüz belli değilse tahta **`corporate_code=0`** veya default kodlarla
  (**`353535`**, **`19381938`**) çalışır — çevrimdışı şifreyle açılıp kapanabilir. Elemanlar okul
  tanıtımı yapmadan da böyle test ediyor. (`akilli_tahtalar` kütüğündeki ilk kayıtlar zaten `353535`.)
- **Rapor kuralı:** Bu default kodlar **"aktif okul" sayımından ÇIKARILIR** (yoksa test kodları okul
  gibi sayılır), ama ayrı bir **"okula atanmamış / default kodda çalışan tahta"** kutusunda gösterilir.

### 5B.3 Rapor metrik kuralı (ZORUNLU)
- **Aktif OKUL sayısı GÜVENİLİR** → `COUNT(DISTINCT kurum_koduss)` (v4 okul kodunu hep doğru yazar).
- **Aktif TAHTA sayısı GÜRÜLTÜLÜ** → tek şişik rakam gösterme. İki katman: **(a) kütükle eşleşen =
  doğrulanmış**, **(b) eşleşmeyen = "geçmiş/bilinmeyen"** ayrı gösterilir. Default kodlar 3. kutu.
- Bozuk tarihli satırlar (ör. `7540-10-13`, id 4109713 — MyISAM yarım-yazması) rapordan tarih aralığı
  filtresiyle dışlanır; günlük rollup işi `tarih < CURDATE()+1 AND tarih >= '2024-01-01'` koşulu koyar.

### 5B.4 `smart_board_post` mükerrer kayıt riski → UNIQUE indeks EKLENDİ ✅ (14 Tem 2026)
- `(kurum_kodu, t_id)` üzerinde UNIQUE kısıt **yoktu**. Prod temizdi (4.292 satır = 4.292 tahta,
  0 mükerrer) ama **dev'de mükerrer oluşmuştu** (tek tahtada 27 kayıt) — yani engelleyen bir şey yoktu.
- **Kök neden:** v4, v5 ve ynt5'in üçü de "önce `SELECT`, varsa `UPDATE`, yoksa `INSERT`" yapıyor.
  İki istek aynı anda gelirse ikisi de "kayıt yok" görüp `INSERT` eder → mükerrer. Klasik yarış koşulu.
- **Neden tehlikeli:** Yoklama sorgusu (`s_brt.php` fnc 5567) `LIMIT`/`ORDER BY` içermiyor. Mükerrer
  varsa **hangi satırın okunacağı belirsiz** → panel bir satıra komut yazarken tahta başkasını okur,
  **komut tahtaya hiç ulaşmaz**. ("Kilitledim ama kilitlenmedi" şikayetlerinin muhtemel sebebi.)
- **Yapılan:** `ALTER TABLE smart_board_post ADD UNIQUE KEY uq_board_post_kurum_tid (kurum_kodu, t_id)`
  → prod'a eklendi. Mükerrer artık fiziksel olarak imkânsız.
- **Faz 1'de yapılacak:** v5 cihaz endpoint'inde upsert `INSERT ... ON DUPLICATE KEY UPDATE` ile
  **atomik** hale getirilecek (bu indeks onun ön koşuluydu). Ayrıca tüm durum sorguları her tahta için
  **en güncel** kaydı (`MAX(id)`) almalı — savunmacı yazım.

### 5B.5 ynt5'te bulunan iki sessiz hata (düzeltildi)
Okul bazlı tahta listesi eklenirken ortaya çıktı — ikisi de **yanlış bilgi gösteren** cinsten:
1. **Komutlar yanlış numaraya gidiyordu.** Genel liste `SELECT * FROM akilli_tahtalar` yapıyordu; orada
   alan adı `tahta_no`, ama frontend `t_id` arıyordu. Bulamayınca `board.id`'ye (kütük satır id'si, ör. 46)
   düşüyor ve komut o numarayla gönderiliyordu — hedef tahta 1 numaralıyken. → Sorguda
   `a.tahta_no AS t_id` eşlemesi yapıldı.
2. **Durumu bilinmeyen tahta "Aktif" görünüyordu.** Genel liste durum alanlarını hiç çekmiyordu;
   `open_close` tanımsız olunca kontroller düşüyor ve **her tahta yeşil "Aktif"** damgası alıyordu.
   → Durum alanları `smart_board_post`'tan bağlandı; komut kaydı yoksa **"Durum yok"** (gri) gösteriliyor.

> 💡 **Kural:** Panelde *bilinmeyen* bir durumu *bilinen* gibi göstermek, hiç göstermemekten kötüdür.
> Eleman "Aktif" görüp tahtanın çalıştığını sanır. Veri yoksa "Durum yok" denir.

---

## 5C. 🔴 GÜVENLİK — Çevrimdışı Şifre Formülü ÇÖZÜLMÜŞ (v6'da değişecek, KOORDİNELİ)

- **Sorun:** Çevrimdışı (internetsiz) tahta açma şifresi **öğrenciler tarafından çözülmüş**.
- **Neden zayıf:** Formül `(yıl × gün × dakika × 85)`'in ilk 6 hanesi (`generate_dynamic_password`,
  [client.py:294](fatih_projesi_python/client/client.py)). Sadece 3 değişken; yıl+gün zaten biliniyor,
  tek bilinmeyen dakika → günde ~58 olası şifre. Tahtaya özel sır YOK.
- **Ek kırılganlıklar:** (1) `hour` hesaba katılmıyor — 09:15 ile 14:15 aynı şifre. (2) Doğrulama
  toleransı tek yönlü (`offset [0,+1,+2]`); mobilin saati tahtadan **geride** kalırsa şifre tutmaz →
  saha "şifre çalışmıyor" şikayetlerinin muhtemel sebebi. (3) `minute` 60'a taşınca mod alınmıyor.
- **⛔ TEK TARAFLI DEĞİŞTİRİLEMEZ.** Aynı formül **3 yerde** paylaşılıyor: şifreyi üreten **mobil
  uygulama**, doğrulayan **Pardus (client.py)**, doğrulayan **Windows (C#)**. Biri değişip diğerleri
  kalırsa sahadaki tüm çevrimdışı açma çöker.
- **v6 planı (ayrı, dikkatli iş):** Saat-tabanlı OTP (TOTP benzeri) + **tahta-özel sır** (kurum kodu +
  board_id türevi) ile değiştirilir; çift yönlü zaman toleransı. Mobil + Pardus + C# aynı sürümde
  koordineli geçer. Faz planına eklendi.

---

## 5D. OTURUM DURUMU — 14/15 Temmuz 2026 (KALINAN YER)

### Bugün TAMAMLANANLAR ✅
1. **v6 iskeleti:** `v1.00.93` tag'i, `v6` branch + `C:\Github\Pardus_Tahta_v6` worktree, bu kurallar dosyası.
2. **`.gitignore` düzeltmesi** hem `v6` hem `main`'de (UTF-16 `*.zip` → "her şeyi yoksay" hatasıydı).
3. **DB bakımı (prod, dev'den sonra):** `smart_boadr_logs` tarih indeksi + MyISAM→InnoDB (rapor 7,7s→0,30s),
   gereksiz indeks silindi, `smart_board_post`'a `UNIQUE(kurum_kodu, t_id)`, `tahta_istatistik_gunluk`
   özet tablosu (615 gün geçmiş).
4. **ynt5 Akıllı Tahta ekranı** (canlıda, commit `cd632aa`): master-detail (solda 18 okul `t_aktif=1`,
   sağda tahtalar), Kilit+Elektrik ayrı sütunlar, `GET /smartboards/schools` + `/school/:kk` +
   `/school/commands`. 3 sessiz hata düzeltildi (komut yanlış no'ya gidiyordu, "Durum yok" yerine "Aktif",
   Dashboard'da yanlış "dev" etiketi).

### YARIN DEVAM EDİLECEKLER (öncelik sırasıyla)
1. **🔴 Eski `ynt.mebre.com.tr` (v4 PHP paneli) kapatma kararı.** Giriş loglarında gece boyu bot taraması
   görüldü (AWS IP'leri `login.php`'ye vuruyor, KULLANICI sütunu boş = giriş YOK, sadece bot gürültüsü).
   ynt5'e geçildiyse eski panel kapatılmalı/IP-whitelist'e alınmalı. **ÖNCE** v4'ün başka neyinin ona
   bağlı olduğu kontrol edilmeli — körlemesine kapatma. Kullanıcıya soruldu: "eski ynt hâlâ kullanılıyor mu?"
   → cevap bekliyor.
2. **Tahta çalışma-saati mantığını netleştir.** Kullanıcı "saatleri tetikleyen cron var" sanıyordu ama:
   `workAll.php` = lisans+IP işi (tahtaya dokunmaz), tahta saatleri aslında **client-side** (tahta
   `get_values`/5563 ile çalışma saatlerini çeker, `_saat.php`'den saati alır, KENDİ açılıp kapanır).
   İstenirse `client.py`'deki çalışma-saati mantığı birlikte gözden geçirilecek.
3. **Faz 1'e başla:** v5'e cihaz endpoint modülü (`akilliTahtaCihaz`): 5567/5566/5563/5571/5574/5570 +
   heartbeat (`son_gorulme`) + `5566` kolon whitelist + atomik upsert (UNIQUE hazır).

### Cron durumu (kontrol edildi, HEPSİ SAĞLAM)
Sunucu `mebrecomtr` kullanıcısı crontab'ında: `workAll.php` (gece 8×, lisans+IP), `tableOnarim.php`
(00:03, TÜM tabloları `REPAIR` — InnoDB'ye çevirdiğimiz tabloyu zararsızca atlar; MyISAM bozulma
workaround'uydu, artık o tablo için gereksiz), `cronBackupCtrl.php` (yedek). **Hiçbiri bugünkü DB
değişikliklerinden etkilenmedi.** Cron scriptleri REPODA YOK (`/home/mebrecomtr/public_html/api/crons/`) —
canlıda repoda olmayan v4 kodu var (ayrı teknik borç).

### Önemli mimari hatırlatma
- Cihaz tarafı (`s_brt.php` 5567 vb.) HÂLÂ v4'te. Loglarda `/v4/s_brt.php` görmek DOĞRU. `securtyphp_logs`'a
  sadece `v4/security.php` yazar; ynt5 sadece okur. Loglar Faz 1'de v5'e geçince node'a taşınır.
- ynt5 yerel geliştirme: MySQL kullanıcı IP whitelist gerektiriyor (yerelden dev DB'ye bağlanılamadı,
  `176.216.9.169` reddedildi). Test SQL'leri phpMyAdmin'den yapıldı.

---

## 6. Tespit Edilen Hatalar ve Teknik Borç

### 6.1 Güvenlik — v5'e taşırken MUTLAKA düzeltilecek
- **`5566` SQL enjeksiyonu (KRİTİK):** `UPDATE smart_board_post SET $clmns='$values' ...` — client'tan
  gelen `c_l` (kolon adı) hiçbir filtreden geçmeden sorguya giriyor. Tahta yazılımı açık kaynak
  dağıtıldığı için `wb_user`/`wb_pass` eline geçen biri istediği kolonu yazabilir.
  → **v5'te kolon adı whitelist'e bağlanacak**, asla dinamik SQL'e girmeyecek.

### 6.2 v4'te duran bozukluklar (dokunmuyoruz, ama bilinsin)
- **`5572` bozuk SQL:** `system_Remove='0,p_tarihi='$tarih1'` — tırnak kapanmamış, bu UPDATE sessizce
  hiç çalışmıyor. Yani v4'te tahta şifresi alındığında beklenen sıfırlama gerçekleşmiyor olmalı.
  v5'teki `updateBoardRecordForPassword` bunu doğru yapıyor (orada düzelmiş).

### 6.3 Depo hijyeni (v6'da temizlenecek)
- **`.gitignore` bozuk:** Son satırdaki `*.zip` kuralı **UTF-16LE** olarak yazılmış
  (`2a 00 2e 00 7a 00 69 00 70 00`), git bunu okuyamıyor → **zip filtresi hiç çalışmıyor**.
- **`.gitignore`'a yazılı "debug dosyaları" hâlâ git'te takipli.** (`.gitignore` zaten takip edilen
  dosyayı geri çekmez.) Takipten çıkarılacaklar: `old_client.py`, `diff.txt`, `login_dialog.txt`,
  `changepass_dialog.txt`, `config_dialog*.txt`, `kiosk_osk.txt`, `osk_*.txt`, `*_check.txt`,
  `output_lines.txt`, `fatihclientapp.txt`, `screen.png`, `mebre_lock.png`, `Fatih_Client_Kurulum.zip`.
  Bunların bir kısmı (`old_client.py`, `changepass_dialog.txt`, `login_dialog.txt`) doğrudan şifre/kilit
  ekranı kodunun eski kopyaları — açık kaynak dağıtımda bulunmamalı.
  ⚠️ `fatih_projesi_python/client/resources/Artboard 3.png` **hariç** — o gerçek bir uygulama kaynağı.
- **Kök `version.txt` bayat:** `V1.00.26` yazıyor; gerçek sürüm `fatih_projesi_python/client/version.txt`
  = `V1.00.93`. İki dosyanın ilişkisi netleştirilmeli veya kökteki silinmeli.

---

## 7. Cevap Bekleyen Sorular

1. **v5 cihaz endpoint'leri hangi auth'u kullanacak?** Node tarafında `wb_user`/`wb_pass` karşılığı
   (Basic) ve `User-Key` doğrulaması nasıl saklanacak/üretilecek? (v4'teki `CheckAccesptKey()`
   mantığının Node karşılığı yazılmalı.)
2. **v6'da tahtada hangi yeni özellikler/düzeltmeler hedefleniyor?** (Backend taşıması dışında.)
3. ~~v5 sunucusu tahta trafiğini kaldırır mı?~~ → **Ölçüldü, bkz. §4A.4: zirve ~710 req/s, hedef
   ~1.000 req/s.** Geriye kalan soru: **v5 sunucusunun (188.132.200.30) donanımı ne?** Henüz ölçülmedi.
   CPU/RAM, Node sürümü, PM2 durumu, nginx yapılandırması ve `.env`'deki DB host'u alınmalı.
4. Redis / cache katmanı v5 sunucusunda mevcut mu, yoksa kurulacak mı?

---

## 7A. 🔴 VERİTABANI ÇALIŞMA KURALI (ZORUNLU)

> **HER SQL DEĞİŞİKLİĞİ ÖNCE DEV, SONRA PROD.** İstisnası yoktur.

| Ortam | Veritabanı |
|---|---|
| **Dev** (önce burada) | `mebrecomtr_mbrdata_dev` |
| **Prod** (dev'de doğrulandıktan sonra) | `mebrecomtr_mbrdata` |

Kapsam: `CREATE TABLE`, `ALTER TABLE`, indeks ekleme, backfill/migration, toplu `UPDATE` — kısacası
şemaya veya veriye dokunan her şey. Önce dev'de çalıştırılır, sonuç doğrulanır, **ancak ondan sonra**
prod'da aynısı koşulur. Migration script'leri (`ynt5/src/scripts/db_setup_*.ts` deseni) idempotent
yazılır ki iki ortamda da güvenle tekrar çalıştırılabilsin.

Gerekçe: DB, tüm ekosistemin (v4 PHP, v5 Node, ynt5 panel, masaüstü, mobil, tahtalar) tek ortak
noktasıdır. Prod'da bozulan bir şema, sahadaki 3.000+ tahtayı ve tüm okulları aynı anda etkiler.

---

## 8. Değişmez Kurallar (Hatırlatma)

`.agents/workflows/project_rules.md` **tam olarak geçerlidir**. Özellikle:
- Plaintext URL/şifre yasak; XOR + RAM temizliği; `verify=True`.
- `QDialog.exec_()` yasak; dialoglar `Qt.Tool | Frameless | StaysOnTop`; gömülü Numpad.
- Varsayılan admin şifresi `803580`; `mebre` → `803580` migration'ı korunur (§5 Password Invariant).
- Paketleme **yalnızca** `python paket_olustur.py` ile; C# kodu bu depoda bulunmaz.

v6 bu kuralların hiçbirini gevşetmez.
