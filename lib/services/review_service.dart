import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');

  // =========================================================
  // GET PROVIDER REVIEWS
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getProviderReviews(
    String providerId,
  ) {
    return _reviews
        .where(
          'providerId',
          isEqualTo: providerId,
        )
        .snapshots();
  }

  // =========================================================
  // GET CUSTOMER NAME
  // =========================================================

  Future<String> _getCustomerName(User user) async {
    try {
      final userSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userSnapshot.data();

      if (userData != null) {
        final firestoreName =
            (userData['name'] ?? userData['displayName'] ?? '')
                .toString()
                .trim();

        if (firestoreName.isNotEmpty) {
          return firestoreName;
        }
      }
    } catch (_) {
      // If Firestore name cannot be loaded,
      // continue with Firebase Auth display name.
    }

    final authName = (user.displayName ?? '').trim();

    if (authName.isNotEmpty) {
      return authName;
    }

    return 'Customer';
  }

  // =========================================================
  // CHECK IF CUSTOMER ALREADY REVIEWED BOOKING
  // =========================================================

  Future<bool> hasReviewed(
    String bookingId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final snapshot = await _reviews
        .where(
          'bookingId',
          isEqualTo: bookingId,
        )
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (data['userId'] == user.uid) {
        return true;
      }
    }

    return false;
  }

  // =========================================================
  // GET REVIEW BY BOOKING
  // =========================================================

Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
    getReviewByBookingId(String bookingId) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return null;
  }

  final snapshot = await _firestore
      .collection('reviews')
      .where('bookingId', isEqualTo: bookingId)
      .where('userId', isEqualTo: user.uid)
      .limit(1)
      .get();

  if (snapshot.docs.isEmpty) {
    return null;
  }

  return snapshot.docs.first;
}

  // =========================================================
  // CREATE REVIEW
  // =========================================================

  Future<void> addReview({
    required String bookingId,
    required String providerId,
    required String providerName,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to submit a review.',
      );
    }

    if (rating < 1 || rating > 5) {
      throw Exception(
        'Rating must be between 1 and 5 stars.',
      );
    }

    if (comment.trim().isEmpty) {
      throw Exception(
        'Please write a comment.',
      );
    }

    // =======================================================
    // GET CUSTOMER NAME
    // =======================================================

    final customerName = await _getCustomerName(user);

    // =======================================================
    // CHECK BOOKING
    // =======================================================

    final bookingSnapshot = await _firestore
        .collection('bookings')
        .doc(bookingId)
        .get();

    if (!bookingSnapshot.exists) {
      throw Exception(
        'Booking not found.',
      );
    }

    final bookingData = bookingSnapshot.data();

    if (bookingData == null) {
      throw Exception(
        'Booking information is unavailable.',
      );
    }

    // =======================================================
    // VERIFY BOOKING BELONGS TO CUSTOMER
    // =======================================================

    if (bookingData['userId'] != user.uid) {
      throw Exception(
        'You can only review your own booking.',
      );
    }

    // =======================================================
    // VERIFY COMPLETED STATUS
    // =======================================================

    final status = (bookingData['status'] ?? '')
        .toString()
        .toLowerCase();

    if (status != 'completed') {
      throw Exception(
        'You can only review a completed booking.',
      );
    }

    // =======================================================
    // VERIFY PROVIDER
    // =======================================================

    if (bookingData['providerId'] != providerId) {
      throw Exception(
        'Provider information does not match the booking.',
      );
    }

    // =======================================================
    // PREVENT DUPLICATE REVIEW
    // =======================================================

    final existingReview = await _reviews
        .where(
          'bookingId',
          isEqualTo: bookingId,
        )
        .get();

    for (final doc in existingReview.docs) {
      if (doc.data()['userId'] == user.uid) {
        throw Exception(
          'You have already reviewed this booking.',
        );
      }
    }

    // =======================================================
    // CREATE REVIEW
    // =======================================================

    await _reviews.add({
      'userId': user.uid,

      // Customer information
      'userName': customerName,
      'userEmail': user.email ?? 'Customer',

      // Booking information
      'bookingId': bookingId,

      // Provider information
      'providerId': providerId,
      'providerName': providerName,

      // Service information
      'service': bookingData['service'] ?? 'Service',

      // Review information
      'rating': rating,
      'comment': comment.trim(),

      // Timestamp
      'createdAt': FieldValue.serverTimestamp(),

      // Updated timestamp
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // UPDATE REVIEW
  // =========================================================

  Future<void> updateReview({
    required String reviewId,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to update your review.',
      );
    }

    // =======================================================
    // VALIDATE RATING
    // =======================================================

    if (rating < 1 || rating > 5) {
      throw Exception(
        'Rating must be between 1 and 5 stars.',
      );
    }

    // =======================================================
    // VALIDATE COMMENT
    // =======================================================

    final trimmedComment = comment.trim();

    if (trimmedComment.isEmpty) {
      throw Exception(
        'Please write a comment.',
      );
    }

    // =======================================================
    // GET REVIEW
    // =======================================================

    final reviewSnapshot = await _reviews
        .doc(reviewId)
        .get();

    if (!reviewSnapshot.exists) {
      throw Exception(
        'Review not found.',
      );
    }

    final reviewData = reviewSnapshot.data();

    if (reviewData == null) {
      throw Exception(
        'Review information is unavailable.',
      );
    }

    // =======================================================
    // VERIFY REVIEW OWNER
    // =======================================================

    if (reviewData['userId'] != user.uid) {
      throw Exception(
        'You can only edit your own review.',
      );
    }

    // =======================================================
    // UPDATE REVIEW
    // =======================================================

    await _reviews
        .doc(reviewId)
        .update({
      'rating': rating,
      'comment': trimmedComment,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // DELETE REVIEW
  // =========================================================

  Future<void> deleteReview(
    String reviewId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    final review = await _reviews
        .doc(reviewId)
        .get();

    if (!review.exists) {
      throw Exception(
        'Review not found.',
      );
    }

    final data = review.data();

    if (data == null) {
      throw Exception(
        'Review information is unavailable.',
      );
    }

    if (data['userId'] != user.uid) {
      throw Exception(
        'You can only delete your own review.',
      );
    }

    await _reviews
        .doc(reviewId)
        .delete();
  }
}