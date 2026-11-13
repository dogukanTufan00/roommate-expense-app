import 'dart:convert';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/main.dart' show navigatorKey;
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/screens/household_screen.dart';
import 'package:roommate_expense_app/screens/notifications_screen.dart';
import 'package:roommate_expense_app/session.dart';

// Push notifications (Firebase Cloud Messaging) for Evce.
//
// - While the app is open, Android does not show FCM notifications by itself,
//   so a push that arrives in the foreground is shown as a local notification.
// - Tapping a notification opens its home, or the notifications screen when the
//   home is not known. Taps are handled on a cold start too.
// - After login, this phone's FCM token is sent to the API together with the app
//   language, so the server writes pushes in that language. The token is sent
//   again when it changes or when the language changes, and removed on logout.
//
// Every method fails softly: problems are logged with debugPrint and never block
// login or app start.
class PushService {
  PushService._();

  // Android notification channel. The server's pushes use this id, see
  // default_notification_channel_id in AndroidManifest.xml.
  static const String _channelId = 'evce_default';

  // Terracotta, the accent color of the status bar icon.
  static const Color _accent = Color(0xFFD96C4F);

  // Bumped each time a push arrives while the app is open. The households screen
  // listens to it and reloads the unread badge.
  static final ValueNotifier<int> notificationsChanged = ValueNotifier<int>(0);

  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  // True only when Firebase started. Everything else is skipped when it did not.
  static bool _ready = false;

  // The last token we know. It is needed to remove the token on logout.
  static String? _token;

  // A tap that came before the navigator existed (the app was started by a notification).
  static Map<String, String>? _pendingTap;

