import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/screens/expense_form_screen.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/category.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';

// The home's monthly recurring expenses. The server adds each next month on its own.
// Stopping one means opening its latest expense and turning off the recurring switch.
class RecurringExpensesScreen extends StatefulWidget {
  const RecurringExpensesScreen({super.key, required this.householdId});

  final int householdId;

  @override
  State<RecurringExpensesScreen> createState() => _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends State<RecurringExpensesScreen> {
  // null means "still loading".
  List<RecurringExpense>? _items;
  String? _loadError;
  // Only admins may run the check by hand, so only they see the button.
  bool _isAdmin = false;
  // True while the manual check runs. Disables the button.
  bool _running = false;
  // True while a tapped expense is being loaded for editing.
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await Api.getRecurringExpenses(widget.householdId);
      final isAdmin = await _checkAdmin();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isAdmin = isAdmin;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_items == null) {
        setState(() => _loadError = errorMessage(context, e));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage(context, e))));
      }
    }
  }

  // Finds the logged in user's admin flag in the member list, the same way the other screens do.
  // A failure just hides the button.
  Future<bool> _checkAdmin() async {
    try {
      final members = await Api.getMembers(widget.householdId);
      for (final member in members) {
        if (member.email == Session.email) return member.isAdmin;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Admins only: adds the months that are due now, then reloads the list.
  Future<void> _runNow() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _running = true);
    try {
      final generated = await Api.runRecurringNow(widget.householdId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            generated == 0 ? l10n.recurringRunNone : l10n.recurringRunAdded(generated),
          ),
        ),
      );
      setState(() => _running = false);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _running = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage(context, e))));
    }
  }

  // The form needs the full expense with its shares, so the list is searched for it.
  // The form returns when it closes, and the list reloads either way.
  Future<void> _open(RecurringExpense item) async {
    setState(() => _opening = true);
    Expense? expense;
    Object? failure;
    try {
      final expenses = await Api.getExpenses(widget.householdId);
      for (final e in expenses) {
        if (e.id == item.expenseId) expense = e;
      }
    } catch (e) {
      failure = e;
    }
    if (!mounted) return;
    setState(() => _opening = false);

    if (expense == null) {
      final message = failure == null
          ? AppLocalizations.of(context).errorNotFound
          : errorMessage(context, failure);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(
          householdId: widget.householdId,
          expense: expense,
        ),
      ),
    );
    if (!mounted) return;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurringExpenses),
        actions: [
          if (_isAdmin)
            TextButton.icon(
              onPressed: (_running || _items == null) ? null : _runNow,
              icon: const Icon(Icons.sync_rounded),
              label: Text(l10n.recurringCheckNow),
            ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final items = _items;

    if (items == null) {
      final loadError = _loadError;
      if (loadError != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loadError, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: Text(l10n.retry)),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            l10n.recurringExplainer,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  const Icon(Icons.autorenew_rounded, size: 48, color: AppColors.muted),
                  const SizedBox(height: 12),
                  Text(
                    l10n.recurringEmpty,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            )
          else
            for (final item in items) _buildCard(l10n, item),
        ],
      ),
    );
  }

  // One chain: category icon, description, amount, payer, and the repeat day with the next date.
  Widget _buildCard(AppLocalizations l10n, RecurringExpense item) {
    final color = categoryColor(item.category);
    final description = item.description ?? '';
    final next = item.nextDate;
    final dayInfo = l10n.recurringDayInfo(item.recurrenceDay);
    final schedule = next == null
        ? dayInfo
        : '$dayInfo · ${l10n.recurringNextDate(formatDate(context, next))}';

    return Card(
      child: ListTile(
        onTap: _opening ? null : () => _open(item),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(categoryIcon(item.category), color: color),
        ),
        title: Text(
          description.isEmpty ? categoryLabel(l10n, item.category) : description,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.paidByName(item.paidByName),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              schedule,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
        trailing: Text(
          formatMoney(context, item.amount),
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
      ),
    );
  }
}
