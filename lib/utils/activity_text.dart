import 'package:intl/intl.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/utils/category.dart';
import 'package:roommate_expense_app/utils/format.dart';

// The sentence and the change lines of one history item, already in the current language.
class ActivityText {
  const ActivityText({required this.sentence, required this.changeLines});

  final String sentence;
  // One line per change, for example "Tutar: ₺30.000,00 → ₺31.000,00".
  final List<ChangeLine> changeLines;
}

// One change, split in two so the screen can lay it out as a row:
// label on the left ("Tutar"), values on the right ("₺30.000,00 → ₺31.000,00").
class ChangeLine {
  const ChangeLine(this.label, this.values, {this.short = false, this.share = false});

  final String label;
  // Null for a line that is only a label, like "Bölüşüm değişti".
  final String? values;
  // True for short values (money, dates, choices). The screen keeps them on one line,
  // so an amount is never cut in half. Free text (description, note, names) may wrap.
  final bool short;
  // True for one person's share. The label is then just the name; the screen shows all
  // shares under one "Paylar" heading instead of repeating "payı" on every line.
  final bool share;
}

// Fields whose values are short enough to always fit on one line.
const Set<String> _shortFields = {
  'amount', 'share', 'category', 'expenseDate', 'paidAt',
  'recurring', 'splitType', 'role',
};

// Shown when a value is missing or empty.
const String _noValue = '—';

// Builds the words for one history item. The server sends only data (who did it,
// what changed), so the sentences are made here. It only needs AppLocalizations.
ActivityText activityText(AppLocalizations l10n, ActivityEntry entry) {
  final tag = l10n.localeName;
  final actor = entry.actorName ?? l10n.historyUnknownName;
  final subject = entry.subjectName ?? l10n.historyUnknownName;
  final other = entry.otherName ?? l10n.historyUnknownName;
  final label = entry.label ?? l10n.historyExpenseFallback;
  // Formatted once in the app's language, for example "₺450,00" or "₺450.00".
  final amount = entry.amount == null ? _noValue : formatMoneyFor(tag, entry.amount!);

  final sentence = switch (entry.type) {
    ActivityType.householdCreated => l10n.historyHouseholdCreated(actor),
    ActivityType.householdRenamed => l10n.historyHouseholdRenamed(actor),
    ActivityType.ownershipTransferred =>
      l10n.historyOwnershipTransferred(actor, subject),
    ActivityType.memberJoined => l10n.historyMemberJoined(subject),
    ActivityType.memberLeft => l10n.historyMemberLeft(subject),
    ActivityType.memberRemoved => l10n.historyMemberRemoved(actor, subject),
    ActivityType.memberRoleChanged =>
      l10n.historyMemberRoleChanged(actor, subject),
    ActivityType.expenseAdded => l10n.historyExpenseAdded(actor, label, amount),
    ActivityType.expenseUpdated => l10n.historyExpenseUpdated(actor, label),
    ActivityType.expenseDeleted => l10n.historyExpenseDeleted(actor, label, amount),
    ActivityType.recurringExpenseGenerated =>
      l10n.historyRecurringGenerated(label, amount),
    ActivityType.paymentAdded =>
      l10n.historyPaymentAdded(actor, subject, other, amount),
    ActivityType.paymentUpdated =>
      l10n.historyPaymentUpdated(actor, subject, other),
    ActivityType.paymentDeleted =>
      l10n.historyPaymentDeleted(actor, subject, other, amount),
    ActivityType.unknown => l10n.historyGeneric(actor),
  };

  return ActivityText(
    sentence: sentence,
    changeLines: [for (final change in entry.changes) _changeLine(l10n, change)],
  );
}

// One change as label + "old → new". Old "shares" rows have no values, so they are a label only.
ChangeLine _changeLine(AppLocalizations l10n, ActivityChange change) {
  if (change.field == 'shares') return ChangeLine(l10n.historySharesChanged, null);
  final short = _shortFields.contains(change.field);
  // One person's split share, for example "Doğukan Tufan" + "₺750,00 → ₺1.050,00".
  // A missing old or new value (person added or removed) shows as a dash.
  if (change.field == 'share') {
    return ChangeLine(
      change.personName ?? l10n.historyUnknownName,
      '${_fieldValue(l10n, 'amount', change.oldValue)} → ${_fieldValue(l10n, 'amount', change.newValue)}',
      short: short,
      share: true,
    );
  }

  final oldText = _fieldValue(l10n, change.field, change.oldValue);
  final newText = _fieldValue(l10n, change.field, change.newValue);
  // Unknown fields keep the API's name, so the user still sees what changed.
  final label = _fieldLabel(l10n, change.field) ?? change.field;
  return ChangeLine(label, '$oldText → $newText', short: short);
}

// The name of a changed field in the current language. Null for an unknown field.
String? _fieldLabel(AppLocalizations l10n, String field) {
  return switch (field) {
    'amount' => l10n.historyFieldAmount,
    'description' => l10n.historyFieldDescription,
    'category' => l10n.historyFieldCategory,
    'expenseDate' || 'paidAt' => l10n.historyFieldDate,
    'paidBy' => l10n.historyFieldPaidBy,
    'fromUser' => l10n.historyFieldFrom,
    'toUser' => l10n.historyFieldTo,
    'recurring' => l10n.historyFieldRecurring,
    'splitType' => l10n.historyFieldSplitType,
    'note' => l10n.historyFieldNote,
    'role' => l10n.historyFieldRole,
    'name' => l10n.historyFieldName,
    _ => null,
  };
}

// A changed value in a readable form. A missing value shows as a dash.
String _fieldValue(AppLocalizations l10n, String field, String? value) {
  if (value == null || value.isEmpty) return _noValue;
  final tag = l10n.localeName;

  switch (field) {
    case 'amount':
      final number = double.tryParse(value);
      return number == null ? value : formatMoneyFor(tag, number);
    case 'category':
      return categoryLabel(l10n, value);
    case 'expenseDate':
      final date = DateTime.tryParse(value);
      return date == null ? value : formatDateFor(tag, date.toLocal());
    case 'paidAt':
      // Payments also keep the time of day.
      final time = DateTime.tryParse(value);
      return time == null
          ? value
          : DateFormat.yMMMd(tag).add_Hm().format(time.toLocal());
    case 'recurring':
      if (value == 'true') return l10n.historyYes;
      if (value == 'false') return l10n.historyNo;
      return value;
    case 'splitType':
      return switch (value) {
        'EQUAL' => l10n.splitEqual,
        'PERCENT' => l10n.splitPercent,
        'AMOUNT' => l10n.splitAmount,
        _ => value,
      };
    case 'role':
      return switch (value) {
        'ADMIN' => l10n.admin,
        'MEMBER' => l10n.historyRoleMember,
        _ => value,
      };
    default:
      return value;
  }
}
