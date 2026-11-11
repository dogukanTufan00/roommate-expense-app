import 'package:flutter/material.dart';
import 'package:roommate_expense_app/api/api_client.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/screens/households_screen.dart';
import 'package:roommate_expense_app/screens/login_screen.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/theme.dart';

// Lets code outside the widget tree (the API client) open screens.
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session.load();
  runApp(const RoommateApp());
}

class RoommateApp extends StatefulWidget {
  const RoommateApp({super.key});

  @override
  State<RoommateApp> createState() => _RoommateAppState();
}

class _RoommateAppState extends State<RoommateApp> {
  @override
  void initState() {
    super.initState();

    // When the token expires, the API client calls this. We go back to login
    // and remove all other screens, so the user cannot press "back" into them.
    ApiClient.onUnauthorized = () {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app when the user changes the language.
    return ValueListenableBuilder<Locale?>(
      valueListenable: Session.locale,
      builder: (context, value, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
          locale: value, // null = follow the phone's language
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: buildAppTheme(),
          home: Session.isLoggedIn ? const HouseholdsScreen() : const LoginScreen(),
        );
      },
    );
  }
}
