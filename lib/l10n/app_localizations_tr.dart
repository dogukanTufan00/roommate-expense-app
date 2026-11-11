// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Ev Giderleri';

  @override
  String get login => 'Giriş yap';

  @override
  String get register => 'Kayıt ol';

  @override
  String get name => 'Ad Soyad';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get noAccount => 'Hesabın yok mu? Kayıt ol';

  @override
  String get haveAccount => 'Zaten hesabın var mı? Giriş yap';

  @override
  String get registerSuccess =>
      'Hesabın oluşturuldu. Şimdi giriş yapabilirsin.';

  @override
  String get logout => 'Çıkış yap';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'Telefonun dili';

  @override
  String get households => 'Evlerim';

  @override
  String get noHouseholds =>
      'Henüz bir evin yok. Yeni bir ev oluştur ya da ev arkadaşından seni eklemesini iste.';

  @override
  String get createHousehold => 'Yeni ev';

  @override
  String get householdName => 'Ev adı';

  @override
  String get rename => 'Yeniden adlandır';

  @override
  String get delete => 'Sil';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get save => 'Kaydet';

  @override
  String get add => 'Ekle';

  @override
  String get deleteHouseholdConfirm =>
      'Bu ev, tüm giderleri ve ödemeleriyle birlikte silinsin mi? Bu işlem geri alınamaz.';

  @override
  String get tabExpenses => 'Giderler';

  @override
  String get tabBalances => 'Bakiye';

  @override
  String get tabMembers => 'Üyeler';

  @override
  String get addExpense => 'Gider ekle';

  @override
  String get editExpense => 'Gideri düzenle';

  @override
  String get amount => 'Tutar (₺)';

  @override
  String get category => 'Kategori';

  @override
  String get categoryRent => 'Kira';

  @override
  String get categoryUtilities => 'Faturalar';

  @override
  String get categoryGroceries => 'Market';

  @override
  String get categoryOther => 'Diğer';

  @override
  String get description => 'Açıklama (isteğe bağlı)';

  @override
  String get paidBy => 'Ödeyen';

  @override
  String get date => 'Tarih';

  @override
  String get recurring => 'Her ay tekrarlanır';

  @override
  String get noExpenses => 'Henüz gider yok.';

  @override
  String get deleteExpenseConfirm => 'Bu gider silinsin mi?';

  @override
  String paidByName(String name) {
    return '$name ödedi';
  }

  @override
  String get balancesTitle => 'Bakiyeler';

  @override
  String get settlementsTitle => 'Kim kime ödemeli';

  @override
  String get allSettled => 'Herkes ödeşmiş 🎉';

  @override
  String get getsBack => 'alacaklı';

  @override
  String get owes => 'borçlu';

  @override
  String get settled => 'ödeşmiş';

  @override
  String get markAsPaid => 'Ödendi olarak işaretle';

  @override
  String markAsPaidConfirm(String from, String to, String amount) {
    return '$from kişisinin $to kişisine $amount ödediği kaydedilsin mi?';
  }

  @override
  String get paymentsTitle => 'Ödeme geçmişi';

  @override
  String get noPayments => 'Henüz ödeme yok.';

  @override
  String get deletePaymentConfirm => 'Bu ödeme kaydı silinsin mi?';

  @override
  String get addMember => 'Üye ekle';

  @override
  String get memberEmailHint => 'Ev arkadaşının e-postası (hesabı olmalı)';

  @override
  String get removeMember => 'Evden çıkar';

  @override
  String removeMemberConfirm(String name) {
    return '$name evden çıkarılsın mı? Geçmiş giderleri ve borçları korunur.';
  }

  @override
  String get admin => 'Yönetici';

  @override
  String get you => 'sen';

  @override
  String get fieldRequired => 'Bu alan zorunlu';

  @override
  String get invalidEmail => 'Geçerli bir e-posta gir';

  @override
  String get passwordTooShort => 'En az 8 karakter olmalı';

  @override
  String get invalidAmount => '0\'dan büyük bir tutar gir';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get errorNetwork => 'Sunucuya ulaşılamıyor. API çalışıyor mu?';

  @override
  String get errorBadRequest => 'Bazı alanlar hatalı.';

  @override
  String get errorUnauthorized =>
      'Oturumun sona erdi, lütfen tekrar giriş yap.';

  @override
  String get errorWrongCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get errorForbidden => 'Bu işlem için yetkin yok.';

  @override
  String get errorNotFound => 'Bulunamadı, silinmiş olabilir.';

  @override
  String get errorEmailExists => 'Bu e-postayla zaten bir hesap var.';

  @override
  String get errorHouseholdFull => 'Ev dolu (en fazla 3 kişi).';

  @override
  String get errorAlreadyMember => 'Bu kişi zaten evin üyesi.';

  @override
  String get errorLastAdmin => 'Evin son yöneticisi evden çıkamaz.';

  @override
  String get errorNoSuchUser => 'Bu e-postayla kayıtlı hesap yok.';

  @override
  String get errorUnknown => 'Bir şeyler ters gitti.';
}
