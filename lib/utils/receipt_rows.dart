// Groups the text lines that ML Kit finds into printed rows. A product name on the left
// and its price on the right are two separate lines; they belong to one row:
// "Lahmacun 160,00". Pure Dart (only dart:ui for Offset).
//
// Why the tilt matters: a receipt photo is almost never perfectly straight, and a long
// receipt is often curved. At 3 degrees, the right edge of an 800 px wide receipt sits
// about 40 px higher than the left edge, which is a whole printed row. Without a fix,
// every price lands on the row above its product. So each line's height is first
// corrected with the local tilt of the receipt, measured from the long lines nearby
// (short lines like "*99.00" report no useful angle of their own).
import 'dart:math' as math;
import 'dart:ui';

// One recognized line of text and its four corners on the photo, in ML Kit's order:
// top-left, top-right, bottom-right, bottom-left.
class OcrLine {
  const OcrLine(this.text, this.corners);

  final String text;
  final List<Offset> corners;
}

// Lines with at least this many letters/digits are long enough to measure the tilt.
const _minCharsForAngle = 8;
// Lines further apart than this (in pixels, vertically) don't share a local tilt.
const _angleWindow = 250.0;
// Angles beyond this are not receipt tilt (e.g. a rotated logo or a signature).
const _maxAngle = 20.0;
// A line joins a row when its corrected height is within this share of the line height.
const _rowTolerance = 0.6;

// Returns one string per printed row, from the top of the receipt to the bottom.
List<String> buildReceiptRows(List<OcrLine> lines) {
  final measured = [
    for (final line in lines)
      if (line.text.trim().isNotEmpty) _Measured(line),
  ];
  if (measured.isEmpty) return [];

  // Tilt references: long lines with a believable angle.
  final refs = measured
      .where((m) => m.chars >= _minCharsForAngle && m.angle.abs() <= _maxAngle)
      .toList();
  final globalAngle = refs.isEmpty ? 0.0 : _median(refs.map((r) => r.angle).toList());

  // Straighten every line: its height as if the receipt were not tilted.
  for (final m in measured) {
    final near = refs
        .where((r) => (r.centerY - m.centerY).abs() <= _angleWindow)
        .map((r) => r.angle)
        .toList();
    final angle = near.length >= 3 ? _median(near) : globalAngle;
    m.straightY = m.centerY - m.centerX * math.tan(angle * math.pi / 180);
  }

  // Top to bottom, then group lines that sit at the same straightened height.
  measured.sort((a, b) => a.straightY.compareTo(b.straightY));
  final rows = <List<_Measured>>[];
  for (final m in measured) {
    if (rows.isNotEmpty && _joinsRow(rows.last, m)) {
      rows.last.add(m);
    } else {
      rows.add([m]);
    }
  }

  // Inside each row, read from left to right and join with one space.
  return [
    for (final row in rows)
      ([...row]..sort((a, b) => a.centerX.compareTo(b.centerX)))
          .map((m) => m.text)
          .join(' '),
  ];
}

bool _joinsRow(List<_Measured> row, _Measured m) {
  final rowY = _median(row.map((r) => r.straightY).toList());
  final rowHeight = _median(row.map((r) => r.height).toList());
  return (m.straightY - rowY).abs() <= _rowTolerance * rowHeight;
}

// A line with the numbers the grouping needs, worked out once.
class _Measured {
  _Measured(OcrLine line)
      : text = line.text.trim(),
        chars = line.text.replaceAll(RegExp(r'\s'), '').length {
    final c = line.corners;
    centerX = c.map((p) => p.dx).reduce((a, b) => a + b) / c.length;
    centerY = c.map((p) => p.dy).reduce((a, b) => a + b) / c.length;
    if (c.length == 4) {
      // Height across the text (left and right edges), angle along the top edge.
      height = ((c[0] - c[3]).distance + (c[1] - c[2]).distance) / 2;
      angle = math.atan2(c[1].dy - c[0].dy, c[1].dx - c[0].dx) * 180 / math.pi;
    } else {
      final ys = c.map((p) => p.dy);
      height = ys.reduce(math.max) - ys.reduce(math.min);
      angle = 0;
    }
    if (height <= 0) height = 1;
    straightY = centerY;
  }

  final String text;
  final int chars;
  late final double centerX;
  late final double centerY;
  late final double height;
  late final double angle;
  late double straightY;
}

// The middle value of a list of numbers (the average of the two middle ones for an even count).
double _median(List<double> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[middle];
  return (sorted[middle - 1] + sorted[middle]) / 2;
}
