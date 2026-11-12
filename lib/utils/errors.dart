import 'package:flutter/widgets.dart';
import 'package:roommate_expense_app/api/api_client.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';

// Turns any error into a message in the user's language.
//
// The API's messages are in English. We map them by status code (and some
// message text) so the user sees their own language.
String errorMessage(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);

  if (error is! ApiException) return l10n.errorUnknown;

  final status = error.statusCode;
  final message = error.message;

  if (status == 0) return l10n.errorNetwork;
  if (status == 400) {
    // Checked first: "Invalid IBAN checksum" would otherwise match the "sum" keyword below.
    if (message.contains('Invalid IBAN')) return l10n.errorInvalidIban;
    if (message.contains('Current password is incorrect')) {
      return l10n.errorWrongCurrentPassword;
    }
    // Split errors from the API. The keywords are a best guess at the English messages.
    final lower = message.toLowerCase();
    if (lower.contains('share') ||
        lower.contains('percent') ||
        lower.contains('sum') ||
        lower.contains('participant')) {
      return l10n.errorInvalidSplit;
    }
    return l10n.errorBadRequest;
  }
  if (status == 401) return l10n.errorUnauthorized;
  if (status == 403) {
    // The founder rules. "Only the founder can transfer ownership" is checked first.
    if (message.contains('transfer ownership')) return l10n.errorOnlyFounderTransfer;
    if (message.contains('delete the household')) return l10n.errorOnlyFounderDelete;
    if (message.contains('founder')) return l10n.errorFounderProtected;
    return l10n.errorForbidden;
  }

  if (status == 404) {
    if (message.startsWith('No user with email')) return l10n.errorNoSuchUser;
    return l10n.errorNotFound;
  }

  if (status == 409) {
    if (message.contains('already exists') || message.contains('Email')) {
      return l10n.errorEmailExists;
    }
    // Checked before "pending": the full-home message also mentions pending invitations.
    if (message.contains('maximum') || message.contains('Household is full')) {
      return l10n.errorHouseholdFull;
    }
    if (message.contains('no longer pending')) {
      return l10n.errorInvitationNotPending;
    }
    if (message.contains('pending invitation')) {
      return l10n.errorInvitationPending;
    }
    if (message.contains('already an active member')) {
      return l10n.errorAlreadyMember;
    }
    // Used both for leaving and for removing or demoting, so the text tells the user what to do.
    if (message.toLowerCase().contains('last admin')) return l10n.errorLastAdmin;
    return l10n.errorUnknown;
  }

  return l10n.errorUnknown;
}
