import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/iban.dart';
import 'package:share_plus/share_plus.dart';

// Opens a sheet with the IBAN as a QR code, so a payer can scan it with a banking app.
// [name] is the account holder, [iban] the IBAN as stored (spaces are removed for the QR code).
Future<void> showIbanQrSheet(
  BuildContext context, {
  required String name,
  required String iban,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _IbanQrSheet(
      // The page's context is kept for the copy SnackBar, because the sheet closes first.
      pageContext: context,
      name: name,
      iban: iban,
    ),
  );
}

class _IbanQrSheet extends StatelessWidget {
  const _IbanQrSheet({
    required this.pageContext,
    required this.name,
    required this.iban,
  });

  final BuildContext pageContext;
  final String name;
  final String iban;

  // Side of the white box around the QR code, in logical pixels.
  static const double _boxPadding = 12;
  static const double _maxQrSize = 220;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final grouped = formatIban(iban);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.iban,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            // The QR code is drawn on white, because scanners need dark modules on a light background.
            LayoutBuilder(
              builder: (context, constraints) {
                final qrSize = math.min(
                  _maxQrSize,
                  constraints.maxWidth - 2 * _boxPadding,
                );
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(_boxPadding),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: normalizeIban(iban),
                      version: QrVersions.auto,
                      size: qrSize,
                      backgroundColor: Colors.white,
                      semanticsLabel: l10n.ibanQrTooltip,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SelectableText(
              grouped,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.ibanQrHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: 20),
            // Two buttons side by side. Expanded keeps them on one line on a 360dp phone.
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(
                      l10n.ibanQrCopy,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () {
                      // The sheet closes first, so the SnackBar is seen on the page below it.
                      Navigator.of(context).pop();
                      copyIban(pageContext, iban);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.share_outlined),
                    label: Text(
                      l10n.ibanQrShare,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(text: l10n.ibanShareText(name, grouped)),
                    ),
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
