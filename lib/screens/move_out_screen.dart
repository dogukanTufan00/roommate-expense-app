import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/screens/balances_tab.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';

// Everything a member does when moving out: the deposit share goes to the others, the open debts
// are settled, and then the person leaves the home (or an admin removes them). It is opened from
// the Members tab, for yourself ("Leave home") or for another member ("Remove"). Pops true once the
// person is no longer a member, so the Members tab can react to it.
class MoveOutScreen extends StatefulWidget {
  const MoveOutScreen({
    super.key,
    required this.householdId,
    required this.userId,
    required this.name,
    required this.isSelf,
  });

  final int householdId;
  // The person who moves out.
  final int userId;
  final String name;
  // True when the logged in user is the one moving out.
  final bool isSelf;

  @override
  State<MoveOutScreen> createState() => _MoveOutScreenState();
}

class _MoveOutScreenState extends State<MoveOutScreen> {
  bool _loading = true;
  Object? _loadError;

  Deposit _deposit = Deposit.none();
  // The active members. The leaving person is one of them, unless they already left.
  List<Member> _members = [];
  List<Settlement> _settlements = [];

  // True once the share was passed on from this screen. The deposit then holds nothing for the
  // person, so the step stays visible through this flag and shows a check instead.
  bool _passed = false;
  // A request is running, so the action buttons are disabled.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Loads everything the screen shows. Also used for retry and pull-to-refresh.
  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>([
        Api.getDeposit(widget.householdId),
        Api.getMembers(widget.householdId),
        Api.getSettlements(widget.householdId),
      ]);
      if (!mounted) return;
      setState(() {
        _deposit = results[0] as Deposit;
        _members = results[1] as List<Member>;
        _settlements = results[2] as List<Settlement>;
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_loading) {
        setState(() {
          _loading = false;
          _loadError = e;
        });
      } else {
        // A reload failed but the screen has data, so only tell the user.
        _showError(e);
      }
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

  // The share this person holds in the deposit. 0 when they hold nothing.
  double get _share {
    for (final share in _deposit.shares) {
      if (share.userId == widget.userId) return share.amount;
    }
    return 0;
  }

  // The other active members, who receive the share.
  List<Member> get _others =>
      [for (final member in _members) if (member.userId != widget.userId) member];

  // The settlements that involve this person, as payer or receiver.
  List<Settlement> get _myDebts => [
        for (final s in _settlements)
          if (s.fromUserId == widget.userId || s.toUserId == widget.userId) s,
      ];

  // Passes the whole share to the other active members. They owe the person that money now.
  Future<void> _passDeposit() async {
    setState(() => _busy = true);
    try {
      await Api.moveOutDeposit(widget.householdId, widget.userId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(e);
      return;
    }
    if (!mounted) return;
    setState(() {
      _passed = true;
      _busy = false;
    });
    // The new debts show up in the settlements, so reload them.
    await _load();
  }

  // "Ödendi": records a payment for this settlement with the same dialog as the Balances tab.
  Future<void> _markPaid(Settlement s) async {
    final result = await recordSettlementPayment(
      context,
      householdId: widget.householdId,
      settlement: s,
      owedHundredths: owedHundredthsBetween(_settlements, s.fromUserId, s.toUserId),
    );
    if (result == null || !mounted) return;

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.failedUploads == 0
              ? l10n.paymentRecorded
              : l10n.paymentAttachmentsUploadFailed(result.failedUploads),
        ),
      ),
    );
    await _load();
  }

  // The person's net balance right now, for the leave warning. Null if it cannot be loaded.
  Future<double?> _netBalance() async {
    try {
      final balances = await Api.getBalances(widget.householdId);
      for (final balance in balances) {
        if (balance.userId == widget.userId) return balance.netBalance;
      }
      return 0;
    } catch (_) {
      return null;
    }
  }

  // Confirms the leave or the removal. Open money gets a warning in red above the question.
  Future<bool> _confirmLeave(AppLocalizations l10n, double? net) async {
    final palette = context.palette;
    String? warning;
    if (net != null && net.abs() >= 0.01) {
      final amount = formatMoney(context, net.abs());
      if (widget.isSelf) {
        warning = net < 0
            ? l10n.leaveHomeOwesWarning(amount)
            : l10n.leaveHomeGetsBackWarning(amount);
      } else {
        warning = net < 0
            ? l10n.removeMemberOwesWarning(widget.name, amount)
            : l10n.removeMemberGetsBackWarning(widget.name, amount);
      }
    }
    final title = widget.isSelf ? l10n.leaveHome : l10n.removeMember;
    final message = widget.isSelf
        ? l10n.leaveHomeConfirm
        : l10n.removeMemberConfirm(widget.name);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (warning != null) ...[
              Text(
                warning,
                style: TextStyle(
                  color: palette.owes,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(message),
          ],
        ),
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
            child: Text(title),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  // The final step: leave the home, or remove the member. Pops true on success.
  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    final net = await _netBalance();
    if (!mounted) return;
    final confirmed = await _confirmLeave(l10n, net);
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      if (widget.isSelf) {
        await Api.leaveHousehold(widget.householdId, widget.userId);
      } else {
        await Api.removeMember(widget.householdId, widget.userId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(e);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelf ? l10n.leaveHome : l10n.removeMember),
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
    final palette = context.palette;
    final showDeposit = _share >= 0.005 || _passed;

    // Cards bring their own side margins, so only the other widgets get the 16 px gutter.
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.isSelf
                  ? l10n.moveOutTitleSelf
                  : l10n.moveOutTitleOther(widget.name),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (showDeposit) _depositStep(l10n, theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              l10n.moveOutDebtsTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.ink,
              ),
            ),
          ),
          _debtsStep(l10n),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.owes,
                ),
                onPressed: _busy ? null : _finish,
                child: Text(
                  widget.isSelf
                      ? l10n.leaveHome
                      : l10n.moveOutRemoveButton(widget.name),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: the deposit share. Shows the amount and the button to pass it on, or a check once done.
  Widget _depositStep(AppLocalizations l10n, ThemeData theme) {
    final palette = context.palette;
    final others = _others;
    final perPerson = others.isEmpty ? 0.0 : _share / others.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_passed)
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: palette.getsBack),
                  const SizedBox(width: 8),
                  Text(
                    l10n.moveOutDepositPassed,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.getsBack,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            else ...[
              Text(
                l10n.moveOutDepositShare(formatMoney(context, _share)),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                others.isEmpty
                    ? l10n.moveOutNoOtherMembers
                    : l10n.moveOutPassHint(
                        others.length,
                        formatMoney(context, perPerson),
                      ),
                style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy || others.isEmpty ? null : _passDeposit,
                  child: Text(l10n.moveOutPassDeposit),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Step 2: the open debts that involve this person. Each one can be marked as paid.
  Widget _debtsStep(AppLocalizations l10n) {
    final palette = context.palette;
    final debts = _myDebts;
    if (debts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: palette.getsBack),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.moveOutNoOpenDebts,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [for (final s in debts) _debtCard(s, l10n)],
    );
  }

  bool _mayMarkPaid(Settlement s) {
    Member? me;
    for (final m in _members) {
      if (m.email == Session.email) me = m;
    }
    return canHandlePayment(
      fromUserId: s.fromUserId,
      toUserId: s.toUserId,
      myUserId: me?.userId,
      iAmAdmin: me?.isAdmin ?? false,
      activeUserIds: {for (final m in _members) m.userId},
    );
  }

  Widget _debtCard(Settlement s, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${s.fromName} → ${s.toName} · ${formatMoney(context, s.amount)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            // Only the payer or the receiver may mark it paid (same rule as the Balances tab).
            if (_mayMarkPaid(s)) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _busy ? null : () => _markPaid(s),
                child: Text(l10n.moveOutMarkPaid),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
