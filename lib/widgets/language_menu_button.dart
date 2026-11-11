import 'package:flutter/material.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/session.dart';

// A globe button that opens a menu to choose the app language.
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = Session.locale.value;

    // Menu values are strings, not Locale?. A null value would be treated as
    // "cancelled" by PopupMenuButton, so "system" stands for "phone language".
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      tooltip: l10n.language,
      onSelected: (code) {
        Session.setLocale(code == 'system' ? null : Locale(code));
      },
      itemBuilder: (context) => [
        _item('system', l10n.languageSystem, current == null),
        _item('tr', 'Türkçe', current?.languageCode == 'tr'),
        _item('en', 'English', current?.languageCode == 'en'),
      ],
    );
  }

  PopupMenuItem<String> _item(String value, String label, bool selected) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          // A fixed-width box keeps the labels aligned when nothing is checked.
          SizedBox(
            width: 24,
            child: selected ? const Icon(Icons.check, size: 20) : null,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
