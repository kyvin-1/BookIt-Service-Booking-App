import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // ============================================================
  // EMAIL / PASSWORD REGISTER
  // ============================================================

  Future<User?> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;

      if (user != null) {
        // Save name to Firebase Authentication.
        if (name != null && name.trim().isNotEmpty) {
          await user.updateDisplayName(name.trim());
        }

        // Send email verification.
        await user.sendEmailVerification();

        // Create Firestore user document.
        await _createOrUpdateUserDocument(
          user,
          name: name,
        );

        // Save FCM token for this user.
        await NotificationService.saveCurrentUserToken();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    }
  }

  // ============================================================
  // EMAIL / PASSWORD LOGIN
  // ============================================================

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;

      if (user != null) {
        // Refresh the user so emailVerified has the latest value.
        await user.reload();

        final refreshedUser = _auth.currentUser;

        if (refreshedUser != null) {
          await _createOrUpdateUserDocument(
            refreshedUser,
          );

          // Save FCM token for this user.
          await NotificationService.saveCurrentUserToken();

          return refreshedUser;
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    }
  }

  // ============================================================
  // GOOGLE SIGN-IN
  // ============================================================

  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('==============================');
      debugPrint('GOOGLE SIGN-IN START');

      await _googleSignIn.initialize(
        serverClientId:
            '567767359710-9v9cid596619qp2oqiesiaephqstb3vb.apps.googleusercontent.com',
      );

      debugPrint('Google Sign-In initialized');

      final googleUser =
          await _googleSignIn.authenticate();

      debugPrint(
        'Google account selected: ${googleUser.email}',
      );

      final googleAuth = googleUser.authentication;

      debugPrint(
        'Google ID token received: ${googleAuth.idToken != null}',
      );

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      debugPrint('Firebase credential created');

      final userCredential =
          await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      debugPrint('Firebase Google login successful');
      debugPrint('Firebase UID: ${user?.uid}');

      if (user != null) {
        debugPrint(
          'Creating/updating Firestore user document...',
        );

        await _createOrUpdateUserDocument(
          user,
          name: googleUser.displayName,
          photoUrl: googleUser.photoUrl,
        );

        debugPrint(
          'Firestore user document successful',
        );

        // Save FCM token for Google user.
        await NotificationService.saveCurrentUserToken();

        debugPrint(
          'FCM token saved for Google user',
        );
      }

      debugPrint('GOOGLE SIGN-IN COMPLETE');
      debugPrint('==============================');

      return user;
    } on GoogleSignInException catch (e) {
      debugPrint('==============================');
      debugPrint('GOOGLE SIGN-IN ERROR');
      debugPrint('CODE: ${e.code}');
      debugPrint('DESCRIPTION: ${e.description}');
      debugPrint('DETAILS: ${e.details}');
      debugPrint('==============================');

      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }

      throw Exception(
        'Google Sign-In failed: ${e.description ?? e.code}',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('==============================');
      debugPrint('FIREBASE AUTH ERROR');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('==============================');

      throw Exception(
        'Firebase login failed: ${e.message ?? e.code}',
      );
    } on FirebaseException catch (e) {
      debugPrint('==============================');
      debugPrint('FIRESTORE/FIREBASE ERROR');
      debugPrint('PLUGIN: ${e.plugin}');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('==============================');

      throw Exception(
        'Database error: ${e.message ?? e.code}',
      );
    } catch (e, stackTrace) {
      debugPrint('==============================');
      debugPrint('GOOGLE SIGN-IN UNEXPECTED ERROR');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('==============================');

      throw Exception(
        'Google Sign-In failed: $e',
      );
    }
  }

  // ============================================================
  // SEND EMAIL VERIFICATION
  // ============================================================

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception(
          'No signed-in account was found.',
        );
      }

      if (user.emailVerified) {
        return;
      }

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    }
  }

  // ============================================================
  // CHECK EMAIL VERIFICATION
  // ============================================================

  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return false;
      }

      await user.reload();

      final refreshedUser = _auth.currentUser;

      return refreshedUser?.emailVerified ?? false;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    }
  }

  // ============================================================
  // CREATE / UPDATE FIRESTORE USER DOCUMENT
  // ============================================================

  Future<void> _createOrUpdateUserDocument(
    User user, {
    String? name,
    String? photoUrl,
  }) async {
    final userRef = _firestore
        .collection('users')
        .doc(user.uid);

    final userSnapshot = await userRef.get();

    final existingData = userSnapshot.data();

    // Use provided name first.
    // Otherwise use Firebase Auth displayName.
    // Otherwise use default name.
    final userName =
        name?.trim().isNotEmpty == true
            ? name!.trim()
            : user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : 'BookIt User';

    // Use provided photo first.
    // Otherwise use Firebase Auth photo.
    final userPhoto =
        photoUrl?.trim().isNotEmpty == true
            ? photoUrl!.trim()
            : user.photoURL;

    final Map<String, dynamic> userData = {
      'name': userName,
      'email': user.email ?? '',
      'photoUrl': userPhoto,
      'role': existingData?['role'] ?? 'user',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only create createdAt for a brand-new user.
    if (!userSnapshot.exists) {
      userData['createdAt'] =
          FieldValue.serverTimestamp();
    }

    await userRef.set(
      userData,
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> resetPassword({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _auth.signOut();

    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google sign-out errors.
    }
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  // ============================================================
  // FIREBASE ERROR MESSAGES
  // ============================================================

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
        return 'Incorrect password.';

      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'operation-not-allowed':
        return 'This authentication method is not enabled.';

      default:
        return 'Authentication failed. Please try again.';
    }
  }
}