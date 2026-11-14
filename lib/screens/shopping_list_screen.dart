import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/screens/expense_form_screen.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';
import 'package:roommate_expense_app/widgets/illustration.dart';

// Menu actions on one open item.
enum _ItemAction { edit, delete }

// The shared shopping list of one home. Open items are ticked when bought.
// Bought items can then be saved together as one expense.
class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key, required this.householdId});

  final int householdId;

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<ShoppingItem> _items = [];
  bool _loading = true;
  // Set when the first load fails, so the screen can show a retry button.
  Object? _loadError;

  // Items whose "bought" or "restore" request is running, so they cannot be tapped twice.
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  // The first failure replaces the screen with an error. Later failures
  // (pull to refresh, after an action) only show a SnackBar.
  Future<void> _load() async {
    try {
      final items = await Api.getShoppingItems(widget.householdId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_loading) {
        setState(() {
          _loadError = e;
          _loading = false;
        });
      } else {
        _showError(e);
      }
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMessage(context, e))));
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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

  // Runs one request for one item. The row is disabled while it runs, then the list reloads.
  Future<void> _changeItem(
    ShoppingItem item,
    Future<Object?> Function() request,
  ) async {
    setState(() => _busy.add(item.id));
    try {
      await request();
      await _load();
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  Future<void> _markBought(ShoppingItem item) => _changeItem(
        item,
        () => Api.markShoppingItemBought(widget.householdId, item.id),
      );

  Future<void> _restore(ShoppingItem item) => _changeItem(
        item,
        () => Api.restoreShoppingItem(widget.householdId, item.id),
      );

  // For items already saved into an expense: adds a NEW item with the same name and note.
  // The old one stays linked to its expense, so it can never be saved twice.
  Future<void> _addAgain(ShoppingItem item) async {
    setState(() => _busy.add(item.id));
    try {
      await Api.addShoppingItem(widget.householdId, item.name, item.note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).shoppingAddedAgain(item.name))),
      );
      await _load();
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  Future<void> _deleteItem(ShoppingItem item) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      message: l10n.shoppingDeleteConfirm,
      confirmLabel: l10n.delete,
    );
    if (!confirmed || !mounted) return;

    try {
      await Api.deleteShoppingItem(widget.householdId, item.id);
    } catch (e) {
      if (mounted) _showError(e);
      return;
    }
    if (!mounted) return;
    await _load();
  }

  // Deletes every bought item after a confirmation.
  Future<void> _clearBought() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      message: l10n.shoppingClearConfirm,
      confirmLabel: l10n.shoppingClear,
    );
    if (!confirmed || !mounted) return;

    try {
      await Api.clearBoughtShoppingItems(widget.householdId);
    } catch (e) {
      if (mounted) _showError(e);
      return;
    }
    if (!mounted) return;
    await _load();
  }

  // Opens the add sheet, or the edit sheet when editing is set. Reloads when it closes.
  Future<void> _openItemSheet({ShoppingItem? editing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ItemSheet(householdId: widget.householdId, editing: editing),
    );
    if (!mounted) return;
    await _load();
  }

  // Picks the bought items for one expense, then opens the expense form with them.
  Future<void> _checkout(List<ShoppingItem> candidates) async {
    final l10n = AppLocalizations.of(context);
    final chosen = await showModalBottomSheet<List<ShoppingItem>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _CheckoutPicker(items: candidates),
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(
          householdId: widget.householdId,
          shoppingItems: chosen,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
    if (saved == true && mounted) _showMessage(l10n.shoppingExpenseSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Bought items that are not in an expense yet. The checkout button covers these.
    final checkoutItems =
        _items.where((item) => item.bought && item.expenseId == null).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shoppingListTitle)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.shoppingAddFab),
        onPressed: () => _openItemSheet(),
      ),
      // The Scaffold puts the floating button above this bar, so the two never overlap.
      bottomNavigationBar: checkoutItems.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton.icon(
                  icon: const Icon(Icons.receipt_long),
                  label: Text(l10n.shoppingCheckoutButton(checkoutItems.length)),
                  onPressed: () => _checkout(checkoutItems),
                ),
              ),
            ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final loadError = _loadError;
    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage(context, loadError), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _retry, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }

    final open = _items.where((item) => !item.bought).toList();
    final bought = _items.where((item) => item.bought).toList();

    // ListView keeps pull-to-refresh working even when the list is empty.
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // The bottom space keeps the last row clear of the add button.
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
        children: [
          if (open.isEmpty)
            _emptyState(l10n)
          else
            for (final item in open) _openRow(item, l10n),
          if (bought.isNotEmpty) ...[
            _boughtHeader(bought.length, l10n),
            for (final item in bought) _boughtRow(item, l10n),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                l10n.shoppingBoughtNote,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Shown when no item is open. Bought items may still be listed below it.
  Widget _emptyState(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Illustration(
            'empty-shopping.png',
            fallbackIcon: Icons.shopping_cart_outlined,
            height: 140,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.shoppingEmptyTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.shoppingEmptyHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  // One open item: a checkbox to tick it as bought, its name and a menu for edit and delete.
  Widget _openRow(ShoppingItem item, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: AppColors.muted);
    final busy = _busy.contains(item.id);
    final note = item.note;
    final errorColor = theme.colorScheme.error;

    return Card(
      child: ListTile(
        leading: Checkbox(
          value: false,
          onChanged: busy ? null : (_) => _markBought(item),
        ),
        title: Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (note != null)
              Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            Text(
              l10n.shoppingAddedBy(item.addedByName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
          ],
        ),
        trailing: PopupMenuButton<_ItemAction>(
          onSelected: (action) {
            switch (action) {
              case _ItemAction.edit:
                _openItemSheet(editing: item);
              case _ItemAction.delete:
                _deleteItem(item);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: _ItemAction.edit,
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 12),
                  Text(l10n.edit),
                ],
              ),
            ),
            PopupMenuItem(
              value: _ItemAction.delete,
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
      ),
    );
  }

  // The "Bought (N)" header with the clear button.
  Widget _boughtHeader(int count, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.shoppingBoughtHeader(count),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: _clearBought,
            child: Text(l10n.shoppingClear),
          ),
        ],
      ),
    );
  }

  // One bought item: struck through, who bought it and when, and a button to put it back.
  Widget _boughtRow(ShoppingItem item, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: AppColors.muted);
    final busy = _busy.contains(item.id);
    final note = item.note;
    final boughtAt = item.boughtAt;
    final boughtByName = item.boughtByName;

    final details = [
      if (boughtByName != null) l10n.shoppingBoughtBy(boughtByName),
      if (boughtAt != null)
        '${formatDate(context, boughtAt)} ${DateFormat.Hm(localeTagOf(context)).format(boughtAt)}',
    ].join(' · ');

    return Card(
      child: ListTile(
        leading: const Checkbox(value: true, onChanged: null),
        title: Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
            color: AppColors.muted,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (note != null)
              Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            Row(
              children: [
                Flexible(
                  child: Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ),
                if (item.expenseId != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.sage.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l10n.shoppingSavedAsExpense,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sage,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        // An item saved into an expense is never brought back (it could be saved twice);
        // "add again" puts a new copy on the list instead.
        trailing: item.expenseId != null
            ? IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                tooltip: l10n.shoppingAddAgain,
                onPressed: busy ? null : () => _addAgain(item),
              )
            : IconButton(
                icon: const Icon(Icons.undo),
                tooltip: l10n.shoppingRestore,
                onPressed: busy ? null : () => _restore(item),
              ),
      ),
    );
  }
}

