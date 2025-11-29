import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';

class ActivityDetector extends StatelessWidget {
  final Widget child;

  const ActivityDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => AppLockService.instance.onUserActivity(),
      onPointerMove: (_) => AppLockService.instance.onUserActivity(),
      onPointerUp: (_) => AppLockService.instance.onUserActivity(),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}