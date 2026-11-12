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

// The household's default ratio for each category. Everyone can read it,
// admins can change it. The expense form uses it to pre-fill the split.
class SplitDefaultsScreen extends StatefulWidget {
  const SplitDefaultsScreen({super.key, required this.householdId});

  final int householdId;

  @override
  State<SplitDefaultsScreen> createState() => _SplitDefaultsScreenState();
}

class _SplitDefaultsScreenState extends State<SplitDefaultsScreen> {
  // null means "still loading".
  List<Member>? _members;
  List<CategorySplitDefault> _defaults = [];
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final members = await Api.getMembers(widget.householdId);
      final defaults = await Api.getSplitDefaults(widget.householdId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _defaults = defaults;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = errorMessage(context, e));
    }
  }

  // The logged in user's row, found the same way the members screen does.
  Member? get _me {
    for (final member in _members ?? const <Member>[]) {
      if (member.email == Session.email) return member;
    }
    return null;
  }

  bool get _isAdmin => _me?.isAdmin ?? false;

  CategorySplitDefault? _defaultFor(String category) {
    for (final item in _defaults) {
      if (item.category == category) return item;
    }
    return null;
  }

  Future<void> _editCategory(String category) async {
    final members = _members;
    if (members == null) return;

    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _SplitDefaultDialog(
        householdId: widget.householdId,
        category: category,
        members: members,
        existing: _defaultFor(category),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.splitDefaults)),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_members == null) {
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
    final isAdmin = _isAdmin;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            l10n.splitDefaultsIntro,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          if (!isAdmin) ...[
            const SizedBox(height: 8),
            Text(
              l10n.splitDefaultsReadOnly,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 12),
          for (final category in expenseCategories)
            _buildCategoryCard(l10n, category, isAdmin),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(AppLocalizations l10n, String category, bool isAdmin) {
    final color = categoryColor(category);
    final def = _defaultFor(category);

    // Example: "Doğukan %60 · Bülent %40", or "Split equally" when there is no default.
    final description = (def == null || def.shares.isEmpty)
        ? l10n.splitEqualSplit
        : def.shares
            .map((s) => '${s.name} %${formatPercent(context, s.percent)}')
            .join(' · ');

    return Card(
      child: ListTile(
        onTap: isAdmin ? () => _editCategory(category) : null,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(categoryIcon(category), color: color),
        ),
        title: Text(
          categoryLabel(l10n, category),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(description),
        trailing: isAdmin ? const Icon(Icons.chevron_right) : null,
      ),
    );
  }
}

// Edits the percents of one category. It returns true when it saved or removed the default.
// It calls the API itself, so errors show in the screen's snack bar.
class _SplitDefaultDialog extends StatefulWidget {
  const _SplitDefaultDialog({
    required this.householdId,
    required this.category,
    required this.members,
    required this.existing,
  });

  final int householdId;
  final String category;
  // The active members. Each one gets a percent.
  final List<Member> members;
  // The saved default, or null when the category shares equally.
  final CategorySplitDefault? existing;

  @override
  State<_SplitDefaultDialog> createState() => _SplitDefaultDialogState();
}

class _SplitDefaultDialogState extends State<_SplitDefaultDialog> {
  final Map<int, TextEditingController> _controllers = {};

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final savedPercents = {
      for (final share in existing?.shares ?? const <CategorySplitShare>[])
        share.userId: share.percent,
    };
    // Without a saved ratio, start from an even split so no field is empty.
    final evenly = splitEvenly(10000, widget.members.length);

    for (var i = 0; i < widget.members.length; i++) {
      final userId = widget.members[i].userId;
      final String text;
      if (existing == null) {
        text = numberText(evenly[i] / 100);
      } else {
        final saved = savedPercents[userId];
        text = saved == null ? '' : numberText(saved);
      }
      _controllers[userId] = TextEditingController(text: text);
    }
  }

  @override
  void dispose() {
    // The controllers are disposed here, after the dialog is gone.
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Percent in hundredths, or null when the field is empty or invalid.
  int? _units(int userId) {
    final value = parseDecimal(_controllers[userId]!.text);
    if (value == null || value <= 0 || !hasAtMostTwoDecimals(value)) return null;
    return toHundredths(value);
  }

  // Left to hand out, in hundredths. Negative means too much.
  int get _remainingUnits {
    var used = 0;
    for (final member in widget.members) {
      used += _units(member.userId) ?? 0;
    }
    return 10000 - used;
  }

  // Every member has a valid percent and the total is exactly 100.
  bool get _valid {
    for (final member in widget.members) {
      if (_units(member.userId) == null) return false;
    }
    return _remainingUnits == 0;
  }

  Future<void> _save() async {
    if (!_valid) return;
    setState(() => _saving = true);

    final percents = {
      for (final member in widget.members)
        member.userId: parseDecimal(_controllers[member.userId]!.text)!,
    };
    try {
      await Api.saveSplitDefault(widget.householdId, widget.category, percents);
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

  Future<void> _remove() async {
    setState(() => _saving = true);
    try {
      await Api.deleteSplitDefault(widget.householdId, widget.category);
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

  // Shows an error under a field only when something was typed that is not a valid percent.
  String? _fieldError(AppLocalizations l10n, int userId) {
    final text = _controllers[userId]!.text.trim();
    if (text.isEmpty || _units(userId) != null) return null;
    return l10n.splitInvalidValue;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final remaining = _remainingUnits;
    final valid = _valid;

    return AlertDialog(
      title: Text(categoryLabel(l10n, widget.category)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final member in widget.members)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _controllers[member.userId],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.end,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          isDense: true,
                          suffixText: '%',
                          errorText: _fieldError(l10n, member.userId),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              l10n.splitRemainingPercent(formatPercent(context, remaining / 100)),
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: remaining == 0 ? AppColors.getsBack : AppColors.owes,
              ),
            ),
            if (!valid) ...[
              const SizedBox(height: 4),
              Text(
                l10n.splitNotBalanced,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.owes),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: _saving ? null : _remove,
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: Text(l10n.removeDefault),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: (_saving || !valid) ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
