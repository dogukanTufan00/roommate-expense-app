import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/category.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';
import 'package:roommate_expense_app/utils/split.dart';

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

  // One text field per participant, used by PERCENT and AMOUNT splits.
  // Created on demand and kept, so typed values survive a switch of split type.
  final Map<int, TextEditingController> _shareControllers = {};

  // null means "still loading the members".
  List<Member>? _members;
  String? _loadError;

  // The household's category defaults. Only loaded on create. Null if not loaded.
  List<CategorySplitDefault>? _splitDefaults;

  int? _paidByUserId;
  late String _category;
  late DateTime _date;
  late bool _recurring;

  // The split: EQUAL, PERCENT or AMOUNT.
  late String _splitType;
  // The user ids that share this expense.
  final Set<int> _selected = {};
  // Edit only: names of people in the saved split who are no longer members.
  List<String> _formerNames = [];
  // True once the user changes the split by hand. Stops the automatic category default.
  bool _splitTouched = false;
  // True while the split is the category's saved default ratio.
  bool _usingDefaultRatio = false;

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
      _splitType = 'EQUAL';
    } else {
      _amountController.text = expense.amount.toStringAsFixed(2);
      _descriptionController.text = expense.description ?? '';
      _category = expense.category;
      _date = _atNoon(expense.expenseDate);
      _recurring = expense.recurring;
      _splitType = expense.splitType;

      // Prefill the saved split. The people are selected now, and the values later
      // only if they are still members (see _applyMembers).
      for (final share in expense.shares) {
        _selected.add(share.userId);
        final value = _splitType == 'PERCENT'
            ? share.percent
            : _splitType == 'AMOUNT'
                ? share.owedAmount
                : null;
        if (value != null) _controllerFor(share.userId).text = numberText(value);
      }
    }

    _loadMembers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    for (final controller in _shareControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int userId) =>
      _shareControllers.putIfAbsent(userId, () => TextEditingController());

  Future<void> _loadMembers() async {
    try {
      final members = await Api.getMembers(widget.householdId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loadError = null;
        _paidByUserId = _defaultPayer(members);
        _applyMembers(members);
      });
      if (widget.expense == null) _loadSplitDefaults();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = errorMessage(context, e));
    }
  }

  // Loaded once on create. The form works without it, so errors are ignored.
  Future<void> _loadSplitDefaults() async {
    try {
      final defaults = await Api.getSplitDefaults(widget.householdId);
      if (!mounted) return;
      setState(() {
        _splitDefaults = defaults;
        final members = _members;
        if (members != null) _applyCategoryDefault(members);
      });
    } catch (_) {
      // No defaults: the split stays equal.
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

  // Sets the selection after the members load. Changes the state, so call it inside setState.
  void _applyMembers(List<Member> members) {
    final activeIds = {for (final m in members) m.userId};
    final expense = widget.expense;

    if (expense == null) {
      _applyCategoryDefault(members);
      return;
    }

    // Edit: people who moved out are not selected. The note under the chips says so,
    // and the user must redistribute their share before saving.
    _selected.removeWhere((id) => !activeIds.contains(id));
    _formerNames = [
      for (final share in expense.shares)
        if (!activeIds.contains(share.userId)) share.name,
    ];
    // Old expenses may have no shares at all. Then everyone shares equally.
    if (_selected.isEmpty) _selected.addAll(activeIds);
  }

  // Create only. If the category has a default for exactly the current members,
  // use it as a PERCENT split. Otherwise everyone shares equally.
  // Does nothing once the user has changed the split by hand.
  void _applyCategoryDefault(List<Member> members) {
    if (_splitTouched) return;

    final activeIds = {for (final m in members) m.userId};
    _selected
      ..clear()
      ..addAll(activeIds);

    final def = _defaultFor(_category);
    if (def != null && _matchesMembers(def, activeIds)) {
      _splitType = 'PERCENT';
      for (final share in def.shares) {
        _controllerFor(share.userId).text = numberText(share.percent);
      }
      _usingDefaultRatio = true;
    } else {
      _splitType = 'EQUAL';
      _usingDefaultRatio = false;
    }
  }

  CategorySplitDefault? _defaultFor(String category) {
    for (final item in _splitDefaults ?? const <CategorySplitDefault>[]) {
      if (item.category == category) return item;
    }
    return null;
  }

  // True when the default covers exactly the active members, no more and no less.
  bool _matchesMembers(CategorySplitDefault def, Set<int> activeIds) {
    return def.shares.length == activeIds.length &&
        def.shares.every((s) => activeIds.contains(s.userId));
  }

  // The amount, or null if it is missing or not above 0.
  double? get _amount {
    final amount = _parseAmount(_amountController.text);
    if (amount == null || !amount.isFinite || amount <= 0) return null;
    return amount;
  }

  // What the shares must add up to, in hundredths: 10000 for percent, cents for amount.
  int? get _targetUnits {
    if (_splitType == 'PERCENT') return 10000;
    final amount = _amount;
    if (amount == null) return null;
    return toHundredths(amount);
  }

  // One share value in hundredths, or null when the field is empty or invalid.
  int? _shareUnits(int userId) {
    final value = parseDecimal(_controllerFor(userId).text);
    if (value == null || value <= 0 || !hasAtMostTwoDecimals(value)) return null;
    return toHundredths(value);
  }

  // What is still left to hand out, in hundredths. Negative means too much.
  // Null when the target is unknown (no valid amount yet).
  int? get _remainingUnits {
    final target = _targetUnits;
    if (target == null) return null;
    var used = 0;
    for (final id in _selected) {
      used += _shareUnits(id) ?? 0;
    }
    return target - used;
  }

  // True when the split can be saved: someone is selected and, for PERCENT or AMOUNT,
  // every value is valid and the total is exact.
  bool get _splitValid {
    if (_selected.isEmpty) return false;
    if (_splitType == 'EQUAL') return true;
    for (final id in _selected) {
      if (_shareUnits(id) == null) return false;
    }
    return _remainingUnits == 0;
  }

  // Edit only: the split was not touched, so the stored split is kept.
  bool get _keepsStoredSplit => widget.expense != null && !_splitTouched;

  // Edit only: an AMOUNT split whose amount changed. The API rejects that unless the
  // shares are sent, so the user must adjust the split first.
  bool get _amountNeedsAdjust {
    final expense = widget.expense;
    if (expense == null || !_keepsStoredSplit || expense.splitType != 'AMOUNT') {
      return false;
    }
    final amount = _amount;
    return amount != null && toHundredths(amount) != toHundredths(expense.amount);
  }

  // Edit only: show the stored split read-only. This happens when someone moved out,
  // or when an AMOUNT split needs adjusting. "Change split" switches to the editor.
  bool get _readOnlySplit =>
      _keepsStoredSplit && (_formerNames.isNotEmpty || _amountNeedsAdjust);

  // Selected user ids in the member list order.
  List<int> _selectedIdsInOrder() {
    final members = _members ?? const <Member>[];
    return [for (final m in members) if (_selected.contains(m.userId)) m.userId];
  }

  // A user change ends the automatic default.
  void _markSplitChanged() {
    _splitTouched = true;
    _usingDefaultRatio = false;
  }

  void _setSplitType(String type) {
    setState(() {
      _markSplitChanged();
      _splitType = type;
      // Start from an even split, so the fields are never empty.
      if (type != 'EQUAL') _fillEvenly();
    });
  }

  // Writes an even split into the fields of the selected people.
  void _fillEvenly() {
    final target = _targetUnits;
    if (target == null) return;
    final ids = _selectedIdsInOrder();
    final parts = splitEvenly(target, ids.length);
    for (var i = 0; i < ids.length; i++) {
      _controllerFor(ids[i]).text = numberText(parts[i] / 100);
    }
  }

  void _toggleMember(Member member, bool selected) {
    // At least one person must share the expense.
    if (!selected && _selected.length == 1 && _selected.contains(member.userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).splitNoneSelected)),
      );
      return;
    }
    setState(() {
      _markSplitChanged();
      if (selected) {
        _selected.add(member.userId);
      } else {
        _selected.remove(member.userId);
      }
    });
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

    final keepStored = _keepsStoredSplit;
    if (keepStored) {
      // The message is shown in the split section, which offers "Change split".
      if (_amountNeedsAdjust) return;
    } else if (!_splitValid) {
      // The split must add up exactly. The message under the split explains it.
      return;
    }

    final members = _members!;
    final shares = keepStored
        ? null
        : [
            for (final member in members)
              if (_selected.contains(member.userId))
                ShareInput(
                  userId: member.userId,
                  value: _splitType == 'EQUAL'
                      ? null
                      : parseDecimal(_controllerFor(member.userId).text)!,
                ),
          ];

    final description = _descriptionController.text.trim();
    final input = ExpenseInput(
      paidByUserId: _paidByUserId!,
      amount: _parseAmount(_amountController.text)!,
      category: _category,
      description: description.isEmpty ? null : description,
      recurring: _recurring,
      expenseDate: _date,
      // Null on an untouched edit: the API keeps the stored split.
      splitType: keepStored ? null : _splitType,
      shares: shares,
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
              // Rebuilds the split preview and the remaining line as the amount changes.
              onChanged: (_) => setState(() {}),
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
                if (value == null) return;
                setState(() {
                  _category = value;
                  // On create, an untouched split follows the new category's default.
                  if (widget.expense == null) _applyCategoryDefault(members);
                });
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
            const SizedBox(height: 16),
            _buildSplitSection(l10n, members),
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

  Widget _buildSplitSection(AppLocalizations l10n, List<Member> members) {
    if (_readOnlySplit) return _buildStoredSplit(l10n, members);

    final theme = Theme.of(context);
    final amount = _amount;
    final remaining = _remainingUnits;
    final isEqual = _splitType == 'EQUAL';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.splitTitle,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final member in members)
              FilterChip(
                label: Text(member.name),
                selected: _selected.contains(member.userId),
                onSelected: (value) => _toggleMember(member, value),
              ),
          ],
        ),
        if (_formerNames.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.splitFormerMembers(_formerNames.join(', ')),
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.owes),
          ),
        ],
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'EQUAL', label: Text(l10n.splitEqual)),
            ButtonSegment(value: 'PERCENT', label: Text(l10n.splitPercent)),
            ButtonSegment(value: 'AMOUNT', label: Text(l10n.splitAmount)),
          ],
          selected: {_splitType},
          onSelectionChanged: (value) => _setSplitType(value.first),
        ),
        if (_usingDefaultRatio) ...[
          const SizedBox(height: 8),
          Text(
            l10n.splitDefaultApplied,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
        const SizedBox(height: 8),
        for (final member in members)
          if (_selected.contains(member.userId))
            _buildShareRow(l10n, member, amount, isEqual),
        if (!isEqual && remaining != null) ...[
          const SizedBox(height: 4),
          Text(
            _splitType == 'PERCENT'
                ? l10n.splitRemainingPercent(formatPercent(context, remaining / 100))
                : l10n.splitRemainingAmount(formatMoney(context, remaining / 100)),
            textAlign: TextAlign.end,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: remaining == 0 ? AppColors.getsBack : AppColors.owes,
            ),
          ),
        ],
        if (!isEqual && !_splitValid) ...[
          const SizedBox(height: 4),
          Text(
            l10n.splitNotBalanced,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.owes),
          ),
        ],
      ],
    );
  }

  // Edit only, untouched split: the stored shares, read-only. Former members get a tag.
  Widget _buildStoredSplit(AppLocalizations l10n, List<Member> members) {
    final theme = Theme.of(context);
    final expense = widget.expense!;
    final activeIds = {for (final m in members) m.userId};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.splitTitle,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final share in expense.shares)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          share.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (!activeIds.contains(share.userId)) ...[
                        const SizedBox(width: 8),
                        Text(
                          l10n.movedOutTag,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  share.percent == null
                      ? formatMoney(context, share.owedAmount)
                      : '%${formatPercent(context, share.percent!)} · ${formatMoney(context, share.owedAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ],
            ),
          ),
        if (_amountNeedsAdjust) ...[
          const SizedBox(height: 4),
          Text(
            l10n.splitAmountChanged,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.owes),
          ),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(_markSplitChanged),
            child: Text(l10n.changeSplit),
          ),
        ),
      ],
    );
  }

  // One person in the split. EQUAL shows the computed share. PERCENT and AMOUNT show an input.
  Widget _buildShareRow(
    AppLocalizations l10n,
    Member member,
    double? amount,
    bool isEqual,
  ) {
    final theme = Theme.of(context);

    if (isEqual) {
      final share = amount == null ? null : amount / _selected.length;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text(
              share == null ? '' : formatMoney(context, share),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ],
        ),
      );
    }

    final isPercent = _splitType == 'PERCENT';
    final units = _shareUnits(member.userId);
    // For percent, show what that percent is in lira as a hint.
    final hint = (isPercent && amount != null && units != null)
        ? formatMoney(context, amount * units / 10000)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (hint != null)
                  Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: TextFormField(
              controller: _controllerFor(member.userId),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                isDense: true,
                suffixText: isPercent ? '%' : '₺',
              ),
              onChanged: (_) => setState(_markSplitChanged),
              validator: (value) {
                final v = parseDecimal(value ?? '');
                if (v == null || v <= 0 || !hasAtMostTwoDecimals(v)) {
                  return l10n.splitInvalidValue;
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
