import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/avatar.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';
import 'package:roommate_expense_app/utils/iban.dart';

// The actions an admin can take on another member, from the popup menu.
// "stepDown" is for the logged in user's own row. The others are for other members.
enum _MemberAction { toggleAdmin, remove, transferOwnership, stepDown }

// Shows the members of one home, plus the invitations that are still waiting for an answer.
// Admins can invite and remove members and cancel invitations. Others see the lists only.
// This is one tab inside the home screen, so it has its own Scaffold but no AppBar.
class MembersTab extends StatefulWidget {
  const MembersTab({super.key, required this.householdId});

  final int householdId;

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  List<Member> _members = [];
  List<Invitation> _invitations = [];

  // true only during the first load. Later reloads keep the list on screen.
  bool _loading = true;

  // Set when the first load fails. The screen then shows it with a retry button.
  String? _loadErrorText;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  // Loads members and pending invitations together.
  Future<void> _loadMembers() async {
    try {
      final results = await Future.wait<Object>([
        Api.getMembers(widget.householdId),
        Api.getHouseholdInvitations(widget.householdId),
      ]);
      if (!mounted) return;
      setState(() {
        _members = results[0] as List<Member>;
        _invitations = results[1] as List<Invitation>;
        _loading = false;
        _loadErrorText = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_loading) {
        setState(() {
          _loading = false;
          _loadErrorText = errorMessage(context, e);
        });
      } else {
        // A reload failed, so keep the list we already show.
        _showError(e);
      }
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _loadErrorText = null;
    });
    await _loadMembers();
  }

  // The logged in user's row. Null if the list has not loaded yet.
  Member? get _me {
    for (final member in _members) {
      if (member.email == Session.email) return member;
    }
    return null;
  }

  bool _isMe(Member member) => member.email == Session.email;

  // Whether a row gets the popup menu. Own row: only when I am an admin (step down).
  // Other rows: only for admins, and the founder's row only for the founder.
  bool _canOpenMenu(Member member) {
    if (_isMe(member)) return _iAmAdmin;
    if (!_iAmAdmin) return false;
    return !member.founder || _iAmFounder;
  }

