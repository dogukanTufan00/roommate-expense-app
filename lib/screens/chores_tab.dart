import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/api/api_client.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/screens/chore_form_screen.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';
import 'package:roommate_expense_app/widgets/illustration.dart';

// The "Chores" tab: the home's chores, whose turn each one is, and who did it last.
// It is shown inside another screen's TabBarView, and it has its own add button.
class ChoresTab extends StatefulWidget {
  const ChoresTab({super.key, required this.householdId});

  final int householdId;

  @override
  State<ChoresTab> createState() => _ChoresTabState();
}

// Menu actions on one chore card.
enum _ChoreAction { edit, delete }

class _ChoresTabState extends State<ChoresTab> {
  List<Chore> _chores = [];

  // The logged in user's id, found by the login email (the API does not say "me").
  int? _myUserId;

  // Chores whose list of recent completions is open.
  final Set<int> _historyOpen = {};

  // Chores whose "done" or "remind" request is running, so its buttons cannot be tapped twice.
  final Set<int> _busy = {};

  bool _loading = true;
  // Set when the first load fails, so the tab can show a retry button.
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  // First load. A failure replaces the whole tab with an error and a retry button.
  Future<void> _loadInitial() async {
    try {
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      Api.getChores(widget.householdId),
      Api.getMembers(widget.householdId),
    ]);
    final chores = results[0] as List<Chore>;
    final members = results[1] as List<Member>;

    int? myId;
    for (final member in members) {
      if (member.email == Session.email) myId = member.userId;
    }

