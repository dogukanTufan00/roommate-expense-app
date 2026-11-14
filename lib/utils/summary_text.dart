import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/utils/format.dart';
import 'package:roommate_expense_app/utils/iban.dart';

// Builds the plain text of the "share summary" (for WhatsApp and other apps) from the
// settlements of the Balances tab. It only builds text, so it can be unit tested.
//
// Turkish example:
// 🏠 Kadıköy ev · 15 Kas 2026
//
// Kim kime ne ödeyecek:
// • Hatem → Doğukan: ₺1.250,00
//
// IBAN'lar:
// Doğukan Tufan: TR12 0006 4000 0011 2345 6789 01
//
// Evce ile hesaplandı
String buildBalanceSummary(
  AppLocalizations l10n, {
  required String householdName,
  required DateTime date,
  required List<Settlement> settlements,
}) {
  // The language tag ("tr" or "en") drives the money and date formats.
  final localeTag = l10n.localeName;
  final sections = <String>[
    '🏠 $householdName · ${formatDateFor(localeTag, date)}',
  ];

  if (settlements.isEmpty) {
    sections.add(l10n.summaryAllSettled);
  } else {
    sections.add([
      l10n.summaryWhoPaysWhom,
      for (final s in settlements)
        '• ${s.fromName} → ${s.toName}: ${formatMoneyFor(localeTag, s.amount)}',
    ].join('\n'));

    final ibanSection = _ibanSection(l10n, settlements);
    if (ibanSection != null) sections.add(ibanSection);
  }

  sections.add(l10n.summaryFooter);
  return sections.join('\n\n');
}

// One line per receiver who has an IBAN, each receiver only once. Null when nobody has one.
String? _ibanSection(AppLocalizations l10n, List<Settlement> settlements) {
  final seenReceivers = <int>{};
  final lines = <String>[];
  for (final s in settlements) {
    final iban = s.toIban;
    if (iban == null || !seenReceivers.add(s.toUserId)) continue;
    lines.add('${s.toName}: ${formatIban(iban)}');
  }
  if (lines.isEmpty) return null;
  return [l10n.summaryIbansTitle, ...lines].join('\n');
}

// The message for ONE payment, to send straight to that person.
// If the sharer is the one who gets the money, it speaks to the payer by first name:
//   "Selam Bülent, Kadıköy ev hesabına göre bana ₺2.000,00 ödemen gerekiyor."
// Anyone else gets a neutral line: "Kadıköy ev · Bülent → Doğukan: ₺2.000,00".
// The receiver's IBAN follows when they have one, then the footer.
String buildSettlementMessage(
  AppLocalizations l10n, {
  required String householdName,
  required Settlement settlement,
  required int? myUserId,
}) {
  final localeTag = l10n.localeName;
  final amount = formatMoneyFor(localeTag, settlement.amount);
  final lines = <String>[
    settlement.toUserId == myUserId
        ? l10n.summaryPersonalAsk(_firstName(settlement.fromName), householdName, amount)
        : '$householdName · ${settlement.fromName} → ${settlement.toName}: $amount',
  ];
  final iban = settlement.toIban;
  if (iban != null) {
    lines.add(l10n.summaryIbanLine(formatIban(iban), settlement.toName));
  }
  return '${lines.join('\n')}\n\n${l10n.summaryFooter}';
}

// "Bülent Aksoy" -> "Bülent": a greeting uses the first name only.
String _firstName(String fullName) {
  final trimmed = fullName.trim();
  final space = trimmed.indexOf(' ');
  return space < 0 ? trimmed : trimmed.substring(0, space);
}
