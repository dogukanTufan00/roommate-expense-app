[English](README.md) | **Türkçe**

# Evce — Mobil Uygulama

Ev arkadaşlarının ortak ev giderlerini kaydedip kimin kime ne kadar borçlu olduğunu görebildiği, Shared Expense Tracking System REST API'si için geliştirilmiş bir Flutter Android istemcisidir.
Backend [dogukanTufan00/shared-expense-tracking-system](https://github.com/dogukanTufan00/shared-expense-tracking-system) deposunda yer alır ve uygulamanın çalışması için çalışır durumda olmalıdır.

## Özellikler

- **Giriş yapma ve kayıt olma.** Uygulamayı kapatsanız bile oturumunuz açık kalır. API oturum belirteci (token) 24 saat geçerlidir; bu süre dolduğunda yeniden giriş yapmanız gerekir.
- **Evler.** Ev oluşturun, adını değiştirin ve silin.
- **Üyeler.** Ev yöneticisi, e-posta adresiyle bir ev arkadaşı ekleyebilir (ev arkadaşının bir hesabı olmalıdır) ve üyeleri çıkarabilir. Uygulama kendi kaydınızı "siz" etiketiyle, yöneticileri ise "Yönetici" rozetiyle gösterir.
- **Giderler.** Gider ekleyin, düzenleyin ve silin. Her gider için kategori (Kira, Faturalar, Market, Diğer), ödeyen kişi, tarih ve "her ay tekrarlanır" seçeneği belirlenebilir. Tutarlar hem `12,50` hem de `12.50` biçiminde girilebilir.
- **Bakiyeler.** Her üyenin net bakiyesini görün: ev kendisine borçlu mu, yoksa o mu eve borçlu.
- **Kim kime ödeyecek.** Herkesin borcunu kapatacak kısa bir ödeme önerisi listesi ve tek dokunuşla "Ödendi olarak işaretle" düğmesi.
- **Ödeme geçmişi.** Kaydedilmiş tüm ödemeleri görün ve yanlış girilen bir ödemeyi silin.
- **Türkçe ve İngilizce.** Arayüz varsayılan olarak telefonunuzun dilini kullanır. Dili uygulama içinden değiştirebilirsiniz.
- **Açık hata mesajları.** API hataları yerelleştirilmiş mesajlar olarak gösterilir; örneğin "Ev dolu (en fazla 3 kişi)."

## Teknoloji Yığını

| Konu | Teknoloji |
|---|---|
| Çatı / dil | Flutter / Dart |
| Arayüz | Material 3 ve özel sıcak tema (`lib/theme.dart`): terracotta, adaçayı yeşili, hardal ve krem paleti, Nunito fontu, Gemini ile üretilen illüstrasyonlar |
| HTTP | `http` |
| Yerel depolama | `shared_preferences` (belirteç ve dil seçimi) |
| Yerelleştirme | `intl` + `flutter_localizations`; ARB dosyalarından gen-l10n ile üretilir |
| Durum yönetimi | Yalnızca `setState`. Kodu sade tutmak için bilerek hiçbir durum yönetimi kütüphanesi kullanılmamıştır. |

## Proje Yapısı

```
lib/
├── api/
│   ├── api.dart           # API çağrılarının her biri için bir statik metot (evler, üyeler, giderler, ödemeler…)
│   └── api_client.dart    # Düşük seviyeli HTTP yardımcısı: temel adres, JSON, belirteç başlığı, hata işleme
├── l10n/                  # ARB çeviri dosyaları (app_en.arb, app_tr.arb) ve üretilen yerelleştirme sınıfları
├── screens/               # Giriş, kayıt, evler listesi, ev detayı (sekmeler), gider formu
├── utils/
│   ├── category.dart      # Kategori kodları, etiketleri ve simgeleri
│   ├── errors.dart        # API hatalarını yerelleştirilmiş mesajlara çevirir
│   └── format.dart        # Geçerli dile göre para ve tarih biçimlendirme
├── widgets/
│   └── language_menu_button.dart  # Uygulama çubuğundaki dil değiştirme menüsü
├── config.dart            # API temel adresi (--dart-define ile ayarlanabilir)
├── models.dart            # fromJson fabrikalarına sahip veri sınıfları
├── session.dart           # Kayıtlı belirteç, giriş yapan kullanıcının e-postası ve dil seçimi
└── main.dart              # Uygulama başlangıcı, tema ve giriş ile evler ekranı arasındaki yönlendirme
```

## Uygulamayı Çalıştırma

### Gereksinimler

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`pubspec.yaml` içindeki Dart SDK sürümü gereklidir)
- Android SDK (en kolay yol Android Studio ile kurmaktır); bir emülatör veya USB hata ayıklaması açık bir telefon
- `http://localhost:8080` adresinde çalışan backend API. Kurulum adımları için [backend README](https://github.com/dogukanTufan00/shared-expense-tracking-system#readme) dosyasına bakın.

Önce paketleri yükleyin:

```bash
flutter pub get
```

### Seçenek 1: Android emülatörü

Uygulama varsayılan olarak `http://10.0.2.2:8080` adresini kullanır. `10.0.2.2`, Android emülatörünün ana bilgisayara ulaşmak için kullandığı adrestir; böylece emülatör, bilgisayarınızda çalışan API'ye bağlanabilir.

```bash
flutter run
```

### Seçenek 2: USB ile fiziksel telefon

Telefonu USB kablosuyla bağlayın ve USB hata ayıklamayı açın. Ardından çalıştırın:

```bash
adb reverse tcp:8080 tcp:8080
flutter run --release --dart-define=API_BASE_URL=http://localhost:8080
```

`adb reverse`, telefondaki `localhost:8080` adresini bilgisayarınıza yönlendirir; bu nedenle Wi-Fi, IP adresi veya güvenlik duvarı ayarı gerekmez. Kabloyu yeniden taktıktan sonra `adb reverse` komutunu yeniden çalıştırın.

## Yol Haritası

- Bir gidere fiş, fatura veya dekont fotoğrafı ekleme
- Daha hızlı geri ödeme için IBAN bilgisi içeren kullanıcı profili
- Uygulamanın kablo olmadan çalışması için API'yi yayınlama
- Otomatik widget testleri
- Google Play sürümü
