import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PinService {
  static final PinService instance = PinService._init();
  
  PinService._init();

  final _storage = const FlutterSecureStorage();
  static const String _pinKey = 'user_pin_hash';
  static const String _pinSetKey = 'is_pin_set';

  // Check if PIN is set
  Future<bool> isPinSet() async {
    final isSet = await _storage.read(key: _pinSetKey);
    return isSet == 'true';
  }

  // Set a new PIN
  Future<void> setPin(String pin) async {
    if (pin.length < 4) {
      throw Exception('PIN must be at least 4 digits');
    }

    final hashedPin = _hashPin(pin);
    await _storage.write(key: _pinKey, value: hashedPin);
    await _storage.write(key: _pinSetKey, value: 'true');
    print('PIN set successfully');
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinKey);
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    final isValid = storedHash == inputHash;
    
    if (isValid) {
      print('PIN verified successfully');
    } else {
      print('PIN verification failed');
    }
    
    return isValid;
  }

  // Hash PIN for security (SHA-256)
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Clear PIN (for testing/reset)
  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _pinSetKey);
    print('PIN cleared');
  }
}