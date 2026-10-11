import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/provider_model.dart';
import '../services/favorite_service.dart';
import '../services/review_service.dart';
import '../screens/booking/booking_screen.dart';

class ProviderDetailsScreen extends StatelessWidget {
  final ServiceProvider provider;

  const ProviderDetailsScreen({
    super.key,
    required this.provider,
  });

  static const Color primaryGreen = Color(0xFF1D8F5A);
  static const Color lightGreen = Color(0xFFE9F7EF);
  static const Color darkText = Color(0xFF17231D);
  static const Color secondaryText = Color(0xFF69736D);
  static const Color background = Color(0xFFF7FAF8);

  // =========================================================
  // RATING STARS
  // =========================================================

  Widget _buildStars(
    double rating, {
    double size = 17,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (rating >= index + 1) {
          return Icon(
            Icons.star_rounded,
            color: Colors.amber.shade600,
            size: size,
          );
        }

        if (rating >= index + 0.5) {
          return Icon(
            Icons.star_half_rounded,
            color: Colors.amber.shade600,
            size: size,
          );
        }

        return Icon(
          Icons.star_border_rounded,
          color: Colors.amber.shade600,
          size: size,
        );
      }),
    );
  }

  // =========================================================
  // PROVIDER IMAGE
  // =========================================================

  Widget _buildProviderImage() {
    final image = provider.resolvedImageUrl;

    if (image.isEmpty) {
      return _buildImagePlaceholder();
    }

    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        loadingBuilder: (
          context,
          child,
          progress,
        ) {
          if (progress == null) {
            return child;
          }

          return Container(
            height: 300,
            color: lightGreen,
            child: const Center(
              child: CircularProgressIndicator(
                color: primaryGreen,
              ),
            ),
          );
        },
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _buildImagePlaceholder();
        },
      );
    }

    return Image.asset(
      image,
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return _buildImagePlaceholder();
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 300,
      color: lightGreen,
      child: const Icon(
        Icons.business_rounded,
        color: primaryGreen,
        size: 72,
      ),
    );
  }

  // =========================================================
  // CIRCLE BUTTON
  // =========================================================

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: darkText,
            size: 21,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // FAVORITE
  // =========================================================

  Widget _buildFavoriteButton() {
    return StreamBuilder<bool>(
      stream: FavoriteService().isFavorite(
        provider.id,
      ),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;

        return _circleButton(
          icon: isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
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
        );
      },
    );
  }

  // =========================================================
  // RATING SUMMARY
  // =========================================================

  Widget _buildRatingSummary() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ReviewService().getProviderReviews(
        provider.id,
      ),
      builder: (context, snapshot) {
        final reviews = snapshot.data?.docs ?? [];

        if (reviews.isEmpty) {
          return Row(
            children: [
              _buildStars(0),
              const SizedBox(width: 8),
              Text(
                'No reviews yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }

        double total = 0;

        for (final review in reviews) {
          total +=
              (review.data()['rating'] as num?)
                      ?.toDouble() ??
                  0;
        }

        final average = total / reviews.length;

        return Row(
          children: [
            _buildStars(
              average,
              size: 19,
            ),
            const SizedBox(width: 8),
            Text(
              average.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              reviews.length == 1
                  ? '1 review'
                  : '${reviews.length} reviews',
              style: const TextStyle(
                fontSize: 12,
                color: secondaryText,
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // QUICK INFO
  // =========================================================

  Widget _infoItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 7,
        ),
        decoration: BoxDecoration(
          color: lightGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: primaryGreen,
              size: 21,
            ),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: darkText,
      ),
    );
  }

  // =========================================================
  // SERVICES
  // =========================================================

  Widget _buildServices() {
    if (provider.servicesOffered.isEmpty) {
      return Text(
        'No services listed.',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: provider.servicesOffered.map((service) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primaryGreen.withValues(
                alpha: 0.16,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: primaryGreen,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                service,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =========================================================
  // PRICE
  // =========================================================

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryGreen.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: primaryGreen,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Starting price',
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Service rate',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₱${provider.hourlyRate.toInt()}',
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: primaryGreen,
            ),
          ),
          const Text(
            '/hr',
            style: TextStyle(
              fontSize: 11,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // REVIEW DATE
  // =========================================================

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return '';
    }

    final date = value.toDate();

    return '${date.month}/${date.day}/${date.year}';
  }

  // =========================================================
  // REVIEWS
  // =========================================================

  Widget _buildReviews() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ReviewService().getProviderReviews(
        provider.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                color: primaryGreen,
              ),
            ),
          );
        }

        final reviews = [
          ...(snapshot.data?.docs ?? []),
        ];

        reviews.sort((a, b) {
          final aTime = a.data()['createdAt'];
          final bTime = b.data()['createdAt'];

          if (aTime is! Timestamp ||
              bTime is! Timestamp) {
            return 0;
          }

          return bTime.compareTo(aTime);
        });

        if (reviews.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 42,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 10),
                const Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Customer reviews will appear here.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: reviews.map((review) {
            final data = review.data();

            final customerName =
                (data['userName'] ?? '').toString().trim();

            final email =
                data['userEmail']?.toString() ??
                    'Customer';

            final displayName = customerName.isNotEmpty
                ? customerName
                : email;

            final rating =
                (data['rating'] as num?)
                        ?.toDouble() ??
                    0;

            final comment =
                data['comment']?.toString() ?? '';

            final date = _formatDate(
              data['createdAt'],
            );

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(
                bottom: 12,
              ),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration:
                            const BoxDecoration(
                          color: lightGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: darkText,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                _buildStars(
                                  rating,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  rating.toStringAsFixed(
                                    1,
                                  ),
                                  style:
                                      const TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (date.isNotEmpty)
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      comment,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 105,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // =================================================
                // HERO
                // =================================================

                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      child: _buildProviderImage(),
                    ),

                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(
                                  alpha: 0.22,
                                ),
                                Colors.transparent,
                                Colors.black.withValues(
                                  alpha: 0.08,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 18,
                      left: 16,
                      child: SafeArea(
                        child: _circleButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),

                    Positioned(
                      top: 18,
                      right: 16,
                      child: SafeArea(
                        child: _buildFavoriteButton(),
                      ),
                    ),
                  ],
                ),

                // =================================================
                // INFORMATION
                // =================================================

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    22,
                    20,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 27,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: darkText,
                        ),
                      ),

                      const SizedBox(height: 9),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.work_outline_rounded,
                              color: primaryGreen,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              provider.specialty,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 13),

                      _buildRatingSummary(),

                      const SizedBox(height: 22),

                      // =================================================
                      // QUICK INFO
                      // =================================================

                      Row(
                        children: [
                          _infoItem(
                            icon: Icons.schedule_rounded,
                            title: 'Flexible',
                            subtitle: 'Schedule',
                          ),
                          const SizedBox(width: 8),
                          _infoItem(
                            icon: Icons.verified_rounded,
                            title: 'Trusted',
                            subtitle: 'Provider',
                          ),
                          const SizedBox(width: 8),
                          _infoItem(
                            icon: Icons.flash_on_rounded,
                            title: 'Fast',
                            subtitle: 'Booking',
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // =================================================
                      // ABOUT
                      // =================================================

                      _sectionTitle(
                        'About this provider',
                      ),

                      const SizedBox(height: 9),

                      Text(
                        'Professional ${provider.specialty.toLowerCase()} '
                        'service provider available for your booking needs. '
                        'Book a trusted professional through BookIt and '
                        'choose a schedule that works for you.',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: secondaryText,
                        ),
                      ),

                      const SizedBox(height: 29),

                      // =================================================
                      // SERVICES
                      // =================================================

                      _sectionTitle(
                        'Services offered',
                      ),

                      const SizedBox(height: 12),

                      _buildServices(),

                      const SizedBox(height: 29),

                      // =================================================
                      // PRICE
                      // =================================================

                      _buildPriceCard(),

                      const SizedBox(height: 30),

                      // =================================================
                      // REVIEWS
                      // =================================================

                      Row(
                        children: [
                          Expanded(
                            child: _sectionTitle(
                              'Customer Reviews',
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration:
                                const BoxDecoration(
                              color: lightGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.rate_review_outlined,
                              color: primaryGreen,
                              size: 18,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 13),

                      _buildReviews(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // =========================================================
          // BOOK NOW BAR
          // =========================================================

          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BookingScreen(
                            provider: provider,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                    ),
                    label: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}