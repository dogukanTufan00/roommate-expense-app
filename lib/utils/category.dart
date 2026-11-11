import 'package:flutter/material.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/theme.dart';

// The category codes sent to the API. These must match the API's ExpenseCategory enum.
const List<String> expenseCategories = ['RENT', 'UTILITIES', 'GROCERIES', 'OTHER'];

// The translated name shown to the user.
String categoryLabel(AppLocalizations l10n, String category) {
  switch (category) {
    case 'RENT':
      return l10n.categoryRent;
    case 'UTILITIES':
      return l10n.categoryUtilities;
    case 'GROCERIES':
      return l10n.categoryGroceries;
    default:
      return l10n.categoryOther;
  }
}

// The icon shown next to an expense.
IconData categoryIcon(String category) {
  switch (category) {
    case 'RENT':
      return Icons.house;
    case 'UTILITIES':
      return Icons.bolt;
    case 'GROCERIES':
      return Icons.shopping_cart;
    default:
      return Icons.category;
  }
}

// The color used for an expense's category, so categories are easy to tell apart.
Color categoryColor(String category) {
  switch (category) {
    case 'RENT':
      return const Color(0xFF8E7DBE);
    case 'UTILITIES':
      return AppColors.mustard;
    case 'GROCERIES':
      return AppColors.sage;
    default:
      return const Color(0xFF9AA0B5);
  }
}
