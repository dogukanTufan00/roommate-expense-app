**English** | [Türkçe](README.tr.md)

# Evce — Mobile App

A Flutter Android client for the Shared Expense Tracking System REST API, which lets roommates record shared household costs and see who owes whom.
The backend lives in [dogukanTufan00/shared-expense-tracking-system](https://github.com/dogukanTufan00/shared-expense-tracking-system) and must be running for the app to work.

## Features

- **Log in and sign up.** You stay logged in after closing the app. The API token is valid for 24 hours, after which you log in again.
- **Homes.** Create, rename and delete a home.
- **Members.** A home admin adds a roommate by email (the roommate needs an account) and removes members. The app marks your own entry with "you" and admins with an "Admin" badge.
- **Expenses.** Add, edit and delete expenses with a category (Rent, Bills, Groceries, Other), a payer, a date and a "repeats every month" flag. Amounts accept both `12,50` and `12.50`.
- **Balances.** See each member's net balance: what the home owes them, or what they owe.
- **Who pays whom.** A short list of suggested payments that settles everyone, with a one-tap "Mark as paid" button.
- **Payment history.** See every recorded payment and delete a mistaken one.
- **Turkish and English.** The UI follows the phone's language by default. You can switch the language inside the app.
- **Clear errors.** API errors are shown as localized messages, for example "This home is full (max 3 members)."

## Tech Stack

| Concern | Technology |
|---|---|
| Framework / language | Flutter / Dart |
| UI | Material 3 with a custom warm theme (`lib/theme.dart`): terracotta, sage, mustard and cream palette, Nunito font, illustrations made with Gemini |
| HTTP | `http` |
| Local storage | `shared_preferences` (token and language) |
| Localization | `intl` + `flutter_localizations`, generated with gen-l10n from ARB files |
| State management | `setState` only. No state-management library, on purpose, to keep the code simple. |

## Project Structure

```
lib/
├── api/
│   ├── api.dart           # One static method per API call (households, members, expenses, payments…)
│   └── api_client.dart    # Low-level HTTP helper: base URL, JSON, token header, error handling
├── l10n/                  # ARB translation files (app_en.arb, app_tr.arb) and generated localization classes
├── screens/               # Login, sign up, homes list, home details (tabs), expense form
├── utils/
│   ├── category.dart      # Category codes, labels and icons
│   ├── errors.dart        # Maps API errors to localized messages
│   └── format.dart        # Money and date formatting for the current language
├── widgets/
│   └── language_menu_button.dart  # Language switch in the app bar
├── config.dart            # API base URL (can be set with --dart-define)
├── models.dart            # Data classes with fromJson factories
├── session.dart           # Saved token, logged in user's email and language choice
└── main.dart              # App start, theme and routing between login and homes
```

## Running the App

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (the Dart SDK version in `pubspec.yaml` is required)
- Android SDK (Android Studio is the easiest way to install it), with an emulator or a phone that has USB debugging enabled
- The backend API running on `http://localhost:8080`. See the [backend README](https://github.com/dogukanTufan00/shared-expense-tracking-system#readme) for setup steps.

Install the packages first:

```bash
flutter pub get
```

### Option 1: Android emulator

The app uses `http://10.0.2.2:8080` by default. `10.0.2.2` is the address the Android emulator uses to reach the host computer, so the emulator can call the API running on your computer.

```bash
flutter run
```

### Option 2: Physical phone over USB

Connect the phone with a USB cable and enable USB debugging. Then run:

```bash
adb reverse tcp:8080 tcp:8080
flutter run --release --dart-define=API_BASE_URL=http://localhost:8080
```

`adb reverse` forwards the phone's `localhost:8080` to your computer, so no Wi-Fi, IP address or firewall setup is needed. Run the `adb reverse` command again after you reconnect the cable.

## Push Notifications

Push notifications use Firebase Cloud Messaging (`firebase_core`, `firebase_messaging`, `flutter_local_notifications`). The Android build applies the Google services plugin, so **the app does not build without a Firebase config file**, even if you do not use push. Setup, once per developer:

1. Create a project in the [Firebase console](https://console.firebase.google.com).
2. Add an Android app with the package name `com.dogukan_tufan.roommate_expense_app`.
3. Download `google-services.json` and put it in `android/app/`.

`android/app/google-services.json` is in `.gitignore`, because it is specific to each Firebase project. Every developer downloads their own copy and never commits it.

## Roadmap

- Attach a receipt, bill or bank-transfer photo to an expense
- User profile with IBAN for faster repayments
- Deploy the API so the app works without a cable
- Automated widget tests
- Google Play release
