import 'dart:async';
import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import '../widgets/activity_detector.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _obscurePin = true;
  String _errorMessage = '';
  bool _isLockedOut = false;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _checkLockoutStatus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLockoutStatus() async {
    final lockedOut = await PinService.instance.isLockedOut();
    if (lockedOut) {
      final remaining = await PinService.instance.getRemainingLockoutSeconds();
      setState(() {
        _isLockedOut = true;
        _remainingSeconds = remaining;
        _errorMessage = 'Too many failed attempts. Try again in $_remainingSeconds seconds.';
      });
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final remaining = await PinService.instance.getRemainingLockoutSeconds();
      if (remaining <= 0) {
        timer.cancel();
        setState(() {
          _isLockedOut = false;
          _remainingSeconds = 0;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _remainingSeconds = remaining;
          _errorMessage = 'Too many failed attempts. Try again in $_remainingSeconds seconds.';
        });
      }
    });
  }

  Future<void> _verifyPin() async {
    if (_isLockedOut) return;

    final pin = _pinController.text;

    if (pin.length < 6) {
      setState(() {
        _errorMessage = 'PIN must be at least 6 digits';
      });
      return;
    }

    final lockedOut = await PinService.instance.isLockedOut();
    if (lockedOut) {
      final remaining = await PinService.instance.getRemainingLockoutSeconds();
      setState(() {
        _isLockedOut = true;
        _remainingSeconds = remaining;
        _errorMessage = 'Too many failed attempts. Try again in $_remainingSeconds seconds.';
      });
      _startCountdown();
      return;
    }

    final isValid = await PinService.instance.verifyPin(pin);

    if (isValid && mounted) {
      Navigator.of(context).pop(true);
    } else {
      final nowLockedOut = await PinService.instance.isLockedOut();
      final attemptCount = await PinService.instance.getAttemptCount();

      if (nowLockedOut) {
        final remaining = await PinService.instance.getRemainingLockoutSeconds();
        setState(() {
          _isLockedOut = true;
          _remainingSeconds = remaining;
          _errorMessage = 'Too many failed attempts. Try again in $_remainingSeconds seconds.';
          _pinController.clear();
        });
        _startCountdown();
      } else {
        final attemptsLeft = PinService.maxAttempts - attemptCount;
        setState(() {
          _errorMessage = 'Incorrect PIN. $attemptsLeft attempt${attemptsLeft == 1 ? '' : 's'} remaining.';
          _pinController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActivityDetector(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _isLockedOut
                          ? Colors.red.withOpacity(0.1)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isLockedOut ? Icons.lock : Icons.lock_outline,
                      size: 64,
                      color: _isLockedOut
                          ? Colors.red
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    _isLockedOut ? 'Account Locked' : 'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _isLockedOut ? Colors.red : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    _isLockedOut
                        ? 'Too many failed attempts'
                        : 'Enter your PIN to access notes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 48),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _pinController,
                          obscureText: _obscurePin,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          enabled: !_isLockedOut,
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '• • • • • •',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePin
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePin = !_obscurePin;
                                });
                              },
                            ),
                          ),
                          onSubmitted: (_) => _verifyPin(),
                        ),
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: TextStyle(
                              color: _isLockedOut ? Colors.orange : Colors.red,
                              fontSize: 14,
                              fontWeight: _isLockedOut
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLockedOut ? null : _verifyPin,
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isLockedOut
                                  ? 'Locked ($_remainingSeconds s)'
                                  : 'Unlock',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
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