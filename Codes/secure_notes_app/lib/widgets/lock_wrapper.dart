import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';

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
      _lockService.lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _lockService.onUserActivity(),
      onPointerMove: (_) => _lockService.onUserActivity(),
      onPointerUp: (_) => _lockService.onUserActivity(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}