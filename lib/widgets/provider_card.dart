import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/provider_model.dart';
import '../services/favorite_service.dart';
import '../services/review_service.dart';

class ProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final VoidCallback onTap;

  const ProviderCard({
    super.key,
    required this.provider,
    required this.onTap,
  });

  // =========================================================
  // DYNAMIC RATING
  // =========================================================

  Widget _buildRating() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ReviewService().getProviderReviews(provider.id),
      builder: (context, snapshot) {
        double rating = provider.rating;
        int reviewCount = provider.reviewCount;

        if (snapshot.hasData) {
          final reviews = snapshot.data!.docs;

          if (reviews.isNotEmpty) {
            double totalRating = 0;

            for (final review in reviews) {
              final data = review.data();

              final reviewRating =
                  (data['rating'] as num?)?.toDouble() ?? 0;

              totalRating += reviewRating;
            }

            rating = totalRating / reviews.length;
            reviewCount = reviews.length;
          }
        }

        final reviewText =
            reviewCount == 1 ? '1 review' : '$reviewCount reviews';

        return Row(
          children: [
            const Icon(
              Icons.star_rounded,
              color: Colors.amber,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF343A36),
              ),
            ),
            const SizedBox(width: 3),
            Text(
              '($reviewText)',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF7A817D),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // PROVIDER IMAGE
  // =========================================================

  Widget _buildProviderImage() {
    final imageSource = provider.resolvedImageUrl;

    if (imageSource.isEmpty) {
      return _buildImagePlaceholder();
    }

    if (imageSource.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          imageSource,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _buildImagePlaceholder();
          },
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.asset(
        imageSource,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _buildImagePlaceholder();
        },
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.business_rounded,
        color: Color(0xFF1D8F5A),
        size: 34,
      ),
    );
  }

  // =========================================================
  // FAVORITE BUTTON
  // =========================================================

  Widget _buildFavoriteButton() {
    return StreamBuilder<bool>(
      stream: FavoriteService().isFavorite(provider.id),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;

        return Material(
          color: isFavorite
              ? Colors.red.withValues(alpha: 0.10)
              : const Color(0xFFE9F7EF),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              try {
                await FavoriteService().toggleFavorite(
                  provider,
                  isFavorite,
                );

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFavorite
                          ? 'Removed from favorites.'
                          : 'Added to favorites.',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceFirst(
                            'Exception: ',
                            '',
                          ),
                    ),
                  ),
                );
              }
            },
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite
                    ? Colors.red
                    : const Color(0xFF1D8F5A),
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // SPECIALTY CHIP
  // =========================================================

  Widget _buildSpecialtyChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7EF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        provider.specialty,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF1D8F5A),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // =========================================================
  // SERVICE CHIPS
  // =========================================================

  Widget _buildServices() {
    if (provider.servicesOffered.isEmpty) {
      return const SizedBox.shrink();
    }

    final services =
        provider.servicesOffered.take(2).toList();

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: services.map((service) {
        return Container(
          constraints: const BoxConstraints(
            maxWidth: 120,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            service,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF5F6762),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.045,
                ),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // IMAGE
              // =================================================

              _buildProviderImage(),

              const SizedBox(width: 14),

              // =================================================
              // INFORMATION
              // =================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // Name + Favorite
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            provider.name,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.15,
                              fontWeight:
                                  FontWeight.w800,
                              color: Color(0xFF17231D),
                            ),
                          ),
                        ),

                        const SizedBox(width: 7),

                        _buildFavoriteButton(),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Specialty
                    _buildSpecialtyChip(),

                    const SizedBox(height: 8),

                    // Rating
                    _buildRating(),

                    const SizedBox(height: 9),

                    // Services
                    _buildServices(),

                    const SizedBox(height: 11),

                    // Price + Arrow
                    Row(
                      children: [
                        const Text(
                          'Starts at ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7A817D),
                          ),
                        ),

                        Text(
                          '₱${provider.hourlyRate.toInt()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w800,
                            color: Color(0xFF1D8F5A),
                          ),
                        ),

                        const Text(
                          '/hr',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7A817D),
                          ),
                        ),

                        const Spacer(),

                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE9F7EF,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF1D8F5A),
                            size: 17,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}