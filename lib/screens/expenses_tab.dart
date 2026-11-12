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
import 'package:roommate_expense_app/widgets/illustration.dart';

// The expenses list of one home. It is one tab inside the home screen.
class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key, required this.householdId});

  final int householdId;

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  // null means "still loading".
  List<Expense>? _expenses;
  String? _loadError;
  // The logged in user's id, for the "your share" line. Null if the members could not be loaded.
  int? _myUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final expenses = await Api.getExpenses(widget.householdId);
      final myUserId = await _findMyUserId();
      if (!mounted) return;
      setState(() {
        _expenses = expenses;
        _myUserId = myUserId;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_expenses == null) {
        // First load failed: show the error with a retry button.
        setState(() => _loadError = errorMessage(context, e));
      } else {
        // The list is already on screen: a short message is enough.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage(context, e))),
        );
      }
    }
  }

  // Finds the logged in user in the member list, the same way the members screen does.
  // The list is only used for the split line, so a failure is not shown.
  Future<int?> _findMyUserId() async {
    try {
      final members = await Api.getMembers(widget.householdId);
      for (final member in members) {
        if (member.email == Session.email) return member.userId;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // A short line about the split, for example "Payın: 173,34 ₺ · %60 / %40".
  // Returns null when there is nothing to say (old expenses without shares).
  String? _splitLine(BuildContext context, AppLocalizations l10n, Expense e) {
    if (e.shares.isEmpty) return null;

    final parts = <String>[];
    final myUserId = _myUserId;
    if (myUserId != null) {
      ExpenseShare? mine;
      for (final share in e.shares) {
        if (share.userId == myUserId) mine = share;
      }
      parts.add(
        mine == null
            ? l10n.notInSplit
            : l10n.yourShare(formatMoney(context, mine.owedAmount)),
      );
    }

    if (e.splitType == 'PERCENT') {
      parts.add(
        e.shares
            .map((s) => '%${formatPercent(context, s.percent ?? 0)}')
            .join(' / '),
      );
    } else if (e.splitType == 'AMOUNT') {
      parts.add(l10n.customAmounts);
    }

    return parts.isEmpty ? null : parts.join(' · ');
  }

  // Opens the form. A new expense has no expense; editing passes one.
  // The form returns true when it saved or deleted something.
  Future<void> _openForm({Expense? expense}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(
          householdId: widget.householdId,
          expense: expense,
        ),
      ),
    );
    if (!mounted) return;
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.addExpense),
        onPressed: () => _openForm(),
      ),
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    final expenses = _expenses;

    if (expenses == null) {
      if (_loadError != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: Text(l10n.retry)),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    // ListView keeps pull-to-refresh working even when the list is empty.
    if (expenses.isEmpty) {
      final theme = Theme.of(context);
      return RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Illustration(
                          'empty-expenses.png',
                          fallbackIcon: Icons.receipt_long_rounded,
                          height: 180,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noExpensesTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noExpenses,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        // Top and bottom padding: the floating button must not cover the last card.
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final e = expenses[index];
          final description = e.description ?? '';
          final color = categoryColor(e.category);
          final splitLine = _splitLine(context, l10n, e);

          return Card(
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(categoryIcon(e.category), color: color),
              ),
              title: Text(
                description.isEmpty
                    ? categoryLabel(l10n, e.category)
                    : description,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${l10n.paidByName(e.paidByName)} · ${formatDate(context, e.expenseDate)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (e.recurring) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.repeat, size: 16),
                      ],
                    ],
                  ),
                  if (splitLine != null)
                    Text(
                      splitLine,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                ],
              ),
              trailing: Text(
                formatMoney(context, e.amount),
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              onTap: () => _openForm(expense: e),
            ),
          );
        },
      ),
    );
  }
}
