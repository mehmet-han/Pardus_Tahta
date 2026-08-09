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

- [ ] Standardı bir dosyaya yaz: `v5/veritabani_standardi.md` (SQL'in yaşadığı yerde dursun)
- [ ] Mevcut eksik tablolara `ALTER TABLE` ile ekle — **önce dev, sonra prod**
      (`finans_*`, `optik*`, `yedek_durum` öncelikli)
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
