import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

// Formats money for the current language.
// Turkish gives "₺1.234,50", English gives "₺1,234.50".
String formatMoney(BuildContext context, double amount) {
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  return NumberFormat.currency(
    locale: localeTag,
    symbol: '₺',
    decimalDigits: 2,
  ).format(amount);
}

// Formats a percent number for the current language, without a % sign.
// Turkish gives "33,5", English gives "33.5". At most 2 decimals.
String formatPercent(BuildContext context, double value) {
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  return NumberFormat('#,##0.##', localeTag).format(value);
}

// Formats a month and year, for example "Kasım 2026" or "November 2026".
// The first letter is capitalized, because Turkish month names are lowercase in intl.
String formatMonthYear(BuildContext context, DateTime date) {
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  final text = DateFormat.yMMMM(localeTag).format(date);
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

// Formats a date for the current language, for example "10 Kas 2026" or "10 Nov 2026".
String formatDate(BuildContext context, DateTime date) {
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(localeTag).format(date);
}
