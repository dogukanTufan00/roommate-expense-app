**English** | [Türkçe](README.tr.md)

# Evce — Mobile App

A Flutter Android client for the Shared Expense Tracking System REST API. Evce helps roommates record shared household expenses, see who owes whom, record payments, and export a monthly statement as PDF.
The backend lives in [dogukanTufan00/shared-expense-tracking-system](https://github.com/dogukanTufan00/shared-expense-tracking-system) and must be running for the app to work.

## Features

- **Warm, bilingual UI.** Turkish and English. The app follows the phone's language by default, and you can switch languages inside the app. The choice is saved.
- **Login and sign up.** You stay logged in after closing the app. The saved token's expiry is checked at start-up, and an expired session asks you to log in again.
- **Homes and invitations.** A list of your homes, with invitation cards you can accept or decline. A notification bell in the top bar shows an unread badge.
- **Household screen with five tabs:**
  - **Expenses:** a shopping list card at the top, with the number of items still to buy. Tap it to open the shared list: tick items as they are bought, then save the bought items together as one expense ("checkout"). Below it, an "Upcoming payments" card lists the next bills (up to three, then "+N more"). Expenses are grouped by month, with filters and a search box. Search checks the description, product list, category, payer, share names and amount, and ignores Turkish letter differences (so "irmak" also finds "Irmak"). Badges mark expenses with a receipt (paperclip), recurring expenses, and automatically generated ones.
  - **Balances:** who pays whom, with one line per debt between two people. Only the payer or the receiver can mark a payment as paid (an admin can do it only when one of them has left the home). Copy the recipient's IBAN with one tap, show it as a QR code, and record a payment with a suggested amount (the app warns you about overpayment). Share a single payment, or the whole summary, to WhatsApp or any other app. The person who is owed can tap "Remind" to send the debtor a gentle reminder, once every 24 hours. A payment details sheet shows the receipts.
  - **Chores:** household chores (for example trash or dishes) with a rotation. Tick the people who take part and drag them into the turn order. The turn moves on when a chore is marked done, and you can remind the person whose turn it is. Each chore keeps its own history.
  - **Statement:** pick a month or a custom date range to see per-person bars, the dominant payer insight, a category breakdown, and a 6-month chart. The statement can be exported as PDF and shared.
  - **Members:** founder and admin icons (with tooltips), invite members by email, change roles, transfer ownership, remove members (with a warning if they still have open debts), and leave the home. The deposit card shows the home's deposit and what each person holds; admins can undo a deposit transfer. Leaving the home, or removing a member, opens the move-out screen: hand the person's deposit share to the others, settle their open debts, and then leave.
- **Expense form.** Choose the members involved and a split: Equal, Percent or Amount. Default split ratios can be saved and reused. Expenses can be set to recur, and receipts can be attached from the camera, the gallery, or as PDF files. For recurring expenses, you can also choose a bill reminder (none, or 1, 3 or 7 days before the due date); everyone with a share gets a notification. There are 12 categories, each with its own icon: rent, utilities, groceries, cleaning, eating out, subscriptions, home items and repairs, pets, entertainment, transport, health and beauty, and other.
- **Receipt scanning.** When adding an expense, tap "Fill from receipt" and take a photo or pick one from the gallery. The text is read on the phone with Google ML Kit, offline and free. The app finds the total, the date, the store name and the product lines, and guesses the category from known chains (for example Migros or A101) or from the words on the receipt. A sheet shows what was found; uncheck any product you do not want, then apply. The form is filled in, the products go into the expense's product list, and the photo is attached as the receipt. You can check and correct everything before saving. The product list stays editable in the "Products" field of the expense form, and it is also printed in the statement PDF.
- **Recurring expenses.** A screen to review and manage recurring expenses.
- **Default ratios.** A screen to set the default split ratios for each home.
- **Profile.** Change your name, set your IBAN (validated) and show it as a QR code, change your password, and choose the appearance: Light, Dark or System. The choice is saved on the device.
- **Account deletion.** Delete your account from the profile. The first screen explains what happens. Homes where you are the only member are deleted with their expenses and payments. If you are the founder of a home that still has other members, or the last admin of one, you must transfer ownership or make another member an admin first; the delete button stays disabled until then. Open balances are shown as a warning, because deleting your account does not clear them. You type your password and confirm that this cannot be undone. Expenses and payments you shared stay in your roommates' balances, under a placeholder name ("Silinmiş kullanıcı").
- **Notifications.** A full notifications screen with invitations, new expenses, recorded payments, recurring expenses, chore turns and payment or chore reminders.
- **Push notifications.** Firebase Cloud Messaging works while the app is open, in the background, and after the app was closed. Tapping a notification opens its home.
- **Activity history.** The clock icon in a home's top bar opens its history: every addition, edit and deletion of expenses, payments and members, newest first, with who did it, when, and what changed.

## Tech Stack

| Concern | Technology |
|---|---|
| Framework / language | Flutter / Dart (Dart SDK `^3.13.5`, see `pubspec.yaml`) |
| UI | Material 3 with a custom warm theme (`lib/theme.dart`): terracotta, sage, mustard and cream palette for light mode, and a warm coffee-brown palette for dark mode (`AppPalette`), Nunito font, illustrations made with Gemini |
| State management | `setState`, with a few shared `ValueNotifier`s (for example the language and the theme). No state-management library, on purpose: the app is small, and plain `setState` is easier to read and maintain. |
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
| `share_plus` | ^13.3.1 | Shares the balance summary and single payments with other apps (for example WhatsApp), and shares the IBAN QR code |
| `qr_flutter` | ^4.1.0 | Draws the IBAN as a QR code that a banking app can scan |
| `google_mlkit_text_recognition` | ^1.0.3 | Reads the text of a receipt photo on the device (Latin script model, works offline) |
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
├── services/
│   └── receipt_scanner.dart   # Reads a receipt photo with ML Kit and passes the rows to the parser
├── screens/
│   ├── login_screen.dart, register_screen.dart
│   ├── households_screen.dart        # Home list, invitation cards, notification bell
│   ├── household_screen.dart         # Home details with the five tabs
│   ├── expenses_tab.dart, balances_tab.dart, chores_tab.dart, statement_tab.dart, members_tab.dart
│   ├── expense_form_screen.dart      # Add or edit an expense
│   ├── shopping_list_screen.dart     # Shared shopping list, checkout into one expense
│   ├── chore_form_screen.dart        # Add or edit a chore and its rotation order
│   ├── deposit_form_screen.dart      # Set the home deposit and each person's share
│   ├── move_out_screen.dart          # Deposit handover, settling debts, leaving or removing a member
│   ├── history_screen.dart           # Activity history of one home
│   ├── recurring_expenses_screen.dart
│   ├── split_defaults_screen.dart    # Default split ratios
│   ├── profile_screen.dart           # Name, IBAN, password, appearance
│   ├── delete_account_screen.dart    # Account deletion, with the blockers and open balances
│   └── notifications_screen.dart
├── utils/
│   ├── avatar.dart, category.dart    # Member avatars, category codes, labels and icons
│   ├── split.dart, iban.dart         # Split calculations, IBAN validation
│   ├── bill_reminder.dart            # Reminder choices and days until a due date
│   ├── search.dart                   # Expense search text folding (Turkish letters)
│   ├── summary_text.dart             # Text of the shareable balance summary
│   ├── activity_text.dart            # Sentences and change lines of the history
│   ├── errors.dart                   # Maps API errors to localized messages
│   ├── format.dart                   # Money and date formatting for the current language
│   ├── notification_text.dart        # Builds notification sentences from server data
│   ├── receipt_rows.dart             # Straightens a tilted photo and groups OCR lines into printed rows
│   ├── receipt_parser.dart           # Finds the total, date, store, category and products in the rows
│   └── statement_pdf.dart            # Statement PDF with the embedded Nunito font
├── widgets/
│   ├── language_menu_button.dart     # Language switch in the app bar
│   ├── attachments_section.dart      # Receipt list and viewer
│   ├── deposit_card.dart             # Deposit card on the Members tab
│   ├── iban_qr_sheet.dart            # IBAN as a QR code, with share
│   ├── receipt_result_sheet.dart     # What was read from a receipt, with product checkboxes
│   └── illustration.dart             # Illustrations, with dark versions in dark mode
├── config.dart            # API base URL (can be set with --dart-define)
├── models.dart            # Data classes with fromJson factories
├── session.dart           # Saved token, logged in user's email, language and theme choice, JWT expiry check
├── theme.dart             # Light and dark colors (AppColors, AppPalette), typography and component themes
└── main.dart              # App start, theme and routing between login and homes
test/
├── summary_text_test.dart     # Balance summary text
├── category_test.dart         # Category codes, labels and icons
├── receipt_parser_test.dart   # Receipt rules on clean text
├── receipt_rows_test.dart     # Tilt correction and row grouping
├── receipt_real_test.dart     # Real ML Kit output of scanned receipts
└── fixtures/                  # Saved OCR results (personal data replaced)
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

The APK is a universal build that runs on every Android device. Because it contains the ML Kit text recognition model for each processor type, it is about 100 MB.

## Push Notifications

Push notifications use Firebase Cloud Messaging (`firebase_core`, `firebase_messaging`, `flutter_local_notifications`). The Android build applies the Google services plugin, so **the app does not build without a Firebase config file**, even if you do not use push. Setup, once per developer:

1. Create a project in the [Firebase console](https://console.firebase.google.com).
2. Add an Android app with the package name `com.dogukan_tufan.roommate_expense_app`.
3. Download `google-services.json` and put it in `android/app/`.

`android/app/google-services.json` is in `.gitignore`, because it is specific to each Firebase project. Every developer downloads their own copy and never commits it.

## Design Notes

- **The server sends data, the app writes the text.** The API returns only facts (who did what, how much, which home). The app builds the notification sentences in the current language (`lib/utils/notification_text.dart`), so the wording stays consistent in Turkish and English.
- **Attachments come from the server.** Receipts are fetched from the API when they are opened. The downloaded bytes are kept in memory only (RAM), not on disk, so they are cleared when the app closes.
- **Receipts are read on the device.** Receipt scanning uses Google ML Kit on the phone, so the photo is not sent to any OCR service and the feature works without internet. The rules that find the total, date and products are plain Dart (`lib/utils/receipt_parser.dart`), so they are covered by unit tests, including saved output of real receipts. The total is chosen by priority ("ÖDENECEK" before "GENEL TOPLAM" before "TOPLAM"), because receipts print several totals.
- **PDFs are generated on the device.** The statement PDF is built on the phone with the `pdf` package and the embedded Nunito font, so Turkish characters (ç, ğ, ı, ö, ş, ü) and the ₺ sign print correctly.
- **Dark mode uses the theme, not fixed colors.** The app has Light, Dark and System modes. Screens read their colors with `context.palette` (for example `context.palette.muted`), which returns the light or dark set of the `AppPalette` theme extension in `lib/theme.dart`.
- **Dark illustrations.** Each illustration has a dark version next to it (for example `empty-homes-dark.png`), and the illustrations have transparent backgrounds. If a dark version is missing, the light file is used.

> **Developer note:** new UI code must take its colors from `context.palette`, not from the light-only `AppColors` constants. Using `AppColors` directly makes the screen look wrong in dark mode.

## Roadmap

- Google Play release (with a proper release signing config)
- HTTPS API, and removal of cleartext HTTP
- Deploy the API so the app works without a cable
- iOS support
- Offline cache
- Automated tests (widget and integration tests)
