import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_notes_app/services/preferences_service.dart';

void main() {
  group('PreferencesService Tests', () {
    late PreferencesService preferencesService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferencesService = PreferencesService.instance;
    });

    test('TC-14: Default lock duration should be 30 seconds', () async {
      final duration = await preferencesService.getLockDuration();
      expect(duration, 30);
    });

    test('TC-15: Set lock duration to 60 should return 60', () async {
      await preferencesService.setLockDuration(60);
      final duration = await preferencesService.getLockDuration();
      expect(duration, 60);
    });

    test('TC-16: Set lock duration to 0 (Never) should return 0', () async {
      await preferencesService.setLockDuration(0);
      final duration = await preferencesService.getLockDuration();
      expect(duration, 0);
    });

    test('TC-17: Default theme should be system', () async {
      final theme = await preferencesService.getTheme();
      expect(theme, 'system');
    });

    test('TC-18: Set theme to dark should return dark', () async {
      await preferencesService.setTheme('dark');
      final theme = await preferencesService.getTheme();
      expect(theme, 'dark');
    });

    test('TC-19: Set theme to light should return light', () async {
      await preferencesService.setTheme('light');
      final theme = await preferencesService.getTheme();
      expect(theme, 'light');
    });
  });
}