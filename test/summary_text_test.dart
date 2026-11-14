import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/utils/summary_text.dart';

const _iban = 'TR120006400000112345678901';

Settlement _settlement({
  required int from,
  required String fromName,
  required int to,
  required String toName,
  required double amount,
  String? toIban,
}) {
  return Settlement(
    fromUserId: from,
    fromName: fromName,
    toUserId: to,
    toName: toName,
    amount: amount,
    toIban: toIban,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    await initializeDateFormatting('en');
  });

  final date = DateTime(2026, 11, 15);

  test('Turkish summary lists payments, the IBAN once per receiver and the footer', () {
    final l10n = lookupAppLocalizations(const Locale('tr'));
    final text = buildBalanceSummary(
      l10n,
      householdName: 'Kadıköy ev',
      date: date,
      settlements: [
        _settlement(from: 1, fromName: 'Hatem', to: 2, toName: 'Doğukan', amount: 1250, toIban: _iban),
        _settlement(from: 3, fromName: 'Bülent', to: 2, toName: 'Doğukan', amount: 300, toIban: _iban),
      ],
    );

    expect(
      text,
      '🏠 Kadıköy ev · 15 Kas 2026\n'
      '\n'
      'Kim kime ne ödeyecek:\n'
      '• Hatem → Doğukan: ₺1.250,00\n'
      '• Bülent → Doğukan: ₺300,00\n'
      '\n'
      "IBAN'lar:\n"
      'Doğukan: TR12 0006 4000 0011 2345 6789 01\n'
      '\n'
      'Evce ile hesaplandı',
    );
  });

  test('IBAN section is omitted when no receiver has an IBAN', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final text = buildBalanceSummary(
      l10n,
      householdName: 'Flat',
      date: date,
      settlements: [
        _settlement(from: 1, fromName: 'Hatem', to: 2, toName: 'Doğukan', amount: 10),
      ],
    );

    expect(text.contains('IBANs:'), isFalse);
    expect(text, contains('• Hatem → Doğukan: ₺10.00'));
  });

  test('no settlements gives the all-settled text', () {
    final l10n = lookupAppLocalizations(const Locale('tr'));
    final text = buildBalanceSummary(
      l10n,
      householdName: 'Kadıköy ev',
      date: date,
      settlements: const [],
    );

    expect(text, '🏠 Kadıköy ev · 15 Kas 2026\n\nHerkes ödeşmiş 🎉\n\nEvce ile hesaplandı');
  });

  test('Personal message speaks to the payer when I get the money', () {
    final l10n = lookupAppLocalizations(const Locale('tr'));
    final text = buildSettlementMessage(
      l10n,
      householdName: 'Kadıköy ev',
      settlement: _settlement(from: 2, fromName: 'Bülent Aksoy', to: 1, toName: 'Doğukan Tufan', amount: 2000, toIban: _iban),
      myUserId: 1,
    );
    expect(text, 'Selam Bülent, Kadıköy ev hesabına göre bana ₺2.000,00 ödemen gerekiyor.\n'
        'IBAN: TR12 0006 4000 0011 2345 6789 01 (Doğukan Tufan)\n\n'
        'Evce ile hesaplandı');
  });

  test('Someone else sharing gets a neutral line, no IBAN when there is none', () {
    final l10n = lookupAppLocalizations(const Locale('tr'));
    final text = buildSettlementMessage(
      l10n,
      householdName: 'Kadıköy ev',
      settlement: _settlement(from: 3, fromName: 'Hatem', to: 1, toName: 'Doğukan', amount: 2000),
      myUserId: 2,
    );
    expect(text, 'Kadıköy ev · Hatem → Doğukan: ₺2.000,00\n\nEvce ile hesaplandı');
  });
}
