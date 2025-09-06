import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'package:todo_assignment/screens/home/home_page.dart';
import 'package:todo_assignment/core/services/fcm_servisec.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          // Re-initialize FCM to ensure token is saved for current user
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FcmService().init();
          });
          
          return const HomePage(); 
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
