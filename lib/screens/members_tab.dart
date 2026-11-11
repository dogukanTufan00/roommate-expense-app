import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/utils/errors.dart';

// Shows the members of one home. Admins can add and remove members.
// This is one tab inside the home screen, so it has its own Scaffold but no AppBar.
class MembersTab extends StatefulWidget {
  const MembersTab({super.key, required this.householdId});

  final int householdId;

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  List<Member> _members = [];

  // true only during the first load. Later reloads keep the list on screen.
  bool _loading = true;

  // Set when the first load fails. The screen then shows it with a retry button.
  String? _loadErrorText;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await Api.getMembers(widget.householdId);
      if (!mounted) return;
      setState(() {
        _members = members;
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

  Future<void> _removeMember(Member member) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.removeMember),
        content: Text(l10n.removeMemberConfirm(member.name)),
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

  Future<void> _showAddMemberDialog() async {
    // The dialog only collects the email. This screen calls the API,
    // so the dialog can close before the request finishes.
    final email = await showDialog<String>(
      context: context,
      builder: (_) => const _AddMemberDialog(),
    );
    if (email == null || !mounted) return;

    try {
      await Api.addMember(widget.householdId, email);
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      return;
    }
    if (!mounted) return;
    await _loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: _buildBody(l10n),
      // Only admins can add members.
      floatingActionButton: _iAmAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddMemberDialog,
              icon: const Icon(Icons.person_add),
              label: Text(l10n.addMember),
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

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.builder(
        // Extra bottom space so the last card is not hidden behind the FAB.
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: _members.length,
        itemBuilder: (context, index) =>
            _buildMemberCard(_members[index], l10n),
      ),
    );
  }

  Widget _buildMemberCard(Member member, AppLocalizations l10n) {
    final name = _isMe(member) ? '${member.name} (${l10n.you})' : member.name;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(member.name.isEmpty ? '?' : member.name[0].toUpperCase()),
        ),
        title: Text(name),
        subtitle: Text(member.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (member.isAdmin)
              Chip(
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
}

// Collects the email of the person to add. It returns the trimmed email, or null if cancelled.
class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
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
      title: Text(l10n.addMember),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.memberEmailHint),
          onFieldSubmitted: (_) => _submit(),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return l10n.fieldRequired;
            if (!_emailPattern.hasMatch(text)) return l10n.invalidEmail;
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.add),
        ),
      ],
    );
  }
}
