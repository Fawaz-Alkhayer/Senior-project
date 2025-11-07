import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/notes_list_screen.dart';
import 'widgets/lock_wrapper.dart';
import 'services/app_lock_service.dart';

void main() {
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
      home: ListenableBuilder(
        listenable: AppLockService.instance,
        builder: (context, child) {
          if (AppLockService.instance.isLocked) {
            return const LoginScreen();
          }
          return const LockWrapper(child: NotesListScreen());
        },
      ),
    );
  }
}