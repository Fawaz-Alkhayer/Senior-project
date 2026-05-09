import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PinService {
  static final PinService instance = PinService._init();

  PinService._init();

  final _storage = const FlutterSecureStorage();
  static const String _pinKey = 'user_pin_hash';
  static const String _pinSetKey = 'is_pin_set';
  static const String _attemptCountKey = 'pin_attempt_count';
  static const String _lockoutTimeKey = 'pin_lockout_time';
  static const int maxAttempts = 5;
  static const int _lockoutDurationSeconds = 30;

  Future<bool> isPinSet() async {
    final isSet = await _storage.read(key: _pinSetKey);
    return isSet == 'true';
  }

  Future<void> setPin(String pin) async {
    if (pin.length < 6) {
      throw Exception('PIN must be at least 6 digits');
    }
    final hashedPin = _hashPin(pin);
    await _storage.write(key: _pinKey, value: hashedPin);
    await _storage.write(key: _pinSetKey, value: 'true');
    await _resetAttemptCount();
  }

  Future<bool> isLockedOut() async {
    final lockoutTimeStr = await _storage.read(key: _lockoutTimeKey);
    if (lockoutTimeStr == null) return false;

    final lockoutTime = DateTime.parse(lockoutTimeStr);
    final elapsed = DateTime.now().difference(lockoutTime).inSeconds;

    if (elapsed < _lockoutDurationSeconds) {
      return true;
    } else {
      await _storage.delete(key: _lockoutTimeKey);
      await _resetAttemptCount();
      return false;
    }
  }

  Future<int> getRemainingLockoutSeconds() async {
    final lockoutTimeStr = await _storage.read(key: _lockoutTimeKey);
    if (lockoutTimeStr == null) return 0;

    final lockoutTime = DateTime.parse(lockoutTimeStr);
    final elapsed = DateTime.now().difference(lockoutTime).inSeconds;
    final remaining = _lockoutDurationSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  Future<int> getAttemptCount() async {
    final countStr = await _storage.read(key: _attemptCountKey);
    return int.tryParse(countStr ?? '0') ?? 0;
  }

  Future<void> _resetAttemptCount() async {
    await _storage.write(key: _attemptCountKey, value: '0');
  }

  Future<bool> verifyPin(String pin) async {
    final lockedOut = await isLockedOut();
    if (lockedOut) return false;

    final storedHash = await _storage.read(key: _pinKey);
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    final isValid = storedHash == inputHash;

    if (isValid) {
      await _resetAttemptCount();
    } else {
      final count = await getAttemptCount() + 1;
      await _storage.write(
          key: _attemptCountKey, value: count.toString());

      if (count >= maxAttempts) {
        await _storage.write(
            key: _lockoutTimeKey,
            value: DateTime.now().toIso8601String());
        await _resetAttemptCount();
      }
    }

    return isValid;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _pinSetKey);
    await _storage.delete(key: _attemptCountKey);
    await _storage.delete(key: _lockoutTimeKey);
  }
}