  PopupMenuItem<_MemberAction> _menuItem(
    _MemberAction value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Flexible(
            child: Text(label, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  bool get _iAmAdmin => _me?.isAdmin ?? false;

  bool get _iAmFounder => _me?.founder ?? false;

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMessage(context, error))));
  }

  // Looks up this member's net balance so the confirm dialogs can warn about open debts.
  // Returns null if the balances cannot be loaded; the action still works, just without the warning.
  Future<double?> _netBalanceOf(Member member) async {
    try {
      final balances = await Api.getBalances(widget.householdId);
      for (final balance in balances) {
        if (balance.userId == member.userId) return balance.netBalance;
      }
      return 0;
    } catch (_) {
      return null;
    }
  }

  // The warning text for an open balance, or null when there is nothing to warn about.
  // Removing someone (or leaving) with a debt is allowed: people do move out before settling
  // up. The balance stays visible and can be settled later, so the dialog only names the amount.
  Future<String?> _openBalanceWarning(
    Member member, {
    required bool leaving,
  }) async {
    final l10n = AppLocalizations.of(context);
    final net = await _netBalanceOf(member);
    if (!mounted || net == null || net.abs() < 0.01) return null;

    final amount = formatMoney(context, net.abs());
    if (leaving) {
      return net < 0
          ? l10n.leaveHomeOwesWarning(amount)
          : l10n.leaveHomeGetsBackWarning(amount);
    }
    return net < 0
        ? l10n.removeMemberOwesWarning(member.name, amount)
        : l10n.removeMemberGetsBackWarning(member.name, amount);
  }

  // A yes/no dialog. The optional warning is shown in red above the question.
  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String actionLabel,
    String? warning,
    bool destructive = true,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (warning != null) ...[
              Text(
                warning,
                style: const TextStyle(
                  color: AppColors.owes,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: destructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(dialogContext).colorScheme.error,
                  )
                : null,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  // Admin only: removes another member.
  Future<void> _removeMember(Member member) async {
    final l10n = AppLocalizations.of(context);
    final warning = await _openBalanceWarning(member, leaving: false);
    if (!mounted) return;

    final confirmed = await _confirmAction(
      title: l10n.removeMember,
      message: l10n.removeMemberConfirm(member.name),
      warning: warning,
      actionLabel: l10n.removeMember,
    );
    if (!confirmed || !mounted) return;

    try {
      await Api.removeMember(widget.householdId, member.userId);
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    if (!mounted) return;
    await _loadMembers();
  }

  // Admin only: makes a member an admin, or takes the admin role away.
  Future<void> _changeRole(Member member) async {
    final l10n = AppLocalizations.of(context);
    final makeAdmin = !member.isAdmin;

    final confirmed = await _confirmAction(
      title: makeAdmin ? l10n.makeAdmin : l10n.removeAdmin,
      message: makeAdmin
          ? l10n.makeAdminConfirm(member.name)
          : l10n.removeAdminConfirm(member.name),
      actionLabel: makeAdmin ? l10n.makeAdmin : l10n.removeAdmin,
      destructive: false,
    );
    if (!confirmed || !mounted) return;

    try {
      await Api.changeRole(
        widget.householdId,
        member.userId,
        makeAdmin ? 'ADMIN' : 'MEMBER',
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.roleChanged)));
    await _loadMembers();
  }

  // Any member: leaves the home. The API refuses if this is the last admin.
  Future<void> _leaveHousehold() async {
    final l10n = AppLocalizations.of(context);
    final me = _me;
    if (me == null) return;

    final warning = await _openBalanceWarning(me, leaving: true);
    if (!mounted) return;

    final confirmed = await _confirmAction(
      title: l10n.leaveHome,
      message: l10n.leaveHomeConfirm,
      warning: warning,
      actionLabel: l10n.leaveHome,
    );
    if (!confirmed || !mounted) return;

    try {
      await Api.leaveHousehold(widget.householdId, me.userId);
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    if (!mounted) return;
    // We are no longer a member, so go back to the homes list, which reloads itself.
    Navigator.of(context).pop();
  }

  // Any admin: takes their own admin role away. The API refuses if this is the last admin.
  Future<void> _stepDown() async {
    final l10n = AppLocalizations.of(context);
    final me = _me;
    if (me == null) return;

    final confirmed = await _confirmAction(
      title: l10n.stepDownAdmin,
      message: l10n.stepDownAdminConfirm,
      actionLabel: l10n.stepDownAdmin,
      destructive: false,
    );
    if (!confirmed || !mounted) return;

    try {
      await Api.changeRole(widget.householdId, me.userId, 'MEMBER');
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.roleChanged)));
    await _loadMembers();
  }

  // Founder only: gives the founder role to another active member.
  Future<void> _transferOwnership(Member member) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await _confirmAction(
      title: l10n.transferOwnership,
      message: member.isAdmin
          ? l10n.transferOwnershipAdminConfirm(member.name)
          : l10n.transferOwnershipConfirm(member.name),
      actionLabel: l10n.transferOwnership,
      destructive: false,
    );
    if (!confirmed || !mounted) return;

    try {
      await Api.transferOwnership(widget.householdId, member.userId);
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.ownershipTransferred)));
    await _loadMembers();
  }

  void _onMemberAction(Member member, _MemberAction action) {
    switch (action) {
      case _MemberAction.toggleAdmin:
        _changeRole(member);
      case _MemberAction.remove:
        _removeMember(member);
      case _MemberAction.transferOwnership:
        _transferOwnership(member);
      case _MemberAction.stepDown:
        _stepDown();
    }
  }

  Future<void> _showInviteDialog() async {
    final l10n = AppLocalizations.of(context);
    // The dialog only collects the email. This screen calls the API,
    // so the dialog can close before the request finishes.
    final email = await showDialog<String>(
      context: context,
      builder: (_) => const _InviteDialog(),
    );
    if (email == null || !mounted) return;

    try {
      await Api.inviteMember(widget.householdId, email);
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.inviteSent)));
    await _loadMembers();
  }

  Future<void> _cancelInvitation(Invitation invitation) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cancelInvitation),
        content: Text(l10n.cancelInvitationConfirm(invitation.invitedUserName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.cancelInvitation),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await Api.cancelInvitation(widget.householdId, invitation.id);
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.invitationCancelled)));
    await _loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: _buildBody(l10n),
      // Only admins can invite members.
      floatingActionButton: _iAmAdmin
          ? FloatingActionButton.extended(
              onPressed: _showInviteDialog,
              icon: const Icon(Icons.person_add),
              label: Text(l10n.inviteMember),
            )
          : null,
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final loadErrorText = _loadErrorText;
    if (loadErrorText != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loadErrorText, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _retry, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView(
        // Extra bottom space so the last card is not hidden behind the FAB.
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          for (final member in _sortedMembers) _buildMemberCard(member, l10n),
          if (_invitations.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text(
                l10n.pendingInvitesTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (final invitation in _invitations)
              _buildInvitationCard(invitation, l10n),
          ],
          if (_me != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: TextButton.icon(
                  onPressed: _leaveHousehold,
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: Text(l10n.leaveHome),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Founder first, then admins, then everyone else; inside each group, whoever joined first
  // comes first. The API returns members in database order, which has no meaning to people.
  List<Member> get _sortedMembers {
    int rank(Member m) => m.founder ? 0 : (m.isAdmin ? 1 : 2);
    return [..._members]..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.joinedAt.compareTo(b.joinedAt);
    });
  }

  Widget _buildMemberCard(Member member, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isMe = _isMe(member);
    final name = isMe ? '${member.name} (${l10n.you})' : member.name;
    final iban = member.iban;

    // A custom layout instead of ListTile: ListTile squeezes everything between leading and
    // trailing, so badges wrapped badly and the IBAN got cut off. Here the name and small badges
    // share the first line, the email is the second, and the IBAN gets the full card width.
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: avatarColor(member.userId),
                  child: Text(
                    initials(member.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(name, style: theme.textTheme.titleMedium),
                          if (member.founder)
                            _RoleBadge(
                              icon: Icons.workspace_premium_rounded,
                              label: l10n.founder,
                              color: const Color(0xFF8A6A1F),
                              background: AppColors.mustard.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          if (member.isAdmin)
                            _RoleBadge(
                              icon: Icons.star_rounded,
                              label: l10n.admin,
                              color: AppColors.terracotta,
                              background: AppColors.terracotta.withValues(
                                alpha: 0.12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildMemberMenu(member, l10n, isMe, theme),
              ],
            ),
            if (iban != null)
              Padding(
                // Lines the IBAN up under the name (avatar 40 + gap 14).
                padding: const EdgeInsets.only(left: 54, top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        // Scales down a little on narrow phones instead of cutting the IBAN off.
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatIban(iban),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.copyIban,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      onPressed: () => copyIban(context, iban),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // The "..." menu on a member row, or an empty box of the same width when there is no menu,
  // so the rows stay aligned.
  Widget _buildMemberMenu(
    Member member,
    AppLocalizations l10n,
    bool isMe,
    ThemeData theme,
  ) {
    return SizedBox(
      width: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Admins can change roles and remove other members. Only the founder can touch the
          // founder's row, so other admins get no menu there. Any admin can step down from their
          // own row. Leaving is at the bottom of the list. The backend refuses the last admin's
          // change, and the error is shown as a SnackBar.
          if (_canOpenMenu(member))
            PopupMenuButton<_MemberAction>(
              tooltip: l10n.memberOptions,
              onSelected: (action) => _onMemberAction(member, action),
              itemBuilder: (_) => isMe
                  ? [
                      _menuItem(
                        _MemberAction.stepDown,
                        Icons.remove_moderator_outlined,
                        l10n.stepDownAdmin,
                        theme.colorScheme.onSurface,
                      ),
                    ]
                  : [
                      _menuItem(
                        _MemberAction.toggleAdmin,
                        member.isAdmin
                            ? Icons.remove_moderator_outlined
                            : Icons.admin_panel_settings_outlined,
                        member.isAdmin ? l10n.removeAdmin : l10n.makeAdmin,
                        theme.colorScheme.onSurface,
                      ),
                      _menuItem(
                        _MemberAction.remove,
                        Icons.person_remove_outlined,
                        l10n.removeMember,
                        theme.colorScheme.error,
                      ),
                      if (_iAmFounder)
                        _menuItem(
                          _MemberAction.transferOwnership,
                          Icons.workspace_premium_outlined,
                          l10n.transferOwnership,
                          theme.colorScheme.onSurface,
                        ),
                    ],
            ),
        ],
      ),
    );
  }

  // An invitation that is still waiting for the invitee to answer.
  Widget _buildInvitationCard(Invitation invitation, AppLocalizations l10n) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor(invitation.invitedUserId),
          child: Text(
            initials(invitation.invitedUserName),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(invitation.invitedUserName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(invitation.invitedUserEmail),
            const SizedBox(height: 4),
            Chip(
              label: Text(l10n.awaitingResponse),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        // Only admins can cancel. Everyone else sees the list read-only.
        trailing: _iAmAdmin
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.cancelInvitation,
                onPressed: () => _cancelInvitation(invitation),
              )
            : null,
      ),
    );
  }
}

// Collects the email of the person to invite. It returns the trimmed email, or null if cancelled.
class _InviteDialog extends StatefulWidget {
  const _InviteDialog();

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  // Simple check. The API does the real validation.
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    // The controller lives in this State, so it is disposed only after the dialog is gone.
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.inviteMember),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.inviteMemberHint, style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.inviteMemberEmailHint),
              onFieldSubmitted: (_) => _submit(),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return l10n.fieldRequired;
                if (!_emailPattern.hasMatch(text)) return l10n.invalidEmail;
                return null;
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.inviteMember)),
      ],
    );
  }
}

// A small round role icon next to a member's name. Only the icon is shown, so the name line
// never wraps; tapping it shows the role ("Founder", "Admin") for 3 seconds. Screen readers get
// the label too, through the Tooltip's semantics.
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 3),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}
