import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/notes_list_screen.dart';
import 'widgets/lock_wrapper.dart';
import 'services/app_lock_service.dart';
import 'services/theme_service.dart';

// Light Theme
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue.shade700,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.blue.shade700,
    foregroundColor: Colors.white,
  ),
);

// Dark Theme
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1F1F1F),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  ),
);
void main() {
  AppLockService.instance.setNavigatorKey(AppNavigator.navigatorKey);
  runApp(const SecureNotesApp());
}



@override
class SecureNotesApp extends StatelessWidget {
const SecureNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, child) {
        return MaterialApp(
          title: 'Secure Notes',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeService.instance.themeMode,
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
      },
    );
  }
}


class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}