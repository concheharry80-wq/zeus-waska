import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeus_waska/models/content_item.dart';

class StorageService {
  static const _kGroupsKey = 'zw_saved_groups_v1';
  static const _kHistoryKey = 'zw_game_history_v1';
  static const _kCustomKey = 'zw_custom_challenges_v1';
  static const _kSettingsKey = 'zw_app_settings_v1';
  static const _kActiveSessionKey = 'zw_active_session_v1';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<SavedGroup>> loadGroups() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kGroupsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SavedGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveGroups(List<SavedGroup> groups) async {
    final prefs = await _prefs;
    await prefs.setString(
      _kGroupsKey,
      jsonEncode(groups.map((g) => g.toJson()).toList()),
    );
  }

  Future<List<GameHistoryEntry>> loadHistory() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kHistoryKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => GameHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveHistory(List<GameHistoryEntry> entries) async {
    final prefs = await _prefs;
    await prefs.setString(
      _kHistoryKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<CustomChallenge>> loadCustomChallenges() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kCustomKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CustomChallenge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCustomChallenges(List<CustomChallenge> items) async {
    final prefs = await _prefs;
    await prefs.setString(
      _kCustomKey,
      jsonEncode(items.map((c) => c.toJson()).toList()),
    );
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kSettingsKey);
    if (raw == null || raw.isEmpty) return const AppSettings();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await _prefs;
    await prefs.setString(_kSettingsKey, jsonEncode(settings.toJson()));
  }

  Future<Map<String, dynamic>?> loadActiveSession() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kActiveSessionKey);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveActiveSession(Map<String, dynamic>? session) async {
    final prefs = await _prefs;
    if (session == null) {
      await prefs.remove(_kActiveSessionKey);
    } else {
      await prefs.setString(_kActiveSessionKey, jsonEncode(session));
    }
  }

  Future<void> clearHistoryOnly() async {
    final prefs = await _prefs;
    await prefs.remove(_kHistoryKey);
  }

  Future<void> clearAllData() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
