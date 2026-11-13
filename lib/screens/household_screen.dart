import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/screens/balances_tab.dart';
import 'package:roommate_expense_app/screens/expenses_tab.dart';
import 'package:roommate_expense_app/screens/members_tab.dart';
import 'package:roommate_expense_app/screens/recurring_expenses_screen.dart';
import 'package:roommate_expense_app/screens/split_defaults_screen.dart';
import 'package:roommate_expense_app/screens/statement_tab.dart';
import 'package:roommate_expense_app/utils/errors.dart';

// One home, with four tabs: expenses, balances, statement and members.
class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key, required this.household, this.initialTab = 0});

  // The index of the Balances tab. Used when a notification opens the home on it.
  static const int balancesTab = 1;

  final Household household;
  // Which tab opens first. 0 is Expenses.
  final int initialTab;

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

// Menu actions in the app bar. A private enum keeps the menu code type-safe.
enum _HouseholdMenuAction { splitDefaults, recurring, rename, delete }

class _HouseholdScreenState extends State<HouseholdScreen> {
  // Kept in the State so the title updates after a rename.
  late String _name = widget.household.name;

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage(context, e))),
    );
  }

  Future<void> _rename() async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(title: l10n.rename, initialName: _name),
    );
    if (!mounted) return;
    final newName = result?.trim();
    if (newName == null || newName.isEmpty || newName == _name) return;

    try {
      final updated = await Api.renameHousehold(widget.household.id, newName);
      if (!mounted) return;
      setState(() => _name = updated.name);
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  void _openSplitDefaults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SplitDefaultsScreen(householdId: widget.household.id),
      ),
    );
  }

  void _openRecurring() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecurringExpensesScreen(householdId: widget.household.id),
      ),
    );
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final error = Theme.of(context).colorScheme.error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteHouseholdConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) return;

    try {
      await Api.deleteHousehold(widget.household.id);
      if (!mounted) return;
      // Going back to the list, which reloads itself.
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = widget.household.id;
    final errorColor = Theme.of(context).colorScheme.error;

    // DefaultTabController gives the TabBar and TabBarView one shared tab index.
    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_name),
          actions: [
            PopupMenuButton<_HouseholdMenuAction>(
              onSelected: (action) {
                switch (action) {
                  case _HouseholdMenuAction.splitDefaults:
                    _openSplitDefaults();
                  case _HouseholdMenuAction.recurring:
                    _openRecurring();
                  case _HouseholdMenuAction.rename:
                    _rename();
                  case _HouseholdMenuAction.delete:
                    _delete();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _HouseholdMenuAction.splitDefaults,
                  child: Row(
                    children: [
                      const Icon(Icons.pie_chart_outline),
                      const SizedBox(width: 12),
                      Text(l10n.splitDefaults),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _HouseholdMenuAction.recurring,
                  child: Row(
                    children: [
                      const Icon(Icons.autorenew),
                      const SizedBox(width: 12),
                      Text(l10n.recurringExpenses),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _HouseholdMenuAction.rename,
                  child: Row(
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 12),
                      Text(l10n.rename),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _HouseholdMenuAction.delete,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: errorColor),
                      const SizedBox(width: 12),
                      Text(l10n.delete, style: TextStyle(color: errorColor)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.receipt_long), text: l10n.tabExpenses),
              Tab(
                icon: const Icon(Icons.account_balance_wallet),
                text: l10n.tabBalances,
              ),
              Tab(icon: const Icon(Icons.insights_rounded), text: l10n.tabStatement),
              Tab(icon: const Icon(Icons.group), text: l10n.tabMembers),
            ],
          ),
        ),
        // No FloatingActionButton here: each tab has its own "add" button.
        body: TabBarView(
          children: [
            ExpensesTab(householdId: id),
            BalancesTab(householdId: id),
            StatementTab(householdId: id),
            MembersTab(householdId: id),
          ],
        ),
      ),
    );
  }
}

// A dialog with one text field, prefilled with initialName. Returns the typed
// text, or null if cancelled. The caller trims it and ignores empty names.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initialName});

  final String title;
  final String initialName;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  // The controller lives in the State so it is disposed only after the dialog closes.
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.householdName),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
