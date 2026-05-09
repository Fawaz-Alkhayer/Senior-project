import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_notes_app/services/pin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock the flutter_secure_storage platform channel
  const channel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final Map<String, String> mockStorage = {};

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'write':
          final key = methodCall.arguments['key'] as String;
          final value = methodCall.arguments['value'] as String?;
          if (value != null) mockStorage[key] = value;
          return null;
        case 'read':
          final key = methodCall.arguments['key'] as String;
          return mockStorage[key];
        case 'delete':
          final key = methodCall.arguments['key'] as String;
          mockStorage.remove(key);
          return null;
        case 'containsKey':
          final key = methodCall.arguments['key'] as String;
          return mockStorage.containsKey(key);
        default:
          return null;
      }
    });
  });

  tearDown(() {
    mockStorage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('PinService Tests', () {
    test('TC-01: PIN too short should throw exception', () {
      expect(
        () async => await PinService.instance.setPin('123'),
        throwsException,
      );
    });

    test('TC-02: Valid PIN should be set successfully', () async {
      await PinService.instance.setPin('123456');
      final isSet = await PinService.instance.isPinSet();
      expect(isSet, true);
    });

    test('TC-03: Correct PIN should verify successfully', () async {
      await PinService.instance.setPin('123456');
      final result = await PinService.instance.verifyPin('123456');
      expect(result, true);
    });

    test('TC-04: Wrong PIN should fail verification', () async {
      await PinService.instance.setPin('123456');
      final result = await PinService.instance.verifyPin('654321');
      expect(result, false);
    });

    test('TC-05: Cleared PIN should not be set', () async {
      await PinService.instance.setPin('123456');
      await PinService.instance.clearPin();
      final isSet = await PinService.instance.isPinSet();
      expect(isSet, false);
    });

    test('TC-06: Verify PIN after clear should return false', () async {
      await PinService.instance.setPin('123456');
      await PinService.instance.clearPin();
      final result = await PinService.instance.verifyPin('123456');
      expect(result, false);
    });
  });
}