import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register Firebase Cloud Messaging background handler
  FirebaseMessaging.onBackgroundMessage(
    NotificationService.firebaseMessagingBackgroundHandler,
  );

  // Initialize local notifications + FCM
  await NotificationService.initialize();

  runApp(
    const ProviderScope(
      child: BookItApp(),
    ),
  );
}

class BookItApp extends StatelessWidget {
  const BookItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookIt',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      // Keep your existing authentication flow
      home: const AuthGate(),
    );
  }
}