import 'package:flutter/material.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/theme.dart';

// The category codes sent to the API. These must match the API's ExpenseCategory enum.
// The order here is the order shown in every list (dropdown, chips, split defaults).
// OTHER is always last.
const List<String> expenseCategories = [
  'RENT',
  'UTILITIES',
  'GROCERIES',
  'CLEANING',
  'EATING_OUT',
  'SUBSCRIPTIONS',
  'HOME_REPAIR',
  'PETS',
  'ENTERTAINMENT',
  'TRANSPORT',
  'HEALTH_BEAUTY',
  'OTHER',
];

// The translated name shown to the user.
String categoryLabel(AppLocalizations l10n, String category) {
  switch (category) {
    case 'RENT':
      return l10n.categoryRent;
    case 'UTILITIES':
      return l10n.categoryUtilities;
    case 'GROCERIES':
      return l10n.categoryGroceries;
    case 'CLEANING':
      return l10n.categoryCleaning;
    case 'EATING_OUT':
      return l10n.categoryEatingOut;
    case 'SUBSCRIPTIONS':
      return l10n.categorySubscriptions;
    case 'HOME_REPAIR':
      return l10n.categoryHomeRepair;
    case 'PETS':
      return l10n.categoryPets;
    case 'ENTERTAINMENT':
      return l10n.categoryEntertainment;
    case 'TRANSPORT':
      return l10n.categoryTransport;
    case 'HEALTH_BEAUTY':
      return l10n.categoryHealthBeauty;
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
    case 'CLEANING':
      return Icons.cleaning_services_rounded;
    case 'EATING_OUT':
      return Icons.restaurant_rounded;
    case 'SUBSCRIPTIONS':
      return Icons.subscriptions_rounded;
    case 'HOME_REPAIR':
      return Icons.handyman_rounded;
    case 'PETS':
      return Icons.pets_rounded;
    case 'ENTERTAINMENT':
      return Icons.celebration_rounded;
    case 'TRANSPORT':
      return Icons.directions_bus_rounded;
    case 'HEALTH_BEAUTY':
      return Icons.spa_rounded;
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
    case 'CLEANING':
      return const Color(0xFF4FA3A5);
    case 'EATING_OUT':
      return const Color(0xFFE2725B);
    case 'SUBSCRIPTIONS':
      return const Color(0xFF5C6BC0);
    case 'HOME_REPAIR':
      return const Color(0xFF8D7B6A);
    case 'PETS':
      return const Color(0xFFC2885B);
    case 'ENTERTAINMENT':
      return const Color(0xFFD97BA6);
    case 'TRANSPORT':
      return const Color(0xFF3E92CC);
    case 'HEALTH_BEAUTY':
      return const Color(0xFF66A68B);
    default:
      return const Color(0xFF9AA0B5);
  }
}
