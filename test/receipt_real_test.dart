// End-to-end tests on REAL ML Kit output of four receipt photos taken with the phone
// (test/fixtures/ocr_*.json, personal data removed): rows are built with
// buildReceiptRows and then parsed. Unlike receipt_parser_test.dart, the text here has
// real OCR mistakes: "%1." read as "21.", "%10" as "210", "MI%1.0" as "WIH1.0",
// "BEDELİ" as "BEDELÍ", "Toplam" as "Top lan" (with its amount not read at all).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_expense_app/utils/receipt_parser.dart';
import 'package:roommate_expense_app/utils/receipt_rows.dart';
import 'package:roommate_expense_app/utils/search.dart';

ReceiptData scan(String name) {
  final raw = jsonDecode(File('test/fixtures/ocr_$name.json').readAsStringSync()) as List;
  final lines = [
    for (final l in raw.cast<Map<String, dynamic>>())
      OcrLine(l['t'] as String, [
        for (final p in (l['c'] as List).cast<List>()) Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
      ]),
  ];
  return parseReceipt(buildReceiptRows(lines));
}

// Product names compared without case and Turkish letters (OCR often drops the dot of İ).
List<String> folded(ReceiptData r) => [for (final i in r.items) normalizeForSearch(i.name)];

// A cleaned name never ends with leftovers of the VAT column like "21.", "210", "*1.0", "%1.".
final vatLeftover = RegExp(r'([%*]\s*\d|\d[.,]?\d?\.?)$');

void main() {
  group('File Market (real photo)', () {
    final r = scan('file');

    test('total', () => expect(r.total, 468.80));
    test('date', () => expect(r.date, DateTime(2026, 11, 10)));
    test('store and category', () {
      expect(r.storeName, 'File Market');
      expect(r.category, 'GROCERIES');
    });
    test('four products with the right prices; the two milks are merged', () {
      expect(folded(r), [
        'if kabak 150g harras',
        'alisveris poseti',
        'zencefil3lu organuca',
        'proteinli sut 500ml',
      ]);
      expect(r.items.map((i) => i.price).toList(), [99.00, 1.00, 189.00, closeTo(179.80, 0.001)]);
      expect(r.items.last.quantity, '2 adet');
      expect(r.items.take(3).every((i) => i.quantity == null), isTrue);
    });
  });

  group('A101 (real photo)', () {
    final r = scan('a101');

    test('total', () => expect(r.total, 284.00));
    test('date with slashes', () => expect(r.date, DateTime(2026, 11, 10)));
    test('store and category', () {
      expect(r.storeName, 'A101');
      expect(r.category, 'GROCERIES');
    });
    test('four products, Coca-Cola included, "2 X 75.00" goes to Kaan', () {
      final names = folded(r);
      expect(names.length, 4);
      expect(names[0], startsWith('cerezza 117 g sut'));
      expect(names[1], 'cips nht pro fstkezm');
      expect(names[2], 'ssiz500mlcocacola');
      expect(names[3], startsWith('kaan 300ml pro.lak'));
      expect(r.items.map((i) => i.price).toList(), [54.50, 39.50, 40.00, 150.00]);
      expect(r.items[3].quantity, '2 adet');
    });
    test('no VAT leftovers at the end of names', () {
      for (final i in r.items) {
        expect(vatLeftover.hasMatch(i.name), isFalse, reason: i.name);
      }
    });
  });

  group('Kırmızı Pide (real photo, prices not readable)', () {
    final r = scan('pide');

    test('total = Ara Toplam - İndirim, because the Toplam amount was not read', () {
      expect(r.total, 335.00);
    });
    test('store without the OCR accent noise', () {
      expect(normalizeForSearch(r.storeName ?? ''), 'kirmizi pide');
      expect(r.category, isNull);
    });
    test('garbled date "15.11206" is not used', () => expect(r.date, isNull));
    test('rows without prices are not products', () => expect(r.items, isEmpty));
  });

  group('DESKİ water bill (real photo, curved)', () {
    final r = scan('deski');

    test('total from "FATURA BEDELÍ 301, 00"', () => expect(r.total, 301.00));
    test('bill date, not the due date', () => expect(r.date, DateTime(2026, 10, 3)));
    test('store and category', () {
      expect(r.storeName, 'DESKİ');
      expect(r.category, 'UTILITIES');
    });
    test('no products on a bill', () => expect(r.items, isEmpty));
  });

  group('File Market names have no VAT leftovers', () {
    final r = scan('file');
    test('names are clean', () {
      for (final i in r.items) {
        expect(vatLeftover.hasMatch(i.name), isFalse, reason: i.name);
      }
    });
  });
}
