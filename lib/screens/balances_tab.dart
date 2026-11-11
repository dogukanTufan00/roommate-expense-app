import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/avatar.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';
import 'package:roommate_expense_app/widgets/illustration.dart';

// The "Balances" tab: who owes whom, the suggested payments and the payment history.
// It is shown inside another screen's TabBarView, so it returns a body, not a Scaffold.
class BalancesTab extends StatefulWidget {
  const BalancesTab({super.key, required this.householdId});

  final int householdId;

  @override
  State<BalancesTab> createState() => _BalancesTabState();
}

class _BalancesTabState extends State<BalancesTab> {
  List<Balance> _balances = [];
  List<Settlement> _settlements = [];
  List<Payment> _payments = [];

  // The logged in user's id. The API does not say "me", so we find the member
  // whose email matches the login email. Null if we cannot find it.
  int? _myUserId;

  bool _loading = true;
  // Set when the first load fails, so the screen can show a retry button.
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  // First load. A failure replaces the whole tab with an error and a retry button.
  Future<void> _loadInitial() async {
    try {
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  // Loads all four requests at the same time, then updates the screen once.
  Future<void> _loadAll() async {
    final results = await Future.wait([
      Api.getBalances(widget.householdId),
      Api.getSettlements(widget.householdId),
      Api.getPayments(widget.householdId),
      Api.getMembers(widget.householdId),
    ]);

    final balances = results[0] as List<Balance>;
    final settlements = results[1] as List<Settlement>;
    final payments = results[2] as List<Payment>;
    final members = results[3] as List<Member>;

    int? myId;
    for (final member in members) {
      if (member.email == Session.email) myId = member.userId;
    }

    if (!mounted) return;
    setState(() {
      _balances = balances;
      _settlements = settlements;
      _payments = payments;
      _myUserId = myId;
      _loading = false;
      _loadError = null;
    });
  }

  // Used by pull to refresh and after an action. The screen already has data,
  // so a failure only shows a SnackBar.
  Future<void> _refresh() async {
    try {
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _loadInitial();
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage(context, e))),
    );
  }

  // Shows a yes/no dialog. Returns true only if the user taps the confirm button.
  Future<bool> _confirm({
    required String message,
    required String confirmLabel,
  }) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _markAsPaid(Settlement s) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      message: l10n.markAsPaidConfirm(
        s.fromName,
        s.toName,
        formatMoney(context, s.amount),
      ),
      confirmLabel: l10n.markAsPaid,
    );
    if (!confirmed || !mounted) return;

    try {
      await Api.createPayment(
        widget.householdId,
        s.fromUserId,
        s.toUserId,
        s.amount,
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    // The payment changes the balances, so reload everything.
    await _refresh();
  }

  Future<void> _deletePayment(Payment p) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      message: l10n.deletePaymentConfirm,
      confirmLabel: l10n.delete,
    );
    if (!confirmed || !mounted) return;

    try {
      await Api.deletePayment(widget.householdId, p.id);
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    await _refresh();
  }

  // My net balance. If I am not in the balance list, it is 0.
  double get _myNet {
    for (final b in _balances) {
      if (b.userId == _myUserId) return b.netBalance;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                errorMessage(context, _loadError!),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _retry,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        // Lets pull to refresh work even when the list is short.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _summaryCard(l10n),

          _sectionTitle(theme, l10n.balancesTitle),
          ..._balances.map((b) => _balanceCard(b, l10n)),

          _sectionTitle(theme, l10n.settlementsTitle),
          if (_settlements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Illustration(
                      'all-settled.png',
                      fallbackIcon: Icons.celebration_rounded,
                      height: 140,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.allSettled,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._settlements.map((s) => _settlementCard(s, l10n)),

          _sectionTitle(theme, l10n.paymentsTitle),
          if (_payments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n.noPayments,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            )
          else
            ..._payments.map((p) => _paymentCard(p, l10n)),
        ],
      ),
    );
  }

  // The hero card at the top: my overall position in one glance.
  Widget _summaryCard(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final net = _myNet;
    final amount = formatMoney(context, net.abs());

    final Color background;
    final Color amountColor;
    final String line;
    if (net.abs() < 0.005) {
      background = AppColors.mustard.withValues(alpha: 0.20);
      amountColor = AppColors.ink;
      line = l10n.summarySettled;
    } else if (net > 0) {
      background = AppColors.getsBack.withValues(alpha: 0.12);
      amountColor = AppColors.getsBack;
      line = l10n.summaryGetsBack;
    } else {
      background = AppColors.owes.withValues(alpha: 0.10);
      amountColor = AppColors.owes;
      line = l10n.summaryOwes;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.summaryTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            line,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
    );
  }

  // A round avatar with the person's initials, in the color chosen for that person.
  Widget _personAvatar(int userId, String name, {double radius = 20}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarColor(userId),
      child: Text(
        initials(name),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _balanceCard(Balance b, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isMe = b.userId == _myUserId;

    // netBalance > 0: the household owes this person (they get money back).
    // netBalance < 0: this person owes the household.
    // A tiny amount counts as zero, because of rounding.
    final String label;
    final Color color;
    if (b.netBalance.abs() < 0.005) {
      label = l10n.settled;
      color = AppColors.muted;
    } else if (b.netBalance > 0) {
      label = l10n.getsBack;
      color = AppColors.getsBack;
    } else {
      label = l10n.owes;
      color = AppColors.owes;
    }

    return Card(
      child: ListTile(
        leading: _personAvatar(b.userId, b.name),
        title: Text(isMe ? '${b.name} (${l10n.you})' : b.name),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatMoney(context, b.netBalance.abs()),
              style: theme.textTheme.titleSmall,
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // One person in a settlement: an avatar with the name under it.
  Widget _settlementPerson(int userId, String name) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _personAvatar(userId, name),
        const SizedBox(height: 4),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _settlementCard(Settlement s, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _settlementPerson(s.fromUserId, s.fromName)),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.muted,
                  ),
                ),
                Expanded(child: _settlementPerson(s.toUserId, s.toName)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              formatMoney(context, s.amount),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => _markAsPaid(s),
                child: Text(l10n.markAsPaid),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentCard(Payment p, AppLocalizations l10n) {
    return Card(
      child: ListTile(
        leading: _personAvatar(p.fromUserId, p.fromUserName),
        title: Text('${p.fromUserName} → ${p.toUserName}'),
        subtitle: Text(formatDate(context, p.paidAt)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatMoney(context, p.amount)),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deletePayment(p),
            ),
          ],
        ),
      ),
    );
  }
}
