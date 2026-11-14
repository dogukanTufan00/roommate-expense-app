// Text helpers for the expense search. Both the query and the searched fields go through
// normalizeForSearch, so "ırmak", "Irmak" and "ISMAIL" compare the same way.

// Lowercases text with Turkish rules and folds the Turkish letters to plain Latin letters.
// "İ" becomes "i" and "I" becomes "ı" before lowercasing (Dart's own lowercasing would make
// "I" into "i" and "İ" into "i" plus a dot). Then ı, ş, ğ, ü, ö, ç are folded to i, s, g, u, o, c.
// The result is trimmed.
String normalizeForSearch(String input) {
  final lower = input
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase();
  return lower
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .trim();
}
