// Reads the text of a receipt (one string per printed row) and finds the total, date,
// store, category and product lines. Pure Dart, so the rules can be tested without a phone.
// Text is compared with normalizeForSearch, so "ÖDENECEK" and "Odenecek" are the same.
import 'package:roommate_expense_app/utils/search.dart';

// One product line of a receipt.
class ReceiptItem {
  const ReceiptItem({required this.name, this.quantity, this.price});

  final String name;
  // For example "2 adet" or "0,856 kg". Null when it is just one piece.
  final String? quantity;
  final double? price;
}

// Everything we could find on a receipt. Every field can be null.
class ReceiptData {
  const ReceiptData({
    this.total,
    this.date,
    this.storeName,
    this.category,
    this.items = const <ReceiptItem>[],
  });

  final double? total;
  final DateTime? date;
  final String? storeName;
  final String? category;
  final List<ReceiptItem> items;
}

// Main entry point: takes the rows of the receipt, returns what we could read from them.
ReceiptData parseReceipt(List<String> rows) {
  // Fold OCR accents first, then drop empty rows and extra spaces.
  final lines = rows
      .map((row) => _foldAccents(row.trim()))
      .where((row) => row.isNotEmpty)
      .toList();
  final store = _findKnownStore(lines);
  // A known chain decides the category. Only when none matched, the words guess it.
  final category = store?.category ?? _categoryFromKeywords(lines);
  return ReceiptData(
    total: _findTotal(lines),
    date: _findDate(lines),
    storeName: store?.name ?? _fallbackStoreName(lines),
    category: category,
    // A utility bill has no products we want to list.
    items: category == 'UTILITIES' ? const <ReceiptItem>[] : _findItems(lines),
  );
}

// One line of the product list, as text: "Name · 2 adet · 179,80 ₺".
// Parts that are null are left out.
String formatReceiptItem(ReceiptItem item) {
  final parts = <String>[item.name];
  if (item.quantity != null) parts.add(item.quantity!);
  if (item.price != null) parts.add('${_formatAmount(item.price!)} ₺');
  return parts.join(' · ');
}

// 179.8 becomes "179,80" (Turkish decimal comma, always two decimals).
String _formatAmount(double value) => value.toStringAsFixed(2).replaceAll('.', ',');

// ---------------------------------------------------------------------------
// Words and text helpers
// ---------------------------------------------------------------------------

// Accents that OCR adds by mistake, mapped to the plain letter. "Í" becomes "İ" so that
// normalizeForSearch turns it into "i" (not "ı"). ç ğ ı ö ş ü İ are not in the map.
const Map<String, String> _accentFolds = {
  'Í': 'İ', 'Ì': 'İ', 'Î': 'İ', 'Ï': 'İ',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'Á': 'A', 'À': 'A', 'Â': 'A', 'Ä': 'A',
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a',
  'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o',
  'Ú': 'U', 'Ù': 'U', 'Û': 'U',
  'ú': 'u', 'ù': 'u', 'û': 'u',
  'Ñ': 'N', 'ñ': 'n',
};

// Replaces the accented letters of [_accentFolds] with plain letters.
String _foldAccents(String text) {
  var out = text;
  _accentFolds.forEach((accented, plain) => out = out.replaceAll(accented, plain));
  return out;
}

// Folds Turkish letters and lowercases, for example "ÖDENECEK" becomes "odenecek".
String _fold(String text) => normalizeForSearch(text);

// Turkish lowercase: "İ" must become "i" and "I" must become "ı".
// Dart's toLowerCase does not do this by itself.
// English-looking words ending in "ING" (like "STARKING") keep a plain "i".
String _turkishLower(String text) {
  return text.splitMapJoin(
    RegExp(r'\S+'),
    onMatch: (match) {
      final word = match.group(0)!;
      final plainI = word.toUpperCase().endsWith('ING');
      final fixed = word.replaceAll('İ', 'i').replaceAll('I', plainI ? 'i' : 'ı');
      return fixed.toLowerCase();
    },
    onNonMatch: (other) => other,
  );
}

