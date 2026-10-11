import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../../services/review_service.dart';
import '../../services/reviews/edit_review_screen.dart';
import '../../services/reviews/write_review_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String _selectedFilter = 'All';

  final Map<String, String> _previousBookingStatuses = {};

  final List<String> _filters = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];

  // =========================================================
  // COLORS
  // =========================================================

  static const Color primaryGreen = Color(0xFF1D9B61);
  static const Color darkText = Color(0xFF17231D);
  static const Color secondaryText = Color(0xFF69736D);
  static const Color backgroundColor = Color(0xFFF5F9F7);

  // =========================================================
  // TIME FORMAT
  // =========================================================

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();

    int hour = date.hour;
    final minute = date.minute;

    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    final minuteText = minute.toString().padLeft(2, '0');

    return '$hour:$minuteText $period';
  }

  // =========================================================
  // SHORT DATE
  // =========================================================

  String _formatShortDate(Timestamp timestamp) {
    final date = timestamp.toDate();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}';
  }

  // =========================================================
  // BOOKING STATUS NOTIFICATIONS
  // =========================================================

  Future<void> _checkBookingStatusChanges(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings,
  ) async {
    for (final booking in bookings) {
      final data = booking.data();

      final bookingId = booking.id;

      final currentStatus =
          (data['status'] ?? 'pending').toString().toLowerCase();

      final providerName =
          (data['providerName'] ?? 'your service provider').toString();

      if (!_previousBookingStatuses.containsKey(bookingId)) {
        _previousBookingStatuses[bookingId] = currentStatus;
        continue;
      }

      final previousStatus = _previousBookingStatuses[bookingId];

      if (previousStatus == currentStatus) {
        continue;
      }

      _previousBookingStatuses[bookingId] = currentStatus;

      String? title;
      String? body;

      if (previousStatus == 'pending' &&
          currentStatus == 'confirmed') {
        title = 'Booking Confirmed';
        body =
            'Your booking with $providerName has been confirmed.';
      } else if (previousStatus == 'confirmed' &&
          currentStatus == 'completed') {
        title = 'Booking Completed';
        body =
            'Your booking with $providerName has been completed. You can now leave a review.';
      } else if ((previousStatus == 'pending' ||
              previousStatus == 'confirmed') &&
          currentStatus == 'cancelled') {
        title = 'Booking Cancelled';
        body =
            'Your booking with $providerName has been cancelled.';
      }

      if (title != null && body != null) {
        await NotificationService.showBookingNotification(
          title: title,
          body: body,
        );
      }
    }
  }

  // =========================================================
  // STATUS COLOR
  // =========================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF198754);

      case 'completed':
        return const Color(0xFF3B82F6);

      case 'cancelled':
        return const Color(0xFFDC3545);

      case 'pending':
      default:
        return const Color(0xFFE89B00);
    }
  }

  // =========================================================
  // STATUS ICON
  // =========================================================

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_rounded;

      case 'completed':
        return Icons.task_alt_rounded;

      case 'cancelled':
        return Icons.cancel_rounded;

      case 'pending':
      default:
        return Icons.schedule_rounded;
    }
  }

  // =========================================================
  // STATUS DESCRIPTION
  // =========================================================

  String _statusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Your booking has been confirmed.';

      case 'completed':
        return 'Your service has been completed.';

      case 'cancelled':
        return 'This booking has been cancelled.';

      case 'pending':
      default:
        return 'Waiting for confirmation.';
    }
  }

  // =========================================================
  // FILTER
  // =========================================================

  bool _matchesFilter(String status) {
    if (_selectedFilter == 'All') {
      return true;
    }

    return status.toLowerCase() == _selectedFilter.toLowerCase();
  }

  // =========================================================
  // CANCEL BOOKING
  // =========================================================

  Future<void> _cancelBooking(String bookingId) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Cancel Booking?',
            style: TextStyle(
              color: darkText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to cancel this booking? This action cannot be undone.',
            style: TextStyle(
              color: secondaryText,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Keep Booking',
                style: TextStyle(
                  color: secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) {
      return;
    }

    try {
      await BookingService().cancelBooking(bookingId);

      if (!mounted) return;

      _showMessage(
        'Booking cancelled successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to cancel booking.',
        isError: true,
      );
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade600 : primaryGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // =========================================================
  // OPEN WRITE REVIEW
  // =========================================================

  Future<void> _openReviewScreen(
    String bookingId,
    String providerId,
    String providerName,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(
          bookingId: bookingId,
          providerId: providerId,
          providerName: providerName,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  // =========================================================
  // OPEN EDIT REVIEW
  // =========================================================

  Future<void> _openEditReviewScreen(
    String bookingId,
    String providerName,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReviewScreen(
          bookingId: bookingId,
          providerName: providerName,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {});
    }
  }

  // =========================================================
  // DELETE REVIEW
  // =========================================================

  Future<void> _deleteReview(String bookingId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Delete Review?',
            style: TextStyle(
              color: darkText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete your review? This action cannot be undone.',
            style: TextStyle(
              color: secondaryText,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Keep Review',
                style: TextStyle(
                  color: secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      final review =
          await ReviewService().getReviewByBookingId(bookingId);

      if (review == null) {
        if (!mounted) return;

        _showMessage(
          'Review not found.',
          isError: true,
        );
        return;
      }

      await ReviewService().deleteReview(review.id);

      if (!mounted) return;

      _showMessage(
        'Review deleted successfully.',
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to delete review.',
        isError: true,
      );
    }
  }

  // =========================================================
  // REVIEW SECTION
  // =========================================================

  Widget _buildReviewSection({
    required String bookingId,
    required String providerId,
    required String providerName,
  }) {
    return FutureBuilder<bool>(
      future: ReviewService().hasReviewed(bookingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryGreen,
              ),
            ),
          );
        }

        final hasReviewed = snapshot.data ?? false;

        // =====================================================
        // ALREADY REVIEWED
        // =====================================================

        if (hasReviewed) {
          return Column(
            children: [
              // EDIT REVIEW
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _openEditReviewScreen(
                      bookingId,
                      providerName,
                    );
                  },
                  icon: const Icon(
                    Icons.edit_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    'Edit Review',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryGreen,
                    side: const BorderSide(
                      color: primaryGreen,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // DELETE REVIEW
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _deleteReview(bookingId);
                  },
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: Colors.red.shade600,
                  ),
                  label: Text(
                    'Delete Review',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(
                      color: Colors.red.shade200,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // REVIEWED INDICATOR
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F0),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFFCBEAD8),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD7F1E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: primaryGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'You already reviewed this booking.',
                        style: TextStyle(
                          color: darkText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // =====================================================
        // NOT YET REVIEWED
        // =====================================================

        return SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () {
              _openReviewScreen(
                bookingId,
                providerId,
                providerName,
              );
            },
            icon: const Icon(
              Icons.star_rounded,
              size: 20,
            ),
            label: const Text(
              'Rate Provider',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE09A00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // FILTER BAR
  // =========================================================

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 6,
        bottom: 10,
      ),
      color: backgroundColor,
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          itemCount: _filters.length,
          separatorBuilder: (context, index) {
            return const SizedBox(width: 8);
          },
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final selected = _selectedFilter == filter;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? primaryGreen
                      : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected
                        ? primaryGreen
                        : const Color(0xFFE0E6E2),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: primaryGreen.withValues(
                              alpha: 0.16,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : secondaryText,
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    final isAll = _selectedFilter == 'All';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: primaryGreen.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 48,
                color: primaryGreen.withValues(
                  alpha: 0.65,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isAll
                  ? 'No bookings yet'
                  : 'No $_selectedFilter bookings',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: darkText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              isAll
                  ? 'Your appointments will appear here once you make a booking.'
                  : 'There are no bookings under this status.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryText,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ERROR STATE
  // =========================================================

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: Colors.red.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 43,
                color: Colors.red.shade500,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load bookings',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: const BorderSide(
                  color: primaryGreen,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BOOKING CARD
  // =========================================================

  Widget _buildBookingCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final bookingId = document.id;

    final status = (data['status'] ?? 'pending').toString();

    final providerName =
        (data['providerName'] ?? 'Provider').toString();

    final service =
        (data['service'] ?? 'Service').toString();

    final providerId =
        (data['providerId'] ?? '').toString();

    final dateTime = data['dateTime'];

    final statusColor = _statusColor(status);
    final statusIcon = _statusIcon(status);

    final statusLower = status.toLowerCase();

    final canCancel =
        statusLower != 'cancelled' &&
        statusLower != 'completed';

    return Container(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5EBE7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================
            // TOP ROW
            // =================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryGreen.withValues(
                          alpha: 0.13,
                        ),
                        primaryGreen.withValues(
                          alpha: 0.06,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.home_repair_service_rounded,
                    color: primaryGreen,
                    size: 27,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        service,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // STATUS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.09,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // =================================================
            // DATE / TIME BOX
            // =================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFE6ECE8),
                ),
              ),
              child: Row(
                children: [
                  // DATE
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: primaryGreen,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DATE',
                                style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                dateTime is Timestamp
                                    ? _formatShortDate(
                                        dateTime,
                                      )
                                    : 'No date',
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: darkText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 38,
                    color: const Color(0xFFDCE4DF),
                  ),

                  const SizedBox(width: 13),

                  // TIME
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.access_time_rounded,
                            color: primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TIME',
                                style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                dateTime is Timestamp
                                    ? _formatTime(
                                        dateTime,
                                      )
                                    : 'No time',
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: darkText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 13),

            // =================================================
            // STATUS INFORMATION
            // =================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusDescription(status),
                    style: const TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),

            // =================================================
            // REVIEW
            // =================================================

            if (statusLower == 'completed') ...[
              const SizedBox(height: 14),
              _buildReviewSection(
                bookingId: bookingId,
                providerId: providerId,
                providerName: providerName,
              ),
            ],

            // =================================================
            // CANCEL
            // =================================================

            if (canCancel) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _cancelBooking(bookingId);
                  },
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: 18,
                  ),
                  label: const Text(
                    'Cancel Booking',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(
                      color: Colors.red.shade200,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: darkText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          // FILTERS
          _buildFilterBar(),

          // BOOKINGS
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: BookingService().getBookings(),

              builder: (context, snapshot) {
                // ===========================================
                // LOADING
                // ===========================================

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: primaryGreen,
                    ),
                  );
                }

                // ===========================================
                // ERROR
                // ===========================================

                if (snapshot.hasError) {
                  return _buildErrorState(
                    snapshot.error!,
                  );
                }

                // ===========================================
                // DOCUMENTS
                // ===========================================

                final documents =
                    snapshot.data?.docs ?? [];

                // ===========================================
                // CHECK STATUS CHANGES
                // ===========================================

                _checkBookingStatusChanges(documents);

                // ===========================================
                // FILTER
                // ===========================================

                final bookings = documents.where((doc) {
                  final data = doc.data();

                  final status =
                      (data['status'] ?? 'pending')
                          .toString();

                  return _matchesFilter(status);
                }).toList();

                // ===========================================
                // EMPTY
                // ===========================================

                if (bookings.isEmpty) {
                  return _buildEmptyState();
                }

                // ===========================================
                // LIST
                // ===========================================

                return RefreshIndicator(
                  color: primaryGreen,
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      30,
                    ),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      return _buildBookingCard(
                        bookings[index],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}