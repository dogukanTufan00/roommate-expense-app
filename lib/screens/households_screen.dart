import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/screens/household_screen.dart';
import 'package:roommate_expense_app/screens/login_screen.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/widgets/language_menu_button.dart';

// The home page after login: the list of homes the user belongs to.
class HouseholdsScreen extends StatefulWidget {
  const HouseholdsScreen({super.key});

  @override
  State<HouseholdsScreen> createState() => _HouseholdsScreenState();
}

class _HouseholdsScreenState extends State<HouseholdsScreen> {
  List<Household> _households = [];
  bool _loading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Loads the list. Errors are shown here, so callers can just await it.
  Future<void> _load() async {
    try {
      final households = await Api.getHouseholds();
      if (!mounted) return;
      setState(() {
        _households = households;
        _loadError = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_households.isEmpty) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.households),
        actions: [
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
    if (_households.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Icon(
              Icons.home_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                l10n.noHouseholds,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        // Bottom padding leaves room so the floating button does not hide the last card.
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: _households.length,
        itemBuilder: (context, index) {
          final household = _households[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.home),
              title: Text(household.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openHousehold(household),
            ),
          );
        },
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
