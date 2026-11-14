import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';
import 'package:roommate_expense_app/utils/split.dart';

// Sets the household deposit: the total, and how much each person holds. Every active member gets
// a field. A former member gets one only while they still hold money. Pops true when the deposit
// was saved or deleted, so the Members tab reloads.
class DepositFormScreen extends StatefulWidget {
  const DepositFormScreen({super.key, required this.householdId});

  final int householdId;

  @override
  State<DepositFormScreen> createState() => _DepositFormScreenState();
}

// One amount field and the person it belongs to.
class _ShareField {
  _ShareField({
    required this.userId,
    required this.name,
    required this.active,
    required String initialText,
  }) : controller = TextEditingController(text: initialText);

  final int userId;
  final String name;
  final bool active;
  // Lives as long as the screen, so it is disposed in dispose().
  final TextEditingController controller;
}

class _DepositFormScreenState extends State<DepositFormScreen> {
  bool _loading = true;
  Object? _loadError;
  bool _saving = false;
  // Whether a deposit is recorded already. Only then the delete option is shown.
  bool _hasDeposit = false;

  final _totalController = TextEditingController();
  List<_ShareField> _fields = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _totalController.dispose();
    for (final field in _fields) {
      field.controller.dispose();
    }
    super.dispose();
  }

  // Loads the deposit and the members together, then builds the fields.
  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>([
        Api.getDeposit(widget.householdId),
        Api.getMembers(widget.householdId),
      ]);
      if (!mounted) return;
      final deposit = results[0] as Deposit;
      final members = results[1] as List<Member>;
      final heldBy = {for (final share in deposit.shares) share.userId: share};

      final fields = <_ShareField>[
        for (final member in members)
          _ShareField(
            userId: member.userId,
            name: member.name,
            active: true,
            initialText: deposit.exists
                ? numberText(heldBy[member.userId]?.amount ?? 0)
                : '',
          ),
        // Former members appear only while they still hold money.
        for (final share in deposit.shares)
          if (!share.active && share.amount > 0)
            _ShareField(
              userId: share.userId,
              name: share.name,
              active: false,
              initialText: numberText(share.amount),
            ),
      ];

      setState(() {
        _totalController.text =
            deposit.totalAmount == null ? '' : numberText(deposit.totalAmount!);
        _fields = fields;
        _hasDeposit = deposit.exists;
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e;
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMessage(context, error))));
  }

  // The total typed in, or null when it is empty or not a number.
  double? get _total => parseDecimal(_totalController.text);

  // The sum of all share fields in hundredths. An empty or bad field counts as 0 here.
  int get _sumHundredths {
    var sum = 0;
    for (final field in _fields) {
      sum += toHundredths(parseDecimal(field.controller.text) ?? 0);
    }
    return sum;
  }

  // Equal split of the total over the active members. Former members keep their amounts, so the
  // active members share what is left after them. The cents go to the first members.
  void _splitEqually() {
    final l10n = AppLocalizations.of(context);
    final total = _total;
    if (total == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));
      return;
    }
    final active = [for (final field in _fields) if (field.active) field];
    if (active.isEmpty) return;

    var formerHundredths = 0;
    for (final field in _fields) {
      if (!field.active) {
        formerHundredths += toHundredths(parseDecimal(field.controller.text) ?? 0);
      }
    }
    final rest = toHundredths(total) - formerHundredths;
    if (rest < 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorDepositSharesSum)));
      return;
    }
    final parts = splitEvenly(rest, active.length);
    setState(() {
      for (var i = 0; i < active.length; i++) {
        active[i].controller.text = numberText(parts[i] / 100);
      }
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final total = _total;
    if (total == null || total <= 0 || !hasAtMostTwoDecimals(total)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));
      return;
    }

    // Every field is sent, empty ones as 0.
    final shares = <int, double>{};
    for (final field in _fields) {
      final text = field.controller.text.trim();
      final amount = text.isEmpty ? 0.0 : parseDecimal(text);
      if (amount == null || amount < 0 || !hasAtMostTwoDecimals(amount)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));
        return;
      }
      shares[field.userId] = amount;
    }

    // Checked here too, so the user sees the problem before the request.
    if (toHundredths(total) != _sumHundredths) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorDepositSharesSum)));
      return;
    }

    setState(() => _saving = true);
    try {
      await Api.saveDeposit(widget.householdId, total, shares);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(e);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.depositSaved)));
    Navigator.of(context).pop(true);
  }

  Future<void> _deleteDeposit() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.depositDeleteAction),
        content: Text(l10n.depositDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.depositDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await Api.deleteDeposit(widget.householdId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(e);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.depositDeleted)));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.depositTitle),
        actions: [
          if (_hasDeposit && !_loading && _loadError == null)
            PopupMenuButton<String>(
              onSelected: (_) => _deleteDeposit(),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: errorColor),
                      const SizedBox(width: 12),
                      Text(
                        l10n.depositDeleteAction,
                        style: TextStyle(color: errorColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final loadError = _loadError;
    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage(context, loadError), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _retry, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final total = _total;
    final sum = _sumHundredths;
    // Red when the shares do not add up to the total. Muted while there is no total yet.
    final matches = total != null && toHundredths(total) == sum;
    final Color sumColor = total == null
        ? AppColors.muted
        : (matches ? AppColors.getsBack : AppColors.owes);
    final totalText = total == null ? '—' : formatMoney(context, total);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        TextField(
          controller: _totalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.depositTotalLabel),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.depositSumLine(formatMoney(context, sum / 100), totalText),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: sumColor,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            TextButton(
              onPressed: _saving ? null : _splitEqually,
              child: Text(l10n.depositEqualSplit),
            ),
          ],
        ),
        Text(
          l10n.depositEqualSplitHint,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        for (final field in _fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: field.controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: field.active
                    ? field.name
                    : '${field.name} ${l10n.depositFormerMember}',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.save),
          ),
        ),
      ],
    );
  }
}
