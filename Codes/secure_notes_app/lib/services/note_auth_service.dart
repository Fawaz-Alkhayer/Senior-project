import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'pin_service.dart';
import 'app_lock_service.dart';
import '../screens/pin_login_screen.dart';

class NoteAuthService {
  static final NoteAuthService instance = NoteAuthService._internal();
  
  NoteAuthService._internal();
  
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticateForNote(BuildContext context) async {
    
    AppLockService.instance.pauseAutoLock();
    
    try {
      
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canCheckBiometrics && isDeviceSupported) {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to access this locked note',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        AppLockService.instance.resumeAutoLock();
        return authenticated;
      }

      final hasPinSetup = await PinService.instance.isPinSet();
      
      if (hasPinSetup && context.mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PinLoginScreen(),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        AppLockService.instance.resumeAutoLock();
        return result == true;
      }

      AppLockService.instance.resumeAutoLock();
      return false;
    } catch (e) {
      debugPrint('Authentication error: $e');
      AppLockService.instance.resumeAutoLock();
      return false;
    }
  }
}