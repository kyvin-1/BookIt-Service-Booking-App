import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/admin_dashboard_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _isAdmin(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data();

      return data?['role'] == 'admin';
    } catch (e) {
      debugPrint('Error checking user role: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase is checking the current login session.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // No user is logged in.
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final User user = snapshot.data!;

        return FutureBuilder<bool>(
          future: _isAdmin(user),
          builder: (context, adminSnapshot) {
            // Checking the user's role.
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final bool isAdmin = adminSnapshot.data ?? false;

            // Admin accounts do not require email verification.
            if (isAdmin) {
              return const AdminDashboardScreen();
            }

            // Normal users must verify their email.
            if (!user.emailVerified) {
              return const VerifyEmailScreen();
            }

            // Normal verified user.
            return const DashboardScreen();
          },
        );
      },
    );
  }
}