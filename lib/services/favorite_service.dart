import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/provider_model.dart';

class FavoriteService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // =========================================================
  // CURRENT USER
  // =========================================================

  User? get currentUser => _auth.currentUser;

  // =========================================================
  // FAVORITE DOCUMENT
  // =========================================================

  DocumentReference<Map<String, dynamic>> _favoriteDoc(
    String providerId,
  ) {
    final user = currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to use favorites.',
      );
    }

    return _firestore
        .collection('favorites')
        .doc('${user.uid}_$providerId');
  }

  // =========================================================
  // CHECK IF FAVORITE
  // =========================================================

  Stream<bool> isFavorite(String providerId) {
    final user = currentUser;

    if (user == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('favorites')
        .doc('${user.uid}_$providerId')
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // =========================================================
  // ADD FAVORITE
  // =========================================================

  Future<void> addFavorite(
    ServiceProvider provider,
  ) async {
    final user = currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to add favorites.',
      );
    }

    await _favoriteDoc(provider.id).set({
      'userId': user.uid,
      'providerId': provider.id,
      'name': provider.name,
      'category': provider.specialty,
      'rating': provider.rating,
      'reviewCount': provider.reviewCount,
      'imageUrl': provider.imageUrl,
      'latitude': provider.latitude,
      'longitude': provider.longitude,
      'servicesOffered': provider.servicesOffered,
      'price': provider.hourlyRate,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // REMOVE FAVORITE
  // =========================================================

  Future<void> removeFavorite(
    String providerId,
  ) async {
    await _favoriteDoc(providerId).delete();
  }

  // =========================================================
  // TOGGLE FAVORITE
  // =========================================================

  Future<void> toggleFavorite(
    ServiceProvider provider,
    bool currentlyFavorite,
  ) async {
    if (currentlyFavorite) {
      await removeFavorite(provider.id);
    } else {
      await addFavorite(provider);
    }
  }

  // =========================================================
  // GET ALL CURRENT USER FAVORITES
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getFavorites() {
    final user = currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('favorites')
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .snapshots();
  }
}