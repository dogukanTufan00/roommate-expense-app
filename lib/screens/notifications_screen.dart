import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/screens/household_screen.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';
import 'package:roommate_expense_app/utils/notification_text.dart';

// The notifications of all my homes, newest first. Opening one takes me to its home.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await Api.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage(context, e))),
    );
  }

  // Marks one item read at once. If the request fails, the item goes back to unread.
  Future<void> _markRead(AppNotification item) async {
    if (item.read) return;
    setState(() => item.read = true);
    try {
      await Api.markNotificationRead(item.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => item.read = false);
      _showError(e);
    }
  }

  Future<void> _markAllRead() async {
    setState(() {
      for (final item in _items) {
        item.read = true;
      }
    });
    try {
      await Api.markAllNotificationsRead();
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      // Reload so the list shows what the server really has.
      await _load();
    }
  }

  // Marks the item read, then opens its home. Invitations go back to the homes
  // screen, where the invitation cards are.
  Future<void> _onTap(AppNotification item) async {
    _markRead(item);

    if (item.type == NotificationType.invitationReceived) {
      Navigator.pop(context);
      return;
    }
    final householdId = item.householdId;
    if (householdId == null) return;
    // A payment reminder opens the Balances tab, where the debt is.
    final initialTab = item.type == NotificationType.paymentReminder
        ? HouseholdScreen.balancesTab
        : 0;
    await _openHousehold(householdId, initialTab: initialTab);
  }

  Future<void> _openHousehold(int householdId, {int initialTab = 0}) async {
    final l10n = AppLocalizations.of(context);
    final List<Household> households;
    try {
      households = await Api.getHouseholds();
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    if (!mounted) return;

    // If I was removed from the home (or it was deleted), it is not in my list anymore.
    final matches = households.where((h) => h.id == householdId).toList();
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notificationsNoAccess)),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HouseholdScreen(household: matches.first, initialTab: initialTab),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasUnread = _items.any((item) => !item.read);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: l10n.notificationsMarkAllRead,
            onPressed: hasUnread ? _markAllRead : null,
          ),
        ],
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
        children: _items.isEmpty ? [_buildEmptyState(l10n)] : _buildGroups(l10n),
      ),
    );
  }

  // Splits the list into today, yesterday and earlier. The list is already newest first.
  List<Widget> _buildGroups(AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <AppNotification>[];
    final yesterdayItems = <AppNotification>[];
    final earlierItems = <AppNotification>[];
    for (final item in _items) {
      final time = item.createdAt;
      final day = DateTime(time.year, time.month, time.day);
      if (day == today) {
        todayItems.add(item);
      } else if (day == yesterday) {
        yesterdayItems.add(item);
      } else {
        earlierItems.add(item);
      }
    }

    return [
      ..._buildGroup(l10n.notificationsGroupToday, todayItems, l10n),
      ..._buildGroup(l10n.notificationsGroupYesterday, yesterdayItems, l10n),
      ..._buildGroup(l10n.notificationsGroupEarlier, earlierItems, l10n),
    ];
  }

  List<Widget> _buildGroup(
    String title,
    List<AppNotification> items,
    AppLocalizations l10n,
  ) {
    if (items.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.muted,
              ),
        ),
      ),
      for (final item in items) _buildTile(item, l10n),
    ];
  }

  Widget _buildTile(AppNotification item, AppLocalizations l10n) {
    final text = notificationText(l10n, item);
    final style = _styleFor(item.type);
    final theme = Theme.of(context);

    return Card(
      // Unread items get a warm tint, so they stand out from the read ones.
      color: item.read
          ? AppColors.paper
          : AppColors.terracotta.withValues(alpha: 0.10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onTap(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (text.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(text.body),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _relativeTime(l10n, item.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (!item.read)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 6),
                  child: CircleAvatar(radius: 4, backgroundColor: AppColors.terracotta),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // The icon and color for each kind of notification.
  _TypeStyle _styleFor(NotificationType type) {
    return switch (type) {
      NotificationType.expenseAdded =>
        const _TypeStyle(Icons.receipt_long_rounded, AppColors.terracotta),
      NotificationType.paymentRecorded =>
        const _TypeStyle(Icons.payments_rounded, AppColors.sage),
      NotificationType.invitationReceived =>
        const _TypeStyle(Icons.mail_rounded, AppColors.mustard),
      NotificationType.invitationAccepted =>
        const _TypeStyle(Icons.person_add_rounded, AppColors.sage),
      NotificationType.recurringExpenseAdded =>
        const _TypeStyle(Icons.autorenew_rounded, AppColors.ink),
      NotificationType.paymentReminder =>
        const _TypeStyle(Icons.notifications_active_rounded, AppColors.mustard),
      NotificationType.unknown =>
        const _TypeStyle(Icons.notifications_rounded, AppColors.muted),
    };
  }

  // "Az önce", "5 dk önce", "2 sa önce", and a date for anything older than a day.
  String _relativeTime(AppLocalizations l10n, DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return l10n.notificationsJustNow;
    if (difference.inMinutes < 60) {
      return l10n.notificationsMinutesAgo(difference.inMinutes);
    }
    if (difference.inHours < 24) {
      return l10n.notificationsHoursAgo(difference.inHours);
    }
    return formatDate(context, time);
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_none_rounded, size: 72, color: AppColors.muted),
          const SizedBox(height: 16),
          Text(
            l10n.notificationsEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// The icon and color of one notification kind.
class _TypeStyle {
  const _TypeStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}
