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

// Formats a date for the current language, for example "10 Kas 2026" or "10 Nov 2026".
String formatDate(BuildContext context, DateTime date) {
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(localeTag).format(date);
}
