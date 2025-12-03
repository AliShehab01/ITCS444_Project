import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/env_config.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';
import 'models/user_role.dart';
import 'screens/login_screen.dart';
import 'screens/home/admin_home.dart';
import 'screens/home/renter_home.dart';
import 'screens/home/guest_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase with environment variables
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: EnvConfig.firebaseApiKey,
      projectId: EnvConfig.firebaseProjectId,
      messagingSenderId: EnvConfig.firebaseMessagingSenderId,
      appId: EnvConfig.firebaseAppId,
    ),
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ITCS444 Project',
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
      home: const AuthWrapper(),
    );
  }
}

// Authentication Wrapper to handle user state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in, get their role and navigate accordingly
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: authService.getUserData(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                final user = userSnapshot.data!;

                // Navigate based on user role
                switch (user.role) {
                  case UserRole.admin:
                    return const AdminHome();
                  case UserRole.renter:
                    return const RenterHome();
                  case UserRole.guest:
                    return const GuestHome();
                }
              }

              // If no user data found, go to login
              return const LoginScreen();
            },
          );
        }

        // If not logged in, show login screen
        return const LoginScreen();
      },
    );
  }
}
