[English](README.md) | **Türkçe**

# Evce — Mobil Uygulama

Shared Expense Tracking System REST API'si için geliştirilmiş bir Flutter Android istemcisidir. Evce, ev arkadaşlarının ortak giderlerini kaydetmesine, kimin kime ne kadar borçlu olduğunu görmesine, ödemeleri kaydetmesine ve aylık özeti PDF olarak dışa aktarmasına yardımcı olur.
Backend [dogukanTufan00/shared-expense-tracking-system](https://github.com/dogukanTufan00/shared-expense-tracking-system) deposunda yer alır ve uygulamanın çalışması için çalışır durumda olmalıdır.

## Özellikler

- **Sıcak ve iki dilli arayüz.** Türkçe ve İngilizce. Uygulama varsayılan olarak telefonun dilini kullanır; dili uygulama içinden değiştirebilirsiniz. Seçiminiz kaydedilir.
- **Giriş yapma ve kayıt olma.** Uygulamayı kapatsanız bile oturumunuz açık kalır. Uygulama açılırken kayıtlı oturum belirtecinin (JWT) süresi kontrol edilir; süresi dolmuşsa yeniden giriş yapmanız istenir.
- **Evler ve davetler.** Evlerinizin listesi; davetleri kabul edebileceğiniz veya reddedebileceğiniz davet kartları. Üst çubuktaki bildirim simgesinde okunmamış bildirim sayısı görünür.
- **Ev ekranı, dört sekmeli:**
  - **Giderler:** Giderler aylara göre gruplanır ve filtrelenebilir. Fiş eklenmiş giderler (ataş simgesi), tekrarlanan giderler ve otomatik oluşturulan giderler rozetlerle işaretlenir.
  - **Bakiyeler:** Kendi durumunuz ve kimin kime ödeyeceği. Alıcının IBAN'ını tek dokunuşla kopyalayabilir, önerilen tutarla ödeme kaydedebilirsiniz (fazla ödeme yapılırsa uyarı verilir). Ödeme ayrıntıları penceresinde fişler görüntülenir.
  - **Özet:** Bir ay veya özel bir tarih aralığı seçerek kişi bazında çubukları, en çok ödeyen kişiyi, kategori dağılımını ve 6 aylık grafiği görebilirsiniz. Özet PDF olarak dışa aktarılabilir ve paylaşılabilir.
  - **Üyeler:** Kurucu ve yönetici simgeleri (açıklama balonlarıyla), e-posta ile davet, rol değiştirme, evin sahipliğini devretme, üye çıkarma (üyenin hâlâ açık borcu varsa uyarı gösterilir) ve evden ayrılma.
- **Gider formu.** Gidere dahil edilecek üyeleri seçin ve paylaşım yöntemini belirleyin: Eşit, Yüzde veya Tutar. Varsayılan paylaşım oranları kaydedilip yeniden kullanılabilir. Gider tekrarlanacak şekilde işaretlenebilir; fişler kameradan, galeriden veya PDF dosyası olarak eklenebilir.
- **Tekrarlanan giderler.** Tekrarlanan giderleri görüntüleyip yönetebileceğiniz ekran.
- **Varsayılan oranlar.** Her ev için varsayılan paylaşım oranlarını belirlediğiniz ekran.
- **Profil.** Adınızı değiştirin, IBAN bilginizi girin (doğrulanır) ve şifrenizi değiştirin.
- **Bildirimler.** Davetler, yeni giderler, kaydedilen ödemeler ve tekrarlanan giderler dahil tüm bildirimleri gösteren ekran.
- **Push bildirimleri.** Firebase Cloud Messaging; uygulama açıkken, arka plandayken ve kapatıldıktan sonra çalışır. Bildirime dokunmak ilgili evi açar.

## Teknoloji Yığını

| Konu | Teknoloji |
|---|---|
| Çatı / dil | Flutter / Dart (Dart SDK `^3.13.5`, bkz. `pubspec.yaml`) |
| Arayüz | Material 3 ve özel sıcak tema (`lib/theme.dart`): terracotta, adaçayı yeşili, hardal ve krem paleti, Nunito fontu, Gemini ile üretilen illüstrasyonlar |
| Durum yönetimi | `setState`, birkaç paylaşılan `ValueNotifier` ile (örneğin dil seçimi). Bilerek bir durum yönetimi kütüphanesi kullanılmamıştır: uygulama küçük olduğundan düz `setState` daha okunabilir ve bakımı daha kolaydır. |
| Backend | REST API (Spring Boot), bkz. [backend deposu](https://github.com/dogukanTufan00/shared-expense-tracking-system) |

### Paketler

| Paket | Sürüm | Amacı |
|---|---|---|
| `http` | ^1.6.0 | REST API çağrıları |
| `shared_preferences` | ^2.5.6 | Giriş belirtecini ve dil seçimini cihazda saklar |
| `intl` | any | Geçerli dile göre para ve tarih biçimlendirme |
| `flutter_localizations` | SDK | Flutter'ın kendi çevirileri (iletişim kutuları, seçiciler vb.) |
| `image_picker` | ^1.2.4 | Kamerayla fiş fotoğrafı çeker veya galeriden seçer |
| `file_picker` | ^13.3.3 | Dosya sisteminden PDF fişleri seçer |
| `open_filex` | ^5.0.0 | İndirilen fişi veya özeti telefondaki bir uygulamayla açar |
| `path_provider` | ^2.1.6 | Dosyaların açılmadan veya paylaşılmadan önce kaydedileceği klasörleri bulur |
| `pdf` | ^3.13.1 | Aylık özet PDF'ini cihazda oluşturur |
| `printing` | ^5.15.1 | Oluşturulan PDF'i paylaşır veya yazdırır |
| `firebase_core` | ^5.1.0 | Uygulamada Firebase'i başlatır |
| `firebase_messaging` | ^17.0.1 | Push bildirimlerini alır ve cihazın FCM belirtecini verir |
| `flutter_local_notifications` | ^23.0.1 | Uygulama açıkken push bildirimlerini gösterir ve bildirime dokunuşları yönetir |
| `flutter_launcher_icons` (geliştirme) | ^0.14.4 | Android uygulama simgesini tüm boyutlarda üretir |
| `flutter_native_splash` (geliştirme) | ^2.4.8 | Uygulama simgesiyle krem renkli açılış ekranını üretir |

## Proje Yapısı

```
lib/
├── api/
│   ├── api.dart           # API çağrılarının her biri için bir statik metot (evler, üyeler, giderler, ödemeler, bildirimler…)
│   └── api_client.dart    # Düşük seviyeli HTTP yardımcısı: temel adres, JSON, belirteç başlığı, hata işleme
├── l10n/                  # ARB çeviri dosyaları (app_en.arb, app_tr.arb) ve üretilen yerelleştirme sınıfları
├── push/
│   └── push_service.dart  # Firebase kurulumu, push gösterimi, bildirime dokununca yönlendirme, cihaz belirteci kaydı
├── screens/
│   ├── login_screen.dart, register_screen.dart
│   ├── households_screen.dart        # Ev listesi, davet kartları, bildirim simgesi
│   ├── household_screen.dart         # Ev detayı ve dört sekme
│   ├── expenses_tab.dart, balances_tab.dart, statement_tab.dart, members_tab.dart
│   ├── expense_form_screen.dart      # Gider ekleme veya düzenleme
│   ├── recurring_expenses_screen.dart
│   ├── split_defaults_screen.dart    # Varsayılan paylaşım oranları
│   ├── profile_screen.dart           # Ad, IBAN, şifre
│   └── notifications_screen.dart
├── utils/
│   ├── avatar.dart, category.dart    # Üye avatarları, kategori kodları, etiketleri ve simgeleri
│   ├── split.dart, iban.dart         # Paylaşım hesapları, IBAN doğrulama
│   ├── errors.dart                   # API hatalarını yerelleştirilmiş mesajlara çevirir
│   ├── format.dart                   # Geçerli dile göre para ve tarih biçimlendirme
│   ├── notification_text.dart        # Sunucu verisinden bildirim cümleleri oluşturur
│   └── statement_pdf.dart            # Gömülü Nunito fontlu özet PDF'i
├── widgets/
│   ├── language_menu_button.dart     # Uygulama çubuğundaki dil değiştirme menüsü
│   ├── attachments_section.dart      # Fiş listesi ve görüntüleyici
│   └── illustration.dart             # Sıcak temalı ekranlarda kullanılan illüstrasyonlar
├── config.dart            # API temel adresi (--dart-define ile ayarlanabilir)
├── models.dart            # fromJson fabrikalarına sahip veri sınıfları
├── session.dart           # Kayıtlı belirteç, giriş yapan kullanıcının e-postası, dil seçimi, JWT süre kontrolü
├── theme.dart             # Renkler, yazı tipleri ve bileşen temaları
└── main.dart              # Uygulama başlangıcı, tema ve giriş ile evler ekranı arasındaki yönlendirme
```

## Uygulamayı Çalıştırma

### Gereksinimler

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`pubspec.yaml` içindeki Dart SDK sürümü gereklidir)
- Android SDK (en kolay yol Android Studio ile kurmaktır); bir emülatör veya USB hata ayıklaması açık bir telefon
- `http://localhost:8080` adresinde çalışan backend API. Kurulum adımları için [backend README](https://github.com/dogukanTufan00/shared-expense-tracking-system#readme) dosyasına bakın. **Önce backend'i başlatın.**
- Firebase yapılandırma dosyası (bkz. [Push Bildirimleri](#push-bildirimleri)). Bu dosya olmadan Android derlemesi başarısız olur.

> **Not (Android derlemesi):** Proje yolu yalnızca ASCII karakterlerden oluşmalıdır. Türkçe karakter içeren bir yol (örneğin `ı`, `ş` veya `ğ` içeren bir klasör adı) Android derlemesini bozabilir. Projeyi `C:\dev\roommate-expense-app` gibi bir yolda tutun.

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
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

`adb reverse`, telefondaki `localhost:8080` adresini bilgisayarınıza yönlendirir; bu nedenle Wi-Fi, IP adresi veya güvenlik duvarı ayarı gerekmez. Kabloyu yeniden taktıktan sonra `adb reverse` komutunu yeniden çalıştırın.

### Yayın derlemesi

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example.com
```

Yayın derlemesi şu anda hata ayıklama anahtarıyla imzalanmaktadır ve manifest, yerel geliştirme için düz HTTP trafiğine izin vermektedir. Herkese açık bir sürümden önce HTTPS'e geçilmeli, `usesCleartextTraffic` kaldırılmalı ve bir yayın imzalama yapılandırması eklenmelidir.

## Push Bildirimleri

Push bildirimleri Firebase Cloud Messaging ile çalışır (`firebase_core`, `firebase_messaging`, `flutter_local_notifications`). Android derlemesi Google services eklentisini uygular; bu nedenle **Firebase yapılandırma dosyası olmadan uygulama derlenmez**, push kullanmasanız bile. Her geliştirici bir kez şunları yapar:

1. [Firebase konsolunda](https://console.firebase.google.com) bir proje oluşturun.
2. Paket adı `com.dogukan_tufan.roommate_expense_app` olan bir Android uygulaması ekleyin.
3. `google-services.json` dosyasını indirip `android/app/` klasörüne koyun.

`android/app/google-services.json` dosyası `.gitignore` içindedir, çünkü her Firebase projesine özeldir. Her geliştirici kendi kopyasını indirir ve bu dosyayı asla commit etmez.

## Tasarım Notları

- **Sunucu veri gönderir, metni uygulama oluşturur.** API yalnızca gerçekleri döndürür (kim ne yaptı, ne kadar, hangi ev). Bildirim cümlelerini uygulama geçerli dilde oluşturur (`lib/utils/notification_text.dart`); böylece metinler Türkçe ve İngilizcede tutarlı kalır.
- **Ekler sunucudan gelir.** Fişler açıldığında API'den alınır. İndirilen veriler yalnızca bellekte (RAM) tutulur, diske yazılmaz; bu nedenle uygulama kapandığında silinirler.
- **PDF'ler cihazda üretilir.** Özet PDF'i, telefonda `pdf` paketi ve gömülü Nunito fontu kullanılarak oluşturulur; böylece Türkçe karakterler (ç, ğ, ı, ö, ş, ü) ve ₺ işareti doğru yazdırılır.

## Yol Haritası

- Uygun bir yayın imzalama yapılandırmasıyla Google Play sürümü
- HTTPS API'si ve düz HTTP trafiğinin kaldırılması
- Uygulamanın kablo olmadan çalışması için API'nin yayınlanması
- iOS desteği
- Çevrimdışı önbellek
- Otomatik testler (widget ve entegrasyon testleri)
