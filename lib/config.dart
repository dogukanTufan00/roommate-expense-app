// Base URL of the roommate expense REST API (Spring Boot, port 8080).
//
// Chosen at build time, so the same code works on every device:
//   Emulator (default):  flutter run
//                        10.0.2.2 is how the Android emulator reaches the host computer's localhost.
//   Phone over USB:      adb reverse tcp:8080 tcp:8080
//                        flutter run --dart-define=API_BASE_URL=http://localhost:8080
//                        adb reverse forwards the phone's localhost:8080 to the computer, so no
//                        Wi-Fi, IP address or firewall setup is needed.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);
