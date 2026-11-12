import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/avatar.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';

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

  bool get _iAmAdmin => _me?.isAdmin ?? false;

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage(context, error))),
    );
  }

  // Looks up this member's net balance so the remove dialog can warn about open debts.
  // Returns null if the balances cannot be loaded; removing still works then, just without the warning.
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

  Future<void> _removeMember(Member member) async {
    final l10n = AppLocalizations.of(context);

    // Removing someone who still owes (or is owed) money is allowed: people do move out before
    // settling up. Their balance stays visible and can still be settled later. But the admin
    // should make that choice knowingly, so the dialog names the open amount.
    final net = await _netBalanceOf(member);
    if (!mounted) return;
    String? warning;
    if (net != null && net.abs() >= 0.01) {
      final amount = formatMoney(context, net.abs());
      warning = net < 0
          ? l10n.removeMemberOwesWarning(member.name, amount)
          : l10n.removeMemberGetsBackWarning(member.name, amount);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.removeMember),
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
            Text(l10n.removeMemberConfirm(member.name)),
          ],
        ),
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
            child: Text(l10n.removeMember),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Read this before the await. After removing ourselves we leave the home.
    final removingMe = _isMe(member);
    try {
      await Api.removeMember(widget.householdId, member.userId);
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    if (!mounted) return;

    if (removingMe) {
      // We are no longer a member, so go back to the households list.
      Navigator.of(context).pop();
      return;
    }
    await _loadMembers();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.inviteSent)),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.invitationCancelled)),
    );
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
          for (final member in _members) _buildMemberCard(member, l10n),
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
        ],
      ),
    );
  }

  Widget _buildMemberCard(Member member, AppLocalizations l10n) {
    final name = _isMe(member) ? '${member.name} (${l10n.you})' : member.name;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor(member.userId),
          child: Text(
            initials(member.name),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(name),
        subtitle: Text(member.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (member.isAdmin)
              Chip(
                avatar: const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Color(0xFFB7862A),
                ),
                label: Text(l10n.admin),
                visualDensity: VisualDensity.compact,
              ),
            // The backend refuses to remove the last admin. The error is shown as a SnackBar.
            if (_iAmAdmin)
              IconButton(
                icon: const Icon(Icons.person_remove_outlined),
                tooltip: l10n.removeMember,
                onPressed: () => _removeMember(member),
              ),
          ],
        ),
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
          Text(
            l10n.inviteMemberHint,
            style: TextStyle(color: AppColors.muted),
          ),
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
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.inviteMember),
        ),
      ],
    );
  }
}
