import 'package:flutter/material.dart';
import 'preferences_service.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._init();
  
  ThemeService._init() {
    _loadTheme();
  }

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadTheme() async {
    final savedTheme = await PreferencesService.instance.getTheme();
    
    switch (savedTheme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    await PreferencesService.instance.setTheme(theme);
    
    switch (theme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    
    notifyListeners();
  }
}