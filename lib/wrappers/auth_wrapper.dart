import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth_screen.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Delay navigation until after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(
              context,
              '/dashboard',
              arguments: {'user': snapshot.data!},
            );
          });

          // Show temporary loading screen while Navigator runs
          return const Scaffold(
            body: Center(child: Text("Redirecting to Dashboard...")),
          );
        } else {
          return AuthScreen();
        }
      },
    );
  }
}