// "PROTEİNLİ SÜT" becomes "Proteinli süt": first letter capital, the rest small.
String _sentenceCase(String text) {
  final lower = _turkishLower(text);
  if (lower.isEmpty) return lower;
  final first = lower[0] == 'i' ? 'İ' : lower[0].toUpperCase();
  return first + lower.substring(1);
}

// Splits a folded row into words and removes punctuation, so "MİGROS:" gives "migros".
List<String> _words(String folded) => folded
    .split(RegExp(r'\s+'))
    .map((word) => word.replaceAll(RegExp(r'[^a-z0-9]'), ''))
    .toList();

// True when the row has at least [count] letters (digits and symbols do not count).
bool _hasLetters(String text, {int count = 1}) {
  final letters = RegExp(r'\p{L}', unicode: true).allMatches(text).length;
  return letters >= count;
}

// ---------------------------------------------------------------------------
// Money
// ---------------------------------------------------------------------------

// An amount at the END of a row, like "*99.00", "301, 00" or "*1.234,56".
// Group 1 is the whole part (it may have . or , as thousands separators).
// Group 2 is the two decimals. Plain integers such as "200" or "2025" do not match.
// The star may touch the amount or have a space before it. A digit, dot, comma or "%"
// before the amount means it is part of a VAT leftover, not a price.
final RegExp _moneyAtEnd =
    RegExp(r'(?:^|(?<![\d.,%]))\*?\s*(\d{1,3}(?:[.,]\d{3})+|\d+)[.,]\s*(\d{2})$');

// The same amount anywhere in a row (not only at the end), for example "225.00" in
// "Indirim: 225.00 88B". The last match of a row is the amount.
final RegExp _moneyAnywhere =
    RegExp(r'(?:^|(?<![\d.,%]))\*?\s*(\d{1,3}(?:[.,]\d{3})+|\d+)[.,]\s*(\d{2})(?!\d)');

// The amount of a money match, for example "1.234,56" becomes 1234.56.
double _amountOf(RegExpMatch match) {
  final whole = match.group(1)!.replaceAll(RegExp(r'[.,]'), '');
  final cents = match.group(2)!;
  return int.parse(whole) + int.parse(cents) / 100;
}

// The amount at the end of a row, or null when the row does not end with money.
double? _priceAtEnd(String row) {
  final match = _moneyAtEnd.firstMatch(row);
  return match == null ? null : _amountOf(match);
}

// The last amount anywhere in a row, or null when the row has no amount.
double? _lastMoney(String row) {
  final matches = _moneyAnywhere.allMatches(row).toList();
  return matches.isEmpty ? null : _amountOf(matches.last);
}

// The amount of a total-like row: the amount at its end, or else the last amount in it.
double? _moneyIn(String row) => _priceAtEnd(row) ?? _lastMoney(row);

// Used only when no total row had an amount: "Ara toplam" minus "İndirim", or the
// "Ara toplam" alone when there is no discount amount.
double? _totalFromSubtotal(List<String> lines) {
  double? subtotal;
  double? discount;
  for (final line in lines) {
    final folded = _fold(line);
    if (subtotal == null && folded.contains('ara toplam')) subtotal = _moneyIn(line);
    if (discount == null && folded.contains('indirim')) discount = _moneyIn(line);
  }
  if (subtotal == null) return null;
  if (discount == null) return subtotal;
  // Rounded to two decimals, so 560.00 - 225.00 is exactly 335.00.
  return ((subtotal - discount) * 100).round() / 100;
}

// ---------------------------------------------------------------------------
// Total
// ---------------------------------------------------------------------------

// Looks for the total in priority order. The first row of the highest priority that
// has an amount at its end wins. "Ara toplam", "indirim" and "kdv" rows are never used
// for the plain "toplam" rule (priority 4).
double? _findTotal(List<String> lines) {
  final tiers = <bool Function(String folded)>[
    // 1) "Ödenecek": the amount the customer actually pays.
    (folded) => folded.contains('odenecek'),
    // 2) "Genel toplam".
    (folded) => folded.contains('genel toplam'),
    // 3) "Fatura bedeli" or "fatura tutarı" (bills).
    (folded) => folded.contains('fatura bedeli') || folded.contains('fatura tutari'),
    // 4) A plain "Toplam" row.
    _isPlainTotalRow,
  ];
  for (final isMatch in tiers) {
    for (final line in lines) {
      if (!isMatch(_fold(line))) continue;
      final price = _moneyIn(line);
      if (price != null) return price;
    }
  }
  return _totalFromSubtotal(lines);
}

