import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/api/api_client.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/push/push_service.dart';
import 'package:roommate_expense_app/screens/households_screen.dart';
import 'package:roommate_expense_app/screens/register_screen.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/widgets/illustration.dart';
import 'package:roommate_expense_app/widgets/language_menu_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await Api.login(_emailController.text.trim(), _passwordController.text);
      // Asks for the notification permission and registers this phone. Failures are logged only.
      PushService.registerAfterLogin();
      if (!mounted) return;

      // Replace the login screen so "back" does not return to it.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HouseholdsScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      // A 401 on login means a wrong email or password. errorMessage would
      // say "session expired", which is wrong here.
      final isWrongCredentials = e is ApiException && e.statusCode == 401;
      final message = isWrongCredentials
          ? l10n.errorWrongCredentials
          : errorMessage(context, e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(actions: const [LanguageMenuButton()]),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Illustration('login.png', fallbackIcon: Icons.home_work_rounded, height: 200),
                  const SizedBox(height: 16),
                  Text(
                    l10n.appTitle,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: AppColors.terracotta,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loginTagline,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(labelText: l10n.email),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return l10n.fieldRequired;
                            if (!_emailPattern.hasMatch(text)) return l10n.invalidEmail;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(labelText: l10n.password),
                          validator: (value) {
                            if (value == null || value.isEmpty) return l10n.fieldRequired;
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(l10n.login),
                          ),
                        ),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  ),
                          child: Text(l10n.noAccount),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// A simple check: something@something.something, with no spaces.
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
