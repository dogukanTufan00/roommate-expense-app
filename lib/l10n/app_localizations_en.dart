// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Evce';

  @override
  String get login => 'Log in';

  @override
  String get register => 'Sign up';

  @override
  String get name => 'Full name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get noAccount => 'Don\'t have an account? Sign up';

  @override
  String get haveAccount => 'Already have an account? Log in';

  @override
  String get registerSuccess => 'Welcome aboard! You can log in now.';

  @override
  String get logout => 'Log out';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Phone language';

  @override
  String get households => 'My homes';

  @override
  String get noHouseholds =>
      'Create a home and invite your roommates, or wait for an invitation.';

  @override
  String get createHousehold => 'New home';

  @override
  String get householdName => 'Home name';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get deleteHouseholdConfirm =>
      'Delete this home with all its expenses and payments? This cannot be undone.';

  @override
  String get tabExpenses => 'Expenses';

  @override
  String get tabBalances => 'Balances';

  @override
  String get tabMembers => 'Members';

  @override
  String get addExpense => 'Add expense';

  @override
  String get editExpense => 'Edit expense';

  @override
  String get amount => 'Amount (₺)';

  @override
  String get category => 'Category';

  @override
  String get categoryRent => 'Rent';

  @override
  String get categoryUtilities => 'Bills';

  @override
  String get categoryGroceries => 'Groceries';

  @override
  String get categoryOther => 'Other';

  @override
  String get description => 'Description (optional)';

  @override
  String get paidBy => 'Paid by';

  @override
  String get date => 'Date';

  @override
  String get recurring => 'Repeats every month';

  @override
  String get noExpenses => 'Rent day will fill this up soon 🙂';

  @override
  String get deleteExpenseConfirm => 'Delete this expense?';

  @override
  String paidByName(String name) {
    return 'Paid by $name';
  }

  @override
  String get balancesTitle => 'Balances';

  @override
  String get settlementsTitle => 'Who pays whom';

  @override
  String get allSettled => 'All square, nobody owes anybody 🎉';

  @override
  String get getsBack => 'gets back';

  @override
  String get owes => 'owes';

  @override
  String get settled => 'settled up';

  @override
  String get markAsPaid => 'Record payment';

  @override
  String markAsPaidConfirm(String from, String to) {
    return 'Record that $from paid $to?';
  }

  @override
  String get paymentsTitle => 'Payment history';

  @override
  String get noPayments => 'No payments yet. Settled debts will show up here.';

  @override
  String get deletePaymentConfirm => 'Delete this payment record?';

  @override
  String get inviteMember => 'Invite';

  @override
  String get inviteMemberHint =>
      'Invitation will be sent. They join the home once they accept.';

  @override
  String get inviteMemberEmailHint =>
      'Roommate\'s email (they need an account)';

  @override
  String get inviteSent => 'Invitation sent';

  @override
  String get pendingInvitesTitle => 'Pending invitations';

  @override
  String get awaitingResponse => 'Waiting for reply';

  @override
  String get cancelInvitation => 'Cancel invitation';

  @override
  String cancelInvitationConfirm(String name) {
    return 'Cancel the invitation for $name?';
  }

  @override
  String get invitationCancelled => 'Invitation cancelled';

  @override
  String get incomingInvitesTitle => 'You\'ve been invited';

  @override
  String invitedYou(String inviter) {
    return '$inviter invited you to a home';
  }

  @override
  String get acceptInvitation => 'Accept';

  @override
  String get declineInvitation => 'Decline';

  @override
  String declineInvitationConfirm(String household) {
    return 'Decline the invitation to $household?';
  }

  @override
  String welcomeToHousehold(String household) {
    return 'Welcome to $household!';
  }

  @override
  String get invitationDeclined => 'Invitation declined';

  @override
  String get memberEmailHint => 'Roommate\'s email (they need an account)';

  @override
  String get removeMember => 'Remove from home';

  @override
  String removeMemberConfirm(String name) {
    return 'Remove $name from this home? Their past expenses and debts are kept.';
  }

  @override
  String removeMemberOwesWarning(String name, String amount) {
    return 'Heads up: $name hasn\'t settled up and still owes $amount. If you remove them, the debt stays in the balances and you can record their payment later.';
  }

  @override
  String removeMemberGetsBackWarning(String name, String amount) {
    return 'Heads up: $name hasn\'t settled up and is still owed $amount. If you remove them, it stays in the balances and you can record your payment to them later.';
  }

  @override
  String get admin => 'Admin';

  @override
  String get you => 'you';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get passwordTooShort => 'Must be at least 8 characters';

  @override
  String get invalidAmount => 'Enter an amount greater than 0';

  @override
  String get retry => 'Try again';

  @override
  String get errorNetwork => 'Cannot reach the server. Is the API running?';

  @override
  String get errorBadRequest => 'Some fields are invalid.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Please log in again.';

  @override
  String get errorWrongCredentials => 'Wrong email or password.';

  @override
  String get errorForbidden => 'You don\'t have permission to do this.';

  @override
  String get errorNotFound => 'Not found. It may have been deleted.';

  @override
  String get errorEmailExists => 'An account with this email already exists.';

  @override
  String get errorHouseholdFull =>
      'This home is full (max 3 people, invitations included).';

  @override
  String get errorAlreadyMember => 'This person is already a member.';

  @override
  String get errorInvitationPending =>
      'This person already has an open invitation to this home.';

  @override
  String get errorInvitationNotPending =>
      'This invitation is no longer open. It may have been cancelled or answered.';

  @override
  String get errorLastAdmin =>
      'You are the last admin. Make another member an admin first.';

  @override
  String get errorNoSuchUser => 'No account with this email.';

  @override
  String get errorUnknown => 'Something went wrong.';

  @override
  String get loginTagline => 'Shared home, fair shares.';

  @override
  String get summaryTitle => 'Your balance';

  @override
  String get summaryGetsBack => 'Your roommates owe you';

  @override
  String get summaryOwes => 'You owe your roommates';

  @override
  String get summarySettled =>
      'You\'re all square. Nobody owes you, you owe nobody.';

  @override
  String get noHouseholdsTitle => 'No home yet';

  @override
  String get noExpensesTitle => 'No expenses yet';

  @override
  String get splitTitle => 'Who shares this?';

  @override
  String get splitEqual => 'Equal';

  @override
  String get splitPercent => 'Percent';

  @override
  String get splitAmount => 'Amount';

  @override
  String splitRemainingPercent(String value) {
    return 'Remaining: %$value';
  }

  @override
  String splitRemainingAmount(String value) {
    return 'Remaining: $value';
  }

  @override
  String get splitNotBalanced =>
      'Shares must add up exactly before you can save.';

  @override
  String get splitNoneSelected => 'At least one person must stay selected.';

  @override
  String get splitInvalidValue => 'Enter a valid value (up to 2 decimals).';

  @override
  String get splitDefaultApplied =>
      'The home\'s default ratio was applied. You can still change it.';

  @override
  String splitFormerMembers(String names) {
    return '$names moved out and was removed from this split. Redistribute the shares to save.';
  }

  @override
  String yourShare(String amount) {
    return 'Your share: $amount';
  }

  @override
  String get notInSplit => 'Not part of this split';

  @override
  String get customAmounts => 'Custom amounts';

  @override
  String get splitDefaults => 'Default ratios';

  @override
  String get splitDefaultsIntro =>
      'The ratio set here is pre-filled when you add an expense in that category. It only applies while the same people live in the house.';

  @override
  String get splitDefaultsReadOnly => 'Only admins can change the ratios.';

  @override
  String get splitEqualSplit => 'Split equally';

  @override
  String get removeDefault => 'Remove default';

  @override
  String get errorInvalidSplit =>
      'The split is not valid. Check the shares and try again.';

  @override
  String get movedOutTag => 'moved out';

  @override
  String get changeSplit => 'Change split';

  @override
  String get splitAmountChanged =>
      'You changed the amount, so the amount split needs adjusting too.';

  @override
  String get editPayment => 'Edit payment';

  @override
  String get edit => 'Edit';

  @override
  String get paymentNote => 'Note (optional)';

  @override
  String get paymentNoteHint => 'e.g. paid by bank transfer';

  @override
  String paymentFromTo(String from, String to) {
    return '$from → $to';
  }

  @override
  String get paymentUpdated => 'Payment updated';

  @override
  String get copyIban => 'Copy IBAN';

  @override
  String get ibanCopied => 'IBAN copied';

  @override
  String get addIbanHint =>
      'Add your IBAN in your profile so roommates can pay you easily.';

  @override
  String get makeAdmin => 'Make admin';

  @override
  String get removeAdmin => 'Remove admin role';

  @override
  String makeAdminConfirm(String name) {
    return 'Make $name an admin? Admins can invite and remove members and change the ratios.';
  }

  @override
  String removeAdminConfirm(String name) {
    return 'Remove admin rights from $name?';
  }

  @override
  String get roleChanged => 'Role updated';

  @override
  String get memberOptions => 'Member options';

  @override
  String get leaveHome => 'Leave home';

  @override
  String get leaveHomeConfirm =>
      'Leave this home? Someone has to invite you again to come back.';

  @override
  String leaveHomeOwesWarning(String amount) {
    return 'Heads up: you haven\'t settled up and still owe $amount. If you leave, the debt stays in the balances and you can pay it later.';
  }

  @override
  String leaveHomeGetsBackWarning(String amount) {
    return 'Heads up: you haven\'t settled up and are still owed $amount. If you leave, it stays in the balances and your roommates can pay you later.';
  }

  @override
  String get profile => 'Profile';

  @override
  String get securityTitle => 'Security';

  @override
  String get iban => 'IBAN';

  @override
  String get ibanPlaceholder => 'TR00 0000 0000 0000 0000 0000 00';

  @override
  String get ibanHelper => 'Optional. Roommates use it to pay you.';

  @override
  String get ibanFormatHint =>
      'A Turkish IBAN starts with TR and has 26 characters.';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get repeatNewPassword => 'Repeat new password';

  @override
  String get passwordMismatch => 'The passwords don\'t match';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get errorInvalidIban =>
      'This IBAN doesn\'t look right. Check it and try again.';

  @override
  String get errorWrongCurrentPassword => 'Your current password is wrong.';

  @override
  String get founder => 'Founder';

  @override
  String get stepDownAdmin => 'Step down as admin';

  @override
  String get stepDownAdminConfirm =>
      'Step down as admin? You\'ll stay in the home as a member.';

  @override
  String get transferOwnership => 'Transfer ownership';

  @override
  String transferOwnershipConfirm(String name) {
    return '$name will become the home\'s founder and an admin. You stay an admin.';
  }

  @override
  String transferOwnershipAdminConfirm(String name) {
    return '$name will become the home\'s founder. You stay an admin.';
  }

  @override
  String get ownershipTransferred => 'Ownership transferred';

  @override
  String get errorFounderProtected =>
      'Only the founder can change the founder\'s role or remove them.';

  @override
  String get errorOnlyFounderTransfer =>
      'Only the founder can transfer ownership.';

  @override
  String get errorOnlyFounderDelete =>
      'Only the home\'s founder can delete it.';

  @override
  String suggestedAmount(String amount) {
    return 'Suggested: $amount';
  }

  @override
  String overpaymentWarning(
    String from,
    String to,
    String owed,
    String amount,
  ) {
    return '$from currently owes $to $owed. You entered $amount, so the extra will look like $to owes $from. Save anyway?';
  }

  @override
  String overpaymentNoDebtWarning(String from, String to, String amount) {
    return '$from doesn\'t owe $to anything right now. You entered $amount, so it will look like $to owes $from. Save anyway?';
  }

  @override
  String get saveAnyway => 'Save anyway';

  @override
  String monthExpenseSummary(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$_temp0 · $amount';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterPaidByMe => 'Paid by me';

  @override
  String get filterInMyShare => 'Where I have a share';

  @override
  String get noExpensesMatchFilter => 'No expenses match this filter';

  @override
  String get clearFilter => 'Clear filter';

  @override
  String get attachmentsTitle => 'Receipts & documents';

  @override
  String get attachmentAdd => 'Add';

  @override
  String get attachmentMaxHint => 'Up to 5 files';

  @override
  String get attachmentTakePhoto => 'Take photo';

  @override
  String get attachmentPickGallery => 'Choose from gallery';

  @override
  String get attachmentPickPdf => 'Choose PDF';

  @override
  String get attachmentEmpty => 'No receipts yet';

  @override
  String get attachmentDeleteConfirm => 'Delete this file?';

  @override
  String attachmentByline(String name, String date) {
    return 'Added by $name · $date';
  }

  @override
  String get attachmentNoApp => 'No app on this phone can open this file.';

  @override
  String get attachmentCannotOpen => 'The file could not be opened.';

  @override
  String get attachmentsPendingHint =>
      'Files are uploaded when you save the expense.';

  @override
  String attachmentsUploadFailed(int count) {
    return '$count file(s) could not be uploaded. You can add them again from the expense.';
  }

  @override
  String get paymentReceipts => 'Receipts';

  @override
  String get attachReceipt => 'Attach receipt';

  @override
  String paymentAttachmentsUploadFailed(int count) {
    return 'Payment recorded, but $count file(s) could not be uploaded.';
  }

  @override
  String get paymentRecorded => 'Payment recorded';

  @override
  String get errorAttachmentType =>
      'Only JPEG, PNG, WEBP images and PDF files can be attached.';

  @override
  String get errorAttachmentLimit =>
      'You can attach at most 5 files here. Delete one first.';

  @override
  String get errorAttachmentTooLarge =>
      'This file is too large. The limit is 10 MB.';

  @override
  String get recurringExpenses => 'Recurring expenses';

  @override
  String get recurringExplainer =>
      'These expenses are added automatically every month. To stop one, open it and turn off \'Repeats every month\'.';

  @override
  String get recurringEmpty =>
      'No recurring expenses yet. Turn on \'Repeats every month\' for rent or a bill and it will show up here.';

  @override
  String recurringAutoHint(int day) {
    return 'Added automatically on day $day of every month';
  }

  @override
  String recurringDayInfo(int day) {
    return 'Every month, on day $day';
  }

  @override
  String recurringNextDate(String date) {
    return 'Next: $date';
  }

  @override
  String get recurringAutoTag => 'auto';

  @override
  String get recurringCheckNow => 'Check now';

  @override
  String recurringRunAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses added',
      one: '1 expense added',
    );
    return '$_temp0';
  }

  @override
  String get recurringRunNone => 'Nothing to add right now';

  @override
  String get tabStatement => 'Statement';

  @override
  String get statementThisMonth => 'This month';

  @override
  String get statementPickRange => 'Choose a date range';

  @override
  String get statementPrevMonth => 'Previous month';

  @override
  String get statementNextMonth => 'Next month';

  @override
  String get statementTotalSpent => 'Total spent';

  @override
  String statementExpenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$_temp0';
  }

  @override
  String statementPaymentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments',
      one: '1 payment',
    );
    return '$_temp0';
  }

  @override
  String get statementExpenseNumber => 'Number of expenses';

  @override
  String get statementPaymentNumber => 'Number of payments';

  @override
  String get statementPaymentsTotal => 'Payments';

  @override
  String statementDominantPayer(String name, String percent) {
    return '$name made $percent% of this period\'s payments.';
  }

  @override
  String statementDominantPayerYou(String percent) {
    return 'You made $percent% of this period\'s payments.';
  }

  @override
  String get statementWhoPaid => 'Who paid how much?';

  @override
  String statementShareLine(String share) {
    return 'Share $share';
  }

  @override
  String statementNetLine(String net) {
    return 'Difference $net';
  }

  @override
  String get statementLeftTag => '(left)';

  @override
  String get statementNoExpenses => 'No expenses in this period.';

  @override
  String get statementNoPayments => 'No payments in this period.';

  @override
  String get statementCategories => 'Categories';

  @override
  String get statementLastSixMonths => 'Last 6 months';

  @override
  String get statementSharePdf => 'Share as PDF';

  @override
  String get statementPdfTitle => 'Evce — Account statement';

  @override
  String get statementPdfSummary => 'Summary';

  @override
  String statementPdfPeriod(String period) {
    return 'Period: $period';
  }

  @override
  String statementPdfGenerated(String date) {
    return 'Created on $date';
  }

  @override
  String statementPdfPage(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get statementColMember => 'Member';

  @override
  String get statementColPaid => 'Paid';

  @override
  String get statementColShare => 'Share';

  @override
  String get statementColNet => 'Difference';

  @override
  String get statementColFrom => 'From';

  @override
  String get statementColTo => 'To';

  @override
  String get statementColDate => 'Date';

  @override
  String get statementColDescription => 'Description';

  @override
  String get statementColCategory => 'Category';

  @override
  String get statementColPaidBy => 'Paid by';

  @override
  String get statementColAmount => 'Amount';

  @override
  String get statementColNote => 'Note';

  @override
  String get pushChannelName => 'Evce notifications';

  @override
  String get pushChannelDescription =>
      'Alerts for new expenses, payments and invitations';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty =>
      'Nothing new yet. When your roommates add expenses or payments, you\'ll see them here.';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsGroupToday => 'Today';

  @override
  String get notificationsGroupYesterday => 'Yesterday';

  @override
  String get notificationsGroupEarlier => 'Earlier';

  @override
  String get notificationsJustNow => 'Just now';

  @override
  String notificationsMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String notificationsHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String get notificationsNoAccess => 'You no longer have access to this home.';

  @override
  String get notificationGenericTitle => 'Notification';

  @override
  String notificationExpenseTitle(String household) {
    return 'New expense · $household';
  }

  @override
  String notificationExpenseBody(String actor, String amount, String detail) {
    return '$actor added $amount for $detail';
  }

  @override
  String notificationExpenseBodyNoDetail(String actor, String amount) {
    return '$actor added an expense of $amount';
  }

  @override
  String notificationPaymentTitle(String household) {
    return 'Payment · $household';
  }

  @override
  String notificationPaymentBody(String payer, String receiver, String amount) {
    return '$payer paid $receiver $amount';
  }

  @override
  String notificationPaymentBodyNoTarget(String actor, String amount) {
    return '$actor recorded a payment of $amount';
  }

  @override
  String get notificationInvitationTitle => 'New invitation';

  @override
  String notificationInvitationBody(String actor, String household) {
    return '$actor invited you to $household';
  }

  @override
  String notificationAcceptedTitle(String household) {
    return 'New roommate · $household';
  }

  @override
  String notificationAcceptedBody(String actor) {
    return '$actor accepted the invitation';
  }

  @override
  String notificationRecurringTitle(String household) {
    return 'Recurring expense · $household';
  }

  @override
  String notificationRecurringBody(String detail, String amount) {
    return '$detail $amount was added for this month too';
  }

  @override
  String notificationRecurringBodyNoDetail(String amount) {
    return 'A recurring expense of $amount was added for this month too';
  }
}
