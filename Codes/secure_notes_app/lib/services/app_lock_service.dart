import 'dart:async';
import 'package:flutter/material.dart';

class AppLockService extends ChangeNotifier {
  static final AppLockService instance = AppLockService._init();
  
  AppLockService._init();

  bool _isLocked = true;
  Timer? _timer;
  int _lockDuration = 120;
  bool _isPaused = false;
  GlobalKey<NavigatorState>? _navigatorKey;
  

  bool get isLocked => _isLocked;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void unlock() {
    _isLocked = false;
    _resetTimer();
    notifyListeners();
  }

  void lock() {
    _isLocked = true;
    _timer?.cancel();
    
    if (_navigatorKey?.currentState != null) {
      _navigatorKey!.currentState!.popUntil((route) => route.isFirst);
    }
    
    notifyListeners();
  }

  void _resetTimer() {
    _timer?.cancel();
    
    // Don't start timer if paused
    if (_isPaused) {
      return;
    }
    
    if (_lockDuration > 0 && !_isLocked) {
      _timer = Timer(Duration(seconds: _lockDuration), () {
        lock();
      });
    }
  }

  void onUserActivity() {
    if (!_isLocked) {
      _resetTimer();
    }
  }

  void updateLockDuration(int seconds) {
    if (seconds == 0) {
      _timer?.cancel();
      _lockDuration = 0;
    } else {
      _lockDuration = seconds;
    }
    _resetTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void pauseAutoLock() {
    _isPaused = true;
    _timer?.cancel();
  }

  void resumeAutoLock() {
    _isPaused = false;
    _resetTimer();
  }
}