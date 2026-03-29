# Fatih Client - Akıllı Tahta Kilit Sistemi

Bu proje, Pardus ETAP 23 işletim sistemi yüklü akıllı tahtaları merkezi bir sunucu üzerinden yönetmek, kilitlemek ve kontrol etmek için geliştirilmiş güvenlik yazılımıdır.

## Proje Hakkında

Fatih Client, akıllı tahtaların yetkisiz kullanımını engellemek amacıyla tasarlanmıştır. Sistem açıldığında otomatik olarak başlar, ekranı kilitler ve klavye/fare girişlerini devre dışı bırakır.

### Özellikler

- **Merkezi Yönetim:** MebreCep mobil uygulaması ile tahtaları kilitleme/açma
- **Dinamik Şifre:** Zamana dayalı otomatik şifre üretimi (öğretmen MebreCep'ten görür)
- **USB Anahtar Desteği:** Özel USB bellek ile fiziksel kilit açma
- **Otomatik Kilitleme:** USB çıkarıldığında veya ders bittiğinde otomatik kilitleme
- **Ders Programı:** Haftalık program desteği (giriş-çıkış saatleri)
- **Uzaktan Kontrol:** Kapatma, yeniden başlatma, mesaj gönderme
- **Gözetmen (Watchdog):** Uygulama kapanırsa otomatik yeniden başlatma

---

## Kurulum

### Yöntem 1: Tek Satır Kurulum (Önerilen)

Tahtada terminal açın ve aşağıdaki komutu çalıştırın:

```bash
curl -sL https://raw.githubusercontent.com/mehmet-han/Pardus_Tahta/main/install_from_github.sh | sudo bash
```

### Yöntem 2: ZIP Dosyası ile Kurulum

1. `Fatih_Client_Kurulum.zip` dosyasını USB belleğe kopyalayın
2. Tahtaya takın ve terminalde:

```bash
cd /media/etapadmin/USB_BELLEK
unzip Fatih_Client_Kurulum.zip
cd Fatih_Client_Kurulum
sudo bash setup.sh
```

### Yöntem 3: Web Sitesinden İndirme

[mebre.com.tr](https://mebre.com.tr) adresinden kurulum dosyasını indirin.

### Kurulum Sonrası

Kurulum tamamlandıktan sonra tahtayı **yeniden başlatın**:
```bash
sudo reboot
```

---

## Yönetim

Kurulumdan sonra yönetim menüsü için:
```bash
sudo ./fatih-manager.sh
```

Menü seçenekleri:
1. **Kur** - Tam kurulum (pre-login dahil)
2. **Kaldır** - Sistemi kaldır
3. **Başlat/Durdur/Yeniden Başlat** - Uygulama kontrolü
4. **Güncelle** - Git'ten güncel sürümü çek
5. **Logları Gör** - Hata ayıklama
6. **Durum** - Sistem durumunu kontrol et

---

## Yapılandırma

Her tahtanın sunucu tarafından tanınması için kurum kodu gereklidir. Kurulum sırasında sorulur veya sonradan yönetim panelinden ayarlanabilir.

---

## Kilit Yöntemleri

### 1. MebreCep Uygulaması (Önerilen)
Öğretmen telefonundaki MebreCep uygulamasından tahtayı açar/kilitler.

### 2. Dinamik Şifre
MebreCep uygulamasında gösterilen zamana dayalı 6 haneli şifre ile giriş.

### 3. USB Anahtar
Yetkili USB bellek ile fiziksel kilit açma (USB anahtarı yönetim panelinden temin edilir).

---

## Sorun Giderme

Log dosyaları:
```bash
# Ana log
cat ~/fatih_client.log

# Hata logları
cat /opt/fatih-client/logs/client.err.log

# Watchdog logları
cat /opt/fatih-client/logs/watchdog.log
```

---

## Sistem Gereksinimleri

- Pardus ETAP 23 (x86_64)
- İnternet bağlantısı (ilk kurulum için)
- Root/sudo yetkisi

---

## Lisans

Bu yazılım özel lisanslıdır. İzinsiz kopyalanması, dağıtılması veya tersine mühendislik yapılması yasaktır.

© 2025-2026 MebreCep - Tüm hakları saklıdır.