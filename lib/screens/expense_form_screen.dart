import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/utils/category.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';

// Parses "12,50" and "12.50" the same way.
double? _parseAmount(String text) {
  return double.tryParse(text.trim().replaceAll(',', '.'));
}

// Dates are stored at 12:00 so that the day does not shift when the
// server or another time zone converts the value.
DateTime _atNoon(DateTime date) => DateTime(date.year, date.month, date.day, 12);

// expense == null means "create a new expense".
class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, required this.householdId, this.expense});

  final int householdId;
  final Expense? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  // null means "still loading the members".
  List<Member>? _members;
  String? _loadError;

  int? _paidByUserId;
  late String _category;
  late DateTime _date;
  late bool _recurring;

  // True while saving or deleting. Disables the buttons.
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;

    if (expense == null) {
      _category = 'GROCERIES';
      _date = _atNoon(DateTime.now());
      _recurring = false;
    } else {
      _amountController.text = expense.amount.toStringAsFixed(2);
      _descriptionController.text = expense.description ?? '';
      _category = expense.category;
      _date = _atNoon(expense.expenseDate);
      _recurring = expense.recurring;
    }

    _loadMembers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await Api.getMembers(widget.householdId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loadError = null;
        _paidByUserId = _defaultPayer(members);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = errorMessage(context, e));
    }
  }

  // Edit: the saved payer, if they are still a member.
  // Create: the logged in user. Otherwise null, so the user must pick one.
  int? _defaultPayer(List<Member> members) {
    final expense = widget.expense;
    if (expense != null) {
      for (final m in members) {
        if (m.userId == expense.paidByUserId) return m.userId;
      }
      return null;
    }
    for (final m in members) {
      if (m.email == Session.email) return m.userId;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = _atNoon(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();
    final input = ExpenseInput(
      paidByUserId: _paidByUserId!,
      amount: _parseAmount(_amountController.text)!,
      category: _category,
      description: description.isEmpty ? null : description,
      recurring: _recurring,
      expenseDate: _date,
    );

    setState(() => _saving = true);
    try {
      final expense = widget.expense;
      if (expense == null) {
        await Api.createExpense(widget.householdId, input);
      } else {
        await Api.updateExpense(widget.householdId, expense.id, input);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage(context, e))),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.deleteExpenseConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await Api.deleteExpense(widget.householdId, widget.expense!.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage(context, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.expense != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.editExpense : l10n.addExpense),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.delete,
              onPressed: _saving ? null : _confirmDelete,
            ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final members = _members;

    if (members == null) {
      if (_loadError != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _loadMembers, child: Text(l10n.retry)),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.amount),
              validator: (value) {
                final amount = _parseAmount(value ?? '');
                // isFinite rejects "NaN" and "Infinity", which double.tryParse accepts.
                if (amount == null || !amount.isFinite || amount <= 0) {
                  return l10n.invalidAmount;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(labelText: l10n.category),
              items: [
                for (final category in expenseCategories)
                  DropdownMenuItem(
                    value: category,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon(category), size: 20, color: categoryColor(category)),
                        const SizedBox(width: 8),
                        Text(categoryLabel(l10n, category)),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _paidByUserId,
              decoration: InputDecoration(labelText: l10n.paidBy),
              items: [
                for (final member in members)
                  DropdownMenuItem(value: member.userId, child: Text(member.name)),
              ],
              onChanged: (value) => setState(() => _paidByUserId = value),
              validator: (value) => value == null ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: l10n.description),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.date),
              subtitle: Text(formatDate(context, _date)),
              onTap: _pickDate,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.recurring),
              value: _recurring,
              onChanged: (value) => setState(() => _recurring = value),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
