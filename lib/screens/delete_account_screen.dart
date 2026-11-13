import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/api/api_client.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/push/push_service.dart';
import 'package:roommate_expense_app/screens/login_screen.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';

// Deletes the user's account. The screen first explains what happens: homes that block
// the deletion, open balances, the homes that go with the account, and what stays for the
// roommates. The delete button stays disabled until there are no blockers, the password is
// typed and the user has confirmed that this cannot be undone.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();

  DeletionCheck? _check;
  bool _loading = true;
  Object? _loadError;

  bool _obscurePassword = true;
  bool _confirmed = false;
  bool _deleting = false;
  // Shown under the password field, for example when the password is wrong.
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _loadCheck();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  // First load and retry. A failure replaces the screen with an error and a retry button.
  Future<void> _loadCheck() async {
    try {
      final check = await Api.getDeletionCheck();
      if (!mounted) return;
      setState(() {
        _check = check;
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    await _loadCheck();
  }

  // Reloads the check in place, keeping the password field as it is. Used after a 409.
  Future<void> _refreshCheck() async {
    try {
      final check = await Api.getDeletionCheck();
      if (!mounted) return;
      setState(() => _check = check);
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage(context, e))),
    );
  }

  Future<void> _deleteAccount() async {
    // Read before the first await: the screen is gone by the time the account is deleted.
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _deleting = true;
      _passwordError = null;
    });

    try {
      await Api.deleteAccount(_passwordController.text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      if (e is ApiException && e.statusCode == 400) {
        // The wrong password. Shown under the field so the user can fix it.
        setState(() => _passwordError = errorMessage(context, e));
        return;
      }
      _showError(e);
      // 409: a home still blocks the deletion. Reload, so the blocker cards are up to date.
      if (e is ApiException && e.statusCode == 409) {
        await _refreshCheck();
      }
      return;
    }

    // The account is gone, so the API rejects every call from now on (401).
    // Only local work is left: remove this phone's push token, then clear the session.
    // Session is cleared even if the screen was closed meanwhile, so the login stays consistent.
    await PushService.forgetDeviceLocally();
    await Session.clear();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.deleteAccountDone)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccountTitle)),
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

    final check = _check!;
    final blocked = check.blockers.isNotEmpty;
    final canDelete = !blocked &&
        !_deleting &&
        _confirmed &&
        _passwordController.text.isNotEmpty;

    // Balances of exactly 0 need no warning.
    final openBalances =
        check.openBalances.where((balance) => balance.net != 0).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (blocked) ...[
          Text(
            l10n.deleteAccountBlockedTitle,
            style: _headingStyle(context),
          ),
          const SizedBox(height: 8),
          for (final blocker in check.blockers) _buildBlockerCard(blocker, l10n),
          const SizedBox(height: 16),
        ],
        if (openBalances.isNotEmpty) ...[
          Text(l10n.openBalancesTitle, style: _headingStyle(context)),
          const SizedBox(height: 8),
          for (final balance in openBalances) _buildBalanceCard(balance, l10n),
          const SizedBox(height: 16),
        ],
        Text(l10n.deleteAccountWhatTitle, style: _headingStyle(context)),
        const SizedBox(height: 8),
        _Bullet(l10n.deleteAccountDeletesProfile),
        _Bullet(l10n.deleteAccountLeavesHomes),
        if (check.householdsToDelete.isNotEmpty) ...[
          _Bullet(l10n.deleteAccountHouseholdsIntro),
          for (final name in check.householdsToDelete)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6),
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text(l10n.deleteAccountKeepsTitle, style: _headingStyle(context)),
        const SizedBox(height: 8),
        _Bullet(l10n.deleteAccountKeepsShared),
        const SizedBox(height: 8),
        Text(
          l10n.deleteAccountIrreversible,
          style: const TextStyle(
            color: AppColors.owes,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _passwordError = null),
          decoration: InputDecoration(
            labelText: l10n.password,
            errorText: _passwordError,
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _confirmed,
          onChanged: _deleting
              ? null
              : (value) => setState(() => _confirmed = value ?? false),
          title: Text(l10n.deleteAccountConfirmCheckbox),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.owes),
            onPressed: canDelete ? _deleteAccount : null,
            child: _deleting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.deleteAccountButton),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  TextStyle? _headingStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);
  }

  // A home that stops the deletion. The text says what to do there.
  Widget _buildBlockerCard(DeletionBlocker blocker, AppLocalizations l10n) {
    // Any reason other than the founder one is the admin one, the only other reason the API sends.
    final message = blocker.reason == 'FOUNDER_WITH_MEMBERS'
        ? l10n.blockerFounderWithMembers(blocker.householdName)
        : l10n.blockerLastAdminWithMembers(blocker.householdName);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.owes.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.owes.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.owes),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.blockerHint,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The money still open in one home. Red when the user owes, green when the user is owed.
  Widget _buildBalanceCard(DeletionOpenBalance balance, AppLocalizations l10n) {
    final amount = formatMoney(context, balance.net.abs());
    final owes = balance.net < 0;
    final color = owes ? AppColors.owes : AppColors.getsBack;
    final message = owes
        ? l10n.balanceOwesWarning(balance.householdName, amount)
        : l10n.balanceGetsBackWarning(balance.householdName, amount);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              owes ? Icons.trending_down_rounded : Icons.trending_up_rounded,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// One line of explanation with a small dot in front of it.
class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7, right: 10, left: 4),
            child: CircleAvatar(radius: 3, backgroundColor: AppColors.muted),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
