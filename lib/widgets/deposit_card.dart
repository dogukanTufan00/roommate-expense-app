import 'package:flutter/material.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/format.dart';
import 'package:roommate_expense_app/utils/split.dart';

// The deposit card on the Members tab: the total, what each person holds and the passed-on shares.
// Active members can edit the deposit and buy in when they hold nothing. Admins can undo a transfer.
// The card only shows the data and reports taps; the Members tab does the API calls.
class DepositCard extends StatelessWidget {
  const DepositCard({
    super.key,
    required this.deposit,
    required this.canEdit,
    required this.isAdmin,
    required this.onEdit,
    required this.onJoin,
    required this.onUndoTransfer,
  });

  final Deposit deposit;
  // True when the logged in user is an active member of the home.
  final bool canEdit;
  final bool isAdmin;
  final VoidCallback onEdit;
  final void Function(DepositShare share) onJoin;
  final void Function(DepositTransfer transfer) onUndoTransfer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final total = deposit.totalAmount;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.savings_outlined, color: AppColors.ink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.depositTitle,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (total != null && canEdit)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.edit),
                  ),
              ],
            ),
            if (total == null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.depositNone, style: muted),
              ),
              if (canEdit)
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: onEdit,
                    child: Text(l10n.depositAdd),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.depositTotal, style: muted),
                  ),
                  Text(
                    formatMoney(context, total),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              for (final share in deposit.shares) _shareRow(context, l10n, share),
              if (deposit.unassigned.abs() >= 0.005)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.depositUnassigned(
                      formatMoney(context, deposit.unassigned.abs()),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.owes,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (deposit.transfers.isNotEmpty) _transfers(context, l10n),
            ],
          ],
        ),
      ),
    );
  }

  // One person's share. A former member is marked "(left)". An active member with nothing in
  // the deposit gets a small "Join" button when I am an active member too.
  Widget _shareRow(
    BuildContext context,
    AppLocalizations l10n,
    DepositShare share,
  ) {
    final theme = Theme.of(context);
    final canJoin = canEdit && share.active && share.amount.abs() < 0.005;
    final name = share.active
        ? share.name
        : '${share.name} ${l10n.depositFormerMember}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: share.active
                  ? null
                  : theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ),
          if (canJoin)
            TextButton(
              onPressed: () => onJoin(share),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: Text(l10n.depositJoin),
            ),
          const SizedBox(width: 8),
          Text(
            formatMoney(context, share.amount),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // The passed-on shares, collapsed by default. Each row says from whom, to whom, how much and when.
  Widget _transfers(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      // No border lines around the tile when it opens.
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        l10n.depositTransfersTitle(deposit.transfers.length),
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      children: [
        for (final transfer in deposit.transfers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${transfer.fromName} → ${transfer.toName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        formatDate(context, transfer.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatMoney(context, transfer.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                // Only admins may undo a transfer.
                if (isAdmin)
                  IconButton(
                    tooltip: l10n.depositTransferUndo,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.undo_rounded, color: AppColors.muted),
                    onPressed: () => onUndoTransfer(transfer),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// Asks how much a new member buys in with. The suggested amount is prefilled and can be changed.
// Returns the amount, or null if the user cancelled.
Future<double?> showJoinDepositDialog(
  BuildContext context, {
  required String name,
  required double suggestedAmount,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _JoinDepositDialog(
      name: name,
      suggestedAmount: suggestedAmount,
    ),
  );
}

class _JoinDepositDialog extends StatefulWidget {
  const _JoinDepositDialog({required this.name, required this.suggestedAmount});

  final String name;
  final double suggestedAmount;

  @override
  State<_JoinDepositDialog> createState() => _JoinDepositDialogState();
}

class _JoinDepositDialogState extends State<_JoinDepositDialog> {
  final _formKey = GlobalKey<FormState>();
  // The controller lives in the State so it is disposed only after the dialog closes.
  late final TextEditingController _amountController = TextEditingController(
    text: numberText(widget.suggestedAmount),
  );

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, parseDecimal(_amountController.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.depositJoinTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.depositJoinExplain(widget.name)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.amount),
              onFieldSubmitted: (_) => _submit(),
              validator: (value) {
                final amount = parseDecimal(value ?? '');
                if (amount == null ||
                    amount <= 0 ||
                    !hasAtMostTwoDecimals(amount)) {
                  return l10n.invalidAmount;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.depositJoin)),
      ],
    );
  }
}
