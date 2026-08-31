// ============================================
// SERVICIO DE PREFERENCIAS DE POMODORO (LOCAL)
// ============================================

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pomodoro_preferences.dart';

class PomodoroPreferencesService {
  static const _key = 'pomodoro_preferences';

  static Future<PomodoroPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key);
    if (encoded == null || encoded.isEmpty) {
      return PomodoroPreferences.defaults();
    }

    try {
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      return PomodoroPreferences.fromJson(decoded);
    } catch (_) {
      return PomodoroPreferences.defaults();
    }
  }

  static Future<void> save(PomodoroPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(preferences.toJson()));
  }
}
