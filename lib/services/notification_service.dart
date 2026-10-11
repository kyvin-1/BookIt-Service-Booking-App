import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static bool _initialized = false;

  // =========================================================
  // BACKGROUND FCM HANDLER
  // =========================================================

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    debugPrint('==========================================');
    debugPrint('BACKGROUND FCM MESSAGE');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');
    debugPrint('==========================================');
  }

  // =========================================================
  // INITIALIZE NOTIFICATIONS
  // =========================================================

  static Future<void> initialize() async {
    // Prevent duplicate initialization.
    if (_initialized) {
      return;
    }

    _initialized = true;

    // -------------------------------------------------------
    // LOCAL NOTIFICATION SETUP
    // -------------------------------------------------------

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
    );

    // -------------------------------------------------------
    // ANDROID NOTIFICATION CHANNEL
    // -------------------------------------------------------

    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
      'bookit_booking_channel',
      'BookIt Booking Notifications',
      description: 'Notifications about BookIt bookings',
      importance: Importance.high,
    );

    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      channel,
    );

    // -------------------------------------------------------
    // REQUEST LOCAL NOTIFICATION PERMISSION
    // -------------------------------------------------------

    await androidPlugin?.requestNotificationsPermission();

    // -------------------------------------------------------
    // FCM PERMISSION
    // -------------------------------------------------------

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      'FCM permission: ${settings.authorizationStatus}',
    );

    // -------------------------------------------------------
    // GET FCM TOKEN
    // -------------------------------------------------------

    final token = await _messaging.getToken();

    debugPrint('==========================================');
    debugPrint('BOOKIT FCM TOKEN');
    debugPrint(token);
    debugPrint('==========================================');

    // -------------------------------------------------------
    // TOKEN REFRESH
    // -------------------------------------------------------

    _messaging.onTokenRefresh.listen(
      (newToken) async {
        debugPrint('==========================================');
        debugPrint('FCM Token refreshed: $newToken');
        debugPrint('==========================================');

        await _saveTokenForCurrentUser(newToken);
      },
    );

    // -------------------------------------------------------
    // FOREGROUND MESSAGE
    // -------------------------------------------------------

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        debugPrint('==========================================');
        debugPrint('FCM MESSAGE RECEIVED');
        debugPrint('Title: ${message.notification?.title}');
        debugPrint('Body: ${message.notification?.body}');
        debugPrint('Data: ${message.data}');
        debugPrint('==========================================');

        final notification = message.notification;

        if (notification != null) {
          await showBookingNotification(
            title: notification.title ?? 'BookIt',
            body: notification.body ?? '',
          );
        }
      },
    );

    // -------------------------------------------------------
    // APP OPENED FROM BACKGROUND NOTIFICATION
    // -------------------------------------------------------

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        debugPrint('Notification opened from background.');

        debugPrint(
          'Notification data: ${message.data}',
        );

        // Future:
        // Navigate to My Bookings here.
      },
    );

    // -------------------------------------------------------
    // APP OPENED FROM TERMINATED STATE
    // -------------------------------------------------------

    final initialMessage =
        await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint(
        'App opened from terminated notification.',
      );

      debugPrint(
        'Notification data: ${initialMessage.data}',
      );

      // Future:
      // Navigate to My Bookings here.
    }
  }

  // =========================================================
  // SAVE CURRENT USER FCM TOKEN
  // =========================================================

  static Future<void> saveCurrentUserToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint(
        'FCM token not saved: no logged-in user.',
      );
      return;
    }

    final token = await _messaging.getToken();

    if (token == null || token.isEmpty) {
      debugPrint(
        'FCM token not saved: token is null or empty.',
      );
      return;
    }

    await _saveTokenForCurrentUser(token);
  }

  // =========================================================
  // SAVE TOKEN TO FIRESTORE
  // =========================================================

  static Future<void> _saveTokenForCurrentUser(
    String token,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint(
        'FCM token refresh received, but no user is logged in.',
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint(
        'FCM token saved for user: ${user.uid}',
      );
    } catch (e) {
      debugPrint(
        'Failed to save FCM token: $e',
      );
    }
  }

  // =========================================================
  // CREATE BOOKING NOTIFICATION
  // =========================================================
  //
  // This creates a notification inside Firestore.
  //
  // Example:
  //
  // Customer receives:
  // "Booking Confirmed"
  // "Your booking with ABC Salon has been confirmed."
  //
  // This is IN-APP notification history.
  // It does NOT send an FCM push by itself.
  //
  // FCM push notifications still require a server-side
  // sender such as Firebase Cloud Functions.
  // =========================================================

  static Future<void> createBookingNotification({
    required String userId,
    required String bookingId,
    required String title,
    required String body,
    required String status,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': 'booking',
        'bookingId': bookingId,
        'status': status,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        'Booking notification created for user: $userId',
      );
    } catch (e) {
      debugPrint(
        'Failed to create booking notification: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // MARK NOTIFICATION AS READ
  // =========================================================

  static Future<void> markAsRead(
    String notificationId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
      });

      debugPrint(
        'Notification marked as read: $notificationId',
      );
    } catch (e) {
      debugPrint(
        'Failed to mark notification as read: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // MARK ALL NOTIFICATIONS AS READ
  // =========================================================

  static Future<void> markAllAsRead(
    String userId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where(
            'userId',
            isEqualTo: userId,
          )
          .get();

      final batch =
          FirebaseFirestore.instance.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['isRead'] != true) {
          batch.update(
            doc.reference,
            {
              'isRead': true,
            },
          );
        }
      }

      await batch.commit();

      debugPrint(
        'All notifications marked as read.',
      );
    } catch (e) {
      debugPrint(
        'Failed to mark all notifications as read: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // DELETE NOTIFICATION
  // =========================================================

  static Future<void> deleteNotification(
    String notificationId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();

      debugPrint(
        'Notification deleted: $notificationId',
      );
    } catch (e) {
      debugPrint(
        'Failed to delete notification: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // SHOW LOCAL NOTIFICATION
  // =========================================================

  static Future<void> showBookingNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'bookit_booking_channel',
      'BookIt Booking Notifications',
      channelDescription:
          'Notifications about BookIt bookings',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .remainder(100000),
      title:title,
      body:body,
      notificationDetails: notificationDetails,
    );
  }
}