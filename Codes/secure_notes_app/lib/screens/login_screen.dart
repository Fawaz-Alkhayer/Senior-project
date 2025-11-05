import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'notes_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _message = 'Tap the fingerprint to unlock';

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
          // Navigate to notes list screen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const NotesListScreen(),
              ),
            );
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 100,
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 30),
            Text(
              'Secure Notes',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: _isAuthenticating ? null : _authenticate,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  shape: BoxShape.circle,
                ),
                child: Icon(
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}