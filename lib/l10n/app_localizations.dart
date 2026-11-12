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
  /// **'Create a home and invite your roommates, or ask a roommate to add you.'**
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
  /// **'Mark as paid'**
  String get markAsPaid;

  /// No description provided for @markAsPaidConfirm.
  ///
  /// In en, this message translates to:
  /// **'Record that {from} paid {to} {amount}?'**
  String markAsPaidConfirm(String from, String to, String amount);

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

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMember;

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
  /// **'This home is full (max 3 members).'**
  String get errorHouseholdFull;

  /// No description provided for @errorAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'This person is already a member.'**
  String get errorAlreadyMember;

  /// No description provided for @errorLastAdmin.
  ///
  /// In en, this message translates to:
  /// **'The last admin cannot leave the home.'**
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