    if (!mounted) return;
    setState(() {
      _chores = chores;
      _myUserId = myId;
      _loading = false;
      _loadError = null;
    });
  }

  // Used by pull to refresh and after an action. The screen already has data,
  // so a failure only shows a SnackBar.
  Future<void> _refresh() async {
    try {
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _loadInitial();
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

  // Marks the chore done. Anyone may do it, but when the turn is someone else's, ask first.
  Future<void> _markDone(Chore chore) async {
    final l10n = AppLocalizations.of(context);
    final notMyTurn =
        chore.currentUserId != null && chore.currentUserId != _myUserId;
    if (notMyTurn) {
      final confirmed = await _confirm(
        message: l10n.choresDoneNotMyTurn(chore.currentUserName ?? ''),
        confirmLabel: l10n.choresDone,
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _busy.add(chore.id));
    try {
      await Api.markChoreDone(widget.householdId, chore.id);
      if (!mounted) return;
      _showMessage(l10n.choresDoneSnack);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy.remove(chore.id));
    }
  }

  // Reminds the person whose turn it is. The reload gives the new cooldown.
  Future<void> _remind(Chore chore) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy.add(chore.id));
    try {
      await Api.remindChore(widget.householdId, chore.id);
      if (!mounted) return;
      _showMessage(l10n.reminderSent);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      // 400 (it is my turn now) and 429 (already reminded) mean the screen is out of date.
      if (e is ApiException && (e.statusCode == 400 || e.statusCode == 429)) {
        await _refresh();
      }
    } finally {
      if (mounted) setState(() => _busy.remove(chore.id));
    }
  }

  Future<void> _delete(Chore chore) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      message: l10n.choresDeleteConfirm,
      confirmLabel: l10n.delete,
    );
    if (!confirmed || !mounted) return;

    try {
      await Api.deleteChore(widget.householdId, chore.id);
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    if (!mounted) return;
    _showMessage(l10n.choresDeleted);
    await _refresh();
  }

  // Opens the editor. chore is null for a new one. The editor returns true after a save.
  Future<void> _openForm([Chore? chore]) async {
    final l10n = AppLocalizations.of(context);
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChoreFormScreen(householdId: widget.householdId, chore: chore),
      ),
    );
    if (saved != true || !mounted) return;
    _showMessage(l10n.choresSaved);
    await _refresh();
  }

  // "Now", "5 min ago", "2 hours ago", "yesterday", "3 days ago", or a date for older ones.
  String _whenText(AppLocalizations l10n, DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final days = today.difference(day).inDays;

    if (days == 0) {
      if (difference.inMinutes < 1) return l10n.notificationsJustNow;
      if (difference.inMinutes < 60) return l10n.choresMinutesAgo(difference.inMinutes);
      return l10n.choresHoursAgo(difference.inHours);
    }
    if (days == 1) return l10n.choresYesterday;
    if (days < 7) return l10n.choresDaysAgo(days);
    return formatDate(context, time);
  }

  // "Today at 14:30" or "Tomorrow at 14:30" in local time. A reminder cooldown lasts at most
  // 24 hours, so it always ends today or tomorrow.
  String _remindedAgainLabel(AppLocalizations l10n, DateTime until) {
    final now = DateTime.now();
    final time = DateFormat.Hm(localeTagOf(context)).format(until);
    final isToday =
        until.year == now.year && until.month == now.month && until.day == now.day;
    return isToday
        ? l10n.choresRemindedToday(time)
        : l10n.choresRemindedTomorrow(time);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.choresAdd),
        onPressed: () => _openForm(),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                errorMessage(context, _loadError!),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _retry, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        // Lets pull to refresh work even when the list is short.
        physics: const AlwaysScrollableScrollPhysics(),
        // The bottom space keeps the last card clear of the add button.
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 96),
        children: _chores.isEmpty
            ? [_emptyState(l10n)]
            : [for (final chore in _chores) _choreCard(chore, l10n)],
      ),
    );
  }

  Widget _emptyState(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Illustration(
            'empty-chores.png',
            fallbackIcon: Icons.cleaning_services_rounded,
            height: 160,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.choresEmptyTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.choresEmptyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n.choresAdd),
            onPressed: () => _openForm(),
          ),
        ],
      ),
    );
  }

  // One card: the name, whose turn it is, the rotation, the last completion and the buttons.
  Widget _choreCard(Chore chore, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: AppColors.muted);
    final errorColor = theme.colorScheme.error;
    final isMine = chore.currentUserId != null && chore.currentUserId == _myUserId;
    final busy = _busy.contains(chore.id);
    final historyOpen = _historyOpen.contains(chore.id);

    // The reminder goes to the person whose turn it is, and only when that is not me.
    final canRemind = chore.currentUserId != null && !isMine;
    // Set while a reminder is on cooldown: the time when it is allowed again.
    final reminderAt = chore.reminderAvailableAt;
    final DateTime? remindWaitingUntil =
        reminderAt != null && reminderAt.isAfter(DateTime.now()) ? reminderAt : null;

    // Who is up now. Mine is highlighted.
    final String turnText;
    if (chore.currentUserId == null) {
      turnText = l10n.choresNobodyTurn;
    } else if (isMine) {
      turnText = l10n.choresTurnYou;
    } else {
      turnText = l10n.choresTurnOf(chore.currentUserName ?? '');
    }

    final last = chore.recentCompletions.isEmpty ? null : chore.recentCompletions.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    chore.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<_ChoreAction>(
                  onSelected: (action) {
                    switch (action) {
                      case _ChoreAction.edit:
                        _openForm(chore);
                      case _ChoreAction.delete:
                        _delete(chore);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _ChoreAction.edit,
                      child: Row(
                        children: [
                          const Icon(Icons.edit),
                          const SizedBox(width: 12),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _ChoreAction.delete,
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
            ),
            // The big line: whose turn it is.
            Text(
              turnText,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: isMine ? AppColors.terracotta : AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            // The rotation in order. The one who is up is highlighted.
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final member in chore.rotation)
                  _rotationChip(
                    member.name,
                    current: member.userId == chore.currentUserId,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    last == null
                        ? l10n.choresNotDoneYet
                        : l10n.choresLastDone(
                            last.userName,
                            _whenText(l10n, last.doneAt),
                          ),
                    style: muted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    if (historyOpen) {
                      _historyOpen.remove(chore.id);
                    } else {
                      _historyOpen.add(chore.id);
                    }
                  }),
                  child: Text(l10n.choresHistory),
                ),
              ],
            ),
            if (historyOpen) _historyList(chore, l10n, muted),
            const SizedBox(height: 4),
            Row(
              children: [
                if (canRemind) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      // While waiting, the button only says "Hatırlatıldı"; the time is shown
                      // in full under the buttons, because it does not fit inside a half-width button.
                      icon: Icon(
                        remindWaitingUntil != null
                            ? Icons.check_rounded
                            : Icons.notifications_active_outlined,
                        size: 18,
                      ),
                      label: Text(
                        remindWaitingUntil != null
                            ? l10n.reminderSentShort
                            : l10n.choresRemind,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: (remindWaitingUntil != null || busy)
                          ? null
                          : () => _remind(chore),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(l10n.choresDone),
                    onPressed: busy ? null : () => _markDone(chore),
                  ),
                ),
              ],
            ),
            if (canRemind && remindWaitingUntil != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _remindedAgainLabel(l10n, remindWaitingUntil),
                  style: muted,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // One name in the rotation. The current person has a filled color.
  Widget _rotationChip(String name, {required bool current}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: current
            ? AppColors.terracotta
            : AppColors.mustard.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name,
        style: theme.textTheme.bodySmall?.copyWith(
          color: current ? Colors.white : AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // The last completions (at most 5), newest first. Shown when "History" is open.
  Widget _historyList(Chore chore, AppLocalizations l10n, TextStyle? muted) {
    if (chore.recentCompletions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(l10n.choresNoHistory, style: muted),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final done in chore.recentCompletions.take(5))
            Text(
              '${done.userName} · ${_whenText(l10n, done.doneAt)}',
              style: muted,
            ),
        ],
      ),
    );
  }
}
