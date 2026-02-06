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
        builder: (context, themeVM, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart Todo',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
          ),
          darkTheme: ThemeData.dark().copyWith(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          themeMode: themeVM.themeMode,
          home: const AuthWrapper(),
        ),
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
