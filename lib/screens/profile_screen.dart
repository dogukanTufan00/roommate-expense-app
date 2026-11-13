import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/push/push_service.dart';
import 'package:roommate_expense_app/screens/delete_account_screen.dart';
import 'package:roommate_expense_app/screens/login_screen.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/iban.dart';
import 'package:roommate_expense_app/widgets/language_menu_button.dart';

// The user's own profile: name, IBAN (roommates use it to pay them) and password.
// The email is shown but cannot be changed here.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ibanController = TextEditingController();

  UserProfile? _profile;
  bool _loading = true;
  Object? _loadError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  // First load and retry. A failure replaces the screen with an error and a retry button.
  Future<void> _load() async {
    try {
      final profile = await Api.getProfile();
      if (!mounted) return;
      _fillFields(profile);
      setState(() {
        _profile = profile;
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
    await _load();
  }

  // Puts the saved values into the fields. The IBAN is shown in groups of 4.
  void _fillFields(UserProfile profile) {
    _nameController.text = profile.name;
    final iban = profile.iban;
    _ibanController.text = iban == null ? '' : formatIban(iban);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      // An empty IBAN removes the saved one.
      final updated = await Api.updateProfile(
        _nameController.text.trim(),
        normalizeIban(_ibanController.text),
      );
      if (!mounted) return;
      _fillFields(updated);
      setState(() {
        _profile = updated;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage(context, e))),
      );
    }
  }

  Future<void> _openChangePassword() async {
    final l10n = AppLocalizations.of(context);
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (changed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.passwordChanged)),
    );
  }

  // Same as the logout button on the homes screen.
  Future<void> _logout() async {
    await PushService.unregisterOnLogout();
    await Session.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // The delete screen does its own logout when the account is gone, so nothing is done here afterwards.
  Future<void> _openDeleteAccount() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: const [LanguageMenuButton()],
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

    final profile = _profile!;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            initialValue: profile.email,
            enabled: false,
            decoration: InputDecoration(labelText: l10n.email),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.name),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return l10n.fieldRequired;
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ibanController,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            inputFormatters: [_IbanInputFormatter()],
            decoration: InputDecoration(
              labelText: l10n.iban,
              hintText: l10n.ibanPlaceholder,
              helperText: l10n.ibanHelper,
              helperMaxLines: 2,
            ),
            // A quick local check only. The API does the real checksum test.
            validator: (value) {
              final compact = normalizeIban(value ?? '');
              if (compact.isEmpty) return null;
              if (!compact.startsWith('TR') || compact.length != 26) {
                return l10n.ibanFormatHint;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.securityTitle,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.lock_outline, color: AppColors.terracotta),
              title: Text(l10n.changePassword),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              onTap: _openChangePassword,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
            ),
          ),
          // A quiet danger zone at the very bottom, away from the everyday actions.
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: _openDeleteAccount,
              style: TextButton.styleFrom(foregroundColor: AppColors.owes),
              child: Text(l10n.deleteAccount),
            ),
          ),
        ],
      ),
    );
  }
}

// Uppercases the IBAN as the user types and drops anything that is not a letter, digit or space.
class _IbanInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9 ]'), '');
    final cursor = newValue.selection.baseOffset;
    final offset = cursor < 0 ? cleaned.length : (cursor > cleaned.length ? cleaned.length : cursor);
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

// Asks for the current password and the new one twice. Returns true when the password changed.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _repeatController = TextEditingController();

  bool _saving = false;
  // The message when the change fails, for example a wrong current password.
  String? _serverError;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _serverError = null;
    });
    try {
      await Api.changePassword(_currentController.text, _newController.text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = errorMessage(context, e);
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    return AlertDialog(
      title: Text(l10n.changePassword),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _currentController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.currentPassword),
              validator: (value) {
                if (value == null || value.isEmpty) return l10n.fieldRequired;
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.newPassword),
              validator: (value) {
                if (value == null || value.isEmpty) return l10n.fieldRequired;
                if (value.length < 8) return l10n.passwordTooShort;
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _repeatController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(labelText: l10n.repeatNewPassword),
              validator: (value) {
                if (value != _newController.text) return l10n.passwordMismatch;
                return null;
              },
            ),
            if (_serverError != null) ...[
              const SizedBox(height: 12),
              Text(
                _serverError!,
                style: TextStyle(color: errorColor, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
