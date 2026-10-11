import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/booking_service.dart';
import '../../services/review_service.dart';
import '../../services/reviews/write_review_screen.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState
    extends State<BookingDetailsScreen> {
  static const Color primaryGreen = Color(0xFF1D9B61);
  static const Color darkText = Color(0xFF17231D);
  static const Color secondaryText = Color(0xFF69736D);
  static const Color backgroundColor = Color(0xFFF5F9F7);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _loading = true;
  bool _cancelling = false;

  Map<String, dynamic>? _booking;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  // =========================================================
  // LOAD BOOKING
  // =========================================================

  Future<void> _loadBooking() async {
    try {
      final document = await _firestore
          .collection('bookings')
          .doc(widget.bookingId)
          .get();

      if (!mounted) return;

      if (!document.exists) {
        setState(() {
          _loading = false;
          _booking = null;
        });
        return;
      }

      setState(() {
        _booking = document.data();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _booking = null;
      });
    }
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'No date';
    }

    final date = value.toDate();

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // =========================================================
  // FORMAT TIME
  // =========================================================

  String _formatTime(dynamic value) {
    if (value is! Timestamp) {
      return 'No time';
    }

    final date = value.toDate();

    int hour = date.hour;
    final minute = date.minute;

    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    final minuteText =
        minute.toString().padLeft(2, '0');

    return '$hour:$minuteText $period';
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
        return 'Your booking has been confirmed by the service provider.';

      case 'completed':
        return 'Your service has been completed. You can now leave a review.';

      case 'cancelled':
        return 'This booking has been cancelled.';

      case 'pending':
      default:
        return 'Your booking is waiting for confirmation.';
    }
  }

  // =========================================================
  // CANCEL BOOKING
  // =========================================================

  Future<void> _cancelBooking() async {
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

    setState(() {
      _cancelling = true;
    });

    try {
      await BookingService().cancelBooking(
        widget.bookingId,
      );

      if (!mounted) return;

      await _loadBooking();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booking cancelled successfully.',
          ),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to cancel booking.',
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cancelling = false;
        });
      }
    }
  }

  // =========================================================
  // REVIEW
  // =========================================================

  Future<void> _openReviewScreen({
    required String providerId,
    required String providerName,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(
          bookingId: widget.bookingId,
          providerId: providerId,
          providerName: providerName,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  // =========================================================
  // REVIEW SECTION
  // =========================================================

  Widget _buildReviewSection({
    required String providerId,
    required String providerName,
  }) {
    return FutureBuilder<bool>(
      future: ReviewService().hasReviewed(
        widget.bookingId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(13),
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

        final hasReviewed =
            snapshot.data ?? false;

        if (hasReviewed) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFCBEAD8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD7F1E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'You already reviewed this booking.',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: () {
              _openReviewScreen(
                providerId: providerId,
                providerName: providerName,
              );
            },
            icon: const Icon(
              Icons.star_rounded,
              size: 21,
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
  // INFO ROW
  // =========================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5EBE7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BOOKING ID
  // =========================================================

  Widget _buildBookingId() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5EBE7),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.confirmation_number_outlined,
            color: primaryGreen,
            size: 21,
          ),
          const SizedBox(width: 10),
          const Text(
            'Booking ID',
            style: TextStyle(
              color: secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              widget.bookingId,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: darkText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // LOADING
  // =========================================================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: primaryGreen,
      ),
    );
  }

  // =========================================================
  // NOT FOUND
  // =========================================================

  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.red.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 44,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Booking Not Found',
              style: TextStyle(
                color: darkText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This booking may have been removed or is no longer available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryText,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
              ),
              label: const Text('Go Back'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MAIN CONTENT
  // =========================================================

  Widget _buildContent() {
    final data = _booking!;

    final providerName =
        (data['providerName'] ?? 'Provider').toString();

    final service =
        (data['service'] ?? 'Service').toString();

    final providerId =
        (data['providerId'] ?? '').toString();

    final status =
        (data['status'] ?? 'pending').toString();

    final statusLower =
        status.toLowerCase();

    final dateTime =
        data['dateTime'];

    final statusColor =
        _statusColor(status);

    final statusIcon =
        _statusIcon(status);

    final canCancel =
        statusLower != 'cancelled' &&
        statusLower != 'completed';

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _loadBooking,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          35,
        ),
        children: [
          // =================================================
          // STATUS HEADER
          // =================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withValues(
                  alpha: 0.18,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 31,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  status[0].toUpperCase() +
                      status.substring(1).toLowerCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _statusDescription(status),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // =================================================
          // PROVIDER / SERVICE
          // =================================================

          const Text(
            'Booking Information',
            style: TextStyle(
              color: darkText,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 11),

          _buildInfoRow(
            icon: Icons.business_center_rounded,
            label: 'Service Provider',
            value: providerName,
          ),

          const SizedBox(height: 10),

          _buildInfoRow(
            icon: Icons.home_repair_service_rounded,
            label: 'Service',
            value: service,
          ),

          const SizedBox(height: 10),

          _buildInfoRow(
            icon: Icons.calendar_month_rounded,
            label: 'Date',
            value: _formatDate(dateTime),
          ),

          const SizedBox(height: 10),

          _buildInfoRow(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: _formatTime(dateTime),
          ),

          const SizedBox(height: 18),

          // =================================================
          // BOOKING ID
          // =================================================

          _buildBookingId(),

          // =================================================
          // REVIEW
          // =================================================

          if (statusLower == 'completed' &&
              providerId.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Your Review',
              style: TextStyle(
                color: darkText,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 11),
            _buildReviewSection(
              providerId: providerId,
              providerName: providerName,
            ),
          ],

          // =================================================
          // CANCEL
          // =================================================

          if (canCancel) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed:
                    _cancelling ? null : _cancelBooking,
                icon: _cancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Icon(
                        Icons.cancel_outlined,
                        size: 20,
                      ),
                label: Text(
                  _cancelling
                      ? 'Cancelling...'
                      : 'Cancel Booking',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.red.shade700,
                  side: BorderSide(
                    color: Colors.red.shade200,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ],
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
        title: const Text(
          'Booking Details',
          style: TextStyle(
            color: darkText,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? _buildLoading()
          : _booking == null
              ? _buildNotFound()
              : _buildContent(),
    );
  }
}