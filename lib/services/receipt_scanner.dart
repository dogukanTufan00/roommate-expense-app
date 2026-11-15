import 'dart:convert';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:roommate_expense_app/utils/receipt_parser.dart';
import 'package:roommate_expense_app/utils/receipt_rows.dart';

// Reads a receipt photo on the phone with ML Kit. It needs no internet and costs nothing.
// Returns what the parser could find on the receipt.
Future<ReceiptData> scanReceiptImage(String imagePath) async {
  // Latin letters are enough for Turkish receipts.
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await recognizer.processImage(inputImage);

    // Every text line with its four corners on the photo (they carry the tilt).
    final lines = [
      for (final block in recognized.blocks)
        for (final line in block.lines)
          OcrLine(line.text, [
            for (final p in line.cornerPoints) Offset(p.x.toDouble(), p.y.toDouble()),
          ]),
    ];
    // Only in a tuning build (--dart-define=RECEIPT_DEBUG=true): writes the raw OCR
    // result to logcat, so new real receipts can be turned into test data.
    if (_receiptDebug) _debugDump(recognized);
    return parseReceipt(buildReceiptRows(lines));
  } finally {
    // Always free the recognizer, even when reading fails.
    await recognizer.close();
  }
}

// Off in normal builds, so receipt text never ends up in the phone's log.
const _receiptDebug = bool.fromEnvironment('RECEIPT_DEBUG');

// Tuning builds only: one logcat line per recognized text line (text, angle, corners,
// words), between EVCE_OCR_BEGIN and EVCE_OCR_END. Read with: adb logcat -d -v raw -s flutter
void _debugDump(RecognizedText recognized) {
  // ignore: avoid_print
  print('EVCE_OCR_BEGIN');
  for (final block in recognized.blocks) {
    for (final line in block.lines) {
      // ignore: avoid_print
      print('EVCE_OCR ${jsonEncode({
        't': line.text,
        'a': line.angle,
        'c': [for (final p in line.cornerPoints) [p.x, p.y]],
        'e': [
          for (final e in line.elements)
            {'t': e.text, 'c': [for (final p in e.cornerPoints) [p.x, p.y]]}
        ],
      })}');
    }
  }
  // ignore: avoid_print
  print('EVCE_OCR_END');
}
