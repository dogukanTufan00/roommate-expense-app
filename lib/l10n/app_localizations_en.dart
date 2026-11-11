// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Roommate Expenses';

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
  String get registerSuccess => 'Account created. You can log in now.';

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
      'You are not in any home yet. Create one, or ask a roommate to add you.';

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
  String get noExpenses => 'No expenses yet.';

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
  String get allSettled => 'Everyone is settled up 🎉';

  @override
  String get getsBack => 'gets back';

  @override
  String get owes => 'owes';

  @override
  String get settled => 'settled up';

  @override
  String get markAsPaid => 'Mark as paid';

  @override
  String markAsPaidConfirm(String from, String to, String amount) {
    return 'Record that $from paid $to $amount?';
  }

  @override
  String get paymentsTitle => 'Payment history';

  @override
  String get noPayments => 'No payments yet.';

  @override
  String get deletePaymentConfirm => 'Delete this payment record?';

  @override
  String get addMember => 'Add member';

  @override
  String get memberEmailHint => 'Roommate\'s email (they need an account)';

  @override
  String get removeMember => 'Remove from home';

  @override
  String removeMemberConfirm(String name) {
    return 'Remove $name from this home? Their past expenses and debts are kept.';
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
  String get errorHouseholdFull => 'This home is full (max 3 members).';

  @override
  String get errorAlreadyMember => 'This person is already a member.';

  @override
  String get errorLastAdmin => 'The last admin cannot leave the home.';

  @override
  String get errorNoSuchUser => 'No account with this email.';

  @override
  String get errorUnknown => 'Something went wrong.';
}
