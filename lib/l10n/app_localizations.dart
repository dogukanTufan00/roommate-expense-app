import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Evce'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get register;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get haveAccount;

  /// No description provided for @registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome aboard! You can log in now.'**
  String get registerSuccess;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get languageSystem;

  /// No description provided for @households.
  ///
  /// In en, this message translates to:
  /// **'My homes'**
  String get households;

  /// No description provided for @noHouseholds.
  ///
  /// In en, this message translates to:
  /// **'Create a home and invite your roommates, or wait for an invitation.'**
  String get noHouseholds;

  /// No description provided for @createHousehold.
  ///
  /// In en, this message translates to:
  /// **'New home'**
  String get createHousehold;

  /// No description provided for @householdName.
  ///
  /// In en, this message translates to:
  /// **'Home name'**
  String get householdName;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @deleteHouseholdConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this home with all its expenses and payments? This cannot be undone.'**
  String get deleteHouseholdConfirm;

  /// No description provided for @tabExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get tabExpenses;

  /// No description provided for @tabBalances.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get tabBalances;

  /// No description provided for @tabMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get tabMembers;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get editExpense;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount (₺)'**
  String get amount;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get categoryRent;

  /// No description provided for @categoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get categoryUtilities;

  /// No description provided for @categoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryGroceries;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get description;

  /// No description provided for @paidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidBy;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Repeats every month'**
  String get recurring;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'Rent day will fill this up soon 🙂'**
  String get noExpenses;

  /// No description provided for @deleteExpenseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this expense?'**
  String get deleteExpenseConfirm;

  /// No description provided for @paidByName.
  ///
  /// In en, this message translates to:
  /// **'Paid by {name}'**
  String paidByName(String name);

  /// No description provided for @balancesTitle.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get balancesTitle;

  /// No description provided for @settlementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Who pays whom'**
  String get settlementsTitle;

  /// No description provided for @allSettled.
  ///
  /// In en, this message translates to:
  /// **'All square, nobody owes anybody 🎉'**
  String get allSettled;

  /// No description provided for @getsBack.
  ///
  /// In en, this message translates to:
  /// **'gets back'**
  String get getsBack;

  /// No description provided for @owes.
  ///
  /// In en, this message translates to:
  /// **'owes'**
  String get owes;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'settled up'**
  String get settled;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get markAsPaid;

  /// No description provided for @markAsPaidConfirm.
  ///
  /// In en, this message translates to:
  /// **'Record that {from} paid {to}?'**
  String markAsPaidConfirm(String from, String to);

  /// No description provided for @paymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get paymentsTitle;

  /// No description provided for @noPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments yet. Settled debts will show up here.'**
  String get noPayments;

  /// No description provided for @deletePaymentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this payment record?'**
  String get deletePaymentConfirm;

  /// No description provided for @inviteMember.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get inviteMember;

  /// No description provided for @inviteMemberHint.
  ///
  /// In en, this message translates to:
  /// **'Invitation will be sent. They join the home once they accept.'**
  String get inviteMemberHint;

  /// No description provided for @inviteMemberEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Roommate\'s email (they need an account)'**
  String get inviteMemberEmailHint;

  /// No description provided for @inviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get inviteSent;

  /// No description provided for @pendingInvitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending invitations'**
  String get pendingInvitesTitle;

  /// No description provided for @awaitingResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for reply'**
  String get awaitingResponse;

  /// No description provided for @cancelInvitation.
  ///
  /// In en, this message translates to:
  /// **'Cancel invitation'**
  String get cancelInvitation;

  /// No description provided for @cancelInvitationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel the invitation for {name}?'**
  String cancelInvitationConfirm(String name);

  /// No description provided for @invitationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Invitation cancelled'**
  String get invitationCancelled;

  /// No description provided for @incomingInvitesTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been invited'**
  String get incomingInvitesTitle;

  /// No description provided for @invitedYou.
  ///
  /// In en, this message translates to:
  /// **'{inviter} invited you to a home'**
  String invitedYou(String inviter);

  /// No description provided for @acceptInvitation.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptInvitation;

  /// No description provided for @declineInvitation.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineInvitation;

  /// No description provided for @declineInvitationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Decline the invitation to {household}?'**
  String declineInvitationConfirm(String household);

  /// No description provided for @welcomeToHousehold.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {household}!'**
  String welcomeToHousehold(String household);

  /// No description provided for @invitationDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined'**
  String get invitationDeclined;

  /// No description provided for @memberEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Roommate\'s email (they need an account)'**
  String get memberEmailHint;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove from home'**
  String get removeMember;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this home? Their past expenses and debts are kept.'**
  String removeMemberConfirm(String name);

  /// No description provided for @removeMemberOwesWarning.
  ///
  /// In en, this message translates to:
  /// **'Heads up: {name} hasn\'t settled up and still owes {amount}. If you remove them, the debt stays in the balances and you can record their payment later.'**
  String removeMemberOwesWarning(String name, String amount);

  /// No description provided for @removeMemberGetsBackWarning.
  ///
  /// In en, this message translates to:
  /// **'Heads up: {name} hasn\'t settled up and is still owed {amount}. If you remove them, it stays in the balances and you can record your payment to them later.'**
  String removeMemberGetsBackWarning(String name, String amount);

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get you;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than 0'**
  String get invalidAmount;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Is the API running?'**
  String get errorNetwork;

  /// No description provided for @errorBadRequest.
  ///
  /// In en, this message translates to:
  /// **'Some fields are invalid.'**
  String get errorBadRequest;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errorWrongCredentials;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do this.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found. It may have been deleted.'**
  String get errorNotFound;

  /// No description provided for @errorEmailExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errorEmailExists;

  /// No description provided for @errorHouseholdFull.
  ///
  /// In en, this message translates to:
  /// **'This home is full (max 3 people, invitations included).'**
  String get errorHouseholdFull;

  /// No description provided for @errorAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'This person is already a member.'**
  String get errorAlreadyMember;

  /// No description provided for @errorInvitationPending.
  ///
  /// In en, this message translates to:
  /// **'This person already has an open invitation to this home.'**
  String get errorInvitationPending;

  /// No description provided for @errorInvitationNotPending.
  ///
  /// In en, this message translates to:
  /// **'This invitation is no longer open. It may have been cancelled or answered.'**
  String get errorInvitationNotPending;

  /// No description provided for @errorLastAdmin.
  ///
  /// In en, this message translates to:
  /// **'You are the last admin. Make another member an admin first.'**
  String get errorLastAdmin;

  /// No description provided for @errorNoSuchUser.
  ///
  /// In en, this message translates to:
  /// **'No account with this email.'**
  String get errorNoSuchUser;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorUnknown;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Shared home, fair shares.'**
  String get loginTagline;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your balance'**
  String get summaryTitle;

  /// No description provided for @summaryGetsBack.
  ///
  /// In en, this message translates to:
  /// **'Your roommates owe you'**
  String get summaryGetsBack;

  /// No description provided for @summaryOwes.
  ///
  /// In en, this message translates to:
  /// **'You owe your roommates'**
  String get summaryOwes;

  /// No description provided for @summarySettled.
  ///
  /// In en, this message translates to:
  /// **'You\'re all square. Nobody owes you, you owe nobody.'**
  String get summarySettled;

  /// No description provided for @noHouseholdsTitle.
  ///
  /// In en, this message translates to:
  /// **'No home yet'**
  String get noHouseholdsTitle;

  /// No description provided for @noExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesTitle;

  /// No description provided for @splitTitle.
  ///
  /// In en, this message translates to:
  /// **'Who shares this?'**
  String get splitTitle;

  /// No description provided for @splitEqual.
  ///
  /// In en, this message translates to:
  /// **'Equal'**
  String get splitEqual;

  /// No description provided for @splitPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get splitPercent;

  /// No description provided for @splitAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get splitAmount;

  /// No description provided for @splitRemainingPercent.
  ///
  /// In en, this message translates to:
  /// **'Remaining: %{value}'**
  String splitRemainingPercent(String value);

  /// No description provided for @splitRemainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {value}'**
  String splitRemainingAmount(String value);

  /// No description provided for @splitNotBalanced.
  ///
  /// In en, this message translates to:
  /// **'Shares must add up exactly before you can save.'**
  String get splitNotBalanced;

  /// No description provided for @splitNoneSelected.
  ///
  /// In en, this message translates to:
  /// **'At least one person must stay selected.'**
  String get splitNoneSelected;

  /// No description provided for @splitInvalidValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid value (up to 2 decimals).'**
  String get splitInvalidValue;

  /// No description provided for @splitDefaultApplied.
  ///
  /// In en, this message translates to:
  /// **'The home\'s default ratio was applied. You can still change it.'**
  String get splitDefaultApplied;

  /// No description provided for @splitFormerMembers.
  ///
  /// In en, this message translates to:
  /// **'{names} moved out and was removed from this split. Redistribute the shares to save.'**
  String splitFormerMembers(String names);

  /// No description provided for @yourShare.
  ///
  /// In en, this message translates to:
  /// **'Your share: {amount}'**
  String yourShare(String amount);

  /// No description provided for @notInSplit.
  ///
  /// In en, this message translates to:
  /// **'Not part of this split'**
  String get notInSplit;

  /// No description provided for @customAmounts.
  ///
  /// In en, this message translates to:
  /// **'Custom amounts'**
  String get customAmounts;

  /// No description provided for @splitDefaults.
  ///
  /// In en, this message translates to:
  /// **'Default ratios'**
  String get splitDefaults;

  /// No description provided for @splitDefaultsIntro.
  ///
  /// In en, this message translates to:
  /// **'The ratio set here is pre-filled when you add an expense in that category. It only applies while the same people live in the house.'**
  String get splitDefaultsIntro;

  /// No description provided for @splitDefaultsReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Only admins can change the ratios.'**
  String get splitDefaultsReadOnly;

  /// No description provided for @splitEqualSplit.
  ///
  /// In en, this message translates to:
  /// **'Split equally'**
  String get splitEqualSplit;

  /// No description provided for @removeDefault.
  ///
  /// In en, this message translates to:
  /// **'Remove default'**
  String get removeDefault;

  /// No description provided for @errorInvalidSplit.
  ///
  /// In en, this message translates to:
  /// **'The split is not valid. Check the shares and try again.'**
  String get errorInvalidSplit;

  /// No description provided for @movedOutTag.
  ///
  /// In en, this message translates to:
  /// **'moved out'**
  String get movedOutTag;

  /// No description provided for @changeSplit.
  ///
  /// In en, this message translates to:
  /// **'Change split'**
  String get changeSplit;

  /// No description provided for @splitAmountChanged.
  ///
  /// In en, this message translates to:
  /// **'You changed the amount, so the amount split needs adjusting too.'**
  String get splitAmountChanged;

  /// No description provided for @editPayment.
  ///
  /// In en, this message translates to:
  /// **'Edit payment'**
  String get editPayment;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @paymentNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get paymentNote;

  /// No description provided for @paymentNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. paid by bank transfer'**
  String get paymentNoteHint;

  /// No description provided for @paymentFromTo.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String paymentFromTo(String from, String to);

  /// No description provided for @paymentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Payment updated'**
  String get paymentUpdated;

  /// No description provided for @copyIban.
  ///
  /// In en, this message translates to:
  /// **'Copy IBAN'**
  String get copyIban;

  /// No description provided for @ibanCopied.
  ///
  /// In en, this message translates to:
  /// **'IBAN copied'**
  String get ibanCopied;

  /// No description provided for @addIbanHint.
  ///
  /// In en, this message translates to:
  /// **'Add your IBAN in your profile so roommates can pay you easily.'**
  String get addIbanHint;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get makeAdmin;

  /// No description provided for @removeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove admin role'**
  String get removeAdmin;

  /// No description provided for @makeAdminConfirm.
  ///
  /// In en, this message translates to:
  /// **'Make {name} an admin? Admins can invite and remove members and change the ratios.'**
  String makeAdminConfirm(String name);

  /// No description provided for @removeAdminConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove admin rights from {name}?'**
  String removeAdminConfirm(String name);

  /// No description provided for @roleChanged.
  ///
  /// In en, this message translates to:
  /// **'Role updated'**
  String get roleChanged;

  /// No description provided for @memberOptions.
  ///
  /// In en, this message translates to:
  /// **'Member options'**
  String get memberOptions;

  /// No description provided for @leaveHome.
  ///
  /// In en, this message translates to:
  /// **'Leave home'**
  String get leaveHome;

  /// No description provided for @leaveHomeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave this home? Someone has to invite you again to come back.'**
  String get leaveHomeConfirm;

  /// No description provided for @leaveHomeOwesWarning.
  ///
  /// In en, this message translates to:
  /// **'Heads up: you haven\'t settled up and still owe {amount}. If you leave, the debt stays in the balances and you can pay it later.'**
  String leaveHomeOwesWarning(String amount);

  /// No description provided for @leaveHomeGetsBackWarning.
  ///
  /// In en, this message translates to:
  /// **'Heads up: you haven\'t settled up and are still owed {amount}. If you leave, it stays in the balances and your roommates can pay you later.'**
  String leaveHomeGetsBackWarning(String amount);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @iban.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get iban;

  /// No description provided for @ibanPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'TR00 0000 0000 0000 0000 0000 00'**
  String get ibanPlaceholder;

  /// No description provided for @ibanHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Roommates use it to pay you.'**
  String get ibanHelper;

  /// No description provided for @ibanFormatHint.
  ///
  /// In en, this message translates to:
  /// **'A Turkish IBAN starts with TR and has 26 characters.'**
  String get ibanFormatHint;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @repeatNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get repeatNewPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don\'t match'**
  String get passwordMismatch;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @errorInvalidIban.
  ///
  /// In en, this message translates to:
  /// **'This IBAN doesn\'t look right. Check it and try again.'**
  String get errorInvalidIban;

  /// No description provided for @errorWrongCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Your current password is wrong.'**
  String get errorWrongCurrentPassword;

  /// No description provided for @founder.
  ///
  /// In en, this message translates to:
  /// **'Founder'**
  String get founder;

  /// No description provided for @stepDownAdmin.
  ///
  /// In en, this message translates to:
  /// **'Step down as admin'**
  String get stepDownAdmin;

  /// No description provided for @stepDownAdminConfirm.
  ///
  /// In en, this message translates to:
  /// **'Step down as admin? You\'ll stay in the home as a member.'**
  String get stepDownAdminConfirm;

  /// No description provided for @transferOwnership.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership'**
  String get transferOwnership;

  /// No description provided for @transferOwnershipConfirm.
  ///
  /// In en, this message translates to:
  /// **'{name} will become the home\'s founder and an admin. You stay an admin.'**
  String transferOwnershipConfirm(String name);

  /// No description provided for @transferOwnershipAdminConfirm.
  ///
  /// In en, this message translates to:
  /// **'{name} will become the home\'s founder. You stay an admin.'**
  String transferOwnershipAdminConfirm(String name);

  /// No description provided for @ownershipTransferred.
  ///
  /// In en, this message translates to:
  /// **'Ownership transferred'**
  String get ownershipTransferred;

  /// No description provided for @errorFounderProtected.
  ///
  /// In en, this message translates to:
  /// **'Only the founder can change the founder\'s role or remove them.'**
  String get errorFounderProtected;

  /// No description provided for @errorOnlyFounderTransfer.
  ///
  /// In en, this message translates to:
  /// **'Only the founder can transfer ownership.'**
  String get errorOnlyFounderTransfer;

  /// No description provided for @errorOnlyFounderDelete.
  ///
  /// In en, this message translates to:
  /// **'Only the home\'s founder can delete it.'**
  String get errorOnlyFounderDelete;

  /// No description provided for @suggestedAmount.
  ///
  /// In en, this message translates to:
  /// **'Suggested: {amount}'**
  String suggestedAmount(String amount);

  /// No description provided for @overpaymentWarning.
  ///
  /// In en, this message translates to:
  /// **'{from} currently owes {to} {owed}. You entered {amount}, so the extra will look like {to} owes {from}. Save anyway?'**
  String overpaymentWarning(String from, String to, String owed, String amount);

  /// No description provided for @overpaymentNoDebtWarning.
  ///
  /// In en, this message translates to:
  /// **'{from} doesn\'t owe {to} anything right now. You entered {amount}, so it will look like {to} owes {from}. Save anyway?'**
  String overpaymentNoDebtWarning(String from, String to, String amount);

  /// No description provided for @saveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get saveAnyway;

  /// No description provided for @monthExpenseSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 expense} other{{count} expenses}} · {amount}'**
  String monthExpenseSummary(int count, String amount);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterPaidByMe.
  ///
  /// In en, this message translates to:
  /// **'Paid by me'**
  String get filterPaidByMe;

  /// No description provided for @filterInMyShare.
  ///
  /// In en, this message translates to:
  /// **'Where I have a share'**
  String get filterInMyShare;

  /// No description provided for @noExpensesMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No expenses match this filter'**
  String get noExpensesMatchFilter;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearFilter;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
