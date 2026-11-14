import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/errors.dart';

// The editor of one chore: its name, who takes part and in which order (the turn order).
// For an edit it also sets who is up now. Returns true after a save.
class ChoreFormScreen extends StatefulWidget {
  const ChoreFormScreen({super.key, required this.householdId, this.chore});

  final int householdId;
  // Null for a new chore.
  final Chore? chore;

  @override
  State<ChoreFormScreen> createState() => _ChoreFormScreenState();
}

class _ChoreFormScreenState extends State<ChoreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  // The controller lives in the State so the text stays while the screen is open.
  late final TextEditingController _nameController =
      TextEditingController(text: widget.chore?.name ?? '');

  // The active members of the home. Null while they load.
  List<Member>? _members;
  Object? _loadError;

  // The people who take part, in turn order. The first one is up first.
  late final List<int> _order = [
    for (final member in widget.chore?.rotation ?? const <ChoreMember>[]) member.userId,
  ];

  // Who is up now (edit only). Null when it is not one of the people in _order.
  late int? _currentUserId = widget.chore?.currentUserId;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await Api.getMembers(widget.householdId);
      if (!mounted) return;
      final ids = {for (final m in members) m.userId};
      setState(() {
        _members = members;
        // A person who is no longer an active member cannot stay in the rotation.
        _order.removeWhere((id) => !ids.contains(id));
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  void _retry() {
    setState(() => _loadError = null);
    _loadMembers();
  }

  // The person who is up now: the chosen one if still in the rotation, else the first one.
  int? get _effectiveCurrentUserId {
    if (_order.contains(_currentUserId)) return _currentUserId;
    return _order.isEmpty ? null : _order.first;
  }

  // Ticks a person in or out. A new person joins at the end of the order.
  void _toggle(int userId, bool? include) {
    setState(() {
      if (include == true) {
        if (!_order.contains(userId)) _order.add(userId);
      } else {
        _order.remove(userId);
      }
    });
  }

  // Moves one person in the turn order.
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final id = _order.removeAt(oldIndex);
      _order.insert(newIndex, id);
    });
  }

  String _nameOf(int userId) {
    for (final member in _members ?? const <Member>[]) {
      if (member.userId == userId) return member.name;
    }
    return '';
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_order.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.choresPickOne)));
      return;
    }

    final name = _nameController.text.trim();
    final chore = widget.chore;
    setState(() => _saving = true);
    try {
      if (chore == null) {
        await Api.createChore(widget.householdId, name, List.of(_order));
      } else {
        await Api.updateChore(
          widget.householdId,
          chore.id,
          name: name,
          rotationUserIds: List.of(_order),
          currentUserId: _effectiveCurrentUserId,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage(context, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.chore != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.choresFormEditTitle : l10n.choresFormNewTitle),
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
                Text(errorMessage(context, _loadError!), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _retry, child: Text(l10n.retry)),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final current = _effectiveCurrentUserId;
    final isEdit = widget.chore != null;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            maxLength: 60,
            autofocus: !isEdit,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.choresNameLabel),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? l10n.choresNameRequired : null,
          ),
          const SizedBox(height: 16),

          // Step 1: tick the people who take part.
          Text(l10n.choresPeopleTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            l10n.choresPeopleHint,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          for (final member in members)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(member.name),
              value: _order.contains(member.userId),
              onChanged: _saving ? null : (value) => _toggle(member.userId, value),
            ),

          // Step 2: drag the ticked people into the turn order.
          if (_order.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.choresOrderTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: _onReorder,
              children: [
                for (var i = 0; i < _order.length; i++)
                  ListTile(
                    key: ValueKey(_order[i]),
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.mustard.withValues(alpha: 0.4),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(_nameOf(_order[i])),
                    trailing: ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.drag_handle_rounded, color: AppColors.muted),
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Edit only: who is up now.
          if (isEdit && _order.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              // The key rebuilds the field when the people change, so it never shows a removed one.
              key: ValueKey('next-${_order.join(',')}'),
              initialValue: current,
              decoration: InputDecoration(labelText: l10n.choresNextUp),
              items: [
                for (final id in _order)
                  DropdownMenuItem(value: id, child: Text(_nameOf(id))),
              ],
              onChanged: (value) => setState(() => _currentUserId = value),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ),
        ],
      ),
    );
  }
}