// A row that starts with "toplam" but is not a VAT total or a subtotal.
// "Ara toplam" and "mal/hizmet toplam" do not start with "toplam", so they never match here.
bool _isPlainTotalRow(String folded) {
  if (!folded.startsWith('toplam')) return false;
  return !folded.contains('kdv') && !folded.contains('topkdv');
}

// ---------------------------------------------------------------------------
// Date
// ---------------------------------------------------------------------------

// A date like "10.11.2026", "10/11/2026" or "03. 10. 2026".
final RegExp _dateInRow = RegExp(r'(?<!\d)(\d{1,2})\s*[./]\s*(\d{1,2})\s*[./]\s*(\d{4})(?!\d)');

// Rows with these words show other dates (due date, previous reading, old bill date).
const List<String> _otherDateWords = ['son odeme', 'onceki', 'tarihli'];

// The first valid date in the rows that are not about other dates. The time is ignored.
DateTime? _findDate(List<String> lines) {
  for (final line in lines) {
    if (_otherDateWords.any(_fold(line).contains)) continue;
    for (final match in _dateInRow.allMatches(line)) {
      final date = _validDate(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
      if (date != null) return date;
    }
  }
  return null;
}

// Returns the date, or null when it does not exist (for example 31.02).
DateTime? _validDate(int day, int month, int year) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final date = DateTime(year, month, day);
  // DateTime quietly moves 31.02 to 03.03, so we check that nothing moved.
  if (date.day != day || date.month != month) return null;
  return date;
}

// ---------------------------------------------------------------------------
// Store and category
// ---------------------------------------------------------------------------

// A chain we know. The key is the folded name, for example "turk telekom" (two words).
class _KnownStore {
  const _KnownStore(this.key, this.name, this.category);

  final String key;
  final String name;
  final String category;
}

const List<_KnownStore> _knownStores = [
  // Groceries.
  _KnownStore('migros', 'Migros', 'GROCERIES'),
  _KnownStore('a101', 'A101', 'GROCERIES'),
  _KnownStore('bim', 'BİM', 'GROCERIES'),
  _KnownStore('sok', 'ŞOK', 'GROCERIES'),
  _KnownStore('file', 'File Market', 'GROCERIES'),
  _KnownStore('carrefoursa', 'CarrefourSA', 'GROCERIES'),
  _KnownStore('metro', 'Metro', 'GROCERIES'),
  _KnownStore('macrocenter', 'Macrocenter', 'GROCERIES'),
  _KnownStore('hakmar', 'Hakmar', 'GROCERIES'),
  _KnownStore('onur', 'Onur Market', 'GROCERIES'),
  // Utility bills.
  _KnownStore('deski', 'DESKİ', 'UTILITIES'),
  _KnownStore('iski', 'İSKİ', 'UTILITIES'),
  _KnownStore('aski', 'ASKİ', 'UTILITIES'),
  _KnownStore('enerjisa', 'Enerjisa', 'UTILITIES'),
  _KnownStore('ck', 'CK Enerji', 'UTILITIES'),
  _KnownStore('aksa', 'Aksa', 'UTILITIES'),
  _KnownStore('igdas', 'İGDAŞ', 'UTILITIES'),
  _KnownStore('turk telekom', 'Türk Telekom', 'UTILITIES'),
  _KnownStore('turkcell', 'Turkcell', 'UTILITIES'),
  _KnownStore('vodafone', 'Vodafone', 'UTILITIES'),
  _KnownStore('superonline', 'Superonline', 'UTILITIES'),
  // Health and beauty.
  _KnownStore('gratis', 'Gratis', 'HEALTH_BEAUTY'),
  _KnownStore('watsons', 'Watsons', 'HEALTH_BEAUTY'),
  _KnownStore('rossmann', 'Rossmann', 'HEALTH_BEAUTY'),
  _KnownStore('eve', 'Eve', 'HEALTH_BEAUTY'),
  // Home and repairs.
  _KnownStore('koctas', 'Koçtaş', 'HOME_REPAIR'),
  _KnownStore('ikea', 'IKEA', 'HOME_REPAIR'),
  _KnownStore('bauhaus', 'Bauhaus', 'HOME_REPAIR'),
  _KnownStore('tekzen', 'Tekzen', 'HOME_REPAIR'),
];

