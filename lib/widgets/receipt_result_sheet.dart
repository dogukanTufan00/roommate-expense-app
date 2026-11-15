import 'package:flutter/material.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/category.dart';
import 'package:roommate_expense_app/utils/format.dart';
import 'package:roommate_expense_app/utils/receipt_parser.dart';

// The sheet that shows what was read from a receipt. Only the found parts are shown.
// The products start all checked. "Uygula" returns the checked products, "Vazgeç" returns null.
class ReceiptResultSheet extends StatefulWidget {
  const ReceiptResultSheet({super.key, required this.data});

  final ReceiptData data;

  @override
  State<ReceiptResultSheet> createState() => _ReceiptResultSheetState();
}

class _ReceiptResultSheetState extends State<ReceiptResultSheet> {
  // One flag per product, in the same order as the products.
  late final List<bool> _checked = [
    for (final _ in widget.data.items) true,
  ];

  // One label and value line, for example "Tarih   10 Kas 2026".
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: context.palette.muted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final data = widget.data;
    final items = data.items;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.receiptResultTitle,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (data.total != null)
              _infoRow(l10n.amount, formatMoney(context, data.total!)),
            if (data.date != null)
              _infoRow(l10n.date, formatDate(context, data.date!)),
            if (data.storeName != null) _infoRow(l10n.receiptStore, data.storeName!),
            if (data.category != null)
              _infoRow(l10n.category, categoryLabel(l10n, data.category!)),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.itemsTextLabel,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              // A long receipt scrolls inside the sheet instead of pushing the buttons away.
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(formatReceiptItem(items[i])),
                        value: _checked[i],
                        onChanged: (value) => setState(() => _checked[i] = value ?? false),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, [
                      for (var i = 0; i < items.length; i++)
                        if (_checked[i]) items[i],
                    ]),
                    child: Text(l10n.receiptApply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
