import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/api/api_client.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/avatar.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';
import 'package:roommate_expense_app/utils/iban.dart';
import 'package:roommate_expense_app/utils/split.dart';
import 'package:roommate_expense_app/widgets/attachments_section.dart';
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

  // Admins can edit and delete any payment, not only their own.
  bool _myIsAdmin = false;

  // Until when I may not remind each debtor again, keyed by the debtor's user id.
  // Only debtors I reminded in the last 24 hours are in it.
  Map<int, DateTime> _reminderCooldowns = {};

  // Debtors whose reminder is being sent right now, so the button cannot be tapped twice.
  final Set<int> _sendingReminders = {};

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
    // The cooldowns are extra: if they fail, the tab still works with no cooldowns.
    final cooldownsRequest = Api.getReminderCooldowns(widget.householdId)
        .catchError((_) => <ReminderCooldown>[]);
    final results = await Future.wait([
      Api.getBalances(widget.householdId),
      Api.getSettlements(widget.householdId),
      Api.getPayments(widget.householdId),
      Api.getMembers(widget.householdId),
      cooldownsRequest,
    ]);

    final balances = results[0] as List<Balance>;
    final settlements = results[1] as List<Settlement>;
    final payments = results[2] as List<Payment>;
    final members = results[3] as List<Member>;
    final cooldowns = results[4] as List<ReminderCooldown>;

    int? myId;
    var myIsAdmin = false;
    for (final member in members) {
      if (member.email == Session.email) {
        myId = member.userId;
        myIsAdmin = member.isAdmin;
      }
    }

    if (!mounted) return;
    setState(() {
      _balances = balances;
      _settlements = settlements;
      _payments = payments;
      _myUserId = myId;
      _myIsAdmin = myIsAdmin;
      _reminderCooldowns = {
        for (final c in cooldowns) c.debtorUserId: c.nextAllowedAt,
      };
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMessage(context, e))));
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
    // The dialog lets the user change the amount and add an optional note.
    // Null means the user cancelled.
    final edit = await showDialog<_PaymentEdit>(
      context: context,
      builder: (_) => _MarkAsPaidDialog(
        settlement: s,
        owedHundredths: _owedHundredths(s.fromUserId, s.toUserId),
      ),
    );
    if (edit == null || !mounted) return;

    final Payment created;
    try {
      created = await Api.createPayment(
        widget.householdId,
        s.fromUserId,
        s.toUserId,
        edit.amount,
        edit.note,
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    // Upload the receipts picked in the dialog. One failed upload must not undo the payment,
    // so failures are only counted and reported.
    var failed = 0;
    for (final file in edit.files) {
      try {
        await Api.uploadPaymentAttachment(widget.householdId, created.id, file);
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed == 0
              ? l10n.paymentRecorded
              : l10n.paymentAttachmentsUploadFailed(failed),
        ),
        // If nothing was attached (or something failed), offer it once more right here.
        action: edit.files.isEmpty || failed > 0
            ? SnackBarAction(
                label: l10n.attachReceipt,
                onPressed: () => _openPaymentAttachments(created),
              )
            : null,
      ),
    );
    // The payment changes the balances, so reload everything.
    await _refresh();
  }

  // Asks for an optional note, then sends the reminder. The answer has the new cooldown,
  // so the button updates at once.
  Future<void> _remind(Settlement s) async {
    final l10n = AppLocalizations.of(context);
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _ReminderDialog(name: s.fromName),
    );
    // Cancel gives null. An empty note is sent as null.
    if (note == null || !mounted) return;

    setState(() => _sendingReminders.add(s.fromUserId));
    try {
      final cooldown = await Api.sendReminder(
        widget.householdId,
        s.fromUserId,
        note.isEmpty ? null : note,
      );
      if (!mounted) return;
      setState(() => _reminderCooldowns[cooldown.debtorUserId] = cooldown.nextAllowedAt);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.reminderSent)));
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      // 400 (no debt any more) and 429 (already reminded) mean the screen is out of date.
      if (e is ApiException && (e.statusCode == 400 || e.statusCode == 429)) {
        await _refresh();
      }
    } finally {
      if (mounted) setState(() => _sendingReminders.remove(s.fromUserId));
    }
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

  // The original sender of a payment, or an admin, may edit or delete it.
  bool _canEditPayment(Payment p) => p.fromUserId == _myUserId || _myIsAdmin;

  // The uploader, the sender of the payment, or an admin may delete one of its receipts.
  bool _canDeleteReceipt(Payment p, Attachment attachment) {
    return attachment.uploadedById == _myUserId ||
        p.fromUserId == _myUserId ||
        _myIsAdmin;
  }

  // Details sheet of one payment: who paid whom, amount, date, note, the receipts (dekont), and
  // Edit / Delete for the sender or an admin. Any member may view and add receipts.
  // The rows are refreshed when the sheet closes (counts, or after an edit/delete).
  Future<void> _openPaymentAttachments(Payment p) async {
    final l10n = AppLocalizations.of(context);
    final canEdit = _canEditPayment(p);
    final note = p.note;
    // Edit and delete open their own dialogs, so the sheet closes first and says which one.
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.paymentFromTo(p.fromUserName, p.toUserName),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                formatMoney(context, p.amount),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                formatDate(context, p.paidAt),
                style: const TextStyle(color: AppColors.muted),
              ),
              if (note != null) ...[
                const SizedBox(height: 8),
                Text(note, style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 16),
              AttachmentsSection(
                householdId: widget.householdId,
                paymentId: p.id,
                canDelete: (attachment) => _canDeleteReceipt(p, attachment),
              ),
              if (canEdit) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.edit),
                        onPressed: () => Navigator.pop(sheetContext, 'edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.delete),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.owes,
                          side: const BorderSide(color: AppColors.owes),
                        ),
                        onPressed: () => Navigator.pop(sheetContext, 'delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      await _editPayment(p);
    } else if (action == 'delete') {
      await _deletePayment(p);
    } else {
      await _refresh();
    }
  }

  Future<void> _editPayment(Payment p) async {
    final l10n = AppLocalizations.of(context);
    // The settlements already include this payment, so its old amount is added back.
    final owedForEdit =
        _owedHundredths(p.fromUserId, p.toUserId) + toHundredths(p.amount);
    final edit = await showDialog<_PaymentEdit>(
      context: context,
      builder: (_) =>
          _EditPaymentDialog(payment: p, owedHundredths: owedForEdit),
    );
    if (edit == null || !mounted) return;

    try {
      await Api.updatePayment(
        widget.householdId,
        p.id,
        fromUserId: p.fromUserId,
        toUserId: p.toUserId,
        amount: edit.amount,
        note: edit.note,
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.paymentUpdated)));
    await _refresh();
  }

  // My net balance. If I am not in the balance list, it is 0.
  double get _myNet {
    for (final b in _balances) {
      if (b.userId == _myUserId) return b.netBalance;
    }
    return 0;
  }

  // How much fromUserId currently owes toUserId, in hundredths, from the loaded settlements.
  // Settlements are already netted, so money going the other way is subtracted.
  // Zero or less means there is no debt in this direction.
  int _owedHundredths(int fromUserId, int toUserId) {
    var owed = 0;
    for (final s in _settlements) {
      if (s.fromUserId == fromUserId && s.toUserId == toUserId) {
        owed += toHundredths(s.amount);
      } else if (s.fromUserId == toUserId && s.toUserId == fromUserId) {
        owed -= toHundredths(s.amount);
      }
    }
    return owed;
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
              FilledButton(onPressed: _retry, child: Text(l10n.retry)),
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
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _settlementCard(Settlement s, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final toIban = s.toIban;

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
            const SizedBox(height: 12),
            // The receiver's IBAN, so the payer can copy it into their bank app.
            if (toIban != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      formatIban(toIban),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.copyIban,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    onPressed: () => copyIban(context, toIban),
                  ),
                ],
              )
            else if (s.toUserId == _myUserId)
              Text(
                l10n.addIbanHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Only the creditor (the person who gets the money) sees the Remind button.
                if (s.toUserId == _myUserId) ...[
                  Expanded(child: _reminderButton(s, l10n)),
                  const SizedBox(width: 8),
                ] else
                  const Spacer(),
                OutlinedButton(
                  onPressed: () => _markAsPaid(s),
                  child: Text(l10n.markAsPaid),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // The Remind button of a settlement. While the 24 hour cooldown runs it is disabled and
  // shows when it can be used again.
  Widget _reminderButton(Settlement s, AppLocalizations l10n) {
    final cooldown = _reminderCooldowns[s.fromUserId];
    final String label;
    final bool canRemind;
    if (cooldown != null && cooldown.isAfter(DateTime.now())) {
      label = _reminderAgainLabel(l10n, cooldown);
      canRemind = false;
    } else {
      label = l10n.reminderButton;
      canRemind = !_sendingReminders.contains(s.fromUserId);
    }

    return OutlinedButton.icon(
      icon: const Icon(Icons.notifications_active_outlined, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      onPressed: canRemind ? () => _remind(s) : null,
    );
  }

  // "Today at 14:30" or "Tomorrow at 14:30" in local time. A cooldown lasts at most 24 hours,
  // so it always ends today or tomorrow.
  String _reminderAgainLabel(AppLocalizations l10n, DateTime until) {
    final now = DateTime.now();
    final time = DateFormat.Hm(localeTagOf(context)).format(until);
    final isToday =
        until.year == now.year && until.month == now.month && until.day == now.day;
    return isToday
        ? l10n.reminderCooldownToday(time)
        : l10n.reminderCooldownTomorrow(time);
  }

  Widget _paymentCard(Payment p, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final note = p.note;

    final muted = theme.textTheme.bodySmall?.copyWith(color: AppColors.muted);

    // A quiet row: who paid whom and the amount on top, date / note / receipt count below.
    // The actions (receipts, edit, delete) live in the details sheet that opens on tap; three
    // icon buttons in the row left too little room and the names wrapped letter by letter.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPaymentAttachments(p),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              _personAvatar(p.fromUserId, p.fromUserName),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.fromUserName} → ${p.toUserName}',
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(formatDate(context, p.paidAt), style: muted),
                        if (p.attachmentCount > 0) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.attach_file_rounded,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          Text(
                            '${p.attachmentCount}',
                            style: muted?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ],
                    ),
                    if (note != null)
                      Text(
                        note,
                        style: muted?.copyWith(fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatMoney(context, p.amount),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// True when a payment of [amount] is more than what the sender still owes.
// owedHundredths is in hundredths. Zero or less means no debt, so any payment is extra.
bool _overpays(double amount, int owedHundredths) {
  return owedHundredths <= 0 || toHundredths(amount) > owedHundredths;
}

// Asks before saving a payment that is more than the open debt. Returns true only if confirmed.
// The caller only calls this when _overpays is true.
Future<bool> _confirmOverpayment(
  BuildContext context, {
  required String fromName,
  required String toName,
  required int owedHundredths,
  required double amount,
}) async {
  final l10n = AppLocalizations.of(context);
  final amountText = formatMoney(context, amount);
  final message = owedHundredths <= 0
      ? l10n.overpaymentNoDebtWarning(fromName, toName, amountText)
      : l10n.overpaymentWarning(
          fromName,
          toName,
          formatMoney(context, owedHundredths / 100),
          amountText,
        );

  final confirmed = await showDialog<bool>(
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
          child: Text(l10n.saveAnyway),
        ),
      ],
    ),
  );
  return confirmed == true;
}

// Asks for an optional note before a reminder is sent. Returns the typed text (empty when
// nothing was typed), or null if the user cancelled.
class _ReminderDialog extends StatefulWidget {
  const _ReminderDialog({required this.name});

  // The debtor's name, shown in the explanation.
  final String name;

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  // The controller lives in the State so it is disposed only after the dialog closes.
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.reminderButton),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reminderDialogBody(widget.name)),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: l10n.paymentNote,
              hintText: l10n.reminderNoteHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _noteController.text.trim()),
          child: Text(l10n.reminderSend),
        ),
      ],
    );
  }
}