// Finds a known chain: its name must be the FIRST word of one of the first 6 rows.
// So "Ali K. Migros" does not count, because Migros is not the first word there.
_KnownStore? _findKnownStore(List<String> lines) {
  for (final line in lines.take(6)) {
    final words = _words(_fold(line));
    for (final store in _knownStores) {
      if (_startsWithWords(words, store.key.split(' '))) return store;
    }
  }
  return null;
}

// True when the words of a row start with the words of the key.
bool _startsWithWords(List<String> words, List<String> keyWords) {
  if (words.length < keyWords.length) return false;
  for (var i = 0; i < keyWords.length; i++) {
    if (words[i] != keyWords[i]) return false;
  }
  return true;
}

// Words that point to a category when no known chain was found.
// They are matched as whole words, so "pide" does not match inside another word.
const List<String> _restaurantWords = [
  'lahmacun', 'pide', 'kebap', 'doner', 'durum', 'restoran', 'restaurant', 'lokanta',
  'cafe', 'kafe', 'burger', 'pizza', 'yemeksepeti', 'afiyet',
  // Turkish shop names: "Kebapçı Mehmet", "Pideci", "Dönerci", "... Lokantası", "Börekçi".
  'kebapci', 'pideci', 'donerci', 'lokantasi', 'borekci', 'kofteci',
];
const List<String> _petWords = ['mama', 'petshop', 'veteriner', 'kum'];
const List<String> _pharmacyWords = ['eczane'];

// Guesses the category from the words of all rows. Only used when no chain matched.
// The order is the priority: restaurant words first, then pets, then pharmacy.
String? _categoryFromKeywords(List<String> lines) {
  // Every word of every row, folded, so "KIRMIZI PIDE" gives "pide".
  final allWords = <String>{};
  for (final line in lines) {
    allWords.addAll(_words(_fold(line)));
  }
  if (_restaurantWords.any(allWords.contains)) return 'EATING_OUT';
  if (_petWords.any(allWords.contains)) return 'PETS';
  if (_pharmacyWords.any(allWords.contains)) return 'HEALTH_BEAUTY';
  return null;
}

// Rows that are headers on a receipt, not the store name.
const List<String> _headerPrefixes = ['e-arsiv', 'fatura', 't.c.', 'm.adi', 'www', 'http'];

