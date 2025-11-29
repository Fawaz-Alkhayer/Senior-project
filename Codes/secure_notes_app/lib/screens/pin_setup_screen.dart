import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import '../widgets/activity_detector.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _setupPin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.isEmpty) {
      _showError('Please enter a PIN');
      return;
    }

    if (pin.length < 4) {
      _showError('PIN must be at least 4 digits');
      return;
    }

    if (pin != confirm) {
      _showError('PINs do not match');
      return;
    }

    try {
      await PinService.instance.setPin(pin);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ActivityDetector(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Setup Backup PIN'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.pin_outlined,
                size: 80,
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 30),
              const Text(
                'Create a Backup PIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This PIN can be used as an alternative to biometric authentication',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _pinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Enter PIN',
                  hintText: 'At least 4 digits',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePin = !_obscurePin;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Confirm PIN',
                  hintText: 'Re-enter your PIN',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _setupPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Set PIN',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}