// The values the edit dialog returns. The note is null when it is empty.
class _PaymentEdit {
  const _PaymentEdit({
    required this.amount,
    required this.note,
    this.files = const [],
  });

  final double amount;
  final String? note;
  // Receipts (dekont) picked in the "record payment" dialog. They are uploaded right after the
  // payment is created, because a file needs the new payment's id.
  final List<UploadFile> files;
}

// Edits the amount and the note of a payment. Who paid whom stays fixed.
class _EditPaymentDialog extends StatefulWidget {
  const _EditPaymentDialog({
    required this.payment,
    required this.owedHundredths,
  });

  final Payment payment;
  // What the sender may still owe the receiver, in hundredths. Includes this payment's old amount.
  final int owedHundredths;

  @override
  State<_EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<_EditPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  // The controllers live in the State so they are disposed only after the dialog closes.
  late final TextEditingController _amountController = TextEditingController(
    text: numberText(widget.payment.amount),
  );
  late final TextEditingController _noteController = TextEditingController(
    text: widget.payment.note ?? '',
  );

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = parseDecimal(_amountController.text)!;
    final payment = widget.payment;
    if (_overpays(amount, widget.owedHundredths)) {
      final ok = await _confirmOverpayment(
        context,
        fromName: payment.fromUserName,
        toName: payment.toUserName,
        owedHundredths: widget.owedHundredths,
        amount: amount,
      );
      // Cancel keeps this dialog open with the values as they are.
      if (!ok || !mounted) return;
    }
    final note = _noteController.text.trim();
    Navigator.of(context)
        .pop(_PaymentEdit(amount: amount, note: note.isEmpty ? null : note));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final payment = widget.payment;

