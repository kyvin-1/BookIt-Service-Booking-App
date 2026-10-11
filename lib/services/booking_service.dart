import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // =========================================================
  // CREATE BOOKING
  // =========================================================

  Future<String> createBooking({
    required String providerId,
    required String providerName,
    required String service,
    required DateTime dateTime,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to book an appointment.',
      );
    }

    try {
      final doc = await _firestore
          .collection('bookings')
          .add({
        // Customer information
        'userId': user.uid,
        'userEmail': user.email ?? '',

        // Provider information
        'providerId': providerId,
        'providerName': providerName,
        'service': service,

        // Appointment information
        'dateTime': Timestamp.fromDate(dateTime),

        // Booking status
        'status': 'pending',

        // Created timestamp
        'createdAt': FieldValue.serverTimestamp(),
      });

      return doc.id;
    } on FirebaseException catch (e) {
      throw Exception(
        'Failed to create booking: '
        '${e.message ?? e.code}',
      );
    }
  }

  // =========================================================
  // GET CURRENT USER BOOKINGS
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getBookings() {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to view your bookings.',
      );
    }

    return _firestore
        .collection('bookings')
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .orderBy('dateTime')
        .snapshots();
  }

  // =========================================================
  // GET BOOKED TIME SLOTS
  // =========================================================
  //
  // IMPORTANT:
  // This version does NOT use multiple Firestore where()
  // conditions.
  //
  // It gets the provider's bookings first, then Flutter
  // checks the selected date locally.
  //
  // This avoids the composite index requirement for
  // providerId + dateTime.
  // =========================================================

  Future<Set<String>> getBookedTimeSlots({
    required String providerId,
    required DateTime date,
    required List<String> timeSlots,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where(
            'providerId',
            isEqualTo: providerId,
          )
          .get();

      final Set<String> bookedSlots = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Ignore cancelled bookings
        if (data['status'] == 'cancelled') {
          continue;
        }

        final timestamp = data['dateTime'];

        if (timestamp is! Timestamp) {
          continue;
        }

        final bookingDate = timestamp.toDate();

        // Check if booking belongs to the selected date
        final sameDate =
            bookingDate.year == date.year &&
            bookingDate.month == date.month &&
            bookingDate.day == date.day;

        if (!sameDate) {
          continue;
        }

        // Convert booking time to AM/PM format
        final formattedTime =
            _formatTime(bookingDate);

        // Only add valid time slots
        if (timeSlots.contains(formattedTime)) {
          bookedSlots.add(formattedTime);
        }
      }

      return bookedSlots;
    } on FirebaseException catch (e) {
      throw Exception(
        'Failed to check availability: '
        '${e.message ?? e.code}',
      );
    }
  }

  // =========================================================
  // CANCEL BOOKING
  // =========================================================

  Future<void> cancelBooking(
    String bookingId,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'cancelled',
      });
    } on FirebaseException catch (e) {
      throw Exception(
        'Failed to cancel booking: '
        '${e.message ?? e.code}',
      );
    }
  }

  // =========================================================
  // FORMAT TIME
  // =========================================================

  String _formatTime(DateTime date) {
    int hour = date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '$hour:$minute $period';
  }
}