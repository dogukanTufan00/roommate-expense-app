import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/screens/household_screen.dart';
import 'package:roommate_expense_app/screens/login_screen.dart';
import 'package:roommate_expense_app/screens/profile_screen.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/widgets/illustration.dart';
import 'package:roommate_expense_app/widgets/language_menu_button.dart';

// The home page after login: the invitations waiting for me, then the list of homes I belong to.
class HouseholdsScreen extends StatefulWidget {
  const HouseholdsScreen({super.key});

  @override
  State<HouseholdsScreen> createState() => _HouseholdsScreenState();
}

class _HouseholdsScreenState extends State<HouseholdsScreen> {
  List<Household> _households = [];
  List<Invitation> _invitations = [];

  // Invitations with a request in progress. Their buttons are disabled meanwhile.
  final Set<int> _busyInvitationIds = {};

  bool _loading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Loads homes and my invitations together. Errors are shown here, so callers can just await it.
  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>([
        Api.getHouseholds(),
        Api.getMyInvitations(),
      ]);
      if (!mounted) return;
      setState(() {
        _households = results[0] as List<Household>;
        _invitations = results[1] as List<Invitation>;
        _loadError = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_households.isEmpty && _invitations.isEmpty) {
        // First load failed: show the error with a retry button.
        setState(() {
          _loadError = e;
          _loading = false;
        });
      } else {
        // Refresh failed but we still have data: keep the list, show a message.
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

  Future<void> _logout() async {
    await Session.clear();
    if (!mounted) return;
    // Remove every screen from the stack so "back" cannot return to the homes.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // The profile has its own data, so nothing needs reloading when it closes.
  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  Future<void> _openHousehold(Household household) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HouseholdScreen(household: household)),
    );
    if (!mounted) return;
    // The home may have been renamed or deleted while we were inside it.
    await _load();
  }

  Future<void> _createHousehold() async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(title: l10n.createHousehold),
    );
    if (!mounted) return;
    final name = result?.trim();
    if (name == null || name.isEmpty) return;

    try {
      await Api.createHousehold(name);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  // Runs accept or decline. Then it shows the message and reloads, so the invitation
  // disappears (and the new home appears after accepting). On failure the reload also
  // helps: the invitation may be gone already.
  Future<void> _respondToInvitation({
    required Invitation invitation,
    required Future<void> Function() request,
    required String successMessage,
  }) async {
    setState(() => _busyInvitationIds.add(invitation.id));

    var succeeded = false;
    try {
      await request();
      succeeded = true;
    } catch (e) {
      if (mounted) _showError(e);
    }
    if (!mounted) return;

    setState(() => _busyInvitationIds.remove(invitation.id));
    if (succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    }
    await _load();
  }

  Future<void> _acceptInvitation(Invitation invitation) async {
    final l10n = AppLocalizations.of(context);
    await _respondToInvitation(
      invitation: invitation,
      request: () => Api.acceptInvitation(invitation.id),
      successMessage: l10n.welcomeToHousehold(invitation.householdName),
    );
  }

  Future<void> _declineInvitation(Invitation invitation) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.declineInvitation),
        content: Text(l10n.declineInvitationConfirm(invitation.householdName)),
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
            child: Text(l10n.declineInvitation),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _respondToInvitation(
      invitation: invitation,
      request: () => Api.declineInvitation(invitation.id),
      successMessage: l10n.invitationDeclined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.households),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: l10n.profile,
            onPressed: _openProfile,
          ),
          const LanguageMenuButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(l10n),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createHousehold,
        icon: const Icon(Icons.add),
        label: Text(l10n.createHousehold),
      ),
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
        // Bottom padding leaves room so the floating button does not hide the last card.
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        children: [
          if (_invitations.isNotEmpty) ..._buildInvitationSection(l10n),
          // With invitations waiting, the invitations already explain what to do, so skip the empty state.
          if (_households.isEmpty && _invitations.isEmpty) _buildEmptyState(l10n),
          for (final household in _households) _buildHouseholdCard(household),
        ],
      ),
    );
  }

  List<Widget> _buildInvitationSection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          l10n.incomingInvitesTitle,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      for (final invitation in _invitations) _buildInvitationCard(invitation, l10n),
    ];
  }

  // A warm, mustard-tinted card with the accept and decline buttons.
  Widget _buildInvitationCard(Invitation invitation, AppLocalizations l10n) {
    final busy = _busyInvitationIds.contains(invitation.id);

    return Card(
      color: AppColors.mustard.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.mustard.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.mail_rounded, color: AppColors.terracotta),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.invitedYou(invitation.invitedByName),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        invitation.householdName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: busy ? null : () => _declineInvitation(invitation),
                  child: Text(l10n.declineInvitation),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: busy ? null : () => _acceptInvitation(invitation),
                  child: Text(l10n.acceptInvitation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Illustration(
            'empty-homes.png',
            fallbackIcon: Icons.house_rounded,
            height: 180,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noHouseholdsTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noHouseholds,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdCard(Household household) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.terracotta.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.house_rounded, color: AppColors.terracotta),
        ),
        title: Text(
          household.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        onTap: () => _openHousehold(household),
      ),
    );
  }
}

// A dialog with one text field. It returns the typed text, or null if cancelled.
// The caller trims the text and ignores empty names.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title});

  final String title;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  // The controller lives in the State so it is disposed only after the dialog closes.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.householdName),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
