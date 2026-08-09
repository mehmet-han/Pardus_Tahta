# Gelecek İşler (Backlog)

> Henüz başlanmamış, sırası gelince yapılacak işler. Kararı verilmiş olanlar
> `php_bagimliligi_bitirme_todo.md`'de; burası "unutmayalım" listesi.
>
> Açılış: 9 Ağustos 2026

---

## 1. Tablo standardı — meta sütunları + `props` esnekliği

**İstek:** Eskiden açılan tablolarda kayıt tarihi, güncelleme tarihi gibi alanlar
ve ileride lazım olacak veriler için JSON tutan bir `props` sütunu vardı. Son
eklenen tabloların çoğunda bunlar yok. Özellikle **finans** tarafında bir yıl
sonra geliştirme yapabilmek için bu esneklik şart.

### Mevcut durum (9 Ağu 2026'da ölçüldü)

Uygulama tanımlarına bakıldığında tutarlılık dağılmış:

| Tablo grubu | Durum |
|---|---|
| `ilcePuantaj` (ilceKurum, ilKurum, ilcePuantaj, genelMudurluk…) | ✅ En iyi örnek — `props LONGTEXT DEFAULT '{}'` var |
| `kesinti`, `gunlukKilit`, `ogretmen` | 🟡 Kısmî — bazı alanlar var |
| `tatil`, `veliizin` | 🟡 Tek alan |
| **`finans_*`** (kalem, tarife, indirim, kasa…) | ❌ **Hiçbiri yok** |
| **`optik*`** (Sablonlar, Sinavlar, CevapAnahtarlari, Sonuclar) | ❌ Hiçbiri yok |
| `yedek_durum` | ❌ Hiçbiri yok |

`finans_kalem`'de yalnızca `olusturma TIMESTAMP` var: kimin oluşturduğu yok,
güncelleme tarihi yok, kimin güncellediği yok, `props` yok. Para tutan tablo
grubu, esneklik ihtiyacının en yüksek olduğu yer — ve en çıplak olan yer orası.

Ayrıca **iki ayrı isimlendirme** yan yana yaşıyor: `olusturma` (finans) ve
`created_at` (ogrenciler). Biri Türkçe biri İngilizce. Standart tek olmalı.

### Önerilen standart — her yeni tabloda

```sql
`created_at`   INT UNSIGNED NOT NULL DEFAULT 0,
`updated_at`   INT UNSIGNED NOT NULL DEFAULT 0,
`created_from` INT NULL DEFAULT NULL,   -- kullanıcı id
`updated_from` INT NULL DEFAULT NULL,
`kaynak`       VARCHAR(20) NOT NULL DEFAULT '',
`deleted_at`   INT UNSIGNED NOT NULL DEFAULT 0,
`deleted_from` INT NULL DEFAULT NULL,
`props`        LONGTEXT NOT NULL DEFAULT '{}',
```

`INT UNSIGNED` unix saniye seçildi çünkü `ogrenciler` gibi büyük mevcut tablolar
zaten öyle (`created_at = 1720449265`). Yeni tabloları `TIMESTAMP` yapmak üçüncü
bir desen daha üretirdi. Tek dezavantajı phpMyAdmin'de okunmaması — kod
tarafında zaten çevriliyor.

### Neden bu sütunlar — ve düşündüğümüz ek esneklikler

**`kaynak` — bugün canımızı yakan eksik.** Bu satırı hangi sistem yazdı:
`panel`, `mobil`, `tahta`, `cron`, `v4`, `v5`, `ynt5`. Bugün "v4'e hâlâ kim
vuruyor" ölçümünü yazarken v4 ile v5 kayıtlarını ayırmak için
`smart_boadr_logs.school_id`'nin v4'te gerçek id, v5'te sabit `0` olmasından
faydalanmak zorunda kaldık — kod arkeolojisiyle bulunan, kırılgan bir ayrım.
Tek bir `kaynak` sütunu olsaydı sorgu tek satır olurdu. Her geçiş döneminde
(v5→v6, mobil→web) aynı ihtiyaç doğacak.

**`deleted_at` — özellikle finansta silme yasağı.** Para tutan bir satır
`DELETE` edilmemeli; iptal edildiği işaretlenmeli. Aksi halde "bu tahsilat neden
kayboldu" sorusunun cevabı hiçbir yerde olmaz. Not: silinen satırlar
sorgulardan düşsün diye tüm okuma sorgularına `deleted_at = 0` koşulu eklenmeli
— bu, standardın en kolay unutulan kısmı.

