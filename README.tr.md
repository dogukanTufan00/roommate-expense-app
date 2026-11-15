[English](README.md) | **Türkçe**

# Evce — Mobil Uygulama

Shared Expense Tracking System REST API'si için geliştirilmiş bir Flutter Android istemcisidir. Evce, ev arkadaşlarının ortak giderlerini kaydetmesine, kimin kime ne kadar borçlu olduğunu görmesine, ödemeleri kaydetmesine ve aylık özeti PDF olarak dışa aktarmasına yardımcı olur.
Backend [dogukanTufan00/shared-expense-tracking-system](https://github.com/dogukanTufan00/shared-expense-tracking-system) deposunda yer alır ve uygulamanın çalışması için çalışır durumda olmalıdır.

## Özellikler

- **Sıcak ve iki dilli arayüz.** Türkçe ve İngilizce. Uygulama varsayılan olarak telefonun dilini kullanır; dili uygulama içinden değiştirebilirsiniz. Seçiminiz kaydedilir.
- **Giriş yapma ve kayıt olma.** Uygulamayı kapatsanız bile oturumunuz açık kalır. Uygulama açılırken kayıtlı oturum belirtecinin (JWT) süresi kontrol edilir; süresi dolmuşsa yeniden giriş yapmanız istenir.
- **Evler ve davetler.** Evlerinizin listesi; davetleri kabul edebileceğiniz veya reddedebileceğiniz davet kartları. Üst çubuktaki bildirim simgesinde okunmamış bildirim sayısı görünür.
- **Ev ekranı, beş sekmeli:**
  - **Giderler:** Üstte, hâlâ alınacak ürün sayısını gösteren bir alışveriş listesi kartı bulunur. Karta dokunarak ortak listeyi açabilirsiniz: alınan ürünleri işaretleyip alınanları tek bir gider olarak kaydedebilirsiniz. Bunun altında "Yaklaşan ödemeler" kartı, yaklaşan faturaları listeler (en fazla üç tane, sonra "+N tane daha"). Giderler aylara göre gruplanır; filtrelenebilir ve arama kutusuyla aranabilir. Arama; açıklamayı, kategoriyi, ödeyeni, paylaşan kişilerin adlarını ve tutarı kontrol eder, Türkçe harf farklarını yok sayar (böylece "irmak" da "Irmak"ı bulur). Fiş eklenmiş giderler (ataş simgesi), tekrarlanan giderler ve otomatik oluşturulan giderler rozetlerle işaretlenir.
  - **Bakiyeler:** Kimin kime ne ödeyeceği; iki kişi arasındaki her borç için bir satır. Ödemeyi yalnızca ödeyen veya alan kişi ödendi olarak işaretleyebilir; yönetici ise yalnızca bu ikisinden biri evden ayrıldıysa işaretleyebilir. Alıcının IBAN'ını tek dokunuşla kopyalayabilir, QR kod olarak gösterebilir ve önerilen tutarla ödeme kaydedebilirsiniz (fazla ödeme yapılırsa uyarı verilir). Tek bir ödemeyi veya tüm özeti WhatsApp'a ya da başka bir uygulamaya gönderebilirsiniz. Alacaklı kişi "Hatırlat" düğmesine dokunarak borçluya nazik bir hatırlatma bildirimi gönderebilir; bu, 24 saatte bir yapılabilir. Ödeme ayrıntıları penceresinde fişler görüntülenir.
  - **İşler:** Çöp çıkarma, bulaşık gibi ev işleri; sırayla dönerek kendiliğinden ilerler. Işe katılan kişileri işaretleyip sıra düzenine sürükleyin. Bir iş "yapıldı" olarak işaretlendiğinde sıra ilerler; sırası gelen kişiye hatırlatma gönderebilirsiniz. Her işin kendi geçmişi tutulur.
  - **Özet:** Bir ay veya özel bir tarih aralığı seçerek kişi bazında çubukları, en çok ödeyen kişiyi, kategori dağılımını ve 6 aylık grafiği görebilirsiniz. Özet PDF olarak dışa aktarılabilir ve paylaşılabilir.
  - **Üyeler:** Kurucu ve yönetici simgeleri (açıklama balonlarıyla), e-posta ile davet, rol değiştirme, evin sahipliğini devretme, üye çıkarma (üyenin hâlâ açık borcu varsa uyarı gösterilir) ve evden ayrılma. Depozito kartı, evin depozitosunu ve her kişinin elinde tuttuğu tutarı gösterir; yöneticiler depozito aktarımını geri alabilir. Evden ayrılmak veya bir üyeyi çıkarmak, taşınma ekranını açar: kişinin depozito payı diğerlerine devredilir, açık borçları kapatılır ve sonra ev terk edilir.
- **Gider formu.** Gidere dahil edilecek üyeleri seçin ve paylaşım yöntemini belirleyin: Eşit, Yüzde veya Tutar. Varsayılan paylaşım oranları kaydedilip yeniden kullanılabilir. Gider tekrarlanacak şekilde işaretlenebilir; fişler kameradan, galeriden veya PDF dosyası olarak eklenebilir. Tekrarlanan giderler için bir fatura hatırlatması da seçebilirsiniz (yok, ya da vade tarihinden 1, 3 veya 7 gün önce); payı olan herkese bildirim gider.
- **Tekrarlanan giderler.** Tekrarlanan giderleri görüntüleyip yönetebileceğiniz ekran.
- **Varsayılan oranlar.** Her ev için varsayılan paylaşım oranlarını belirlediğiniz ekran.
- **Profil.** Adınızı değiştirin, IBAN bilginizi girin (doğrulanır) ve QR kod olarak gösterin, şifrenizi değiştirin ve görünümü seçin: Açık, Koyu veya Sistem. Seçiminiz cihazda kaydedilir.
- **Hesap silme.** Hesabınızı profilinizden silebilirsiniz. İlk ekran neyin olacağını açıklar. Tek üyesi siz olduğunuz evler, giderleri ve ödemeleriyle birlikte silinir. Başka üyeleri olan bir evin kurucusuysanız veya son yöneticisiyseniz, önce sahipliği devretmeniz ya da başka bir üyeyi yönetici yapmanız gerekir; bu yapılana kadar silme düğmesi kapalı kalır. Açık bakiyeler bir uyarı olarak gösterilir, çünkü hesap silmek bu borçları kapatmaz. Şifrenizi yazıp bunun geri alınamayacağını onaylarsınız. Ev arkadaşlarınızla birlikte yaptığınız giderler ve ödemeler, onların bakiyelerinde kalır; adınız "Silinmiş kullanıcı" olarak görünür.
- **Bildirimler.** Davetler, yeni giderler, kaydedilen ödemeler, tekrarlanan giderler, işlerde sıra bildirimleri ve ödeme veya iş hatırlatmaları dahil tüm bildirimleri gösteren ekran.
- **Push bildirimleri.** Firebase Cloud Messaging; uygulama açıkken, arka plandayken ve kapatıldıktan sonra çalışır. Bildirime dokunmak ilgili evi açar.
- **Geçmiş.** Bir evin üst çubuğundaki saat simgesi, o evin geçmişini açar: giderlerde, ödemelerde ve üyelerde yapılan her ekleme, düzenleme ve silme; en yeniden eskiye, kimin yaptığı, ne zaman ve neyin değiştiğiyle birlikte.

## Teknoloji Yığını

| Konu | Teknoloji |
|---|---|
| Çatı / dil | Flutter / Dart (Dart SDK `^3.13.5`, bkz. `pubspec.yaml`) |
| Arayüz | Material 3 ve özel sıcak tema (`lib/theme.dart`): açık modda terracotta, adaçayı yeşili, hardal ve krem paleti; koyu modda sıcak kahverengi bir palet (`AppPalette`), Nunito fontu, Gemini ile üretilen illüstrasyonlar |
| Durum yönetimi | `setState`, birkaç paylaşılan `ValueNotifier` ile (örneğin dil ve tema seçimi). Bilerek bir durum yönetimi kütüphanesi kullanılmamıştır: uygulama küçük olduğundan düz `setState` daha okunabilir ve bakımı daha kolaydır. |
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
| `share_plus` | ^13.3.1 | Bakiye özetini ve tek bir ödemeyi başka uygulamalarla (örneğin WhatsApp) paylaşır; IBAN QR kodunu paylaşır |
| `qr_flutter` | ^4.1.0 | IBAN'ı, bankacılık uygulamasının okuyabileceği bir QR koda dönüştürür |
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
│   ├── household_screen.dart         # Ev detayı ve beş sekme
│   ├── expenses_tab.dart, balances_tab.dart, chores_tab.dart, statement_tab.dart, members_tab.dart
│   ├── expense_form_screen.dart      # Gider ekleme veya düzenleme
│   ├── shopping_list_screen.dart     # Ortak alışveriş listesi, tek bir gidere dönüştürme
│   ├── chore_form_screen.dart        # İş ekleme veya düzenleme ve sıra düzeni
│   ├── deposit_form_screen.dart      # Evin depozitosunu ve her kişinin payını belirleme
│   ├── move_out_screen.dart          # Depozito devri, borçların kapatılması, ayrılma veya üye çıkarma
│   ├── history_screen.dart           # Bir evin geçmişi
│   ├── recurring_expenses_screen.dart
│   ├── split_defaults_screen.dart    # Varsayılan paylaşım oranları
│   ├── profile_screen.dart           # Ad, IBAN, şifre, görünüm
│   ├── delete_account_screen.dart    # Hesap silme; engeller ve açık bakiyeler
│   └── notifications_screen.dart
├── utils/
│   ├── avatar.dart, category.dart    # Üye avatarları, kategori kodları, etiketleri ve simgeleri
│   ├── split.dart, iban.dart         # Paylaşım hesapları, IBAN doğrulama
│   ├── bill_reminder.dart            # Hatırlatma seçenekleri ve vadeye kalan gün sayısı
│   ├── search.dart                   # Gider aramasında metin normalleştirme (Türkçe harfler)
│   ├── summary_text.dart             # Paylaşılabilir bakiye özetinin metni
│   ├── activity_text.dart            # Geçmişteki cümleler ve değişiklik satırları
│   ├── errors.dart                   # API hatalarını yerelleştirilmiş mesajlara çevirir
│   ├── format.dart                   # Geçerli dile göre para ve tarih biçimlendirme
│   ├── notification_text.dart        # Sunucu verisinden bildirim cümleleri oluşturur
│   └── statement_pdf.dart            # Gömülü Nunito fontlu özet PDF'i
├── widgets/
│   ├── language_menu_button.dart     # Uygulama çubuğundaki dil değiştirme menüsü
│   ├── attachments_section.dart      # Fiş listesi ve görüntüleyici
│   ├── deposit_card.dart             # Üyeler sekmesindeki depozito kartı
│   ├── iban_qr_sheet.dart            # IBAN'ın QR kodu, paylaşma seçeneğiyle
│   └── illustration.dart             # Illüstrasyonlar; koyu modda koyu sürümleriyle
├── config.dart            # API temel adresi (--dart-define ile ayarlanabilir)
├── models.dart            # fromJson fabrikalarına sahip veri sınıfları
├── session.dart           # Kayıtlı belirteç, giriş yapan kullanıcının e-postası, dil ve tema seçimi, JWT süre kontrolü
├── theme.dart             # Açık ve koyu renkler (AppColors, AppPalette), yazı tipleri ve bileşen temaları
└── main.dart              # Uygulama başlangıcı, tema ve giriş ile evler ekranı arasındaki yönlendirme
test/
└── summary_text_test.dart # Bakiye özeti metni için birim testi
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
- **Koyu mod temadan renk alır, sabit renk kullanmaz.** Uygulamada Açık, Koyu ve Sistem modları vardır. Ekranlar renklerini `context.palette` ile alır (örneğin `context.palette.muted`); bu, `lib/theme.dart` içindeki `AppPalette` tema uzantısının açık veya koyu setini döndürür.
- **Koyu illüstrasyonlar.** Her illüstrasyonun yanında koyu bir sürümü vardır (örneğin `empty-homes-dark.png`) ve illüstrasyonların arka planı saydamdır. Koyu sürüm yoksa açık dosya kullanılır.

> **Geliştirici notu:** Yeni arayüz kodu renklerini yalnızca açık temaya ait `AppColors` sabitlerinden değil, `context.palette`den almalıdır. `AppColors` doğrudan kullanılırsa ekran koyu modda yanlış görünür.

## Yol Haritası

- Uygun bir yayın imzalama yapılandırmasıyla Google Play sürümü
- HTTPS API'si ve düz HTTP trafiğinin kaldırılması
- Uygulamanın kablo olmadan çalışması için API'nin yayınlanması
- iOS desteği
- Çevrimdışı önbellek
- Otomatik testler (widget ve entegrasyon testleri)
