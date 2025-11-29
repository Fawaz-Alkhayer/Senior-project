import 'dart:async';
import 'package:flutter/material.dart';
//imports 

class AppLockService extends ChangeNotifier {
  static final AppLockService instance = AppLockService._init();
  
  AppLockService._init();

  bool _isLocked = true;
  Timer? _lockTimer;
  Duration _lockDuration = const Duration(seconds: 30);

  bool get isLocked => _isLocked;

  void unlock() {
    _isLocked = false;
    _resetTimer();
    notifyListeners();
  }

  void lock() {
    _isLocked = true;
    _lockTimer?.cancel();
    notifyListeners();
  }

  void _resetTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer(_lockDuration, () {
      lock();
    });
  }

  void onUserActivity() {
    if (!_isLocked) {
      _resetTimer();
    }
  }

  void updateLockDuration(int seconds) {
    if (seconds == 0) {
      _lockTimer?.cancel();
      _lockDuration = const Duration(days: 365);
    } else {
      _lockDuration = Duration(seconds: seconds);
    }
    
    if (!_isLocked) {
      _resetTimer();
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }
}