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
      'Bir ev kur ve ev arkadaşlarını davet et ya da bir davet gelmesini bekle.';

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
  String get markAsPaid => 'Ödeme kaydet';

  @override
  String markAsPaidConfirm(String from, String to) {
    return '$from kişisinin $to kişisine ödediği kaydedilsin mi?';
  }

  @override
  String get paymentsTitle => 'Ödeme geçmişi';

  @override
  String get noPayments =>
      'Henüz ödeme yok. Kapatılan borçlar burada görünecek.';

  @override
  String get deletePaymentConfirm => 'Bu ödeme kaydı silinsin mi?';

  @override
  String get inviteMember => 'Davet et';

  @override
  String get inviteMemberHint =>
      'Davet gönderilecek; kabul edince eve katılacak.';

  @override
  String get inviteMemberEmailHint =>
      'Ev arkadaşının e-postası (hesabı olmalı)';

  @override
  String get inviteSent => 'Davet gönderildi';

  @override
  String get pendingInvitesTitle => 'Bekleyen davetler';

  @override
  String get awaitingResponse => 'Yanıt bekleniyor';

  @override
  String get cancelInvitation => 'Daveti iptal et';

  @override
  String cancelInvitationConfirm(String name) {
    return '$name için gönderilen davet iptal edilsin mi?';
  }

  @override
  String get invitationCancelled => 'Davet iptal edildi';

  @override
  String get incomingInvitesTitle => 'Sana davet var';

  @override
  String invitedYou(String inviter) {
    return '$inviter seni bir eve davet etti';
  }

  @override
  String get acceptInvitation => 'Kabul et';

  @override
  String get declineInvitation => 'Reddet';

  @override
  String declineInvitationConfirm(String household) {
    return '$household davetini reddetmek istediğinden emin misin?';
  }

  @override
  String welcomeToHousehold(String household) {
    return '$household artık senin de evin, hoş geldin!';
  }

  @override
  String get invitationDeclined => 'Davet reddedildi';

  @override
  String get memberEmailHint => 'Ev arkadaşının e-postası (hesabı olmalı)';

  @override
  String get removeMember => 'Evden çıkar';

  @override
  String removeMemberConfirm(String name) {
    return '$name evden çıkarılsın mı? Geçmiş giderleri ve borçları korunur.';
  }

  @override
  String removeMemberOwesWarning(String name, String amount) {
    return 'Dikkat: $name henüz ödeşmedi, eve $amount borcu var. Çıkarsan da borcu bakiyede kalır; ödeme yapınca kaydedebilirsin.';
  }

  @override
  String removeMemberGetsBackWarning(String name, String amount) {
    return 'Dikkat: $name henüz ödeşmedi, evden $amount alacağı var. Çıkarsan da alacağı bakiyede kalır; ona ödeme yapınca kaydedebilirsin.';
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
  String get errorHouseholdFull => 'Ev dolu (davetler dahil en fazla 3 kişi).';

  @override
  String get errorAlreadyMember => 'Bu kişi zaten evin üyesi.';

  @override
  String get errorInvitationPending =>
      'Bu kişinin bu evle ilgili bekleyen bir daveti zaten var.';

  @override
  String get errorInvitationNotPending =>
      'Bu davet artık açık değil. İptal edilmiş ya da yanıtlanmış olabilir.';

  @override
  String get errorLastAdmin =>
      'Evin tek yöneticisi sensin. Önce başka bir üyeyi yönetici yap.';

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

  @override
  String get editPayment => 'Ödemeyi düzenle';

  @override
  String get edit => 'Düzenle';

  @override
  String get paymentNote => 'Not (isteğe bağlı)';

  @override
  String get paymentNoteHint => 'ör. havale ile ödendi';

  @override
  String paymentFromTo(String from, String to) {
    return '$from → $to';
  }

  @override
  String get paymentUpdated => 'Ödeme güncellendi';

  @override
  String get copyIban => 'IBAN\'ı kopyala';

  @override
  String get ibanCopied => 'IBAN kopyalandı';

  @override
  String get addIbanHint =>
      'IBAN\'ını profilinden ekleyebilirsin, böylece ev arkadaşların sana kolayca ödeme yapabilir.';

  @override
  String get makeAdmin => 'Yönetici yap';

  @override
  String get removeAdmin => 'Yöneticilikten al';

  @override
  String makeAdminConfirm(String name) {
    return '$name yönetici yapılsın mı? Yöneticiler davet edebilir, üye çıkarabilir ve oranları değiştirebilir.';
  }

  @override
  String removeAdminConfirm(String name) {
    return '$name kişisinin yönetici yetkisi alınsın mı?';
  }

  @override
  String get roleChanged => 'Rol güncellendi';

  @override
  String get memberOptions => 'Üye seçenekleri';

  @override
  String get leaveHome => 'Evden ayrıl';

  @override
  String get leaveHomeConfirm =>
      'Bu evden ayrılmak istediğinden emin misin? Geri dönmek için birinin seni yeniden davet etmesi gerekir.';

  @override
  String leaveHomeOwesWarning(String amount) {
    return 'Dikkat: henüz ödeşmedin, evde $amount borcun var. Ayrılsan da borcun bakiyede kalır; sonra ödeyebilirsin.';
  }

  @override
  String leaveHomeGetsBackWarning(String amount) {
    return 'Dikkat: henüz ödeşmedin, evden $amount alacağın var. Ayrılsan da alacağın bakiyede kalır; ev arkadaşların sonra ödeyebilir.';
  }

  @override
  String get profile => 'Profil';

  @override
  String get securityTitle => 'Güvenlik';

  @override
  String get iban => 'IBAN';

  @override
  String get ibanPlaceholder => 'TR00 0000 0000 0000 0000 0000 00';

  @override
  String get ibanHelper =>
      'İsteğe bağlı. Ev arkadaşların sana ödeme yapmak için kullanır.';

  @override
  String get ibanFormatHint => 'Türk IBAN\'ı TR ile başlar ve 26 karakterdir.';

  @override
  String get profileUpdated => 'Profilin güncellendi';

  @override
  String get changePassword => 'Şifreyi değiştir';

  @override
  String get currentPassword => 'Mevcut şifre';

  @override
  String get newPassword => 'Yeni şifre';

  @override
  String get repeatNewPassword => 'Yeni şifreyi tekrar yaz';

  @override
  String get passwordMismatch => 'Şifreler eşleşmiyor';

  @override
  String get passwordChanged => 'Şifren değiştirildi';

  @override
  String get errorInvalidIban =>
      'Bu IBAN doğru görünmüyor. Kontrol edip tekrar dene.';

  @override
  String get errorWrongCurrentPassword => 'Mevcut şifren yanlış.';

  @override
  String get founder => 'Kurucu';

  @override
  String get stepDownAdmin => 'Yöneticilikten çık';

  @override
  String get stepDownAdminConfirm =>
      'Yöneticilik yetkin alınsın mı? Evde üye olarak devam edersin.';

  @override
  String get transferOwnership => 'Kuruculuğu devret';

  @override
  String transferOwnershipConfirm(String name) {
    return '$name evin kurucusu olacak ve yönetici yapılacak. Sen yönetici olarak kalırsın.';
  }

  @override
  String transferOwnershipAdminConfirm(String name) {
    return '$name evin kurucusu olacak. Sen yönetici olarak kalırsın.';
  }

  @override
  String get ownershipTransferred => 'Kuruculuk devredildi';

  @override
  String get errorFounderProtected =>
      'Kurucunun rolünü ya da üyeliğini yalnızca kurucu değiştirebilir.';

  @override
  String get errorOnlyFounderTransfer =>
      'Kuruculuğu yalnızca kurucu devredebilir.';

  @override
  String get errorOnlyFounderDelete => 'Evi yalnızca kurucusu silebilir.';

  @override
  String suggestedAmount(String amount) {
    return 'Önerilen: $amount';
  }

  @override
  String overpaymentWarning(
    String from,
    String to,
    String owed,
    String amount,
  ) {
    return '$from kişisinin $to kişisine şu anki borcu $owed. $amount girdin; fazlası $to kişisinin $from kişisine borcu gibi görünecek. Yine de kaydedilsin mi?';
  }

  @override
  String overpaymentNoDebtWarning(String from, String to, String amount) {
    return '$from kişisinin $to kişisine şu anda borcu yok. $amount girdin; bu tutar $to kişisinin $from kişisine borcu gibi görünecek. Yine de kaydedilsin mi?';
  }

  @override
  String get saveAnyway => 'Yine de kaydet';

  @override
  String monthExpenseSummary(int count, String amount) {
    return '$count gider · $amount';
  }

  @override
  String get filterAll => 'Tümü';

  @override
  String get filterPaidByMe => 'Benim ödediklerim';

  @override
  String get filterInMyShare => 'Payım olanlar';

  @override
  String get noExpensesMatchFilter => 'Bu filtreye uyan gider yok';

  @override
  String get clearFilter => 'Filtreyi temizle';
}
