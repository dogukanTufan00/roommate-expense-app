// Tests for buildReceiptRows: joining ML Kit's lines into printed rows, also when the
// receipt photo is tilted or the receipt is curved.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_expense_app/utils/receipt_rows.dart';

// Real ML Kit output (personal data replaced) from test/fixtures/ocr_<name>.json.
List<OcrLine> fixture(String name) {
  final raw = jsonDecode(File('test/fixtures/ocr_$name.json').readAsStringSync()) as List;
  return [
    for (final l in raw.cast<Map<String, dynamic>>())
      OcrLine(l['t'] as String, [
        for (final p in (l['c'] as List).cast<List>()) Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
      ]),
  ];
}

// A line drawn as a box of [w] x [h] at top-left (x, y), turned by [degrees] around its
// top-left corner, like a word on a tilted photo.
OcrLine tilted(String text, double x, double y, double w, double h, double degrees) {
  final a = degrees * math.pi / 180;
  Offset at(double dx, double dy) =>
      Offset(x + dx * math.cos(a) - dy * math.sin(a), y + dx * math.sin(a) + dy * math.cos(a));
  return OcrLine(text, [at(0, 0), at(w, 0), at(w, h), at(0, h)]);
}

void main() {
  test('flat receipt: name on the left and price on the right make one row', () {
    final rows = buildReceiptRows([
      tilted('*160,00', 600, 102, 90, 30, 0),
      tilted('1 Lahmacun', 20, 100, 200, 30, 0),
      tilted('*35,00', 610, 152, 80, 30, 0),
      tilted('1 Ayran 170 ml', 20, 150, 240, 30, 0),
    ]);
    expect(rows, ['1 Lahmacun *160,00', '1 Ayran 170 ml *35,00']);
  });

  test('receipt tilted by 4 degrees: each price stays with its own product', () {
    // Rising to the right: every point further right sits higher (smaller y).
    const deg = -4.0;
    final t = math.tan(deg * math.pi / 180);
    final lines = <OcrLine>[];
    for (var i = 0; i < 5; i++) {
      final y = 100.0 + i * 40; // rows are 40 px apart, lines 30 px high
      lines.add(tilted('PRODUCT NUMBER $i', 10, y, 300, 30, deg));
      // The price is 600 px to the right, so it sits about 42 px higher: a whole row.
      lines.add(tilted('*$i.50', 610, y + 600 * t, 80, 30, 0));
    }
    expect(buildReceiptRows(lines), [for (var i = 0; i < 5; i++) 'PRODUCT NUMBER $i *$i.50']);
  });

  test('empty input and blank lines', () {
    expect(buildReceiptRows(const []), isEmpty);
    expect(buildReceiptRows([tilted('   ', 0, 0, 10, 10, 0)]), isEmpty);
  });

  test('real File Market photo (-3 degrees): prices on their own rows', () {
    final rows = buildReceiptRows(fixture('file'));
    expect(rows, containsAllInOrder([
      'if KABAK 150G HARRAS 21. *99.00',
      'ALIŞVERIS POŞETI 20 *1.00',
      'ZENCEFIL3LÜ ORGANUCA 210 *189.00',
      'PROTEINLİ SÜT 500ML %1. *89.90',
      'PROTEINLİ SÜT 500ML %1. *89.90',
      'TOPLAM KDV *20.11',
      'Odenecek KDV Dahil Tutar *468.80',
    ]));
  });

  test('real A101 photo: the "2 X 75.00" row stays above its product', () {
    final rows = buildReceiptRows(fixture('a101'));
    expect(rows, containsAllInOrder([
      'ŞSIZ500MLCOCACOLA 10. *40.00',
      '2 X 75.00',
      'KAAN 300ML PRO.LAK.*1.0 *150.00',
      'ÖDENECEK TUTAR * 284.00',
    ]));
  });

  test('real Kırmızı Pide photo: the courier platform shares the customer row', () {
    final rows = buildReceiptRows(fixture('pide'));
    expect(rows.first, 'Kirmìzi Pide');
    expect(rows, contains('Ali K, Migros'));
    expect(rows, contains('Ara Toplam : 560,00'));
  });

  test('real DESKİ bill (curved, more tilted at the bottom): total on its row', () {
    final rows = buildReceiptRows(fixture('deski'));
    expect(rows, contains('FATURA BEDELÍ 301, 00'));
    // Subscriber and bill numbers are placeholders (000000) in the fixture.
    expect(rows, contains('000000 03. 10.2026 000000000 2026/10'));
  });
}
