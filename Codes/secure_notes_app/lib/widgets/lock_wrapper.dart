import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import '../screens/login_screen.dart';

class LockWrapper extends StatefulWidget {
  final Widget child;

  const LockWrapper({super.key, required this.child});

  @override
  State<LockWrapper> createState() => _LockWrapperState();
}

class _LockWrapperState extends State<LockWrapper> with WidgetsBindingObserver {
  final AppLockService _lockService = AppLockService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive) {
      // App went to background - lock it
      _lockService.lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _lockService.onUserActivity(),
      onPanDown: (_) => _lockService.onUserActivity(),
      behavior: HitTestBehavior.translucent,
      child: ListenableBuilder(
        listenable: _lockService,
        builder: (context, child) {
          if (_lockService.isLocked) {
            return const LoginScreen();
          }
          return widget.child;
        },
      ),
    );
  }
}