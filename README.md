**English** | [Türkçe](README.tr.md)

# Evce — Mobile App

A Flutter Android client for the Shared Expense Tracking System REST API. Evce helps roommates record shared household expenses, see who owes whom, record payments, and export a monthly statement as PDF.
The backend lives in [dogukanTufan00/shared-expense-tracking-system](https://github.com/dogukanTufan00/shared-expense-tracking-system) and must be running for the app to work.

## Features

- **Warm, bilingual UI.** Turkish and English. The app follows the phone's language by default, and you can switch languages inside the app. The choice is saved.
- **Login and sign up.** You stay logged in after closing the app. The saved token's expiry is checked at start-up, and an expired session asks you to log in again.
- **Homes and invitations.** A list of your homes, with invitation cards you can accept or decline. A notification bell in the top bar shows an unread badge.
- **Household screen with four tabs:**
  - **Expenses:** expenses grouped by month, with filters. Badges mark expenses with a receipt (paperclip), recurring expenses, and automatically generated ones.
  - **Balances:** your own status, and who pays whom. Copy the recipient's IBAN with one tap, and record a payment with a suggested amount (the app warns you about overpayment). A payment details sheet shows the receipts.
  - **Statement:** pick a month or a custom date range to see per-person bars, the dominant payer insight, a category breakdown, and a 6-month chart. The statement can be exported as PDF and shared.
  - **Members:** founder and admin icons (with tooltips), invite members by email, change roles, transfer ownership, remove members (with a warning if they still have open debts), and leave the home.
- **Expense form.** Choose the members involved and a split: Equal, Percent or Amount. Default split ratios can be saved and reused. Expenses can be set to recur, and receipts can be attached from the camera, the gallery, or as PDF files.
- **Recurring expenses.** A screen to review and manage recurring expenses.
- **Default ratios.** A screen to set the default split ratios for each home.
- **Profile.** Change your name, set your IBAN (validated), and change your password.
- **Notifications.** A full notifications screen with invitations, new expenses, recorded payments and recurring expenses.
- **Push notifications.** Firebase Cloud Messaging works while the app is open, in the background, and after the app was closed. Tapping a notification opens its home.

## Tech Stack

| Concern | Technology |
|---|---|
| Framework / language | Flutter / Dart (Dart SDK `^3.13.5`, see `pubspec.yaml`) |
| UI | Material 3 with a custom warm theme (`lib/theme.dart`): terracotta, sage, mustard and cream palette, Nunito font, illustrations made with Gemini |
| State management | `setState`, with a few shared `ValueNotifier`s (for example the language). No state-management library, on purpose: the app is small, and plain `setState` is easier to read and maintain. |
| Backend | REST API (Spring Boot), see the [backend repository](https://github.com/dogukanTufan00/shared-expense-tracking-system) |

### Packages

| Package | Version | Purpose |
|---|---|---|
| `http` | ^1.6.0 | Calls to the REST API |
| `shared_preferences` | ^2.5.6 | Keeps the login token and the language choice on the device |
| `intl` | any | Money and date formatting for the current language |
| `flutter_localizations` | SDK | Flutter's own translations (dialogs, pickers, and so on) |
| `image_picker` | ^1.2.4 | Takes receipt photos with the camera or picks them from the gallery |
| `file_picker` | ^13.3.3 | Picks PDF receipts from the file system |
| `open_filex` | ^5.0.0 | Opens a downloaded receipt or statement with an app on the phone |
| `path_provider` | ^2.1.6 | Finds the folders where files are saved before they are opened or shared |
| `pdf` | ^3.13.1 | Builds the monthly statement PDF on the device |
| `printing` | ^5.15.1 | Shares or prints the generated PDF |
| `firebase_core` | ^5.1.0 | Starts Firebase in the app |
| `firebase_messaging` | ^17.0.1 | Receives push notifications and gives the device's FCM token |
| `flutter_local_notifications` | ^23.0.1 | Shows push notifications while the app is open, and handles taps on them |
| `flutter_launcher_icons` (dev) | ^0.14.4 | Generates the Android app icon in every size |
| `flutter_native_splash` (dev) | ^2.4.8 | Generates the cream launch screen with the app icon |

## Project Structure

```
lib/
├── api/
│   ├── api.dart           # One static method per API call (homes, members, expenses, payments, notifications…)
│   └── api_client.dart    # Low-level HTTP helper: base URL, JSON, token header, error handling
├── l10n/                  # ARB translation files (app_en.arb, app_tr.arb) and generated localization classes
├── push/
│   └── push_service.dart  # Firebase setup, push display, tap navigation, device token registration
├── screens/
│   ├── login_screen.dart, register_screen.dart
│   ├── households_screen.dart        # Home list, invitation cards, notification bell
│   ├── household_screen.dart         # Home details with the four tabs
│   ├── expenses_tab.dart, balances_tab.dart, statement_tab.dart, members_tab.dart
│   ├── expense_form_screen.dart      # Add or edit an expense
│   ├── recurring_expenses_screen.dart
│   ├── split_defaults_screen.dart    # Default split ratios
│   ├── profile_screen.dart           # Name, IBAN, password
│   └── notifications_screen.dart
├── utils/
│   ├── avatar.dart, category.dart    # Member avatars, category codes, labels and icons
│   ├── split.dart, iban.dart         # Split calculations, IBAN validation
│   ├── errors.dart                   # Maps API errors to localized messages
│   ├── format.dart                   # Money and date formatting for the current language
│   ├── notification_text.dart        # Builds notification sentences from server data
│   └── statement_pdf.dart            # Statement PDF with the embedded Nunito font
├── widgets/
│   ├── language_menu_button.dart     # Language switch in the app bar
│   ├── attachments_section.dart      # Receipt list and viewer
│   └── illustration.dart             # Illustrations used on the warm screens
├── config.dart            # API base URL (can be set with --dart-define)
├── models.dart            # Data classes with fromJson factories
├── session.dart           # Saved token, logged in user's email, language choice, JWT expiry check
├── theme.dart             # Colors, typography and component themes
└── main.dart              # App start, theme and routing between login and homes
```

## Running the App

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (the Dart SDK version in `pubspec.yaml` is required)
- Android SDK (Android Studio is the easiest way to install it), with an emulator or a phone that has USB debugging enabled
- The backend API running on `http://localhost:8080`. See the [backend README](https://github.com/dogukanTufan00/shared-expense-tracking-system#readme) for setup steps. **Start the backend first.**
- A Firebase config file (see [Push Notifications](#push-notifications)). The Android build fails without it.

> **Note (Android build):** the project path must contain only ASCII characters. A path with non-ASCII characters (for example a folder named with Turkish letters such as `ı`, `ş` or `ğ`) can break the Android build. Keep the project in a path like `C:\dev\roommate-expense-app`.

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
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

`adb reverse` forwards the phone's `localhost:8080` to your computer, so no Wi-Fi, IP address or firewall setup is needed. Run the `adb reverse` command again after you reconnect the cable.

### Release build

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example.com
```

The release build is currently signed with the debug key, and the manifest allows cleartext HTTP for local development. Before a public release, use HTTPS, remove `usesCleartextTraffic`, and add a release signing config.

## Push Notifications

Push notifications use Firebase Cloud Messaging (`firebase_core`, `firebase_messaging`, `flutter_local_notifications`). The Android build applies the Google services plugin, so **the app does not build without a Firebase config file**, even if you do not use push. Setup, once per developer:

1. Create a project in the [Firebase console](https://console.firebase.google.com).
2. Add an Android app with the package name `com.dogukan_tufan.roommate_expense_app`.
3. Download `google-services.json` and put it in `android/app/`.

`android/app/google-services.json` is in `.gitignore`, because it is specific to each Firebase project. Every developer downloads their own copy and never commits it.

## Design Notes

- **The server sends data, the app writes the text.** The API returns only facts (who did what, how much, which home). The app builds the notification sentences in the current language (`lib/utils/notification_text.dart`), so the wording stays consistent in Turkish and English.
- **Attachments come from the server.** Receipts are fetched from the API when they are opened. The downloaded bytes are kept in memory only (RAM), not on disk, so they are cleared when the app closes.
- **PDFs are generated on the device.** The statement PDF is built on the phone with the `pdf` package and the embedded Nunito font, so Turkish characters (ç, ğ, ı, ö, ş, ü) and the ₺ sign print correctly.

## Roadmap

- Google Play release (with a proper release signing config)
- HTTPS API, and removal of cleartext HTTP
- Deploy the API so the app works without a cable
- iOS support
- Offline cache
- Automated tests (widget and integration tests)
