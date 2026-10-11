import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() =>
      _AdminReviewsScreenState();
}

class _AdminReviewsScreenState
    extends State<AdminReviewsScreen> {
  // =========================================================
  // BOOKIT COLORS
  // =========================================================

  static const Color primaryGreen = Color(0xFF1D9B61);
  static const Color darkText = Color(0xFF17231D);
  static const Color secondaryText = Color(0xFF69736D);
  static const Color backgroundColor = Color(0xFFF5F9F7);
  static const Color lightGreen = Color(0xFFE9F7EF);

  // =========================================================
  // SEARCH + FILTER
  // =========================================================

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  int? _selectedRating;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery =
            _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Date unavailable';
    }

    final date = timestamp.toDate();

    int hour = date.hour;
    final minute =
        date.minute.toString().padLeft(2, '0');

    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '${date.month}/${date.day}/${date.year} '
        '$hour:$minute $period';
  }

  // =========================================================
  // DELETE REVIEW
  // =========================================================

  Future<void> deleteReview(
    BuildContext context,
    String reviewId,
  ) async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Text('Delete Review?'),
            ],
          ),
          content: const Text(
            'Are you sure you want to permanently delete this review?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: secondaryText,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId)
          .delete();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Review deleted successfully.',
          ),
          backgroundColor: primaryGreen,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Failed to delete review: $e'),
          backgroundColor: Colors.red,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // RATING STARS
  // =========================================================

  Widget buildStars(double rating) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: List.generate(
        5,
        (index) {
          final filled =
              index < rating.round();

          return Icon(
            filled
                ? Icons.star
                : Icons.star_border,
            color:
                Colors.amber.shade700,
            size: 19,
          );
        },
      ),
    );
  }

  // =========================================================
  // RATING BREAKDOWN ROW
  // =========================================================

  Widget _buildRatingRow(
    int rating,
    int count,
    int totalReviews,
  ) {
    final percentage =
        totalReviews == 0
            ? 0.0
            : count / totalReviews;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 6,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 25,
            child: Text(
              '$rating★',
              style:
                  const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
                color: darkText,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              child:
                  LinearProgressIndicator(
                value: percentage,
                minHeight: 7,
                backgroundColor:
                    const Color(
                  0xFFE8EFEB,
                ),
                valueColor:
                    const AlwaysStoppedAnimation<
                        Color>(
                  primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                fontSize: 11,
                color: secondaryText,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SEARCH + FILTER BAR
  // =========================================================

  Widget _buildSearchAndFilter(
    int totalReviews,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14,
      ),
      color: Colors.white,
      child: Column(
        children: [
          // SEARCH FIELD
          TextField(
            controller:
                _searchController,
            decoration:
                InputDecoration(
              hintText:
                  'Search provider or customer...',
              prefixIcon:
                  const Icon(
                Icons.search_rounded,
                color: secondaryText,
              ),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            _searchController
                                .clear();
                          },
                          icon:
                              const Icon(
                            Icons.clear,
                          ),
                        )
                      : null,
              filled: true,
              fillColor:
                  backgroundColor,
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
                borderSide:
                    BorderSide.none,
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFFE1E9E4),
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
                borderSide:
                    const BorderSide(
                  color: primaryGreen,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // RATING FILTER
          Row(
            children: [
              const Text(
                'Rating:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                  color: darkText,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child:
                    SingleChildScrollView(
                  scrollDirection:
                      Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRatingFilterChip(
                        label: 'All',
                        rating: null,
                      ),
                      _buildRatingFilterChip(
                        label: '5 ★',
                        rating: 5,
                      ),
                      _buildRatingFilterChip(
                        label: '4 ★',
                        rating: 4,
                      ),
                      _buildRatingFilterChip(
                        label: '3 ★',
                        rating: 3,
                      ),
                      _buildRatingFilterChip(
                        label: '2 ★',
                        rating: 2,
                      ),
                      _buildRatingFilterChip(
                        label: '1 ★',
                        rating: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_searchQuery.isNotEmpty ||
              _selectedRating != null) ...[
            const SizedBox(height: 9),

            Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                'Showing filtered results',
                style:
                    const TextStyle(
                  fontSize: 11.5,
                  color: secondaryText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // RATING FILTER CHIP
  // =========================================================

  Widget _buildRatingFilterChip({
    required String label,
    required int? rating,
  }) {
    final isSelected =
        _selectedRating == rating;

    return Padding(
      padding:
          const EdgeInsets.only(
        right: 7,
      ),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedRating = rating;
          });
        },
        selectedColor:
            primaryGreen.withValues(
          alpha: 0.14,
        ),
        checkmarkColor:
            primaryGreen,
        side: BorderSide(
          color: isSelected
              ? primaryGreen
              : const Color(
                  0xFFDDE6E0,
                ),
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight:
              FontWeight.w600,
          color: isSelected
              ? primaryGreen
              : secondaryText,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // FILTER REVIEWS
  // =========================================================

  List<QueryDocumentSnapshot<
      Map<String, dynamic>>> _filterReviews(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        reviews,
  ) {
    return reviews.where((review) {
      final data = review.data();

      final providerName =
          data['providerName']
                  ?.toString()
                  .toLowerCase() ??
              '';

      // NEW: CUSTOMER NAME
      final userName =
          data['userName']
                  ?.toString()
                  .toLowerCase() ??
              '';

      // OLD REVIEWS / FALLBACK
      final userEmail =
          data['userEmail']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final comment =
          data['comment']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final rating =
          (data['rating'] as num?)
                  ?.toDouble() ??
              0;

      // SEARCH
      if (_searchQuery.isNotEmpty) {
        final matchesSearch =
            providerName.contains(
                  _searchQuery,
                ) ||
                userName.contains(
                  _searchQuery,
                ) ||
                userEmail.contains(
                  _searchQuery,
                ) ||
                comment.contains(
                  _searchQuery,
                );

        if (!matchesSearch) {
          return false;
        }
      }

      // RATING
      if (_selectedRating != null &&
          rating.round() !=
              _selectedRating) {
        return false;
      }

      return true;
    }).toList();
  }

  // =========================================================
  // REVIEW CARD
  // =========================================================

  Widget buildReviewCard(
    BuildContext context,
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        review,
  ) {
    final data = review.data();

    final providerName =
        data['providerName']
                ?.toString() ??
            'Unknown Provider';

    // =======================================================
    // CUSTOMER NAME
    // =======================================================

    final customerName =
        (data['userName'] ?? '')
            .toString()
            .trim();

    // =======================================================
    // EMAIL FALLBACK
    // =======================================================

    final userEmail =
        data['userEmail']
                ?.toString() ??
            'Unknown User';

    // If the review has userName,
    // display it. Otherwise display email.
    final displayName =
        customerName.isNotEmpty
            ? customerName
            : userEmail;

    final comment =
        data['comment']
                ?.toString() ??
            'No comment';

    final rating =
        (data['rating'] as num?)
                ?.toDouble() ??
            0;

    final timestamp =
        data['createdAt']
            as Timestamp?;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE5ECE8),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =================================================
            // PROVIDER + DELETE
            // =================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    color: lightGreen,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: const Icon(
                    Icons.business_outlined,
                    color: primaryGreen,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // PROVIDER NAME
                      Text(
                        providerName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w700,
                          color: darkText,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // CUSTOMER NAME
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color:
                                secondaryText,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 12.5,
                                color:
                                    secondaryText,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // SHOW EMAIL ONLY IF
                      // NAME IS AVAILABLE
                      if (customerName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            left: 18,
                          ),
                          child: Text(
                            userEmail,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 10.5,
                              color:
                                  secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                IconButton(
                  tooltip:
                      'Delete review',
                  onPressed: () {
                    deleteReview(
                      context,
                      review.id,
                    );
                  },
                  style:
                      IconButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFFFFF1F1,
                    ),
                  ),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 21,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // =================================================
            // RATING
            // =================================================

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFFFFFAEA),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  buildStars(rating),
                  const SizedBox(width: 7),
                  Text(
                    rating.toStringAsFixed(
                      1,
                    ),
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                      fontSize: 13,
                      color: darkText,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 13),

            // =================================================
            // COMMENT
            // =================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(13),
              decoration:
                  BoxDecoration(
                color: backgroundColor,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons
                        .format_quote_rounded,
                    size: 20,
                    color:
                        primaryGreen
                            .withValues(
                      alpha: 0.65,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      comment,
                      style:
                          const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: darkText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 11),

            // =================================================
            // DATE
            // =================================================

            Row(
              children: [
                const Icon(
                  Icons
                      .access_time_rounded,
                  size: 15,
                  color:
                      secondaryText,
                ),
                const SizedBox(width: 5),
                Text(
                  formatDate(
                    timestamp,
                  ),
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget buildEmptyState({
    bool filtered = false,
  }) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration:
                  BoxDecoration(
                color: lightGreen,
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),
              child: Icon(
                filtered
                    ? Icons.search_off_rounded
                    : Icons
                        .rate_review_outlined,
                size: 42,
                color: primaryGreen,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              filtered
                  ? 'No matching reviews'
                  : 'No reviews yet',
              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w700,
                color: darkText,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              filtered
                  ? 'Try changing your search or rating filter.'
                  : 'Customer reviews will appear here once\n'
                      'someone leaves a review.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: secondaryText,
              ),
            ),

            if (filtered) ...[
              const SizedBox(height: 15),

              OutlinedButton(
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _selectedRating = null;
                  });
                },
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      primaryGreen,
                  side:
                      const BorderSide(
                    color: primaryGreen,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                child:
                    const Text(
                  'Clear Filters',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ERROR STATE
  // =========================================================

  Widget buildErrorState(
    Object error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFFFFF1F1),
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 38,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to load reviews',
              style:
                  TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w700,
                color: darkText,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '$error',
              textAlign:
                  TextAlign.center,
              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 13,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          backgroundColor,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Review Management',
          style:
              TextStyle(
            color: darkText,
            fontSize: 20,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        iconTheme:
            const IconThemeData(
          color: darkText,
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('reviews')
                .snapshots(),
        builder:
            (context, snapshot) {
          // =================================================
          // LOADING
          // =================================================

          if (snapshot
                  .connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color:
                    primaryGreen,
              ),
            );
          }

          // =================================================
          // ERROR
          // =================================================

          if (snapshot.hasError) {
            return buildErrorState(
              snapshot.error!,
            );
          }

          // =================================================
          // EMPTY
          // =================================================

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return buildEmptyState();
          }

          // =================================================
          // SORT REVIEWS
          // =================================================

          final reviews =
              snapshot.data!.docs.toList();

          reviews.sort(
            (a, b) {
              final aTime =
                  a.data()['createdAt']
                      as Timestamp?;

              final bTime =
                  b.data()['createdAt']
                      as Timestamp?;

              if (aTime == null &&
                  bTime == null) {
                return 0;
              }

              if (aTime == null) {
                return 1;
              }

              if (bTime == null) {
                return -1;
              }

              return bTime.compareTo(
                aTime,
              );
            },
          );

          // =================================================
          // CALCULATE SUMMARY
          // =================================================

          double totalRating = 0;

          int fiveStars = 0;
          int fourStars = 0;
          int threeStars = 0;
          int twoStars = 0;
          int oneStar = 0;

          for (final review
              in reviews) {
            final rating =
                (review.data()['rating']
                            as num?)
                        ?.toDouble() ??
                    0;

            totalRating += rating;

            final roundedRating =
                rating.round();

            switch (roundedRating) {
              case 5:
                fiveStars++;
                break;

              case 4:
                fourStars++;
                break;

              case 3:
                threeStars++;
                break;

              case 2:
                twoStars++;
                break;

              case 1:
                oneStar++;
                break;
            }
          }

          final averageRating =
              reviews.isEmpty
                  ? 0.0
                  : totalRating /
                      reviews.length;

          // =================================================
          // FILTER REVIEWS
          // =================================================

          final filteredReviews =
              _filterReviews(
            reviews,
          );

          // =================================================
          // MAIN CONTENT
          // =================================================

          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // =================================================
              // HEADER
              // =================================================

              Container(
                width: double.infinity,
                color: Colors.white,
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  16,
                  18,
                  17,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration:
                          BoxDecoration(
                        color: lightGreen,
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .rate_review_outlined,
                        color:
                            primaryGreen,
                        size: 22,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Text(
                          'Customer Reviews',
                          style:
                              TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight
                                    .w700,
                            color:
                                darkText,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          '${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                          style:
                              const TextStyle(
                            fontSize: 12,
                            color:
                                secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // =================================================
              // SUMMARY
              // =================================================

              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  0,
                ),
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFFE5ECE8,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Review Summary',
                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight
                                .w800,
                        color:
                            darkText,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Container(
                          width: 120,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 14,
                            horizontal: 6,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                lightGreen,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                          ),
                          child:
                              Column(
                            children: [
                              Text(
                                averageRating
                                    .toStringAsFixed(
                                  1,
                                ),
                                style:
                                    const TextStyle(
                                  fontSize:
                                      27,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                  color:
                                      primaryGreen,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              buildStars(
                                averageRating,
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                '${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    const TextStyle(
                                  fontSize:
                                      11,
                                  color:
                                      secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          width: 18,
                        ),

                        Expanded(
                          child:
                              Column(
                            children: [
                              _buildRatingRow(
                                5,
                                fiveStars,
                                reviews.length,
                              ),
                              _buildRatingRow(
                                4,
                                fourStars,
                                reviews.length,
                              ),
                              _buildRatingRow(
                                3,
                                threeStars,
                                reviews.length,
                              ),
                              _buildRatingRow(
                                2,
                                twoStars,
                                reviews.length,
                              ),
                              _buildRatingRow(
                                1,
                                oneStar,
                                reviews.length,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // =================================================
              // SEARCH + FILTER
              // =================================================

              const SizedBox(
                height: 12,
              ),

              _buildSearchAndFilter(
                reviews.length,
              ),

              // =================================================
              // RESULT COUNT
              // =================================================

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  13,
                  16,
                  0,
                ),
                child: Text(
                  '${filteredReviews.length} result${filteredReviews.length == 1 ? '' : 's'}',
                  style:
                      const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        secondaryText,
                  ),
                ),
              ),

              // =================================================
              // REVIEW LIST
              // =================================================

              Expanded(
                child:
                    filteredReviews.isEmpty
                        ? buildEmptyState(
                            filtered: true,
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              16,
                              12,
                              16,
                              24,
                            ),
                            itemCount:
                                filteredReviews
                                    .length,
                            itemBuilder:
                                (context,
                                    index) {
                              return buildReviewCard(
                                context,
                                filteredReviews[
                                    index],
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}