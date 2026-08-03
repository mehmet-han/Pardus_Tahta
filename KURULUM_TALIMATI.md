# Akıllı Tahta Kurulum Talimatı

**Pardus ETAP · Mebre Yazılım**

> Bu talimat sürümden bağımsızdır. Elinizdeki paketin sürümü dosya adında yazar
> (`Fatih_Client_Kurulum_V6_00_47_KORUMALI.zip` gibi) ve kurulum sonunda ekranda görünür.

Bu talimat, akıllı tahtaya kilit programının kurulmasını anlatır.
İnternetten ve USB'den kurulum **aynı adımlardan** oluşur; tek fark dosyayı
nereden aldığınızdır.

---

## Kurulumdan önce elinizde olması gerekenler

| | Ne |
|---|---|
| 1 | Kurulum paketi — adı `Fatih_Client_Kurulum_V6_00_XX_KORUMALI.zip` biçimindedir |
| 2 | **Zip şifresi** — Mebre'den alınır |
| 3 | **Okulun kurum kodu** (MEB kurum kodu, sadece rakam) |
| 4 | Tahtada çalışan **internet bağlantısı** |

İnternet olmadan kurulum tamamlanamaz. Tahtanın kendini tanıtabilmesi için
sunucuya bağlanması gerekir.

---

## ADIM 1 — Paketi edinin

### A) İnternetten kuracaksanız

1. Tahtada tarayıcıyı açın, Mebre'nin indirme sayfasına girin.
2. Giriş yapıp paketi indirin.
3. İnen dosyayı sağ tıklayıp **Buraya çıkart** deyin.
4. Şifre sorulduğunda Mebre'den aldığınız **zip şifresini** girin.

### B) USB ile kuracaksanız

1. USB belleği tahtaya takın.
2. Paketi USB'de sağ tıklayıp **Buraya çıkart** deyin, **zip şifresini** girin.

> **Önemli:** Dosyaları tek tek kopyalamayın. Paketi olduğu gibi çıkartın —
> içindeki dosyalar birbirinin yanında durmak zorundadır.

---

## ADIM 2 — Kurulumu başlatın

Çıkarttığınız klasörde sağ tıklayıp **Terminalde aç** deyin, sonra:

```
sudo ./setup.sh
```

### Kurulum size ne soracak

**1) Kurum kodu.** Okulun MEB kurum kodunu yazıp Enter'a basın. Sadece rakam olmalı.

**2) Kurulum kodu (bazen).** Paketin içinde varsa hiç sorulmaz, kendisi okur.
Sorulursa Mebre'den aldığınız **64 haneli kodu** girin.

Bundan sonrası kendiliğinden ilerler. Ekranda `[0/7]`'den `[7/7]`'ye kadar
adımları görürsünüz.

### Kurulum bitince ekranda şu özet çıkar

```
✅ KURULUM TAMAMLANDI!
---------------------------------------------------------
Kurulan sürüm : V6.00.47
Kurum kodu    : 353535
Tahta kimliği : ⏳ Tanıtılmadı — kurulum kodu gömüldü.
---------------------------------------------------------
```

**Bu üç satırı mutlaka okuyun.** Sürüm, indirdiğiniz paketin adındaki sürümle
aynı olmalı; kurum kodu da doğru okul olmalı.

---

## ADIM 3 — Tahtayı yeniden başlatın

```
sudo reboot
```

Tahta açıldığında kilit ekranı gelir.

---

## ADIM 4 — Tahtayı tanıtın

Kilit ekranında **Tahta Yapılandırması** ekranını açın.

### Önce şifreyi değiştirin — bu zorunlu

Ekrana **sağ tıklayıp** şifre değiştirme bölümünü açın ve fabrika şifresini
(`803580`) okula özel yeni bir şifreyle değiştirin.

> Şifreyi değiştirmeden tahta listesi **gelmez**. Ekranda
> *"Önce sağ tıklayıp şifrenizi değiştiriniz!"* yazar.

Yeni şifreyi okul yönetimine bırakın ve kendi kaydınıza yazın.

### Sonra tahtayı seçin

1. **Kurum Kodu** kutusuna okulun kurum kodunu yazın.
2. **Şifre** kutusuna az önce belirlediğiniz yeni şifreyi yazın.
3. **Tahtaları Getir** düğmesine basın.
4. Sağda okulun tahtaları listelenir. **Bu tahtanın hangisi olduğunu seçin**
   (örn. "5-B sınıfı").
5. **Onayla** deyin.

"Başarılı! N tahta bulundu" yazısını görüp doğru tahtayı seçtiyseniz kurulum bitti.

---

## ADIM 5 — Kontrol edin

- Tahtayı yeniden başlatın, kilit ekranı geliyor mu?
- Okul yönetiminden MebreCep'ten tahtayı açmasını isteyin — açılıyor mu?
- Ders çıkış saatinde kendiliğinden kilitleniyor mu?

Üçü de çalışıyorsa okuldan ayrılabilirsiniz.

### ÖNEMLİ — Ders programı girilmiş mi?

Okuldan ayrılmadan önce **okul yönetimine sorun**: Mebre masaüstü programında
akıllı tahta **çalışma saatleri** (ders giriş/çıkış saatleri) girilmiş mi?

Girilmemişse tahta **ders bitiminde kendiliğinden kilitlenmez.** Öğretmen açar,
açık kalır — kilit sisteminin en önemli işi yapılmamış olur. Ayrıca tahtaya
gönderilen duyurular da gün içinde düşmez, birikir.

