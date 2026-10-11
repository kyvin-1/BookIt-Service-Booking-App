import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/provider_model.dart';
import '../../services/favorite_service.dart';
import '../../widgets/provider_card.dart';
import '../../providers/provider_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const Color primaryGreen = Color(0xFF1D9B61);
  static const Color lightGreen = Color(0xFFE9F7EF);
  static const Color darkText = Color(0xFF17231D);
  static const Color secondaryText = Color(0xFF69736D);
  static const Color backgroundColor = Color(0xFFF5F9F7);

  ServiceProvider _providerFromData(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return ServiceProvider(
      id: data['providerId'] ?? documentId,
      name: data['name'] ?? 'Unknown Provider',
      specialty: data['category'] ?? 'Service Provider',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount:
          (data['reviewCount'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      latitude:
          (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude:
          (data['longitude'] as num?)?.toDouble() ?? 0.0,
      servicesOffered: List<String>.from(
        data['servicesOffered'] ?? [],
      ),
      hourlyRate:
          (data['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  void _openProviderDetails(
    BuildContext context,
    ServiceProvider provider,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProviderDetailsScreen(provider: provider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'My Favorites',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: darkText,
          ),
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FavoriteService().getFavorites(),

        builder: (context, snapshot) {
          // =====================================================
          // ERROR
          // =====================================================

          if (snapshot.hasError) {
            return _buildErrorState(
              context,
              snapshot.error.toString(),
            );
          }

          // =====================================================
          // LOADING
          // =====================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryGreen,
              ),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          // =====================================================
          // EMPTY
          // =====================================================

          if (documents.isEmpty) {
            return _buildEmptyState(context);
          }

          // =====================================================
          // FAVORITES LIST
          // =====================================================

          return RefreshIndicator(
            color: primaryGreen,
            onRefresh: () async {
              await Future.delayed(
                const Duration(milliseconds: 500),
              );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                30,
              ),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF147A4A),
                        Color(0xFF35AD70),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.18,
                          ),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Favorites',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${documents.length} saved provider${documents.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: Colors.white
                                    .withValues(
                                  alpha: 0.85,
                                ),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'Saved Providers',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Quickly access the service providers you saved.',
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryText,
                  ),
                ),

                const SizedBox(height: 14),

                ...documents.map((document) {
                  final provider = _providerFromData(
                    document.data(),
                    document.id,
                  );

                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 14),
                    child: ProviderCard(
                      provider: provider,
                      onTap: () {
                        _openProviderDetails(
                          context,
                          provider,
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================
  // EMPTY STATE
  // ===========================================================

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 48,
                color: primaryGreen,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Save your favorite service providers by tapping '
              'the heart icon on their provider card.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: secondaryText,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.search_rounded,
              ),
              label: const Text(
                'Explore Providers',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // ERROR STATE
  // ===========================================================

  Widget _buildErrorState(
    BuildContext context,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: Colors.red.shade600,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Unable to load favorites',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Something went wrong while loading your '
              'favorite providers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryText,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const FavoritesScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Try Again',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: const BorderSide(
                  color: primaryGreen,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            // Keeps the error variable intentionally available
            // for debugging during development.
            if (error.isNotEmpty)
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}