// When no known chain is found, the store is the first row with letters that is not a header.
String? _fallbackStoreName(List<String> lines) {
  for (final line in lines) {
    if (!_hasLetters(line)) continue;
    final folded = _fold(line);
    if (_headerPrefixes.any(folded.startsWith)) continue;
    return line;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Products
// ---------------------------------------------------------------------------

// Words that show a row is a total, a VAT line or a discount. Products are listed only
// above the first row like this.
final RegExp _kdvWord = RegExp(r'\bkdv\b');

bool _isTotalLikeRow(String folded) {
  return folded.contains('toplam') ||
      folded.contains('odenecek') ||
      folded.contains('fatura bedeli') ||
      _kdvWord.hasMatch(folded) ||
      folded.contains('indirim');
}

// Header and info rows (date, tax number, card, table titles) that can have a number
// at the end but are not products.
const List<String> _infoRowPrefixes = [
  'e-arsiv', 'fatura', 't.c.', 'm.adi', 'www', 'http', 'tarih', 'saat', 'vergi',
  'tckn', 'ettn', 'kasiyer', 'onay', 'belge', 'sira', 'provizyon', 'puan',
  'kdv orani', 'mk ', 'abone', 'okuma', 'sayac', 'ref',
];

bool _isInfoRow(String folded) => _infoRowPrefixes.any(folded.startsWith);

// A row that only says how many, like "2 X 75.00" or "0,856 KG X 39,90".
// It is not a product. It sets the quantity of the NEXT product.
final RegExp _quantityRow = RegExp(
  r'^(\d+(?:[.,]\d+)?)\s*(kg|gr|g|lt|l)?\s*x\s*[\d.,*\s]+$',
  caseSensitive: false,
);

// The quantity of a quantity row. "2" with no unit becomes count 2,
// "0,856" with "KG" becomes the label "0,856 kg".
class _Quantity {
  const _Quantity({this.count = 1, this.label});

  final int count;
  final String? label;
}

_Quantity _quantityFrom(String number, String? unit) {
  if (unit != null) return _Quantity(label: '$number ${unit.toLowerCase()}');
  return _Quantity(count: int.tryParse(number) ?? 1);
}

// The text of a quantity, or null for one piece.
String? _quantityText(int count, String? label) {
  if (label != null) return label;
  return count > 1 ? '$count adet' : null;
}

// A product while we collect them. Same names are merged into one of these.
class _RawItem {
  _RawItem(this.name, this.quantity, this.price) : count = quantity.count;

  final String name;
  final _Quantity quantity;
  double price;
  int count;
}

// One VAT leftover at the end of a name, as OCR reads it: "%1.", "%20", "21.", "210",
// "%10.", "WIH1.0" or "*1.0". The number must be a Turkish VAT rate (1, 8, 10, 18, 20),
// so a product size like "COLA 250" or "ICE TEA 330" is kept. It must also follow a
// space, a letter or a dot.
final RegExp _vatRateAtEnd = RegExp(
  r'\s*(?:^|(?<=[\s.\p{L}]))[%*HhZz2]?(?:1|8|10|18|20)(?:[.,]\d{0,2})?\.?$',
  unicode: true,
);

// The product name without its VAT leftover, and without stars, "%" and spaces at the end.
String _cleanName(String text) {
  // The text before the price may still end with a space (or the star of the price).
  final withoutVat = text.trimRight().replaceFirst(_vatRateAtEnd, '');
  return withoutVat.replaceAll(RegExp(r'[\s*%]+$'), '').trim();
}

// Collects the products above the first total-like row.
List<ReceiptItem> _findItems(List<String> lines) {
  final merged = <String, _RawItem>{};
  _Quantity? pending; // quantity from a "2 X 75.00" row, for the next product
  for (final line in lines) {
    final folded = _fold(line);
    if (_isTotalLikeRow(folded)) break; // products end at the first total-like row
    if (_isInfoRow(folded)) continue;

    final quantityRow = _quantityRow.firstMatch(line);
    if (quantityRow != null) {
      pending = _quantityFrom(quantityRow.group(1)!, quantityRow.group(2));
      continue;
    }

    // A product row needs an amount at its end.
    final priceMatch = _moneyAtEnd.firstMatch(line);
    if (priceMatch == null) continue;
    var name = _cleanName(line.substring(0, priceMatch.start));
    var quantity = pending ?? const _Quantity();

    // A leading small number is the quantity: "1 Lahmacun" or "2 Ayran".
    final leading = RegExp(r'^(\d{1,2})\s+(.+)$').firstMatch(name);
    if (leading != null && pending == null) {
      quantity = _Quantity(count: int.parse(leading.group(1)!));
      name = leading.group(2)!;
    }
    if (!_hasLetters(name, count: 2)) continue;

    pending = null;
    final key = _turkishLower(name);
    final existing = merged[key];
    if (existing == null) {
      merged[key] = _RawItem(name, quantity, _amountOf(priceMatch));
    } else {
      // The same product again: add the count and the price.
      existing.count += quantity.count;
      existing.price += _amountOf(priceMatch);
    }
  }

  return merged.values
      .map((raw) => ReceiptItem(
            name: _sentenceCase(raw.name),
            quantity: _quantityText(raw.count, raw.quantity.label),
            price: raw.price,
          ))
      .toList();
}
