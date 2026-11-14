import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/screens/expense_form_screen.dart';
import 'package:roommate_expense_app/screens/shopping_list_screen.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/category.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';
import 'package:roommate_expense_app/utils/split.dart';
import 'package:roommate_expense_app/widgets/illustration.dart';

// The filter for "who is involved". Only one person filter can be on at a time.
enum _PersonFilter { all, paidByMe, inMyShare }

// One calendar month of expenses, newest first, with its total in hundredths.
class _MonthGroup {
  _MonthGroup(this.month);

  // The first day of the month, at local midnight.
  final DateTime month;
  final List<Expense> expenses = [];
  int totalHundredths = 0;
}

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
  // The logged in user's id, for the "your share" line and the person filters.
  // Null if the members could not be loaded.
  int? _myUserId;
  // How many shopping items are still open. Null when the shopping list could not be loaded,
  // then the card shows no count. The expenses still load.
  int? _openShoppingCount;

  _PersonFilter _personFilter = _PersonFilter.all;
  // One category code from expenseCategories, or null for all categories.
  String? _categoryFilter;

  // Months the user opened or closed by tapping. Other months use the default:
  // the current month and later are open, older months are closed.
  final Map<DateTime, bool> _monthOpenByTap = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Both requests start now and run side by side.
      final expensesFuture = Api.getExpenses(widget.householdId);
      final shoppingFuture = _fetchOpenShoppingCount();
      final expenses = await expensesFuture;
      final openShoppingCount = await shoppingFuture;
      final myUserId = await _findMyUserId();
      if (!mounted) return;
      setState(() {
        _expenses = expenses;
        _openShoppingCount = openShoppingCount;
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage(context, e))));
      }
    }
  }

  // The number of open shopping items. Never throws: a failure only hides the count.
  Future<int?> _fetchOpenShoppingCount() async {
    try {
      final items = await Api.getShoppingItems(widget.householdId);
      return items.where((item) => !item.bought).length;
    } catch (_) {
      return null;
    }
  }

  // Opens the shared shopping list. The list may have changed (expenses from checkout),
  // so this tab always reloads when the user comes back.
  Future<void> _openShoppingList() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListScreen(householdId: widget.householdId),
      ),
    );
    if (!mounted) return;
    _load();
  }

  // The card at the top of the tab: the shopping list with its open item count.
  Widget _shoppingCard(AppLocalizations l10n) {
    final count = _openShoppingCount;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.shopping_cart_outlined),
        title: Text(
          l10n.shoppingListTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: count == null ? null : Text(l10n.shoppingCardSubtitle(count)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        onTap: _openShoppingList,
      ),
    );
  }

  // Finds the logged in user in the member list, the same way the members screen does.
  // The list is only used for the split line and the person filters, so a failure is not shown.
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

  // ---- Filters ----

  bool get _filtersActive =>
      _personFilter != _PersonFilter.all || _categoryFilter != null;

  void _clearFilters() {
    setState(() {
      _personFilter = _PersonFilter.all;
      _categoryFilter = null;
    });
  }

  // Tapping the active person filter again turns it off.
  void _togglePersonFilter(_PersonFilter filter) {
    setState(() {
      _personFilter = _personFilter == filter ? _PersonFilter.all : filter;
    });
  }

  // Tapping the active category again turns it off.
  void _toggleCategoryFilter(String category) {
    setState(() {
      _categoryFilter = _categoryFilter == category ? null : category;
    });
  }

  // True when the expense passes both the person filter and the category filter.
  bool _matchesFilters(Expense e) {
    final me = _myUserId;
    if (_personFilter == _PersonFilter.paidByMe && e.paidByUserId != me) {
      return false;
    }
    if (_personFilter == _PersonFilter.inMyShare &&
        !e.shares.any((share) => share.userId == me)) {
      return false;
    }
    final category = _categoryFilter;
    if (category != null && e.category != category) return false;
    return true;
  }

  // ---- Months ----

  // Splits the expenses into months. The newest expense comes first, so the months do too.
  List<_MonthGroup> _groupByMonth(List<Expense> expenses) {
    final sorted = [...expenses]
      // Newest date first. Expenses on the same day have equal dates (the form picks a day, not
      // a time), so without a tie-breaker their order looked random; the most recently added
      // one goes first.
      ..sort((a, b) {
        final byDate = b.expenseDate.compareTo(a.expenseDate);
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });

    final groups = <_MonthGroup>[];
    for (final e in sorted) {
      final month = DateTime(e.expenseDate.year, e.expenseDate.month);
      if (groups.isEmpty || groups.last.month != month) {
        groups.add(_MonthGroup(month));
      }
      final group = groups.last;
      group.expenses.add(e);
      group.totalHundredths += toHundredths(e.amount);
    }
    return groups;
  }

  // The current month and any later month start open. Older months start closed.
  bool _isMonthOpen(DateTime month) {
    final tapped = _monthOpenByTap[month];
    if (tapped != null) return tapped;
    final now = DateTime.now();
    return !month.isBefore(DateTime(now.year, now.month));
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
    // The shopping card is always at the top. Only a home with no expenses at all
    // gets the big empty-state picture below it.
    if (expenses.isEmpty) {
      final theme = Theme.of(context);
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 88),
          children: [
            _shoppingCard(l10n),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
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
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noExpenses,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final groups = _groupByMonth(expenses.where(_matchesFilters).toList());

    // The shopping card is first. The filter row scrolls away with the list. The month cards follow it.
    final children = <Widget>[_shoppingCard(l10n), _filterRow(l10n)];
    if (groups.isEmpty) {
      children.add(_noMatchesView(l10n));
    } else {
      for (final group in groups) {
        children.add(_monthHeader(group, l10n));
        if (_isMonthOpen(group.month)) {
          for (final e in group.expenses) {
            children.add(_expenseCard(context, l10n, e));
          }
        }
      }
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        // Top and bottom padding: the floating button must not cover the last card.
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        children: children,
      ),
    );
  }

  // One row of chips: "All", the two person filters, then one chip per category.
  Widget _filterRow(AppLocalizations l10n) {
    final me = _myUserId;
    // The person filters need to know who "me" is, so they are off until the members load.
    final chips = <Widget>[
      FilterChip(
        label: Text(l10n.filterAll),
        selected: !_filtersActive,
        onSelected: (_) => _clearFilters(),
      ),
      FilterChip(
        label: Text(l10n.filterPaidByMe),
        selected: _personFilter == _PersonFilter.paidByMe,
        onSelected: me == null
            ? null
            : (_) => _togglePersonFilter(_PersonFilter.paidByMe),
      ),
      FilterChip(
        label: Text(l10n.filterInMyShare),
        selected: _personFilter == _PersonFilter.inMyShare,
        onSelected: me == null
            ? null
            : (_) => _togglePersonFilter(_PersonFilter.inMyShare),
      ),
      for (final category in expenseCategories)
        FilterChip(
          avatar: Icon(
            categoryIcon(category),
            size: 18,
            color: categoryColor(category),
          ),
          label: Text(categoryLabel(l10n, category)),
          selected: _categoryFilter == category,
          onSelected: (_) => _toggleCategoryFilter(category),
        ),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }

  // Shown when expenses exist but none match the filters. A small text is enough here.
  Widget _noMatchesView(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        children: [
          Text(
            l10n.noExpensesMatchFilter,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _clearFilters,
            child: Text(l10n.clearFilter),
          ),
        ],
      ),
    );
  }

  // The month name on the left, its count and total on the right, and a chevron.
  // Tapping it opens or closes the month's expenses.
  Widget _monthHeader(_MonthGroup group, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final open = _isMonthOpen(group.month);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _monthOpenByTap[group.month] = !open),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  formatMonthYear(context, group.month),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  l10n.monthExpenseSummary(
                    group.expenses.length,
                    formatMoney(context, group.totalHundredths / 100),
                  ),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // One expense. Tapping it opens the form to edit it.
  Widget _expenseCard(BuildContext context, AppLocalizations l10n, Expense e) {
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
          description.isEmpty ? categoryLabel(l10n, e.category) : description,
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
                  const Icon(Icons.autorenew_rounded, size: 16, color: AppColors.muted),
                ],
                // Tiny muted tag on copies the server created by itself.
                if (e.generatedFromId != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    l10n.recurringAutoTag,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                // Paperclip and count when receipts are attached.
                if (e.attachmentCount > 0) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.attach_file_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${e.attachmentCount}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            if (splitLine != null)
              Text(
                splitLine,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
          ],
        ),
        trailing: Text(
          formatMoney(context, e.amount),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        onTap: () => _openForm(expense: e),
      ),
    );
  }
}
