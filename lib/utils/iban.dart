import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';

// Removes spaces and uppercases, the same form the API stores: "tr12 3456" -> "TR123456".
String normalizeIban(String text) {
  return text.replaceAll(RegExp(r'\s'), '').toUpperCase();
}

// Groups the IBAN in blocks of 4 for display: "TR123456..." -> "TR12 3456 ...".
String formatIban(String iban) {
  final compact = normalizeIban(iban);
  return RegExp(r'.{1,4}').allMatches(compact).map((m) => m.group(0)!).join(' ');
}

// Copies the raw IBAN (no spaces) and confirms with a SnackBar.
Future<void> copyIban(BuildContext context, String iban) async {
  final l10n = AppLocalizations.of(context);
  await Clipboard.setData(ClipboardData(text: normalizeIban(iban)));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.ibanCopied)),
  );
}
