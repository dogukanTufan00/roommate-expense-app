import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/activity_text.dart';
import 'package:roommate_expense_app/utils/errors.dart';

// The history of one home, newest first, grouped by day.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.householdId,
    required this.householdName,
  });

  final int householdId;
  final String householdName;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // How many items one page has. A shorter page means there is nothing older.
  static const int _pageSize = 30;

  List<ActivityEntry> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Loads the newest page. Also used for pull-to-refresh.
  Future<void> _load() async {
    try {
      final items = await Api.getActivity(widget.householdId, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _items = items;
        _hasMore = items.length >= _pageSize;
        _loadError = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_items.isEmpty) {
        // First load failed: show the error with a retry button.
        setState(() {
          _loadError = e;
          _loading = false;
        });
      } else {
        // Refresh failed but the list is still there: keep it and show a message.
        setState(() => _loading = false);
        _showError(e);
      }
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    await _load();
  }

  // Adds the next, older page after the list. beforeId is the smallest id loaded.
  Future<void> _loadMore() async {
    if (_loadingMore || _items.isEmpty) return;
    final oldestId = _items.map((item) => item.id).reduce(min);
    setState(() => _loadingMore = true);
    try {
      final more = await Api.getActivity(
        widget.householdId,
        limit: _pageSize,
        beforeId: oldestId,
      );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...more];
        _hasMore = more.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      _showError(e);
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage(context, e))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.historyTitle),
            Text(
              widget.householdName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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

    // ListView even when empty, so pull-to-refresh still works.
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: _items.isEmpty
            ? [_buildEmptyState(l10n)]
            : [..._buildGroups(l10n), if (_hasMore) _buildLoadMore(l10n)],
      ),
    );
  }

  // A day header before the first item of each day. The list is already newest first.
  List<Widget> _buildGroups(AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final widgets = <Widget>[];
    DateTime? currentDay;
    for (final item in _items) {
      final time = item.createdAt;
      final day = DateTime(time.year, time.month, time.day);
      if (day != currentDay) {
        currentDay = day;
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            _dayTitle(l10n, day, today, yesterday),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                ),
          ),
        ));
      }
      widgets.add(_buildTile(item, l10n));
    }
    return widgets;
  }

  // "Bugün", "Dün", or a date like "12 Kasım 2026".
  String _dayTitle(
    AppLocalizations l10n,
    DateTime day,
    DateTime today,
    DateTime yesterday,
  ) {
    if (day == today) return l10n.notificationsGroupToday;
    if (day == yesterday) return l10n.notificationsGroupYesterday;

    final text = DateFormat('d MMMM yyyy', l10n.localeName).format(day);
    // intl writes Turkish month names in lowercase, so the month gets a capital.
    final parts = text.split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      parts[1] = parts[1][0].toUpperCase() + parts[1].substring(1);
    }
    return parts.join(' ');
  }

  Widget _buildTile(ActivityEntry entry, AppLocalizations l10n) {
    final text = activityText(l10n, entry);
    final style = _styleFor(entry.type);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(style.icon, color: style.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text.sentence,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat.Hm(l10n.localeName).format(entry.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
            // The changes sit under the whole header, not beside the time, so they get the full
            // width of the card (minus the icon column, to stay lined up with the sentence).
            if (text.changeLines.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 56, top: 8),
                child: _changes(theme, l10n, text.changeLines),
              ),
          ],
        ),
      ),
    );
  }

  // The changes of one item. Short values (money, dates, choices) go into a two-column table:
  // labels on the left, "old → new" right-aligned in one column, so the amounts line up under
  // each other and are never split over two lines. If space is tight, a label is cut with "…"
  // instead. Shares come under one "Paylar" heading with only the names. Free text (a note,
  // a description) does not fit a table cell well, so it follows as normal wrapping lines.
  Widget _changes(ThemeData theme, AppLocalizations l10n, List<ChangeLine> lines) {
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted);
    final valueStyle = labelStyle?.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    TableRow row(String label, String values, {bool indent = false}) {
      return TableRow(children: [
        Padding(
          padding: EdgeInsets.only(left: indent ? 10 : 0, right: 12, bottom: 4),
          child: Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(values, style: valueStyle, maxLines: 1, softWrap: false, textAlign: TextAlign.end),
        ),
      ]);
    }

    final fields = [for (final l in lines) if (l.short && !l.share && l.values != null) l];
    final shares = [for (final l in lines) if (l.share && l.values != null) l];
    final others = [for (final l in lines) if (!l.short && !l.share || l.values == null) l];

    final rows = <TableRow>[
      for (final l in fields) row(l.label, l.values!),
      if (shares.isNotEmpty)
        TableRow(children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              l10n.historySharesHeading,
              style: labelStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox.shrink(),
        ]),
      for (final l in shares) row(l.label, l.values!, indent: true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rows.isNotEmpty)
          Table(
            // The value column is as wide as its widest value; the labels get the rest.
            columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
            defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: rows,
          ),
        for (final l in others)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(l.values == null ? l.label : '${l.label}: ${l.values}', style: labelStyle),
          ),
      ],
    );
  }

  Widget _buildLoadMore(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Center(
        child: OutlinedButton(
          onPressed: _loadingMore ? null : _loadMore,
          child: _loadingMore
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.historyLoadMore),
        ),
      ),
    );
  }

  // The icon and color for each kind of item. Adds are green, edits yellow, deletes red.
  _TypeStyle _styleFor(ActivityType type) {
    return switch (type) {
      ActivityType.householdCreated =>
        const _TypeStyle(Icons.home_rounded, AppColors.sage),
      ActivityType.householdRenamed =>
        const _TypeStyle(Icons.edit_rounded, AppColors.mustard),
      ActivityType.ownershipTransferred =>
        const _TypeStyle(Icons.workspace_premium_rounded, AppColors.mustard),
      ActivityType.memberJoined =>
        const _TypeStyle(Icons.person_add_rounded, AppColors.sage),
      ActivityType.memberLeft =>
        const _TypeStyle(Icons.person_remove_rounded, AppColors.ink),
      ActivityType.memberRemoved =>
        const _TypeStyle(Icons.person_remove_rounded, AppColors.terracotta),
      ActivityType.memberRoleChanged =>
        const _TypeStyle(Icons.person_rounded, AppColors.ink),
      ActivityType.expenseAdded =>
        const _TypeStyle(Icons.add_circle_rounded, AppColors.sage),
      ActivityType.expenseUpdated =>
        const _TypeStyle(Icons.edit_rounded, AppColors.mustard),
      ActivityType.expenseDeleted =>
        const _TypeStyle(Icons.delete_outline_rounded, AppColors.owes),
      ActivityType.recurringExpenseGenerated =>
        const _TypeStyle(Icons.autorenew_rounded, AppColors.ink),
      ActivityType.paymentAdded =>
        const _TypeStyle(Icons.add_circle_rounded, AppColors.sage),
      ActivityType.paymentUpdated =>
        const _TypeStyle(Icons.edit_rounded, AppColors.mustard),
      ActivityType.paymentDeleted =>
        const _TypeStyle(Icons.delete_outline_rounded, AppColors.owes),
      ActivityType.unknown =>
        const _TypeStyle(Icons.history_rounded, AppColors.muted),
    };
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 72, 32, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history_rounded, size: 96, color: AppColors.muted),
          const SizedBox(height: 20),
          Text(
            l10n.historyEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.historyEmptyHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// The icon and color of one history kind.
class _TypeStyle {
  const _TypeStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}