**`props` kullanım kuralları** (yoksa çöplüğe döner):
- Varsayılan `'{}'`, asla `NULL` değil → kodda `JSON.parse(row.props)` her zaman güvenli
- **Asla `WHERE` ile aranmaz.** İndekslenemez; aranacak bir alan doğduysa
  gerçek sütuna terfi ettirilir
- Yani `props` "henüz şekli oturmamış veri"nin evi, kalıcı ev değil
- MariaDB'de `JSON` tipi zaten `LONGTEXT` diğer adı — `LONGTEXT` doğru seçim,
  istenirse `CHECK (json_valid(props))` eklenebilir

**Ek olarak düşünülmesi gerekenler:**

- **`surum INT NOT NULL DEFAULT 0`** (iyimser kilit). İki kullanıcı aynı kaydı
  açıp kaydettiğinde ikincisi birincinin değişikliğini sessizce eziyor. Finans
  ve tarife ekranlarında bu gerçek bir risk. `UPDATE … WHERE id=? AND surum=?`
  ile 0 satır dönerse kullanıcıya "kayıt sizden sonra değişti" denir.
- **Para tabloları için ters kayıt (append-only).** `finans_tahsilat` gibi
  tablolarda `UPDATE` yerine iptal + ters kayıt deseni. Muhasebe mantığına da
  uygun, geçmiş hiç bozulmaz.
- **`ip` / `user_agent` yalnızca denetim tablolarında.** Her tabloya konursa
  gereksiz kişisel veri toplamış oluruz; giriş, yetki değişikliği ve para
  hareketlerinde anlamlı.
- **`etiketler` alanının akıbeti.** `finans_kalem.etiketler` zaten JSON dizi
  tutuyor (`["Zorunlu","Opsiyonel"]`). Standart gelince ya `props` içine taşınır
  ya da "adı belli, şekli belli" diye ayrı kalır — karar verilmeli, ikisi birden
  olmasın.

### Yapılacaklar

- [x] Standardı bir dosyaya yaz ✅ `v5/veritabani_standardi.md`
- [x] Mevcut eksik tablolara `ALTER TABLE` ile ekle ✅ **9 Ağu 2026 — 26 tablo,
      dev ve prod tamam, veri kaybı yok**

  | Dalga | Tablolar | Dosya |
  |---|---|---|
  | 1 | `finans_*` (4), `optik*` (4), `yedek_durum` | `migrations/2026_08_meta_sutunlari.sql` |
  | 2 | `kazanim_*` (4), `rehberlik_*` (8), `sporzeka_*` (5) | `migrations/2026_08_meta_sutunlari_2_TEK_SATIR.sql` |

  Yol boyunca çıkan üç tuzak (hepsi dosyalara not edildi):
  - **`DATABASE()` phpMyAdmin'de boş dönüyor** → doğrulama sorgusu hiçbir şey
    bulamıyor ve sütunlar eklenmemiş gibi görünüyor. Veritabanı adı elle yazılmalı.
  - **phpMyAdmin çok satırlı `ALTER`'ı yanlış yerden bölüyor** ("Tanınmayan ifade
    türü, near ADD"). Çözüm: her ifade tek satırda, yorumlarda tırnak/ters tırnak yok.
  - **`surum` adı çakışıyordu** — `yedek_durum.surum` zaten "masaüstü sürümü"
    demek. İyimser kilit sütunu `satir_surum` olarak netleştirildi.
- [ ] Repository katmanına ortak yardımcı: insert/update'te `created_at`,
      `updated_at`, `kaynak` otomatik dolsun; her sorguda elle yazılmasın
- [ ] Okuma sorgularına `deleted_at = 0` koşulunu ekle (tek tek gözden geçirme işi)
- [ ] `olusturma` → `created_at` isim birleştirmesi yapılsın mı, karar ver
      *(kolon adı değişikliği kod değişikliği demek; sadece yeni tablolarda
      standart uygulanıp eskiler bırakılabilir)*

---

## 2. Masaüstü Etkinlikler — okulun etkinlik takvimi

**İstek:** Masaüstünde okulun **etkinlik takvimi** gösterilecek.
*(9 Ağu 2026'da netleşti: kullanım/telemetri kaydı değil, okulun kendi
etkinlikleri — tören, gezi, veli toplantısı, sınav günü gibi.)*

### Sıfırdan başlamıyoruz — dokunacağı üç mevcut sistem

| Sistem | Nerede | Ne yapıyor |
|---|---|---|
| **Masaüstü duyuru** | `v5/src/repositories/client/desktop_duyuru/` | `okul_duyurular` tablosundan okuyup masaüstüne düşürüyor |
| **Tahta duyuru** | `v5/…/tahta_duyuru/`, `Pardus_Tahta_v6/…/client.py` | Tahtada duyuru gösteriyor (V6.00.45'te fotoğraf, V6.00.46'da ders saati bitince düşme eklendi) |
| **MEB Takvimi** | `v5/src/apps/tatil/` (`Tatil`, `AkademikYil`) | Resmî tatil ve akademik yıl takvimi |

