import 'package:roommate_expense_app/l10n/app_localizations.dart';

// The reminder choices in days before the due date. 0 means no reminder.
const List<int> reminderDayChoices = [0, 1, 3, 7];

// The reminder setting as text: "Yok", "1 gün önce" or "3 gün önce" (or the English forms).
String reminderChoiceLabel(AppLocalizations l10n, int days) =>
    days == 0 ? l10n.reminderOff : l10n.reminderDaysBefore(days);

// Whole calendar days from today until the day of date, in local time. 0 is today.
int daysUntil(DateTime date, DateTime now) {
  final local = date.toLocal();
  final due = DateTime.utc(local.year, local.month, local.day);
  final today = DateTime.utc(now.year, now.month, now.day);
  return due.difference(today).inDays;
}

// When a bill is due, as short text: "Bugün", "Yarın" or "3 gün sonra".
String dueWhenLabel(AppLocalizations l10n, int daysLeft) {
  if (daysLeft <= 0) return l10n.dueToday;
  if (daysLeft == 1) return l10n.dueTomorrow;
  return l10n.dueInDays(daysLeft);
}