  // Starts Firebase, the local notifications and the Android channel. Call once before runApp.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();

      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_evce'),
        ),
        onDidReceiveNotificationResponse: (response) =>
            _handleTap(_decodePayload(response.payload)),
      );

      final android = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final l10n = _l10n();
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId,
          l10n.pushChannelName,
          description: l10n.pushChannelDescription,
          importance: Importance.high,
        ),
      );

      FirebaseMessaging.onMessage.listen(_showForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp
          .listen((message) => _handleTap(_stringMap(message.data)));
      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);
      // A language change sends the new language to the server (see _onLanguageChanged).
      Session.locale.addListener(_onLanguageChanged);

      // Tap while the app was terminated: FCM message first, then a local notification.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _handleTap(_stringMap(initial.data));
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _handleTap(_decodePayload(launch?.notificationResponse?.payload));
      }

      _ready = true;

      // After the first frame the navigator exists, and the permission dialog
      // does not appear over the splash screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _flushPendingTap();
        if (Session.isLoggedIn) registerAfterLogin();
      });
    } catch (e) {
      debugPrint('Push notifications are off: $e');
    }
  }

  // Asks for permission (Android 13+ shows the dialog), then sends this phone's
  // token to the API. Call after a successful login, and at app start when a session exists.
  static Future<void> registerAfterLogin() {
    return _safely('registration', () async {
      await FirebaseMessaging.instance.requestPermission();
      await _uploadToken();
    });
  }

  // Removes this phone from the account, then deletes the FCM token.
  // Call it BEFORE Session.clear(): the DELETE request needs the login token.
  static Future<void> unregisterOnLogout() {
    return _safely('logout', () async {
      final token = _token ?? await _fetchToken();
      _token = null;
      if (token != null && Session.isLoggedIn) {
        await _safely('device removal', () => Api.unregisterPushDevice(token));
      }
      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.deleteToken();
    });
  }

  // Deletes the FCM token on this phone only, without calling the API. Used after the
  // account was deleted: the server already removed this device, and the login token no longer works.
  static Future<void> forgetDeviceLocally() {
    return _safely('local token removal', () async {
      _token = null;
      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.deleteToken();
    });
  }

  // Sends the current token with the current language to the API.
  static Future<void> _uploadToken() async {
    final token = await _fetchToken();
    if (token == null) return;
    _token = token;
    if (!Session.isLoggedIn) return;
    await Api.registerPushDevice(token, _languageCode());
  }

  static void _onTokenRefresh(String token) {
    _token = token;
    if (Session.isLoggedIn) {
      _safely('token update', () => Api.registerPushDevice(token, _languageCode()));
    }
  }

  static void _onLanguageChanged() {
    if (Session.isLoggedIn) _safely('language update', _uploadToken);
  }

  // A push that arrives while the app is open. Android does not show it by itself,
  // so it is shown here. Also tells the households screen to refresh the badge.
  static Future<void> _showForegroundMessage(RemoteMessage message) async {
    notificationsChanged.value++;
    await _safely('display', () async {
      final l10n = _l10n();
      await _local.show(
        id: (message.messageId ?? '${DateTime.now().microsecondsSinceEpoch}').hashCode,
        title: message.notification?.title ?? message.data['title'],
        body: message.notification?.body ?? message.data['body'],
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            l10n.pushChannelName,
            channelDescription: l10n.pushChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_stat_evce',
            color: _accent,
          ),
        ),
        // The data is kept in the payload, so a tap on this local notification can open its home.
        payload: jsonEncode(message.data),
      );
    });
  }

  // Opens the target of a tap. A tap before the navigator exists waits for the first frame.
  static void _handleTap(Map<String, String>? data) {
    if (data == null || data.isEmpty) return;
    if (navigatorKey.currentState == null) {
      _pendingTap = data;
      return;
    }
    _openTarget(data);
  }

  static void _flushPendingTap() {
    final data = _pendingTap;
    _pendingTap = null;
    if (data != null) _handleTap(data);
  }

  // Opens the home from the push data, or the notifications screen when the home
  // is not in my list (I was removed, or it is an invitation).
  static Future<void> _openTarget(Map<String, String> data) async {
    final navigator = navigatorKey.currentState;
    // Logged out: the app just opens normally on the login screen.
    if (navigator == null || !Session.isLoggedIn) return;

    try {
      final householdId = int.tryParse(data['householdId'] ?? '');
      if (householdId != null) {
        final households = await Api.getHouseholds();
        final matches = households.where((h) => h.id == householdId).toList();
        if (matches.isNotEmpty) {
          // A payment reminder opens the Balances tab, where the debt is.
          final initialTab =
              NotificationType.fromApi(data['type'] ?? '') == NotificationType.paymentReminder
                  ? HouseholdScreen.balancesTab
                  : 0;
          await navigator.push(
            MaterialPageRoute(
              builder: (_) => HouseholdScreen(
                household: matches.first,
                initialTab: initialTab,
              ),
            ),
          );
          return;
        }
      }
      await navigator.push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    } catch (e) {
      debugPrint('Could not open a push notification: $e');
    }
  }

  // Turns the payload (a JSON map written by _showForegroundMessage) back into data.
  static Map<String, String>? _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      return _stringMap(json);
    } catch (_) {
      return null;
    }
  }

  // The FCM registration token, which the server sends pushes to. The newer
  // register() and onRegistered API gives the Firebase Installation ID instead, so
  // the deprecated getToken() is still used until the server works with that ID.
  // ignore: deprecated_member_use
  static Future<String?> _fetchToken() => FirebaseMessaging.instance.getToken();

  // Push data is a Map<String, dynamic>, and the tap handler needs strings.
  static Map<String, String> _stringMap(Map<dynamic, dynamic> data) {
    return data.map((key, value) => MapEntry('$key', '$value'));
  }

  // Runs one action and logs any error. Does nothing when Firebase did not start.
  static Future<void> _safely(String what, Future<void> Function() action) async {
    if (!_ready) return;
    try {
      await action();
    } catch (e) {
      debugPrint('Push $what failed: $e');
    }
  }

  // "tr" or "en". The language chosen in the app wins, otherwise the phone's
  // language. Any other language gets English, the same as the API.
  static String _languageCode() {
    final code = Session.locale.value?.languageCode ??
        ui.PlatformDispatcher.instance.locale.languageCode;
    return code == 'tr' ? 'tr' : 'en';
  }

  // Localized strings outside the widget tree (the channel and the notifications).
  static AppLocalizations _l10n() => lookupAppLocalizations(Locale(_languageCode()));
}