Yani masaüstünde zaten bir duyuru kanalı **var**. İlk karar bu yüzden şu:

- [ ] **Yeni sistem mi, `okul_duyurular`'ın genişletilmiş hâli mi?**
      "Duyuru" ile "etkinlik" farkı: duyurunun tek bir yayın anı var, etkinliğin
      **başlangıç–bitiş tarihi** ve takvim üzerinde bir yeri var. Bu fark tek
      başına ayrı tablo gerektirebilir; ama iki ayrı sistem olursa okul aynı
      şeyi iki yere girmek zorunda kalır.

### Netleşmesi gerekenler

- [ ] Hangi istemci: Windows masaüstü (`Fatih_Client_CSharp`), Pardus tahta, ikisi de?
- [ ] Kim oluşturur — okul yöneticisi, öğretmen, yoksa merkez de gönderebilir mi?
- [ ] Nerede görünür: kilit ekranı, uygulama içi, MebreCep'e de düşecek mi?
- [ ] Tekrar eden etkinlik (her salı) olacak mı? Olacaksa tasarım baştan ona göre kurulmalı.
- [ ] `Tatil` / `AkademikYil` takvimiyle aynı ekranda mı gösterilecek?
      Kullanıcı için "okulun takvimi" tek bir şeydir; resmî tatiller ve okul
      etkinlikleri ayrı ekranlarda durursa parçalı görünür.

> ⚠️ Duyuru tarafında geçmiş var: duyuru özelliği öğrencilere toplu mesaj
> atmak için suistimal edildiği için v5'ten kaldırılmıştı
> (bkz. hafıza: *Duyuru suistimal & yeniden tasarım*). Etkinlik takvimi de bir
> yayın kanalıdır — kimin kime ne gönderebileceği baştan sınırlanmalı, sonradan
> eklenen kısıt tutmuyor.

---

## 3. Masaüstü programa bağlamsal ipucu balonları

**İstek (9 Ağu 2026):** Google Search Console'da ekranın köşelerinde çıkan
açıklama balonlarının benzeri masaüstü programına da konsun.

**Ne işe yarar:** Kullanıcı bir ekranı ilk kez açtığında, o ekrandaki düğmenin
ne yaptığını anlatan küçük bir balon çıkar. Yeni bir özellik eklendiğinde de
"burada yeni bir şey var" diye işaret eder. Bugün yeni özellikleri kullanıcıya
duyurmanın tek yolu telefonla anlatmak; balonlar bu yükü azaltır.

### Tasarımda baştan düşünülmesi gerekenler

- [ ] **"Gördüm" bilgisi nerede tutulacak?** Balon bir kez gösterilip
      kapatıldıktan sonra bir daha çıkmamalı. Bu bilgi **kullanıcı bazında**
      tutulmalı (okul bazında değil) — aynı okulda iki müdür yardımcısı varsa
      ikisi de kendi rehberini görmeli.
- [ ] **Sürüm bilgisi şart.** Balon "gördüm" olarak işaretlenirken hangi
      ipucunun hangi sürümü görüldüğü de yazılmalı. Aksi halde ipucunun metni
      güncellendiğinde kimse yeni hâlini görmez.
- [ ] **Sunucudan mı gelecek, programa mı gömülü olacak?** Sunucudan gelirse
      yeni sürüm dağıtmadan ipucu eklenebilir — asıl kazanç bu. Gömülü olursa
      her değişiklik için istemci güncellemesi gerekir.
- [ ] **Kapatma her zaman mümkün olmalı.** "Bir daha gösterme" seçeneği
      olmayan rehberler kullanıcıyı bıktırır; program açılışında art arda dört
      balon çıkarsa özellik ters teper.
- [ ] Windows masaüstü mü, Pardus tahta mı, ikisi de mi?

> 🔗 Madde 1 ile bağlantılı: "gördüm" işaretleri tam olarak `props` JSON
> sütununun tarif ettiği veri — şekli zamanla değişecek, tek tek sorgulanmayacak
> ve her ipucu için ayrı sütun açmak anlamsız. Tablo standardı bu iş
> başlamadan önce oturursa buraya hazır zemin olur.

---

## 4. Web girişi — okul kullanıcıları için web uygulaması

