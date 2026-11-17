import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/utils/notification_text.dart';

AppNotification _reminder({String? note}) {
  return AppNotification(
    id: 1,
    type: NotificationType.paymentReminder,
    householdId: 1,
    householdName: "Moda'daki Ev",
    actorName: 'Doğukan Tufan',
    targetName: null,
    amount: 9495.77,
    previousAmount: null,
    detail: note,
    expenseId: null,
    paymentId: null,
    invitationId: null,
    read: false,
    createdAt: DateTime(2026, 11, 17),
  );
}

void main() {
  // Regression: the amount and the home name were swapped in the reminder sentence
  // ("₺9.495,77 evinde ona Moda'daki Ev borcun var").
  test('Turkish payment reminder puts the amount in the sentence and the home in the title', () {
    final l10n = lookupAppLocalizations(const Locale('tr'));
    final text = notificationText(l10n, _reminder());

    expect(text.title, contains("Moda'daki Ev"));
    expect(text.body, 'Doğukan Tufan nazikçe hatırlatıyor: ona ₺9.495,77 borcun var.');
  });

  test('English payment reminder uses the amount, not the home name', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final text = notificationText(l10n, _reminder());

    expect(text.title, contains("Moda'daki Ev"));
    expect(text.body, 'Doğukan Tufan is gently reminding you that you owe them ₺9,495.77.');
  });

  test('The optional note goes on its own line after the sentence', () {
    final l10n = lookupAppLocalizations(const Locale('tr'));
    final text = notificationText(l10n, _reminder(note: 'Kira için'));

    expect(text.body, 'Doğukan Tufan nazikçe hatırlatıyor: ona ₺9.495,77 borcun var.\nNot: Kira için');
  });
}
