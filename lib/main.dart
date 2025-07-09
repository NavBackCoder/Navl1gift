import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Important!
import 'firebase_options.dart';
import 'wrappers/auth_wrapper.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(Naval1GiftyApp());
}

class Naval1GiftyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naval1Gifty',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.teal,
      ),
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          final args = settings.arguments as Map<String, dynamic>;
          final user = args['user'] as User;
          return MaterialPageRoute(
            builder: (_) => DashboardScreen(user: user),
          );
        }
        return null;
      },
    );
  }
}
