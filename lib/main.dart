import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/notification_service.dart';

// ViewModels
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/todo_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';

// Pages
import 'views/auth/login_page.dart';
import 'views/todo/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and notifications, but don't crash the app on failure.
  bool firebaseInitialized = true;
  String? initError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize local notifications
    await NotificationService.init();
  } catch (e, st) {
    firebaseInitialized = false;
    initError = e.toString();
    // Print to logs so adb logcat can show the failure
    // ignore: avoid_print
    print('Firebase/Notification init error: $e\n$st');
  }

  if (firebaseInitialized) {
    runApp(const MyApp());
  } else {
    runApp(ErrorApp(message: initError ?? 'Initialization failed'));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(),
        ),
        ChangeNotifierProvider<TodoViewModel>(
          create: (_) => TodoViewModel(),
        ),
        ChangeNotifierProvider<ThemeViewModel>(
          create: (_) => ThemeViewModel(),
        ),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVM, _) {
          const primaryColor = Colors.blue;
          
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Smart Todo',
            // --- LIGHT THEME ---
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: primaryColor,
              brightness: Brightness.light,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            // --- DARK THEME ---
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: primaryColor,
              brightness: Brightness.dark,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            themeMode: themeVM.themeMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

// ================= AUTH STATE HANDLER =================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    // If user is logged in → go to Home
    if (authVM.user != null) {
      return HomePage(uid: authVM.user!.uid);
    }

    // Otherwise → Login
    return const LoginPage();
  }
}

class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Initialization Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}