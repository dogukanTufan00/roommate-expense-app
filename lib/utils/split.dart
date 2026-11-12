// Helpers for expense splits.
//
// Money and percents are compared as whole hundredths (cents, or hundredths of
// a percent), so the "does it add up?" check never trips on floating point errors.

// Parses "12,50" and "12.50" the same way. Returns null for anything that is not a finite number.
double? parseDecimal(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite) return null;
  return value;
}

// True when the value has at most 2 decimals, for example 33.33 but not 33.333.
bool hasAtMostTwoDecimals(double value) {
  final scaled = value * 100;
  return (scaled - scaled.round()).abs() < 1e-6;
}

// Converts to whole hundredths, for example 60.5 -> 6050.
int toHundredths(double value) => (value * 100).round();

// Splits a total (in hundredths) into [count] parts that add up exactly.
// The first parts get the extra units: 10000 / 3 -> [3334, 3333, 3333].
List<int> splitEvenly(int total, int count) {
  if (count <= 0) return const [];
  final base = total ~/ count;
  final remainder = total % count;
  return [
    for (var i = 0; i < count; i++) base + (i < remainder ? 1 : 0),
  ];
}

// Plain text for a value with at most 2 decimals, without trailing zeros.
// Used to prefill text fields: 60 -> "60", 33.5 -> "33.5", 33.33 -> "33.33".
String numberText(double value) {
  final text = value.toStringAsFixed(2);
  if (text.endsWith('.00')) return text.substring(0, text.length - 3);
  if (text.endsWith('0')) return text.substring(0, text.length - 1);
  return text;
}
