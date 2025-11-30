import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/app_lock_service.dart';
import '../services/pin_service.dart';
import 'pin_setup_screen.dart';
import 'pin_login_screen.dart';
import '../widgets/activity_detector.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _message = 'Tap the fingerprint to unlock';
  bool _isPinSet = false;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final isPinSet = await PinService.instance.isPinSet();
    setState(() {
      _isPinSet = isPinSet;
    });
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _message = 'Authenticating...';
    });

    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to access your secure notes',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      setState(() {
        _isAuthenticating = false;
        if (authenticated) {
          _message = 'Authentication successful!';
          // Unlock the app - main.dart will handle showing NotesListScreen
          AppLockService.instance.unlock();
        } else {
          _message = 'Authentication failed. Try again.';
        }
      });
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _message = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _setupPin() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PinSetupScreen(),
      ),
    );

    if (result == true) {
      _checkPinStatus(); // Refresh PIN status
    }
  }

  Future<void> _loginWithPin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PinLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ActivityDetector(
      child: Scaffold(
    
        backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFE3F2FD),

        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    Icons.lock_outline,
                    size: 100,
                    color: const Color(0xFF1A237E), // Navy blue
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'SafeNotes',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E), // Navy blue
                    ),
                  ),
                const SizedBox(height: 50),
                GestureDetector(
                  onTap: _isAuthenticating ? null : _authenticate,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00BCD4), // Cyan
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1A237E), // Navy blue
                  ),
                ),
                const SizedBox(height: 40),
                
                // Divider with "OR"
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Use PIN button
                if (_isPinSet)
                  OutlinedButton.icon(
                    onPressed: _loginWithPin,
                    icon: const Icon(Icons.pin),
                    label: const Text('Use PIN Instead'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D47A1), // Dark blue
                      side: const BorderSide(color: Color(0xFF0D47A1)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
                
                // Setup PIN button (only if PIN not set)
                if (!_isPinSet)
                  OutlinedButton.icon(
                    onPressed: _setupPin,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Setup Backup PIN'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade700),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}