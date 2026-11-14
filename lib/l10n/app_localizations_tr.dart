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
  String get deleteAccount => 'Hesabımı sil';

  @override
  String get deleteAccountTitle => 'Hesabı sil';

  @override
  String get deleteAccountWhatTitle => 'Neler silinecek';

  @override
  String get deleteAccountDeletesProfile =>
      'Adın, e-postan, IBAN\'ın, şifren, bildirimlerin ve kayıtlı cihazların silinir.';

  @override
  String get deleteAccountLeavesHomes =>
      'Üye olduğun bütün evlerden ayrılırsın.';

  @override
  String get deleteAccountHouseholdsIntro =>
      'Evde tek başına kaldığın evler, içindeki tüm giderler ve ödemelerle birlikte tamamen silinir:';

  @override
  String get deleteAccountKeepsTitle => 'Neler kalacak';

  @override
  String get deleteAccountKeepsShared =>
      'Ev arkadaşlarınla birlikte yaptığın giderler ve ödemeler, onların bakiyelerinde kalır. Senin yerine adın “Silinmiş kullanıcı” olarak görünür, böylece hesapları bozulmaz.';

  @override
  String get deleteAccountIrreversible => 'Bu işlem geri alınamaz.';

  @override
  String get deleteAccountBlockedTitle => 'Hesabını henüz silemezsin';

  @override
  String blockerFounderWithMembers(String household) {
    return '$household: önce kuruculuğu devretmelisin';
  }

  @override
  String blockerLastAdminWithMembers(String household) {
    return '$household: önce başka birini yönetici yapmalısın';
  }

  @override
  String get blockerHint => 'Evi açıp Üyeler sekmesinden yapabilirsin.';

  @override
  String get openBalancesTitle => 'Açık bakiyelerin';

  @override
  String balanceOwesWarning(String household, String amount) {
    return '$household: $amount borcun var. Hesabını silsen de borç bakiyede kalır.';
  }

  @override
  String balanceGetsBackWarning(String household, String amount) {
    return '$household: $amount alacağın var. Silersen bu parayı uygulama üzerinden takip edemezsin.';
  }

  @override
  String get showPassword => 'Şifreyi göster';

  @override
  String get hidePassword => 'Şifreyi gizle';

  @override
  String get deleteAccountConfirmCheckbox =>
      'Bunun geri alınamayacağını anlıyorum';

  @override
  String get deleteAccountButton => 'Hesabımı kalıcı olarak sil';

  @override
  String get deleteAccountDone => 'Hesabın silindi. Seni özleyeceğiz 🧡';

  @override
  String get errorWrongPassword => 'Şifre yanlış.';

  @override
  String get errorDeleteAccountBlocked =>
      'Önce evlerindeki kuruculuğu devretmeli ya da yöneticilik yetkini bırakmalısın.';

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

  @override
  String get attachmentsTitle => 'Fiş ve belgeler';

  @override
  String get attachmentAdd => 'Ekle';

  @override
  String get attachmentMaxHint => 'En fazla 5 dosya';

  @override
  String get attachmentTakePhoto => 'Fotoğraf çek';

  @override
  String get attachmentPickGallery => 'Galeriden seç';

  @override
  String get attachmentPickPdf => 'PDF seç';

  @override
  String get attachmentEmpty => 'Henüz fiş yok';

  @override
  String get attachmentDeleteConfirm => 'Bu dosya silinsin mi?';

  @override
  String attachmentByline(String name, String date) {
    return '$name ekledi · $date';
  }

  @override
  String get attachmentNoApp =>
      'Bu telefonda dosyayı açabilecek bir uygulama yok.';

  @override
  String get attachmentCannotOpen => 'Dosya açılamadı.';

  @override
  String get attachmentsPendingHint =>
      'Gideri kaydettiğinde dosyalar yüklenecek.';

  @override
  String attachmentsUploadFailed(int count) {
    return '$count dosya yüklenemedi. Gideri düzenleyip tekrar ekleyebilirsin.';
  }

  @override
  String get paymentReceipts => 'Dekontlar';

  @override
  String get attachReceipt => 'Dekont ekle';

  @override
  String paymentAttachmentsUploadFailed(int count) {
    return 'Ödeme kaydedildi ama $count dosya yüklenemedi.';
  }

  @override
  String get paymentRecorded => 'Ödeme kaydedildi';

  @override
  String get errorAttachmentType =>
      'Yalnızca JPEG, PNG, WEBP görselleri ve PDF dosyaları eklenebilir.';

  @override
  String get errorAttachmentLimit =>
      'Buraya en fazla 5 dosya ekleyebilirsin. Önce birini silmelisin.';

  @override
  String get errorAttachmentTooLarge => 'Dosya çok büyük. Sınır 10 MB.';

  @override
  String get recurringExpenses => 'Tekrarlayan giderler';

  @override
  String get recurringExplainer =>
      'Bu giderler her ay kendiliğinden eklenir. Durdurmak için gideri açıp \'Her ay tekrarlanır\'ı kapat.';

  @override
  String get recurringEmpty =>
      'Henüz tekrarlayan gider yok. Kira ya da bir faturada \'Her ay tekrarlanır\'ı açarsan burada görünür.';

  @override
  String recurringAutoHint(int day) {
    return 'Her ay, ayın $day. günü otomatik eklenir';
  }

  @override
  String recurringDayInfo(int day) {
    return 'Her ay, ayın $day. günü';
  }

  @override
  String recurringNextDate(String date) {
    return 'Sonraki: $date';
  }

  @override
  String get recurringAutoTag => 'otomatik';

  @override
  String get recurringCheckNow => 'Şimdi kontrol et';

  @override
  String recurringRunAdded(int count) {
    return '$count gider eklendi';
  }

  @override
  String get recurringRunNone => 'Eklenecek gider yok';

  @override
  String get tabStatement => 'Döküm';

  @override
  String get statementThisMonth => 'Bu ay';

  @override
  String get statementPickRange => 'Tarih aralığı seç';

  @override
  String get statementPrevMonth => 'Önceki ay';

  @override
  String get statementNextMonth => 'Sonraki ay';

  @override
  String get statementTotalSpent => 'Toplam harcama';

  @override
  String statementExpenseCount(int count) {
    return '$count gider';
  }

  @override
  String statementPaymentCount(int count) {
    return '$count ödeme';
  }

  @override
  String get statementExpenseNumber => 'Gider sayısı';

  @override
  String get statementPaymentNumber => 'Ödeme sayısı';

  @override
  String get statementPaymentsTotal => 'Ödemeler';

  @override
  String statementDominantPayer(String name, String percent) {
    return 'Bu dönem ödemelerin %$percent\'ünü $name yaptı.';
  }

  @override
  String statementDominantPayerYou(String percent) {
    return 'Bu dönem ödemelerin %$percent\'ünü sen yaptın.';
  }

  @override
  String get statementWhoPaid => 'Kim ne kadar ödedi?';

  @override
  String statementShareLine(String share) {
    return 'Payı $share';
  }

  @override
  String statementNetLine(String net) {
    return 'Fark $net';
  }

  @override
  String get statementLeftTag => '(ayrıldı)';

  @override
  String get statementNoExpenses => 'Bu dönemde gider yok.';

  @override
  String get statementNoPayments => 'Bu dönemde ödeme yok.';

  @override
  String get statementCategories => 'Kategoriler';

  @override
  String get statementLastSixMonths => 'Son 6 ay';

  @override
  String get statementSharePdf => 'PDF olarak paylaş';

  @override
  String get statementPdfTitle => 'Evce — Hesap Dökümü';

  @override
  String get statementPdfSummary => 'Özet';

  @override
  String statementPdfPeriod(String period) {
    return 'Dönem: $period';
  }

  @override
  String statementPdfGenerated(String date) {
    return 'Oluşturulma: $date';
  }

  @override
  String statementPdfPage(int page, int total) {
    return 'Sayfa $page / $total';
  }

  @override
  String get statementColMember => 'Üye';

  @override
  String get statementColPaid => 'Ödedi';

  @override
  String get statementColShare => 'Payı';

  @override
  String get statementColNet => 'Fark';

  @override
  String get statementColFrom => 'Kimden';

  @override
  String get statementColTo => 'Kime';

  @override
  String get statementColDate => 'Tarih';

  @override
  String get statementColDescription => 'Açıklama';

  @override
  String get statementColCategory => 'Kategori';

  @override
  String get statementColPaidBy => 'Ödeyen';

  @override
  String get statementColAmount => 'Tutar';

  @override
  String get statementColNote => 'Not';

  @override
  String get pushChannelName => 'Evce bildirimleri';

  @override
  String get pushChannelDescription =>
      'Yeni gider, ödeme ve davet bildirimleri';

  @override
  String get notificationsTitle => 'Bildirimler';

  @override
  String get notificationsEmpty =>
      'Henüz yeni bir şey yok. Ev arkadaşların gider ya da ödeme ekledikçe burada göreceksin.';

  @override
  String get notificationsMarkAllRead => 'Tümünü okundu yap';

  @override
  String get notificationsGroupToday => 'Bugün';

  @override
  String get notificationsGroupYesterday => 'Dün';

  @override
  String get notificationsGroupEarlier => 'Daha önce';

  @override
  String get notificationsJustNow => 'Az önce';

  @override
  String notificationsMinutesAgo(int count) {
    return '$count dk önce';
  }

  @override
  String notificationsHoursAgo(int count) {
    return '$count sa önce';
  }

  @override
  String get notificationsNoAccess => 'Bu eve artık erişimin yok.';

  @override
  String get notificationGenericTitle => 'Bildirim';

  @override
  String notificationExpenseTitle(String household) {
    return 'Yeni gider · $household';
  }

  @override
  String notificationExpenseBody(String actor, String amount, String detail) {
    return '$actor, $detail için $amount ekledi';
  }

  @override
  String notificationExpenseBodyNoDetail(String actor, String amount) {
    return '$actor, $amount tutarında gider ekledi';
  }

  @override
  String notificationPaymentTitle(String household) {
    return 'Ödeme · $household';
  }

  @override
  String notificationPaymentBody(String payer, String receiver, String amount) {
    return '$payer → $receiver: $amount ödeme kaydedildi';
  }

  @override
  String notificationPaymentBodyNoTarget(String actor, String amount) {
    return '$actor $amount ödeme kaydetti';
  }

  @override
  String get notificationInvitationTitle => 'Yeni davet';

  @override
  String notificationInvitationBody(String actor, String household) {
    return '$actor seni bir eve davet etti: $household';
  }

  @override
  String notificationAcceptedTitle(String household) {
    return 'Yeni ev arkadaşı · $household';
  }

  @override
  String notificationAcceptedBody(String actor) {
    return '$actor davetini kabul etti';
  }

  @override
  String notificationRecurringTitle(String household) {
    return 'Tekrarlayan gider · $household';
  }

  @override
  String notificationRecurringBody(String detail, String amount) {
    return '$detail $amount bu ay da eklendi';
  }

  @override
  String notificationRecurringBodyNoDetail(String amount) {
    return '$amount tutarındaki gider bu ay da eklendi';
  }

  @override
  String get reminderButton => 'Hatırlat';

  @override
  String get reminderSentShort => 'Hatırlatıldı';

  @override
  String reminderCooldownToday(String time) {
    return 'Bugün $time\'da tekrar hatırlatabilirsin';
  }

  @override
  String reminderCooldownTomorrow(String time) {
    return 'Yarın $time\'da tekrar hatırlatabilirsin';
  }

  @override
  String reminderDialogBody(String name) {
    return '$name kişisine kibar bir hatırlatma bildirimi gönderilecek.';
  }

  @override
  String get reminderNoteHint => 'ör. acele yok, uygun olduğunda';

  @override
  String get reminderSend => 'Gönder';

  @override
  String get reminderSent => 'Hatırlatma gönderildi';

  @override
  String get errorReminderSelf => 'Kendini hatırlatamazsın.';

  @override
  String get errorReminderNoDebt =>
      'Bu kişinin sana borcu yok, liste güncellendi.';

  @override
  String get errorReminderCooldown =>
      'Bu kişiyi son 24 saatte zaten hatırlattın.';

  @override
  String notificationReminderTitle(String household) {
    return 'Hatırlatma · $household';
  }

  @override
  String notificationReminderBody(
    String actor,
    String amount,
    String household,
  ) {
    return '$actor nazikçe hatırlatıyor: $household evinde ona $amount borcun var.';
  }

  @override
  String notificationReminderNote(String note) {
    return 'Not: $note';
  }

  @override
  String notificationNoteLine(String note) {
    return 'Not: $note';
  }

  @override
  String notificationExpenseUpdatedTitle(String household) {
    return 'Gider düzenlendi · $household';
  }

  @override
  String notificationExpenseUpdatedBody(
    String actor,
    String detail,
    String change,
  ) {
    return '$actor \"$detail\" giderini düzenledi$change';
  }

  @override
  String notificationExpenseUpdatedBodyNoDetail(String actor, String change) {
    return '$actor bir gideri düzenledi$change';
  }

  @override
  String notificationPaymentUpdatedTitle(String household) {
    return 'Ödeme düzenlendi · $household';
  }

  @override
  String notificationPaymentUpdatedBody(String actor, String change) {
    return '$actor bir ödemeyi düzenledi$change';
  }

  @override
  String get historyTitle => 'Geçmiş';

  @override
  String get historyEmpty => 'Henüz kayıt yok';

  @override
  String get historyEmptyHint =>
      'Gider, ödeme ve üyelerle ilgili her ekleme, düzenleme ve silme; kimin yaptığı ve ne zaman yaptığıyla birlikte burada listelenecek.';

  @override
  String get historySharesHeading => 'Paylar';

  @override
  String get historyLoadMore => 'Daha fazla';

  @override
  String get historyUnknownName => 'Biri';

  @override
  String get historyExpenseFallback => 'gider';

  @override
  String get historyYes => 'Evet';

  @override
  String get historyNo => 'Hayır';

  @override
  String get historyRoleMember => 'Üye';

  @override
  String get historySharesChanged => 'Bölüşüm değişti';

  @override
  String get historyFieldAmount => 'Tutar';

  @override
  String get historyFieldDescription => 'Açıklama';

  @override
  String get historyFieldCategory => 'Kategori';

  @override
  String get historyFieldDate => 'Tarih';

  @override
  String get historyFieldPaidBy => 'Ödeyen';

  @override
  String get historyFieldFrom => 'Gönderen';

  @override
  String get historyFieldTo => 'Alan';

  @override
  String get historyFieldRecurring => 'Tekrarlayan';

  @override
  String get historyFieldSplitType => 'Bölüşüm türü';

  @override
  String get historyFieldNote => 'Not';

  @override
  String get historyFieldRole => 'Rol';

  @override
  String get historyFieldName => 'Ad';

  @override
  String historyHouseholdCreated(String actor) {
    return '$actor evi kurdu';
  }

  @override
  String historyHouseholdRenamed(String actor) {
    return '$actor evin adını değiştirdi';
  }

  @override
  String historyOwnershipTransferred(String actor, String subject) {
    return '$actor kuruculuğu $subject kişisine devretti';
  }

  @override
  String historyMemberJoined(String subject) {
    return '$subject eve katıldı';
  }

  @override
  String historyMemberLeft(String subject) {
    return '$subject evden ayrıldı';
  }

  @override
  String historyMemberRemoved(String actor, String subject) {
    return '$actor, $subject kişisini evden çıkardı';
  }

  @override
  String historyMemberRoleChanged(String actor, String subject) {
    return '$actor, $subject kişisinin rolünü değiştirdi';
  }

  @override
  String historyExpenseAdded(String actor, String label, String amount) {
    return '$actor \"$label\" giderini ekledi · $amount';
  }

  @override
  String historyExpenseUpdated(String actor, String label) {
    return '$actor \"$label\" giderini düzenledi';
  }

  @override
  String historyExpenseDeleted(String actor, String label, String amount) {
    return '$actor \"$label\" giderini sildi · $amount';
  }

  @override
  String historyRecurringGenerated(String label, String amount) {
    return 'Tekrarlayan gider eklendi: \"$label\" · $amount';
  }

  @override
  String historyPaymentAdded(
    String actor,
    String subject,
    String other,
    String amount,
  ) {
    return '$actor ödeme kaydetti: $subject → $other · $amount';
  }

  @override
  String historyPaymentUpdated(String actor, String subject, String other) {
    return '$actor bir ödemeyi düzenledi: $subject → $other';
  }

  @override
  String historyPaymentDeleted(
    String actor,
    String subject,
    String other,
    String amount,
  ) {
    return '$actor bir ödemeyi sildi: $subject → $other · $amount';
  }

  @override
  String historyGeneric(String actor) {
    return '$actor bir değişiklik yaptı';
  }

  @override
  String get tabChores => 'İşler';

  @override
  String get choresEmptyTitle => 'Henüz ev işi yok';

  @override
  String get choresEmptyBody =>
      'Çöp, bulaşık, temizlik gibi işleri ekle; sıra sizin aranızda kendiliğinden dönsün.';

  @override
  String get choresAdd => 'İş ekle';

  @override
  String choresTurnOf(String name) {
    return 'Sıra: $name';
  }

  @override
  String get choresTurnYou => 'Sıra sende';

  @override
  String get choresNobodyTurn => 'Sırada kimse yok';

  @override
  String choresLastDone(String name, String when) {
    return 'Son: $name · $when';
  }

  @override
  String get choresNotDoneYet => 'Henüz yapılmadı';

  @override
  String get choresHistory => 'Geçmiş';

  @override
  String get choresNoHistory => 'Henüz kayıt yok.';

  @override
  String get choresDone => 'Yaptım';

  @override
  String get choresDoneSnack => 'Yapıldı olarak işaretlendi, sıra ilerledi.';

  @override
  String choresDoneNotMyTurn(String name) {
    return 'Sıra $name kişisinde. Yine de yaptım olarak işaretlensin mi?';
  }

  @override
  String get choresRemind => 'Hatırlat';

  @override
  String choresRemindedToday(String time) {
    return 'Bugün $time\'da tekrar hatırlatabilirsin';
  }

  @override
  String choresRemindedTomorrow(String time) {
    return 'Yarın $time\'da tekrar hatırlatabilirsin';
  }

  @override
  String get choresDeleteConfirm => 'Bu iş silinsin mi?';

  @override
  String get choresDeleted => 'İş silindi';

  @override
  String get choresSaved => 'İş kaydedildi';

  @override
  String choresMinutesAgo(int count) {
    return '$count dk önce';
  }

  @override
  String choresHoursAgo(int count) {
    return '$count saat önce';
  }

  @override
  String get choresYesterday => 'dün';

  @override
  String choresDaysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String get choresFormNewTitle => 'Yeni iş';

  @override
  String get choresFormEditTitle => 'İşi düzenle';

  @override
  String get choresNameLabel => 'İş adı';

  @override
  String get choresNameRequired => 'İş adı yazın.';

  @override
  String get choresPeopleTitle => 'Kimler yapacak';

  @override
  String get choresPeopleHint =>
      'Kişileri işaretle, sonra sürükleyerek sırayı ayarla.';

  @override
  String get choresOrderTitle => 'Dönüş sırası';

  @override
  String get choresPickOne => 'En az bir kişi seçin.';

  @override
  String get choresNextUp => 'Sıradaki kişi';

  @override
  String get errorChoreLimit => 'Bir evde en fazla 20 iş olabilir.';

  @override
  String get errorChoreMembers => 'Sıradaki herkes evin aktif üyesi olmalı.';

  @override
  String get errorChoreOwnTurn => 'Sıra zaten sende.';

  @override
  String notificationChoreTitle(String household) {
    return 'İşler · $household';
  }

  @override
  String notificationChoreTurnBody(String actor, String detail) {
    return '$actor \"$detail\" işini yaptı, sıra sende.';
  }

  @override
  String notificationChoreReminderBody(String actor, String detail) {
    return '$actor nazikçe hatırlatıyor: \"$detail\" sırası sende.';
  }

  @override
  String historyChoreAdded(String actor, String label) {
    return '$actor \"$label\" işini ekledi';
  }

  @override
  String historyChoreUpdated(String actor, String label) {
    return '$actor \"$label\" işini düzenledi';
  }

  @override
  String historyChoreDeleted(String actor, String label) {
    return '$actor \"$label\" işini sildi';
  }

  @override
  String get historyRotationChanged => 'Sıra değişti';

  @override
  String get historyFieldRotation => 'Sıra';

  @override
  String get historyBefore => 'Önce';

  @override
  String get historyAfter => 'Sonra';

  @override
  String get historyFieldCurrentUser => 'Sıradaki';
}
