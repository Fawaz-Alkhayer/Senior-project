import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/notes_list_screen.dart';
import 'widgets/lock_wrapper.dart';
import 'services/app_lock_service.dart';

void main() {
  AppLockService.instance.setNavigatorKey(AppNavigator.navigatorKey);
  runApp(const SecureNotesApp());
}

class SecureNotesApp extends StatelessWidget {
  const SecureNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      navigatorKey: AppNavigator.navigatorKey,
      home: LockWrapper(
        child: ListenableBuilder(
          listenable: AppLockService.instance,
          builder: (context, child) {
            if (AppLockService.instance.isLocked) {
              return const LoginScreen();
            }
            return const NotesListScreen();
          },
        ),
      ),
    );
  }
}

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}