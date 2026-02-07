import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/pin_service.dart';
import '../services/theme_service.dart';
import '../services/app_lock_service.dart';
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
            content: Text('Auto-lock set to ${_formatDuration(result)}'),
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
      trailing: isSelected 
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) 
          : null,
      selected: isSelected,
      onTap: () => Navigator.of(context).pop(seconds),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return 'Never';
    if (seconds < 60) return '$seconds seconds';
    return '${seconds ~/ 60} minute${seconds ~/ 60 > 1 ? 's' : ''}';
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
            content: Text('PIN removed successfully'),
            backgroundColor: Colors.green,
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
            'SafeNotes Privacy Policy\n\n'
            'Your Privacy Matters\n\n'
            'SafeNotes is designed with your privacy as the top priority. '
            'All your notes are stored locally on your device and encrypted '
            'using industry-standard AES-256 encryption.\n\n'
            'Data Storage:\n'
            '• All notes are stored locally on your device\n'
            '• Database is encrypted with SQLCipher\n'
            '• No cloud synchronization\n'
            '• No data is sent to external servers\n\n'
            'Biometric Data:\n'
            '• Biometric authentication is handled by your device\'s secure hardware\n'
            '• No biometric data is stored by SafeNotes\n'
            '• Authentication stays on your device\n\n'
            'PIN Security:\n'
            '• PIN is hashed using SHA-256\n'
            '• Only the hash is stored, never the actual PIN\n'
            '• Stored in secure platform keychain\n\n'
            'No Tracking:\n'
            '• No analytics or tracking\n'
            '• No advertisements\n'
            '• No third-party services\n\n'
            'Data Deletion:\n'
            '• Uninstalling the app permanently deletes all data\n'
            '• No backups are kept\n\n'
            'Your data stays yours. Always.',
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
        ),
        body: ListView(
          children: [
            // Security Section
            _buildSectionHeader('Security'),
            
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Auto-lock Duration'),
              subtitle: Text(_formatDuration(_lockDuration)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _updateLockDuration,
            ),

            if (_isPinSet)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Change PIN'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PinSetupScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadSettings();
                  }
                },
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
                    MaterialPageRoute(
                      builder: (context) => const PinSetupScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadSettings();
                  }
                },
              ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Lock App Now'),
              subtitle: const Text('Immediately lock the app'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                AppLockService.instance.lock();
              },
            ),

            // Appearance Section
            const Divider(height: 32),
            _buildSectionHeader('Appearance'),
            
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              subtitle: Text(_theme == 'system' 
                  ? 'System Default' 
                  : _theme == 'dark' 
                      ? 'Enabled' 
                      : 'Disabled'),
              value: _theme == 'dark',
              onChanged: (value) async {
                final newTheme = value ? 'dark' : 'light';
                await ThemeService.instance.setTheme(newTheme);
                setState(() {
                  _theme = newTheme;
                });
              },
            ),

            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Theme'),
              subtitle: Text(_getThemeName(_theme)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Choose Theme'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildThemeOption('light', 'Light', Icons.light_mode),
                        _buildThemeOption('dark', 'Dark', Icons.dark_mode),
                        _buildThemeOption('system', 'System Default', Icons.settings_suggest),
                      ],
                    ),
                  ),
                );

                if (result != null) {
                  await ThemeService.instance.setTheme(result);
                  setState(() {
                    _theme = result;
                  });
                }
              },
            ),

            // About Section
            const Divider(height: 32),
            _buildSectionHeader('About'),
            
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('App Version'),
              subtitle: const Text('1.0.0'),
            ),

            ListTile(
              leading: const Icon(Icons.code_outlined),
              title: const Text('Developers'),
              subtitle: const Text('University of Bahrain\nSenior Project Team'),
            ),

            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showPrivacyPolicy,
            ),

            const SizedBox(height: 32),
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
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildThemeOption(String value, String label, IconData icon) {
    final isSelected = _theme == value;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: isSelected 
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) 
          : null,
      selected: isSelected,
      onTap: () => Navigator.of(context).pop(value),
    );
  }

  String _getThemeName(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System Default';
    }
  }
}