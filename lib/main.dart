import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/notification_service.dart';

// ViewModels
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/todo_viewmodel.dart';

// Pages
import 'views/auth/login_page.dart';
import 'views/todo/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local notifications
  await NotificationService.init();

  runApp(const MyApp());
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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Todo',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
        ),
        home: const AuthWrapper(),
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