    return AlertDialog(
      title: Text(l10n.editPayment),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.paymentFromTo(payment.fromUserName, payment.toUserName),
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.amount,
                helperText: widget.owedHundredths > 0
                    ? l10n.suggestedAmount(
                        formatMoney(context, widget.owedHundredths / 100),
                      )
                    : null,
              ),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: l10n.paymentNote,
                hintText: l10n.paymentNoteHint,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}

// The confirm dialog for "mark as paid". The amount starts at the settlement amount and can be
// changed, and there is an optional note. It returns a _PaymentEdit, or null if cancelled.
class _MarkAsPaidDialog extends StatefulWidget {
  const _MarkAsPaidDialog({
    required this.settlement,
    required this.owedHundredths,
  });

  final Settlement settlement;
  // What the payer owes the receiver right now, in hundredths. Used for the suggestion.
  final int owedHundredths;

  @override
  State<_MarkAsPaidDialog> createState() => _MarkAsPaidDialogState();
}

class _MarkAsPaidDialogState extends State<_MarkAsPaidDialog> {
  final _formKey = GlobalKey<FormState>();
  // The controllers live in the State so they are disposed only after the dialog closes.
  late final TextEditingController _amountController = TextEditingController(
    text: numberText(widget.settlement.amount),
  );
  final _noteController = TextEditingController();
  final List<UploadFile> _files = [];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = parseDecimal(_amountController.text)!;
    final settlement = widget.settlement;
    if (_overpays(amount, widget.owedHundredths)) {
      final ok = await _confirmOverpayment(
        context,
        fromName: settlement.fromName,
        toName: settlement.toName,
        owedHundredths: widget.owedHundredths,
        amount: amount,
      );
      // Cancel keeps this dialog open with the values as they are.
      if (!ok || !mounted) return;
    }
    final note = _noteController.text.trim();
    Navigator.pop(
      context,
      _PaymentEdit(
        amount: amount,
        note: note.isEmpty ? null : note,
        files: _files,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settlement = widget.settlement;

    return AlertDialog(
      // Scrollable: with receipt thumbnails and the keyboard open the dialog can get tall.
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.markAsPaidConfirm(settlement.fromName, settlement.toName),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  helperText: widget.owedHundredths > 0
                      ? l10n.suggestedAmount(
                          formatMoney(context, widget.owedHundredths / 100),
                        )
                      : null,
                ),
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
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: l10n.paymentNote,
                  hintText: l10n.paymentNoteHint,
                ),
              ),
              const SizedBox(height: 8),
              // Receipts (dekont) can be picked right here; they upload after the payment is saved.
              PendingAttachmentsSection(
                files: _files,
                onAdded: (file) => setState(() => _files.add(file)),
                onRemoved: (index) => setState(() => _files.removeAt(index)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(onPressed: _submit, child: Text(l10n.markAsPaid)),
      ],
    );
  }
}
