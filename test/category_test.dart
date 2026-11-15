// Tests for the expense categories (C-13): the 12 codes, their labels, the fallback
// for unknown codes, and the receipt parser's guesses for the new categories.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/l10n/app_localizations_en.dart';
import 'package:roommate_expense_app/l10n/app_localizations_tr.dart';
import 'package:roommate_expense_app/utils/category.dart';
import 'package:roommate_expense_app/utils/receipt_parser.dart';

void main() {
  // The generated classes give the texts without a widget tree.
  final AppLocalizations tr = AppLocalizationsTr();
  final AppLocalizations en = AppLocalizationsEn();

  group('expenseCategories list', () {
    test('has 12 unique codes', () {
      expect(expenseCategories.length, 12);
      expect(expenseCategories.toSet().length, 12);
    });

    test('keeps the old codes first and OTHER last', () {
      expect(expenseCategories.take(3).toList(), ['RENT', 'UTILITIES', 'GROCERIES']);
      expect(expenseCategories.last, 'OTHER');
    });
  });

  group('labels', () {
    test('every code has a non-empty Turkish label', () {
      for (final code in expenseCategories) {
        expect(categoryLabel(tr, code).trim(), isNotEmpty, reason: code);
      }
    });

    test('every code has its own English label', () {
      for (final code in expenseCategories) {
        expect(categoryLabel(en, code).trim(), isNotEmpty, reason: code);
      }
    });

    test('no code except OTHER shows the OTHER label (a missing case would)', () {
      for (final code in expenseCategories) {
        if (code == 'OTHER') continue;
        expect(categoryLabel(tr, code), isNot(tr.categoryOther), reason: code);
        expect(categoryIcon(code), isNot(Icons.category), reason: code);
      }
    });
  });

  group('unknown code', () {
    test('falls back to the OTHER look without throwing', () {
      expect(categoryLabel(tr, 'SOMETHING_NEW'), tr.categoryOther);
      expect(categoryIcon('SOMETHING_NEW'), Icons.category);
      expect(categoryColor('SOMETHING_NEW'), categoryColor('OTHER'));
    });
  });

  group('receipt categories', () {
    test('GRATIS KOZMETIK A.S. is health and beauty', () {
      final r = parseReceipt(['GRATIS KOZMETIK A.S.']);
      expect(r.category, 'HEALTH_BEAUTY');
      expect(r.storeName, 'Gratis');
    });

    test('a kebab shop and a durum (wrap) row is eating out', () {
      final r = parseReceipt([
        'Kebapçı Mehmet',
        '1 Adana Dürüm 180,00',
        'Toplam 180,00',
      ]);
      expect(r.category, 'EATING_OUT');
    });
  });
}
