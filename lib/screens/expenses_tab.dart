import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/screens/expense_form_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final expenses = await Api.getExpenses(widget.householdId);
      if (!mounted) return;
      setState(() {
        _expenses = expenses;
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
              subtitle: Row(
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
