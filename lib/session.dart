import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keeps the login token and the chosen language.
//
// Why the token is kept: the user stays logged in after closing the app.
// The API's token is valid for 24 hours, so we check its expiry on start.
class Session {
  // The JWT token sent with every API request (null = logged out).
  static String? token;

  // The logged in user's email (the JWT "sub" claim).
  static String? email;

  // The app language. null means "follow the phone's language".
  static final ValueNotifier<Locale?> locale = ValueNotifier(null);

  static const String _tokenKey = 'token';
  static const String _languageKey = 'language';

  static bool get isLoggedIn => token != null;

  // Reads the saved token and language. Called once at app start.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    locale.value = _localeFromCode(prefs.getString(_languageKey));

    final savedToken = prefs.getString(_tokenKey);
    if (savedToken == null || _isExpired(savedToken)) {
      // No token, or the token is too old: treat the user as logged out.
      await clear();
      return;
    }

    token = savedToken;
    email = _payload(savedToken)?['sub'] as String?;
  }

  // Saves a new token after login.
  static Future<void> saveToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);

    token = newToken;
    email = _payload(newToken)?['sub'] as String?;
  }

  // Logs out. The language choice is kept on purpose.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);

    token = null;
    email = null;
  }

  // Changes the language. Pass null to follow the phone's language again.
  static Future<void> setLocale(Locale? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_languageKey);
    } else {
      await prefs.setString(_languageKey, value.languageCode);
    }

    locale.value = value;
  }

  // Only "tr" and "en" are supported. Anything else means "phone language".
  static Locale? _localeFromCode(String? code) {
    if (code == 'tr') return const Locale('tr');
    if (code == 'en') return const Locale('en');
    return null;
  }

  // A JWT has three parts separated by dots: header.payload.signature.
  // The middle part is the payload, encoded as Base64Url JSON.
  static Map<String, dynamic>? _payload(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;

      // Base64Url.normalize adds the "=" padding that decode() needs.
      final json = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // "exp" is the expiry time in seconds since 1970.
  static bool _isExpired(String jwt) {
    final exp = _payload(jwt)?['exp'];
    if (exp is! num) return true;

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    return DateTime.now().isAfter(expiresAt);
  }
}
