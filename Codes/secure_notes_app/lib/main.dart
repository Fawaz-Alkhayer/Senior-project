import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/notes_list_screen.dart';
import 'widgets/lock_wrapper.dart';
import 'services/app_lock_service.dart';
import 'services/theme_service.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'; 

// Light Theme - Dark Blue + Cyan
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF0D47A1), // Dark Blue
    primary: const Color(0xFF0D47A1),
    secondary: const Color(0xFF00BCD4), // Cyan
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A237E), // Navy Blue
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF00BCD4), // Cyan
    foregroundColor: Colors.white,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFF00BCD4), // Cyan
  ),
);

// Dark Theme - Dark Blue + Cyan
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF0D47A1), // Dark Blue
    primary: const Color(0xFF1976D2),
    secondary: const Color(0xFF00E5FF), // Bright Cyan
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A237E), // Navy Blue
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF00BCD4), // Cyan
    foregroundColor: Colors.white,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFF00E5FF), // Bright Cyan
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
          title: 'SafeNotes',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeService.instance.themeMode,
          navigatorKey: AppNavigator.navigatorKey,
          localizationsDelegates: const [
            FlutterQuillLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), 
          ],
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