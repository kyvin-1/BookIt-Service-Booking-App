import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/provider_model.dart';

final firestoreProvidersProvider =
    StreamProvider<List<ServiceProvider>>((ref) {
  return FirebaseFirestore.instance
      .collection('providers')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final name = data['name'] as String? ?? 'Unknown Provider';
      final specialty = data['category'] as String? ?? 'Service Provider';
      final fallbackImageUrl =
          ServiceProvider.defaultImageForCategory(name, specialty);
      final imageUrl =
          (data['imageUrl'] as String? ?? '').trim().isNotEmpty
              ? (data['imageUrl'] as String? ?? '')
              : fallbackImageUrl;

      return ServiceProvider(
        id: doc.id,
        name: name,
        specialty: specialty,
        rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
        imageUrl: imageUrl,
        latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
        servicesOffered:
            List<String>.from(data['servicesOffered'] ?? []),
        hourlyRate: (data['price'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  });
});