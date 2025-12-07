import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  // Keys
  static const String _seenOnboarding = "seen_onboarding";
  static const String _accessToken = "access_token";
  static const String _refreshToken = "refresh_token";
  static const String _userData = "user_data";
  static const String _deviceIdKey = "device_id";

  // Load SharedPreferences once
  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  // ============================================================
  // ONBOARDING
  // ============================================================
  static Future<void> setSeenOnboarding() async {
    final prefs = await _prefs;
    await prefs.setBool(_seenOnboarding, true);
  }

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await _prefs;
    return prefs.getBool(_seenOnboarding) ?? false;
  }

  // ============================================================
  // TOKENS
  // ============================================================
  static Future<void> saveTokens({
    required String access,
    String? refresh,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_accessToken, access);
    if (refresh != null) {
      await prefs.setString(_refreshToken, refresh);
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(_accessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(_refreshToken);
  }

  // ============================================================
  // USER DATA — SAVE AS JSON MAP (not string)
  // ============================================================
  static Future<void> saveUserJson(Map<String, dynamic> userMap) async {
    final prefs = await _prefs;
    await prefs.setString(_userData, jsonEncode(userMap));
  }

  static Future<Map<String, dynamic>?> getUserJson() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_userData);
    if (raw == null) return null;

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // CLEAR USER
  // ============================================================
  static Future<void> clearUserData() async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.remove(_accessToken),
      prefs.remove(_refreshToken),
      prefs.remove(_userData),
    ]);
  }

  // ============================================================
  // DEVICE ID
  // ============================================================
  static Future<String?> getDeviceId() async {
    final prefs = await _prefs;
    return prefs.getString(_deviceIdKey);
  }

  static Future<void> saveDeviceId(String id) async {
    final prefs = await _prefs;
    await prefs.setString(_deviceIdKey, id);
  }

  // ============================================================
  // CLEAR EVERYTHING
  // ============================================================
  static Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
