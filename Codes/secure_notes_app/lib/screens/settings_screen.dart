import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import '../services/pin_service.dart';
import '../services/preferences_service.dart';
import 'pin_setup_screen.dart';
import '../widgets/activity_detector.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _lockDuration = 30;
  String _theme = 'system';
  bool _isPinSet = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final duration = await PreferencesService.instance.getLockDuration();
    final theme = await PreferencesService.instance.getTheme();
    final isPinSet = await PinService.instance.isPinSet();

    setState(() {
      _lockDuration = duration;
      _theme = theme;
      _isPinSet = isPinSet;
      _isLoading = false;
    });
  }

  Future<void> _updateLockDuration() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-lock Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDurationOption(30, '30 seconds'),
            _buildDurationOption(60, '1 minute'),
            _buildDurationOption(120, '2 minutes'),
            _buildDurationOption(300, '5 minutes'),
            _buildDurationOption(0, 'Never'),
          ],
        ),
      ),
    );

    if (result != null) {
      await PreferencesService.instance.setLockDuration(result);
      AppLockService.instance.updateLockDuration(result);
      setState(() {
        _lockDuration = result;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result == 0 
                ? 'Auto-lock disabled' 
                : 'Auto-lock set to ${_formatDuration(result)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildDurationOption(int seconds, String label) {
    final isSelected = _lockDuration == seconds;
    return ListTile(
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      selected: isSelected,
      onTap: () => Navigator.of(context).pop(seconds),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return 'Never';
    if (seconds < 60) return '$seconds seconds';
    final minutes = seconds ~/ 60;
    return '$minutes minute${minutes > 1 ? 's' : ''}';
  }

  Future<void> _changePin() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PinSetupScreen()),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _removePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PIN'),
        content: const Text(
          'Are you sure you want to remove your backup PIN? '
          'You will only be able to use biometric authentication.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PinService.instance.clearPin();
      setState(() {
        _isPinSet = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN removed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Secure Notes Privacy Policy\n\n'
            '1. Data Storage\n'
            'All your notes are stored locally on your device using encrypted storage (SQLCipher). '
            'We do not collect, transmit, or store your data on any external servers.\n\n'
            '2. Biometric Data\n'
            'Biometric authentication (fingerprint/face) is handled entirely by your device\'s operating system. '
            'We do not access, store, or process your biometric data.\n\n'
            '3. PIN Security\n'
            'Your backup PIN is hashed using SHA-256 and stored securely using platform-specific encryption.\n\n'
            '4. No Tracking\n'
            'We do not use any analytics, tracking, or third-party services. '
            'Your usage of this app is completely private.\n\n'
            '5. Data Deletion\n'
            'Uninstalling the app will permanently delete all your notes and settings from your device.\n\n'
            'Last updated: November 2024',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ActivityDetector(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          children: [
            // Security Section
            _buildSectionHeader('SECURITY'),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Auto-lock Duration'),
              subtitle: Text(_formatDuration(_lockDuration)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _updateLockDuration,
            ),
            if (_isPinSet)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Change PIN'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changePin,
              ),
            if (_isPinSet)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove PIN', style: TextStyle(color: Colors.red)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _removePin,
              ),
            if (!_isPinSet)
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Setup PIN'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const PinSetupScreen()),
                  );
                  if (result == true) {
                    _loadSettings();
                  }
                },
              ),

            const Divider(),

            // Appearance Section
            _buildSectionHeader('APPEARANCE'),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Theme'),
              subtitle: Text(_theme == 'system' 
                  ? 'System Default' 
                  : _theme == 'dark' 
                      ? 'Dark' 
                      : 'Light'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Theme settings coming in next feature!'),
                  ),
                );
              },
            ),

            const Divider(),

            // About Section
            _buildSectionHeader('ABOUT'),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('App Version'),
              subtitle: Text('1.0.0'),
            ),
            const ListTile(
              leading: Icon(Icons.people_outline),
              title: Text('Developers'),
              subtitle: Text('Your Team Name\nUniversity of Bahrain'), // Update with your names
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showPrivacyPolicy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}