// The add and edit sheet. In add mode it stays open after each item, for fast entry.
class _ItemSheet extends StatefulWidget {
  const _ItemSheet({required this.householdId, this.editing});

  final int householdId;
  // The item to edit, or null to add a new one.
  final ShoppingItem? editing;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  final _nameFocus = FocusNode();

  bool _saving = false;
  // The last item added in this sheet, shown as "Added: Milk".
  String? _lastAdded;
  // Shown under the name field when a save fails.
  String? _error;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _nameController.text = editing.name;
      _noteController.text = editing.note ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // Adds the item (add mode) or saves it (edit mode). Enter on the name field also saves.
  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;
    final note = _noteController.text.trim();
    final noteOrNull = note.isEmpty ? null : note;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final editing = widget.editing;
      if (editing == null) {
        await Api.addShoppingItem(widget.householdId, name, noteOrNull);
        if (!mounted) return;
        // The sheet stays open. Fields are cleared and the cursor goes back to the name.
        setState(() {
          _saving = false;
          _lastAdded = name;
          _nameController.clear();
          _noteController.clear();
        });
        _nameFocus.requestFocus();
      } else {
        await Api.updateShoppingItem(widget.householdId, editing.id, name, noteOrNull);
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = errorMessage(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canSave = !_saving && _nameController.text.trim().isNotEmpty;

    return Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            autofocus: true,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.shoppingNameLabel,
              errorText: _error,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.shoppingNoteLabel,
              hintText: l10n.shoppingNoteHint,
            ),
            onSubmitted: (_) => _save(),
          ),
          if (_lastAdded != null && !_isEdit) ...[
            const SizedBox(height: 4),
            Text(
              l10n.shoppingAddedNotice(_lastAdded!),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.getsBack,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: canSave ? _save : null,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEdit ? l10n.save : l10n.shoppingAddButton),
          ),
        ],
      ),
    );
  }
}

// Asks which bought items are on the receipt. All are checked at first.
// Pops with the checked items.
class _CheckoutPicker extends StatefulWidget {
  const _CheckoutPicker({required this.items});

  final List<ShoppingItem> items;

  @override
  State<_CheckoutPicker> createState() => _CheckoutPickerState();
}

class _CheckoutPickerState extends State<_CheckoutPicker> {
  late final Set<int> _chosenIds = {for (final item in widget.items) item.id};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final chosen = [
      for (final item in widget.items)
        if (_chosenIds.contains(item.id)) item,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.shoppingPickTitle,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final item in widget.items)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    value: _chosenIds.contains(item.id),
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        _chosenIds.add(item.id);
                      } else {
                        _chosenIds.remove(item.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: chosen.isEmpty
                ? null
                : () => Navigator.pop(context, chosen),
            child: Text(l10n.shoppingContinue),
          ),
        ],
      ),
    );
  }
}
