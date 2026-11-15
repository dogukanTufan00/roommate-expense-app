// Tests for the receipt parser (C-11, reading a receipt photo).
//
// The input is what the app builds from ML Kit's result: one string per printed row,
// with words that sit at the same height joined left to right (so a product name and
// its right-aligned price end up on one row). The four fixtures below are real Turkish
// receipts typed out row by row, with personal data (name, address, phone) removed.
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_expense_app/utils/receipt_parser.dart';

// File Market e-Arşiv receipt. Decimal point, "*" before amounts, VAT rate after names,
// the same product printed twice, and a "TOPLAM KDV" line that is NOT the total.
const fileMarket = [
  'E-Arsiv Fatura',
  'FİLE PAMUKKALE ÜNİVERSİTESİ/PAMUKKA',
  'FİLE MARKET MAĞAZACILIK ANONİM ŞİRKETİ',
  'YUNUS EMRE MAHALLESİ, SÜLEYMAN DEMİREL B',
  'ULVARI 64A PAMUKKALE / DENIZLI',
  'Sarıgazi VDM 3871427056',
  '10.11.2026 15:32 Sira No : 200',
  'ETTN970551fc-9649-4957-84a4-fcd83ae08a6e',
  '237900110116022902OO',
  'TCKN/VKN:11111111111-NIHAI TÜKETICI',
  'İÇ KABAK 150G HARRAS %1. *99.00',
  'ALIŞVERİŞ POŞETİ %20 *1.00',
  'ZENCEFİL3LÜ ORGANUCA %10 *189.00',
  'PROTEİNLİ SÜT 500ML %1. *89.90',
  'PROTEİNLİ SÜT 500ML %1. *89.90',
  'TOPLAM KDV *20.11',
  'Odenecek KDV Dahil Tutar *468.80',
  'Ippos Kredi Kartı (1) *468.80',
  'IS BANKASI',
  'I:704764505 T:S1E6K603 454314******5541',
  '10.11.2026 15:32 B:269 S:63',
  'Onay No:658576 Ref.No:631414730733',
  'KDV MATRAH KDV TUTAR KDV DAHIL',
  '%1. 276.04 *2.76 *278.80',
  '%10 171.82 *17.18 *189.00',
  '%20 0.83 *0.17 *1.00',
  'POS:1 - 463919 - Z**** H**** 940123791',
];

// DESKİ water bill. Decimal comma with a space ("301, 00"), dates with spaces, a due date
// that must not win over the bill date, a table of charges that are NOT products, and a
// larger "419,87 TL" in the footer that is NOT the total.
const deskiBill = [
  'T.C.',
  'DENİZLİ BÜYÜKŞEHİR BELEDİYESİ',
  'DESKİ Genel Müdürlüğü',
  'FATURA',
  'www.deski.gov.tr',
  'ALO DESKİ 185 • 444 9 185 Vergi Dairesi : Saraylar',
  'Vergi No : 2910822784',
  'ABONE NO FATURA TARİHİ FATURA NO DÖNEM',
  '03. 10. 2026 2026/10',
  'T.C. Kimlik',
  'Ad Soyad',
  'Adres :',
  'Abone Türü MESKEN Sayaç No 25035291',
  'Önceki Tarih 03. 09. 2026 S.Damga Yılı 2025',
  'Okuma Tarihi 03. 10. 2026 09:35 Okuyucu No 62',
  'Okuma Durumu NORMAL OKUMA',
  'Önceki Okuma Son Okuma İlave / İade Kullanılan m3',
  '77 83 0 6',
  'Birim Fiyat Kullanılan m3 Tutar Tutarlar',
  '1. Kademe Su Bedeli 177, 88',
  '29,646 6,00 177, 88 Su KDV 1, 78',
  '2. Kademe Atık Su Bedeli 88, 93',
  '77,468 0,00 0,00 Atık Su KDV %10 8, 89',
  '3. Kademe ÇTV 24, 00',
  '120,000 0,00 0,00 Sökme Takma 0, 00',
  'Yuvarlama -0, 48',
  'FATURA BEDELİ 301, 00',
  'SON ÖDEME TARİHİ 12. 10. 2026',
  'ESKİ DÖNEM BORCU 0 ADET 0.0',
  'ABONEYE AİT BİLDİRİM',
  'INDIRIMSIZ 419,87 TL olan su faturanıza,',
  '16.05.2024 tarihli Büyükşehir Belediye',
  'Meclisi kararı ile 118,87 TL INDIRIM yapılmıştır.',
];