**İstek (9 Ağu 2026):** Web sitesine "Giriş" düğmesi konsun. Kullanıcı cep
numarası ve MebreCep şifresiyle girsin; **mobilde yapması zor olan işleri**
web'den yapsın.

### Verilen kararlar (9 Ağu 2026)

| Konu | Karar |
|---|---|
| Konum | **Ayrı bir web uygulaması** — `kurum-panel` kurumsal kademeye özel kalacak |
| İlk roller | **Yönetici / müdür yardımcısı** ve **öğretmen** |
| Sonraki roller | Veli ve öğrenci — ilk faz oturduktan sonra |

### Sıfırdan başlamıyoruz

`kurum-panel` (React + Vite) zaten var ve giriş mekanizması tam bu desende:

```
Kurum Kodu + Cep Telefonu + Şifre  →  POST /client/login   (apiv5)
```

Ayrı uygulama yazılacak ama **kimlik doğrulama ucu yeniden yazılmamalı**;
`/client/login` ve `client/*` uçları paylaşılmalı. `kurum-panel`'in
`src/services/api.ts` ve `src/store/authStore.ts` dosyaları başlangıç deseni
olarak alınabilir.

### 🔴 Güvenlik — baştan tasarlanacak, sonradan eklenmeyecek

Bu iş, bugüne kadar yalnızca mobil uygulamada duran bir kapıyı **herkese açık
bir web adresine** taşıyor. Telefon numarası tahmin edilebilir bir bilgi ve
şifre 6 hane; yani kaba kuvvet denemesi gerçekçi bir tehdit.

- [ ] Deneme sınırı: IP + telefon başına, artan gecikmeli
- [ ] Belirli sayıda hatalı denemeden sonra geçici kilit
- [ ] Oturum süresi ve yenileme mantığı (mobildekiyle aynı olmak zorunda değil)
- [ ] Her giriş denemesi denetim kaydına — başarılı/başarısız, IP, `kaynak='web'`
- [ ] Şifre hiçbir zaman adres satırında taşınmaz

> ⚠️ **Atlanması muhtemel kritik nokta — MebreCep izni.** `Mebre_Cep_Izni`
> alanının polaritesi TERS: **1 = ENGELLİ**, 0/NULL = izinli. Bu kısıtı okul
> koyuyor; yani okul bir öğretmenin veya velinin MebreCep kullanmasını bilerek
> kapatmış olabilir. **Web girişi bu kontrolü uygulamazsa, okulun koyduğu
> kısıtın etrafından dolaşan bir kapı açılmış olur.** Giriş ucunda bu alan
> mutlaka kontrol edilmeli.
> (bkz. hafıza: *MebreCep izin polaritesi*)

### Netleşmesi gereken — ekran listesi

**"Mobilde yapması zor olan işler" hangileri?** Cevap gelmeden tasarım tahmin
olur. Aşağıdaki liste bir **öneri**, onaylanması/düzeltilmesi gerekiyor:

*Yönetici / müdür yardımcısı*
- Toplu yoklama düzeltme (geçmiş güne dönük)
- Devamsızlık raporları, tarih aralığı seçerek
- Veli sözleşmesi hazırlama ve yazdırma
- Finans: tahsilat girişi ve dönemsel rapor
- Ders programı görüntüleme / düzenleme

*Öğretmen*
- Not girişi (ölçme değerlendirme)
- Ödev oluşturma ve gönderilen ödevleri değerlendirme
- Kazanım işaretleme (işlenen / işlenmeyen)
- Kendi dersinin yoklamasını düzeltme

Ortak nokta: hepsi **klavye, geniş ekran veya yazıcı** isteyen işler. Telefonda
yapılabilen bir işi web'e taşımanın kazancı yok; seçim ölçütü bu olmalı.

### Sıralama

- [ ] 1. Ekran listesi netleşsin
- [ ] 2. Güvenlik tasarımı (yukarıdaki maddeler) yazılsın
- [ ] 3. Uygulama iskeleti + giriş ekranı
- [ ] 4. Yönetici ekranları → öğretmen ekranları
- [ ] 5. **Siteye "Giriş" düğmesi en son eklenir**

> Düğme neden en sona bırakılıyor: arkasında çalışan bir uygulama olmadan
> konursa ziyaretçi ölü bir bağlantıya tıklar. Site bugün itibarıyla arama
> motorlarına yeni açıldı; ilk izlenimi kırık bir düğmeyle vermek istemeyiz.

> 🔗 Madde 1 ile bağlantılı: `kaynak` sütununa `web` değeri bu iş için eklendi.
> Web'den yazılan her kayıt `kaynak='web'` taşıyacak — böylece bir veri sorunu
> çıktığında hangi uçtan geldiği belli olur.
