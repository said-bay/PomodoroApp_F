# 🍅 Pomodoro Zamanlayıcı

Flutter ile geliştirilmiş modern ve kullanıcı dostu bir Pomodoro Zamanlayıcı uygulaması. Odaklanmanızı artırın ve üretkenliğinizi takip edin.

[Türkçe](README.md) | [English](README.en.md)

![Flutter Version](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green.svg)
![License](https://img.shields.io/badge/License-MIT-purple.svg)

## ✨ Özellikler

### Temel Özellikler
- 🕒 Özelleştirilebilir çalışma ve mola süreleri (1-180 dakika)
- 🌓 Koyu ve açık tema desteği
- 📊 Detaylı istatistikler ve ilerleme takibi
- 📝 Tüm çalışma oturumlarının geçmişi
- 🔔 Rahatsız etmeyen bildirimler
- 🎵 Oturum geçişlerinde ses uyarıları
- 📱 Yatay ve dikey mod desteği
- 🎯 Dikkat dağıtmayan saat modu

### Ek Özellikler
- 💪 Basit ve sezgisel arayüz
- 📈 Üretkenlik takibi için görsel istatistikler
- ⏸️ Duraklatma ve devam ettirme
- 🔄 Otomatik mola başlatma
- 🔍 Detaylı oturum geçmişi
- ⚡ Hızlı zamanlayıcı ayarı

## 🚀 Başlangıç

### Gereksinimler
- Flutter SDK (3.0 veya üzeri)
- Android Studio / Xcode
- Git

### Kurulum

1. Projeyi klonlayın
```bash
git clone https://github.com/said-bay/PomodoroApp_F.git
```

2. Proje dizinine gidin
```bash
cd PomodoroApp_F
```

3. Bağımlılıkları yükleyin
```bash
flutter pub get
```

4. Uygulamayı çalıştırın
```bash
flutter run
```

## 📱 Kullanım

1. **Zamanlayıcı Ayarı**
   - Süreyi ayarlamak için zamanlayıcıya dokunun
   - 1-180 dakika arasında süre seçin
   - Başlat düğmesi ile zamanlayıcıyı başlatın

2. **Oturum Sırasında**
   - Gerektiğinde duraklat/devam et
   - Kalan süreyi bildirim çubuğunda görüntüleyin
   - Odaklanmak için saat-modu'na geçin

3. **Geçmiş ve İstatistikler**
   - Geçmiş sekmesinde tamamlanan oturumları görüntüleyin
   - İstatistikler'de üretkenlik trendlerini kontrol edin
   - Geçmiş oturumları silin veya filtreleyin

4. **Ayarlar**
   - Koyu/açık tema geçişi
   - Bildirim davranışını özelleştirme
   - Sesleri açma/kapama
   - Otomatik başlatma seçenekleri

## 🛠️ Teknik Detaylar

### Mimari
- Provider pattern ile durum yönetimi
- Temiz mimari prensipleri
- Modüler ve sürdürülebilir kod yapısı

### Bağımlılıklar
```yaml
provider: ^6.0.0          # Durum yönetimi
awesome_notifications: ^0.8.3  # Yerel bildirimler
audioplayers: ^5.2.1      # Ses efektleri
shared_preferences: ^2.3.3 # Yerel depolama
wakelock_plus: ^1.2.8     # Ekran kilit kontrolü
```

## 📝 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır - detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 📞 İletişim

Ahmet Said Bay - [@github](https://github.com/said-bay)

Proje Bağlantısı: [https://github.com/said-bay/PomodoroApp_F](https://github.com/said-bay/PomodoroApp_F)
