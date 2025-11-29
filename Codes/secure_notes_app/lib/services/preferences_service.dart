import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService instance = PreferencesService._init();
  
  PreferencesService._init();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Auto-lock duration in seconds
  Future<void> setLockDuration(int seconds) async {
    await init();
    await _prefs?.setInt('lock_duration', seconds);
    print('Lock duration set to $seconds seconds');
  }

  Future<int> getLockDuration() async {
    await init();
    return _prefs?.getInt('lock_duration') ?? 30; // Default 30 seconds
  }

  // Theme preference (light, dark, system)
  Future<void> setTheme(String theme) async {
    await init();
    await _prefs?.setString('theme', theme);
    print('Theme set to $theme');
  }

  Future<String> getTheme() async {
    await init();
    return _prefs?.getString('theme') ?? 'system'; // Default system theme
  }

  // Clear all preferences (for testing)
  Future<void> clearAll() async {
    await init();
    await _prefs?.clear();
    print('All preferences cleared');
  }
}