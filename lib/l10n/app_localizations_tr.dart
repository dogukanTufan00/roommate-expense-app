// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Evce';

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
  String get registerSuccess => 'Aramıza hoş geldin! Şimdi giriş yapabilirsin.';

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
      'Bir ev kur ve ev arkadaşlarını davet et ya da ev arkadaşından seni eklemesini iste.';

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
  String get noExpenses => 'Kira günü gelince burası dolar 🙂';

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
  String get allSettled => 'Hesaplar temiz, kimse kimseye borçlu değil 🎉';

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
  String get noPayments =>
      'Henüz ödeme yok. Kapatılan borçlar burada görünecek.';

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

  @override
  String get loginTagline => 'Ortak ev, adil hesap.';

  @override
  String get summaryTitle => 'Senin durumun';

  @override
  String get summaryGetsBack => 'Ev arkadaşların sana borçlu';

  @override
  String get summaryOwes => 'Ev arkadaşlarına borçlusun';

  @override
  String get summarySettled =>
      'Hesabın temiz. Kimseye borcun yok, kimsenin sana borcu yok.';

  @override
  String get noHouseholdsTitle => 'Henüz bir evin yok';

  @override
  String get noExpensesTitle => 'Henüz gider yok';

  @override
  String get splitTitle => 'Kimler paylaşıyor?';

  @override
  String get splitEqual => 'Eşit';

  @override
  String get splitPercent => 'Yüzde';

  @override
  String get splitAmount => 'Tutar';

  @override
  String splitRemainingPercent(String value) {
    return 'Kalan: %$value';
  }

  @override
  String splitRemainingAmount(String value) {
    return 'Kalan: $value';
  }

  @override
  String get splitNotBalanced =>
      'Paylar tam olarak tamamlanmadan kaydedemezsin.';

  @override
  String get splitNoneSelected => 'En az bir kişi seçili kalmalı.';

  @override
  String get splitInvalidValue => 'Geçerli bir değer gir (en fazla 2 ondalık).';

  @override
  String get splitDefaultApplied =>
      'Evin varsayılan oranı uygulandı. İstersen değiştirebilirsin.';

  @override
  String splitFormerMembers(String names) {
    return '$names evden ayrıldı, paylaşımdan çıkarıldı. Kaydetmeden önce payları yeniden dağıtmalısın.';
  }

  @override
  String yourShare(String amount) {
    return 'Payın: $amount';
  }

  @override
  String get notInSplit => 'Sana pay düşmüyor';

  @override
  String get customAmounts => 'Özel tutarlar';

  @override
  String get splitDefaults => 'Varsayılan oranlar';

  @override
  String get splitDefaultsIntro =>
      'Burada belirlediğin oran, o kategoride gider eklerken otomatik gelir. Sadece aynı kişiler evde yaşadığı sürece geçerli.';

  @override
  String get splitDefaultsReadOnly =>
      'Oranları yalnızca yönetici değiştirebilir.';

  @override
  String get splitEqualSplit => 'Eşit bölünür';

  @override
  String get removeDefault => 'Varsayılanı kaldır';

  @override
  String get errorInvalidSplit =>
      'Paylaşım geçerli değil. Payları kontrol edip tekrar dene.';

  @override
  String get movedOutTag => 'evden ayrıldı';

  @override
  String get changeSplit => 'Bölüşümü değiştir';

  @override
  String get splitAmountChanged =>
      'Tutarı değiştirdin, o yüzden tutar bazlı bölüşümü de ayarlamalısın.';
}
