import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/utils/category.dart';
import 'package:roommate_expense_app/utils/format.dart';

// Colors from theme.dart, written for the PDF.
final PdfColor _terracotta = PdfColor.fromHex('#D96C4F');
final PdfColor _ink = PdfColor.fromHex('#3D405B');
final PdfColor _muted = PdfColor.fromHex('#8A8C9E');
final PdfColor _line = PdfColor.fromHex('#EDE4D8');
final PdfColor _cream = PdfColor.fromHex('#FAF3E6');
final PdfColor _mustardSoft = PdfColor.fromHex('#FBEFD3');

// Builds the statement as an A4 PDF and returns its bytes.
// period is the already formatted period, for example "Kasım 2026" or "1 Kas – 15 Kas 2026".
// The fonts are the app's Nunito, so Turkish letters and the ₺ sign print correctly.
Future<Uint8List> buildStatementPdf({
  required Statement statement,
  required AppLocalizations l10n,
  required String localeTag,
  required String period,
}) async {
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Nunito-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Nunito-Bold.ttf'),
  );

  final doc = pw.Document(
    title: l10n.statementPdfTitle,
    author: 'Evce',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  String money(double value) => formatMoneyFor(localeTag, value);
  String percent(double value) => '${formatPercentFor(localeTag, value)}%';
  // Positive differences get a plus sign, negative ones a minus sign.
  String signedMoney(double value) {
    if (value.abs() < 0.005) return money(0);
    final sign = value > 0 ? '+' : '-';
    return '$sign${money(value.abs())}';
  }

  final generated = formatDateFor(localeTag, DateTime.now());
  final dominant = statement.dominantPayer;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 48),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            statement.householdName,
            style: pw.TextStyle(fontSize: 8, color: _muted),
          ),
          pw.Text(
            l10n.statementPdfPage(context.pageNumber, context.pagesCount),
            style: pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
      build: (context) => [
        pw.Text(
          l10n.statementPdfTitle,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: _terracotta,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          statement.householdName,
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          l10n.statementPdfPeriod(period),
          style: pw.TextStyle(fontSize: 10, color: _ink),
        ),
        pw.Text(
          l10n.statementPdfGenerated(generated),
          style: pw.TextStyle(fontSize: 9, color: _muted),
        ),

        _heading(l10n.statementPdfSummary),
        _table(
          headers: [l10n.statementPdfSummary, ''],
          rows: [
            [l10n.statementTotalSpent, money(statement.totalExpenses)],
            [
              l10n.statementExpenseNumber,
              '${statement.expenseCount}',
            ],
            [l10n.statementPaymentsTotal, money(statement.totalPayments)],
            [
              l10n.statementPaymentNumber,
              '${statement.paymentCount}',
            ],
          ],
          rightAligned: {1},
        ),

        if (dominant != null) ...[
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _mustardSoft,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              l10n.statementDominantPayer(
                dominant.name,
                formatPercentFor(localeTag, dominant.paidPercent),
              ),
              style: pw.TextStyle(fontSize: 10, color: _ink),
            ),
          ),
        ],

        _heading(l10n.statementWhoPaid),
        _table(
          headers: [
            l10n.statementColMember,
            l10n.statementColPaid,
            l10n.statementColShare,
            l10n.statementColNet,
            '%',
          ],
          rows: [
            for (final m in statement.members)
              [
                m.active ? m.name : '${m.name} ${l10n.statementLeftTag}',
                money(m.paid),
                money(m.share),
                signedMoney(m.net),
                percent(m.paidPercent),
              ],
          ],
          rightAligned: {1, 2, 3, 4},
        ),

        _heading(l10n.statementCategories),
        if (statement.categories.isEmpty)
          _note(l10n.statementNoExpenses)
        else
          _table(
            headers: [
              l10n.statementColCategory,
              l10n.statementColAmount,
              '%',
            ],
            rows: [
              for (final c in statement.categories)
                [categoryLabel(l10n, c.category), money(c.total), percent(c.percent)],
            ],
            rightAligned: {1, 2},
          ),

        _heading(l10n.tabExpenses),
        if (statement.expenses.isEmpty)
          _note(l10n.statementNoExpenses)
        else
          _table(
            headers: [
              l10n.statementColDate,
              l10n.statementColDescription,
              l10n.statementColCategory,
              l10n.statementColPaidBy,
              l10n.statementColAmount,
            ],
            rows: [
              for (final e in statement.expenses)
                [
                  formatDateFor(localeTag, e.date),
                  e.description ?? '-',
                  categoryLabel(l10n, e.category),
                  e.paidByName,
                  money(e.amount),
                ],
            ],
            rightAligned: {4},
            widths: {1: const pw.FlexColumnWidth(2.5)},
          ),

        _heading(l10n.paymentsTitle),
        if (statement.payments.isEmpty)
          _note(l10n.statementNoPayments)
        else
          _table(
            headers: [
              l10n.statementColDate,
              l10n.statementColFrom,
              l10n.statementColTo,
              l10n.statementColAmount,
              l10n.statementColNote,
            ],
            rows: [
              for (final p in statement.payments)
                [
                  formatDateFor(localeTag, p.paidAt),
                  p.fromName,
                  p.toName,
                  money(p.amount),
                  p.note ?? '-',
                ],
            ],
            rightAligned: {3},
            widths: {4: const pw.FlexColumnWidth(2)},
          ),
      ],
    ),
  );

  return doc.save();
}

// A section title above a table.
pw.Widget _heading(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    ),
  );
}

// A short line of muted text, used when a section has nothing to list.
pw.Widget _note(String text) {
  return pw.Text(text, style: pw.TextStyle(fontSize: 9, color: _muted));
}

// A table with a shaded header row. Tables split over pages on their own.
pw.Widget _table({
  required List<String> headers,
  required List<List<String>> rows,
  Set<int> rightAligned = const {},
  Map<int, pw.TableColumnWidth> widths = const {},
}) {
  final alignments = {
    for (final column in rightAligned) column: pw.Alignment.centerRight,
  };
  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: _ink,
    ),
    cellStyle: pw.TextStyle(fontSize: 9, color: _ink),
    headerDecoration: pw.BoxDecoration(color: _cream),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    border: pw.TableBorder(
      horizontalInside: pw.BorderSide(color: _line, width: 0.5),
      bottom: pw.BorderSide(color: _line, width: 0.5),
    ),
    cellAlignments: alignments,
    headerAlignments: alignments,
    columnWidths: widths,
  );
}