Program girilmemişse okul yönetimine masaüstü programdan girmesini söyleyin ve
girdikten sonra **veri gönderdiğinden** emin olun. Tahta yeni saatleri bir
sonraki yoklamada alır.

Bunu kontrol etmenin en pratik yolu: bir ders çıkış saatini bekleyip tahtanın
kendiliğinden kilitlenmesini görmek. Zaman yoksa en azından okul yönetiminden
"çalışma saatleri girildi" teyidini alın ve Mebre'ye bildirin.

---

## Hata mesajları ve ne yapmalı

### Kurulum sırasında

| Ekranda yazan | Sebebi | Ne yapmalı |
|---|---|---|
| `Kurulum dosyaları eksik` | Paket düzgün çıkarılmamış | Paketi olduğu gibi yeniden çıkartın, dosyaları tek tek kopyalamayın |
| `Kurum kodu boş olamaz` | Enter'a boş basıldı | Kurum kodunu yazın |
| `Kurum kodu yalnızca rakam olmalı` | Harf/boşluk girilmiş | Sadece rakam yazın |
| `Kurulum kodu girilmedi` | 64 haneli kod istendi, girilmedi | Mebre'yi arayın, kodu isteyin |
| `/opt bölümünde yeterli yer yok` | Disk dolu | Tahtada yer açın |
| `gcc yok ve hazır derlenmiş dosya da yok` | İnternet yok, derleyici de yok | İnterneti bağlayıp tekrar deneyin |

### Tahta ekranında

| Ekranda yazan | Sebebi | Ne yapmalı |
|---|---|---|
| `Önce sağ tıklayıp şifrenizi değiştiriniz!` | Fabrika şifresi duruyor | Sağ tıklayıp şifreyi değiştirin (ADIM 4) |
| `Hata: Şifre yanlış!` | Şifre hatalı | Doğru şifreyi girin |
| `Hata: Kurulum dosyası eksik` | Tahtaya kurulum kodu gitmemiş | Kurulumu baştan yapın, kod dosyası klasörde olsun |
| `Kurulum kodu geçersiz (401)` | Elinizdeki paket eski | Mebre'yi arayın, güncel paketi isteyin |
| `Bu tahta bu kuruma ait değil (403)` | Kurum kodu yanlış | Kurum kodunu kontrol edin |
| `Sunucu yapılandırması eksik (500)` | Sunucu tarafında sorun | Mebre'yi arayın |
| `İnternet yok` | Ağ bağlantısı yok | Tahtanın internetini kontrol edin |
| `Güvenli bağlantı kurulamadı` | Okul ağı engelliyor | Okul BT sorumlusuyla görüşün |
| `Uyarı: Bu kurum için tahta bulunamadı` | Okulun tahtaları tanımlı değil | Okul yönetimi masaüstü programdan tahtaları tanımlasın |

### Kurulum sonrası görülen durumlar

| Belirti | Sebebi | Ne yapmalı |
|---|---|---|
| Tahta ders bitiminde kilitlenmiyor | Çalışma saatleri (ders programı) girilmemiş | Okul yönetimi masaüstünden girip veri göndersin (bkz. ADIM 5) |
| Duyurular gün boyu birikiyor, düşmüyor | Aynı sebep — tahta dersin ne zaman bittiğini bilmiyor | Aynı çözüm |
| Kilit ekranında hiçbir panel yok (aferin, doğum günü, duyuru) | Tahtanın adı hiçbir sınıf adıyla eşleşmiyor | Tahta adı sınıf adıyla birebir aynı olmalı ("5AC", "5-A"). Okulda o sınıfta öğrenci kaydı da olmalı |

---

## Yapılmaması gerekenler

**Paketi başkasıyla paylaşmayın.** WhatsApp'a, genel bir bağlantıya, e-postaya
koymayın. Zip şifresini de kurulum yapmayacak kişilere vermeyin.

**Masaüstü programdan kurulu tahtaları silmeyin.** Silerseniz o okuldaki tüm
tahtalar kilitli kalır ve her birine tek tek gidilmesi gerekir. Değiştirmek
istiyorsanız silmeyin, **düzenleyin**.

**Fabrika şifresini bırakmayın.** `803580` herkesin bildiği şifredir.

**Kurulumu yarıda kesmeyin.** Hata alırsanız baştan çalıştırın; kurulum
tekrarlanabilir, önceki ayarlar korunur.

---

## Sık sorulanlar

**Tahtaya daha önce kurulmuştu, yeniden kuruyorum. Kurulum kodu gerekir mi?**
Hayır. Tahta zaten tanıtılmışsa kimliği korunur, kod sorulmaz. Kurulum
"mevcut kimlik korunacak" yazar.

**Tahta formatlandı, baştan kuruyorum.**
Bu yeni tahta sayılır, kurulum kodu gerekir.

**Tahtanın adını/sınıfını değiştirmem gerekiyor.**
Kurulum yapmanıza gerek yok. Tahta ekranından yapılandırmayı açıp yeni tahtayı
seçmeniz yeterli.

**Kurulum çok uzun sürüyor.**
İlk kurulumda kod tahtada derleniyor olabilir, birkaç dakika sürer. Pakette
hazır dosya varsa saniyeler içinde biter.

**Aynı USB'yi başka tahtada kullanabilir miyim?**
Evet. Kurulum dosyaları USB'den silinmez.

---

## Kurulum bittiğinde Mebre'ye bildirin

- Okul adı ve kurum kodu
- Kaç tahta kuruldu, hangi sınıflar
- Belirlediğiniz yeni şifre
- Yaşadığınız sorun varsa ekran görüntüsüyle
