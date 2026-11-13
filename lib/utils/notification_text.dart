import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/utils/format.dart';

// The title and body of one notification, already in the current language.
class NotificationText {
  const NotificationText({required this.title, required this.body});

  final String title;
  // Empty when the notification needs only a title.
  final String body;
}

// Builds the words for one notification. The server sends only data (who did it,
// how much, which home), so the sentences are made here. It only needs
// AppLocalizations, so push notifications can reuse it later.
NotificationText notificationText(
  AppLocalizations l10n,
  AppNotification notification,
) {
  final household = notification.householdName;
  final actor = notification.actorName;
  final target = notification.targetName;
  final detail = notification.detail;
  final amountValue = notification.amount;
  // Formatted once in the app's language, for example "₺450,00" or "₺450.00".
  final amount = amountValue == null
      ? ''
      : formatMoneyFor(l10n.localeName, amountValue);
  // After an edit that changed the amount: ": ₺1.500,00 → ₺2.500,00". Empty otherwise.
  final previousValue = notification.previousAmount;
  final change = previousValue == null || amountValue == null
      ? ''
      : ': ${formatMoneyFor(l10n.localeName, previousValue)} → $amount';

  switch (notification.type) {
    case NotificationType.expenseAdded:
      return NotificationText(
        title: l10n.notificationExpenseTitle(household),
        body: detail == null
            ? l10n.notificationExpenseBodyNoDetail(actor, amount)
            : l10n.notificationExpenseBody(actor, detail, amount),
      );
    case NotificationType.paymentRecorded:
      return NotificationText(
        title: l10n.notificationPaymentTitle(household),
        body: target == null
            ? l10n.notificationPaymentBodyNoTarget(actor, amount)
            : l10n.notificationPaymentBody(actor, target, amount),
      );
    case NotificationType.invitationReceived:
      return NotificationText(
        title: l10n.notificationInvitationTitle,
        body: l10n.notificationInvitationBody(actor, household),
      );
    case NotificationType.invitationAccepted:
      return NotificationText(
        title: l10n.notificationAcceptedTitle(household),
        body: l10n.notificationAcceptedBody(actor),
      );
    case NotificationType.recurringExpenseAdded:
      return NotificationText(
        title: l10n.notificationRecurringTitle(household),
        body: detail == null
            ? l10n.notificationRecurringBodyNoDetail(amount)
            : l10n.notificationRecurringBody(detail, amount),
      );
    case NotificationType.paymentReminder:
      // The optional note from the creditor goes on its own line.
      final sentence = l10n.notificationReminderBody(actor, household, amount);
      return NotificationText(
        title: l10n.notificationReminderTitle(household),
        body: detail == null
            ? sentence
            : '$sentence\n${l10n.notificationReminderNote(detail)}',
      );
    case NotificationType.expenseUpdated:
      return NotificationText(
        title: l10n.notificationExpenseUpdatedTitle(household),
        body: detail == null
            ? l10n.notificationExpenseUpdatedBodyNoDetail(actor, change)
            : l10n.notificationExpenseUpdatedBody(actor, detail, change),
      );
    case NotificationType.paymentUpdated:
      // Like a payment reminder, the note goes on its own line.
      final updatedSentence = l10n.notificationPaymentUpdatedBody(actor, change);
      return NotificationText(
        title: l10n.notificationPaymentUpdatedTitle(household),
        body: detail == null
            ? updatedSentence
            : '$updatedSentence\n${l10n.notificationNoteLine(detail)}',
      );
    case NotificationType.unknown:
      return NotificationText(title: l10n.notificationGenericTitle, body: '');
  }
}
