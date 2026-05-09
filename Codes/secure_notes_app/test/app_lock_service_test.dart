import 'package:flutter_test/flutter_test.dart';
import 'package:secure_notes_app/services/app_lock_service.dart';

void main() {
  group('AppLockService Tests', () {
    late AppLockService lockService;

    setUp(() {
      lockService = AppLockService.instance;
    });

    test('TC-07: App should be locked on initial state', () {
      expect(lockService.isLocked, true);
    });

    test('TC-08: App should be unlocked after unlock() is called', () {
      lockService.unlock();
      expect(lockService.isLocked, false);
    });

    test('TC-09: App should be locked after lock() is called', () {
      lockService.unlock();
      lockService.lock();
      expect(lockService.isLocked, true);
    });

    test('TC-10: isPaused should be false by default', () {
      expect(lockService.isPaused, false);
    });

    test('TC-11: pauseAutoLock should set isPaused to true', () {
      lockService.pauseAutoLock();
      expect(lockService.isPaused, true);
      lockService.resumeAutoLock(); // cleanup
    });

    test('TC-12: resumeAutoLock should set isPaused to false', () {
      lockService.pauseAutoLock();
      lockService.resumeAutoLock();
      expect(lockService.isPaused, false);
    });

    test('TC-13: updateLockDuration with 0 should disable timer', () {
      lockService.unlock();
      lockService.updateLockDuration(0);
      expect(lockService.isLocked, false);
    });
  });
}