// Restaurant delivery slip. Decimal comma, a quantity before each product, "Ara Toplam" and
// "İndirim" that are NOT the total, and the word "Migros" (the delivery platform) that must
// NOT become the store name.
const pideSlip = [
  'Kırmızı Pide',
  'Sip: 13 15.11.2026 02:37',
  'Ali K. Migros',
  'Bina: 6 Kat: 3 Daire: 6',
  '/ Denizli · Migros no:',
  '1503048450',
  'Sip No: 1503048450 #2552411',
  'Mk Ürün Adı Tutar',
  '1 Lahmacun 160,00',
  '1 Ayran (170 Ml 35,00',
  '1 Kuşbaşılı Kaşarlı Pide 170 Ml 365,00',
  'Ayran İkram',
  '-> 1 Porsiyon',
  'Ara Toplam : 560,00',
  'İndirim : 225,00',
  'Toplam : 335,00',
  'Ödeme: Online (ödendi)',
  'ÖDENDİ - kapıda tahsilat YOK',
  'Afiyet Olsun',
  'www.kenvixpos.com',
];

// A101 e-Arşiv receipt. Date with slashes, VAT rate glued to the name ("MI%1.0"), a
// "2 X 75.00" row that belongs to the NEXT product, and several "TOPLAM" rows of which
// only "ÖDENECEK TUTAR" is the amount paid.
const a101 = [
  'e-Arşiv Fatura',
  'M.Adı:Üniversite Pamukk / M.Kodu:E195',
  'A101 YENI MAGAZACILIK A.S.',
  'Yunusemre Mh. 97/A 6449. Sokak',
  'ÜSKÜDAR V.D./9480423762',
  'Tarih: 10/11/2026 Saat : 15:39',
  'Belge No: 1419501101160026145',
  'ETTN :3a26811a-a1ab-49bf-adf8-ba0a97607d12',
  'ÇEREZZA 117 G SÜT MI%1.0 *54.50',
  'ÇİPS NHT PRO FSTKEZM%1.0 *39.50',
  'ŞSİZ500MLCOCACOLA %10. *40.00',
  '2 X 75.00',
  'KAAN.300 ML PRO.LAK.%1.0 *150.00',
  'ARA TOPLAM *284.00',
  'MAL/HIZMET TOPLAM TUTARI * 277.94',
  'TOPKDV * 6.06',
  'ÖDENECEK TUTAR * 284.00',
  'KREDI KARTI *284.00',
  'Işbankası Debit (1)',
  'Provizyon No : 772122',
  'Puan:0.00',
  'IS BANKASI',
  '10.11.2026 15:39 B:2401 S:13',
  'KDV Orani KDV Dahil Tutar KDV',
  '%1.00 *244.00 *2.42',
  '%10.00 *40.00 *3.64',
  'KASIYER ISIMmm : Ö**** K**** Y****',
  'FaturaAdres https://fatura.a101.com.tr',
];

