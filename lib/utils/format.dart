import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

// The language tag of the current locale, for example "tr" or "en".
String localeTagOf(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

// Formats money for the current language.
// Turkish gives "₺1.234,50", English gives "₺1,234.50".
String formatMoney(BuildContext context, double amount) =>
    formatMoneyFor(localeTagOf(context), amount);

// The same as formatMoney, for code that has a language tag but no BuildContext (the PDF).
String formatMoneyFor(String localeTag, double amount) {
  return NumberFormat.currency(
    locale: localeTag,
    symbol: '₺',
    decimalDigits: 2,
  ).format(amount);
}

// Formats a percent number for the current language, without a % sign.
// Turkish gives "33,5", English gives "33.5". At most 2 decimals.
String formatPercent(BuildContext context, double value) =>
    formatPercentFor(localeTagOf(context), value);

String formatPercentFor(String localeTag, double value) {
  return NumberFormat('#,##0.##', localeTag).format(value);
}

// Formats a month and year, for example "Kasım 2026" or "November 2026".
// The first letter is capitalized, because Turkish month names are lowercase in intl.
String formatMonthYear(BuildContext context, DateTime date) =>
    formatMonthYearFor(localeTagOf(context), date);

String formatMonthYearFor(String localeTag, DateTime date) {
  final text = DateFormat.yMMMM(localeTag).format(date);
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

// Formats a date for the current language, for example "10 Kas 2026" or "10 Nov 2026".
String formatDate(BuildContext context, DateTime date) =>
    formatDateFor(localeTagOf(context), date);

String formatDateFor(String localeTag, DateTime date) {
  return DateFormat.yMMMd(localeTag).format(date);
}

// True when from and to are the first and last day of the same calendar month.
bool isWholeMonth(DateTime from, DateTime to) {
  final lastDayOfMonth = DateTime(from.year, from.month + 1, 0).day;
  return from.day == 1 &&
      from.year == to.year &&
      from.month == to.month &&
      to.day == lastDayOfMonth;
}

// Formats a period from one day to another (both inclusive). A whole calendar month
// becomes "Kasım 2026", anything else becomes "1 Kas – 15 Kas 2026".
String formatPeriod(String localeTag, DateTime from, DateTime to) {
  if (isWholeMonth(from, to)) return formatMonthYearFor(localeTag, from);

  final sameYear = from.year == to.year;
  final start = DateFormat(sameYear ? 'd MMM' : 'd MMM yyyy', localeTag).format(from);
  final end = DateFormat('d MMM yyyy', localeTag).format(to);
  return '$start – $end';
}
