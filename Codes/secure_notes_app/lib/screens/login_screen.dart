import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/app_lock_service.dart';
import '../services/pin_service.dart';
import 'pin_login_screen.dart';
import 'pin_setup_screen.dart';
import '../widgets/activity_detector.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  String _message = 'Tap the fingerprint to unlock';
  bool _hasPinSetup = false;

  @override
  void initState() {
    super.initState();
    _checkPinSetup();
    _authenticate();
  }

  Future<void> _checkPinSetup() async {
    final hasPinSetup = await PinService.instance.isPinSet();
    setState(() {
      _hasPinSetup = hasPinSetup;
    });
  }

  Future<void> _authenticate() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        setState(() {
          _message = 'Biometric authentication not available';
        });
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your secure notes',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        AppLockService.instance.unlock();
      } else {
        setState(() {
          _message = 'Authentication failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _usePinLogin() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PinLoginScreen(),
      ),
    );

    if (result == true) {
      AppLockService.instance.unlock();
    }
  }

  Future<void> _setupPin() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PinSetupScreen(),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _hasPinSetup = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN setup successful! You can now use PIN to unlock.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActivityDetector(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lock Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'SafeNotes',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Unlock to access your notes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Fingerprint Button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _authenticate,
                      icon: const Icon(Icons.fingerprint),
                      iconSize: 80,
                      color: Theme.of(context).colorScheme.onSecondary,
                      padding: const EdgeInsets.all(32),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Message
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // PIN Options
                  if (_hasPinSetup)
                    OutlinedButton.icon(
                      onPressed: _usePinLogin,
                      icon: const Icon(Icons.dialpad),
                      label: const Text('Use PIN Instead'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                  if (!_hasPinSetup)
                    OutlinedButton.icon(
                      onPressed: _setupPin,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Setup PIN'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}