void main() {
  group('File Market receipt', () {
    final r = parseReceipt(fileMarket);

    test('total is the amount to pay, not the VAT total', () {
      expect(r.total, 468.80);
    });
    test('date', () => expect(r.date, DateTime(2026, 11, 10)));
    test('store and category from the known chain', () {
      expect(r.storeName, 'File Market');
      expect(r.category, 'GROCERIES');
    });
    test('products: VAT rate removed, duplicates merged, Turkish sentence case', () {
      expect(r.items.map((i) => i.name).toList(), [
        'İç kabak 150g harras',
        'Alışveriş poşeti',
        'Zencefil3lü organuca',
        'Proteinli süt 500ml',
      ]);
      final milk = r.items.last;
      expect(milk.quantity, '2 adet');
      expect(milk.price, closeTo(179.80, 0.001));
      expect(r.items.first.quantity, isNull);
      expect(r.items.first.price, 99.00);
    });
  });

  group('DESKİ water bill', () {
    final r = parseReceipt(deskiBill);

    test('total is FATURA BEDELİ, with "301, 00" read as 301.00', () {
      expect(r.total, 301.00);
    });
    test('date is the bill date, not the due date or older dates', () {
      expect(r.date, DateTime(2026, 10, 3));
    });
    test('store and category from the known utility', () {
      expect(r.storeName, 'DESKİ');
      expect(r.category, 'UTILITIES');
    });
    test('a utility bill has no products', () => expect(r.items, isEmpty));
  });

  group('Restaurant slip', () {
    final r = parseReceipt(pideSlip);

    test('total is Toplam, not Ara Toplam or İndirim', () => expect(r.total, 335.00));
    test('date', () => expect(r.date, DateTime(2026, 11, 15)));
    test('store is the first row; a chain name later in a row does not count', () {
      expect(r.storeName, 'Kırmızı Pide');
      expect(r.category, 'EATING_OUT'); // restaurant words (pide, lahmacun)
    });
    test('products with a leading quantity of 1; rows without a price are skipped', () {
      expect(r.items.map((i) => i.name).toList(), [
        'Lahmacun',
        'Ayran (170 ml',
        'Kuşbaşılı kaşarlı pide 170 ml',
      ]);
      expect(r.items.every((i) => i.quantity == null), isTrue);
      expect(r.items.map((i) => i.price).toList(), [160.00, 35.00, 365.00]);
    });
  });

  group('A101 receipt', () {
    final r = parseReceipt(a101);

    test('total is ÖDENECEK TUTAR', () => expect(r.total, 284.00));
    test('date with slashes', () => expect(r.date, DateTime(2026, 11, 10)));
    test('store and category', () {
      expect(r.storeName, 'A101');
      expect(r.category, 'GROCERIES');
    });
    test('products: glued VAT rate removed, "2 X 75.00" goes to the next product', () {
      expect(r.items.map((i) => i.name).toList(), [
        'Çerezza 117 g süt mı',
        'Çips nht pro fstkezm',
        'Şsiz500mlcocacola',
        'Kaan.300 ml pro.lak.',
      ]);
      expect(r.items[3].quantity, '2 adet');
      expect(r.items[3].price, 150.00);
      expect(r.items.take(3).every((i) => i.quantity == null), isTrue);
    });
  });

  group('Edge cases', () {
    test('weighed product: "0,856 KG X 39,90" row before the product', () {
      final r = parseReceipt([
        'MİGROS TİCARET A.Ş.',
        '12.11.2026',
        '0,856 KG X 39,90',
        'ELMA STARKING %1 *34,15',
        'TOPLAM *34,15',
      ]);
      expect(r.storeName, 'Migros');
      expect(r.items.single.name, 'Elma starking');
      expect(r.items.single.quantity, '0,856 kg');
      expect(r.items.single.price, 34.15);
      expect(r.total, 34.15);
    });
    test('thousands separator and GENEL TOPLAM', () {
      final r = parseReceipt(['BİM BİRLEŞİK MAĞAZALAR', 'GENEL TOPLAM *1.234,56']);
      expect(r.total, 1234.56);
      expect(r.storeName, 'BİM');
      expect(r.category, 'GROCERIES');
    });
    test('a product size at the end of a name is not mistaken for a VAT rate', () {
      final r = parseReceipt([
        'ŞOK MARKETLER',
        'COLA 250 *25,00',
        'ICE TEA 330 %10 *30,00',
        'TOPLAM *55,00',
      ]);
      expect(r.items.map((i) => i.name).toList(), ['Cola 250', 'Ice tea 330']);
    });
    test('nothing recognisable gives an empty result, never a crash', () {
      final r = parseReceipt(['', '   ', 'merhaba', '12345']);
      expect(r.total, isNull);
      expect(r.date, isNull);
      expect(r.items, isEmpty);
      expect(r.category, isNull);
    });
    test('empty input', () {
      final r = parseReceipt(const []);
      expect(r.total, isNull);
      expect(r.storeName, isNull);
    });
  });

  group('formatReceiptItem (one row of the "Ürünler" field)', () {
    test('with quantity', () {
      expect(
        formatReceiptItem(const ReceiptItem(name: 'Proteinli süt 500ml', quantity: '2 adet', price: 179.80)),
        'Proteinli süt 500ml · 2 adet · 179,80 ₺',
      );
    });
    test('without quantity', () {
      expect(formatReceiptItem(const ReceiptItem(name: 'Lahmacun', price: 160)), 'Lahmacun · 160,00 ₺');
    });
    test('without price', () {
      expect(formatReceiptItem(const ReceiptItem(name: 'Ekmek')), 'Ekmek');
    });
  });
}
